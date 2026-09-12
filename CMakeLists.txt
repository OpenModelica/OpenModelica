
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
# included. The old (cmake 2.8) cmake source in there is used by the legacy
# standalone Autoconf/Make build.
set(OPENMODELICA_NEW_CMAKE_BUILD ON)

# include utility macros.
include(cmake/omc_utils.cmake)
include(cmake/omc_target_info.cmake)
include(cmake/omc_check_exists.cmake)

## Get the revision info. The version is saved in the variable SOURCE_REVISION
include(cmake/omc_git_revision.cmake)

# Every configure-time download in the tree lands here. Point it outside the
# build tree to survive a wipe, or in-source to bundle for an offline tarball.
set(OM_DOWNLOADS_DIR "${CMAKE_BINARY_DIR}/downloads" CACHE PATH
    "Cache for everything the configure step downloads.")

# Cross-compiling to Windows (xwin toolchain): fetch PThreads4W and OpenBLAS.
# Before OMCPThreads.cmake, which find_package(pthreads CONFIG REQUIRED).
include(${CMAKE_CURRENT_SOURCE_DIR}/OMCompiler/Compiler/OpenModelica.rs/.cmake/windows-deps.cmake)

# Include the small thread library setup we have. This provides the library
# OMCPThreads::OMCPThreads which gives us a PThreads library on Windows as
# well as linux. See the file for more info.
include(cmake/OMCPThreads.cmake)

if (MINGW)
SET(IS_MINGW64 ON)
endif(MINGW)

omc_add_to_report(CMAKE_VERSION)
# Add the compiler ids to the report for convenience.
omc_add_to_report(CMAKE_C_COMPILER_ID)
omc_add_to_report(CMAKE_CXX_COMPILER_ID)
omc_add_to_report(CMAKE_Fortran_COMPILER_ID)
omc_add_to_report(CMAKE_LIBRARY_ARCHITECTURE)

# `lib/<OM_LIBRARY_ARCH>/omc` holds what omc installs for one target. CMake fills
# CMAKE_LIBRARY_ARCHITECTURE only where GNU multiarch applies, so Windows and macOS
# used to flatten into lib/omc with nowhere to put another target's libraries; keep
# the same <cpu>-<os>-<env> scheme for them.
if(CMAKE_LIBRARY_ARCHITECTURE)
  set(OM_LIBRARY_ARCH "${CMAKE_LIBRARY_ARCHITECTURE}")
else()
  if(CMAKE_SYSTEM_PROCESSOR MATCHES "^(x86_64|AMD64|amd64)$")
    set(_om_arch x86_64)
  elseif(CMAKE_SYSTEM_PROCESSOR MATCHES "^(aarch64|arm64|ARM64)$")
    set(_om_arch aarch64)
  else()
    string(TOLOWER "${CMAKE_SYSTEM_PROCESSOR}" _om_arch)
  endif()
  if(APPLE)
    # `universal`, not the CPU: mac-universal.sh lipos the two per-architecture
    # trees, which only merge where their paths coincide.
    set(OM_LIBRARY_ARCH "universal-apple-darwin")
  elseif(WIN32 AND (MINGW OR CYGWIN))
    set(OM_LIBRARY_ARCH "${_om_arch}-windows-gnu")
  elseif(WIN32)
    set(OM_LIBRARY_ARCH "${_om_arch}-windows-msvc")
  elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    # Arch and friends leave CMAKE_LIBRARY_ARCHITECTURE empty; Autoconf.rs still
    # computes <cpu>-linux-gnu, so the install has to write there.
    if(CMAKE_SYSTEM_PROCESSOR MATCHES "musl")
      set(OM_LIBRARY_ARCH "${_om_arch}-linux-musl")
    else()
      set(OM_LIBRARY_ARCH "${_om_arch}-linux-gnu")
    endif()
  else()
    string(TOLOWER "${CMAKE_SYSTEM_NAME}" _om_os)
    set(OM_LIBRARY_ARCH "${_om_arch}-${_om_os}")
  endif()
endif()
omc_add_to_report(OM_LIBRARY_ARCH)

## OPTIONS #################################################################################################

