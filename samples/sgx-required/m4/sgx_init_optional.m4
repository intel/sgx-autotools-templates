# SGX_INIT_OPTIONAL
# -----------------------------------
# Initialize automake/autoconf with Intel SGX build options.
# Calling this macro from configure.ac will make SGX support
# a build configuration option (--enable-sgx)
# -----------------------------------
AC_DEFUN([SGX_INIT_OPTIONAL],[

	AC_ARG_ENABLE([sgx],
		[AS_HELP_STRING([--enable-sgx],
			[Build with/without Intel SGX support (default: disabled)])
		], [sgxenable=${enableval}], [sgxenable=no])

	SGX_INIT()
])

