

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
else ()
  omc_install_gui_client(OMEdit)
endif()
