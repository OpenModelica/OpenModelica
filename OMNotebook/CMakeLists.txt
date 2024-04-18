cmake_minimum_required (VERSION 3.14)

project(OMNotebook)
## Anything installed from this directory and its subdirectories belongs
## to the install component 'omnotebook' if it is not explicitly changed.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omnotebook)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)


find_package(Qt5 COMPONENTS Widgets PrintSupport Xml REQUIRED)

omc_add_subdirectory(OMNotebook/OMNotebookGUI)


# Move this to DrModelica directory once we add CMake support for it.
install(DIRECTORY
	DrModelica/
	DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/drmodelica/
    FILES_MATCHING PATTERN "*.onb")
install(FILES OMNotebookHelp.onb
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/)
