# SGX_TSTDC_CHECK_DECL([SYMBOL], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ------------------------------------------------------------------------
# Works like AC_CHECK_DECL only it looks for headers in the 
# SGX trusted C headers, not in the standard C library headers.
# We do this by saving the old compiler and preprocessor flags
# and replacing them with the flags used to compile a trusted
# library.
AC_DEFUN([SGX_TSTDC_CHECK_DECL], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_HEADER_SET_FLAGS
		AC_CHECK_DECL([$1],[$2],[$3],[$4])
		_SGX_TSTDC_CHECK_HEADER_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_DECL] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_DECL

# SGX_TSTDC_CHECK_DECLS([SYMBOL], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ------------------------------------------------------------------------
# Works like AC_CHECK_DECLS only it looks for headers in the 
# SGX trusted C headers, not in the standard C library headers.
# See SGX_TSTDC_CHECK_DECL
AC_DEFUN([SGX_TSTDC_CHECK_DECLS], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_HEADER_SET_FLAGS
		AC_CHECK_DECLS([$1],[$2],[$3],[$4])
		_SGX_TSTDC_CHECK_HEADER_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_DECLS] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_DECLS


# SGX_TSTDC_CHECK_HEADER(HEADER, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
# Works like AC_CHECK_HEADER only it looks for headers in the 
# SGX trusted C headers, not in the standard C library headers.
# We do this by saving the old compiler and preprocessor flags
# and replacing them with the flags used to compile a trusted
# library.
AC_DEFUN([SGX_TSTDC_CHECK_HEADER], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_HEADER_SET_FLAGS
		AC_CHECK_HEADER([$1],[$2],[$3])
		_SGX_TSTDC_CHECK_HEADER_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_HEADER] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_HEADER

# SGX_TSTDC_CHECK_HEADERS(HEADER, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
# Works like AC_CHECK_HEADERS only it looks for headers in the 
# SGX trusted C headers, not in the standard C library headers.
# See SGX_TSTDC_CHECK_HEADER
AC_DEFUN([SGX_TSTDC_CHECK_HEADERS], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_HEADER_SET_FLAGS
		AC_CHECK_HEADERS([$1],[$2],[$3])
		_SGX_TSTDC_CHECK_HEADER_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_HEADERS] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_HEADERS


# SGX_TSTDC_CHECK_FUNC(FUNCTION, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
# Works like AC_CHECK_FUNC only it looks for the function in the 
# SGX trusted C runtime library, not the standard C library. We do
# this by saving the old compiler flags and replacing them with the
# arguments needed for building a trusted library. We do the same 
# with the linker flags, only we use some of the flags needed to 
# create an enclave. We don't have to go all the way to creating
# an enclave, however: it's enough to produce an object file with
# --no-undefined that links against sgx_tstdc.
AC_DEFUN([SGX_TSTDC_CHECK_FUNC], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_FUNC_SET_FLAGS
		AC_CHECK_FUNC([$1],[$2],[$3])
		_SGX_TSTDC_CHECK_FUNC_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_FUNC] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_FUNC

# SGX_TSTDC_CHECK_FUNCS(FUNCTION..., [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ----------------------------------------------------------------------------
# Works like AC_CHECK_FUNCS only it looks for the functions in the 
# SGX trusted runtime libraries, not the standard C library. See
# SGX_TSTDC_CHECK_FUNC.
AC_DEFUN([SGX_TSTDC_CHECK_FUNCS], [
	AS_IF([test "x${ac_cv_enable_sgx}" = "xyes"],[
		_SGX_TSTDC_CHECK_FUNC_SET_FLAGS
		AC_CHECK_FUNCS([$1],[$2],[$3])
		_SGX_TSTDC_CHECK_FUNC_RESTORE_FLAGS
	],[
		AC_MSG_ERROR([Tried to call [SGX_TRTS_CHECK_FUNCS] on build without Intel SGX])
	])
]) # SGX_TSTDC_CHECK_FUNCS

AC_DEFUN([_SGX_TSTDC_CHECK_HEADER_SET_FLAGS],[
		old_CFLAGS="$CFLAGS"
		old_CPPFLAGS="$CPPFLAGS"
		old_CXXFLAGS="$CXXFLAGS"
		CFLAGS="${ac_cv_sgx_tlib_cflags}"
		CPPFLAGS="-nostdinc -nostdinc++ ${ac_cv_sgx_tlib_cppflags}"
		CXXFLAGS="${ac_cv_sgx_tlib_cxxflags}"
])

AC_DEFUN([_SGX_TSTDC_CHECK_HEADER_RESTORE_FLAGS],[
		CFLAGS="${old_CFLAGS}"
		CPPFLAGS="${old_CPPFLAGS}"
		CXXFLAGS="${old_CXXFLAGS}"
])

AC_DEFUN([_SGX_TSTDC_CHECK_FUNC_SET_FLAGS],[
		old_CFLAGS="$CFLAGS"
		old_CPPFLAGS="$CPPFLAGS"
		old_CXXFLAGS="$CXXFLAGS"
		old_LDFLAGS="$LDFLAGS"
		old_LIBS="$LIBS"
		CFLAGS="${ac_cv_sgx_tlib_cflags}"
		CPPFLAGS="${ac_cv_sgx_tlib_cppflags}"
		CXXFLAGS="${ac_cv_sgx_tlib_cxxflags}"
		dnl We have to do thiese a litte differently to ensure a clean
		dnl link. Remember, we are just trying to ensure the symbol
		dnl is found, not produce a usable object.
		LDFLAGS="${ac_cv_sgx_enclave_ldflags} -Wl,--defsym,__intel_security_check_cookie=0 -Wl,--defsym,__intel_security_cookie=0 -Wl,--defsym,abort=0 -Wl,--defsym,get_errno_addr=0 -Wl,--no-undefined"
		LIBS="-Wl,--no-undefined -Wl,--start-group -lsgx_tstdc"
])

AC_DEFUN([_SGX_TSTDC_CHECK_FUNC_RESTORE_FLAGS],[
		CFLAGS="${old_CFLAGS}"
		CPPFLAGS="${old_CPPFLAGS}"
		CXXFLAGS="${old_CXXFLAGS}"
		LDFLAGS="${old_LDFLAGS}"
		LIBS="${old_LIBS}"
])
