AC_PREREQ([2.63])
AC_INIT([SimulationRuntimeCpp],[dev],[https://trac.openmodelica.org/OpenModelica],[openmodelica],[https://openmodelica.org])

AC_LANG([C])
AC_PROG_CC
AC_PROG_CXX
AC_PROG_CPP

AC_CANONICAL_BUILD
AC_CANONICAL_HOST
AC_CANONICAL_TARGET

build_short=$build_cpu-$build_os
host_short=$host_cpu-$host_os

AC_SUBST(host_short)

AC_ARG_WITH(cppruntime-args,  [  --with-cppruntime-args=[cpp-args]       (pass comma separated arguments to the cppruntime configuration - see the cpp runtime documentation for details)],[CPP_RUNTIME_ARGS="$withval"],[CPP_RUNTIME_ARGS=""])

BOOST_STATIC_LINKING="no"
BOOST_REALPATHS="no"
BOOST_ROOT=""
BOOST_ROOT_COMMAND=""
RUNTIME_PROFILING="no"
SCOREP="no"
SCOREP_HOME=""
FMU_KINSOL="no"
PARALLEL_OUTPUT="no"
LOGGER="yes"
CPP_03="no"
#CMAKE_COMMANDS="CC=\"${CC}\" CXX=\"${CXX}\" CFLAGS=\"${CFLAGS}\" CXXFLAGS=\"${CXXFLAGS}\""
CMAKE_COMMANDS="CC=\"${CC}\" CXX=\"${CXX}\""
CMAKE_BUILDTYPE="RelWithDebInfo"

AC_SUBST(BOOST_STATIC_LINKING_COMMAND)
AC_SUBST(BOOST_REALPATHS_COMMAND)
AC_SUBST(BOOST_ROOT_COMMAND)
AC_SUBST(RUNTIME_PROFILING_COMMAND)
AC_SUBST(SCOREP_COMMAND)
AC_SUBST(SCOREP_HOME)
AC_SUBST(FMU_SUNDIALS_COMMAND)
AC_SUBST(PARALLEL_OUTPUT_COMMAND)
AC_SUBST(LOGGER_COMMAND)
AC_SUBST(CMAKE_COMMANDS)
AC_SUBST(CMAKE_BUILDTYPE)
AC_SUBST(CPP_03_COMMAND)

evaluateParameter() {
  case $1 in
    BOOST_STATIC_LINKING) BOOST_STATIC_LINKING="yes" ;;
    BOOST_REALPATHS) BOOST_REALPATHS="yes" ;;
    BOOST_ROOT=?*) BOOST_ROOT=`echo $1| cut -d'=' -f 2` ;;
    RUNTIME_PROFILING) RUNTIME_PROFILING="yes" ;;
    SCOREP) SCOREP="yes" ;;
    SCOREP_HOME=?*) SCOREP_HOME=`echo $1| cut -d'=' -f 2` ;;
    SCOREP_HOME=) ;;
    FMU_SUNDIALS) FMU_SUNDIALS="yes" ;;
    PARALLEL_OUTPUT) PARALLEL_OUTPUT="yes" ;;
    DISABLE_LOGGER) LOGGER="no" ;;
    BUILDTYPE=?*) CMAKE_BUILDTYPE=`echo $1| cut -d'=' -f 2` ;;
    BUILDTYPE=) ;;
    CPP_03) CPP_03="yes" ;;
    *) echo "Unknown Parameter given $1" ;;
  esac
}

old_ifs=$IFS
IFS=,
for var in $CPP_RUNTIME_ARGS ; do
  evaluateParameter "$var"
done;
IFS=$old_ifs


AC_ARG_WITH(boost-root,  [  --with-boost-root=[path]       (set the root directory of boost)],[BOOST_ROOT="$withval"],[])
if test "$BOOST_ROOT" = ""; then
  BOOST_ROOT_COMMAND=""
else
  BOOST_ROOT_COMMAND="-DBOOST_ROOT=$BOOST_ROOT"
  AC_MSG_RESULT([Boost root is set to $BOOST_ROOT])
fi


AC_ARG_WITH(cppruntimeBoostStaticLinking,  [  --with-boost-static-linking       (use static boost libraries for linking)],[BOOST_STATIC_LINKING="$withval"],[])

