# Notice

You are viewing a branch that is in active development. It contains
undocumented features that will change before a final relase, and
has only partial functionality. *Do not use the code in this branch
for critical or production projects.*

# Intel SGX Autotools Config

The files in this package provide convenience macros and definitions
to integrate Intel Software Guard Extensions (Intel SGX) projects into
the GNU build system. It can be used with the following SGX tool kits:

 * [Intel SGX SDK](https://github.com/intel/linux-sgx)
 * [Microsoft\* Open Enclave SDK\*](https://github.com/Microsoft/openenclave), either standalone or as part of [Azure\* Confidential Computing\*](https://azure.microsoft.com/en-us/solutions/confidential-compute/)

It includes the following files.

M4 Macro files:
```
  m4/sgx_config_openenclave.m4
  m4/sgx_config_sgxsdk.m4
  m4/sgx_init.m4
  m4/sgx_init_optional.m4
  m4/sgx_tstdc_check.m4
  m4/sgx_tstdc_check_prefix.m4
```

Automake includes:
```
  build-aux/sgx_app.am
  build-aux/sgx_enclave.am
  build-aux/sgx_tlib.am
```

In addition to these template files, two sample projects has been provided
that demonstrate their usage. One shows integration for a project that
requires Intel SGX, and the other for a project where Intel SGX support
is a compile-time option.


## M4 Macros

The M4 macro files define the following functions for use in GNU Autoconf
configure.ac files:

<table><tbody>
<tr><th> File                   </th><th> Macro                </th></tr>
<tr><td rowspan=2> sgx_init.m4  </td><td> SGX_IF_ENABLED       </td></tr>
<tr>                                 <td> SGX_INIT             </td></tr>
<tr><td>  sgx_init_optional.m4  </td><td> SGX_INIT_OPTIONAL    </td></tr>
<tr><td rowspan=9> sgx_tstdc_check.m4 </td><td> SGX_TSTDC_CHECK_DECL </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_DECLS </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_DECLS_ONCE </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_FUNC       </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_FUNCS      </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_HEADER     </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_HEADERS    </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_TYPE       </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_TYPES      </td></tr>
<tr><td rowspan=9> sgx_tstdc_check_prefix.m4 </td><td> SGX_TSTDC_CHECK_DECL_PREFIX </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_DECLS_PREFIX   </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_DECLS_ONCE_PREFIX </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_FUNC_PREFIX    </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_FUNCS_PREFIX   </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_HEADER_PREFIX  </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_HEADERS_PREFIX </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_TYPE_PREFIX    </td></tr>
<tr>                                 <td> SGX_TSTDC_CHECK_TYPES_PREFIX      </td></tr>
</tbody>
</table>

You should invoke either **SGX_INIT** or **SGX_INIT_OPTIONAL**. Do not call
both.

### SGX_IF_ENABLED

&mdash;Macro: SGX_IF_ENABLED([ _run-if-enabled_ ], [ _run-if-disabled_ ])

If Intel SGX is enabled in the build, then run the shell code
_run-if-enabled_, otherwise run _run-if-disabled_.

Note that "enabled" in this context means: the build _explicitly_
depends on Intel SGX because SGX_INIT was called (see below), or the
user asked for Intel SGX by supplying `--enable-sgx` as an option
to configure in builds where Intel SGX is optional (via the
SGX_INIT_OPTIONAL macro).

This is typically used to indication actions that need to be taken
when software is compiled without Intel SGX support. For example,

```
  SGX_IF_ENABLED([
  	AC_DEFINE(HAVE_SGX, 1, [Build with Intel SGX support])
  ],[
	dnl libcrypto is required if we aren't compiling with Intel SGX support
	AC_CHECK_HEADERS([openssl/sha.h], ,
		[AC_MSG_FAILURE([OpenSSL headers required])])
	AC_CHECK_LIBS([SHA256], [crypto], ,
		[AC_MSG_FAILURE([libcrypto required])])
  ])
```

ensures that the non-Intel SGX build has the necessary libraries, and
defines the symbol `HAVE_SGX` in `config.h`.

### SGX_INIT

&mdash;Macro: SGX_INIT

Set up definitions for a software build that requires the use of Intel SGX.
The project will require that Intel SGX SDK be installed, and configure will
abort if it's not found.

It takes the following actions:

* Adds configuration options to the final 'configure' script:

```
  --enable-sgx-simulation Use Intel SGX in simulation mode.  (default: disabled)

  --with-enclave-libdir=path
                          Set the directory where enclave libraries should be
                          installed (default: EPREFIX/libexec)

  --with-sgx-build=debug|prerelease|release
                          Set Intel SGX build mode (default: debug)

  --with-sgx-toolkit=intel|ms-openenclave
                          Set the SGX tool kit to either the Intel SGX
                          SDK (intel) or Microsoft's Open ENCLAVE
                          (ms-openenclave). (defaults to intel)

  --with-sgxssl=path      Set the path to your Intel SGX SSL directory
                          (defaults to /opt/intel/sgxssl)

  --with-sgxsdk=path      Set the path to your Intel SGX SDK directory
                          (defaults to auto-detection)

  --with-openenclave=path
                          Set the path to your Open Enclave directory
                          (defaults to /opt/openenclave)
```


* Determines whether or not Intel SGX support should be enabled in the build.

    * If **SGX_INIT** was invoked directly from configure.ac, then Intel SGX
 support is enabled.

    * If **SGX_INIT_OPTIONAL** was invoked instead, then Intel SGX support is
 enabled if and only if `--enable-sgx` was provided on the command line.

* Defines the C preprocessor symbol **HAVE_SGX** if Intel SGX support
   is enabled. Otherwise, it is left undefined.

* Sets Automake conditionals.

* If using the Intel SGX SDK, it attempts to discover the location of the SDK using the following
procedure:

    1. If `--with-sgxsdk-path=path` is provided, use that path.

    2. If the **$SGX_SDK** enviornment variable is set, use that path.

    3. Look in the following directories (in this order):

        1) `/opt/intel/sgxsdk`

        2) `$HOME/sgxsdk`

        3) `./sgxsdk`

