# This script will build and install all required libraries of the C++ Simulation-runtime
#
# The following conditional defines are passed to the c++ compiler:
#     if the Boost_log and Boost_setup_log libraries were found                    -DUSE_BOOST_LOG
#     if the Boost_thread library was found or C++ 11 is available                 -DUSE_THREAD
#     if the UMFPack library of SuiteSparse was found                              -DUSE_UMFPACK
#     if the PAPI library was found                                                -DUSE_PAPI
#     if the Sundials libraries were found                                         -DPMC_USE_SUNDIALS
#     if the runtime is build for the OMC                                          -DOMC_BUILD
#     if the write-output functionality should be handled in parallel              -DUSE_PARALLEL_OUTPUT
#     if ScoreP should be used for performance analysis                            -DUSE_SCOREP
#     if the Intel TBB library was found                                           -DUSE_INTEL_TBB
#     if the Pugi XML library was found                                            -DUSE_PUGI_XML
#     if profiling for the simulation runtime is enabled                           -DRUNTIME_PROFILING
#     if the equation systems of a FMU should be solved with sundials solvers      -DFMU_SUNDIALS
#     if the logger is used                                                        -DUSE_LOGGER
#
# Some of these options can be controlled by passing arguments to CMAKE
#     if write output should be handled in parallel                                -DUSE_PARALLEL_OUTPUT=ON [default: OFF]
#     if ScoreP should be used for performance analysis                            -DUSE_SCOREP=ON [default: OFF]
#     the path to the scorep-installation                                          -DSCOREP_HOME="..." [default: ""]
#     if dgesv library should NOT be used to solve simple equation systems in FMUs -DUSE_DGESV=OFF [default: ON]
#     the path to the dgesv-installation                                           -DDGESV_HOME="..." [default: ""]
#     if the boost libraries should be linked statically                           -DBOOST_STATIC_LINKING=ON [default: OFF]
#     if boost libraries should be linked against absolute path libraries          -DUSE_BOOST_REALPATHS=ON [default: OFF]
#     disable c++11, even if the compiler is able to use it                        -DUSE_CPP_03=ON [default: OFF]
#     if profiling of the simulation runtime should be enabled                     -DRUNTIME_PROFILING=ON [default: OFF]
#     if the equation systems of a FMU should be solved with sundials solvers      -DFMU_SUNDIALS=ON [default: OFF]
#     if the logger should be completely disabled or used                          -DUSE_LOGGER=OFF [default: ON]
#     specify target platform for compilation                                      -DPLATFORM=<dynamic, static or platform triple> [default: "dynamic"]
#     use Klu sparse liner solver                                                    -DUSE_KLU [default: OFF]
#     Example: "cmake -DCMAKE_BUILD_TYPE=RelWithDebInfo" to create statically linked libraries
#
# The used defines are stored in the SYSTEM_CFLAGS variable, which is passed to the ModelicaConfig.inc and written in the PrecompiledHeader.cmake

cmake_minimum_required(VERSION 3.5)

# OMSICPP_SOURCE_DIR is used by sub-CMakeLists.txt to reference paths relative
# to the OMSICpp directory. In standalone mode it equals CMAKE_SOURCE_DIR; in
# integrated mode (add_subdirectory from the parent) CMAKE_CURRENT_SOURCE_DIR
# points to the OMSICpp directory which is what we want.
set(OMSICPP_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

# When included as a subdirectory in the full OpenModelica CMake build,
# delegate to cmake_integrated.cmake which sets up the build using CMake
# targets from the parent project instead of find_library() calls.
if(OPENMODELICA_NEW_CMAKE_BUILD)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake_integrated.cmake)
  return()
endif()

project(CppOMSISimulation)

set(CMAKE_VERBOSE_MAKEFILE ON)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMake")
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

