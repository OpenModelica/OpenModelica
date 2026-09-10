cmake_minimum_required(VERSION 3.14)

# The OpenModelica User's Guide.
#
# The guide documents OpenModelica by *running* it: omc executes the examples in
# the text and prints their real output, OMSimulator prints its own help, and the
# scripting API chapter is generated from the compiler's builtin definitions. So
# this needs a complete, installed OpenModelica, which CMake cannot express as a
# target dependency. Build and install the project first, then build the guide:
#
#   cmake -S . -B build -DOM_ENABLE_DOCS=ON
#   cmake --build build && cmake --install build
#   cmake --build build --target usersguide
#
# It can also be configured on its own against an OpenModelica installed
# elsewhere:
#
#   cmake -S doc/UsersGuide -B build-doc -DOM_USERSGUIDE_OMHOME=/usr/local
#   cmake --build build-doc
#
# Nothing is generated into the source tree; everything lands in the build
# directory.

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_CURRENT_SOURCE_DIR)
  project(OpenModelicaUsersGuide NONE)
  # Nothing is compiled here, so GNUInstallDirs has no architecture to derive a
  # libdir from and would warn about it. It is not one of the directories used.
  set(CMAKE_INSTALL_LIBDIR "lib" CACHE PATH "Object code libraries")
  include(GNUInstallDirs)
endif()

set(OM_USERSGUIDE_OMHOME "${CMAKE_INSTALL_PREFIX}" CACHE PATH
    "The installed OpenModelica the User's Guide is generated from (OPENMODELICAHOME).")

set(OM_USERSGUIDE_HTML_DIR "${CMAKE_CURRENT_BINARY_DIR}/build/html" CACHE PATH
    "The HTML tree to install and package. Point this at a pre-built guide to \
package one that was built elsewhere, for instance by a separate CI stage.")
mark_as_advanced(OM_USERSGUIDE_HTML_DIR)

## Tools ############################################################################################

find_package(Python3 COMPONENTS Interpreter REQUIRED)

# sphinx-build renders the guide; pandoc converts the HTML documentation
# annotations of the scripting API and the GitHub release notes to reST;
# inkscape rasterises the icons and diagrams; gnuplot draws the simulation
# results of the examples.
find_program(SPHINX_BUILD_EXECUTABLE NAMES sphinx-build sphinx-build3)
find_program(PANDOC_EXECUTABLE NAMES pandoc)
find_program(INKSCAPE_EXECUTABLE NAMES inkscape)
find_program(GNUPLOT_EXECUTABLE NAMES gnuplot)

set(OM_USERSGUIDE_OMC "${OM_USERSGUIDE_OMHOME}/${CMAKE_INSTALL_BINDIR}/omc")
set(OM_USERSGUIDE_OMSIMULATOR "${OM_USERSGUIDE_OMHOME}/${CMAKE_INSTALL_BINDIR}/OMSimulator")

foreach(tool SPHINX_BUILD_EXECUTABLE PANDOC_EXECUTABLE INKSCAPE_EXECUTABLE GNUPLOT_EXECUTABLE)
  if(NOT ${tool})
    message(FATAL_ERROR
      "${tool} not found, which the User's Guide needs. Install the tools listed in "
      "doc/UsersGuide/README.md, or configure with -DOM_ENABLE_DOCS=OFF.")
  endif()
endforeach()

# conf.py, the openmodelica extension and the helper scripts all import from
# source/requirements.txt, so an interpreter without those packages cannot build
# the guide. Say so now: otherwise the first missing one surfaces as a traceback
# several steps into a build that has already spent minutes running omc.
execute_process(
  COMMAND "${Python3_EXECUTABLE}"
          "${CMAKE_CURRENT_SOURCE_DIR}/cmake/check_requirements.py"
          "${CMAKE_CURRENT_SOURCE_DIR}/source/requirements.txt"
  OUTPUT_VARIABLE OM_USERSGUIDE_MISSING_REQUIREMENTS
  ERROR_VARIABLE OM_USERSGUIDE_REQUIREMENTS_ERROR
  RESULT_VARIABLE OM_USERSGUIDE_REQUIREMENTS_RESULT
  OUTPUT_STRIP_TRAILING_WHITESPACE)

