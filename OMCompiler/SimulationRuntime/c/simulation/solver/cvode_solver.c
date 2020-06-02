/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2020, Open Source Modelica Consortium (OSMC),
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

/* Standard C headers */
#include <string.h>
#include <stdio.h>
#include <stdlib.h>

/* OMC headers */
#include "simulation_data.h"
#include "simulation/options.h"
#include "simulation/solver/external_input.h"
#include "solver_main.h"
#include "model_help.h"
#include "omc_math.h"

#include "util/omc_error.h"
#include "gc/omc_gc.h"

#include "dassl.h"
#include "epsilon.h"

#include "cvode_solver.h"

#ifdef WITH_SUNDIALS

/* Macros for better readability */
#define CVODE_LMM_MAX 2
const char *CVODE_LMM_NAME[CVODE_LMM_MAX + 1] = {
    "undefined",
    "CV_ADAMS", /* 1 */
    "CV_BDF"    /* 2 */
};

const char *CVODE_LMM_DESC[CVODE_LMM_MAX + 1] = {
    "undefined",
    "Adams-Moulton linear multistep method. Use together with CV_FUNCTIONAL for nonstiff problems.",
    "BDF linear multistep method. Use together with CV_NEWTON for stiff problems. Default option."};

#define CVODE_ITER_MAX 2
const char *CVODE_ITER_NAME[CVODE_ITER_MAX + 1] = {
    "undefined",
    "CV_FUNCTIONAL", /* 1 */
    "CV_NEWTON"      /* 2 */
};

const char *CVODE_ITER_DESC[CVODE_ITER_MAX + 1] = {
    "undefined",
    "Nonlinear system solution through functional iterations",
    "Nonlinear system solution through Newton iterations"};

/* Internal function prototypes */
int cvodeRightHandSideODEFunction(realtype time, N_Vector y, N_Vector ydot, void *userData);

/**
 * @brief Computes the ODE right-hand side for a given value of the independent variable t and state vector y
 *
 * @param time        is the current value of the independent variable
 * @param y           is the current value of the dependent variable vector, y(t).
 * @param ydot        is the output vector f(t, y).
 * @param userData    user data containing CVODE_SOLVER
 * @return int
 */
int cvodeRightHandSideODEFunction(realtype time, N_Vector y, N_Vector ydot, void *userData)
{

  /* Variables */
  CVODE_SOLVER *cvodeData;
  DATA *data;
  threadData_t *threadData;
  long int i;
  int success = 0, retVal = 0;
  int saveJumpState;

  /* Access userData */
  cvodeData = (CVODE_SOLVER *)userData;
  data = cvodeData->simData->data;
  threadData = cvodeData->simData->threadData;

  infoStreamPrint(LOG_SOLVER_V, 1, "### eval cvodeRightHandSideODEFunction ###");

  /* TODO: Add scaling of y and ydot */

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_ODE);
  }
  /* Set time */
  data->localData[0]->timeValue = time;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* Debug print for states (input) */
  if (ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "y at time=%f", time);
    for (i = 0; i < data->modelData->nStates; i++)
    {
      infoStreamPrint(LOG_SOLVER_V, 0, "y[%ld] = %e", i, NV_Ith_S(y, i));
    }
    messageClose(LOG_SOLVER_V);
  }

  /* Read input vars (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  /* eval function ODE (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
  data->callback->functionODE(data, threadData);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  /* Update ydot */
  for (i = 0; i < data->modelData->nStates; i++)
  {
    NV_Ith_S(ydot, i) = data->localData[0]->realVars[data->modelData->nStates + i];
  }

  /* Debug print for derived states (output) */
  if (ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "ydot at time=%f", time);
    for (i = 0; i < data->modelData->nStates; i++)
    {
      infoStreamPrint(LOG_SOLVER_V, 0, "ydot[%ld] = %e", i, NV_Ith_S(ydot, i));
    }
    messageClose(LOG_SOLVER_V);
  }

  /* TODO: Scale result */

  success = 1;

  /* catch */
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif

  if (!success)
  {
    retVal = -1;
  }

  threadData->currentErrorStage = saveJumpState;

  if (data->simulationInfo->currentContext == CONTEXT_ODE)
  {
    unsetContext(data);
  }
  messageClose(LOG_SOLVER_V);
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}

