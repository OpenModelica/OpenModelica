/* Main Simulation File */

#if defined(__cplusplus)
extern "C" {
#endif

#include "TestFMU_model.h"
#include "simulation/solver/events.h"



/* dummy VARINFO and FILEINFO */
const VAR_INFO dummyVAR_INFO = omc_dummyVarInfo;

int TestFMU_input_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_input_function_init(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_input_function_updateStartValues(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_inputNames(DATA *data, char ** names){
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_data_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  TRACE_POP
  return 0;
}

int TestFMU_dataReconciliationInputNames(DATA *data, char ** names){
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_dataReconciliationUnmeasuredVariables(DATA *data, char ** names)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_output_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  data->simulationInfo->outputVars[0] = (data->localData[0]->realVars[3] /* x variable */);
  
  TRACE_POP
  return 0;
}

int TestFMU_setc_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}

int TestFMU_setb_function(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/*
equation index: 5
type: SIMPLE_ASSIGN
$x_der = 8.0 * $outputAlias_x - $outputAlias_x ^ 2.0
*/
void TestFMU_eqFunction_5(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,5};
  modelica_real tmp0;
  tmp0 = (data->localData[0]->realVars[0] /* $outputAlias_x STATE(1,$x_der) */);
  (data->localData[0]->realVars[2] /* $x_der variable */) = (8.0) * ((data->localData[0]->realVars[0] /* $outputAlias_x STATE(1,$x_der) */)) - ((tmp0 * tmp0));
  TRACE_POP
}
/*
equation index: 6
type: SIMPLE_ASSIGN
$DER.$outputAlias_x = $x_der
*/
void TestFMU_eqFunction_6(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,6};
  (data->localData[0]->realVars[1] /* der($outputAlias_x) STATE_DER */) = (data->localData[0]->realVars[2] /* $x_der variable */);
  TRACE_POP
}
/*
equation index: 7
type: SIMPLE_ASSIGN
x = $outputAlias_x
*/
void TestFMU_eqFunction_7(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,7};
  (data->localData[0]->realVars[3] /* x variable */) = (data->localData[0]->realVars[0] /* $outputAlias_x STATE(1,$x_der) */);
  TRACE_POP
}

OMC_DISABLE_OPT
int TestFMU_functionDAE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int equationIndexes[1] = {0};
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_tick(SIM_TIMER_DAE);
#endif

  data->simulationInfo->needToIterate = 0;
  data->simulationInfo->discreteCall = 1;
  TestFMU_functionLocalKnownVars(data, threadData);
  TestFMU_eqFunction_5(data, threadData);

  TestFMU_eqFunction_6(data, threadData);

  TestFMU_eqFunction_7(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_accumulate(SIM_TIMER_DAE);
#endif
  TRACE_POP
  return 0;
}


int TestFMU_functionLocalKnownVars(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  
  TRACE_POP
  return 0;
}


/* forwarded equations */
extern void TestFMU_eqFunction_5(DATA* data, threadData_t *threadData);
extern void TestFMU_eqFunction_6(DATA* data, threadData_t *threadData);

static void functionODE_system0(DATA *data, threadData_t *threadData)
{
  {
    TestFMU_eqFunction_5(data, threadData);
    threadData->lastEquationSolved = 5;
  }
  {
    TestFMU_eqFunction_6(data, threadData);
    threadData->lastEquationSolved = 6;
  }
}

int TestFMU_functionODE(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_tick(SIM_TIMER_FUNCTION_ODE);
#endif

  
  data->simulationInfo->callStatistics.functionODE++;
  
  TestFMU_functionLocalKnownVars(data, threadData);
  functionODE_system0(data, threadData);

#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_accumulate(SIM_TIMER_FUNCTION_ODE);
#endif

  TRACE_POP
  return 0;
}

/* forward the main in the simulation runtime */
extern int _main_SimulationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData);

#include "TestFMU_12jac.h"
#include "TestFMU_13opt.h"

