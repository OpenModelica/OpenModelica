cmake_minimum_required (VERSION 2.6)




project(CppSolverInterface)
# on windows  boost,blas,lapack  and sundial solvers from omdev is used else the installed versions are used
IF( WIN32 )
SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost_1_45_0/")
SET(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll CACHE FILEPATH "Blas library")
SET(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll CACHE FILEPATH "Lapack library")
SET(BLAS_DIRY "$ENV{OMDEV}/lib/3rdParty/Lapack/Lib/" CACHE LOCATION "where was yarp built?")

#set mico paths 
SET(MICO_LIB_HOME $ENV{OMDEV}/lib/mico-msys-mingw/)
SET(MICO_INCLUDE_HOME  $ENV{OMDEV}/include/mico-msys-mingw/)
#set sundials solvers include and library directories
SET(SUNDIALS_INLCUDE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/include)

if(MSVC)
SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/vc100)
elseif(MINGW)
SET(SUNDIALS_LIBRARY_RELEASE_HOME  $ENV{OMDEV}/lib/3rdParty/Sundials/lib/release/mingw)
endif()

ENDIF( WIN32 )

SET(MODELICA_MODEL "ModelicaSystem")
SET(USE_MICO OFF)
SET(REDUCE_DAE OFF)
SET(USE_SUNDIALS ON)
SET(INSTALL_OMDEV_LIBS ON)

# Boost
SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
SET(Boost_USE_STATIC_RUNTIME OFF)
find_package(Boost 1.45.0 COMPONENTS serialization REQUIRED)
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

find_library(SUNDIALS_IDAS_LIB "sundials_idas"
    PATHS ${SUNDIALS_LIBRARY_RELEASE_HOME} )

set(SUNDIALS_LIBS ${SUNDIALS_NVECSERIAL_LIB}  ${SUNDIALS_CVODES_LIB}  ${SUNDIALS_IDAS_LIB} ${SUNDIALS_IDA_LIB})

message(STATUS "Sundials Libraries:")
message(STATUS ${SUNDIALS_LIBS})
add_definitions(-DPMC_USE_SUNDIALS)
endif()

#Mico corba
if(USE_MICO)
  find_library(MICO_LIBRARY  mico2313  
    PATHS ${MICO_LIB_HOME}) #you can add additional search paths for mico library
  find_path(MICO_INCLUDE_DIR CORBA.h 
     ${MICO_INCLUDE_HOME}) #you can add additional search paths for mico include
  message(STATUS ${MICO_LIBRARY})
  message(STATUS ${MICO_INCLUDE_DIR})
endif()



link_directories ( ${Boost_LIBRARY_DIRS} )

include_directories (${Boost_INCLUDE_DIR})
include_directories ("${PROJECT_SOURCE_DIR}")
include_directories ("${PROJECT_BINARY_DIR}")




#add solver default implemention project
add_subdirectory (Solver/Implementation)


#add  Euler solver project
add_subdirectory (Solver/Euler/Implementation)



#add  math project
add_subdirectory (Math/Implementation)
add_subdirectory (SettingsFactory/Implementation)
#add  simmanager project
add_subdirectory (SimManager)

if(REDUCE_DAE)
  add_subdirectory(ReduceDAE/Implementation)
endif()

add_subdirectory (System/Implementation)
add_subdirectory (System/Modelica)
add_subdirectory (System/Newton/Implementation)
add_subdirectory (ModelicaExternalC)

if(USE_SUNDIALS)
#add  Cvode solver project
add_subdirectory (Solver/CVode/Implementation)
#add  Idas solver project
add_subdirectory (Solver/Idas/Implementation)
add_subdirectory (Solver/Ida/Implementation)
GET_TARGET_PROPERTY(libCVode CVode LOCATION)
GET_FILENAME_COMPONENT(libCVodeName ${libCVode} NAME)
GET_TARGET_PROPERTY(libIdas Idas LOCATION)
GET_FILENAME_COMPONENT(libIdasName ${libIdas} NAME)
GET_TARGET_PROPERTY(libIda Ida LOCATION)
GET_FILENAME_COMPONENT(libIdaName ${libIda} NAME)

