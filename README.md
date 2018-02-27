
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

The M$ macro files define the following functions for use in GNU Autoconf
configure.ac files:

| File        | Macro    |
| ----------- | -------- |
| sgx_init.m4 | SGX_INIT |
| sgx_init_optional.m4 | SGX_INIT_OPTIONAL |

You should invoke either **SGX_INIT** or **SGX_INIT_OPTIONAL**. Do not call 
both.

### SGX_INIT

Set up definitions for a software build that depends on Intel SGX.
The project will require the Intel SGX SDK and configure will 
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

* Defines the C preprocessor symbol HAVE_SGX if Intel SGX support
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

* If Intel SGX support is enabled, sets Makefile substitution variables.

### SGX_INIT_OPTIONAL

This macro adds a configuration option to specifically enable SGX support
in the software project at build time, and SGX support is disabled by
default. It is intended for packages where Intel SGX is not required,
and should be a configuration option prior to compilation. 

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


* Invokes the **SGX_INIT** macro

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

> Set to 1 if the build should utilize Intel SGX, and 0 if it should not.

**SGX_HW_SIM**

> Set to 1 if the final application should use Intel SGX in simulation
> mode (via `--enable-sgx-simulation`)

**ENCLAVE_RELEASE_SIGN**

> Set to 1 if the enclave is being built in release mode. This is used
> internally in the automake includes.

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

#### Building Enclaves

Include `sgx_enclave.am` in your Makefile.am to build an enclave. This
should be included before setting any automake variables.

Enclaves are essentially shared objects, but Automake doesn't provide
a convenience definition for building a shared object without using
libtool. Libtool is not an appropriate means of building an Intel SGX
enclave because of assumptions it makes about how shared objects should
be compiled, and it takes away direct control of the compiler and linker
flags.  To solve this problem, Intel SGX enclaves are built using
the PROGRAM rules with EXEEXT set to ".so".

Your Makefile.am will have to define some key variables:

**ENCLAVE**

> The name of your enclave

**ENCLAVE_CONFIG**

> The name of your enclave configuration file. A simple config file will 
> be created for you at build time if you don't have one.

**ENCLAVE_KEY**

> The name of the private key file to use when building and signing _debug
> mode enclaves_. (Release mode enclaves must use a two-step signing 
> procedure.)

If you need to include additional trusted libraries to build your enclave,
add the linker flags (`-lsomelib`) to **SGX_EXTRA_TLIBS**. This Makefile
variable gets substituted into the final link command line in order
to include it in the library list between the `--start-group` and
`--end-group` flags.  Do not use **target_LDADD** for this purpose.

