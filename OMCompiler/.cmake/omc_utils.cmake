include(FeatureSummary)
include(CMakePrintHelpers)

macro(omc_add_to_report var)
  cmake_print_variables(${var})
  add_feature_info(${var} ${var} ${${var}})
endmacro(omc_add_to_report)

set(CMAKE_MESSAGE_CONTEXT_SHOW ON)
macro(omc_add_subdirectory var)
  list(APPEND CMAKE_MESSAGE_CONTEXT ${var})
  add_subdirectory(${var})
  list(POP_BACK CMAKE_MESSAGE_CONTEXT)
endmacro(omc_add_subdirectory)