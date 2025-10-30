#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "arrayIndex.h"
#include "simulation_data.h"
#include "openmodelica_types.h"

/**
 * @brief Test calculation of linear and multi-dimensional array index for a 2x3x4 tensor.
 *
 * Dimensions: T[2][3][4]
 * Row-major strides: [3*4=12, 4, 1]
 * Linear index = i*12 + j*4 + k
 *
 * @return int Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  size_t input_linear_index;
  size_t expected_linear_index;
  size_t actual_linear_index;
  size_t input_array_index[3];
  size_t expected_array_index[3];
  size_t* actual_array_index;

  // Prepare dimension data for 2x3x4 tensor
  DIMENSION_ATTRIBUTE dimensions[] = {
      {.type = DIMENSION_BY_START,
       .start = 2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 3,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 4,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info = {
      .numberOfDimensions = 3,
      .dimensions = dimensions,
      .scalar_length = 2*3*4};

  // Test [0,0,0] --> 0
  input_array_index[0] = 0;
  input_array_index[1] = 0;
  input_array_index[2] = 0;
  expected_linear_index = 0;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 0 --> [0,0,0]
  input_linear_index = 0;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 0;
  expected_array_index[1] = 0;
  expected_array_index[2] = 0;
  for (size_t i = 0; i < 3; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  // Test [1,0,0] --> 12
  input_array_index[0] = 1;
  input_array_index[1] = 0;
  input_array_index[2] = 0;
  expected_linear_index = 12;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 12 --> [1,0,0]
  input_linear_index = 12;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 1;
  expected_array_index[1] = 0;
  expected_array_index[2] = 0;
  for (size_t i = 0; i < 3; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  // Test [0,1,0] --> 4
  input_array_index[0] = 0;
  input_array_index[1] = 1;
  input_array_index[2] = 0;
  expected_linear_index = 4;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 4 --> [0,1,0]
  input_linear_index = 4;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 0;
  expected_array_index[1] = 1;
  expected_array_index[2] = 0;
  for (size_t i = 0; i < 3; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  // Test [1,2,3] --> 23 (max index)
  input_array_index[0] = 1;
  input_array_index[1] = 2;
  input_array_index[2] = 3;
  expected_linear_index = 23;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 23 --> [1,2,3]
  input_linear_index = 23;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 1;
  expected_array_index[1] = 2;
  expected_array_index[2] = 3;
  for (size_t i = 0; i < 3; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  if (test_success)
  {
    printf("All tests passed!\n");
    return 0;
  }
  else
  {
    printf("Some tests failed!\n");
    return 1;
  }
}
