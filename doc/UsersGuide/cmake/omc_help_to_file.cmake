# Write the output of `omc <flag>` to a file.
#
# A build rule cannot redirect stdout portably, and these two help texts are
# reST that the guide includes verbatim.
#
# Usage: cmake -DOMC=<omc> -DFLAG=<+help=...> -DOUTPUT=<file> -P omc_help_to_file.cmake

execute_process(
  COMMAND "${OMC}" "${FLAG}"
  OUTPUT_FILE "${OUTPUT}"
  RESULT_VARIABLE result
  ERROR_VARIABLE stderr)

if(NOT result EQUAL 0)
  file(REMOVE "${OUTPUT}")
  message(FATAL_ERROR "'${OMC} ${FLAG}' failed (${result}): ${stderr}")
endif()