* Sets Makefile substitution variables.

* Sets cache variables

### SGX_INIT_OPTIONAL

&mdash;Macro: SGX_INIT_OPTIONAL

This macro adds a configuration option to enable SGX support in projects
at build time. It is intended for packages where Intel SGX is not required,
and thus provided as a configuration option prior to compilation. Intel
SGX support is _disabled_ by default.

It takes the following actions:

* Adds a command line argument to enable SGX support in the build.

```
  --enable-sgx        Build with/without Intel SGX support (default: disabled)
```

* Invokes the **SGX_INIT** macro.

### SGX_TSTDC_CHECK_\*

These macros are equivalent to the AC_CHECK_\* macros of the same
name, only they perform their tests on the trusted C library distributed
with the Intel SGX SDK instead of the standard C library.

They are intended to facilite porting static libraries to Intel SGX
trusted libraries: an Intel SGX build should call these functions
instead of the standard ones to ensure it properly detects which
headers and functions are present.

For example, a library intended to offer both a standard and Intel SGX
trusted build might do the following:

```
  SGX_IF_ENABLED([
    SGX_TSTDC_CHECK_HEADERS([fcntl.h float.h locale.h time.h unistd.h wchar.h])
	SGX_TSTDC_CHECK_FUNCS([getpagesize sigaction snprintf sprintf_s vsnprintf sscanf])
  ],[
    AC_CHECK_HEADERS([fcntl.h float.h locale.h time.h unistd.h wchar.h])
	AC_CHECK_FUNCS([getpagesize sigaction snprintf sprintf_s vsnprintf sscanf])
  ])
```

**Warning:** Since these macros call the equivalent AC_CHECK_\* macro,
they will by default define the symbol HAVE_\* for each function found.
When building just a trusted library or enclave this is fine, but if a
common autoconf configuration is used for both _untrusted_ applications
and libaries _and_ trusted ones (enclaves and trusted libraries), then
the untrusted code will have incorrect definitions. These macros also
collide with AC_CHECK_\* since they share the same cache variables.
**Use the SGX_TSTDC_CHECK_\*_PREFIX macros if your autoconfig file is
used to create both trusted and untrusted code.**

### SGX_TSTDC_CHECK_\*_PREFIX

