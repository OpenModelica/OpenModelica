
cmake_minimum_required(VERSION 3.14)

option(OM_WITH_VCPKG "Use vcpkg to manage dependencies." OFF)
if(OM_WITH_VCPKG)
  set(X_VCPKG_APPLOCAL_DEPS_INSTALL ON)
  set(CMAKE_TOOLCHAIN_FILE vcpkg/scripts/buildsystems/vcpkg.cmake)
endif()

project(OpenModelica
        HOMEPAGE_URL "https://openmodelica.org/"
        LANGUAGES C CXX)

# Any custom Find* modules should be placed here.
set(CMAKE_MODULE_PATH ${CMAKE_MODULE_PATH} "${CMAKE_CURRENT_SOURCE_DIR}/cmake/modules/")

#########################################################################################################
## Enable verbose Makefiles if you want to debug. (you can also instead use 'make VERBOSE=1')
# set(CMAKE_VERBOSE_MAKEFILE ON)
## Disable colors if you do not want them.
# set(CMAKE_COLOR_MAKEFILE OFF)

# Variable for signifying that we are using the new CMake configuration.
# We use this to selectively include some cmake source files
# e.g. simulationRuntime/c/ has two cmake sources that are conditionally
# included. The old (cmake 2.8) cmake source in there is used for compilation
# of simulationruntimemsvc by the Makefile.omdev.mingw makefiles.
set(OPENMODELICA_NEW_CMAKE_BUILD ON)

# include utility macros.
include(cmake/omc_utils.cmake)
include(cmake/omc_target_info.cmake)
include(cmake/omc_check_exists.cmake)

## Get the revision info. The version is saved in the variable SOURCE_REVISION
include(cmake/omc_git_revision.cmake)

# Include the small thread library setup we have. This provides the library
# OMCPThreads::OMCPThreads which gives us a PThreads library on Windows as
# well as linux. See the file for more info.
include(cmake/OMCPThreads.cmake)

omc_add_to_report(CMAKE_VERSION)
# Add the compiler ids to the report for convenience.
omc_add_to_report(CMAKE_C_COMPILER_ID)
omc_add_to_report(CMAKE_CXX_COMPILER_ID)
omc_add_to_report(CMAKE_Fortran_COMPILER_ID)
omc_add_to_report(CMAKE_LIBRARY_ARCHITECTURE)


## OPTIONS #################################################################################################
omc_option(OM_ENABLE_GUI_CLIENTS "Enable, build, and install the qt based GUI clients." ON)

omc_option(OM_ENABLE_ENCRYPTION "Enable and build the OpenModelica Encryption support module. " OFF)

## Use ccache to speedup compilation! It is important to use ccache if you can.
## You get almost no op compilations (for unmodified files) at the cost of some memory.
## This is usefull, for example, in cases where you change branches often or need to clean
## for some reason. However, it is even more important with OMC because we generate C sources
## from MetaModelica files whenever they change. This causes CMake to issue compilations of
## dependent source files because headers are changed. ccache will essentially eliminate that cost.
omc_option(OM_USE_CCACHE "Use ccache to speedup compilations." ON)


### Standards ###############################################################################################
## Set the C standard to use. Unfortunately, we can not enforce c90.
## Our sources contain a lot of c99 and gnu extension code.
# set(CMAKE_C_STANDARD 90)

## Set the C++ standard to use. We use C++17 for everything in OpenModelica now.
## Note that 3rdParty libraries might set their own standards.
## If you need to use a different C++ standard for parts of OpenModelica, you can
## of course override this in the corresponding directory's CMake file.
set(CMAKE_CXX_STANDARD 17)
set(CXX_STANDARD_REQUIRED ON)
## Make sure we do not start relying on extensions down the road.
set(CMAKE_CXX_EXTENSIONS OFF)


### Build type configurations ###############################################################################
# Default build type is Debug.
if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
      "Choose the type of build, options are: Debug Release RelWithDebInfo MinSizeRel." FORCE)
endif(NOT CMAKE_BUILD_TYPE)
omc_add_to_report(CMAKE_BUILD_TYPE)

## Set position independent code for everything built in OpenModelica.
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

