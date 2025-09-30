#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "omc_error.h"
#include "omc_init.h"
#include "options.h"
#include "simulation_omc_assert.h"

#include "simulation_input_xml.h"

int main(void) {

  int test_success = 1;

  // Set XML file for testing
  omc_flag[FLAG_F] = 1;
  omc_flagValue[FLAG_F] = "/home/andreas/workdir/OpenModelica/testsuite/CTest/SimulationRuntime/c/inputXML/unit/resources/RealMatrixVariable_init.xml";

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

  simulationInfo.OPENMODELICAHOME = "/home/andreas/workdir/OpenModelica/build_cmake/install_cmake";

  initDumpSystem();
  omc_useStream[OMC_LOG_DEBUG] = 1; // Enable debug logging for testing

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
  if (test_success && strcmp(modelData.realVarsData[0].info.name, "A") != 0) {
    fprintf(stderr, "Test failed: real variable name mismatch. Expected 'A', got '%s'\n", modelData.realVarsData[0].info.name);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.numberOfDimensions != 2) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected '2', got '%lu'\n", modelData.realVarsData[0].dimension.numberOfDimensions);
    test_success = 0;
  }

  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].type != DIMENSION_BY_START) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].start != 3) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected 'start=3', got '%lu'\n", modelData.realVarsData[0].dimension.dimensions[0].start);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[0].valueReference == -1) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to not contain 'valueReference'\n");
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].type != DIMENSION_BY_START) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected <dimension> to contain 'start'\n");
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].start != 2) {
    fprintf(stderr, "Test failed: real variable dimension mismatch. Expected 'start=2', got '%lu'\n", modelData.realVarsData[0].dimension.dimensions[1].start);
    test_success = 0;
  }
  if (test_success && modelData.realVarsData[0].dimension.dimensions[1].valueReference == -1) {
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
