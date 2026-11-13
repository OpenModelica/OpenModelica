/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#include <float.h>
#include <math.h>
#include <string.h>

#include "../arrayIndex.h"

#include "dae_mode.h"
#include "kinsolSolver.h"
#include "nonlinearSystem.h"

#ifdef __cplusplus
extern "C" {
#endif

/* EVAL_DYNAMIC = 1000 */
const int EVAL_DYNAMIC = 1;
/* EVAL_ALGEBRAIC = 0100 */
const int EVAL_ALGEBRAIC = 2;
/* EVAL_ZEROCROSS = 0010 */
const int EVAL_ZEROCROSS = 4;
/* EVAL_DISCRETE = 0001 */
const int EVAL_DISCRETE = 8;
/* EVAL_ALL = 1111 */
const int EVAL_ALL = 15;


/*! \fn void evaluateDAEResiduals_wrapperEventUpdate
 *
 * wrapper function of the main evaluation function for DAE mode
 */
int evaluateDAEResiduals_wrapperEventUpdate(DATA* data, threadData_t* threadData)
{
  int retVal;

  data->simulationInfo->discreteCall = 1;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_DISCRETE);
  data->simulationInfo->discreteCall = 0;

  return retVal;
}

/*! \fn void evaluateDAEResiduals_wrapperZeroCrossingsEquations
 *
 * wrapper function of the ZeroCrossing function for DAE mode
 */
int evaluateDAEResiduals_wrapperZeroCrossingsEquations(DATA* data, threadData_t* threadData)
{
  int retVal;
  retVal = data->simulationInfo->daeModeData->evaluateDAEResiduals(data, threadData, EVAL_ZEROCROSS);

  return retVal;
}

/*! \fn void getAlgebraicDAEVarNominals
 *
 *  collects DAE mode algebraic nominal values from modelData
 */
void getAlgebraicDAEVarNominals(DATA* data, double *algebraicNominals)
{
  int i;

  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraicNominals[i] = getPositiveNominalFromScalarIdx(data->simulationInfo, data->modelData, VAR_KIND_VARIABLE, daeModeData->algIndexes[i]);
  }
}

/*! \fn getAlgebraicVars
 *
 *  function obtains algebraic variable values for DAEmode
 */
void getAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    algebraic[i] = data->localData[0]->realVars[daeModeData->algIndexes[i]];
  }
}

/*! \fn setAlgebraicVars
 *
 *  function set algebraic variable values for DAEmode
 */
void setAlgebraicDAEVars(DATA *data, double* algebraic)
{
  int i;
  DAEMODE_DATA* daeModeData = data->simulationInfo->daeModeData;
  for(i=0; i < daeModeData->nAlgebraicDAEVars; i++){
    data->localData[0]->realVars[daeModeData->algIndexes[i]] = algebraic[i];
  }
}

/* ---------------------------------------------------------------------------
 * A --daeMode model run as an ODE (fmi-ls-dae's ODE mode): at the time and
 * states the model holds, F(t, x, der(x), z) = 0 is a nonlinear system in
 * der(x) and the algebraic DAE variables z. This part only describes that
 * system as a NONLINEAR_SYSTEM_DATA; solveNLS solves it like any other.
 * ------------------------------------------------------------------------- */

/* The unknowns of the residual: der(x), then the algebraic DAE variables. */
static double* daeUnknown(DATA *data, int j)
{
  long nStates = data->modelData->nStates;
  return j < nStates ? &data->localData[0]->realVars[nStates + j]
                     : &data->localData[0]->realVars[data->simulationInfo->daeModeData->algIndexes[j - nStates]];
}

/* residualFunc of the system: F at the unknowns x. */
static void daeModeExplicitResidual(RESIDUAL_USERDATA *userData, const double *x, double *res, const int *iflag)
{
  DATA *data = userData->data;
  DAEMODE_DATA *daeModeData = data->simulationInfo->daeModeData;
  int j, n = (int) daeModeData->nResidualVars;
  (void) iflag;
  for (j = 0; j < n; j++) {
    *daeUnknown(data, j) = x[j];
  }
  daeModeData->evaluateDAEResiduals(data, userData->threadData, EVAL_DYNAMIC);
  memcpy(res, daeModeData->residualVars, n * sizeof(double));
}

/* The residual's sparsity pattern, if it is complete and colored. Its columns
 * are the unknowns: DAE-mode differentiation folds der(x) into x, so a der(x)
 * column has the pattern of x's. NULL for a dense Jacobian. */
static SPARSE_PATTERN* usablePattern(DAEMODE_DATA *daeModeData)
{
  SPARSE_PATTERN *sp = daeModeData->sparsePattern;
  unsigned int c, k, n = daeModeData->nResidualVars;
  if (!sp || sp->sizeCols != n || sp->maxColors == 0) {
    return NULL;
  }
  for (c = 0; c < n; c++) {
    if (sp->colorCols[c] == 0 || sp->colorCols[c] > sp->maxColors) {
      return NULL;
    }
    for (k = sp->leadindex[c]; k < sp->leadindex[c+1]; k++) {
      if (sp->index[k] >= n) {
        return NULL;
      }
    }
  }
  return sp;
}

