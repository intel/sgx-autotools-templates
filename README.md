# Intel SGX Autotools Config

The files in this package provide convenience macros and definitions
to integrate Intel Software Guard Extensions (Intel SGX) projects into
the GNU build system. It includes the following.

M4 Macro files:
```
  sgx_init.m4
  sgx_init_optional.m4
```

Automake includes:
```
  sgx_app.am
  sgx_enclave.am
  sgx_tlib.am
```

In addition to these template files, two sample projects has been provided
that demonstrate their usage. One shows integration for a project that
requires Intel SGX, and the other for a project where Intel SGX support
is a compile-time option.


## M4 Macros 

The M4 macro files define the following functions for use in GNU Autoconf
configure.ac files:

| File        | Macro    |
| ----------- | -------- |
| sgx_init.m4 | SGX_INIT |
| sgx_init_optional.m4 | SGX_INIT_OPTIONAL |

You should invoke either **SGX_INIT** or **SGX_INIT_OPTIONAL**. Do not call 
both.

### SGX_INIT

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

  --with-sgxssl=path      Set the path to your Intel SGX SSL directory
                          (defaults to /opt/intel/sgxssl)

  --with-sgxsdk=path      Set the path to your Intel SGX SDK directory
                          (defaults to auto-detection)
```


* Determines whether or not Intel SGX support should be enabled in the build. 

    * If **SGX_INIT** was invoked directly from configure.ac, then Intel SGX
 support is enabled.

    * If **SGX_INIT_OPTIONAL** was invoked instead, then Intel SGX support is
 enabled if and only if `--enable-sgx` was provided on the command line.

* Defines the C preprocessor symbol **HAVE_SGX** if Intel SGX support
   is enabled. Otherwise, it is left undefined.

* Sets Automake conditionals.

* Attempts to discover the location of the Intel SGX SDK using the following
procedure:

    1. If `--with-sgxsdk-path=path` is provided, use that path.

    2. If the **$SGX_SDK** enviornment variable is set, use that path.

    3. Look in the following directories (in this order):

        1) `/opt/intel/sgxsdk`

        2) `$HOME/sgxsdk`

        3) `./sgxsdk`

* Sets Makefile substitution variables.

### SGX_INIT_OPTIONAL

This macro adds a configuration option to enable SGX support in projects
at build time. It is intended for packages where Intel SGX is not required,
and thus provided as a configuration option prior to compilation. Intel
SGX support is _disabled_ by default. 

It takes the following actions:

* Adds a command line argument to enable SGX support in the build.

```
      --enable-sgx        Build with/without Intel SGX support (default: disabled)
```


* Defines the following cache variable, which is set to either "yes" or
  "no". This variable can be tested in configure.ac in order to modify 
  the final build configuration.

```
       $ac_cv_enable_sgx 
```


* Invokes the **SGX_INIT** macro.

---

## Makefile substitution variables

**Intel SGX SDK paths**
```
        SGXSDK
        SGXSDK_BINDIR
        SGXSDK_INCDIR
        SGXSDK_LIBDIR
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

**Flags for compiling and linking an Intel SGX enclave**
```
		SGX_ENCLAVE_CFLAGS
		SGX_ENCLAVE_CPPFLAGS
		SGX_ENCLAVE_CXXFLAGS
		SGX_ENCLAVE_LDFLAGS
		SGX_ENCLAVE_LDADD
```

**Flags for compiling an Intel SGX trusted library**
```
		SGX_TLIB_CFLAGS
		SGX_TLIB_CPPFLAGS
		SGX_TLIB_CXXFLAGS
```

**Trusted runtime library names (to support h/w and simulation modes)**
```
		SGX_TRTS_LIB
		SGX_TSERVICE_LIB
```

**Untrusted runtime library names (to support h/w and simulation modes)**
```
		SGX_UAE_SERVICE_LIB
		SGX_URTS_LIB
```

**Indicating use of Intel SGX simulation mode**
```
		SGX_HW_SIM
```

---

## Automake Conditionals

**SGX_ENABLED**

  Set to 1 if the build should utilize Intel SGX, and 0 if it should not.


**SGX_HW_SIM**

  Set to 1 if the final application should use Intel SGX in simulation
  mode (via `--enable-sgx-simulation`)


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

AS_IF([test "x$ac_cv_enable_sgx" = "xyes"], [
	AC_CONFIG_FILES([Enclave/Makefile])
	AC_DEFINE(HAVE_SGX, 1, [Build with SGX support])
],[
	dnl Actions to take if Intel SGX is not compiled in
]
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

If you need to include additional trusted libraries to build your enclave,
add the linker flags (`-lsomelib`) to **SGX_EXTRA_TLIBS**. This Makefile
variable gets substituted into the final link command line in order
to include it in the library list between the `--start-group` and
`--end-group` flags.  Do not use **target_LDADD** for this purpose.

A pattern rule exists to create the proxy routines from your EDL file,
but you'll need to add them to the _SOURCES target manually. For example,
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