# Web (wasm) target: build the browser/Node WebAssembly bundle of omc. It is a
# Rust-omc build (OM_OMC_ENABLE_RUST) compiled for wasm32-unknown-unknown, so the
# C libraries and the *Qt* GUI clients are unused. We force Rust mode on and skip
# the native runtime / 3rdParty / libraries / testsuite subdirectories. The Qt
# clients (the OM_ENABLE_GUI_CLIENTS subdirs below) are guarded with NOT
# OM_OMC_WASM rather than forcing the flag off, so OM_ENABLE_GUI_CLIENTS still
# carries the user's intent into the wasm build — where it selects the OMShell
# *web* pages (omshell_egui + omshell_dioxus; see omc_rust_setup_wasm). Mode/
# profile is chosen with RUST_OMC_WASM_MODE.
omc_option(OM_OMC_WASM "Build only the WebAssembly (browser/Node) omc bundle." OFF)
if(OM_OMC_WASM)
  set(OM_OMC_ENABLE_RUST ON CACHE BOOL "Build the Rust (mmtorust) omc port instead of the bootstrapped C omc." FORCE)
endif()

## On Conda-forge this should be disabled
omc_option(OM_MACOS_APP_BUNDLE "Build GUI clients as application bundles on macOS" ON)
mark_as_advanced(OM_MACOS_APP_BUNDLE)

omc_option(OM_ENABLE_ENCRYPTION "Enable and build the OpenModelica Encryption support module. " OFF)

cmake_dependent_option(OM_ENABLE_OMSIMULATOR "Enable OMSimulator" ON "NOT OM_OMC_WASM" OFF)
omc_add_to_report(OM_ENABLE_OMSIMULATOR)

# The User's Guide is generated by running an *installed* OpenModelica, so it
# cannot be part of 'all': build and install the project first, then build the
# 'usersguide' target. See doc/UsersGuide/CMakeLists.txt.
omc_option(OM_ENABLE_DOCS "Enable the User's Guide target. Needs Sphinx, pandoc, inkscape and gnuplot." OFF)

# GUI options
omc_option(OM_ENABLE_GUI_CLIENTS "Enable, build, and install the qt based GUI clients." ON)
# Qt version (5/6) used by the GUI clients.
set(OM_QT_MAJOR_VERSION 6 CACHE STRING "Qt version")
# The Qt clients are unused in the wasm build, so force them off when OM_OMC_WASM is set.
cmake_dependent_option(OM_ENABLE_OMSHELL    "Enable OMShell gui client"    ON "NOT OM_OMC_WASM;OM_ENABLE_GUI_CLIENTS" OFF)
cmake_dependent_option(OM_ENABLE_OMNOTEBOOK "Enable OMNotebook gui client" ON "NOT OM_OMC_WASM;OM_ENABLE_GUI_CLIENTS" OFF)
cmake_dependent_option(OM_ENABLE_OMEDIT     "Enable OMEdit gui client"     ON "NOT OM_OMC_WASM;OM_ENABLE_GUI_CLIENTS" OFF)
cmake_dependent_option(OM_ENABLE_OMSENS_QT  "Enable OMSens_Qt gui client"  ON "NOT OM_OMC_WASM;OM_ENABLE_GUI_CLIENTS" OFF)
cmake_dependent_option(OM_OMOPTIM_ENABLE "Enable and build the (legacy) OMOptim optimization GUI." OFF "NOT OM_OMC_WASM" OFF)
omc_add_to_report(OM_ENABLE_OMSHELL)
omc_add_to_report(OM_ENABLE_OMNOTEBOOK)
omc_add_to_report(OM_ENABLE_OMEDIT)
omc_add_to_report(OM_ENABLE_OMSENS_QT)
omc_add_to_report(OM_OMOPTIM_ENABLE)
# libomc_result is built with cargo, which a C-only toolchain does not have (the
# OMDev Windows build is one), so both options default to whether cargo is on
# PATH rather than to plain ON. Without it the build falls back to the C readers
# and writers, which cannot handle .arrow. Turning either option on explicitly
# without a cargo is still a hard error, see rust_result_reader.cmake.
find_program(CARGO_EXECUTABLE cargo)
if(CARGO_EXECUTABLE)
  set(OM_RUST_RESULT_DEFAULT ON)
else()
  set(OM_RUST_RESULT_DEFAULT OFF)
  message(STATUS "cargo not found: defaulting OM_RUST_RESULT_READERS/OM_RUST_RESULT_WRITERS to OFF. "
                 "The C result readers and writers can not read or write .arrow result files; "
                 "install a stable Rust toolchain to get them.")
