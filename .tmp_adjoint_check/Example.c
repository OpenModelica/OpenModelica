/* Main Simulation File */

#if defined(__cplusplus)
extern "C" {
#endif

#include "Example_model.h"
#include "simulation/solver/events.h"
#include "simulation/arrayIndex.h"

/* FIXME these defines are ugly and hard to read, why not use direct function pointers instead? */
#define prefixedName_performSimulation Example_performSimulation
#define prefixedName_updateContinuousSystem Example_updateContinuousSystem
#include <simulation/solver/perform_simulation.c.inc>

#define prefixedName_performQSSSimulation Example_performQSSSimulation
#include <simulation/solver/perform_qss_simulation.c.inc>


/* dummy VARINFO and FILEINFO */
const VAR_INFO dummyVAR_INFO = omc_dummyVarInfo;

int Example_input_function(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

int Example_input_function_init(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

int Example_input_function_updateStartValues(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

int Example_inputNames(DATA *data, char ** names){
  
  return 0;
}

int Example_data_function(DATA *data, threadData_t *threadData)
{
  return 0;
}

int Example_dataReconciliationInputNames(DATA *data, char ** names){
  
  return 0;
}

int Example_dataReconciliationUnmeasuredVariables(DATA *data, char ** names)
{
  
  return 0;
}

int Example_output_function(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

int Example_setc_function(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

int Example_setb_function(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

extern void Example_eqFunction_9(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_8(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_7(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_6(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_3(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_2(DATA *data, threadData_t *threadData);

extern void Example_eqFunction_1(DATA *data, threadData_t *threadData);

OMC_DISABLE_OPT
int Example_functionDAE(DATA *data, threadData_t *threadData)
{
  int equationIndexes[1] = {0};
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_tick(SIM_TIMER_DAE);
#endif

  data->simulationInfo->needToIterate = 0;
  data->simulationInfo->discreteCall = 1;
  Example_functionLocalKnownVars(data, threadData);
  static void (*const eqFunctions[7])(DATA*, threadData_t*) = {
    Example_eqFunction_9,
    Example_eqFunction_8,
    Example_eqFunction_7,
    Example_eqFunction_6,
    Example_eqFunction_3,
    Example_eqFunction_2,
    Example_eqFunction_1
  };
  
  for (int id = 0; id < 7; id++) {
    eqFunctions[id](data, threadData);
  }
  data->simulationInfo->discreteCall = 0;
  
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_accumulate(SIM_TIMER_DAE);
#endif
  return 0;
}


int Example_functionLocalKnownVars(DATA *data, threadData_t *threadData)
{
  
  return 0;
}

/* forwarded equations */
extern void Example_eqFunction_9(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_8(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_7(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_6(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_3(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_2(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_1(DATA* data, threadData_t *threadData);

static void functionODE_system0(DATA *data, threadData_t *threadData)
{
  static void (*const eqFunctions[7])(DATA*, threadData_t*) = {
    Example_eqFunction_9,
    Example_eqFunction_8,
    Example_eqFunction_7,
    Example_eqFunction_6,
    Example_eqFunction_3,
    Example_eqFunction_2,
    Example_eqFunction_1
  };
  
  if (data->simulationInfo->evalSelection) {
    for (int i = 0; i < data->simulationInfo->evalSelection->n; i++) {
      int id = data->simulationInfo->evalSelection->idx[i];
      eqFunctions[id](data, threadData);
    }
  } else {
    for (int id = 0; id < 7; id++) {
      eqFunctions[id](data, threadData);
    }
  }
}

int Example_functionODE(DATA *data, threadData_t *threadData)
{
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_tick(SIM_TIMER_FUNCTION_ODE);
#endif

  
  data->simulationInfo->callStatistics.functionODE++;
  
  Example_functionLocalKnownVars(data, threadData);
  functionODE_system0(data, threadData);

#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_accumulate(SIM_TIMER_FUNCTION_ODE);
#endif

  return 0;
}

void Example_ODE_DAG(DATA* data, threadData_t* threadData)
{
  const size_t eqMap[] = {9, 8, 7, 6, 3, 2, 1};
  buildEvalDAG(data->modelData, sizeof(eqMap)/sizeof(size_t), eqMap);
}

/* forward the main in the simulation runtime */
extern int _main_SimulationRuntime(int argc, char **argv, DATA *data, threadData_t *threadData);
extern int _main_OptimizationRuntime(int argc, char **argv, DATA *data, threadData_t *threadData);

#include "Example_12jac.h"
#include "Example_13opt.h"

struct OpenModelicaGeneratedFunctionCallbacks Example_callback = {
  (int (*)(DATA *, threadData_t *, void *)) Example_performSimulation,    /* performSimulation */
  (int (*)(DATA *, threadData_t *, void *)) Example_performQSSSimulation,    /* performQSSSimulation */
  Example_updateContinuousSystem,    /* updateContinuousSystem */
  Example_callExternalObjectDestructors,    /* callExternalObjectDestructors */
  Example_initialNonLinearSystem,    /* initialNonLinearSystem */
  NULL,    /* initialLinearSystem */
  NULL,    /* initialMixedSystem */
  #if !defined(OMC_NO_STATESELECTION)
  Example_initializeStateSets,
  #else
  NULL,
  #endif    /* initializeStateSets */
  Example_initializeDAEmodeData,
  Example_ODE_DAG,
  Example_functionODE,
  Example_functionAlgebraics,
  Example_functionDAE,
  Example_functionLocalKnownVars,
  Example_input_function,
  Example_input_function_init,
  Example_input_function_updateStartValues,
  Example_data_function,
  Example_output_function,
  Example_setc_function,
  Example_setb_function,
  Example_function_storeDelayed,
  Example_function_storeSpatialDistribution,
  Example_function_initSpatialDistribution,
  Example_updateBoundVariableAttributes,
  Example_functionInitialEquations,
  GLOBAL_EQUIDISTANT_HOMOTOPY,
  NULL,
  Example_functionRemovedInitialEquations,
  Example_updateBoundParameters,
  Example_checkForAsserts,
  Example_function_ZeroCrossingsEquations,
  Example_function_ZeroCrossings,
  Example_function_updateRelations,
  Example_zeroCrossingDescription,
  Example_relationDescription,
  Example_function_initSample,
  Example_INDEX_JAC_A,
  Example_INDEX_JAC_ADJ,
  Example_INDEX_JAC_B,
  Example_INDEX_JAC_C,
  Example_INDEX_JAC_D,
  Example_INDEX_JAC_F,
  Example_INDEX_JAC_H,
  Example_initialAnalyticJacobianA,
  Example_initialAnalyticJacobianADJ,
  Example_initialAnalyticJacobianB,
  Example_initialAnalyticJacobianC,
  Example_initialAnalyticJacobianD,
  Example_initialAnalyticJacobianF,
  Example_initialAnalyticJacobianH,
  Example_functionJacA_column,
  Example_functionJacADJ_column,
  Example_functionJacB_column,
  Example_functionJacC_column,
  Example_functionJacD_column,
  Example_functionJacF_column,
  Example_functionJacH_column,
  Example_linear_model_frame,
  Example_linear_model_datarecovery_frame,
  Example_mayer,
  Example_lagrange,
  Example_getInputVarIndicesInOptimization,
  Example_pickUpBoundsForInputsInOptimization,
  Example_setInputData,
  Example_getTimeGrid,
  Example_symbolicInlineSystem,
  Example_function_initSynchronous,
  Example_function_updateSynchronous,
  Example_function_equationsSynchronous,
  Example_inputNames,
  Example_dataReconciliationInputNames,
  Example_dataReconciliationUnmeasuredVariables,
  NULL,
  NULL,
  NULL,
  NULL,
  -1,
  NULL,
  NULL,
  -1

};

static const MMC_DEFSTRUCTLIT(_OMC_LIT_RESOURCES,0,MMC_ARRAY_TAG) {}};
void Example_setupDataStruc(DATA *data, threadData_t *threadData)
{
  assertStreamPrint(threadData,0!=data, "Error while initialize Data");
  threadData->localRoots[LOCAL_ROOT_SIMULATION_DATA] = data;
  data->callback = &Example_callback;
  OpenModelica_updateUriMapping(threadData, MMC_REFSTRUCTLIT(_OMC_LIT_RESOURCES));
  data->modelData->modelName = "Example";
  data->modelData->modelFilePrefix = "Example";
  data->modelData->modelFileName = "";
  data->modelData->resultFileName = NULL;
  data->modelData->modelDir = "/home/felix/work/OpenModelica/.tmp_adjoint_check";
  data->modelData->modelGUID = "{3949b950-c333-4715-93f8-801c68b307ec}";
  #if defined(OPENMODELICA_XML_FROM_FILE_AT_RUNTIME)
  data->modelData->initXMLData = NULL;
  data->modelData->modelDataXml.infoXMLData = NULL;
  #else
  #if defined(_MSC_VER) /* handle joke compilers */
  {
  /* for MSVC we encode a string like char x[] = {'a', 'b', 'c', '\0'} */
  /* because the string constant limit is 65535 bytes */
  static const char contents_init[] =
    #include "Example_init.c"
    ;
  static const char contents_info[] =
    #include "Example_info.c"
    ;
    data->modelData->initXMLData = contents_init;
    data->modelData->modelDataXml.infoXMLData = contents_info;
  }
  #else /* handle real compilers */
  data->modelData->initXMLData =
  #include "Example_init.c"
    ;
  data->modelData->modelDataXml.infoXMLData =
  #include "Example_info.c"
    ;
  #endif /* defined(_MSC_VER) */
  #endif /* defined(OPENMODELICA_XML_FROM_FILE_AT_RUNTIME) */
  data->modelData->modelDataXml.fileName = "Example_info.json";
  data->modelData->resourcesDir = NULL;
  data->modelData->runTestsuite = 0;
  data->modelData->nStatesArray = 1;
  data->modelData->nDiscreteReal = 0;
  data->modelData->nVariablesRealArray = 12;
  data->modelData->nVariablesIntegerArray = 0;
  data->modelData->nVariablesBooleanArray = 1;
  data->modelData->nVariablesStringArray = 0;
  data->modelData->nParametersRealArray = 0;
  data->modelData->nParametersIntegerArray = 1;
  data->modelData->nParametersBooleanArray = 0;
  data->modelData->nParametersStringArray = 0;
  data->modelData->nParametersReal = 0;
  data->modelData->nParametersInteger = 1;
  data->modelData->nParametersBoolean = 0;
  data->modelData->nParametersString = 0;
  data->modelData->nAliasRealArray = 0;
  data->modelData->nAliasIntegerArray = 0;
  data->modelData->nAliasBooleanArray = 0;
  data->modelData->nAliasStringArray = 0;
  data->modelData->nInputVars = 0;
  data->modelData->nOutputVars = 0;
  data->modelData->nZeroCrossings = 1;
  data->modelData->nSamples = 0;
  data->modelData->nRelations = 1;
  data->modelData->nMathEvents = 0;
  data->modelData->nExtObjs = 0;
  data->modelData->modelDataXml.modelInfoXmlLength = 0;
  data->modelData->modelDataXml.nFunctions = 0;
  data->modelData->modelDataXml.nProfileBlocks = 0;
  data->modelData->modelDataXml.nEquations = 49;
  data->modelData->nMixedSystems = 0;
  data->modelData->nLinearSystems = 0;
  data->modelData->nNonLinearSystems = 2;
  data->modelData->nStateSets = 0;
  data->modelData->nJacobians = 7;
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


#if defined(__MINGW32__) || defined(_MSC_VER)

#if !defined(_UNICODE)
#define _UNICODE
#endif
#if !defined(UNICODE)
#define UNICODE
#endif

#include <windows.h>
char** omc_fixWindowsArgv(int argc, wchar_t **wargv)
{
  char** newargv;
  /* Support for non-ASCII characters
  * Read the unicode command line arguments and translate it to char*
  */
  newargv = (char**)malloc(argc*sizeof(char*));
  for (int i = 0; i < argc; i++) {
    newargv[i] = omc_wchar_to_multibyte_str(wargv[i]);
  }
  return newargv;
}

#define OMC_MAIN wmain
#define OMC_CHAR wchar_t
#define OMC_EXPORT __declspec(dllexport) extern

#else
#define omc_fixWindowsArgv(N, A) (A)
#define OMC_MAIN main
#define OMC_CHAR char
#define OMC_EXPORT extern
#endif

#if defined(threadData)
#undef threadData
#endif
/* call the simulation runtime main from our main! */
#if defined(OMC_DLL_MAIN_DEFINE)
OMC_EXPORT int omcDllMain(int argc, OMC_CHAR **argv)
#else
int OMC_MAIN(int argc, OMC_CHAR** argv)
#endif
{
  char** newargv = omc_fixWindowsArgv(argc, argv);
  /*
    Set the error functions to be used for simulation.
    The default value for them is 'functions' version. Change it here to 'simulation' versions
  */
  omc_assert = omc_assert_simulation;
  omc_assert_withEquationIndexes = omc_assert_simulation_withEquationIndexes;

  omc_assert_warning_withEquationIndexes = omc_assert_warning_simulation_withEquationIndexes;
  omc_assert_warning = omc_assert_warning_simulation;
  omc_terminate = omc_terminate_simulation;
  omc_throw = omc_throw_simulation;

  int res;
  DATA data;
  MODEL_DATA modelData;
  SIMULATION_INFO simInfo;
  data.modelData = &modelData;
  data.simulationInfo = &simInfo;
  measure_time_flag = 0;
  compiledInDAEMode = 0;
  compiledWithSymSolver = 0;
  MMC_INIT(0);
  omc_alloc_interface.init();
  {
    MMC_TRY_TOP()
  
    MMC_TRY_STACK()
  
    Example_setupDataStruc(&data, threadData);
    res = _main_initRuntimeAndSimulation(argc, newargv, &data, threadData);
    if(res == 0) {
      if (omc_flag[FLAG_MOO_OPTIMIZATION]) {
        res = _main_OptimizationRuntime(argc, newargv, &data, threadData);
      } else {
        res = _main_SimulationRuntime(argc, newargv, &data, threadData);
      }
    }
    
    MMC_ELSE()
    rml_execution_failed();
    fprintf(stderr, "Stack overflow detected and was not caught.\nSend us a bug report at https://trac.openmodelica.org/OpenModelica/newticket\n    Include the following trace:\n");
    printStacktraceMessages();
    fflush(NULL);
    return 1;
    MMC_CATCH_STACK()
    
    MMC_CATCH_TOP(return rml_execution_failed());
  }

  fflush(NULL);
  return res;
}

#ifdef __cplusplus
}
#endif


