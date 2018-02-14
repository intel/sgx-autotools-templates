include $(top_srcdir)/am/sgx_enclave.am

## The name of your enclave goes here. The expectation is that your
## enclave name will also determine the name of your EDL file,
## enclave configuration file and private key file. (e.g. if your
## enclave is named DoStuff, you would have DoStuff.edl, 
## DoStuff.config.xml and DoStuff_private.pem

ENCLAVE=EnclaveHash


## Put your sources here. Don't forget to list the _t.c and _t.h 
## files. You can't use the $(ENCLAVE) variable here.

EnclaveHash_SOURCES = EnclaveHash_t.c EnclaveHash_t.h EnclaveHash.c


## This line is OPTIONAL. Add additional linker flags to AM_LDFLAGS 
## here. Don't put additional, trusted libraries here (those go in 
## *_LDADD below). Be sure to use += to add to, and not replace, the
# default AM_LDFLAGS.

# AM_LDFLAGS +=


## This line is REQUIRED. It can't be generically defined for 
## automake, so you must specify it for your enclave. Note that you
## can't say $(ENCLAVE)_LDADD here: you must spell out the enclave name.
## If you add flags to it, you MUST include @SGX_ENCLAVE_LDADD@ as part
## of the deifniton to make sure you pick up the right linker flags
## and SGX trusted libraries.

EnclaveHash_LDADD = @SGX_ENCLAVE_LDADD@


## Place any additional trusted libraries that your enclave may need in
## SGX_EXTRA_TLIBS. This will ensure they get place inside the 
## --startgroup and --endgroup flags. (This would be where you'd add
## SGXSSL, e.g. -lsgx_tcrypto)

SGX_EXTRA_TLIBS=


# This line is OPTIONAL, and comes with a WARNING.
#
# In general, you shouldn't need to use the program-specific LDFLAGS
# instead of AM_LDFLAGS. But, if you need to, then you'll need to ensure
# @SGX_ENCLAVE_LDFLAGS@ is included in the definition as this will 
# override AM_LDFLAGS.
#
# EnclaveHash_LDFLAGS = @SGX_ENCLAVE_LDFLAGS@
#

