# Removes the coverage counter files of previous runs. Run in script mode:
#   cmake -DOM_COVERAGE_BINARY_DIR=<build dir> -P OpenModelicaCoverageReset.cmake
#
# Only the .gcda files are removed; the .gcno files describing the code
# structure are written by the compiler and have to survive.

file(GLOB_RECURSE gcda_files "${OM_COVERAGE_BINARY_DIR}/*.gcda")
if(gcda_files)
  file(REMOVE ${gcda_files})
endif()
list(LENGTH gcda_files count)
message(STATUS "Removed ${count} coverage counter files")
