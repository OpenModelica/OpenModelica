

## This is not tested very well. Will be updated as we go.

execute_process(COMMAND autoconf
  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
  RESULT_VARIABLE AUTOCONF_FOR_FMU_EXIT_STATUS
  OUTPUT_VARIABLE AUTOCONF_FOR_FMU_OUTPUT
  ERROR_VARIABLE AUTOCONF_FOR_FMU_OUTPUT
  #   OUTPUT_QUIET
)


if(NOT ${AUTOCONF_FOR_FMU_EXIT_STATUS} EQUAL "0")
    message(SEND_ERROR ${AUTOCONF_FOR_FMU_OUTPUT})
    message(FATAL_ERROR "autoconf failed configuring for FMUS.")
endif()

install(FILES configure
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/runtime/c/fmi/buildproject ## This should not be omc/runtime/c/fmi but rather omc/fmi. It is inconsistent
)
