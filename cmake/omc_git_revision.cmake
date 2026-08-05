
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

# Untagged revision, for build systems that append their own tag — the Rust omc
# reports "…-rust" (see rust_omc.cmake).
set(SOURCE_REVISION_BASE "${SOURCE_REVISION}")
set(SOURCE_REVISION "${SOURCE_REVISION}-cmake")

omc_add_to_report(SOURCE_REVISION)
