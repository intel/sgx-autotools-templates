AC_INIT(sgx-autotools, 1.0, john.p.mechalas@intel.com)

AC_CONFIG_MACRO_DIRS([m4])
AM_INIT_AUTOMAKE([foreign])

AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP
AM_PROG_CC_C_O

SGX_INIT_OPTIONAL()

SGX_IF_ENABLED([
	AC_DEFINE(HAVE_SGX, 1, [Build with SGX support])
],[
	AC_CHECK_HEADER([openssl/sha.h], [], [
		AC_MSG_FAILURE([OpenSSL headers required for non-SGX builds])
	])
	AC_SEARCH_LIBS([SHA256], [crypto], [], [
		AC_MSG_FAILURE([libcrypto required for non-SGX builds])
	])
])
AC_CONFIG_HEADERS([config.h])

dnl  EnclaveHash/Makefile has to be here for 'make dist', 'make distclean'
dnl  and 'make maintainer-clean' to work, even if SGX is disabled. The
dnl  conditional in Makefile.am takes care of whether or not to include
dnl  it in the build.

AC_CONFIG_FILES([Makefile EnclaveHash/Makefile])

AC_OUTPUT()

