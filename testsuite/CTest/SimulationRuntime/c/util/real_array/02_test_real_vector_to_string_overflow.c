#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "util/real_array.h"

/**
 * @brief Test function `real_vector_to_string` with a too short buffer.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;

  real_array test_array;
  simple_alloc_1d_real_array(&test_array, 10);
  ((modelica_real *)test_array.data)[0] = 1.0;
  ((modelica_real *)test_array.data)[1] = 2.0;
  ((modelica_real *)test_array.data)[2] = 3.0;
  ((modelica_real *)test_array.data)[3] = 4.0;
  ((modelica_real *)test_array.data)[4] = 5.0;
  ((modelica_real *)test_array.data)[5] = 6.0;
  ((modelica_real *)test_array.data)[6] = 7.0;
  ((modelica_real *)test_array.data)[7] = 8.0;
  ((modelica_real *)test_array.data)[8] = 9.0;
  ((modelica_real *)test_array.data)[9] = 10.0;

  const char *expected_print = "{1, 2, 3, 4, 5, ...}";
  // Test
  size_t buffer_size = 22;
  char buffer[buffer_size];
  real_vector_to_string(&test_array, TRUE, buffer, buffer_size);

  // Validate
  if (test_success && strcmp(buffer, expected_print))
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", expected_print, buffer);
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
