#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "simulation_input_xml.h"
#include "openmodelica_types.h"
#include "util/base_array.h"
#include "util/integer_array.h"

/* private prototype */
void read_array_var_integer(integer_array *array, const char *str, modelica_integer default_value);

/**
 * @brief Test parsing of integer array attributes.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  integer_array test_array;
  const modelica_integer expected[] = {1, -2, 3, 40};

  // Array
  read_array_var_integer(&test_array, "1 -2 3 40", 0);
  if (base_array_nr_of_elements(test_array) != 4)
  {
    fprintf(stderr, "Test failed: Wrong number of elements. Expected '4', got '%ld'\n", (long)base_array_nr_of_elements(test_array));
    test_success = 0;
  }
  for (int i = 0; test_success && i < 4; i++)
  {
    if (integer_get(test_array, i) != expected[i])
    {
      fprintf(stderr, "Test failed: Wrong value at index %d. Expected '%ld', got '%ld'\n", i, (long)expected[i], (long)integer_get(test_array, i));
      test_success = 0;
    }
  }
  omc_array_release(&test_array);

  // Empty string uses default value
  read_array_var_integer(&test_array, "", 7);
  if (test_success && (base_array_nr_of_elements(test_array) != 1 || integer_get(test_array, 0) != 7))
  {
    fprintf(stderr, "Test failed: Expected single default value '7'.\n");
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
