## This must come first when building an application that uses Intel
## SGX enclaves.

include $(top_srcdir)/build-aux/sgx_app.am

## It sets the following automake variables:
##
##   AM_CPPFLAGS = -I$(SGXSDK_INCDIR)
##   AM_LDFLAGS = -L$(SGXSDK_LIBDIR)
##
## And a pattern rule for building proxy functions from EDL files:
##
##   %_u.h %_u.c: %.edl
##
## And sets these Makefile variables:
##
##   SGXSDK
##   SGXSDK_BINDIR
##   SGXSDK_INCDIR
##   SGXSDK_LIBDIR
##   SGXSSL
##   SGXSSL_BINDIR
##   SGXSSL_INCDIR
##   SGXSSL_LIBDIR
##   SGX_URTS_LIB
##   SGX_UAE_SERVICE_LIB
##   SGX_EDGER8R

DIST_SUBDIRS = EnclaveHash
if SGX_ENABLED
SUBDIRS = EnclaveHash
else !SGX_ENABLED
SUBDIRS =
endif


## Supply additional flags to edger8r here. 
##
## SGX_EDGER8R_FLAGS=


## Needed to make our pattern rule work

if SGX_ENABLED
EnclaveHash.edl: EnclaveHash/EnclaveHash.edl
	ln -s $?
endif


## Additional automake variables
##
## AM_CPPFLAGS += 
## AM_CFLAGS = 
## AM_CXXFLAGS = 

AM_CPPFLAGS += -fno-builtin-memset

## Additional targets to remove with 'make clean'. You must list
## any edger8r generated files here.

if SGX_ENABLED
CLEANFILES = EnclaveHash_u.c EnclaveHash_u.h EnclaveHash.edl \
	EnclaveHash.signed.so

## Copy the signed enclave to the current directory

EnclaveHash.signed.so: EnclaveHash/EnclaveHash.signed.so
	ln -s $?

endif


## The build target

bin_PROGRAMS = storesecret


## You can't use $(wildcard ...) with automake so all source files 
## have to be explicitly listed.

storesecret_SOURCES = main.c
if SGX_WITH_SGXSDK
storesecret_SOURCES += sgx_detect_linux.c sgx_stub.c
endif
if SGX_ENABLED
nodist_storesecret_SOURCES = EnclaveHash_u.c EnclaveHash_u.h
BUILT_SOURCES = EnclaveHash_u.c EnclaveHash_u.h
EXTRA_storesecret_DEPENDENCIES = EnclaveHash.signed.so
endif


## Library flags. At minimum, an Intel SGX application will need:
##
##   -l$(SGX_URTS_LIB)
##
## Applications that use platform services or perform attestation
## will also need:
##
##  -l$(SGX_UA_SERVICE_LIB)
##
## Use the variables, not the actualy library names to ensure these
## targets work on simulation builds.

if SGX_WITH_SGXSDK
storesecret_LDADD=-l$(SGX_URTS_LIB) -ldl -l:libsgx_capable.a -lpthread
else
storesecret_LDADD=$(OE_APP_LDADD)
endif

