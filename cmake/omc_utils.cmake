include(FeatureSummary)
include(CMakePrintHelpers)
include(CheckCCompilerFlag)
include(CMakeDependentOption)

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

# Keep the Qt translation sources (*.ts) of a GUI client up to date by running
# lupdate (qt_add_lupdate, Qt >= 6.2) as part of every build.
#
#   omc_add_qt_lupdate(<target>
#                      TS_FILES <file.ts>...   # absolute paths
#                      SOURCES  <file>...)     # absolute paths of everything lupdate scans
#
# <target> must already exist; it is made to depend on the custom target <target>_lupdate,
# so the .ts files are current before lrelease (qt_add_translation) reads them.
# Controlled by OM_UPDATE_TRANSLATIONS, the lupdate arguments by OM_LUPDATE_OPTIONS.
function(omc_add_qt_lupdate target)
  if(NOT OM_UPDATE_TRANSLATIONS)
    return()
  endif()
  cmake_parse_arguments(PARSE_ARGV 1 ARG "" "" "TS_FILES;SOURCES")
  find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
  # lupdate creates missing .ts files, but not their directory. Create both (an empty .ts with the
  # language taken from the file name, OMEdit_zh_CN.ts -> zh_CN), so adding a language to TS_FILES
  # is enough and lrelease (qt_add_translation) finds all its inputs.
  foreach(_ts IN LISTS ARG_TS_FILES)
    if(NOT EXISTS "${_ts}")
      get_filename_component(_ts_dir "${_ts}" DIRECTORY)
      get_filename_component(_ts_name "${_ts}" NAME_WE)
      string(REGEX REPLACE "^[^_]+_(.*)$" "\\1" _ts_language "${_ts_name}")
      file(MAKE_DIRECTORY "${_ts_dir}")
      file(WRITE "${_ts}" "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<!DOCTYPE TS>\n<TS version=\"2.1\" language=\"${_ts_language}\">\n</TS>\n")
      message(STATUS "Created the empty translation file ${_ts}")
    endif()
  endforeach()
  if(NOT COMMAND qt_add_lupdate)
    message(WARNING "qt_add_lupdate needs Qt 6.2 or newer (found ${Qt6_VERSION}). "
                    "The translations of ${target} are not updated automatically.")
    return()
  endif()
  # The signature of qt_add_lupdate changed in Qt 6.7: before, the first argument is the target
  # whose sources are scanned unless SOURCES is given, and the custom target is <target>_lupdate.
  # Since 6.7 there is no such argument any more (it would add the sources of the target to
  # SOURCES, including the generated ones) and the custom target is named ${PROJECT_NAME}_lupdate
  # unless LUPDATE_TARGET is given. Either way, only SOURCES is scanned.
  if(Qt6_VERSION VERSION_LESS 6.7)
    qt_add_lupdate(${target}
      TS_FILES ${ARG_TS_FILES}
      SOURCES ${ARG_SOURCES}
      OPTIONS ${OM_LUPDATE_OPTIONS})
  else()
    qt_add_lupdate(
      LUPDATE_TARGET ${target}_lupdate
      TS_FILES ${ARG_TS_FILES}
      SOURCES ${ARG_SOURCES}
      OPTIONS ${OM_LUPDATE_OPTIONS})
  endif()
  # Run lupdate before the target is built so lrelease sees the updated .ts files.
  add_dependencies(${target} ${target}_lupdate)
endfunction()

macro(omc_install_gui_client target)
  # On macOS we want BUNDLEs (.app) to go to an 'Applications/' directory instead of a 'bin/' directory
  if(APPLE AND OM_MACOS_APP_BUNDLE)
    set_target_properties(${target} PROPERTIES MACOSX_BUNDLE TRUE)
  endif ()
  set(OM_MACOS_INSTALL_BUNDLEDIR "Applications")
  install(TARGETS ${target} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
                            BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
endmacro()

# Resolve the MSYS2 installation prefix (the ucrt64 tree) into an absolute
# Windows path with forward slashes and store it in ${out_var}.
#
# MSYS2 exports MSYSTEM_PREFIX as a POSIX-style path (e.g. "/ucrt64"). When
# cmake is invoked directly from an MSYS2 shell, MSYS2 auto-translates that to
# an absolute Windows path (relative to its own install root) before the native
# cmake.exe process ever sees it, so it can be used as-is. Only if it is still
# POSIX-style (translation didn't happen) do we resolve it ourselves against
# OMDEV's msys tree.
function(omc_get_msys_prefix out_var)
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()

  if("$ENV{MSYSTEM_PREFIX}" MATCHES "^[A-Za-z]:")
    string(REPLACE "\\" "/" msys_prefix "$ENV{MSYSTEM_PREFIX}")
  else()
    if(NOT DEFINED ENV{OMDEV})
      message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
    endif()
    string(REPLACE "\\" "/" msys_prefix "$ENV{OMDEV}\\tools\\msys\\$ENV{MSYSTEM_PREFIX}")
  endif()

  set(${out_var} "${msys_prefix}" PARENT_SCOPE)
endfunction()
