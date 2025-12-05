/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_nls.c
 */

#include "gbode_main.h"
#include "gbode_nls.h"
#include "gbode_util.h"
#include "gbode_sparse.h"

#include "../../simulation_data.h"

#include "arrayIndex.h"
#include "solver_main.h"
#include "kinsolSolver.h"
#include "kinsol_b.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"

#include "../jacobian_util.h"
#include "../../util/rtclock.h"

/* forward declarations */
int jacobian_SR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);
int jacobian_MR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);
int jacobian_IRK_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian);

/**
 * @brief Specific error handling of kinsol for gbode
 *
 * @param error_code  Reported error code
 * @param module      Module of failure
 * @param function    Nonlinear function
 * @param msg         Message of failure
 * @param data        Pointer to userData
 */
void GB_KINErrHandler(int error_code, const char *module, const char *function, char *msg, void *data)
{
// Preparation for specific error handling of the solution process of kinsol for gbode
// This is needed to speed up simulation in case of failure
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagonal implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_SR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states
    const modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, i);
    nonlinsys->nominal[i] = fmax(fabs(nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[i].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[i].attribute.max;
  }

  /* Initialize sparsity pattern */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Initialize static data of non-linear system for DIRK.
 *
 * Initialize for diagonal implicit Runge-Kutta (DIRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_MR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  // This needs to be done each time, the fast states change!
  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states
    const modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, i);
    nonlinsys->nominal[i] = fmax(fabs(nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[i].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[i].attribute.max;
  }

  /* Initialize sparsity pattern, First guess (all states are fast states) */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Initialize static data of non-linear system for IRK.
 *
 * Initialize for implicit Runge-Kutta (IRK) method.
 * Sets min, max, nominal values and sparsity pattern.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param nonlinsys         Non-linear system data.
 */
void initializeStaticNLSData_IRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsePattern, modelica_boolean initNonlinearPattern)
{
  for (int i = 0; i < nonlinsys->size; i++) {
    // Get the nominal values of the states, the non-linear system has size stages*nStates, i.e. [states, states, ...]
    int ii = i % data->modelData->nStates;
    const modelica_real nominal = getNominalFromScalarIdx(data->simulationInfo, data->modelData, ii);
    nonlinsys->nominal[i] = fmax(fabs(nominal), 1e-32);
    nonlinsys->min[i]     = data->modelData->realVarsData[i].attribute.min;
    nonlinsys->max[i]     = data->modelData->realVarsData[i].attribute.max;
  }

  /* Initialize sparsity pattern */
  if (initSparsePattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_IRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
}

/**
 * @brief Allocate memory for non-linear system data.
 *
 * Initialize varaibles with 0.
 * Free memory with freeNlsDataGB.
 *
 * @param threadData                Used for error handling
 * @param size                      Size of non-linear system
 * @return NONLINEAR_SYSTEM_DATA*   Allocated non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* allocNlsDataGB(threadData_t* threadData, const int size)
{
  NONLINEAR_SYSTEM_DATA* nlsData = (NONLINEAR_SYSTEM_DATA*) calloc(1, sizeof(NONLINEAR_SYSTEM_DATA));
  assertStreamPrint(threadData, nlsData != NULL,"Out of memory");

  nlsData->size = size;

  nlsData->nlsx              = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxExtrapolation = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->nlsxOld           = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->resValues         = (double*) malloc(nlsData->size*sizeof(double));

  nlsData->nominal = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->min     = (double*) malloc(nlsData->size*sizeof(double));
  nlsData->max     = (double*) malloc(nlsData->size*sizeof(double));
  return nlsData;
}

/**
 * @brief Free non-linear system data.
 *
 * @param nlsData   Pointer to nls-data.
 */
void freeNlsDataGB(NONLINEAR_SYSTEM_DATA* nlsData)
{
  free(nlsData->nlsx);
  free(nlsData->nlsxExtrapolation);
  free(nlsData->nlsxOld);
  free(nlsData->resValues);
  free(nlsData->nominal);
  free(nlsData->min);
  free(nlsData->max);
  free(nlsData);
}

/**
 * @brief Allocate and initialize non-linear system data for Runge-Kutta method.
 *
 * Runge-Kutta method has to be implicit or diagonal implicit.
 *
 * @param data                        Runtime data struct.
 * @param threadData                  Thread data for error handling.
 * @param gbData                     Runge-Kutta method.
 * @return NONLINEAR_SYSTEM_DATA*     Pointer to initialized non-linear system data.
 */
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData)
{
  assertStreamPrint(threadData, gbData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;

  nlsData = allocNlsDataGB(threadData, gbData->nlSystemSize);
  nlsData->equationIndex = -1;

  switch (gbData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_SR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_SR;
    nlsData->getIterationVars = NULL;

    break;
  case GM_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_IRK;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_IRK_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_IRK;
    nlsData->getIterationVars = NULL;

    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS;
    if (gbData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_SR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_SR;
    nlsData->getIterationVars = NULL;

    break;
  default:
    throwStreamPrint(NULL, "Residual function for NLS type %i not yet implemented.", gbData->type);
  }

  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE, TRUE);

  gbData->jacobian = (JACOBIAN*) malloc(sizeof(JACOBIAN));
  initJacobian(gbData->jacobian, gbData->nlSystemSize, gbData->nlSystemSize, gbData->nlSystemSize, nlsData->analyticalJacobianColumn, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbData->jacobian);
  nlsUserData->solverData = (void*) gbData;

  /* Initialize NLS method */
  switch (gbData->nlsSolverMethod) {
  case GB_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData = (void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL_B:
    nlsData->nlsMethod = NLS_KINSOL_B;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) B_nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  default:
    throwStreamPrint(NULL, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbData->nlsSolverMethod]);
  }

  return nlsData;
}

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
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData)
{
  assertStreamPrint(threadData, gbfData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  struct dataSolver *solverData = (struct dataSolver*) calloc(1, sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;

  nlsData = allocNlsDataGB(threadData, gbfData->nStates);
  nlsData->equationIndex = -1;

  switch (gbfData->type)
  {
  case GM_TYPE_DIRK:
    nlsData->residualFunc = residual_DIRK_MR;
    if (gbfData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_MR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    break;
  case MS_TYPE_IMPLICIT:
    nlsData->residualFunc = residual_MS_MR;
    if (gbfData->symJacAvailable) {
      nlsData->analyticalJacobianColumn = jacobian_MR_column;
    } else {
      nlsData->analyticalJacobianColumn = NULL;
    }
    nlsData->initializeStaticNLSData = initializeStaticNLSData_MR;
    nlsData->getIterationVars = NULL;

    break;
  default:
    throwStreamPrint(NULL, "Residual function for NLS type %i not yet implemented.", gbfData->type);
  }

  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE, TRUE);

  gbfData->jacobian = (JACOBIAN*) malloc(sizeof(JACOBIAN));
  initJacobian(gbfData->jacobian, gbfData->nlSystemSize, gbfData->nlSystemSize, gbfData->nlSystemSize, nlsData->analyticalJacobianColumn, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbfData->jacobian);
  nlsUserData->solverData = (void*) gbfData;

  /* Initialize NLS method */
  switch (gbfData->nlsSolverMethod) {
  case GB_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case GB_NLS_KINSOL_B:
    nlsData->nlsMethod = NLS_KINSOL_B;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) B_nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE, nlsData->isPatternAvailable);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  default:
    throwStreamPrint(NULL, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
  }

  return nlsData;
}

/**
 * @brief Free memory of gbode non-linear system data.
 *
 * Free memory allocated with initRK_NLS_DATA or initRK_NLS_DATA_MR
 *
 * @param nlsData           Pointer to non-linear system data.
 */
void freeRK_NLS_DATA(NONLINEAR_SYSTEM_DATA* nlsData)
{
  if (nlsData == NULL) return;

  struct dataSolver *dataSolver = nlsData->solverData;
  switch (nlsData->nlsMethod)
  {
  case NLS_NEWTON:
    freeNewtonData(dataSolver->ordinaryData);
    break;
  case NLS_KINSOL:
    nlsKinsolFree(dataSolver->ordinaryData);
    break;
  case NLS_KINSOL_B:
    B_nlsKinsolFree(dataSolver->ordinaryData);
    break;
  default:
    throwStreamPrint(NULL, "Not handled NONLINEAR_SOLVER in gbode_freeData. Are we leaking memroy?");
  }
  free(dataSolver);
  freeNlsDataGB(nlsData);
}

/**
 * @brief Set kinsol parameters
 *
 * @param kin_mem       Pointer to kinsol data object
 * @param numIter       Number of nonlinear iterations
 * @param jacUpdate     Update of jacobian necessary (SUNFALSE => yes)
 * @param maxJacUpdate  Maximal number of constant jacobian
 */
void set_kinsol_parameters(void* kin_mem, int numIter, int jacUpdate, int maxJacUpdate, double tolerance)
{
    int flag;

    flag = KINSetNumMaxIters(kin_mem, numIter);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");
    flag = KINSetNoInitSetup(kin_mem, jacUpdate);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNoInitSetup");
    flag = KINSetMaxSetupCalls(kin_mem, maxJacUpdate);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetMaxSetupCalls");
    flag = KINSetFuncNormTol(kin_mem, tolerance);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetFuncNormTol");
}

/**
 * @brief Get the kinsol statistics object
 *
 * @param kin_mem Pointer to kinsol data object
 */
void get_kinsol_statistics(NLS_KINSOL_DATA* kin_mem)
{
  int flag;
  long int nIters, nFuncEvals, nJacEvals;
  double fnorm;

  // Get number of nonlinear iteration steps
  flag = KINGetNumNonlinSolvIters(kin_mem, &nIters);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumNonlinSolvIters");

  // Get the error of the residual function
  flag = KINGetFuncNorm(kin_mem, &fnorm);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetFuncNorm");

  // Get the number of jacobian evaluation
  flag = KINGetNumJacEvals(kin_mem, &nJacEvals);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumJacEvals");

  // Get the number of function evaluation
  flag = KINGetNumFuncEvals(kin_mem, &nFuncEvals);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINGetNumFuncEvals");

  // Report numbers
  infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "Kinsol statistics: nIters = %ld, nFuncEvals = %ld, nJacEvals = %ld,  fnorm:  %14.12g", nIters, nFuncEvals, nJacEvals, fnorm);
}
/**
 * @brief Special treatment when solving non linear systems of equations
 *
 *        Will be described, when it is ready
 *
 * @param data                Pointer to runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nlsData             Non-linear solver data.
 * @param gbData              Runge-Kutta method.
 * @return NLS_SOLVER_STATUS  Return NLS_SOLVED on success and NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS solveNLS_gb(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData, DATA_GBODE* gbData)
{
  struct dataSolver * solverData = (struct dataSolver *)nlsData->solverData;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  // Debug nonlinear solution process
  rtclock_t clock;
  double cpu_time_used;
  double newtonTol = fmax(newtonFTol, newtonXTol);
  double newtonMaxStepsValue = fmax(newtonMaxSteps, 10*nlsData->size);

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    rt_ext_tp_tick(&clock);
  }

  if (gbData->nlsSolverMethod == GB_NLS_KINSOL || gbData->nlsSolverMethod == GB_NLS_KINSOL_B) {
    // Get kinsol data object
    void* kin_mem;
    if (gbData->nlsSolverMethod == GB_NLS_KINSOL){
       kin_mem = ((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory;
    }
    else {
       kin_mem = ((B_NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory;
    }
    if (maxJacUpdate[0] > 0) {
      set_kinsol_parameters(kin_mem, newtonMaxSteps, SUNTRUE, maxJacUpdate[0], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[1] > 0) {
      if (maxJacUpdate[0] > 0)
        infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "GBODE: Solution of NLS failed. Try with updated Jacobian.");
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[1], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[2] > 0) {
      infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "GBODE: Solution of NLS failed, Try with extrapolated start value.");
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsxOld,  nlsData->size*sizeof(modelica_real));
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[2], newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
    if (!solved && maxJacUpdate[3] > 0) {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "GBODE: Solution of NLS failed, Try with less accuracy.");
      memcpy(nlsData->nlsxExtrapolation,    nlsData->nlsx, nlsData->size*sizeof(modelica_real));
      set_kinsol_parameters(kin_mem, newtonMaxStepsValue, SUNFALSE, maxJacUpdate[3], 10*newtonTol);
      solved = solveNLS(data, threadData, nlsData);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) get_kinsol_statistics(kin_mem);
    }
  } else {
    solved = solveNLS(data, threadData, nlsData);
  }

  if (solved)
    infoStreamPrint(OMC_LOG_GBODE_NLS_V, 0, "GBODE: NLS solved.");

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    cpu_time_used = rt_ext_tp_tock(&clock);
    infoStreamPrint(OMC_LOG_GBODE_NLS, 0, "Time needed for solving the NLS:  %20.16g", cpu_time_used);
  }

  return solved;
}

/**
 * @brief Residual function for non-linear system of generic multi-step methods.
 *
 * Based on the values of the multi-step method the following nonlinear residuals
 * will be calculated:
 * res = -sum(c[j]*x[j], i=1..stage) + h*sum(b[j]*k[j], i=1..stage)
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + h
 *  res_const = -sum(c[j]*x[j], i=1..stage-1) + h*sum(b[j]*k[j], i=1..stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_MS(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_MS: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  const int nStates = data->modelData->nStates;
  const int nStages = gbData->tableau->nStages;

  // Set states
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_MS: xloc is NAN");
  memcpy(sData->realVars, xloc, nStates*sizeof(modelica_real));
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_MS: fODE is NAN");

  // Evaluate residuals
  for (i = 0; i < nStates; i++) {
    res[i] = gbData->res_const[i]
             - xloc[i] * gbData->tableau->c[nStages-1]
             + fODE[i] * gbData->tableau->b[nStages-1] * gbData->stepSize;
  }
}

/**
 * @brief Residual function for non-linear system of generic multi-step methods.
 *
 * For the fast states:
 * Based on the values of the multi-step method the following nonlinear residuals
 * will be calculated:
 * res = -sum(c[j]*x[j], i=1..stage) + h*sum(b[j]*k[j], i=1..stage)
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + h
 *  res_const = -sum(c[j]*x[j], i=1..stage-1) + h*sum(b[j]*k[j], i=1..stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_MS_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODEF *gbfData = (DATA_GBODEF *)userData->solverData;
  assertStreamPrint(threadData, gbfData != NULL, "residual_MS_MR: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  const int nFastStates = gbfData->nFastStates;
  const int nStages = gbfData->tableau->nStages;

  // Set fast states
  // ph: are slow states interpolated and set correctly?
  for (ii = 0; ii < nFastStates; ii++) {
    assertStreamPrint(threadData, !isnan(xloc[ii]), "residual_MS_MR: xloc is NAN");
    i = gbfData->fastStatesIdx[ii];
    sData->realVars[i] = xloc[ii];
  }
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));

  // Evaluate residuals
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbfData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_MS_MR: fODE is NAN");
    res[ii] = gbfData->res_const[i]
              - xloc[ii] * gbfData->tableau->c[nStages-1]
              + fODE[i]  * gbfData->tableau->b[nStages-1] * gbfData->stepSize;
  }
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], j=1..act_stage))
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + c[i]*h
 *  res_const = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_DIRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_DIRK: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i;
  const int nStates = data->modelData->nStates;
  const int nStages = gbData->tableau->nStages;
  const int stage_  = gbData->act_stage;
  const modelica_real fac = gbData->stepSize * gbData->tableau->A[stage_ * nStages + stage_];

  // Set states
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_DIRK: xloc is NAN");
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

  // Evaluate residuals
  for (i = 0; i < nStates; i++) {
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_DIRK: fODE is NAN");
    res[i] = gbData->res_const[i] - xloc[i] + fac * fODE[i];
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - x and residual:");
    printVector_gb(OMC_LOG_GBODE_NLS, "x", (double *)xloc, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    printVector_gb(OMC_LOG_GBODE_NLS, "r", res, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    messageClose(OMC_LOG_GBODE_NLS);
  }
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * For the fast states:
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 *   y[j] = yOld + h*sum(A[i,j]*k[j], j=1..act_stage)
 *   res_const[j] = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 * res = res_const[j] - y[j] + f(tOld + c[i]*h, y[j])
 * When calling, the following is already calculated:
 *  sData->timeValue = tOld + c[i]*h
 *  res_const = yOld + h*sum(A[i,j]*k[j], j=1..act_stage-1)
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_DIRK_MR(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag)
{
  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODEF *gbfData = (DATA_GBODEF *)userData->solverData;
  assertStreamPrint(threadData, gbfData != NULL, "residual_DIRK_MR: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = &sData->realVars[data->modelData->nStates];

  int i, ii;
  const int nFastStates = gbfData->nFastStates;
  const int nStages = gbfData->tableau->nStages;
  const int stage_  = gbfData->act_stage;
  const modelica_real fac = gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_];

  // Set fast states
  // ph: are slow states interpolated and set correctly?
  for (ii = 0; ii < nFastStates; ii++) {
    assertStreamPrint(threadData, !isnan(xloc[ii]), "residual_DIRK_MR: xloc is NAN");
    i = gbfData->fastStatesIdx[ii];
    sData->realVars[i] = xloc[ii];
  }
  // Evaluate right hand side of ODE
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));

  // Evaluate residuals
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbfData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(fODE[i]), "residual_DIRK_MR: fODE is NAN");
    res[ii] = gbfData->res_const[i] - xloc[ii] + fac * fODE[i];
  }
}

/**
 * @brief Evaluate residual for non-linear system of implicit Runge-Kutta method.
 *
 * Based on the Butcher tableau the following nonlinear residuals will be calculated:
 *
 * for i=1 .. stage
 *  res[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], j=1..stage))
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc      Input vector for non-linear system.
 * @param res       Residuum vector for given input xloc.
 * @param iflag     Unused.
 */
