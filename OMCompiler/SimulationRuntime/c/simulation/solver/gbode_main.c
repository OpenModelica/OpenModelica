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
 * 3) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 4) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 5) Check accuracy and decide on the Left-limit of the implicit embedded RK method, if possible...
 *
*/

/*! \file gm.c
 *  Implementation of a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau. Utilizes the sparsity pattern of the ODE
 *  together with the KINSOL (KLU) solver
 *
 *  \author bbachmann
 */

#include <time.h>

#include "gbode_conf.h"
#include "gbode_ctrl.h"
#include "gbode_events.h"
#include "gbode_main.h"
#include "gbode_nls.h"
#include "gbode_sparse.h"
#include "gbode_step.h"
#include "gbode_util.h"

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
#include "util/jacobian_util.h"
#include "util/omc_error.h"
#include "util/omc_file.h"
#include "util/simulation_options.h"
#include "util/varinfo.h"
#include "epsilon.h"

/**
 * @brief Calculate function values of function ODE f(t,y).
 *
 * Assuming the correct values for time value and states are set.
 *
 * @param data               Runtime data struct.
 * @param threadData         Thread data for error handling.
 * @param evalFunctionsODE   Counter for function calls.
 * @param fODE               Array of state derivatives.
 * @return int               Returns 0 on success.
 */
