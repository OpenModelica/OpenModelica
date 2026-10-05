## Anything installed from this directory belongs to the install component 'drmodelica'.
set(CMAKE_INSTALL_DEFAULT_COMPONENT_NAME drmodelica)

install(DIRECTORY ./
        DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/omnotebook/drmodelica/
        FILES_MATCHING PATTERN "*.onb")
