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

# Run windeployqt on an already-installed GUI client so its Qt runtime (the Qt
# DLLs, the platform/imageformat/tls plugins, the translations and -- for a
# client that links Qt WebEngine -- QtWebEngineProcess.exe and the Chromium
# resource/locale trees) is copied next to the installed <target>.exe.
#
# Works both for the MSYS2/MinGW Qt (windeployqt found under the ucrt64 tree)
# and for a native MSVC build against an official Qt on CMAKE_PREFIX_PATH
# (windeployqt found next to qmake). It is a no-op when not building for Windows
# and when cross-compiling -- a Windows windeployqt.exe cannot run on the build
# host, so those builds bundle the Qt runtime by hand instead.
function(omc_windeployqt target)
  if(NOT WIN32 OR CMAKE_CROSSCOMPILING)
    return()
  endif()

  # Cache the lookup: every GUI client calls this, but windeployqt is the same
  # tool for all of them.
  if(NOT WINDEPLOYQT_EXECUTABLE)
    set(_hints "")
    # Qt >= 6.5 exports the tool as an imported target.
    if(TARGET Qt6::windeployqt)
      get_target_property(_wdq Qt6::windeployqt IMPORTED_LOCATION)
      if(_wdq)
        set(WINDEPLOYQT_EXECUTABLE "${_wdq}" CACHE FILEPATH "windeployqt")
      endif()
    endif()
    if(TARGET Qt6::qmake)
      get_target_property(_qmake Qt6::qmake IMPORTED_LOCATION)
      if(_qmake)
        get_filename_component(_qtbin "${_qmake}" DIRECTORY)
        list(APPEND _hints "${_qtbin}")
      endif()
    endif()
    if(MINGW)
      omc_get_msys_prefix(_msys_prefix)
      list(APPEND _hints "${_msys_prefix}/bin")
    endif()
    if(NOT WINDEPLOYQT_EXECUTABLE)
      find_program(WINDEPLOYQT_EXECUTABLE
        NAMES windeployqt6 windeployqt
        HINTS ${_hints}
        REQUIRED)
    endif()
  endif()

  install(CODE "
    message(STATUS \"Running windeployqt on ${target}...\")
    execute_process(
      COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
        --no-compiler-runtime
        --no-system-d3d-compiler
        --no-quick-import
        --libdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\"
        --translationdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/share/qt6/translations\"
        \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/${target}.exe\"
      RESULT_VARIABLE _wdq_rc
      OUTPUT_VARIABLE _wdq_out
      ERROR_VARIABLE  _wdq_err
    )
    if(NOT _wdq_rc EQUAL 0)
      message(FATAL_ERROR \"windeployqt failed for ${target}:\n\${_wdq_out}\n\${_wdq_err}\")
    endif()
    message(STATUS \"windeployqt (${target}): \${_wdq_out}\")
  ")
endfunction()
