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
# The per-package documentation below keeps it from being empty: a component with no install rule
# is never registered, so the loop further down would drop it.

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
## Per-package documentation ##########################################################################
# Debian policy requires every binary package to ship share/doc/<package>/copyright, and every
# non-native one a share/doc/<package>/changelog.Debian.gz as well; lintian reports their absence as
# no-copyright-file and no-changelog. The directory is named after the *binary package*, which is not
# always the component name (meta is packaged as openmodelica), hence om_package_name().
#
# These install rules are also what registers each component with CMake. They therefore have to run
# before the get_cmake_property(... COMPONENTS) below picks the list up -- and they are the only
# rules the meta component has, since a metapackage ships no program of its own.
#
# The changelog is generated rather than maintained: this project's history is its git log, and a
# hand-written debian/changelog would only ever restate the version that is already in the package.
# One entry naming the version being built is what the policy asks for and all that can honestly be
# said. gzip -9n, because lintian wants maximum compression and no embedded timestamp.
#
# It is called changelog.Debian.gz and so means nothing to rpm, which keeps its changelog in the spec
# rather than on disk. The file is installed into both formats' packages all the same: install rules
# are fixed at configure time, and cpack chooses the generator later.
# The copyright file is machine-readable (DEP-5) and generated, rather than OSMC-License.txt
# shipped verbatim. Two reasons, both lintian errors on the raw file:
#   * Debian policy wants the licence of each set of files stated in the DEP-5 fields, not just a
#     licence text dropped in the package.
#   * copyright-not-using-common-license-for-gpl: a copyright file that names the GPL has to say
#     where the GPL lives on a Debian system. OpenModelica is offered under the AGPL version 3 or
#     the OSMC-PL, so the file names the GPL and must point at /usr/share/common-licenses.
#
# The OSMC-PL text is embedded because it is not a licence Debian ships; every line is indented by
# one space, and a blank line becomes " .", as the DEP-5 format requires.
#
# AGPL-3 is not in /usr/share/common-licenses either (only GPL-1/2/3 and LGPL are), so the
# reference below points at GPL-3, which the AGPL is the GPL-3 text plus its section 13, and names
# the canonical URL for the rest. A Debian archive upload would be expected to carry the full
# AGPL-3 text instead; we publish through our own repository, where this is enough to satisfy both
# policy's intent and the linter.
set(OM_COPYRIGHT_FILE "${CMAKE_CURRENT_BINARY_DIR}/copyright")
file(READ "${PROJECT_SOURCE_DIR}/OSMC-License.txt" OM_LICENSE_RAW)

# Indent the licence for the DEP-5 License field: every line gains one leading space, and a line
# that is otherwise blank becomes " ." -- a line holding only a space ends the field, which would
# truncate the licence at its first paragraph break and leave the rest as unparsable garbage.
#
# Done one line at a time rather than with string(REPLACE "\n" "\n "), which cannot express the
# blank-line case. A CMake list is no use here either: list elements cannot be empty, so splitting
# on newlines silently drops exactly the blank lines this has to treat specially.
set(OM_LICENSE_REST "${OM_LICENSE_RAW}")
set(OM_LICENSE_TEXT "")
while(NOT OM_LICENSE_REST STREQUAL "")
  string(FIND "${OM_LICENSE_REST}" "\n" OM_LICENSE_NL)
  if(OM_LICENSE_NL EQUAL -1)
    set(OM_LICENSE_LINE "${OM_LICENSE_REST}")
    set(OM_LICENSE_REST "")
  else()
    string(SUBSTRING "${OM_LICENSE_REST}" 0 ${OM_LICENSE_NL} OM_LICENSE_LINE)
    math(EXPR OM_LICENSE_NEXT "${OM_LICENSE_NL} + 1")
    string(SUBSTRING "${OM_LICENSE_REST}" ${OM_LICENSE_NEXT} -1 OM_LICENSE_REST)
  endif()
  string(STRIP "${OM_LICENSE_LINE}" OM_LICENSE_STRIPPED)
  if(OM_LICENSE_STRIPPED STREQUAL "")
    string(APPEND OM_LICENSE_TEXT " .\n")
  else()
    string(APPEND OM_LICENSE_TEXT " ${OM_LICENSE_LINE}\n")
  endif()
