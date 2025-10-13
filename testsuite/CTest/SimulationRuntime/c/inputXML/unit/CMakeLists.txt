# Test 1
add_executable(test_read_array_input_xml
  01_test_read_array_input_xml.c
)
target_link_libraries(test_read_array_input_xml PRIVATE SimulationRuntimeC)
file(REAL_PATH 01_RealArrayVariable_init.xml TEST_REAL_ARRAY_XML BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/resources)
add_test(NAME test_read_array_input_xml COMMAND test_read_array_input_xml ${TEST_REAL_ARRAY_XML})

# Test 2
add_executable(test_read_matrix_input_xml
  02_test_read_matrix_input_xml.c
)
target_link_libraries(test_read_matrix_input_xml PRIVATE SimulationRuntimeC)
file(REAL_PATH 02_RealMatrixVariable_init.xml TEST_REAL_MATRIX_XML BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/resources)
add_test(NAME test_read_matrix_input_xml COMMAND test_read_matrix_input_xml ${TEST_REAL_MATRIX_XML})

# Test 3
add_executable(test_read_tensor_input_xml
  03_test_read_tensor_input_xml.c
)
target_link_libraries(test_read_tensor_input_xml PRIVATE SimulationRuntimeC)
file(REAL_PATH 03_IntTensorVariable_init.xml TEST_REAL_MATRIX_XML BASE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/resources)
add_test(NAME test_read_tensor_input_xml COMMAND test_read_tensor_input_xml ${TEST_REAL_MATRIX_XML})

add_custom_target(ctestsuite-inputXML-unit DEPENDS
  test_read_array_input_xml
  test_read_matrix_input_xml
  test_read_tensor_input_xml
)