/*
 *  function calculates a jacobian matrix by
 *  numerical method finite differences with coloring
 *  into a dense DlsMat matrix
 */
static int jacColoredNumericalDense(double currentTime, N_Vector y, N_Vector fy,
                                    DlsMat Jac, void *userData)
{
  /* TODO: Add stuff for colored dense jacobian */
  return -1;
}

/**
 * @brief Wrapper function to call dense Jacobian
 *
 * @param N
 * @param t
 * @param y
 * @param fy
 * @param Jac
 * @param user_data
 * @param tmp1
 * @param tmp2
 * @param tmp3
 * @return int
 */
static int callDenseJacobian(long int N, double t,
                             N_Vector y, N_Vector fy,
                             DlsMat Jac, void *user_data,
                             N_Vector tmp1, N_Vector tmp2, N_Vector tmp3)
{
  /* Variables */
  CVODE_SOLVER *cvodeData;
  DATA *data;
  threadData_t *threadData;
  int retVal = -1;
  _omc_matrix *dumpJac;

  /* Access userData */
  cvodeData = (CVODE_SOLVER *)user_data;
  data = cvodeData->simData->data;
  threadData = cvodeData->simData->threadData;

  /* profiling */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
  rt_tick(SIM_TIMER_JACOBIAN);

  if (cvodeData->config.jacobianMethod == COLOREDNUMJAC || cvodeData->config.jacobianMethod == NUMJAC)
  {
    retVal = jacColoredNumericalDense(t, y, fy, Jac, user_data);
  }
  else
  {
    throwStreamPrint(threadData, "##CVODE## Something goes wrong while obtain jacobian matrix!");
  }

  /* debug */
  if (ACTIVE_STREAM(LOG_JAC))
  {
    dumpJac = _omc_createMatrix(data->modelData->nStates, data->modelData->nStates, Jac->data);
    _omc_printMatrix(dumpJac, "CVODE-Solver: Matrix A", LOG_JAC);
    _omc_destroyMatrix(dumpJac);
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  return retVal;
}

/**
 * @brief Root function for CVODE
 *
 * @param time        Current time.
 * @param y           State vector.
 * @param gout        Zero crossing array.
 * @param userData    User data.
 * @return int        Will return 0 on success.
 */
int rootsFunctionCVODE(double time, N_Vector y, double *gout, void *userData)
{
  TRACE_PUSH
  CVODE_SOLVER *cvodeData = (CVODE_SOLVER *)userData;
  DATA *data = (DATA *)(((CVODE_USERDATA *)cvodeData->simData)->data);
  threadData_t *threadData = (threadData_t *)(((CVODE_USERDATA *)((CVODE_SOLVER *)userData)->simData)->threadData);

  int saveJumpState;

  infoStreamPrint(LOG_SOLVER_V, 1, "### eval rootsFunctionCVODE ###");

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, &time, CONTEXT_EVENTS);
  }

  /* TODO: re-scale idaData->y to evaluate the equations */

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_EVENTSEARCH;

  data->localData[0]->timeValue = time;

  /* Read input vars (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations (exclude from timer) */
  data->callback->function_ZeroCrossingsEquations(data, threadData);
  data->callback->function_ZeroCrossings(data, threadData, gout);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  threadData->currentErrorStage = saveJumpState;

  /* TODO: scale data again */

  if (data->simulationInfo->currentContext == CONTEXT_EVENTS)
  {
    unsetContext(data);
  }
  messageClose(LOG_SOLVER_V);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  TRACE_POP
  return 0;
}

/**
 * @brief Get settings for CVODE from user flags.
 *
 * If the user didn't provide any flags following settings will be chosen:
 *   config->lmm = CV_BDF
 *   config->iter = CV_NEWTON
 *
 * @param cvodeData       CVODE solver data struckt
 * @param threadData      Thread data for error handling
 */
