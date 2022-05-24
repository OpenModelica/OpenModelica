/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! \file gbode.c
 *  Implementation of  a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau
 *
 *  \author bbachmann
 */

#include <time.h>

#include "gbode.h"

#include <float.h>
#include <math.h>
#include <string.h>

#include "external_input.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "util/varinfo.h"
#include "util/jacobian_util.h"
#include "epsilon.h"

// help functions
void printVector_gb(char name[], double* a, int n, double time);
void printIntVector_gb(char name[], int* a, int n, double time);
void printMatrix_gb(char name[], double* a, int n, double time);


// singlerate step function
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_MS_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

void residual_MS_MR(void **dataIn, const double *xloc, double *res, const int *iflag);
void residual_DIRK_MR(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_MR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

SPARSE_PATTERN* initializeSparsePattern_MS(DATA* data, NONLINEAR_SYSTEM_DATA* sysData);
SPARSE_PATTERN* initializeSparsePattern_DIRK(DATA* data, NONLINEAR_SYSTEM_DATA* sysData);
void ColoringAlg(SPARSE_PATTERN* sparsePattern, int sizeRows, int sizeCols, int nStages);


// step size control function
double IController(double* err_values, double* stepSize_values, double err_order);
double PIController(double* err_values, double* stepSize_values, double err_order);

double checkForEvents(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double timeLeft, double* leftValues, double timeRight, double* rightValues);

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagoanl implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_MR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {

  // This needs to be done each time, the fast states change!
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if (initSparsPattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_MS(data, nonlinsys);
    //nonlinsys->sparsePattern = initializeSparsePattern_DIRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
  return;
}

struct RK_USER_DATA_MR {
  DATA* data;
  threadData_t* threadData;
  DATA_GBODEF* gbfData;
};

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};


/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gbfData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData) {
  assertStreamPrint(threadData, gbfData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gbfData->nStates;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gbfData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    // nlsData->analyticalJacobianColumn = NULL;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    // gbfData->symJacAvailable = FALSE;
    gbfData->symJacAvailable = TRUE;
    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS_MR;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    gbfData->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gbfData->type);
    break;
  }

  /* allocate system data */
  nlsData->nlsx = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxExtrapolation = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxOld = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->resValues = (double*) malloc(nlsData->size*sizeof(double));

  nlsData->lastTimeSolved = 0.0;

  nlsData->nominal = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->min = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->max = (double*) malloc(nlsData->size*sizeof(double));

  // // TODO: Do we need to initialize the Jacobian or is it already initialized?
  // ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  // data->callback->initialAnalyticJacobianA(data, threadData, jacobian_ODE);
  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  gbfData->jacobian = initAnalyticJacobian(gbfData->nlSystemSize, gbfData->nlSystemSize, gbfData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gbfData->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case RK_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (gbfData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gbfData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", GM_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Function allocates memory needed for chosen gbodef method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGbodef(DATA* data, threadData_t *threadData, DATA_GBODE* gbData)
{
  DATA_GBODEF* gbfData = (DATA_GBODEF*) malloc(sizeof(DATA_GBODEF));
  gbData->gbfData = gbfData;

  gbfData->nStates = gbData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gbfData->GM_method = getGM_method(FLAG_MR);
  gbfData->tableau = initButcherTableau(gbfData->GM_method, FLAG_MR_ERR);
  if (gbfData->tableau == NULL){
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gbfData->tableau, gbfData->nStates, &gbfData->nlSystemSize, &gbfData->type);

  if (gbfData->GM_method == MS_ADAMS_MOULTON) {
    gbfData->nlSystemSize = gbfData->nStates;
    gbfData->step_fun = &(full_implicit_MS_MR);
    gbfData->type = MS_TYPE_IMPLICIT;
    gbfData->isExplicit = FALSE;
  }

  switch (gbfData->type)
  {
  case GM_TYPE_EXPLICIT:
    gbfData->isExplicit = TRUE;
    gbfData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case GM_TYPE_DIRK:
    gbfData->isExplicit = FALSE;
    gbfData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case MS_TYPE_IMPLICIT:
    gbfData->isExplicit = FALSE;
    gbfData->step_fun = &(full_implicit_MS_MR);
    break;

  case GM_TYPE_IMPLICIT:
    errorStreamPrint(LOG_STDOUT, 0, "Fully Implicit RK method is not supported for the fast states integration!");
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);

    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", gbfData->tableau->fac);

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_SR_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gbfData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "PIController is use for step size control");
  } else
  {
    gbfData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "IController is use for step size control");
  }

  // allocate memory for the generic RK method
  gbfData->y = malloc(sizeof(double)*gbfData->nStates);
  gbfData->yOld = malloc(sizeof(double)*gbfData->nStates);
  gbfData->yt = malloc(sizeof(double)*gbfData->nStates);
  gbfData->f = malloc(sizeof(double)*gbfData->nStates);
  if (!gbfData->isExplicit) {
    gbfData->Jf = malloc(sizeof(double)*gbfData->nStates*gbfData->nStates);
    for (int i=0; i<gbfData->nStates*gbfData->nStates; i++)
      gbfData->Jf[i] = 0;

  } else {
    gbfData->Jf = NULL;
  }
  gbfData->k = malloc(sizeof(double)*gbfData->nStates*gbfData->tableau->nStages);
  gbfData->x = malloc(sizeof(double)*gbfData->nStates*gbfData->tableau->nStages);
  gbfData->res_const = malloc(sizeof(double)*gbfData->nStates);
  gbfData->errest = malloc(sizeof(double)*gbfData->nStates);
  gbfData->errtol = malloc(sizeof(double)*gbfData->nStates);
  gbfData->err = malloc(sizeof(double)*gbfData->nStates);
  gbfData->ringBufferSize = 5;
  gbfData->errValues = malloc(sizeof(double)*gbfData->ringBufferSize);
  gbfData->stepSizeValues = malloc(sizeof(double)*gbfData->ringBufferSize);

  gbfData->nFastStates = gbfData->nStates;
  gbfData->nSlowStates = 0;
  gbfData->fastStates_old = malloc(sizeof(int)*gbfData->nStates);
  gbfData->nFastStates_old = gbfData->nFastStates;
  for (int i=0; i<gbfData->nStates; i++)
  {
    gbfData->fastStates_old[i] = i;
  }

  printButcherTableau(gbfData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gbfData->stepsDone = 0;
  gbfData->evalFunctionODE = 0;
  gbfData->evalJacobians = 0;
  gbfData->errorTestFailures = 0;
  gbfData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gbfData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gbfData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    } else {
      gbfData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    gbfData->nlsSolverMethod = getGM_NLS_METHOD(FLAG_MR_NLS);
    //gbfData->nlsSolverMethod = RK_NLS_NEWTON;
    gbfData->nlsData = initRK_NLS_DATA_MR(data, threadData, gbfData);
    if (!gbfData->nlsData) {
      return -1;
    }
  }  else
  {
    gbfData->symJacAvailable = FALSE;
    gbfData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gbfData->nlsData = NULL;
    gbfData->jacobian = NULL;
  }

  const char* flag_Interpolation = omc_flagValue[FLAG_MR_INT];

  if (flag_Interpolation != NULL) {
    gbfData->interpolation = 1;
    infoStreamPrint(LOG_SOLVER, 0, "Linear interpolation is used for the slow states");
  } else
  {
    gbfData->interpolation = 2;
    infoStreamPrint(LOG_SOLVER, 0, "Hermite interpolation is used for the slow states");
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGbf(DATA_GBODEF* gbfData) {
  /* Free non-linear system data */
  if(gbfData->nlsData != NULL) {
    struct dataSolver* dataSolver = gbfData->nlsData->solverData;
    switch (gbfData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gbData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled GM_NLS_METHOD in freeDataGbf. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gbfData->nlsData);
  }

  /* Free Jacobian */
  freeAnalyticJacobian(gbfData->jacobian);

  freeButcherTableau(gbfData->tableau);

  free(gbfData->y);
  free(gbfData->yOld);
  free(gbfData->yt);
  free(gbfData->f);
  free(gbfData->Jf);
  free(gbfData->k);
  free(gbfData->x);
  free(gbfData->res_const);
  free(gbfData->errest);
  free(gbfData->errtol);
  free(gbfData->err);
  free(gbfData->errValues);
  free(gbfData->stepSizeValues);
  free(gbfData->fastStates_old);

  free(gbfData);
  gbfData = NULL;

  return;
}

/**
 * @brief Initialize sparsity pattern for non-linear system of diagonal implicit Runge-Kutta methods.
 *
 * Get sparsity pattern of ODE Jacobian and edit to be non-zero on diagonal elements.
 * Coloring of ODE Jacobian will be used, if it had non-zero elements on all diagonal entries.
 * Calculate coloring otherwise.
 *
 * @param data                Runtime data struct.
 * @param sysData             Non-linear system.
 * @return SPARSE_PATTERN*    Pointer to sparsity pattern of non-linear system.
 */
SPARSE_PATTERN* initializeSparsePattern_MS(DATA* data, NONLINEAR_SYSTEM_DATA* sysData)
{
  unsigned int i,j;
  unsigned int row, col;

  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  SPARSE_PATTERN* sparsePattern_MR;
  SPARSE_PATTERN* sparsePattern_DIRK = gbData->jacobian->sparsePattern;

  int nStates = gbfData->nStates;

  /* Compute size of new sparsitiy pattern
   * Increase the size to contain non-zero elements on diagonal. */
  int sizeofIndex = sparsePattern_DIRK->sizeofIndex;

  // Allocate memory for new sparsity pattern
  sparsePattern_MR = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));

  sparsePattern_MR->sizeofIndex = sizeofIndex;
  sparsePattern_MR->numberOfNonZeros = sparsePattern_DIRK->numberOfNonZeros;
  sparsePattern_MR->maxColors = sparsePattern_DIRK->maxColors;

  sparsePattern_MR->leadindex = (unsigned int*) malloc((nStates + 1)*sizeof(unsigned int));
  memcpy(sparsePattern_MR->leadindex, sparsePattern_DIRK->leadindex, (nStates + 1)*sizeof(unsigned int));

  sparsePattern_MR->index = (unsigned int*) malloc(sizeofIndex*sizeof(unsigned int));
  memcpy(sparsePattern_MR->index, sparsePattern_DIRK->index, sizeofIndex*sizeof(unsigned int));

  sparsePattern_MR->colorCols = (unsigned int*) malloc(nStates*sizeof(unsigned int));
  memcpy(sparsePattern_MR->colorCols, sparsePattern_DIRK->colorCols, nStates*sizeof(unsigned int));

  return sparsePattern_MR;
}

