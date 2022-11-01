cmake_minimum_required (VERSION 3.14)
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME gui)


project(OMShell)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt5 COMPONENTS Widgets PrintSupport WebKitWidgets Xml REQUIRED)

omc_add_subdirectory(OMShell/OMShellGUI)
