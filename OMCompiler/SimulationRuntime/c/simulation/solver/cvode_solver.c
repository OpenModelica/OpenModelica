/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "cvode_solver.h"

/* OMC headers */
#include "../../util/context.h"
#include "../options.h"
#include "../solver/external_input.h"
#include "model_help.h"
#include "omc_math.h"

#include "../../util/omc_error.h"
#include "../../gc/omc_gc.h"

#include "dassl.h"
#include "epsilon.h"


#ifdef WITH_SUNDIALS

#define CVODE_LMM_MAX 2
const char *CVODE_LMM_NAME[CVODE_LMM_MAX + 1] = {
    "undefined",
    "CV_ADAMS", /* 1 */
    "CV_BDF"    /* 2 */
};

const char *CVODE_LMM_DESC[CVODE_LMM_MAX + 1] = {
    "undefined",
    "Adams-Moulton linear multistep method. Use together with CV_ITER_FIXED_POINT for nonstiff problems.",
    "BDF linear multistep method. Use together with CV_ITER_NEWTON for stiff problems. Default option."};

#define CVODE_ITER_MAX 2
const char *CVODE_ITER_NAME[CVODE_ITER_MAX + 1] = {
    "undefined",
    "CV_ITER_FIXED_POINT", /* 1 */
    "CV_ITER_NEWTON"       /* 2 */
};

const char *CVODE_ITER_DESC[CVODE_ITER_MAX + 1] = {
    "undefined",
    "Nonlinear system solution through fixed-point iterations",
    "Nonlinear system solution through Newton iterations"
};

/* Internal function prototypes */
int cvodeRightHandSideODEFunction(realtype time, N_Vector y, N_Vector ydot, void *userData);
void cvodeGetConfig(CVODE_CONFIG *config, threadData_t *threadData, booleantype isFMI);

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

  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### eval cvodeRightHandSideODEFunction ###");

  /* TODO: Add scaling of y and ydot */

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, time, CONTEXT_ODE);
  }
  /* Set time */
  data->localData[0]->timeValue = time;

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_INTEGRATOR;

  /* try */
#if !defined(OMC_EMCC)
  MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif

  /*
   fix issue https://github.com/OpenModelica/OpenModelica/issues/13582
   Update y*/
  for (i = 0; i < cvodeData->N; i++)
  {
    data->localData[0]->realVars[i] = NV_Ith_S(y, i);
  }

  /* Debug print for states (input) */
  if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V))
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "y at time=%f", time);
    for (i = 0; i < cvodeData->N; i++)
    {
      infoStreamPrint(OMC_LOG_SOLVER_V, 0, "y[%ld] = %e", i, NV_Ith_S(y, i));
    }
    messageClose(OMC_LOG_SOLVER_V);
  }

  /* Read input vars (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
#ifndef OMC_FMI_RUNTIME
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
#endif
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  /* eval function ODE (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
  data->callback->functionODE(data, threadData);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  /* Update ydot */
  for (i = 0; i < cvodeData->N; i++)
  {
    NV_Ith_S(ydot, i) = data->localData[0]->realVars[cvodeData->N + i];
  }

  /* Debug print for derived states (output) */
  if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER_V))
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "ydot at time=%f", time);
    for (i = 0; i < cvodeData->N; i++)
    {
      infoStreamPrint(OMC_LOG_SOLVER_V, 0, "ydot[%ld] = %e", i, NV_Ith_S(ydot, i));
    }
    messageClose(OMC_LOG_SOLVER_V);
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
  messageClose(OMC_LOG_SOLVER_V);
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}


/**
 * @brief Calculates jacobian matrix numerical with coloring
 *
 * Not implemented!
 *
 * @param currentTime
 * @param y
 * @param fy
 * @param Jac
 * @param userData
 * @return int
 */
static int jacColoredNumericalDense(double currentTime, N_Vector y, N_Vector fy,
                                    SUNMatrix Jac, void *userData)
{
  /* TODO: Add stuff for colored dense jacobian */
  return -1;
}


/**
 * @brief Wrapper function to call dense Jacobian
 *
 * Not usable at the moment!
 *
 * @param t           Independent variable (time).
 * @param y           Dependent variable vector.
 * @param fy          Current value of f(t,y).
 * @param Jac         Output Jacobian.
 * @param user_data   User supplied data.
 * @param tmp1        Pointer to allocated memory to be used as temp storage or work space.
 * @param tmp2        "
 * @param tmp3        "
 * @return int        Returns 0 on success, positive value for recoverable error, negative value for error.
 */