if(NOT OM_USERSGUIDE_REQUIREMENTS_RESULT EQUAL 0)
  message(FATAL_ERROR "Could not check the User's Guide requirements with "
                      "${Python3_EXECUTABLE}: ${OM_USERSGUIDE_REQUIREMENTS_ERROR}")
endif()

if(OM_USERSGUIDE_MISSING_REQUIREMENTS)
  string(REPLACE "\n" " " OM_USERSGUIDE_MISSING_REQUIREMENTS
                 "${OM_USERSGUIDE_MISSING_REQUIREMENTS}")
  message(FATAL_ERROR
    "${Python3_EXECUTABLE} is missing: ${OM_USERSGUIDE_MISSING_REQUIREMENTS}\n"
    "Install them with\n"
    "  ${Python3_EXECUTABLE} -m pip install -r ${CMAKE_CURRENT_SOURCE_DIR}/source/requirements.txt\n"
    "or build against an interpreter that already has them, for instance a "
    "virtualenv, with\n"
    "  -DPython3_EXECUTABLE=<venv>/bin/python3 -DSPHINX_BUILD_EXECUTABLE=<venv>/bin/sphinx-build")
endif()

# sphinx-build has to come from that same environment: the extension runs inside
# *its* interpreter, not the one checked above. Both are cached on the first
# configure, so an activated virtualenv does not change them afterwards -- only
# passing them explicitly does.
get_filename_component(OM_USERSGUIDE_PYTHON_DIR "${Python3_EXECUTABLE}" DIRECTORY)
get_filename_component(OM_USERSGUIDE_SPHINX_DIR "${SPHINX_BUILD_EXECUTABLE}" DIRECTORY)
if(NOT OM_USERSGUIDE_PYTHON_DIR STREQUAL OM_USERSGUIDE_SPHINX_DIR)
  message(WARNING
    "sphinx-build and the Python interpreter come from different places:\n"
    "  ${SPHINX_BUILD_EXECUTABLE}\n"
    "  ${Python3_EXECUTABLE}\n"
    "The guide is built by the first and its requirements were checked against "
    "the second, so this only works if both environments have them.")
endif()

message(STATUS "User's Guide: ${SPHINX_BUILD_EXECUTABLE}")
message(STATUS "User's Guide: ${Python3_EXECUTABLE}")
message(STATUS "User's Guide: documenting ${OM_USERSGUIDE_OMHOME}")

## Layout ###########################################################################################

# sphinx-build runs from the binary directory, in the layout the directives in
# the text expect of it: the models they compile go to ./tmp, the plots they draw
# to ./source and the profiling data they publish to ./build/html, all relative
# to the working directory.
set(UG_WORKDIR "${CMAKE_CURRENT_BINARY_DIR}")
set(UG_SOURCE "${UG_WORKDIR}/source")
set(UG_BUILD "${UG_WORKDIR}/build")
set(UG_OMSIMULATOR_SOURCE "${CMAKE_CURRENT_SOURCE_DIR}/../../OMSimulator/doc/UsersGuide/source")

# OMPython needs to find the omc it should talk to, and conf.py needs the source
# root to describe the version this guide was built from.
set(UG_ENV
  "OPENMODELICAHOME=${OM_USERSGUIDE_OMHOME}"
  "OPENMODELICA_SOURCE_ROOT=${CMAKE_CURRENT_SOURCE_DIR}/../..")

## Inputs generated from the OpenModelica being documented ##########################################