void residual_IRK(RESIDUAL_USERDATA* userData, const double *xloc, double *res, const int *iflag) {

  DATA *data = userData->data;
  threadData_t *threadData = userData->threadData;
  DATA_GBODE *gbData = (DATA_GBODE *)userData->solverData;
  assertStreamPrint(threadData, gbData != NULL, "residual_IRK: user data not set correctly");

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  int i;
  const int nStages = gbData->tableau->nStages;
  const int nStates = data->modelData->nStates;
  int stage, stage_;

  for (i = 0; i < nStages*nStates; i++)
    assertStreamPrint(threadData, !isnan(xloc[i]), "residual_IRK: xloc is NAN");

  // Update the derivatives for current estimate of the states
  for (stage_ = 0; stage_ < nStages; stage_++) {
    /* Evaluate ODE for each stage_ */
    if (!gbData->tableau->isKLeftAvailable || stage_ > 0) {
      sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
      memcpy(sData->realVars, xloc + stage_ * nStates, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      for (i = 0; i < nStates; i++)
        assertStreamPrint(threadData, !isnan(fODE[i]), "residual_IRK: fODE is NAN");
      memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
    } else {
      // memcpy(sData->realVars, gbData->yLeft, nStates*sizeof(double));
      memcpy(gbData->k + stage_ * nStates, gbData->kLeft, nStates*sizeof(double));
    }
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (stage = 0; stage < nStages; stage++) {
    for (i = 0; i < nStates; i++) {
      res[stage * nStates + i] = gbData->yOld[i] - xloc[stage * nStates + i];
      for (stage_ = 0; stage_ < nStages; stage_++) {
        res[stage * nStates + i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * (gbData->k + stage_*nStates)[i];
      }
    }
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - residual:");
    for (stage = 0; stage < nStages; stage++) {
      printVector_gb(OMC_LOG_GBODE_NLS, "r", res + stage*nStates, nStates, gbData->time + gbData->tableau->c[stage] * gbData->stepSize);
    }
    messageClose(OMC_LOG_GBODE_NLS);
  }
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_SR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  int i;
  const int nStages = gbData->tableau->nStages;
  const int stage = gbData->act_stage;
  modelica_real fac;

  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  /* Evaluate column of Jacobian ODE */
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  if (gbData->type == MS_TYPE_IMPLICIT) {
    fac = gbData->stepSize * gbData->tableau->b[nStages-1];
  } else {
    fac = gbData->stepSize * gbData->tableau->A[stage * nStages + stage];
  }

  for (i = 0; i < jacobian->sizeCols; i++) {
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_SR_column: jacobian_ODE is NAN");
    jacobian->resultVars[i] = fac * jacobian_ODE->resultVars[i] - jacobian->seedVars[i];
  }

  return 0;
}

/**
 * @brief Evaluate column of DIRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_MR_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  /* define callback to column function of Jacobian ODE */
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  const int nStages = gbfData->tableau->nStages;
  const int nFastStates = gbData->nFastStates;
  const int stage_ = gbfData->act_stage;
  modelica_real fac;

  for (i = 0; i < jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStatesIdx[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  if (gbfData->type == MS_TYPE_IMPLICIT) {
    fac = gbfData->stepSize * gbfData->tableau->b[nStages-1];
  } else {
    fac = gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_];
  }

  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStatesIdx[ii];
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_MR_column: jacobian_ODE is NAN");
    jacobian->resultVars[ii] = fac * jacobian_ODE->resultVars[i] - jacobian->seedVars[ii];
  }

  return 0;
}

/**
 * @brief Evaluate column of IRK Jacobian.
 *
 * @param data              Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(DATA* data, threadData_t *threadData, JACOBIAN *jacobian, JACOBIAN *parentJacobian)
{
  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = gbData->nlsData->nlsx;

  int i;
  int stage, stage_;
  const int nStages = gbData->tableau->nStages;
  const int nStates = data->modelData->nStates;

  /* Evaluate column of Jacobian ODE */
  JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  // and find out which stage is active; different stages have different colors
  // reset jacobian_ODE->seedVars
  for (i = 0; i < jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (i = 0, stage_ = 0; i < jacobian->sizeCols; i++) {
    if (jacobian->seedVars[i]) {
      stage_ = i; /* store last index, for determining the active stage */
      jacobian_ODE->seedVars[i%jacobian_ODE->sizeCols] = 1;
    }
  }

  // Determine active stage
  stage_ = stage_/jacobian_ODE->sizeCols;

  // update timeValue and unknown vector based on the active column "stage_"
  sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
  memcpy(sData->realVars, &(xloc[stage_*nStates]), nStates*sizeof(double));

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);
  for (i = 0; i < nStates; i++)
    assertStreamPrint(threadData, !isnan(jacobian_ODE->resultVars[i]), "jacobian_SR_column: jacobian_ODE is NAN");

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (stage = 0; stage < nStages; stage++) {
    for (i = 0; i < nStates; i++) {
      jacobian->resultVars[stage * nStates + i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage_]  * jacobian_ODE->resultVars[i] - jacobian->seedVars[stage * nStates + i];
    }
  }

  return 0;
}
