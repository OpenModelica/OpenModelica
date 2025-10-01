#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "omc_error.h"
#include "omc_init.h"
#include "options.h"
#include "simulation_omc_assert.h"

#include "simulation_input_xml.h"

/**
 * @brief Test parsing of init XML
 *
 * Test init XML with matrix variable containing two dimension tags.
 * Uses only "start" attribute in dimension tag.
 *
 * @param argc  Number of arguments. Has to be 2.
 * @param argv  Second argument has to be path to resources/RealMatrixVariable_init.xml;
 * @return int  Return 0 on test success, 1 otherwise.
 */
int main(int argc, char* argv[]) {

  if (argc != 2) {
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
  modelData.realVarsData = (STATIC_REAL_DATA*)calloc(modelData.nVariablesReal, sizeof(STATIC_REAL_DATA));
  modelData.initXMLData = NULL;
  modelData.modelGUID = "test-guid";

  SIMULATION_INFO simulationInfo = {0};
  DATA data = {
    .modelData = &modelData,
    .simulationInfo = &simulationInfo
  };

  simulationInfo.OPENMODELICAHOME = "/home/user/workdir/OpenModelica/build_cmake/install_cmake/";

  initDumpSystem();

  MMC_INIT(0);
  {
    MMC_TRY_TOP()
    MMC_TRY_STACK()

    threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = &data;

    // Call the function under test
    read_input_xml(&modelData, &simulationInfo);

    MMC_ELSE()
    fprintf(stderr, "Stack overflow!\n");
    test_success = 0;
    MMC_CATCH_STACK()
    MMC_CATCH_TOP(fprintf(stderr, "Test throw!\n"); test_success = 0);
  }

  // Validate
  if (test_success && strcmp(modelData.realVarsData[0].info.name, "A")) {
    fprintf(stderr, "Test failed: real variable name mismatch. Expected 'A', got '%s'\n", modelData.realVarsData[0].info.name);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.numberOfDimensions != 2) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected '2', got '%lu'\n", modelData.realVarsData[0].dimension.numberOfDimensions);
    test_success = 0;
  }

  // Dimension 1
  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].type != DIMENSION_BY_START) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].start != 100) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected 'start=100', got '%lu'\n", modelData.realVarsData[0].dimension.dimensions[0].start);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].valueReference != -1) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to not contain 'valueReference'\n");
    test_success = 0;
  }
  // Dimension 2
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].type != DIMENSION_BY_START) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].start != 2) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected 'start=2', got '%lu'\n", modelData.realVarsData[0].dimension.dimensions[1].start);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].valueReference != -1) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to not contain 'valueReference'\n");
    test_success = 0;
  }

  // Free allocated memory
  free(modelData.realVarsData);
  free(modelData.integerParameterData);

  if (test_success) {
    printf("All tests passed!\n");
    return 0;
  } else {
    printf("Some tests failed!\n");
    return 1;
  }
}
