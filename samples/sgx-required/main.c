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
#include "EnclaveHash_u.h"
#include <limits.h>
#include <stdio.h>
#include <sys/stat.h>

#ifdef SGX_HAVE_SGXSDK
#include "sgx_stub.h"
#include <sgx_urts.h>
#else
#include <openenclave/host.h>
#endif

#define MAX_LEN 80

#ifdef __x86_64__
#define DEF_LIB_SEARCHPATH "/lib:/lib64:/usr/lib:/usr/lib64"
#else
#define DEF_LIB_SEARCHPATH "/lib:/usr/lib"
#endif

#ifdef SGX_HW_SIM
#define SGX_SIM_FLAG 1
#else
#define SGX_SIM_FLAG 0
#endif

/* This is a hack */
#ifndef SGX_DEBUG_FLAG
# define SGX_DEBUG_FLAG OE_DEBUG_FLAG
#endif

#define ENCLAVE_NAME "EnclaveHash.signed.so"

typedef struct _enclave_meta_struct {
#ifdef SGX_HAVE_SGXSDK
	sgx_launch_token_t token;
	int updated;
	sgx_enclave_id_t enclave;
	sgx_misc_attribute_t *attr;
#else
	oe_enclave_type_t type;
	void *config;
	uint32_t config_size;
	oe_enclave_t *enclave;
#endif
} enclave_meta_t;

int file_in_searchpath (const char *file, char *search, char *fullpath,
	size_t len);

