/* Non Linear Systems */
#include "Example_model.h"
#include "Example_12jac.h"
#include "simulation/jacobian_util.h"
#include "simulation/arrayIndex.h"

#if defined(__cplusplus)
extern "C" {
#endif

/* inner equations */

void residualFunc6(RESIDUAL_USERDATA* userData, const double* xloc, double* res, const int* iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  const int equationIndexes[2] = {1,6};
  int i,j;
  /* iteration variables */
  for (i=0; i<2; i++) {
    if (isinf(xloc[i]) || isnan(xloc[i])) {
      errorStreamPrint(OMC_LOG_NLS, 0, "residualFunc6: Iteration variable `%s` is inf or nan.",
        modelInfoGetEquation(&data->modelData->modelDataXml, 6).vars[i]);
      for (j=0; j<2; j++) {
        res[j] = NAN;
      }
      throwStreamPrintWithEquationIndexes(threadData, omc_dummyFileInfo, equationIndexes, "residualFunc6 failed at time=%.15g.\nFor more information please use -lv LOG_NLS.", data->localData[0]->timeValue);
      return;
    }
  }
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */) = xloc[0];
  (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */) = xloc[1];
  /* backup outputs */
  /* pre body */
  /* body */
  res[0] = (-((3.0) * ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */)) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[11]] /* $FUN_1 variable */)));
  threadData->lastEquationSolved = 4;
  res[1] = (-((0.25) * ((data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */)) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */) + (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[0]] /* v STATE(1,der(v)) */)));
  threadData->lastEquationSolved = 5;
  /* restore known outputs */
  threadData->lastEquationSolved = 6;
}
void initializeSparsePatternNLS6(NONLINEAR_SYSTEM_DATA* inSysData)
{
  /* no sparsity pattern available */
  inSysData->isPatternAvailable = FALSE;
}

void freeSparsePatternNLS6(NONLINEAR_SYSTEM_DATA* inSysData)
{
  /* nothing to free */
}
void initializeNonlinearPatternNLS6(NONLINEAR_SYSTEM_DATA* inSysData)
{
  /* no nonlinear pattern available */
}

OMC_DISABLE_OPT
void initializeStaticDataNLS6(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *sysData, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  int i=0;
  /* static nls data for y */
  sysData->nominal[i] = getNominalFromScalarIdx(data->simulationInfo, data->modelData, VAR_KIND_VARIABLE, 3 /* y */);
  sysData->min[i]     = getMinFromScalarIdx(data->simulationInfo, data->modelData, VAR_TYPE_REAL, VAR_KIND_VARIABLE, 3 /* y */);
  sysData->max[i++]   = getMaxFromScalarIdx(data->simulationInfo, data->modelData, VAR_TYPE_REAL, VAR_KIND_VARIABLE, 3 /* y */);
  /* static nls data for z */
  sysData->nominal[i] = getNominalFromScalarIdx(data->simulationInfo, data->modelData, VAR_KIND_VARIABLE, 4 /* z */);
  sysData->min[i]     = getMinFromScalarIdx(data->simulationInfo, data->modelData, VAR_TYPE_REAL, VAR_KIND_VARIABLE, 4 /* z */);
  sysData->max[i++]   = getMaxFromScalarIdx(data->simulationInfo, data->modelData, VAR_TYPE_REAL, VAR_KIND_VARIABLE, 4 /* z */);
  /* initial sparse pattern */
  if (initSparsePattern) {
    initializeSparsePatternNLS6(sysData);
  }
  if (initNonlinearPattern) {
    initializeNonlinearPatternNLS6(sysData);
  }
}

OMC_DISABLE_OPT
void freeStaticDataNLS6(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *sysData)
{
  freeSparsePatternNLS6(sysData);
}

OMC_DISABLE_OPT
void getIterationVarsNLS6(DATA* data, double *array)
{
  array[0] = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[3]] /* y variable */);
  array[1] = (data->localData[0]->realVars[data->simulationInfo->realVarsIndex[4]] /* z variable */);
}

/* Prototypes for the strict sets (Dynamic Tearing) */

/* Global constraints for the casual sets */
/* function initialize non-linear systems */
void Example_initialNonLinearSystem(int nNonLinearSystems, NONLINEAR_SYSTEM_DATA* nonLinearSystemData)
{
  
  nonLinearSystemData[0].equationIndex = 6;
  nonLinearSystemData[0].size = 2;
  nonLinearSystemData[0].homotopySupport = 0 /* false */;
  nonLinearSystemData[0].mixedSystem = 0 /* false */;
  nonLinearSystemData[0].residualFunc = residualFunc6;
  nonLinearSystemData[0].strictTearingFunctionCall = NULL;
  nonLinearSystemData[0].analyticalJacobianColumn = NULL;
  nonLinearSystemData[0].initialAnalyticalJacobian = NULL;
  nonLinearSystemData[0].jacobianIndex = -1;
  nonLinearSystemData[0].initializeStaticNLSData = initializeStaticDataNLS6;
  nonLinearSystemData[0].freeStaticNLSData = freeStaticDataNLS6;
  nonLinearSystemData[0].getIterationVars = getIterationVarsNLS6;
  nonLinearSystemData[0].checkConstraints = NULL;
  
  const int tmp_eqn_indices_0[2] = {4, 5};
  nonLinearSystemData[0].eqn_simcode_indices = malloc(2 * sizeof(int));
  memcpy(nonLinearSystemData[0].eqn_simcode_indices, tmp_eqn_indices_0, 2 * sizeof(int));
  nonLinearSystemData[0].torn_plus_residual_size = 2;
}

#if defined(__cplusplus)
}
#endif
