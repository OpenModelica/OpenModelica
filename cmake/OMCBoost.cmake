# Boost from source for SimulationRuntime/cpp, OMSICpp and ParModelica.
#
# A cross build has no Boost to find: the host's is the wrong architecture and
# neither the xwin sysroot nor the macOS SDK ships one. add_subdirectory'ing the
# modular-CMake release builds under any configured toolchain (clang-cl, `zig
# cc`, the host compiler), unlike the vcpkg route it replaced, which could only
# produce Windows binaries.

# RUST_OMC_PREBUILT_CDYLIB is the GUI-only build; SimulationRuntime/CMakeLists.txt
# skips all three trees under it.
if(RUST_OMC_PREBUILT_CDYLIB OR NOT (OM_OMC_ENABLE_CPP_RUNTIME OR OM_OMC_ENABLE_PARMODELICA))
  return()
endif()

if(CMAKE_CROSSCOMPILING)
  set(_om_boost_fetch_default ON)
else()
  set(_om_boost_fetch_default OFF)
endif()
omc_option(OM_FETCH_BOOST
  "Download and build Boost instead of using an installed one (default: only when cross-compiling)."
  ${_om_boost_fetch_default})
if(NOT OM_FETCH_BOOST)
  return()
endif()

# file(ARCHIVE_EXTRACT) needs 3.18, above the repo floor of 3.14.
if(CMAKE_VERSION VERSION_LESS 3.18)
  message(FATAL_ERROR "OM_FETCH_BOOST needs CMake >= 3.18; have ${CMAKE_VERSION}.")
endif()

set(OM_BOOST_VERSION "1.92.0" CACHE STRING "Boost release to fetch.")
set(OM_BOOST_SHA256 "9bed76128d4e46755dbe818487788c6fceb6f72b378f4daa49b7e1e600d9088d"
    CACHE STRING "SHA256 of boost-<OM_BOOST_VERSION>-cmake.tar.xz. Override alongside OM_BOOST_VERSION.")

set(_om_boost_tarball "${OM_DOWNLOADS_DIR}/boost-${OM_BOOST_VERSION}-cmake.tar.xz")
set(_om_boost_src "${CMAKE_BINARY_DIR}/boost-deps/boost-${OM_BOOST_VERSION}")

if(NOT EXISTS "${_om_boost_src}/CMakeLists.txt")
  if(NOT EXISTS "${_om_boost_tarball}")
    message(STATUS "Fetching Boost ${OM_BOOST_VERSION} (modular CMake release, ~108 MB)")
    file(DOWNLOAD
      "https://github.com/boostorg/boost/releases/download/boost-${OM_BOOST_VERSION}/boost-${OM_BOOST_VERSION}-cmake.tar.xz"
      "${_om_boost_tarball}"
      EXPECTED_HASH SHA256=${OM_BOOST_SHA256}
      SHOW_PROGRESS)
  endif()
  file(ARCHIVE_EXTRACT INPUT "${_om_boost_tarball}" DESTINATION "${CMAKE_BINARY_DIR}/boost-deps")
  if(NOT EXISTS "${_om_boost_src}/CMakeLists.txt")
    message(FATAL_ERROR "Boost ${OM_BOOST_VERSION} did not unpack to ${_om_boost_src}.")
  endif()
  # 440 MB of the 690 MB unpacked. Nothing reaches it: the superproject globs
  # only libs/*/CMakeLists.txt, and BoostRoot.cmake forces BUILD_TESTING off for
  # an add_subdirectory build.
  file(GLOB _om_boost_junk LIST_DIRECTORIES true
       "${_om_boost_src}/doc"
       "${_om_boost_src}/libs/*/doc" "${_om_boost_src}/libs/*/test"
       "${_om_boost_src}/libs/*/example" "${_om_boost_src}/libs/*/examples"
       "${_om_boost_src}/libs/numeric/*/doc" "${_om_boost_src}/libs/numeric/*/test"
       "${_om_boost_src}/libs/numeric/*/example" "${_om_boost_src}/libs/numeric/*/examples")
  if(_om_boost_junk)
    file(REMOVE_RECURSE ${_om_boost_junk})
  endif()
endif()

# The modules included directly, as libs/ directory names; BoostRoot.cmake adds
# their dependencies. Mostly the boost/ headers under SimulationRuntime/cpp; the
# compiled ones are what the three find_package calls ask for.
set(BOOST_INCLUDE_LIBRARIES
    algorithm array asio assert assign atomic bind chrono circular_buffer
    concept_check config container core filesystem foreach function graph
    iterator lambda lexical_cast math mpl multi_array numeric/ublas preprocessor
    program_options property_tree range serialization smart_ptr static_assert
    thread tuple type_traits unordered)
set(_om_boost_components filesystem program_options serialization graph chrono)
# Boost::boost exists only with these.
set(BOOST_ENABLE_COMPATIBILITY_TARGETS ON)

# Static + PIC: the OMCpp* shared libraries absorb Boost, so the install tree
# carries no boost_*.dll / .dylib and needs no rpath for one.
set(_om_boost_saved_shared ${BUILD_SHARED_LIBS})
set(_om_boost_saved_pic ${CMAKE_POSITION_INDEPENDENT_CODE})
set(BUILD_SHARED_LIBS OFF)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

add_subdirectory("${_om_boost_src}" "${CMAKE_BINARY_DIR}/boost-deps/build")

set(BUILD_SHARED_LIBS ${_om_boost_saved_shared})
set(CMAKE_POSITION_INDEPENDENT_CODE ${_om_boost_saved_pic})

# Boost::headers looks for a target named after the libs/ directory, so it misses
# libs/numeric/: uBLAS declares Boost::numeric_ublas. Its dependencies follow.
target_link_libraries(boost_headers INTERFACE Boost::numeric_ublas)

# OMSICpp and ParModelica read the FindBoost variables rather than the targets.
# A modular Boost has no single include directory, and include_directories()
# takes a list.
file(GLOB Boost_INCLUDE_DIR "${_om_boost_src}/libs/*/include"
                            "${_om_boost_src}/libs/numeric/*/include")
set(Boost_LIBRARIES "")
foreach(_c IN LISTS _om_boost_components)
  set(Boost_${_c}_FOUND TRUE)
  list(APPEND Boost_LIBRARIES Boost::${_c})
endforeach()
