# This skript will build and install all required libraries of the C++ Simulation-runtime
#
# The following conditional defines are passed to the c++ compiler:
#     if the Boost_log and Boost_setup_log libraries were found ->   -DUSE_BOOST_LOG
#     if the Boost_thread library was found ->                       -DUSE_BOOST_THREAD
#     if the Umfpack library of SuiteSparse was found ->             -DUSE_UMFPACK
#     if the PAPI library was found ->				                       -DUSE_PAPI
#     if the Sundials libraries were found ->                        -DPMC_USE_SUNDIALS
#     if the runtime is build for the omc ->                         -DOMC_BUILD
#
# Additionally it is possible to link all libraries statically (experimental), therefor -DANALYZATION_MODE=ON musst be passed to cmake
#
# The used defines are stored in the SYSTEM_CFLAGS variable, which is passed to the ModelicaConfig.inc and written in the PrecompiledHeader.cmake

CMAKE_MINIMUM_REQUIRED (VERSION 2.6)
PROJECT(CppSolverInterface)



#Set Options
OPTION(ANALYZATION_MODE "ANALYZATION_MODE" OFF)
OPTION(USE_THREADS "USE_PARALLEL_OUTPUT" OFF)


#Set Variables
SET(MODELICAEXTERNALCDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/C-Sources")
SET(USERTABDIR  "${CMAKE_SOURCE_DIR}/../../libraries/Resources/Data/Tables")

SET(LIBINSTALLEXT "cpp")
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
SET(EulerName ${LIBPREFIX}Euler)
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

SET(USE_MICO OFF)
SET(REDUCE_DAE OFF)
SET(USE_SUNDIALS ON)
SET(OMC_BUILD ON)
SET(SIMSTER_BUILD OFF)

SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
SET(Boost_USE_STATIC_RUNTIME OFF)


# Handle Analyzation mode
IF(NOT ANALYZATION_MODE)
	#Precompiled header produces problems if the compiler is not "g++" but "scorep g++"
	INCLUDE(${CMAKE_SOURCE_DIR}/PrecompiledHeader.cmake)
	MESSAGE(STATUS "Analyzation mode disabled")
ELSE(NOT ANALYZATION_MODE)
	MESSAGE(STATUS "Using analyzation mode")
	ADD_DEFINITIONS(-DANALYZATION_MODE)	
ENDIF(NOT ANALYZATION_MODE )


# Handle parallel output
IF(USE_PARALLEL_OUTPUT)
	ADD_DEFINITIONS(-DUSE_PARALLEL_OUTPUT)
ENDIF(USE_PARALLEL_OUTPUT)


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
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install/msvc")
ELSE(MSVC)
    SET(CMinpack_Path "${CMAKE_SOURCE_DIR}/../../3rdParty/CMinpack/install")
ENDIF(MSVC)

FIND_PATH(CMINPACK_INCLUDE_DIR cminpack.h
          HINTS ${CMinpack_Path}
          PATH_SUFFIXES include include/cminpack include/cminpack-1)

FIND_LIBRARY(CMINPACK_LIBRARY
             NAMES cminpack
             HINTS ${CMinpack_Path}
             PATH_SUFFIXES lib lib64)

INCLUDE_DIRECTORIES(${CMINPACK_INCLUDE_DIR})


# Find PAPI
FIND_LIBRARY(PAPI_LIBRARIES NAMES libpapi.a papi)
FIND_PATH(PAPI_INCLUDE_DIRS NAMES papi.h)
INCLUDE(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(PAPI DEFAULT_MSG PAPI_LIBRARIES PAPI_INCLUDE_DIRS)
IF(PAPI_FOUND)
  #ADD_DEFINITIONS(-DUSE_PAPI)
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

FIND_PACKAGE(Boost COMPONENTS filesystem system serialization program_options REQUIRED)
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

MESSAGE(STATUS "Lapack Libraries")
MESSAGE(STATUS ${LAPACK_LIBRARIES})


# Find Sundials solvers
IF(USE_SUNDIALS)
  FIND_PATH(SUNDIALS_INCLUDE_DIR cvode/cvode.h
      PATHS ${SUNDIALS_INLCUDE_HOME})
  MESSAGE(STATUS ${SUNDIALS_INCLUDE_DIR})

  FIND_LIBRARY(SUNDIALS_NVECSERIAL_LIB "sundials_nvecserial"
      PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME})
  FIND_LIBRARY(SUNDIALS_CVODES_LIB "sundials_cvodes"
      PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  FIND_LIBRARY(SUNDIALS_IDA_LIB "sundials_ida"
      PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  FIND_LIBRARY(SUNDIALS_KINSOL_LIB "sundials_kinsol"
      PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )
  #FIND_LIBRARY(SUNDIALS_IDAS_LIB "sundials_idas"
  #    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )

  SET(SUNDIALS_LIBS ${SUNDIALS_NVECSERIAL_LIB}  ${SUNDIALS_CVODES_LIB}  ${SUNDIALS_IDA_LIB}  ${SUNDIALS_KINSOL_LIB})

  MESSAGE(STATUS "Sundials Libraries:")
  MESSAGE(STATUS ${SUNDIALS_LIBS})
  ADD_DEFINITIONS(-DPMC_USE_SUNDIALS)

  # On Windows we need to install those libraries along with the SimManager
  INSTALL(FILES ${SUNDIALS_LIBS} DESTINATION bin)
ENDIF(USE_SUNDIALS)


#Handle umfpack
FIND_PACKAGE(SuiteSparse HINTS "${CMAKE_SOURCE_DIR}/Solver/UmfPack/")
IF(SuiteSparse_found)
	MESSAGE(STATUS "Using UmfPack")
	INCLUDE_DIRECTORIES(${SUITESPARSE_INCLUDE_DIRS})
	ADD_DEFINITIONS(-DUSE_UMFPACK)
    SET(SUITESPARSE_INCLUDE ${SUITESPARSE_INCLUDE_DIRS})
	SET(UMFPACK_LIB ${SUITESPARSE_LIBRARIES})
ELSE(SuiteSparse_found)
	MESSAGE(STATUS "UmfPack disabled")
	SET(SUITESPARSE_INCLUDE ".")
	SET(UMFPACK_LIB "")
ENDIF(SuiteSparse_found)


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
