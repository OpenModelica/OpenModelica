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
#include "kinsolSolver.h"
#include "kinsol_b.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "omc_math.h"
#include "../options.h"
#include "../results/simulation_result.h"
#include "../jacobian_util.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "../../util/simulation_options.h"
#include "epsilon.h"

extern void communicateStatus(const char *phase, double completionPercent, double currentTime, double currentStepSize);

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

  JACOBIAN *jacobian = NULL;
  int i;

  gbfData->nStates = gbData->nStates;

  gbfData->GM_method = getGB_method(FLAG_MR);
  gbfData->tableau = initButcherTableau(gbfData->GM_method, FLAG_MR_ERR);
  if (gbfData->tableau == NULL) {
    // ERROR
    messageClose(OMC_LOG_STDOUT);
    omc_throw_function(threadData);
  }

  // Get size of non-linear system
  analyseButcherTableau(gbfData->tableau, gbData->nStates, &gbfData->nlSystemSize, &gbfData->type);

  if (gbfData->GM_method == MS_ADAMS_MOULTON) {
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

  infoStreamPrint(OMC_LOG_SOLVER, 0, "Step control factor is set to %g", gbfData->tableau->fac);

  gbfData->ctrl_method = getControllerMethod(FLAG_MR_CTRL);
  if (gbfData->ctrl_method == GB_CTRL_CNST) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Constant step size not supported for inner integration. Using IController.");
    gbfData->ctrl_method = GB_CTRL_I;
  }

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
  for (int i = 0; i < gbData->nStates; i++) {
    gbfData->fastStates_old[i] = i;
  }

  printButcherTableau(gbfData->tableau);

  /* initialize analytic Jacobian, if available and needed */
  if (!gbfData->isExplicit) {
    // Allocate Jacobian, if !gbfData->isExplcit and gbData->isExplicit
    // Free is done in gbode_freeData
    if (gbData->isExplicit) {
      jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
      data->callback->initialAnalyticJacobianA(data, threadData, jacobian);
      if (jacobian->availability == JACOBIAN_AVAILABLE || jacobian->availability == JACOBIAN_ONLY_SPARSITY) {
        infoStreamPrint(OMC_LOG_SOLVER, 1, "Initialized Jacobian:");
        infoStreamPrint(OMC_LOG_SOLVER, 0, "columns: %zu rows: %zu", jacobian->sizeCols, jacobian->sizeRows);
        infoStreamPrint(OMC_LOG_SOLVER, 0, "NNZ:  %u colors: %u", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
        messageClose(OMC_LOG_SOLVER);
      }

      // Compare user flag to availabe Jacobian methods
      const char* flagValue;
      if (omc_flag[FLAG_JACOBIAN]) {
        flagValue = omc_flagValue[FLAG_JACOBIAN];
      } else {
        flagValue = NULL;
      }
      JACOBIAN_METHOD jacobianMethod = setJacobianMethod(threadData, jacobian->availability, flagValue);

      gbfData->symJacAvailable = jacobian->availability == JACOBIAN_AVAILABLE;
      // change GBODE specific jacobian method
      if (jacobianMethod == SYMJAC) {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobians without coloring are currently not supported by GBODE."
                                          " Colored symbolical Jacobian will be used.");
      } else if(jacobianMethod == NUMJAC || jacobianMethod == COLOREDNUMJAC || jacobianMethod == INTERNALNUMJAC) {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "Numerical Jacobians without coloring are currently not supported by GBODE."
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
    if (!gbfData->nlsData) {
      return -1;
    }
    gbfData->sparsePattern_DIRK = initializeSparsePattern_SR(data, gbfData->nlsData);
  } else {
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
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Linear interpolation is used for emitting results");
    break;
  case GB_INTERPOL_HERMITE:
  case GB_INTERPOL_HERMITE_a:
  case GB_INTERPOL_HERMITE_b:
  case GB_INTERPOL_HERMITE_ERRCTRL:
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Hermite interpolation is used for the slow states");
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Dense output is used for emitting results");
    break;
  default:
    throwStreamPrint(NULL, "Unhandled interpolation case.");
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
    char filename[4096];
    unsigned int bufSize = 4096;
    snprintf(filename, bufSize, "%s_ActiveStates.txt", data->modelData->modelFilePrefix);
    gbfData->fastStatesDebugFile = omc_fopen(filename, "w");
    warningStreamPrint(OMC_LOG_STDOUT, 0, "LOG_GBODE_STATES sets -noEquidistantTimeGrid for emitting results!");
    solverInfo->solverNoEquidistantGrid = TRUE;
  } else {
    gbfData->fastStatesDebugFile = NULL;
  }
  i = fmin(fmax(round(gbData->nStates * gbData->percentage), 1), gbData->nStates - 1);
  infoStreamPrint(OMC_LOG_SOLVER, 0, "Number of states %d (%d slow states, %d fast states)", gbData->nStates, gbData->nStates-i, i);

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

  JACOBIAN* jacobian = NULL;

  gbData->GM_method = getGB_method(FLAG_SR);
  gbData->tableau = initButcherTableau(gbData->GM_method, FLAG_SR_ERR);
  if (gbData->tableau == NULL) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "allocateDataGm: Failed to initialize gbode tableau for method %s", GB_METHOD_NAME[gbData->GM_method]);
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

  // detect controller method
  gbData->ctrl_method = getControllerMethod(FLAG_SR_CTRL);
  use_fhr = omc_flag[FLAG_SR_CTRL_FHR];
  use_filter = getGBCtrlFilterValue();

   /* define maximum step size gbode is allowed to go */
  if (omc_flag[FLAG_MAX_STEP_SIZE]) {
    gbData->maxStepSize = atof(omc_flagValue[FLAG_MAX_STEP_SIZE]);
    if (gbData->maxStepSize < 0 || gbData->maxStepSize > DBL_MAX/2) {
      throwStreamPrint(NULL, "maximum step size %g is not allowed", gbData->maxStepSize);
    } else {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "maximum step size %g", gbData->maxStepSize);
    }
  } else {
    gbData->maxStepSize = -1;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "maximum step size not set");
  }
    /* Initial step size */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE]) {
    gbData->initialStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);
    if (gbData->initialStepSize < GB_MINIMAL_STEP_SIZE || gbData->initialStepSize > DBL_MAX/2) {
      throwStreamPrint(NULL, "initial step size %g is not allowed, minimal step size is %g", gbData->initialStepSize, GB_MINIMAL_STEP_SIZE);
    } else {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "initial step size %g", gbData->initialStepSize);
    }
  } else {
    gbData->initialStepSize = -1; /* use default */
    infoStreamPrint(OMC_LOG_SOLVER, 0, "initial step size not set");
  }

 /* if FLAG_NO_RESTART is set, configure gbode */
  gbData->noRestart = omc_flag[FLAG_NO_RESTART];

  gbData->eventTime = DBL_MAX;

  infoStreamPrint(OMC_LOG_SOLVER, 0, "gbode performs a restart after an event occurs %s", gbData->noRestart?"NO":"YES");

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
  gbData->y2        = malloc(sizeof(double) * gbData->nStates);
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
      infoStreamPrint(OMC_LOG_SOLVER, 1, "Initialized Jacobian:");
      infoStreamPrint(OMC_LOG_SOLVER, 0, "columns: %zu rows: %zu", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(OMC_LOG_SOLVER, 0, "NNZ:  %u colors: %u", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(OMC_LOG_SOLVER);
    }

    // Compare user flag to availabe Jacobian methods
    const char* flagValue;
    if(omc_flag[FLAG_JACOBIAN]){
      flagValue = omc_flagValue[FLAG_JACOBIAN];
    } else {
      flagValue = NULL;
    }
    JACOBIAN_METHOD jacobianMethod = setJacobianMethod(threadData, jacobian->availability, flagValue);

    gbData->symJacAvailable = jacobian->availability == JACOBIAN_AVAILABLE;
    // change GBODE specific jacobian method
    if (jacobianMethod == SYMJAC) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Symbolic Jacobians without coloring are currently not supported by GBODE."
                                        " Colored symbolical Jacobian will be used.");
    } else if (jacobianMethod == NUMJAC || jacobianMethod == COLOREDNUMJAC || jacobianMethod == INTERNALNUMJAC) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Numerical Jacobians without coloring are currently not supported by GBODE."
                                        " Colored numerical Jacobian will be used.");
      gbData->symJacAvailable = FALSE;
    }

    /* Allocate memory for the nonlinear solver */
    gbData->nlsSolverMethod = getGB_NLS_method(FLAG_SR_NLS);
    gbData->nlsData = initRK_NLS_DATA(data, threadData, gbData);
    if (!gbData->nlsData) {
      return -1;
    } else {
      infoStreamPrint(OMC_LOG_SOLVER, 1, "Nominal values of  the states:");
      for (int i = 0; i < gbData->nStates; i++) {
        infoStreamPrint(OMC_LOG_SOLVER, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbData->nlsData->nominal[i]);
      }
      messageClose(OMC_LOG_SOLVER);
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
    // TODO memcpy() faster?
    gbData->fastStatesIdx[i] = i;
    gbData->slowStatesIdx[i] = i;
    gbData->sortedStatesIdx[i] = i;
  }

  if (gbData->multi_rate && omc_flagValue[FLAG_SR_INT]==NULL) {
    gbData->interpolation = GB_DENSE_OUTPUT;
  } else {
    gbData->interpolation = getInterpolationMethod(FLAG_SR_INT);
  }

  if (!gbData->tableau->withDenseOutput) {
    switch (gbData->interpolation) {
    case GB_DENSE_OUTPUT:         gbData->interpolation = GB_INTERPOL_HERMITE; break;
    case GB_DENSE_OUTPUT_ERRCTRL: gbData->interpolation = GB_INTERPOL_HERMITE_ERRCTRL; break;
    default: break;
    }
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
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Linear interpolation is used for emitting results%s", buffer);
    break;
  case GB_INTERPOL_HERMITE_ERRCTRL:
  case GB_INTERPOL_HERMITE_a:
  case GB_INTERPOL_HERMITE_b:
  case GB_INTERPOL_HERMITE:
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Hermite interpolation is used for emitting results%s", buffer);
    break;
  case GB_DENSE_OUTPUT:
  case GB_DENSE_OUTPUT_ERRCTRL:
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Dense output is used for emitting results%s", buffer);
    break;
  default:
    throwStreamPrint(NULL, "Unhandled interpolation case.");
  }
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
  freeJacobian(gbfData->jacobian);
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

  return;
}