if(OM_USE_CCACHE)
  find_program(CCACHE_PROGRAM ccache)
  if(CCACHE_PROGRAM)
    message(STATUS "Found ccache. It will be used for compilation C/C++ sources")
    set(CMAKE_CXX_COMPILER_LAUNCHER ${CCACHE_PROGRAM})
    set(CMAKE_C_COMPILER_LAUNCHER   ${CCACHE_PROGRAM})
    omc_add_to_report(CCACHE_PROGRAM)
  else()
    message(FATAL_ERROR "ccache program not found. It is highly recommended to use ccache for compilation of OpenModelica. Please install ccache and rerun configuration.
            You can disable this check by specifying -DOM_USE_CCACHE=OFF to CMake configuration command.")
  endif()
endif()

# Export compile commands (compile_commands.json) for each source file. This helps editors (e.g. vscode, emacs) have
# a more accurate code navigation and intellisense. E.g. includes can be pinpointed instead of
# using glob expressions to parse everything.
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

### Installation configurations ###############################################################################
# Install following GNU conventions (i.e., bin, lib, include, share ...)
include(GNUInstallDirs)

# Precaution so that users do not install in system folders (e.g. /user/, /usr/local/)
# unintentionally. If the user has not specified anything default to an install_cmake dir in the root
# build directory.
if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT)
    set(CMAKE_INSTALL_PREFIX "${PROJECT_BINARY_DIR}/install_cmake" CACHE PATH "Default installation directory" FORCE)
    # Prevent sub-projects from changing it by checking CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT after this
    set(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT FALSE)
    message(WARNING "No installation directory specified. Defaulting to: ${CMAKE_INSTALL_PREFIX}")
endif()
omc_add_to_report(CMAKE_INSTALL_PREFIX)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20")
  cmake_path(APPEND CMAKE_INSTALL_LIBDIR "${CMAKE_LIBRARY_ARCHITECTURE}" "omc")
else()
  set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/${CMAKE_LIBRARY_ARCHITECTURE}/omc/")
endif()
message(STATUS "CMAKE_INSTALL_LIBDIR: ${CMAKE_INSTALL_LIBDIR}")

# We prefer to install headers to "include/omc" dir inside.
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.20")
  cmake_path(APPEND CMAKE_INSTALL_INCLUDEDIR "omc")
else()
  set(CMAKE_INSTALL_INCLUDEDIR "${CMAKE_INSTALL_INCLUDEDIR}/omc/")
endif()
message(STATUS "CMAKE_INSTALL_INCLUDEDIR: ${CMAKE_INSTALL_INCLUDEDIR}")

# On macOS we want BUNDLEs (.app) to go to an 'Applications/' directory instead of a 'bin/' directory
if(APPLE)
  set(OM_MACOS_INSTALL_BUNDLEDIR "Applications/")
endif()

## Set the adjusted installation lib directory as an rpath for all installed binaries.
## Assumes binaries end up in either 'bin' or 'lib' AND also assumes that 'bin' and 'lib' are sibling directories.
if(APPLE)
  ## MacOS Bundles end up in bin/<BundleName>.app/Contents/MacOS/
  ## So make sure that the lib dir is referenced from that location as well
  set(CMAKE_INSTALL_RPATH "@loader_path/../${CMAKE_INSTALL_LIBDIR};@loader_path/../../../../${CMAKE_INSTALL_LIBDIR}")
else()
  set(CMAKE_INSTALL_RPATH "$ORIGIN;$ORIGIN/../${CMAKE_INSTALL_LIBDIR}")
endif()

## Do not print unnecessary install messages when nothing has actually changed.
set(CMAKE_INSTALL_MESSAGE LAZY)

# Set a 'catch-all' install component "unknown-install-component". If you see some install component under this
# id, then you know that something has not set an install component either explicitly on the install() command
# or at higher level using 'set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME <id>)' to cover all install() commands
# issues after it.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME "unknown-install-component")

## Subdirectories ##########################################################################################
# If asked for encryption support, add and configure the OMEncryption directory.
if(OM_ENABLE_ENCRYPTION)
  omc_add_subdirectory(OMEncryption)
endif()

## Include and enable testing
set(CMAKE_CTEST_ARGUMENTS "--output-on-failure" "--output-junit" "junit.xml")
include(CTest)
enable_testing()

omc_add_subdirectory(OMCompiler)

if(OM_ENABLE_GUI_CLIENTS)
  # select qt version 5/6
  set (OM_QT_MAJOR_VERSION 5 CACHE STRING "Qt version")

  omc_add_subdirectory(OMParser)
  omc_add_subdirectory(OMPlot)
  omc_add_subdirectory(OMShell)
  omc_add_subdirectory(OMNotebook)
  omc_add_subdirectory(OMSimulator)
  omc_add_subdirectory(OMEdit)
  omc_add_subdirectory(OMSens_Qt)
endif()

omc_add_subdirectory(libraries)
omc_add_subdirectory(testsuite)

## Packaging ##########################################################################################
# Configure the file OpenModelicaCPackOptions.in.cmake to pick up full paths based on the current location.
# This will generate the output file in the build directory.
configure_file(cmake/packaging/OpenModelicaCPackOptions.in.cmake ${CMAKE_CURRENT_BINARY_DIR}/OpenModelicaCPackOptions.cmake)
# Tell CPack to use this configured file when it is invoked to create packages.
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/OpenModelicaCPackOptions.cmake)
# Tell CPack about our components (dispaly names, descriptions, dependencies ...)
include(cmake/packaging/components.cmake)

## Report some status info.
message(STATUS "--------------------------------------------------------------------------")
message(STATUS "--------------------------------------------------------------------------")
feature_summary(WHAT ALL)
