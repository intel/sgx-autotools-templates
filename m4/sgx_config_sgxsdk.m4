# SGX_CONFIG_SGXSDK()
# -------------------
# Configure the SGX build for the Intel SGX SDK. This macro should not
# be called directly. It's invoked by SGX_INIT.
AC_DEFUN([SGX_CONFIG_SGXSDK],[
	AC_DEFINE([SGX_HAVE_SGXSDK], 1,
		[Define if building for SGX with the Intel SGX SDK])
	AS_IF([test "x$sgxsim" = "xyes"], [
			AC_SUBST(SGX_TRTS_LIB, [sgx_trts_sim])
			AC_SUBST(SGX_TSERVICE_LIB, [sgx_tservice_sim])
			AC_SUBST(SGX_UAE_SERVICE_LIB, [sgx_uae_service_sim])
			AC_SUBST(SGX_URTS_LIB, [sgx_urts_sim])
			AC_SUBST(LIBS_HW_SIMU, ["-lsgx_urts_sim -lsgx_uae_service_sim"])
			AC_DEFINE(SGX_HW_SIM, 1, [Enable hardware simulation mode])
		], [
			AC_SUBST(SGX_TRTS_LIB, [sgx_trts])
			AC_SUBST(SGX_TSERVICE_LIB, [sgx_tservice])
			AC_SUBST(SGX_UAE_SERVICE_LIB, [sgx_uae_service])
			AC_SUBST(SGX_URTS_LIB, [sgx_urts])
		]
	)
	AS_IF([test "x$_sgxbuild" = "xdebug"], [
			AC_DEFINE(DEBUG, 1, [Enable debugging])
			AC_SUBST(ENCLAVE_SIGN_TARGET, [signed_enclave_dev])
		],
		[test "x$_sgxbuild" = "xprerelease"], [
			AC_DEFINE(NDEBUG, 1, [Flag set for prerelease and release builds])
			AC_DEFINE(EDEBUG, 1, [Flag set for prerelease builds])
			AC_SUBST(ENCLAVE_SIGN_TARGET, [signed_enclave_dev])
		],
		[test "x$_sgxbuild" = "xrelease"], [
			AS_IF(test "x$_sgxsim" = "xyes", [
				AC_MSG_ERROR([Can't build in both release and simulation mode])
			],
			[
				AC_DEFINE(NDEBUG, 1)
				AC_SUBST(ENCLAVE_SIGN_TARGET, [signed_enclave_rel])
			])
		],
		[AC_MSG_ERROR([Unknown build mode $_sgxbuild])]
	)
	AC_SUBST(SGX_DEBUG_FLAGS, [$_sgxdebug])
	AS_IF([test "x$SGX_SDK" = "x"], [SGXSDK=detect], [SGXSDK=env])

	AS_IF([test "x$SGXSDK" = "xenv"], [SGXSDK=$SGX_SDK],
		[test "x$SGXSDK" != "xdetect"], [],
		[test -d /opt/intel/sgxsdk], [SGXSDK=/opt/intel/sgxsdk],
		[test -d ~/sgxsdk], [SGXSDK=~/sgxsdk],
		[test -d ./sgxsdk], [SGXSDK=./sgxsdk],
		[AC_MSG_ERROR([Can't detect your Intel SGX SDK installation directory])])

	AC_SUBST(SGXSDK)
	AC_SUBST(SGXSDK_INCDIR, $SGXSDK/include)

	ac_cv_sgx_sdk=$SGXSDK
	ac_cv_sgx_sdk_incdir=$SGXSDK/include

	AS_IF([test -d $SGXSDK/lib], [
		AC_SUBST(SGXSDK_LIBDIR, $SGXSDK/lib)
		ac_cv_sgx_sdk_libdir=$SGXSDK/lib
	], [test -d $SGXSDK/lib64], [
		AC_SUBST(SGXSDK_LIBDIR, $SGXSDK/lib64)
		ac_cv_sgx_sdk_libdir=$SGXSDK/lib64
	], [
		AC_MSG_ERROR(Can't find Intel SGX SDK lib directory)
	])

	AS_IF([test -d $SGXSDK/bin/ia32], [
		ac_cv_sgx_sdk_bindir=$SGXSDK/bin
		AC_SUBST(SGXSDK_BINDIR, $SGXSDK/bin/ia32)
	], [test -d $SGXSDK/bin/x64], [
		ac_cv_sgx_sdk_bindir=$SGXSDK/bin/x64
		AC_SUBST(SGXSDK_BINDIR, $SGXSDK/bin/x64)
	], [
		AC_MSG_ERROR(Can't find Intel SGX SDK bin directory)
	])

	AC_MSG_NOTICE([found Intel SGX SDK in $SGXSDK])

	dnl These are not quite the same as the Makefile substitution variables.
	dnl They are set in a manner to allow autoconf to use them when running
	dnl a compiler or linker for things like header and function checks.

	ac_cv_sgx_tlib_cflags="-nostdinc -fvisibility=hidden -fpie -fstack-protector"
	ac_cv_sgx_tlib_cppflags="-I${ac_cv_sgx_sdk_incdir} -I${ac_cv_sgx_sdk_incdir}/tlibc"
	ac_cv_sgx_tlib_cxxflags="-nostdinc++ -fvisibility=hidden -fpie -fstack-protector"

	ac_cv_sgx_enclave_ldflags="-nostdlib -nodefaultlibs -nostartfiles -L${ac_cv_sgx_sdk_libdir}"
	ac_cv_sgx_enclave_ldadd="-Wl,--no-undefined -Wl,--whole-archive -lsgx_trts -Wl,--no-whole-archive -Wl,--start-group -lsgx_tstdc -lsgx_tcrypto -lsgx_tservice_lib -Wl,--end-group -Wl,-Bstatic -Wl,-Bsymbolic -Wl,-pie,-eenclave_entry -Wl,--export-dynamic -Wl,--defsym,__ImageBase=0"


	dnl Substitutions for building a trusted library

	AC_SUBST(SGX_TLIB_CFLAGS,
		["-nostdinc -fvisibility=hidden -fpie -fstack-protector"])
	AC_SUBST(SGX_TLIB_CPPFLAGS,
		["-I\$(SGXSDK_INCDIR) -I\$(SGXSDK_INCDIR)/tlibc"])
	AC_SUBST(SGX_TLIB_CXXFLAGS,
		["-nostdinc++ -fvisibility=hidden -fpie -fstack-protector"])

	dnl Substitutions for building an enclave

	AC_SUBST(SGX_ENCLAVE_CFLAGS,
	 	["-nostdinc -fvisibility=hidden -fpie -ffunction-sections -fdata-sections -fstack-protector"])
	AC_SUBST(SGX_ENCLAVE_CPPFLAGS, 
		["-I\$(SGXSDK_INCDIR) -I\$(SGXSDK_INCDIR)/tlibc"])
	AC_SUBST(SGX_ENCLAVE_CXXFLAGS, ["-nostdinc++ -fvisibility=hidden -fpie -ffunction-sections -fdata-sections -fstack-protector"])
	AC_SUBST(SGX_ENCLAVE_LDFLAGS,
		["-nostdlib -nodefaultlibs -nostartfiles -L\$(SGXSDK_LIBDIR)"])
	AC_SUBST(SGX_ENCLAVE_LDADD,
		["-Wl,--no-undefined -Wl,--whole-archive -l\$(SGX_TRTS_LIB) -Wl,--no-whole-archive -Wl,--start-group \$(SGX_EXTRA_TLIBS) -lsgx_tstdc -lsgx_tcrypto -l\$(SGX_TSERVICE_LIB) -Wl,--end-group -Wl,-Bstatic -Wl,-Bsymbolic -Wl,-pie,-eenclave_entry -Wl,--export-dynamic -Wl,--defsym,__ImageBase=0"])

	])

	AC_MSG_NOTICE([enabling SGX build using the SGX SDK... ${ac_cv_enable_sgx}])
])

