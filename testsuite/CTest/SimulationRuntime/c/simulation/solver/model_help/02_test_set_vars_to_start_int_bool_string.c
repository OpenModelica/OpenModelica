#include "simulation_data.h"
#include "solver/model_help.c"

/**
 * @brief Test initialization of integer, boolean and string start values.
 *
 * Model data contains a scalar followed by an array variable for each type:
 *   Integer i = 7, I[3] = {1, 2, 3}
 *   Boolean b = true, B[2] = {false, true}
 *   String  s = "s", S[2] = {"a", "b"}
 *
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(void)
{
  modelica_boolean test_success = TRUE;
  int i;

  DIMENSION_ATTRIBUTE dim3[] = {{.type = DIMENSION_BY_START, .start = 3, .valueReference = -1}};
  DIMENSION_ATTRIBUTE dim2[] = {{.type = DIMENSION_BY_START, .start = 2, .valueReference = -1}};

  // Integer
  STATIC_INTEGER_DATA integerVarsData[2] = {0};
  simple_alloc_1d_integer_array(&integerVarsData[0].attribute.start, 1);
  put_integer_element(7, 0, &integerVarsData[0].attribute.start);
  integerVarsData[0].dimension.scalar_length = 1;
  integerVarsData[1].dimension.numberOfDimensions = 1;
  integerVarsData[1].dimension.dimensions = dim3;
  integerVarsData[1].dimension.scalar_length = 3;
  simple_alloc_1d_integer_array(&integerVarsData[1].attribute.start, 3);
  for (i = 0; i < 3; i++) {
    put_integer_element(i + 1, i, &integerVarsData[1].attribute.start);
  }

  // Boolean
  STATIC_BOOLEAN_DATA booleanVarsData[2] = {0};
  simple_alloc_1d_boolean_array(&booleanVarsData[0].attribute.start, 1);
  put_boolean_element(1, 0, &booleanVarsData[0].attribute.start);
  booleanVarsData[0].dimension.scalar_length = 1;
  booleanVarsData[1].dimension.numberOfDimensions = 1;
  booleanVarsData[1].dimension.dimensions = dim2;
  booleanVarsData[1].dimension.scalar_length = 2;
  simple_alloc_1d_boolean_array(&booleanVarsData[1].attribute.start, 2);
  put_boolean_element(0, 0, &booleanVarsData[1].attribute.start);
  put_boolean_element(1, 1, &booleanVarsData[1].attribute.start);

  // String
  const char *string_start[] = {"s", "a", "b"};
  modelica_string tmp;
  STATIC_STRING_DATA stringVarsData[2] = {0};
  simple_alloc_1d_string_array(&stringVarsData[0].attribute.start, 1);
  tmp = omc_string_new(string_start[0]);
  put_string_element(tmp, 0, &stringVarsData[0].attribute.start);
  omc_string_release(tmp);
  stringVarsData[0].dimension.scalar_length = 1;
  stringVarsData[1].dimension.numberOfDimensions = 1;
  stringVarsData[1].dimension.dimensions = dim2;
  stringVarsData[1].dimension.scalar_length = 2;
  simple_alloc_1d_string_array(&stringVarsData[1].attribute.start, 2);
  for (i = 0; i < 2; i++) {
    tmp = omc_string_new(string_start[i + 1]);
    put_string_element(tmp, i, &stringVarsData[1].attribute.start);
    omc_string_release(tmp);
  }

  MODEL_DATA modelData = {0};
  modelData.nVariablesInteger = 4;
  modelData.nVariablesIntegerArray = 2;
  modelData.integerVarsData = integerVarsData;
  modelData.nVariablesBoolean = 3;
  modelData.nVariablesBooleanArray = 2;
  modelData.booleanVarsData = booleanVarsData;
  modelData.nVariablesString = 3;
  modelData.nVariablesStringArray = 2;
  modelData.stringVarsData = stringVarsData;

  SIMULATION_INFO simulationInfo = {0};
  size_t integerVarsIndex[3] = {0, 1, 4};
  size_t booleanVarsIndex[3] = {0, 1, 3};
  size_t stringVarsIndex[3] = {0, 1, 3};
  simulationInfo.integerVarsIndex = integerVarsIndex;
  simulationInfo.booleanVarsIndex = booleanVarsIndex;
  simulationInfo.stringVarsIndex = stringVarsIndex;

  SIMULATION_DATA simulationData = {0};
  simulationData.integerVars = (modelica_integer *)calloc(4, sizeof(modelica_integer));
  simulationData.booleanVars = (modelica_boolean *)calloc(3, sizeof(modelica_boolean));
  simulationData.stringVars = (modelica_string *)calloc(3, sizeof(modelica_string));

  // Execute function under test
  setAllVarsToStart(&simulationData, &simulationInfo, &modelData);

  // Check simulation data
  const modelica_integer expected_int[] = {7, 1, 2, 3};
  for (i = 0; i < 4; i++) {
    if (simulationData.integerVars[i] != expected_int[i]) {
      fprintf(stderr, "Test failed: Wrong integer start value at %d. Expected '%ld', got '%ld'\n", i, (long)expected_int[i], (long)simulationData.integerVars[i]);
      test_success = FALSE;
    }
  }
  const modelica_boolean expected_bool[] = {1, 0, 1};
  for (i = 0; i < 3; i++) {
    if (simulationData.booleanVars[i] != expected_bool[i]) {
      fprintf(stderr, "Test failed: Wrong boolean start value at %d. Expected '%d', got '%d'\n", i, expected_bool[i], simulationData.booleanVars[i]);
      test_success = FALSE;
    }
  }
  for (i = 0; i < 3; i++) {
    if (simulationData.stringVars[i] == NULL || strcmp(omc_string_data(simulationData.stringVars[i]), string_start[i]) != 0) {
      fprintf(stderr, "Test failed: Wrong string start value at %d. Expected '%s'\n", i, string_start[i]);
      test_success = FALSE;
    }
  }

  // Free memory
  for (i = 0; i < 3; i++) {
    omc_string_release(simulationData.stringVars[i]);
  }
  free(simulationData.integerVars);
  free(simulationData.booleanVars);
  free(simulationData.stringVars);
  freeIntegerVarAttributes(integerVarsData, 2);
  freeBooleanVarAttributes(booleanVarsData, 2);
  freeStringVarAttributes(stringVarsData, 2);

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
