cmake_minimum_required(VERSION 3.14)
project(OMCompiler)

# We use this to selectively include some cmake source files
# e.g. simulationRuntime/c/ has two cmake sources that are conditionally
# included. The old (cmake 2.8) cmake source in there is used for compilation
# of simulationruntimemsvc by the Makefile.omdev.mingw makefiles.
set(OPENMODELICA_NEW_CMAKE_BUILD ON)

# set(CMAKE_VERBOSE_MAKEFILE ON)

set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_SOURCE_DIR}/.cmake/")
include(omc_utils)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Release" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
omc_add_to_report(CMAKE_BUILD_TYPE)


# options
option(OMC_USE_CORBA "Should use corba." OFF)
omc_add_to_report(OMC_USE_CORBA)


omc_add_subdirectory(3rdParty)

# We want to make sure include directories are handled properly. C allows implicit function
# declaration. We have to disable that so that we can be consistent and correct with our inclusions.
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
endif()

omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Parser)
omc_add_subdirectory(Compiler)


message(STATUS "--------------------------------------------------------------------------")
message(STATUS "--------------------------------------------------------------------------")
feature_summary(WHAT ALL)