/**
 * @brief Residual function for non-linear system of generic multistep methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_MS_MR(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GBODEF *gbfData = (DATA_GBODEF *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int nFastStates = gbfData->nFastStates;
  int stage_   = gbfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii < nFastStates;ii++) {
    i = gbfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_gb(data, threadData, &(gbfData->evalFunctionODE), fODE);

  for (ii=0; ii < nFastStates; ii++) {
    i = gbfData->fastStates[ii];
    res[ii] = gbfData->res_const[i] - xloc[ii] * gbfData->tableau->c[nStages-1] +
                                       fODE[i] * gbfData->tableau->b[nStages-1] * gbfData->stepSize;
  }

  return;
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_DIRK_MR(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GBODEF *gbfData = (DATA_GBODEF *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int stage_  = gbfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii<gbfData->nFastStates;ii++) {
    i = gbfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_gb(data, threadData, &(gbfData->evalFunctionODE), fODE);

  // Evaluate residual
  for (ii=0; ii<gbfData->nFastStates; ii++) {
    i = gbfData->fastStates[ii];
    res[ii] = gbfData->res_const[i] - xloc[ii] + gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  // printVector_gb("res", res, gbfData->nFastStates, gbfData->time);
  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  /* define callback to column function of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int nFastStates = gbfData->nFastStates;
  int stage_ = gbfData->act_stage;

  // printSparseStructure(gbfData->jacobian->sparsePattern,
  //                     nFastStates,
  //                     nFastStates,
  //                     LOG_STDOUT,
  //                     "sparsePattern");

  for (i=0; i<jacobian_ODE->sizeCols; i++)
    jacobian_ODE->seedVars[i] = 0;
  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii=0; ii<nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // update timeValue and unknown vector based on the active column "stage_"
  //sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbfData->fastStates[ii];
    if (gbfData->type == MS_TYPE_IMPLICIT) {
      jacobian->resultVars[ii] = gbfData->tableau->b[nStages-1] * gbfData->stepSize * jacobian_ODE->resultVars[i];
    } else {
      jacobian->resultVars[ii] = gbfData->stepSize * gbfData->tableau->A[stage_ * gbfData->tableau->nStages + stage_] * jacobian_ODE->resultVars[i];
    }
    /* -1 on diagonal elements */
    if (jacobian->seedVars[ii] == 1) {
      jacobian->resultVars[ii] -= 1;
    }
  }
  // printVector_gb("jacobian_ODE colums", jacobian_ODE->resultVars, nFastStates, gbfData->time);
  // printVector_gb("jacobian colums", jacobian->resultVars, nFastStates, gbfData->time);
  // printIntVector_gb("sparsity pattern colors", jacobian->sparsePattern->colorCols, nFastStates, gbfData->time);

  return 0;
}

