# SGX_ADD_ENCLAVES(ENCLAVES, [ENCLAVE PARENT DIRECTORY=.])
# ------------------
AC_DEFUN([SGX_ADD_ENCLAVES], [
	AS_IF([test "x$2" = "x"],
		[
			AS_VAR_APPEND([SGX_ENCLAVES], m4_map_args_w($[1],[],[],[\ ]))
			AC_CONFIG_FILES(m4_map_args_w($[1],[],[/Makefile],[ ]))
		],
		[
			AS_VAR_APPEND([SGX_ENCLAVES], m4_map_args_w($[1],$[2]/,[],[\ ]))
			AC_CONFIG_FILES(m4_map_args_w($[1],[$[2]/],[/Makefile],[ ]))
		]
	)
	AC_SUBST(SGX_ENCLAVES)
	AC_CONFIG_FILES([sgx_enclave.mk])
])