void cvodeGetConfig(CVODE_CONFIG *config, threadData_t *threadData)
{
  /* Variables */
  int i;

  /* ### Options for CVodeCreate ### */

  /* Set linear multistep method */
  if (omc_flag[FLAG_CVODE_LMM])
  {
    if (strcmp((const char *)omc_flagValue[FLAG_CVODE_LMM], CVODE_LMM_NAME[CV_ADAMS]))
    {
      config->lmm = CV_ADAMS;
    }
    else if (strcmp((const char *)omc_flagValue[FLAG_CVODE_LMM], CVODE_LMM_NAME[CV_BDF]))
    {
      config->lmm = CV_BDF;
    }
    else
    {
      if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
      {
        warningStreamPrint(LOG_SOLVER, 1, "Unrecognized linear multistep method %s for CVODE, current options are:", (const char *)omc_flagValue[FLAG_CVODE_LMM]);
        for (i = 1; i <= CVODE_LMM_MAX; ++i)
        {
          warningStreamPrint(LOG_SOLVER, 0, "%s [%s]", CVODE_LMM_NAME[i], CVODE_LMM_DESC[i]);
        }
        messageClose(LOG_SOLVER);
      }
      throwStreamPrint(threadData, "Unrecognized linear multistep method %s for CVODE.", (const char *)omc_flagValue[FLAG_CVODE_LMM]);
    }
  }
  else /* No user provided flag */
  {
    config->lmm = CV_BDF;
  }

  /* Set nonlinear solver iteration type */
  if (omc_flag[FLAG_CVODE_ITER])
  {
    if (strcmp((const char *)omc_flagValue[FLAG_CVODE_ITER], CVODE_ITER_NAME[CV_FUNCTIONAL]))
    {
      config->iter = CV_FUNCTIONAL;
    }
    else if (strcmp((const char *)omc_flagValue[FLAG_CVODE_ITER], CVODE_ITER_NAME[CV_NEWTON]))
    {
      config->iter = CV_NEWTON;
    }
    else
    {
      if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
      {
        warningStreamPrint(LOG_SOLVER, 1, "Unrecognized type of nonlinear solver iteration %s for CVODE, current options are:", (const char *)omc_flagValue[FLAG_CVODE_ITER]);
        for (i = 1; i <= CVODE_ITER_MAX; ++i)
        {
          warningStreamPrint(LOG_SOLVER, 0, "%s [%s]", CVODE_ITER_NAME[i], CVODE_ITER_DESC[i]);
        }
        messageClose(LOG_SOLVER);
      }
      throwStreamPrint(threadData, "Unrecognized type of nonlinear solver iteration %s for CVODE.", (const char *)omc_flagValue[FLAG_CVODE_LMM]);
    }
  }
  else /* No user provided flag */
  {
    if (config->lmm == CV_ADAMS)
    {
      config->iter = CV_FUNCTIONAL;
    }
    else
    {
      config->iter = CV_NEWTON;
    }
  }

  /* Check for compability of lmn and iter */
  if ((config->lmm == CV_ADAMS && config->iter != CV_FUNCTIONAL) ||
      (config->lmm == CV_BDF && config->iter != CV_NEWTON))
  {
    if (ACTIVE_WARNING_STREAM(LOG_SOLVER))
    {
      warningStreamPrint(LOG_SOLVER, 1, "Combination of %s and %s not recommended.", CVODE_LMM_NAME[config->lmm], CVODE_ITER_NAME[config->iter]);
      warningStreamPrint(LOG_SOLVER, 0, "Use simflags %s and %s to set.", FLAG_NAME[FLAG_CVODE_LMM], FLAG_NAME[FLAG_CVODE_ITER]);
      warningStreamPrint(LOG_SOLVER, 0, "Use (CV_BDF, CV_NEWTON) for stiff problems (Default) or");
      warningStreamPrint(LOG_SOLVER, 0, "Use (CV_ADAMS, CV_FUNCTIONAL) for nonstiff problems.");
      messageClose(LOG_SOLVER);
    }
  }
  infoStreamPrint(LOG_SOLVER, 0, "CVODE linear multistep method %s", CVODE_LMM_NAME[config->lmm]);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE maximum integration order %s", CVODE_ITER_NAME[config->iter]);

  /* if FLAG_NOEQUIDISTANT_GRID is set, choose ida step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID])
  {
    warningStreamPrint(LOG_SOLVER, 0, "Ignoring user supplied flag \"%s\", using equidistant time grid.", omc_flagValue[FLAG_NOEQUIDISTANT_GRID]);
  }
  config->internalSteps = FALSE;
  infoStreamPrint(LOG_SOLVER, 0, "use equidistant time grid %s", config->internalSteps ? "NO" : "YES");

  /* Set jacobian method */
  if (omc_flag[FLAG_JACOBIAN])
  {
    warningStreamPrint(LOG_SOLVER, 0, "Ignoring user supplied flag \"%s\", using internal dense Jacobian of CVODE.", omc_flagValue[FLAG_JACOBIAN]);
  }
  config->jacobianMethod = INTERNALNUMJAC;
  //config->jacobianMethod = COLOREDNUMJAC;

  /* Minimum absolute step size */
  config->minStepSize = 1e-12; /* TODO: This should be depending on the system? Bigger for 32 bit? */

  /* Maximum absolute step size */
  /* TODO: Check flags FLAG_NOEQUIDISTANT_OUT_FREQ, FLAG_NOEQUIDISTANT_OUT_TIME */
  config->maxStepSize = 0.0; /* default value a.k.a. no maximum step size */

  /* Initial step size */
  if (omc_flag[FLAG_INITIAL_STEP_SIZE])
  {
    config->initStepSize = atof(omc_flagValue[FLAG_INITIAL_STEP_SIZE]);
    assertStreamPrint(threadData, config->initStepSize >= DASSL_STEP_EPS, "Selected initial step size %e is too small.", config->initStepSize);
  }
  else
  {
    config->initStepSize = 0.0; /* use default */
  }

  /* Maximum integration order */
  /* TODO: Add a user flag */
  if (config->lmm == CV_ADAMS)
  {
    config->maxOrderLinearMultistep = ADAMS_Q_MAX;
  }
  else if (config->lmm == CV_BDF)
  {
    config->maxOrderLinearMultistep = BDF_Q_MAX;
  }
  else
  {
    throwStreamPrint(threadData, "Unrecognized linear multistep method. Can't set maximum order.");
  }
  /* Maximum number of nonlinear convergence failures */
  /* TODO: Add a user flag */
  config->maxConvFailPerStep = 10;

  /* Use BDF stability limit detection */
  /* TODO: Add a user flag */
  if (config->lmm == CV_BDF)
  {
    config->BDFStabDetect = FALSE;
  }
  else
  {
    config->BDFStabDetect = FALSE;
  }
}