endif()
# The GUI clients read result files through libomc_result (needs cargo); OFF
# compiles the C readers (OM_LEGACY_RESULT_READERS), which cannot open .arrow.
cmake_dependent_option(OM_RUST_RESULT_READERS "Read result files in the GUI clients through the Rust omc_result library." ${OM_RUST_RESULT_DEFAULT} "NOT OM_OMC_WASM;OM_ENABLE_GUI_CLIENTS" OFF)
omc_add_to_report(OM_RUST_RESULT_READERS)
# The C simulation runtime writes its result files through the same library;
# OFF keeps the C writers, which cannot write .arrow.
cmake_dependent_option(OM_RUST_RESULT_WRITERS "Write result files from the C simulation runtime through the Rust omc_result library." ${OM_RUST_RESULT_DEFAULT} "NOT OM_OMC_WASM" OFF)
omc_add_to_report(OM_RUST_RESULT_WRITERS)

## Use ccache to speedup compilation! It is important to use ccache if you can.
## You get almost no op compilations (for unmodified files) at the cost of some memory.
## This is usefull, for example, in cases where you change branches often or need to clean
## for some reason. However, it is even more important with OMC because we generate C sources
## from MetaModelica files whenever they change. This causes CMake to issue compilations of
## dependent source files because headers are changed. ccache will essentially eliminate that cost.
omc_option(OM_USE_CCACHE "Use ccache to speedup compilations." ON)


### Standards ###############################################################################################
## Set the C standard to use. Unfortunately, we can not enforce C17.
## Our sources contain a lot of gnu extension code / C23 features.
# set(CMAKE_C_STANDARD 17)

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
# Force CMAKE_INSTALL_LIBDIR to "lib" instead of letting GNUInstallDirs default to "lib64" on
# RHEL-based distros (Fedora, AlmaLinux, ...). The compiler hardcodes "<omhome>/lib/..." when
# generating linker flags for simulated models (see Settings.getInstallationDirectoryPath() usage
# in OMCompiler/Compiler/Script/CevalScriptBackend.mo), so the install layout must match.
set(CMAKE_INSTALL_LIBDIR "lib")
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
  cmake_path(APPEND CMAKE_INSTALL_LIBDIR "${OM_LIBRARY_ARCH}" "omc")
else()
  set(CMAKE_INSTALL_LIBDIR "${CMAKE_INSTALL_LIBDIR}/${OM_LIBRARY_ARCH}/omc/")
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
  # The last two are for the app bundle mac-app-bundle.sh builds; they resolve
  # nothing in a plain unix prefix.
  set(CMAKE_INSTALL_RPATH "@loader_path/../${CMAKE_INSTALL_LIBDIR};@loader_path/../../../../${CMAKE_INSTALL_LIBDIR};@loader_path/../Frameworks;@loader_path/../Resources/${CMAKE_INSTALL_LIBDIR}")
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

## BLAS/LAPACK detection ###################################################################################
## Detect BLAS and LAPACK once, here at the top level, before descending into the subprojects.
##
## When no BLA_VENDOR is pinned, CMake's stock FindBLAS/FindLAPACK modules sweep *every* known vendor
## (Intel MKL, ACML, ARMPL, Apple, OpenBLAS, BLIS, ATLAS, Goto, Generic, ...), issuing hundreds of
## find_library() calls. On a machine without a vendor BLAS this all-vendor sweep dominates the configure
## (see issue #15904: ~200s of a ~285s configure). There are 18+ find_package(BLAS|LAPACK) call sites across
## the tree (SimulationRuntime/c, Compiler/runtime, sundials, primme, CMinpack, Ipopt/MUMPS, OMSI, OMSICpp,
## ...), and each one can re-trigger the full sweep, compounding the cost.
##
## FindBLAS/FindLAPACK clear the *normal* variables BLAS_LIBRARIES/LAPACK_LIBRARIES at entry, then guard
## their all-vendor sweep with `if(NOT BLAS_LIBRARIES)` / `if(NOT LAPACK_LIBRARIES)`. A plain normal variable
## inherited by a child scope is therefore wiped before the guard runs, so propagation alone does NOT prevent
## a re-sweep. A *cache* entry of the same name, however, shows through `set(<var>)` (which only unsets the
## normal variable) and trips the guard -- skipping the sweep entirely.
##
## So: detect once here, and (when found) publish the results as cache entries. Every subsequent
## find_package(BLAS|LAPACK) anywhere in the tree -- including inside the OMCompiler/3rdParty and OMSimulator
## submodules, which we cannot edit from this repository -- then short-circuits to the cached libraries. The
## expensive vendor sweep runs at most once per configure instead of once per call site. Autodetection is
## preserved (we don't pin BLA_VENDOR); if nothing is found here, the cache stays empty and a REQUIRED child
## call still re-runs and errors exactly as before.
## Detect and cache BLAS first: find_package(LAPACK) internally re-runs find_package(BLAS), so publishing
## the BLAS cache up front lets LAPACK's own BLAS lookup short-circuit too -- otherwise the vendor sweep
## would still run twice here.
find_package(BLAS)
if(BLAS_FOUND AND BLAS_LIBRARIES)
  set(BLAS_LIBRARIES "${BLAS_LIBRARIES}" CACHE STRING "BLAS libraries (detected once at the top level)" FORCE)
  set(BLAS_LINKER_FLAGS "${BLAS_LINKER_FLAGS}" CACHE STRING "BLAS linker flags (detected once at the top level)" FORCE)
  mark_as_advanced(BLAS_LIBRARIES BLAS_LINKER_FLAGS)