int gbode_fODE(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE)
{
  unsigned int* counter = (unsigned int*) evalFunctionODE;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  fODE = sData->realVars + data->modelData->nStates;

  (*counter)++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/**
 * @brief Function allocates memory needed for chosen gbodef method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int gbodef_allocateData(DATA* data, threadData_t *threadData, DATA_GBODE* gbData)
{
  DATA_GBODEF* gbfData = (DATA_GBODEF*) malloc(sizeof(DATA_GBODEF));
  gbData->gbfData = gbfData;

  gbfData->nStates = gbData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gbfData->GM_method = getGB_method(FLAG_MR);
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
    gbfData->nlsSolverMethod = getGB_NLS_METHOD(FLAG_MR_NLS);
  // BB ToDo: get kinsol up and running!!
    gbfData->nlsData = initRK_NLS_DATA_MR(data, threadData, gbfData);
    if (!gbfData->nlsData) {
      return -1;
    }
    gbfData->sparesPattern_DIRK = initializeSparsePattern_SR(data, gbfData->nlsData);
  }  else
  {
    gbfData->symJacAvailable = FALSE;
    gbfData->nlsSolverMethod = GB_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
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

  if (ACTIVE_STREAM(LOG_M_FASTSTATES)) {
    gbfData->fastStatesDebugFile = omc_fopen("fastStates.txt","w");
  } else {
    gbfData->fastStatesDebugFile = NULL;
  }

  return 0;
}

/**
 * @brief Function allocates memory needed for generic RK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int gbode_allocateData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo) {
  DATA_GBODE* gbData = (DATA_GBODE*) malloc(sizeof(DATA_GBODE));

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void*) gbData;

  solverInfo->solverData = (void*) gbData;

  gbData->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gbData->GM_method = getGB_method(FLAG_SR);
  gbData->tableau = initButcherTableau(gbData->GM_method, FLAG_SR_ERR);
  if (gbData->tableau == NULL){
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGm: Failed to initialize gbode tableau for method %s", GB_SINGLERATE_METHOD_NAME[gbData->GM_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(gbData->tableau, gbData->nStates, &gbData->nlSystemSize, &gbData->type);

  switch (gbData->type)
  {
  case GM_TYPE_EXPLICIT:
    gbData->isExplicit = TRUE;
    gbData->step_fun = &(expl_diag_impl_RK);
    break;
  case GM_TYPE_DIRK:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(expl_diag_impl_RK);
    break;
  case GM_TYPE_IMPLICIT:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(full_implicit_RK);
    break;
  case MS_TYPE_IMPLICIT:
    gbData->isExplicit = FALSE;
    gbData->step_fun = &(full_implicit_MS);
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "gbode_allocateData: Unknown type %i", gbData->type);
    return -1;
  }
  // adapt decision for testing of the fully implicit implementation
  if (gbData->GM_method == RK_ESDIRK2_test || gbData->GM_method == RK_ESDIRK3_test) {
    gbData->nlSystemSize = gbData->tableau->nStages*gbData->nStates;
    gbData->step_fun = &(full_implicit_RK);
    gbData->type = GM_TYPE_IMPLICIT;
  }
  if (gbData->GM_method == MS_ADAMS_MOULTON) {
    gbData->nlSystemSize = gbData->nStates;
    gbData->step_fun = &(full_implicit_MS);
    gbData->type = MS_TYPE_IMPLICIT;
    gbData->isExplicit = FALSE;
  }

  // test of multistep method

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_SR_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    gbData->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using PIController");
  } else
  {
    gbData->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "Stepsize control using IController");
  }

  /* Allocate internal memory */
  gbData->isFirstStep = TRUE;
  gbData->y = malloc(sizeof(double)*gbData->nStates);
  gbData->yOld = malloc(sizeof(double)*gbData->nStates);
  gbData->yLeft = malloc(sizeof(double)*gbData->nStates);
  gbData->kLeft = malloc(sizeof(double)*gbData->nStates);
  gbData->yRight = malloc(sizeof(double)*gbData->nStates);
  gbData->kRight = malloc(sizeof(double)*gbData->nStates);
  gbData->nlsxLeft = malloc(sizeof(double)*gbData->nStates);
  gbData->nlskLeft = malloc(sizeof(double)*gbData->nStates);
  gbData->nlsxRight = malloc(sizeof(double)*gbData->nStates);
  gbData->nlskRight = malloc(sizeof(double)*gbData->nStates);
  gbData->yt = malloc(sizeof(double)*gbData->nStates);
  gbData->f = malloc(sizeof(double)*gbData->nStates);
  gbData->k = malloc(sizeof(double)*gbData->nStates*(gbData->tableau->nStages + 1));
  gbData->x = malloc(sizeof(double)*gbData->nStates*(gbData->tableau->nStages + 1));
  gbData->res_const = malloc(sizeof(double)*gbData->nStates);
  gbData->errest = malloc(sizeof(double)*gbData->nStates);
  gbData->errtol = malloc(sizeof(double)*gbData->nStates);
  gbData->err = malloc(sizeof(double)*gbData->nStates);
  gbData->ringBufferSize = 5;
  gbData->errValues = malloc(sizeof(double)* gbData->ringBufferSize);
  gbData->stepSizeValues = malloc(sizeof(double)* gbData->ringBufferSize);
  if (!gbData->isExplicit) {
    gbData->Jf = malloc(sizeof(double)*gbData->nStates*gbData->nStates);
    for (int i=0; i<gbData->nStates*gbData->nStates; i++)
      gbData->Jf[i] = 0;
  } else {
    gbData->Jf = NULL;
  }

  printButcherTableau(gbData->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  gbData->stepsDone = 0;
  gbData->evalFunctionODE = 0;
  gbData->evalJacobians = 0;
  gbData->errorTestFailures = 0;
  gbData->convergenceFailures = 0;

  /* initialize analytic Jacobian, if available and needed */
  if (!gbData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    // TODO: Do we need to initialize the Jacobian or is it already initialized?
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      gbData->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to numeric Jacobians.");
    } else {
      gbData->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

  /* Allocate memory for the nonlinear solver */
    gbData->nlsSolverMethod = getGB_NLS_METHOD(FLAG_SR_NLS);
    gbData->nlsData = initRK_NLS_DATA(data, threadData, gbData);
    if (!gbData->nlsData) {
      return -1;
    } else {
      infoStreamPrint(LOG_SOLVER, 1, "Nominal values of  the states:");
      for (int i =0; i<gbData->nStates; i++)
      {
        infoStreamPrint(LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbData->nlsData->nominal[i]);
      }
      messageClose(LOG_SOLVER);
    }
  }
  else
  {
    gbData->symJacAvailable = FALSE;
    gbData->nlsSolverMethod = GB_NLS_UNKNOWN;  // TODO AHeu: Add a no-solver option?
    gbData->nlsData = NULL;
    gbData->jacobian = NULL;
  }

  const char* flag_value = omc_flagValue[FLAG_MR_PAR];
  if (flag_value != NULL)
    gbData->percentage = atof(omc_flagValue[FLAG_MR_PAR]);
  else
    gbData->percentage = 0;
  if (gbData->percentage > 0) {
    gbData->multi_rate = 1;
  } else {
    gbData->multi_rate = 0;
  }

  gbData->fastStates = malloc(sizeof(int)*gbData->nStates);
  gbData->slowStates = malloc(sizeof(int)*gbData->nStates);
  gbData->sortedStates = malloc(sizeof(int)*gbData->nStates);

  gbData->nFastStates = 0;
  gbData->nSlowStates = gbData->nStates;
  for (int i=0; i<gbData->nStates; i++)
  {
    gbData->fastStates[i] = i;
    gbData->slowStates[i] = i;
    gbData->sortedStates[i] = i;
  }

  if (gbData->multi_rate) {
    gbodef_allocateData(data, threadData, gbData);
  } else {
    gbData->gbfData = NULL;
  }

  //gbData->interpolation = 2; // GM_HERMITE
  gbData->interpolation = 1; // GM_LINEAR
  gbData->err_threshold = 0.1;

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void gbodef_freeData(DATA_GBODEF* gbfData) {
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
      warningStreamPrint(LOG_SOLVER, 0, "Not handled GB_NLS_METHOD in gbodef_freeData. Are we leaking memroy?");
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

  if (gbfData->fastStatesDebugFile != NULL)
    fclose(gbfData->fastStatesDebugFile);

  free(gbfData);
  gbfData = NULL;

  return;
}

/**
 * @brief Free generic RK data.
 *
 * @param gbData    Pointer to generik Runge-Kutta data struct.
 */
void gbode_freeData(DATA_GBODE* gbData) {
  /* Free non-linear system data */
  if(gbData->nlsData != NULL) {
    struct dataSolver* dataSolver = gbData->nlsData->solverData;
    switch (gbData->nlsSolverMethod)
    {
    case RK_NLS_NEWTON:
      freeNewtonData(dataSolver->ordinaryData);
      break;
    case RK_NLS_KINSOL:
      //kinsolData = (NLS_KINSOL_DATA*) gbData->nlsData->solverData;
      nlsKinsolFree(dataSolver->ordinaryData);
      break;
    default:
      warningStreamPrint(LOG_SOLVER, 0, "Not handled GB_NLS_METHOD in gbode_freeData. Are we leaking memroy?");
      break;
    }
    free(dataSolver);
    free(gbData->nlsData);
  }
  /* Free Jacobian */
  freeAnalyticJacobian(gbData->jacobian);

  /* Free Butcher tableau */
  freeButcherTableau(gbData->tableau);

  if (gbData->multi_rate == 1) {
    gbodef_freeData(gbData->gbfData);
  }
  /* Free multi-rate data */
  free(gbData->err);
  free(gbData->errValues);
  free(gbData->stepSizeValues);
  free(gbData->fastStates);
  free(gbData->slowStates);

  /* Free remaining arrays */
  free(gbData->y);
  free(gbData->yOld);
  free(gbData->yLeft);
  free(gbData->kLeft);
  free(gbData->yRight);
  free(gbData->kRight);
  free(gbData->nlsxLeft);
  free(gbData->nlskLeft);
  free(gbData->nlsxRight);
  free(gbData->nlskRight);
  free(gbData->yt);
  free(gbData->f);
  free(gbData->Jf);
  free(gbData->k);
  free(gbData->x);
  free(gbData->res_const);
  free(gbData->errest);
  free(gbData->errtol);

  free(gbData);
  gbData = NULL;

  return;
}


/*! \fn gbodef_main
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'gm'
 */
int gbodef_main(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
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

  modelica_boolean fastStateChange = FALSE;

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

  for (int k=0; k<nFastStates; k++) {
    if (gbfData->fastStates_old[k] - gbfData->fastStates[k]) {
      if(ACTIVE_STREAM(LOG_SOLVER) && !fastStateChange)
      {
        printIntVector_gb("old fast States:", gbfData->fastStates_old, gbfData->nFastStates_old, gbfData->time);
        printIntVector_gb("new fast States:", gbfData->fastStates, gbfData->nFastStates, gbfData->time);
      }
      fastStateChange = TRUE;
      gbfData->fastStates_old[k] = gbfData->fastStates[k];
    }
  }
  if (gbfData->nFastStates_old != gbfData->nFastStates) {
    gbfData->nFastStates_old = gbfData->nFastStates;
    fastStateChange = TRUE;
  }

  if (!gbfData->isExplicit) {
    struct dataSolver *solverData = gbfData->nlsData->solverData;
    // set number of non-linear variables and corresponding nominal values (changes dynamically during simulation)
    gbfData->nlsData->size = gbfData->nFastStates;

    infoStreamPrint(LOG_MULTIRATE, 1, "Fast states and corresponding nominal values:");
    for (ii=0; ii<nFastStates; ii++) {
      i = gbfData->fastStates[ii];
    // Get the nominal values of the fast states
      gbfData->nlsData->nominal[ii] = fabs(data->modelData->realVarsData[i].attribute.nominal);
      gbfData->nlsData->nominal[ii] = fmax(fabs(gbfData->nlsData->nominal[ii]), 1e-32);
      infoStreamPrint(LOG_MULTIRATE, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbfData->nlsData->nominal[ii]);
    }
    messageClose(LOG_MULTIRATE);

    if (gbfData->symJacAvailable && fastStateChange) {

      // The following assumes that the fastStates are sorted (i.e. [0, 2, 6, 7, ...])
      SPARSE_PATTERN* sparsePattern_DIRK = gbfData->sparesPattern_DIRK;
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

      switch (gbfData->nlsSolverMethod)
      {
        case  RK_NLS_NEWTON:
          ((DATA_NEWTON*) solverData->ordinaryData)->n = gbfData->nFastStates;
          break;
        case  RK_NLS_KINSOL:
          nlsKinsolFree(solverData->ordinaryData);
          solverData->ordinaryData = (void*) nlsKinsolAllocate(gbfData->nlsData->size, gbfData->nlsData->nlsLinearSolver);
          resetKinsolMemory(solverData->ordinaryData, gbfData->nlsData);
          break;
        default:
          errorStreamPrint(LOG_STDOUT, 0, "NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
          return -1;
          break;
      }

      printSparseStructure(sparsePattern_MR,
                           nFastStates,
                           nFastStates,
                           LOG_MULTIRATE,
                          "sparsePattern_MR");

    }
  }

  if (ACTIVE_STREAM(LOG_M_FASTSTATES)) {
    char fastStates_row[2048];
    sprintf(fastStates_row, "%10g ", gbfData->time);
    for (i=0, ii=0; i<nStates; ) {
      if (i == gbfData->fastStates[ii]) {
        sprintf(fastStates_row, "%s 1", fastStates_row);
        i++; ii++;
      } else {
        sprintf(fastStates_row, "%s 0", fastStates_row);
        i++;
      }
    }
    fprintf(gbfData->fastStatesDebugFile,"%s\n", fastStates_row);
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
        errorStreamPrint(LOG_STDOUT, 0, "gbodef_main: Failed to calculate step at time = %5g.", gbfData->time);
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
 //   gbData->lastStepSize = gbfData->time - gbData->timeLeft;
 //   gbData->timeRight = gbfData->time;
 //   if (gbData->time > gbData->timeLeft)
 //     gbData->time = gbfData->time;
 //   else
 //     gbData->time = gbData->timeLeft;

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

/**
 * @brief Generic Runge-Kutta step.
 *
 * Do one Runge-Kutta integration step.
 * has step-size control and event handling.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Storing Runge-Kutta solver data.
 * @return int          Return 0 on success, -1 on failure.
 */
int gbode_main(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  double err, err_threshold;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  int i, ii, l;
  int nStates = (int) data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  int rk_step_info;

  double targetTime;
  double eventTime;
  double stopTime = data->simulationInfo->stopTime;

  solverInfo->solverRootFinding = 1;

  infoStreamPrint(LOG_SOLVER, 0, "gbode solver started:");

  if(ACTIVE_STREAM(LOG_MULTIRATE_V))
  {
    printVector_gb("yIni:", sData->realVars, gbData->nStates, sDataOld->timeValue);
  }
  // TODO AHeu: Copy-paste code used in dassl,c, ida.c, irksco.c and here. Make it a function!
  // Also instead of solverInfo->integratorSteps we should set and use solverInfo->solverNoEquidistantGrid
  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => emit result at integrator step points; 0 => equidistant grid
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
    targetTime = solverInfo->currentTime + solverInfo->currentStepSize;
    // targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  // (Re-)initialize after events or at first call of gbode_main
  if (solverInfo->didEventStep == 1 || gbData->isFirstStep)
  {
    gm_first_step(data, threadData, solverInfo);

    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  if (ACTIVE_STREAM(LOG_M_BB)) {
    printf("\n");
    for (int stage_=0; stage_< nStages; stage_++) {
      printVector_gb("gb->x:    ", gbData->x + stage_ * nStates, nStates, gbData->time + gbData->tableau->c[stage_]*gbData->lastStepSize);
    }
    printVector_gb("gb->x:    ", gbData->x + nStages * nStates, nStates, gbData->time + gbData->lastStepSize);
    for (int stage_=0; stage_< nStages; stage_++) {
      printVector_gb("gb->k:    ", gbData->k + stage_ * nStates, nStates, gbData->time + gbData->tableau->c[stage_]*gbData->lastStepSize);
    }
    printVector_gb("gb->k:    ", gbData->k + nStages * nStates, nStates, gbData->time + gbData->lastStepSize);
    printf("\n");
  }


  // Check if multirate step is necessary, otherwise the correct values are already stored in sData
  if (gbData->multi_rate)
    if (gbData->nFastStates > 0 && gbData->gbfData->time < gbData->time)
      if (gbodef_main(data, threadData, solverInfo, targetTime))
              return 0;


  /* Main integration loop */
  while (gbData->time < targetTime)
  {
    do
    {
      // printVector_gb("yOld: ", gbData->yOld, nStates, gbData->time);
      // printVector_gb("y:    ", gbData->y, nStates, gbData->time);
      /* store yOld in yLeft for interpolation purposes, if necessary
      * BB: Check condition
      */
      gbData->timeLeft = gbData->time;
      memcpy(gbData->yLeft, gbData->yOld, data->modelData->nStates*sizeof(double));
      memcpy(gbData->kLeft, gbData->k, data->modelData->nStates*sizeof(double));

      if(ACTIVE_STREAM(LOG_MULTIRATE))
      {
        printVector_gb("gb->yOld: ", gbData->yOld, gbData->nStates, gbData->time);
      }
      if(ACTIVE_STREAM(LOG_M_BB))
      {
        printVector_gb("gb->yL:    ", gbData->yLeft, gbData->nStates, gbData->timeLeft);
        printVector_gb("gb->kL:    ", gbData->kLeft, gbData->nStates, gbData->timeLeft);
      }

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
      // calculate one step of the integrator
      if (gbData->percentage!=1 || !gbData->stepsDone) {
        rk_step_info = gbData->step_fun(data, threadData, solverInfo);
      }

      // error handling: try half of the step size!
      if (rk_step_info != 0) {
        errorStreamPrint(LOG_STDOUT, 0, "gbode_main: Failed to calculate step at time = %5g.", gbData->time);
        errorStreamPrint(LOG_STDOUT, 0, "Try half of the step size!");
        gbData->stepSize = gbData->stepSize/2.;
        continue;
        //return -1;
      }

      // calculate corresponding values for error estimator and step size control
      // BB ToDo: Investigate error estimator with respect for global accuracy
      // userdata->errtol[i] = Rtol*(fabs(userdata->y[i]) + fabs(userdata->stepSize*fODE[i])) + Atol*1e-3;
      for (i=0; i<nStates; i++)
      {
        gbData->errtol[i] = Rtol*fmax(fabs(gbData->y[i]),fabs(gbData->yt[i])) + Atol;
        gbData->errest[i] = fabs(gbData->y[i] - gbData->yt[i]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i<nStates; i++)
      {
         gbData->err[i] = gbData->errest[i]/gbData->errtol[i];
         err = fmax(err, gbData->err[i]);
      }
      err = gbData->tableau->fac * err;

      // printVector_gb("Error before sorting:", gbData->err, gbData->nStates, gbData->time);
      // printIntVector_gb("Indices before sorting:", gbData->sortedStates, gbData->nStates, gbData->time);
      // printIntVector_gb("Indices after sorting:", gbData->sortedStates, gbData->nStates, gbData->time);
      // printVector_gbf("Error after sorting:", gbData->err, gbData->nStates, gbData->time,  gbData->nStates, gbData->sortedStates);

      if (gbData->multi_rate)
      {
        // BB ToDo: Gives problems, if the orderig of the fast states change during simulation
        int *sortedStates;
        if(ACTIVE_STREAM(LOG_MULTIRATE_V))
        {
          sortedStates = (int*) malloc(sizeof(int)*nStates);
          memcpy(sortedStates, gbData->sortedStates, sizeof(int)*nStates);
        }
        err_threshold = getErrorThreshold(gbData);
        if(ACTIVE_STREAM(LOG_MULTIRATE_V))
        {
          for (int k=0; k<nStates; k++)
            if (sortedStates[k] - gbData->sortedStates[k]) {
              printIntVector_gb("sortedStates before:", sortedStates, nStates, gbData->time);
              printIntVector_gb("sortedStates after:", gbData->sortedStates, nStates, gbData->time);
              break;
            }
            free(sortedStates);
        }
        //Find fast and slow states based on
        gbData->nFastStates = 0;
        gbData->nSlowStates = 0;
        gbData->err_slow = 0;
        gbData->err_fast = 0;
        for (i=0; i<gbData->nStates; i++)
        {
          if (gbData->err[i]>=err_threshold || gbData->percentage==1)
          {
            gbData->fastStates[gbData->nFastStates] = i;
            gbData->nFastStates++;
            gbData->err_fast = fmax(gbData->err_fast, gbData->err[i]);
          }
          else
          {
            gbData->slowStates[gbData->nSlowStates] = i;
            gbData->nSlowStates++;
            gbData->err_slow = fmax(gbData->err_slow, gbData->err[i]);
          }
        }
        err = gbData->err_slow;
      }

      gbData->errValues[0]      =  err;
      gbData->stepSizeValues[0] = gbData->stepSize;

      // see Hairer book II, Seite 124 ....
      // step_values[0] =
      // step_values[1] =

      // Store performed stepSize for adjusting the time and interpolation purposes
      // gbData->stepSize_old = gbData->lastStepSize;
      gbData->lastStepSize = gbData->stepSize;

      // store right hand values for interpolation in the inner integration
      gbData->timeRight    = gbData->time + gbData->stepSize;
      memcpy(gbData->yRight, gbData->y, nStates * sizeof(double));
      memcpy(gbData->kRight, gbData->k + nStages * nStates, nStates * sizeof(double));

      // Call the step size control
      gbData->stepSize *= gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);

      if (ACTIVE_STREAM(LOG_M_FASTSTATES)) {
        char fastStates_row[2048];
        sprintf(fastStates_row, "%10g ", gbData->time);
        for (i=0; i<nStates; i++) {
            sprintf(fastStates_row, "%s 1", fastStates_row);
          }
        fprintf(gbData->gbfData->fastStatesDebugFile,"%s\n", fastStates_row);
      }

      if (gbData->multi_rate)
      {
        if (gbData->nFastStates>0)
        {
          if (gbodef_main(data, threadData, solverInfo, targetTime))
            return 0;
          err = fmax(gbData->err_slow, gbData->err_fast);
        }
      }
      if (err>1)
      {
        gbData->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, err, gbData->stepSize);
      }
      else
      {
        // BB ToDo: check if this is appropriate
        gbData->stepSize = fmin(gbData->stepSize, stopTime - (gbData->time + gbData->lastStepSize));
      }

    } while  (err>1);
    gbData->stepsDone += 1;

    // Rotate ring buffer
    for (i=0; i<(gbData->ringBufferSize-1); i++) {
      gbData->errValues[i+1] = gbData->errValues[i];
      gbData->stepSizeValues[i+1] = gbData->stepSizeValues[i];
    }

    if (gbData->type == MS_TYPE_IMPLICIT) {
      for (int stage_=0; stage_< (gbData->tableau->nStages-1); stage_++) {
        memcpy(gbData->k + stage_ * nStates, gbData->k + (stage_+1) * nStates, nStates*sizeof(double));
        memcpy(gbData->x + stage_ * nStates, gbData->x + (stage_+1) * nStates, nStates*sizeof(double));
      }
    }

    if (ACTIVE_STREAM(LOG_M_BB)) {
      printf("\n");
      for (int stage_=0; stage_< nStages; stage_++) {
        printVector_gb("gb->x:    ", gbData->x + stage_ * nStates, nStates, gbData->time + gbData->tableau->c[stage_]*gbData->lastStepSize);
      }
      printVector_gb("gb->x:    ", gbData->x + nStages * nStates, nStates, gbData->time + gbData->lastStepSize);
      for (int stage_=0; stage_< nStages; stage_++) {
        printVector_gb("gb->k:    ", gbData->k + stage_ * nStates, nStates, gbData->time + gbData->tableau->c[stage_]*gbData->lastStepSize);
      }
      printVector_gb("gb->k:    ", gbData->k + nStages * nStates, nStates, gbData->time + gbData->lastStepSize);
      printf("\n");
    }


    if (!gbData->multi_rate || !gbData->percentage)
    {
      eventTime = checkForEvents(data, threadData, solverInfo, gbData->time, gbData->yOld, gbData->time + gbData->lastStepSize, gbData->y);
      if (eventTime > 0)
      {
        solverInfo->currentTime = eventTime;
        sData->timeValue = eventTime;

        // sData->realVars are the "numerical" values on the right hand side of the event
        gbData->time = eventTime;
        memcpy(gbData->yOld, sData->realVars, gbData->nStates * sizeof(double));
        // printVector_gb("y:    ", gbData->y, nStates, gbData->time);
        if(ACTIVE_STREAM(LOG_MULTIRATE))
        {
          printIntVector_gb("fast states:", gbData->fastStates, gbData->nFastStates, solverInfo->currentTime);
          printVector_gb("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
          messageClose(LOG_MULTIRATE);
        }
        if (!gbData->multi_rate || (gbData->multi_rate && !gbData->percentage))
        {
            /* write statistics to the solverInfo data structure */
          solverInfo->solverStatsTmp[0] = gbData->stepsDone;
          solverInfo->solverStatsTmp[1] = gbData->evalFunctionODE;
          solverInfo->solverStatsTmp[2] = gbData->evalJacobians;
          solverInfo->solverStatsTmp[3] = gbData->errorTestFailures;
          solverInfo->solverStatsTmp[4] = gbData->convergenceFailures;
        }

        return 0;
      }
    }
    /* update time with performed stepSize */
    gbData->time += gbData->lastStepSize;

    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printVector_gb("gb->y:    ", gbData->y, gbData->nStates, gbData->time);
    }
    if(ACTIVE_STREAM(LOG_M_BB))
    {
      printVector_gb("gb->yR:   ", gbData->yRight, gbData->nStates, gbData->timeRight);
      printVector_gb("gb->kR:   ", gbData->kRight, gbData->nStates, gbData->timeRight);
    }



    // printVector_gb("yOld", gbData->yOld, gbData->nStates, gbData->time - gbData->lastStepSize);
    // printVector_gb("y   ", gbData->y, gbData->nStates, gbData->time);
    /* step is accepted and yOld needs to be updated */
    memcpy(gbData->yOld, gbData->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gbData->time- gbData->lastStepSize, gbData->time, gbData->err_slow, gbData->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps  && !gbData->multi_rate)
    {
      sData->timeValue = gbData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbData->y, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
    if ((stopTime - gbData->time) < DASSL_STEP_EPS){
      gbData->time = stopTime;
      break;
    }
  } // end of while-loop (gbData->time < targetTime)

  if(ACTIVE_STREAM(LOG_MULTIRATE_V))
  {
    printf("\n");
  }

  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = sDataOld->timeValue + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;
    if (gbData->multi_rate) {
      // interpolating fast states if multirate method is used
      linear_interpolation_gbf(gbData->gbfData->time-gbData->gbfData->lastStepSize, gbData->gbfData->yt,
                              gbData->gbfData->time, gbData->gbfData->y,
                              sData->timeValue, sData->realVars,
                              gbData->nFastStates, gbData->fastStates);

    }

    // interpolating slow states if multirate method is used, otherwise all states are slow states
    linear_interpolation_gbf(gbData->timeLeft, gbData->yLeft,
                          gbData->timeRight, gbData->y,
                          sData->timeValue, sData->realVars,
                          gbData->nSlowStates, gbData->slowStates);
    if(ACTIVE_STREAM(LOG_MULTIRATE))
    {
      printIntVector_gb("fast states:", gbData->fastStates, gbData->nFastStates, solverInfo->currentTime);
      printVector_gb("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
      messageClose(LOG_MULTIRATE);
    }
  }else{
    // Integrator emits result on the simulation grid
    sData->timeValue = gbData->time;
    solverInfo->currentTime = gbData->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  /* Solver statistics */
  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "gm call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", gbData->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", gbData->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", gbData->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", gbData->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", gbData->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", gbData->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", gbData->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  if (!gbData->multi_rate || (gbData->multi_rate && !gbData->percentage))
  {
      /* write statistics to the solverInfo data structure */
    solverInfo->solverStatsTmp[0] = gbData->stepsDone;
    solverInfo->solverStatsTmp[1] = gbData->evalFunctionODE;
    solverInfo->solverStatsTmp[2] = gbData->evalJacobians;
    solverInfo->solverStatsTmp[3] = gbData->errorTestFailures;
    solverInfo->solverStatsTmp[4] = gbData->convergenceFailures;
  }

  infoStreamPrint(LOG_SOLVER, 0, "finished gm step.");
  messageClose(LOG_SOLVER);
  return 0;
}

