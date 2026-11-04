find_package(Python3 COMPONENTS Interpreter REQUIRED)
set(INIT_BIN_DIR ${CMAKE_CURRENT_BINARY_DIR}/resources)
file(MAKE_DIRECTORY ${INIT_BIN_DIR})
set(INIT_BIN_FILES ${INIT_BIN_DIR}/01_RealArrayVariable_init.bin
                   ${INIT_BIN_DIR}/02_RealMatrixVariable_init.bin
                   ${INIT_BIN_DIR}/03_IntTensorVariable_init.bin)
add_custom_command(
  OUTPUT ${INIT_BIN_FILES}
  COMMAND ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/resources/make_init_bin.py
  WORKING_DIRECTORY ${INIT_BIN_DIR}
  DEPENDS ${CMAKE_CURRENT_SOURCE_DIR}/resources/make_init_bin.py
  COMMENT "Writing the init.bin test inputs")
add_custom_target(read_input_init_bin DEPENDS ${INIT_BIN_FILES})

# Test 1
add_executable(test_read_array_input_xml
  01_test_read_array_input_xml.c
)
target_link_libraries(test_read_array_input_xml PRIVATE SimulationRuntimeC)
add_dependencies(test_read_array_input_xml read_input_init_bin)
add_test(NAME test_read_array_input_xml COMMAND test_read_array_input_xml ${INIT_BIN_DIR}/01_RealArrayVariable_init.bin)

# Test 2
add_executable(test_read_matrix_input_xml
  02_test_read_matrix_input_xml.c
)
target_link_libraries(test_read_matrix_input_xml PRIVATE SimulationRuntimeC)
add_dependencies(test_read_matrix_input_xml read_input_init_bin)
add_test(NAME test_read_matrix_input_xml COMMAND test_read_matrix_input_xml ${INIT_BIN_DIR}/02_RealMatrixVariable_init.bin)

# Test 3
add_executable(test_read_tensor_input_xml
  03_test_read_tensor_input_xml.c
)
target_link_libraries(test_read_tensor_input_xml PRIVATE SimulationRuntimeC)
add_dependencies(test_read_tensor_input_xml read_input_init_bin)
add_test(NAME test_read_tensor_input_xml COMMAND test_read_tensor_input_xml ${INIT_BIN_DIR}/03_IntTensorVariable_init.bin)

add_custom_target(ctestsuite-simulation-inputXML-read_input_xml DEPENDS
  test_read_array_input_xml
  test_read_matrix_input_xml
  test_read_tensor_input_xml
)