/**
 * @brief Generic multistep function.
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int full_implicit_MS_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // printVector_gb("k:  ", gbfData->k + 0 * nStates, nStates, gbfData->time);
  // printVector_gb("k:  ", gbfData->k + 1 * nStates, nStates, gbfData->time);
  // printVector_gb("x:  ", gbfData->x + 0 * nStates, nStates, gbfData->time);
  // printVector_gb("x:  ", gbfData->x + 1 * nStates, nStates, gbfData->time);

  // Is this necessary???
  // gbfData->data = (void*) data;
  // gbfData->threadData = threadData;

  /* Predictor Schritt */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->yt[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                          gbfData->k[stage_ * nStates + i] * gbfData->tableau->bt[stage_] *  gbfData->stepSize;
    }
    gbfData->yt[i] += gbfData->k[stage_ * nStates + i] * gbfData->tableau->bt[stage_] * gbfData->stepSize;
    gbfData->yt[i] /= gbfData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->res_const[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                                 gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] *  gbfData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbfData->time + gbfData->stepSize;
  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
if (gbfData->interpolation == 1) {
    linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                            gbfData->endTime,    gbfData->yEnd,
                            sData->timeValue,    sData->realVars,
                            gbfData->nSlowStates, gbfData->slowStates);

  } else {
    hermite_interpolation_gbf(gbfData->startTime,  gbfData->yStart, gbfData->kStart,
                              gbfData->endTime,    gbfData->yEnd,   gbfData->kEnd,
                              sData->timeValue,    sData->realVars,
                              gbfData->nSlowStates, gbfData->slowStates);
  }

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gbfData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gbData->multi_rate_phase = 1;

  if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbodef error: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gbfData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->y[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                         gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] *  gbfData->stepSize;
    }
    gbfData->y[i] += gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] * gbfData->stepSize;
    gbfData->y[i] /= gbfData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gbfData->x + stage_ * nStates, gbfData->y, nStates*sizeof(double));

  return 0;
}

