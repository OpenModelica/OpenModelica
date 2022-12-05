

set(STAMP 20221102135323.stamp)

# Note that omc needs to be built and INSTALLED before you can add the libs for testing.
# The reason being omc needs to be in a folder **/bin to work. Otherwise it will refuse to run
# Plus it needs to know where find the shared libs it needs. That is structured to work for install.
set(LIBS_DIR_FOR_TESTING ${CMAKE_CURRENT_SOURCE_DIR}/.openmodelica/libraries)
add_custom_target(libs-for-testing
            COMMAND ${CMAKE_COMMAND} -E remove_directory ${LIBS_DIR_FOR_TESTING}
            COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBS_DIR_FOR_TESTING}
            COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/index.json ${LIBS_DIR_FOR_TESTING}
            COMMAND ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/omc index.mos

            WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        )


## Disabled until we figure out how to properly handle this for packaging.

# # Note that omc needs to be built and INSTALLED before you can add the libs for testing.
# # The reason being omc needs to be in a folder **/bin to work. Otherwise it will refuse to run
# # Plus it needs to know where find the shared libs it needs. That is structured to work for install.
# set(LIBS_DIR_FOR_INSTALLER ${CMAKE_CURRENT_SOURCE_DIR}/.openmodelica/libraries)
# add_custom_target(libs-for-installer
#             COMMAND ${CMAKE_COMMAND} -E remove_directory ${LIBS_DIR_FOR_INSTALLER}
#             COMMAND ${CMAKE_COMMAND} -E make_directory ${LIBS_DIR_FOR_INSTALLER}
#             COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_CURRENT_SOURCE_DIR}/install-index.json ${LIBS_DIR_FOR_INSTALLER}
#             COMMAND ${CMAKE_INSTALL_PREFIX}/${CMAKE_INSTALL_BINDIR}/omc ../index.mos

#             WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/installing
#         )
