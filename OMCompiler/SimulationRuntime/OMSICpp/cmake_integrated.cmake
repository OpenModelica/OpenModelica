# cmake_integrated.cmake
#
# Configures the OMSICpp runtime as a subdirectory of the full OpenModelica
# CMake build (OPENMODELICA_NEW_CMAKE_BUILD=ON). Uses CMake targets from the
# parent project instead of find_library() calls, and derives install paths
# from CMAKE_INSTALL_LIBDIR rather than the LIB_OMC Makefile variable.
#
# This file is included (not add_subdirectory'd) from OMSICpp/CMakeLists.txt
# when OPENMODELICA_NEW_CMAKE_BUILD is set, and execution returns to the caller
# immediately afterward via return().

cmake_minimum_required(VERSION 3.14)
set(CMAKE_VERBOSE_MAKEFILE ON)

# Make OMSICpp-specific CMake modules available (PrecompiledHeader, CheckCXX11, …)
list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake")
include(${CMAKE_CURRENT_SOURCE_DIR}/CMake/PrecompiledHeader.cmake)
include(${CMAKE_CURRENT_SOURCE_DIR}/CMake/CheckCXX11.cmake)

set(CMAKE_POSITION_INDEPENDENT_CODE ON)

# ── Install directory ──────────────────────────────────────────────────────────
# In the Makefile build LIBINSTALLEXT is ${OMBUILDDIR}/${LIB_OMC}/omsicpp.
# In the CMake build we derive the equivalent from CMAKE_INSTALL_LIBDIR.
if(MSVC)
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsicpp/msvc")
else()
  set(LIBINSTALLEXT "${CMAKE_INSTALL_LIBDIR}/omsicpp")
endif()
message(STATUS "OMSICpp libs will be installed in ${CMAKE_INSTALL_PREFIX}/${LIBINSTALLEXT}")

# ── Always build shared libs ──────────────────────────────────────────────────
# OMSICpp's factory (OMCFactory.cpp) uses dlopen() at runtime to load plugins
# (SimController, Solver, Math, CVode, etc.). Static .a files cannot be
# dlopen'd, so OMSICpp always requires shared libraries regardless of PLATFORM.
set(BUILD_SHARED_LIBS ON)
set(LIBSUFFIX "")

# LIB_OMC is used by omsi/CMakeLists.txt to set the executable RPATH:
#   "$ORIGIN/../${LIB_OMC}/omsicpp/:$ORIGIN"
# Set it to CMAKE_INSTALL_LIBDIR (e.g. lib/x86_64-linux-gnu/omc) so the
# installed OMCppOSUSimulation binary can find libOMCppExtensionUtilities.so
# and friends in the omsicpp/ subdirectory.
set(LIB_OMC "${CMAKE_INSTALL_LIBDIR}")

# ── Build-mode flags ──────────────────────────────────────────────────────────
set(OMC_BUILD ON)
set(SIMSTER_BUILD OFF)
set(USE_MICO OFF)
set(USE_KLU OFF CACHE BOOL "Use KLU solver")
set(USE_DGESV OFF)
set(USE_MINPACK ON)
set(BUILD_BROYDEN ON)
set(BUILD_PEER ON)
set(USE_FMILIB ON)
set(USE_OMSI ON)
set(USE_ZEROMQ OFF)
set(USE_PRECOMPILEDHEADER OFF)
set(REDUCE_DAE OFF)
set(FMU_SUNDIALS OFF)
set(RUNTIME_PROFILING OFF)
add_definitions(-DOMC_BUILD)

# ── Library name variables ────────────────────────────────────────────────────
# Several OMSICpp target names collide with targets already created by
# SimulationRuntime/cpp/ in the integrated build (both dynamic, no suffix).
# Prefix conflicting CMake target names with "omsicpp_" to avoid the
# collision; OUTPUT_NAME is set after add_subdirectory() calls so the
# installed file still carries the expected "OMCpp…" filename.
set(LIBPREFIX "OMCpp")
set(OMSICPP_PREFIX "omsicpp_")
set(MODELICA_MODEL "ModelicaSystem")

