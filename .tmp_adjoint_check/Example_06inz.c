/* Initialization */
#include "Example_model.h"
#include "Example_11mix.h"
#include "Example_12jac.h"
#if defined(__cplusplus)
extern "C" {
#endif

void Example_functionInitialEquations_0(DATA *data, threadData_t *threadData);

/*
equation index: 10
type: SIMPLE_ASSIGN
v = $START.v
*/
void Example_eqFunction_10(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,10};
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */) = ((modelica_real *)((data->modelData->realVarsData[0] /* v STATE(1,der(v)) */).attribute .start.data))[0];
  threadData->lastEquationSolved = 10;
}

/*
equation index: 9
type: SIMPLE_ASSIGN
$SEV_0 = v > 1.5
*/
void Example_eqFunction_9(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,9};
  modelica_boolean tmp0;
  modelica_real tmp1;
  modelica_real tmp2;
  tmp1 = 1.0;
  tmp2 = 1.5;
  relationhysteresis(data, &tmp0, (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */), 1.5, tmp1, tmp2, 0, Greater, GreaterZC);
  (data->localData[0]->booleanVars[data->simulationInfo->booleanVarsIndex[0]] /* $SEV_0 DISCRETE */) = tmp0;
  threadData->lastEquationSolved = 9;
}

/*
equation index: 8
type: SIMPLE_ASSIGN
w = if $SEV_0 then v ^ 2.0 else 0.5
*/
void Example_eqFunction_8(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,8};
  modelica_real tmp3;
  modelica_boolean tmp4;
  modelica_real tmp5;
  tmp4 = (modelica_boolean)(data->localData[0]->booleanVars[data->simulationInfo->booleanVarsIndex[0]] /* $SEV_0 DISCRETE */);
  if(tmp4)
  {
    tmp3 = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */);
    tmp5 = (tmp3 * tmp3);
  }
  else
  {
    tmp5 = 0.5;
  }
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[2]] /* w variable */) = tmp5;
  threadData->lastEquationSolved = 8;
}

/*
equation index: 7
type: SIMPLE_ASSIGN
$FUN_1 = cos(time)
*/
void Example_eqFunction_7(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,7};
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[11]] /* $FUN_1 variable */) = cos(data->localData[0]->timeValue);
  threadData->lastEquationSolved = 7;
}

void Example_eqFunction_4(DATA*, threadData_t*);
void Example_eqFunction_5(DATA*, threadData_t*);
/*
equation index: 6
indexNonlinear: 0
type: NONLINEAR

vars: {y, z}
eqns: {4, 5}
*/
void Example_eqFunction_6(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,6};
  int retValue;
  infoStreamPrint(OMC_LOG_DT, 0, "Solving nonlinear system 6 (STRICT TEARING SET if tearing enabled) at time = %18.10e", data->localData[0]->timeValue);
  /* get old value */
  data->simulationInfo->nonlinearSystemData[0].nlsxOld[0] = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */);
  data->simulationInfo->nonlinearSystemData[0].nlsxOld[1] = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */);
  retValue = solve_nonlinear_system(data, threadData, 0);
  /* check if solution process was successful */
  if (retValue > 0){
    const int indexes[2] = {1,6};
    throwStreamPrintWithEquationIndexes(threadData, omc_dummyFileInfo, indexes, "Solving non-linear system 6 failed at time=%.15g.\nFor more information please use -lv LOG_NLS.", data->localData[0]->timeValue);
  }
  /* write solution */
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */) = data->simulationInfo->nonlinearSystemData[0].nlsx[0];
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */) = data->simulationInfo->nonlinearSystemData[0].nlsx[1];
  threadData->lastEquationSolved = 6;
}

/*
equation index: 3
type: SIMPLE_ASSIGN
$DER.v = y - 0.1 * v
*/
void Example_eqFunction_3(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,3};
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[1]] /* der(v) STATE_DER */) = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */) - ((0.1) * ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */)));
  threadData->lastEquationSolved = 3;
}

/*
equation index: 2
type: SES_RESIZABLE_ASSIGN call index: 0
*/
void Example_eqFunction_2(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,2};
    for(modelica_integer _omcQ_24i1=((modelica_integer) 1); in_range_integer(_omcQ_24i1, ((modelica_integer) 1), ((modelica_integer) 3)); _omcQ_24i1+=((modelica_integer) 1)){
    genericCall_0(data, threadData, equationIndexes, _omcQ_24i1); /*Example_genericCall*/
    }
  threadData->lastEquationSolved = 2;
}

/*
equation index: 1
type: ALGORITHM

  a := 2.0 * v;
  b := y + z;
  c := x[3] + a;
*/
void Example_eqFunction_1(DATA *data, threadData_t *threadData)
{
  const int equationIndexes[2] = {1,1};
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[8]] /* a variable */) = (2.0) * ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */));

  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[9]] /* b variable */) = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */);

  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[10]] /* c variable */) = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[7]] /* x[3] variable */) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[8]] /* a variable */);
  threadData->lastEquationSolved = 1;
}
OMC_DISABLE_OPT
void Example_functionInitialEquations_0(DATA *data, threadData_t *threadData)
{
  static void (*const eqFunctions[8])(DATA*, threadData_t*) = {
    Example_eqFunction_10,
    Example_eqFunction_9,
    Example_eqFunction_8,
    Example_eqFunction_7,
    Example_eqFunction_6,
    Example_eqFunction_3,
    Example_eqFunction_2,
    Example_eqFunction_1
  };
  
  for (int id = 0; id < 8; id++) {
    eqFunctions[id](data, threadData);
  }
}

int Example_functionInitialEquations(DATA *data, threadData_t *threadData)
{
  data->simulationInfo->discreteCall = 1;
  Example_functionInitialEquations_0(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
  return 0;
}

/* No Example_functionInitialEquations_lambda0 function */

int Example_functionRemovedInitialEquations(DATA *data, threadData_t *threadData)
{
  const int *equationIndexes = NULL;
  double res = 0.0;

  
  return 0;
}


#if defined(__cplusplus)
}
#endif
