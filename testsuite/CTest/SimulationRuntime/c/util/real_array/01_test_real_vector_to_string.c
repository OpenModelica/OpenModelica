#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "util/real_array.h"

/**
 * @brief Test function `real_vector_to_string`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;

  real_array test_array;
  simple_alloc_1d_real_array(&test_array, 4);
  ((modelica_real *)test_array.data)[0] = 1.0;
  ((modelica_real *)test_array.data)[1] = 100000000000.0;
  ((modelica_real *)test_array.data)[2] = -2;
  ((modelica_real *)test_array.data)[3] = -0.000000123456789;

  const char *expected_print = "{1, 1e+11, -2, -1.23457e-07}";

  // Test
  size_t buffer_size = 2048;
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
