/*

Copyright 2017 Intel Corporation

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

1. Redistributions of source code must retain the above copyright
notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright
notice, this list of conditions and the following disclaimer in the
documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
contributors may be used to endorse or promote products derived from
this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED
TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

*/

#include "config.h"
#include "EnclaveHash_t.h"
#include <string.h>
#ifdef SGX_HAVE_SGXSDK
#include <sgx_tcrypto.h>
#else
#include <openenclave/enclave.h>
#include <openenclave/3rdparty/mbedtls/sha256.h>
#endif
#ifdef HAVE_FPRINTF
#include <stdio.h>
#endif

char secret[81];

void store_secret(char *s)
{
	strncpy(secret, s, 80);
#ifdef HAVE_FPRINTF
	fprintf(stderr, "Secret stored in enclave\n");
#endif
}

int get_hash(unsigned char hash[32])
{
#ifdef SGX_HAVE_SGXSDK
	sgx_status_t status;

	status= sgx_sha256_msg((uint8_t *) secret, strlen(secret), (sgx_sha256_hash_t *) hash);
	return (status == SGX_SUCCESS) ? 1 : 0;
#else
	oe_result_t status;
	mbedtls_sha256_context ctx;

	mbedtls_sha256_init(&ctx);
	mbedtls_sha256_starts_ret(&ctx, 0);
	mbedtls_sha256_update_ret(&ctx, secret, strlen(secret));
	mbedtls_sha256_finish_ret(&ctx, hash);

	return 1;
#endif
}

