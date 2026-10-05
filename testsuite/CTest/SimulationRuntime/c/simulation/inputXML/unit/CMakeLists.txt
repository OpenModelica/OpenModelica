# Test 1
add_executable(test_read_array_var_real
  01_test_read_array_var_real.c
)
target_link_libraries(test_read_array_var_real PRIVATE SimulationRuntimeC)
add_test(NAME test_read_array_var_real COMMAND test_read_array_var_real)

# Test 2
add_executable(test_read_array_var_integer
  02_test_read_array_var_integer.c
)
target_link_libraries(test_read_array_var_integer PRIVATE SimulationRuntimeC)
add_test(NAME test_read_array_var_integer COMMAND test_read_array_var_integer)

# Test 3
add_executable(test_read_array_var_boolean
  03_test_read_array_var_boolean.c
)
target_link_libraries(test_read_array_var_boolean PRIVATE SimulationRuntimeC)
add_test(NAME test_read_array_var_boolean COMMAND test_read_array_var_boolean)

# Test 4
add_executable(test_read_array_var_string
  04_test_read_array_var_string.c
)
target_link_libraries(test_read_array_var_string PRIVATE SimulationRuntimeC)
add_test(NAME test_read_array_var_string COMMAND test_read_array_var_string)

add_custom_target(ctestsuite-simulation-inputXML-unit DEPENDS
  test_read_array_var_real
  test_read_array_var_integer
  test_read_array_var_boolean
  test_read_array_var_string
)
