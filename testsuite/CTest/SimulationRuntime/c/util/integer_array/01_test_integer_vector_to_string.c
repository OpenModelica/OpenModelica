#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "util/integer_array.h"

/**
 * @brief Test function `integer_vector_to_string`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  char buffer[2048];
  char small_buffer[12];

  integer_array test_array;
  simple_alloc_1d_integer_array(&test_array, 4);
  put_integer_element(1, 0, &test_array);
  put_integer_element(-20, 1, &test_array);
  put_integer_element(300, 2, &test_array);
  put_integer_element(4, 3, &test_array);

  // Vector
  integer_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{1, -20, 300, 4}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{1, -20, 300, 4}", buffer);
    test_success = 0;
  }

  // Truncated
  integer_vector_to_string(&test_array, TRUE, small_buffer, sizeof(small_buffer));
  if (strcmp(small_buffer, "{1, ...}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{1, ...}", small_buffer);
    test_success = 0;
  }
  omc_array_release(&test_array);

  // Scalar
  simple_alloc_1d_integer_array(&test_array, 1);
  put_integer_element(42, 0, &test_array);

  integer_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "42") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "42", buffer);
    test_success = 0;
  }

  // Array with single element
  integer_vector_to_string(&test_array, FALSE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{42}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{42}", buffer);
    test_success = 0;
  }
  omc_array_release(&test_array);

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
