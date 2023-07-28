
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME omsimulator)


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
                                                OMTLM=OFF
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE="${CMAKE_COMMAND}"
                      COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                config-OMSimulator
                                                OMTLM=OFF
                                                BUILD_TYPE=${CMAKE_BUILD_TYPE}
                                                OMSYSIDENT=OFF
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE="${CMAKE_COMMAND}"
    #--Build step-----------------
    BUILD_ALWAYS 1
    BUILD_COMMAND COMMAND ${CMAKE_MAKE_PROGRAM} -C ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator
                                                -j${NUM_PROCESSPRS}
                                                OMSimulator
                                                OMTLM=OFF
                                                BUILD_TYPE=${CMAKE_BUILD_TYPE}
                                                OMBUILDDIR=${CMAKE_CURRENT_BINARY_DIR}/OMSimulator
                                                host_short=${CMAKE_LIBRARY_ARCHITECTURE}
                                                CMAKE="${CMAKE_COMMAND}"
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

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/bin/
          DESTINATION ${CMAKE_INSTALL_BINDIR}
          # There is a libOMSimulator.dll.a in the bin dir. It should go in lib.
          PATTERN *.dll.a EXCLUDE)


  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/include/
          DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/
          DESTINATION ${CMAKE_INSTALL_LIBDIR})

  # There is a libOMSimulator.dll.a in the bin dir. It should go in lib.
  install(FILES ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/bin/libOMSimulator.dll.a
          DESTINATION ${CMAKE_INSTALL_LIBDIR})

  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/share/
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR})

elseif(MSVC)
  # For now print error and bail out. It should be the same as Mingw except we need to check where the .lib file is located.
  message(FATAL_ERROR "Importing of OMSimulator is not implemented correctly for MSVC. Adjust the MINGW implementation to where the dll and lib files are expected.")
else()

  # if host_short (= CMAKE_LIBRARY_ARCHITECTURE) is empty (e.g on Arch Linux systems or macOS), OMSimulator does not
  # add the omc/ part to the library location. (See OMSimulator/Makefile:88-93)
  if(CMAKE_LIBRARY_ARCHITECTURE)
    set(OMSIMULATORLIB_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/${CMAKE_LIBRARY_ARCHITECTURE}/omc/)
  else()
    set(OMSIMULATORLIB_LOCATION ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/)
  endif()

  set(LIB_OMSIMULATOR_NAME ${CMAKE_SHARED_LIBRARY_PREFIX}OMSimulator${CMAKE_SHARED_LIBRARY_SUFFIX})

  set_target_properties(libOMSimulator PROPERTIES
    IMPORTED_LOCATION ${OMSIMULATORLIB_LOCATION}/${LIB_OMSIMULATOR_NAME}
  )


  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/bin/
          DESTINATION ${CMAKE_INSTALL_BINDIR}
          USE_SOURCE_PERMISSIONS)


  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/include/
          DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

  install(DIRECTORY ${OMSIMULATORLIB_LOCATION}
          DESTINATION ${CMAKE_INSTALL_LIBDIR})

  # There is another folder called OMSimulator inside the lib (just lib/ not lib/<arch>/..) folder that
  # contains some python files as well some duplicate shared libs.
  # I am guessing the python files are expected to be in <actual_lib_dir>/OMSimulator/.
  # So copy them there (only the python files though. No point in having duplicate shared libs)
  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/lib/OMSimulator/
          DESTINATION ${CMAKE_INSTALL_LIBDIR}/OMSimulator
          FILES_MATCHING
            PATTERN "*.py"
            # # if ${CMAKE_LIBRARY_ARCHITECTURE} is not an empty string OMSimulator will create a dedicated
            # # folder for the shared libs. We have excluded them with the *.py pattern so avoid creating the
            # # empty directory on install.
            ## Unfortunately, when it is actually empty this will result in an invalid CMake command.
            # PATTERN ${CMAKE_LIBRARY_ARCHITECTURE} EXCLUDE
          )


  install(DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}/OMSimulator/share/
          DESTINATION ${CMAKE_INSTALL_DATAROOTDIR})


endif()

set_target_properties(libOMSimulator PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_CURRENT_SOURCE_DIR}/OMSimulator/src/OMSimulatorLib
)
