# Test 1
add_executable(test_set_vars_to_start
  01_test_set_vars_to_start.c
)
target_link_libraries(test_set_vars_to_start PRIVATE SimulationRuntimeC)
add_test(NAME test_set_vars_to_start COMMAND test_set_vars_to_start)

add_custom_target(ctestsuite-simulation-solver-model_help DEPENDS
  test_set_vars_to_start
)