/**
 * @brief Allocate memory, initialize and set configurations for CVODE solver
 *
 * @param data              Runtime data struckt
 * @param threadData        Thread data for error handling
 * @param solverInfo        Information about main solver. Unused at the moment.
 * @param cvodeData         CVODE solver data struckt.
 * @return int              Return 0 on success.
 */
int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData)
{
  /* Variables */
  int flag;
  int i;
  double *abstol_tmp;
  ANALYTIC_JACOBIAN *jacobian;

  /* Log cvode_initial */
  infoStreamPrint(LOG_SOLVER_V, 0, "### Start initialize of CVODE solver ###");

  /* Set simData */
  cvodeData->simData = (CVODE_USERDATA *)malloc(sizeof(CVODE_USERDATA));
  cvodeData->simData->data = data;
  cvodeData->simData->threadData = threadData;

  cvodeData->isInitialized = FALSE;

  /* Get CVODE settings from user flags */
  cvodeGetConfig(&(cvodeData->config), threadData);

  /* Initialize states */
  cvodeData->y = N_VMake_Serial(data->modelData->nStates, (realtype *)data->localData[0]->realVars);
  assertStreamPrint(threadData, NULL != cvodeData->y, "SUNDIALS_ERROR: N_VMake_Serial failed - returned NULL pointer.");

  /* Allocate CVODE memory block */
  cvodeData->cvode_mem = CVodeCreate(cvodeData->config.lmm, cvodeData->config.iter);
  assertStreamPrint(threadData, NULL != cvodeData->cvode_mem, "CVODE_ERROR: CVodeCreate failed - returned NULL pointer.");

  if (measure_time_flag)
  {
    rt_tick(SIM_TIMER_SOLVER); /* Maybe use SIM_TIMER_OVERHEAD instead? */
  }

  /* Provide problem and solution specifications, allocate internal memory and initializes CVODE */
  flag = CVodeInit(cvodeData->cvode_mem,
                   cvodeRightHandSideODEFunction,
                   data->simulationInfo->startTime,
                   cvodeData->y);
  assertStreamPrint(threadData, flag != CV_MEM_NULL, "CVODE_ERROR: CVodeInit failed with flag CV_MEM_NULL: \"The cvode memory block was not initialized through a previous call to CVodeCreate\"");
  assertStreamPrint(threadData, flag != CV_MEM_FAIL, "CVODE_ERROR: CVodeInit failed with flag CV_MEM_FAIL: \"A memory allocation request has failed.\"");
  assertStreamPrint(threadData, flag != CV_ILL_INPUT, "CVODE_ERROR: CVodeInit failed with flag CV_ILL_INPUT: \"An input argument to CVodeInit has an illegal value.\"");
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeInit failed with unknown flag %i", flag);

  /* Set CVODE relative and absolute error tolerances */
  abstol_tmp = (double *)calloc(data->modelData->nStates, sizeof(double)); /* Is freed with `free(NV_DATA_S(cvodeData->absoluteTolerance));` */
  assertStreamPrint(threadData, abstol_tmp != NULL, "Out of memory.");
  for (i = 0; i < data->modelData->nStates; ++i)
  {
    abstol_tmp[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32) * data->simulationInfo->tolerance;
  }
  cvodeData->absoluteTolerance = N_VMake_Serial(data->modelData->nStates, abstol_tmp);
  assertStreamPrint(threadData, NULL != cvodeData->absoluteTolerance, "SUNDIALS_ERROR: N_VMake_Serial failed - returned NULL pointer.");
  CVodeSVtolerances(cvodeData->cvode_mem, data->simulationInfo->tolerance, cvodeData->absoluteTolerance);
  infoStreamPrint(LOG_SOLVER, 0, "Tolreance %e", data->simulationInfo->tolerance);

  /* Provide cvodeData as user data */
  flag = CVodeSetUserData(cvodeData->cvode_mem, cvodeData);
  assertStreamPrint(threadData, flag != CV_MEM_NULL, "CVODE_ERROR: CVodeSetUserData failed with flag CV_MEM_NULL: \"The cvode mem pointer is NULL.\"");
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeInit failed with unknown flag %i", flag);

  /* Specify the CVDENSE dense linear solver */
  switch (cvodeData->config.jacobianMethod)
  {
  case INTERNALNUMJAC:
  case COLOREDNUMJAC:
    flag = CVDense(cvodeData->cvode_mem, (long int)data->modelData->nStates);
    assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVDense failed with flag %i", flag);
    break;
  default:
    throwStreamPrint(threadData, "Unknown linear solver method %s for CVODE.", JACOBIAN_METHOD[cvodeData->config.jacobianMethod]);
  }

  /* Set Jacobian function */
  jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian) == 0)
  {
  }
  else
  {
  }

  switch (cvodeData->config.jacobianMethod)
  {
  case INTERNALNUMJAC:
    flag = CVDlsSetDenseJacFn(cvodeData->cvode_mem, NULL);
    assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVDlsSetDenseJacFn failed with flag %i", flag);
    infoStreamPrint(LOG_SOLVER, 0, "CVODE uses internal dense numeric jacobian method");
    break;
  case COLOREDNUMJAC:
    flag = CVDlsSetDenseJacFn(cvodeData->cvode_mem, callDenseJacobian);
    assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVDlsSetDenseJacFn failed with flag %i", flag);
    infoStreamPrint(LOG_SOLVER, 0, "CVODE uses colored dense numeric jacobian method");
    break;
  default:
    throwStreamPrint(threadData, "Unknown linear solver method %s for CVODE.", JACOBIAN_METHOD[cvodeData->config.jacobianMethod]);
  }

  /* Set root finding function */
  solverInfo->solverRootFinding = 1;
  flag = CVodeRootInit(cvodeData->cvode_mem, data->modelData->nZeroCrossings, rootsFunctionCVODE);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeRootInit failed with flag %i", flag);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE uses internal root finding method %s", solverInfo->solverRootFinding ? "YES" : "NO");

  /* ### Set optional settings ### */
  /* Minimum absolute step size */
  flag = CVodeSetMinStep(cvodeData->cvode_mem, cvodeData->config.minStepSize);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMinStep failed with flag %i", flag);

  /* Maximum absolute step size */
  flag = CVodeSetMaxStep(cvodeData->cvode_mem, cvodeData->config.maxStepSize);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxStep failed with flag %i", flag);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE maximum absolut step size %g", cvodeData->config.maxStepSize);

  /* Initial step size */
  flag = CVodeSetInitStep(cvodeData->cvode_mem, cvodeData->config.initStepSize);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetInitStep failed with flag %i", flag);
  if (cvodeData->config.initStepSize == 0)
  {
    infoStreamPrint(LOG_SOLVER, 0, "CVODE initial step size is set automatically");
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "CVODE initial step size %g", cvodeData->config.initStepSize);
  }

  /* Maximum integration order */
  flag = CVodeSetMaxOrd(cvodeData->cvode_mem, cvodeData->config.maxOrderLinearMultistep);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxOrd failed with flag %i", flag);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE maximum integration order %d", cvodeData->config.maxOrderLinearMultistep);

  /* Maximum number of nonlinear convergence failures */
  flag = CVodeSetMaxConvFails(cvodeData->cvode_mem, cvodeData->config.maxConvFailPerStep);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxConvFails failed with flag %i", flag);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE maximum number of nonlinear convergence failures permitted during one step %d", cvodeData->config.maxConvFailPerStep);

  /* BDF stability limit detection */
  flag = CVodeSetStabLimDet(cvodeData->cvode_mem, cvodeData->config.BDFStabDetect);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetStabLimDet failed with flag %i", flag);
  infoStreamPrint(LOG_SOLVER, 0, "CVODE BDF stability limit detection algorithm %s", cvodeData->config.maxConvFailPerStep ? "ON" : "OFF");

  /* TODO: Add stuff in cvodeGetConfig for this */
  flag = CVodeSetMaxNonlinIters(cvodeData->cvode_mem, 5); /* Maximum number of iterations */
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxNonlinIters failed with flag %i", flag);
  flag = CVodeSetMaxErrTestFails(cvodeData->cvode_mem, 100); /* Maximum number of error test failures */
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxErrTestFails failed with flag %i", flag);
  flag = CVodeSetMaxNumSteps(cvodeData->cvode_mem, 1000); /* Maximum number of steps */
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetMaxNumSteps failed with flag %i", flag);

  /* Log cvode_initial */
  infoStreamPrint(LOG_SOLVER_V, 0, "### Finished initialize of CVODE solver successfully ###");

  if (measure_time_flag)
    rt_clear(SIM_TIMER_SOLVER); /* Initialization should not add this timer... */

  return 0;
}