# ── Conflicting names (need OMSICPP_PREFIX) ───────────────────────────────────
set(SolverName              ${OMSICPP_PREFIX}${LIBPREFIX}Solver)
set(MathName                ${OMSICPP_PREFIX}${LIBPREFIX}Math)
set(OMCFactoryName          ${OMSICPP_PREFIX}${LIBPREFIX}OMCFactory)
set(ModelicaName            ${OMSICPP_PREFIX}${LIBPREFIX}Modelica)
set(SimulationSettings      ${OMSICPP_PREFIX}${LIBPREFIX}SimulationSettings)
set(SimControllerName       ${OMSICPP_PREFIX}${LIBPREFIX}SimController)
set(CVodeName               ${OMSICPP_PREFIX}${LIBPREFIX}CVode)
set(KinsolName              ${OMSICPP_PREFIX}${LIBPREFIX}Kinsol)
set(LinearSolverName        ${OMSICPP_PREFIX}${LIBPREFIX}LinearSolver)
set(NewtonName              ${OMSICPP_PREFIX}${LIBPREFIX}Newton)
set(ExtensionUtilitiesName  ${OMSICPP_PREFIX}${LIBPREFIX}ExtensionUtilities)
set(ModelicaUtilitiesName   ${OMSICPP_PREFIX}${LIBPREFIX}ModelicaUtilities)
set(DataExchangeName        ${OMSICPP_PREFIX}${LIBPREFIX}DataExchange)
set(FMUName                 ${OMSICPP_PREFIX}${LIBPREFIX}FMU)

# ── Non-conflicting names (no prefix needed) ──────────────────────────────────
# OMCppSystemBase / OMCppExtendedSystem / OMCppSystemOMSI are unique to OMSICpp.
# OMCppIDA differs from cpp/'s OMCppIda (case).
# OMCppCppDASSL differs from cpp/'s OMCppDASSL.
# Broyden, Hybrj, Peer, Euler, RK12, RTEuler are not built by cpp/ in the
# integrated build.
set(SystemBaseName          ${LIBPREFIX}SystemBase)
set(SystemOMSIName          ${LIBPREFIX}SystemOMSI)
set(ExtendedSystemName      ${LIBPREFIX}ExtendedSystem)
set(IDAName                 ${LIBPREFIX}IDA)
set(CppDASSLName            ${LIBPREFIX}CppDASSL)
set(EulerName               ${LIBPREFIX}Euler)
set(RK12Name                ${LIBPREFIX}RK12)
set(RTEulerName             ${LIBPREFIX}RTEuler)
set(BroydenName             ${LIBPREFIX}Broyden)
set(HybrjName               ${LIBPREFIX}Hybrj)
set(PeerName                ${LIBPREFIX}Peer)

# ── Static-only libs (not dlopen'd at runtime, no conflict risk) ──────────────
set(ModelicaExternalName    ModelicaExternalC)
set(ModelicaTablesName      ModelicaStandardTables)
set(ModelicaIOName          ModelicaIO)
set(ModelicaMatIOName       ModelicaMatIO)
set(LibZName                zlib)
set(DgesvName               ${LIBPREFIX}Dgesv_static)
set(DgesvSolverName         ${OMSICPP_PREFIX}${LIBPREFIX}DgesvSolver)
set(UmfPackName             ${LIBPREFIX}UmfPack)
set(OSUSimName              ${LIBPREFIX}OSUSimulation)
set(OSUName                 ${LIBPREFIX}OSU)
set(BasiLibName             ${LIBPREFIX}Base)

# ── Boost ─────────────────────────────────────────────────────────────────────
set(Boost_USE_MULTITHREADED ON)
find_package(Boost REQUIRED COMPONENTS filesystem serialization program_options)
find_package(Threads REQUIRED)
if(WIN32)
  set(CPPTHREADS_LIBRARY)
  set(CPPTHREADS_LIBRARY_FLAG)
else()
  set(CPPTHREADS_LIBRARY Threads::Threads)
  set(CPPTHREADS_LIBRARY_FLAG ${CMAKE_THREAD_LIBS_INIT})
