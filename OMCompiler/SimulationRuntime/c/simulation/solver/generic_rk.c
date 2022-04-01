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

/* BB: ToDo's
 *
 * 0) Update comments for better readability, delete stuff no longer necessary
 * 1) Check pointer, especially, if there is no memory leak!
 * 2) Check necessary function evaluation and counting of it (use userdata->f, userdata->fOld)
 * 3) Use analytical Jacobian of the functionODE, if available
 *    Check calculation for a highly nonlinear test problem (VDP, etc.)
 * 4) Use sparsity pattern and kinsol solver
 * 5) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 6) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 7) Implement other ESDIRK methods
 * 8) configure userdata->fac with respect to the accuracy prediction
 * 9) ...
 *
*/

/*! \file genericRK.c
 *  Implementation of a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau.
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

//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void printVector_genericRK(char name[], double* a, int n, double time);
void printMatrix_genericRK(char name[], double* a, int n, double time);

// singlerate step function
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

// Residuum and Jacobian functions for diagonal implicit (DIRK) and implicit (IRK) Runge-Kutta methods.
void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_DIRK(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);
void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag);
int jacobian_IRK(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian);;

void initializeStaticNLSData(void* nlsDataVoid, threadData_t *threadData, void* rk_data_void);


struct RK_USER_DATA {
  DATA* data;
  threadData_t* threadData;
  DATA_GENERIC_RK* rk_data;
};

struct dataSolver
{
  void* ordinaryData;
  void* initHomotopyData;
};

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_RK.
 *
 * Defaults to RK_DOPRI45 if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum RK_SINGLERATE_METHOD getRK_Method() {
  enum RK_SINGLERATE_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK];
  char* RK_method_string;

  if (flag_value != NULL) {
    RK_method_string = GC_strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(RK_method_string, RK_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: %s", RK_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow Runge-Kutta method %s.", RK_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK method: %s [from command line]", RK_method_string);
    return RK_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: dopri45 [default]");
    return RK_DOPRI45;
  }
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_RK_NLS.
 *
 * Defaults to Newton if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_NLS_METHOD   NLS method.
 */
