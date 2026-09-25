#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "arrayIndex.h"
#include "simulation_data.h"
#include "openmodelica_types.h"

/**
 * @brief Compare name of element `linear` with `expected`.
 */
static int check(const char *name, const DIMENSION_INFO *dimension, size_t linear, const char *expected)
{
  char buffer[256];
  printArrayElementName(buffer, sizeof(buffer), name, dimension, linear);
  if (strcmp(buffer, expected) != 0)
  {
    fprintf(stderr, "Test failed: Expected '%s', got '%s'\n", expected, buffer);
    return 0;
  }
  return 1;
}

/**
 * @brief Test names of array elements as used in result and initialization files.
 *
 * @return int Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;

  DIMENSION_ATTRIBUTE dims[] = {
      {.type = DIMENSION_BY_START, .start = 2, .valueReference = -1},
      {.type = DIMENSION_BY_START, .start = 3, .valueReference = -1}};
  DIMENSION_INFO matrix = {.numberOfDimensions = 2, .dimensions = dims, .scalar_length = 6};
  DIMENSION_INFO vector = {.numberOfDimensions = 1, .dimensions = dims, .scalar_length = 2};
  DIMENSION_INFO scalar = {.numberOfDimensions = 0, .dimensions = NULL, .scalar_length = 1};

  test_success &= check("x", &scalar, 0, "x");
  test_success &= check("x", NULL, 0, "x");
  test_success &= check("v", &vector, 1, "v[2]");
  test_success &= check("A", &matrix, 0, "A[1,1]");
  test_success &= check("A", &matrix, 2, "A[1,3]");
  test_success &= check("A", &matrix, 4, "A[2,2]");
  test_success &= check("der(A)", &matrix, 5, "der(A[2,3])");
  test_success &= check("der(x)", &scalar, 0, "der(x)");

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
