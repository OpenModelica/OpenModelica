

## This is not tested very well. Will be updated as we go.

if(NOT WIN32)
execute_process(COMMAND autoconf
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  RESULT_VARIABLE AUTOCONF_FOR_FMU_EXIT_STATUS
  OUTPUT_VARIABLE AUTOCONF_FOR_FMU_OUTPUT
  ERROR_VARIABLE AUTOCONF_FOR_FMU_ERROR
  #   OUTPUT_QUIET
)

if(AUTOCONF_FOR_FMU_EXIT_STATUS AND NOT AUTOCONF_FOR_FMU_EXIT_STATUS EQUAL 0)
    message(STATUS ${AUTOCONF_FOR_FMU_EXIT_STATUS})
    message(STATUS ${AUTOCONF_FOR_FMU_OUTPUT})
    message(STATUS ${AUTOCONF_FOR_FMU_ERROR})
    message(FATAL_ERROR "autoconf failed configuring for FMUS.")
endif()

install(FILES configure
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/runtime/c/fmi/buildproject ## This should not be omc/runtime/c/fmi but rather omc/fmi. It is inconsistent
)

endif()
