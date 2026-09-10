# The system documentation that is shipped as-is.
#
# These four are the current form of their respective documents; the .doc files
# next to them are the sources they were written from and are not installed.
install(FILES
          ModelicaTutorialFritzson.pdf
          OpenModelicaMetaProgramming.pdf
          OpenModelicaSystem.pdf
          OpenModelicaTemplateProgramming.pdf
        DESTINATION ${CMAKE_INSTALL_DOCDIR}
        COMPONENT doc)

if(OM_ENABLE_DOCS)
  omc_add_subdirectory(UsersGuide)
endif()
