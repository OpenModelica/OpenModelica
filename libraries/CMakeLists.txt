

set(STAMP 20200610130629.stamp)

# Note that omc needs to be built and INSTALLED before you can add the libs for testing.
# The reason being omc needs to be ina folder **/bin to work. Otherwise it will refuse to run
# Plus it needs to know where find the shared libs it needs. That is structured to work for install.
add_custom_target(libs-for-testing
            COMMAND ${CMAKE_COMMAND} -E remove_directory .openmodelica/libraries
            COMMAND ${CMAKE_COMMAND} -E make_directory .openmodelica/libraries
            COMMAND ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/omc index.mos

            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )
