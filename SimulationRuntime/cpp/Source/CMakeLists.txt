cmake_minimum_required (VERSION 2.6)

project(CppSolverInterface)

# on windows  boost,blas,lapack from omdev is used else the installed versions are used
IF( WIN32 )
SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost_1_45_0/")
#set(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas.dll CACHE FILEPATH "Blas library")
#set(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack.dll CACHE FILEPATH "Lapack library")
#Lapack and Blas for Visual Studio
set(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas_win32.dll CACHE FILEPATH "Blas library")
set(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack_win32.dll CACHE FILEPATH "Lapack library")
ENDIF( WIN32 )

SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
SET(Boost_USE_STATIC_RUNTIME OFF)
SET(MODELICA_MODEL "ModelicaSystem")

find_package(Boost 1.45.0 COMPONENTS serialization REQUIRED )
find_package( BLAS )
find_package( LAPACK  )
 #PATHS $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/ 
link_directories ( ${Boost_LIBRARY_DIRS} )
include_directories ( ${Boost_INCLUDE_DIRS} )



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
#add  system default implementation project

add_subdirectory (System/Implementation)
add_subdirectory (System/Modelica)
add_subdirectory (System/Newton/Implementation)
#include_directories ("${PROJECT_SOURCE_DIR}/System/Modelica/Implementation")

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

  

install (FILES "${PROJECT_BINARY_DIR}/LibrariesConfig.h" DESTINATION bin)
install (FILES "DataExchange/Interfaces/IHistory.h" 
  DESTINATION include/omc/cpp/DataExchange/Interfaces)