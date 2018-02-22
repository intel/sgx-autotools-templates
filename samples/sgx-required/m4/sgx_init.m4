AC_DEFUN([SGX_INIT],[
	AC_ARG_WITH([enclave-libdir],
		[AS_HELP_STRING([--with-enclave-libdir=path],
			[Set the directory where enclave libraries should be installed (default: EPREFIX/libexec)])
		], [enclave_libdir=$withval],
			[enclave_libdir=\$\{exec_prefix\}/libexec])

	AC_ARG_ENABLE([sgx-simulation],
		[AS_HELP_STRING([--enable-sgx-simulation],
			[Use Intel SGX in simulation mode. Implies --enable-sgx (default: disabled)])
		], [
			sgxenable=yes
			sgxsim=${enableval}
		], [sgxsim=no])

	AC_ARG_WITH([sgx-build],
		[AS_HELP_STRING([--with-sgx-build=debug|prerelease|release],
			[Set Intel SGX build mode (default: debug)])
		], [_sgxbuild=$withval], [_sgxbuild=debug])

	AC_ARG_WITH([sgxssl],
		[AS_HELP_STRING([--with-sgxssl=path],
			[Set the path to your Intel SGX SSL directory (defaults to /opt/intel/sgxssl)])
		], [SGXSSL=$withval],[SGXSSL=/opt/intel/sgxssl])

	AC_ARG_WITH([sgxsdk],
		[AS_HELP_STRING([--with-sgxsdk=path],
			[Set the path to your Intel SGX SDK directory (defaults to auto-detection)])
		], [SGXSDK=$withval],[SGXSDK="detect"])

	AM_CONDITIONAL([ENABLE_SGX], [test "x$sgenable" != "xno"])

	AS_IF([test "x$sgxenable" != "xno" ], [

	AS_IF([test "x$sgxsim" = "xyes"], [
			AC_SUBST(SGX_TRTS_LIB, [sgx_trts_sim])
			AC_SUBST(SGX_TSERVICE_LIB, [sgx_tservice_sim])
			AC_SUBST(SGX_UAE_SERVICE_LIB, [sgx_uae_service_sim])
			AC_SUBST(SGX_URTS_LIB, [sgx_urts_sim])
			AC_SUBST(LIBS_HW_SIMU, ["-lsgx_urts_sim -lsgx_uae_service_sim"])
			SGX_HW_SIM=1
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

	AS_IF([test "x$SGXSDK" = "xenv"], [],
		[test "x$SGXSDK" != "xdetect"], [],
		[test -d /opt/intel/sgxsdk], [SGXSDK=/opt/intel/sgxsdk],
		[test -d ~/sgxsdk], [SGXSDK=~/sgxsdk],
		[test -d ./sgxsdk], [SGXSDK=./sgxsdk],
		[AC_MSG_ERROR([Can't detect your Intel SGX SDK installation directory])])
	AS_IF([test -d $SGXSDK/lib], [AC_SUBST(SGXSDK_LIBDIR, $SGXSDK/lib)],
       		[test -d $SGXSDK/lib64], [AC_SUBST(SGXSDK_LIBDIR, $SGXSDK/lib64)],
       		[AC_MSG_ERROR(Can't find Intel SGX SDK lib directory)])
	AS_IF([test -d $SGXSDK/bin/ia32], [AC_SUBST(SGXSDK_BINDIR, $SGXSDK/bin/ia32)],
       		[test -d $SGXSDK/bin/x64], [AC_SUBST(SGXSDK_BINDIR, $SGXSDK/bin/x64)],
       		[AC_MSG_ERROR(Can't find Intel SGX SDK bin directory)])
	AC_MSG_NOTICE([Found your Intel SGX SDK in $SGXSDK])

	AC_SUBST(enclave_libdir)
	AC_SUBST(SGXSSL_INCDIR, $SGXSSL/include)
	AC_SUBST(SGXSSL_LIBDIR, $SGXSSL/lib64)
	AC_SUBST(SGXSSL)
	AC_SUBST(SGXSDK_INCDIR, $SGXSDK/include)
	AC_SUBST(SGXSDK)
	AC_SUBST(SGX_TLIB_CPPFLAGS, 
		["-I\$(SGXSDK_INCDIR) -I\$(SGXSDK_INCDIR)/tlibc"])
	AC_SUBST(SGX_TLIB_CFLAGS,
	 	["-nostdinc -fvisibility=hidden -fpie -fstack-protector"])
	AC_SUBST(SGX_TLIB_CXXFLAGS,
		["-nostdinc++ -fvisibility=hidden -fpie -fstack-protector"])

	AC_SUBST(SGX_ENCLAVE_CFLAGS,
	 	["-nostdinc -fvisibility=hidden -fpie -ffunction-sections -fdata-sections -fstack-protector"])
	AC_SUBST(SGX_ENCLAVE_CPPFLAGS, 
		["-I\$(SGXSDK_INCDIR) -I\$(SGXSDK_INCDIR)/tlibc"])
	AC_SUBST(SGX_ENCLAVE_CXXFLAGS, ["-nostdinc++ -fvisibility=hidden -fpie -ffunction-sections -fdata-sections -fstack-protector"])
	AC_SUBST(SGX_ENCLAVE_LDFLAGS,
		["-nostdlib -nodefaultlibs -nostartfiles -L\$(SGXSDK_LIBDIR)"])
	AC_SUBST(SGX_ENCLAVE_LDADD,
		["-Wl,--no-undefined -Wl,--whole-archive -l\$(SGX_TRTS_LIB) -Wl,--no-whole-archive -Wl,--start-group \$(SGX_EXTRA_TLIBS) -lsgx_tstdc -lsgx_tcrypto -l\$(SGX_TSERVICE_LIB) -Wl,--end-group -Wl,-Bstatic -Wl,-Bsymbolic -Wl,-pie,-eenclave_entry -Wl,--export-dynamic -Wl,--defsym,__ImageBase=0"])

	AM_CONDITIONAL([ENCLAVE_RELEASE_SIGN], [test "x$_sgxbuild" = "xrelease"])
	AM_CONDITIONAL([SGX_HW_SIM], [test "x$sgxsim" = "xyes"])

	])
])