enum RK_NLS_METHOD getRK_NLS_Method() {
  enum RK_NLS_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK_NLS];
  char* RK_NLS_method_string;

  if (flag_value != NULL) {
    RK_NLS_method_string = GC_strdup(flag_value);
    for (method=RK_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(RK_NLS_method_string, RK_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK NLS method: %s", RK_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for Runge-Kutta method.", RK_NLS_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK NLS method: %s [from command line]", RK_NLS_method_string);
    return RK_NLS_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: omc_newton [default]");
    return RK_NLS_NEWTON;
  }
}


// TODO: Not working yet!
void initializeSparsePattern_DIRK(NONLINEAR_SYSTEM_DATA* sysData) {
  int i = 0;

  // TODO: Get sparsity pattern of DIRK in CSC format
  const unsigned int length_column_indices = 1;
  const unsigned int length_row_indices = 1;

  const unsigned int colIndex[length_column_indices] = {0};
  const unsigned int rowIndex[length_row_indices] = {0};
  const unsigned int maxColor = 1;
  const unsigned int colorCols[maxColor] = {1};

  /* sparsity pattern available */
  sysData->isPatternAvailable = TRUE;
  sysData->sparsePattern = (SPARSE_PATTERN*) malloc(sizeof(SPARSE_PATTERN));
  sysData->sparsePattern->leadindex = (unsigned int*) malloc((length_column_indices)*sizeof(unsigned int));
  sysData->sparsePattern->index = (unsigned int*) malloc(1*sizeof(unsigned int));
  sysData->sparsePattern->numberOfNonZeros = 1;
  sysData->sparsePattern->colorCols = (unsigned int*) malloc(1*sizeof(unsigned int));
  sysData->sparsePattern->maxColors = 1;
  // TODO: Free sparsity pattern with freeSparsePattern or when freeing Jacobian with freeAnalyticJacobian

  /* write lead index of compressed sparse column */
  memcpy(sysData->sparsePattern->leadindex, colIndex, length_column_indices*sizeof(unsigned int));

  /* call sparse index */
  memcpy(sysData->sparsePattern->index, rowIndex, length_row_indices*sizeof(unsigned int));

  /* write color array */
  memcpy(sysData->sparsePattern->colorCols, colorCols, maxColor*sizeof(unsigned int));
}

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
void initializeStaticNLSData_DIRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys) {
  for(int i=0; i<nonlinsys->size; i++) {
    nonlinsys->nominal[i] = 1.0;
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  nonlinsys->isPatternAvailable = FALSE;
  nonlinsys->sparsePattern = NULL;
  //initializeSparsePattern_DIRK(nlsData);

  return;
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param rk_data                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* intiRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GENERIC_RK* rk_data) {
  assertStreamPrint(threadData, rk_data->type != RK_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  ANALYTIC_JACOBIAN* jacobian = NULL;

  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

  nlsData->size = rk_data->nlSystemSize;
  nlsData->equationIndex = -1;

  nlsData->homotopySupport = FALSE;
  nlsData->initHomotopy = FALSE;
  nlsData->mixedSystem = FALSE;

  // TODO Set min, max, nominal
  nlsData->min = NULL;
  nlsData->max = NULL;
  nlsData->nominal = NULL;

  // TODO: Check if jacobian of DIRK is initialized
  nlsData->initialAnalyticalJacobian = data->callback->initialAnalyticJacobianA;
  nlsData->jacobianIndex = data->callback->INDEX_JAC_A;

  jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  // TODO: Do we need to initialize the Jacobian or is it already initialized?
  data->callback->initialAnalyticJacobianA(data, threadData, jacobian);

  nlsData->sparsePattern = jacobian->sparsePattern;
  nlsData->isPatternAvailable = TRUE;

  switch (rk_data->type)
  {
  case RK_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    nlsData->analyticalJacobianColumn = jacobian_DIRK;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK;
    nlsData->getIterationVars = NULL;

    //TODO AHeu: Only for testing. Remove
    rk_data->symJacAvailable = FALSE;
    break;
  case RK_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    nlsData->analyticalJacobianColumn = jacobian_IRK;
    nlsData->initializeStaticNLSData = initializeStaticNLSData_DIRK;
    nlsData->getIterationVars = NULL;

    //TODO AHeu: Only for testing. Remove
    rk_data->symJacAvailable = FALSE;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", rk_data->type);
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
  nlsData->initializeStaticNLSData(data, threadData, nlsData);

  switch (rk_data->nlsSolverMethod) {
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
    //nlsData->nlsLinearSolver = NLS_LS_KLU;  // Error in Kinsol.c L1290
                                              // TODO AHeu: It seems that the Jacobian is sparse but should be dense (or vice versa)
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsData->nlsLinearSolver);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    if (rk_data->symJacAvailable) {
      resetKinsolMemory(solverData->ordinaryData, nlsData->sparsePattern->numberOfNonZeros, nlsData->analyticalJacobianColumn);
    } else {
      resetKinsolMemory(solverData->ordinaryData, nlsData->size*nlsData->size, NULL);
      int flag = KINSetJacFn(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, NULL);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_KINLS_FLAG, "KINSetJacFn");
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[rk_data->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Function allocates memory needed for ESDIRK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGenericRK(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo) {
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) malloc(sizeof(DATA_GENERIC_RK));
  solverInfo->solverData = (void*) rk_data;

  rk_data->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  rk_data->RK_method = getRK_Method();
  rk_data->tableau = initButcherTableau(rk_data->RK_method);
  if (rk_data->tableau == NULL){
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Failed to initialize butcher tableau for Runge-Kutta method %s", RK_SINGLERATE_METHOD_NAME[rk_data->RK_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(rk_data->tableau, rk_data->nStates, &rk_data->nlSystemSize, &rk_data->type);

  switch (rk_data->type)
  {
  case RK_TYPE_EXPLICIT:
    rk_data->isExplicit = TRUE;
    rk_data->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_DIRK:
    rk_data->isExplicit = FALSE;
    rk_data->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_IMPLICIT:
    rk_data->isExplicit = FALSE;
    rk_data->step_fun = &(full_implicit_RK);
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGenericRK: Unknown Runge-Kutta type %i", rk_data->type);
    return -1;
  }
  // adapt decision for testing of the fully implicit implementation
  if (rk_data->RK_method == RK_ESDIRK2_test || rk_data->RK_method == RK_ESDIRK3_test) {
    rk_data->nlSystemSize = rk_data->tableau->nStages*rk_data->nStates;
    rk_data->step_fun = &(full_implicit_RK);
    rk_data->type = RK_TYPE_IMPLICIT;
  }

  // TODO: Move this log message. Has nothing to do with memory allocation.
  infoStreamPrint(LOG_STATS, 0, "Step control factor is set to %g", rk_data->tableau->fac);

  /* Allocate internal memory */
  rk_data->isFirstStep = TRUE;
  rk_data->y = malloc(sizeof(double)*rk_data->nStates);
  rk_data->yOld = malloc(sizeof(double)*rk_data->nStates);
  rk_data->yt = malloc(sizeof(double)*rk_data->nStates);
  rk_data->f = malloc(sizeof(double)*rk_data->nStates);
  rk_data->k = malloc(sizeof(double)*rk_data->nStates*rk_data->tableau->nStages);
  rk_data->errest = malloc(sizeof(double)*rk_data->nStates);
  rk_data->errtol = malloc(sizeof(double)*rk_data->nStates);
  rk_data->res_const = malloc(sizeof(double)*rk_data->nStates);
  if (!rk_data->isExplicit) {
    rk_data->Jf = malloc(sizeof(double)*rk_data->nStates*rk_data->nStates);
  }

  printButcherTableau(rk_data->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  rk_data->stepsDone = 0;
  rk_data->evalFunctionODE = 0;
  rk_data->evalJacobians = 0;
  rk_data->errorTestFailures = 0;
  rk_data->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!rk_data->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    // TODO: Do we need to initialize the Jacobian or is it already initialized?
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      rk_data->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to numeric Jacobians.");
    } else {
      rk_data->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    rk_data->nlsSolverMethod = getRK_NLS_Method();
    rk_data->nlsData = intiRK_NLS_DATA(data, threadData, rk_data);
    if (!rk_data->nlsData) {
      return -1;
    }
  }
  else
  {
    rk_data->symJacAvailable = FALSE;
    rk_data->nlsSolverMethod = RK_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    rk_data->nlsData = NULL;
  }

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void*) rk_data;

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK(DATA_GENERIC_RK* rk_data) {
  /* Free non-linear system data */
  if(rk_data->nlsData != NULL) {
    struct dataSolver* dataSolver = rk_data->nlsData->solverData;
    switch (rk_data->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) rk_data->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(rk_data->nlsData);
  }

  /* Free Butcher tableau */
  freeButcherTableau(rk_data->tableau);

  /* Free remaining arrays */
  free(rk_data->y);
  free(rk_data->yOld);
  free(rk_data->yt);
  free(rk_data->f);
  free(rk_data->Jf);
  free(rk_data->k);
  free(rk_data->res_const);
  free(rk_data->errest);
  free(rk_data->errtol);

  free(rk_data);
  rk_data = NULL;

  return;
}

/**
 * @brief Calculate function values of function ODE f(t,y).
 *
 * Assuming the correct values for time value and states are set.
 *
 * @param data            Runtime data struct.
 * @param threadData      Thread data for error handling.
 * @param genericRKData   Runge-Kutta solver data.
 * @param fODE            Array of state derivatives.
 * @return int            Returns 0 on success.
 */
int wrapper_f_genericRK(DATA* data, threadData_t *threadData, void* genericRKData, modelica_real* fODE)
{
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) genericRKData;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  fODE = sData->realVars + data->modelData->nStates;

  // TODO AHeu: We don't need userdata in this function when we count evalFunctionODE somewhere in data.
  rk_data->evalFunctionODE++;

  /* Evaluate ODE */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/*
 * Sets element (i,j) in matrixA to given value val.
 */
// TODO: Rename, its no longer ESDIRK and this is a dense matrix JF.
// Don't we already have such a function somewhere in the runtime?
void setJacElementESDIRKSparse(int i, int j, int nth, double val, void* Jf,
                              int rows)
{
  int l = j*rows + i;
  ((double*) Jf)[l]=val;
}

/**
 * @brief Calculate symbolic Jacobian of functionODE with respect to the states.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param rk_data       Runge-Kutta method.
 * @return int          Return 0 on success.
 */
int wrapper_Jf_symbolic_genericRK(DATA* data, threadData_t *threadData, DATA_GENERIC_RK* rk_data)
{
  /* profiling */
  rt_tick(SIM_TIMER_JACOBIAN);

  /* statisitcs */
  rk_data->evalJacobians++;

  /* Evaluate symbolic Jacobian */
  const int index = data->callback->INDEX_JAC_A;
  ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
  ANALYTIC_JACOBIAN* t_jac = jac;

  unsigned int columns = jac->sizeCols;
  unsigned int rows = jac->sizeRows;
  unsigned int sizeTmpVars = jac->sizeTmpVars;
  SPARSE_PATTERN* spp = jac->sparsePattern;

  /* Evaluate constant equations if available */
  if (jac->constantEqns != NULL) {
    jac->constantEqns(data, threadData, jac, NULL);
  }
  genericColoredSymbolicJacobianEvaluation(rows, columns, spp, rk_data->Jf, t_jac,
                                           data, threadData, &setJacElementESDIRKSparse);

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);

  return 0;
}

/**
 * @brief Calculate numeric Jacobian of functionODE with respect to the states.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param rk_data       Runge-Kutta method.
 * @return int          Return 0 on success.
 */
int wrapper_Jf_numeric_genericRK(DATA* data, threadData_t *threadData, DATA_GENERIC_RK* rk_data)
{
  int i,j,l;
  int nStates = data->modelData->nStates;
  double timeValue;

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *states = sData->realVars;
  modelica_real *stateDerivatives = &sData->realVars[nStates];

  timeValue = sData->timeValue;

  // Only implemented for non-linear solver Newton
  assertStreamPrint(threadData, rk_data->nlsSolverMethod == RK_NLS_NEWTON, "wrapper_Jf_numeric_genericRK only implemented for Newton solver");
  DATA_NEWTON* solverData = (DATA_NEWTON*)rk_data->nlsData;

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh;
  double xsave;

  /* profiling */
  rt_tick(SIM_TIMER_JACOBIAN);

  /* statisitcs */
  rk_data->evalJacobians++;

  /* Evaluate symbolic Jacobian */
  // TODO: Use a generic numeric Jacobian evaluation
  memcpy(rk_data->f, stateDerivatives, nStates * sizeof(double));
  for(i = 0; i < nStates; i++)
  {
    delta_hh = fmax(delta_h * fmax(fabs(states[i]), fabs(rk_data->f[i])), delta_h);
    delta_hh = ((rk_data->f[i] >= 0) ? delta_hh : -delta_hh);
    delta_hh = states[i] + delta_hh - states[i];
    xsave = states[i];
    states[i] += delta_hh;
    delta_hh = 1. / delta_hh;

    wrapper_f_genericRK(data, threadData, rk_data, stateDerivatives);
    // this should not count on function evaluation, since
    // it belongs to jacobian evaluation
    rk_data->evalFunctionODE--;

    /* BB: Is this necessary for the statistics? */
    solverData->nfev++;

    for(j = 0; j < nStates; j++)
    {
      l = i * nStates + j;
      rk_data->Jf[l] = (stateDerivatives[j] - rk_data->f[j]) * delta_hh;
    }
    states[i] = xsave;
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);

  return 0;
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
void residual_DIRK(void **dataIn, const double *xloc, double *res, const int *iflag)
{
  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GENERIC_RK *rk_data = (DATA_GENERIC_RK *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int nStates = data->modelData->nStates;
  int diagIdx = rk_data->act_stage * rk_data->tableau->nStages + rk_data->act_stage;

  // Evaluate right hand side of ODE
  sData->timeValue = rk_data->time + rk_data->tableau->c[rk_data->act_stage] * rk_data->stepSize;
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, rk_data, fODE);

  // Evaluate residual
  for (int i=0; i<nStates; i++) {
    res[i] = rk_data->res_const[i] - xloc[i] + rk_data->stepSize * rk_data->tableau->A[diagIdx] * fODE[i];
  }

  return;
}

/**
 * @brief Jacobian for non-linear system given by residual_DIRK.
 *
 * @param inData            Void pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param genericRKData     Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_DIRK(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA* data = (DATA*) inData;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) data->simulationInfo->backupSolverData;

  int i,j,l;
  int nStates = data->modelData->nStates;
  int diagIdx = rk_data->act_stage * rk_data->tableau->nStages + rk_data->act_stage;

  // TODO AHeu: Only compute once?

  /* Evaluate Jacobian of ODE */
  if (rk_data->symJacAvailable) {
    wrapper_Jf_symbolic_genericRK(data, threadData, rk_data);
  } else {
    wrapper_Jf_numeric_genericRK(data, threadData, rk_data);
  }

  /* Compute Jacobian of non-linear system */
  for (i = 0; i < nStates; i++)
  {
    for (j = 0; j < nStates; j++)
    {
      l = i * nStates + j;
      jacobian->resultVars[l] = rk_data->stepSize * rk_data->tableau->A[diagIdx] * rk_data->Jf[l];
      if (i == j)
      {
        jacobian->resultVars[l] -= 1;
      }
    }
  }

  return 0;
}


/**
 * @brief Evaluate residual for non-linear system of implicit Runge-Kutta method.
 *
 * TODO: Describe how the residual is computed.
 *
 * @param dataIn  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
 */
void residual_IRK(void **dataIn, const double *xloc, double *res, const int *iflag) {

  DATA *data = (DATA *)((void **)dataIn[0]);
  threadData_t *threadData = (threadData_t *)((void **)dataIn[1]);
  DATA_GENERIC_RK *rk_data = (DATA_GENERIC_RK *)((void **)dataIn[2]);

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  int k,l;
  int nStages = rk_data->tableau->nStages;
  int nStates = data->modelData->nStates;

  // Set res to previous result of RK step - xloc
  for (l = 0; l < nStages; l++)
  {
    for (i = 0; i < nStates; i++)
    {
      res[l * nStates + i] = rk_data->yOld[i] - xloc[l * nStates + i];
    }
  }

  for (k=0; k<nStages; k++)
  {
    /* Evaluate ODE and compute res for each stage */
    sData->timeValue = rk_data->time + rk_data->tableau->c[k] * rk_data->stepSize;
    memcpy(sData->realVars, &xloc[k*nStates], nStates*sizeof(double));
    wrapper_f_genericRK(data, threadData, rk_data, fODE);
    memcpy(&rk_data->k[k*nStates], fODE, nStates*sizeof(double));
    for (l=0; l<nStages; l++)
    {
      for (i=0; i<nStates; i++)
      {
        res[l * nStates + i] += rk_data->stepSize * rk_data->tableau->A[l * nStages + k] * fODE[i];
      }
    }
  }

  return;
}


int jacobian_IRK(void* inData, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  assertStreamPrint(threadData, 0, "jacobian_IRK not yet implemented!");

  DATA* data = (DATA*) inData;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  int i,j;
  int nStages = rk_data->tableau->nStages;
  int nStates = data->modelData->nStates;

#if 0
  assertStreamPrint(threadData, rk_data->nlsSolverMethod == RK_NLS_NEWTON, "full_implicit_RK only implemented for Newton solver");
  DATA_NEWTON* solverData = (DATA_NEWTON*)rk_data->nlsData;
  /*!
    *  fODE = f(tOld + h,x); x ~ yOld + h*(b1*k1+b2*k2+b3*k3)
    *  set correct time value and states of simulation system
    *  this should not count on function evaluation, since
    *  it belongs to the jacobian evaluation
    *  \ToBeChecked: This calculation maybe not be necessary since f has already
    *                just evaluated! works so far
    */
  // sData->timeValue = userdata->time + userdata->stepSize;
  // memcpy(sData->realVars, x, n*sizeof(double));
  // wrapper_f_genericRK(data, threadData, userdata, fODE);
  // userdata->evalFunctionODE--;

  /* store values for finite differences scheme
    * not necessary for analytic Jacobian */
  //memcpy(userdata->f, fODE, n*sizeof(double));

  /* Calculate Jacobian of the ODE system, stored in  solverData->fjac */
  //wrapper_Jf_genericRK(&n, x, userdata->f, userdata, fODE);
  // set correct time value and states of simulation system

  // residual function res = yOld-x[i]+h*(a[l][1]*k[1]+...+a[l][stages]*k[stages])
  // residual function res = yOld-x[i]+h*(a[l][1]*f(t[1],x[1])+...+a[l][stages]*f(t[stages],x[stages]))
  // jacobian          Jac = -E + h*(a[l][1]*Jf(t[1],x[1])+...+a[l][stages]*Jf(t[stages],x[stages]))
  for (i=0; i < nStages * nStates; i++)
  {
    for (j=0; j < nStages * nStates; j++)
    {
      if (i==j)
        solverData->fjac[i * nStages*nStates + j] = -1;
      else
        solverData->fjac[i * nStages*nStates + j] = 0;
    }
  }
  //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, userdata->time);
  for (k=0; k<nStages && !rk_data->isExplicit; k++)
  {
    // calculate Jf[k] and sweap over the stages
    sData->timeValue = rk_data->time + rk_data->tableau->c[k] * rk_data->stepSize;
    memcpy(sData->realVars, (x + k * nStates), nStates*sizeof(double));
    // works only for analytical Jacobian!!!
    //printf("Hier: %d\n", k);
    // BB: needs to be verified, that for the numerical Jacobian fODE is actual!!
    wrapper_Jf_symbolic_genericRK(data, threadData, rk_data);
    //wrapper_Jf_genericRK(n, sData->timeValue, sData->realVars, fODE, rk_data);
    //printMatrix_genericRK("Jacobian of system", userdata->Jf, n, sData->timeValue);
    //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, sData->timeValue);
    for (l=0; l<nStages; l++)
    {
      for (i=0; i<nStates; i++)
      {
        for (j=0; j<nStates; j++)
        {
          ind = l * nStages * nStates * nStates + i * nStages * nStates + j + k*nStates;
          solverData->fjac[ind] += rk_data->stepSize * rk_data->tableau->A[l * nStages + k] * rk_data->Jf[i * nStates + j];
          //solverData->fjac[ind] += userdata->Jf[i * n + j];
          //printf("Hier2: l=%d i=%d j=%d\n", l,i,j);
          //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, ind);
        }
      }
    }
  }

  return 0;
#else

  // TODO AHeu: How to evaluate the jacobian?

  /* Evaluate Jacobian of ODE */
  if (rk_data->symJacAvailable) {
    wrapper_Jf_symbolic_genericRK(data, threadData, rk_data);
  } else {
    wrapper_Jf_numeric_genericRK(data, threadData, rk_data);
  }

  /* Compute Jacobian of non-linear system */
  for (i = 0; i < nStages * nStates; i++)
  {
    for (j = 0; j < nStages * nStates; j++)
    {
      if (i == j)
        jacobian->resultVars[i * nStages * nStates + j] = -1;
      else
        jacobian->resultVars[i * nStages * nStates + j] = 0;
    }
  }
#endif
}

/**
 * @brief Generic diagonal implicit Runge-Kutta step function.
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;

  int stateIdx, k, l;
  int stage;
  int nStates = data->modelData->nStates;
  int nStages = rk_data->tableau->nStages;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;

  sData->timeValue = rk_data->time;
  solverInfo->currentTime = sData->timeValue;

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    /* Set constant parts or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */
    k = stage * nStages;    // Index of A[stage,0]
    for (stateIdx = 0; stateIdx < nStates; stateIdx++)
    {
      rk_data->res_const[stateIdx] = rk_data->yOld[stateIdx];
      for (l = 0; l < stage; l++)
      {
        rk_data->res_const[stateIdx] += rk_data->stepSize * rk_data->tableau->A[k + l] * rk_data->k[l * nStates + stateIdx];
      }
    }

    /* Compute intermediate step k
     * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
    k = stage * nStages + stage;    // Index of A[stage,stage]
    if (rk_data->tableau->A[k] == 0)
    {
      // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
      // set correct time value and states of simulation system
      sData->timeValue = rk_data->time + rk_data->tableau->c[stage]*rk_data->stepSize;
      memcpy(sData->realVars, rk_data->res_const, nStates*sizeof(double));
      rk_data->act_stage = stage;
      wrapper_f_genericRK(data, threadData, rk_data, fODE);
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = rk_data->nlsData;
      // Set start vector
      memcpy(nlsData->nlsx, rk_data->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, rk_data->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, rk_data->yOld, nStates*sizeof(modelica_real));
      solved = solveNLS(data, threadData, nlsData, -1);
      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "expl_diag_impl_RK: Failed to solve NLS in expl_diag_impl_RK");
        return -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(rk_data->k + stage * nStates, fODE, nStates*sizeof(double));
  }

  return 0;
}

/**
 * @brief Single implicit Runge-Kutta step.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, k, l, n=data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  modelica_boolean solved = FALSE;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;

  /* Set start values for non-linear solver */
  for (k=0; k<rk_data->tableau->nStages; k++) {
    //memcpy((solverData->x + k*n), rk_data->yOld, n*sizeof(double));
    memcpy(&rk_data->nlsData->nlsx[k*n], rk_data->yOld, n*sizeof(double));
    memcpy(&rk_data->nlsData->nlsxOld[k*n], rk_data->yOld, n*sizeof(double));
    memcpy(&rk_data->nlsData->nlsxExtrapolation[k*n], rk_data->yOld, n*sizeof(double));
  }

  solved = solveNLS(data, threadData, rk_data->nlsData, -1);
  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "full_implicit_RK: Failed to solve NLS in full_implicit_RK");
    return -1;
  }

  return 0;
}

/**
 * @brief Initialize values and calculate initial step size.
 *
 * Called at the beginning of simulation or after an event occurred.
 *
 * TODO BB: Lookup the reference in Hairers book
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 */
void genericRK_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GENERIC_RK* rk_data = (DATA_GENERIC_RK*)solverInfo->solverData;
  const int nStates = data->modelData->nStates;
  modelica_real* fODE = &sData->realVars[nStates];

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  // TODO AHeu: We have flags for absolute and relative solver tolerances
  // Use data->simulationInfo->tolerance?
  double Atol = 1e-6;
  double Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  rk_data->time = sDataOld->timeValue;

  /* set correct flags in order to calculate initial step size */
  rk_data->isFirstStep = FALSE;
  solverInfo->didEventStep = 0;

 /* reset statistics because it is accumulated in solver_main.c */
  rk_data->stepsDone = 0;
  rk_data->evalFunctionODE = 0;
  rk_data->evalJacobians = 0;
  rk_data->errorTestFailures = 0;
  rk_data->convergenceFailures = 0;

  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_genericRK("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_genericRK("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);
  memcpy(rk_data->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, rk_data, fODE);
  /* store values of the state derivatives at initial or event time */
  memcpy(rk_data->f, fODE, data->modelData->nStates*sizeof(double));

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((fODE[i] * fODE[i]) / (sc*sc));
  }
  d0 /= data->modelData->nStates;
  d1 /= data->modelData->nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);

  /* calculate first guess of the initial step size */
  if (d0 < 1e-5 || d1 < 1e-5)
  {
    h0 = 1e-6;
  }
  else
  {
    h0 = 0.01 * d0/d1;
  }


  for (i=0; i<data->modelData->nStates; i++)
  {
    sData->realVars[i] = rk_data->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_genericRK(data, threadData, rk_data, fODE);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(rk_data->yOld[i])*Rtol;
    d2 += ((fODE[i]-rk_data->f[i])*(fODE[i]-rk_data->f[i])/(sc*sc));
  }

  d2 /= h0;
  d2 = sqrt(d2);


  d = fmax(d1,d2);

  if (d > 1e-15)
  {
    h1 = sqrt(0.01/d);
  }
  else
  {
    h1 = fmax(1e-6, h0*1e-3);
  }

  rk_data->stepSize = 0.5*fmin(100*h0,h1);

  /* end calculation new step size */

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e at time %g", rk_data->stepSize, rk_data->time);
}