/*!	\fn expl_diag_impl_RK
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage, stage_;

  int nStates = data->modelData->nStates;
  int nFastStates = gbfData->nFastStates;
  int nStages = gbfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
    if (gbfData->interpolation == 1) {
    linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                            gbfData->endTime,    gbfData->yEnd,
                            gbfData->time,       gbfData->yOld,
                            gbfData->nSlowStates, gbfData->slowStates);

  } else {
    hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                              gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                              gbfData->time,      gbfData->yOld,
                              gbfData->nSlowStates, gbfData->slowStates);

  }
  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gbfData->time;
  memcpy(sData->realVars, gbfData->yOld, nStates*sizeof(double));
  wrapper_f_gb(data, threadData, &(gbfData->evalFunctionODE), fODE);
  memcpy(gbfData->k, fODE, nStates*sizeof(double));

  for (stage = 0; stage < nStages; stage++)
  {
    gbfData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++)
    {
      gbfData->res_const[i] = gbfData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gbfData->res_const[i] += gbfData->stepSize * gbfData->tableau->A[stage * nStages + stage_] * gbfData->k[stage_ * nStates + i];
    }

    // set simulation time with respect to the current stage
    sData->timeValue = gbfData->time + gbfData->tableau->c[stage]*gbfData->stepSize;

    // index of diagonal element of A
    if (gbfData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gbfData->res_const, nStates*sizeof(double));
        wrapper_f_gb(data, threadData, &(gbfData->evalFunctionODE), fODE);
      }
//      memcpy(gbfData->x + stage_ * nStates, gbfData->res_const, nStates*sizeof(double));
    }
    else
    {
      // interpolate the slow states on the time of the current stage
    if (gbfData->interpolation == 1) {
      linear_interpolation_gbf(gbfData->startTime,  gbfData->yStart,
                               gbfData->endTime,    gbfData->yEnd,
                               sData->timeValue,    sData->realVars,
                               gbfData->nSlowStates, gbfData->slowStates);
      } else {
        hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                                  gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                                  sData->timeValue,   sData->realVars,
                                  gbfData->nSlowStates, gbfData->slowStates);

      }
      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gbfData->yOld[gbfData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (ii=0; ii<nFastStates; ii++) {
          i = gbfData->fastStates[ii];
          nlsData->nlsx[ii] = gbfData->yOld[i] + gbfData->tableau->c[stage_] * gbfData->stepSize * gbfData->k[i];
      }
      //memcpy(nlsData->nlsx, gbfData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gbData->multi_rate_phase = 1;

      if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();
        solved = solveNLS(data, threadData, nlsData, -1);
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
      } else {
        solved = solveNLS(data, threadData, nlsData, -1);
      }

      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "gbodef error: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(gbfData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  }

  for (ii=0; ii<nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gbfData->y[i]  = gbfData->yOld[i];
    gbfData->yt[i] = gbfData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbfData->y[i]  += gbfData->stepSize * gbfData->tableau->b[stage_]  * (gbfData->k + stage_ * nStates)[i];
      gbfData->yt[i] += gbfData->stepSize * gbfData->tableau->bt[stage_] * (gbfData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/*! \fn gbodef_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'gm'
 */
