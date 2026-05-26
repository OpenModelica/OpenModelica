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

macro(omc_install_gui_client target)
  # On macOS we want BUNDLEs (.app) to go to an 'Applications/' directory instead of a 'bin/' directory
  if(APPLE AND OM_MACOS_APP_BUNDLE)
    set_target_properties(${target} PROPERTIES MACOSX_BUNDLE TRUE)
  endif ()
  set(OM_MACOS_INSTALL_BUNDLEDIR "Applications")
  install(TARGETS ${target} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
                            BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
endmacro()
