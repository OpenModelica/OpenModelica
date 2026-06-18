
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Widgets PrintSupport Xml REQUIRED)

set(OMSHELLL_SOURCES  main.cpp
                      commandcompletion.cpp
                      omcinteractiveenvironment.cpp
                      oms.cpp
                      oms.qrc
                      rc_omshell.rc)

set(OMSHELLL_HEADERS commandcompletion.h
                       omcinteractiveenvironment.h
                       oms.h)

if(APPLE)
  set(MACOSX_BUNDLE_ICON_FILE omshell.icns)

  # The following tells CMake where to find and install the file itself.
  set(app_icon_macos "${CMAKE_CURRENT_SOURCE_DIR}/Resources/omshell.icns")
  set_source_files_properties(${app_icon_macos} PROPERTIES
       MACOSX_PACKAGE_LOCATION "Resources")
else()
  set(app_icon_macos "")
endif()

add_executable(OMShell WIN32 ${OMSHELLL_SOURCES} ${OMSHELLL_HEADERS} ${app_icon_macos})

target_link_libraries(OMShell PRIVATE OpenModelicaCompiler)
target_link_libraries(OMShell PRIVATE Qt${OM_QT_MAJOR_VERSION}::Xml)
target_link_libraries(OMShell PRIVATE Qt${OM_QT_MAJOR_VERSION}::Widgets)
target_link_libraries(OMShell PRIVATE Qt${OM_QT_MAJOR_VERSION}::PrintSupport)

omc_install_gui_client(OMShell)

if(MINGW)
  # Find windeployqt6
  find_program(WINDEPLOYQT_EXECUTABLE
    NAMES windeployqt windeployqt6
    HINTS "${MSYSTEM_PREFIX_ESCAPED}/bin"
    REQUIRED
  )

  install(CODE "
    message(STATUS \"Running windeployqt6 on OMShell...\")
    execute_process(
      COMMAND \"${WINDEPLOYQT_EXECUTABLE}\"
        --no-compiler-runtime
        --no-system-d3d-compiler
        --no-quick-import
        --libdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}\"
        --translationdir \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/share/qt6/translations\"
        \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/OMShell.exe\"
      RESULT_VARIABLE WINDEPLOYQT_RESULT
      OUTPUT_VARIABLE WINDEPLOYQT_OUTPUT
      ERROR_VARIABLE  WINDEPLOYQT_ERROR
    )
    if(NOT WINDEPLOYQT_RESULT EQUAL 0)
      message(FATAL_ERROR \"windeployqt6 failed:\n\${WINDEPLOYQT_OUTPUT}\n\${WINDEPLOYQT_ERROR}\")
    endif()
    message(STATUS \"windeployqt6 output: \${WINDEPLOYQT_OUTPUT}\")
  ")
endif()

install(FILES commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omshell)