endif()
set(Boost_Library_folder ${Boost_LIBRARY_DIRS})
link_directories(${Boost_LIBRARY_DIRS})

# ── LAPACK / BLAS ─────────────────────────────────────────────────────────────
find_package(BLAS)
find_package(LAPACK)
list(LENGTH LAPACK_LIBRARIES LAPACKVARCOUNT)
if(LAPACKVARCOUNT GREATER 0)
  list(GET LAPACK_LIBRARIES 0 LAPACKLISTHEAD)
  get_filename_component(LAPACKLISTHEAD "${LAPACKLISTHEAD}" PATH)
  set(LAPACK_LIBS "${LAPACKLISTHEAD}")
endif()

# ── OpenMP ────────────────────────────────────────────────────────────────────
find_package(OpenMP)
if(OPENMP_FOUND)
  set(USE_OPENMP_ "ON")
  set(OMPCFLAGS ${OpenMP_CXX_FLAGS})
else()
  set(USE_OPENMP_ "OFF")
  set(OMPCFLAGS "")
endif()

# ── MPI ───────────────────────────────────────────────────────────────────────
find_package(MPI)
if(MPI_FOUND)
  set(USE_MPI_ "ON")
else()
  set(USE_MPI_ "OFF")
endif()

# ── Sundials ──────────────────────────────────────────────────────────────────
# Use the CMake targets exposed by 3rdParty/CMakeLists.txt rather than
# find_library() so the build works before the libraries are installed.
set(USE_SUNDIALS ON)
set(SUNDIALS_LIBRARIES
  omc::3rd::sundials::cvode
  omc::3rd::sundials::idas
  omc::3rd::sundials::kinsol)
add_definitions(-DPMC_USE_SUNDIALS)

# Sundials include/library paths for the generated ModelicaConfig_gcc.inc.
# At model-compile time these files will have been installed already.
set(SUNDIALS_INCLUDE_DIR "${CMAKE_INSTALL_PREFIX}/include/omc/sundials")
set(SUNDIALS_LIBS        "${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_LIBDIR}")

# Determine the Sundials version from the installed config header (best effort).
set(SUNDIALS_CONFIG_FILE "${SUNDIALS_INCLUDE_DIR}/sundials/sundials_config.h")
if(EXISTS "${SUNDIALS_CONFIG_FILE}")
  file(READ "${SUNDIALS_CONFIG_FILE}" SUNDIALS_CONFIG_FILE_CONTENT)
  string(REGEX MATCH "#define SUNDIALS_VERSION .([0-9]+)\\.([0-9]+)\\.([0-9]+)." _ ${SUNDIALS_CONFIG_FILE_CONTENT})
  if(DEFINED CMAKE_MATCH_1)
    set(SUNDIALS_MAJOR_VERSION "${CMAKE_MATCH_1}")
    set(SUNDIALS_MINOR_VERSION "${CMAKE_MATCH_2}")
    add_definitions("-DSUNDIALS_MAJOR_VERSION=${SUNDIALS_MAJOR_VERSION}")
    add_definitions("-DSUNDIALS_MINOR_VERSION=${SUNDIALS_MINOR_VERSION}")
    message(STATUS "OMSICpp: using Sundials ${CMAKE_MATCH_1}.${CMAKE_MATCH_2}.${CMAKE_MATCH_3}")
  endif()
endif()

# ── FMIL ──────────────────────────────────────────────────────────────────────
# Use the CMake target; its INTERFACE_INCLUDE_DIRECTORIES propagate automatically
# when targets link against it.
set(FMILIB_LIB omc::3rd::fmilib)
if(WIN32)
  set(FMILIB_LIB_EXTRA shlwapi)
else()
  set(FMILIB_LIB_EXTRA "")
endif()
# Expose include directories globally so that sub-directories that use plain
# include_directories() (rather than target_include_directories) still compile.
get_target_property(_fmilib_incs fmilib INTERFACE_INCLUDE_DIRECTORIES)
if(_fmilib_incs)
  include_directories(${_fmilib_incs})
endif()
add_definitions(-DENABLE_OMSI)
message(STATUS "OMSICpp: FMI library target: ${FMILIB_LIB}")

