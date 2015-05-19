# This script will build and install all required libraries of the C++ Simulation-runtime
#
# The following conditional defines are passed to the c++ compiler:
#     if the Boost_log and Boost_setup_log libraries were found                    -DUSE_BOOST_LOG
#     if the Boost_thread library was found                                        -DUSE_BOOST_THREAD
#     if the UMFPack library of SuiteSparse was found                              -DUSE_UMFPACK
#     if the PAPI library was found                                                -DUSE_PAPI
#     if the Sundials libraries were found                                         -DPMC_USE_SUNDIALS
#     if the runtime is build for the OMC                                          -DOMC_BUILD
#     if the write-output functionality should be handled in parallel              -DUSE_PARALLEL_OUTPUT
#     if ScoreP should be used for performance analysis                            -DUSE_SCOREP
#     if the Intel TBB library was found                                           -DUSE_INTEL_TBB
#     if the Pugi XML library was found                                            -DUSE_PUGI_XML
#     if profiling for the simulation runtime should be enabled                    -DRUNTIME_PROFILING
#
# Some of these options can be controlled by passing arguments to CMAKE
#     if all runtime libraries should be built and linked statically               -DRUNTIME_STATIC_LINKING=ON
#     if write output should be handled in parallel                                -DUSE_PARALLEL_OUTPUT=ON
#     if ScoreP should be used for performance analysis                            -DUSE_SCOREP=ON
#     if the boost libraries should be linked statically                           -DBOOST_STATIC_LINKING=ON
#     if the lapack functions and data structurs of sundials should be used        -DSUNDIALS_LAPACK=ON
#     if boost libraries should be linked against absolute path libraries          -DUSE_BOOST_REALPATHS=ON
#
#     Example: "cmake -DRUNTIME_STATIC_LINKING=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo" to create statically linked libraries
#
# The used defines are stored in the SYSTEM_CFLAGS variable, which is passed to the ModelicaConfig.inc and written in the PrecompiledHeader.cmake

