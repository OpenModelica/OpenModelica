

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
                                                BUILD_TYPE=${CMAKE_BUILD_TYPE}
                                                CERES=OFF
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
                      COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                config-OMSimulator
                                                BUILD_TYPE=${CMAKE_BUILD_TYPE}
                                                OMSYSIDENT=OFF
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
    #--Build step-----------------
    BUILD_COMMAND COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                OMSimulator
                                                BUILD_TYPE=${CMAKE_BUILD_TYPE}
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE=${CMAKE_COMMAND}
    #--Install step---------------
    INSTALL_COMMAND ""
)

set_target_properties(OMSimulator_external PROPERTIES EXCLUDE_FROM_ALL TRUE)


add_library(libOMSimulator SHARED IMPORTED)
add_dependencies(libOMSimulator OMSimulator_external)

# The location where the lib is located and whether it comes with an import lib, depends on the OS/Env.
if(MINGW)
  set_target_properties(libOMSimulator PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/bin/libOMSimulator.dll
    # The dll.a import lib. It is located in the same dir as the dll right now.
    IMPORTED_IMPLIB ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/bin/libOMSimulator.dll.a
  )
elseif(MSVC)
  # For now print error and bail out. It should be the same as Mingw except we need to check where the .lib file is located.
  message(FATAL_ERROR "Importing of OMSimulator is not implemented correctly for MSVC. Adjust the MINGW implementation to where the dll and lib files are expected.")
else()
  set_target_properties(libOMSimulator PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/x86_64-linux-gnu/omc/libOMSimulator.so
  )
endif()

set_target_properties(libOMSimulator PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator/src/OMSimulatorLib
)



install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/
        DESTINATION ${CMAKE_INSTALL_PREFIX}
        USE_SOURCE_PERMISSIONS
        # Exclude the directories created by CMake's ExternalProject
        PATTERN src EXCLUDE
        PATTERN tmp EXCLUDE)
