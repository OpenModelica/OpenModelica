cmake_minimum_required (VERSION 3.14)

project(OMPlot)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omplot' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omplot)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Widgets PrintSupport Svg REQUIRED)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  find_package(Qt6 COMPONENTS Core5Compat REQUIRED)
endif ()

omc_option (OM_USE_SYSTEM_QWT "Use system qwt" OFF)
if (OM_USE_SYSTEM_QWT)
  list (APPEND CMAKE_MODULE_PATH ${CMAKE_CURRENT_SOURCE_DIR})
  find_package (Qwt 6 MODULE REQUIRED)
  add_library (omqwt INTERFACE)
  target_include_directories (omqwt INTERFACE ${QWT_INCLUDE_DIRS})
  target_link_libraries (omqwt INTERFACE ${QWT_LIBRARIES})
else ()
  omc_add_subdirectory(qwt)
endif ()

omc_add_subdirectory(OMPlot/OMPlotGUI)
