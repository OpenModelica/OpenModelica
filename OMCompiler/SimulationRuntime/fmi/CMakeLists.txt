## I am not sure if more is needed here
## This needs to be completely fixed. the files should be moved out of
## SimulationRuntime/fmi and to SimulationRuntime/c/fmi or the other way
## around. As it is now it is not really consistent.
## This is just imitating the Makefiles for now.

omc_add_subdirectory(export/buildproject)


file(GLOB FMI_OPENMODELICA_EXPORT_FILES ${CMAKE_CURRENT_SOURCE_DIR}/export/openmodelica/*)

install(FILES ${FMI_OPENMODELICA_EXPORT_FILES}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/fmi-export/
)

file(GLOB FMI_EXPORT_FILES ${CMAKE_CURRENT_SOURCE_DIR}/export/fmi/*)

install(FILES ${FMI_EXPORT_FILES}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/c/fmi/
)
