# This skript will build and install all required libraries of the C++ Simulation-runtime
#
# The following conditional defines are passed to the c++ compiler:
#     if the Boost_log and Boost_setup_log libraries were found ->   -DUSE_BOOST_LOG
#     if the Boost_thread library was found ->                       -DUSE_BOOST_THREAD
#     if the Umfpack library of SuiteSparse was found ->             -DUSE_UMFPACK
#     if the Sundials libraries were found ->                        -DPMC_USE_SUNDIALS
#     if the runtime is build for the omc ->                         -DOMC_BUILD
#
# Additionally it is possible to link all libraries statically (experimental), therefor -DANALYZATION_MODE=ON musst be passed to cmake
#
# The used defines are stored in the SYSTEM_CFLAGS variable, which is passed to the ModelicaConfig.inc and written in the PrecompiledHeader.cmake




cmake_minimum_required (VERSION 2.6)
project(CppSolverInterface)

IF(NOT ANALYZATION_MODE)
	#Precompiled header produces problems if the compiler is not "g++" but "scorep g++"
	include(${CMAKE_SOURCE_DIR}/PrecompiledHeader.cmake)
ENDIF(NOT ANALYZATION_MODE)
#set(CMAKE_VERBOSE_MAKEFILE ON)

option(ANALYZATION_MODE "ANALYZATION_MODE" OFF)
option(USE_THREADS "USE_PARALLEL_OUTPUT" OFF)

IF(ANALYZATION_MODE)
	message(STATUS "Using analyzation mode")
	add_definitions(-DANALYZATION_MODE)
ELSE(ANALYZATION_MODE)
	message(STATUS "Analyzation mode disabled")
ENDIF(ANALYZATION_MODE)

IF(USE_PARALLEL_OUTPUT)
	add_definitions(-DUSE_PARALLEL_OUTPUT)
ENDIF(USE_PARALLEL_OUTPUT)

# on windows  boost,blas,lapack  and sundial solvers from omdev is used else the installed versions are used
IF( WIN32 )
SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost-1_55/")
#SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost-1_49/")
SET(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll CACHE FILEPATH "Blas library")
SET(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll CACHE FILEPATH "Lapack library")
SET(BLAS_DIRY "$ENV{OMDEV}/lib/3rdParty/Lapack/Lib/" CACHE LOCATION "where was yarp built?")

# Disable Optimization for RelWithDebInfo on Windows
if (MSVC)
    STRING(REPLACE "/O2" "/Od" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
else()
	STRING(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_RELWITHDEBINFO ${CMAKE_CXX_FLAGS_RELWITHDEBINFO})
	STRING(REPLACE "/O2" "/O0" CMAKE_CXX_FLAGS_DEBUG ${CMAKE_CXX_FLAGS_DEBUG})
endif()


#set mico paths
SET(MICO_LIB_HOME $ENV{OMDEV}/lib/mico-msys-mingw/)
SET(MICO_INCLUDE_HOME  $ENV{OMDEV}/include/mico-msys-mingw/)
#set sundials solvers include and library directories
SET(SUNDIALS_INLCUDE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/include)

if(MSVC)
SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/vc100)
elseif(MINGW)
SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/mingw/dlls)
endif()
SET(INSTALL_OMDEV_LIBS ON)
ENDIF( WIN32 )

# Find CMinpack
# Note: Visual Studio libs are located in install/msvc, libs for gcc are directly in install
if(MSVC)
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install/msvc")
else(MSVC)
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install")
endif(MSVC)

FIND_PATH(CMINPACK_INCLUDE_DIR cminpack.h
          HINTS ${CMinpack_Path}
          PATH_SUFFIXES include include/cminpack include/cminpack-1)

FIND_LIBRARY(CMINPACK_LIBRARY
             NAMES cminpack
             HINTS ${CMinpack_Path}
             PATH_SUFFIXES lib lib64)

include_directories(${CMINPACK_INCLUDE_DIR})

set(MODELICAEXTERNALCDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/C-Sources")
set(USERTABDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/Data/Tables")

SET(LIBINSTALLEXT "cpp")
SET(MODELICA_MODEL "ModelicaSystem")
SET(LIBPREFIX "OMCpp")
SET(SolverName ${LIBPREFIX}Solver)
SET(SystemName ${LIBPREFIX}System)
SET(OMCFactoryName ${LIBPREFIX}OMCFactory)
set(MathName ${LIBPREFIX}Math)
set(ModelicaExternalName ModelicaExternalC)
set(ModelicaTablesName ModelicaStandardTables)
set(SimulationSettings ${LIBPREFIX}SimulationSettings)
set(SimControllerName ${LIBPREFIX}SimController)
set(CVodeName ${LIBPREFIX}CVode)
set(EulerName ${LIBPREFIX}Euler)
set(IdaName ${LIBPREFIX}Ida)
set(IdasName ${LIBPREFIX}Idas)
set(KinsolName ${LIBPREFIX}Kinsol)
set(ModelicaName ${LIBPREFIX}Modelica)
set(NewtonName ${LIBPREFIX}Newton)
set(HybrjName ${LIBPREFIX}Hybrj)
set(UmfPackName ${LIBPREFIX}UmfPack)
set(DataExchangeName ${LIBPREFIX}DataExchange)
set(ModelicaUtilitiesName ${LIBPREFIX}ModelicaUtilities)
set(ExtensionUtilitiesName ${LIBPREFIX}ExtensionUtilities)
set(BasiLibName ${LIBPREFIX}Base)

SET(USE_MICO OFF)
SET(REDUCE_DAE OFF)
SET(USE_SUNDIALS ON)
SET(OMC_BUILD ON)
SET(SIMSTER_BUILD OFF)
# Boost
SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
SET(Boost_USE_STATIC_RUNTIME OFF)


# The optional boost libraries must be searched separately, otherwise no library is found if just one is missing.
# Additionaly the Boost_LIBRARIES variable is overwritten each time find_package(Boost ...) is called, thus it must be rescued
find_package(Boost COMPONENTS log log_setup)
SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
IF(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)
	add_definitions(-DUSE_BOOST_LOG)
	message(STATUS "Using boost log")
ELSE(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)
	message(STATUS "Boost log disabled")
	unset(Boost_LOG_LIBRARY)
ENDIF(Boost_LOG_FOUND AND Boost_LOG_SETUP_FOUND)

find_package(Boost COMPONENTS thread atomic)

SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
find_package(Threads)
IF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
	add_definitions(-DUSE_BOOST_THREAD)
	message(STATUS "Using boost thread")
ELSE(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)
	message(STATUS "Boost thread disabled")
ENDIF(Boost_THREAD_FOUND AND Boost_ATOMIC_FOUND)

find_package(Boost COMPONENTS filesystem system serialization program_options REQUIRED)
SET(Boost_LIBRARIES_TMP ${Boost_LIBRARIES_TMP} ${Boost_LIBRARIES})
SET(Boost_LIBRARIES ${Boost_LIBRARIES_TMP})
message(STATUS "Boost Libraries")
message(STATUS ${Boost_LIBRARIES})

# Lapack and Blas
find_package( BLAS )
find_package( LAPACK  )
if(MSVC)
  #workaround  because cmake does not find the lapack libraries for Visual Studio 10
  SET(LAPACK_MSVC_10  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.lib  )
  SET(BLAS_MSVC_10 $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.lib )
  SET(LAPACK_LIBRARIES  ${LAPACK_MSVC_10}   ${BLAS_MSVC_10} )

elseif(MINGW)
  SET(LAPACK_MINGW  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll  )
  SET(BLAS_MINGW $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll )
  SET(LAPACK_LIBRARIES  ${LAPACK_MINGW}   ${BLAS_MINGW} )

endif()

find_library(mkl_rt mkl_rt)
if (mkl_rt)
  #workaround because find_package(lapack)-command returns the wrong libraries on Taurus (ZIH-TU Dresden)
  SET(LAPACK_LIBRARIES ${mkl_rt})
endif(mkl_rt)

if(OMC_BUILD)
add_definitions(-DOMC_BUILD)
elseif(SIMSTER_BUILD)
add_definitions(-DSIMSTER_BUILD)
endif()


message(STATUS "Lapack Libraries")
message(STATUS ${LAPACK_LIBRARIES})


# Sundials solvers
if(USE_SUNDIALS)

find_path(SUNDIALS_INCLUDE_DIR cvode/cvode.h
    PATHS ${SUNDIALS_INLCUDE_HOME})
message(STATUS ${SUNDIALS_INCLUDE_DIR})

find_library(SUNDIALS_NVECSERIAL_LIB "sundials_nvecserial"
    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME})
find_library(SUNDIALS_CVODES_LIB "sundials_cvodes"
    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
find_library(SUNDIALS_IDA_LIB "sundials_ida"
    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
find_library(SUNDIALS_KINSOL_LIB "sundials_kinsol"
    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
#find_library(SUNDIALS_IDAS_LIB "sundials_idas"
#    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )

set(SUNDIALS_LIBS ${SUNDIALS_NVECSERIAL_LIB}  ${SUNDIALS_CVODES_LIB}  ${SUNDIALS_IDA_LIB}  ${SUNDIALS_KINSOL_LIB})

message(STATUS "Sundials Libraries:")
message(STATUS ${SUNDIALS_LIBS})
add_definitions(-DPMC_USE_SUNDIALS)

# On Windows we need to install those libraries along with the SimManager
INSTALL(FILES ${SUNDIALS_LIBS} DESTINATION bin)
endif()

#Handle umfpack
FIND_PACKAGE(SuiteSparse HINTS "${CMAKE_SOURCE_DIR}/Solver/UmfPack/")
IF(SuiteSparse_found)
	message(STATUS "Using UmfPack")
	include_directories(${SUITESPARSE_INCLUDE_DIRS})
	add_definitions(-DUSE_UMFPACK)
    SET(SUITESPARSE_INCLUDE_FLAG "-I${SUITESPARSE_INCLUDE_DIRS}")
ELSE()
	message(STATUS "UmfPack disabled")
	SET(SUITESPARSE_INCLUDE_FLAG "")
ENDIF()

#Mico corba
if(USE_MICO)
  find_library(MICO_LIBRARY  mico2313
    PATHS ${MICO_LIB_HOME}) #you can add additional search paths for mico library
  find_path(MICO_INCLUDE_DIR CORBA.h
     ${MICO_INCLUDE_HOME}) #you can add additional search paths for mico include
  message(STATUS ${MICO_LIBRARY})
  message(STATUS ${MICO_INCLUDE_DIR})
endif()

#Write the defines into the ADDITIONAL_DEFINES variable
# GET_DIRECTORY_PROPERTY(ADDITIONAL_DEFINES DEFINITIONS)
# message(STATUS "Generated compile definitions: ${ADDITIONAL_DEFINES}")

link_directories ( ${Boost_LIBRARY_DIRS} )


include_directories (${Boost_INCLUDE_DIR})
include_directories ("${PROJECT_SOURCE_DIR}")
include_directories ("${PROJECT_BINARY_DIR}")

message(STATUS "Boost dirs '${Boost_LIBRARY_DIRS}', '${Boost_INCLUDE_DIR}'")

#build of simulation.core
include_directories ("Include")


add_subdirectory (Core/Math)

add_subdirectory (Core/Utils/Modelica)
add_subdirectory (Core/Utils/extension)
add_subdirectory (Core/DataExchange)
add_subdirectory (SimCoreFactory/OMCFactory)

#add system default implemention project
add_subdirectory (Core/System)
#add solver default implemention project
add_subdirectory (Core/Solver)
add_subdirectory (Core/SimulationSettings)
#add_subdirectory (Core/SimController)
add_subdirectory (Core/Modelica)
add_subdirectory (Core/ModelicaExternalC)
add_subdirectory (Core/SimController)
#build of simulation.solver
include_directories ("Include/Solver")
#add  Euler solver project
add_subdirectory (Solver/Euler)
add_subdirectory (Solver/Newton)
add_subdirectory (Solver/Hybrj)
add_subdirectory (Solver/UmfPack)



if(REDUCE_DAE)
  add_subdirectory(ReduceDAE/Implementation)
endif()



if(USE_SUNDIALS)
#add  Cvode solver project
add_subdirectory (Solver/CVode)
add_subdirectory (Solver/Kinsol)
#add  Idas solver project
#add_subdirectory (Solver/Idas/Implementation)
#add_subdirectory (Solver/Ida/Implementation)
GET_TARGET_PROPERTY(libCVode ${CVodeName} LOCATION)
GET_FILENAME_COMPONENT(libCVodeName ${libCVode} NAME)

GET_TARGET_PROPERTY(libKinsol ${KinsolName} LOCATION)
GET_FILENAME_COMPONENT(libKinsolName ${libKinsol} NAME)
#GET_TARGET_PROPERTY(libIdas ${IdasName} LOCATION)
#GET_FILENAME_COMPONENT(libIdasName ${libIdas} NAME)
#GET_TARGET_PROPERTY(libIda ${IdaName} LOCATION)
#GET_FILENAME_COMPONENT(libIdaName ${libIda} NAME)

#set (IDAS_LIB ${libIdasName})
set (CVODE_LIB ${libCVodeName})
set (KINSOL_LIB ${libKinsolName})
#set (IDA_LIB ${libIdaName})
endIf()

GET_TARGET_PROPERTY(libNewton ${NewtonName} LOCATION)
GET_FILENAME_COMPONENT(libNewtonName ${libNewton} NAME)

GET_TARGET_PROPERTY(libUmfPack ${UmfPackName} LOCATION)
GET_FILENAME_COMPONENT(libUmfPackName ${libUmfPack} NAME)

GET_TARGET_PROPERTY(libEuler ${EulerName} LOCATION)
GET_FILENAME_COMPONENT(libEulerName ${libEuler} NAME)

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


GET_TARGET_PROPERTY(libSimObjFactory ${OMCFactoryName} LOCATION)
GET_FILENAME_COMPONENT(libSimObjFactoryName ${libSimObjFactory} NAME)

set (EULER_LIB ${libEulerName})
set (SETTINGSFACTORY_LIB ${libSetFactoryName})
set (MODELICASYSTEM_LIB ${libModelicaName})
set (NEWTON_LIB ${libNewtonName})
set (UMFPACK_LIB ${libUmfPackName})
set (SYSTEM_LIB ${libSystemName})
set (SOLVER_LIB ${libSolverName})
set (MATH_LIB ${libMathName})
set (HYBRJ_LIB ${libHybrjName})
set (SIMOBJFACTORY_LIB ${libSimObjFactoryName})
set (DATAEXCHANGE_LIB ${libDataExchangeName})
set (SIMCONRTOLLER_LIB ${libSimControllerName})
set (EXTENSIONUTILITIES_LIB ${libExtensionUtilitiesName})

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
	#message(STATUS "coopy to "include/omc/cpp/${DIR})
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
        Include/FMU/FMUWrapper.h)
   INSTALL_HEADERS_WITH_DIRECTORY(HS)