static int callDenseJacobian(double t, N_Vector y, N_Vector fy,
                             SUNMatrix Jac, void *user_data,
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
    throwStreamPrint(threadData, "##CVODE## Something went wrong while obtain jacobian matrix!");
  }

  /* debug */
  if (OMC_ACTIVE_STREAM(OMC_LOG_JAC))
  {
    dumpJac = _omc_createMatrix(cvodeData->N, cvodeData->N, SM_DATA_D(Jac));
    _omc_printMatrix(dumpJac, "CVODE-Solver: Matrix A", OMC_LOG_JAC);
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
  CVODE_SOLVER *cvodeData = (CVODE_SOLVER *)userData;
  DATA *data = (DATA *)(((CVODE_USERDATA *)cvodeData->simData)->data);
  threadData_t *threadData = (threadData_t *)(((CVODE_USERDATA *)((CVODE_SOLVER *)userData)->simData)->threadData);

  int saveJumpState;

  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### eval rootsFunctionCVODE ###");

  if (data->simulationInfo->currentContext == CONTEXT_ALGEBRAIC)
  {
    setContext(data, time, CONTEXT_EVENTS);
  }

  /* TODO: re-scale cvodeData->y to evaluate the equations */

  saveJumpState = threadData->currentErrorStage;
  threadData->currentErrorStage = ERROR_EVENTSEARCH;

  data->localData[0]->timeValue = time;

  /* Read input vars (exclude from timer) */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);
#ifndef OMC_FMI_RUNTIME
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
#endif
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
  messageClose(OMC_LOG_SOLVER_V);
  if (measure_time_flag)
    rt_tick(SIM_TIMER_SOLVER);

  return 0;
}

/**
 * @brief Get settings for CVODE from user flags.
 *
 * If the user didn't provide any flags following settings will be chosen:
 *   config->lmm = CV_BDF
 *   config->iter = CV_ITER_NEWTON
 *
 * @param cvodeData       CVODE solver data struckt
 * @param threadData      Thread data for error handling
 */