/**
 * @brief Reinitialize CVODE solver
 * * Provide required problem specifications and reinitialize CVODE.
 * If scaling is used y will be scaled accordingly.
 *
 * @param data              Runtime data struckt.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Information about main solver. Unused at the moment.
 * @param cvodeData         CVODE solver data struckt.
 * @return int              Return 0 on success.
 */
int cvode_solver_reinit(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData)
{
  /* Variables */
  int flag, i;

  infoStreamPrint(LOG_SOLVER, 0, "Re-initialized CVODE Solver");

  /* Calculate matrix for residual scaling */
  /* TODO: Add scaling */

  flag = CVodeReInit(cvodeData->cvode_mem,
                     solverInfo->currentTime,
                     cvodeData->y);
  assertStreamPrint(threadData, flag != CV_MEM_NULL, "CVODE_ERROR: CVodeInit failed with flag CV_MEM_NULL: \"The cvode memory block was not initialized through a previous call to CVodeCreate\"");
  assertStreamPrint(threadData, flag != CV_NO_MALLOC, "CVODE_ERROR: CVodeInit failed with flag CV_NO_MALLOC: \"Memory space for the cvode memory block was not allocated through a previous call to CVodeInit.\"");
  assertStreamPrint(threadData, flag != CV_ILL_INPUT, "CVODE_ERROR: CVodeInit failed with flag CV_ILL_INPUT: \"An input argument to CVodeInit has an illegal value.\"");
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeInit failed with unknown flag %i", flag);

  /* Calculate matrix for residual scaling */
  /* TODO: Add rescaling */

  return 0;
}