int gbodef_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  double stopTime = data->simulationInfo->stopTime;

  double err, eventTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;

  int i, ii, j, jj, l, ll, r, rr;
  int integrator_step_info;

  int nStates = data->modelData->nStates;
  int nFastStates = gbData->nFastStates;

  // This is the target time of the main integrator
  double innerTargetTime = fmin(targetTime, gbData->timeRight);

  // BB ToDo: needs to be performed also after an event!!!
  if (gbfData->didEventStep)
  {
     /* reset statistics because it is accumulated in solver_main.c */
    gbfData->stepsDone = 0;
    gbfData->evalFunctionODE = 0;
    gbfData->evalJacobians = 0;
    gbfData->errorTestFailures = 0;
    gbfData->convergenceFailures = 0;

    gbfData->time = gbData->time;
    gbfData->stepSize = gbData->lastStepSize;
    // BB ToDO: Copy only fast states!!
    memcpy(gbfData->yOld, gbData->yOld, sizeof(double)*gbData->nStates);
    gbfData->didEventStep = FALSE;
    if (gbfData->type == MS_TYPE_IMPLICIT) {
      memcpy(gbfData->x, gbData->x, nStates*sizeof(double));
      memcpy(gbfData->k, gbData->k, nStates*sizeof(double));
    }
  }
