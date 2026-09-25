
# Install the CMakeLists.txt.in template used to (re)build source-code FMUs.
# This is the only build system supported for source-code FMUs.
install(FILES ${CMAKE_CURRENT_SOURCE_DIR}/CMakeLists.txt.in
        ## This should not be omc/runtime/c/fmi but rather omc/fmi. It is inconsistent
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omc/runtime/c/fmi/buildproject
)