struct OpenModelicaGeneratedFunctionCallbacks TestFMU_callback = {
   NULL,    /* performSimulation */
   NULL,    /* performQSSSimulation */
   NULL,    /* updateContinuousSystem */
   TestFMU_callExternalObjectDestructors,    /* callExternalObjectDestructors */
   NULL,    /* initialNonLinearSystem */
   NULL,    /* initialLinearSystem */
   NULL,    /* initialMixedSystem */
   #if !defined(OMC_NO_STATESELECTION)
   TestFMU_initializeStateSets,
   #else
   NULL,
   #endif    /* initializeStateSets */
   TestFMU_initializeDAEmodeData,
   TestFMU_functionODE,
   TestFMU_functionAlgebraics,
   TestFMU_functionDAE,
   TestFMU_functionLocalKnownVars,
   TestFMU_input_function,
   TestFMU_input_function_init,
   TestFMU_input_function_updateStartValues,
   TestFMU_data_function,
   TestFMU_output_function,
   TestFMU_setc_function,
   TestFMU_setb_function,
   TestFMU_function_storeDelayed,
   TestFMU_function_storeSpatialDistribution,
   TestFMU_function_initSpatialDistribution,
   TestFMU_updateBoundVariableAttributes,
   TestFMU_functionInitialEquations,
   1, /* useHomotopy - 0: local homotopy (equidistant lambda), 1: global homotopy (equidistant lambda), 2: new global homotopy approach (adaptive lambda), 3: new local homotopy approach (adaptive lambda)*/
   NULL,
   TestFMU_functionRemovedInitialEquations,
   TestFMU_updateBoundParameters,
   TestFMU_checkForAsserts,
   TestFMU_function_ZeroCrossingsEquations,
   TestFMU_function_ZeroCrossings,
   TestFMU_function_updateRelations,
   TestFMU_zeroCrossingDescription,
   TestFMU_relationDescription,
   TestFMU_function_initSample,
   TestFMU_INDEX_JAC_A,
   TestFMU_INDEX_JAC_B,
   TestFMU_INDEX_JAC_C,
   TestFMU_INDEX_JAC_D,
   TestFMU_INDEX_JAC_F,
   TestFMU_INDEX_JAC_H,
   TestFMU_initialAnalyticJacobianA,
   TestFMU_initialAnalyticJacobianB,
   TestFMU_initialAnalyticJacobianC,
   TestFMU_initialAnalyticJacobianD,
   TestFMU_initialAnalyticJacobianF,
   TestFMU_initialAnalyticJacobianH,
   TestFMU_functionJacA_column,
   TestFMU_functionJacB_column,
   TestFMU_functionJacC_column,
   TestFMU_functionJacD_column,
   TestFMU_functionJacF_column,
   TestFMU_functionJacH_column,
   TestFMU_linear_model_frame,
   TestFMU_linear_model_datarecovery_frame,
   TestFMU_mayer,
   TestFMU_lagrange,
   TestFMU_pickUpBoundsForInputsInOptimization,
   TestFMU_setInputData,
   TestFMU_getTimeGrid,
   TestFMU_symbolicInlineSystem,
   TestFMU_function_initSynchronous,
   TestFMU_function_updateSynchronous,
   TestFMU_function_equationsSynchronous,
   TestFMU_inputNames,
   TestFMU_dataReconciliationInputNames,
   TestFMU_dataReconciliationUnmeasuredVariables,
   TestFMU_read_simulation_info,
   TestFMU_read_input_fmu,
   NULL,
   NULL,
   -1,
   NULL,
   NULL,
   -1

};

#define _OMC_LIT_RESOURCE_0_name_data "TestFMU"
#define _OMC_LIT_RESOURCE_0_dir_data "."
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_name,7,_OMC_LIT_RESOURCE_0_name_data);
static const MMC_DEFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir,1,_OMC_LIT_RESOURCE_0_dir_data);

static const MMC_DEFSTRUCTLIT(_OMC_LIT_RESOURCES,2,MMC_ARRAY_TAG) {MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_name), MMC_REFSTRINGLIT(_OMC_LIT_RESOURCE_0_dir)}};
void TestFMU_setupDataStruc(DATA *data, threadData_t *threadData)
{
  assertStreamPrint(threadData,0!=data, "Error while initialize Data");
  threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data;
  data->callback = &TestFMU_callback;
  OpenModelica_updateUriMapping(threadData, MMC_REFSTRUCTLIT(_OMC_LIT_RESOURCES));
  data->modelData->modelName = "TestFMU";
  data->modelData->modelFilePrefix = "TestFMU";
  data->modelData->resultFileName = NULL;
  data->modelData->modelDir = "";
  data->modelData->modelGUID = "{8bbe51cf-6df6-4c76-a5dc-e613c0ae1625}";
  data->modelData->encrypted = 0;
  data->modelData->initXMLData = NULL;
  data->modelData->modelDataXml.infoXMLData = NULL;
  GC_asprintf(&data->modelData->modelDataXml.fileName, "%s/TestFMU_info.json", data->modelData->resourcesDir);
  data->modelData->runTestsuite = 0;
  data->modelData->nStates = 1;
  data->modelData->nVariablesReal = 4;
  data->modelData->nDiscreteReal = 0;
  data->modelData->nVariablesInteger = 0;
  data->modelData->nVariablesBoolean = 0;
  data->modelData->nVariablesString = 0;
  data->modelData->nParametersReal = 0;
  data->modelData->nParametersInteger = 0;
  data->modelData->nParametersBoolean = 0;
  data->modelData->nParametersString = 0;
  data->modelData->nInputVars = 0;
  data->modelData->nOutputVars = 1;
  data->modelData->nAliasReal = 1;
  data->modelData->nAliasInteger = 0;
  data->modelData->nAliasBoolean = 0;
  data->modelData->nAliasString = 0;
  data->modelData->nZeroCrossings = 0;
  data->modelData->nSamples = 0;
  data->modelData->nRelations = 0;
  data->modelData->nMathEvents = 0;
  data->modelData->nExtObjs = 0;
  data->modelData->modelDataXml.modelInfoXmlLength = 0;
  data->modelData->modelDataXml.nFunctions = 0;
  data->modelData->modelDataXml.nProfileBlocks = 0;
  data->modelData->modelDataXml.nEquations = 8;
  data->modelData->nMixedSystems = 0;
  data->modelData->nLinearSystems = 0;
  data->modelData->nNonLinearSystems = 0;
  data->modelData->nStateSets = 0;
  data->modelData->nJacobians = 6;
  data->modelData->nOptimizeConstraints = 0;
  data->modelData->nOptimizeFinalConstraints = 0;
  data->modelData->nDelayExpressions = 0;
  data->modelData->nBaseClocks = 0;
  data->modelData->nSpatialDistributions = 0;
  data->modelData->nSensitivityVars = 0;
  data->modelData->nSensitivityParamVars = 0;
  data->modelData->nSetcVars = 0;
  data->modelData->ndataReconVars = 0;
  data->modelData->nSetbVars = 0;
  data->modelData->nRelatedBoundaryConditions = 0;
  data->modelData->linearizationDumpLanguage = OMC_LINEARIZE_DUMP_LANGUAGE_MODELICA;
}

static int rml_execution_failed()
{
  fflush(NULL);
  fprintf(stderr, "Execution failed!\n");
  fflush(NULL);
  return 1;
}

