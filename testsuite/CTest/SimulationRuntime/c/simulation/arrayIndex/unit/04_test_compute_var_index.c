#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "arrayIndex.h"
#include "simulation_data.h"

/* private funciton prototype */
void computeVarsIndex(void *variableData, enum var_type type, size_t num_variables, size_t *varsIndex);

/**
 * @brief Test calculation of array length of tensor variable.
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  int test_success = 1;
  size_t dim1_1 = 2;
  size_t dim1_2 = 3;
  size_t dim3_1 = 4;
  size_t dim3_2 = 3;
  size_t dim3_3 = 2;

  // Prepare dummy data
  DIMENSION_ATTRIBUTE dimensions_var1[] = {
      {.type = DIMENSION_BY_START,
       .start = dim1_1,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = dim1_2,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info_var1 = {
      .numberOfDimensions = 2,
      .dimensions = dimensions_var1,
      .scalar_length = dim1_1 * dim1_2};

  DIMENSION_INFO dimension_info_var2 = {
      .numberOfDimensions = 0,
      .dimensions = NULL,
      .scalar_length = 1};

  DIMENSION_ATTRIBUTE dimensions_var3[] = {
      {.type = DIMENSION_BY_START,
       .start = dim3_1,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = dim3_2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = dim3_3,
       .valueReference = -1}};
  DIMENSION_INFO dimension_info_var3 = {
      .numberOfDimensions = 3,
      .dimensions = dimensions_var3,
      .scalar_length = dim3_1 * dim3_2 * dim3_3};

  STATIC_REAL_DATA realVarsData[] = {
      {.dimension = dimension_info_var1,
       .info = {.id = 0}},
      {.dimension = dimension_info_var2,
       .info = {.id = 1}},
      {.dimension = dimension_info_var3,
       .info = {.id = 2}}};

  // Test
  size_t varsIndex[4] = {0};
  computeVarsIndex(&realVarsData, T_REAL, 3, varsIndex);

  // Validate
  if (varsIndex[0] != 0)
  {
    fprintf(stderr, "Test failed: Expected varsIndex[0]=0, but got '%zu'.\n", varsIndex[0]);
    test_success = 0;
  }
  if (varsIndex[1] != (dim1_1 * dim1_2))
  {
    fprintf(stderr, "Test failed: Expected varsIndex[1]=%zu, but got '%zu'.\n", (dim1_1 * dim1_2), varsIndex[1]);
    test_success = 0;
  }
  if (varsIndex[2] != (dim1_1 * dim1_2) + 1)
  {
    fprintf(stderr, "Test failed: Expected varsIndex[2]=%zu, but got '%zu'.\n", (dim1_1 * dim1_2) + 1, varsIndex[2]);
    test_success = 0;
  }
  if (varsIndex[3] != (dim1_1 * dim1_2) + 1 + (dim3_1 * dim3_2 * dim3_3))
  {
    fprintf(stderr, "Test failed: Expected varsIndex[3]=%zu, but got '%zu'.\n", (dim1_1 * dim1_2) + 1 + (dim3_1 * dim3_2 * dim3_3), varsIndex[3]);
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
