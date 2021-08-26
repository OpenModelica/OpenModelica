## I am not sure if more is needed here

omc_add_subdirectory(export/buildproject)

install(DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}/omc
        FILES_MATCHING
        PATTERN "*.h"
        PATTERN "*.c.inc"
        PATTERN "buildproject" EXCLUDE
)
