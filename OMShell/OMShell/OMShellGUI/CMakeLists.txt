
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS Widgets PrintSupport Xml REQUIRED)

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

add_executable(OMShell WIN32 MACOSX_BUNDLE ${OMSHELLL_SOURCES}
                                           ${OMSHELLL_HEADERS}
                                           ${app_icon_macos})

target_link_libraries(OMShell PRIVATE OpenModelicaCompiler)
target_link_libraries(OMShell PRIVATE Qt5::Xml)
target_link_libraries(OMShell PRIVATE Qt5::Widgets)
target_link_libraries(OMShell PRIVATE Qt5::PrintSupport)


install(TARGETS OMShell
        BUNDLE DESTINATION ${OM_MACOS_INSTALL_BUNDLEDIR})
install(FILES commands.xml
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omshell)