void cvodeGetConfig(CVODE_CONFIG *config, threadData_t *threadData, booleantype isFMI)
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
      if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_SOLVER))
      {
        warningStreamPrint(OMC_LOG_SOLVER, 1, "Unrecognized linear multistep method %s for CVODE, current options are:", (const char *)omc_flagValue[FLAG_CVODE_LMM]);
        for (i = 1; i <= CVODE_LMM_MAX; ++i)
        {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "%s [%s]", CVODE_LMM_NAME[i], CVODE_LMM_DESC[i]);
        }
        messageClose(OMC_LOG_SOLVER);
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
    if (strcmp((const char *)omc_flagValue[FLAG_CVODE_ITER], CVODE_ITER_NAME[CV_ITER_FIXED_POINT]))
    {
      config->iter = CV_ITER_FIXED_POINT;
    }
    else if (strcmp((const char *)omc_flagValue[FLAG_CVODE_ITER], CVODE_ITER_NAME[CV_ITER_NEWTON]))
    {
      config->iter = CV_ITER_NEWTON;
    }
    else
    {
      if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_SOLVER))
      {
        warningStreamPrint(OMC_LOG_SOLVER, 1, "Unrecognized type of nonlinear solver iteration %s for CVODE, current options are:", (const char *)omc_flagValue[FLAG_CVODE_ITER]);
        for (i = 1; i <= CVODE_ITER_MAX; ++i)
        {
          warningStreamPrint(OMC_LOG_SOLVER, 0, "%s [%s]", CVODE_ITER_NAME[i], CVODE_ITER_DESC[i]);
        }
        messageClose(OMC_LOG_SOLVER);
      }
      throwStreamPrint(threadData, "Unrecognized type of nonlinear solver iteration %s for CVODE.", (const char *)omc_flagValue[FLAG_CVODE_LMM]);
    }
  }
  else /* No user provided flag */
  {
    if (config->lmm == CV_ADAMS)
    {
      config->iter = CV_ITER_FIXED_POINT;
    }
    else
    {
      config->iter = CV_ITER_NEWTON;
    }
  }

  /* Check for compability of lmn and iter */
  if ((config->lmm == CV_ADAMS && config->iter != CV_ITER_FIXED_POINT) ||
      (config->lmm == CV_BDF && config->iter != CV_ITER_NEWTON))
  {
    if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_SOLVER))
    {
      warningStreamPrint(OMC_LOG_SOLVER, 1, "Combination of %s and %s not recommended.", CVODE_LMM_NAME[config->lmm], CVODE_ITER_NAME[config->iter]);
      warningStreamPrint(OMC_LOG_SOLVER, 0, "Use simflags %s and %s to set.", FLAG_NAME[FLAG_CVODE_LMM], FLAG_NAME[FLAG_CVODE_ITER]);
      warningStreamPrint(OMC_LOG_SOLVER, 0, "Use (CV_BDF, CV_NEWTON) for stiff problems (Default) or");
      warningStreamPrint(OMC_LOG_SOLVER, 0, "Use (CV_ADAMS, CV_FUNCTIONAL) for nonstiff problems.");
      messageClose(OMC_LOG_SOLVER);
    }
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE linear multistep method %s", CVODE_LMM_NAME[config->lmm]);
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE maximum integration order %s", CVODE_ITER_NAME[config->iter]);

  /* if FLAG_NOEQUIDISTANT_GRID is set, choose ida step method */
  if (omc_flag[FLAG_NOEQUIDISTANT_GRID])
  {
    warningStreamPrint(OMC_LOG_SOLVER, 0, "Ignoring user supplied flag \"%s\", using equidistant time grid.", omc_flagValue[FLAG_NOEQUIDISTANT_GRID]);
  }
  config->internalSteps = FALSE;    // TODO: Setting not used yet
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE use equidistant time grid %s", config->internalSteps ? "NO" : "YES");

  /* Set jacobian method */
  if (omc_flag[FLAG_JACOBIAN])
  {
    warningStreamPrint(OMC_LOG_SOLVER, 0, "Ignoring user supplied flag \"%s\", using internal dense Jacobian of CVODE.", omc_flagValue[FLAG_JACOBIAN]);
  }
  config->jacobianMethod = INTERNALNUMJAC;
  //config->jacobianMethod = COLOREDNUMJAC; // Not implemented yet!

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
    config->maxOrderLinearMultistep = 12 /* From ADAMS_Q_MAX */;
  }
  else if (config->lmm == CV_BDF)
  {
    config->maxOrderLinearMultistep = 5 /* From BDF_Q_MAX */;
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

  if(omc_flag[FLAG_NO_ROOTFINDING] || isFMI)
  {
    config->solverRootFinding = FALSE;
  }
  else
  {
    config->solverRootFinding = TRUE;
  }
}

/**
 * @brief Allocate memory, initialize and set configurations for CVODE solver
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param solverInfo        Information about main solver. Unused at the moment.
 * @param cvodeData         CVODE solver data struct.
 * @return int              Return 0 on success.
 */
