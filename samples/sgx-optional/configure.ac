AC_INIT(sgx-autotools, 1.0, john.p.mechalas@intel.com)

AC_CONFIG_MACRO_DIRS([m4])
AM_INIT_AUTOMAKE([foreign])

AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP
AM_PROG_CC_C_O

SGX_INIT_OPTIONAL()

AS_IF([test "x$ac_cv_enable_sgx" = "xyes"], [
	AC_CONFIG_FILES([EnclaveHash/Makefile])
	AC_DEFINE(HAVE_SGX, 1, [Build with SGX support])
],[
	dnl AC_MSG_CHECKING([openssl])
	AC_CHECK_HEADER([openssl/sha.h], [], [
		AC_MSG_FAILURE([OpenSSL headers required for non-SGX builds])
	])
	AC_SEARCH_LIBS([SHA256], [crypto], [], [
		AC_MSG_FAILURE([libcrypto required for non-SGX builds])
	])
])
AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile])

AC_OUTPUT()

