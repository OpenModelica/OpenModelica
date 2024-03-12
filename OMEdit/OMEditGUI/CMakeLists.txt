

if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omedit.icns)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/../OMEditLIB/Resources/icons/omedit.icns")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMEdit WIN32 MACOSX_BUNDLE main.cpp rc_omedit.rc ${app_icon_macos})
target_link_libraries(OMEdit PRIVATE OMEditLib)

if(APPLE)
  set_target_properties(OMEdit PROPERTIES MACOSX_BUNDLE_INFO_PLIST ${CMAKE_CURRENT_SOURCE_DIR}/Info.plist)
endif()

if(OM_OMEDIT_INSTALL_RUNTIME_DLLS AND MINGW)

  # Escape the environment variable path
  if(NOT DEFINED ENV{OMDEV})
    message(FATAL_ERROR "Environment variable \"OMDEV\" is not set.")
  endif()
  if(CMAKE_SIZEOF_VOID_P EQUAL 8)
    string(REPLACE "\\" "/" OMDEV_MSYS_ESCAPED "$ENV{OMDEV}\\tools\\msys")
    set(UCRT_DIR "${OMDEV_MSYS_ESCAPED}/ucrt64")
    message(STATUS "MSYS environment UCRT64: ${OMDEV}\\tools\\msys")
  else()
    message(FATAL_ERROR "No 32-bit version of UCRT available!")
  endif()
  if(NOT DEFINED ENV{MSYSTEM_PREFIX})
    message(FATAL_ERROR "Environment variable \"MSYSTEM_PREFIX\" is not set.")
  endif()
  string(REPLACE "\\" "/" MSYSTEM_PREFIX_ESCAPED "$ENV{MSYSTEM_PREFIX}")

  # Install the Qt plugins directories
  message(STATUS "Installing QT5 plugins from ${MSYSTEM_PREFIX_ESCAPED}/share/qt5/plugins/")
  install(DIRECTORY ${MSYSTEM_PREFIX_ESCAPED}/share/qt5/plugins/    # Note the slash at the end!
          TYPE BIN)

  # TODO: This is stupid, but I can't get install with RUNTIME_DEPENDENCIES to run.
  # It needs to link to libs that are isntalled to ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR},
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
          ${MSYSTEM_PREFIX_ESCAPED}/bin/Qt5OpenGL.dll
          TYPE BIN)

  install(TARGETS OMEdit
          RUNTIME_DEPENDENCIES
            DIRECTORIES ${MSYSTEM_PREFIX_ESCAPED}/bin ${RUNTIME_LIB_DIRS}
            PRE_EXCLUDE_REGEXES "api-ms-" "ext-ms-"
            POST_EXCLUDE_REGEXES ".*system32/.*\\.dll")
else()
  install(TARGETS OMEdit
          BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
endif()
