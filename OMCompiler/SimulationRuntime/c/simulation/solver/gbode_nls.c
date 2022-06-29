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

#include "solver_main.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"

#include "util/jacobian_util.h"

int gbode_fODE(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE);


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
void initializeStaticNLSData_SR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if (initSparsPattern) {
    // TODO AHeu: This is leaking memory?
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
  return;
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
void initializeStaticNLSData_MR(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {

  // This needs to be done each time, the fast states change!
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern, First guess (all states are fast states) */
  if (initSparsPattern) {
    // TODO AHeu: This is leaking memory?
    nonlinsys->sparsePattern = initializeSparsePattern_SR(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
  return;
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
void initializeStaticNLSData_IRK(DATA* data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nonlinsys, modelica_boolean initSparsPattern) {
  for(int i=0; i<nonlinsys->size; i++) {
    // Get the nominal values of the states, the non-linear system has size stages*nStates
    int ii = i % data->modelData->nStates;
    nonlinsys->nominal[i] = fmax(fabs(data->modelData->realVarsData[ii].attribute.nominal), 1e-32);
    nonlinsys->min[i]     = DBL_MIN;
    nonlinsys->max[i]     = DBL_MAX;
  }

  /* Initialize sparsity pattern */
  if (initSparsPattern) {
    nonlinsys->sparsePattern = initializeSparsePattern_IRK(data, nonlinsys);
    nonlinsys->isPatternAvailable = TRUE;
  }
  return;
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
NONLINEAR_SYSTEM_DATA* allocNlsDataGB(threadData_t* threadData, const int size) {
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
void freeNlsDataGB(NONLINEAR_SYSTEM_DATA* nlsData) {
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
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA(DATA* data, threadData_t* threadData, DATA_GBODE* gbData) {
  assertStreamPrint(threadData, gbData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  // TODO AHeu: Free solverData again
  struct dataSolver *solverData = (struct dataSolver*) calloc(1,sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

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
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gbData->type);
    break;
  }

  // TODO: Do we need to initialize the Jacobian or is it already initialized?
  // This leaks memory
  //ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  //data->callback->initialAnalyticJacobianA(data, threadData, jacobian_ODE);
  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  // TODO AHeu: This will leak memory if gbData->jacobian is already set!
  // What Jacobian is this? For the NLS or for the ODE?
  gbData->jacobian = (ANALYTIC_JACOBIAN*) malloc(sizeof(ANALYTIC_JACOBIAN));
  initAnalyticJacobian(gbData->jacobian, gbData->nlSystemSize, gbData->nlSystemSize, gbData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbData->jacobian);
  nlsUserData->solverData = (void*) gbData;

  /* Initialize NLS method */
  switch (gbData->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case RK_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;

    int flag = KINSetNumMaxIters(((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory, nlsData->size * 10);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_KIN_FLAG, "KINSetNumMaxIters");
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbData->nlsSolverMethod]);
    return NULL;
    break;
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
NONLINEAR_SYSTEM_DATA* initRK_NLS_DATA_MR(DATA* data, threadData_t* threadData, DATA_GBODEF* gbfData) {
  assertStreamPrint(threadData, gbfData->type != GM_TYPE_EXPLICIT, "Don't initialize non-linear solver for explicit Runge-Kutta method.");

  struct dataSolver *solverData = (struct dataSolver*) calloc(1, sizeof(struct dataSolver));

  NONLINEAR_SYSTEM_DATA* nlsData;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn;

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
    errorStreamPrint(LOG_STDOUT, 0, "Residual function for NLS type %i not yet implemented.", gbfData->type);
    break;
  }

  nlsData->initializeStaticNLSData(data, threadData, nlsData, TRUE);

  // TODO: Set callback to initialize Jacobian
  //       Write said function...
  // TODO: Free memory
  gbfData->jacobian = (ANALYTIC_JACOBIAN*) malloc(sizeof(ANALYTIC_JACOBIAN));
  initAnalyticJacobian(gbfData->jacobian, gbfData->nlSystemSize, gbfData->nlSystemSize, gbfData->nlSystemSize, NULL, nlsData->sparsePattern);
  nlsData->initialAnalyticalJacobian = NULL;
  nlsData->jacobianIndex = -1;

  /* Set NLS user data */
  NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, nlsData, gbfData->jacobian);
  nlsUserData->solverData = (void*) gbfData;

  /* Initialize NLS method */
  switch (gbfData->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    nlsData->nlsMethod = NLS_NEWTON;
    nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    nlsData->jacobianIndex = -1;
    solverData->ordinaryData =(void*) allocateNewtonData(nlsData->size, nlsUserData);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  case RK_NLS_KINSOL:
    nlsData->nlsMethod = NLS_KINSOL;
    if (nlsData->isPatternAvailable) {
      nlsData->nlsLinearSolver = NLS_LS_KLU;
    } else {
      nlsData->nlsLinearSolver = NLS_LS_DEFAULT;
    }
    solverData->ordinaryData = (void*) nlsKinsolAllocate(nlsData->size, nlsUserData, FALSE);
    solverData->initHomotopyData = NULL;
    nlsData->solverData = solverData;
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
    return NULL;
    break;
  }

  return nlsData;
}

/**
 * @brief Free memory of gbode non-linear system data.
 *
 * Free memory allocated with initRK_NLS_DATA or initRK_NLS_DATA_MR
 *
 * @param nlsData           Pointer to non-linear system data.
 * @param nlsSolverMethod   Used non-linear system solver method.
 */
void freeRK_NLS_DATA( NONLINEAR_SYSTEM_DATA* nlsData, enum GB_NLS_METHOD nlsSolverMethod) {
  if (nlsData == NULL) return;

  struct dataSolver *dataSolver = nlsData->solverData;
  switch (nlsSolverMethod)
  {
  case RK_NLS_NEWTON:
    freeNewtonData(dataSolver->ordinaryData);
    break;
  case RK_NLS_KINSOL:
    nlsKinsolFree(dataSolver->ordinaryData);
    break;
  default:
    warningStreamPrint(LOG_SOLVER, 0, "Not handled GB_NLS_METHOD in gbode_freeData. Are we leaking memroy?");
    break;
  }
  free(dataSolver);

  // TODO AHeu: This malloc and free is a nightmare!
  //freeSparsePattern(nlsData->sparsePattern);
  //free(nlsData->sparsePattern); nlsData->sparsePattern = NULL;
  freeNlsDataGB(nlsData);
  return;
}


/**
 * @brief Residual function for non-linear system of generic multistep methods.
 *
 * TODO: Describe what the residual means.
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
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage_   = gbData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gbData->res_const[i] - xloc[i] * gbData->tableau->c[nStages-1] +
                                    fODE[i] * gbData->tableau->b[nStages-1] * gbData->stepSize;
  }

  return;
}

/**
 * @brief Residual function for non-linear system of generic multistep methods.
 *
 * TODO: Describe what the residual means.
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
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int nFastStates = gbfData->nFastStates;
  int stage_   = gbfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii < nFastStates;ii++) {
    i = gbfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE), fODE);

  // Evaluate residuals
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
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int stage_  = gbfData->act_stage;

  // Evaluate right hand side of ODE
  for (ii=0; ii<gbfData->nFastStates;ii++) {
    i = gbfData->fastStates[ii];
    sData->realVars[i] = xloc[ii];
  }
  gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE), fODE);

  // Evaluate residual
  for (ii=0; ii<gbfData->nFastStates; ii++) {
    i = gbfData->fastStates[ii];
    res[ii] = gbfData->res_const[i] - xloc[ii] + gbfData->stepSize * gbfData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  return;
}

/**
 * @brief Residual function for non-linear system for diagonal implicit Runge-Kutta methods.
 *
 * TODO: Describe what the residual means.
 *
 * @param userData  Userdata provided to non-linear system solver.
 * @param xloc    Input vector for non-linear system.
 * @param res     Residuum vector for given input xloc.
 * @param iflag   Unused.
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
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage_   = gbData->act_stage;

  // Evaluate right hand side of ODE
  memcpy(sData->realVars, xloc, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE), fODE);

  // Evaluate residual
  for (i=0; i<nStates; i++) {
    res[i] = gbData->res_const[i] - xloc[i] + gbData->stepSize * gbData->tableau->A[stage_ * nStages + stage_] * fODE[i];
  }

  if (ACTIVE_STREAM(LOG_GBODE_NLS)) {
    infoStreamPrint(LOG_GBODE_NLS, 1, "NLS - x and residual:");
    printVector_gb(LOG_GBODE_NLS, "x", (double *)xloc, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    printVector_gb(LOG_GBODE_NLS, "r", res, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    messageClose(LOG_GBODE_NLS);
  }

  return;
}

/**
 * @brief Evaluate residual for non-linear system of implicit Runge-Kutta method.
 *
 * TODO: Describe how the residual is computed.
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
  int nStages = gbData->tableau->nStages;
  int nStates = data->modelData->nStates;
  int stage, stage_;

  // Update the derivatives for current estimate of the states
  for (stage_=0; stage_<nStages; stage_++)
  {
    /* Evaluate ODE for each stage_ */
    sData->timeValue = gbData->time + gbData->tableau->c[stage_] * gbData->stepSize;
    memcpy(sData->realVars, xloc + stage_ * nStates, nStates*sizeof(double));
    gbode_fODE(data, threadData, &(gbData->stats.nCallsODE), fODE);
    memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  // Calculate residuum for the full implicit RK method based on stages and A matrix
  for (stage=0; stage<nStages; stage++)
  {
    for (i=0; i<nStates; i++)
    {
      res[stage * nStates + i] = gbData->yOld[i] - xloc[stage * nStates + i];
      for (stage_=0; stage_<nStages; stage_++)
      {
        res[stage * nStates + i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * (gbData->k + stage_*nStates)[i];
      }
    }
  }

  if (ACTIVE_STREAM(LOG_GBODE_NLS)) {
    infoStreamPrint(LOG_GBODE_NLS, 1, "NLS - residual:");
    for (stage=0; stage<nStages; stage++) {
      printVector_gb(LOG_GBODE_NLS, "r", res + stage*nStates, nStates, gbData->time + gbData->tableau->c[stage] * gbData->stepSize);
    }
    messageClose(LOG_GBODE_NLS);
  }

  return;
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
int jacobian_SR_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;

  int i;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int stage = gbData->act_stage;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  memcpy(jacobian_ODE->seedVars, jacobian->seedVars, sizeof(modelica_real)*jacobian->sizeCols);
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (i = 0; i < jacobian->sizeCols; i++) {
    if (gbData->type == MS_TYPE_IMPLICIT) {
      jacobian->resultVars[i] = gbData->tableau->b[nStages-1] * gbData->stepSize * jacobian_ODE->resultVars[i];
    } else {
      jacobian->resultVars[i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage] * jacobian_ODE->resultVars[i];
    }
    /* -1 on diagonal elements */
    if (jacobian->seedVars[i] == 1) {
      jacobian->resultVars[i] -= 1;
    }
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
int jacobian_MR_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  /* define callback to column function of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  int i, ii;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  int nFastStates = gbData->nFastStates;
  int stage_ = gbfData->act_stage;

  // printSparseStructure(gbfData->jacobian->sparsePattern,
  //                     nFastStates,
  //                     nFastStates,
  //                     LOG_STDOUT,
  //                     "sparsePattern");

  for (i=0; i<jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (ii=0; ii<nFastStates; ii++) {
    i = gbData->fastStates[ii];
    if (jacobian->seedVars[ii])
      jacobian_ODE->seedVars[i] = 1;
  }

  // call jacobian_ODE with the mapped seedVars
  data->callback->functionJacA_column(data, threadData, jacobian_ODE, NULL);

  /* Update resultVars array */
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStates[ii];
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

  return 0;
}

/**
 * @brief Evaluate column of IRK Jacobian.
 *
* @param data               Pointer to runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param gbData            Runge-Kutta method.
 * @param jacobian          Jacobian. jacobian->resultVars will be set on exit.
 * @param parentJacobian    Unused
 * @return int              Return 0 on success.
 */
int jacobian_IRK_column(DATA* data, threadData_t *threadData, ANALYTIC_JACOBIAN *jacobian, ANALYTIC_JACOBIAN *parentJacobian) {

  DATA_GBODE* gbData = (DATA_GBODE*) data->simulationInfo->backupSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  const double* xloc = gbData->nlsData->nlsx;

  int i;
  int stage, stage_;
  int nStages = gbData->tableau->nStages;
  int nStates = data->modelData->nStates;

  /* Evaluate column of Jacobian ODE */
  ANALYTIC_JACOBIAN* jacobian_ODE = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  // and find out which stage is active; different stages have different colors
  // reset jacobian_ODE->seedVars
  for (i=0; i<jacobian_ODE->sizeCols; i++) {
    jacobian_ODE->seedVars[i] = 0;
  }

  // Map the jacobian->seedVars to the jacobian_ODE->seedVars
  for (i=0, stage_=0; i<jacobian->sizeCols; i++) {
    if (jacobian->seedVars[i]) {
      stage_ = i;
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

  /* Update resultVars array for corresponding jacobian->seedVars*/
  for (stage=0; stage<nStages; stage++) {
    for (i=0; i<nStates; i++) {
      jacobian->resultVars[stage * nStates + i] = gbData->stepSize * gbData->tableau->A[stage * nStages + stage_]  * jacobian_ODE->resultVars[i];
      /* -1 on diagonal elements */
      if (jacobian->seedVars[stage * nStates + i] == 1) {
        jacobian->resultVars[stage * nStates + i] -= 1;
      }
    }
  }

  return 0;
}
