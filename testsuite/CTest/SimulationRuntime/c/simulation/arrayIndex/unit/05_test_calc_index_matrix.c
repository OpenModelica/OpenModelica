#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "arrayIndex.h"
#include "simulation_data.h"
#include "openmodelica_types.h"

/**
 * @brief Test calculation of linear and multi-dimensional array index.
 *
 * Test index conversion for 2x3 Matrix A =
 * ```txt
 *     a_{1,1} a_{1,2} a_{1,3}
 *     a_{2,1} a_{2,2} a_{2,3}
 * ```
 *
 * Expected output:
 * ```txt
 * Address | Access  | Value
 * --------|---------|--------
 *    0    | A[0][0] | a_{1,1}
 *    1    | A[0][1] | a_{1,2}
 *    2    | A[0][2] | a_{1,3}
 *    3    | A[1][0] | a_{2,1}
 *    4    | A[1][1] | a_{2,2}
 *    5    | A[1][2] | a_{2,3}
 * ```
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  size_t input_linear_index;
  size_t expected_linear_index;
  size_t actual_linear_index;
  size_t input_array_index[2];
  size_t expected_array_index[2];
  size_t* actual_array_index;

  // Prepare dimension data
  DIMENSION_ATTRIBUTE dimensions[] = {
      {.type = DIMENSION_BY_START,
       .start = 2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 3,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info = {
      .numberOfDimensions = 2,
      .dimensions = dimensions,
      .scalar_length = 2*3};

  // Test [0, 0] --> 0
  input_array_index[0] = 0;
  input_array_index[1] = 0;
  expected_linear_index = 0;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 0 --> [0, 0]
  input_linear_index = 0;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 0;
  expected_array_index[1] = 0;
  for (size_t i = 0; i < 2; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  // Test [1, 0] --> 3
  input_array_index[0] = 1;
  input_array_index[1] = 0;
  expected_linear_index = 3;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 3 --> [1, 0]
  input_linear_index = 3;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 1;
  expected_array_index[1] = 0;
  for (size_t i = 0; i < 2; i++)
  {
    if (actual_array_index[i] != expected_array_index[i])
    {
      fprintf(stderr, "Test failed: Expected array_index[%zu]=%zu, but got '%zu'.\n", i, expected_array_index[i], actual_array_index[i]);
      test_success = 0;
    }
  }
  free(actual_array_index);

  // Test [1,2] --> 5
  input_array_index[0] = 1;
  input_array_index[1] = 2;
  expected_linear_index = 5;
  actual_linear_index = multiDimArrayToLinearIndex(&dimension_info, input_array_index);
  if (actual_linear_index != expected_linear_index)
  {
    fprintf(stderr, "Test failed: Expected linear index %zu, but got '%zu'.\n", expected_linear_index, actual_linear_index);
    test_success = 0;
  }

  // Test 5 --> [1, 2]
  input_linear_index = 5;
  actual_array_index = linearToMultiDimArrayIndex(&dimension_info, input_linear_index);
  expected_array_index[0] = 1;
  expected_array_index[1] = 2;
  for (size_t i = 0; i < 2; i++)
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
