
set(SOURCE_REVISION "unknown")

if (EXISTS ${CMAKE_SOURCE_DIR}/OMVERSION.txt)
  file(READ ${CMAKE_SOURCE_DIR}/OMVERSION.txt SOURCE_REVISION)
  string(STRIP "${SOURCE_REVISION}" SOURCE_REVISION)
else ()
  ## Get the revision info. The version is saved in the variable SOURCE_REVISION
  find_package(Git)
  if(Git_FOUND)
    execute_process(COMMAND
      ${GIT_EXECUTABLE} describe --match "v*.*" --always
      WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
      OUTPUT_VARIABLE SOURCE_REVISION
      ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
    )
  endif()
endif ()

# No build-system tag is appended: CMake is the only way to build omc, so the
# "-cmake" suffix this used to carry said nothing. The Rust omc still tags itself
# "…-rust" on top of this (see rust_omc.cmake).

omc_add_to_report(SOURCE_REVISION)