int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData, int isFMI)
{
  /* Variables */
  int flag;
  int i;
  double *abstol_tmp;
  JACOBIAN *jacobian;

  /* Log cvode_initial */
  infoStreamPrint(OMC_LOG_SOLVER_V, 0, "### Start initialize of CVODE solver ###");

  /* Set simData */
  cvodeData->simData = (CVODE_USERDATA *)malloc(sizeof(CVODE_USERDATA));
  cvodeData->simData->data = data;
  cvodeData->simData->threadData = threadData;

  cvodeData->isInitialized = FALSE;

  /* Get CVODE settings from user flags */
  cvodeGetConfig(&(cvodeData->config), threadData, isFMI);

  /* Initialize states */
  cvodeData->N = (long int)data->modelData->nStates;
  cvodeData->y = N_VMake_Serial(cvodeData->N, (realtype *)data->localData[0]->realVars);
  assertStreamPrint(threadData, NULL != cvodeData->y, "SUNDIALS_ERROR: N_VMake_Serial failed - returned NULL pointer.");

  /* Allocate CVODE memory block */
  cvodeData->cvode_mem = CVodeCreate(cvodeData->config.lmm);
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
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeInit");

  /* Set CVODE relative and absolute error tolerances */
  abstol_tmp = (double *)calloc(cvodeData->N, sizeof(double)); /* Is freed with `free(NV_DATA_S(cvodeData->absoluteTolerance));` */
  assertStreamPrint(threadData, abstol_tmp != NULL, "Out of memory.");
  for (i = 0; i < cvodeData->N; ++i)
  {
    abstol_tmp[i] = fmax(fabs(data->modelData->realVarsData[i].attribute.nominal), 1e-32) * data->simulationInfo->tolerance;
  }
  cvodeData->absoluteTolerance = N_VMake_Serial(cvodeData->N, abstol_tmp);
  assertStreamPrint(threadData, NULL != cvodeData->absoluteTolerance, "SUNDIALS_ERROR: N_VMake_Serial failed - returned NULL pointer.");
  flag = CVodeSVtolerances(cvodeData->cvode_mem, data->simulationInfo->tolerance, cvodeData->absoluteTolerance);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSVtolerances");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE Using relative error tolerance %e", data->simulationInfo->tolerance);

  /* Provide cvodeData as user data */
  flag = CVodeSetUserData(cvodeData->cvode_mem, cvodeData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetUserData");

  /* Set error handler */
  flag = CVodeSetErrHandlerFn(cvodeData->cvode_mem, cvodeErrorHandlerFunction, cvodeData);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetErrHandlerFn");

  /* Set linear solver used by CVODE */
  cvodeData->y_linSol = N_VNew_Serial(cvodeData->N);
  switch (cvodeData->config.jacobianMethod)
  {
  case INTERNALNUMJAC:
  case COLOREDNUMJAC:
    cvodeData->J = SUNDenseMatrix(cvodeData->N, cvodeData->N);
    cvodeData->linSol = SUNLinSol_Dense(cvodeData->y_linSol, cvodeData->J);
    assertStreamPrint(threadData, NULL != cvodeData->linSol, "##CVODE## SUNLinSol_Dense failed.");
    break;
  default:
    throwStreamPrint(threadData, "##CVODE## Unknown linear solver method %s for CVODE.", JACOBIAN_METHOD_NAME[cvodeData->config.jacobianMethod]);
  }
  flag = CVodeSetLinearSolver(cvodeData->cvode_mem, cvodeData->linSol, cvodeData->J);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CVLS_FLAG, "CVodeSetLinearSolver");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE Using dense internal linear solver SUNLinSol_Dense.");

  /* Set Jacobian function */
  jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
  if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian) == 0 /* Jac present */)
  {
    // TODO: Implement Jacobian evaluation with analytic Jacobian
  }
  else
  {
    // Do Nothing
  }

  switch (cvodeData->config.jacobianMethod)
  {
  case INTERNALNUMJAC:
    flag = CVodeSetJacFn(cvodeData->cvode_mem, NULL);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_CVLS_FLAG, "CVodeSetJacFn");
    infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE Use internal dense numeric jacobian method.");
    break;
  case COLOREDNUMJAC:
    throwStreamPrint(threadData, "##CVODE## LJacobian method %s not yet implemented.", JACOBIAN_METHOD_NAME[cvodeData->config.jacobianMethod]);
    //flag = CVodeSetJacFn(cvodeData->cvode_mem, callDenseJacobian);
    //checkReturnFlag_SUNDIALS(flag, SUNDIALS_CVLS_FLAG, "CVodeSetJacFn");
    //infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE Use colored dense numeric jacobian method.");
    break;
  default:
    throwStreamPrint(threadData, "##CVODE## Jacobian method %s not yet implemented.", JACOBIAN_METHOD_NAME[cvodeData->config.jacobianMethod]);
  }

  /* Set optional non-linear solver module */
  switch (cvodeData->config.iter)
  {
    case CV_ITER_FIXED_POINT:
      cvodeData->y_nonLinSol = N_VNew_Serial(cvodeData->N);
      cvodeData->nonLinSol = SUNNonlinSol_FixedPoint(cvodeData->y_nonLinSol, cvodeData->N /* Num acceleration vectors for Anderson's method, m <= dimension*/);
      assertStreamPrint(threadData, NULL != cvodeData->nonLinSol, "##CVODE## SUNNonlinSol_FixedPoint failed.");
      flag = CVodeSetNonlinearSolver(cvodeData->cvode_mem, cvodeData->nonLinSol);
      checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetNonlinearSolver");
    case CV_ITER_NEWTON:
      /* Default option, no allocation needed */
      cvodeData->y_nonLinSol = NULL;
      cvodeData->nonLinSol = NULL;
      break;
    case CV_ITER_MAX:
      throwStreamPrint(threadData, "##CVODE## Non-linear solver method not set.");
    default:
      throwStreamPrint(threadData, "##CVODE## Unknown non-linear solver method %s.", CVODE_ITER_NAME[cvodeData->config.iter]);
  }

  /* Set root finding function */
  if (cvodeData->config.solverRootFinding)
  {
    solverInfo->solverRootFinding = 1;
    flag = CVodeRootInit(cvodeData->cvode_mem, data->modelData->nZeroCrossings, rootsFunctionCVODE);
    checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeRootInit");
  }
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE uses internal root finding method %s", solverInfo->solverRootFinding ? "YES" : "NO");

  /* ### Set optional settings ### */
  /* Minimum absolute step size */
  flag = CVodeSetMinStep(cvodeData->cvode_mem, cvodeData->config.minStepSize);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMinStep");

  /* Maximum absolute step size */
  flag = CVodeSetMaxStep(cvodeData->cvode_mem, cvodeData->config.maxStepSize);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxStep");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE maximum absolut step size %g", cvodeData->config.maxStepSize);

  /* Initial step size */
  flag = CVodeSetInitStep(cvodeData->cvode_mem, cvodeData->config.initStepSize);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetInitStep");
  if (cvodeData->config.initStepSize == 0)
  {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE initial step size is set automatically");
  }
  else
  {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE initial step size %g", cvodeData->config.initStepSize);
  }

  /* Maximum integration order */
  flag = CVodeSetMaxOrd(cvodeData->cvode_mem, cvodeData->config.maxOrderLinearMultistep);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxOrd");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE maximum integration order %d", cvodeData->config.maxOrderLinearMultistep);

  /* Maximum number of nonlinear convergence failures */
  flag = CVodeSetMaxConvFails(cvodeData->cvode_mem, cvodeData->config.maxConvFailPerStep);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxConvFails");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE maximum number of nonlinear convergence failures permitted during one step %d", cvodeData->config.maxConvFailPerStep);

  /* BDF stability limit detection */
  flag = CVodeSetStabLimDet(cvodeData->cvode_mem, cvodeData->config.BDFStabDetect);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetStabLimDet");
  infoStreamPrint(OMC_LOG_SOLVER, 0, "CVODE BDF stability limit detection algorithm %s", cvodeData->config.BDFStabDetect ? "ON" : "OFF");

  /* TODO: Add stuff in cvodeGetConfig for this */
  flag = CVodeSetMaxNonlinIters(cvodeData->cvode_mem, 5); /* Maximum number of iterations */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxNonlinIters");
  flag = CVodeSetMaxErrTestFails(cvodeData->cvode_mem, 100); /* Maximum number of error test failures */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxErrTestFails");
  flag = CVodeSetMaxNumSteps(cvodeData->cvode_mem, 1000); /* Maximum number of steps */
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetMaxNumSteps");

  /* Log cvode_initial */
  infoStreamPrint(OMC_LOG_SOLVER_V, 0, "### Finished initialize of CVODE solver successfully ###");

  if (measure_time_flag)
  {
    rt_clear(SIM_TIMER_SOLVER); /* Initialization should not add to this timer... */
  }

  return 0;
}

