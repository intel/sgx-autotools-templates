#include "EnclaveHash_u.h"
#include <errno.h>

typedef struct ms_store_secret_t {
	char* ms_s;
} ms_store_secret_t;

typedef struct ms_get_hash_t {
	int ms_retval;
	unsigned char* ms_hash;
} ms_get_hash_t;

static const struct {
	size_t nr_ocall;
	void * table[1];
} ocall_table_EnclaveHash = {
	0,
	{ NULL },
};
sgx_status_t store_secret(sgx_enclave_id_t eid, char* s)
{
	sgx_status_t status;
	ms_store_secret_t ms;
	ms.ms_s = s;
	status = sgx_ecall(eid, 0, &ocall_table_EnclaveHash, &ms);
	return status;
}

sgx_status_t get_hash(sgx_enclave_id_t eid, int* retval, unsigned char hash[32])
{
	sgx_status_t status;
	ms_get_hash_t ms;
	ms.ms_hash = (unsigned char*)hash;
	status = sgx_ecall(eid, 1, &ocall_table_EnclaveHash, &ms);
	if (status == SGX_SUCCESS && retval) *retval = ms.ms_retval;
	return status;
}

