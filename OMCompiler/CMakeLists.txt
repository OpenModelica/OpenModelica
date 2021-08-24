cmake_minimum_required(VERSION 3.14)
project(OMCompiler C CXX Fortran)

# Variable for signifying that we are using the new CMake configuration.
# We use this to selectively include some cmake source files
# e.g. simulationRuntime/c/ has two cmake sources that are conditionally
# included. The old (cmake 2.8) cmake source in there is used for compilation
# of simulationruntimemsvc by the Makefile.omdev.mingw makefiles.
set(OPENMODELICA_NEW_CMAKE_BUILD ON)

# Remove -DNDEBUG from release build command lines. The reason is that -DNDEBUG completely
# removes assert(...) statements. We have some assert statements with side effects. Of course,
# these should be removed and the flag enabled so that we can benefit from removing asserts from
# libraries and standard headers.
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")

string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO}")
string(REPLACE "-DNDEBUG" "" CMAKE_C_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE}")


# include utility macros.
include(.cmake/omc_utils.cmake)
include(.cmake/omc_target_info.cmake)
include(.cmake/omc_check_exists.cmake)

# Add the compiler ids to the report for convenience.
omc_add_to_report(CMAKE_C_COMPILER_ID)
omc_add_to_report(CMAKE_CXX_COMPILER_ID)
omc_add_to_report(CMAKE_Fortran_COMPILER_ID)
omc_add_to_report(CMAKE_LIBRARY_ARCHITECTURE)

#########################################################################################################
## Set the C standard to use. Unfortunately, we can not enforce c90.
## Our sources contain a lot of c99 and gnu extension code.
# set(CMAKE_C_STANDARD 90)

## Set the C++ standard to use.
set(CMAKE_CXX_STANDARD 11)
set(CXX_STANDARD_REQUIRED ON)
## Make sure we do not start relying on extensions down the road.
set(CMAKE_CXX_EXTENSIONS OFF)

## Set position independent code project wide. We will take some performance hit from this.
## However it allows us to build all static libs and combine them later to single shared libs
## for easy configuration. Instead of having dozens of shared libs.
## This can of course be turned of if we do not care about memory and are happy to sacrifice a
## bunch of memory for some performance gain. If so disable this and change the few libraries
## we build as shared to static (see SimulationRuntime/c, which contains the only shared libs to come).
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

#########################################################################################################
## Enable verbose Makefiles if you want to debug. (you can also instead use 'make VERBOSE=1')
# set(CMAKE_VERBOSE_MAKEFILE ON)

# Export compile commands (compile_commands.json) for each source file. This helps editors (e.g. vscode, emacs) have
# a more accurate code navigation and intellisense. E.g. includes can be pinpointed instead of
# using glob expressions to parse everything.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)


if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
omc_add_to_report(CMAKE_BUILD_TYPE)


# Install following GNU conventions (i.e., bin, lib, include, share ...)
include(GNUInstallDirs)

# Precaution so that users do not install in system folders (e.g. /user/, /usr/local/)
# unintentionally. If the user has not specified anything default to an install_cmake dir in the root
# build directory.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX ${PROJECT_BINARY_DIR}/install_cmake CACHE PATH "Default installation directory" FORCE)
    # Prevent sub-projects from changing it by checking CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT after this
    set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT FALSE)
    message(WARNING "No installation directory specified. Defaulting to: ${CMAKE_INSTALL_PREFIX}")
endif()
omc_add_to_report(CMAKE_INSTALL_PREFIX)

# We prefer to install libs to "<library architecture>/omc" dir inside lib directory (e.g lib/x86_64-linux-gnu/omc/).
set(CMAKE_INSTALL_LIBDIR ${CMAKE_INSTALL_LIBDIR}/${CMAKE_LIBRARY_ARCHITECTURE}/omc/)

## Set the adjusted installation lib directory as an rpath for all installed binaries.
## This is useful for those binaries that end up in bin/ directory but not for
## others as it is a relative path to the lib dir from <build_dir>/<some_dir>.
## Maybe there is a better way to do this but it should suffice for now.
set(CMAKE_INSTALL_RPATH "$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")


# Write out a compiler detection header. checkout the file <build_dir>/omc_compiler_detection.h to
# get an idea of what it means. We intend to use this for portability reasons in the future.
# You know. things like is it ctime_s() or ctime_r(), MvFileEx() vs rename() and the like.
include(WriteCompilerDetectionHeader)
write_compiler_detection_header(
  FILE omc_compiler_detection.h
  PREFIX OMC
  COMPILERS GNU Clang MSVC
  FEATURES cxx_static_assert
)

# Use ccache to speedup compilation!
omc_option(OMC_USE_CCACHE "Use ccache to speedup compilations." ON)

if(OMC_USE_CCACHE)
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    message(STATUS "Found ccache. It will be used for compilation C/C++ sources")
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
    set(CMAKE_C_COMPILER_LAUNCHER   ${CCACHE_PROGRAM})
    omc_add_to_report(CCACHE_PROGRAM)
  else()
    message(FATAL_ERROR "ccache program not found. It is highly recommended to use ccache for compilation of OpenModelica. Please install ccache and rerun configuration.
            You can disable this check by specifying -DOMC_USE_CCACHE=OFF to CMake configuration command.")
  endif()
endif()



# options
omc_option(OMC_USE_CORBA "Should use corba." OFF)

omc_option(OMC_USE_LPSOLVE "Should we use lpsolve." OFF)
omc_option(OMC_BUILD_LPSOLVE "Should we build our own 3rdParty/lpsolve." OFF)

omc_option(OMC_USE_LAPACK "Should we use lapack." ON)


add_library(omc_config INTERFACE)
add_library(omc::config ALIAS omc_config)
target_include_directories(omc_config INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})



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