endwhile()
file(WRITE "${OM_COPYRIGHT_FILE}"
"Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/\n"
"Upstream-Name: OpenModelica\n"
"Upstream-Contact: ${CPACK_PACKAGE_CONTACT}\n"
"Source: https://github.com/OpenModelica/OpenModelica\n"
"\n"
"Files: *\n"
"Copyright: 1998-2026 Open Source Modelica Consortium (OSMC),\n"
"           c/o Linkoepings universitet, Department of Computer and Information Science,\n"
"           SE-58183 Linkoeping, Sweden\n"
"License: OSMC-PL-1.8 or AGPL-3\n"
"\n"
"License: AGPL-3\n"
" This program is free software: you can redistribute it and/or modify it under\n"
" the terms of the GNU Affero General Public License version 3, as published by\n"
" the Free Software Foundation.\n"
" .\n"
" This program is distributed in the hope that it will be useful, but WITHOUT ANY\n"
" WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A\n"
" PARTICULAR PURPOSE. See the GNU Affero General Public License for more details.\n"
" .\n"
" The GNU Affero General Public License version 3 is the GNU General Public\n"
" License version 3 together with its additional section 13. On Debian systems\n"
" the complete text of the GNU General Public License version 3 can be found in\n"
" /usr/share/common-licenses/GPL-3; the full text of the Affero variant is at\n"
" https://www.gnu.org/licenses/agpl-3.0.html\n"
"\n"
"License: OSMC-PL-1.8\n"
"${OM_LICENSE_TEXT}")

set(OM_CHANGELOG_FILE "${CMAKE_CURRENT_BINARY_DIR}/changelog.Debian")
string(TIMESTAMP OM_CHANGELOG_DATE "%a, %d %b %Y %H:%M:%S +0000" UTC)
file(WRITE "${OM_CHANGELOG_FILE}"
"openmodelica (${CPACK_PACKAGE_VERSION}-1) unstable; urgency=medium\n"
"\n"
"  * Build of OpenModelica ${CPACK_PACKAGE_VERSION}. The change history of this\n"
"    release is the git log of the OpenModelica repository.\n"
"\n"
" -- OpenModelica Build System <${CPACK_PACKAGE_CONTACT}>  ${OM_CHANGELOG_DATE}\n")

find_program(OM_GZIP_EXECUTABLE gzip)
if(OM_GZIP_EXECUTABLE)
  execute_process(COMMAND "${OM_GZIP_EXECUTABLE}" -9 -n -f "${OM_CHANGELOG_FILE}"
                  RESULT_VARIABLE OM_CHANGELOG_GZIP_RESULT)
  if(NOT OM_CHANGELOG_GZIP_RESULT EQUAL 0)
    message(WARNING "Could not gzip ${OM_CHANGELOG_FILE}; the packages will have no changelog.")
  endif()
else()
  message(WARNING "No gzip found, so the packages will have no changelog.Debian.gz "
                  "and lintian will report no-changelog.")
endif()

foreach(comp IN LISTS OM_PACKAGE_COMPONENTS)
  om_package_name(${comp} _om_doc_package)
  install(FILES "${OM_COPYRIGHT_FILE}"
          DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/${_om_doc_package}"
          COMPONENT ${comp})
  if(EXISTS "${OM_CHANGELOG_FILE}.gz")
    install(FILES "${OM_CHANGELOG_FILE}.gz"
            DESTINATION "${CMAKE_INSTALL_DATAROOTDIR}/doc/${_om_doc_package}"
            COMPONENT ${comp})
  endif()
endforeach()

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
                    DESCRIPTION
                    "Modelica compiler, without the simulation runtime
omc translates Modelica and MetaModelica models into C, and provides the
scripting API the other OpenModelica tools drive. Simulating a model also
needs the simrt package, which omc depends on."
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
                    DESCRIPTION
                    "C simulation runtime for omc-generated code
The libraries that code generated by omc includes and links against, the
solvers it integrates with, and the headers and static libraries an exported
FMU is built from."
                    )

cpack_add_component(simrtcpp
                    DISPLAY_NAME "C++ Simulation Runtime"
                    DEPENDS simrt
                    GROUP Runtimes
                    DESCRIPTION
                    "C++ simulation runtime for omc-generated code
The C++ counterpart of simrt, used by models translated with the Cpp
simulation code target."
                    )

