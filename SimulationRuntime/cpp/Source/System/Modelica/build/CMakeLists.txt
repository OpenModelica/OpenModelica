cmake_minimum_required (VERSION 2.6)

project(Modelica)

# on windows  boost,blas,lapack from omdev is used else the installed versions are used
IF( WIN32 )
SET(ENV{BOOST_ROOT} $ENV{OMDEV}"/lib/3rdParty/boost_1_45_0/")
set(BLAS_blas_LIBRARY $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/blas.dll CACHE FILEPATH "Blas library")
set(LAPACK_lapack_LIBRARY  $ENV{OMDEV}/lib/3rdParty/Lapack/Lib/lapack.dll CACHE FILEPATH "Lapack library")
ENDIF( WIN32 )

SET(Boost_USE_STATIC_LIBS OFF)
SET(Boost_USE_MULTITHREADED ON)
SET(Boost_USE_STATIC_RUNTIME OFF)
SET(MODELICA_MODEL "ModelicaSystem")

find_package(Boost 1.45.0 COMPONENTS serialization REQUIRED )
find_package( Lapack REQUIRED)


SET(MODELICA_INCLUDE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../include")
SET(MODELICA_BIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../bin")
link_directories ( ${Boost_LIBRARY_DIRS} )
link_directories ( ${MODELICA_BIN_DIR} )
include_directories ( ${Boost_INCLUDE_DIRS} )
include_directories( ${MODELICA_INCLUDE_DIR} )



MESSAGE( STATUS "PROJECT_BINARY_DIR:         " ${PROJECT_BINARY_DIR} )
MESSAGE( STATUS "MODELICA_INCLUDE:         " ${MODELICA_INCLUDE} )




add_library(Modelica SHARED ModelicaSystem.cpp )
target_link_libraries (Modelica  System)

#install (TARGETS Modelica DESTINATION bin)
  
  
 
