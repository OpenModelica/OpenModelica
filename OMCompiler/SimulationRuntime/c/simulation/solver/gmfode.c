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

/*! \file gmode.c
 *  Implementation of  a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau
 *
 *  \author bbachmann
 */

#include "gmode.h"

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

// help functions
void printVector_gm(char name[], double* a, int n, double time);
void printIntVector_gm(char name[], int* a, int n, double time);
void printMatrix_gm(char name[], double* a, int n, double time);


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
  DATA_GMF* gmfData;
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
 * @param gmfData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GMF* gmfData) {
  assertStreamPrint(threadData, gmfData->type != GM_type_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gmfData->nStates;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gmfData->type)
  {
  case GM_type_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    // nlsData->analyticalJacobianColumn = NULL;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    // gmfData->symJacAvailable = FALSE;
    gmfData->symJacAvailable = TRUE;
    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS_MR;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    gmfData->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gmfData->type);
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
  gmfData->jacobian = initAnalyticJacobian(gmfData->nlSystemSize, gmfData->nlSystemSize, gmfData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gmfData->nlsSolverMethod) {
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
    if (gmfData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gmfData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", GM_NLS_METHOD_NAME[gmfData->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Function allocates memory needed for chosen RK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDatagmf(DATA* data, threadData_t *threadData, DATA_GM* gmData)
{
  DATA_GMF* gmfData = (DATA_GMF*) malloc(sizeof(DATA_GMF));
  gmData->gmfData = gmfData;

  gmfData->nStates = gmData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gmfData->GM_method = getGM_method(FLAG_MR);
  gmfData->tableau = initButcherTableau(gmfData->GM_method);
  if (gmfData->tableau == NULL){
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gmfData->tableau, gmfData->nStates, &gmfData->nlSystemSize, &gmfData->type);

  if (gmfData->GM_method == MS_ADAMS_MOULTON) {
    gmfData->nlSystemSize = gmfData->nStates;
    gmfData->step_fun = &(full_implicit_MS_MR);
    gmfData->type = MS_TYPE_IMPLICIT;
    gmfData->isExplicit = FALSE;
  }

  switch (gmfData->type)
  {
  case GM_type_EXPLICIT:
    gmfData->isExplicit = TRUE;
    gmfData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case GM_type_DIRK:
    gmfData->isExplicit = FALSE;
    gmfData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case MS_TYPE_IMPLICIT:
    gmfData->isExplicit = FALSE;
    gmfData->step_fun = &(full_implicit_MS_MR);
    break;

  case GM_type_IMPLICIT:
    errorStreamPrint(LOG_STDOUT, 0, "Fully Implicit RK method is not supported for the fast states integration!");
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);

    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", gmfData->tableau->fac);

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_SR_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gmfData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "PIController is use for step size control");
  } else
  {
    gmfData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "IController is use for step size control");
  }

  // allocate memory for the generic RK method
  gmfData->y = malloc(sizeof(double)*gmfData->nStates);
  gmfData->yOld = malloc(sizeof(double)*gmfData->nStates);
  gmfData->yt = malloc(sizeof(double)*gmfData->nStates);
  gmfData->f = malloc(sizeof(double)*gmfData->nStates);
  if (!gmfData->isExplicit) {
    gmfData->Jf = malloc(sizeof(double)*gmfData->nStates*gmfData->nStates);
    for (int i=0; i<gmfData->nStates*gmfData->nStates; i++)
      gmfData->Jf[i] = 0;

  } else {
    gmfData->Jf = NULL;
  }
  gmfData->k = malloc(sizeof(double)*gmfData->nStates*gmfData->tableau->nStages);
  gmfData->x = malloc(sizeof(double)*gmfData->nStates*gmfData->tableau->nStages);
  gmfData->res_const = malloc(sizeof(double)*gmfData->nStates);
  gmfData->errest = malloc(sizeof(double)*gmfData->nStates);
  gmfData->errtol = malloc(sizeof(double)*gmfData->nStates);
  gmfData->err = malloc(sizeof(double)*gmfData->nStates);
  gmfData->ringBufferSize = 5;
  gmfData->errValues = malloc(sizeof(double)*gmfData->ringBufferSize);
  gmfData->stepSizeValues = malloc(sizeof(double)*gmfData->ringBufferSize);

  gmfData->nFastStates = gmfData->nStates;
  gmfData->nSlowStates = 0;
  gmfData->fastStates_old = malloc(sizeof(int)*gmfData->nStates);
  gmfData->nFastStates_old = gmfData->nFastStates;
  for (int i=0; i<gmfData->nStates; i++)
  {
    gmfData->fastStates_old[i] = i;
  }

  printButcherTableau(gmfData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gmfData->stepsDone = 0;
  gmfData->evalFunctionODE = 0;
  gmfData->evalJacobians = 0;
  gmfData->errorTestFailures = 0;
  gmfData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gmfData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gmfData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    } else {
      gmfData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
  //gmfData->nlsSolverMethod = getGM_NLS_METHOD();
    gmfData->nlsSolverMethod = RK_NLS_NEWTON;
    gmfData->nlsData = initRK_NLS_DATA_MR(data, threadData, gmfData);
    if (!gmfData->nlsData) {
      return -1;
    }
  }  else
  {
    gmfData->symJacAvailable = FALSE;
    gmfData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gmfData->nlsData = NULL;
    gmfData->jacobian = NULL;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDatagmf(DATA_GMF* gmfData) {
  /* Free non-linear system data */
  if(gmfData->nlsData != NULL) {
    struct dataSolver* dataSolver = gmfData->nlsData->solverData;
    switch (gmfData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gmData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled GM_NLS_METHOD in freeDatagm. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gmfData->nlsData);
  }

  /* Free Jacobian */
  freeAnalyticJacobian(gmfData->jacobian);

  freeButcherTableau(gmfData->tableau);

  free(gmfData->y);
  free(gmfData->yOld);
  free(gmfData->yt);
  free(gmfData->f);
  free(gmfData->Jf);
  free(gmfData->k);
  free(gmfData->x);
  free(gmfData->res_const);
  free(gmfData->errest);
  free(gmfData->errtol);
  free(gmfData->err);
  free(gmfData->errValues);
  free(gmfData->stepSizeValues);
  free(gmfData->fastStates_old);

  free(gmfData);
  gmfData = NULL;

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

  DATA_GM* gmData = (DATA_GM*) data->simulationInfo->backupSolverData;
  DATA_GMF* gmfData = gmData->gmfData;

  SPARSE_PATTERN* sparsePattern_MR;
  SPARSE_PATTERN* sparsePattern_DIRK = gmData->jacobian->sparsePattern;

  int nStates = gmfData->nStates;

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

  // /* Set full matrix sparsitiy pattern */
  // for (i=0; i < gmfData->nStates+1; i++)
  //   sparsePattern_MR->leadindex[i] = i * nStates;
  // for(i=0; i < nStates*nStates; i++) {
  //   sparsePattern_MR->index[i] = i% nStates;
  // }

  // printIntVector_gm("sparsePattern leadindex", sparsePattern_MR->leadindex, length_column_indices, 0);
  // printIntVector_gm("sparsePattern index", sparsePattern_MR->index, length_index, 0);

  // trivial coloring, needs to be set each call of MR, if number of fast States changes...
//   sparsePattern_MR->maxColors = nStates;
//   for (i=0; i < nStates; i++)
//     sparsePattern_MR->colorCols[i] = i+1;
//
  // printSparseStructure(sparsePattern_MR,
  //                     nStates,
  //                     nStates,
  //                     LOG_STDOUT,
  //                     "sparsePattern_MR");

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
  DATA_GMF *gmfData = (DATA_GMF *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmfData->tableau->nStages;
  int nFastStates = gmfData->nFastStates;
  int stage_   = gmfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii < nFastStates;ii++) {
    i = gmfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_gm(data, threadData, &(gmfData->evalFunctionODE), fODE);

  for (ii=0; ii < nFastStates; ii++) {
    i = gmfData->fastStates[ii];
    res[ii] = gmfData->res_const[i] - xloc[ii] * gmfData->tableau->c[nStages-1] +
                                       fODE[i] * gmfData->tableau->b[nStages-1] * gmfData->stepSize;
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
  DATA_GMF *gmfData = (DATA_GMF *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmfData->tableau->nStages;
  int stage_  = gmfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii<gmfData->nFastStates;ii++) {
    i = gmfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_gm(data, threadData, &(gmfData->evalFunctionODE), fODE);

  // Evaluate residual
  for (ii=0; ii<gmfData->nFastStates; ii++) {
    i = gmfData->fastStates[ii];
    res[ii] = gmfData->res_const[i] - xloc[ii] + gmfData->stepSize * gmfData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  // printVector_gm("res", res, gmfData->nFastStates, gmfData->time);
  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gmData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GM* gmData = (DATA_GM*) data->simulationInfo->backupSolverData;
  DATA_GMF* gmfData = gmData->gmfData;

  /* define callback to column function of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmfData->tableau->nStages;
  int nFastStates = gmfData->nFastStates;
  int stage_ = gmfData->act_stage;

  // printSparseStructure(gmfData->jacobian->sparsePattern,
  //                     nFastStates,
  //                     nFastStates,
  //                     LOG_STDOUT,
  //                     "sparsePattern");

  for (i=0; i<jacobian_ODE->sizeCols; i++)
    jacobian_ODE->seedVars[i] = 0;
  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii=0; ii<nFastStates; ii++)
  {
    i = gmfData->fastStates[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // update timeValue and unknown vector based on the active column "stage_"
  //sData->timeValue = gmData->time + gmData->tableau->c[stage_] * gmData->stepSize;

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (ii = 0; ii < nFastStates; ii++) {
    i = gmfData->fastStates[ii];
    if (gmfData->type == MS_TYPE_IMPLICIT) {
      jacobian->resultVars[ii] = gmfData->tableau->b[nStages-1] * gmfData->stepSize * jacobian_ODE->resultVars[i];
    } else {
      jacobian->resultVars[ii] = gmfData->stepSize * gmfData->tableau->A[stage_ * gmfData->tableau->nStages + stage_] * jacobian_ODE->resultVars[i];
    }
    /* -1 on diagonal elements */
    if (jacobian->seedVars[ii] == 1) {
      jacobian->resultVars[ii] -= 1;
    }
  }
  // printVector_gm("jacobian_ODE colums", jacobian_ODE->resultVars, nFastStates, gmfData->time);
  // printVector_gm("jacobian colums", jacobian->resultVars, nFastStates, gmfData->time);
  // printIntVector_gm("sparsity pattern colors", jacobian->sparsePattern->colorCols, nFastStates, gmfData->time);

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
  DATA_GM* gmData = (DATA_GM*)solverInfo->solverData;
  DATA_GMF* gmfData = gmData->gmfData;

  int i, ii;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gmfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // printVector_gm("k:  ", gmfData->k + 0 * nStates, nStates, gmfData->time);
  // printVector_gm("k:  ", gmfData->k + 1 * nStates, nStates, gmfData->time);
  // printVector_gm("x:  ", gmfData->x + 0 * nStates, nStates, gmfData->time);
  // printVector_gm("x:  ", gmfData->x + 1 * nStates, nStates, gmfData->time);

  // Is this necessary???
  // gmfData->data = (void*) data;
  // gmfData->threadData = threadData;

  /* Predictor Schritt */
  for (ii = 0; ii < gmfData->nFastStates; ii++)
  {
    i = gmfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gmData->k[]
    gmfData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmfData->yt[i] += -gmfData->x[stage_ * nStates + i] * gmfData->tableau->c[stage_] +
                          gmfData->k[stage_ * nStates + i] * gmfData->tableau->bt[stage_] *  gmfData->stepSize;
    }
    gmfData->yt[i] += gmfData->k[stage_ * nStates + i] * gmfData->tableau->bt[stage_] * gmfData->stepSize;
    gmfData->yt[i] /= gmfData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (ii = 0; ii < gmfData->nFastStates; ii++)
  {
    i = gmfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gmData->k[]
    gmfData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmfData->res_const[i] += -gmfData->x[stage_ * nStates + i] * gmfData->tableau->c[stage_] +
                                 gmfData->k[stage_ * nStates + i] * gmfData->tableau->b[stage_] *  gmfData->stepSize;
    }
  }
  // printVector_gm("res_const:  ", gmData->res_const, nStates, gmData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gmfData->time + gmfData->stepSize;
  // interpolate the slow states on the current time of gmfData->yOld for correct evaluation of gmfData->res_const
  linear_interpolation_MR(gmfData->startTime, gmfData->yStart,
                          gmfData->endTime, gmfData->yEnd,
                          sData->timeValue,  sData->realVars, gmfData->nSlowStates, gmfData->slowStates);


  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gmfData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gmfData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gmData->multi_rate_phase = 1;
  solved = solveNLS(data, threadData, nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_MS: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gmfData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (ii = 0; ii < gmfData->nFastStates; ii++)
  {
    i = gmfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gmData->k[]
    gmfData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmfData->y[i] += -gmfData->x[stage_ * nStates + i] * gmfData->tableau->c[stage_] +
                         gmfData->k[stage_ * nStates + i] * gmfData->tableau->b[stage_] *  gmfData->stepSize;
    }
    gmfData->y[i] += gmfData->k[stage_ * nStates + i] * gmfData->tableau->b[stage_] * gmfData->stepSize;
    gmfData->y[i] /= gmfData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gmfData->x + stage_ * nStates, gmfData->y, nStates*sizeof(double));

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
  DATA_GM* gmData = (DATA_GM*)solverInfo->solverData;
  DATA_GMF* gmfData = gmData->gmfData;

  int i, ii;
  int stage, stage_;

  int nStates = data->modelData->nStates;
  int nFastStates = gmfData->nFastStates;
  int nStages = gmfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // Is this necessary???
  // gmfData->data = (void*) data;
  // gmfData->threadData = threadData;

  // interpolate the slow states on the current time of gmfData->yOld for correct evaluation of gmfData->res_const
  linear_interpolation_MR(gmfData->startTime, gmfData->yStart,
                          gmfData->endTime,   gmfData->yEnd,
                          gmfData->time, gmfData->yOld, gmfData->nSlowStates, gmfData->slowStates);

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gmfData->time;
  memcpy(sData->realVars, gmfData->yOld, nStates*sizeof(double));
  wrapper_f_gm(data, threadData, &(gmfData->evalFunctionODE), fODE);
  memcpy(gmfData->k, fODE, nStates*sizeof(double));

  for (stage = 0; stage < nStages; stage++)
  {
    gmfData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++)
    {
      gmfData->res_const[i] = gmfData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gmfData->res_const[i] += gmfData->stepSize * gmfData->tableau->A[stage * nStages + stage_] * gmfData->k[stage_ * nStates + i];
    }

    // set simulation time with respect to the current stage
    sData->timeValue = gmfData->time + gmfData->tableau->c[stage]*gmfData->stepSize;

    // index of diagonal element of A
    if (gmfData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gmfData->res_const, nStates*sizeof(double));
        wrapper_f_gm(data, threadData, &(gmfData->evalFunctionODE), fODE);
      }
//      memcpy(gmfData->x + stage_ * nStates, gmfData->res_const, nStates*sizeof(double));
    }
    else
    {
      // interpolate the slow states on the time of the current stage
      linear_interpolation_MR(gmfData->startTime, gmfData->yStart,
                              gmfData->endTime,   gmfData->yEnd,
                              sData->timeValue, sData->realVars, gmfData->nSlowStates, gmfData->slowStates);

      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gmfData->yOld[gmfData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gmfData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (ii=0; ii<nFastStates; ii++) {
          i = gmfData->fastStates[ii];
          nlsData->nlsx[ii] = gmfData->yOld[i] + gmfData->tableau->c[stage_] * gmfData->stepSize * gmfData->k[i];
      }
      //memcpy(nlsData->nlsx, gmfData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gmData->multi_rate_phase = 1;
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(gmfData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  }

  for (ii=0; ii<nFastStates; ii++)
  {
    i = gmfData->fastStates[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gmfData->y[i]  = gmfData->yOld[i];
    gmfData->yt[i] = gmfData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gmfData->y[i]  += gmfData->stepSize * gmfData->tableau->b[stage_]  * (gmfData->k + stage_ * nStates)[i];
      gmfData->yt[i] += gmfData->stepSize * gmfData->tableau->bt[stage_] * (gmfData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/*! \fn gmf_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'gm'
 */
int gmf_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GM* gmData = (DATA_GM*)solverInfo->solverData;
  DATA_GMF* gmfData = gmData->gmfData;

  double err, eventTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;

  int i, ii, j, jj, l, ll, r, rr;
  int integrator_step_info;

  int nStates = data->modelData->nStates;
  int nFastStates = gmData->nFastStates;

  // This is the target time of the main integrator
  double innerTargetTime = fmin(targetTime, gmData->timeRight);

  // BB ToDo: needs to be performed also after an event!!!
  if (gmfData->didEventStep)
  {
     /* reset statistics because it is accumulated in solver_main.c */
    gmfData->stepsDone = 0;
    gmfData->evalFunctionODE = 0;
    gmfData->evalJacobians = 0;
    gmfData->errorTestFailures = 0;
    gmfData->convergenceFailures = 0;

    gmfData->time = gmData->time;
    gmfData->stepSize = gmData->lastStepSize;
    // BB ToDO: Copy only fast states!!
    memcpy(gmfData->yOld, gmData->yOld, sizeof(double)*gmData->nStates);
    gmfData->didEventStep = FALSE;
    if (gmfData->type == MS_TYPE_IMPLICIT) {
      memcpy(gmfData->x, gmData->x, nStates*sizeof(double));
      memcpy(gmfData->k, gmData->k, nStates*sizeof(double));
    }
  }
//  gmfData->stepSize    = fmin(gmfData->stepSize, gmData->timeRight - gmfData->time);
  gmfData->startTime   = gmData->timeLeft;
  gmfData->endTime     = gmData->timeRight;
  gmfData->yStart      = gmData->yLeft;
  gmfData->yEnd        = gmData->y;
  gmfData->fastStates  = gmData->fastStates;
  gmfData->slowStates  = gmData->slowStates;
  gmfData->nFastStates = gmData->nFastStates;
  gmfData->nSlowStates = gmData->nSlowStates;

  if (!gmfData->isExplicit) {
    struct dataSolver *solverDataStruct = gmfData->nlsData->solverData;
    // set number of non-linear variables and corresponding nominal values (changes dynamically during simulation)
    gmfData->nlsData->size = gmfData->nFastStates;
    switch (gmfData->nlsSolverMethod)
    {
      case  RK_NLS_NEWTON:
        ((DATA_NEWTON*) solverDataStruct->ordinaryData)->n = gmfData->nFastStates;
        break;
      case  RK_NLS_KINSOL:
        ((NLS_KINSOL_DATA*) solverDataStruct->ordinaryData)->size = gmfData->nFastStates;
        break;
      default:
        errorStreamPrint(LOG_STDOUT, 0, "NLS method %s not yet implemented.", GM_NLS_METHOD_NAME[gmfData->nlsSolverMethod]);
        return -1;
        break;
    }

    infoStreamPrint(LOG_SOLVER, 1, "Fast states and corresponding nominal values:");
    for (ii=0; ii<nFastStates; ii++) {
      i = gmfData->fastStates[ii];
    // Get the nominal values of the fast states
      gmfData->nlsData->nominal[ii] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
      infoStreamPrint(LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gmData->nlsData->nominal[i]);
    }
    messageClose(LOG_SOLVER);

    modelica_boolean fastStateChange = FALSE;
    if (gmfData->nFastStates != gmfData->nFastStates_old) {
      infoStreamPrint(LOG_SOLVER, 0, "Number of fast states changed from %d to %g", gmfData->nFastStates, gmfData->nFastStates_old);
      fastStateChange = TRUE;
    } else {
      for (int k=0; k<nFastStates; k++)
        if (gmfData->fastStates[k] - gmfData->fastStates_old[k]) {
          if(ACTIVE_STREAM(LOG_SOLVER))
          {
            printIntVector_gm("old fast States:", gmfData->fastStates_old, gmfData->nFastStates_old, gmData->time);
            printIntVector_gm("new fast States:", gmfData->fastStates, gmfData->nFastStates, gmData->time);
          }
          fastStateChange = TRUE;
          break;
        }
    }

    if (gmfData->symJacAvailable && fastStateChange) {

      // The following assumes that the fastStates are sorted (i.e. [0, 2, 6, 7, ...])
      SPARSE_PATTERN* sparsePattern_DIRK = gmData->jacobian->sparsePattern;
      SPARSE_PATTERN* sparsePattern_MR = gmfData->jacobian->sparsePattern;

      /* Set sparsity pattern for the fast states */
      ii = 0;
      jj = 0;
      ll = 0;

      sparsePattern_MR->leadindex[0] = sparsePattern_DIRK->leadindex[0];
      for(rr=0; rr < nFastStates; rr++) {
        r = gmfData->fastStates[rr];
        ii = 0;
        for(jj = sparsePattern_DIRK->leadindex[r]; jj < sparsePattern_DIRK->leadindex[r+1];) {
          i = gmfData->fastStates[ii];
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

      gmfData->jacobian->sizeCols = nFastStates;
      gmfData->jacobian->sizeRows = nFastStates;

      printSparseStructure(sparsePattern_MR,
                           nFastStates,
                           nFastStates,
                           LOG_MULTIRATE,
                          "sparsePattern_MR");

    }
  }

  // print informations on the calling details
  infoStreamPrint(LOG_SOLVER, 0, "generic Runge-Kutta method (fast states):");
  infoStreamPrint(LOG_SOLVER, 0, "interpolation is done between %10g to %10g (SR-stepsize: %10g)",
                  gmData->timeLeft, gmData->timeRight, gmData->lastStepSize);
  if(ACTIVE_STREAM(LOG_MULTIRATE))
  {
    printVector_gm("yL: ", gmData->yLeft, gmData->nStates, gmData->timeLeft);
    printVector_gm("yR: ", gmData->y, gmData->nStates, gmData->timeRight);
    printf("\n");
  }

  while (gmfData->time < innerTargetTime)
  {
    do
    {
      if(ACTIVE_STREAM(LOG_MULTIRATE))
      {
        //printVector_gmf("yOld: ", gmfData->yOld, gmfData->nStates, gmfData->time, gmfData->nFastStates, gmfData->fastStates);
        printVector_gm("yOld: ", gmfData->yOld, gmfData->nStates, gmfData->time);
      }

      // calculate one step of the integrator
      integrator_step_info = gmfData->step_fun(data, threadData, solverInfo);

      // error handling: try half of the step size!
      if (integrator_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "gmode_step: Failed to calculate step at time = %5g.", gmfData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gmfData->stepSize = gmfData->stepSize/2.;
        continue;
        //return -1;
      }

      for (i=0; i<nFastStates; i++)
      {
        ii = gmfData->fastStates[i];
        // calculate corresponding values for the error estimator and step size control
        gmfData->errtol[ii] = Rtol*fmax(fabs(gmfData->y[ii]),fabs(gmfData->yt[ii])) + Atol;
        gmfData->errest[ii] = fabs(gmfData->y[ii] - gmfData->yt[ii]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i < nFastStates; i++)
      {
        ii = gmfData->fastStates[i];
        gmfData->err[ii] = gmfData->errest[ii]/gmfData->errtol[ii];
        err = fmax(err, gmfData->err[ii]);
      }

      gmfData->errValues[0] = gmfData->tableau->fac * err;
      gmfData->stepSizeValues[0] = gmfData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      gmfData->lastStepSize = gmfData->stepSize;

      // Call the step size control
      gmfData->stepSize *= gmfData->stepSize_control(gmfData->errValues, gmfData->stepSizeValues, gmfData->tableau->error_order);

      // Re-do step, if error is larger than requested
      if (err>1)
      {
        gmfData->errorTestFailures++;
        infoStreamPrint(LOG_MULTIRATE, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gmfData->time, gmfData->time + gmfData->lastStepSize, err, gmfData->stepSize);
      }
    } while  (err>1);

    // Count succesful integration steps
    gmfData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gmfData->ringBufferSize-1); i++) {
      gmfData->errValues[i+1] = gmfData->errValues[i];
      gmfData->stepSizeValues[i+1] = gmfData->stepSizeValues[i];
    }

    if (gmfData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gmfData->tableau->nStages-1); stage_++) {
        memcpy(gmfData->k + stage_ * nStates, gmfData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gmfData->x + stage_ * nStates, gmfData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
    }

    // interpolate the slow states to the boundaries of current integration interval, this is used for event detection
    linear_interpolation_MR(gmfData->startTime, gmfData->yStart,
                            gmfData->endTime,   gmfData->yEnd,
                            gmfData->time, gmfData->yOld, gmfData->nSlowStates, gmfData->slowStates);
    linear_interpolation_MR(gmfData->startTime, gmfData->yStart,
                            gmfData->endTime,   gmfData->yEnd,
                            gmfData->time + gmfData->lastStepSize, gmfData->y, gmfData->nSlowStates, gmfData->slowStates);
    eventTime = checkForEvents(data, threadData, solverInfo, gmfData->time, gmfData->yOld, gmfData->time + gmfData->lastStepSize, gmfData->y);
    if (eventTime > 0)
    {
      solverInfo->currentTime = eventTime;
      sData->timeValue = solverInfo->currentTime;

      // sData->realVars are the "numerical" values on the right hand side of the event
      gmData->time = eventTime;
      memcpy(gmData->yOld, sData->realVars, gmfData->nStates * sizeof(double));

      gmfData->time = eventTime;
      memcpy(gmfData->yOld, sData->realVars, gmfData->nStates * sizeof(double));

      /* write statistics to the solverInfo data structure */
      solverInfo->solverStatsTmp[0] = gmfData->stepsDone;
      solverInfo->solverStatsTmp[1] = gmfData->evalFunctionODE;
      solverInfo->solverStatsTmp[2] = gmfData->evalJacobians;
      solverInfo->solverStatsTmp[3] = gmfData->errorTestFailures;
      solverInfo->solverStatsTmp[4] = gmfData->convergenceFailures;

      if(ACTIVE_STREAM(LOG_SOLVER))
      {
        messageClose(LOG_SOLVER);
      }
      // Get out of the integration routine for event handling
      return 1;
    }

    /* update time with performed stepSize */
    gmfData->time += gmfData->lastStepSize;
    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printVector_gm("y:    ", gmfData->y, gmfData->nStates, gmfData->time);
    }


    /* step is accepted and yOld needs to be updated, store yOld for later interpolation... */
    copyVector_gmf(gmfData->yt, gmfData->yOld, nFastStates, gmfData->fastStates);

    /* step is accepted and yOld needs to be updated */
    copyVector_gmf(gmfData->yOld, gmfData->y, nFastStates, gmfData->fastStates);
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gmfData->time- gmfData->lastStepSize, gmfData->time, err, gmfData->stepSize);

    // Dont disturb the inner step size control!!
    if (gmfData->time + gmfData->stepSize > innerTargetTime)
      break;
  }

  // restore the last predicted step size, only necessary if last step size has been reduced to reach the target time
  // gmfData->stepSize = gmfData->stepSize_old;

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  gmData->err_fast = gmfData->errValues[0];

  //outer integration needs to be synchronized
  // if ((gmfData->time < gmData->timeRight) && (gmData->timeRight < targetTime))
  if  ((gmfData->time + gmfData->stepSize > gmData->timeRight) ||
        (gmData->time > targetTime) ||
        ((gmData->time < targetTime) && (gmData->time + gmData->lastStepSize > targetTime))
      )
  {
    gmData->lastStepSize = gmfData->time - gmData->timeLeft;
    gmData->timeRight = gmfData->time;
    if (gmData->time > gmData->timeLeft)
      gmData->time = gmfData->time;
    else
      gmData->time = gmData->timeLeft;

    memcpy(gmData->yOld, gmfData->y, gmfData->nStates * sizeof(double));
    memcpy(gmData->y, gmfData->y, gmfData->nStates * sizeof(double));

    // solverInfo->currentTime = eventTime;
    // sData->timeValue = solverInfo->currentTime;
    copyVector_gmf(gmData->err, gmfData->err, nFastStates, gmfData->fastStates);
    // copyVector_gmf(gmData->y, gmfData->y, nFastStates, gmfData->fastStates);
    // copyVector_gmf(gmData->yOld, gmfData->y, nFastStates, gmfData->fastStates);
  }

  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "gmode call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gmfData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gmfData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gmfData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gmfData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gmfData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gmfData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gmfData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = gmfData->stepsDone;
  solverInfo->solverStatsTmp[1] = gmfData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = gmfData->evalJacobians;
  solverInfo->solverStatsTmp[3] = gmfData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = gmfData->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished gmode inner step.");
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
void linear_interpolation_MR(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx)
{
  double lambda, h0, h1;
  int ii;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<nIdx; i++)
  {
    ii = idx[i];
    f[ii] = h0*fa[ii] + h1*fb[ii];
  }
}

void printVector_gmf(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("%s\t(time = %14.8g):", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%16.12g ", a[indx[i]]);
  printf("\n");
}

void printMatrix_gmf(char name[], double* a, int n, double time)
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