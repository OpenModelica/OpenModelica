# Every file here but this one, as the autotools build's `cp -p Examples/*.*`.
file(GLOB DOCS LIST_DIRECTORIES false "*.*")
list(FILTER DOCS EXCLUDE REGEX "/CMakeLists\\.txt$")
install(FILES ${DOCS} DESTINATION "share/doc/omc/testmodels")
