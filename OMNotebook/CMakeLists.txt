cmake_minimum_required (VERSION 3.14)

project(OMNotebook)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omnotebook' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omnotebook)

omc_option(OM_ENABLE_DRMODELICA "Install the DrModelica example notebooks with OMNotebook" ON)
omc_option(OM_ENABLE_DRCONTROL  "Install the DrControl example notebooks with OMNotebook"  ON)

# Qt options
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Widgets PrintSupport Xml REQUIRED)

if (OM_QT_MAJOR_VERSION VERSION_GREATER_EQUAL 6)
  find_package(Qt6 COMPONENTS Core5Compat REQUIRED)
endif ()

omc_add_subdirectory(OMNotebook/OMNotebookGUI)

if(OM_ENABLE_DRMODELICA)
  omc_add_subdirectory(DrModelica)
endif()

if(OM_ENABLE_DRCONTROL)
  omc_add_subdirectory(DrControl)
endif()

install(FILES OMNotebookHelp.onb
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/)