# OMSI base/solver includes (used by SystemOMSI and the omsi/ subdirectory)
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../OMSI/base/include")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../OMSI/solver/include")

# ── CMinpack (for Hybrj solver) ───────────────────────────────────────────────
if(USE_MINPACK AND TARGET omc::3rd::cminpack)
  set(CMINPACK_LIBRARY omc::3rd::cminpack)
  get_target_property(_cminpack_incs cminpack INTERFACE_INCLUDE_DIRECTORIES)
  if(_cminpack_incs)
    include_directories(${_cminpack_incs})
  else()
    include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../../../3rdParty/CMinpack")
  endif()
else()
  set(USE_MINPACK OFF)
endif()

# ── Global include directories ────────────────────────────────────────────────
include_directories(${Boost_INCLUDE_DIR})
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/runtime/include/")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}/../OMSI/include/")
include_directories("${CMAKE_CURRENT_SOURCE_DIR}")
include_directories("${CMAKE_CURRENT_BINARY_DIR}")

# ── Sub-directories ───────────────────────────────────────────────────────────
# Build order follows link-time dependencies (leaves first).
# ModelicaExternalC / ModelicaStandardTables / zlib already exist from the
# parent build; do NOT add Core/ModelicaExternalC to avoid target-name clashes.
add_subdirectory(runtime/src/Core/Utils/extension)
add_subdirectory(runtime/src/Core/Utils/Modelica)
add_subdirectory(runtime/src/Core/Modelica)
add_subdirectory(runtime/src/SimCoreFactory/OMCFactory)
add_subdirectory(runtime/src/Core/Math)
add_subdirectory(runtime/src/Core/Solver)
add_subdirectory(runtime/src/Core/DataExchange)
add_subdirectory(runtime/src/Core/SimulationSettings)
add_subdirectory(runtime/src/Core/SimController)
add_subdirectory(runtime/src/Core/System)
add_subdirectory(runtime/src/Solver/Newton)
add_subdirectory(runtime/src/Solver/CVode)
add_subdirectory(runtime/src/Solver/IDA)
add_subdirectory(runtime/src/Solver/Kinsol)
add_subdirectory(runtime/src/Solver/LinearSolver)
add_subdirectory(runtime/src/Solver/Euler)
add_subdirectory(runtime/src/Solver/RK12)
add_subdirectory(runtime/src/Solver/RTEuler)
add_subdirectory(runtime/src/FMU)
if(BUILD_BROYDEN)
  add_subdirectory(runtime/src/Solver/Broyden)
endif()
if(USE_MINPACK)
  add_subdirectory(runtime/src/Solver/Hybrj)
endif()
if(BUILD_PEER)
  add_subdirectory(runtime/src/Solver/Peer)
endif()
add_subdirectory(omsi)

# ── Restore expected output filenames on prefixed targets ─────────────────────
# The OMSICPP_PREFIX avoids CMake target-name collisions with cpp/ targets.
# OUTPUT_NAME restores the "OMCpp…" filename so the OMSICpp factory can
# dlopen() the correct shared-library name from the omsicpp/ directory.
foreach(_base IN ITEMS
    Solver Math OMCFactory Modelica SimulationSettings SimController
    CVode Kinsol LinearSolver Newton ExtensionUtilities ModelicaUtilities
    DataExchange FMU)
  if(TARGET ${OMSICPP_PREFIX}${LIBPREFIX}${_base})
    set_target_properties(${OMSICPP_PREFIX}${LIBPREFIX}${_base}
      PROPERTIES OUTPUT_NAME ${LIBPREFIX}${_base})
  endif()
endforeach()

