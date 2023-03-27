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

/*! \file gbode_main.c
 *  Implementation of a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau. Utilizes the sparsity pattern of the ODE
 *  together with the KINSOL (KLU) solver
 *
 *  \author bbachmann
 */

#include <time.h>

#include "gbode_main.h"
#include "gbode_util.h"

#include "gbode_conf.h"
#include "gbode_ctrl.h"
#include "gbode_events.h"
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
#include "simulation/jacobian_util.h"
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
 * @param data        Runtime data struct.
 * @param threadData  Thread data for error handling.
 * @param counter     Counter for function calls. Incremented by 1.
 */
void gbode_fODE(DATA *data, threadData_t *threadData, unsigned int* counter)
{
  (*counter)++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return;
}

/**
 * @brief Function allocates memory needed for chosen gbodef method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int gbodef_allocateData(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, DATA_GBODE *gbData)
{
  DATA_GBODEF *gbfData = (DATA_GBODEF *)calloc(1, sizeof(DATA_GBODEF));
  gbData->gbfData = gbfData;

  ANALYTIC_JACOBIAN *jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;
  int i;

  gbfData->nStates = gbData->nStates;

  gbfData->GM_method = getGB_method(FLAG_MR);
  gbfData->tableau = initButcherTableau(gbfData->GM_method, FLAG_MR_ERR);
  if (gbfData->tableau == NULL)
  {
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gbfData->tableau, gbData->nStates, &gbfData->nlSystemSize, &gbfData->type);

  if (gbfData->GM_method == MS_ADAMS_MOULTON)
  {
    gbfData->nlSystemSize = gbData->nStates;
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
    throwStreamPrint(NULL, "Fully Implicit RK method is not supported for the fast states integration!");
  default:
    throwStreamPrint(NULL, "Not handled case for Runge-Kutta method %i", gbfData->type);
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", gbfData->tableau->fac);

  gbfData->ctrl_method = getControllerMethod(FLAG_MR_CTRL);
  if (gbfData->ctrl_method == GB_CTRL_CNST) {
    warningStreamPrint(LOG_STDOUT, 0, "Constant step size not supported for inner integration. Using IController.");
    gbfData->ctrl_method = GB_CTRL_I;
  }
  gbfData->stepSize_control = getControllFunc(gbfData->ctrl_method);

  // allocate memory for the generic RK method
  gbfData->y    = malloc(gbData->nStates*sizeof(double));
  gbfData->yOld = malloc(gbData->nStates*sizeof(double));
  gbfData->yt   = malloc(gbData->nStates*sizeof(double));
  gbfData->y1   = malloc(gbData->nStates*sizeof(double));
  gbfData->f    = malloc(gbData->nStates*sizeof(double));
  gbfData->k         = malloc(gbData->nStates*gbfData->tableau->nStages*sizeof(double));
  gbfData->x         = malloc(gbData->nStates*gbfData->tableau->nStages*sizeof(double));
  gbfData->yLeft     = malloc(gbData->nStates*sizeof(double));
  gbfData->kLeft     = malloc(gbData->nStates*sizeof(double));
  gbfData->yRight    = malloc(gbData->nStates*sizeof(double));
  gbfData->kRight    = malloc(gbData->nStates*sizeof(double));
  gbfData->res_const = malloc(gbData->nStates*sizeof(double));
  gbfData->errest    = malloc(gbData->nStates*sizeof(double));
  gbfData->errtol    = malloc(gbData->nStates*sizeof(double));
  gbfData->err       = malloc(gbData->nStates*sizeof(double));
  gbfData->ringBufferSize = 4;
  gbfData->errValues      = calloc(gbfData->ringBufferSize, sizeof(double));
  gbfData->stepSizeValues = malloc(gbfData->ringBufferSize*sizeof(double));
  gbfData->tv             = malloc(gbfData->ringBufferSize*sizeof(double));
  gbfData->yv             = malloc(gbData->nStates*gbfData->ringBufferSize*sizeof(double));
  gbfData->kv             = malloc(gbData->nStates*gbfData->ringBufferSize*sizeof(double));

  gbData->nFastStates = 0;
  gbData->nSlowStates = gbData->nFastStates;
  gbfData->fastStates_old = malloc(gbData->nStates*sizeof(int));
  gbfData->nFastStates_old = gbData->nFastStates;
  for (int i = 0; i < gbData->nStates; i++)
  {
    gbfData->fastStates_old[i] = i;
  }

  printButcherTableau(gbfData->tableau);

  /* initialize analytic Jacobian, if available and needed */
  if (!gbfData->isExplicit)
  {
    // Allocate Jacobian, if !gbfData->isExplcit and gbData->isExplicit
    // Free is done in gbode_freeData
    if (gbData->isExplicit) {
      jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
      data->callback->initialAnalyticJacobianA(data, threadData, jacobian);
      if(jacobian->availability == JACOBIAN_AVAILABLE || jacobian->availability == JACOBIAN_ONLY_SPARSITY) {
        infoStreamPrint(LOG_SOLVER, 1, "Initialized Jacobian:");
        infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
        infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
        messageClose(LOG_SOLVER);
      }

      // Compare user flag to availabe Jacobian methods
      const char* flagValue;
      if(omc_flag[FLAG_JACOBIAN]){
        flagValue = omc_flagValue[FLAG_JACOBIAN];
      } else {
        flagValue = NULL;
      }
      enum JACOBIAN_METHOD jacobianMethod = setJacobianMethod(threadData, jacobian->availability, flagValue);

      gbfData->symJacAvailable = jacobian->availability == JACOBIAN_AVAILABLE;
      // change GBODE specific jacobian method
      if (jacobianMethod == SYMJAC) {
        warningStreamPrint(LOG_STDOUT, 0, "Symbolic Jacobians without coloring are currently not supported by GBODE."
                                          " Colored symbolical Jacobian will be used.");
      } else if(jacobianMethod == NUMJAC || jacobianMethod == COLOREDNUMJAC || jacobianMethod == INTERNALNUMJAC) {
        warningStreamPrint(LOG_STDOUT, 0, "Numerical Jacobians without coloring are currently not supported by GBODE."
                                          " Colored numerical Jacobian will be used.");
        gbfData->symJacAvailable = FALSE;
      }
    } else {
      gbfData->symJacAvailable = gbData->symJacAvailable;
    }

    /* Allocate memory for the nonlinear solver */
    gbfData->nlsSolverMethod = getGB_NLS_method(FLAG_MR_NLS);

    /* Initialize data for the nonlinear solver */
    gbfData->nlsData = initRK_NLS_DATA_MR(data, threadData, gbfData);
    if (!gbfData->nlsData)
    {
      return -1;
    }
    gbfData->sparsePattern_DIRK = initializeSparsePattern_SR(data, gbfData->nlsData);
  }
  else
  {
    gbfData->symJacAvailable = FALSE;
    gbfData->nlsSolverMethod = GB_NLS_UNKNOWN;
    gbfData->nlsData = NULL;
    gbfData->jacobian = NULL;
  }

  gbfData->interpolation = getInterpolationMethod(FLAG_MR_INT);
  if (!gbfData->tableau->withDenseOutput) {
    if (gbfData->interpolation == GB_DENSE_OUTPUT) gbfData->interpolation = GB_INTERPOL_HERMITE;
  }
  switch (gbfData->interpolation)
  {
  case GB_INTERPOL_LIN:
    infoStreamPrint(LOG_SOLVER, 0, "Linear interpolation is used for emitting results");
    break;
  case GB_INTERPOL_HERMITE:
  case GB_INTERPOL_HERMITE_a:
  case GB_INTERPOL_HERMITE_b:
  case GB_INTERPOL_HERMITE_ERRCTRL:
    infoStreamPrint(LOG_SOLVER, 0, "Hermite interpolation is used for the slow states");
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    infoStreamPrint(LOG_SOLVER, 0, "Dense output is used for emitting results");
    break;
  default:
    throwStreamPrint(NULL, "Unhandled interpolation case.");
  }

  if (ACTIVE_STREAM(LOG_GBODE_STATES))
  {
    char filename[4096];
    unsigned int bufSize = 4096;
    snprintf(filename, bufSize, "%s_ActiveStates.txt", data->modelData->modelFilePrefix);
    gbfData->fastStatesDebugFile = omc_fopen(filename, "w");
    warningStreamPrint(LOG_STDOUT, 0, "LOG_GBODE_STATES sets -noEquidistantTimeGrid for emitting results!");
    solverInfo->integratorSteps = TRUE;
  }
  else
  {
    gbfData->fastStatesDebugFile = NULL;
  }
  i = fmin(fmax(round(gbData->nStates * gbData->percentage), 1), gbData->nStates - 1);
  infoStreamPrint(LOG_SOLVER, 0, "Number of states %d (%d slow states, %d fast states)", gbData->nStates, gbData->nStates-i, i);

   /* reset statistics because it is accumulated in solver_main.c */
  resetSolverStats(&gbfData->stats);

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
int gbode_allocateData(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  DATA_GBODE *gbData = (DATA_GBODE *)calloc(1, sizeof(DATA_GBODE));

  // Set backup in simulationInfo
  data->simulationInfo->backupSolverData = (void *)gbData;

  solverInfo->solverData = (void *)gbData;

  gbData->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  gbData->GM_method = getGB_method(FLAG_SR);
  gbData->tableau = initButcherTableau(gbData->GM_method, FLAG_SR_ERR);
  if (gbData->tableau == NULL) {
    errorStreamPrint(LOG_STDOUT, 0, "allocateDataGm: Failed to initialize gbode tableau for method %s", GB_METHOD_NAME[gbData->GM_method]);
    return -1;
  }

  // Get size of non-linear system
  analyseButcherTableau(gbData->tableau, gbData->nStates, &gbData->nlSystemSize, &gbData->type);

  switch (gbData->type) {
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
    throwStreamPrint(NULL, "gbode_allocateData: Unknown type %i", gbData->type);
  }
  if (gbData->GM_method == MS_ADAMS_MOULTON) {
    gbData->nlSystemSize = gbData->nStates;
    gbData->step_fun = &(full_implicit_MS);
    gbData->type = MS_TYPE_IMPLICIT;
    gbData->isExplicit = FALSE;
  }

  // test of multi-step method

  gbData->ctrl_method = getControllerMethod(FLAG_SR_CTRL);
  gbData->stepSize_control = getControllFunc(gbData->ctrl_method);
   /* define maximum step size gbode is allowed to go */
  if (omc_flag[FLAG_MAX_STEP_SIZE])
  {
    gbData->maxStepSize = atof(omc_flagValue[FLAG_MAX_STEP_SIZE]);
    if (gbData->maxStepSize < 0 || gbData->maxStepSize > DBL_MAX/2) {
      throwStreamPrint(NULL, "maximum step size %g is not allowed", gbData->maxStepSize);
    } else {
      infoStreamPrint(LOG_SOLVER, 0, "maximum step size %g", gbData->maxStepSize);
    }
  }
  else
  {
    gbData->maxStepSize = -1;
    infoStreamPrint(LOG_SOLVER, 0, "maximum step size not set");
  }
    /* Initial step size */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE])
  {
    gbData->initialStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);
    if (gbData->initialStepSize < GB_MINIMAL_STEP_SIZE || gbData->initialStepSize > DBL_MAX/2) {
      throwStreamPrint(NULL, "initial step size %g is not allowed, minimal step size is %g", gbData->initialStepSize, GB_MINIMAL_STEP_SIZE);
    } else {
      infoStreamPrint(LOG_SOLVER, 0, "initial step size %g", gbData->initialStepSize);
    }
  }
  else
  {
    gbData->initialStepSize = -1; /* use default */
    infoStreamPrint(LOG_SOLVER, 0, "initial step size not set");
  }

 /* if FLAG_NO_RESTART is set, configure gbode */
  if (omc_flag[FLAG_NO_RESTART])
  {
    gbData->noRestart = TRUE;
  }
  else
  {
    gbData->noRestart = FALSE;
  }
  infoStreamPrint(LOG_SOLVER, 0, "gbode performs a restart after an event occurs %s", gbData->noRestart?"NO":"YES");

  gbData->isFirstStep = TRUE;

  /* Allocate internal memory */
  gbData->y         = malloc(sizeof(double) * gbData->nStates);
  gbData->yOld      = malloc(sizeof(double) * gbData->nStates);
  gbData->yLeft     = malloc(sizeof(double) * gbData->nStates);
  gbData->kLeft     = malloc(sizeof(double) * gbData->nStates);
  gbData->yRight    = malloc(sizeof(double) * gbData->nStates);
  gbData->kRight    = malloc(sizeof(double) * gbData->nStates);
  gbData->yt        = malloc(sizeof(double) * gbData->nStates);
  gbData->y1        = malloc(sizeof(double) * gbData->nStates);
  gbData->f         = malloc(sizeof(double) * gbData->nStates);
  gbData->k         = malloc(sizeof(double) * gbData->nStates * gbData->tableau->nStages);
  gbData->x         = malloc(sizeof(double) * gbData->nStates * gbData->tableau->nStages);
  gbData->res_const = malloc(sizeof(double) * gbData->nStates);
  gbData->errest    = malloc(sizeof(double) * gbData->nStates);
  gbData->errtol    = malloc(sizeof(double) * gbData->nStates);
  gbData->err       = malloc(sizeof(double) * gbData->nStates);
  // ring buffer for different purposes (extrapolation, etc.)
  gbData->ringBufferSize = 4;
  gbData->errValues      = malloc(sizeof(double) * gbData->ringBufferSize);
  gbData->stepSizeValues = malloc(sizeof(double) * gbData->ringBufferSize);
  gbData->tv             = malloc(sizeof(double) * gbData->ringBufferSize);
  gbData->yv             = malloc(gbData->nStates*sizeof(double) * gbData->ringBufferSize);
  gbData->kv             = malloc(gbData->nStates*sizeof(double) * gbData->ringBufferSize);
  gbData->tr             = malloc(sizeof(double) * 2);
  gbData->yr             = malloc(gbData->nStates*sizeof(double) * 2);
  gbData->kr             = malloc(gbData->nStates*sizeof(double) * 2);

  printButcherTableau(gbData->tableau);

  /* initialize analytic Jacobian, if available and needed */
  if (!gbData->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    data->callback->initialAnalyticJacobianA(data, threadData, jacobian);
    if(jacobian->availability == JACOBIAN_AVAILABLE || jacobian->availability == JACOBIAN_ONLY_SPARSITY) {
      infoStreamPrint(LOG_SOLVER, 1, "Initialized Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }

    // Compare user flag to availabe Jacobian methods
    const char* flagValue;
    if(omc_flag[FLAG_JACOBIAN]){
      flagValue = omc_flagValue[FLAG_JACOBIAN];
    } else {
      flagValue = NULL;
    }
    enum JACOBIAN_METHOD jacobianMethod = setJacobianMethod(threadData, jacobian->availability, flagValue);

    gbData->symJacAvailable = jacobian->availability == JACOBIAN_AVAILABLE;
    // change GBODE specific jacobian method
    if (jacobianMethod == SYMJAC) {
      warningStreamPrint(LOG_STDOUT, 0, "Symbolic Jacobians without coloring are currently not supported by GBODE."
                                        " Colored symbolical Jacobian will be used.");
    } else if(jacobianMethod == NUMJAC || jacobianMethod == COLOREDNUMJAC || jacobianMethod == INTERNALNUMJAC) {
      warningStreamPrint(LOG_STDOUT, 0, "Numerical Jacobians without coloring are currently not supported by GBODE."
                                        " Colored numerical Jacobian will be used.");
      gbData->symJacAvailable = FALSE;
    }

    /* Allocate memory for the nonlinear solver */
    gbData->nlsSolverMethod = getGB_NLS_method(FLAG_SR_NLS);
    gbData->nlsData = initRK_NLS_DATA(data, threadData, gbData);
    if (!gbData->nlsData) {
      return -1;
    } else {
      infoStreamPrint(LOG_SOLVER, 1, "Nominal values of  the states:");
      for (int i = 0; i < gbData->nStates; i++) {
        infoStreamPrint(LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbData->nlsData->nominal[i]);
      }
      messageClose(LOG_SOLVER);
    }
  } else {
    gbData->symJacAvailable = FALSE;
    gbData->nlsSolverMethod = GB_NLS_UNKNOWN;
    gbData->nlsData = NULL;
    gbData->jacobian = NULL;
  }

  gbData->percentage = getGBRatio();
  gbData->multi_rate = gbData->percentage > 0 && gbData->percentage < 1;

  gbData->fastStatesIdx   = malloc(sizeof(int) * gbData->nStates);
  gbData->slowStatesIdx   = malloc(sizeof(int) * gbData->nStates);
  gbData->sortedStatesIdx = malloc(sizeof(int) * gbData->nStates);

  gbData->nFastStates = 0;
  gbData->nSlowStates = gbData->nStates;
  for (int i = 0; i < gbData->nStates; i++) {
    gbData->fastStatesIdx[i] = i;
    gbData->slowStatesIdx[i] = i;
    gbData->sortedStatesIdx[i] = i;
  }


  if (gbData->multi_rate && omc_flagValue[FLAG_SR_INT]==NULL) {
    gbData->interpolation = GB_DENSE_OUTPUT_ERRCTRL;
  } else {
    gbData->interpolation = getInterpolationMethod(FLAG_SR_INT);
  }

  if (!gbData->tableau->withDenseOutput) {
    if (gbData->interpolation == GB_DENSE_OUTPUT) gbData->interpolation = GB_INTERPOL_HERMITE;
    if (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL) gbData->interpolation = GB_INTERPOL_HERMITE_ERRCTRL;
  }

  char buffer[1024];
  unsigned int bufSize = 1024;
  if (gbData->multi_rate) {
    snprintf(buffer, bufSize, "%s", " and slow states interpolation");
  } else {
    snprintf(buffer, bufSize, "%s"," ");
  }
  switch (gbData->interpolation)
  {
  case GB_INTERPOL_LIN:
    infoStreamPrint(LOG_SOLVER, 0, "Linear interpolation is used for emitting results%s", buffer);
    break;
  case GB_INTERPOL_HERMITE_ERRCTRL:
  case GB_INTERPOL_HERMITE_a:
  case GB_INTERPOL_HERMITE_b:
  case GB_INTERPOL_HERMITE:
    infoStreamPrint(LOG_SOLVER, 0, "Hermite interpolation is used for emitting results%s", buffer);
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    infoStreamPrint(LOG_SOLVER, 0, "Dense output is used  for emitting results%s", buffer);
    break;
  default:
    throwStreamPrint(NULL, "Unhandled interpolation case.");
  }
  gbData->err_threshold = 0.1;
  gbData->err_int = 0;            // needed, if GB_INTERPOL_HERMITE_ERRCTRL or GB_DENSE_OUTPUT_ERRCTRL is used

  if (gbData->multi_rate) {
    gbodef_allocateData(data, threadData, solverInfo, gbData);
    gbData->tableau->isKRightAvailable = FALSE;
  } else {
    gbData->gbfData = NULL;
  }

  // Value will be handled in the initial step size determination (-1 and 0 means no failure)
  gbData->initialFailures = -1;

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void gbodef_freeData(DATA_GBODEF *gbfData)
{
  /* Free non-linear system data */
  freeRK_NLS_DATA(gbfData->nlsData);

  /* Free Jacobian */
  freeAnalyticJacobian(gbfData->jacobian);
  free(gbfData->jacobian); gbfData->jacobian = NULL;

  /* Free sparsity pattern */
  freeSparsePattern(gbfData->sparsePattern_DIRK);
  free(gbfData->sparsePattern_DIRK);

  /* Free Butcher tableau */
  freeButcherTableau(gbfData->tableau);

  free(gbfData->y);
  free(gbfData->yOld);
  free(gbfData->yLeft);
  free(gbfData->kLeft);
  free(gbfData->yRight);
  free(gbfData->kRight);
  free(gbfData->yt);
  free(gbfData->y1);
  free(gbfData->f);
  free(gbfData->k);
  free(gbfData->x);
  free(gbfData->res_const);
  free(gbfData->errest);
  free(gbfData->errtol);
  free(gbfData->err);
  free(gbfData->errValues);
  free(gbfData->stepSizeValues);
  free(gbfData->tv);
  free(gbfData->yv);
  free(gbfData->kv);
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
void gbode_freeData(DATA* data, DATA_GBODE *gbData)
{
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  freeAnalyticJacobian(jacobian);

  /* Free non-linear system data */
  freeRK_NLS_DATA(gbData->nlsData);

  /* Free Jacobian */
  freeAnalyticJacobian(gbData->jacobian);
  free(gbData->jacobian); gbData->jacobian = NULL;

  /* Free Butcher tableau */
  freeButcherTableau(gbData->tableau);

  if (gbData->multi_rate)
  {
    gbodef_freeData(gbData->gbfData);
  }
  /* Free multi-rate data */
  free(gbData->err);
  free(gbData->errValues);
  free(gbData->stepSizeValues);
  free(gbData->tv);
  free(gbData->yv);
  free(gbData->kv);
  free(gbData->tr);
  free(gbData->yr);
  free(gbData->kr);
  free(gbData->fastStatesIdx);
  free(gbData->slowStatesIdx);
  free(gbData->sortedStatesIdx);

  /* Free remaining arrays */
  free(gbData->y);
  free(gbData->yOld);
  free(gbData->yLeft);
  free(gbData->kLeft);
  free(gbData->yRight);
  free(gbData->kRight);
  free(gbData->yt);
  free(gbData->y1);
  free(gbData->f);
  free(gbData->k);
  free(gbData->x);
  free(gbData->res_const);
  free(gbData->errest);
  free(gbData->errtol);

  free(gbData);
  gbData = NULL;

  return;
}

/**
 * @brief Calculate initial step size.
 *
 * Called at the beginning of simulation or after an event occurred.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 */
void gbodef_init(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GBODE*  gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;
  int nStates = gbfData->nStates;
  int nStages = gbfData->tableau->nStages;

  int i;

  gbfData->didEventStep = FALSE;

  gbfData->time = gbData->time;
  gbfData->stepSize = 0.1*gbData->stepSize*IController(&(gbData->err_fast), &(gbData->stepSize), 1);

  memcpy(gbfData->yOld, gbData->yOld, sizeof(double) * nStates);
  memcpy(gbfData->y, gbData->y, sizeof(double) * nStates);

  gbfData->timeRight = gbData->timeLeft;
  memcpy(gbfData->yRight, gbData->yLeft, sizeof(double) * nStates);
  memcpy(gbfData->kRight, gbData->kLeft, sizeof(double) * nStates);

  // set solution ring buffer (extrapolation in case of NLS)
  for (i=0; i<gbfData->ringBufferSize; i++) {
    gbfData->tv[i] = gbData->tv[i];
    memcpy(gbfData->yv + i * nStates, gbData->yv + i * nStates, nStates * sizeof(double));
    memcpy(gbfData->kv + i * nStates, gbData->kv + i * nStates, nStates * sizeof(double));
  }
}

/**
 * @brief Initialize ring buffer and interpolation arrays.
 *
 * Called at the beginning of simulation or after an event occurred.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 */
void gbode_init(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = &sData->realVars[gbData->nStates];
  int nStates = gbData->nStates;
  int i;

  // initialize ring buffer for error and step size control
  for (i=0; i<gbData->ringBufferSize; i++) {
    gbData->errValues[i] = 0;
    gbData->stepSizeValues[i] = 0;
  }

  /* reset statistics, because it is accumulated in solver_main.c */
  if (!gbData->isExplicit)
    gbData->nlsData->numberOfJEval = 0;
  resetSolverStats(&gbData->stats);

  // initialize vector used for interpolation (equidistant time grid)
  // and for the birate inner integration
  gbData->timeRight = gbData->time;
  memcpy(gbData->yRight, gbData->yOld, nStates*sizeof(double));
  memcpy(gbData->kRight, fODE, nStates*sizeof(double));

  // set solution ring buffer (extrapolation in case of NLS)
  for (i=0; i<gbData->ringBufferSize; i++) {
    gbData->tv[i] = gbData->timeRight;
    memcpy(gbData->yv + i * nStates, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kv + i * nStates, gbData->kRight, nStates * sizeof(double));
  }
}

/*! \fn gbodef_main
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'gm'
 */
int gbodef_main(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;
  DATA_GBODEF *gbfData = gbData->gbfData;

  double stopTime = data->simulationInfo->stopTime;

  double err, eventTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;

  int i, ii, j, jj, l, ll, r, rr;
  int integrator_step_info;

  int nStates = gbData->nStates;
  int nFastStates = gbData->nFastStates;
  int nStages = gbfData->tableau->nStages;

  modelica_boolean fastStatesChange = FALSE;
  modelica_boolean foundEvent;

  // This is the target time of the main integrator
  double innerTargetTime = fmin(targetTime, gbData->timeRight);

  /* The inner integrator needs to be initialzed, at start time, when an event occured,
  *  and if outer integrations have been done with all states involved
  * (gbfData->timeRight < gbData->timeLeft)
  */
  if (gbfData->didEventStep || gbfData->timeRight < gbData->timeLeft) {
    gbodef_init(data, threadData, solverInfo);
  }


  fastStatesChange = checkFastStatesChange(gbData);

  if (fastStatesChange && !gbfData->isExplicit) {
    struct dataSolver *solverData = gbfData->nlsData->solverData;
    // set number of non-linear variables and corresponding nominal values (changes dynamically during simulation)
    gbfData->nlsData->size = gbData->nFastStates;

    infoStreamPrint(LOG_GBODE, 1, "Fast states and corresponding nominal values:");
    for (ii = 0; ii < nFastStates; ii++)
    {
      i = gbData->fastStatesIdx[ii];
      // Get the nominal values of the fast states
      gbfData->nlsData->nominal[ii] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
      infoStreamPrint(LOG_GBODE, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbfData->nlsData->nominal[ii]);
    }
    messageClose(LOG_GBODE);

    if (gbfData->nlsData->isPatternAvailable)
    {
      updateSparsePattern_MR(gbData, gbfData->jacobian->sparsePattern);
      gbfData->jacobian->sizeCols = nFastStates;
      gbfData->jacobian->sizeRows = nFastStates;

      switch (gbfData->nlsSolverMethod)
      {
      case GB_NLS_NEWTON:
        ((DATA_NEWTON *)solverData->ordinaryData)->n = gbData->nFastStates;
        break;
      case GB_NLS_KINSOL:
        nlsKinsolFree(solverData->ordinaryData);
        /* Set NLS user data */
        NLS_USERDATA* nlsUserData = initNlsUserData(data, threadData, -1, gbfData->nlsData, gbfData->jacobian);
        nlsUserData->solverData = (void*) gbfData;
        solverData->ordinaryData = (void*) nlsKinsolAllocate(gbfData->nlsData->size, nlsUserData, FALSE);
        break;
      default:
        throwStreamPrint(NULL, "NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
      }
    }
  }

  // print informations on the calling details
  infoStreamPrint(LOG_SOLVER, 1, "gbodef solver started (fast states/states): %d/%d", gbData->nFastStates,gbData->nStates);
  printIntVector_gb(LOG_SOLVER, "fast States:", gbData->fastStatesIdx, gbData->nFastStates, gbfData->time);
  infoStreamPrint(LOG_SOLVER, 0, "interpolation is done between %10g to %10g (SR-stepsize: %10g)",
                  gbData->timeLeft, gbData->timeRight, gbData->lastStepSize);

  if (ACTIVE_STREAM(LOG_GBODE_V)) {
    infoStreamPrint(LOG_GBODE_V, 1, "Interpolation values from outer integration:");
    printVector_gb(LOG_GBODE_V, "yL", gbData->yLeft, gbData->nStates, gbData->timeLeft);
    printVector_gb(LOG_GBODE_V, "kL", gbData->kLeft, gbData->nStates, gbData->timeLeft);
    printVector_gb(LOG_GBODE_V, "yR", gbData->yRight, gbData->nStates, gbData->timeRight);
    printVector_gb(LOG_GBODE_V, "kR", gbData->kRight, gbData->nStates, gbData->timeRight);
    messageClose(LOG_GBODE_V);
  }

  while (gbfData->time < innerTargetTime) {

    // Don't exceed simulation stop time
    if (gbfData->time + gbfData->stepSize > stopTime) {
      gbfData->stepSize = stopTime - gbfData->time;
    }

    // Synchronize inner integration with outer integration
    // Strategy: either set outer step to the inner integration
    // or the other way around (depending on, if more or less
    // than 2 inner steps required)
    if (gbfData->time + gbfData->stepSize > gbData->timeRight) {
      // if (gbfData->time - gbfData->stepSize > gbData->timeLeft) {
      //   gbData->timeRight = gbfData->timeRight;
      //   gbData->lastStepSize = gbData->timeRight - gbData->timeLeft;
      //   messageClose(LOG_SOLVER);
      //   return 0;
      // } else {
        gbfData->stepSize = gbData->timeRight - gbfData->time;
      // }
    }

    // store left hand data for later interpolation
    gbfData->timeLeft = gbfData->timeRight;
    memcpy(gbfData->yLeft, gbfData->yRight, nStates * sizeof(double));
    memcpy(gbfData->kLeft, gbfData->kRight, nStates * sizeof(double));

    // debug the changes of the states and derivatives during integration
    if (ACTIVE_STREAM(LOG_GBODE)) {
      infoStreamPrint(LOG_GBODE, 1, "states and derivatives at left hand side (inner integration):");
      printVector_gb(LOG_GBODE, "yL", gbfData->yLeft, nStates, gbfData->timeLeft);
      printVector_gb(LOG_GBODE, "kL", gbfData->kLeft, nStates, gbfData->timeLeft);
      messageClose(LOG_GBODE);
    }

    do {
      if (ACTIVE_STREAM(LOG_SOLVER_V)) {
        infoStreamPrint(LOG_SOLVER_V, 1, "States and derivatives of the ring buffer:");
        for (int i=0; i<gbfData->ringBufferSize; i++) {
          printVector_gbf(LOG_SOLVER_V, "y", gbfData->yv + i * nStates, nStates, gbfData->tv[i], gbData->nFastStates, gbData->fastStatesIdx);
          printVector_gbf(LOG_SOLVER_V, "k", gbfData->kv + i * nStates, nStates, gbfData->tv[i], gbData->nFastStates, gbData->fastStatesIdx);
        }
        messageClose(LOG_SOLVER_V);
      }

      // do one integration step resulting in two different approximations
      // results are stored in gbData->y and gbData->yt
      if (gbfData->tableau->richardson) {
        integrator_step_info = gbodef_richardson(data, threadData, solverInfo);
      } else {
        integrator_step_info = gbfData->step_fun(data, threadData, solverInfo);
      }

      // error handling: try half of the step size!
      if (integrator_step_info != 0) {
        (gbfData->stats).nConvergenveTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "gbodef_main: Failed to calculate step at time = %5g.", gbfData->time);
        gbfData->stepSize *= 0.5;
        infoStreamPrint(LOG_SOLVER, 0, "Try half of the step size = %g", gbfData->stepSize);
        if (gbfData->stepSize < GB_MINIMAL_STEP_SIZE) {
          errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but error still to large.", GB_MINIMAL_STEP_SIZE);
          messageClose(LOG_SOLVER);
          return -1;
        }
        err = 100;
        continue;
      }

      for (i = 0, err=0; i < nFastStates; i++) {
        ii = gbData->fastStatesIdx[i];
        // calculate corresponding values for the error estimator and step size control
        gbfData->errtol[ii] = Rtol * fmax(fabs(gbfData->y[ii]), fabs(gbfData->yt[ii])) + Atol;
        gbfData->errest[ii] = fabs(gbfData->y[ii] - gbfData->yt[ii]);
        gbfData->err[ii] = gbfData->tableau->fac * gbfData->errest[ii] / gbfData->errtol[ii];
        err = fmax(err, gbfData->err[ii]);
      }

      gbData->err_fast = err;

      // Rotate and update buffer
      for (i = (gbfData->ringBufferSize - 1); i > 0 ; i--) {
        gbfData->errValues[i] = gbfData->errValues[i - 1];
        gbfData->stepSizeValues[i] = gbfData->stepSizeValues[i - 1];
      }

      gbfData->errValues[0] = err;
      gbfData->stepSizeValues[0] = gbfData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      // Call the step size control
      gbfData->lastStepSize = gbfData->stepSize;
      gbfData->stepSize *= gbfData->stepSize_control(gbfData->errValues, gbfData->stepSizeValues, gbfData->tableau->error_order);

      // debug ring buffer for the states and derviatives of the states
      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        infoStreamPrint(LOG_GBODE_V, 1, "ring buffer during steps of inner integration");
        infoStreamPrint(LOG_GBODE_V, 0, "old value:");
        printVector_gb(LOG_GBODE_V, "y", gbfData->yOld, nStates, gbfData->time);
        debugRingBuffer(LOG_GBODE_V, gbfData->x, gbfData->k, nStates, gbfData->tableau, gbfData->time, gbfData->lastStepSize);
        infoStreamPrint(LOG_GBODE_V, 0, "new value:");
        printVector_gb(LOG_GBODE_V, "y", gbfData->y, nStates, gbfData->time + gbfData->lastStepSize);
        messageClose(LOG_GBODE_V);
      }

      // Re-do step, if error is larger than requested
      if (err > 1)
      {
        gbfData->stats.nErrorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "Reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbfData->time, gbfData->time + gbfData->lastStepSize, err, gbfData->stepSize);
        if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
          dumpFastStates_gbf(gbData, gbfData->time + gbfData->lastStepSize, 1);
        }
      }
    } while (err > 1);

    // Count successful integration steps
    gbfData->stats.nStepsTaken += 1;

    // interpolate the slow states to the boundaries of current integration interval, this is used for event detection
    // interpolate the slow states on the time of the current stage
    gb_interpolation(gbfData->interpolation,
                     gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                     gbData->timeRight, gbData->yRight, gbData->kRight,
                     gbfData->time, gbfData->yOld,
                     gbData->nSlowStates, gbData->slowStatesIdx,  nStates, gbData->tableau, gbData->x, gbData->k);

    gb_interpolation(gbfData->interpolation,
                     gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                     gbData->timeRight, gbData->yRight, gbData->kRight,
                     gbfData->time + gbfData->lastStepSize, gbfData->y,
                     gbData->nSlowStates, gbData->slowStatesIdx,  nStates, gbData->tableau, gbData->x, gbData->k);

    // store right hand values for latter interpolation
    gbfData->timeRight = gbfData->time + gbfData->lastStepSize;
    memcpy(gbfData->yRight, gbfData->y, nStates * sizeof(double));
    // update kRight
    if (!gbfData->tableau->isKRightAvailable) {
      sData->timeValue = gbfData->timeRight;
      memcpy(sData->realVars, gbfData->yRight, data->modelData->nStates * sizeof(double));
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
    }
    memcpy(gbfData->kRight, fODE, nStates * sizeof(double));

    eventTime = checkForEvents(data, threadData, solverInfo, gbfData->time, gbfData->yOld, gbfData->time + gbfData->lastStepSize, gbfData->y, TRUE, &foundEvent);
    if (foundEvent)
    {
      solverInfo->currentTime = eventTime;
      sData->timeValue = solverInfo->currentTime;

      // sData->realVars are the "numerical" values on the right hand side of the event
      gbData->time = eventTime;
      memcpy(gbData->yOld, sData->realVars, gbData->nStates * sizeof(double));

      gbfData->time = eventTime;
      memcpy(gbfData->yOld, sData->realVars, gbData->nStates * sizeof(double));

      /* write statistics to the solverInfo data structure */
      memcpy(&solverInfo->solverStatsTmp, &gbfData->stats, sizeof(SOLVERSTATS));

      // log the emitted result
      if (ACTIVE_STREAM(LOG_GBODE)){
        infoStreamPrint(LOG_GBODE, 1, "Emit result (inner integration):");
        printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
        messageClose(LOG_GBODE);
      }

      if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
        dumpFastStates_gb(gbData, TRUE, eventTime, 0);
      }

      // Get out of the integration routine for event handling
      messageClose(LOG_SOLVER);
      return 1;
    }

    /* update time with performed stepSize */
    gbfData->time += gbfData->lastStepSize;

    // debug the changes of the states and derivatives during integration
    if (ACTIVE_STREAM(LOG_GBODE)) {
      infoStreamPrint(LOG_GBODE, 1, "States and derivatives at right hand side (inner integration):");
      printVector_gb(LOG_GBODE, "yR", gbfData->yRight, nStates, gbfData->timeRight);
      printVector_gb(LOG_GBODE, "kR", gbfData->kRight, nStates, gbfData->timeRight);
      messageClose(LOG_GBODE);
    }

    // Rotate ring buffer
    for (i = (gbfData->ringBufferSize - 1); i > 0 ; i--) {
      gbfData->tv[i] = gbfData->tv[i - 1];
      memcpy(gbfData->yv + i * nStates, gbfData->yv + (i - 1) * nStates, nStates * sizeof(double));
      memcpy(gbfData->kv + i * nStates, gbfData->kv + (i - 1) * nStates, nStates * sizeof(double));
    }

    gbfData->tv[0] = gbfData->timeRight;
    memcpy(gbfData->yv, gbfData->yRight, nStates * sizeof(double));
    memcpy(gbfData->kv, gbfData->kRight, nStates * sizeof(double));

    debugRingBufferSteps(LOG_GBODE, gbfData->yv, gbfData->kv, gbfData->tv, nStates,  gbfData->ringBufferSize);

    /* step is accepted and yOld needs to be updated */
    //  copyVector_gbf(gbfData->yOld, gbfData->y, nFastStates, gbData->fastStates);
    memcpy(gbfData->yOld, gbfData->y, nStates * sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "Accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gbfData->time - gbfData->lastStepSize, gbfData->time, err, gbfData->stepSize);

    if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
      dumpFastStates_gbf(gbData, gbfData->time, 0);
    }

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps) {
      sData->timeValue = gbfData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbfData->y, nStates * sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
      // log the emitted result
      if (ACTIVE_STREAM(LOG_GBODE)){
        infoStreamPrint(LOG_GBODE, 1, "Emit result (inner integration):");
        printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
        messageClose(LOG_GBODE);
      }
    }

    if ((gbData->timeRight - gbfData->time) < GB_MINIMAL_STEP_SIZE || gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
      gbfData->time = gbData->timeRight;
      break;
    }
  }

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  //gbData->err_fast = gbfData->errValues[0];

  if (!solverInfo->integratorSteps && gbfData->time >= targetTime) {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    /* Here, only the fast states get updated */
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    // solverInfo->currentTime = sData->timeValue;

    gb_interpolation(gbfData->interpolation,
                     gbfData->timeLeft,  gbfData->yLeft,  gbfData->kLeft,
                     gbfData->timeRight, gbfData->yRight, gbfData->kRight,
                     sData->timeValue,  sData->realVars,
                     nFastStates, gbData->fastStatesIdx,  nStates, gbfData->tableau, gbfData->x, gbfData->k);
  }
  /* Solver statistics */
  if (!gbfData->isExplicit)
    gbfData->stats.nCallsJacobian = gbfData->nlsData->numberOfJEval;

  infoStreamPrint(LOG_SOLVER, 0, "gbodef finished  (inner steps).");
  messageClose(LOG_SOLVER);

  return 0;
}

