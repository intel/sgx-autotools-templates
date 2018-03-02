#include "EnclaveHash_t.h"

#include "sgx_trts.h" /* for sgx_ocalloc, sgx_is_outside_enclave */

#include <errno.h>
#include <string.h> /* for memcpy etc */
#include <stdlib.h> /* for malloc/free etc */

#define CHECK_REF_POINTER(ptr, siz) do {	\
	if (!(ptr) || ! sgx_is_outside_enclave((ptr), (siz)))	\
		return SGX_ERROR_INVALID_PARAMETER;\
} while (0)

#define CHECK_UNIQUE_POINTER(ptr, siz) do {	\
	if ((ptr) && ! sgx_is_outside_enclave((ptr), (siz)))	\
		return SGX_ERROR_INVALID_PARAMETER;\
} while (0)


typedef struct ms_store_secret_t {
	char* ms_s;
} ms_store_secret_t;

typedef struct ms_get_hash_t {
	int ms_retval;
	unsigned char* ms_hash;
} ms_get_hash_t;

static sgx_status_t SGX_CDECL sgx_store_secret(void* pms)
{
	ms_store_secret_t* ms = SGX_CAST(ms_store_secret_t*, pms);
	sgx_status_t status = SGX_SUCCESS;
	char* _tmp_s = ms->ms_s;
	size_t _len_s = _tmp_s ? strlen(_tmp_s) + 1 : 0;
	char* _in_s = NULL;

	CHECK_REF_POINTER(pms, sizeof(ms_store_secret_t));
	CHECK_UNIQUE_POINTER(_tmp_s, _len_s);

	if (_tmp_s != NULL) {
		_in_s = (char*)malloc(_len_s);
		if (_in_s == NULL) {
			status = SGX_ERROR_OUT_OF_MEMORY;
			goto err;
		}

		memcpy(_in_s, _tmp_s, _len_s);
		_in_s[_len_s - 1] = '\0';
	}
	store_secret(_in_s);
err:
	if (_in_s) free(_in_s);

	return status;
}

static sgx_status_t SGX_CDECL sgx_get_hash(void* pms)
{
	ms_get_hash_t* ms = SGX_CAST(ms_get_hash_t*, pms);
	sgx_status_t status = SGX_SUCCESS;
	unsigned char* _tmp_hash = ms->ms_hash;
	size_t _len_hash = 32 * sizeof(*_tmp_hash);
	unsigned char* _in_hash = NULL;

	CHECK_REF_POINTER(pms, sizeof(ms_get_hash_t));
	CHECK_UNIQUE_POINTER(_tmp_hash, _len_hash);

	if (_tmp_hash != NULL) {
		if ((_in_hash = (unsigned char*)malloc(_len_hash)) == NULL) {
			status = SGX_ERROR_OUT_OF_MEMORY;
			goto err;
		}

		memset((void*)_in_hash, 0, _len_hash);
	}
	ms->ms_retval = get_hash(_in_hash);
err:
	if (_in_hash) {
		memcpy(_tmp_hash, _in_hash, _len_hash);
		free(_in_hash);
	}

	return status;
}

SGX_EXTERNC const struct {
	size_t nr_ecall;
	struct {void* ecall_addr; uint8_t is_priv;} ecall_table[2];
} g_ecall_table = {
	2,
	{
		{(void*)(uintptr_t)sgx_store_secret, 0},
		{(void*)(uintptr_t)sgx_get_hash, 0},
	}
};

SGX_EXTERNC const struct {
	size_t nr_ocall;
} g_dyn_entry_table = {
	0,
};