/**
 * @brief Reinitialize CVODE solver
 * Provide required problem specifications and reinitialize CVODE.
 * If scaling is used y will be scaled accordingly.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Information about main solver. Unused at the moment.
 * @param cvodeData         CVODE solver data struckt.
 * @return int              Return 0 on success.
 */
int cvode_solver_reinit(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData)
{
  /* Variables */
  int flag, i;

  infoStreamPrint(OMC_LOG_SOLVER, 0, "Re-initialized CVODE Solver");

  /* Calculate matrix for residual scaling */
  /* TODO: Add scaling */

  flag = CVodeReInit(cvodeData->cvode_mem,
                     solverInfo->currentTime,
                     cvodeData->y);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeReInit");

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
  /* Free work arrays */
  N_VDestroy_Serial(cvodeData->y);
  free(NV_DATA_S(cvodeData->absoluteTolerance));
  N_VDestroy_Serial(cvodeData->absoluteTolerance);

  /* Free linear solver data */
  N_VDestroy_Serial(cvodeData->y_linSol);
  SUNMatDestroy(cvodeData->J);
  SUNLinSolFree(cvodeData->linSol);

  /* Free non-linear solver data */
  N_VDestroy_Serial(cvodeData->y_nonLinSol);
  SUNNonlinSolFree(cvodeData->nonLinSol);

  /* Free CVODE internal data */
  CVodeFree(&cvodeData->cvode_mem);
  free(cvodeData->simData);

  free(cvodeData);

  /* Log cvode_solver_deinitial */
  infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### Finished deinitialization of CVODE solver successfully ###");
  return 0;
}