set (IDAS_LIB ${libIdasName})
set (CVODE_LIB ${libCVodeName})
set (IDA_LIB ${libIdaName})
endIf()

GET_TARGET_PROPERTY(libNewton Newton LOCATION)
GET_FILENAME_COMPONENT(libNewtonName ${libNewton} NAME) 

GET_TARGET_PROPERTY(libEuler Euler LOCATION)
GET_FILENAME_COMPONENT(libEulerName ${libEuler} NAME)



GET_TARGET_PROPERTY(libSetFactory SettingsFactory LOCATION)
GET_FILENAME_COMPONENT(libSetFactoryName ${libSetFactory} NAME)

GET_TARGET_PROPERTY(libModelica Modelica LOCATION)
GET_FILENAME_COMPONENT(libModelicaName ${libModelica} NAME)

GET_TARGET_PROPERTY(libSystem System LOCATION)
GET_FILENAME_COMPONENT(libSystemName ${libSystem} NAME)


set (EULER_LIB ${libEulerName})
set (SETTINGSFACTORY_LIB ${libSetFactoryName})
set (MODELICASYSTEM_LIB ${libModelicaName})
set (NEWTON_LIB ${libNewtonName})
set (SYSTEM_LIB ${libSystemName})
# configure a header file to pass some library names
# to the source code which are used to dynamic load and instantiate 

configure_file (
  "${PROJECT_SOURCE_DIR}/LibrariesConfig.h.in"
  "${PROJECT_BINARY_DIR}/LibrariesConfig.h"
  )

message(STATUS  ${SUNDIALS_CVODES_LIB})

if(INSTALL_OMDEV_LIBS)
  if(USE_SUNDIALS)
    install (FILES "${SUNDIALS_NVECSERIAL_LIB}"  "${SUNDIALS_IDAS_LIB}" "${SUNDIALS_IDA_LIB}" "${SUNDIALS_CVODES_LIB}" DESTINATION bin)
  endif()

  if(USE_MICO)
    install (FILES "${MICO_LIBRARY}"   DESTINATION bin)
  endif()

  install (FILES "${LAPACK_lapack_LIBRARY}"   DESTINATION bin)
  install (FILES "${BLAS_blas_LIBRARY}"   DESTINATION bin)
  #install (FILES "${Boost_LIBRARIES}"   DESTINATION bin)
endif()


MACRO(INSTALL_HEADERS_WITH_DIRECTORY HEADER_LIST)
 
FOREACH(HEADER ${${HEADER_LIST}})
    STRING(REGEX MATCH "(.*)[/\\]" DIR ${HEADER})
    INSTALL(FILES ${HEADER} DESTINATION include/omc/cpp/${DIR})
ENDFOREACH(HEADER)
 
ENDMACRO(INSTALL_HEADERS_WITH_DIRECTORY)
 



install (FILES "${PROJECT_BINARY_DIR}/LibrariesConfig.h" DESTINATION include/omc/cpp)
install (FILES "DataExchange/Interfaces/IHistory.h" 
  DESTINATION include/omc/cpp/DataExchange/Interfaces)
 
 
 #copy utils/extension
 SET(HS utils/extension/adaptable_factory.hpp  utils/extension/common.hpp utils/extension/convenience.hpp 
		utils/extension/extension.hpp  utils/extension/factory.hpp utils/extension/factory_map.hpp utils/extension/filesystem.hpp 
		utils/extension/parameter.hpp utils/extension/parameter_map.hpp utils/extension/registry.hpp utils/extension/shared_library.hpp 
		utils/extension/type_map.hpp
 utils/extension/impl/adaptable_factory.hpp utils/extension/impl/adaptable_factory_free_functions.hpp utils/extension/impl/adaptable_factory_set.hpp
 utils/extension/impl/create.hpp  utils/extension/impl/create_func.hpp utils/extension/impl/decl.hpp
 utils/extension/impl/factory.hpp utils/extension/impl/factory_map.hpp utils/extension/impl/function.hpp utils/extension/impl/library_impl.hpp 
 utils/extension/impl/shared_library.hpp utils/extension/impl/typeinfo.hpp) 
   INSTALL_HEADERS_WITH_DIRECTORY(HS)
  