cpack_add_component(omsimulator
                    DISPLAY_NAME "OMSimulator"
                    DESCRIPTION
                    "FMI and SSP co-simulation environment
OMSimulator loads FMUs and SSP system descriptions and simulates them,
standalone or from its Python bindings. It does not need a Modelica
compiler."
                    )

cpack_add_component(omshellterminal
                    DISPLAY_NAME "OMShell-terminal"
                    DEPENDS simrt omplot
                    DESCRIPTION
                    "Command-line interactive shell for OpenModelica
A readline-based REPL for the omc scripting API: load models, simulate them
and plot the results without a graphical environment."
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
                    DESCRIPTION
                    "Plotting tool for OpenModelica simulation results
OMPlot draws the result files a simulation produces. It is what omc's plot()
command starts, so plotting from a script needs this package."
                    )

cpack_add_component(omnotebook
                    DISPLAY_NAME "OMNotebook"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION
                    "Interactive notebook for OpenModelica
An electronic notebook in the style of Mathematica's, mixing text with
Modelica models that can be simulated in place."
                    )

cpack_add_component(drmodelica
                    DISPLAY_NAME "DrModelica"
                    DEPENDS omnotebook
                    GROUP GUIClients
                    DESCRIPTION
                    "Interactive Modelica tutorial for OMNotebook
The worked examples from the Modelica book, as OMNotebook documents: a
guided introduction to the language."
                    )

cpack_add_component(drcontrol
                    DISPLAY_NAME "DrControl"
                    DEPENDS omnotebook
                    GROUP GUIClients
                    DESCRIPTION
                    "Interactive control-theory tutorial for OMNotebook
An introduction to control theory with Modelica, as OMNotebook documents,
covering feedback, state-space models and controller design."
                    )

cpack_add_component(omshell
                    DISPLAY_NAME "OMShell"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION
                    "Graphical interactive shell for OpenModelica
A Qt front end to the omc scripting API, with command history and syntax
highlighting. See omshell-terminal for the text-mode equivalent."
                    )

cpack_add_component(omedit
                    DISPLAY_NAME "OMEdit"
                    DEPENDS simrt omplot omsimulator
                    GROUP GUIClients
                    DESCRIPTION
                    "Graphical connection editor for Modelica models
OMEdit draws Modelica models as connection diagrams, edits them textually or
graphically, runs simulations and plots the results. It is the graphical
front end most users work in."
                    )

# OMSens_Qt installs no program of its own: it is the sensitivity-analysis plugin OMEdit loads,
# which is why it depends on omedit rather than the other way round.
cpack_add_component(omsens
                    DISPLAY_NAME "OMSens"
                    DEPENDS omedit
                    GROUP GUIClients
                    DESCRIPTION
                    "Sensitivity analysis plugin for OMEdit
OMSens runs a model repeatedly over varied parameters and reports how much
each one moves the result. It is loaded by OMEdit and has no interface of
its own."
                    )

cpack_add_component(omoptim
                    DISPLAY_NAME "OMOptim"
                    DEPENDS simrt omplot
                    GROUP GUIClients
                    DESCRIPTION
                    "Legacy optimisation front end for OpenModelica
A graphical tool for parameter optimisation over Modelica models. Superseded
and off by default; see the OM_OMOPTIM_ENABLE build option."
                    )

cpack_add_component(omlibrary
                    DISPLAY_NAME "Modelica libraries"
                    DEPENDS omc
                    DESCRIPTION
                    "Modelica library cache for offline installation
The Modelica libraries omc's package manager would otherwise download, so
that installPackage() works on a machine with no network access."
                    )

## The metapackage
# No DEPENDS here: only the DEB and RPM generators build a metapackage, and the list is decided at
# cpack time (OpenModelicaCPackOptions.in.cmake). A component that selected every other one would
# only get in the way of the graphical installers, which show the component tree instead.
cpack_add_component(meta
                    DISPLAY_NAME "OpenModelica"
                    DESCRIPTION
                    "OpenModelica modelling and simulation environment
OpenModelica is an open-source environment for modelling and simulating
systems described in the Modelica language.
.
This package installs the whole tool chain: the compiler, the simulation
runtime and the graphical clients. It contains no files of its own."
                    )

## Documentation
cpack_add_component(doc
                    DISPLAY_NAME "Documentation"
                    DESCRIPTION
                    "Documentation for OpenModelica
The OpenModelica User's Guide and the system documentation."
                    )
