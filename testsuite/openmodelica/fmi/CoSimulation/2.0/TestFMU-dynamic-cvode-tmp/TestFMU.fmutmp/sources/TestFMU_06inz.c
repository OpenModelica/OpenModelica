/* Initialization */
#include "TestFMU_model.h"
#include "TestFMU_11mix.h"
#include "TestFMU_12jac.h"
#if defined(__cplusplus)
extern "C" {
#endif

void TestFMU_functionInitialEquations_0(DATA *data, threadData_t *threadData);

/*
equation index: 1
type: SIMPLE_ASSIGN
$outputAlias_x = $START.$outputAlias_x
*/
void TestFMU_eqFunction_1(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int equationIndexes[2] = {1,1};
  (data->localData[0]->realVars[0] /* $outputAlias_x STATE(1,$x_der) */) = (data->modelData->realVarsData[0] /* $outputAlias_x STATE(1,$x_der) */).attribute .start;
  TRACE_POP
}
extern void TestFMU_eqFunction_7(DATA *data, threadData_t *threadData);

extern void TestFMU_eqFunction_5(DATA *data, threadData_t *threadData);

extern void TestFMU_eqFunction_6(DATA *data, threadData_t *threadData);

OMC_DISABLE_OPT
void TestFMU_functionInitialEquations_0(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  TestFMU_eqFunction_1(data, threadData);
  TestFMU_eqFunction_7(data, threadData);
  TestFMU_eqFunction_5(data, threadData);
  TestFMU_eqFunction_6(data, threadData);
  TRACE_POP
}

int TestFMU_functionInitialEquations(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  data->simulationInfo->discreteCall = 1;
  TestFMU_functionInitialEquations_0(data, threadData);
  data->simulationInfo->discreteCall = 0;
  
  TRACE_POP
  return 0;
}

/* No TestFMU_functionInitialEquations_lambda0 function */

int TestFMU_functionRemovedInitialEquations(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  const int *equationIndexes = NULL;
  double res = 0.0;

  
  TRACE_POP
  return 0;
}


#if defined(__cplusplus)
}
#endif

