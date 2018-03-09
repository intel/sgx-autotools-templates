# SGX_TSTDC_CHECK_TYPE_PREFIX([TYPE], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ----------------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_TYPE_PREFIX], [
]) # SGX_TSTDC_CHECK_TYPE_PREFIX


# SGX_TSTDC_CHECK_TYPES_PREFIX([TYPES], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ----------------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_TYPES_PREFIX], [
]) # SGX_TSTDC_CHECK_TYPES_PREIFX



# SGX_TSTDC_CHECK_DECL_PREFIX([SYMBOL], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_DECL_PREFIX], [
]) # SGX_TSTDC_CHECK_DECL_PREFIX


# SGX_TSTDC_CHECK_DECLS_PREFIX([SYMBOLS], [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND], [INCLUDES])
# ------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_DECLS_PREFIX], [
]) # SGX_TSTDC_CHECK_DECLS_PREFIX


# SGX_TSTDC_CHECK_DECLS_ONCE_PREFIX([SYMBOLS])
# -------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_DECLS_ONCE_PREFIX], [
]) # SGX_TSTDC_CHECK_DECLS_PREFIX


# SGX_TSTDC_CHECK_HEADER_PREFIX(HEADER, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
# Works like SGX_TSTDC_CHECK_HEADER, only assigns a prefix of "tstdc_" to
# the cache variable and "TSTDC_" to the CPP define (HAVE_TSTDC_x).
AC_DEFUN([SGX_TSTDC_CHECK_HEADER_PREFIX], [
	header=AS_TR_SH([$1])
	AS_VAR_SET_IF([ac_cv_header_$header], [
		AS_VAR_COPY([o_ac_cv_header_$header],[ac_cv_header_$header])
		AS_UNSET([ac_cv_header_$header])
	])
	SGX_TSTDC_CHECK_HEADER([$1], [$2], [$3])
	AS_VAR_COPY([ac_cv_tstdc_header_$header],[ac_cv_header_$header])
	AS_VAR_SET_IF([o_ac_cv_header_$header], [
		AS_VAR_COPY([ac_cv_header_$header],[o_ac_cv_header_$header])
		AS_UNSET([o_ac_cv_header_$header])
	],[
		AS_UNSET([ac_cv_header_$header])
	])
	AH_TEMPLATE(AS_TR_CPP([HAVE_TSTDC_$1]),
		[Define to 1 if Intel SGX has the <$1> header file.])
	AC_DEFINE(AS_TR_CPP([HAVE_TSTDC_$1]), 1)
]) # SGX_TSTDC_CHECK_HEADER_PREFIX


# SGX_TSTDC_CHECK_HEADERS_PREFIX(HEADER, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
# Works like SGX_TSTDC_CHECK_HEADERS, only assigns a prefix of "tstdc_" to
# the cache variable and "TSTDC_" to the CPP define (HAVE_TSTDC_x).
AC_DEFUN([SGX_TSTDC_CHECK_HEADERS_PREFIX], [
	m4_foreach_w([SGX_Header], [$1], [
		SGX_TSTDC_CHECK_HEADER_PREFIX(m4_defn([SGX_Header]), [$2], [$3])
	])
]) # SGX_TSTDC_CHECK_HEADERS_PREFIX


# SGX_TSTDC_CHECK_FUNC_PREFIX(FUNCTION, [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_FUNC_PREFIX], [
	func=AS_TR_SH([$1])
	AS_VAR_SET_IF([ac_cv_func_$func], [
		AS_VAR_COPY([o_ac_cv_func_$func],[ac_cv_func_$func])
		AS_UNSET([ac_cv_func_$func])
	])
	SGX_TSTDC_CHECK_FUNC([$1], [$2], [$3])
	AS_VAR_COPY([ac_cv_tstdc_func_$func],[ac_cv_func_$func])
	AS_VAR_SET_IF([o_ac_cv_func_$func], [
		AS_VAR_COPY([ac_cv_func_$func],[o_ac_cv_func_$func])
		AS_UNSET([o_ac_cv_func_$func])
	],[
		AS_UNSET([ac_cv_func_$func])
	])
	AC_DEFINE(AS_TR_CPP([HAVE_TSTDC_$1]), 1)
]) # SGX_TSTDC_CHECK_FUNC_PREFIX


# SGX_TSTDC_CHECK_FUNCS_PREFIX(FUNCTION..., [ACTION-IF-FOUND], [ACTION-IF-NOT-FOUND])
# ----------------------------------------------------------------------------
AC_DEFUN([SGX_TSTDC_CHECK_FUNCS_PREFIX], [
	m4_foreach_w([SGX_Func], [$1], [
		SGX_TSTDC_CHECK_FUNC_PREFIX(m4_defn([SGX_Func]), [$2], [$3])
	])
]) # SGX_TSTDC_CHECK_FUNCS_PREFIX

