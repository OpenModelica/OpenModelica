omc_add_subdirectory(difftool)
omc_add_subdirectory(ReferenceFiles)
omc_add_subdirectory(CTest
  EXCLUDE_FROM_ALL
)

add_custom_target(testsuite-depends
                    DEPENDS omc-diff
                    DEPENDS libs-for-testing
                    DEPENDS reference-files)
