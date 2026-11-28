# Build every cargo workspace from vendored crates, without network access.
#
# OM_CARGO_VENDOR_CONFIG is the source replacement that `cargo vendor` printed,
# with the crate directory relative to the file; a source tarball carries it as
# cargo-vendor.toml. It goes into a CARGO_HOME of the build tree, and
# CARGO_EXECUTABLE becomes a wrapper that sets that CARGO_HOME, so the cargo
# builds that build scripts start get it too.

set(_om_cargo_vendor_default "")
if(EXISTS "${CMAKE_SOURCE_DIR}/cargo-vendor.toml")
  set(_om_cargo_vendor_default "${CMAKE_SOURCE_DIR}/cargo-vendor.toml")
endif()
set(OM_CARGO_VENDOR_CONFIG "${_om_cargo_vendor_default}" CACHE FILEPATH
    "Output of cargo vendor (source replacement) to build the Rust code offline with.")

set(_om_cargo_home "${CMAKE_BINARY_DIR}/cargo-home")
if(NOT OM_CARGO_VENDOR_CONFIG)
  if(CARGO_EXECUTABLE MATCHES "^${_om_cargo_home}/")
    unset(CARGO_EXECUTABLE CACHE)
  endif()
  return()
endif()

file(READ "${OM_CARGO_VENDOR_CONFIG}" _om_cargo_vendor)
if(NOT _om_cargo_vendor MATCHES "directory = \"([^\"]*)\"")
  message(FATAL_ERROR "${OM_CARGO_VENDOR_CONFIG} names no directory of vendored crates")
endif()
set(_om_cargo_vendor_rel "${CMAKE_MATCH_1}")
get_filename_component(_om_cargo_vendor_base "${OM_CARGO_VENDOR_CONFIG}" DIRECTORY)
get_filename_component(_om_cargo_vendor_dir "${_om_cargo_vendor_rel}" ABSOLUTE BASE_DIR "${_om_cargo_vendor_base}")
if(NOT IS_DIRECTORY "${_om_cargo_vendor_dir}")
  message(FATAL_ERROR "${OM_CARGO_VENDOR_CONFIG}: ${_om_cargo_vendor_dir} does not exist")
endif()
string(REPLACE "directory = \"${_om_cargo_vendor_rel}\"" "directory = \"${_om_cargo_vendor_dir}\""
       _om_cargo_vendor "${_om_cargo_vendor}")

file(WRITE "${_om_cargo_home}/config.toml" "${_om_cargo_vendor}\n[net]\noffline = true\n")

find_program(OM_CARGO_REAL_EXECUTABLE cargo)
if(NOT OM_CARGO_REAL_EXECUTABLE)
  message(FATAL_ERROR "cargo not found")
endif()
if(CMAKE_HOST_WIN32)
  set(_om_cargo_wrapper "${_om_cargo_home}/cargo.cmd")
  file(WRITE "${_om_cargo_wrapper}"
       "@set \"CARGO_HOME=${_om_cargo_home}\"\r\n@\"${OM_CARGO_REAL_EXECUTABLE}\" %*\r\n")
else()
  set(_om_cargo_wrapper "${_om_cargo_home}/cargo")
  file(WRITE "${CMAKE_BINARY_DIR}/CMakeFiles/cargo"
       "#!/bin/sh\nCARGO_HOME='${_om_cargo_home}' exec '${OM_CARGO_REAL_EXECUTABLE}' \"$@\"\n")
  file(COPY "${CMAKE_BINARY_DIR}/CMakeFiles/cargo" DESTINATION "${_om_cargo_home}"
       FILE_PERMISSIONS OWNER_READ OWNER_WRITE OWNER_EXECUTE GROUP_READ GROUP_EXECUTE
                        WORLD_READ WORLD_EXECUTE)
endif()
set(CARGO_EXECUTABLE "${_om_cargo_wrapper}" CACHE FILEPATH "cargo" FORCE)
message(STATUS "cargo: vendored crates from ${_om_cargo_vendor_dir}, offline")
