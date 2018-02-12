SUBDIRS = . EnclaveHash

include ../am/sgx_app.am

EnclaveHash_u.c EnclaveHash_u.h: EnclaveHash/EnclaveHash.edl

bin_PROGRAMS = storesecret
storesecret_LDADD = -ldl -l:libsgx_capable.a
storesecret_SOURCES = EnclaveHash_u.c EnclaveHash_u.h main.c sgx_stub.c sgx_detect_linux.c 

