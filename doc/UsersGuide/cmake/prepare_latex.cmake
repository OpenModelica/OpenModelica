# Prepare the LaTeX that sphinx-build produced for latexmk.
#
# Two things are missing from it:
#
#  * The profiler chapter publishes its flame graphs as SVG, which pdflatex
#    cannot include. They only exist once the guide has been built, so they are
#    converted here rather than with the rest of the figures. Sphinx refers to
#    the thumbnails by a name in which the dots have become dashes, so each one
#    is also copied under that name.
#
#  * Sphinx writes image references as `media/<name>.*` and leaves picking an
#    extension to LaTeX, which does not do it, and it declares every non-ASCII
#    character it saw with \DeclareUnicodeCharacter on top of inputenc's own
#    definitions. Point the references at the PDFs and let utf8x handle the
#    characters.
#
# Usage: cmake -DINKSCAPE=<inkscape> -DSOURCE=<staged source dir>
#              -DLATEX_DIR=<sphinx latex output> -P prepare_latex.cmake

file(GLOB profiling_svgs "${SOURCE}/ProfilingTest_*.svg")

foreach(svg IN LISTS profiling_svgs)
  string(REGEX REPLACE "[.]svg$" ".pdf" pdf "${svg}")
  execute_process(
    COMMAND "${INKSCAPE}" "${svg}" --export-filename=${pdf}
    RESULT_VARIABLE result
    OUTPUT_QUIET
    ERROR_VARIABLE stderr)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "inkscape failed to convert ${svg} (${result}): ${stderr}")
  endif()

  # ProfilingTest_prof.999.thumb.pdf is also needed as
  # ProfilingTest_prof-999-thumb.pdf.
  get_filename_component(name "${pdf}" NAME)
  string(REPLACE "." "-" dashed "${name}")
  string(REGEX REPLACE "-pdf$" ".pdf" dashed "${dashed}")
  if(NOT dashed STREQUAL name)
    configure_file("${pdf}" "${SOURCE}/${dashed}" COPYONLY)
  endif()
endforeach()

file(GLOB profiling_pdfs "${SOURCE}/ProfilingTest_*.pdf")
if(profiling_pdfs)
  file(COPY ${profiling_pdfs} DESTINATION "${LATEX_DIR}")
endif()

set(tex "${LATEX_DIR}/OpenModelicaUsersGuide.tex")
file(READ "${tex}" content)

string(REPLACE "\\usepackage[utf8]{inputenc}" "\\usepackage[utf8x]{inputenc}" content "${content}")
string(REGEX REPLACE "\n[ ]*\\\\DeclareUnicodeCharacter[^\n]*" "" content "${content}")
string(REGEX REPLACE "{(media/[A-Za-z_0-9.-]*)[.][*]" "{${SOURCE}/\\1.pdf" content "${content}")
string(REGEX REPLACE "{ProfilingTest_prof[.]([^.]*)[.]thumb}[.]svg"
                     "{${SOURCE}/ProfilingTest_prof-\\1-thumb}.pdf" content "${content}")

file(WRITE "${tex}" "${content}")
