# Test 1
add_executable(test_same_time_large_time
  01_test_same_time_large_time.c
)
target_link_libraries(test_same_time_large_time PRIVATE SimulationRuntimeC)
add_test(NAME test_same_time_large_time COMMAND test_same_time_large_time)

add_custom_target(ctestsuite-simulation-solver-nonlinearValuesList DEPENDS
  test_same_time_large_time
)
