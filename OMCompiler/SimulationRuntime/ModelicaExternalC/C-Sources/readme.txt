All *.c files in this directory should be compiled by a tool vendor
to the following object libraries

- ModelicaExternalC (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaFFT.c
  ModelicaInternal.c
  ModelicaRandom.c
  ModelicaStrings.c
  win32_dirent.c (for Visual C++ on Windows)

- ModelicaIO (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaIO.c

- ModelicaMatIO (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaMatIO.c
  snprintf.c

- ModelicaStandardTables (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaStandardTables.c
  ModelicaStandardTablesUsertab.c

- zlib (.lib, .dll, .a, .so, depending on tool and OS) containing:
  zlib/*.c

When the library annotation "ModelicaExternalC", "ModelicaIO" or
"ModelicaStandardTables" is utilized in an external Modelica function, then the
respective object library should be provided by the linker or should be
dynamically linked to the simulation environment.

For backwards-compatibility with the Modelica Standard Library (MSL) v3.2.1, a
tool vendor supporting MSL v3.2.1 and later releases has to provide the library
"ModelicaStandardTables" in such a way that the required library dependencies
(i.e., libraries "ModelicaIO", "ModelicaMatIO" and "zlib") are automatically
resolved. For instance, this can be achieved by building shared object
libraries (.dll, .so) and dynamically linking library "ModelicaStandardTables" to
"ModelicaIO", "ModelicaIO" to "ModelicaMatIO" and "ModelicaMatIO" to "zlib".

On Windows, when compiling libraries (.dll, .lib) or executables (.exe) with
C sources including gconstructor.h, particularly, projects that build
ModelicaInternal.c or ModelicaStandardTables.c, the following (optimization)
options shall be applied in the Release configuration of Visual Studio 2013, 2015
or 2017:
- Compiler: /Zc:inline (Remove unreferenced COMDAT) must not be set. Either do not
  set this option at all or explicitly set /Zc:inline- to unset
- Linker: /OPT:NOREF (Keep unreferenced functions) should be set, in case
  /GL (Whole Program Optimization) and /LTCG (Link-time Code Generation) are set

Build projects for the object libraries are provided under
  ../BuildProjects

Additionally, a tool vendor has to provide library "lapack"
(>= v3.1; download from http://www.netlib.org/lapack)
and this library should be used in the linker when a model is compiled
that uses this library in its library annotation.

January 05, 2018.
