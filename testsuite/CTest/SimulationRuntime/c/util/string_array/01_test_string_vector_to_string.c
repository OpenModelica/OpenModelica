#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "util/string_array.h"
#include "util/omc_string.h"

static void put_new_string(const char *str, int i, string_array *array)
{
  modelica_string s = omc_string_new(str);
  put_string_element(s, i, array);
  omc_string_release(s);
}

/**
 * @brief Test function `string_vector_to_string`.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  char buffer[2048];
  char small_buffer[12];

  string_array test_array;
  simple_alloc_1d_string_array(&test_array, 3);
  put_new_string("a", 0, &test_array);
  put_new_string("b c", 1, &test_array);
  put_new_string("", 2, &test_array);

  // Vector
  string_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{\"a\", \"b c\", \"\"}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{\"a\", \"b c\", \"\"}", buffer);
    test_success = 0;
  }

  // Truncated
  string_vector_to_string(&test_array, TRUE, small_buffer, sizeof(small_buffer));
  if (strcmp(small_buffer, "{\"a\", ...}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{\"a\", ...}", small_buffer);
    test_success = 0;
  }
  omc_string_array_release(&test_array);

  // Scalar
  simple_alloc_1d_string_array(&test_array, 1);
  put_new_string("x", 0, &test_array);
  string_vector_to_string(&test_array, TRUE, buffer, sizeof(buffer));
  if (strcmp(buffer, "\"x\"") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "\"x\"", buffer);
    test_success = 0;
  }

  // Array with single element
  string_vector_to_string(&test_array, FALSE, buffer, sizeof(buffer));
  if (strcmp(buffer, "{\"x\"}") != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", "{\"x\"}", buffer);
    test_success = 0;
  }
  omc_string_array_release(&test_array);

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
