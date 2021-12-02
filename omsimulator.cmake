

include(ExternalProject)
include(ProcessorCount)
ProcessorCount(NUM_PROCESSPRS)


ExternalProject_Add(OMSimulator_external
    SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
    PREFIX OMSimulator
    #--Configure step-------------
    CONFIGURE_COMMAND COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                config-3rdParty
                                                CERES=OFF
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
                      COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                config-OMSimulator
                                                OMSYSIDENT=OFF
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
    #--Build step-----------------
    BUILD_COMMAND COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                OMSimulator
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
    #--Install step---------------
    INSTALL_COMMAND ""
)

set_target_properties(OMSimulator_external PROPERTIES EXCLUDE_FROM_ALL TRUE)


add_library(libOMSimulator SHARED IMPORTED)
set_target_properties(libOMSimulator PROPERTIES
  IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/x86_64-linux-gnu/omc/libOMSimulator.so
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator/src/OMSimulatorLib
)

add_dependencies(libOMSimulator OMSimulator_external)


install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/
        DESTINATION ${CMAKE_INSTALL_PREFIX}
        USE_SOURCE_PERMISSIONS
        # Exclude the directories created by CMake's ExternalProject
        PATTERN src EXCLUDE
        PATTERN tmp EXCLUDE)
