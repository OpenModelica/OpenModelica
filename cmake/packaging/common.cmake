# Common variables for most package generators.

set(CPACK_VERBATIM_VARIABLES ON)

set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VENDOR "Open Source Modelica Consoritum")

set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
SET(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_BINARY_DIR}/_packages")

set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/omc")

set(CPACK_PACKAGE_VERSION ${SOURCE_REVISION})

set(CPACK_PACKAGE_CONTACT "build@openmodelica.org")

set(CPACK_RESOURCE_FILE_LICENSE "${PROJECT_SOURCE_DIR}/OSMC-License.txt")
# set(CPACK_RESOURCE_FILE_README "${PROJECT_SOURCE_DIR}/README.md")

# Generator specific variables go in their own files.
include(cmake/packaging/debian.cmake)
include(cmake/packaging/productbuild.cmake)

# Now that the options/settings variables have been set include CPack and add the components.
include(CPack)

cpack_add_component(omc
                    DISPLAY_NAME "OpenModelica core compiler(omc)"
                    # For graphical multi-component installers, set this to required.
                    REQUIRED
                    DESCRIPTION "The OpenModelica Compiler without any of the simulation support."
                    )

## Runtimes
cpack_add_component_group(Runtimes
                    EXPANDED
                    BOLD_TITLE
                    DESCRIPTION
                   "The OpenModleica simulation runtime libraries and tools.")

cpack_add_component(simrt
                    DISPLAY_NAME "Simulation Runtime"
                    DEPENDS omc
                    GROUP Runtimes
                    DESCRIPTION "The OpenModelica C simulation runtime libraries and tools."
                    )

cpack_add_component(simrtcpp
                    DISPLAY_NAME "C++ Simulation Runtime"
                    DEPENDS simrt
                    GROUP Runtimes
                    DESCRIPTION "The OpenModelica C++ simulation runtime libraries and tools."
                    )

cpack_add_component(fmu
                    DISPLAY_NAME "FMU Support"
                    DEPENDS simrt
                    GROUP Runtimes
                    DESCRIPTION "The libaries and files needed to compile an OpenModelica
FMU (normal or Source-Code FMU) including the simulation runtime source files needed for creating Source-Code FMUs."
                    )

cpack_add_component(omsimulator
                    DISPLAY_NAME "OMSimulator"
                    DESCRIPTION "The OpenModelica FMI & SSP-based co-simulation environment."
                    )

cpack_add_component(omshellterminal
                    DISPLAY_NAME "OMShell-terminal"
                    DEPENDS simrt omplot
                    DESCRIPTION "A text-based REPL command-line interface to OpenModelica."
                    )

## Graphical User Interface Clients
cpack_add_component_group(GUIClients
                    DISPLAY_NAME "GUI Clients"
                    EXPANDED
                    BOLD_TITLE
                    DESCRIPTION
                   "The OpenModelica Graphical User Interface clients.")

cpack_add_component(omplot
                    DISPLAY_NAME "OMPlot"
                    DEPENDS simrt
                    GROUP GUIClients
                    DESCRIPTION "Plot tool for OpenModelica. This tool is essential for using the plot() command in omc."
                    )

cpack_add_component(omnotebook
                    DISPLAY_NAME "OMNotebook"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION "A Mathematica-style Notebook for OpenModelica."
                    )

cpack_add_component(omshell
                    DISPLAY_NAME "OMShell"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION "A text-based interface to OpenModelica (based on Qt)."
                    )

cpack_add_component(omedit
                    DISPLAY_NAME "OMEdit"
                    DEPENDS simrt omplot omsimulator
                    GROUP GUIClients
                    DESCRIPTION "The OpenModelica Graphical Connection Editor."
                    )

cpack_add_component(omsens
                    DISPLAY_NAME "OMSens"
                    DEPENDS omedit
                    GROUP GUIClients
                    DESCRIPTION "Sensitivity analysis support for OMEdit."
                    )