message(STATUS "CMake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

string(TOUPPER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_UPPER)

#Set Options
option(USE_PARALLEL_OUTPUT "USE_PARALLEL_OUTPUT" OFF)
option(USE_SCOREP "USE_SCOREP" OFF)
option(USE_DGESV "USE_DGESV" ON)
option(BOOST_STATIC_LINKING "BOOST_STATIC_LINKING" OFF)
option(USE_BOOST_REALPATHS "USE_BOOST_REALPATHS" OFF)
option(RUNTIME_PROFILING "RUNTIME_PROFILING" OFF)
option(FMU_SUNDIALS "FMU_SUNDIALS" OFF)
option(USE_OMSI "Enable omsi nonlinear and linear solver interface" ON)
option(KLU_ROOT "KLU ROOT" "")
option(USE_CPP_03 "USE_CPP_03" OFF)
option(USE_FMILIB "use fmi library" ON)
option(REDUCE_DAE "Use reduce dae method" OFF)

set(USE_MICO OFF)
set(USE_KLU CACHE BOOL OFF)

if(NOT FMU_TARGET OR FMU_SUNDIALS)
  set(USE_SUNDIALS ON)
endif(NOT FMU_TARGET OR FMU_SUNDIALS)
set(OMC_BUILD ON)
set(SIMSTER_BUILD OFF)
set(Boost_USE_MULTITHREADED ON)

#Set Variables
set(MODELICAEXTERNALCDIR  "${CMAKE_SOURCE_DIR}/../ModelicaExternalC/C-Sources")
set(USERTABDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/Data/Tables")

if(UNIX)
  if(APPLE)
    # We set the rpath manually, later...
  else(APPLE)
    # Needed to find Sundials; actually only the Sundials objects need this,
    # but there are so many of them
    set(CMAKE_INSTALL_RPATH "$ORIGIN:$ORIGIN/..")
  endif(APPLE)
endif(UNIX)

if(NOT PLATFORM OR PLATFORM STREQUAL "dynamic")
  set(BUILD_SHARED_LIBS ON)
elseif(PLATFORM STREQUAL "static")
  set(BUILD_SHARED_LIBS OFF)
else()
  # cross compilation of a subset of the runtime for FMI export
  set(FMU_TARGET PLATFORM)
  set(BUILD_SHARED_LIBS OFF)

  # set cross compiler and force its use
  include(CMakeForceCompiler)
  set(CMAKE_C_COMPILER ${PLATFORM}-gcc)
  cmake_force_c_compiler(${PLATFORM}-gcc GNU)
  set(CMAKE_CXX_COMPILER ${PLATFORM}-g++)
  cmake_force_cxx_compiler(${PLATFORM}-g++ GNU)

  # adapt lib installation dir, like lib/${PLATFORM}/omc/cpp
  execute_process(COMMAND gcc -dumpmachine OUTPUT_VARIABLE MACHINE)
  string(STRIP ${MACHINE} MACHINE)
  string(REPLACE ${MACHINE} ${PLATFORM} LIBINSTALLEXT ${LIBINSTALLEXT})
  message(STATUS "Libs will be installed in ${LIBINSTALLEXT}")
endif()

message(STATUS "Libs will be installed in ${LIBINSTALLEXT}")
message(STATUS "Libs will be installed in MACHINE = ${MACHINE} PLATFORM = ${PLATFORM}   -> ${LIBINSTALLEXT}")


message(STATUS "CMake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

string(TOUPPER "${CMAKE_BUILD_TYPE}" CMAKE_BUILD_TYPE_UPPER)

#Set Options
option(USE_PARALLEL_OUTPUT "USE_PARALLEL_OUTPUT" OFF)
option(USE_SCOREP "USE_SCOREP" OFF)
option(USE_DGESV "USE_DGESV" ON)
option(BOOST_STATIC_LINKING "BOOST_STATIC_LINKING" OFF)
option(USE_BOOST_REALPATHS "USE_BOOST_REALPATHS" OFF)
option(RUNTIME_PROFILING "RUNTIME_PROFILING" OFF)
option(FMU_SUNDIALS "FMU_SUNDIALS" OFF)
option(KLU_ROOT "KLU ROOT" "")
option(USE_CPP_03 "USE_CPP_03" OFF)
option(USE_ZEROMQ "USE zeromq and cppzmq" ON)
option(USE_PRECOMPILEDHEADER  OFF)
option(USE_MINPACK ON)

option(BUILD_BROYDEN ON)
option(BUILD_PEER ON)

#Set Variables
set(MODELICAEXTERNALCDIR  "${CMAKE_SOURCE_DIR}/../ModelicaExternalC/C-Sources")

if(NOT FMU_TARGET)
  if(MSVC)
    message(STATUS "MSVC")
    set(LIBINSTALLEXT "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}/omsicpp/msvc" CACHE STRING "library directory" FORCE)
  else(MSVC)
    set(LIBINSTALLEXT "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}/omsicpp" CACHE STRING "library directory" FORCE)
  endif(MSVC)
endif(NOT FMU_TARGET)
message(STATUS "Using library folder extension " ${LIBINSTALLEXT})
set(MODELICA_MODEL "ModelicaSystem")
set(LIBPREFIX "OMCpp")
if(BUILD_SHARED_LIBS)
  set(LIBSUFFIX "")
else(BUILD_SHARED_LIBS)
  set(LIBSUFFIX "_static")
endif(BUILD_SHARED_LIBS)
set(SolverName ${LIBPREFIX}Solver${LIBSUFFIX})
set(SystemBaseName ${LIBPREFIX}SystemBase${LIBSUFFIX})
set(SystemOMSIName ${LIBPREFIX}SystemOMSI${LIBSUFFIX})
set(ExtendedSystemName ${LIBPREFIX}ExtendedSystem${LIBSUFFIX})
set(OMCFactoryName ${LIBPREFIX}OMCFactory${LIBSUFFIX})
set(MathName ${LIBPREFIX}Math${LIBSUFFIX})

set(ModelicaExternalName ModelicaExternalC) # only static version
set(ModelicaTablesName ModelicaStandardTables) # only static version
set(ModelicaIOName ModelicaIO) # only static version
set(ModelicaMatIOName ModelicaMatIO) # only static version
set(LibZName zlib) # only static version

set(SimulationSettings ${LIBPREFIX}SimulationSettings${LIBSUFFIX})
set(SimControllerName ${LIBPREFIX}SimController${LIBSUFFIX})
set(CVodeName ${LIBPREFIX}CVode${LIBSUFFIX})
set(IDAName ${LIBPREFIX}IDA${LIBSUFFIX})
set(PeerName ${LIBPREFIX}Peer${LIBSUFFIX})
set(CppDASSLName ${LIBPREFIX}CppDASSL${LIBSUFFIX})
set(EulerName ${LIBPREFIX}Euler${LIBSUFFIX})
set(RK12Name ${LIBPREFIX}RK12${LIBSUFFIX})
set(RTEulerName ${LIBPREFIX}RTEuler${LIBSUFFIX})
set(IdaName ${LIBPREFIX}Ida${LIBSUFFIX})
set(IdasName ${LIBPREFIX}Idas${LIBSUFFIX})
set(KinsolName ${LIBPREFIX}Kinsol${LIBSUFFIX})
set(LinearSolverName ${LIBPREFIX}LinearSolver${LIBSUFFIX})
set(DgesvSolverName ${LIBPREFIX}DgesvSolver${LIBSUFFIX})
set(ModelicaName ${LIBPREFIX}Modelica${LIBSUFFIX})
set(NewtonName ${LIBPREFIX}Newton${LIBSUFFIX})
set(BroydenName ${LIBPREFIX}Broyden${LIBSUFFIX})
set(HybrjName ${LIBPREFIX}Hybrj${LIBSUFFIX})
set(UmfPackName ${LIBPREFIX}UmfPack${LIBSUFFIX})
set(DataExchangeName ${LIBPREFIX}DataExchange${LIBSUFFIX})
set(ModelicaUtilitiesName ${LIBPREFIX}ModelicaUtilities${LIBSUFFIX})
set(ExtensionUtilitiesName ${LIBPREFIX}ExtensionUtilities${LIBSUFFIX})
set(BasiLibName ${LIBPREFIX}Base${LIBSUFFIX})
set(FMUName ${LIBPREFIX}FMU${LIBSUFFIX})
set(DgesvName ${LIBPREFIX}Dgesv_static) # only static version
set(ReduceDAEName ${LIBPREFIX}ReduceDAE) # only static version

set(USE_MICO OFF)
set(USE_KLU CACHE BOOL OFF)

if(NOT FMU_TARGET OR FMU_SUNDIALS)
  set(USE_SUNDIALS ON)
endif(NOT FMU_TARGET OR FMU_SUNDIALS)
set(OMC_BUILD ON)
set(SIMSTER_BUILD OFF)

set(Boost_USE_MULTITHREADED ON)


#Currently only mingw is supported for the model reduction algorithm
#IF(MINGW)
#    SET(REDUCE_DAE ON)
#ELSE()
#    SET(REDUCE_DAE OFF)
#ENDIF()


if(USE_BOOST_REALPATHS)
  message(STATUS "Using boost real paths")
  set(Boost_REALPATH ON)
else(USE_BOOST_REALPATHS)
  message(STATUS "Boost real paths disabled")
endif(USE_BOOST_REALPATHS)

# Precompiled Header
if(MSVC)
  set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} /Zm113")
endif(MSVC)
include(${CMAKE_SOURCE_DIR}/CMake/PrecompiledHeader.cmake)

#IF(IS_MINGW32 OR IS_MINGW64)
# SET(USE_CPP_03 ON)
#ENDIF(IS_MINGW32 OR IS_MINGW64)



include(CMake/CheckCXX11.cmake)


#Handle static boost linking
if(NOT BOOST_STATIC_LINKING)
  set(Boost_USE_STATIC_LIBS OFF)
  set(Boost_USE_STATIC_RUNTIME OFF)
else(NOT BOOST_STATIC_LINKING)
  set(Boost_USE_STATIC_LIBS ON)
  set(Boost_USE_STATIC_RUNTIME ON)
  add_definitions(-DBOOST_STATIC_LINKING)
endif(NOT BOOST_STATIC_LINKING)

# Handle parallel output
if(USE_PARALLEL_OUTPUT)
  add_definitions(-DUSE_PARALLEL_OUTPUT)
  message(STATUS "Using parallel output")
else(USE_PARALLEL_OUTPUT)
  message(STATUS "Parallel output disabled")
endif(USE_PARALLEL_OUTPUT)

# Handle ScoreP
if(USE_SCOREP)
  add_definitions(-DUSE_SCOREP)
  set(USE_SCOREP_ "ON")
  find_package(ScoreP)
  set(SCOREP_INCLUDE_ ${SCOREP_INCLUDE_DIR})
  message(STATUS "ScoreP enabled")
  include_directories(${SCOREP_INCLUDE_DIR})
else(USE_SCOREP)
  set(SCOREP_INCLUDE_ ".")
  set(USE_SCOREP_ "OFF")
  message(STATUS "ScoreP disabled")
endif(USE_SCOREP)

# Handle dgesv
if(USE_DGESV)
  add_definitions(-DUSE_DGESV)
  set(USE_DGESV_ "ON")
  find_package(Dgesv)
  set(DGESV_INCLUDE_ ${DGESV_INCLUDE_DIR})
  message(STATUS "Dgesv enabled ${DGESV_FOUND} was found")
else(USE_DGESV)
  set(DGESV_INCLUDE_ ".")
  set(USE_DGESV_ "OFF")
  message(STATUS "Dgesv disabled")
endif(USE_DGESV)


# Handle runtime profiling
if(RUNTIME_PROFILING)
  add_definitions(-DRUNTIME_PROFILING)
  message(STATUS "Runtime profiling enabled")
else(RUNTIME_PROFILING)
  message(STATUS "Runtime profiling disabled")
endif(RUNTIME_PROFILING)

# Handle FMU sundials support
if(FMU_SUNDIALS)
  add_definitions(-DENABLE_SUNDIALS_STATIC)
  set(USE_FMU_SUNDIALS_ "ON")
  message(STATUS "FMU sundials enabled")
else(FMU_SUNDIALS)
  set(USE_FMU_SUNDIALS_ "OFF")
  message(STATUS "FMU sundials disabled")
endif(FMU_SUNDIALS)

# Handle Logger usage
if(USE_LOGGER)
  add_definitions(-DUSE_LOGGER)
  set(USE_LOGGER_ "ON")
  message(STATUS "Logger enabled")
else(USE_LOGGER)
  message(STATUS "Logger disabled")
  set(USE_LOGGER_ "OFF")
endif(USE_LOGGER)

# Handle build type
if(OMC_BUILD)
  add_definitions(-DOMC_BUILD)
elseif(SIMSTER_BUILD)
  add_definitions(-DSIMSTER_BUILD)
endif(OMC_BUILD)


# Handle OMDEV
#  - On windows boost,blas,lapack and sundial solvers from omdev are used else the installed versions are used
if(WIN32)
  set(Boost_DEBUG 1)
  message(STATUS "MINGW:")
  message(STATUS ${IS_MINGW64})

  # Check environment variables
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()
  string(REPLACE "\\" "/" OMDEV_ESCAPED "$ENV{OMDEV}")
  string(REPLACE "\\" "/" OMDEV_MSYS_ESCAPED "$ENV{OMDEV}/tools/msys")
  string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")

  if(IS_MINGW64)
    set(BOOST_ROOT ${MSYSTEM_PREFIX_ESCAPED})
  elseif(IS_MINGW632)
    message(FATAL_ERROR "32-bit version not supported")
  else()
    if(MSVC_VERSION GREATER 1800)
      message(STATUS "USE MSVC 2015 and greater:")
      #SET(Boost_COMPILER  "-vc142")
      set(BOOST_ROOT ${OMDEV_ESCAPED}"/lib/3rdParty/boost-1_59/")
      #SET(Boost_COMPILER  "-vc142")
    elseif(MSVC_VERSION GREATER 1700)
      set(BOOST_ROOT ${OMDEV_ESCAPED}"/lib/3rdParty/boost-1_59/")
    else()
      set(BOOST_ROOT ${OMDEV_ESCAPED}"/lib/3rdParty/boost-1_55/")
    endif()
  endif(IS_MINGW32)
  message(STATUS "Boost root for omsicpp runtime:")
  message(STATUS ${BOOST_ROOT} )
  set(BLAS_blas_LIBRARY ${OMDEV_ESCAPED}/lib/3rdParty/Lapack/Lib/blas_win32.dll CACHE FILEPATH "Blas library")
  set(LAPACK_lapack_LIBRARY  ${OMDEV_ESCAPED}/lib/3rdParty/Lapack/Lib/lapack_win32.dll CACHE FILEPATH "Lapack library")
  set(BLAS_DIRY "${OMDEV_ESCAPED}/lib/3rdParty/Lapack/Lib/" CACHE LOCATION "where was yarp built?")

  # Disable Optimization for RelWithDebInfo on Windows
  if(MSVC)
    string(REPLACE "/O2" "/Od" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
  else(MSVC)
    string(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
    string(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
  endif(MSVC)

  #set mico paths
  set(MICO_LIB_HOME ${OMDEV_ESCAPED}/lib/mico-msys-mingw/)
  set(MICO_INCLUDE_HOME  ${OMDEV_ESCAPED}/include/mico-msys-mingw/)

  set(INSTALL_OMDEV_LIBS OFF)
endif(WIN32)

# Find OpenMP
find_package(OpenMP)
if(OPENMP_FOUND)
  message(STATUS "OPENMP enabled")
  set(USE_OPENMP_ "ON")
else(OPENMP_FOUND)
  message(STATUS "OPENMP disabled")
  set(USE_OPENMP_ "OFF")
endif(OPENMP_FOUND)

# Find MPI
find_package(MPI)
if(MPI_FOUND)
  message(STATUS "MPI enabled")
  set(USE_MPI_ "ON")
else(MPI_FOUND)
  message(STATUS "MPI disabled")
  set(USE_MPI_ "OFF")
endif(MPI_FOUND)

# Find CMinpack
# Note: Visual Studio libs are located in install/msvc, libs for gcc are directly in install
if(MSVC)
  set(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install_msvc")
else(MSVC)
  set(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/build")
endif(MSVC)


if(USE_MINPACK)
  find_path(CMINPACK_INCLUDE_DIR cminpack.h
            HINTS ${CMinpack_Path}
            PATH_SUFFIXES include include/cminpack include/cminpack-1 ..)

  find_library(CMINPACK_LIBRARY
               NAMES cminpack
               HINTS ${CMinpack_Path}
               PATH_SUFFIXES lib lib64)

  include_directories(${CMINPACK_INCLUDE_DIR})

endif(USE_MINPACK)

# Find Intel TBB
find_package(TBB)
if(TBB_FOUND)
  add_definitions(-DUSE_INTEL_TBB)
  message(STATUS "Using Intel TBB")
else(TBB_FOUND)
  message(STATUS "Intel TBB disabled")
endif(TBB_FOUND)

# Find Pugi XML
find_package(PugiXML)
if(PUGIXML_FOUND)
  add_definitions(-DUSE_PUGI_XML)
  message(STATUS "Using Pugi XML")
else(PUGIXML_FOUND)
  message(STATUS "Pugi XML disabled")
endif(PUGIXML_FOUND)

# Find PAPI
find_library(PAPI_LIBRARIES NAMES libpapi.a papi)
find_path(PAPI_INCLUDE_DIRS NAMES papi.h)
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PAPI DEFAULT_MSG PAPI_LIBRARIES PAPI_INCLUDE_DIRS)
if(PAPI_FOUND)
  add_definitions(-DUSE_PAPI)
  set(USE_PAPI_ "ON")
else(PAPI_FOUND)
  set(USE_PAPI_ "OFF")
endif(PAPI_FOUND)


# Find Boost
# If MSVC, we do not want to use MSYS/MingGW installed boost's CMake config files for locating Boost
# We have a manually provided boost already specified using BOOST_ROOT.
# This is essentialy saying we do not want any help from boost itself in finding its libraries and setup.
# Let CMake do it alone the old way by just finding the files it knows.
if(MSVC)
  set(Boost_NO_BOOST_CMAKE ON)
endif(MSVC)
#  - The optional boost libraries must be searched separately, otherwise no library is found if just one is missing.
#  - Additionaly the Boost_LIBRARIES variable is overwritten each time find_package(Boost ...) is called, thus it must be rescued
find_package(Boost COMPONENTS log log_setup)

# Deactivate threading stuff in MSVC release mode, because this produces linker errors to boost::exception_ptr
if(MSVC AND (CMAKE_BUILD_TYPE_UPPER STREQUAL "RELEASE"))
  set(Boost_THREAD_LIBRARY_RELEASE "NOT_FOUND")
  set(Boost_THREAD_LIBRARY_DEBUG "NOT_FOUND")
  message(STATUS "Boost threading disabled because othwerwise the MSVC build produces linker errors in release mode.")
else(MSVC AND (CMAKE_BUILD_TYPE_UPPER STREQUAL "RELEASE"))
  find_package(Boost COMPONENTS thread atomic)
endif(MSVC AND (CMAKE_BUILD_TYPE_UPPER STREQUAL "RELEASE"))

if(NOT(COMPILER_SUPPORTS_CXX11))
  set(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
  find_package(Threads)
  if(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
    add_definitions(-DUSE_THREAD)
    message(STATUS "Using boost thread")
  else(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
    message(STATUS "Boost thread disabled")
  endif(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
elseif(NOT FMU_TARGET)
  add_definitions(-DUSE_THREAD)
  message(STATUS "Boost thread disabled because of available C++11 support")
endif(NOT(COMPILER_SUPPORTS_CXX11))

if(NOT FMU_TARGET)
  find_package(Boost REQUIRED COMPONENTS filesystem serialization program_options)
else(NOT FMU_TARGET)
  find_package(Boost COMPONENTS filesystem serialization program_options)
endif(NOT FMU_TARGET)

# Use old C++ ABI for cross compilation of FMUs
# because libstdc++ might not be upgraded yet
# (e.g. i686-w64-mingw32 under Ubuntu 16.04 LTS).
# Note: the default ABI is used for simulators that link with boost libs.
if(FMU_TARGET AND NOT MSVC)
  add_definitions(-D_GLIBCXX_USE_CXX11_ABI=0)
endif(FMU_TARGET AND NOT MSVC)

if(WIN32)
  set(CPPTHREADS_LIBRARY)
  set(CPPTHREADS_LIBRARY_FLAG)
else(WIN32)
  find_package(Threads REQUIRED)
  set(CPPTHREADS_LIBRARY Threads::Threads)
  set(CPPTHREADS_LIBRARY_FLAG ${CMAKE_THREAD_LIBS_INIT})
endif(WIN32)

set(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
set(Boost_LIBRARIES ${Boost_LIBRARIES_TMP})
message(STATUS "using boost include for omsicpp runtime:  ${Boost_INCLUDE_DIR}")
message(STATUS "Boost Libraries for omsicpp runtime")
message(STATUS ${Boost_LIBRARIES})

# Find Lapack and Blas
if(MSVC)
  #workaround  because cmake does not find the lapack libraries for Visual Studio 10
  set(LAPACK_MSVC_10  ${OMDEV_ESCAPED}/lib/3rdParty/Lapack/Lib/lapack_win32.lib )
  set(BLAS_MSVC_10 ${OMDEV_ESCAPED}/lib/3rdParty/Lapack/Lib/blas_win32.lib )
  set(LAPACK_LIBRARIES  ${LAPACK_MSVC_10}   ${BLAS_MSVC_10} )
else()
  find_package(BLAS)
  find_package(LAPACK)
endif(MSVC)

list(LENGTH LAPACK_LIBRARIES LAPACKVARCOUNT)
if(LAPACKVARCOUNT GREATER 0)
  list(GET LAPACK_LIBRARIES 0 LAPACKLISTHEAD)
  get_filename_component(LAPACKLISTHEAD "${LAPACKLISTHEAD}" PATH)
  set(LAPACK_LIBS "${LAPACKLISTHEAD}")
endif()

message(STATUS "LAPACK Libraries: ${LAPACK_LIBRARIES}")


if(REDUCE_DAE)
  add_definitions("-DUSE_REDUCE_DAE")
  set(OMCCAPI_INLCUDE_HOME  omcWrapper/omcCAPI/include/)
  set(OMCCAPI_LIBRARY_RELEASE_HOME   Build_CAPI/tmp/lib)
  find_library(OMCCAPI_LIB "OMCDLL" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMCCAPI_LIBRARY_RELEASE_HOME} )
  if(NOT OMCCAPI_LIB)
    message(FATAL_ERROR "Could not find omc c- api library!")
  endif()
  message(STATUS "omc c api include:")
  message(STATUS "${OMCCAPI_INLCUDE_HOME}")
  message(STATUS "omc c api library path:")
  message(STATUS "${OMCCAPI_LIBRARY_RELEASE_HOME}")
  find_path(OMCCAPI_INCLUDE_DIR OMC.h PATHS ${OMCCAPI_INLCUDE_HOME})
  if(NOT OMCCAPI_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find omc c- api")
  endif(NOT OMCCAPI_INCLUDE_DIR)
  message(STATUS "omc c api library for ReduceDAE:")
  message(STATUS "${OMCCAPI_LIB}")
  message(STATUS "omc c api include dir for ReduceDAE:")
  message(STATUS "${OMCCAPI_INCLUDE_DIR}")
endif(REDUCE_DAE)

# Find Sundials solvers
if(USE_SUNDIALS)
  #set sundials solvers include and library directories
  if(MSVC)
    set(SUNDIALS_INLCUDE_HOME  "${CMAKE_SOURCE_DIR}/../../3rdParty/sundials-5.4.0/build_msvc/include/sundials")
    set(SUNDIALS_LIBRARY_RELEASE_HOME "${CMAKE_SOURCE_DIR}/../../3rdParty/sundials-5.4.0/build_msvc/lib/")
  else(MSVC)
    set(SUNDIALS_INLCUDE_HOME  ${CMAKE_INSTALL_PREFIX}/include/omc/sundials)
    set(SUNDIALS_LIBRARY_RELEASE_HOME ${CMAKE_INSTALL_PREFIX}/${LIB_OMC})
  endif(MSVC)

  message(STATUS "Sundials include:")
  message(STATUS "${SUNDIALS_INLCUDE_HOME}")
  message(STATUS "Sundials library for omsicpp:")
  message(STATUS "${SUNDIALS_LIBRARY_RELEASE_HOME}")
  message(STATUS "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}")


  set(SUNDIALS_INCLUDE_DIR "${SUNDIALS_INLCUDE_HOME}")
  if(NOT EXISTS "${SUNDIALS_INLCUDE_HOME}/cvode/cvode.h")
    message(FATAL_ERROR "Could not find Sundials; compile omc first")
  endif()
  include_directories(${SUNDIALS_INCLUDE_DIR})

  find_library(SUNDIALS_NVECSERIAL_LIB "sundials_nvecserial" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)

  if(NOT SUNDIALS_NVECSERIAL_LIB)
    message(FATAL_ERROR "Could not find libsundials_nvecserial!")
  endif()
  get_filename_component(SUNDIALS_LIBS "${SUNDIALS_NVECSERIAL_LIB}" PATH)

  find_library(SUNDIALS_CVODES_LIB "sundials_cvodes"  NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  )
  if(NOT SUNDIALS_CVODES_LIB)
    message(FATAL_ERROR "Could not find libsundials_cvodes!")
  endif()

  find_library(SUNDIALS_CVODE_LIB "sundials_cvode" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  if(NOT SUNDIALS_CVODES_LIB)
    message(FATAL_ERROR "Could not find libsundials_cvodes!")
  endif()

  find_library(SUNDIALS_IDA_LIB "sundials_idas" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  if(NOT SUNDIALS_IDA_LIB)
    message(FATAL_ERROR "Could not find libsundials_ida!")
  endif()

  find_library(SUNDIALS_KINSOL_LIB "sundials_kinsol" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  if(NOT SUNDIALS_KINSOL_LIB)
    message(FATAL_ERROR "Could not find libsundials_kinsol!")
  endif()
  set(SUNDIALS_LIBRARIES ${SUNDIALS_NVECSERIAL_LIB} ${SUNDIALS_CVODE_LIB} ${SUNDIALS_CVODES_LIB} ${SUNDIALS_IDA_LIB} ${SUNDIALS_KINSOL_LIB})

  message(STATUS "Sundials Libraries for omsicpp:")
  message(STATUS "${SUNDIALS_LIBRARIES}")
  add_definitions(-DPMC_USE_SUNDIALS)

  # On Windows we need to install those libraries along with the SimManager
  if(WIN32)
    install(FILES ${SUNDIALS_LIBRARIES} DESTINATION bin)
  endif(WIN32)
endif(USE_SUNDIALS)



# Find FMI lib
if(USE_OMSI)

  if(MSVC)
    set(FMILIB_INLCUDE_HOME "${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/install_msvc/include")
    set(FMILIB_LIBRARY_RELEASE_HOME "${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/install_msvc/${LIB_OMC}")
    set(OMSIBASELIB_LIBRARY_RELEASE_HOME "${CMAKE_INSTALL_PREFIX}/lib/omc/omsi/msvc")
  elseif(WIN32)
    set(FMILIB_INLCUDE_HOME "${CMAKE_INSTALL_PREFIX}/include/omc/fmil")
    set(FMILIB_LIBRARY_RELEASE_HOME  "${CMAKE_INSTALL_PREFIX}/lib/omc")
    set(OMSIBASELIB_LIBRARY_RELEASE_HOME "${CMAKE_INSTALL_PREFIX}/lib/omc/omsi")
  else()
    set(FMILIB_INLCUDE_HOME "${CMAKE_SOURCE_DIR}/../../3rdParty/FMIL/install/include")
    set(FMILIB_LIBRARY_RELEASE_HOME  "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}")
    set(OMSIBASELIB_LIBRARY_RELEASE_HOME "${CMAKE_INSTALL_PREFIX}/${LIB_OMC}/omsi")
  endif()

  message(STATUS "FMI lib include:")
  message(STATUS "${FMILIB_INLCUDE_HOME}")
  message(STATUS "FMI lib library:")
  message(STATUS "${FMILIB_LIBRARY_RELEASE_HOME}")
  message(STATUS "OMSI lib library:")
  message(STATUS "${OMSIBASELIB_LIBRARY_RELEASE_HOME}")


  find_path(FMILIB_INCLUDE_DIR fmilib_config.h PATHS ${FMILIB_INLCUDE_HOME})
  if(NOT FMILIB_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find fmi library; compile omc first")
  else(NOT FMILIB_INCLUDE_DIR)
    include_directories(${FMILIB_INCLUDE_DIR})
  endif()

  find_library(FMILIB_LIB NAMES "fmilib_shared" "fmilib" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${FMILIB_LIBRARY_RELEASE_HOME} )
  if(NOT FMILIB_LIB)
    message(FATAL_ERROR "Could not find FMI library \"libfmilib\" or \"libfmilib_shared${CMAKE_SHARED_LIBRARY_SUFFIX}\" in ${FMILIB_LIBRARY_RELEASE_HOME}")
  endif()

  if(WIN32)
    set(FMILIB_LIB_EXTRA "shlwapi") # adrpo: we need to link with shlwapi on Windows for fmil
  endif(WIN32)

  # Find OMSIBase library
  find_library(OMSIBASE_LIB NAMES "OMSIBase" "OMSIBase_static" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${OMSIBASELIB_LIBRARY_RELEASE_HOME} )
  if(NOT OMSIBASE_LIB)
    message(STATUS "LIB_OMC = ${LIB_OMC}")
    message(FATAL_ERROR "Could not find OMSIBase library in: ${OMSIBASELIB_LIBRARY_RELEASE_HOME}")
  endif()


  message(STATUS "FMI-lib Libraries:")
  message(STATUS "${FMILIB_LIB}")


  message(STATUS "OMSI Libraries:")
  message(STATUS "${OMSIBASE_LIB}")
  message(STATUS "OMSI Includes:")
  message(STATUS "${CMAKE_SOURCE_DIR}/../OMSI/base/include")
  #omsi base includes
  include_directories ("${CMAKE_SOURCE_DIR}/../OMSI/base/include")
  #omsi solver includes
  include_directories ("${CMAKE_SOURCE_DIR}/../OMSI/solver/include")
  add_definitions(-DENABLE_OMSI)
  message(STATUS "OSI linear and nonlinear solver interface enabled")
  #set exapat lib for visual studio compiler used by omsi xml and json  parser
  if(MSVC)
    include_directories(${OMDEV_ESCAPED}/lib/expat-win32-msvc)
  endif(MSVC)


  # On Windows we need to install those libraries along with the SimManager
  if(WIN32)
    install(FILES ${FMILIB_LIB} DESTINATION bin)
  endif(WIN32)
endif(USE_OMSI)




# Find Klu solvers
if(USE_KLU)
  #set klu solvers include and library directories
  if(MSVC)
    set(Klu_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/SuiteSparse/install_msvc")

#            SET(KLU_INLCUDE_HOME  ${Klu_Path}/include/omc/c/suitesparse)
#    SET(KLU_LIBRARY_RELEASE_HOME  ${Klu_Path}/lib/omc)
  else(MSVC)
    set(Klu_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/SuiteSparse")
    #SET(Klu_Path ${CMAKE_SOURCE_DIR}/../../../build/include/omc/c/suitesparse) #"${CMAKE_SOURCE_DIR}/../../3rdParty/SuiteSparse")
  endif(MSVC)

  if(MSVC)
    set(KLU_INLCUDE_HOME ${Klu_Path}/include/omc/c/suitesparse) #${Klu_Path}/KLU/Include)
    set(KLU_LIBRARY_RELEASE_HOME ${Klu_Path}/lib/omc) #${Klu_Path}/build)
  else(MSVC)
    set(KLU_INLCUDE_HOME ${Klu_Path}/KLU/Include) #${Klu_Path}/KLU/Include)
    set(KLU_LIBRARY_RELEASE_HOME ${Klu_Path}/build) #${Klu_Path}/build)
  endif(MSVC)

  message(STATUS "Klu include:")
  message(STATUS "${KLU_INLCUDE_HOME}")
  message(STATUS "Klu library:")
  message(STATUS "${KLU_LIBRARY_RELEASE_HOME}")

  find_path(KLU_INCLUDE_DIR klu.h PATHS ${KLU_INLCUDE_HOME} $ENV{KLU_ROOT}/include)
  if(NOT KLU_INCLUDE_DIR)
    message(FATAL_ERROR "Could not find Klu, specify environment variable KLU_ROOT")
  else(NOT KLU_INCLUDE_DIR)
    include_directories(${KLU_INCLUDE_DIR})
  endif(NOT KLU_INCLUDE_DIR)

  find_library(KLU_LIB "klu" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${KLU_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  if(NOT KLU_LIB)
    message(FATAL_ERROR "Could not find klu library!")
  endif()

  find_library(AMD_LIB "amd" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${KLU_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  if(NOT AMD_LIB)
    message(FATAL_ERROR "Could not find klu amd library!")
  endif()

  find_library(BTF "btf" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${KLU_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  if(NOT BTF)
    message(FATAL_ERROR "Could not find klu btf library!")
  endif()

  find_library(COLAMD "colamd" NO_DEFAULT_PATH NO_SYSTEM_ENVIRONMENT_PATH PATHS ${KLU_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  if(NOT COLAMD)
    message(FATAL_ERROR "Could not find klu colamd library!")
  endif()

  set(KLU_LIBRARIES ${KLU_LIB} ${AMD_LIB} ${BTF} ${COLAMD})

  message(STATUS "Klu Libraries:")
  message(STATUS "${KLU_LIBRARIES}")
  add_definitions(-Dklu)
endif(USE_KLU)


#Handle umfpack
#FIND_PACKAGE(SuiteSparse)
if(SUITESPARSE_UMFPACK_FOUND)
  message(STATUS "Using UmfPack include path: ${SUITESPARSE_UMFPACK_INCLUDE_DIR}")
  include_directories(${SUITESPARSE_UMFPACK_INCLUDE_DIR})
  #ADD_DEFINITIONS(-DUSE_UMFPACK)
  set(SUITESPARSE_INCLUDE ${SUITESPARSE_UMFPACK_INCLUDE_DIR})
  set(UMFPACK_LIB ${SUITESPARSE_UMFPACK_LIBRARIES})
else(SUITESPARSE_UMFPACK_FOUND)
  message(STATUS "UmfPack disabled")
  set(SUITESPARSE_INCLUDE ".")
  set(UMFPACK_LIB "")
endif(SUITESPARSE_UMFPACK_FOUND)


#Handle Mico corba
if(USE_MICO)
  find_library(MICO_LIBRARY  mico2313
    PATHS ${MICO_LIB_HOME}) #you can add additional search paths for mico library
  find_path(MICO_INCLUDE_DIR CORBA.h
     ${MICO_INCLUDE_HOME}) #you can add additional search paths for mico include
  message(STATUS ${MICO_LIBRARY})
  message(STATUS ${MICO_INCLUDE_DIR})
endif(USE_MICO)
#Handle ZeroMQ


if(MSVC)
  set(ZeroMQ_DIR  "${CMAKE_SOURCE_DIR}/../../3rdParty/libzmq/build_msvc/share/cmake/ZeroMQ")
  set(cppzmq_DIR "${CMAKE_SOURCE_DIR}/../../3rdParty/cppzmq/build_msvc/share/cmake/cppzmq")
else(MSVC)
  set(ZeroMQ_DIR  "${CMAKE_SOURCE_DIR}/../../3rdParty/libzmq/build/share/cmake/ZeroMQ")
  set(cppzmq_DIR "${CMAKE_SOURCE_DIR}/../../3rdParty/cppzmq/build/share/cmake/cppzmq")
endif(MSVC)


find_package(ZeroMQ )
find_package(cppzmq )



if(ZeroMQ_FOUND AND cppzmq_FOUND)
  message(STATUS "zeromq type: ${CMAKE_BUILD_TYPE}")
  if((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))# workarround, find_package(ZeroMQ)  fails because wrong filename under windows and VS projects
    get_target_property(ZeroMQ_LIB libzmq  IMPORTED_IMPLIB_DEBUG)
    message(STATUS "Using workarround for ${ZeroMQ_LIB} " )
  else((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))
    set(ZeroMQ_LIB  ${ZeroMQ_LIBRARY})
  endif((MSVC) AND (CMAKE_BUILD_TYPE MATCHES Debug))

  message(STATUS "Using ZMQ library ${ZeroMQ_LIBRARY} ${ZeroMQ_LIB} " )
  message(STATUS "cppzmq version ${cppzmq_VERSION}")
  message(STATUS "Using ZMQ Header ${ZeroMQ_INCLUDE_DIR}" )
  message(STATUS "Using CPPZMQ Header ${cppzmq_INCLUDE_DIR}" )
else(ZeroMQ_found AND cppzmq_found)
  set(USE_ZEROMQ OFF)
  message(STATUS "Using not ZMQ library " )
endif(ZeroMQ_FOUND AND cppzmq_FOUND)

#Write the defines into the ADDITIONAL_DEFINES variable
# GET_DIRECTORY_PROPERTY(ADDITIONAL_DEFINES DEFINITIONS)
# message(STATUS "Generated compile definitions: ${ADDITIONAL_DEFINES}")
set(Boost_Library_folder  ${Boost_LIBRARY_DIRS} CACHE STRING "library directory" )
link_directories ( ${Boost_LIBRARY_DIRS} )


include_directories (${Boost_INCLUDE_DIR} ${cppzmq_INCLUDE_DIR} ${ZeroMQ_INCLUDE_DIR} )
include_directories ("${PROJECT_SOURCE_DIR}")
include_directories ("${PROJECT_BINARY_DIR}")
message(STATUS "Boost dirs '${Boost_LIBRARY_DIRS}', '${Boost_INCLUDE_DIR}'")

if(UNIX AND Boost_INCLUDE_DIR STREQUAL "/usr/include")
  # symlink boost includes outside platform specific /usr/include
  execute_process(COMMAND ln -sf /usr/include/boost ./)
endif(UNIX AND Boost_INCLUDE_DIR STREQUAL "/usr/include")


#include path for cpp simulation kernel
include_directories ("${CMAKE_SOURCE_DIR}/runtime/include/")
#include path for OpenModelica Simulation Interface (OMSI)
include_directories ("${CMAKE_SOURCE_DIR}/../OMSI/include/")

#set module names
set(MODELICA_MODEL "ModelicaSystem")
set(LIBPREFIX "OMCpp")
if(BUILD_SHARED_LIBS)
  set(LIBSUFFIX "")
else(BUILD_SHARED_LIBS)
  set(LIBSUFFIX "_static")
endif(BUILD_SHARED_LIBS)
set(SolverName ${LIBPREFIX}Solver${LIBSUFFIX})

set(OMCFactoryName ${LIBPREFIX}OMCFactory${LIBSUFFIX})
set(MathName ${LIBPREFIX}Math${LIBSUFFIX})
set(ModelicaExternalName ModelicaExternalC) # only static version
set(ModelicaTablesName ModelicaStandardTables) # only static version
set(LibZName zlib) # only static version
set(ModelicaMatIOName ModelicaMatIO) # only static version
set(SimulationSettings ${LIBPREFIX}SimulationSettings${LIBSUFFIX})
set(SimControllerName ${LIBPREFIX}SimController${LIBSUFFIX})
set(CVodeName ${LIBPREFIX}CVode${LIBSUFFIX})
set(IDAName ${LIBPREFIX}IDA${LIBSUFFIX})
set(PeerName ${LIBPREFIX}Peer${LIBSUFFIX})
set(CppDASSLName ${LIBPREFIX}CppDASSL${LIBSUFFIX})
set(EulerName ${LIBPREFIX}Euler${LIBSUFFIX})
set(RK12Name ${LIBPREFIX}RK12${LIBSUFFIX})
set(RTEulerName ${LIBPREFIX}RTEuler${LIBSUFFIX})
set(IdaName ${LIBPREFIX}Ida${LIBSUFFIX})
set(IdasName ${LIBPREFIX}Idas${LIBSUFFIX})
set(KinsolName ${LIBPREFIX}Kinsol${LIBSUFFIX})
set(LinearSolverName ${LIBPREFIX}LinearSolver${LIBSUFFIX})
set(DgesvSolverName ${LIBPREFIX}DgesvSolver${LIBSUFFIX})
set(ModelicaName ${LIBPREFIX}Modelica${LIBSUFFIX})
set(NewtonName ${LIBPREFIX}Newton${LIBSUFFIX})
set(BroydenName ${LIBPREFIX}Broyden${LIBSUFFIX})
set(HybrjName ${LIBPREFIX}Hybrj${LIBSUFFIX})
set(UmfPackName ${LIBPREFIX}UmfPack${LIBSUFFIX})
set(DataExchangeName ${LIBPREFIX}DataExchange${LIBSUFFIX})
set(ModelicaUtilitiesName ${LIBPREFIX}ModelicaUtilities${LIBSUFFIX})
set(ExtensionUtilitiesName ${LIBPREFIX}ExtensionUtilities${LIBSUFFIX})
set(BasiLibName ${LIBPREFIX}Base${LIBSUFFIX})
set(FMUName ${LIBPREFIX}FMU${LIBSUFFIX})
set(DgesvName ${LIBPREFIX}Dgesv_static) # only static version
set(OSUSimName ${LIBPREFIX}OSUSimulation${LIBSUFFIX})
set(OSUName ${LIBPREFIX}OSU${LIBSUFFIX})




# simulation kernel
add_subdirectory(runtime/src)



#get library names for dynamic loading and linking simulation kernel
# Helper function to extract library filename from target using generator expressions
# This replaces deprecated GET_TARGET_PROPERTY with LOCATION
function(get_target_filename TARGET_NAME OUTPUT_VAR)
  # Use file(GENERATE) with generator expression to extract filename at build time
  file(GENERATE OUTPUT "${CMAKE_BINARY_DIR}/get_target_filename_${TARGET_NAME}.cmake"
    CONTENT "file(WRITE \"${CMAKE_BINARY_DIR}/target_filename_${TARGET_NAME}.txt\" \"$<TARGET_FILE_NAME:${TARGET_NAME}>\")"
  )
  # For now, we'll use a simpler approach: just use the target name variable
  # Since we're extracting library names for configuration, we can derive them from the known target naming
  get_target_property(TARGET_TYPE ${TARGET_NAME} TYPE)
  if(TARGET_TYPE STREQUAL "SHARED_LIBRARY")
    set(${OUTPUT_VAR} "${CMAKE_SHARED_LIBRARY_PREFIX}${TARGET_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}" PARENT_SCOPE)
  else()
    set(${OUTPUT_VAR} "${CMAKE_STATIC_LIBRARY_PREFIX}${TARGET_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}" PARENT_SCOPE)
  endif()
endfunction()

if(USE_SUNDIALS)
  get_target_filename(${CVodeName} libCVodeName)
  get_target_filename(${IDAName} libIDAName)
  get_target_filename(${KinsolName} libKinsolName)

  set(CVODE_LIB ${libCVodeName})
  set(IDA_LIB ${libIDAName})
  set(KINSOL_LIB ${libKinsolName})
endif(USE_SUNDIALS)

get_target_filename(${LinearSolverName} libLinearSolverName)
get_target_filename(${DgesvSolverName} libDgesvSolverName)

if(BUILD_PEER)
  get_target_filename(${PeerName} libPeerName)
endif(BUILD_PEER)

if(OPENMP_FOUND AND SUITESPARSE_UMFPACK_FOUND)
  get_target_filename(${CppDASSLName} libCppDASSLName)
endif(OPENMP_FOUND AND SUITESPARSE_UMFPACK_FOUND)

get_target_filename(${NewtonName} libNewtonName)

if(BUILD_BROYDEN)
  get_target_filename(${BroydenName} libBroydenName)
endif(BUILD_BROYDEN)

get_target_filename(${UmfPackName} libUmfPackName)
get_target_filename(${EulerName} libEulerName)
get_target_filename(${RK12Name} libRK12Name)
get_target_filename(${RTEulerName} libRTEulerName)

if(USE_MINPACK)
  get_target_filename(${HybrjName} libHybrjName)
endif(USE_MINPACK)

get_target_filename(${SimulationSettings} libSetFactoryName)
get_target_filename(${ModelicaName} libModelicaName)
get_target_filename(${SystemBaseName} libSystemBaseName)
get_target_filename(${SystemOMSIName} libSystemOMSIName)
get_target_filename(${ExtendedSystemName} libExtendedSystemName)
get_target_filename(${SolverName} libSolverName)
get_target_filename(${SimControllerName} libSimControllerName)
get_target_filename(${MathName} libMathName)
get_target_filename(${DataExchangeName} libDataExchangeName)
get_target_filename(${OMCFactoryName} libSimObjFactoryName)
get_target_filename(${FMUName} libFMUName)
get_target_filename(${DgesvName} libDgesvName)

set(EULER_LIB ${libEulerName})
set(RK12_LIB ${libRK12Name})
set(RTEULER_LIB ${libRTEulerName})
set(SETTINGSFACTORY_LIB ${libSetFactoryName})
set(MODELICASYSTEM_LIB ${libModelicaName})
set(NEWTON_LIB ${libNewtonName})
set(BROYDEN_LIB ${libBroydenName})
set(PEER_LIB ${libPeerName})
set(CPPDASSL_LIB ${libCppDASSLName})
set(SYSTEMBASE_LIB ${libSystemBaseName})
set(SYSTEMOMSI_LIB ${libSystemOMSIName})
set(EXTENDEDSYSTEM_LIB ${libExtendedSystemName})
set(SOLVER_LIB ${libSolverName})
set(LINEARSOLVER_LIB ${libLinearSolverName})
set(DGESVSOLVER_LIB ${libDgesvSolverName})
set(MATH_LIB ${libMathName})
set(HYBRJ_LIB ${libHybrjName})
set(SIMOBJFACTORY_LIB ${libSimObjFactoryName})
set(DATAEXCHANGE_LIB ${libDataExchangeName})
set(SIMCONTROLLER_LIB ${libSimControllerName})

# configure a header file to pass some library names
# to the source code which are used to dynamic load and instantiate
configure_file (
  "${PROJECT_SOURCE_DIR}/runtime/src/LibrariesConfig.h.in"
  "${PROJECT_BINARY_DIR}/LibrariesConfig.h"
  )


# omsu simulation
add_subdirectory(omsi)



#install 3rdparty libraries
if(INSTALL_OMDEV_LIBS)
  if(USE_MICO)
    install (FILES "${MICO_LIBRARY}"   DESTINATION bin)
  endif()

  install (FILES "${LAPACK_lapack_LIBRARY}"   DESTINATION bin)
  install (FILES "${BLAS_blas_LIBRARY}"   DESTINATION bin)
endif()


macro(INSTALL_HEADERS_WITH_DIRECTORY HEADER_LIST)

  foreach(HEADER ${${HEADER_LIST}})
    string(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    string(REPLACE runtime/include "" DIR ${DIR})
    message(STATUS "copy to " include/omc/omsicpp/${DIR})
    install(FILES ${HEADER} DESTINATION include/omc/omsicpp/${DIR})
  endforeach(HEADER)

endmacro(INSTALL_HEADERS_WITH_DIRECTORY)




install (FILES "${PROJECT_BINARY_DIR}/LibrariesConfig.h" DESTINATION include/omc/omsicpp)

install (FILES "Licenses/sundials.license" DESTINATION share/omc/runtime/omsicpp/licenses)

#copy Utils/extension
set(HS 	runtime/include/Core/Utils/extension/adaptable_factory.hpp
        runtime/include/Core/Utils/extension/common.hpp
        runtime/include/Core/Utils/extension/convenience.hpp
        runtime/include/Core/Utils/extension/extension.hpp
        runtime/include/Core/Utils/extension/factory.hpp
        runtime/include/Core/Utils/extension/factory_map.hpp
        runtime/include/Core/Utils/extension/filesystem.hpp
        runtime/include/Core/Utils/extension/parameter.hpp
        runtime/include/Core/Utils/extension/parameter_map.hpp
        runtime/include/Core/Utils/extension/registry.hpp
        runtime/include/Core/Utils/extension/shared_library.hpp
        runtime/include/Core/Utils/extension/type_map.hpp
        runtime/include/Core/Utils/extension/logger.hpp
        runtime/include/Core/Utils/extension/impl/adaptable_factory.hpp
        runtime/include/Core/Utils/extension/impl/adaptable_factory_free_functions.hpp
        runtime/include/Core/Utils/extension/impl/adaptable_factory_set.hpp
        runtime/include/Core/Utils/extension/impl/create.hpp
        runtime/include/Core/Utils/extension/impl/create_func.hpp
        runtime/include/Core/Utils/extension/impl/decl.hpp
        runtime/include/Core/Utils/extension/impl/factory.hpp
        runtime/include/Core/Utils/extension/impl/factory_map.hpp
        runtime/include/Core/Utils/extension/impl/function.hpp
        runtime/include/Core/Utils/extension/impl/library_impl.hpp
        runtime/include/Core/Utils/extension/impl/shared_library.hpp
        runtime/include/Core/Utils/extension/impl/typeinfo.hpp
        runtime/include/FMU2/fmi2Functions.h
        runtime/include/FMU2/fmi2FunctionTypes.h
        runtime/include/FMU2/fmi2TypesPlatform.h
        runtime/include/FMU2/FMU2GlobalSettings.h
        runtime/include/FMU2/FMU2Interface.cpp
        runtime/include/FMU2/FMU2Wrapper.cpp
        runtime/include/FMU2/FMU2Wrapper.h)
INSTALL_HEADERS_WITH_DIRECTORY(HS)
if(UNIX AND Boost_INCLUDE_DIR STREQUAL "/usr/include")
  # symlink boost includes outside platform specific /usr/include
  install(CODE "execute_process(COMMAND ln -sf /usr/include/boost \"${CMAKE_INSTALL_PREFIX}/include/omc/omsicpp/\")")
endif(UNIX AND Boost_INCLUDE_DIR STREQUAL "/usr/include")
