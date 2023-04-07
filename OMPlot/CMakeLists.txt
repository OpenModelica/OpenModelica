cmake_minimum_required (VERSION 3.14)

project(OMPlot)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omplot' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omplot)

## Set the C++ standard to use. OMPlot uses C++14.
set(CMAKE_CXX_STANDARD 14)
set(CXX_STANDARD_REQUIRED ON)
## Make sure we do not start relying on extensions down the road.
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt5 COMPONENTS Widgets PrintSupport REQUIRED)

omc_add_subdirectory(qwt)
omc_add_subdirectory(OMPlot/OMPlotGUI)