/*! \fn initDAEModeExplicitNLS
 *
 *  The nonlinear system F(t, x, der(x), z) = 0 in der(x) and z, for an FMU of a
 *  --daeMode model that runs as an ODE, with the KINSOL data to solve it: KLU
 *  on the residual's sparsity pattern, or a dense Jacobian without one.
 *  Free it with freeDAEModeExplicitNLS.
 *
 *  Returns NULL if the residuals are not der(x) and z.
 */
NONLINEAR_SYSTEM_DATA* initDAEModeExplicitNLS(DATA *data, threadData_t *threadData)
{
  DAEMODE_DATA *daeModeData = data->simulationInfo->daeModeData;
  long j, n = daeModeData->nResidualVars, nStates = data->modelData->nStates;
  NONLINEAR_SYSTEM_DATA *nlsData;
  struct dataSolver *solverData;
  NLS_USERDATA *userData;

  if (n <= 0 || daeModeData->nAlgebraicDAEVars + nStates != n) {
    return NULL;
  }

  nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL, "Out of memory");
  nlsData->size = n;
  nlsData->equationIndex = -1;
  nlsData->nlsx = (double*) calloc(n, sizeof(double));
  nlsData->nlsxExtrapolation = (double*) calloc(n, sizeof(double));
  nlsData->nlsxOld = (double*) calloc(n, sizeof(double));
  nlsData->resValues = (double*) calloc(n, sizeof(double));
  nlsData->positiveNominal = (double*) calloc(n, sizeof(double));
  nlsData->nominalSign = (double*) calloc(n, sizeof(double));
  nlsData->min = (double*) calloc(n, sizeof(double));
  nlsData->max = (double*) calloc(n, sizeof(double));

  /* der(x) has no nominal of its own; z has its variable's. No bounds. */
  for (j = 0; j < n; j++) {
    nlsData->positiveNominal[j] = 1.0;
    nlsData->nominalSign[j] = 1.0;
    nlsData->min[j] = -DBL_MAX;
    nlsData->max[j] = DBL_MAX;
  }
  getAlgebraicDAEVarNominals(data, nlsData->positiveNominal + nStates);

  nlsData->residualFunc = daeModeExplicitResidual;
  nlsData->sparsePattern = usablePattern(daeModeData);
  nlsData->analyticalJacobianColumn = NULL;
  nlsData->jacobianIndex = -1;

  userData = initNlsUserData(data, threadData, -1, nlsData, NULL);
  solverData = (struct dataSolver*) calloc(1, sizeof(struct dataSolver));
  nlsData->nlsMethod = NLS_KINSOL;
  nlsData->nlsLinearSolver = nlsData->sparsePattern ? NLS_LS_KLU : NLS_LS_DEFAULT;
  solverData->ordinaryData = (void*) nlsKinsolAllocate(n, userData, FALSE, nlsData->sparsePattern != NULL);
  nlsData->solverData = solverData;
  return nlsData;
}

/*! \fn freeDAEModeExplicitNLS
 *
 *  Frees what initDAEModeExplicitNLS allocated. The sparsity pattern belongs
 *  to daeModeData.
 */
void freeDAEModeExplicitNLS(NONLINEAR_SYSTEM_DATA *nlsData)
{
  struct dataSolver *solverData;
  if (!nlsData) {
    return;
  }
  solverData = (struct dataSolver*) nlsData->solverData;
  if (solverData) {
    nlsKinsolFree((NLS_KINSOL_DATA*) solverData->ordinaryData); /* and its NLS_USERDATA */
    free(solverData);
  }
  free(nlsData->nlsx);
  free(nlsData->nlsxExtrapolation);
  free(nlsData->nlsxOld);
  free(nlsData->resValues);
  free(nlsData->positiveNominal);
  free(nlsData->nominalSign);
  free(nlsData->min);
  free(nlsData->max);
  free(nlsData);
}

/*! \fn solveDAEModeExplicit
 *
 *  Solves the system of initDAEModeExplicitNLS with solveNLS, from the values
 *  der(x) and z hold, and leaves the model evaluated at the solution.
 *
 *  Returns 0 on success.
 */
int solveDAEModeExplicit(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA *nlsData)
{
  RESIDUAL_USERDATA userData = {.data = data, .threadData = threadData, .solverData = NULL};
  NLS_SOLVER_STATUS status;
  long j, n;

  if (!nlsData) {
    return -1;
  }
  n = nlsData->size;
  for (j = 0; j < n; j++) {
    nlsData->nlsx[j] = nlsData->nlsxExtrapolation[j] = nlsData->nlsxOld[j] = *daeUnknown(data, j);
  }
  status = solveNLS(data, threadData, nlsData);
  if (status == NLS_FAILED) {
    return -1;
  }
  /* The solver's last evaluation need not be at its solution. */
  daeModeExplicitResidual(&userData, nlsData->nlsx, nlsData->resValues, NULL);
  return 0;
}

#ifdef __cplusplus
}
#endif
