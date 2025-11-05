# Test 1
add_executable(test_read_array_var_real
  01_test_read_array_var_real.c
)
target_link_libraries(test_read_array_var_real PRIVATE SimulationRuntimeC)
add_test(NAME test_read_array_var_real COMMAND test_read_array_var_real)

add_custom_target(ctestsuite-simulation-inputXML-unit DEPENDS
  test_read_array_var_real
)
