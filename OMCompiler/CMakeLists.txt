cmake_minimum_required(VERSION 3.14)
project(OMCompiler)

# Variable for signifying that we are using the new CMake configuration.
# We use this to selectively include some cmake source files
# e.g. simulationRuntime/c/ has two cmake sources that are conditionally
# included. The old (cmake 2.8) cmake source in there is used for compilation
# of simulationruntimemsvc by the Makefile.omdev.mingw makefiles.
set(OPENMODELICA_NEW_CMAKE_BUILD ON)

# set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/.cmake/")
include(omc_utils)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
omc_add_to_report(CMAKE_BUILD_TYPE)

# Precaution so that users do not install in system folders (e.g. /user/, /usr/local/)
# unintentionally. If the user has not specified anything default to an install_cmake dir in the root folder.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${PROJECT_SOURCE_DIR}/install_cmake CACHE PATH "Default installation directory" FORCE)
    message(WARNING "No installation directory specified. ${CMAKE_INSTALL_PREFIX}")
endif()
omc_add_to_report(CMAKE_INSTALL_PREFIX)


# Set the installation lib directory as an rpath for all installed
# libs and executables.
# Maybe there is a better way to do this but it should suffice for now.
SET(CMAKE_INSTALL_RPATH ${CMAKE_INSTALL_PREFIX}/lib)


# options
option(OMC_USE_CORBA "Should use corba." OFF)
omc_add_to_report(OMC_USE_CORBA)


omc_add_subdirectory(3rdParty)

# We do this after 3rdParty is added because some libs in FMILib use implicit function declaration
# because of missing #defines due to bad configuration.

# We want to make sure include directories are handled properly.
# We have to disable implicit function declaration so that we can be consistent and correct with our inclusions.
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
endif()

omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Parser)
omc_add_subdirectory(Compiler)


message(STATUS "--------------------------------------------------------------------------")
message(STATUS "--------------------------------------------------------------------------")
feature_summary(WHAT ALL)
