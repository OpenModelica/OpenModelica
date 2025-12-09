#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "omc_error.h"
#include "omc_init.h"
#include "options.h"
#include "simulation_omc_assert.h"

#include "simulation_input_xml.h"
#include "model_help.h"


/**
 * @brief Validate dimension of array variable `A`.
 *
 * @param dimension Pointer to dimension info.
 * @return int      Return `1` on success, `0` otherwise.
 */
int validateDimensionA(const DIMENSION_INFO *dimension) {
  if (dimension->numberOfDimensions != 2)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected '2', got '%lu'\n", dimension->numberOfDimensions);
    return 0;
  }

  // Dimension 1
  if (dimension->dimensions[0].type != DIMENSION_BY_START)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    return 0;
  }
  if (dimension->dimensions[0].start != 3)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected 'start=3', got '%lu'\n", dimension->dimensions[0].start);
    return 0;
  }
  if (dimension->dimensions[0].valueReference != -1)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected <dimension> to not contain 'valueReference'\n");
    return 0;
  }

  // Dimension 2
  if (dimension->dimensions[1].type != DIMENSION_BY_START)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    return 0;
  }
  if (dimension->dimensions[1].start != 2)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected 'start=2', got '%lu'\n", dimension->dimensions[1].start);
    return 0;
  }
  if (dimension->dimensions[1].valueReference != -1)
  {
    fprintf(stderr, "Test failed: Real variable dimension mismatch. Expected <dimension> to not contain 'valueReference'\n");
    return 0;
  }

  if (dimension->scalar_length != 6)
  {
    fprintf(stderr, "Test failed: Array length is wrong. Expected '6', got '%lu'\n", dimension->scalar_length);
    return 0;
  }

  return 1;
}

/**
 * @brief Validate start attribute of array variable `A`.
 *
 * @param start Pointer to start attribute.
 * @return int  Return `1` on success, `0` otherwise.
 */
int validateStartA(const real_array *start) {
  const _index_t numElements = base_array_nr_of_elements(*start);
  const _index_t expectedNumElements = 6;
  if (numElements != expectedNumElements)
  {
    fprintf(stderr, "Test failed: Real variable start attribute wrong number of elements. Expected %ld, got %ld\n", expectedNumElements, numElements);
    return 0;
  }

  /* Expected start values: {0.0, 0.1, 1.0, 1.1, 2.0, 2.1} */
  const modelica_real expected[] = {0.0, 0.1, 1.0, 1.1, 2.0, 2.1};
  for (_index_t i = 0; i < expectedNumElements; ++i) {
    const modelica_real elem = real_get(*start, i);
    if (elem != expected[i]) {
      fprintf(stderr, "Test failed: Real variable start attribute mismatched at index %ld. Expected %f, got %f\n", i, expected[i], elem);
      return 0;
    }
  }

  return 1;
}

/**
 * @brief Validate nominal attribute of array variable `A`.
 *
 * @param nominal Pointer to nominal attribute.
 * @return int  Return `1` on success, `0` otherwise.
 */
int validateNominalA(const real_array *nominal) {
  const _index_t numElements = base_array_nr_of_elements(*nominal);
  const _index_t expectedNumElements = 6;
  if (numElements != expectedNumElements)
  {
    fprintf(stderr, "Test failed: Real variable nominal attribute wrong number of elements. Expected %ld, got %ld\n", expectedNumElements, numElements);
    return 0;
  }

  /* Expected nominal values: {10.1, 10.2, 10.3, 10.4, 10.5, 10.6} */
  const modelica_real expected[] = {10.1, 10.2, 10.3, 10.4, 10.5, 10.6};
  for (_index_t i = 0; i < expectedNumElements; ++i) {
    const modelica_real elem = real_get(*nominal, i);
    if (elem != expected[i]) {
      fprintf(stderr, "Test failed: Real variable nominal attribute mismatched at index %ld. Expected %f, got %f\n", i, expected[i], elem);
      return 0;
    }
  }

  return 1;
}

/**
 * @brief Test parsing of init XML
 *
 * Test init XML with matrix variable containing two dimension tags.
 * Uses only "start" attribute in dimension tag.
 *
 * @param argc  Number of arguments. Has to be 2.
 * @param argv  Second argument has to be path to resources/02_RealMatrixVariable_init.xml;
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(int argc, char *argv[])
{

  if (argc != 2)
  {
    printf("Wrong number of arguments!\n");
    printf("First argument has to be path to resources/RealMatrixVariable_init.xml\n");
    return 1;
  }

  int test_success = 1;

  // Set XML file for testing
  omc_flag[FLAG_F] = 1;
  omc_flagValue[FLAG_F] = argv[1];

  // Prepare dummy threadData, MODEL_DATA and SIMULATION_INFO
  omc_assert = omc_assert_simulation;
  omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;

  omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
  omc_assert_warning = omc_assert_warning_simulation;
  omc_terminate = omc_terminate_simulation;
  omc_throw = omc_throw_simulation;

  MODEL_DATA modelData = {0};
  modelData.nStates = 0;
  modelData.nVariablesReal = 1;
  modelData.realVarsData = (STATIC_REAL_DATA *)calloc(modelData.nVariablesReal, sizeof(STATIC_REAL_DATA));
  modelData.initXMLData = NULL;
  modelData.modelGUID = "test-guid";

  SIMULATION_INFO simulationInfo = {0};
  DATA data = {
      .modelData = &modelData,
      .simulationInfo = &simulationInfo};

  simulationInfo.OPENMODELICAHOME = "/home/user/workdir/OpenModelica/build_cmake/install_cmake/";

  initDumpSystem();

  MMC_INIT(0);
  {
    MMC_TRY_TOP()
    MMC_TRY_STACK()

    threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = &data;

    // Call the function under test
    read_input_xml(&modelData, &simulationInfo, threadData);

    MMC_ELSE()
    fprintf(stderr, "Stack overflow!\n");
    test_success = 0;
    MMC_CATCH_STACK()
    MMC_CATCH_TOP(fprintf(stderr, "Test throw!\n"); test_success = 0);
  }

  // Validate
  if (test_success && strcmp(modelData.realVarsData[0].info.name, "A"))
  {
    fprintf(stderr, "Test failed: Real variable name mismatch. Expected 'A', got '%s'\n", modelData.realVarsData[0].info.name);
    test_success = 0;
  }

  test_success = test_success && validateDimensionA(&modelData.realVarsData[0].dimension);
  test_success = test_success && validateStartA(&modelData.realVarsData[0].attribute.start);
  test_success = test_success && validateNominalA(&modelData.realVarsData[0].attribute.nominal);

  // Free allocated memory
  freeModelDataVars(&modelData);

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
