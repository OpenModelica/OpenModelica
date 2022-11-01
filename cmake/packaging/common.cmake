# Common variables for most package generators.

set(CPACK_VERBATIM_VARIABLES ON)

set(CPACK_PACKAGE_NAME ${PROJECT_NAME})
set(CPACK_PACKAGE_VENDOR "Open Source Modelica Consoritum")

set(CPACK_PACKAGE_INSTALL_DIRECTORY ${CPACK_PACKAGE_NAME})
SET(CPACK_OUTPUT_FILE_PREFIX "${CMAKE_BINARY_DIR}/_packages")

set(CPACK_PACKAGING_INSTALL_PREFIX "/opt/omc")

set(CPACK_PACKAGE_VERSION_MAJOR ${PROJECT_VERSION_MAJOR})
set(CPACK_PACKAGE_VERSION_MINOR ${PROJECT_VERSION_MINOR})
set(CPACK_PACKAGE_VERSION_PATCH ${PROJECT_VERSION_PATCH})

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
                    DESCRIPTION "The OpenModelica Compiler without any of the simulation support.
You can use this package to translate Modelica or MetaModelica files. If you
are intending to simulate models you should install the simrt package as well."
                    )

cpack_add_component(simrt
                    DISPLAY_NAME "Simulation Runtime"
                    DEPENDS omc
                    DESCRIPTION "The OpenModelica simulation runtime and tools.
This is the core of the OpenModelica simulation infrastructure and is required if you intend to simulate
Modelica models with OpenModelica.
It is recommended to use it together with an OpenModelica client,
such as OMShell (textual interface), OMNotebook (for teaching purposes)
or OMEdit (graphical modeling) which are available in the openmodelica-gui package."
                    )

cpack_add_component(simrt-cpp
                    DISPLAY_NAME "CPP Simulation Runtime"
                    DEPENDS simrt
                    DESCRIPTION "The C++ simulation runtime for OpenModelica. This is required
if you plan to generate C++ code and simulate models, .i.e., use the --simCodeTarget=Cpp translation option."
                    )

cpack_add_component(fmu
                    DISPLAY_NAME "FMU Support"
                    DEPENDS simrt
                    DESCRIPTION "The libaries and files needed to compile an OpenModelica
FMU (normal or Source-Code FMU) including the simulation runtime source files needed for creating Source-Code FMUs."
                    )

cpack_add_component(omsimulator
                    DISPLAY_NAME "OMSimulator"
                    DESCRIPTION "The OpenModelica FMI & SSP-based co-simulation environment."
                    )

cpack_add_component(gui
                    DISPLAY_NAME "GUI Clients"
                    DEPENDS simrt omsimulator
                    DESCRIPTION "The OpenModelica Graphical User Interface clients. These include OMEdit (graphical modeling),
OMNotebook (for teaching purposes), OMShell (textual interface) and OMPlot (a plotting tool used by the other clients)."
                    )





