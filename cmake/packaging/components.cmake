## The components we package ##########################################################################
# Every install(... COMPONENT <name>) in the whole tree registers <name>, and CPack packages
# each registered component separately (CPACK_DEB_COMPONENT_INSTALL / CPACK_RPM_COMPONENT_INSTALL).
# Left to itself it would therefore also ship the components of the third-party projects we build
# in-tree -- SuiteSparse, libzmq, oneTBB, zlib, fmt, simdjson, CMinpack all install under names of
# their own ("Development", "Runtime", "devel", "headers", "libraries", "pkgconfig", ...) -- as
# packages called openmodelica-Development and the like. Their *files* are not lost by leaving them
# out: the libraries we link against are installed by our own rules, under our own components.
#
# So name the components we own, and package only those. A component that is new here has to be
# added deliberately, which is the point: an install rule should not be able to invent a package.

## The metapackage ####################################################################################
# The Autoconf packaging had an `openmodelica` package that pulled in the whole tool chain; CPack
# packaging replaced it with nothing. It returns as a component with no program of its own: its
# dependencies are what make it a metapackage. OpenModelicaCPackOptions.in.cmake works them out per
# cpack run, and names the package "openmodelica" rather than "openmodelica-meta".
#
# The licence file keeps it from being empty: a component with no install rule is never registered,
# so the loop below would drop it, and dpkg and rpm expect every package to carry its copyright.
install(FILES "${PROJECT_SOURCE_DIR}/OSMC-License.txt"
        DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/openmodelica"
        RENAME copyright
        COMPONENT meta)

set(OM_PACKAGE_COMPONENTS
    omc
    simrt
    simrtcpp
    omsimulator
    omshellterminal
    omplot
    omnotebook
    drmodelica
    drcontrol
    omshell
    omedit
    omsens
    omoptim
    omlibrary
    # Installed above. It holds no program, only dependencies on the components here.
    meta
)

# Components are registered by the install() rules that ran, so which of ours exist depends on the
# OM_ENABLE_* options this build was configured with. Package the ones that are actually there.
get_cmake_property(OM_REGISTERED_COMPONENTS COMPONENTS)
set(CPACK_COMPONENTS_ALL "")
foreach(comp IN LISTS OM_PACKAGE_COMPONENTS)
  if(comp IN_LIST OM_REGISTERED_COMPONENTS)
    list(APPEND CPACK_COMPONENTS_ALL ${comp})
  endif()
endforeach()

# The catch-all component from the top-level CMakeLists.txt. Anything under it is a file that no
# install() rule assigned to a component, so it is in none of the packages above and would silently
# go missing from the installation. Name the offender at configure time instead of letting someone
# find out from a bug report.
if("unknown-install-component" IN_LIST OM_REGISTERED_COMPONENTS)
  message(WARNING
    "Some install() rule did not set a COMPONENT, so its files landed in "
    "'${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME}' and will not be in any package. Find them with\n"
    "  cmake --install <build dir> --component ${CMAKE_INSTALL_DEFAULT_COMPONENT_NAME} "
    "--prefix <scratch dir>\n"
    "and give them a COMPONENT, or a CMAKE_INSTALL_DEFAULT_COMPONENT_NAME for their directory.")
endif()

include(CPack)

# omc and simrt need each other, and both directions are real: simulating a model means
# generating C, and that C includes simrt's headers and links its libSimulationRuntimeC,
# while libSimulationRuntimeC in turn links the libOpenModelicaRuntimeC, libomcgc and
# libomc_result that are installed here. Saying so in only one direction is what let
# `apt-get install omc` produce an omc that could not compile anything:
# "fatal error: 'omc_simulation_settings.h' file not found".
#
# The Autoconf packaging had the same inversion -- its libomcsimulation held
# libSimulationRuntimeC while libOpenModelicaRuntimeC sat in libomc above it -- and hid it
# by having the omc package depend on both. It is a cycle here because these three
# libraries are neither the compiler nor the solver runtime but the base both are built on,
# and there is no component for that yet. Splitting one out (the omc-common/libomc layer of
# the old packaging) is part of deciding the final package granularity, see
# https://github.com/OpenModelica/OpenModelica/issues/16377.
cpack_add_component(omc
                    DISPLAY_NAME "OpenModelica core compiler(omc)"
                    # For graphical multi-component installers, set this to required.
                    REQUIRED
                    DEPENDS simrt
                    DESCRIPTION "The OpenModelica Compiler without any of the simulation support."
                    )

