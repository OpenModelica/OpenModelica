#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "arrayIndex.h"

/**
 * @brief Test calculation of array length of matrix variable.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  size_t dim1 = 2;
  size_t dim2 = 3;
  size_t expected_length = dim1 * dim2;

  // Prepare dummy data
  DIMENSION_ATTRIBUTE dimensions[] = {
      {.type = DIMENSION_BY_START,
       .start = dim1,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = dim2,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info = {
      .numberOfDimensions = 2,
      .dimensions = dimensions};

  // Test
  size_t actual_length = calculateLength(&dimension_info, NULL, 0);

  // Validate
  if (actual_length != expected_length)
  {
    fprintf(stderr, "Test failed: Expected '%zu', but got '%zu'.\n", expected_length, actual_length);
    test_success = 0;
  }

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
