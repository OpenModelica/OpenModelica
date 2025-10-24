#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "simulation_input_xml.h"
#include "openmodelica_types.h"

/* private prototype */
void read_array_var_real(real_array *array, const char *str, modelica_real default_value);

/**
 * @brief Test parsing of real array attributes
 *
 * Test parsing of start array.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;

  const char *test_string = "1.1 2.2 3.3 4.4 5.5";
  const modelica_real test_default_value = 0.0;
  real_array test_array;
  modelica_real *data;

  // Call the function under test
  read_array_var_real(&test_array, test_string, test_default_value);

  // Validate
  data = (modelica_real*) test_array.data;
  if (test_success && data[0] != 1.1)
  {
    fprintf(stderr, "Test failed: Wrong value. Expected '1.1', got '%f'\n", data[0]);
    test_success = 0;
  }
  if (test_success && data[1] != 2.2)
  {
    fprintf(stderr, "Test failed: Wrong value. Expected '2.2', got '%f'\n", data[0]);
    test_success = 0;
  }
  if (test_success && data[2] != 3.3)
  {
    fprintf(stderr, "Test failed: Wrong value. Expected '3.3', got '%f'\n", data[0]);
    test_success = 0;
  }
  if (test_success && data[3] != 4.4)
  {
    fprintf(stderr, "Test failed: Wrong value. Expected '4.4', got '%f'\n", data[0]);
    test_success = 0;
  }
  if (test_success && data[4] != 5.5)
  {
    fprintf(stderr, "Test failed: Wrong value. Expected '5.5', got '%f'\n", data[0]);
    test_success = 0;
  }

  // Free allocated memory
  omc_alloc_interface.free_uncollectable(test_array.data);

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
