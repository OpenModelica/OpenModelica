# Build the C++ runtime

Set `OM_OMC_ENABLE_CPP_RUNTIME=ON` when compiling with CMake.
Check [README.cmake.md](../../../README.cmake.md) for details.

## Configuration arguments

```cmake
  BOOST_STATIC_LINKING="true"
  BOOST_REALPATHS="true"
  RUNTIME_PROFILING="true"
  SCOREP="true"
  SCOREP_HOME=”...”
  FMU_SUNDIALS="true"
  PARALLEL_OUTPUT="true"
  USE_LOGGER="false"
  BUILDTYPE=[Release,Debug]
  USE_KLU=["true","false"]
```

The boost static libraries can be used for the build, by passing the
`BOOST_STATIC_LINKING` argument to make. Take care that all boost- libraries are
linked statically.

Sometimes it's necessary to link boost against it's real path libraries. This
means for example, that instead of linking against “-lboost_filesystem”, the
makefiles will link against “-lboost1.55_filesystem”. Use the `BOOST_REALPATHS`
argument for this purpose.

If profiling informations for the runtime are required, they can be turned on
with the `RUNTIME_PROFILING` command.

Profiling can additionally be handled by Score-P. This gives the possibility to
use tracing besides profiling for performance analysis. Maybe it's necessary to
give the `SCOREP_HOME` directory to make as well. This is the directory
containing `include/scorep/SCOREP_User.h`. Turn the Score-P support on, by
passing the `SCOREP` argument.

The FMU export usually creates executables that use the Newton algorithm to
solve equation systems. The KINSOL solver can be used as well, by passing the
`FMU_SUNDIALS` argument to configure.

Simulation results can be written asynchronously with the help of boost
threads and a consumer producer algorithm (experimental). This feature is
available after passing `PARALLEL_OUTPUT` to configure.

For performance reasons it can be necessary to disable the logger-code completely.
This can be done by passing the `USE_LOGGER` argument.

The build-type of cmake can be directly controlled by passing the `BUILDTYPE`
argument. If debug librariers should be created, set this value to `debug`.
If release libraries are required, pass `release` instead.

The Windows build does not support C++11 at the moment. Therfore a lot of C++11
features are replaced with boost equivalents. Sometimes it is necessary to check
this build on Linux-systems as well. Therefore the argument `CPP_03` can be
passed, to prevent the usage of C++11 features.

Author: Marcus Walther 20.11.2015
