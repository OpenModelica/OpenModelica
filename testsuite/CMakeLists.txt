omc_add_subdirectory(difftool)
omc_add_subdirectory(ReferenceFiles)

add_custom_target(ffi-test-lib
  COMMAND make -C ${CMAKE_CURRENT_SOURCE_DIR}/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc)

add_custom_target(testsuite-depends
  DEPENDS ffi-test-lib
  DEPENDS libs-for-testing
  DEPENDS omc-diff
  DEPENDS reference-files)
