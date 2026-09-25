#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "simulation_input_xml.h"
#include "openmodelica_types.h"
#include "util/base_array.h"
#include "util/omc_string.h"
#include "util/string_array.h"

/* private prototype */
void read_array_var_string(string_array *array, const char *str, modelica_boolean isScalar);

/**
 * @brief Read `str` and compare the result with `expected`.
 *
 * @return int  1 if equal, 0 otherwise.
 */
static int check(const char *str, modelica_boolean isScalar, const char **expected, long n)
{
  int success = 1;
  string_array test_array;

  read_array_var_string(&test_array, str, isScalar);

  if (base_array_nr_of_elements(test_array) != n)
  {
    fprintf(stderr, "Test failed for '%s': Wrong number of elements. Expected '%ld', got '%ld'\n", str, n, (long)base_array_nr_of_elements(test_array));
    success = 0;
  }
  for (long i = 0; success && i < n; i++)
  {
    if (strcmp(omc_string_data(string_get(test_array, i)), expected[i]) != 0)
    {
      fprintf(stderr, "Test failed for '%s': Wrong value at index %ld. Expected '%s', got '%s'\n", str, i, expected[i], omc_string_data(string_get(test_array, i)));
      success = 0;
    }
  }

  omc_string_array_release(&test_array);
  return success;
}

/**
 * @brief Test parsing of string array attributes.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;

  // Array of quoted values
  const char *expected_array[] = {"a", "b c", "", "d"};
  test_success = test_success && check("\"a\" \"b c\" \"\" \"d\"", 0, expected_array, 4);

  // Unescaped quotes inside a value
  const char *expected_quotes[] = {"say \"hi\"", "x"};
  test_success = test_success && check("\"say \"hi\"\" \"x\"", 0, expected_quotes, 2);

  // Unquoted value of array is used for all elements
  const char *expected_fill[] = {"fill value"};
  test_success = test_success && check("fill value", 0, expected_fill, 1);

  // Scalar value is never split
  const char *expected_scalar[] = {"\"a\" \"b\""};
  test_success = test_success && check("\"a\" \"b\"", 1, expected_scalar, 1);

  // Empty string
  const char *expected_empty[] = {""};
  test_success = test_success && check("", 0, expected_empty, 1);
  test_success = test_success && check("", 1, expected_empty, 1);

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
