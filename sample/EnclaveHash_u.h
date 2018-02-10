#ifndef ENCLAVEHASH_U_H__
#define ENCLAVEHASH_U_H__

#include <stdint.h>
#include <wchar.h>
#include <stddef.h>
#include <string.h>
#include "sgx_edger8r.h" /* for sgx_satus_t etc. */


#include <stdlib.h> /* for size_t */

#define SGX_CAST(type, item) ((type)(item))

#ifdef __cplusplus
extern "C" {
#endif


sgx_status_t store_secret(sgx_enclave_id_t eid, char* s);
sgx_status_t get_hash(sgx_enclave_id_t eid, int* retval, unsigned char hash[32]);

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif
