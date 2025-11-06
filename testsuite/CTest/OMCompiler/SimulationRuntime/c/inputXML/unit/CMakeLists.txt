set(TEST_SOURCES
  01_test_read_array_input_xml.cpp
  02_test_read_matrix_input_xml.cpp
  03_test_read_tensor_input_xml.cpp
)

# Add tests to ctestsuite dependencies
add_custom_target(ctestsuite-inputXML-unit)

foreach(TEST_SRC IN LISTS TEST_SOURCES)
  get_filename_component(TEST_NAME ${TEST_SRC} NAME_WE)

  add_executable(${TEST_NAME} ${TEST_SRC})
  target_link_libraries(${TEST_NAME}
    PRIVATE omc::simrt::simruntime
    PRIVATE GTest::gtest_main
  )
  target_compile_definitions(${TEST_NAME}
    PRIVATE TEST_RESOURCES_DIR="${CMAKE_CURRENT_SOURCE_DIR}/resources"
  )
  gtest_discover_tests(${TEST_NAME})
  add_dependencies(ctestsuite-inputXML-unit ${TEST_NAME})
endforeach()