endif()
find_package(LAPACK)
if(LAPACK_FOUND AND LAPACK_LIBRARIES)
  set(LAPACK_LIBRARIES "${LAPACK_LIBRARIES}" CACHE STRING "LAPACK libraries (detected once at the top level)" FORCE)
  set(LAPACK_LINKER_FLAGS "${LAPACK_LINKER_FLAGS}" CACHE STRING "LAPACK linker flags (detected once at the top level)" FORCE)
  mark_as_advanced(LAPACK_LIBRARIES LAPACK_LINKER_FLAGS)
endif()

## Subdirectories ##########################################################################################
# If asked for encryption support, add and configure the OMEncryption directory.
if(OM_ENABLE_ENCRYPTION)
  # OMEncryption builds OpenSSL, which is configured by a perl script that, for its MinGW
  # targets, only accepts a perl reporting paths with forward slashes. In an MSYS2 shell the
  # first perl in PATH is the MinGW one, which reports MSWin32 style paths and stops that
  # configure step with "This perl implementation doesn't produce Unix like paths"; the MSYS
  # perl, which sits in the same directory as cygpath, is the one that works. Point OMEncryption
  # at it so the encryption build does not depend on the order of PATH. If it is not there we
  # leave SEMLA_PERL unset and OMEncryption looks for a perl of its own. A perl given on the
  # command line wins, and it has to be a path CMake can run, so -DSEMLA_PERL=C:/msys64/usr/bin/perl.exe
  # rather than -DSEMLA_PERL=/usr/bin/perl.exe (an MSYS shell rewrites the latter for you).
  if(WIN32 AND NOT MSVC AND NOT SEMLA_PERL)
    find_program(OM_MSYS_CYGPATH NAMES cygpath)
    mark_as_advanced(OM_MSYS_CYGPATH)
    if(OM_MSYS_CYGPATH)
      get_filename_component(om_msys_bin_dir "${OM_MSYS_CYGPATH}" DIRECTORY)
      find_program(SEMLA_PERL NAMES perl HINTS "${om_msys_bin_dir}" NO_DEFAULT_PATH
                   DOC "perl used to configure OpenSSL")
    endif()
  endif()

  omc_add_subdirectory(OMEncryption)
endif()

## Include and enable testing
set(CMAKE_CTEST_ARGUMENTS "--output-on-failure" "--output-junit" "junit.xml")
include(CTest)
enable_testing()

# libomc_result, after CMAKE_INSTALL_LIBDIR is final and before its users.
if(OM_RUST_RESULT_READERS OR OM_RUST_RESULT_WRITERS)
  include(OMCompiler/Compiler/.cmake/rust_result_reader.cmake)
  omc_result_reader_library()
endif()

omc_add_subdirectory(OMCompiler)

if(OM_ENABLE_OMSIMULATOR)
  # A cross toolchain re-roots DCPLib's find_path for asio into its sysroot.
  if(CMAKE_CROSSCOMPILING)
    set(ASIO_ROOT "${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator/3rdParty/asio"
        CACHE PATH "asio for OMSimulator/3rdParty/DCPLib")
  endif()
  omc_add_subdirectory(OMSimulator)
  # ezxml.c skips <unistd.h> on _WIN32 and calls read(); clang-cl rejects that.
  if(MSVC AND CMAKE_C_COMPILER_ID MATCHES "Clang")
    target_compile_options(fmi4c PRIVATE -Wno-implicit-function-declaration)
  endif()
