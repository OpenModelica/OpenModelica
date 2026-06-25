# The LLVM-JIT simulation test exercises the -d=jitSimulate path, which only
# exists when omc was built with OM_OMC_ENABLE_LLVM. Register it with CTest
# (run through the testsuite's rtest driver) only in that case, so a default
# build does not run a test the binary cannot satisfy.
if(OM_OMC_ENABLE_LLVM)
  add_test(
    NAME llvm-jit-simulate
    COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../../rtest -v jitSimulate.mos
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
  set_tests_properties(llvm-jit-simulate PROPERTIES LABELS "llvm-jit;simulation")
endif()
