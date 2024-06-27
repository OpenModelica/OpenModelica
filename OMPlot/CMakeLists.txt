cmake_minimum_required (VERSION 3.14)

project(OMPlot)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omplot' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omplot)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Widgets PrintSupport REQUIRED)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  find_package(Qt6 COMPONENTS Core5Compat REQUIRED)
endif ()

omc_add_subdirectory(qwt)
omc_add_subdirectory(OMPlot/OMPlotGUI)