# Everything below is regenerated on every build. Each step is a couple of
# seconds, and it is the only way to be sure the guide describes the omc that is
# installed right now rather than whatever an earlier build left behind.
add_custom_target(usersguide-prepare
  # A copy of the documentation sources to generate into, so a doc build never
  # writes into the working tree.
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${CMAKE_CURRENT_SOURCE_DIR}/source" "${UG_SOURCE}"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${UG_WORKDIR}/tmp" "${UG_BUILD}/html"

  # The bibliography, with the crossref entries inlined for sphinxcontrib-bibtex.
  COMMAND ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/resolve-crossref.py"
          "${CMAKE_CURRENT_SOURCE_DIR}/../bibliography/openmodelica.bib"
          "${UG_SOURCE}/openmodelica.bib"

  # The scripting API reference, from omc's builtin class definitions.
  COMMAND ${CMAKE_COMMAND} -E env ${UG_ENV}
          "${OM_USERSGUIDE_OMC}" -g=MetaModelica -d=nogen
          "${CMAKE_CURRENT_SOURCE_DIR}/interface.mos"
  COMMAND ${CMAKE_COMMAND} -E rename "${UG_WORKDIR}/interface.inc" "${UG_SOURCE}/interface.inc"

  # The simulation flags and the omc command line reference.
  COMMAND ${CMAKE_COMMAND} -DOMC=${OM_USERSGUIDE_OMC} -DFLAG=+help=simulation-sphinxoutput
          -DOUTPUT=${UG_SOURCE}/simoptions.inc
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/omc_help_to_file.cmake"
  COMMAND ${CMAKE_COMMAND} -DOMC=${OM_USERSGUIDE_OMC} -DFLAG=+help=omcall-sphinxoutput
          -DOUTPUT=${UG_SOURCE}/omchelptext.rst
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/omc_help_to_file.cmake"

  # The OMSimulator chapter: generate its includes into our copy, so the
  # submodule is left untouched, then put them where omsimulator.rst expects.
  COMMAND ${CMAKE_COMMAND} -E copy_directory
          "${UG_OMSIMULATOR_SOURCE}" "${UG_SOURCE}/omsimulator"
  COMMAND ${CMAKE_COMMAND} -E chdir "${UG_SOURCE}/omsimulator"
          ${Python3_EXECUTABLE} conf.py
  COMMAND ${CMAKE_COMMAND} -DOMSIMULATOR=${OM_USERSGUIDE_OMSIMULATOR} -DSOURCE=${UG_SOURCE}
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/stage_omsimulator.cmake"

  WORKING_DIRECTORY "${UG_WORKDIR}"
  COMMENT "Generating the User's Guide inputs from ${OM_USERSGUIDE_OMHOME}"
  VERBATIM)

## Release notes ####################################################################################

# The appendix of release notes comes from the GitHub API rather than from the
# OpenModelica being documented, so unlike everything above it does not go stale
# when omc is rebuilt, and there is no reason to spend a network round trip (and
# a share of the API rate limit) on it every time. It is regenerated when the
# script that reads it changes, or on demand:
#
#   cmake --build <dir> --target usersguide-releases
add_custom_command(
  OUTPUT "${UG_SOURCE}/githubreleases.rst"
  COMMAND ${CMAKE_COMMAND} -E make_directory "${UG_SOURCE}"
  COMMAND ${CMAKE_COMMAND} -E chdir "${UG_SOURCE}"
          ${Python3_EXECUTABLE} "${CMAKE_CURRENT_SOURCE_DIR}/source/githubreleases.py"
  DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/source/githubreleases.py"
          "${CMAKE_CURRENT_SOURCE_DIR}/source/tracreleases.inc"
  COMMENT "Reading the OpenModelica release notes from GitHub"
  VERBATIM)

add_custom_target(usersguide-releases DEPENDS "${UG_SOURCE}/githubreleases.rst")

## Figures ##########################################################################################

# The icons OMEdit and OMOptim ship, and the diagrams that are kept as SVG.
set(UG_OMEDIT_ICONS
  connect-mode transition-mode parametric-plot-window plot-window
  array-parametric-plot-window array-plot-window re-simulate interface-data
  simulation-parameters)

add_custom_target(usersguide-figures
  COMMAND ${CMAKE_COMMAND}
          -DINKSCAPE=${INKSCAPE_EXECUTABLE}
          -DSOURCE=${UG_SOURCE}
          -DOMEDIT_ICONS_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../../OMEdit/OMEditLIB/Resources/icons
          -DOMOPTIM_ICONS_DIR=${CMAKE_CURRENT_SOURCE_DIR}/../../OMOptim/OMOptim/GUI/Resources/icons
          "-DOMEDIT_ICONS=${UG_OMEDIT_ICONS}"
          -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/render_figures.cmake"
  COMMENT "Rendering the User's Guide figures"
  VERBATIM)

add_dependencies(usersguide-figures usersguide-prepare)

## The guide ########################################################################################

