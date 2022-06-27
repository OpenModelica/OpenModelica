include(FeatureSummary)
include(CMakePrintHelpers)
include(CheckCCompilerFlag)

macro(omc_add_to_report var)
  cmake_print_variables(${var})
  # quote to change variables with empty values to "" (empty string).
  # Otherwise they will valuate to nothing and that will cause a
  # syntax error since add_feature_info expects 3 arguments.
  add_feature_info(${var} ${var} "${${var}}")
endmacro(omc_add_to_report)

set(CMAKE_MESSAGE_CONTEXT_SHOW ON)
macro(omc_add_subdirectory var)
  list(APPEND CMAKE_MESSAGE_CONTEXT ${var})
  add_subdirectory(${ARGV0} ${ARGV1} ${ARGV2})
  list(POP_BACK CMAKE_MESSAGE_CONTEXT)
endmacro(omc_add_subdirectory)

macro(omc_option var help_text value)
  option(${var} ${help_text} ${value})
  omc_add_to_report(${var})
endmacro(omc_option)