AC_MSG_CHECKING([if boost static linking is requested])
if test "$BOOST_STATIC_LINKING" = "yes"; then
  BOOST_STATIC_LINKING_COMMAND="-DBOOST_STATIC_LINKING=ON"
  AC_MSG_RESULT([yes])
else
  BOOST_STATIC_LINKING_COMMAND="-DBOOST_STATIC_LINKING=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(cppruntimeBoostRealpaths,  [  --with-boost-realpaths       (use boost real paths for linking)],[BOOST_REALPATHS="$withval"],[])

AC_MSG_CHECKING([if boost real paths are requested])
if test "$BOOST_REALPATHS" = "yes"; then
  BOOST_REALPATHS_COMMAND="-DUSE_BOOST_REALPATHS=ON"
  AC_MSG_RESULT([yes])
else
  BOOST_REALPATHS_COMMAND="-DUSE_BOOST_REALPATHS=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(c++03,  [  --with-c++03       (use c++03 standard)],[CPP_03="$withval"],[])

AC_MSG_CHECKING([if c++03 support is requested])
if test "$CPP_03" = "yes"; then
  CPP_03_COMMAND="-DUSE_CPP_03=ON"
  AC_MSG_RESULT([yes])
else
  CPP_03_COMMAND="-DUSE_CPP_03=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(cppruntimeProfiling,  [  --with-runtime-profiling       (enable runtime profiling)],[RUNTIME_PROFILING="$withval"],[])

AC_MSG_CHECKING([if runtime profiling is requested])
if test "$RUNTIME_PROFILING" = "yes"; then
  RUNTIME_PROFILING_COMMAND="-DRUNTIME_PROFILING=ON"
  AC_MSG_RESULT([yes])
else
  RUNTIME_PROFILING_COMMAND="-DRUNTIME_PROFILING=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(cppruntimeScorep,  [  --with-scorep       (enable scorep support)],[SCOREP="$withval"],[])

AC_MSG_CHECKING([if ScoreP is requested])
if test "$SCOREP" = "yes"; then
  SCOREP_COMMAND="-DUSE_SCOREP=ON"
  CMAKE_COMMANDS="CC=\"scorep --user --nocompiler ${CC}\" CXX=\"scorep --user --nocompiler ${CXX}\""
  AC_MSG_RESULT([yes])
else
  SCOREP_COMMAND="-DUSE_SCOREP=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(scorep-home,  [  --with-scorep-home=[path]       (set the home directory of scorep)],[SCOREP_HOME="$withval"],[])
AC_MSG_RESULT([ScoreP-home is set to $SCOREP_HOME])

AC_ARG_WITH(cppruntimeFmuSundials,  [  --with-fmu-sundials       (enable sundials solver in FMUs)],[FMU_SUNDIALS="$withval"],[])

AC_MSG_CHECKING([if sundials for FMUs is requested])
if test "$FMU_SUNDIALS" = "yes"; then
  FMU_SUNDIALS_COMMAND="-DFMU_SUNDIALS=ON"
  AC_MSG_RESULT([yes])
else
  FMU_SUNDIALS_COMMAND="-DFMU_SUNDIALS=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(cppruntimeParallelOutput,  [  --with-parallel-output       (enable parallel output (unstable))],[PARALLEL_OUTPUT="$withval"],[])

AC_MSG_CHECKING([if parallel output is requested])
if test "$PARALLEL_OUTPUT" = "yes"; then
  PARALLEL_OUTPUT_COMMAND="-DUSE_PARALLEL_OUTPUT=ON"
  AC_MSG_RESULT([yes])
else
  PARALLEL_OUTPUT_COMMAND="-DUSE_PARALLEL_OUTPUT=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(cppruntimeLogger,  [  --with-logger       (enable or disable the logger of the cpp-runtime (on by default))],[LOGGER="$withval"],[])

AC_MSG_CHECKING([if logger should be used])
if test "$LOGGER" = "yes"; then
  LOGGER_COMMAND="-DUSE_LOGGER=ON"
  AC_MSG_RESULT([yes])
else
  LOGGER_COMMAND="-DUSE_LOGGER=OFF"
  AC_MSG_RESULT([no])
fi

AC_ARG_WITH(build-type,  [  --with-build-type=[Release|Debug|RelWithDebInfo]       (set the cmake build type)],[CMAKE_BUILDTYPE="$withval"],[])
AC_MSG_RESULT([Build type is set to $CMAKE_BUILDTYPE])

AC_OUTPUT(Makefile)
