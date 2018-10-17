AC_INIT(sgx-autotools, 1.0, john.p.mechalas@intel.com)

AC_CONFIG_MACRO_DIRS([m4])
AM_INIT_AUTOMAKE([foreign])

AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP
AM_PROG_CC_C_O

SGX_INIT()

SGX_TSTDC_CHECK_HEADERS_PREFIX([stdio.h])
SGX_TSTDC_CHECK_FUNCS_PREFIX([fprintf])

AC_CONFIG_HEADERS([config.h])
AC_CONFIG_FILES([Makefile EnclaveHash/Makefile])

AC_OUTPUT()

