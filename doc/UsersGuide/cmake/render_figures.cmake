# Render the figures of the User's Guide.
#
# The GUI icons are taken from the clients themselves so that the guide always
# shows the buttons OMEdit actually has, and the diagrams are kept as SVG in the
# source tree. Sphinx picks the format it needs from `media/<name>.*`, so each
# SVG is rasterised to PNG for HTML and converted to PDF for LaTeX.
#
# Usage: cmake -DINKSCAPE=<inkscape> -DSOURCE=<staged source dir>
#              -DOMEDIT_ICONS_DIR=<dir> -DOMOPTIM_ICONS_DIR=<dir>
#              "-DOMEDIT_ICONS=<name;name;...>" -P render_figures.cmake

function(convert input output)
  execute_process(
    COMMAND "${INKSCAPE}" "${input}" --export-filename=${output}
    RESULT_VARIABLE result
    OUTPUT_QUIET
    ERROR_VARIABLE stderr)
  if(NOT result EQUAL 0)
    message(FATAL_ERROR "inkscape failed to convert ${input} (${result}): ${stderr}")
  endif()
endfunction()

file(MAKE_DIRECTORY "${SOURCE}/media/omedit-icons")
file(MAKE_DIRECTORY "${SOURCE}/media/omoptim-icons")

foreach(icon IN LISTS OMEDIT_ICONS)
  set(svg "${SOURCE}/media/omedit-icons/${icon}.svg")
  file(COPY "${OMEDIT_ICONS_DIR}/${icon}.svg" DESTINATION "${SOURCE}/media/omedit-icons")
  convert("${svg}" "${SOURCE}/media/omedit-icons/${icon}.png")
  convert("${svg}" "${SOURCE}/media/omedit-icons/${icon}.pdf")
endforeach()

# Icons that OMEdit ships as PNG have nothing to convert.
file(COPY "${OMEDIT_ICONS_DIR}/modeling.png" DESTINATION "${SOURCE}/media/omedit-icons")

file(COPY "${OMOPTIM_ICONS_DIR}/Add.png" DESTINATION "${SOURCE}/media/omoptim-icons")

foreach(figure systemoverview mdt-create-project mdt-build-prompt)
  convert("${SOURCE}/media/${figure}.svg" "${SOURCE}/media/${figure}.png")
endforeach()

convert("${SOURCE}/media/mathematica-notebooks.svg" "${SOURCE}/media/mathematica-notebooks.pdf")

# Only the LaTeX title page uses this one.
convert("${SOURCE}/logo.svg" "${SOURCE}/logo.pdf")
