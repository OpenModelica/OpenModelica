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

# LLVM backend for the MetaModelica compiler (PR #11766 revive).
# OM_OMC_ENABLE_LLVM: when ON the build finds a host LLVM (>= 16) and wires up
# the real Compiler/LLVM/* MetaModelica sources plus the
# Compiler/runtime/llvm_gen.cpp backend (IR generation and the in-process JIT
# that runs it, -d=jitSimulate); when OFF it links against stubs. A single flag
# is deliberate: IR generation and JIT execution currently share one
# translation unit (llvm_gen.cpp), so there is nothing yet to gate separately.
# If an ahead-of-time (AoT) path is added later -- and the JIT runtime is split
# out of llvm_gen.cpp -- a JIT/AoT sub-option can be reintroduced under this
# master.
#
# Default OFF: the LLVM backend is experimental and strictly opt-in. A build
# that does not pass -DOM_OMC_ENABLE_LLVM=ON proceeds exactly as before through
# the stub path, whether or not a host LLVM is installed -- so a machine or CI
# image without llvm-dev (which today includes the build-deps image) is
# completely unaffected, and the mere presence of an LLVM install never changes
# the default build. Enable it explicitly to build and test the backend;
# Compiler/runtime then locates the host LLVM, preferring 18 then 16. A
# non-MSYS clang toolchain on Windows is left open; macOS and MSYS/MinGW Windows
# are not supported.
set(OM_OMC_LLVM_PLATFORM_OK FALSE)
if(NOT APPLE)
  if(NOT WIN32)
    set(OM_OMC_LLVM_PLATFORM_OK TRUE)
  elseif(CMAKE_C_COMPILER_ID STREQUAL "Clang" AND NOT MINGW AND NOT MSYS)
    set(OM_OMC_LLVM_PLATFORM_OK TRUE)
  endif()
endif()

omc_option(OM_OMC_ENABLE_LLVM "Enable the LLVM backend (IR generation + in-process JIT) for the MetaModelica compiler (experimental, revive of PR #11766)." OFF)

# Safety net: if the option is forced ON on an unsupported platform (macOS,
# MSYS/MinGW Windows, a non-clang Windows compiler), turn it back off with a
# warning rather than fail the build.
if(OM_OMC_ENABLE_LLVM AND NOT OM_OMC_LLVM_PLATFORM_OK)
  message(WARNING "OM_OMC_ENABLE_LLVM is not supported on this platform; forcing it OFF.")
  set(OM_OMC_ENABLE_LLVM OFF CACHE BOOL "Enable the LLVM backend (IR generation + in-process JIT) for the MetaModelica compiler (experimental, revive of PR #11766)." FORCE)
endif()


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

omc_add_subdirectory(SimulationRuntime)
omc_add_subdirectory(Parser)
omc_add_subdirectory(Compiler)
omc_add_subdirectory(Examples)
