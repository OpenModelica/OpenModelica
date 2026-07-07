# Generate the build-tree omc_config.unix.h (angle-included by omc_config.h).
#
# This must run in BOTH builds: the C-compiler build includes it from
# runtime/CMakeLists.txt, and the Rust build includes it from
# Compiler/CMakeLists.txt before that file's early return() — otherwise the
# simulation runtime (still built in Rust mode) fails with
# "'omc_config.unix.h' file not found". Optional-feature macros are
# intentionally left empty / neutralised here; in the CMake build they are
# supplied per target with -D and the .in guards them with #ifndef, so the
# header only needs the platform/compiler values below.

# LAPACK may not have been found yet on the Rust path (the C-runtime CMake that
# normally finds it is skipped); find it here so HAVE_LAPACK is set. Harmless
# (cached) when LAPACK was already found.
find_package(LAPACK)

set(SHREXT ${CMAKE_SHARED_LIBRARY_SUFFIX})
string(TOLOWER ${CMAKE_SYSTEM_NAME} OMC_TARGET_SYSTEM_NAME)
omc_add_to_report(OMC_TARGET_SYSTEM_NAME)
set(OPENMODELICA_SPEC_PLATFORM ${CMAKE_SYSTEM_PROCESSOR}-${OMC_TARGET_SYSTEM_NAME})

if(${CMAKE_SIZEOF_VOID_P} EQUAL 8)
  set(OMC_TARGET_ARCH_IS_64 "true")
  set(MODELICA_SPEC_PLATFORM "${OMC_TARGET_SYSTEM_NAME}64")
else()
  set(OMC_TARGET_ARCH_IS_64 "false")
  set(MODELICA_SPEC_PLATFORM "${OMC_TARGET_SYSTEM_NAME}32")
endif()

set(host_short ${CMAKE_LIBRARY_ARCHITECTURE})

get_filename_component(RUNTIMECC ${CMAKE_C_COMPILER} NAME)
get_filename_component(CC ${CMAKE_C_COMPILER} NAME)
get_filename_component(CXX ${CMAKE_CXX_COMPILER} NAME)

find_package(OpenMP)
if(OpenMP_FOUND)
  set(OMPCFLAGS "-fopenmp")
endif()

if(LAPACK_FOUND)
  set(HAVE_LAPACK "#define HAVE_LAPACK")
  if(OMC_HAVE_LAPACK_DEPRECATED)
    set(HAVE_LAPACK_DEPRECATED "#define HAVE_LAPACK_DEPRECATED")
  endif()
endif()


if(OpenMP_FOUND)
  set(CONFIG_WITH_OPENMP 1)
else()
  set(CONFIG_WITH_OPENMP 0)
endif()

set(OMC_HAVE_IPOPT "/* OMC_HAVE_IPOPT Not needed for CMake build. Availability and use of ipopt is handled by the CMakefiles.*/")

set(WITH_SUITESPARSE "#define WITH_SUITESPARSE")
set(WITH_HWLOC 0)
set(WITH_UUID "#define WITH_LIBUUID 1")


set(USE_GRAPH 0)

set(RUNTIMECFLAGS "-fPIC -DOM_HAVE_PTHREADS")

# Generate into the build tree (not the shared source tree) so the CMake and
# autotools builds don't clobber each other's omc_config.unix.h. omc_config.h
# angle-includes it, and OMCompiler_BINARY_DIR is first on omc::config's path.
configure_file(${OMCompiler_SOURCE_DIR}/omc_config.unix.h.in ${OMCompiler_BINARY_DIR}/omc_config.unix.h)
