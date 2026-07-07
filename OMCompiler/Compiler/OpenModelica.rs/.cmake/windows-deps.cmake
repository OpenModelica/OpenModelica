# Provision the Windows (x86_64-pc-windows-msvc) third-party libs the C/C++
# runtime links, cross-built from Linux with the xwin toolchain: PThreads4W,
# OpenBLAS (LAPACK/BLAS), and Boost (cpp runtime, via vcpkg with the
# x64-windows-xwin overlay triplet). Included from the top-level CMakeLists
# before OMCPThreads.cmake (which find_package(pthreads CONFIG)); a no-op unless
# cross-compiling to Windows. Only the downloaded artifacts are cached
# (OM_WINDOWS_DOWNLOADS_DIR, bundle-able into a source tarball); the build/install
# trees stay under the build dir.

if(NOT (CMAKE_CROSSCOMPILING AND CMAKE_SYSTEM_NAME STREQUAL "Windows"))
  return()
endif()

option(OM_WINDOWS_FETCH_DEPS
  "Cross-compiling to Windows: fetch PThreads4W/OpenBLAS and build Boost via vcpkg during configure." ON)
if(NOT OM_WINDOWS_FETCH_DEPS)
  return()
endif()

# file(ARCHIVE_EXTRACT) needs 3.18, list(PREPEND) needs 3.15 — above the repo floor.
if(CMAKE_VERSION VERSION_LESS 3.18)
  message(FATAL_ERROR "Cross-compiling to Windows needs CMake >= 3.18 (windows-deps.cmake); have ${CMAKE_VERSION}.")
endif()

find_package(Git REQUIRED)

set(OM_WINDOWS_DOWNLOADS_DIR "${CMAKE_BINARY_DIR}/windows-deps/downloads" CACHE PATH
    "Cache for downloaded Windows dependency artifacts; bundle into the source tarball for offline builds.")
set(_om_win_build "${CMAKE_BINARY_DIR}/windows-deps")
set(_om_xwin_toolchain "${CMAKE_CURRENT_LIST_DIR}/xwin-toolchain.cmake")

# --- PThreads4W: jwinarske CMake fork, built + wrapped in a config package ---
# (its vcpkg port is nmake-only and cannot cross; the fork ships no CMake config,
# so build it and emit pthreadsConfig.cmake exporting PThreads4W::PThreads4W.)
set(OM_WINDOWS_PTHREADS4W_REF "904b10a2b5de3ac0a8b9dfe45bb36a2b157acd68" CACHE STRING
    "pthreads4w (jwinarske CMake fork) git commit to build.")