endif()

# OMPlot provides OMPlotLib and the omqwt target, needed by OMEdit, OMNotebook
# and OMOptim, so build it whenever any of those clients is enabled.
if(OM_ENABLE_OMEDIT OR OM_ENABLE_OMNOTEBOOK OR OM_OMOPTIM_ENABLE)
  omc_add_subdirectory(OMPlot)
endif()

if(OM_ENABLE_OMEDIT)
  omc_add_subdirectory(OMParser)
  omc_add_subdirectory(OMEdit)
endif()

if(OM_ENABLE_OMSHELL)
  omc_add_subdirectory(OMShell)
endif()

if(OM_ENABLE_OMNOTEBOOK)
  omc_add_subdirectory(OMNotebook)
endif()

if(OM_ENABLE_OMSENS_QT)
  omc_add_subdirectory(OMSens_Qt)
endif()

if(OM_OMOPTIM_ENABLE)
  omc_add_subdirectory(OMOptim)
endif()

# The Modelica libraries and the testsuite are not part of the wasm/web bundle;
# skip them so `make all` builds only the wasm target in that mode.
if(NOT OM_OMC_WASM)
  omc_add_subdirectory(libraries)
  omc_add_subdirectory(testsuite)
endif()

omc_add_subdirectory(doc)

## Packaging ##########################################################################################
# Settings that hold for every package generator. These have to be set *before*
# include(CPack) below, which is what writes them into CPackConfig.cmake -- and which also
# derives CPACK_PACKAGE_FILE_NAME from the name and the version, so setting them later (in
# the project config file) would leave that name built from CPack's own 0.1.1 default.
# Generator-specific settings go in OpenModelicaCPackOptions.in.cmake instead: that one is
# read by cpack once per generator, with CPACK_GENERATOR set.
set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VENDOR "Open Source Modelica Consortium")
set(CPACK_PACKAGE_CONTACT "openmodelica@openmodelica.org")
set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/OSMC-License.txt")
set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
set(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_BINARY_DIR}/_packages")
set(CPACK_VERBATIM_VARIABLES ON)

# OM_PACKAGE_VERSION is empty when the source tree has no version to derive one from; see
# cmake/omc_git_revision.cmake. Leave CPack's defaults alone in that case rather than
# writing an unusable version into the config -- the DEB and RPM generators refuse to run
# on it, and the others (TGZ, the developer's `cpack` on a shallow clone) still work.
if(OM_PACKAGE_VERSION)
  set(CPACK_PACKAGE_VERSION ${OM_PACKAGE_VERSION})
  set(CPACK_PACKAGE_VERSION_MAJOR ${OM_PACKAGE_VERSION_MAJOR})
  set(CPACK_PACKAGE_VERSION_MINOR ${OM_PACKAGE_VERSION_MINOR})
  set(CPACK_PACKAGE_VERSION_PATCH ${OM_PACKAGE_VERSION_PATCH})
endif()

# Configure the file OpenModelicaCPackOptions.in.cmake to pick up full paths based on the current location.
# This will generate the output file in the build directory.
#
# @ONLY: cpack runs this file itself, long after this configure, with the CPACK_ variables
# from CPackConfig.cmake in scope. Only what cpack cannot know -- our version, our source
# directory -- is substituted here, as @VAR@; a ${VAR} is left for cpack to expand. Without
# @ONLY every ${CPACK_...} reference in there would be replaced by whatever it happened to
# hold at configure time, which is how CPACK_DEBIAN_PACKAGE_MAINTAINER used to end up as
# "OpenModelica Build System <>".
configure_file(cmake/packaging/OpenModelicaCPackOptions.in.cmake ${CMAKE_CURRENT_BINARY_DIR}/OpenModelicaCPackOptions.cmake @ONLY)
# Tell CPack to use this configured file when it is invoked to create packages.
set(CPACK_PROJECT_CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/OpenModelicaCPackOptions.cmake)
# Tell CPack about our components (dispaly names, descriptions, dependencies ...)
include(cmake/packaging/components.cmake)

## Report some status info.
message(STATUS "--------------------------------------------------------------------------")
message(STATUS "--------------------------------------------------------------------------")
feature_summary(WHAT ALL)