These macros work like SGX_TSTDC_CHECK_\*, only they assign a prefix of
"tstdc_" to cache variables, and "TSTD_C" to precoressor symbols. They
allow you to search for the same symbol name in both trusted and untrusted
libraries. For example,

```
  AC_CHECK_FUNCS([printf snprintf sscanf])
  SGX_TSTDC_CHECK_FUNCS_PREFIX([printf snprintf sscanf])
```

will result in the following output:

```
  checking for printf... yes
  checking for snprintf... yes
  checking for sscanf... yes
  Intel SGX: checking for printf... no
  Intel SGX: checking for snprintf... yes
  Intel SGX: checking for sscanf... no
```

and the following symbol definitions:

```
  #define HAVE_PRINTF 1
  #define HAVE_SNPRINTF 1
  #define HAVE_SSCANF 1
  #define HAVE_TSTDC_PRINTF 0
  #define HAVE_TSTDC_SNPRINTF 1
  #define HAVE_TSTDC_SSCANF 0
```

## Makefile substitution variables

Unless otherwise noted:

 * Variables starting with **SGXSDK\_** and **SGX_** apply to the Intel SGX SDK only.

 * Variables starting with **OE\_** apply to the Open Enclave SDK only.

### Paths

**Intel SGX SDK paths**
```
  SGXSDK
  SGXSDK_BINDIR
  SGXSDK_INCDIR
  SGXSDK_LIBDIR
```

**Open Enclave SDK paths**
```
  OE
  OE_BINDIR
  OE_INCDIR
  OE_LIBDIR
```

**Intel SGX SSL paths**
```
  SGXSSL
  SGXSSL_BINDIR
  SGXSSL_INCDIR
  SGXSSL_LIBDIR
```

**Enclave library installation path**
```
  enclave_libdir
```

### Compilation and Linking

**Flags for compiling and linking an Intel SGX applications**

Note that using the **_LDADD** variables assumes dynamic linking of the runtime libraries is desired.

```
  OE_APP_CFLAGS
  OE_APP_CPPFLAGS
  OE_APP_CXXFLAGS
  OE_APP_LDFLAGS
  OE_APP_LDADD

  SGX_APP_CFLAGS
  SGX_APP_CPPFLAGS
  SGX_APP_CXXFLAGS
  SGX_APP_LDFLAGS
  SGX_APP_LDADD
```

Note the SGX\_APP\_LDADD is defined using SGX\_UAE\_SERVICE\_LIB and
SGX\_URTS\_LIB (see below).

**Trusted runtime library names (to support h/w and simulation modes)**

These apply to Intel SGX SDK applications only, and are needed to
differentiate between hardware and simulation mode versions of
the trusted runtime and trusted service library.

```
  SGX_TRTS_LIB
  SGX_TSERVICE_LIB
```

**Untrusted runtime library names (to support h/w and simulation modes)**

These apply to Intel SGX SDK applications only, and are needed to
differentiate between hardware and simulation mode versions of
the untrusted runtime and untrusted service library.

```
  SGX_UAE_SERVICE_LIB
  SGX_URTS_LIB
```

**Flags for compiling and linking an Intel SGX enclave**
```
  OE_ENCLAVE_CFLAGS
  OE_ENCLAVE_CPPFLAGS
  OE_ENCLAVE_CXXFLAGS
  OE_ENCLAVE_LDFLAGS
  OE_ENCLAVE_LDADD

  SGX_ENCLAVE_CFLAGS
  SGX_ENCLAVE_CPPFLAGS
  SGX_ENCLAVE_CXXFLAGS
  SGX_ENCLAVE_LDFLAGS
  SGX_ENCLAVE_LDADD
```

Note the SGX\_ENCLAVE\_LDADD is defined using SGX\_TAE\_SERVICE\_LIB and
SGX\_TRTS\_LIB (see below).

**Flags for compiling an Intel SGX trusted library**
```
  OE_TLIB_CFLAGS
  OE_TLIB_CPPFLAGS
  OE_TLIB_CXXFLAGS

  SGX_TLIB_CFLAGS
  SGX_TLIB_CPPFLAGS
  SGX_TLIB_CXXFLAGS
```

