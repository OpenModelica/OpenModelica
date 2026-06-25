
omc_add_subdirectory(difftool)
omc_add_subdirectory(ReferenceFiles)

# LLVM-JIT simulation test. The CMakeLists.txt there registers the rtest-based
# test with CTest only when OM_OMC_ENABLE_LLVM_JIT is set, so it runs on
# LLVM-JIT-enabled builds and is a no-op otherwise.
omc_add_subdirectory(openmodelica/llvm-jit)

add_custom_target(ffi-test-lib
  COMMAND ${CMAKE_MAKE_PROGRAM} -j${CMAKE_BUILD_PARALLEL_LEVEL} -C ${CMAKE_CURRENT_SOURCE_DIR}/flattening/modelica/ffi/FFITest/Resources/BuildProjects/gcc)

add_custom_target(testsuite-depends
  DEPENDS ffi-test-lib
  DEPENDS libs-for-testing
  DEPENDS omc-diff
  DEPENDS reference-files)