/**
 * @brief Deinitialize CVODE data
 *
 * @param cvodeData
 * @return int          Return 0 on success.
 */
int cvode_solver_deinitial(CVODE_SOLVER *cvodeData)
{
  free(cvodeData->simData);
  N_VDestroy_Serial(cvodeData->y);

  free(NV_DATA_S(cvodeData->absoluteTolerance));
  N_VDestroy_Serial(cvodeData->absoluteTolerance);

  CVodeFree(&cvodeData->cvode_mem);

  free(cvodeData);

  /* Log cvode_solver_deinitial */
  infoStreamPrint(LOG_SOLVER_V, 1, "### Finished deinitialization of CVODE solver successfully ###");
  return 0;
}

/**
 * @brief Save solver statistics.
 *
 * If flag LOG_SOLVER_V is provided even more statistics will be collected.
 *
 * @param cvode_mem         Pointer to CVODE memory block.
 * @param solverStatsTmp    Pointer to solverStatsTmp of solverInfo.
 * @param threadData        Thread data for error handling.
 */
void cvode_save_statistics(void *cvode_mem, unsigned int *solverStatsTmp, threadData_t *threadData)
{
  /* Variables */
  long int tmp1, tmp2;
  double dtmp;
  int flag;

  /* Get number of internal steps taken by CVODE */
  tmp1 = 0;
  flag = CVodeGetNumSteps(cvode_mem, &tmp1);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVODEGetNumSteps failed with flag %i", flag);
  solverStatsTmp[0] = tmp1;

  /* Get number of right hand side evaluations */
  /* TODO: Is it okay to count number of rhs evaluations instead of residual evaluations? */
  tmp1 = 0;
  flag = CVodeGetNumRhsEvals(cvode_mem, &tmp1);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeGetNumRhsEvals failed with flag %i", flag);
  solverStatsTmp[1] = tmp1;

  /* Get number of right hand side evaluations for Jacobian */
  /* TODO: Is it okay to add this to the Jacobian? */
  tmp1 = 0;
  flag = CVDlsGetNumRhsEvals(cvode_mem, &tmp1);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVDlsGetNumRhsEvals failed with flag %i", flag);
  solverStatsTmp[2] = tmp1;

  /* Get number of local error test failures */
  tmp1 = 0;
  flag = CVodeGetNumErrTestFails(cvode_mem, &tmp1);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVODEGetNumErrTestFails failed with flag %i", flag);
  solverStatsTmp[3] = tmp1;

  /* Get number of nonlinear convergence failures */
  tmp1 = 0;
  flag = CVodeGetNumNonlinSolvConvFails(cvode_mem, &tmp1);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVODEGetNumNonlinSolvConvFails failed with flag %i", flag);
  solverStatsTmp[4] = tmp1;

  /* Get even more statistics */
  if (useStream[LOG_SOLVER_V])
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "### CVODEStats ###");
    /* Nonlinear stats */
    tmp1 = tmp2 = 0;
    flag = CVodeGetNonlinSolvStats(cvode_mem, &tmp1, &tmp2);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear iterations performed: %ld", tmp1);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear convergence failures that have occurred: %ld", tmp2);

    /* Others stats */
    flag = CVodeGetTolScaleFactor(cvode_mem, &dtmp);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Suggested scaling factor for user tolerances: %g", dtmp);

    flag = CVodeGetNumLinSolvSetups(cvode_mem, &tmp1);
    infoStreamPrint(LOG_SOLVER_V, 0, " ## Number of calls made to the linear solver setup function: %ld", tmp1);

    messageClose(LOG_SOLVER_V);
  }
}

