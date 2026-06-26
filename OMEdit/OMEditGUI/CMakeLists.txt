

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

  # Escape the environment variable path
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(NOT CMAKE_SIZEOF_VOID_P EQUAL 8)
    message(FATAL_ERROR "No 32-bit version of UCRT available!")
  endif()
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()

  if (CMAKE_GENERATOR STREQUAL "MinGW Makefiles" AND "$ENV{VisualStudioVersion}" STREQUAL "")
    string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{OMDEV}\\tools\\msys\\$ENV{MSYSTEM_PREFIX}")
  else()
    string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")
  endif()

  # TODO: This is stupid, but I can't get install with RUNTIME_DEPENDENCIES to run.
  # It needs to link to libs that are installed to ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR},
  # but if I add that to DIRECTORIES it will throw errors on the second run.
  set(OMPLOT_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMPlot/OMPlot/OMPlotGUI ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMPlot/qwt/src)
  set(OMSIMULATOR_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMSimulator/src/OMSimulatorLib)
  set(OMCOMPILER_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/Compiler/bin)
  set(SIMULATION_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/SimulationRuntime/c)
  set(GC_RUNTIME_LIB_DIR ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}OMCompiler/3rdParty/gc)
  set(RUNTIME_LIB_DIRS ${OMPLOT_LIB_DIR} ${OMSIMULATOR_LIB_DIR} ${OMCOMPILER_LIB_DIR} ${SIMULATION_RUNTIME_LIB_DIR} ${GC_RUNTIME_LIB_DIR})
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

  # install(TARGETS RUNTIME_DEPENDENCIES) is rejected when cross-compiling, and
  # file(GET_RUNTIME_DEPENDENCIES) does not resolve PE deps on a Linux host, so
  # walk the import closure ourselves with llvm-objdump.
  install(CODE "
    set(OMDEPLOY_EXE \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMEdit.exe\")
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

  # QML modules (loaded at runtime by the Quick3D animation backend; the whole
  # qml/ tree is small). WebEngine is stubbed on MSVC (OM_OMEDIT_NO_WEBENGINE),
  # so its QML and Chromium runtime assets (QtWebEngineProcess.exe, resources,
  # locales) are intentionally not bundled.
  if(EXISTS "${_qt_root}/qml")
    install(DIRECTORY "${_qt_root}/qml/" DESTINATION "${CMAKE_INSTALL_BINDIR}/qml")
  endif()

  install(CODE "file(WRITE \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/qt.conf\" \"[Paths]\\nPrefix = .\\nPlugins = .\\nQml = qml\\n\")")
else ()
  omc_install_gui_client(OMEdit)
endif()
