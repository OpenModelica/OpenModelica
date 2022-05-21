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

#include "generic_rk.h"

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
void printVector_genericRK(char name[], double* a, int n, double time);
void printIntVector_genericRK(char name[], int* a, int n, double time);
void printMatrix_genericRK(char name[], double* a, int n, double time);


// singlerate step function
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_MS_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

void residual_MS_MR(void **dataIn, const double *xloc, double *res, const int *iflag);
void residual_DIRK_MR(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_MR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);

SPARSE_PATTERN* initializeSparsePattern_MS(DATA* data, NONLINEAR_SYSTEM_DATA* sysData);
SPARSE_PATTERN* initializeSparsePattern_DIRK(DATA* data, NONLINEAR_SYSTEM_DATA* sysData);


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
  DATA_GMRI* gmriData;
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
 * @param gmriData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GMRI* gmriData) {
  assertStreamPrint(threadData, gmriData->type != RK_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = gmriData->nStates;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  switch (gmriData->type)
  {
  case RK_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    // nlsData->analyticalJacobianColumn = NULL;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    // gmriData->symJacAvailable = FALSE;
    gmriData->symJacAvailable = TRUE;
    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS_MR;
    nlsData->analyticalJacobianColumn = jacobian_MR_column;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    gmriData->symJacAvailable = TRUE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gmriData->type);
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
  gmriData->jacobian = initAnalyticJacobian(gmriData->nlSystemSize, gmriData->nlSystemSize, gmriData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Initialize NLS method */
  switch (gmriData->nlsSolverMethod) {
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
    if (gmriData->symJacAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (gmriData->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[gmriData->nlsSolverMethod]);
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
int allocateDataGenericRK_MR(DATA* data, threadData_t *threadData, DATA_GSRI* gsriData)
{
  DATA_GMRI* gmriData = (DATA_GMRI*) malloc(sizeof(DATA_GMRI));
  gsriData->gmriData = gmriData;

  gmriData->nStates = gsriData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gmriData->RK_method = getRK_Method(FLAG_MR);
  gmriData->tableau = initButcherTableau(gmriData->RK_method);
  if (gmriData->tableau == NULL){
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gmriData->tableau, gmriData->nStates, &gmriData->nlSystemSize, &gmriData->type);

  if (gmriData->RK_method == MS_ADAMS_MOULTON) {
    gmriData->nlSystemSize = gmriData->nStates;
    gmriData->step_fun = &(full_implicit_MS_MR);
    gmriData->type = MS_TYPE_IMPLICIT;
    gmriData->isExplicit = FALSE;
  }

  switch (gmriData->type)
  {
  case RK_TYPE_EXPLICIT:
    gmriData->isExplicit = TRUE;
    gmriData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case RK_TYPE_DIRK:
    gmriData->isExplicit = FALSE;
    gmriData->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case MS_TYPE_IMPLICIT:
    gmriData->isExplicit = FALSE;
    gmriData->step_fun = &(full_implicit_MS_MR);
    break;

  case RK_TYPE_IMPLICIT:
    errorStreamPrint(LOG_STDOUT, 0, "Fully Implicit RK method is not supported for the fast states integration!");
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);

    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", gmriData->tableau->fac);

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_SR_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gmriData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "PIController is use for step size control");
  } else
  {
    gmriData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "IController is use for step size control");
  }

  // allocate memory for the generic RK method
  gmriData->y = malloc(sizeof(double)*gmriData->nStates);
  gmriData->yOld = malloc(sizeof(double)*gmriData->nStates);
  gmriData->yt = malloc(sizeof(double)*gmriData->nStates);
  gmriData->f = malloc(sizeof(double)*gmriData->nStates);
  if (!gmriData->isExplicit) {
    gmriData->Jf = malloc(sizeof(double)*gmriData->nStates*gmriData->nStates);
    for (int i=0; i<gmriData->nStates*gmriData->nStates; i++)
      gmriData->Jf[i] = 0;

  } else {
    gmriData->Jf = NULL;
  }
  gmriData->k = malloc(sizeof(double)*gmriData->nStates*gmriData->tableau->nStages);
  gmriData->x = malloc(sizeof(double)*gmriData->nStates*gmriData->tableau->nStages);
  gmriData->res_const = malloc(sizeof(double)*gmriData->nStates);
  gmriData->errest = malloc(sizeof(double)*gmriData->nStates);
  gmriData->errtol = malloc(sizeof(double)*gmriData->nStates);
  gmriData->err = malloc(sizeof(double)*gmriData->nStates);
  gmriData->ringBufferSize = 5;
  gmriData->errValues = malloc(sizeof(double)*gmriData->ringBufferSize);
  gmriData->stepSizeValues = malloc(sizeof(double)*gmriData->ringBufferSize);

  gmriData->nFastStates = gmriData->nStates;
  gmriData->nSlowStates = 0;

  printButcherTableau(gmriData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gmriData->stepsDone = 0;
  gmriData->evalFunctionODE = 0;
  gmriData->evalJacobians = 0;
  gmriData->errorTestFailures = 0;
  gmriData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gmriData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gmriData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    } else {
      gmriData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
  //gmriData->nlsSolverMethod = getRK_NLS_Method();
    gmriData->nlsSolverMethod = RK_NLS_NEWTON;
    gmriData->nlsData = initRK_NLS_DATA_MR(data, threadData, gmriData);
    if (!gmriData->nlsData) {
      return -1;
    }
  }  else
  {
    gmriData->symJacAvailable = FALSE;
    gmriData->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gmriData->nlsData = NULL;
    gmriData->jacobian = NULL;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK_MR(DATA_GMRI* gmriData) {
  /* Free non-linear system data */
  if(gmriData->nlsData != NULL) {
    struct dataSolver* dataSolver = gmriData->nlsData->solverData;
    switch (gmriData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gsriData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gmriData->nlsData);
  }

  /* Free Jacobian */
  freeAnalyticJacobian(gmriData->jacobian);

  freeButcherTableau(gmriData->tableau);

  free(gmriData->y);
  free(gmriData->yOld);
  free(gmriData->yt);
  free(gmriData->f);
  free(gmriData->Jf);
  free(gmriData->k);
  free(gmriData->x);
  free(gmriData->res_const);
  free(gmriData->errest);
  free(gmriData->errtol);
  free(gmriData->err);
  free(gmriData->errValues);
  free(gmriData->stepSizeValues);

  free(gmriData);
  gmriData = NULL;

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

  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  SPARSE_PATTERN* sparsePattern_MR;
  SPARSE_PATTERN* sparsePattern_DIRK = gsriData->jacobian->sparsePattern;

  int nStates = gmriData->nStates;

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
  // for (i=0; i < gmriData->nStates+1; i++)
  //   sparsePattern_MR->leadindex[i] = i * nStates;
  // for(i=0; i < nStates*nStates; i++) {
  //   sparsePattern_MR->index[i] = i% nStates;
  // }

  // printIntVector_genericRK("sparsePattern leadindex", sparsePattern_MR->leadindex, length_column_indices, 0);
  // printIntVector_genericRK("sparsePattern index", sparsePattern_MR->index, length_index, 0);

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
  DATA_GMRI *gmriData = (DATA_GMRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  int nFastStates = gmriData->nFastStates;
  int stage_   = gmriData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii < nFastStates;ii++) {
    i = gmriData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);

  for (ii=0; ii < nFastStates; ii++) {
    i = gmriData->fastStates[ii];
    res[ii] = gmriData->res_const[i] - xloc[ii] * gmriData->tableau->c[nStages-1] +
                                       fODE[i] * gmriData->tableau->b[nStages-1] * gmriData->stepSize;
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
  DATA_GMRI *gmriData = (DATA_GMRI *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  int stage_  = gmriData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii<gmriData->nFastStates;ii++) {
    i = gmriData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);

  // Evaluate residual
  for (ii=0; ii<gmriData->nFastStates; ii++) {
    i = gmriData->fastStates[ii];
    res[ii] = gmriData->res_const[i] - xloc[ii] + gmriData->stepSize * gmriData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  // printVector_genericRK("res", res, gmriData->nFastStates, gmriData->time);
  return;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gsriData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MR_column(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GSRI* gsriData = (DATA_GSRI*) data->simulationInfo->backupSolverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  /* define callback to column function of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  int nFastStates = gmriData->nFastStates;
  int stage_ = gmriData->act_stage;

  // printSparseStructure(gmriData->jacobian->sparsePattern,
  //                     nFastStates,
  //                     nFastStates,
  //                     LOG_STDOUT,
  //                     "sparsePattern");

  for (i=0; i<jacobian_ODE->sizeCols; i++)
    jacobian_ODE->seedVars[i] = 0;
  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii=0; ii<nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // update timeValue and unknown vector based on the active column "stage_"
  //sData->timeValue = gsriData->time + gsriData->tableau->c[stage_] * gsriData->stepSize;

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (ii = 0; ii < nFastStates; ii++) {
    i = gmriData->fastStates[ii];
    if (gmriData->type == MS_TYPE_IMPLICIT) {
      jacobian->resultVars[ii] = gmriData->tableau->b[nStages-1] * gmriData->stepSize * jacobian_ODE->resultVars[i];
    } else {
      jacobian->resultVars[ii] = gmriData->stepSize * gmriData->tableau->A[stage_ * gmriData->tableau->nStages + stage_] * jacobian_ODE->resultVars[i];
    }
    /* -1 on diagonal elements */
    if (jacobian->seedVars[ii] == 1) {
      jacobian->resultVars[ii] -= 1;
    }
  }
  // printVector_genericRK("jacobian_ODE colums", jacobian_ODE->resultVars, nFastStates, gmriData->time);
  // printVector_genericRK("jacobian colums", jacobian->resultVars, nFastStates, gmriData->time);
  // printIntVector_genericRK("sparsity pattern colors", jacobian->sparsePattern->colorCols, nFastStates, gmriData->time);

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
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  int i, ii;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gmriData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // printVector_genericRK("k:  ", gmriData->k + 0 * nStates, nStates, gmriData->time);
  // printVector_genericRK("k:  ", gmriData->k + 1 * nStates, nStates, gmriData->time);
  // printVector_genericRK("x:  ", gmriData->x + 0 * nStates, nStates, gmriData->time);
  // printVector_genericRK("x:  ", gmriData->x + 1 * nStates, nStates, gmriData->time);

  // Is this necessary???
  // gmriData->data = (void*) data;
  // gmriData->threadData = threadData;

  /* Predictor Schritt */
  for (ii = 0; ii < gmriData->nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    // BB ToDo: check the formula with respect to gsriData->k[]
    gmriData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmriData->yt[i] += -gmriData->x[stage_ * nStates + i] * gmriData->tableau->c[stage_] +
                          gmriData->k[stage_ * nStates + i] * gmriData->tableau->bt[stage_] *  gmriData->stepSize;
    }
    gmriData->yt[i] += gmriData->k[stage_ * nStates + i] * gmriData->tableau->bt[stage_] * gmriData->stepSize;
    gmriData->yt[i] /= gmriData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (ii = 0; ii < gmriData->nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    // BB ToDo: check the formula with respect to gsriData->k[]
    gmriData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmriData->res_const[i] += -gmriData->x[stage_ * nStates + i] * gmriData->tableau->c[stage_] +
                                 gmriData->k[stage_ * nStates + i] * gmriData->tableau->b[stage_] *  gmriData->stepSize;
    }
  }
  // printVector_genericRK("res_const:  ", gsriData->res_const, nStates, gsriData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gmriData->time + gmriData->stepSize;
  // interpolate the slow states on the current time of gmriData->yOld for correct evaluation of gmriData->res_const
  linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                          gmriData->endTime, gmriData->yEnd,
                          sData->timeValue,  sData->realVars, gmriData->nSlowStates, gmriData->slowStates);


  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gmriData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gmriData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gsriData->multi_rate_phase = 1;
  solved = solveNLS(data, threadData, nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_MS: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gmriData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (ii = 0; ii < gmriData->nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    // BB ToDo: check the formula with respect to gsriData->k[]
    gmriData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gmriData->y[i] += -gmriData->x[stage_ * nStates + i] * gmriData->tableau->c[stage_] +
                         gmriData->k[stage_ * nStates + i] * gmriData->tableau->b[stage_] *  gmriData->stepSize;
    }
    gmriData->y[i] += gmriData->k[stage_ * nStates + i] * gmriData->tableau->b[stage_] * gmriData->stepSize;
    gmriData->y[i] /= gmriData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gmriData->x + stage_ * nStates, gmriData->y, nStates*sizeof(double));

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
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  int i, ii;
  int stage, stage_;

  int nStates = data->modelData->nStates;
  int nFastStates = gmriData->nFastStates;
  int nStages = gmriData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // Is this necessary???
  // gmriData->data = (void*) data;
  // gmriData->threadData = threadData;

  // interpolate the slow states on the current time of gmriData->yOld for correct evaluation of gmriData->res_const
  linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                          gmriData->endTime,   gmriData->yEnd,
                          gmriData->time, gmriData->yOld, gmriData->nSlowStates, gmriData->slowStates);

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gmriData->time;
  memcpy(sData->realVars, gmriData->yOld, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);
  memcpy(gmriData->k, fODE, nStates*sizeof(double));

  for (stage = 0; stage < nStages; stage++)
  {
    gmriData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++)
    {
      gmriData->res_const[i] = gmriData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gmriData->res_const[i] += gmriData->stepSize * gmriData->tableau->A[stage * nStages + stage_] * gmriData->k[stage_ * nStates + i];
    }

    // set simulation time with respect to the current stage
    sData->timeValue = gmriData->time + gmriData->tableau->c[stage]*gmriData->stepSize;

    // index of diagonal element of A
    if (gmriData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gmriData->res_const, nStates*sizeof(double));
        wrapper_f_genericRK(data, threadData, &(gmriData->evalFunctionODE), fODE);
      }
//      memcpy(gmriData->x + stage_ * nStates, gmriData->res_const, nStates*sizeof(double));
    }
    else
    {
      // interpolate the slow states on the time of the current stage
      linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                              gmriData->endTime,   gmriData->yEnd,
                              sData->timeValue, sData->realVars, gmriData->nSlowStates, gmriData->slowStates);

      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gmriData->yOld[gmriData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gmriData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (ii=0; ii<nFastStates; ii++) {
          i = gmriData->fastStates[ii];
          nlsData->nlsx[ii] = gmriData->yOld[i] + gmriData->tableau->c[stage_] * gmriData->stepSize * gmriData->k[i];
      }
      //memcpy(nlsData->nlsx, gmriData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gsriData->multi_rate_phase = 1;
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(gmriData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  }

  for (ii=0; ii<nFastStates; ii++)
  {
    i = gmriData->fastStates[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gmriData->y[i]  = gmriData->yOld[i];
    gmriData->yt[i] = gmriData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gmriData->y[i]  += gmriData->stepSize * gmriData->tableau->b[stage_]  * (gmriData->k + stage_ * nStates)[i];
      gmriData->yt[i] += gmriData->stepSize * gmriData->tableau->bt[stage_] * (gmriData->k + stage_ * nStates)[i];
    }
  }

  return 0;
}

/*! \fn genericRK_MR_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'genericRK'
 */
int genericRK_MR_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GSRI* gsriData = (DATA_GSRI*)solverInfo->solverData;
  DATA_GMRI* gmriData = gsriData->gmriData;

  double err, eventTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;

  int i, ii, j, jj, l, ll, r, rr;
  int integrator_step_info;

  int nStates = data->modelData->nStates;
  int nFastStates = gsriData->nFastStates;

  // This is the target time of the main integrator
  double innerTargetTime = fmin(targetTime, gsriData->timeRight);

  // BB ToDo: needs to be performed also after an event!!!
  if (gmriData->didEventStep)
  {
     /* reset statistics because it is accumulated in solver_main.c */
    gmriData->stepsDone = 0;
    gmriData->evalFunctionODE = 0;
    gmriData->evalJacobians = 0;
    gmriData->errorTestFailures = 0;
    gmriData->convergenceFailures = 0;

    gmriData->time = gsriData->time;
    gmriData->stepSize = gsriData->lastStepSize;
    // BB ToDO: Copy only fast states!!
    memcpy(gmriData->yOld, gsriData->yOld, sizeof(double)*gsriData->nStates);
    gmriData->didEventStep = FALSE;
    if (gmriData->type == MS_TYPE_IMPLICIT) {
      memcpy(gmriData->x, gsriData->x, nStates*sizeof(double));
      memcpy(gmriData->k, gsriData->k, nStates*sizeof(double));
    }
  }
//  gmriData->stepSize    = fmin(gmriData->stepSize, gsriData->timeRight - gmriData->time);
  gmriData->startTime   = gsriData->timeLeft;
  gmriData->endTime     = gsriData->timeRight;
  gmriData->yStart      = gsriData->yLeft;
  gmriData->yEnd        = gsriData->y;
  gmriData->fastStates  = gsriData->fastStates;
  gmriData->slowStates  = gsriData->slowStates;
  gmriData->nFastStates = gsriData->nFastStates;
  gmriData->nSlowStates = gsriData->nSlowStates;

  if (!gmriData->isExplicit) {
    struct dataSolver *solverDataStruct = gmriData->nlsData->solverData;
    // set number of non-linear variables and corresponding nominal values (changes dynamically during simulation)
    gmriData->nlsData->size = gmriData->nFastStates;
    switch (gmriData->nlsSolverMethod)
    {
      case  RK_NLS_NEWTON:
        ((DATA_NEWTON*) solverDataStruct->ordinaryData)->n = gmriData->nFastStates;
        break;
      case  RK_NLS_KINSOL:
        ((NLS_KINSOL_DATA*) solverDataStruct->ordinaryData)->size = gmriData->nFastStates;
        break;
      default:
        errorStreamPrint(LOG_STDOUT, 0, "NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[gmriData->nlsSolverMethod]);
        return -1;
        break;
    }

    infoStreamPrint(LOG_SOLVER, 1, "Fast states and corresponding nominal values:");
    for (ii=0; ii<nFastStates; ii++) {
      i = gmriData->fastStates[ii];
    // Get the nominal values of the fast states
      gmriData->nlsData->nominal[ii] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
      infoStreamPrint(LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gsriData->nlsData->nominal[i]);
    }
    messageClose(LOG_SOLVER);

    if (gmriData->symJacAvailable) {
      // The following assumes that the fastStates are sorted (i.e. [0, 2, 6, 7, ...])
      SPARSE_PATTERN* sparsePattern_DIRK = gsriData->jacobian->sparsePattern;
      SPARSE_PATTERN* sparsePattern_MR = gmriData->jacobian->sparsePattern;

      // printSparseStructure(sparsePattern_DIRK,
      //                     nStates,
      //                     nStates,
      //                     LOG_MULTIRATE,
      //                     "sparsePattern_DIRK");

      /* Set sparsity pattern for the fast states */
      ii = 0;
      jj = 0;
      ll = 0;

      sparsePattern_MR->leadindex[0] = sparsePattern_DIRK->leadindex[0];
      for(rr=0; rr < nFastStates; rr++) {
        r = gmriData->fastStates[rr];
        ii = 0;
        for(jj = sparsePattern_DIRK->leadindex[r]; jj < sparsePattern_DIRK->leadindex[r+1];) {
          i = gmriData->fastStates[ii];
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

//BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
      // trivial coloring
      // sparsePattern_MR->maxColors = nFastStates;
      // for (i=0; i < nFastStates; i++)
      //   sparsePattern_MR->colorCols[i] = i+1;

      // Just take the coloring from DIRK
      sparsePattern_MR->maxColors = sparsePattern_DIRK->maxColors;
      for (ii=0; ii < nFastStates; ii++) {
        i = gmriData->fastStates[ii];
        sparsePattern_MR->colorCols[ii] = sparsePattern_DIRK->colorCols[i];
      }
//BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB

      gmriData->jacobian->sizeCols = nFastStates;
      gmriData->jacobian->sizeRows = nFastStates;

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
                  gsriData->timeLeft, gsriData->timeRight, gsriData->lastStepSize);
  if(ACTIVE_STREAM(LOG_MULTIRATE))
  {
    printVector_genericRK("yL: ", gsriData->yLeft, gsriData->nStates, gsriData->timeLeft);
    printVector_genericRK("yR: ", gsriData->y, gsriData->nStates, gsriData->timeRight);
    printf("\n");
  }

  while (gmriData->time < innerTargetTime)
  {
    do
    {
      if(ACTIVE_STREAM(LOG_MULTIRATE))
      {
        //printVector_genericRK_MR("yOld: ", gmriData->yOld, gmriData->nStates, gmriData->time, gmriData->nFastStates, gmriData->fastStates);
        printVector_genericRK("yOld: ", gmriData->yOld, gmriData->nStates, gmriData->time);
      }

      // calculate one step of the integrator
      integrator_step_info = gmriData->step_fun(data, threadData, solverInfo);

      // error handling: try half of the step size!
      if (integrator_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "gmode_step: Failed to calculate step at time = %5g.", gmriData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gmriData->stepSize = gmriData->stepSize/2.;
        continue;
        //return -1;
      }

      for (i=0; i<nFastStates; i++)
      {
        ii = gmriData->fastStates[i];
        // calculate corresponding values for the error estimator and step size control
        gmriData->errtol[ii] = Rtol*fmax(fabs(gmriData->y[ii]),fabs(gmriData->yt[ii])) + Atol;
        gmriData->errest[ii] = fabs(gmriData->y[ii] - gmriData->yt[ii]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i < nFastStates; i++)
      {
        ii = gmriData->fastStates[i];
        gmriData->err[ii] = gmriData->errest[ii]/gmriData->errtol[ii];
        err = fmax(err, gmriData->err[ii]);
      }

      gmriData->errValues[0] = gmriData->tableau->fac * err;
      gmriData->stepSizeValues[0] = gmriData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      gmriData->lastStepSize = gmriData->stepSize;

      // Call the step size control
      gmriData->stepSize *= gmriData->stepSize_control(gmriData->errValues, gmriData->stepSizeValues, gmriData->tableau->error_order);

      // Re-do step, if error is larger than requested
      if (err>1)
      {
        gmriData->errorTestFailures++;
        infoStreamPrint(LOG_MULTIRATE, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gmriData->time, gmriData->time + gmriData->lastStepSize, err, gmriData->stepSize);
      }
    } while  (err>1);

    // Count succesful integration steps
    gmriData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gmriData->ringBufferSize-1); i++) {
      gmriData->errValues[i+1] = gmriData->errValues[i];
      gmriData->stepSizeValues[i+1] = gmriData->stepSizeValues[i];
    }

    if (gmriData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gmriData->tableau->nStages-1); stage_++) {
        memcpy(gmriData->k + stage_ * nStates, gmriData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gmriData->x + stage_ * nStates, gmriData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
    }

    // interpolate the slow states to the boundaries of current integration interval, this is used for event detection
    linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                            gmriData->endTime,   gmriData->yEnd,
                            gmriData->time, gmriData->yOld, gmriData->nSlowStates, gmriData->slowStates);
    linear_interpolation_MR(gmriData->startTime, gmriData->yStart,
                            gmriData->endTime,   gmriData->yEnd,
                            gmriData->time + gmriData->lastStepSize, gmriData->y, gmriData->nSlowStates, gmriData->slowStates);
    eventTime = checkForEvents(data, threadData, solverInfo, gmriData->time, gmriData->yOld, gmriData->time + gmriData->lastStepSize, gmriData->y);
    if (eventTime > 0)
    {
      solverInfo->currentTime = eventTime;
      sData->timeValue = solverInfo->currentTime;

      // sData->realVars are the "numerical" values on the right hand side of the event
      gsriData->time = eventTime;
      memcpy(gsriData->yOld, sData->realVars, gmriData->nStates * sizeof(double));

      gmriData->time = eventTime;
      memcpy(gmriData->yOld, sData->realVars, gmriData->nStates * sizeof(double));

      /* write statistics to the solverInfo data structure */
      solverInfo->solverStatsTmp[0] = gmriData->stepsDone;
      solverInfo->solverStatsTmp[1] = gmriData->evalFunctionODE;
      solverInfo->solverStatsTmp[2] = gmriData->evalJacobians;
      solverInfo->solverStatsTmp[3] = gmriData->errorTestFailures;
      solverInfo->solverStatsTmp[4] = gmriData->convergenceFailures;

      if(ACTIVE_STREAM(LOG_SOLVER))
      {
        messageClose(LOG_SOLVER);
      }
      // Get out of the integration routine for event handling
      return 1;
    }

    /* update time with performed stepSize */
    gmriData->time += gmriData->lastStepSize;
    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printVector_genericRK("y:    ", gmriData->y, gmriData->nStates, gmriData->time);
    }


    /* step is accepted and yOld needs to be updated, store yOld for later interpolation... */
    copyVector_genericRK_MR(gmriData->yt, gmriData->yOld, nFastStates, gmriData->fastStates);

    /* step is accepted and yOld needs to be updated */
    copyVector_genericRK_MR(gmriData->yOld, gmriData->y, nFastStates, gmriData->fastStates);
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gmriData->time- gmriData->lastStepSize, gmriData->time, err, gmriData->stepSize);

    // Dont disturb the inner step size control!!
    if (gmriData->time + gmriData->stepSize > innerTargetTime)
      break;
  }

  // restore the last predicted step size, only necessary if last step size has been reduced to reach the target time
  // gmriData->stepSize = gmriData->stepSize_old;

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  gsriData->err_fast = gmriData->errValues[0];

  //outer integration needs to be synchronized
  // if ((gmriData->time < gsriData->timeRight) && (gsriData->timeRight < targetTime))
  if  ((gmriData->time + gmriData->stepSize > gsriData->timeRight) ||
        (gsriData->time > targetTime) ||
        ((gsriData->time < targetTime) && (gsriData->time + gsriData->lastStepSize > targetTime))
      )
  {
    gsriData->lastStepSize = gmriData->time - gsriData->timeLeft;
    gsriData->timeRight = gmriData->time;
    if (gsriData->time > gsriData->timeLeft)
      gsriData->time = gmriData->time;
    else
      gsriData->time = gsriData->timeLeft;

    memcpy(gsriData->yOld, gmriData->y, gmriData->nStates * sizeof(double));
    memcpy(gsriData->y, gmriData->y, gmriData->nStates * sizeof(double));

    // solverInfo->currentTime = eventTime;
    // sData->timeValue = solverInfo->currentTime;
    copyVector_genericRK_MR(gsriData->err, gmriData->err, nFastStates, gmriData->fastStates);
    // copyVector_genericRK_MR(gsriData->y, gmriData->y, nFastStates, gmriData->fastStates);
    // copyVector_genericRK_MR(gsriData->yOld, gmriData->y, nFastStates, gmriData->fastStates);
  }

  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "gmode call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gmriData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gmriData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gmriData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gmriData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gmriData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gmriData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gmriData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = gmriData->stepsDone;
  solverInfo->solverStatsTmp[1] = gmriData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = gmriData->evalJacobians;
  solverInfo->solverStatsTmp[3] = gmriData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = gmriData->convergenceFailures;

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

void printVector_genericRK_MR(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("%s\t(time = %14.8g):", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%16.12g ", a[indx[i]]);
  printf("\n");
}

void printMatrix_genericRK_MR(char name[], double* a, int n, double time)
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