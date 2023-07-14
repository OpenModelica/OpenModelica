cmake_minimum_required(VERSION 3.14)
project(OMCompiler C CXX)

# For now, unless explicitly specified otherwise, we set install component simrt
# for everything installed from the OMCompiler directory. There are some places that
# modify this explicitly, e.g., the omc compiler ('COMPONENT omc'), the cpp runtime (COMPONENT simrtcpp),
# and FMU realted installtions (COMPONENT fmu)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME simrt)

## OPTIONS #################################################################################################

omc_option(OM_OMC_ENABLE_FORTRAN "Enable Fortran support. Fortran is required if you enable IPOPT support." ON)
if(OM_OMC_ENABLE_FORTRAN)
  enable_language(Fortran)
endif()


omc_option(OM_OMC_ENABLE_IPOPT "Should we enable dynamic optimization support with Ipopt." ON)
if(OM_OMC_ENABLE_IPOPT AND NOT OM_OMC_ENABLE_FORTRAN)
  message(FATAL_ERROR "Ipopt support requires Fortran support to be enabled. You can disable Ipopt by adding -DOM_OMC_ENABLE_IPOPT=OFF to the CMake configure command.")
endif()

omc_option(OM_OMC_ENABLE_CPP_RUNTIME "Enable, build, and install the C++ simulation runtime libraries." ON)

omc_option(OM_OMC_USE_CORBA "Should use corba." OFF)

omc_option(OM_OMC_USE_LAPACK "Should we use lapack." ON)


# Remove -DNDEBUG from release build command lines. The reason is that -DNDEBUG completely
# removes assert(...) statements. We have some assert statements with side effects. Of course,
# these should be removed and the flag enabled so that we can benefit from removing asserts from
# libraries and standard headers.
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")

string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE}")

## Add a config library for OMC. They will provide access to common config headres such as
## config.h, version.h ... These headers, right now for us, are in 'OMCompiler' directory. So
## by linking to this library you get the include directories.
add_library(omc_config INTERFACE)
add_library(omc::config ALIAS omc_config)
if(WIN32)
  if(DEFINED ENV{MSYSTEM_PREFIX})
    string(FIND $ENV{MSYSTEM_PREFIX} "ucrt64" IS_UCRT64)
    if(IS_UCRT64)
      target_compile_definitions(omc_config INTERFACE UCRT64)
      message(STATUS "omc_config.h: CONFIG_OPENMODELICA_SPEC_PLATFORM=ucrt64")
    endif()
  endif()
endif()
target_include_directories(omc_config INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})


## Subdirectories ##########################################################################################
omc_add_subdirectory(3rdParty)


# We want to make sure include directories are handled properly by disabling implicit function
# declaration so that we can be consistent and correct with our inclusions.
# We do this after 3rdParty is added!! because some libs in FMILib use implicit function declaration
# because of missing #defines due to bad configuration for now.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=incompatible-pointer-types>)
endif()

omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Parser)
omc_add_subdirectory(Compiler)
omc_add_subdirectory(Examples)
