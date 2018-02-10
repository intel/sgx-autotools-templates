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
#include "sgx_stub.h"
#include <limits.h>
#include <stdio.h>
#include <sgx_urts.h>
#include <sys/stat.h>

#define MAX_LEN 80

#ifdef __x86_64__
#define DEF_LIB_SEARCHPATH "/lib:/lib64:/usr/lib:/usr/lib64"
#else
#define DEF_LIB_SEARCHPATH "/lib:/usr/lib"
#endif

int file_in_searchpath (const char *file, char *search, char *fullpath,
	size_t len);

sgx_status_t sgx_create_enclave_search (
	const char *filename,
	const int debug,
	sgx_launch_token_t *token,
	int *updated,
	sgx_enclave_id_t *eid,
	sgx_misc_attribute_t *attr
);

int main (int argc, char *argv[])
{
	char msg[MAX_LEN];
	sgx_launch_token_t token= { 0 };
	sgx_status_t status;
	sgx_enclave_id_t eid= 0;
	int updated= 0;
	int rv, i;
	unsigned char sha2[32];

	/* Can we run SGX? */

	if ( ! have_sgx_psw() ) {
		fprintf(stderr, "Intel SGX runtime libraries not found.\n");
		fprintf(stderr, "This system cannot use Intel SGX.\n");
		exit(1);
	}

	/* Launch the enclave */

	status= sgx_create_enclave_search("EnclaveHash.signed.so", SGX_DEBUG_FLAG, &token, &updated, &eid, 0);
	if ( status != SGX_SUCCESS ) {
		fprintf(stderr, "sgx_create_enclave: EnclaveHash.signed.so: %08x\n",
			status);
		if ( status == SGX_ERROR_ENCLAVE_FILE_ACCESS ) 
			fprintf(stderr, "Did you forget to set LD_LIBRARY_PATH?\n");
		return 1;
	}

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

	status= store_secret(eid, msg);
	if ( status != SGX_SUCCESS ) {
		fprintf(stderr, "ECALL store_secret: %08x\n", status);
		return 1;
	}

	/* Delete the secret from memory */

	/* Use -fno-builtin-memset with gcc to prevent this from 
	 * being optimized away */
	memset(msg, 0, 80);	

	printf("Secret stored in the enclave.\n");

	/* Get the SHA256 hash of the secret from the enclave */
	status= get_hash(eid, &rv, sha2);
	if ( status != SGX_SUCCESS ) {
		fprintf(stderr, "ECALL get_hash: %08x\n", status);
		return 1;
	}
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

sgx_status_t sgx_create_enclave_search (const char *filename, const int debug,
	sgx_launch_token_t *token, int *updated, sgx_enclave_id_t *eid,
	sgx_misc_attribute_t *attr)
{
	struct stat sb;
	char epath[PATH_MAX];	/* includes NULL */

	/* Is filename an absolute path? */

	if ( filename[0] == '/' ) 
		return sgx_create_enclave(filename, debug, token, updated, eid, attr);

	/* Is the enclave in the current working directory? */

	if ( stat(filename, &sb) == 0 )
		return sgx_create_enclave(filename, debug, token, updated, eid, attr);

	/* Search the paths in LD_LBRARY_PATH */

	if ( file_in_searchpath(filename, getenv("LD_LIBRARY_PATH"), epath, PATH_MAX) )
		return sgx_create_enclave(epath, debug, token, updated, eid, attr);
		
	/* Search the paths in DT_RUNPATH */

	if ( file_in_searchpath(filename, getenv("DT_RUNPATH"), epath, PATH_MAX) )
		return sgx_create_enclave(epath, debug, token, updated, eid, attr);

	/* Standard system library paths */

	if ( file_in_searchpath(filename, DEF_LIB_SEARCHPATH, epath, PATH_MAX) )
		return sgx_create_enclave(epath, debug, token, updated, eid, attr);

	/*
	 * If we've made it this far then we don't know where else to look.
	 * Just call sgx_create_enclave() which assumes the enclave is in
	 * the current working directory. This is almost guaranteed to fail,
	 * but it will insure we are consistent about the error codes that
	 * get reported to the calling function.
	 */

	return sgx_create_enclave(filename, debug, token, updated, eid, attr);
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

