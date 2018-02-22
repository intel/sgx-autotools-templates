AC_DEFUN([SGX_INIT_OPTIONAL],[

	AC_ARG_ENABLE([sgx],
		[AS_HELP_STRING([--enable-sgx],
			[Build with/without Intel SGX support (default: disabled)])
		], [sgxenable=${enableval}], [sgxenable=no])

	SGX_INIT()
])

