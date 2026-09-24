# Every file here but this one, as the autotools build's `cp -p Examples/*.*`.
file(GLOB DOCS LIST_DIRECTORIES false "*.*")
list(FILTER DOCS EXCLUDE REGEX "/CMakeLists\\.txt$")
# The glob matches dot files too; lintian reports a .gitignore as package-contains-vcs-control-file.
list(FILTER DOCS EXCLUDE REGEX "/\\.gitignore$")
install(FILES ${DOCS} DESTINATION "share/doc/omc/testmodels")
