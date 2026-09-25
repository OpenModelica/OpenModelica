#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "simulation_input_xml.h"
#include "openmodelica_types.h"
#include "util/base_array.h"
#include "util/boolean_array.h"

/* private prototype */
void read_array_var_boolean(boolean_array *array, const char *str, modelica_boolean default_value);

/**
 * @brief Test parsing of boolean array attributes.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  boolean_array test_array;
  const modelica_boolean expected[] = {1, 0, 0, 1};

  // Array
  read_array_var_boolean(&test_array, "true false false true", 0);
  if (base_array_nr_of_elements(test_array) != 4)
  {
    fprintf(stderr, "Test failed: Wrong number of elements. Expected '4', got '%ld'\n", (long)base_array_nr_of_elements(test_array));
    test_success = 0;
  }
  for (int i = 0; test_success && i < 4; i++)
  {
    if (boolean_get(test_array, i) != expected[i])
    {
      fprintf(stderr, "Test failed: Wrong value at index %d. Expected '%d', got '%d'\n", i, expected[i], boolean_get(test_array, i));
      test_success = 0;
    }
  }
  omc_array_release(&test_array);

  // Empty string uses default value
  read_array_var_boolean(&test_array, "", 1);
  if (test_success && (base_array_nr_of_elements(test_array) != 1 || boolean_get(test_array, 0) != 1))
  {
    fprintf(stderr, "Test failed: Expected single default value 'true'.\n");
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
