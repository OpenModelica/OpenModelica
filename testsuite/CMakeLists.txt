omc_add_subdirectory(difftool)
omc_add_subdirectory(ReferenceFiles)

add_custom_target(testsuite-depends
                    DEPENDS omc-diff
                    DEPENDS libs-for-testing
                    DEPENDS reference-files)