**Indicating use of Intel SGX simulation mode**

This #define applies to both the Intel SGX SDK and Open Enclave SDK,
though Open Enclave applications can choose to run in simulation mode
at runtime. Simulation mode is a compile-time option for Intel SGX SDK applications.

```
  SGX_HW_SIM
```

---

## Automake Conditionals

**SGX_ENABLED**

  Set to 1 if the build should utilize Intel SGX, and 0 if it should not.

**SGX_WITH_OPENENCLAVE**

  Set to 1 if the project is being built against the Open Enclave SDK.

**SGX_WITH_SGXSDK**

  Set to 1 if the project is being built against the Intel SGX SDK.

**SGX_HW_SIM**

  Set to 1 if the final application should use Intel SGX in simulation
  mode (via `--enable-sgx-simulation`). This is more relevant to the
  Intel SGX SDK, where simulation mode is a compile-time option.

**ENCLAVE_RELEASE_SIGN**

  Set to 1 if the enclave is being built in release mode. This is used
  internally in the automake includes.

---

## Typical usage

### configure.ac

In your `configure.ac` file you call one of either **SGX_INIT** or
**SGX_INIT_OPTIONAL**. _Do not call both_. The former is for software
that must have Intel SGX available in order to _compile_. Generally
this is reserved for cases where the application needs Intel SGX
at runtime in order to function. The latter is for software that
has to run on multiple platforms including those which are not
supported by Intel SGX (including, but not limited to, non-Intel
CPU's).

The **SGX_INIT_OPTIONAL** macro should be followed by **AS_IF** to
check if **$ac_cv_enable_sgx** is set.

```
SGX_INIT_OPTIONAL()

SGX_IF_ENABLED([
	AC_CONFIG_FILES([Enclave/Makefile])
	AC_DEFINE(HAVE_SGX, 1, [Build with SGX support])
],[
	dnl Actions to take if Intel SGX is not compiled in
])
```

### Makefile.am

Automake includes are provided to assist the creation of enclaves,
trusted libraries, and enclave applications.

The samples in this package are generously commented to demonstrate
their usage.

#### Building Enclaves with Automake

Include `sgx_enclave.am` in your Makefile.am to build an enclave. This
should be included before setting any automake variables.

Enclaves are essentially shared objects, but Automake doesn't provide
a convenience definition for building a shared object without using
libtool. Libtool is not an appropriate means of building an Intel SGX
enclave because of assumptions it makes about how shared objects should
be compiled, and it takes away direct control of the compiler and linker
flags.  To solve this problem, Intel SGX enclaves are built using
the libexec_PROGRAM rule with EXEEXT set to ".so" (this rule is defined
in `sgx_enclave.am`).

----

Your Makefile.am must define these three variables:

**ENCLAVE**

  The name of your enclave

**ENCLAVE_CONFIG**

  The name of your enclave configuration file. A simple config file will
  be created for you at build time if you don't have one.

**ENCLAVE_KEY**

  The name of the private key file to use when building and signing _debug
  mode enclaves_. (Release mode enclaves must use a two-step signing
  procedure.) If your application does not have a key then one will be
  randomly generated at build time.

----

##### Intel SGX SDK Note

<blockquote>
If you need to include additional trusted libraries to build your enclave,
add the linker flags (`-lsomelib`) to **SGX_EXTRA_TLIBS**. This Makefile
variable gets substituted into the final link command line in order
to include it in the library list between the `--start-group` and
`--end-group` flags.  Do not use **target_LDADD** for this purpose.
</blockquote>

A pattern rule exists to create the proxy routines from your EDL file,
but you'll need to add them to the **\_SOURCES** target manually. For example,
if your enclave is named MyEnclave, you would say:

```
  myenclave_SOURCES = MyEnclave_t.c MyEnclave_t.h ...
```

This is a requirement of Automake, which needs to know, statically,
which source files are needed by a build target. (Alternatively, you
could define these with the BUILTSOURCES target, but that is a matter
of personal preference.)

You will also need to add the proxy functions to the CLEANFILES target
so they are removed with a `make clean`.

```
  CLEANFILES = MyEnclave_t.c MyEnclave_t.h
```

These are created automatically for you using a pattern rule,

The Automake include also sets flags for the preprocessor, compilers
and linker needed to build the enclave. By default, the Intel SGD SDK
include directory and library directory are added to the preprocessor
and linker search paths.

```
  AM_CPPFLAGS
  AM_CFLAGS
  AM_CXXFLAGS
  AM_LDFLAGS
```

If you need additional flags in your `Makefile.am`, use += to _add_
flags, not replace them. For example:

```
  AM_CXXFLAGS += -std=c++11
```

#### Building Trusted Libraries with Automake

Include `sgx_tlib.am` in your Makefile.am to build a trusted library. This
should be included before setting any automake variables.

A trusted library is just a static library compiled with enclave-specific
flags. Your build target should use the lib_LIBRARIES rule.

```
  lib_LIBRARIES = mytlib.a
  mytlib_a_SOURCES = ...
```

The Automake include also sets flags for the preprocessor and
compilers needed to build the library. By default, the Intel SGD SDK
include directory and library directory are added to the preprocessor
search paths.

```
  AM_CPPFLAGS
  AM_CFLAGS
  AM_CXXFLAGS
```

#### Building Enclave Applications with Automake

Include `sgx_app.am` in your Makefile.am to build an enclave. This
should be included before setting any automake variables.

Enclave applications build like any other application, and should use
the bin_PROGRAMS rule.

```
  bin_PROGRAMS = myapp
```

The untrusted proxy functions automatically generated by edger8r have to
be included in the list of source files, and because Automake must know
the list of source files _statically_ at build time, they have to be
listed explicitly.


```
  myapp_SOURCES = main.c
  nodist_myapp_SOURCES = MyEnclave_u.c MyEnclave_u.h
  BUILT_SOURCES = MyEnclave_u.c MyEnclave_u.h
  CLEANFILES = MyEnclave_u.c MyEnclave_u.h
```

A pattern rule is defined in `sgx_app.am` to make the proxy functions from
the EDL file. That requires the EDL file to be in the build directly. You
can either symlink it in your project directly, or define a rule for
_make_ to do that for you (you'll need to add the symlink to the CLEANFILES
variable if you opt for this approach):

```
  MyEnclave.edl: MyEnclave/MyEnclave.edl
      ln -s $?

  CLEANFILES = MyEnclave_u.c MyEnclave_u.h MyEnclave.edl
```

The Automake include also sets flags for the preprocessor and linker
that are needed to build an enclave application. The Intel SGD SDK
include directory and library directory are added to the preprocessor
and linker search paths.

```
  AM_CPPFLAGS
  AM_LDFLAGS
```

Linking the runtime libraries must be done using the per-target LDADD
variable (e.g. `myapp_LDADD`). This is so the Makefile can create
applicatoons both with and without SGX support. Setting Thesevalues in the
global AM_LDADD would force all applications to link against the untruste
runtime libraries.

These libraries depend on the SDK being used, so this would typically be
wrapped in a conditional:

```
if SGX_WITH_SGXSDK
  myapp_LDADD=$(SGX_LDADD)
else
  myapp_LDADD=$(OE_APP_LDADD)
endif
```

----
## Samples

Two code samples are included to demonstrate how these templates can be
used to build an Intel SGX application. Both samples build the same
application: a program that takes a secret from the command line,
stashes it in its secret "store", and returns a hash of the secret to
be printed to STDOUT.

These samples are independent of one another, so each must be built
separately.

```
   $ ./bootstrap
   $ ./configure
   $ make
```

**Note that these builds _do not_ place the signed enclave in the same
directory as the application binary**, so you'll either need to set
LD_LIBRARY_PATH or copy them manually.

### samples/sgx-required

This build of the _storesecret_ application requires Intel SGX. It can
be built to run in simulation mode on non-Intel SGX hardware, though
simulation mode will not provide any hardware protection.

### samples/sgx-optional

This build of _storesecret_ does not require the Intel SGX SDK. By
default, it does not use Intel SGX and it stores its secret insecurely
in main memory.

If Intel SGX is enabled by supplying `--enable-sgx` to _configure_ the
build will use Intel SGX. It can also be built in simulation mode
via `--enable-sgx-simulation` though of course simulation mode does not
provide any hardware protection.