# ── LibrariesConfig.h ─────────────────────────────────────────────────────────
# Derive expected library filenames from target OUTPUT_NAME properties so that
# LibrariesConfig.h contains the actual on-disk filenames that dlopen() needs.
function(_omsicpp_lib_filename TARGET_NAME OUTPUT_VAR)
  if(TARGET ${TARGET_NAME})
    get_target_property(_type ${TARGET_NAME} TYPE)
    get_target_property(_out ${TARGET_NAME} OUTPUT_NAME)
    if(NOT _out OR _out STREQUAL "${TARGET_NAME}-NOTFOUND")
      set(_out ${TARGET_NAME})
    endif()
    if(_type STREQUAL "SHARED_LIBRARY")
      set(${OUTPUT_VAR}
        "${CMAKE_SHARED_LIBRARY_PREFIX}${_out}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        PARENT_SCOPE)
    else()
      set(${OUTPUT_VAR}
        "${CMAKE_STATIC_LIBRARY_PREFIX}${_out}${CMAKE_STATIC_LIBRARY_SUFFIX}"
        PARENT_SCOPE)
    endif()
  else()
    if(BUILD_SHARED_LIBS)
      set(${OUTPUT_VAR}
        "${CMAKE_SHARED_LIBRARY_PREFIX}${TARGET_NAME}${CMAKE_SHARED_LIBRARY_SUFFIX}"
        PARENT_SCOPE)
    else()
      set(${OUTPUT_VAR}
        "${CMAKE_STATIC_LIBRARY_PREFIX}${TARGET_NAME}${CMAKE_STATIC_LIBRARY_SUFFIX}"
        PARENT_SCOPE)
    endif()
  endif()
endfunction()

_omsicpp_lib_filename(${EulerName}          EULER_LIB)
_omsicpp_lib_filename(${RK12Name}           RK12_LIB)
_omsicpp_lib_filename(${RTEulerName}        RTEULER_LIB)
_omsicpp_lib_filename(${SimulationSettings} SETTINGSFACTORY_LIB)
_omsicpp_lib_filename(${ModelicaName}       MODELICASYSTEM_LIB)
_omsicpp_lib_filename(${NewtonName}         NEWTON_LIB)
_omsicpp_lib_filename(${BroydenName}        BROYDEN_LIB)
_omsicpp_lib_filename(${PeerName}           PEER_LIB)
_omsicpp_lib_filename(${SystemBaseName}     SYSTEMBASE_LIB)
_omsicpp_lib_filename(${SystemOMSIName}     SYSTEMOMSI_LIB)
_omsicpp_lib_filename(${ExtendedSystemName} EXTENDEDSYSTEM_LIB)
_omsicpp_lib_filename(${SolverName}         SOLVER_LIB)
_omsicpp_lib_filename(${LinearSolverName}   LINEARSOLVER_LIB)
_omsicpp_lib_filename(${DgesvSolverName}    DGESVSOLVER_LIB)
_omsicpp_lib_filename(${MathName}           MATH_LIB)
_omsicpp_lib_filename(${HybrjName}          HYBRJ_LIB)
_omsicpp_lib_filename(${OMCFactoryName}     SIMOBJFACTORY_LIB)
_omsicpp_lib_filename(${DataExchangeName}   DATAEXCHANGE_LIB)
_omsicpp_lib_filename(${SimControllerName}  SIMCONTROLLER_LIB)
_omsicpp_lib_filename(${CVodeName}          CVODE_LIB)
_omsicpp_lib_filename(${IDAName}            IDA_LIB)
_omsicpp_lib_filename(${KinsolName}         KINSOL_LIB)

configure_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/runtime/src/LibrariesConfig.h.in"
  "${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h")

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/LibrariesConfig.h"
  DESTINATION include/omc/omsicpp)

install(FILES "Licenses/sundials.license"
  DESTINATION share/omc/runtime/omsicpp/licenses)

# ── Extension utility headers (same as standalone CMakeLists.txt) ─────────────
macro(INSTALL_HEADERS_WITH_DIRECTORY HEADER_LIST)
  foreach(HEADER ${${HEADER_LIST}})
    string(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    string(REPLACE "runtime/include" "" DIR ${DIR})
    install(FILES ${HEADER} DESTINATION include/omc/omsicpp/${DIR})
  endforeach()
endmacro()

set(HS
  runtime/include/Core/Utils/extension/adaptable_factory.hpp
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
  install(CODE "execute_process(COMMAND ln -sf /usr/include/boost \"${CMAKE_INSTALL_PREFIX}/include/omc/omsicpp/\")")
endif()