CMAKE_MINIMUM_REQUIRED (VERSION 2.8.6)
PROJECT(CppSolverInterface)
set(CMAKE_VERBOSE_MAKEFILE ON)
LIST(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/CMake")

MESSAGE(STATUS "CMake version ${CMAKE_MAJOR_VERSION}.${CMAKE_MINOR_VERSION}.${CMAKE_PATCH_VERSION}")

#Set Options
OPTION(RUNTIME_STATIC_LINKING "RUNTIME_STATIC_LINKING" OFF)
OPTION(USE_PARALLEL_OUTPUT "USE_PARALLEL_OUTPUT" OFF)
OPTION(USE_SCOREP "USE_SCOREP" OFF)
OPTION(BOOST_STATIC_LINKING "BOOST_STATIC_LINKING" OFF)
OPTION(RUNTIME_PROFILING "RUNTIME_PROFILING" OFF)
OPTION(SUNDIALS_ROOT "SUNDIALS ROOT" "")


#Set Variables
SET(MODELICAEXTERNALCDIR  "${CMAKE_SOURCE_DIR}/../../3rdParty/ModelicaExternalC/C-Sources")
SET(USERTABDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/Data/Tables")

SET(LIBINSTALLEXT "lib/omc/cpp" CACHE STRING "library directory")
SET(MODELICA_MODEL "ModelicaSystem")
SET(LIBPREFIX "OMCpp")
SET(SolverName ${LIBPREFIX}Solver)
SET(SystemName ${LIBPREFIX}System)
SET(OMCFactoryName ${LIBPREFIX}OMCFactory)
SET(MathName ${LIBPREFIX}Math)
SET(ModelicaExternalName ModelicaExternalC)
SET(ModelicaTablesName ModelicaStandardTables)
SET(SimulationSettings ${LIBPREFIX}SimulationSettings)
SET(SimControllerName ${LIBPREFIX}SimController)
SET(CVodeName ${LIBPREFIX}CVode)
SET(IDAName ${LIBPREFIX}IDA)
SET(PeerName ${LIBPREFIX}Peer)
SET(RTRKName ${LIBPREFIX}RTRK)
SET(EulerName ${LIBPREFIX}Euler)
SET(RTEulerName ${LIBPREFIX}RTEuler)
SET(IdaName ${LIBPREFIX}Ida)
SET(IdasName ${LIBPREFIX}Idas)
SET(KinsolName ${LIBPREFIX}Kinsol)
SET(ModelicaName ${LIBPREFIX}Modelica)
SET(NewtonName ${LIBPREFIX}Newton)
SET(HybrjName ${LIBPREFIX}Hybrj)
SET(UmfPackName ${LIBPREFIX}UmfPack)
SET(DataExchangeName ${LIBPREFIX}DataExchange)
SET(ModelicaUtilitiesName ${LIBPREFIX}ModelicaUtilities)
SET(ExtensionUtilitiesName ${LIBPREFIX}ExtensionUtilities)
SET(BasiLibName ${LIBPREFIX}Base)
SET(ModelicaCompilerName ${LIBPREFIX}ModelicaCompiler)

SET(USE_MICO OFF)
SET(REDUCE_DAE OFF)
SET(USE_SUNDIALS ON)
SET(OMC_BUILD ON)
SET(SIMSTER_BUILD OFF)

SET(Boost_USE_MULTITHREADED ON)

IF(USE_BOOST_REALPATHS)
  MESSAGE(STATUS "Using boost real paths")
  SET(Boost_REALPATH ON)
ELSE(USE_BOOST_REALPATHS)
  MESSAGE(STATUS "Boost real paths disabled")
ENDIF(USE_BOOST_REALPATHS)

INCLUDE(${CMAKE_SOURCE_DIR}/PrecompiledHeader.cmake)

#Handle static boost linking
IF(NOT BOOST_STATIC_LINKING)
  SET(Boost_USE_STATIC_LIBS OFF)
  SET(Boost_USE_STATIC_RUNTIME OFF)
ELSE(NOT BOOST_STATIC_LINKING)
  SET(Boost_USE_STATIC_LIBS ON)
  SET(Boost_USE_STATIC_RUNTIME ON)
  ADD_DEFINITIONS(-DBOOST_STATIC_LINKING)
ENDIF(NOT BOOST_STATIC_LINKING)

# Handle static linking
IF(NOT RUNTIME_STATIC_LINKING)
  MESSAGE(STATUS "Static build and linking of runtime disabled")
ELSE(NOT RUNTIME_STATIC_LINKING)
  MESSAGE(STATUS "Build and linking runtime statically")
  ADD_DEFINITIONS(-DRUNTIME_STATIC_LINKING)
ENDIF(NOT RUNTIME_STATIC_LINKING)

# Handle sundials lapack
IF(NOT SUNDIALS_LAPACK)
  MESSAGE(STATUS "Sundials lapack functions disabled")
ELSE(NOT SUNDIALS_LAPACK)
  MESSAGE(STATUS "Using Sundials lapack functions")
  ADD_DEFINITIONS(-DUSE_SUNDIALS_LAPACK)
ENDIF(NOT SUNDIALS_LAPACK)

# Handle parallel output
IF(USE_PARALLEL_OUTPUT)
  ADD_DEFINITIONS(-DUSE_PARALLEL_OUTPUT)
  MESSAGE(STATUS "Using parallel output")
ELSE(USE_PARALLEL_OUTPUT)
  MESSAGE(STATUS "Parallel output disabled")
ENDIF(USE_PARALLEL_OUTPUT)

# Handle ScoreP
IF(USE_SCOREP)
  ADD_DEFINITIONS(-DUSE_SCOREP)
  MESSAGE(STATUS "ScoreP enabled")
ELSE(USE_SCOREP)
  MESSAGE(STATUS "ScoreP disabled")
ENDIF(USE_SCOREP)

# Handle runtime profiling
IF(RUNTIME_PROFILING)
  ADD_DEFINITIONS(-DRUNTIME_PROFILING)
  MESSAGE(STATUS "Runtime profiling enabled")
ELSE(RUNTIME_PROFILING)
  MESSAGE(STATUS "Runtime profiling disabled")
ENDIF(RUNTIME_PROFILING)

# Handle build type
IF(OMC_BUILD)
  ADD_DEFINITIONS(-DOMC_BUILD)
ELSEIF(SIMSTER_BUILD)
  ADD_DEFINITIONS(-DSIMSTER_BUILD)
ENDIF(OMC_BUILD)


# Handle OMDEV
#  - On windows boost,blas,lapack and sundial solvers from omdev are used else the installed versions are used
IF(WIN32)
  SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost-1_55/")
  SET(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll CACHE FILEPATH "Blas library")
  SET(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll CACHE FILEPATH "Lapack library")
  SET(BLAS_DIRY "$ENV{OMDEV}/lib/3rdParty/Lapack/Lib/" CACHE LOCATION "where was yarp built?")

  # Disable Optimization for RelWithDebInfo on Windows
  IF(MSVC)
    STRING(REPLACE "/O2" "/Od" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
  ELSE(MSVC)
    STRING(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
    STRING(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
  ENDIF(MSVC)

  #set mico paths
  SET(MICO_LIB_HOME $ENV{OMDEV}/lib/mico-msys-mingw/)
  SET(MICO_INCLUDE_HOME  $ENV{OMDEV}/include/mico-msys-mingw/)
  #set sundials solvers include and library directories
  SET(SUNDIALS_INLCUDE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/include)

  IF(MSVC)
    SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/vc100)
  ELSEIF(MINGW)
    SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/mingw/dlls)
  ENDIF(MSVC)

  SET(INSTALL_OMDEV_LIBS ON)
ENDIF(WIN32)


# Find CMinpack
# Note: Visual Studio libs are located in install/msvc, libs for gcc are directly in install
IF(MSVC)
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install_msvc")
ELSE(MSVC)
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/build")
ENDIF(MSVC)

FIND_PATH(CMINPACK_INCLUDE_DIR cminpack.h
          HINTS ${CMinpack_Path}
          PATH_SUFFIXES include include/cminpack include/cminpack-1 ..)

FIND_LIBRARY(CMINPACK_LIBRARY
             NAMES cminpack
             HINTS ${CMinpack_Path}
             PATH_SUFFIXES lib lib64)

INCLUDE_DIRECTORIES(${CMINPACK_INCLUDE_DIR})

# Find Intel TBB
FIND_PACKAGE(TBB)
IF(TBB_FOUND)
  ADD_DEFINITIONS(-DUSE_INTEL_TBB)
  MESSAGE (STATUS "Using Intel TBB")
ELSE(TBB_FOUND)
  MESSAGE (STATUS "Intel TBB disabled")
ENDIF(TBB_FOUND)

# Find Pugi XML
FIND_PACKAGE(PugiXML)
IF(PUGIXML_FOUND)
  ADD_DEFINITIONS(-DUSE_PUGI_XML)
  MESSAGE (STATUS "Using Pugi XML")
ELSE(PUGIXML_FOUND)
  MESSAGE (STATUS "Pugi XML disabled")
ENDIF(PUGIXML_FOUND)

# Find PAPI
FIND_LIBRARY(PAPI_LIBRARIES NAMES libpapi.a papi)
FIND_PATH(PAPI_INCLUDE_DIRS NAMES papi.h)
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PAPI DEFAULT_MSG PAPI_LIBRARIES PAPI_INCLUDE_DIRS)
IF(PAPI_FOUND)
  ADD_DEFINITIONS(-DUSE_PAPI)
ENDIF(PAPI_FOUND)


# Find Boost
#  - The optional boost libraries must be searched separately, otherwise no library is found if just one is missing.
#  - Additionaly the Boost_LIBRARIES variable is overwritten each time find_package(Boost ...) is called, thus it must be rescued
FIND_PACKAGE(Boost COMPONENTS log log_setup)

SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
IF(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)
  ADD_DEFINITIONS(-DUSE_BOOST_LOG)
  MESSAGE(STATUS "Using boost log")
ELSE(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)
  MESSAGE(STATUS "Boost log disabled")
  UNSET(Boost_LOG_LIBRARY)
ENDIF(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)

FIND_PACKAGE(Boost COMPONENTS thread atomic)

SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
FIND_PACKAGE(Threads)
IF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
  ADD_DEFINITIONS(-DUSE_BOOST_THREAD)
  MESSAGE(STATUS "Using boost thread")
ELSE(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
  MESSAGE(STATUS "Boost thread disabled")
ENDIF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)

FIND_PACKAGE(Boost REQUIRED COMPONENTS filesystem system serialization program_options)
SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
SET(Boost_LIBRARIES ${Boost_LIBRARIES_TMP})
MESSAGE(STATUS "Boost Libraries")
MESSAGE(STATUS ${Boost_LIBRARIES})


# Find Lapack and Blas
FIND_PACKAGE(BLAS)
FIND_PACKAGE(LAPACK)

IF(MSVC)
  #workaround  because cmake does not find the lapack libraries for Visual Studio 10
  SET(LAPACK_MSVC_10  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.lib  )
  SET(BLAS_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.lib )
  SET(LAPACK_LIBRARIES  ${LAPACK_MSVC_10}   ${BLAS_MSVC_10} )

ELSEIF(MINGW)
  SET(LAPACK_MINGW  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll  )
  SET(BLAS_MINGW $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll )
  SET(LAPACK_LIBRARIES  ${LAPACK_MINGW}   ${BLAS_MINGW} )
ENDIF(MSVC)

FIND_LIBRARY(mkl_rt mkl_rt)
IF (mkl_rt)
  #workaround because find_package(lapack)-command returns the wrong libraries on Taurus (ZIH-TU Dresden)
  SET(LAPACK_LIBRARIES ${mkl_rt})
ENDIF(mkl_rt)

LIST(LENGTH LAPACK_LIBRARIES LAPACKVARCOUNT)
IF(LAPACKVARCOUNT GREATER 0)
  LIST(GET LAPACK_LIBRARIES 0 LAPACKLISTHEAD)
  GET_FILENAME_COMPONENT(LAPACKLISTHEAD "${LAPACKLISTHEAD}" PATH)
  SET(LAPACK_LIBS "${LAPACKLISTHEAD}")
ENDIF()

MESSAGE(STATUS "Lapack Libraries")
MESSAGE(STATUS ${LAPACK_LIBRARIES})


# Find Sundials solvers
IF(USE_SUNDIALS)
  FIND_PATH(SUNDIALS_INCLUDE_DIR cvode/cvode.h PATHS ${SUNDIALS_INLCUDE_HOME} $ENV{SUNDIALS_ROOT}/include)
  IF (NOT SUNDIALS_INCLUDE_DIR)
    MESSAGE(FATAL_ERROR "Could not find Sundials, specify environment variable SUNDIALS_ROOT")
  ELSE(NOT SUNDIALS_INCLUDE_DIR)
    FIND_PATH(SUNDIALS_CONFIG_FILE "sundials_config.h" ${SUNDIALS_INCLUDE_DIR} "${SUNDIALS_INCLUDE_DIR}/sundials")
    SET(SUNDIALS_CONFIG_FILE "${SUNDIALS_CONFIG_FILE}/sundials_config.h")
    FILE(READ "${SUNDIALS_CONFIG_FILE}" SUNDIALS_CONFIG_FILE_CONTENT)
    STRING(REGEX MATCH "#define SUNDIALS_PACKAGE_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." SUNDIALS_CONFIG_FILE_CONTENT ${SUNDIALS_CONFIG_FILE_CONTENT})
    STRING(REGEX REPLACE "#define SUNDIALS_PACKAGE_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." "\\1;\\2;\\3" SUNDIALS_CONFIG_FILE_VERSION ${SUNDIALS_CONFIG_FILE_CONTENT})
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 0 SUNDIALS_MAJOR_VERSION)
    IF(SUNDIALS_MAJOR_VERSION)
      ADD_DEFINITIONS("-DSUNDIALS_MAJOR_VERSION=${SUNDIALS_MAJOR_VERSION}")
    ELSE()
      MESSAGE(FATAL_ERROR "Could not determine sundials version")
    ENDIF()
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 1 SUNDIALS_MINOR_VERSION)
    IF(SUNDIALS_MINOR_VERSION)
      ADD_DEFINITIONS("-DSUNDIALS_MINOR_VERSION=${SUNDIALS_MINOR_VERSION}")
    ELSE()
      MESSAGE(FATAL_ERROR "Could not determine sundials version")
    ENDIF()
    LIST(GET SUNDIALS_CONFIG_FILE_VERSION 2 SUNDIALS_PATCH_VERSION)
    MESSAGE(STATUS "Using sundials ${SUNDIALS_MAJOR_VERSION}.${SUNDIALS_MINOR_VERSION}.${SUNDIALS_PATCH_VERSION}")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_NVECSERIAL_LIB "sundials_nvecserial" PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_NVECSERIAL_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_nvecserial!")
  ENDIF()
  GET_FILENAME_COMPONENT(SUNDIALS_LIBS "${SUNDIALS_NVECSERIAL_LIB}" PATH)

  FIND_LIBRARY(SUNDIALS_CVODES_LIB "sundials_cvodes" PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  $ENV{SUNDIALS_ROOT}/lib)
  include_directories(${SUNDIALS_INCLUDE_DIR}/cvodes ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
  IF(NOT SUNDIALS_CVODES_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_cvodes!")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_IDA_LIB "sundials_idas" PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME}  $ENV{SUNDIALS_ROOT}/lib)
  include_directories(${SUNDIALS_INCLUDE_DIR}/ida ${SUNDIALS_INCLUDE_DIR}/nvector  ${SUNDIALS_INCLUDE_DIR}/sundials ${SUNDIALS_INCLUDE_DIR})
  IF(NOT SUNDIALS_IDA_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_ida!")
  ENDIF()

  FIND_LIBRARY(SUNDIALS_KINSOL_LIB "sundials_kinsol" PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} $ENV{SUNDIALS_ROOT}/lib)
  IF(NOT SUNDIALS_KINSOL_LIB)
    MESSAGE(FATAL_ERROR "Could not find libsundials_kinsol!")
  ENDIF()
  SET(SUNDIALS_LIBRARIES ${SUNDIALS_NVECSERIAL_LIB} ${SUNDIALS_CVODES_LIB} ${SUNDIALS_IDA_LIB} ${SUNDIALS_KINSOL_LIB})

  MESSAGE(STATUS "Sundials Libraries:")
  MESSAGE(STATUS "${SUNDIALS_LIBS}")
  ADD_DEFINITIONS(-DPMC_USE_SUNDIALS)

  # On Windows we need to install those libraries along with the SimManager
  IF(WIN32)
    INSTALL(FILES ${SUNDIALS_LIBRARIES} DESTINATION bin)
  ENDIF(WIN32)
ENDIF(USE_SUNDIALS)


#Handle umfpack
FIND_PACKAGE(SuiteSparse)
IF(SUITESPARSE_UMFPACK_FOUND)
  MESSAGE(STATUS "Using UmfPack")
  INCLUDE_DIRECTORIES(${SUITESPARSE_UMFPACK_INCLUDE_DIR})
  ADD_DEFINITIONS(-DUSE_UMFPACK)
    SET(SUITESPARSE_INCLUDE ${SUITESPARSE_UMFPACK_INCLUDE_DIR})
  SET(UMFPACK_LIB ${SUITESPARSE_UMFPACK_LIBRARIES})
ELSE(SUITESPARSE_UMFPACK_FOUND)
  MESSAGE(STATUS "UmfPack disabled")
  SET(SUITESPARSE_INCLUDE ".")
  SET(UMFPACK_LIB "")
ENDIF(SUITESPARSE_UMFPACK_FOUND)


#Handle Mico corba
IF(USE_MICO)
  FIND_LIBRARY(MICO_LIBRARY  mico2313
    PATHS ${MICO_LIB_HOME}) #you can add additional search paths for mico library
  FIND_PATH(MICO_INCLUDE_DIR CORBA.h
     ${MICO_INCLUDE_HOME}) #you can add additional search paths for mico include
  MESSAGE(STATUS ${MICO_LIBRARY})
  MESSAGE(STATUS ${MICO_INCLUDE_DIR})
ENDIF(USE_MICO)


#Write the defines into the ADDITIONAL_DEFINES variable
# GET_DIRECTORY_PROPERTY(ADDITIONAL_DEFINES DEFINITIONS)
# message(STATUS "Generated compile definitions: ${ADDITIONAL_DEFINES}")

link_directories ( ${Boost_LIBRARY_DIRS} )


include_directories (${Boost_INCLUDE_DIR})
include_directories ("${PROJECT_SOURCE_DIR}")
include_directories ("${PROJECT_BINARY_DIR}")

message(STATUS "Boost dirs '${Boost_LIBRARY_DIRS}', '${Boost_INCLUDE_DIR}'")
#set (CMAKE_CXX_FLAGS "-Winvalid-pch")
#build of simulation.core
include_directories ("Include")
include_directories ("Solver")
add_subdirectory (Core/Modelica)
add_subdirectory (Core/Math)
add_subdirectory (SimCoreFactory/OMCFactory)
#add_subdirectory (ModelicaCompiler)

add_subdirectory (Core/Utils/Modelica)
add_subdirectory (Core/Utils/extension)
add_subdirectory (Core/DataExchange)


#add system default implemention project
add_subdirectory (Core/System)
#add solver default implemention project
add_subdirectory (Core/Solver)
add_subdirectory (Core/SimulationSettings)
add_subdirectory (Core/ModelicaExternalC)
add_subdirectory (Core/SimController)

#add  Euler solver project
add_subdirectory (Solver/Euler)
add_subdirectory (Solver/RTEuler)
add_subdirectory (Solver/Newton)
add_subdirectory (Solver/Hybrj)
add_subdirectory (Solver/UmfPack)
add_subdirectory (Solver/Peer)
##add_subdirectory (Solver/RTRK)


if(REDUCE_DAE)
  #add_subdirectory(ReduceDAE/Implementation)
endif()



if(USE_SUNDIALS)
#add  Cvode solver project
add_subdirectory (Solver/CVode)
add_subdirectory(Solver/IDA)
add_subdirectory (Solver/Kinsol)
#add  Idas solver project
##add_subdirectory (Solver/Idas/Implementation)
##add_subdirectory (Solver/Ida/Implementation)
GET_TARGET_PROPERTY(libCVode ${CVodeName} LOCATION)
GET_FILENAME_COMPONENT(libCVodeName ${libCVode} NAME)

GET_TARGET_PROPERTY(libIDA ${IDAName} LOCATION)
GET_FILENAME_COMPONENT(libIDAName ${libIDA} NAME)

GET_TARGET_PROPERTY(libKinsol ${KinsolName} LOCATION)
GET_FILENAME_COMPONENT(libKinsolName ${libKinsol} NAME)
#GET_TARGET_PROPERTY(libIdas ${IdasName} LOCATION)
#GET_FILENAME_COMPONENT(libIdasName ${libIdas} NAME)
#GET_TARGET_PROPERTY(libIda ${IdaName} LOCATION)
#GET_FILENAME_COMPONENT(libIdaName ${libIda} NAME)

#set (IDAS_LIB ${libIdasName})
set (CVODE_LIB ${libCVodeName})
set(IDA_LIB ${libIDAName})
set (KINSOL_LIB ${libKinsolName})
#set (IDA_LIB ${libIdaName})
endIf()

GET_TARGET_PROPERTY(libPeer ${PeerName} LOCATION)
GET_FILENAME_COMPONENT(libPeerName ${libPeer} NAME)

GET_TARGET_PROPERTY(libRTRK ${RTRKName} LOCATION)
GET_FILENAME_COMPONENT(libRTRKName ${libRTRK} NAME)

GET_TARGET_PROPERTY(libNewton ${NewtonName} LOCATION)
GET_FILENAME_COMPONENT(libNewtonName ${libNewton} NAME)

GET_TARGET_PROPERTY(libUmfPack ${UmfPackName} LOCATION)
GET_FILENAME_COMPONENT(libUmfPackName ${libUmfPack} NAME)

GET_TARGET_PROPERTY(libEuler ${EulerName} LOCATION)
GET_FILENAME_COMPONENT(libEulerName ${libEuler} NAME)

GET_TARGET_PROPERTY(libRTEuler ${RTEulerName} LOCATION)
GET_FILENAME_COMPONENT(libRTEulerName ${libRTEuler} NAME)

GET_TARGET_PROPERTY(libHybrj ${HybrjName} LOCATION)
GET_FILENAME_COMPONENT(libHybrjName ${libHybrj} NAME)


GET_TARGET_PROPERTY(libSetFactory ${SimulationSettings} LOCATION)
GET_FILENAME_COMPONENT(libSetFactoryName ${libSetFactory} NAME)

GET_TARGET_PROPERTY(libModelica ${ModelicaName} LOCATION)
GET_FILENAME_COMPONENT(libModelicaName ${libModelica} NAME)

GET_TARGET_PROPERTY(libSystem ${SystemName} LOCATION)
GET_FILENAME_COMPONENT(libSystemName ${libSystem} NAME)

GET_TARGET_PROPERTY(libSolver ${SolverName} LOCATION)
GET_FILENAME_COMPONENT(libSolverName ${libSolver} NAME)

GET_TARGET_PROPERTY(libSimController ${SimControllerName} LOCATION)
GET_FILENAME_COMPONENT(libSimControllerName ${libSimController} NAME)

GET_TARGET_PROPERTY(libMath ${MathName} LOCATION)
GET_FILENAME_COMPONENT(libMathName ${libMath} NAME)

GET_TARGET_PROPERTY(libDataExchange ${DataExchangeName} LOCATION)
GET_FILENAME_COMPONENT(libDataExchangeName ${libDataExchange} NAME)

GET_TARGET_PROPERTY(libModelicaCompiler ${ModelicaCompilerName} LOCATION)
GET_FILENAME_COMPONENT(libModelicaCompilerName ${libModelicaCompiler} NAME)

GET_TARGET_PROPERTY(libSimObjFactory ${OMCFactoryName} LOCATION)
GET_FILENAME_COMPONENT(libSimObjFactoryName ${libSimObjFactory} NAME)

set (EULER_LIB ${libEulerName})
set (RTEULER_LIB ${libRTEulerName})
set (SETTINGSFACTORY_LIB ${libSetFactoryName})
set (MODELICASYSTEM_LIB ${libModelicaName})
set (NEWTON_LIB ${libNewtonName})
set (UMFPACK_LIB ${libUmfPackName})
set (PEER_LIB ${libPeerName})
set (RTRK_LIB ${libRTRKName})
set (SYSTEM_LIB ${libSystemName})
set (SOLVER_LIB ${libSolverName})
set (MATH_LIB ${libMathName})
set (HYBRJ_LIB ${libHybrjName})
set (SIMOBJFACTORY_LIB ${libSimObjFactoryName})
set (DATAEXCHANGE_LIB ${libDataExchangeName})
set (SIMCONTROLLER_LIB ${libSimControllerName})
set (EXTENSIONUTILITIES_LIB ${libExtensionUtilitiesName})
set (MODELICACOMPILER_LIB ${libModelicaCompilerName})

# configure a header file to pass some library names
# to the source code which are used to dynamic load and instantiate
configure_file (
  "${PROJECT_SOURCE_DIR}/LibrariesConfig.h.in"
  "${PROJECT_BINARY_DIR}/LibrariesConfig.h"
  )

if(INSTALL_OMDEV_LIBS)
  #if(USE_SUNDIALS)
  #  install (FILES "${SUNDIALS_NVECSERIAL_LIB}"  "${SUNDIALS_IDAS_LIB}" "${SUNDIALS_IDA_LIB}" "${SUNDIALS_CVODES_LIB}" DESTINATION bin)
  #endif(USE_SUNDIALS)

  if(USE_MICO)
    install (FILES "${MICO_LIBRARY}"   DESTINATION bin)
  endif()

  install (FILES "${LAPACK_lapack_LIBRARY}"   DESTINATION bin)
  install (FILES "${BLAS_blas_LIBRARY}"   DESTINATION bin)
  #install (FILES "${BOOST_SERIALIZATION_LIBRARY_RELEASE}"   DESTINATION bin)
endif()


MACRO(INSTALL_HEADERS_WITH_DIRECTORY HEADER_LIST)

FOREACH(HEADER ${${HEADER_LIST}})
    STRING(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    STRING(REPLACE Include "" DIR ${DIR})
  #message(STATUS "copy to "include/omc/cpp/${DIR})
  INSTALL(FILES ${HEADER} DESTINATION include/omc/cpp/${DIR})
ENDFOREACH(HEADER)

ENDMACRO(INSTALL_HEADERS_WITH_DIRECTORY)




install (FILES "${PROJECT_BINARY_DIR}/LibrariesConfig.h" DESTINATION include/omc/cpp)



 #copy Utils/extension
 SET(HS Include/Core/Object/IObject.h
        Include/Core/Object/Object.h
        Include/Core/Utils/extension/adaptable_factory.hpp
        Include/Core/Utils/extension/common.hpp
        Include/Core/Utils/extension/convenience.hpp
        Include/Core/Utils/extension/extension.hpp
        Include/Core/Utils/extension/factory.hpp
        Include/Core/Utils/extension/factory_map.hpp
        Include/Core/Utils/extension/filesystem.hpp
        Include/Core/Utils/extension/parameter.hpp
        Include/Core/Utils/extension/parameter_map.hpp
        Include/Core/Utils/extension/registry.hpp
        Include/Core/Utils/extension/shared_library.hpp
        Include/Core/Utils/extension/type_map.hpp
        Include/Core/Utils/extension/impl/adaptable_factory.hpp
        Include/Core/Utils/extension/impl/adaptable_factory_free_functions.hpp
        Include/Core/Utils/extension/impl/adaptable_factory_set.hpp
        Include/Core/Utils/extension/impl/create.hpp
        Include/Core/Utils/extension/impl/create_func.hpp
        Include/Core/Utils/extension/impl/decl.hpp
        Include/Core/Utils/extension/impl/factory.hpp
        Include/Core/Utils/extension/impl/factory_map.hpp
        Include/Core/Utils/extension/impl/function.hpp
        Include/Core/Utils/extension/impl/library_impl.hpp
        Include/Core/Utils/extension/impl/shared_library.hpp
        Include/Core/Utils/extension/impl/typeinfo.hpp
        Include/FMU/fmiModelFunctions.h
        Include/FMU/fmiModelTypes.h
        Include/FMU/FMUGlobalSettings.h
        Include/FMU/IFMUInterface.h
        Include/FMU/FMULibInterface.cpp
        Include/FMU/FMUWrapper.cpp
        Include/FMU/FMUWrapper.h
        Include/FMU2/fmi2Functions.h
        Include/FMU2/fmi2FunctionTypes.h
        Include/FMU2/fmi2TypesPlatform.h
        Include/FMU2/FMU2GlobalSettings.h
        Include/FMU2/FMU2Interface.cpp
        Include/FMU2/FMU2Wrapper.cpp
        Include/FMU2/FMU2Wrapper.h)
   INSTALL_HEADERS_WITH_DIRECTORY(HS)
