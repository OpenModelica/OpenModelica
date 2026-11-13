
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt6 COMPONENTS Widgets PrintSupport Xml REQUIRED)

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

# Translations. The translation files are looked up as <omhome>/share/omshell/nls/OMShell_<locale>.qm.
find_package(Qt6 REQUIRED COMPONENTS LinguistTools)
set(OMSHELL_TS_FILES ${CMAKE_CURRENT_SOURCE_DIR}/OMShell_de.ts
                     ${CMAKE_CURRENT_SOURCE_DIR}/OMShell_sv.ts)
qt_add_translation(OMSHELL_TRANSLATIONS ${OMSHELL_TS_FILES})

add_executable(OMShell WIN32 ${OMSHELLL_SOURCES} ${OMSHELLL_HEADERS} ${OMSHELL_TRANSLATIONS} ${app_icon_macos})

# Update the .ts files (see OM_UPDATE_TRANSLATIONS). The ui_OtherDlg.h next to the sources is a checked-in
# uic output with the strings of the font size dialog (context Dialog), so all headers are scanned.
file(GLOB OMSHELL_LUPDATE_SOURCES CONFIGURE_DEPENDS
     "${CMAKE_CURRENT_SOURCE_DIR}/*.cpp"
     "${CMAKE_CURRENT_SOURCE_DIR}/*.h")
omc_add_qt_lupdate(OMShell TS_FILES ${OMSHELL_TS_FILES} SOURCES ${OMSHELL_LUPDATE_SOURCES})

target_link_libraries(OMShell PRIVATE OpenModelicaCompiler)
target_link_libraries(OMShell PRIVATE Qt6::Xml)
target_link_libraries(OMShell PRIVATE Qt6::Widgets)
target_link_libraries(OMShell PRIVATE Qt6::PrintSupport)

omc_install_gui_client(OMShell)
install(FILES ${OMSHELL_TRANSLATIONS}
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omshell/nls)

if(MINGW)
  omc_get_msys_prefix(MSYSTEM_PREFIX_ESCAPED)

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