/**
 * @brief Save solver statistics.
 *
 * If flag OMC_LOG_SOLVER_V is provided even more statistics will be collected.
 *
 * @param cvode_mem         Pointer to CVODE memory block.
 * @param solverStats       Pointer to solverStats of solverInfo.
 * @param threadData        Thread data for error handling.
 */
void cvode_save_statistics(void *cvode_mem, SOLVERSTATS *solverStats, threadData_t *threadData)
{
  /* Variables */
  long int tmp1, tmp2;
  double dtmp;
  int flag;

  /* Get number of internal steps taken by CVODE */
  tmp1 = 0;
  flag = CVodeGetNumSteps(cvode_mem, &tmp1);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeGetNumSteps");
  solverStats->nStepsTaken = tmp1;

  /* Get number of right hand side evaluations */
  /* TODO: Is it okay to count number of rhs evaluations instead of residual evaluations? */
  tmp1 = 0;
  flag = CVodeGetNumRhsEvals(cvode_mem, &tmp1);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeGetNumRhsEvals");
  solverStats->nCallsODE = tmp1;

  /* Get number of Jacobian evaluations */
  tmp1 = 0;
  flag = CVodeGetNumJacEvals(cvode_mem, &tmp1);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CVLS_FLAG, "CVodeGetNumJacEvals");
  solverStats->nCallsJacobian = tmp1;

  /* Get number of local error test failures */
  tmp1 = 0;
  flag = CVodeGetNumErrTestFails(cvode_mem, &tmp1);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeGetNumErrTestFails");
  solverStats->nErrorTestFailures = tmp1;

  /* Get number of nonlinear convergence failures */
  tmp1 = 0;
  flag = CVodeGetNumNonlinSolvConvFails(cvode_mem, &tmp1);
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeGetNumNonlinSolvConvFails");
  solverStats->nConvergenceTestFailures = tmp1;

  /* Get even more statistics */
  if (omc_useStream[OMC_LOG_SOLVER_V])
  {
    infoStreamPrint(OMC_LOG_SOLVER_V, 1, "### CVODEStats ###");
    /* Nonlinear stats */
    tmp1 = tmp2 = 0;
    flag = CVodeGetNonlinSolvStats(cvode_mem, &tmp1, &tmp2);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear iterations performed: %ld", tmp1);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Cumulative number of nonlinear convergence failures that have occurred: %ld", tmp2);

    /* Others stats */
    flag = CVodeGetTolScaleFactor(cvode_mem, &dtmp);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Suggested scaling factor for user tolerances: %g", dtmp);

    flag = CVodeGetNumLinSolvSetups(cvode_mem, &tmp1);
    infoStreamPrint(OMC_LOG_SOLVER_V, 0, " ## Number of calls made to the linear solver setup function: %ld", tmp1);

    messageClose(OMC_LOG_SOLVER_V);
  }
}

