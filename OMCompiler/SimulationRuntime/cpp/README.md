# Build the C++ runtime

Set `OM_OMC_ENABLE_CPP_RUNTIME=ON` when compiling with CMake.
Check [README.cmake.md](../../../README.cmake.md) for details.

## Configuration arguments

```cmake
  RUNTIME_PROFILING="true"
  SCOREP="true"
  SCOREP_HOME=”...”
  FMU_SUNDIALS="true"
  PARALLEL_OUTPUT="true"
  USE_LOGGER="false"
  BUILDTYPE=[Release,Debug]
  USE_KLU=["true","false"]
```

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

Author: Marcus Walther 20.11.2015
