SUBDIRS = . EnclaveHash

include $(top_srcdir)/am/sgx_app.am

EnclaveHash_u.c EnclaveHash_u.h: EnclaveHash/EnclaveHash.edl

bin_PROGRAMS = storesecret
storesecret_LDADD = -ldl -l:libsgx_capable.a
if SGX_HW_SIM
storesecret_LDADD += -lpthread
endif 
storesecret_SOURCES = EnclaveHash_u.c EnclaveHash_u.h main.c sgx_stub.c sgx_detect_linux.c 