## Runtimes
cpack_add_component_group(Runtimes
                    EXPANDED
                    BOLD_TITLE
                    DESCRIPTION
                   "The OpenModleica simulation runtime libraries and tools.")

# This also carries what building an FMU needs: the runtime, dgesv and CMinpack sources under
# share/omc/sources/c that every FMU export copies into the FMU it builds
# (SimCodeMain.callTargetTemplatesFMU -- not only a source-code one, despite the name of the
# file that installs them), and the static libSimulationRuntimeFMI and
# libOpenModelicaFMIRuntimeC the result links. They were a component, and so a package, of
# their own for a while; nothing but omc-generated code ever used them, and omc cannot export
# an FMU without them, so they are not separately installable and do not need to be separately
# packaged. The Autoconf packaging shipped them in omc-common for the same reason.
cpack_add_component(simrt
                    DISPLAY_NAME "Simulation Runtime"
                    DEPENDS omc
                    GROUP Runtimes
                    DESCRIPTION "The OpenModelica C simulation runtime libraries and tools, including what is needed to build an FMU."
                    )

cpack_add_component(simrtcpp
                    DISPLAY_NAME "C++ Simulation Runtime"
                    DEPENDS simrt
                    GROUP Runtimes
                    DESCRIPTION "The OpenModelica C++ simulation runtime libraries and tools."
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

cpack_add_component(drmodelica
                    DISPLAY_NAME "DrModelica"
                    DEPENDS omnotebook
                    GROUP GUIClients
                    DESCRIPTION "The DrModelica tutorial, a collection of OMNotebook example notebooks for learning Modelica."
                    )

cpack_add_component(drcontrol
                    DISPLAY_NAME "DrControl"
                    DEPENDS omnotebook
                    GROUP GUIClients
                    DESCRIPTION "The DrControl tutorial, a collection of OMNotebook example notebooks for learning control theory with Modelica."
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

# OMSens_Qt installs no program of its own: it is the sensitivity-analysis plugin OMEdit loads,
# which is why it depends on omedit rather than the other way round.
cpack_add_component(omsens
                    DISPLAY_NAME "OMSens"
                    DEPENDS omedit
                    GROUP GUIClients
                    DESCRIPTION "The OMSens sensitivity analysis plugin for OMEdit."
                    )

cpack_add_component(omoptim
                    DISPLAY_NAME "OMOptim"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION "The (legacy) OpenModelica optimization GUI. Off by default, see OM_OMOPTIM_ENABLE."
                    )

cpack_add_component(omlibrary
                    DISPLAY_NAME "Modelica libraries"
                    DEPENDS omc
                    DESCRIPTION "The cache of Modelica libraries that omc can install without network access."
                    )

## The metapackage
# No DEPENDS here: only the DEB and RPM generators build a metapackage, and the list is decided at
# cpack time (OpenModelicaCPackOptions.in.cmake). A component that selected every other one would
# only get in the way of the graphical installers, which show the component tree instead.
cpack_add_component(meta
                    DISPLAY_NAME "OpenModelica"
                    DESCRIPTION "The OpenModelica tool chain: the compiler, the simulation runtime and the graphical clients."
                    )

## Documentation
cpack_add_component(doc
                    DISPLAY_NAME "Documentation"
                    DESCRIPTION "The OpenModelica User's Guide and the system documentation."
                    )
