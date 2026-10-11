# Every file here but this one, as the autotools build's `cp -p Examples/*.*`.
file(GLOB DOCS LIST_DIRECTORIES false "*.*")
list(FILTER DOCS EXCLUDE REGEX "/CMakeLists\\.txt$")
install(FILES ${DOCS} DESTINATION "share/doc/omc/testmodels")
# The tutorial libraries (Debugging.mo, ...) from the ModelicaTutorial submodule,
# next to the other test models. Empty when the submodule is not checked out.
file(GLOB TUTORIAL_LIBS LIST_DIRECTORIES false "ModelicaTutorial/*.mo")
if(TUTORIAL_LIBS)
  install(FILES ${TUTORIAL_LIBS} DESTINATION "share/doc/omc/testmodels")
endif()
