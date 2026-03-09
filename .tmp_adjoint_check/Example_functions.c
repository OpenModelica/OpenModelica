#include "omc_simulation_settings.h"
#include "Example_functions.h"
#ifdef __cplusplus
extern "C" {
#endif

#include "Example_includes.h"


/*
single generic call 0 {$i1 in 1:1:3}
  x[$i1] = w * (*Real*)($i1) * v;
*/
void genericCall_0(DATA *data, threadData_t *threadData, const int equationIndexes[2], modelica_integer _omcQ_24i1)
{
  (&data->localData[0]->realVars[data->simulationInfo->realVarsIndex[5]] /* x[1] variable */)[_omcQ_24i1 - 1] = (((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[2]] /* w variable */)) * (((modelica_real)_omcQ_24i1))) * ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */));;
}

#ifdef __cplusplus
}
#endif
