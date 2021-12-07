cmake_minimum_required (VERSION 3.14)

project(OMPlot)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt5 COMPONENTS Widgets PrintSupport REQUIRED)

omc_add_subdirectory(qwt)
omc_add_subdirectory(OMPlot/OMPlotGUI)