/**
 * @brief Generic Runge-Kutta step.
 *
 * Do one Runge-Kutta integration step.
 * Has step-size control and event handling.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Storing Runge-Kutta solver data.
 * @return int          Return 0 on success, -1 on failure.
 */
int gbode_birate(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA *)data->localData[1];
  modelica_real *fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;

  double err, err_threshold;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  int i, ii, l;
  int nStates = gbData->nStates;
  int nStages = gbData->tableau->nStages;
  int gb_step_info;

  double targetTime;
  double eventTime;
  double stopTime = data->simulationInfo->stopTime;

  int *sortedStates;
  modelica_boolean foundEvent;

  // root finding will be done in gbode after each accepted step
  solverInfo->solverRootFinding = 1;

  /* Calculate steps until targetTime is reached */
  // 1 => emit result at integrator step points; 0 => equidistant grid
  if (solverInfo->integratorSteps) {
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime) {
      targetTime = data->simulationInfo->nextSampleEvent;
    } else {
      targetTime = data->simulationInfo->stopTime;
    }
  } else {
    targetTime = solverInfo->currentTime + solverInfo->currentStepSize;
  }

  infoStreamPrint(LOG_SOLVER, 1, "Start gbode (birate integration)  from %g to %g",
                  solverInfo->currentTime, targetTime);

  // (Re-)initialize after events or at first call of gbode_sinlerate
  if (solverInfo->didEventStep || gbData->isFirstStep) {
    // calculate initial step size and reset ring buffer and statistic counters
    // initialize gbData->time, gbData->yOld, gbData->timeRight, gbData->yRight and gbData->kRight
    getInitStepSize(data, threadData, gbData);
    gbode_init(data, threadData, solverInfo);
    gbData->gbfData->didEventStep = TRUE;
    gbData->isFirstStep = FALSE;
    solverInfo->didEventStep = FALSE;
  }

  // Constant step size
  if (gbData->ctrl_method == GB_CTRL_CNST) {
    gbData->stepSize = solverInfo->currentStepSize;
  }

  // Check if multirate step is necessary, otherwise the correct values are already stored in sData
  if (gbData->nFastStates > 0 && gbData->gbfData->time < gbData->timeRight && !gbData->gbfData->didEventStep) {
    // run multirate step
    gb_step_info = gbodef_main(data, threadData, solverInfo, targetTime);
    // synchronize y, yRight , kRight and buffer
    if (fabs(gbData->timeRight - gbData->gbfData->timeRight) < GB_MINIMAL_STEP_SIZE) {
      gbData->time = gbData->timeRight;
      memcpy(gbData->y, gbData->gbfData->y, nStates * sizeof(double));
      memcpy(gbData->yOld, gbData->y, nStates * sizeof(double));
      memcpy(gbData->yRight, gbData->gbfData->yRight, nStates * sizeof(double));
      memcpy(gbData->kRight, gbData->gbfData->kRight, nStates * sizeof(double));
      memcpy(gbData->err, gbData->gbfData->err, nStates * sizeof(double));

      // update buffer, rest has already been rotated
      gbData->tv[0] = gbData->timeRight;
      memcpy(gbData->yv, gbData->yRight, nStates * sizeof(double));
      memcpy(gbData->kv, gbData->kRight, nStates * sizeof(double));

      /* step is accepted and yOld needs to be updated */
      infoStreamPrint(LOG_SOLVER, 0, "Accept step from %10g to %10g, error slow states %10g, new stepsize %10g",
                      gbData->time - gbData->lastStepSize, gbData->time, gbData->errValues[0], gbData->stepSize);

      if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
        // dump fast states in file
        dumpFastStates_gb(gbData, FALSE, gbData->time, 0);
      }
    }
    if (gb_step_info !=0) {
      // get out of here, if an event has happend!
      messageClose(LOG_SOLVER);
      if (gb_step_info>0)
        return 0;
      else
        return gb_step_info;
    }
  }

  /* Main integration loop, if gbData->time already greater than targetTime, only the
     interpolation is necessary for emitting the output variables (see below) */
  while (gbData->time < targetTime)
  {
    // store left hand data for later interpolation
    gbData->timeLeft = gbData->timeRight;
    memcpy(gbData->yLeft, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kLeft, gbData->kRight, nStates * sizeof(double));

    // debug the ring buffer changes of the states and derivatives during integration
    if (ACTIVE_STREAM(LOG_GBODE)) {
      infoStreamPrint(LOG_GBODE, 1, "States and derivatives at left hand side:");
      printVector_gb(LOG_GBODE, "yL", gbData->yLeft, nStates, gbData->timeLeft);
      printVector_gb(LOG_GBODE, "kL", gbData->kLeft, nStates, gbData->timeLeft);
      messageClose(LOG_GBODE);
    }

    do {
      if (ACTIVE_STREAM(LOG_SOLVER_V)) {
        infoStreamPrint(LOG_SOLVER_V, 1, "States and derivatives of the ring buffer:");
        for (int i=0; i<gbData->ringBufferSize; i++) {
          printVector_gb(LOG_SOLVER_V, "y", gbData->yv + i * nStates, nStates, gbData->tv[i]);
          printVector_gb(LOG_SOLVER_V, "k", gbData->kv + i * nStates, nStates, gbData->tv[i]);
        }
        messageClose(LOG_SOLVER_V);
      }

      // do one integration step resulting in two different approximations
      // results are stored in gbData->y and gbData->yt
      if (gbData->tableau->richardson) {
        gb_step_info = gbode_richardson(data, threadData, solverInfo);
      } else {
        gb_step_info = gbData->step_fun(data, threadData, solverInfo);
      }

      // debug ring buffer for the states and derviatives of the states
      if (ACTIVE_STREAM(LOG_GBODE) && gb_step_info == 0) {
        infoStreamPrint(LOG_GBODE, 1, "Approximations after step calculation:");
        printVector_gb(LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
        printVector_gb(LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
        messageClose(LOG_GBODE);
      }

      // error handling: try half of the step size!
      if (gb_step_info != 0) {
        gbData->stats.nConvergenveTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "gbode_main: Failed to calculate step at time = %5g.", gbData->time + gbData->stepSize);
        if (gbData->ctrl_method == GB_CTRL_CNST) {
          errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted since gbode is running with fixed step size!");
          messageClose(LOG_SOLVER);
          return -1;
        } else {
          if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
            gbData->err_slow = 0;
            gbData->err_fast = 0;
            gbData->err_int = 0;
            // dump fast states in file
            dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->stepSize, 3);
          }

          if (gbData->stepSize > GB_MINIMAL_STEP_SIZE) {
            // Try smaller steps, if possible.
            gbData->stepSize = gbData->stepSize / 2.;
            warningStreamPrint(LOG_SOLVER, 0, "Try half of the step size = %g", gbData->stepSize);
            err = 100;
            continue;
          } else {
            errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted because the step size is less then %g!", GB_MINIMAL_STEP_SIZE);
            messageClose(LOG_SOLVER);
            return -1;
          }
        }
      }

      // calculate corresponding values for error estimator and step size control (infinity norm)
      for (i = 0, err=0; i < nStates; i++) {
        gbData->errtol[i] = Rtol * fmax(fabs(gbData->y[i]), fabs(gbData->yOld[i])) + Atol;
        gbData->errest[i] = fabs(gbData->y[i] - gbData->yt[i]);
        gbData->err[i] = gbData->tableau->fac * gbData->errest[i] / gbData->errtol[i];
        err = fmax(err, gbData->err[i]);
      }

      if (ACTIVE_STREAM(LOG_GBODE_V))
      {
        sortedStates = (int *)malloc(sizeof(int) * nStates);
        memcpy(sortedStates, gbData->sortedStatesIdx, sizeof(int) * nStates);
      }

      // The error estimation of slow states will be below the threshold
      err_threshold = getErrorThreshold(gbData);
      err = err_threshold;

      if (ACTIVE_STREAM(LOG_GBODE_V))
      {
        for (int k = 0; k < nStates; k++)
          if (sortedStates[k] - gbData->sortedStatesIdx[k])
          {
            printIntVector_gb(LOG_GBODE_V, "sortedStates before:", sortedStates, nStates, gbData->time);
            printIntVector_gb(LOG_GBODE_V, "sortedStates after:", gbData->sortedStatesIdx, nStates, gbData->time);
            break;
          }
        free(sortedStates);
      }

      // Find fast and slow states based on the error threshold
      gbData->nFastStates = 0;
      gbData->nSlowStates = 0;
      gbData->err_slow = 0;
      gbData->err_fast = 0;
      gbData->err_int = 0;
      for (i = 0; i < gbData->nStates; i++) {
        if (gbData->err[i] >= 1) {
          gbData->fastStatesIdx[gbData->nFastStates] = i;
          gbData->nFastStates++;
          gbData->err_fast = fmax(gbData->err_fast, gbData->err[i]);
        } else {
          gbData->slowStatesIdx[gbData->nSlowStates] = i;
          gbData->nSlowStates++;
          gbData->err_slow = fmax(gbData->err_slow, gbData->err[i]);
        }
      }
      // err == threshold;
      // Rotate and update buffer
      for (i = (gbData->ringBufferSize - 1); i > 0 ; i--) {
        gbData->errValues[i] = gbData->errValues[i - 1];
        gbData->stepSizeValues[i] = gbData->stepSizeValues[i - 1];
      }
      // update new values
      gbData->errValues[0] = err;
      gbData->stepSizeValues[0] = gbData->stepSize;

      // Store performed step size for latter interpolation
      // Call the step size control
      gbData->lastStepSize = gbData->stepSize;
      gbData->stepSize *= gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);
      if (gbData->maxStepSize > 0 && gbData->maxStepSize < gbData->stepSize)
        gbData->stepSize = gbData->maxStepSize;

      // reject step, if error is too large
      if ((err > 1 ) && gbData->ctrl_method != GB_CTRL_CNST) {
        // count failed steps and output information on the solver status
        gbData->stats.nErrorTestFailures++;
        // debug the error of the states and derivatives after outer integration
        if (ACTIVE_STREAM(LOG_SOLVER_V)) {
          infoStreamPrint(LOG_SOLVER_V, 1, "Error of the states: threshold = %15.10g", err_threshold);
          printVector_gb(LOG_SOLVER_V, "y", gbData->y, nStates, gbData->time + gbData->lastStepSize);
          printVector_gb(LOG_SOLVER_V, "er", gbData->err, nStates, gbData->time + gbData->lastStepSize);
          messageClose(LOG_SOLVER_V);
        }
        infoStreamPrint(LOG_SOLVER, 0, "Reject step from %10g to %10g, error slow states %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->errValues[0], gbData->stepSize);

        if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
          // dump fast states in file
          gbData->err_slow = err;
          dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->lastStepSize, 1);
        }
        continue;
      }

      // store right hand values for latter interpolation
      gbData->timeRight = gbData->time + gbData->lastStepSize;
      memcpy(gbData->yRight, gbData->y, nStates * sizeof(double));
      // update kRight
      if (!gbData->tableau->isKRightAvailable) {
        sData->timeValue = gbData->timeRight;
        memcpy(sData->realVars, gbData->y, data->modelData->nStates * sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      }
      memcpy(gbData->kRight, fODE, nStates * sizeof(double));

      gbData->err_int = error_interpolation_gb(gbData, gbData->nSlowStates, gbData->slowStatesIdx, Rtol);

      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        // debug the changes of the state values during integration
        infoStreamPrint(LOG_GBODE_V, 1, "Interpolation error of slow states at midpoint:");
        printVector_gb(LOG_GBODE_V, "yL", gbData->yLeft, nStates, gbData->timeLeft);
        printVector_gb(LOG_GBODE_V, "kL", gbData->kLeft, nStates, gbData->timeLeft);
        printVector_gb(LOG_GBODE_V, "yR", gbData->yRight, nStates, gbData->timeRight);
        printVector_gb(LOG_GBODE_V, "kR", gbData->kRight, nStates, gbData->timeRight);
        printVector_gbf(LOG_GBODE_V, "e", gbData->errest, nStates, (gbData->timeLeft + gbData->timeRight)/2, gbData->nSlowStates, gbData->slowStatesIdx);
        messageClose(LOG_GBODE_V);
      }
      if (gbData->ctrl_method != GB_CTRL_CNST && ((gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL)  || (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL))) {
        if (gbData->err_int> err) {
          gbData->errValues[0] = gbData->err_int;
          gbData->stepSize = gbData->lastStepSize * gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);
          if (gbData->maxStepSize > 0 && gbData->maxStepSize < gbData->stepSize)
            gbData->stepSize = gbData->maxStepSize;
        }
      }
      // reject step, if interpolaton error is too large
      if (( gbData->nFastStates>0) && (gbData->err_int > 1 ) && gbData->ctrl_method != GB_CTRL_CNST &&
          ((gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL)  || (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL))) {
        err = 100;
        if (gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
          errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but interpolation error still to large.", GB_MINIMAL_STEP_SIZE);
          messageClose(LOG_SOLVER);
          return -1;
        }
        infoStreamPrint(LOG_SOLVER, 0, "Reject step from %10g to %10g, error slow states %10g, error interpolation %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->err_slow, gbData->err_int, gbData->stepSize);

        if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
          // dump fast states in file
          dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->lastStepSize, 2);
        }

        // count failed steps and output information on the solver status
        // gbData->errorTestFailures++;
        continue;
      }

      if (ACTIVE_STREAM(LOG_GBODE)) {
        // debug the changes of the state values during integration
        infoStreamPrint(LOG_GBODE, 1, "States and derivatives at right hand side:");
        printVector_gb(LOG_GBODE, "yR", gbData->yRight, nStates, gbData->timeRight);
        printVector_gb(LOG_GBODE, "kR", gbData->kRight, nStates, gbData->timeRight);
        messageClose(LOG_GBODE);
      }

      if (gbData->nFastStates > 0) {
        if (ACTIVE_STREAM(LOG_GBODE)) {
          // debug the error of the states and derivatives after outer integration
          infoStreamPrint(LOG_GBODE, 1, "Error of the states before inner integration: threshold = %15.10g", err_threshold);
          printVector_gb(LOG_GBODE, "er", gbData->err, nStates, gbData->timeRight);
          printIntVector_gb(LOG_GBODE, "sr", gbData->sortedStatesIdx, nStates, gbData->timeRight);
          messageClose(LOG_GBODE);
        }
        if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
          // dump fast states in file
          dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->lastStepSize, -1);
        }
        infoStreamPrint(LOG_SOLVER, 0, "Refine step from %10g to %10g, error fast states %10g, error interpolation %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->err_fast, error_interpolation_gb(gbData, nStates, NULL, Rtol), gbData->stepSize);
        // run multirate step
        gb_step_info = gbodef_main(data, threadData, solverInfo, targetTime);
        // synchronize relevant information
        if (fabs(gbData->timeRight - gbData->gbfData->timeRight) < GB_MINIMAL_STEP_SIZE) {
          memcpy(gbData->y, gbData->gbfData->y, nStates * sizeof(double));
          memcpy(gbData->yRight, gbData->gbfData->yRight, nStates * sizeof(double));
          memcpy(gbData->kRight, gbData->gbfData->kRight, nStates * sizeof(double));
          memcpy(gbData->err, gbData->gbfData->err, nStates * sizeof(double));
        }
        infoStreamPrint(LOG_SOLVER, 0, "Refined step from %10g to %10g, error fast states %10g, error interpolation %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->err_fast, error_interpolation_gb(gbData, nStates, NULL, Rtol), gbData->stepSize);
        if (gb_step_info !=0) {
          // get out of here, if an event has happend!
          messageClose(LOG_SOLVER);
          if (gb_step_info>0)
            return 0;
          else
            return gb_step_info;
        }
      }

      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        // debug the error of the states and derivatives after outer integration
        infoStreamPrint(LOG_GBODE_V, 1, "Error of the states: threshold = %15.10g", err_threshold);
        printVector_gb(LOG_GBODE_V, "er", gbData->err, nStates, gbData->timeRight);
        messageClose(LOG_GBODE_V);
      }

      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        // debug ring buffer for the states and derviatives of the states
        infoStreamPrint(LOG_GBODE_V, 1, "Ring buffer after inner steps of integration");
        infoStreamPrint(LOG_GBODE_V, 0, "Old value:");
        printVector_gb(LOG_GBODE_V, "y", gbData->yOld, nStates, gbData->time);
        debugRingBuffer(LOG_GBODE_V, gbData->x, gbData->k, nStates, gbData->tableau, gbData->time, gbData->lastStepSize);
        infoStreamPrint(LOG_GBODE_V, 0, "New value:");
        printVector_gb(LOG_GBODE_V, "y", gbData->y, nStates, gbData->time + gbData->lastStepSize);
        messageClose(LOG_GBODE_V);
      }
    } while ((err > 1) && gbData->ctrl_method != GB_CTRL_CNST);

    // count processed steps
    gbData->stats.nStepsTaken++;

    if (gbData->gbfData->time < gbData->time) {
      eventTime = checkForEvents(data, threadData, solverInfo, gbData->time, gbData->yOld, gbData->time + gbData->lastStepSize, gbData->y, FALSE, &foundEvent);
      if (foundEvent)
      {
        solverInfo->currentTime = eventTime;
        sData->timeValue = solverInfo->currentTime;

        // sData->realVars are the "numerical" values on the right hand side of the event
        gbData->time = eventTime;
        memcpy(gbData->yOld, sData->realVars, nStates * sizeof(double));

        gbData->gbfData->time = eventTime;
        memcpy(gbData->gbfData->yOld, sData->realVars, nStates * sizeof(double));

        /* write statistics to the solverInfo data structure */
        memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

        // log the emitted result
        if (ACTIVE_STREAM(LOG_GBODE)){
          infoStreamPrint(LOG_GBODE, 1, "Emit result (birate integration):");
          printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
          messageClose(LOG_GBODE);
        }

        if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
          // dump fast states in file
          dumpFastStates_gb(gbData, TRUE, eventTime, 0);
        }

        // return to solver main routine for proper event handling (iteration)
        messageClose(LOG_SOLVER);
        return 0;
      }
    }

    /* update time with performed stepSize */
    gbData->time += gbData->lastStepSize;

    // Rotate ring buffer
    for (i = (gbData->ringBufferSize - 1); i > 0 ; i--) {
      gbData->tv[i] =  gbData->tv[i - 1];
      memcpy(gbData->yv + i * nStates, gbData->yv + (i - 1) * nStates, nStates * sizeof(double));
      memcpy(gbData->kv + i * nStates, gbData->kv + (i - 1) * nStates, nStates * sizeof(double));
    }

    gbData->tv[0] = gbData->timeRight;
    memcpy(gbData->yv, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kv, gbData->kRight, nStates * sizeof(double));

    debugRingBufferSteps(LOG_GBODE, gbData->yv, gbData->kv, gbData->tv, nStates,  gbData->ringBufferSize);

    /* step is accepted and yOld needs to be updated */
    memcpy(gbData->yOld, gbData->y, gbData->nStates * sizeof(double));
    infoStreamPrint(LOG_SOLVER, 0, "Accept step from %10g to %10g, error slow states %10g, error interpolation %10g, new stepsize %10g",
                    gbData->time - gbData->lastStepSize, gbData->time, err, gbData->err_int, gbData->stepSize);

    if (ACTIVE_STREAM(LOG_GBODE_STATES)) {
      // dump fast states in file
      dumpFastStates_gb(gbData, FALSE, gbData->time, 0);
    }

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps && gbData->gbfData->time<gbData->time) {
      sData->timeValue = gbData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbData->y, nStates * sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
      // log the emitted result
      if (ACTIVE_STREAM(LOG_GBODE)){
        infoStreamPrint(LOG_GBODE, 1, "Emit result (birate integration):");
        printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
        messageClose(LOG_GBODE);
      }
    }

    if ((stopTime - gbData->time) < GB_MINIMAL_STEP_SIZE)
    {
      gbData->time = stopTime;
      break;
    }
    // reduce step size with respect to the simulation stop time or nextSampleEvent time, if necessary
    gbData->stepSize = fmin(gbData->stepSize, data->simulationInfo->nextSampleEvent - gbData->time);
    gbData->stepSize = fmin(gbData->stepSize, stopTime - gbData->time);
  }
  // end of while-loop (gbData->time < targetTime)

  if (!solverInfo->integratorSteps) {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;

    // if the inner integration has not been started, the outer values need to be emitted
    if (gbData->gbfData->time >= sData->timeValue) {
      gb_interpolation(gbData->interpolation,
                       gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                       gbData->timeRight, gbData->yRight, gbData->kRight,
                       sData->timeValue,  sData->realVars,
                       gbData->nSlowStates, gbData->slowStatesIdx,  nStates, gbData->tableau, gbData->x, gbData->k);
    } else {
      gb_interpolation(gbData->interpolation,
                       gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                       gbData->timeRight, gbData->yRight, gbData->kRight,
                       sData->timeValue,  sData->realVars,
                       nStates, NULL,  nStates, gbData->tableau, gbData->x, gbData->k);
    }
    // log the emitted result
    if (ACTIVE_STREAM(LOG_GBODE)){
      infoStreamPrint(LOG_GBODE, 1, "Emit result (birate integration):");
      printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
      messageClose(LOG_GBODE);
    }
  } else {
    // Integrator emits result on the simulation grid (see above)
    sData->timeValue = gbData->time;
    solverInfo->currentTime = sData->timeValue;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  data->simulationInfo->sampleActivated =    data->simulationInfo->sampleActivated
                                          && solverInfo->currentTime >= data->simulationInfo->nextSampleEvent;

  /* Solver statistics */
  if (!gbData->isExplicit)
    gbData->stats.nCallsJacobian = gbData->nlsData->numberOfJEval;

  if (fabs(targetTime - stopTime) < GB_MINIMAL_STEP_SIZE && ACTIVE_STREAM(LOG_STATS)) {
    infoStreamPrint(LOG_STATS, 0, "gbode (birate integration): slow: %s / fast: %s",
                    GB_METHOD_NAME[gbData->GM_method], GB_METHOD_NAME[gbData->gbfData->GM_method]);
    logSolverStats(LOG_STATS, "inner integration", stopTime, stopTime, 0, &gbData->gbfData->stats);
    logSolverStats(LOG_STATS, "outer integration", stopTime, stopTime, 0, &gbData->stats);
  }
  /* Write statistics to the solverInfo data structure */
  logSolverStats(LOG_SOLVER_V, "gb_singlerate", solverInfo->currentTime, gbData->time, gbData->stepSize, &gbData->stats);
  memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

  messageClose(LOG_SOLVER);
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
int gbode_singlerate(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;

  double stopTime = data->simulationInfo->stopTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = Atol;

  int nStates = gbData->nStates;
  int nStages = gbData->tableau->nStages;

  double targetTime, eventTime, err;

  int gb_step_info;
  int i;
  modelica_boolean foundEvent;

  // root finding will be done in gbode after each accepted step
  solverInfo->solverRootFinding = 1;

  /* Calculate steps until targetTime is reached */
  // 1 => emit result at integrator step points; 0 => equidistant grid
  if (solverInfo->integratorSteps) {
    if (data->simulationInfo->nextSampleEvent < data->simulationInfo->stopTime) {
      targetTime = data->simulationInfo->nextSampleEvent;
    } else {
      targetTime = data->simulationInfo->stopTime;
    }
  } else {
    targetTime = solverInfo->currentTime + solverInfo->currentStepSize;
  }
  infoStreamPrint(LOG_SOLVER, 1, "Start gbode (single-rate integration)  from %g to %g",
                  solverInfo->currentTime, targetTime);

  // (Re-)initialize after events or at first call of gbode_sinlerate
  if (solverInfo->didEventStep || gbData->isFirstStep) {
    if (gbData->noRestart && !gbData->isFirstStep) {
      // just continue, if -noRestart is set
      gbData->time = gbData->timeRight;
      gbData->stepSize = gbData->optStepSize;
      infoStreamPrint(LOG_SOLVER, 0, "Initial step size = %e at time %g", gbData->stepSize, gbData->time);
    } else {
      // calculate initial step size and reset ring buffer and statistic counters
      // initialize gbData->timeRight, gbData->yRight and gbData->kRight
      getInitStepSize(data, threadData, gbData);
      gbode_init(data, threadData, solverInfo);
    }
    gbData->isFirstStep = FALSE;
    solverInfo->didEventStep = FALSE;
  }

  debugRingBufferSteps(LOG_GBODE, gbData->yv, gbData->kv, gbData->tv, nStates,  gbData->ringBufferSize);

  // Constant step size
  if (gbData->ctrl_method == GB_CTRL_CNST) {
    gbData->stepSize = solverInfo->currentStepSize;
  }

  /* Main integration loop, if gbData->time already greater than targetTime, only the
     interpolation is necessary for emitting the output variables (see below) */
  while (gbData->time < targetTime)
  {
    // store left hand data for later interpolation
    gbData->timeLeft = gbData->timeRight;
    memcpy(gbData->yLeft, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kLeft, gbData->kRight, nStates * sizeof(double));

    if (ACTIVE_STREAM(LOG_GBODE)) {
      // debug the changes of the states and derivatives during integration
      infoStreamPrint(LOG_GBODE, 1, "States and derivatives at left hand side:");
      printVector_gb(LOG_GBODE, "yL", gbData->yLeft, nStates, gbData->timeLeft);
      printVector_gb(LOG_GBODE, "kL", gbData->kLeft, nStates, gbData->timeLeft);
      messageClose(LOG_GBODE);
    }

    // Loop will be performed until the error estimate for all states fullfills the
    // given tolerance
    do
    {
      if (ACTIVE_STREAM(LOG_SOLVER_V)) {
        // debug ring buffer of the states and derivatives during integration
        infoStreamPrint(LOG_SOLVER_V, 1, "States and derivatives of the ring buffer:");
        for (int i=0; i<gbData->ringBufferSize; i++) {
          printVector_gb(LOG_SOLVER_V, "y", gbData->yv + i * nStates, nStates, gbData->tv[i]);
          printVector_gb(LOG_SOLVER_V, "k", gbData->kv + i * nStates, nStates, gbData->tv[i]);
        }
        messageClose(LOG_SOLVER_V);
      }

      // do one integration step resulting in two different approximations
      // results are stored in gbData->y and gbData->yt
      if (gbData->tableau->richardson) {
        gb_step_info = gbode_richardson(data, threadData, solverInfo);
      } else {
        gb_step_info = gbData->step_fun(data, threadData, solverInfo);
      }

      // debug the approximations after performed step
      if (ACTIVE_STREAM(LOG_GBODE)) {
        infoStreamPrint(LOG_GBODE, 1, "Approximations after step calculation:");
        printVector_gb(LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
        printVector_gb(LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
        messageClose(LOG_GBODE);
      }

      // error handling: try half of the step size!
      if (gb_step_info != 0) {
        gbData->stats.nConvergenveTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "gbode_main: Failed to calculate step at time = %5g.", gbData->time + gbData->stepSize);
        if (gbData->ctrl_method == GB_CTRL_CNST) {
          errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted since gbode is running with fixed step size!");
          messageClose(LOG_SOLVER);
          return -1;
        } else {
          gbData->stepSize *= 0.5;
          infoStreamPrint(LOG_SOLVER, 0, "Try half of the step size = %g", gbData->stepSize);
          if (gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
            errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but error still to large.", GB_MINIMAL_STEP_SIZE);
            messageClose(LOG_SOLVER);
            return -1;
          }
          err = 100;
          continue;
        }
      }

      // calculate corresponding values for error estimator and step size control (infinity norm)
      for (i = 0, err=0; i < nStates; i++) {
        gbData->errtol[i] = Rtol * fmax(fabs(gbData->y[i]), fabs(gbData->yOld[i])) + Atol;
        gbData->errest[i] = fabs(gbData->y[i] - gbData->yt[i]);
        gbData->err[i] = gbData->tableau->fac * gbData->errest[i] / gbData->errtol[i];
        err = fmax(err, gbData->err[i]);
      }

      // Rotate buffer
      for (i = (gbData->ringBufferSize - 1); i > 0 ; i--) {
        gbData->errValues[i] = gbData->errValues[i - 1];
        gbData->stepSizeValues[i] = gbData->stepSizeValues[i - 1];
      }
      // update new values
      gbData->errValues[0] = err;
      gbData->stepSizeValues[0] = gbData->stepSize;

      // Store performed step size for latter interpolation
      // Call the step size control
      gbData->lastStepSize = gbData->stepSize;
      gbData->stepSize *= gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);
      if (gbData->maxStepSize > 0 && gbData->maxStepSize < gbData->stepSize)
        gbData->stepSize = gbData->maxStepSize;
      gbData->optStepSize = gbData->stepSize;

      // reject step, if error is too large
      if ((err > 1) && gbData->ctrl_method != GB_CTRL_CNST) {
        // count failed steps and output information on the solver status
        gbData->stats.nErrorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "Reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->errValues[0], gbData->stepSize);
      }

      // store right hand values for latter interpolation
      gbData->timeRight = gbData->time + gbData->lastStepSize;
      memcpy(gbData->yRight, gbData->y, nStates * sizeof(double));
      // update kRight
      if (!gbData->tableau->isKRightAvailable) {
        sData->timeValue = gbData->timeRight;
        memcpy(sData->realVars, gbData->y, data->modelData->nStates * sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      }
      memcpy(gbData->kRight, fODE, nStates * sizeof(double));

      if (ACTIVE_STREAM(LOG_SOLVER) || (gbData->ctrl_method != GB_CTRL_CNST && ((gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL)  || (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL)))) {
        gbData->err_int = error_interpolation_gb(gbData, nStates, NULL, Rtol);
      }
      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        // debug the changes of the state values during integration
        infoStreamPrint(LOG_GBODE_V, 1, "Interpolation error of slow states at midpoint:");
        printVector_gb(LOG_GBODE_V, "yL", gbData->yLeft, nStates, gbData->timeLeft);
        printVector_gb(LOG_GBODE_V, "kL", gbData->kLeft, nStates, gbData->timeLeft);
        printVector_gb(LOG_GBODE_V, "yR", gbData->yRight, nStates, gbData->timeRight);
        printVector_gb(LOG_GBODE_V, "kR", gbData->kRight, nStates, gbData->timeRight);
        printVector_gbf(LOG_GBODE_V, "e", gbData->errest, nStates, (gbData->timeLeft + gbData->timeRight)/2, gbData->nSlowStates, gbData->slowStatesIdx);
        messageClose(LOG_GBODE_V);
      }
      if (gbData->ctrl_method != GB_CTRL_CNST && ((gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL)  || (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL))) {
        if (gbData->err_int> err) {
          gbData->errValues[0] = gbData->err_int;
          gbData->stepSize = gbData->lastStepSize * gbData->stepSize_control(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order);
          if (gbData->maxStepSize > 0 && gbData->maxStepSize < gbData->stepSize)
            gbData->stepSize = gbData->maxStepSize;
        }
        gbData->optStepSize = gbData->stepSize;
      }
      // reject step, if interpolaton error is too large
      if ((gbData->err_int > 1 ) && gbData->ctrl_method != GB_CTRL_CNST &&
          ((gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL)  || (gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL))) {
        err = 100;
        // gbData->stepSize = gbData->lastStepSize*IController(&(gbData->err_int), &(gbData->lastStepSize), 1);
        if (gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
          errorStreamPrint(LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but interpolation error still to large.", GB_MINIMAL_STEP_SIZE);
          messageClose(LOG_SOLVER);
          return -1;
        }
        infoStreamPrint(LOG_SOLVER, 0, "Reject step from %10g to %10g, interpolation error %10g, new stepsize %10g",
                        gbData->time, gbData->time + gbData->lastStepSize, gbData->err_int, gbData->stepSize);
        // count failed steps and output information on the solver status
        // gbData->errorTestFailures++;
        continue;
      }

      // debug ring buffer for the states and derviatives of the states at RK points
      if (ACTIVE_STREAM(LOG_GBODE_V)) {
        infoStreamPrint(LOG_GBODE_V, 1, "Ring buffer during steps of integration");
        infoStreamPrint(LOG_GBODE_V, 0, "Old value:");
        printVector_gb(LOG_GBODE_V, "y", gbData->yOld, nStates, gbData->time);
        debugRingBuffer(LOG_GBODE_V, gbData->x, gbData->k, nStates, gbData->tableau, gbData->time, gbData->lastStepSize);
        infoStreamPrint(LOG_GBODE_V, 0, "New value:");
        printVector_gb(LOG_GBODE_V, "y", gbData->y, nStates, gbData->time + gbData->lastStepSize);
        messageClose(LOG_GBODE_V);
      }
    } while ((err > 1) && gbData->ctrl_method != GB_CTRL_CNST);

    // count processed steps
    gbData->stats.nStepsTaken++;

    // debug the changes of the state values during integration
    if (ACTIVE_STREAM(LOG_GBODE)) {
      infoStreamPrint(LOG_GBODE, 1, "States and derivatives at right hand side:");
      printVector_gb(LOG_GBODE, "yR", gbData->yRight, nStates, gbData->timeRight);
      printVector_gb(LOG_GBODE, "kR", gbData->kRight, nStates, gbData->timeRight);
      messageClose(LOG_GBODE);
    }

    /* update time with performed stepSize */
    gbData->time += gbData->lastStepSize;
    gbData->timeDense = gbData->time;

    /* step is accepted and yOld needs to be updated */
    memcpy(gbData->yOld, gbData->y, nStates * sizeof(double));

    // Rotate buffer
    for (i = (gbData->ringBufferSize - 1); i > 0 ; i--) {
      gbData->tv[i] =  gbData->tv[i - 1];
      memcpy(gbData->yv + i * nStates, gbData->yv + (i - 1) * nStates, nStates * sizeof(double));
      memcpy(gbData->kv + i * nStates, gbData->kv + (i - 1) * nStates, nStates * sizeof(double));
    }

    // update new values
    gbData->tv[0] = gbData->timeRight;
    memcpy(gbData->yv, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kv, gbData->kRight, nStates * sizeof(double));

    debugRingBufferSteps(LOG_GBODE, gbData->yv, gbData->kv, gbData->tv, nStates,  gbData->ringBufferSize);

    // check for events, if event is detected stop integrator and trigger event iteration
    eventTime = checkForEvents(data, threadData, solverInfo, gbData->timeLeft, gbData->yLeft, gbData->timeRight, gbData->yRight, FALSE, &foundEvent);
    if (foundEvent) {
      if (eventTime < targetTime + solverInfo->currentStepSize/2)
      {
        solverInfo->currentTime = eventTime;
        sData->timeValue = eventTime;

        // sData->realVars are the "numerical" values on the right hand side of the event (hopefully)
        if (!gbData->noRestart) {
          gbData->time = eventTime;
          memcpy(gbData->yOld, sData->realVars, gbData->nStates * sizeof(double));
        }

        /* write statistics to the solverInfo data structure */
        memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

        // log the emitted result
        if (ACTIVE_STREAM(LOG_GBODE)){
          infoStreamPrint(LOG_GBODE, 1, "Emit result (single-rate integration):");
          printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
          messageClose(LOG_GBODE);
        }
        // return to solver main routine for proper event handling (iteration)
        messageClose(LOG_SOLVER);
        return 0;
      } else {
        // ToDo: If the solver does large steps and finds an event, the interpolation is
        // done in solver_main (linearly) and therefore the states are not very well approximated.
        // Current solution: Step back to the communication interval before the event and event detection
        // needs to be repeated
        listClear(solverInfo->eventLst);
        gbData->lastStepSize = (eventTime - solverInfo->currentStepSize/2) - gbData->timeLeft;
        sData->timeValue = (eventTime - solverInfo->currentStepSize/2);
        gb_interpolation(gbData->interpolation,
                        gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                        gbData->timeRight, gbData->yRight, gbData->kRight,
                                sData->timeValue,  sData->realVars,
                        nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
        memcpy(gbData->yOld, sData->realVars, gbData->nStates * sizeof(double));
        gbData->timeRight = sData->timeValue;
        gbData->time = gbData->timeRight;
        memcpy(gbData->yRight, sData->realVars, gbData->nStates * sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
        memcpy(gbData->kRight, fODE, nStates * sizeof(double));
      }
    }

    infoStreamPrint(LOG_SOLVER, 0, "Accept step from %10g to %10g, error %10g interpolation error %10g, new stepsize %10g",
                    gbData->timeLeft, gbData->timeRight, err, gbData->err_int, gbData->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      solverInfo->currentTime = sData->timeValue;
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
      // log the emitted result
      if (ACTIVE_STREAM(LOG_GBODE)){
        infoStreamPrint(LOG_GBODE, 1, "Emit result (single-rate integration):");
        printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
        messageClose(LOG_GBODE);
      }
    }

    // stop, if simulation nearly reached stopTime
    if ((stopTime - gbData->time) < GB_MINIMAL_STEP_SIZE) {
      gbData->time = stopTime;
      break;
    }

    // reduce step size with respect to the simulation stop time, if necessary
    gbData->stepSize = fmin(gbData->stepSize, stopTime - gbData->time);
  }
  // end of while-loop (gbData->time < targetTime)

  if (!solverInfo->integratorSteps) {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    solverInfo->currentTime = sData->timeValue;

    // use chosen interpolation for emitting equidistant output (default hermite)
    if (solverInfo->currentStepSize > 0) {
      if (gbData->timeDense > gbData->timeRight && (gbData->interpolation == GB_DENSE_OUTPUT || gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL))
      {
        /* This case is needed, if an event has been detected during a large step (gbData->timeDense) of the integration
        * and the integrator (gbData->timeRight) has been set back to the time just before the event. In this case the
        * values in gbData->x and gbData->k are correct for the overall time intervall from gbData->timeLeft to gbData->timeDense */
        gb_interpolation(gbData->interpolation,
                    gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                    gbData->timeDense, gbData->yRight, gbData->kRight,
                    sData->timeValue,  sData->realVars,
                    nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
      } else {
        gb_interpolation(gbData->interpolation,
                    gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                    gbData->timeRight, gbData->yRight, gbData->kRight,
                    sData->timeValue,  sData->realVars,
                    nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
      }
    }
    // log the emitted result
    if (ACTIVE_STREAM(LOG_GBODE)){
      infoStreamPrint(LOG_GBODE, 1, "Emit result (single-rate integration):");
      printVector_gb(LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
      messageClose(LOG_GBODE);
    }
  } else {
    // Integrator emits result on the simulation grid (see above)
    sData->timeValue = gbData->time;
    solverInfo->currentTime = gbData->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  data->simulationInfo->sampleActivated =    data->simulationInfo->sampleActivated
                                          && solverInfo->currentTime >= data->simulationInfo->nextSampleEvent;

  /* Solver statistics */
  if (!gbData->isExplicit)
    gbData->stats.nCallsJacobian = gbData->nlsData->numberOfJEval;
  if (fabs(targetTime - stopTime) < GB_MINIMAL_STEP_SIZE && ACTIVE_STREAM(LOG_STATS)) {
    infoStreamPrint(LOG_STATS, 0, "gbode (single-rate integration): %s", GB_METHOD_NAME[gbData->GM_method]);
  }
  /* Write statistics to the solverInfo data structure */
  logSolverStats(LOG_SOLVER_V, "gb_singlerate", solverInfo->currentTime, gbData->time, gbData->stepSize, &gbData->stats);
  memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

  messageClose(LOG_SOLVER);
  return 0;
}

/**
 * @brief
 *
 * @param data
 * @param threadData
 * @param solverInfo
 * @return int
 */
int gbode_main(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;

  if (gbData->multi_rate) {
    return gbode_birate(data, threadData, solverInfo);
  } else {
    return gbode_singlerate(data, threadData, solverInfo);
  }
}