/**
 * @brief Free generic RK data.
 *
 * @param gbData    Pointer to generik Runge-Kutta data struct.
 */
void gbode_freeData(DATA* data, DATA_GBODE *gbData)
{
  JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  freeJacobian(jacobian);

  /* Free non-linear system data */
  freeRK_NLS_DATA(gbData->nlsData);

  /* Free Jacobian */
  freeJacobian(gbData->jacobian);
  free(gbData->jacobian); gbData->jacobian = NULL;

  /* Free Butcher tableau */
  freeButcherTableau(gbData->tableau);

  if (gbData->multi_rate)
  {
    gbodef_freeData(gbData->gbfData);
    gbData->gbfData = NULL;
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
  free(gbData->y2);
  free(gbData->f);
  free(gbData->k);
  free(gbData->x);
  free(gbData->res_const);
  free(gbData->errest);
  free(gbData->errtol);

  free(gbData);

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
  gbfData->stepSize = 0.1*gbData->stepSize*GenericController(&(gbData->err_fast), &(gbData->stepSize), 1, GB_CTRL_I);

  memcpy(gbfData->yOld, gbData->yOld, sizeof(double) * nStates);
  memcpy(gbfData->y, gbData->y, sizeof(double) * nStates);

  gbfData->timeRight = gbData->timeLeft;
  memcpy(gbfData->yRight, gbData->yLeft, sizeof(double) * nStates);
  memcpy(gbfData->kRight, gbData->kLeft, sizeof(double) * nStates);

  // set solution ring buffer (extrapolation in case of NLS)
  for (i = 0; i < gbfData->ringBufferSize; i++) {
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
  // TODO memset() faster?
  for (i = 0; i < gbData->ringBufferSize; i++) {
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
  for (i = 0; i < gbData->ringBufferSize; i++) {
    gbData->tv[i] = gbData->timeRight;
    memcpy(gbData->yv + i * nStates, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kv + i * nStates, gbData->kRight, nStates * sizeof(double));
  }
  gbData->eventTime = DBL_MAX; // reset event time
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
  const double innerTargetTime = fmin(targetTime, gbData->timeRight);

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

    infoStreamPrint(OMC_LOG_GBODE, 1, "Fast states and corresponding nominal values:");
    for (ii = 0; ii < nFastStates; ii++) {
      i = gbData->fastStatesIdx[ii];
      // Get the nominal values of the fast states
      gbfData->nlsData->nominal[ii] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32);
      infoStreamPrint(OMC_LOG_GBODE, 0, "%s = %g", data->modelData->realVarsData[i].info.name, gbfData->nlsData->nominal[ii]);
    }
    messageClose(OMC_LOG_GBODE);

    if (gbfData->nlsData->isPatternAvailable) {
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
        solverData->ordinaryData = (void*) nlsKinsolAllocate(gbfData->nlsData->size, nlsUserData, FALSE, gbfData->nlsData->isPatternAvailable);
        break;
      case GB_NLS_KINSOL_B:
        B_nlsKinsolFree(solverData->ordinaryData);
        /* Set NLS user data */
        NLS_USERDATA* B_nlsUserData = initNlsUserData(data, threadData, -1, gbfData->nlsData, gbfData->jacobian);
        B_nlsUserData->solverData = (void*) gbfData;
        solverData->ordinaryData = (void*) B_nlsKinsolAllocate(gbfData->nlsData->size, B_nlsUserData, FALSE, gbfData->nlsData->isPatternAvailable);
        break;
      default:
        throwStreamPrint(NULL, "NLS method %s not yet implemented.", GB_NLS_METHOD_NAME[gbfData->nlsSolverMethod]);
      }
    }
  }

  // print informations on the calling details
  infoStreamPrint(OMC_LOG_SOLVER, 1, "gbodef solver started (fast states/states): %d/%d", gbData->nFastStates,gbData->nStates);
  printIntVector_gb(OMC_LOG_SOLVER, "fast States:", gbData->fastStatesIdx, gbData->nFastStates, gbfData->time);
  infoStreamPrint(OMC_LOG_SOLVER, 0, "interpolation is done between %10g to %10g (SR-stepsize: %10g)",
                  gbData->timeLeft, gbData->timeRight, gbData->lastStepSize);

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
    infoStreamPrint(OMC_LOG_GBODE_V, 1, "Interpolation values from outer integration:");
    printVector_gb(OMC_LOG_GBODE_V, "yL", gbData->yLeft, gbData->nStates, gbData->timeLeft);
    printVector_gb(OMC_LOG_GBODE_V, "kL", gbData->kLeft, gbData->nStates, gbData->timeLeft);
    printVector_gb(OMC_LOG_GBODE_V, "yR", gbData->yRight, gbData->nStates, gbData->timeRight);
    printVector_gb(OMC_LOG_GBODE_V, "kR", gbData->kRight, gbData->nStates, gbData->timeRight);
    messageClose(OMC_LOG_GBODE_V);
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
      //   messageClose(OMC_LOG_SOLVER);
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
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      infoStreamPrint(OMC_LOG_GBODE, 1, "states and derivatives at left hand side (inner integration):");
      printVector_gbf(OMC_LOG_GBODE, "yL", gbfData->yLeft, nStates, gbfData->timeLeft, gbData->nFastStates, gbData->fastStatesIdx);
      printVector_gbf(OMC_LOG_GBODE, "kL", gbfData->kLeft, nStates, gbfData->timeLeft, gbData->nFastStates, gbData->fastStatesIdx);
      messageClose(OMC_LOG_GBODE);
    }

    do {
      if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V)) {
        infoStreamPrint(OMC_LOG_SOLVER_V, 1, "States and derivatives of the ring buffer:");
        for (int i = 0; i < gbfData->ringBufferSize; i++) {
          printVector_gbf(OMC_LOG_SOLVER_V, "y", gbfData->yv + i * nStates, nStates, gbfData->tv[i], gbData->nFastStates, gbData->fastStatesIdx);
          printVector_gbf(OMC_LOG_SOLVER_V, "k", gbfData->kv + i * nStates, nStates, gbfData->tv[i], gbData->nFastStates, gbData->fastStatesIdx);
        }
        messageClose(OMC_LOG_SOLVER_V);
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
        infoStreamPrint(OMC_LOG_SOLVER, 0, "gbodef_main: Failed to calculate step at time = %5g.", gbfData->time);
        gbfData->stepSize *= 0.5;
        infoStreamPrint(OMC_LOG_SOLVER, 0, "Try half of the step size = %g", gbfData->stepSize);
        if (gbfData->stepSize < GB_MINIMAL_STEP_SIZE) {
          errorStreamPrint(OMC_LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but error still to large.", GB_MINIMAL_STEP_SIZE);
          messageClose(OMC_LOG_SOLVER);
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
      // TODO memcpy() or actual ring buffer swap...
      for (i = (gbfData->ringBufferSize - 1); i > 0 ; i--) {
        gbfData->errValues[i] = gbfData->errValues[i - 1];
        gbfData->stepSizeValues[i] = gbfData->stepSizeValues[i - 1];
      }

      gbfData->errValues[0] = err;
      gbfData->stepSizeValues[0] = gbfData->stepSize;

      // Store performed stepSize for adjusting the time in case of latter interpolation
      // Call the step size control
      gbfData->lastStepSize = gbfData->stepSize;
      gbfData->stepSize *= GenericController(gbfData->errValues, gbfData->stepSizeValues, gbfData->tableau->error_order, gbfData->ctrl_method);

      // debug ring buffer for the states and derviatives of the states
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
        infoStreamPrint(OMC_LOG_GBODE_V, 1, "ring buffer during steps of inner integration");
        infoStreamPrint(OMC_LOG_GBODE_V, 0, "old value:");
        printVector_gbf(OMC_LOG_GBODE_V, "y", gbfData->yOld, nStates, gbfData->time, gbData->nFastStates, gbData->fastStatesIdx);
        debugRingBuffer_gbf(OMC_LOG_GBODE_V, gbfData->x, gbfData->k, nStates, gbfData->tableau, gbfData->time, gbfData->lastStepSize, gbData->nFastStates, gbData->fastStatesIdx);
        infoStreamPrint(OMC_LOG_GBODE_V, 0, "new value:");
        printVector_gbf(OMC_LOG_GBODE_V, "y", gbfData->y, nStates, gbfData->time + gbfData->lastStepSize, gbData->nFastStates, gbData->fastStatesIdx);
        messageClose(OMC_LOG_GBODE_V);
      }

      // Re-do step, if error is larger than requested
      if (err > 1) {
        gbfData->stats.nErrorTestFailures++;
        gbfData->stepSize *= 0.5;
        infoStreamPrint(OMC_LOG_SOLVER, 0, "Reject step from %10g to %10g, error %10g, new stepsize %10g",
                        gbfData->time, gbfData->time + gbfData->lastStepSize, err, gbfData->stepSize);
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
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

    foundEvent = checkForEvents(data, threadData, solverInfo, gbfData->time, gbfData->yOld, gbfData->time + gbfData->lastStepSize, gbfData->y, TRUE, &eventTime);
    if (foundEvent) {
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
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)){
        infoStreamPrint(OMC_LOG_GBODE, 1, "Emit result (inner integration):");
        printVector_gbf(OMC_LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue, gbData->nFastStates, gbData->fastStatesIdx);
        messageClose(OMC_LOG_GBODE);
      }

      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
        dumpFastStates_gb(gbData, TRUE, eventTime, 0);
      }

      // Get out of the integration routine for event handling
      messageClose(OMC_LOG_SOLVER);
      return 1;
    }

    /* update time with performed stepSize */
    gbfData->time += gbfData->lastStepSize;

    // debug the changes of the states and derivatives during integration
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      infoStreamPrint(OMC_LOG_GBODE, 1, "States and derivatives at right hand side (inner integration):");
      printVector_gbf(OMC_LOG_GBODE, "yR", gbfData->yRight, nStates, gbfData->timeRight, gbData->nFastStates, gbData->fastStatesIdx);
      printVector_gbf(OMC_LOG_GBODE, "kR", gbfData->kRight, nStates, gbfData->timeRight, gbData->nFastStates, gbData->fastStatesIdx);
      messageClose(OMC_LOG_GBODE);
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

    debugRingBufferSteps_gbf(OMC_LOG_GBODE, gbfData->yv, gbfData->kv, gbfData->tv, nStates,  gbfData->ringBufferSize, gbData->nFastStates, gbData->fastStatesIdx);

    /* step is accepted and yOld needs to be updated */
    //  copyVector_gbf(gbfData->yOld, gbfData->y, nFastStates, gbData->fastStates);
    memcpy(gbfData->yOld, gbfData->y, nStates * sizeof(double));
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Accept step from %10g to %10g, error %10g, new stepsize %10g",
                    gbfData->time - gbfData->lastStepSize, gbfData->time, err, gbfData->stepSize);

    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
      dumpFastStates_gbf(gbData, gbfData->time, 0);
    }

    /* emit step, if solverNoEquidistantGrid is selected */
    if (solverInfo->solverNoEquidistantGrid) {
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
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)){
        infoStreamPrint(OMC_LOG_GBODE, 1, "Emit result (inner integration):");
        printVector_gbf(OMC_LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue, gbData->nFastStates, gbData->fastStatesIdx);
        messageClose(OMC_LOG_GBODE);
      }
    }

    if ((gbData->timeRight - gbfData->time) < GB_MINIMAL_STEP_SIZE || gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
      gbfData->time = gbData->timeRight;
      break;
    }
  }

  // copy error and values of the fast states to the outer integrator routine if outer integration time is reached
  //gbData->err_fast = gbfData->errValues[0];

  if (!solverInfo->solverNoEquidistantGrid && gbfData->time >= targetTime) {
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

  infoStreamPrint(OMC_LOG_SOLVER, 0, "gbodef finished (inner steps).");
  messageClose(OMC_LOG_SOLVER);

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
int gbode_main(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA *)data->localData[0];
  modelica_real *fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;

  double stopTime = data->simulationInfo->stopTime;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = Atol;

  int nStates = gbData->nStates;
  int nStages = gbData->tableau->nStages;

  double targetTime, err;

  const modelica_boolean noConst_intWithErrctrl = gbData->ctrl_method != GB_CTRL_CNST && (gbData->interpolation == GB_INTERPOL_HERMITE_ERRCTRL || gbData->interpolation == GB_DENSE_OUTPUT_ERRCTRL);

  int gb_step_info;
  int i, retries = 0;
  modelica_boolean foundEvent;

  int *sortedStates;
  double err_states; // error of the (slow, if multirate) states

  // root finding will be done in gbode after each accepted step
  solverInfo->solverRootFinding = 1;

  /*
  * Determine the next target simulation time step.
  *
  * If the solver is using a non-equidistant grid:
  *    → The target time is the minimum of the next sample event time
  *      and the overall stop time.
  * Otherwise (equidistant grid):
  *    → Start from the current time plus the step size,
  *      but cap it by the stop time and the next scheduled event time.
  */
  if (solverInfo->solverNoEquidistantGrid) {
    // Non-equidistant grid: next step is driven by the nearest sample event.
    targetTime = fmin(data->simulationInfo->nextSampleEvent, stopTime);
  } else {
    // Equidistant output grid: targetTime set to the next output time.
    targetTime = solverInfo->currentTime + solverInfo->currentStepSize;

    // Ensure we don't run past the stop time.
    targetTime = fmin(targetTime, stopTime);

    // Also ensure we don't skip over an event time.
    targetTime = fmin(gbData->eventTime, targetTime);
  }

  if (gbData->multi_rate) {
    infoStreamPrint(OMC_LOG_SOLVER, 1, "Start gbode (birate integration)  from %g to %g",
                    solverInfo->currentTime, targetTime);
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 1, "Start gbode (single-rate integration)  from %g to %g",
                    solverInfo->currentTime, targetTime);
  }

    /*
  * Handle step initialization after an event step or at the very first solver step.
  *
  * This section ensures that the solver’s time, step size, and related buffers
  * are correctly initialized before proceeding with integration.
  */
  if (solverInfo->didEventStep || gbData->isFirstStep) {
    if (gbData->noRestart && !gbData->isFirstStep) {
      /*
        * Case: No restart requested after event (-noRestart flag set)
        *       and we are not at the very first step.
        * → Continue from the right boundary of the last interval
        *   using the optimal step size determined earlier.
        */
      gbData->time = gbData->timeRight;
      gbData->stepSize = gbData->optStepSize;
      infoStreamPrint(OMC_LOG_SOLVER, 0,
                      "Initial step size = %e at time %g",
                      gbData->stepSize, gbData->time);
    } else {
      /*
      * Case: Either restart is allowed OR this is the very first solver step.
      * → Recalculate the initial step size.
      * → Reset the ring buffer and solver statistics.
      * → Initialize gbData->timeRight, gbData->yRight, and gbData->kRight.
      */
      getInitStepSize(data, threadData, gbData);
      gbode_init(data, threadData, solverInfo);
    }

    // Mark initialization as complete for this step
    gbData->isFirstStep = FALSE;
    solverInfo->didEventStep = FALSE;

    // For multi-rate solvers, propagate event-step flag to the fine-level solver
    if (gbData->multi_rate) {
      gbData->gbfData->didEventStep = TRUE;
    }
  }

  debugRingBufferSteps_gb(OMC_LOG_GBODE, gbData->yv, gbData->kv, gbData->tv, nStates, gbData->ringBufferSize);

  /*
  * Case: Constant step size control method.
  * Use the solver's current step size directly without adjustment.
  */
  if (gbData->ctrl_method == GB_CTRL_CNST) {
    gbData->stepSize = solverInfo->currentStepSize;
  }


  if (gbData->multi_rate) {
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
        infoStreamPrint(OMC_LOG_SOLVER, 0, "Accept step from %10g to %10g, error slow states %10g, new stepsize %10g",
                        gbData->time - gbData->lastStepSize, gbData->time, gbData->errValues[0], gbData->stepSize);

        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
          // dump fast states in file
          dumpFastStates_gb(gbData, FALSE, gbData->time, 0);
        }
      }
      if (gb_step_info !=0) {
        // get out of here, if an event has happend!
        messageClose(OMC_LOG_SOLVER);
        if (gb_step_info > 0)
          return 0;
        else
          return gb_step_info;
      }
    }
  }


  /* Main integration loop, if gbData->time already greater than targetTime, only the
     interpolation is necessary for emitting the output variables (see below) */
  while (gbData->time < targetTime) {
    /*
    * Limit the step size so we do not overshoot:
    * 1. The next sample event time
    * 2. The overall simulation stop time
    */
    gbData->stepSize = fmin(gbData->stepSize, data->simulationInfo->nextSampleEvent - gbData->time);
    gbData->stepSize = fmin(gbData->stepSize, stopTime - gbData->time);
    // TODO maybe easier to use targetTime
    //gbData->stepSize = fmin(gbData->stepSize, targetTime - gbData->time);

    // Store the “left-hand side” data from the current step
    // for later use during interpolation.
    // Copies time, states, and derivatives from the “right” (current step)
    // to the “left” (previous step).
    // FIXME is this comment correct?
    gbData->timeLeft = gbData->timeRight;
    memcpy(gbData->yLeft, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kLeft, gbData->kRight, nStates * sizeof(double));

    // debug the ring buffer changes of the states and derivatives during integration
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      // debug the changes of the states and derivatives during integration
      infoStreamPrint(OMC_LOG_GBODE, 1, "States and derivatives at left hand side:");
      printVector_gb(OMC_LOG_GBODE, "yL", gbData->yLeft, nStates, gbData->timeLeft);
      printVector_gb(OMC_LOG_GBODE, "kL", gbData->kLeft, nStates, gbData->timeLeft);
      messageClose(OMC_LOG_GBODE);
    }

    // Loop will be performed until the error estimate for all states fullfills the
    // given tolerance
    do {
      if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V)) {
        // debug ring buffer of the states and derivatives during integration
        infoStreamPrint(OMC_LOG_SOLVER_V, 1, "States and derivatives of the ring buffer:");
        for (int i=0; i<gbData->ringBufferSize; i++) {
          printVector_gb(OMC_LOG_SOLVER_V, "y", gbData->yv + i * nStates, nStates, gbData->tv[i]);
        }
        for (int i=0; i<gbData->ringBufferSize; i++) {
          printVector_gb(OMC_LOG_SOLVER_V, "k", gbData->kv + i * nStates, nStates, gbData->tv[i]);
        }
        messageClose(OMC_LOG_SOLVER_V);
      }

      // Perform one integration step, producing two approximations:
      // the updated states in gbData->y and a second approximation in gbData->yt.
      // Choose the integration method based on the tableau:
      // - If Richardson extrapolation is enabled, use gbode_richardson.
      // - Otherwise, use the default step function stored in gbData->step_fun.
      if (gbData->tableau->richardson) {
        gb_step_info = gbode_richardson(data, threadData, solverInfo);
      } else {
        gb_step_info = gbData->step_fun(data, threadData, solverInfo);
      }

      // debug the approximations after performed step
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
        infoStreamPrint(OMC_LOG_GBODE, 1, "Approximations after step calculation:");
        printVector_gb(OMC_LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
        printVector_gb(OMC_LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
        messageClose(OMC_LOG_GBODE);
      }

      // Error handling for failed integration step:
      // If the step calculation failed (gb_step_info != 0), try reducing the step size by half and retry.
      //
      // Actions taken on failure:
      // - Increment convergence failure statistics counter.
      // - Print an informational message about the failure and the current simulation time.
      //
      // If the solver is using a constant step size control method:
      // - Abort the simulation and print an error message since no step size adjustment is possible.
      //
      // Otherwise (adaptive step size control):
      // - Halve the current step size.
      // - If multi-rate integration is active and detailed logging is enabled:
      //   - Reset error metrics for slow, fast, and internal components.
      //   - Dump the fast states to a file for diagnostics.
      // - Print the new reduced step size being tried.
      //
      // If the step size becomes smaller than the minimal allowed threshold:
      // - Abort the simulation with an error indicating minimum step size reached without acceptable error.
      //
      // If none of the abort conditions occur, the loop continues to retry with the reduced step size.
      if (gb_step_info != 0) {
        gbData->stats.nConvergenveTestFailures++;
        infoStreamPrint(OMC_LOG_STDOUT, 0, "gbode_main: Failed to calculate step at time = %5g.", gbData->time + gbData->stepSize);
        if (gbData->ctrl_method == GB_CTRL_CNST) {
          errorStreamPrint(OMC_LOG_STDOUT, 0, "Simulation aborted since gbode is running with fixed step size!");
          messageClose(OMC_LOG_SOLVER);
          return -1;
        } else {
          gbData->stepSize *= 0.5;
          if (gbData->multi_rate && OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
            gbData->err_slow = 0;
            gbData->err_fast = 0;
            gbData->err_int = 0;
            // dump fast states in file
            dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->stepSize, 3);
          }
          infoStreamPrint(OMC_LOG_STDOUT, 0, "Try half of the step size = %g", gbData->stepSize);
          if (gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
            errorStreamPrint(OMC_LOG_STDOUT, 0, "Simulation aborted! Minimum step size %g reached, but error still to large.", GB_MINIMAL_STEP_SIZE);
            messageClose(OMC_LOG_SOLVER);
            return -1;
          }
          continue;
        }
      }

      // Calculate error estimators and tolerance scaling for each state variable
      for (i = 0; i < nStates; i++) {
        // Compute error tolerance for the i-th state based on relative and absolute tolerances:
        // errtol = Rtol * max(|current state|, |previous state|) + Atol
        gbData->errtol[i] = Rtol * fmax(fabs(gbData->y[i]), fabs(gbData->yOld[i])) + Atol;
        // TODO make errtol and errest local variables

        // Calculate the estimated local error as the absolute difference between
        // the current state approximation and its second approximation.
        gbData->errest[i] = fabs(gbData->y[i] - gbData->yt[i]);

        // Compute the scaled error using a tableau-specific factor, to be used in step size control.
        gbData->err[i] = gbData->tableau->fac * gbData->errest[i] / gbData->errtol[i];
      }
      if (gbData->multi_rate) {
        // Multi-rate integration enabled:
        //
        // If verbose GBODE logging is active, allocate memory and copy the current sorted state indices
        // for comparison and debugging purposes.
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
          sortedStates = (int *)malloc(sizeof(int) * nStates);
          // FIXME avoid allocs during simulation, they are slow!
          memcpy(sortedStates, gbData->sortedStatesIdx, sizeof(int) * nStates);
        }

        // Calculate the error threshold for slow states (used to separate slow and fast states).
        err_states = getErrorThreshold(gbData);
        err = err_states;

        // If verbose logging is active, check if the sorted state indices have changed since the copy.
        // If differences are detected, print the before and after sorted state vectors for debugging.
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
          for (int k = 0; k < nStates; k++) {
            if (sortedStates[k] != gbData->sortedStatesIdx[k]) {
              printIntVector_gb(OMC_LOG_GBODE_V, "sortedStates before:", sortedStates, nStates, gbData->time);
              printIntVector_gb(OMC_LOG_GBODE_V, "sortedStates after:", gbData->sortedStatesIdx, nStates, gbData->time);
              break;
            }
          }
          free(sortedStates);
        }

        // Classify states into fast and slow based on the scaled error:
        // - States with error >= 1 are considered fast.
        // - States with error < 1 are considered slow.
        //
        // Keep track of the count of fast and slow states,
        // and record the maximum error encountered for each group.
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
      } else {
        // If multi-rate is not enabled, use the maximum norm of the error vector over all states.
        err_states = _omc_gen_maximumVectorNorm(gbData->err, nStates);
        err = err_states;
      }

      // Reject the current integration step if the estimated error exceeds the tolerance,
      // and if the solver is not running with a fixed (constant) step size.
      if (err > 1 && gbData->ctrl_method != GB_CTRL_CNST) {

        // Logging
        if (gbData->multi_rate) {
          // For multi-rate integration, print detailed info about the rejected step,
          // including the slow states' error and the reduced step size.
          infoStreamPrint(OMC_LOG_SOLVER, 0,
            "Reject step from %.16g to %.16g, error slow states %.16g, new stepsize %.16g",
            gbData->time, gbData->time + gbData->stepSize, err, gbData->stepSize * 0.5);

          // If verbose solver logging is enabled, print detailed error information for debugging.
          if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V)) {
            infoStreamPrint(OMC_LOG_SOLVER_V, 1, "Error of the states: threshold = %15.10g", err_states);
            printVector_gb(OMC_LOG_SOLVER_V, "y", gbData->y, nStates, gbData->time + gbData->stepSize);
            printVector_gb(OMC_LOG_SOLVER_V, "er", gbData->err, nStates, gbData->time + gbData->stepSize);
            messageClose(OMC_LOG_SOLVER_V);
          }

          // If GBODE state logging is active, dump fast state data to file for further analysis.
          if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
            gbData->err_slow = err; // FIXME should this really only happen when logging is active?
            dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->stepSize, 1);
          }
        } else {
          // For single-rate integration, print basic rejection info with the error and new step size.
          infoStreamPrint(OMC_LOG_SOLVER, 0,
            "Reject step from %.16g to %.16g, error %.16g, new stepsize %.16g",
            gbData->time, gbData->time + gbData->stepSize, err, gbData->stepSize * 0.5);
        }

        // Increment the counter for error test failures.
        gbData->stats.nErrorTestFailures++;

        // Reduce the step size by half to attempt a more accurate integration in the next iteration.
        gbData->stepSize *= 0.5;

        // Restart the integration loop with the smaller step size.
        continue;
      }

      // Store right-hand side values for later interpolation, including event handling:
      // - Update gbData->timeRight to the time at the end of the current step.
      // - Copy current state values (gbData->y) to gbData->yRight.
      //
      // Update the derivative estimates gbData->kRight:
      // - If the tableau does not provide kRight values directly,
      //   compute them by evaluating the ODE function at timeRight and current states.
      //
      // Compute interpolation error estimate (gbData->err_int) if either:
      // - Solver logging is enabled, or
      // - The control method is not constant step size and
      //   the interpolation method is one of the error-controlled Hermite or dense output.
      //
      // For multi-rate integration with fast states, compute the interpolation error only
      // for the slow states subset; otherwise, consider all states.
      gbData->timeRight = gbData->time + gbData->stepSize;
      memcpy(gbData->yRight, gbData->y, nStates * sizeof(double));
      // update kRight
      if (!gbData->tableau->isKRightAvailable) {
        sData->timeValue = gbData->timeRight;
        memcpy(sData->realVars, gbData->y, data->modelData->nStates * sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      }
      memcpy(gbData->kRight, fODE, nStates * sizeof(double));

      if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER) || noConst_intWithErrctrl) {
        if (gbData->multi_rate && gbData->nFastStates>0) {
          gbData->err_int = error_interpolation_gb(gbData, gbData->nSlowStates, gbData->slowStatesIdx, Rtol);
        } else {
          gbData->err_int = error_interpolation_gb(gbData, nStates, NULL, Rtol);
        }
      }
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
        // debug the changes of the state values during integration
        infoStreamPrint(OMC_LOG_GBODE_V, 1, "Interpolation error of slow states at midpoint:");
        if (gbData->multi_rate) {
          printVector_gbf(OMC_LOG_GBODE_V, "yL", gbData->yLeft, nStates, gbData->timeLeft, gbData->nSlowStates, gbData->slowStatesIdx);
          printVector_gbf(OMC_LOG_GBODE_V, "kL", gbData->kLeft, nStates, gbData->timeLeft, gbData->nSlowStates, gbData->slowStatesIdx);
          printVector_gbf(OMC_LOG_GBODE_V, "yR", gbData->yRight, nStates, gbData->timeRight, gbData->nSlowStates, gbData->slowStatesIdx);
          printVector_gbf(OMC_LOG_GBODE_V, "kR", gbData->kRight, nStates, gbData->timeRight, gbData->nSlowStates, gbData->slowStatesIdx);
          printVector_gbf(OMC_LOG_GBODE_V, "e", gbData->errest, nStates, (gbData->timeLeft + gbData->timeRight)/2, gbData->nSlowStates, gbData->slowStatesIdx);
        } else {
          printVector_gb(OMC_LOG_GBODE_V, "yL", gbData->yLeft, nStates, gbData->timeLeft);
          printVector_gb(OMC_LOG_GBODE_V, "yR", gbData->yRight, nStates, gbData->timeRight);
          printVector_gb(OMC_LOG_GBODE_V, "kL", gbData->kLeft, nStates, gbData->timeLeft);
          printVector_gb(OMC_LOG_GBODE_V, "kR", gbData->kRight, nStates, gbData->timeRight);
          printVector_gbf(OMC_LOG_GBODE_V, "e", gbData->errest, nStates, (gbData->timeLeft + gbData->timeRight)/2, gbData->nSlowStates, gbData->slowStatesIdx);
        }
        messageClose(OMC_LOG_GBODE_V);
      }

      // Adjust the error estimate for step size control by incorporating interpolation error.
      // This is done only if:
      // - The current error estimate is greater than 0.01,
      // - The number of retries is less than 4,
      // - The solver is not using a constant step size,
      // - And the interpolation method supports error control (Hermite or dense output).
      //
      // The error used for step size control is set to the maximum of the interpolation error and the current error.
      if ((err > 1e-2) && (retries < 4) && noConst_intWithErrctrl) {
        err = fmax(gbData->err_int, err);
      }

      // Reject the current integration step if the interpolation error exceeds the tolerance,
      // provided that the solver is not running with a fixed step size and interpolation error control is enabled.
      //
      // On rejection:
      // - Increment the retry counter and error test failure statistics.
      // - Reduce the step size by half to attempt a more accurate integration.
      // - Abort the simulation if the step size falls below the minimal allowed threshold.
      //
      // Logging differs for multi-rate and single-rate integration:
      // - For multi-rate, log errors of slow states and interpolation error.
      // - For single-rate, log the overall error and interpolation error.
      //
      // If multi-rate integration and GBODE state logging is active, dump fast states for diagnostics.
      //
      // If the step is accepted, reset the retry counter.
      if (err > 1 && noConst_intWithErrctrl) {

        retries++;
        gbData->stats.nErrorTestFailures++;
        gbData->stepSize *= 0.5;

        if (gbData->stepSize < GB_MINIMAL_STEP_SIZE) {
          errorStreamPrint(OMC_LOG_STDOUT, 0,
            "Simulation aborted! Minimum step size %g reached, but interpolation error still too large.",
            GB_MINIMAL_STEP_SIZE);
          messageClose(OMC_LOG_SOLVER);
          return -1;
        }

        if (gbData->multi_rate) {
          infoStreamPrint(OMC_LOG_SOLVER, 0,
            "Reject step from %.16g to %.16g, error slow states %.16g, error interpolation %.16g, new stepsize %.16g",
            gbData->time, gbData->time + gbData->stepSize, gbData->err_slow, gbData->err_int, gbData->stepSize);
        } else {
          infoStreamPrint(OMC_LOG_SOLVER, 0,
            "Reject step from %.16g to %.16g, error %.16g, interpolation error %.16g, new stepsize %.16g",
            gbData->time, gbData->time + gbData->stepSize, err_states, gbData->err_int, gbData->stepSize);
        }

        if (gbData->multi_rate && OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
          // Dump fast states to file for further analysis after step rejection.
          dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->stepSize, 2);
        }

        continue;
      } else {
        // Reset retries counter if the step was accepted.
        retries = 0;
      }

      // Rotate the error and step size ring buffers to make room for the latest values.
      // The oldest entries are shifted one position towards the end,
      // and the newest error and step size values are stored at the front (index 0).
      // FIXME use actual ring buffer instead of moving data around!
      for (i = (gbData->ringBufferSize - 1); i > 0; i--) {
        gbData->errValues[i] = gbData->errValues[i - 1];
        gbData->stepSizeValues[i] = gbData->stepSizeValues[i - 1];
      }
      // Store the current error and step size at the beginning of the buffers.
      gbData->errValues[0] = err;
      gbData->stepSizeValues[0] = gbData->stepSize;

      // Update the step size using the step size controller
      gbData->lastStepSize = gbData->stepSize;  // Save the current step size before updating

      // Calculate a new step size based on recent error and step size history,
      // the method’s error order, and the control method in use
      gbData->stepSize *= GenericController(gbData->errValues, gbData->stepSizeValues, gbData->tableau->error_order, gbData->ctrl_method);

      // Ensure the new step size does not exceed the user-defined maximum step size (if set)
      if (gbData->maxStepSize > 0 && gbData->maxStepSize < gbData->stepSize)
        gbData->stepSize = gbData->maxStepSize;

      // Store the optimized step size for further use
      gbData->optStepSize = gbData->stepSize;

      if (gbData->multi_rate) {
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
          // debug the changes of the state values during integration
          infoStreamPrint(OMC_LOG_GBODE, 1, "States and derivatives at right hand side:");
          printVector_gb(OMC_LOG_GBODE, "yR", gbData->yRight, nStates, gbData->timeRight);
          printVector_gb(OMC_LOG_GBODE, "kR", gbData->kRight, nStates, gbData->timeRight);
          messageClose(OMC_LOG_GBODE);
        }

        if (gbData->nFastStates > 0) {
          if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
            // debug the error of the states and derivatives after outer integration
            infoStreamPrint(OMC_LOG_GBODE, 1, "Error of the states before inner integration: threshold = %15.10g", err_states);
            printVector_gb(OMC_LOG_GBODE, "er", gbData->err, nStates, gbData->timeRight);
            printIntVector_gb(OMC_LOG_GBODE, "sr", gbData->sortedStatesIdx, nStates, gbData->timeRight);
            messageClose(OMC_LOG_GBODE);
          }
          if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
            // dump fast states in file
            dumpFastStates_gb(gbData, FALSE, gbData->time + gbData->lastStepSize, -1);
          }
          infoStreamPrint(OMC_LOG_SOLVER, 0, "Refine step from %10g to %10g, error fast states %10g, error interpolation %10g, new stepsize %10g",
                          gbData->time, gbData->time + gbData->lastStepSize, gbData->err_fast, error_interpolation_gb(gbData, nStates, NULL, Rtol), gbData->stepSize);
          // run multirate step
          gb_step_info = gbodef_main(data, threadData, solverInfo, targetTime);
          // synchronize relevant information
          if (fabs(gbData->timeRight - gbData->gbfData->timeRight) < GB_MINIMAL_STEP_SIZE) {
            memcpy(gbData->y, gbData->gbfData->y, nStates * sizeof(double));
            memcpy(gbData->yRight, gbData->gbfData->yRight, nStates * sizeof(double));
            memcpy(gbData->err, gbData->gbfData->err, nStates * sizeof(double));
            sData->timeValue = gbData->timeRight;
            memcpy(sData->realVars, gbData->yRight, data->modelData->nStates * sizeof(double));
            gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
            memcpy(gbData->kRight, fODE, nStates * sizeof(double));
          }
          infoStreamPrint(OMC_LOG_SOLVER, 0, "Refined step from %10g to %10g, error fast states %10g, error interpolation %10g, new stepsize %10g",
                          gbData->time, gbData->time + gbData->lastStepSize, gbData->err_fast, error_interpolation_gb(gbData, nStates, NULL, Rtol), gbData->stepSize);
          if (gb_step_info !=0) {
            // get out of here, if an event has happend!
            messageClose(OMC_LOG_SOLVER);
            if (gb_step_info>0)
              return 0;
            else
              return gb_step_info;
          }
        }

        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
          // debug the error of the states and derivatives after outer integration
          infoStreamPrint(OMC_LOG_GBODE_V, 1, "Error of the states: threshold = %15.10g", err_states);
          printVector_gb(OMC_LOG_GBODE_V, "er", gbData->err, nStates, gbData->timeRight);
          messageClose(OMC_LOG_GBODE_V);
        }
      }
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_V)) {
        // debug ring buffer for the states and derviatives of the states
        infoStreamPrint(OMC_LOG_GBODE_V, 1, "Ring buffer during steps of integration");
        infoStreamPrint(OMC_LOG_GBODE_V, 0, "Old value:");
        printVector_gb(OMC_LOG_GBODE_V, "y", gbData->yOld, nStates, gbData->time);
        debugRingBuffer_gb(OMC_LOG_GBODE_V, gbData->x, gbData->k, nStates, gbData->tableau, gbData->time, gbData->lastStepSize);
        infoStreamPrint(OMC_LOG_GBODE_V, 0, "New value:");
        printVector_gb(OMC_LOG_GBODE_V, "y", gbData->y, nStates, gbData->time + gbData->lastStepSize);
        messageClose(OMC_LOG_GBODE_V);
      }
    } while (err > 1 && gbData->ctrl_method != GB_CTRL_CNST);

    // count processed steps
    gbData->stats.nStepsTaken++;

    // debug the changes of the state values during integration
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      infoStreamPrint(OMC_LOG_GBODE, 1, "States and derivatives at right hand side:");
      printVector_gb(OMC_LOG_GBODE, "yR", gbData->yRight, nStates, gbData->timeRight);
      printVector_gb(OMC_LOG_GBODE, "kR", gbData->kRight, nStates, gbData->timeRight);
      messageClose(OMC_LOG_GBODE);
    }

    // If not using multi-rate integration, or if multi-rate is active but the fast integration time
    // is behind the main integrator time, then check for events.
    if (!gbData->multi_rate || (gbData->multi_rate && gbData->gbfData->time < gbData->time)) {

      // Check for any events occurring between the previous accepted time (timeLeft) and current time (timeRight).
      // The function returns the event time if an event is detected, and sets foundEvent accordingly.
      foundEvent = checkForEvents(data, threadData, solverInfo, gbData->timeLeft, gbData->yLeft, gbData->timeRight, gbData->yRight, FALSE, &(gbData->eventTime));

      if (foundEvent) {
        // Clear any pending events in the solver's event list before handling the new event.
        listClear(solverInfo->eventLst);

        // Update the current integration time to the event time.
        gbData->time = gbData->eventTime;

        // Perform interpolation at the event time to estimate states and derivatives accurately.
        gb_interpolation(gbData->interpolation,
                        gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                        gbData->timeRight, gbData->yRight, gbData->kRight,
                        gbData->time,      gbData->yOld,
                        nStates, NULL, nStates, gbData->tableau,
                        gbData->x, gbData->k);

        // Adjust targetTime to not exceed the detected event time,
        // ensuring the integrator stops exactly at the event.
        targetTime = fmin(targetTime, gbData->eventTime);

        // Exit the integration loop early since an event was detected.
        break;
      }
    }

    if (gbData->multi_rate) {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "Accept step from %.16g to %.16g, error slow states %.16g, error interpolation %.16g, new stepsize %.16g",
                                gbData->timeLeft, gbData->timeRight, err_states, gbData->err_int, gbData->stepSize);
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_STATES)) {
        // dump fast states in file
        dumpFastStates_gb(gbData, FALSE, gbData->time, 0);
      }
    } else {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "Accept step from %.16g to %.16g, error %.16g interpolation error %.16g, new stepsize %16g",
                      gbData->timeLeft, gbData->timeRight, err_states, gbData->err_int, gbData->stepSize);

    }

    /* update time with performed stepSize */
    gbData->time = gbData->timeRight;

    /* step is accepted and yOld needs to be updated */
    memcpy(gbData->yOld, gbData->yRight, nStates * sizeof(double));

    // Rotate ring buffer
    for (i = (gbData->ringBufferSize - 1); i > 0 ; i--) {
      gbData->tv[i] =  gbData->tv[i - 1];
      memcpy(gbData->yv + i * nStates, gbData->yv + (i - 1) * nStates, nStates * sizeof(double));
      memcpy(gbData->kv + i * nStates, gbData->kv + (i - 1) * nStates, nStates * sizeof(double));
    }

    // update new values
    gbData->tv[0] = gbData->timeRight;
    memcpy(gbData->yv, gbData->yRight, nStates * sizeof(double));
    memcpy(gbData->kv, gbData->kRight, nStates * sizeof(double));

    debugRingBufferSteps_gb(OMC_LOG_GBODE_V, gbData->yv, gbData->kv, gbData->tv, nStates,  gbData->ringBufferSize);

    /* emit step, if solverNoEquidistantGrid is selected */
    if (solverInfo->solverNoEquidistantGrid && (!gbData->multi_rate || (gbData->multi_rate && gbData->gbfData->time<gbData->time))) {
      sData->timeValue = gbData->time;
      solverInfo->currentTime = sData->timeValue;
      memcpy(sData->realVars, gbData->y, nStates * sizeof(double));
      // log the emitted result
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)){
        infoStreamPrint(OMC_LOG_GBODE, 1, "Emit result:");
        printVector_gb(OMC_LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
        messageClose(OMC_LOG_GBODE);
      }
      break;
    }

    // stop, if simulation nearly reached stopTime
    if (stopTime - gbData->time < GB_MINIMAL_STEP_SIZE) {
      gbData->time = stopTime;
      break;
    }
  } // end of while-loop (gbData->time < targetTime)

  if (gbData->eventTime == targetTime) {

    if (!solverInfo->solverNoEquidistantGrid) {
      foundEvent = checkForEvents(data, threadData, solverInfo, gbData->eventTime, gbData->yOld, gbData->eventTime, gbData->yOld, FALSE, &(gbData->eventTime));
    }

    solverInfo->currentTime = gbData->time;
    sData->timeValue = gbData->time;
    memcpy(sData->realVars, gbData->yOld, nStates * sizeof(double));

    // if noRestart is set, the right hand side values are stored
    if (gbData->noRestart) {
      gbData->timeRight = gbData->time;
      memcpy(gbData->yRight, gbData->yOld, nStates * sizeof(double));
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      memcpy(gbData->kRight, fODE, nStates * sizeof(double));
    }

    /* write statistics to the solverInfo data structure */
    memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

    // log the emitted result
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)){
      infoStreamPrint(OMC_LOG_GBODE, 1, "Emit result (single-rate integration):");
      printVector_gb(OMC_LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
      messageClose(OMC_LOG_GBODE);
    }
    // return to solver main routine for proper event handling (iteration)
    messageClose(OMC_LOG_SOLVER);

    listClear(solverInfo->eventLst);
    gbData->eventTime = DBL_MAX; // reset event time, if eventTime is reached

    return 0;
  }

  if (!solverInfo->solverNoEquidistantGrid) {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    sData->timeValue = fmin(solverInfo->currentTime + solverInfo->currentStepSize, gbData->eventTime);
    sData->timeValue = fmin(sData->timeValue, stopTime);
    solverInfo->currentTime = sData->timeValue;

    if (gbData->multi_rate) {
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
                        nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
      }
    } else {
      // use chosen interpolation for emitting equidistant output (default hermite)
      if (solverInfo->currentStepSize>0)
        gb_interpolation(gbData->interpolation,
                      gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                      gbData->timeRight, gbData->yRight, gbData->kRight,
                      sData->timeValue,  sData->realVars,
                      nStates, NULL, nStates, gbData->tableau, gbData->x, gbData->k);
    }
    // log the emitted result
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)){
      infoStreamPrint(OMC_LOG_GBODE, 1, "Emit result:");
      printVector_gb(OMC_LOG_GBODE, " y", sData->realVars, nStates, sData->timeValue);
      messageClose(OMC_LOG_GBODE);
    }
  } else {
    // Integrator emits result on the simulation grid (see above)
    sData->timeValue = gbData->time;
    solverInfo->currentTime = gbData->time;
    solverInfo->currentStepSize = gbData->stepSize;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  data->simulationInfo->sampleActivated =    data->simulationInfo->sampleActivated
                                          && solverInfo->currentTime >= data->simulationInfo->nextSampleEvent;

  /* Solver statistics */
  if (!gbData->isExplicit)
    gbData->stats.nCallsJacobian = gbData->nlsData->numberOfJEval;
  if (!solverInfo->solverNoEquidistantGrid && fabs(targetTime - stopTime) < GB_MINIMAL_STEP_SIZE && OMC_ACTIVE_STREAM(OMC_LOG_STATS)) {
    if (gbData->multi_rate) {
      infoStreamPrint(OMC_LOG_STATS, 0, "gbode (birate integration): slow: %s / fast: %s",
                      GB_METHOD_NAME[gbData->GM_method], GB_METHOD_NAME[gbData->gbfData->GM_method]);
      logSolverStats(OMC_LOG_STATS, "inner integration", stopTime, stopTime, 0, &gbData->gbfData->stats);
      logSolverStats(OMC_LOG_STATS, "outer integration", stopTime, stopTime, 0, &gbData->stats);
    } else {
      infoStreamPrint(OMC_LOG_STATS, 0, "gbode (single-rate integration): %s", GB_METHOD_NAME[gbData->GM_method]);
    }
  }
  /* Write statistics to the solverInfo data structure */
  logSolverStats(OMC_LOG_SOLVER_V, "gb_singlerate", solverInfo->currentTime, gbData->time, gbData->stepSize, &gbData->stats);
  memcpy(&solverInfo->solverStatsTmp, &gbData->stats, sizeof(SOLVERSTATS));

  messageClose(OMC_LOG_SOLVER);
  return 0;
}
