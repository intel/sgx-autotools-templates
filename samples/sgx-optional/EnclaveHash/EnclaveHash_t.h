#ifndef ENCLAVEHASH_T_H__
#define ENCLAVEHASH_T_H__

#include <stdint.h>
#include <wchar.h>
#include <stddef.h>
#include "sgx_edger8r.h" /* for sgx_ocall etc. */


#include <stdlib.h> /* for size_t */

#define SGX_CAST(type, item) ((type)(item))

#ifdef __cplusplus
extern "C" {
#endif


void store_secret(char* s);
int get_hash(unsigned char hash[32]);


#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif
