## Get the revision info. The version is saved in the variable SOURCE_REVISION
find_package(Git)

if(Git_FOUND)
  execute_process(COMMAND
    ${GIT_EXECUTABLE} describe --match "v*.*" --always
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    OUTPUT_VARIABLE SOURCE_REVISION
    ERROR_QUIET OUTPUT_STRIP_TRAILING_WHITESPACE
  )
  set(SOURCE_REVISION "${SOURCE_REVISION}-cmake")
else()
  set(SOURCE_REVISION "unknown-cmake")
endif()

omc_add_to_report(SOURCE_REVISION)
