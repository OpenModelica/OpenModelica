# Removes the coverage counter files of previous runs. Run in script mode:
#   cmake -DOM_COVERAGE_BINARY_DIR=<build dir> [-DOM_COVERAGE_FMU_DIR=<dir>]
#         -P OpenModelicaCoverageReset.cmake
#
# Only the .gcda files are removed; the .gcno files describing the code
# structure are written by the compiler and have to survive. The exception is
# OM_COVERAGE_FMU_DIR, which goes entirely: the notes in it were written by
# the FMU builds of earlier test runs, not by this build.

file(GLOB_RECURSE gcda_files "${OM_COVERAGE_BINARY_DIR}/*.gcda")
if(gcda_files)
  file(REMOVE ${gcda_files})
endif()
list(LENGTH gcda_files count)
message(STATUS "Removed ${count} coverage counter files")

if(OM_COVERAGE_FMU_DIR AND IS_DIRECTORY "${OM_COVERAGE_FMU_DIR}")
  file(REMOVE_RECURSE "${OM_COVERAGE_FMU_DIR}")
  message(STATUS "Removed the FMU coverage data in ${OM_COVERAGE_FMU_DIR}")
endif()
