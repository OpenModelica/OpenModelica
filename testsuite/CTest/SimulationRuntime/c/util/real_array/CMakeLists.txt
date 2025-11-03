# Test 1
add_executable(test_real_vector_to_string
  01_test_real_vector_to_string.c
)
target_link_libraries(test_real_vector_to_string PRIVATE SimulationRuntimeC)
add_test(NAME test_real_vector_to_string COMMAND test_real_vector_to_string)

add_custom_target(ctestsuite-util-real_array DEPENDS
  test_real_vector_to_string

)