set(_om_p4w_src "${OM_WINDOWS_DOWNLOADS_DIR}/pthreads4w")
set(_om_p4w_prefix "${_om_win_build}/pthreads4w")
set(_om_p4w_cfgdir "${_om_win_build}/pthreads4w-cmake")
if(NOT EXISTS "${_om_p4w_cfgdir}/pthreadsConfig.cmake")
  if(NOT EXISTS "${_om_p4w_src}/.git")
    execute_process(
      COMMAND "${GIT_EXECUTABLE}" clone https://github.com/jwinarske/pthreads4w "${_om_p4w_src}"
      RESULT_VARIABLE _rc)
    if(_rc)
      message(FATAL_ERROR "pthreads4w clone failed (${_rc}).")
    endif()
  endif()
  execute_process(COMMAND "${GIT_EXECUTABLE}" -C "${_om_p4w_src}" checkout --quiet "${OM_WINDOWS_PTHREADS4W_REF}"
                  RESULT_VARIABLE _rc)
  if(_rc)
    message(FATAL_ERROR "pthreads4w checkout ${OM_WINDOWS_PTHREADS4W_REF} failed (${_rc}).")
  endif()
  # The fork forces its own install prefix unless DIST_ROOT is set; it lays
  # files out under <DIST_ROOT>/<arch>/<config>/{bin,lib,include}.
  execute_process(
    COMMAND ${CMAKE_COMMAND} -S "${_om_p4w_src}" -B "${_om_win_build}/pthreads4w-build"
            "-DCMAKE_TOOLCHAIN_FILE=${_om_xwin_toolchain}"
            -DCMAKE_BUILD_TYPE=Release "-DDIST_ROOT=${_om_p4w_prefix}"
    RESULT_VARIABLE _rc)
  if(_rc)
    message(FATAL_ERROR "pthreads4w configure failed (${_rc}).")
  endif()
  execute_process(COMMAND ${CMAKE_COMMAND} --build "${_om_win_build}/pthreads4w-build" --target install
                  RESULT_VARIABLE _rc)
  if(_rc)
    message(FATAL_ERROR "pthreads4w build/install failed (${_rc}).")
  endif()
  # The fork installs under <prefix>/<arch>/<config>/{bin,lib,include}; locate the
  # C-cleanup variant (pthreadVC<n>, not pthreadVCE/VSE) without hardcoding the subdir.
  file(GLOB_RECURSE _om_p4w_implib "${_om_p4w_prefix}/pthreadVC[0-9]*.lib")
  file(GLOB_RECURSE _om_p4w_hdr "${_om_p4w_prefix}/pthread.h")
  if(NOT _om_p4w_implib OR NOT _om_p4w_hdr)
    message(FATAL_ERROR "pthreads4w build produced no pthreadVC*.lib / pthread.h under ${_om_p4w_prefix}.")
  endif()
  list(GET _om_p4w_implib 0 _om_p4w_implib)
  list(GET _om_p4w_hdr 0 _om_p4w_hdr)
  get_filename_component(_om_p4w_name "${_om_p4w_implib}" NAME_WE)
  get_filename_component(_om_p4w_libdir "${_om_p4w_implib}" DIRECTORY)
  get_filename_component(_om_p4w_root "${_om_p4w_libdir}" DIRECTORY)
  get_filename_component(_om_p4w_inc "${_om_p4w_hdr}" DIRECTORY)
  file(WRITE "${_om_p4w_cfgdir}/pthreadsConfig.cmake"
"if(NOT TARGET PThreads4W::PThreads4W)
  add_library(PThreads4W::PThreads4W SHARED IMPORTED)
  set_target_properties(PThreads4W::PThreads4W PROPERTIES
    IMPORTED_IMPLIB \"${_om_p4w_implib}\"
    IMPORTED_LOCATION \"${_om_p4w_root}/bin/${_om_p4w_name}.dll\"
    INTERFACE_INCLUDE_DIRECTORIES \"${_om_p4w_inc}\")
endif()
")
endif()
set(pthreads_DIR "${_om_p4w_cfgdir}" CACHE PATH "" FORCE)

# --- OpenBLAS (lib/libopenblas.lib is a usable MSVC import lib) ---
set(OM_WINDOWS_OPENBLAS_VERSION "0.3.33" CACHE STRING "OpenBLAS prebuilt release to fetch.")
set(_om_openblas_sha256 "7ad797ef0c9a5c42e28903bf726eaaaade307dafe187ff0e923d90cd4002780c")
set(_om_openblas_zip "${OM_WINDOWS_DOWNLOADS_DIR}/OpenBLAS-${OM_WINDOWS_OPENBLAS_VERSION}-x64.zip")
set(_om_openblas_prefix "${_om_win_build}/openblas")
if(NOT EXISTS "${_om_openblas_prefix}/lib/libopenblas.lib")
  if(NOT EXISTS "${_om_openblas_zip}")
    message(STATUS "Fetching OpenBLAS ${OM_WINDOWS_OPENBLAS_VERSION} (Windows x64 prebuilt)")
    file(DOWNLOAD
      "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OM_WINDOWS_OPENBLAS_VERSION}/OpenBLAS-${OM_WINDOWS_OPENBLAS_VERSION}-x64.zip"
      "${_om_openblas_zip}"
      EXPECTED_HASH SHA256=${_om_openblas_sha256}
      SHOW_PROGRESS)
  endif()
  file(ARCHIVE_EXTRACT INPUT "${_om_openblas_zip}" DESTINATION "${_om_openblas_prefix}")
endif()
set(BLA_VENDOR OpenBLAS CACHE STRING "" FORCE)
list(PREPEND CMAKE_PREFIX_PATH "${_om_openblas_prefix}")

# --- Boost via vcpkg (only the cpp simulation runtime needs it) ---
if(OM_OMC_ENABLE_CPP_RUNTIME)
  set(OM_WINDOWS_VCPKG_REF "2026.06.01" CACHE STRING "vcpkg git ref to check out.")
  # Exactly the Boost libraries the cpp runtime includes (vcpkg pulls transitive
  # deps). Not the `boost` meta-port: it drags in python/mpi/locale ports that
  # need vcpkg-msbuild and cannot cross from Linux.
  set(OM_WINDOWS_VCPKG_PACKAGES
      "boost-filesystem;boost-serialization;boost-program-options;boost-system;boost-thread;boost-atomic;boost-chrono;boost-log;boost-asio;boost-ublas;boost-lambda;boost-circular-buffer;boost-intrusive;boost-lexical-cast;boost-foreach;boost-assign;boost-multi-array;boost-multi-index;boost-property-tree;boost-range;boost-optional;boost-math;boost-container;boost-algorithm;boost-tuple;boost-unordered;boost-variant;boost-bind;boost-function;boost-smart-ptr;boost-any;boost-typeof;boost-type-index;boost-numeric-conversion"
      CACHE STRING "vcpkg ports to install (x64-windows-xwin triplet).")
  set(_om_vcpkg "${_om_win_build}/vcpkg")
  if(NOT EXISTS "${_om_vcpkg}/vcpkg")
    if(NOT EXISTS "${_om_vcpkg}/.git")
      execute_process(
        COMMAND "${GIT_EXECUTABLE}" clone --depth 1 --branch "${OM_WINDOWS_VCPKG_REF}"
                https://github.com/microsoft/vcpkg "${_om_vcpkg}"
        RESULT_VARIABLE _rc)
      if(_rc)
        message(FATAL_ERROR "vcpkg clone failed (${_rc}).")
      endif()
    endif()
    execute_process(COMMAND "${_om_vcpkg}/bootstrap-vcpkg.sh" -disableMetrics
                    WORKING_DIRECTORY "${_om_vcpkg}" RESULT_VARIABLE _rc)
    if(_rc)
      message(FATAL_ERROR "vcpkg bootstrap failed (${_rc}).")
    endif()
  endif()

  set(_om_vcpkg_ports "")
  foreach(_p ${OM_WINDOWS_VCPKG_PACKAGES})
    list(APPEND _om_vcpkg_ports "${_p}:x64-windows-xwin")
  endforeach()
  # VCPKG_BINARY_SOURCES=clear: cache only the asset downloads, not built packages.
  execute_process(
    COMMAND ${CMAKE_COMMAND} -E env VCPKG_BINARY_SOURCES=clear
            "${_om_vcpkg}/vcpkg" install ${_om_vcpkg_ports}
            "--overlay-triplets=${CMAKE_CURRENT_LIST_DIR}"
            "--downloads-root=${OM_WINDOWS_DOWNLOADS_DIR}/vcpkg"
    WORKING_DIRECTORY "${_om_vcpkg}"
    RESULT_VARIABLE _rc)
  if(_rc)
    message(FATAL_ERROR "vcpkg install failed (${_rc}): ${_om_vcpkg_ports}")
  endif()
  list(PREPEND CMAKE_PREFIX_PATH "${_om_vcpkg}/installed/x64-windows-xwin")
endif()

# Bundle the fetched runtime DLLs next to omc.exe (Windows resolves DLLs from the
# executable's directory). Built during configure, so they exist on disk now.
if(EXISTS "${_om_openblas_prefix}/bin/libopenblas.dll")
  install(FILES "${_om_openblas_prefix}/bin/libopenblas.dll" TYPE BIN COMPONENT omc)
endif()
file(GLOB_RECURSE _om_p4w_dll "${_om_p4w_prefix}/pthreadVC3.dll")
if(_om_p4w_dll)
  list(GET _om_p4w_dll 0 _om_p4w_dll)
  install(FILES "${_om_p4w_dll}" TYPE BIN COMPONENT omc)
endif()
if(DEFINED _om_vcpkg AND EXISTS "${_om_vcpkg}/installed/x64-windows-xwin/bin")
  file(GLOB _om_boost_dlls "${_om_vcpkg}/installed/x64-windows-xwin/bin/boost_*.dll")
  if(_om_boost_dlls)
    install(FILES ${_om_boost_dlls} TYPE BIN COMPONENT omc)
  endif()
endif()