#ifdef SGX_HAVE_SGXSDK
sgx_status_t create_enclave_search (
#else
oe_result_t create_enclave_search (
#endif
	const char *filename,
	const int debug,
	const int sim,
	enclave_meta_t *enclave
);


int main (int argc, char *argv[])
{
	char msg[MAX_LEN];
	enclave_meta_t e;
#ifdef SGX_HAVE_SGXSDK
	sgx_status_t status;
#else
	oe_result_t status;
#endif
	int rv, i;
	unsigned char sha2[32];

#ifdef SGX_HAVE_SGXSDK
	memset(e.token, 0, sizeof(e.token));
	e.updated= 0;
	e.enclave= 0;
	e.attr= NULL;
#else
	e.config= NULL;
	e.config_size= 0;
	e.type= OE_ENCLAVE_TYPE_SGX;
#endif

	/* Can we run SGX? */

#ifdef SGX_HAVE_SGXSDK
	if ( ! have_sgx_psw() ) {
		fprintf(stderr, "Intel SGX runtime libraries not found.\n");
		fprintf(stderr, "This system cannot use Intel SGX.\n");
		exit(1);
	}
#endif

	/* Launch the enclave */

	status= create_enclave_search(ENCLAVE_NAME, SGX_DEBUG_FLAG,
		SGX_SIM_FLAG, &e);
#ifdef SGX_HAVE_SGXSDK
	if ( status != SGX_SUCCESS ) {
		if ( status == SGX_ERROR_ENCLAVE_FILE_ACCESS ) {
			fprintf(stderr, "sgx_create_enclave: %s: file not found\n",
				ENCLAVE_NAME);
			fprintf(stderr, "Did you forget to set LD_LIBRARY_PATH?\n");
		} else {
			fprintf(stderr, "sgx_create_enclave: %s: %08x\n", ENCLAVE_NAME,
				status);
		}
		return 1;
	}
#else
	if ( status != OE_OK ) {
		fprintf(stderr, "oe_create_enclave: %s: %s\n", ENCLAVE_NAME,
			oe_result_str(status));
		return 1;
	}
#endif

	/* Turn off I/O buffering for stdin */

	if ( setvbuf(stdin, NULL, _IONBF, 0) != 0 ) {
		fprintf(stderr, "Could not turn off I/O buffering for stdin\n");
		perror("setvbuf");
	}

	printf("Enter a short string (< 80 characters) to place in the enclave:\n");
	if ( fgets(msg, MAX_LEN, stdin) == NULL ) {
		fprintf(stderr, "No input received\n");
		return 1;
	}

	status= store_secret(e.enclave, msg);
#ifdef SGX_HAVE_SGXSDK
	if ( status != SGX_SUCCESS ) {
		fprintf(stderr, "ECALL store_secret: %08x\n", status);
		return 1;
	}
#else
	if ( status != OE_OK ) {
		fprintf(stderr, "ECALL store_secret: %s\n", oe_result_str(status));
		return 1;
	}
#endif

	/* Delete the secret from memory */

	/* Use -fno-builtin-memset with gcc to prevent this from 
	 * being optimized away */
	memset(msg, 0, 80);	

	printf("Secret stored in the enclave.\n");

	/* Get the SHA256 hash of the secret from the enclave */
	status= get_hash(e.enclave, &rv, sha2);
#ifdef SGX_HAVE_SGXSDK
	if ( status != SGX_SUCCESS ) {
		fprintf(stderr, "ECALL get_hash: %08x\n", status);
		return 1;
	}
#else
	if ( status != OE_OK ) {
		fprintf(stderr, "ECALL get_hash: %s\n", oe_result_str(status));
		return 1;
	}
#endif
	if ( rv == 0 ) {
		fprintf(stderr, "get_hash: could not calculate hash\n");
		return 1;
	}	

	/* Print the hash as a string of hex characters */

	printf("\nSHA-256 hash of your secret (including the trailing newline) is:\n");
	for (i= 0; i<32; ++i) {
		printf("%02x", sha2[i]);
	}
	printf("\n\n");

	printf("Verify this with sha256sum on Linux, or online at:\n");
	printf("http://passwordsgenerator.net/sha256-hash-generator/\n");
	printf("\n(don't forget to include the trailing newline)\n");

	return 0;
}

/*
 * Search for the enclave file and then try and load it.
 */

#ifdef SGX_HAVE_SGXSDK
sgx_status_t create_enclave_search (const char *filename, const int debug,
#else
oe_result_t create_enclave_search (const char *filename, const int debug,
#endif
	const int sim, enclave_meta_t *e)
{
	struct stat sb;
	char epath[PATH_MAX];	/* includes NULL */
#ifdef SGX_HAVE_OPENENCLAVE
	uint32_t flags= 0;
#endif

#ifdef SGX_HAVE_OPENENCLAVE
	if ( debug ) flags|= OE_ENCLAVE_FLAG_DEBUG;
	if ( sim )   flags|= OE_ENCLAVE_FLAG_SIMULATE;
#endif

	/* Is filename an absolute path? */

	if ( filename[0] == '/' ) {
#ifdef SGX_HAVE_SGXSDK
		return sgx_create_enclave(filename, debug, &e->token, &e->updated,
			&e->enclave, e->attr);
#else
		return oe_create_enclave(filename, e->type, flags, e->config,
			e->config_size, &e->enclave);
#endif
	}

	/* Is the enclave in the current working directory? */

	if ( stat(filename, &sb) == 0 ) {
#ifdef SGX_HAVE_SGXSDK
		return sgx_create_enclave(filename, debug, &e->token, &e->updated,
			&e->enclave, e->attr);
#else
		return oe_create_enclave(filename, e->type, flags, e->config,
			e->config_size, &e->enclave);
#endif
	}

	/* Search the paths in LD_LBRARY_PATH */

	if ( file_in_searchpath(filename, getenv("LD_LIBRARY_PATH"), epath, PATH_MAX) ) {
#ifdef SGX_HAVE_SGXSDK
		return sgx_create_enclave(epath, debug, &e->token, &e->updated,
			&e->enclave, e->attr);
#else
		return oe_create_enclave(epath, e->type, flags, e->config,
			e->config_size, &e->enclave);
#endif
	}
		
	/* Search the paths in DT_RUNPATH */

	if ( file_in_searchpath(filename, getenv("DT_RUNPATH"), epath, PATH_MAX) ) {
#ifdef SGX_HAVE_SGXSDK
		return sgx_create_enclave(epath, debug, &e->token, &e->updated,
			&e->enclave, e->attr);
#else
		return oe_create_enclave(epath, e->type, flags, e->config,
			e->config_size, &e->enclave);
#endif
	}

	/* Standard system library paths */

	if ( file_in_searchpath(filename, DEF_LIB_SEARCHPATH, epath, PATH_MAX) ) {
#ifdef SGX_HAVE_SGXSDK
		return sgx_create_enclave(epath, debug, &e->token, &e->updated,
			&e->enclave, e->attr);
#else
		return oe_create_enclave(epath, e->type, flags, e->config,
			e->config_size, &e->enclave);
#endif
	}

	/*
	 * If we've made it this far then we don't know where else to look.
	 * Just call sgx_create_enclave() which assumes the enclave is in
	 * the current working directory. This is almost guaranteed to fail,
	 * but it will ensure we are consistent about the error codes that
	 * get reported to the calling function.
	 */

#ifdef SGX_HAVE_SGXSDK
	return sgx_create_enclave(filename, debug, &e->token, &e->updated,
		&e->enclave, e->attr);
#else
	return oe_create_enclave(filename, e->type, flags, e->config,
		e->config_size, &e->enclave);
#endif
}

int file_in_searchpath (const char *file, char *search, char *fullpath, 
	size_t len)
{
	char *p, *str;
	size_t rem;
	struct stat sb;

	if ( search == NULL ) return 0;
	if ( strlen(search) == 0 ) return 0;

	str= strdup(search);
	if ( str == NULL ) return 0;

	p= strtok(str, ":");
	while ( p != NULL) {
		size_t lp= strlen(p);

		if ( lp ) {

			strncpy(fullpath, p, len);
			rem= len-lp-1;

			strncat(fullpath, "/", rem);
			--rem;

			strncat(fullpath, file, rem);

			if ( stat(fullpath, &sb) == 0 ) {
				free(str);
				return 1;
			}
		}

		p= strtok(NULL, ":");
	}

	free(str);

	return 0;
}

