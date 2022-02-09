cmake_minimum_required(VERSION 3.14)
project(OMCompiler C CXX Fortran)

## OPTIONS #################################################################################################

omc_option(OM_OMC_ENABLE_CPP_RUNTIME "Enable, build, and install the C++ simulation runtime libraries." ON)

omc_option(WITH_IPOPT "Should we enable dynamic optimization support with Ipopt." ON)
omc_option(OM_OMC_USE_CORBA "Should use corba." OFF)

omc_option(OM_OMC_USE_LPSOLVE "Should we use lpsolve." OFF)
omc_option(OM_OMC_BUILD_LPSOLVE "Should we build our own 3rdParty/lpsolve." OFF)

omc_option(OM_OMC_USE_LAPACK "Should we use lapack." ON)


# Remove -DNDEBUG from release build command lines. The reason is that -DNDEBUG completely
# removes assert(...) statements. We have some assert statements with side effects. Of course,
# these should be removed and the flag enabled so that we can benefit from removing asserts from
# libraries and standard headers.
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")

string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")

## Set position independent code OMCompiler/ wide. We will take some performance hit from this.
## However it allows us to build all static libs and combine them later to single shared libs
## for easy configuration. Instead of having dozens of shared libs.
## This can of course be turned of if we do not care about memory and are happy to sacrifice a
## bunch of memory for some performance gain. If so disable this and change the few libraries
## we build as shared to static (see SimulationRuntime/c, which contains the only shared libs to come).
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

## Add a config library for OMC. They will provide access to common config headres such as
## config.h, version.h ... These headers, right now for us, are in 'OMCompiler' directory. So
## by linking to this library you get the include directories.
add_library(omc_config INTERFACE)
add_library(omc::config ALIAS omc_config)
target_include_directories(omc_config INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})


## Subdirectories ##########################################################################################
omc_add_subdirectory(3rdParty)


# We want to make sure include directories are handled properly by disabling implicit function
# declaration so that we can be consistent and correct with our inclusions.
# We do this after 3rdParty is added!! because some libs in FMILib use implicit function declaration
# because of missing #defines due to bad configuration for now.
if (CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
endif()

omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Parser)
omc_add_subdirectory(Compiler)

