

omc_add_subdirectory(difftool)
omc_add_subdirectory(ReferenceFiles)
omc_add_subdirectory(libraries-for-testing)


add_custom_target(testsuite-depends
                    DEPENDS omc-diff
                    DEPENDS libs-for-testing
                    DEPENDS reference-files)
