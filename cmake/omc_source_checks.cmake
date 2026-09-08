# cmake/omc_source_checks.cmake
#
# Source hygiene targets. These used to be targets of the top-level Makefile.in
# of the autotools build; they are CMake targets now that CMake is the only
# supported build system.
#
# Run with, e.g.:
#   cmake --build <build_dir> --target bom-error
#
# Available targets:
#   bom-error                  fail if a source file starts with a UTF-8 BOM
#   utf8-error                 fail if a source file is not valid UTF-8
#   thumbsdb-error             fail if a Windows Thumbs.db file is checked in
#   trailing-whitespace-error  fail on trailing whitespace in sources
#   tab-error                  fail on hard tabs in sources
#   fix-whitespace             rewrite sources: tabs -> 2 spaces, trim trailing
#   spellcheck                 aspell the gettext strings (omc_spellcheck.cmake)

find_program(BASH_EXECUTABLE bash)

if(BASH_EXECUTABLE)
  foreach(_check
      bom-error
      utf8-error
      thumbsdb-error
      trailing-whitespace-error
      tab-error
      fix-whitespace)
    add_custom_target(${_check}
      COMMAND ${BASH_EXECUTABLE} ${CMAKE_SOURCE_DIR}/cmake/source_checks.sh
              ${_check} ${CMAKE_SOURCE_DIR}
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
      COMMENT "Running source check '${_check}'"
      USES_TERMINAL
    )
  endforeach()
else()
  message(STATUS "bash not found. The source check targets are not available.")
endif()

include(${CMAKE_CURRENT_LIST_DIR}/omc_spellcheck.cmake)