# -t nomathjax renders the maths with imgmath instead of loading MathJax from a
# CDN, so the published guide works offline.
add_custom_target(usersguide
  DEPENDS "${UG_SOURCE}/githubreleases.rst"
  COMMAND ${CMAKE_COMMAND} -E env ${UG_ENV}
          "${SPHINX_BUILD_EXECUTABLE}" -b html -t nomathjax
          -d "${UG_BUILD}/doctrees" "${UG_SOURCE}" "${UG_BUILD}/html"
  # Sphinx signs off with the output directory relative to where it ran, which
  # is not somewhere the reader of a build log has any reason to know about.
  COMMAND ${CMAKE_COMMAND} -E echo "User's Guide: ${UG_BUILD}/html/index.html"
  WORKING_DIRECTORY "${UG_WORKDIR}"
  COMMENT "Building the OpenModelica User's Guide"
  VERBATIM)

add_dependencies(usersguide usersguide-figures)

## The guide as an EPUB #############################################################################

# Published alongside the HTML for offline reading. Same options as the HTML
# build: the EPUB has no MathJax to load either.
add_custom_target(usersguide-epub
  DEPENDS "${UG_SOURCE}/githubreleases.rst"
  COMMAND ${CMAKE_COMMAND} -E env ${UG_ENV}
          "${SPHINX_BUILD_EXECUTABLE}" -b epub -t nomathjax
          -d "${UG_BUILD}/doctrees-epub" "${UG_SOURCE}" "${UG_BUILD}/epub"
  COMMAND ${CMAKE_COMMAND} -E echo
          "User's Guide: ${UG_BUILD}/epub/OpenModelicaUsersGuide.epub"
  WORKING_DIRECTORY "${UG_WORKDIR}"
  COMMENT "Building the OpenModelica User's Guide as EPUB"
  VERBATIM)

add_dependencies(usersguide-epub usersguide-figures)

## The guide as a PDF ###############################################################################

# Not part of 'usersguide': it needs a LaTeX installation on top of everything
# else, and runs the whole guide -- every example, every simulation -- a second
# time, because the LaTeX builder needs its own pass over the sources.
find_program(LATEXMK_EXECUTABLE NAMES latexmk)

if(LATEXMK_EXECUTABLE)
  add_custom_target(usersguide-latex
    DEPENDS "${UG_SOURCE}/githubreleases.rst"
    COMMAND ${CMAKE_COMMAND} -E env ${UG_ENV}
            "${SPHINX_BUILD_EXECUTABLE}" -b latex
            -d "${UG_BUILD}/doctrees-latex" "${UG_SOURCE}" "${UG_BUILD}/latex"
    COMMAND ${CMAKE_COMMAND} -E echo "User's Guide LaTeX sources: ${UG_BUILD}/latex"
    WORKING_DIRECTORY "${UG_WORKDIR}"
    COMMENT "Generating the LaTeX sources of the OpenModelica User's Guide"
    VERBATIM)

  add_dependencies(usersguide-latex usersguide-figures)

  add_custom_target(usersguide-pdf
    COMMAND ${CMAKE_COMMAND} -DINKSCAPE=${INKSCAPE_EXECUTABLE} -DSOURCE=${UG_SOURCE}
            -DLATEX_DIR=${UG_BUILD}/latex
            -P "${CMAKE_CURRENT_SOURCE_DIR}/cmake/prepare_latex.cmake"
    COMMAND ${CMAKE_COMMAND} -E chdir "${UG_BUILD}/latex"
            "${LATEXMK_EXECUTABLE}" -pdf OpenModelicaUsersGuide.tex
    COMMAND ${CMAKE_COMMAND} -E echo
            "User's Guide: ${UG_BUILD}/latex/OpenModelicaUsersGuide.pdf"
    COMMENT "Compiling the OpenModelica User's Guide to PDF"
    VERBATIM)

  add_dependencies(usersguide-pdf usersguide-latex)
else()
  message(STATUS "User's Guide: latexmk not found, the 'usersguide-pdf' target is unavailable")
endif()

## Installation #####################################################################################

install(DIRECTORY "${OM_USERSGUIDE_HTML_DIR}/"
        DESTINATION "${CMAKE_INSTALL_DOCDIR}/UsersGuide/html"
        COMPONENT doc
        OPTIONAL
        PATTERN ".doctrees" EXCLUDE
        PATTERN ".buildinfo" EXCLUDE)

install(FILES "${UG_BUILD}/latex/OpenModelicaUsersGuide.pdf"
              "${UG_BUILD}/epub/OpenModelicaUsersGuide.epub"
        DESTINATION "${CMAKE_INSTALL_DOCDIR}/UsersGuide"
        COMPONENT doc
        OPTIONAL)