/**
 * @brief Main CVODE function to make a step.
 *
 * Integrates on current time intervall.
 *
 * @param data              Runtime data struckt
 * @param threadData        Thread data for error handling
 * @param cvodeData         CVODE solver data struckt.
 * @return int            Returns 0 on success and return flag from CVode else.
 */
int cvode_solver_step(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
  /* Variabes */
  int saveJumpState;
  int flag;
  int retVal = 0;
  int finished = FALSE;
  double tout = 0;

  CVODE_SOLVER *cvodeData;
  SIMULATION_DATA *simulationData;
  SIMULATION_DATA *simulationDataOld;
  MODEL_DATA *modelData;
  SIMULATION_INFO *simulationInfo;

  /* Measure time */
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  /* Access data */
  cvodeData = (CVODE_SOLVER *)solverInfo->solverData;
  simulationData = data->localData[0];
  simulationDataOld = data->localData[1];
  modelData = (MODEL_DATA *)data->modelData;
  simulationInfo = data->simulationInfo;

  /* Set work array */
  N_VSetArrayPointer(data->localData[0]->realVars, cvodeData->y);

  /* Reinitialize after event or at first call to cvode_solver_step() */
  if (solverInfo->didEventStep || !cvodeData->isInitialized)
  {
    cvode_solver_reinit(data, threadData, solverInfo, cvodeData);
    cvodeData->isInitialized = TRUE;
  }

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* Try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /* Check current step size */
  if (solverInfo->currentStepSize < DASSL_STEP_EPS)
  {
    throwStreamPrint(threadData, "##CVODE## Desired step to small!");
    infoStreamPrint(LOG_SOLVER, 0, "Interpolate constant");

    /* Constant extrapolation */
    /* TODO: Interpolate linear solution */
    simulationData->timeValue = solverInfo->currentTime + solverInfo->currentStepSize;
    if (measure_time_flag)
      rt_accumulate(SIM_TIMER_SOLVER);
    data->callback->functionODE(data, threadData);
    solverInfo->currentTime = simulationData->timeValue;

    return 0;
  }

  /* Set stop time */
  tout = solverInfo->currentTime + solverInfo->currentStepSize;
  flag = CVodeSetStopTime(cvodeData->cvode_mem, tout);
  assertStreamPrint(threadData, flag >= 0, "CVODE_ERROR: CVodeSetStopTime failed with flag %i", flag);

  /* Integrator loop */
  do
  {
    infoStreamPrint(LOG_SOLVER, 1, "##CVODE## new step from %.15g to %.15g", solverInfo->currentTime, tout);

    /* Read input vars (exclude from timer) */
    if (measure_time_flag)
      rt_accumulate(SIM_TIMER_SOLVER);
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    if (measure_time_flag)
      rt_tick(SIM_TIMER_SOLVER);

    /* TODO: Add scaling */

    /* Call CVODE integrator */
    flag = CVode(cvodeData->cvode_mem,
                 tout,
                 cvodeData->y,
                 &(solverInfo->currentTime),
                 CV_NORMAL);

    /* Error handling */
    if ((flag == CV_SUCCESS || flag == CV_TSTOP_RETURN) && solverInfo->currentTime >= tout)
    {
      infoStreamPrint(LOG_SOLVER, 0, "##CVODE## step done to time = %.15g", solverInfo->currentTime);
      finished = TRUE;
    }
    else if (flag == CV_ROOT_RETURN)
    {
      infoStreamPrint(LOG_SOLVER, 0, "##CVODE## root found at time = %.15g", solverInfo->currentTime);
      finished = TRUE;
    }
    else
    {
      infoStreamPrint(LOG_STDOUT, 0, "##CVODE## %d error occurred at time = %.15g", flag, solverInfo->currentTime);
      finished = TRUE;
      retVal = flag;
    }

    /* Closing new step message */
    messageClose(LOG_SOLVER);

    /* Set time to current time */
    simulationData->timeValue = solverInfo->currentTime;
  } while (!finished);

  /* Catch */
#if !defined(OMC_EMCC)
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
  threadData->currentErrorStage = saveJumpState;

  /* If a state event occured no sample event needs to be activated */
  if (simulationInfo->sampleActivated && solverInfo->currentTime < simulationInfo->nextSampleEvent)
  {
    simulationInfo->sampleActivated = 0 /* false */;
  }

  /* Save statistics */
  cvode_save_statistics(cvodeData->cvode_mem, solverInfo->solverStatsTmp, threadData);

  infoStreamPrint(LOG_SOLVER, 0, "##CVODE## Finished Integrator step.");
  /* Measure time */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}

#endif /* #ifdef WITH_SUNDIALS */
