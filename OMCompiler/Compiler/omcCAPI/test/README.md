# libOMCDLL smoke test

`verify_libOMCDLL.c` checks that a built/installed `libOMCDLL` (the omc C-API
wrapper, see issue [#16485](https://github.com/OpenModelica/OpenModelica/issues/16485))
can actually be loaded and used by an external program.

It loads the library at runtime (`LoadLibrary`/`dlopen`), resolves every exported
C function by name — the same thing a real consumer does — and drives omc through
the whole public API: `InitMetaOMC`, `InitOMC`, `GetOMCVersion`,
`SetCommandLineOptions`, `SendCommand`, `LoadFile`, `LoadModel` (both the failure
and, when a standard library is available, the success path), `GetError`,
`SetWorkingDirectory`, `FreeOMC`. `InitOMCWithZeroMQ` is resolved but not
invoked. This replaces the old `OMCTest.cpp`.

The MSL block (`LoadModel("Modelica")` + `simulate(...)`) is best-effort: asserted
when a standard library is on the path, noted-and-skipped otherwise (a bare build
tree has none).

A `FAIL:` line (exit 2-19) means the C ABI is broken — a missing export or a
failed assertion. A `SKIP:` line (exit 77) means the library or one of its
dependencies could not be loaded at all, which CTest reports as a skip rather
than a failure.

## As a CTest

The OpenModelica CMake build registers it as `omcCAPI-libOMCDLL-usable` when
`OM_OMC_BUILD_OMCDLL` is ON, `BUILD_TESTING` is ON and CMake is >= 3.22:

```sh
ctest --test-dir <build> -R omcCAPI --output-on-failure
```

CMake passes the full path to `libOMCDLL` as the argument and provides the
build-tree dependency directories and `OPENMODELICAHOME` via the test
environment, so no manual setup is needed.

## By hand

Windows (MinGW / MSYS2 shell):

```sh
gcc verify_libOMCDLL.c -o verify_libOMCDLL.exe
export OPENMODELICAHOME="/c/Program Files/OpenModelica1.28.0-dev-64bit"
PATH="$OPENMODELICAHOME/bin:$PATH" ./verify_libOMCDLL.exe
```

Linux / macOS:

```sh
cc verify_libOMCDLL.c -ldl -o verify_libOMCDLL
OPENMODELICAHOME=/usr LD_LIBRARY_PATH=/usr/lib/omc ./verify_libOMCDLL
```
