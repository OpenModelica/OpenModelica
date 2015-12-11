All *.c files in this directory should be compiled by a tool vendor
to the following object libraries

- ModelicaExternalC (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaInternal.c
  ModelicaStrings.c
  ModelicaRandom.c
  ModelicaFFT.c
  win32_dirent.c (for Visual C++ on Windows)

- ModelicaStandardTables (.lib, .dll, .a, .so, depending on tool and OS) containing:
  ModelicaStandardTables.c
  ModelicaMatIO.c
  zlib/*.c

When the library annotation "ModelicaExternalC" or "ModelicaStandardTables"
is utilized in an external Modelica function, then the respective object library
should be provided by the linker or should be dynamically linked to the
simulation environment.

Build projects for ModelicaStandardTables are provided under
   ../BuildProjects

Additionally, a tool vendor has to provide library "lapack"
(>= version 3.1; download from http://www.netlib.org/lapack)
and this library should be used in the linker when a model is compiled
that uses this library in its library annotation.

October 06, 2015.
