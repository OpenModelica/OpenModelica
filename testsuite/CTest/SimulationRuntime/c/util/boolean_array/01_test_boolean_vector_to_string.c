#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "util/boolean_array.h"

/**
 * @brief Test function `boolean_vector_to_string`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  char buffer[2048];
  char small_buffer[12];

  boolean_array test_array;
  simple_alloc_1d_boolean_array(&test_array, 3);
  put_boolean_element(1, 0, &test_array);
  put_boolean_element(0, 1, &test_array);
  put_boolean_element(1, 2, &test_array);

  // Vector
  boolean_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{true, false, true}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{true, false, true}", buffer);
    test_success = 0;
  }

  // Truncated
  boolean_vector_to_string(&test_array, TRUE, small_buffer, sizeof(small_buffer));
  if (strcmp(small_buffer, "{...}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{...}", small_buffer);
    test_success = 0;
  }
  omc_array_release(&test_array);

  // Scalar
  simple_alloc_1d_boolean_array(&test_array, 1);
  put_boolean_element(0, 0, &test_array);

  boolean_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "false") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "false", buffer);
    test_success = 0;
  }

  // Array with single element
  boolean_vector_to_string(&test_array, FALSE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{false}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{false}", buffer);
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
