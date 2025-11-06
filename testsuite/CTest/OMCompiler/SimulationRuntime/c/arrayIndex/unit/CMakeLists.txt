set(TEST_SOURCES
  01_test_array_length_scalar.cpp
  02_test_array_length_vector.cpp
  03_test_array_length_matrix.cpp
  04_test_compute_var_index.cpp
  05_test_calc_index_matrix.cpp
  06_test_calc_index_tensor.cpp
)

# Add tests to ctestsuite dependencies
add_custom_target(ctestsuite-arrayIndex-unit)

foreach(TEST_SRC IN LISTS TEST_SOURCES)
  get_filename_component(TEST_NAME ${TEST_SRC} NAME_WE)

  add_executable(${TEST_NAME} ${TEST_SRC})
  target_link_libraries(${TEST_NAME}
    PRIVATE omc::simrt::simruntime
    PRIVATE GTest::gtest_main
  )
  gtest_discover_tests(${TEST_NAME})
  add_dependencies(ctestsuite-arrayIndex-unit ${TEST_NAME})
endforeach()
