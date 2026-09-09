# The system documentation that is shipped as-is.
#
# These four are the current form of their respective documents; the .doc files
# next to them are the sources they were written from and are not installed.
# OpenModelicaUsersGuide.pdf is deliberately not in this list: it is the 2015
# edition of the User's Guide and has been superseded by the Sphinx one below,
# which is generated from the compiler that is actually being built.
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
