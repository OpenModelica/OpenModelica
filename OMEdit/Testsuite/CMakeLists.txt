find_package(Qt${OM_QT_MAJOR_VERSION} COMPONENTS Test REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

# Enable testing in this directory. This means you need to be in
# <build_dir>/OMEdit/Testsuite/ folder to run ctest.
# If you want to run the tests while in another directory (ctest > 3.22) you
# have to specify --test-dir (e.g., --test-dir <build_dir>/OMEdit/Testsuite)
enable_testing()

add_library(OMEditTestSuiteUtil STATIC Util/Util.cpp)
add_library(omedit::testsuite::util ALIAS OMEditTestSuiteUtil)

target_link_libraries(OMEditTestSuiteUtil PUBLIC Qt${OM_QT_MAJOR_VERSION}::Test)
target_link_libraries(OMEditTestSuiteUtil PUBLIC OMEditLib)

target_include_directories(OMEditTestSuiteUtil PUBLIC Util/)


# This macro takes two arguments. The test executable name to be created (which will
# also be the name of the test instance right now) and a list of source files to build
# the test executable.
# Note that you have to quote the list you send into this macro. See below for examples.
# This is the ugly part of CMake script syntax.
macro(add_omedit_test test_name test_source_files)
  add_executable(${test_name} ${test_source_files})
  target_link_libraries(${test_name} PUBLIC omedit::testsuite::util)

  add_test(NAME ${test_name}
         COMMAND ${CMAKE_CURRENT_SOURCE_DIR}/RunOMEditTest.sh $<TARGET_FILE:${test_name}>
                                                              ${CMAKE_CURRENT_BINARY_DIR}/OMEditTestResult/)

  # Label the tests (does not matter just now but it will of more types of tests are added.).
  set_tests_properties(${TEST_FILE_NAME} PROPERTIES LABELS "OMEditTestsuite")

  message(STATUS "Added OMEdit test ${test_name}.")
endmacro()

set(OMEDIT_TEST_AUTOCOMPLETION_SOURCES AutoCompletion/AutoCompletionTest.cpp
                                        AutoCompletion/AutoCompletionTest.h)
add_omedit_test(AutoCompletion "${OMEDIT_TEST_AUTOCOMPLETION_SOURCES}")

set(OMEDIT_TEST_BROWSEMSL_SOURCES BrowseMSL/BrowseMSL.cpp
                                  BrowseMSL/BrowseMSL.h)
add_omedit_test(BrowseMSL "${OMEDIT_TEST_BROWSEMSL_SOURCES}")

set(OMEDIT_TEST_DIAGRAM_SOURCES Diagram/Diagram.cpp
                                Diagram/Diagram.h)
add_omedit_test(Diagram "${OMEDIT_TEST_DIAGRAM_SOURCES}")

set(OMEDIT_TEST_DYNAMICANNOTATION_SOURCES DynamicAnnotation/DynamicAnnotationTest.cpp
                                           DynamicAnnotation/DynamicAnnotationTest.h)
add_omedit_test(DynamicAnnotation "${OMEDIT_TEST_DYNAMICANNOTATION_SOURCES}")

set(OMEDIT_TEST_EXPRESSION_SOURCES Expression/ExpressionTest.cpp
                                   Expression/ExpressionTest.h)
add_omedit_test(Expression "${OMEDIT_TEST_EXPRESSION_SOURCES}")

set(OMEDIT_TEST_HOMOTOPY_SOURCES Homotopy/HomotopyTest.cpp
                                 Homotopy/HomotopyTest.h)
add_omedit_test(Homotopy "${OMEDIT_TEST_HOMOTOPY_SOURCES}")
# Set a 5 min timeout for the Homotopy test. This should be investigated
# to figure out why it takes so long in the first place.
# set_tests_properties(Homotopy PROPERTIES TIMEOUT 300)

set(OMEDIT_TEST_MODELINSTANCE_SOURCES ModelInstance/ModelInstanceTest.cpp
                                      ModelInstance/ModelInstanceTest.h)
add_omedit_test(ModelInstance "${OMEDIT_TEST_MODELINSTANCE_SOURCES}")

set(OMEDIT_TEST_STRINGHANDLER_SOURCES StringHandler/StringHandlerTest.cpp
                                       StringHandler/StringHandlerTest.h)
add_omedit_test(StringHandler "${OMEDIT_TEST_STRINGHANDLER_SOURCES}")

set(OMEDIT_TEST_TRANSFORMATION_SOURCES Transformation/TransformationTest.cpp
                                       Transformation/TransformationTest.h)
add_omedit_test(Transformation "${OMEDIT_TEST_TRANSFORMATION_SOURCES}")

set(OMEDIT_TEST_UTILITIES_SOURCES Utilities/UtilitiesTest.cpp
                                  Utilities/UtilitiesTest.h)
add_omedit_test(Utilities "${OMEDIT_TEST_UTILITIES_SOURCES}")

set(OMEDIT_TEST_VARIABLEVALUE_SOURCES VariableValue/VariableValueTest.cpp
                                      VariableValue/VariableValueTest.h)
add_omedit_test(VariableValue "${OMEDIT_TEST_VARIABLEVALUE_SOURCES}")
