#include "simulation_data.h"
#include "solver/model_help.c"

/**
 * @brief Test initialization of simulation data start values from model data.
 *
 * Set 2x3 Matrix A = {1, 2, 3;
 *                     4, 5, 6}
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  modelica_boolean test_success = TRUE;

  // Prepare dummy data
  DIMENSION_ATTRIBUTE dimensions[] = {
      {.type = DIMENSION_BY_START,
       .start = 2,
       .valueReference = -1},
      {.type = DIMENSION_BY_START,
       .start = 3,
       .valueReference = -1}};
  modelica_real start_values[] = {1, 2, 3, 4, 5, 6};

  STATIC_REAL_DATA realVarsData = {0};
  realVarsData.dimension.numberOfDimensions = 2;
  realVarsData.dimension.dimensions = dimensions;
  realVarsData.dimension.scalar_length = 6;
  real_array_create(
      &realVarsData.attribute.start,
      start_values,
      2,
      2,
      3);

  MODEL_DATA modelData = {0};
  modelData.nVariablesReal = 6;
  modelData.nVariablesRealArray = 1;
  modelData.realVarsData = &realVarsData;

  SIMULATION_INFO simulationInfo = {0};
  size_t realVarsIndex[1] = {0};
  simulationInfo.realVarsIndex = realVarsIndex;

  SIMULATION_DATA simulationData = {0};
  simulationData.realVars = (modelica_real *)calloc(6, sizeof(modelica_real));

  // Execute funciton under test
  setAllVarsToStart(&simulationData, &simulationInfo, &modelData);

  // Check simulation data
  if (simulationData.realVars[0] != 1)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '1', got '%f'\n", simulationData.realVars[0]);
    test_success = FALSE;
  }
  if (simulationData.realVars[1] != 2)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '2', got '%f'\n", simulationData.realVars[1]);
    test_success = FALSE;
  }
  if (simulationData.realVars[2] != 3)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '3', got '%f'\n", simulationData.realVars[2]);
    test_success = FALSE;
  }
  if (simulationData.realVars[3] != 4)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '4', got '%f'\n", simulationData.realVars[3]);
    test_success = FALSE;
  }
  if (simulationData.realVars[4] != 5)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '5', got '%f'\n", simulationData.realVars[4]);
    test_success = FALSE;
  }
  if (simulationData.realVars[5] != 6)
  {
    fprintf(stderr, "Test failed: Wrong start value. Expected '6', got '%f'\n", simulationData.realVars[5]);
    test_success = FALSE;
  }

  // Free memory
  free(simulationData.realVars);

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
