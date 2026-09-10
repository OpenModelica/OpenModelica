# Provision the Windows (x86_64-pc-windows-msvc) third-party libs the C/C++
# runtime links, cross-built from Linux with the xwin toolchain: PThreads4W and
# OpenBLAS (LAPACK/BLAS). Included from the top-level CMakeLists before
# OMCPThreads.cmake (which find_package(pthreads CONFIG)); a no-op unless
# cross-compiling to Windows. Only the downloaded artifacts are cached
# (OM_DOWNLOADS_DIR); the build/install trees stay under the build dir.
# Boost is in cmake/OMCBoost.cmake instead, which covers every cross target.

if(NOT (CMAKE_CROSSCOMPILING AND CMAKE_SYSTEM_NAME STREQUAL "Windows"))
  return()
endif()

option(OM_WINDOWS_FETCH_DEPS
  "Cross-compiling to Windows: fetch and build PThreads4W/OpenBLAS during configure." ON)
if(NOT OM_WINDOWS_FETCH_DEPS)
  return()
endif()

# file(ARCHIVE_EXTRACT) needs 3.18, list(PREPEND) needs 3.15 — above the repo floor.
if(CMAKE_VERSION VERSION_LESS 3.18)
  message(FATAL_ERROR "Cross-compiling to Windows needs CMake >= 3.18 (windows-deps.cmake); have ${CMAKE_VERSION}.")
endif()

find_package(Git REQUIRED)

set(_om_win_build "${CMAKE_BINARY_DIR}/windows-deps")
set(_om_xwin_toolchain "${CMAKE_CURRENT_LIST_DIR}/xwin-toolchain.cmake")

# --- PThreads4W: jwinarske CMake fork, built + wrapped in a config package ---
# (its vcpkg port is nmake-only and cannot cross; the fork ships no CMake config,
# so build it and emit pthreadsConfig.cmake exporting PThreads4W::PThreads4W.)
set(OM_WINDOWS_PTHREADS4W_REF "904b10a2b5de3ac0a8b9dfe45bb36a2b157acd68" CACHE STRING
    "pthreads4w (jwinarske CMake fork) git commit to build.")
set(_om_p4w_src "${OM_DOWNLOADS_DIR}/pthreads4w")
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
set(_om_openblas_zip "${OM_DOWNLOADS_DIR}/OpenBLAS-${OM_WINDOWS_OPENBLAS_VERSION}-x64.zip")
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