/**
 * @brief Generic Runge-Kutta step.
 *
 * Do one Runge-Kutta integration step.
 * Has step-size controll and event handling.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Storing Runge-Kutta solver data.
 * @return int          Return 0 on success, -1 on failure.
 */
int genericRK_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* rkData = (DATA_GENERIC_RK*)solverInfo->solverData;

  double err;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  int i, l;
  int nStates = (int) data->modelData->nStates;
  int esdirk_imp_step_info;
  // find appropriate value using the TestAnalytic.mo example
  //double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double norm_errtol;
  double norm_errest;
  double targetTime;

  // TODO AHeu: Copy-paste code used in dassl,c, ida.c, irksco.c and here. Make it a function!
  // Also instead of solverInfo->integratorSteps we should set and use solverInfo->solverNoEquidistantGrid
  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => stepSizeControl; 0 => equidistant grid
  {
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime)
    {
      targetTime = data->simulationInfo->nextSampleEvent;
    }
    else
    {
      targetTime = data->simulationInfo->stopTime;
    }
  }
  else
  {
    targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  // (Re-)initialize after events or at first call of genericRK_step
  if (solverInfo->didEventStep == 1 || rkData->isFirstStep)
  {
    genericRK_first_step(data, threadData, solverInfo);
    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  /* Main integration loop */
  while (rkData->time < targetTime)
  {
    do
    {
      /* calculate jacobian:
       *    once for the first iteration after initial or an event
       *    solverData->calculate_jacobian = 0
       *    always
       *    solverData->calculate_jacobian = 1
       *
       * BB: How does this actually work in combination with the Newton method?
       */
      // TODO AHeu: Not sure how to handle this one
      //if (rkData->stepsDone == 0)
      //  solverData->calculate_jacobian = 0;

      // calculate one step of the integrator
      esdirk_imp_step_info = rkData->step_fun(data, threadData, solverInfo);
      if (esdirk_imp_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "genericRK_step: Failed to calculate step.");
        return -1;
      }

      // printVector_genericRK("y ", userdata->y, data->modelData->nStates, userdata->time);
      // printVector_genericRK("yt ", userdata->yt, data->modelData->nStates, userdata->time);
      // y       = yold+h*sum(b[i]*k[i], i=1..stages);
      // yt      = yold+h*sum(bt[i]*k[i], i=1..stages);
      // calculate corresponding values for error estimator and step size control
      for (i=0; i<nStates; i++)
      {
        rkData->y[i]  = rkData->yOld[i];
        rkData->yt[i] = rkData->yOld[i];
        for (l=0; l<rkData->tableau->nStages; l++)
        {
          rkData->y[i]  += rkData->stepSize * rkData->tableau->b[l]  * (rkData->k + l * nStates)[i];
          rkData->yt[i] += rkData->stepSize * rkData->tableau->bt[l] * (rkData->k + l * nStates)[i];
        }
        //userdata->errtol[i] = Rtol*fabs(userdata->yOld[i]) + Atol;
        rkData->errtol[i] = Rtol*fmax(fabs(rkData->y[i]),fabs(rkData->yt[i])) + Atol;
        rkData->errest[i] = fabs(rkData->y[i] - rkData->yt[i]);
      }

      //printVector_genericRK("y ", userdata->y, n, userdata->time);
      //printVector_genericRK("yt ", userdata->yt, n, userdata->time);



      /*** calculate error (infinity norm!)***/
      // norm_errtol = 0;
      // norm_errest = 0;
      // for (i=0; i<data->modelData->nStates; i++)
      // {
      //    norm_errtol = fmax(norm_errtol, userdata->errtol[i]);
      //    norm_errest = fmax(norm_errest, userdata->errest[i]);
      // }
      // err = norm_errest/norm_errtol;
      /*** calculate error (euclidian norm) ***/
      for (i=0, err=0.0; i<nStates; i++)
      {
        err += (rkData->errest[i]*rkData->errest[i])/(rkData->errtol[i]*rkData->errtol[i]);
      }

      err /= nStates;
      err = sqrt(err);

      // Store performed stepSize for adjusting the time and interpolation purposes
      rkData->lastStepSize = rkData->stepSize;
      rkData->stepSize *= fmin(facmax, fmax(facmin, rkData->tableau->fac*pow(1.0/err, 1./rkData->tableau->error_order)));
      /*
       * step size control from Luca, etc.:
       * stepSize = seccoeff*sqrt(norm_errtol/fmax(norm_errest,errmin));
       * printf("Error:  %g, New stepSize: %g from %g to  %g\n", err, userdata->stepSize, userdata->time, userdata->time+stepSize);
       */
      if (err>1)
      {
        rkData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        rkData->time, rkData->time + rkData->lastStepSize, err, rkData->stepSize);
      }
      rkData->stepsDone += 1;
    } while  (err>1);

    /* update time with performed stepSize */
    rkData->time += rkData->lastStepSize;

    /* store yOld in yt for interpolation purposes, if necessary
     * BB: Check condition
     */
    if (rkData->time > targetTime )
      memcpy(rkData->yt, rkData->yOld, data->modelData->nStates*sizeof(double));

    /* step is accepted and yOld needs to be updated */
    memcpy(rkData->yOld, rkData->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 1, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    rkData->time- rkData->lastStepSize, rkData->time, err, rkData->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = rkData->time;
      memcpy(sData->realVars, rkData->y, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
    messageClose(LOG_SOLVER);
  }

  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
    sData->timeValue = solverInfo->currentTime;
    linear_interpolation(rkData->time-rkData->lastStepSize, rkData->yt, rkData->time, rkData->y, sData->timeValue, sData->realVars, data->modelData->nStates);
    // printVector_genericRK("yOld: ", userdata->yt, data->modelData->nStates, userdata->time-userdata->lastStepSize);
    // printVector_genericRK("y:    ", userdata->y, data->modelData->nStates, userdata->time);
    // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
  }else{
    // Integrator emits result on the simulation grid
    solverInfo->currentTime = rkData->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  /* Solver statistics */
  if(ACTIVE_STREAM(LOG_SOLVER))
  {
    infoStreamPrint(LOG_SOLVER, 1, "genericRK call statistics: ");
    infoStreamPrint(LOG_SOLVER, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER, 0, "current integration time value: %0.4g", rkData->time);
    infoStreamPrint(LOG_SOLVER, 0, "step size h to be attempted on next step: %0.4g", rkData->stepSize);
    infoStreamPrint(LOG_SOLVER, 0, "number of steps taken so far: %d", rkData->stepsDone);
    infoStreamPrint(LOG_SOLVER, 0, "number of calls of functionODE() : %d", rkData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER, 0, "number of calculation of jacobian : %d", rkData->evalJacobians);
    infoStreamPrint(LOG_SOLVER, 0, "error test failure : %d", rkData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER, 0, "convergence failure : %d", rkData->convergenceFailures);
    messageClose(LOG_SOLVER);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = rkData->stepsDone;
  solverInfo->solverStatsTmp[1] = rkData->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = rkData->evalJacobians;
  solverInfo->solverStatsTmp[3] = rkData->errorTestFailures;
  solverInfo->solverStatsTmp[4] = rkData->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished genericRK step.");
  return 0;
}


// TODO AHeu: For sure ther is already a linear interpolation function somewhere
//auxiliary vector functions for better code structure
void linear_interpolation(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
{
  double lambda, h0, h1;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<n; i++)
  {
    f[i] = h0*fa[i] + h1*fb[i];
  }
}

void printVector_genericRK(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n", name, time);
  for (int i=0;i<n;i++)
    printf("%6g ", a[i]);
  printf("\n");
}

void printMatrix_genericRK(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}
