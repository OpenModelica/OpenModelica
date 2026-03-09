/* Events: Sample, Zero Crossings, Relations, Discrete Changes */
#include "Example_model.h"
#if defined(__cplusplus)
extern "C" {
#endif

/* Initializes the raw time events of the simulation using the now
   calcualted parameters. */
void Example_function_initSample(DATA *data, threadData_t *threadData)
{
  long i=0;
}

const char *Example_zeroCrossingDescription(int i, int **out_EquationIndexes)
{
  static const char *res[] = {"v > 1.5"};
  static const int occurEqs0[] = {1,8};
  static const int *occurEqs[] = {occurEqs0};
  *out_EquationIndexes = (int*) occurEqs[i];
  return res[i];
}

/* forwarded equations */
extern void Example_eqFunction_8(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_7(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_6(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_3(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_2(DATA* data, threadData_t *threadData);
extern void Example_eqFunction_1(DATA* data, threadData_t *threadData);

int Example_function_ZeroCrossingsEquations(DATA *data, threadData_t *threadData)
{
  data->simulationInfo->callStatistics.functionZeroCrossingsEquations++;

  static void (*const eqFunctions[6])(DATA*, threadData_t*) = {
    Example_eqFunction_8,
    Example_eqFunction_7,
    Example_eqFunction_6,
    Example_eqFunction_3,
    Example_eqFunction_2,
    Example_eqFunction_1
  };
  
  for (int id = 0; id < 6; id++) {
    eqFunctions[id](data, threadData);
  }
  
  return 0;
}

int Example_function_ZeroCrossings(DATA *data, threadData_t *threadData, double *gout)
{
  const int *equationIndexes = NULL;

  modelica_boolean tmp0;
  modelica_real tmp1;
  modelica_real tmp2;
  modelica_integer current_index = 0;
  modelica_integer start_index;
  
#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_tick(SIM_TIMER_ZC);
#endif
  data->simulationInfo->callStatistics.functionZeroCrossings++;

  start_index = current_index;
  tmp1 = 1.0;
  tmp2 = 1.5;
  tmp0 = GreaterZC((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */), 1.5, tmp1, tmp2, data->simulationInfo->storedRelations[0]);
  gout[start_index] = (tmp0) ? 1 : -1;
  current_index++;

#if !defined(OMC_MINIMAL_RUNTIME)
  if (measure_time_flag) rt_accumulate(SIM_TIMER_ZC);
#endif

  return 0;
}

const char *Example_relationDescription(int i)
{
  const char *res[] = {"v > 1.5"};
  return res[i];
}

int Example_function_updateRelations(DATA *data, threadData_t *threadData, int evalforZeroCross)
{
  const int *equationIndexes = NULL;

  modelica_boolean tmp3;
  modelica_real tmp4;
  modelica_real tmp5;
  modelica_integer current_index = 0;
  modelica_integer start_index;
  
  if(evalforZeroCross) {
    start_index = current_index;
    tmp4 = 1.0;
    tmp5 = 1.5;
    tmp3 = GreaterZC((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */), 1.5, tmp4, tmp5, data->simulationInfo->storedRelations[0]);
    data->simulationInfo->relations[start_index] = tmp3;
    current_index++;
  } else {
    start_index = current_index;
    data->simulationInfo->relations[start_index] = ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */) > 1.5);
    current_index++;
  }
  
  return 0;
}

#if defined(__cplusplus)
}
#endif
