# cmake/omc_spellcheck.cmake
#
# Adds a 'spellcheck' target that checks spelling of gettext strings in the
# Modelica compiler sources using aspell and the personal word list
# .openmodelica.aspell in the root of the repository.
#
# Run with:
#   cmake --build <build_dir> --target spellcheck

find_program(ASPELL aspell)

if(ASPELL)
  add_custom_target(spellcheck
    COMMAND bash ${CMAKE_SOURCE_DIR}/cmake/spellcheck.sh ${CMAKE_SOURCE_DIR} ${ASPELL}
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMENT "Running aspell spellcheck on gettext strings in Modelica compiler sources"
    USES_TERMINAL
  )
else()
  add_custom_target(spellcheck
    COMMAND ${CMAKE_COMMAND} -E echo
      "WARNING: aspell not found. Install aspell to enable spellchecking."
    COMMENT "aspell not found, spellcheck target is a no-op"
  )
  message(STATUS "aspell not found. The 'spellcheck' target will be a no-op. "
    "Install aspell to enable spellchecking.")
endif()
