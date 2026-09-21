# Put the OMSimulator chapter where the User's Guide expects it.
#
# OMSimulator's own conf.py has just generated its API includes inside our copy
# of its documentation. Sphinx resolves the paths in those includes relative to
# the document that pulls them in -- source/omsimulator.rst -- so they have to
# exist next to it as well, not only beside the files that declare them. The
# Makefile did this with symlinks; copies work the same and on every platform.
#
# Which includes exist depends on the OMSimulator version, so glob rather than
# name them.
#
# Usage: cmake -DOMSIMULATOR=<OMSimulator> -DSOURCE=<staged source dir>
#              -P stage_omsimulator.cmake

execute_process(
  COMMAND "${OMSIMULATOR}" --help
  OUTPUT_FILE "${SOURCE}/omsimulator-help.inc"
  RESULT_VARIABLE result
  ERROR_VARIABLE stderr)

if(NOT result EQUAL 0)
  file(REMOVE "${SOURCE}/omsimulator-help.inc")
  message(FATAL_ERROR "'${OMSIMULATOR} --help' failed (${result}): ${stderr}")
endif()

foreach(dir api images)
  if(IS_DIRECTORY "${SOURCE}/omsimulator/${dir}")
    file(COPY "${SOURCE}/omsimulator/${dir}" DESTINATION "${SOURCE}")
  endif()
endforeach()

file(GLOB includes "${SOURCE}/omsimulator/*.inc")
if(includes)
  file(COPY ${includes} DESTINATION "${SOURCE}")
endif()
