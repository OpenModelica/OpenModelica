# The LLVM-JIT simulation tests exercise the -d=jitSimulate path, which only
# exists when omc was built with OM_OMC_ENABLE_LLVM. Register them with CTest
# (run through the testsuite's rtest driver) only in that case, so a default
# build does not run tests the binary cannot satisfy. Each reuses a canonical
# testsuite model (HelloWorld, BouncingBall) and checks JIT vs C agreement.
if(OM_OMC_ENABLE_LLVM)
  foreach(_jit_test helloWorld bouncingBall)
    add_test(
      NAME llvm-jit-${_jit_test}
      COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/../../rtest -v ${_jit_test}.mos
      WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR})
    set_tests_properties(llvm-jit-${_jit_test} PROPERTIES LABELS "llvm-jit;simulation")
  endforeach()
endif()
