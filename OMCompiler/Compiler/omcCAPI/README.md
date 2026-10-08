# omcCAPI — libOMCDLL

`libOMCDLL` is a thin C API around `libOpenModelicaCompiler`. It lets an
external program drive the OpenModelica Compiler (omc) **in-process**  through a
small set of `extern "C"` functions:

```c
#include "OMC.h"

InitMetaOMC();
OMCData *omc = NULL;
InitOMC(&omc, "gcc", openModelicaHome);
char *reply = NULL;
SendCommand(omc, "loadModel(Modelica)", &reply);
SendCommand(omc, "getVersion()", &reply);
FreeOMC(omc);
```

See [include/OMC.h](include/OMC.h) for the full API. Every call returns a status
flag (`> 0` ok, `<= 0` error); `GetError()` returns the message.

## Building

Built as part of the OpenModelica CMake build when `OM_OMC_BUILD_OMCDLL` is `ON`
(the default on MinGW Windows, opt-in elsewhere):

```
cmake -DOM_OMC_BUILD_OMCDLL=ON ...
```

It is installed as `<prefix>/bin/libOMCDLL.{dll,so,dylib}` (plus `OMC.h` /
`OMCAPI.h` under `<prefix>/include/omc`).

## Test

[test/verify_libOMCDLL.c](test/verify_libOMCDLL.c) loads the library at runtime
and exercises the API. It is registered as the CTest `omcCAPI-libOMCDLL-usable`
(runs with `ctest -R omcCAPI`, needs CMake >= 3.22) and can also be built and run
by hand — see [test/README.md](test/README.md).
