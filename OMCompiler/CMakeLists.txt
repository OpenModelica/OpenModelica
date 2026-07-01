cmake_minimum_required(VERSION 3.14)
project(OMCompiler C CXX)

# For now, unless explicitly specified otherwise, we set install component simrt
# for everything installed from the OMCompiler directory. There are some places that
# modify this explicitly, e.g., the omc compiler ('COMPONENT omc'), the cpp runtime (COMPONENT simrtcpp),
# and FMU realted installtions (COMPONENT fmu)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME simrt)

## OPTIONS #################################################################################################

omc_option(OM_OMC_ENABLE_FORTRAN "Enable Fortran support. Fortran is required if you enable IPOPT support." ON)
# Fortran is only needed by the C simulation runtime (MOO / old optimization),
# which the wasm/web bundle does not build — so don't require a Fortran compiler
# in wasm mode even though the option stays nominally ON.
if(OM_OMC_ENABLE_FORTRAN AND NOT OM_OMC_WASM)
  enable_language(Fortran)
endif()


omc_option(OM_OMC_ENABLE_MOO "Should we enable dynamic optimization support with MOO." ON)
if(OM_OMC_ENABLE_MOO AND NOT OM_OMC_ENABLE_FORTRAN)
  message(FATAL_ERROR "Building MOO requires Fortran support (-DOM_OMC_ENABLE_FORTRAN) to be enabled. "
                      "You can disable MOO by adding -DOM_OMC_ENABLE_MOO=OFF to the CMake configure command.")
endif()

omc_option(OM_OMC_ENABLE_OPTIMIZATION "Should we enable dynamic optimization support with the old Optimization Runtime." ON)
if(OM_OMC_ENABLE_OPTIMIZATION AND NOT OM_OMC_ENABLE_FORTRAN AND NOT OM_OMC_ENABLE_MOO)
  message(FATAL_ERROR "The old Optimization Runtime requires Fortran support (-DOM_OMC_ENABLE_FORTRAN) to be enabled and depends on MOO. "
                      "You can disable the old Optimization Runtime by adding -DOM_OMC_ENABLE_OPTIMIZATION=OFF to the CMake configure command. "
                      "You can disable MOO by adding -DOM_OMC_ENABLE_MOO=OFF to the CMake configure command. ")
endif()

omc_option(OM_OMC_ENABLE_PRIMME "Should we enable sparse singular value support with PRIMME." ON)

omc_option(OM_OMC_ENABLE_COLPACK "Should we enable graph coloring with ColPack." ON)

omc_option(OM_OMC_ENABLE_CPP_RUNTIME "Enable, build, and install the C++ simulation runtime libraries." ON)

omc_option(OM_OMC_USE_CORBA "Should use corba." OFF)

omc_option(OM_OMC_USE_LAPACK "Should we use lapack." ON)

# Build the Rust (mmtorust) omc port instead of the bootstrapped C omc. When ON,
# the compiler is produced by transpiling the MetaModelica sources to Rust and
# `cargo build`ing them (see Compiler/.cmake/rust_omc.cmake); bomc/omc are never
# compiled from C. The simulation/function runtime C libraries are still built.
omc_option(OM_OMC_ENABLE_RUST "Build the Rust (mmtorust) omc port instead of the bootstrapped C omc." OFF)


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
# Build dir first: it holds the CMake-generated omc_config.unix.h (the source dir
# may hold the autotools build's copy); source dir provides omc_config.h itself.
target_include_directories(omc_config INTERFACE ${OMCompiler_BINARY_DIR} ${CMAKE_CURRENT_SOURCE_DIR})


## Subdirectories ##########################################################################################
# The C/C++ 3rd-party libraries (fmilib, libzmq, lapack, …) are linked only by the
# native omc artifacts and the simulation runtime. The wasm/web bundle uses none
# of them (the cdylib is built --no-default-features), so skip them in wasm mode.
if(NOT OM_OMC_WASM)
  omc_add_subdirectory(3rdParty)
endif()


# These flags are set after 3rdParty is added so they do not affect 3rdParty libraries.
if (CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang" OR CMAKE_CXX_COMPILER_ID STREQUAL "AppleClang")
  # Disallow implicit function declarations: ensures include directories are handled properly.
  # Excluded from 3rdParty because FMILib uses implicit function declarations due to missing
  # #defines from bad configuration.
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=implicit-function-declaration>)
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=incompatible-pointer-types>)
  # VLAs are a C99/GCC extension not supported by MSVC; catching them prevents portability issues.
  add_compile_options($<$<COMPILE_LANGUAGE:C>:-Werror=vla>)
endif()

# The C simulation/function runtime libraries are dlopened by the native omc and
# installed alongside it; the wasm/web bundle does not use them, so skip them in
# wasm mode (leaving `make all` to build only the wasm target).
if(NOT OM_OMC_WASM)
  omc_add_subdirectory(SimulationRuntime)
endif()
# The ANTLR Modelica parser (omparse) and the Examples are part of the C omc
# toolchain only — the Rust omc port has its own parser and links neither. They
# also pull in the C compiler runtime (omc::compiler::runtime), which the Rust
# build deliberately does not build. Skip them in Rust mode.
if(NOT OM_OMC_ENABLE_RUST)
  omc_add_subdirectory(Parser)
endif()
omc_add_subdirectory(Compiler)
if(NOT OM_OMC_ENABLE_RUST)
  omc_add_subdirectory(Examples)
endif()
