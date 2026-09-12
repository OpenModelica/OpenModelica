

if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omedit.icns)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/../OMEditLIB/Resources/icons/omedit.icns")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMEdit WIN32 main.cpp rc_omedit.rc ${app_icon_macos})
target_link_libraries(OMEdit PRIVATE OMEditLib)

if(MSVC)
  # rc_omedit.rc already embeds OMEdit.manifest; /MANIFEST:NO stops CMake adding
  # a second one (avoids the duplicate-resource error and lld-link's mt.exe call).
  target_link_options(OMEdit PRIVATE /MANIFEST:NO)
endif()

if(APPLE)
  set_target_properties(OMEdit PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
endif()

if(OM_OMEDIT_INSTALL_RUNTIME_DLLS AND MINGW)

  if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "No 32-bit version of UCRT available!")
  endif()

  omc_get_msys_prefix(MSYSTEM_PREFIX_ESCAPED)

  # TODO: This is stupid, but I can't get install with RUNTIME_DEPENDENCIES to run.
  # It needs to link to libs that are installed to ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR},
  # but if I add that to DIRECTORIES it will throw errors on the second run.
  set(OMPLOT_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMPlot/OMPlot/OMPlotGUI ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMPlot/qwt/src)
  set(OMSIMULATOR_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMSimulator/src/OMSimulatorLib)
  set(OMCOMPILER_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/Compiler/bin)
  set(SIMULATION_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/SimulationRuntime/c)
  set(GC_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/3rdParty/gc)
  # OMC_RESULT_LIB_DIR is empty unless the Rust result readers/writers are on.
  set(RUNTIME_LIB_DIRS ${OMPLOT_LIB_DIR} ${OMSIMULATOR_LIB_DIR} ${OMCOMPILER_LIB_DIR} ${SIMULATION_RUNTIME_LIB_DIR} ${GC_RUNTIME_LIB_DIR} ${OMC_RESULT_LIB_DIR})
  message(STATUS "install will search for OMEdit runtime dependencies in ${RUNTIME_LIB_DIRS}")

  # TODO: OMPlot should add this? Or OMEdit needs to link to it directly?
  install(FILES
          ${MSYSTEM_PREFIX_ESCAPED}/bin/Qt6OpenGL.dll
          TYPE BIN)

  message(STATUS "Looking for runtime dependencies of OMEdit in ${MSYSTEM_PREFIX_ESCAPED}/bin ${RUNTIME_LIB_DIRS}")

  if(NOT ${CMAKE_VERSION} VERSION_LESS "4.3")
    cmake_policy(SET CMP0207 NEW)
  endif()
  install(TARGETS OMEdit
          RUNTIME_DEPENDENCIES
            DIRECTORIES ${MSYSTEM_PREFIX_ESCAPED}/bin ${RUNTIME_LIB_DIRS}
            PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-"
            POST_EXCLUDE_REGEXES ".*system32/.*\\.dll")

  # Find windeployqt6
  find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt windeployqt6
    HINTS "${MSYSTEM_PREFIX_ESCAPED}/bin"
    REQUIRED
  )

  install(CODE "
    message(STATUS \"Running windeployqt6 on OMEdit...\")
    execute_process(
      COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
        --no-compiler-runtime
        --no-system-d3d-compiler
        --no-quick-import
        --libdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\"
        --translationdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/share/qt6/translations\"
        \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMEdit.exe\"
      RESULT_VARIABLE WINDEPLOYQT_RESULT
      OUTPUT_VARIABLE WINDEPLOYQT_OUTPUT
      ERROR_VARIABLE  WINDEPLOYQT_ERROR
    )
    if(NOT WINDEPLOYQT_RESULT EQUAL 0)
      message(FATAL_ERROR \"windeployqt6 failed:\n\${WINDEPLOYQT_OUTPUT}\n\${WINDEPLOYQT_ERROR}\")
    endif()
    message(STATUS \"windeployqt6 output: \${WINDEPLOYQT_OUTPUT}\")
  ")
elseif(OM_OMEDIT_INSTALL_RUNTIME_DLLS AND MSVC AND CMAKE_CROSSCOMPILING)
  # Cross (clang-cl) deploy: windeployqt can't run here (it's a Windows binary and
  # the msvc Qt kit ships no ICU, so Qt6Core won't load even under wine), so walk
  # the DLL import closure ourselves and copy the runtime-loaded Qt assets
  # (plugins/QML/WebEngine, not in the import table) by hand.
  get_filename_component(_qt_root "${Qt6_DIR}/../../.." ABSOLUTE)
  set(_om_qt_dep_dirs "${_qt_root}/bin")
  if(DEFINED Qt6WebEngineCore_DIR)
    get_filename_component(_qtx_root "${Qt6WebEngineCore_DIR}/../../.." ABSOLUTE)
    list(APPEND _om_qt_dep_dirs "${_qtx_root}/bin")
  endif()

  omc_install_gui_client(OMEdit)

  # QtWebEngineProcess.exe is launched at runtime, so it is not in OMEdit.exe's
  # import table and needs its own DLLs resolved.
  set(_om_deploy_roots "\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMEdit.exe")
  foreach(_dir IN LISTS _om_qt_dep_dirs)
    if(EXISTS "${_dir}/QtWebEngineProcess.exe")
      install(PROGRAMS "${_dir}/QtWebEngineProcess.exe"
              DESTINATION "${CMAKE_INSTALL_BINDIR}")
      list(APPEND _om_deploy_roots "${_dir}/QtWebEngineProcess.exe")
      break()
    endif()
  endforeach()

  # install(TARGETS RUNTIME_DEPENDENCIES) is rejected when cross-compiling, and
  # file(GET_RUNTIME_DEPENDENCIES) does not resolve PE deps on a Linux host, so
  # walk the import closure ourselves with llvm-objdump.
  install(CODE "
    set(OMDEPLOY_EXE \"${_om_deploy_roots}\")
    set(OMDEPLOY_DEST \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\")
    set(OMDEPLOY_OBJDUMP \"${CMAKE_OBJDUMP}\")
    set(OMDEPLOY_DIRS \"${_om_qt_dep_dirs}\")
  ")
  install(SCRIPT "${CMAKE_SOURCE_DIR}/OMCompiler/Compiler/OpenModelica.rs/.cmake/windows-qt-deploy.cmake")

  foreach(_pp platforms/qwindows.dll styles/qmodernwindowsstyle.dll
              imageformats/qjpeg.dll imageformats/qsvg.dll
              imageformats/qico.dll imageformats/qgif.dll
              iconengines/qsvgicon.dll tls/qschannelbackend.dll
              networkinformation/qnetworklistmanager.dll)
    get_filename_component(_pp_dir "${_pp}" DIRECTORY)
    if(EXISTS "${_qt_root}/plugins/${_pp}")
      install(FILES "${_qt_root}/plugins/${_pp}"
              DESTINATION "${CMAKE_INSTALL_BINDIR}/${_pp_dir}")
    endif()
  endforeach()

  # QML modules, from qmlimportscanner over wasm/qml/AnimImports.qml (the
  # animation scene is built from C++ and has no scannable imports of its own).
  # Installed per module and non-recursively -- the scan names every nested module
  # it needs, and the rest is three quarters of the 37 MB qml/ tree.
  find_program(OM_QMLIMPORTSCANNER_EXECUTABLE qmlimportscanner
               HINTS "${QT_HOST_PATH}/libexec" "${QT_HOST_PATH}/bin"
                     "$ENV{QT_HOST_PATH}/libexec" "$ENV{QT_HOST_PATH}/bin"
                     "${_qt_root}/libexec" "${_qt_root}/bin")
  if(EXISTS "${_qt_root}/qml" AND OM_QMLIMPORTSCANNER_EXECUTABLE)
    execute_process(
      COMMAND "${OM_QMLIMPORTSCANNER_EXECUTABLE}"
              -rootPath "${CMAKE_CURRENT_SOURCE_DIR}/wasm/qml"
              -importPath "${_qt_root}/qml"
      OUTPUT_VARIABLE _om_qml_scan OUTPUT_STRIP_TRAILING_WHITESPACE
      ERROR_VARIABLE _om_qml_scan_err RESULT_VARIABLE _om_qml_scan_rc)
    if(NOT _om_qml_scan_rc EQUAL 0)
      message(FATAL_ERROR "qmlimportscanner failed:\n${_om_qml_scan_err}")
    endif()
    set(_om_qml_modules "")
    string(JSON _om_qml_count LENGTH "${_om_qml_scan}")
    if(_om_qml_count GREATER 0)
      math(EXPR _om_qml_last "${_om_qml_count} - 1")
      foreach(_i RANGE ${_om_qml_last})
        string(JSON _rp ERROR_VARIABLE _e GET "${_om_qml_scan}" ${_i} relativePath)
        if(_e STREQUAL "NOTFOUND")
          list(APPEND _om_qml_modules "${_rp}")
        endif()
      endforeach()
    endif()
    list(REMOVE_DUPLICATES _om_qml_modules)
    foreach(_m IN LISTS _om_qml_modules)
      file(GLOB _om_qml_files LIST_DIRECTORIES false "${_qt_root}/qml/${_m}/*")
      set(_om_qml_keep "")
      foreach(_f IN LISTS _om_qml_files)
        # Qt ships each plugin's debug build beside the release one.
        string(REGEX REPLACE "d\\.dll$" ".dll" _release_name "${_f}")
        if(NOT _release_name STREQUAL _f AND EXISTS "${_release_name}")
          continue()
        endif()
        list(APPEND _om_qml_keep "${_f}")
      endforeach()
      if(_om_qml_keep)
        install(FILES ${_om_qml_keep}
                DESTINATION "${CMAKE_INSTALL_BINDIR}/qml/${_m}")
      endif()
    endforeach()
  elseif(EXISTS "${_qt_root}/qml")
    message(WARNING "No qmlimportscanner (set QT_HOST_PATH): shipping the whole qml/ tree.")
    install(DIRECTORY "${_qt_root}/qml/" DESTINATION "${CMAKE_INSTALL_BINDIR}/qml")
  endif()

  # Chromium's runtime assets, under bin/ where OMEditApplication points
  # QTWEBENGINE_RESOURCES_PATH and QTWEBENGINE_LOCALES_PATH. Minus the 11 MB
  # DevTools pak, and only the locales OMEdit itself is translated to (830 kB each).
  if(DEFINED _qtx_root)
    if(EXISTS "${_qtx_root}/resources")
      install(DIRECTORY "${_qtx_root}/resources/"
              DESTINATION "${CMAKE_INSTALL_BINDIR}/resources"
              REGEX "\\.debug\\." EXCLUDE
              PATTERN "qtwebengine_devtools_resources.pak" EXCLUDE)
    endif()
    set(_om_webengine_locales en-US)
    file(GLOB _om_nls "${CMAKE_CURRENT_SOURCE_DIR}/../OMEditLIB/Resources/nls/OMEdit_*.qm")
    foreach(_qm IN LISTS _om_nls)
      get_filename_component(_qm "${_qm}" NAME_WE)
      string(REPLACE "OMEdit_" "" _qm "${_qm}")
      string(REPLACE "_" "-" _qm "${_qm}")
      list(APPEND _om_webengine_locales "${_qm}")
    endforeach()
    foreach(_loc IN LISTS _om_webengine_locales)
      set(_pak "${_qtx_root}/translations/qtwebengine_locales/${_loc}.pak")
      if(EXISTS "${_pak}")
        install(FILES "${_pak}"
                DESTINATION "${CMAKE_INSTALL_BINDIR}/translations/qtwebengine_locales")
      endif()
    endforeach()
  endif()

  install(CODE "file(WRITE \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/qt.conf\" \"[Paths]\\nPrefix = .\\nPlugins = .\\nQml = qml\\n\")")
else ()
  omc_install_gui_client(OMEdit)
endif()

# Put the Modelica language server beside the built OMEdit as well as in the
# install tree. findBundledServer() looks next to the executable first, and a
# build-tree OMEdit has no share directory of its own -- Helper::OpenModelicaHome
# comes from omc, which points into the build tree -- so without this the server
# is only found after `cmake --install`, and anyone testing from the build tree
# sees the feature do nothing at all.
#
# MODELICA_LS_STAGE_* are set by OMEditLIB, which is added before this directory.
if(MODELICA_LS_STAGE_FILES OR MODELICA_LS_STAGE_EXE)
  set(_ls_build_dir $<TARGET_FILE_DIR:OMEdit>/ls/modelica)
  add_custom_command(TARGET OMEdit POST_BUILD
                     COMMAND ${CMAKE_COMMAND} -E make_directory ${_ls_build_dir}
                     COMMENT "Staging the Modelica language server beside OMEdit")
  foreach(_ls_file ${MODELICA_LS_STAGE_FILES})
    add_custom_command(TARGET OMEdit POST_BUILD
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different
                               "${_ls_file}" ${_ls_build_dir})
  endforeach()
  if(MODELICA_LS_STAGE_EXE)
    # copy_if_different skips the ~120 MB copy on every relink once it is there.
    add_custom_command(TARGET OMEdit POST_BUILD
                       COMMAND ${CMAKE_COMMAND} -E copy_if_different
                               "${MODELICA_LS_STAGE_EXE}"
                               ${_ls_build_dir}/${MODELICA_LS_STAGE_EXE_NAME})
    if(UNIX)
      # The copy inherits the source's permissions, and a file(DOWNLOAD) result
      # is not executable -- so without this the staged server exists and then
      # fails to start with "execvp: Permission denied". install(PROGRAMS) sets
      # the bit for an installed OMEdit; nothing did for the build tree.
      add_custom_command(TARGET OMEdit POST_BUILD
                         COMMAND chmod +x ${_ls_build_dir}/${MODELICA_LS_STAGE_EXE_NAME})
    endif()
  endif()
endif()
