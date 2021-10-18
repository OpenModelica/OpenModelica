
# message(FATAL_ERROR "${CMAKE_LIBRARY_ARCHITECTURE}")

add_custom_target(omsimulator
                  COMMAND ${CMAKE_MAKE_PROGRAM} config-3rdParty
                                                CERES=OFF
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}

                  COMMAND ${CMAKE_MAKE_PROGRAM} config-OMSimulator
                                                OMSYSIDENT=OFF
                                                OMBUILDDIR=${CMAKE_INSTALL_PREFIX}
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}

                  COMMAND ${CMAKE_MAKE_PROGRAM} OMSimulator
                                                OMBUILDDIR=${CMAKE_INSTALL_PREFIX}
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}

                  WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator)

