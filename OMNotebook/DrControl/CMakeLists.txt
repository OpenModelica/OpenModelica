## Anything installed from this directory belongs to the install component 'drcontrol'.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME drcontrol)

install(DIRECTORY ./
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/drcontrol/
        FILES_MATCHING PATTERN "*.onb")