/**
 * @brief Main CVODE function to make a step.
 *
 * Integrates on current time interval.
 *
 * @param data              Runtime data struct
 * @param threadData        Thread data for error handling
 * @param cvodeData         CVODE solver data struct.
 * @return int              Returns 0 on success and return flag from CVode else.
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
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Interpolate constant");

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
  checkReturnFlag_SUNDIALS(flag, SUNDIALS_CV_FLAG, "CVodeSetStopTime");
  /* Integrator loop */
  do
  {
    infoStreamPrint(OMC_LOG_SOLVER, 1, "##CVODE## new step from %.15g to %.15g", solverInfo->currentTime, tout);

    /* Read input vars (exclude from timer) */
    if (measure_time_flag)
      rt_accumulate(SIM_TIMER_SOLVER);
#ifndef OMC_FMI_RUNTIME
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
#endif
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
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##CVODE## step done to time = %.15g", solverInfo->currentTime);
      finished = TRUE;
    }
    else if (flag == CV_ROOT_RETURN)
    {
      infoStreamPrint(OMC_LOG_SOLVER, 0, "##CVODE## root found at time = %.15g", solverInfo->currentTime);
      finished = TRUE;
    }
    else
    {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "##CVODE## %d error occurred at time = %.15g", flag, solverInfo->currentTime);
      finished = TRUE;
      retVal = flag;
    }

    /* Closing new step message */
    messageClose(OMC_LOG_SOLVER); // TODO make sure this is called even if something in between fails

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
  cvode_save_statistics(cvodeData->cvode_mem, &solverInfo->solverStatsTmp, threadData);

  infoStreamPrint(OMC_LOG_SOLVER, 0, "##CVODE## Finished Integrator step.");
  /* Measure time */
  if (measure_time_flag)
    rt_accumulate(SIM_TIMER_SOLVER);

  return retVal;
}

#ifdef OMC_FMI_RUNTIME

/**
 * @brief Integration step with CVODE for fmi2DoStep
 *
 * @param comp          Pointer to FMU component.
 * @param tNext         Next desired time step for integrator to end.
 * @param states        States vector.
 * @return int          Returns 0 on success and -1 else.
 */
int cvode_solver_fmi_step(ModelInstance *comp, double tNext, double* states)
{
  DATA* data = comp->fmuData;
  threadData_t* threadData = comp->threadData;
  SOLVER_INFO* solverInfo = comp->solverInfo;
  /* Variables */
  int flag;
  int retVal = 0;

  CVODE_SOLVER *cvodeData;

  cvodeData = (CVODE_SOLVER*) solverInfo->solverData;
  solverInfo->currentTime = data->localData[0]->timeValue;

  N_VSetArrayPointer(states, cvodeData->y);
  if (solverInfo->didEventStep || !cvodeData->isInitialized)    // TODO Save if we have had an event
  {
    cvode_solver_reinit(data, threadData, solverInfo, cvodeData);
    cvodeData->isInitialized = TRUE;
  }
  flag = CVodeSetStopTime(cvodeData->cvode_mem, tNext);
  if (flag < 0) {
    FILTERED_LOG(comp, fmi2Fatal, LOG_STATUSFATAL, "fmi2DoStep: ##CVODE## CVodeSetStopTime failed with flag %i.", flag)
    return -1;
  }
  flag = CVode(cvodeData->cvode_mem,
               tNext,
               cvodeData->y,
               &(solverInfo->currentTime),
               CV_NORMAL);
  /* Error handling */
  if ((flag == CV_SUCCESS || flag == CV_TSTOP_RETURN) && solverInfo->currentTime >= tNext)
  {
    FILTERED_LOG(comp, fmi2OK, LOG_ALL, "fmi2DoStep:##CVODE## step done to time = %.15g.", comp->solverInfo->currentTime)
  }
  else
  {
    FILTERED_LOG(comp, fmi2Fatal, LOG_STATUSFATAL, "fmi2DoStep: ##CVODE## %d error occurred at time = %.15g.", flag, solverInfo->currentTime)
    return -1;
  }

  return 0;
}

#endif /* OMC_FMI_RUNTIME */

#else /* WITH_SUNDIALS */

int cvode_solver_initial(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo, CVODE_SOLVER *cvodeData, int isFMI)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(threadData, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

int cvode_solver_deinitial(CVODE_SOLVER *cvodeData)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(NULL, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

int cvode_solver_step(DATA *data, threadData_t *threadData, SOLVER_INFO *solverInfo)
{
#ifdef OMC_FMI_RUNTIME
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
#else
  throwStreamPrint(threadData, "##CVODE## SUNDIALS not available. Reconfigure omc with SUNDIALS.\n");
#endif
}

#ifdef OMC_FMI_RUNTIME
int cvode_solver_fmi_step(ModelInstance *comp, double tNext, double* states)
{
  printf("##CVODE## SUNDIALS not available in FMU. See OpenModelica command line flag \"--fmiFlags\" from \"omc --help\" on how to enable CVODE in FMUs.\n");
  return -1;
}
#endif

#endif /* #ifdef WITH_SUNDIALS */