//  gbfData->stepSize    = fmin(gbfData->stepSize, gbData->timeRight - gbfData->time);
  gbfData->startTime   = gbData->timeLeft;
  gbfData->endTime     = gbData->timeRight;
  gbfData->yStart      = gbData->yLeft;
  gbfData->kStart      = gbData->kLeft;
  gbfData->yEnd        = gbData->yRight;
  gbfData->kEnd        = gbData->kRight;
  gbfData->fastStates  = gbData->fastStates;
  gbfData->slowStates  = gbData->slowStates;
  gbfData->nFastStates = gbData->nFastStates;
  gbfData->nSlowStates = gbData->nSlowStates;

  if (!gbfData->isExplicit) {
    struct dataSolver *solverDataStruct = gbfData->nlsData->solverData;
    // set number of non-linear variables and corresponding nominal values (changes dynamically during simulation)
    gbfData->nlsData->size = gbfData->nFastStates;
    switch (gbfData->nlsSolverMethod)
    {
      case  RK_NLS_NEWTON:
        ((DATA_NEWTON*) solverDataStruct->ordinaryData)->n = gbfData->nFastStates;
        break;
      case  RK_NLS_KINSOL:
        ((NLS_KINSOL_DATA*) solverDataStruct->ordinaryData)->size = gbfData->nFastStates;
        break;
      default:
        errorStreamPrint(LOG_STDOUT, 0, "NLS method %s not yet implemented.", GM_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
        return -1;
        break;
    }

    infoStreamPrint(LOG_MULTIRATE, 1, "Fast states and corresponding nominal values:");
    for (ii=0; ii<nFastStates; ii++) {
      i = gbfData->fastStates[ii];
    // Get the nominal values of the fast states
      gbfData->nlsData->nominal[ii] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
      infoStreamPrint(LOG_MULTIRATE, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbData->nlsData->nominal[i]);
    }
    messageClose(LOG_MULTIRATE);

    modelica_boolean fastStateChange = FALSE;
    if (gbfData->nFastStates != gbfData->nFastStates_old) {
      infoStreamPrint(LOG_SOLVER, 0, "Number of fast states changed from %d to %d", gbfData->nFastStates, gbfData->nFastStates_old);
      fastStateChange = TRUE;
    }
    for (int k=0; k<nFastStates; k++) {
      if (gbfData->fastStates[k] - gbfData->fastStates_old[k]) {
        if(ACTIVE_STREAM(LOG_MULTIRATE))
        {
          printIntVector_gb("old fast States:", gbfData->fastStates_old, gbfData->nFastStates_old, gbData->time);
          printIntVector_gb("new fast States:", gbfData->fastStates, gbfData->nFastStates, gbData->time);
        }
        fastStateChange = TRUE;
        break;
      }
    }

    if (gbfData->symJacAvailable && fastStateChange) {

      // The following assumes that the fastStates are sorted (i.e. [0, 2, 6, 7, ...])
      SPARSE_PATTERN* sparsePattern_DIRK = gbData->jacobian->sparsePattern;
      SPARSE_PATTERN* sparsePattern_MR = gbfData->jacobian->sparsePattern;

      /* Set sparsity pattern for the fast states */
      ii = 0;
      jj = 0;
      ll = 0;

      sparsePattern_MR->leadindex[0] = sparsePattern_DIRK->leadindex[0];
      for(rr=0; rr < nFastStates; rr++) {
        r = gbfData->fastStates[rr];
        ii = 0;
        for(jj = sparsePattern_DIRK->leadindex[r]; jj < sparsePattern_DIRK->leadindex[r+1];) {
          i = gbfData->fastStates[ii];
          j = sparsePattern_DIRK->index[jj];
          if( i == j) {
            sparsePattern_MR->index[ll] = ii;
            ll++;
          }
          if (j>i) {
            ii++;
            if (ii >= nFastStates)
              break;
          } else
            jj++;
        }
        sparsePattern_MR->leadindex[rr+1] = ll;
      }

      sparsePattern_MR->numberOfNonZeros = ll;
      sparsePattern_MR->sizeofIndex = ll;

      ColoringAlg(sparsePattern_MR, nFastStates, nFastStates, 1);

      gbfData->jacobian->sizeCols = nFastStates;
      gbfData->jacobian->sizeRows = nFastStates;

      printSparseStructure(sparsePattern_MR,
                           nFastStates,
                           nFastStates,
                           LOG_MULTIRATE,
                          "sparsePattern_MR");

    }
  }

  // print informations on the calling details
  infoStreamPrint(LOG_SOLVER, 0, "gbodef solver started (fast states): %d", gbData->nFastStates);
  infoStreamPrint(LOG_SOLVER, 0, "interpolation is done between %10g to %10g (SR-stepsize: %10g)",
                  gbData->timeLeft, gbData->timeRight, gbData->lastStepSize);
  if(ACTIVE_STREAM(LOG_MULTIRATE))
  {
    printVector_gb("yL:     ", gbData->yLeft, gbData->nStates, gbData->timeLeft);
    printVector_gb("yR:     ", gbData->y, gbData->nStates, gbData->timeRight);
  }

  while (gbfData->time < innerTargetTime)
  {
    do
    {
      if(ACTIVE_STREAM(LOG_MULTIRATE))
      {
        //printVector_gbf("yOld: ", gbfData->yOld, gbfData->nStates, gbfData->time, gbfData->nFastStates, gbfData->fastStates);
        printVector_gb("yOld:     ", gbfData->yOld, gbfData->nStates, gbfData->time);
      }

      // calculate one step of the integrator
      integrator_step_info = gbfData->step_fun(data, threadData, solverInfo);

      // error handling: try half of the step size!
      if (integrator_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "gbodef_step: Failed to calculate step at time = %5g.", gbfData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gbfData->stepSize = gbfData->stepSize/2.;
        continue;
        //return -1;
      }

      for (i=0; i<nFastStates; i++)
      {
        ii = gbfData->fastStates[i];
        // calculate corresponding values for the error estimator and step size control
        gbfData->errtol[ii] = Rtol*fmax(fabs(gbfData->y[ii]),fabs(gbfData->yt[ii])) + Atol;
        gbfData->errest[ii] = fabs(gbfData->y[ii] - gbfData->yt[ii]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i < nFastStates; i++)
      {
        ii = gbfData->fastStates[i];
        gbfData->err[ii] = gbfData->errest[ii]/gbfData->errtol[ii];
        err = fmax(err, gbfData->err[ii]);
      }

      err = gbfData->tableau->fac * err;
      gbfData->errValues[0] = err;
      gbfData->stepSizeValues[0] = gbfData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      gbfData->lastStepSize = gbfData->stepSize;

      // Call the step size control
      gbfData->stepSize *= gbfData->stepSize_control(gbfData->errValues, gbfData->stepSizeValues, gbfData->tableau->error_order);

      // Re-do step, if error is larger than requested
      if (err>1)
      {
        gbfData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbfData->time, gbfData->time + gbfData->lastStepSize, err, gbfData->stepSize);
      }
    } while  (err>1);

    // Count succesful integration steps
    gbfData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gbfData->ringBufferSize-1); i++) {
      gbfData->errValues[i+1] = gbfData->errValues[i];
      gbfData->stepSizeValues[i+1] = gbfData->stepSizeValues[i];
    }

    if (gbfData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gbfData->tableau->nStages-1); stage_++) {
        memcpy(gbfData->k + stage_ * nStates, gbfData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gbfData->x + stage_ * nStates, gbfData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
    }

    // interpolate the slow states to the boundaries of current integration interval, this is used for event detection
      // interpolate the slow states on the time of the current stage
    if (gbfData->interpolation == 1) {
      linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                               gbfData->endTime,   gbfData->yEnd,
                               gbfData->time,      gbfData->yOld,
                               gbfData->nSlowStates, gbfData->slowStates);
      linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                               gbfData->endTime,   gbfData->yEnd,
                               gbfData->time + gbfData->lastStepSize, gbfData->y,
                               gbfData->nSlowStates, gbfData->slowStates);
    } else {
      hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                                gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                                gbfData->time,      gbfData->yOld,
                                gbfData->nSlowStates, gbfData->slowStates);
      hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                                gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                                gbfData->time + gbfData->lastStepSize, gbfData->y,
                                gbfData->nSlowStates, gbfData->slowStates);
    }

    eventTime = checkForEvents(data, threadData, solverInfo, gbfData->time, gbfData->yOld, gbfData->time + gbfData->lastStepSize, gbfData->y);
    if (eventTime > 0)
    {
      solverInfo->currentTime = eventTime;
      sData->timeValue = solverInfo->currentTime;

      // sData->realVars are the "numerical" values on the right hand side of the event
      gbData->time = eventTime;
      memcpy(gbData->yOld, sData->realVars, gbfData->nStates * sizeof(double));

      gbfData->time = eventTime;
      memcpy(gbfData->yOld, sData->realVars, gbfData->nStates * sizeof(double));

      /* write statistics to the solverInfo data structure */
      solverInfo->solverStatsTmp[0] = gbfData->stepsDone;
      solverInfo->solverStatsTmp[1] = gbfData->evalFunctionODE;
      solverInfo->solverStatsTmp[2] = gbfData->evalJacobians;
      solverInfo->solverStatsTmp[3] = gbfData->errorTestFailures;
      solverInfo->solverStatsTmp[4] = gbfData->convergenceFailures;

      if(ACTIVE_STREAM(LOG_SOLVER))
      {
        messageClose(LOG_SOLVER);
      }
      // Get out of the integration routine for event handling
      return 1;
    }

    /* update time with performed stepSize */
    gbfData->time += gbfData->lastStepSize;
    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printVector_gb("y:        ", gbfData->y, gbfData->nStates, gbfData->time);
    }


    /* step is accepted and yOld needs to be updated, store yOld for later interpolation... */
    memcpy(gbfData->yt, gbfData->yOld, nStates);

    /* step is accepted and yOld needs to be updated */
    copyVector_gbf(gbfData->yOld, gbfData->y, nFastStates, gbfData->fastStates);
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gbfData->time- gbfData->lastStepSize, gbfData->time, err, gbfData->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = gbfData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbfData->y, nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }

    // Dont disturb the inner step size control!!
    if (gbfData->time + gbfData->stepSize > stopTime)
      gbfData->stepSize = stopTime - gbfData->time;

    // Dont disturb the inner step size control!!
    // if (gbfData->time + gbfData->stepSize > innerTargetTime)
    //   break;
    gbfData->stepSize_old = gbfData->stepSize;
    if (gbfData->time + gbfData->stepSize > innerTargetTime) {
      gbfData->stepSize = innerTargetTime - gbfData->time;
    }
    if ((innerTargetTime - gbfData->time) < DASSL_STEP_EPS){
      gbfData->time = innerTargetTime;
      break;
    }
  }
  gbfData->stepSize = gbfData->stepSize_old;

  // restore the last predicted step size, only necessary if last step size has been reduced to reach the target time
  // gbfData->stepSize = gbfData->stepSize_old;

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  gbData->err_fast = gbfData->errValues[0];

  //outer integration needs to be synchronized
  // if ((gbfData->time < gbData->timeRight) && (gbData->timeRight < targetTime))
  if  ((gbfData->time + gbfData->stepSize > gbData->timeRight) ||
        (gbData->time > targetTime) ||
        ((gbData->time < targetTime) && (gbData->time + gbData->lastStepSize > targetTime))
      )
  {
    // Resetting the time and the integrator is not a good idea!!!!
    // Just storing the values would be appropriate, integrator should keep their time, and values!!!!
    // Especially, when it comes to high order integrators
    gbData->lastStepSize = gbfData->time - gbData->timeLeft;
    gbData->timeRight = gbfData->time;
    if (gbData->time > gbData->timeLeft)
      gbData->time = gbfData->time;
    else
      gbData->time = gbData->timeLeft;

    memcpy(gbData->yOld, gbfData->yt, gbfData->nStates * sizeof(double));
    memcpy(gbData->y, gbfData->y, gbfData->nStates * sizeof(double));
    memcpy(gbData->x, gbfData->x, gbfData->nStates * sizeof(double));
    memcpy(gbData->x + gbData->tableau->nStages * nStates, gbfData->x + gbData->tableau->nStages * nStates, gbfData->nStates * sizeof(double));
    memcpy(gbData->k, gbfData->k, gbfData->nStates * sizeof(double));
    memcpy(gbData->k + gbData->tableau->nStages * nStates, gbfData->k + gbData->tableau->nStages * nStates, gbfData->nStates * sizeof(double));

    // This could be problem when gbData->y is used for interpolation, one should introduce yRight!!
    // memcpy(gbData->y, gbfData->y, gbfData->nStates * sizeof(double));

    // solverInfo->currentTime = eventTime;
    // sData->timeValue = solverInfo->currentTime;
    copyVector_gbf(gbData->err, gbfData->err, nFastStates, gbfData->fastStates);
    // copyVector_gbf(gbData->y, gbfData->y, nFastStates, gbfData->fastStates);
    // copyVector_gbf(gbData->yOld, gbfData->y, nFastStates, gbfData->fastStates);
  }

  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "gbode call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gbfData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gbfData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gbfData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gbfData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gbfData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gbfData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gbfData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = gbfData->stepsDone;
  solverInfo->solverStatsTmp[1] = gbfData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = gbfData->evalJacobians;
  solverInfo->solverStatsTmp[3] = gbfData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = gbfData->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "gbodef finished  (inner steps).");
  if(ACTIVE_STREAM(LOG_MULTIRATE))
  {
    printf("\n");
  }


  if(ACTIVE_STREAM(LOG_SOLVER))
  {
    messageClose(LOG_SOLVER);
  }

  return 0;
}

//Interpolation only some entries (indices given by idx[nIdx])
void linear_interpolation_gbf(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx)
{
  double lambda, h0, h1;
  int i, ii;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (ii=0; ii<nIdx; ii++)
  {
    i = idx[ii];
    f[i] = h0*fa[i] + h1*fb[i];
  }
}

void hermite_interpolation_gbf(double ta, double* fa, double* dfa, double tb, double* fb, double* dfb, double t, double* f, int nIdx, int* idx)
{
  double tt, h00, h01, h10, h11;
  int i, ii;

  tt = (t-ta)/(tb-ta);
  h00 = (1+2*tt)*(1-tt)*(1-tt);
  h10 = (tb-ta)*tt*(1-tt)*(1-tt);
  h01 = (3-2*tt)*tt*tt;
  h11 = (tb-ta)*(tt-1)*tt*tt;

  for (ii=0; ii<nIdx; ii++)
  {
    i = idx[ii];
    f[i] = h00*fa[i]+h10*dfa[i]+h01*fb[i]+h11*dfb[i];
  }
}


void printVector_gbf(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("%s\t(time = %14.8g):", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%16.12g ", a[indx[i]]);
  printf("\n");
}

void printMatrix_gbf(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%16.12g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}