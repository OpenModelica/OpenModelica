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

/*! \file gbode_step.c
 */

#include "gbode_main.h"
#include "gbode_nls.h"
#include "gbode_internal_nls.h"
#include "gbode_util.h"

#include "kinsolSolver.h"

/**
 * @brief Generic multi-step function.
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int full_implicit_MS(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  int i;
  int stage;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  /* Predictor step */
  for (i = 0; i < nStates; i++) {
    gbData->yt[i] = 0;
    for (stage = 0; stage < nStages-1; stage++) {
      gbData->yt[i] += -gbData->yv[stage * nStates + i] * gbData->tableau->c[stage] +
                        gbData->kv[stage * nStates + i] * gbData->tableau->bt[stage] *  gbData->stepSize;
    }
    gbData->yt[i] += gbData->kv[stage * nStates + i] * gbData->tableau->bt[stage] * gbData->stepSize;
    gbData->yt[i] /= gbData->tableau->c[stage];
  }


  /* Constant part of the multi-step method */
  for (i = 0; i < nStates; i++) {
    gbData->res_const[i] = 0;
    for (stage = 0; stage < nStages-1; stage++) {
      gbData->res_const[i] += -gbData->yv[stage * nStates + i] * gbData->tableau->c[stage] +
                               gbData->kv[stage * nStates + i] * gbData->tableau->b[stage] *  gbData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbData->time + gbData->stepSize;

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=1..j-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;

  // Set start vectors for the noblinear solver
  memcpy(nlsData->nlsx, gbData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));

  solved = solveNLS_gb(data, threadData, nlsData, gbData);

  if (solved != NLS_SOLVED) {
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "gbode error: Failed to solve NLS in full_implicit_MS at time t=%g", gbData->time);
    return -1;
  }

  memcpy(gbData->kv + stage * nStates, fODE, nStates*sizeof(double));

  /* Corrector step */
  for (i = 0; i < nStates; i++) {
    gbData->y[i] = 0;
    for (stage = 0; stage < nStages-1; stage++) {
      gbData->y[i] += -gbData->yv[stage * nStates + i] * gbData->tableau->c[stage] +
                       gbData->kv[stage * nStates + i] * gbData->tableau->b[stage] *  gbData->stepSize;
    }
    gbData->y[i] += gbData->kv[stage * nStates + i] * gbData->tableau->b[stage] * gbData->stepSize;
    gbData->y[i] /= gbData->tableau->c[stage];
  }

  return 0;
}

/**
 * @brief Generic multi-step function.
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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  /* Predictor step */
  for (ii = 0; ii < gbData->nFastStates; ii++)
  {
    i = gbData->fastStatesIdx[ii];
    gbfData->yt[i] = 0;
    for (stage = 0; stage < nStages-1; stage++)
    {
      gbfData->yt[i] += -gbfData->yv[stage * nStates + i] * gbfData->tableau->c[stage] +
                         gbfData->kv[stage * nStates + i] * gbfData->tableau->bt[stage] *  gbfData->stepSize;
    }
    gbfData->yt[i] += gbfData->kv[stage * nStates + i] * gbfData->tableau->bt[stage] * gbfData->stepSize;
    gbfData->yt[i] /= gbfData->tableau->c[stage];
  }


  /* Constant part of the multi-step method */
  for (ii = 0; ii < gbData->nFastStates; ii++)
  {
    i = gbData->fastStatesIdx[ii];
    gbfData->res_const[i] = 0;
    for (stage = 0; stage < nStages-1; stage++)
    {
      gbfData->res_const[i] += -gbfData->yv[stage * nStates + i] * gbfData->tableau->c[stage] +
                                gbfData->kv[stage * nStates + i] * gbfData->tableau->b[stage] *  gbfData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbfData->time + gbfData->stepSize;
  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
  gb_interpolation(gbData->interpolation,
                   gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                   gbData->timeRight, gbData->yRight, gbData->kRight,
                   sData->timeValue,  sData->realVars,
                   gbData->nSlowStates, gbData->slowStatesIdx, nStates, gbData->tableau, gbData->x, gbData->k);

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=1..j-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;

  projVector_gbf(nlsData->nlsx, gbfData->yt, gbData->nFastStates, gbData->fastStatesIdx);
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));

  solved = solveNLS_gb(data, threadData, nlsData, gbData);

  if (solved != NLS_SOLVED) {
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "gbodef error: Failed to solve NLS in full_implicit_MS_MR at time t=%g", gbfData->time);
    return -1;
  }

  memcpy(gbfData->kv + stage * nStates, fODE, nStates*sizeof(double));

  /* Corrector step */
  for (ii = 0; ii < gbData->nFastStates; ii++)
  {
    i = gbData->fastStatesIdx[ii];
    gbfData->y[i] = 0;
    for (stage = 0; stage < nStages-1; stage++)
    {
      gbfData->y[i] += -gbfData->yv[stage * nStates + i] * gbfData->tableau->c[stage] +
                        gbfData->kv[stage * nStates + i] * gbfData->tableau->b[stage] * gbfData->stepSize;
    }
    gbfData->y[i] += gbfData->kv[stage * nStates + i] * gbfData->tableau->b[stage] * gbfData->stepSize;
    gbfData->y[i] /= gbfData->tableau->c[stage];
  }

  return 0;
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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  if (!gbData->isExplicit  && OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS_V)) {
    // NLS - used values for extrapolation
    infoStreamPrint(OMC_LOG_GBODE_NLS_V, 1, "NLS - used values for extrapolation:");
    printVector_gb(OMC_LOG_GBODE_NLS_V, "xL", gbData->yv + nStates, nStates, gbData->tv[1]);
    printVector_gb(OMC_LOG_GBODE_NLS_V, "kL", gbData->kv + nStates, nStates, gbData->tv[1]);
    printVector_gb(OMC_LOG_GBODE_NLS_V, "xR", gbData->yv, nStates, gbData->tv[0]);
    printVector_gb(OMC_LOG_GBODE_NLS_V, "kR", gbData->kv, nStates, gbData->tv[0]);
    messageClose(OMC_LOG_GBODE_NLS_V);
  }

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    gbData->act_stage = stage;

    /* Set constant part or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */
    for (i = 0; i < nStates; i++)
    {
      gbData->res_const[i] = gbData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
      {
        gbData->res_const[i] += gbData->stepSize * gbData->tableau->A[stage * nStages + stage_] * gbData->k[stage_ * nStates + i];
      }
    }

    /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
     * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
    // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

    // set simulation time with respect to the current stage
    sData->timeValue = gbData->time + gbData->tableau->c[stage_]*gbData->stepSize;

    // if the diagonal element is zero, an explicit step has to be performed
    if (gbData->tableau->A[stage * nStages + stage_] == 0) {
      // Store values in the ring buffer
      memcpy(gbData->x + stage_ * nStates, gbData->res_const, nStates*sizeof(double));

      if (!gbData->tableau->isKLeftAvailable || (stage > 0)) {
        // Calculate the fODE values for the explicit stage
        memcpy(sData->realVars, gbData->res_const, nStates*sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      } else {
        memcpy(fODE, gbData->kLeft, nStates*sizeof(double));
      }
    } else {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=1..j-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;
      struct dataSolver * solverData = (struct dataSolver *)nlsData->solverData;
      NLS_KINSOL_DATA* kin_mem = ((NLS_KINSOL_DATA*)solverData->ordinaryData)->kinsolMemory;

      // Set start vector
      memcpy(nlsData->nlsx,    gbData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation,    gbData->yOld, nStates*sizeof(modelica_real));

      if (gbData->time != data->simulationInfo->startTime && gbData->time != gbData->eventTime
          && gbData->tableau->dense_output != NULL && gbData->nlsSolverMethod == GB_NLS_INTERNAL
          && gbData->extrapolationBaseTime != INFINITY)
      {
        double theta = (gbData->time + gbData->tableau->c[stage_] * gbData->stepSize - gbData->extrapolationBaseTime) / gbData->extrapolationStepSize;
        gbData->tableau->dense_output(gbData->tableau, gbData->yLast, NULL, gbData->kLast,
                                      theta, gbData->extrapolationStepSize, nlsData->nlsxOld, 0, NULL, nStates);
      }
      else if (stage>1)
      {
        extrapolation_hermite_gb(nlsData->nlsxOld, gbData->nStates, gbData->time + gbData->tableau->c[stage_-2] * gbData->stepSize, gbData->x + (stage_-2) * nStates, gbData->k + (stage_-2) * nStates,
                             gbData->time + gbData->tableau->c[stage_-1] * gbData->stepSize, gbData->x + (stage_-1) * nStates, gbData->k + (stage_-1) * nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      }
      else
      {
        extrapolation_gb(gbData, nlsData->nlsxOld, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      }

      infoStreamPrint(OMC_LOG_GBODE_NLS_V, 0, "Solving NLS of stage %d at time %g", stage_+1, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      solved = solveNLS_gb(data, threadData, nlsData, gbData);

      if (solved != NLS_SOLVED) {
        if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "gbode error: Failed to solve NLS in expl_diag_impl_RK in stage %d at time t=%g", stage_+1, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
        return -1;
      }

      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS_V)) {
        infoStreamPrint(OMC_LOG_GBODE_NLS_V, 1, "NLS - start values and solution of the NLS:");
        printVector_gb(OMC_LOG_GBODE_NLS_V, "x0", nlsData->nlsxOld, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
        printVector_gb(OMC_LOG_GBODE_NLS_V, "xS", nlsData->nlsxExtrapolation, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
        printVector_gb(OMC_LOG_GBODE_NLS_V, "xL", nlsData->nlsx,              nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
        messageClose(OMC_LOG_GBODE_NLS_V);
      }

      memcpy(gbData->x + stage_ * nStates, nlsData->nlsx, nStates*sizeof(double));
      if (/* non explicit stage of (E)SDIRK integrator */ (stage_ != 0 || gbData->tableau->A[0] != 0) && gbData->nlsSolverMethod == GB_NLS_INTERNAL)
      {
        // reconstruct k_{stage_} from the solution, avoids repeated call to functionODE()
        double ifac = 1.0 / (gbData->stepSize * gbData->tableau->A[stage_ * nStages + stage_]);
        for (int i = 0; i < nStates; i++)
        {
          fODE[i] = ifac * (nlsData->nlsx[i] - gbData->res_const[i]);
        }
      }
    }
    // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
    memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }
  infoStreamPrint(OMC_LOG_GBODE_NLS_V, 0, "GBODE: all stages done.");

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);

  for (i=0; i<nStates; i++)
  {
    gbData->y[i]  = gbData->yOld[i];
    if (!gbData->tableau->richardson) {
      gbData->yt[i] = gbData->yOld[i];
    }
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
      if (!gbData->tableau->richardson) {
        gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
      }
    }
  }

  return 0;
}

/**
 * @brief Generic diagonal implicit Runge-Kutta step function.
 *
 * Only for the fast states (inner integration).
 *
 * Internal non-linear equation system will be solved with non-linear solver specified during setup.
 * Results will be saved in y and embedded results saved in yt.
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 * @return int              Return 0 on success, -1 on failure.
 */
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage, stage_;

  int nStates = gbData->nStates;
  int nFastStates = gbData->nFastStates;
  int nStages = gbfData->tableau->nStages;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
  gb_interpolation(gbData->interpolation,
                   gbData->timeLeft,   gbData->yLeft,  gbData->kLeft,
                   gbData->timeRight,  gbData->yRight, gbData->kRight,
                   gbfData->time,      gbfData->yOld,
                   gbData->nSlowStates, gbData->slowStatesIdx, nStates, gbData->tableau, gbData->x, gbData->k);

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - used values for extrapolation:");
    printVector_gbf(OMC_LOG_GBODE_NLS, "xL", gbfData->yv + nStates, nStates, gbfData->tv[1], gbData->nFastStates, gbData->fastStatesIdx);
    printVector_gbf(OMC_LOG_GBODE_NLS, "kL", gbfData->kv + nStates, nStates, gbfData->tv[1], gbData->nFastStates, gbData->fastStatesIdx);
    printVector_gbf(OMC_LOG_GBODE_NLS, "xR", gbfData->yv, nStates, gbfData->tv[0], gbData->nFastStates, gbData->fastStatesIdx);
    printVector_gbf(OMC_LOG_GBODE_NLS, "kR", gbfData->kv, nStates, gbfData->tv[0], gbData->nFastStates, gbData->fastStatesIdx);
    messageClose(OMC_LOG_GBODE_NLS);
  }

  for (stage = 0; stage < nStages; stage++) {
    gbfData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-1))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++) {
      gbfData->res_const[i] = gbfData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gbfData->res_const[i] += gbfData->stepSize * gbfData->tableau->A[stage * nStages + stage_] * gbfData->k[stage_ * nStates + i];
    }
    // TODO can be streamlined by taking res_const[i-1] instead of the whole sum.

    // set simulation time with respect to the current stage
    // t = t_0 + c[j]*h
    sData->timeValue = gbfData->time + gbfData->tableau->c[stage]*gbfData->stepSize;

    // index of diagonal element of A
    if (gbfData->tableau->A[stage * nStages + stage_] == 0) {
      // Calculate the fODE values for the explicit stage
      memcpy(sData->realVars, gbfData->res_const, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));
    } else {
      // interpolate the slow states on the time of the current stage
      gb_interpolation(gbData->interpolation,
                       gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                       gbData->timeRight, gbData->yRight, gbData->kRight,
                       sData->timeValue,   sData->realVars,
                       gbData->nSlowStates, gbData->slowStatesIdx, nStates, gbData->tableau, gbData->x, gbData->k);

      // setting the start vector for the newton step
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=1..j-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;

      projVector_gbf(nlsData->nlsx, gbfData->yOld, nFastStates, gbData->fastStatesIdx);
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nFastStates*sizeof(modelica_real));

      // use help vector gbData->y1 for security reasons
      extrapolation_gbf(gbData, gbData->y1, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
      projVector_gbf(nlsData->nlsxExtrapolation, gbData->y1, nFastStates, gbData->fastStatesIdx);

      infoStreamPrint(OMC_LOG_GBODE_NLS_V, 0, "Solving NLS of gbf stage %d at time %g", stage_+1, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
      solved = solveNLS_gb(data, threadData, nlsData, gbData);

      if (solved != NLS_SOLVED) {
        if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "gbodef error: Failed to solve NLS in expl_diag_impl_RK_MR in stage %d at time t=%g", stage_+1, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
        return -1;
      }

      // debug residuals
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
        infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - start values and solution of the NLS:");
        printVector_gb(OMC_LOG_GBODE_NLS, "xS", nlsData->nlsxExtrapolation, nFastStates, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
        printVector_gb(OMC_LOG_GBODE_NLS, "xL", nlsData->nlsx,              nFastStates, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
        messageClose(OMC_LOG_GBODE_NLS);
      }
    }

    // copy last values of sData->realVars and fODE, which should coincide with x[i] and k[i]
    memcpy(gbfData->x + stage_ * nStates, sData->realVars, nStates*sizeof(double));
    memcpy(gbfData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  // for the fast states only!
  for (ii = 0; ii < nFastStates; ii++) {
    i = gbData->fastStatesIdx[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gbfData->y[i]  = gbfData->yOld[i];
    gbfData->yt[i] = gbfData->yOld[i];
    for (stage_ = 0; stage_ < nStages; stage_++) {
      gbfData->y[i]  += gbfData->stepSize * gbfData->tableau->b[stage_]  * (gbfData->k + stage_ * nStates)[i];
      gbfData->yt[i] += gbfData->stepSize * gbfData->tableau->bt[stage_] * (gbfData->k + stage_ * nStates)[i];
    }
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
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;

  int i;
  int stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;

  double Atol = data->simulationInfo->tolerance;
  double Rtol = data->simulationInfo->tolerance;
  NLS_SOLVER_STATUS solved = NLS_FAILED;

  // NLS - used values for extrapolation
  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - used values for extrapolation:");
    printVector_gb(OMC_LOG_GBODE_NLS, "xL", gbData->yv + nStates, nStates, gbData->tv[1]);
    printVector_gb(OMC_LOG_GBODE_NLS, "kL", gbData->kv + nStates, nStates, gbData->tv[1]);
    printVector_gb(OMC_LOG_GBODE_NLS, "xR", gbData->yv, nStates, gbData->tv[0]);
    printVector_gb(OMC_LOG_GBODE_NLS, "kR", gbData->kv, nStates, gbData->tv[0]);
    messageClose(OMC_LOG_GBODE_NLS);
  }

  /* Set start values for non-linear solver by extrapolation */
  for (stage_ = 0; stage_ < nStages; stage_++) {
    memcpy(nlsData->nlsx + stage_*nStates,    gbData->yOld, nStates*sizeof(modelica_real));
    memcpy(nlsData->nlsxOld + stage_*nStates, gbData->yOld, nStates*sizeof(modelica_real));

    extrapolation_gb(gbData, nlsData->nlsxExtrapolation + stage_*nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
  }

  if (gbData->time != data->simulationInfo->startTime && gbData->time != gbData->eventTime
      && gbData->tableau->dense_output != NULL && gbData->nlsSolverMethod == GB_NLS_INTERNAL
      && gbData->extrapolationBaseTime != INFINITY)
  {
    for (stage_ = 0; stage_ < nStages; stage_++) {
      double theta = (gbData->time + gbData->tableau->c[stage_] * gbData->stepSize - gbData->extrapolationBaseTime) / gbData->extrapolationStepSize;
      gbData->tableau->dense_output(gbData->tableau, gbData->yLast, NULL, gbData->kLast,
                                    theta, gbData->extrapolationStepSize, nlsData->nlsxOld + stage_*nStates, 0, NULL, nStates);
      }
  }

  solved = solveNLS_gb(data, threadData, nlsData, gbData);

  if (solved != NLS_SOLVED) {
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "gbode error: Failed to solve NLS in full_implicit_RK at time t=%g", gbData->time);
    return -1;
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE_NLS)) {
    infoStreamPrint(OMC_LOG_GBODE_NLS, 1, "NLS - start values and solution of the NLS:");
    for (stage_ = 0; stage_ < nStages; stage_++) {
      printVector_gb(OMC_LOG_GBODE_NLS, "xS", nlsData->nlsxExtrapolation + stage_*nStates, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      printVector_gb(OMC_LOG_GBODE_NLS, "xL", nlsData->nlsx + stage_*nStates,              nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    }
    messageClose(OMC_LOG_GBODE_NLS);
  }


  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);

  if (FALSE /* disable for now */ && gbData->nlsSolverMethod == GB_NLS_INTERNAL && gbData->tableau->t_transform->nRealEigenvalues >= 1)
  {
    // construct a contractive error via a single LU solve
    gbInternalContraction(data, threadData, gbData->nlsData, gbData, gbData->yt, gbData->y);
  }
  else
  {
    for (i = 0; i < nStates; i++) {
      gbData->y[i]  = gbData->yOld[i];
      gbData->yt[i] = gbData->yOld[i];
      for (stage_ = 0; stage_ < nStages; stage_++) {
        gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
        gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
      }
    }
  }

  // copy the whole solution vector to the inner buffer (for latter extrapolation and dense output)
  memcpy(gbData->x, nlsData->nlsx, nlsData->size*sizeof(double));

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
int gbodef_richardson(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  double stepSize, lastStepSize, timeValue;
  int step_info, p;
  int nStates = gbfData->nStates;
  int i;

  // assumption yLeft and yOld coincide!!!
  timeValue = gbfData->time;
  stepSize = gbfData->stepSize;
  lastStepSize = gbfData->lastStepSize;
  p = gbfData->tableau->order_b;

  if (!gbfData->isExplicit) {
    // Store relevant part of the ring buffer, which is used for extrapolation
    for (i = 0; i < 2; i++) {
      gbData->tr[i] = gbfData->tv[i];
      memcpy(gbData->yr + i * nStates, gbfData->yv + i * nStates, nStates * sizeof(double));
      memcpy(gbData->kr + i * nStates, gbfData->kv + i * nStates, nStates * sizeof(double));
    }
  }

  gbfData->stepSize = gbfData->stepSize/2;
  step_info = gbfData->step_fun(data, threadData, solverInfo);
  if (step_info != 0) {
    stepSize = stepSize/2;
    lastStepSize = lastStepSize/2;
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (first half step)");
  } else {
    // debug the approximations after performed step
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (first 1/2 step) approximation:");
      printVector_gb(OMC_LOG_GBODE, " y",  gbfData->y,  nStates, gbfData->time + gbfData->stepSize);
      printVector_gb(OMC_LOG_GBODE, "yt", gbfData->yt, nStates, gbfData->time + gbfData->stepSize);
      messageClose(OMC_LOG_GBODE);
    }
    gbfData->time += gbfData->stepSize;
    gbfData->lastStepSize = gbfData->stepSize;
    memcpy(gbfData->yOld, gbfData->y, nStates * sizeof(double));

    // prepare for the extrapolation
    if (!gbfData->isExplicit) {
      sData->timeValue = gbfData->time;
      memcpy(sData->realVars, gbfData->y, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));
      gbfData->tv[1] = gbfData->tv[0];
      memcpy(gbfData->yv + nStates, gbfData->yv, nStates * sizeof(double));
      memcpy(gbfData->kv + nStates, gbfData->kv, nStates * sizeof(double));
      gbfData->tv[0] = gbfData->time;
      memcpy(gbfData->yv, gbfData->y, nStates * sizeof(double));
      memcpy(gbfData->kv, fODE, nStates * sizeof(double));
    }

    step_info = gbfData->step_fun(data, threadData, solverInfo);
    if (step_info != 0) {
      stepSize = stepSize/2;
      lastStepSize = lastStepSize/2;
      if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (second half step)");
    } else {
      // debug the approximations after performed step
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
        infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (second 1/2 step) approximation:");
        printVector_gb(OMC_LOG_GBODE, " y",  gbfData->y,  nStates, gbfData->time + gbfData->stepSize);
        printVector_gb(OMC_LOG_GBODE, "yt", gbfData->yt, nStates, gbfData->time + gbfData->stepSize);
        messageClose(OMC_LOG_GBODE);
      }
      memcpy(gbfData->y1, gbfData->y, nStates * sizeof(double));

      // prepare for the extrapolation
      if (!gbfData->isExplicit) {
        sData->timeValue = gbfData->time + gbfData->stepSize;
        memcpy(sData->realVars, gbfData->y, nStates*sizeof(double));
        gbode_fODE(data, threadData, &(gbfData->stats.nCallsODE));
        gbfData->tv[0] = gbfData->time;
        memcpy(gbfData->yv, gbfData->y, nStates * sizeof(double));
        memcpy(gbfData->kv, fODE, nStates * sizeof(double));
      }

      // restore yOld
      gbfData->time = timeValue;
      gbfData->stepSize = stepSize;
      gbfData->lastStepSize = lastStepSize;
      memcpy(gbfData->yOld, gbfData->yLeft, nStates * sizeof(double));
      step_info = gbfData->step_fun(data, threadData, solverInfo);
      if (step_info != 0) {
        stepSize = stepSize/2;
        lastStepSize = lastStepSize/2;
        if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (full step)");
      } else {
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
          infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (full step) approximation");
          printVector_gb(OMC_LOG_GBODE, " y",  gbfData->y,  nStates, gbfData->time + gbfData->stepSize);
          printVector_gb(OMC_LOG_GBODE, "yt", gbfData->yt, nStates, gbfData->time + gbfData->stepSize);
          messageClose(OMC_LOG_GBODE);
        }
      }
    }
  }

  // Restore time values and step size
  gbfData->time = timeValue;
  gbfData->stepSize = stepSize;
  gbfData->lastStepSize = lastStepSize;
  memcpy(gbfData->yOld, gbfData->yLeft, nStates * sizeof(double));
  if (!gbfData->isExplicit) {
    // Restore ring buffer
    for (i = 0; i < 2; i++) {
      gbfData->tv[i] = gbData->tr[i];
      memcpy(gbfData->yv + i * nStates, gbData->yr + i * nStates, nStates * sizeof(double));
      memcpy(gbfData->kv + i * nStates, gbData->kr + i * nStates, nStates * sizeof(double));
    }
  }
  if (!step_info) {
    // Extrapolate values based on order of the scheme
    for (i = 0; i < nStates; i++) {
      gbfData->yt[i] = (pow(2.,p) * gbfData->y1[i] - gbfData->y[i]) / (pow(2.,p) - 1);
    }
  }

  return step_info;
}

/**
 * @brief
 *
 * @param data
 * @param threadData
 * @param solverInfo
 * @return int
 */
int gbode_richardson(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  double stepSize, lastStepSize, timeValue;
  int step_info, p;
  int nStates = gbData->nStates;
  int i;

  // assumption yLeft and yOld coincide!!!
  timeValue = gbData->time;
  stepSize = gbData->stepSize;
  lastStepSize = gbData->lastStepSize;
  p = gbData->tableau->order_b;

  if (!gbData->isExplicit) {
    // Store relevant part of the ring buffer, which is used for extrapolation
    for (i = 0; i < 2; i++) {
      gbData->tr[i] = gbData->tv[i];
      memcpy(gbData->yr + i * nStates, gbData->yv + i * nStates, nStates * sizeof(double));
      memcpy(gbData->kr + i * nStates, gbData->kv + i * nStates, nStates * sizeof(double));
    }
  }

  gbData->stepSize = gbData->stepSize/2;
  step_info = gbData->step_fun(data, threadData, solverInfo);
  if (step_info != 0) {
    stepSize = stepSize/2;
    lastStepSize = lastStepSize/2;
    if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (first half step)");
  } else {
    // debug the approximations after performed step
    if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
      infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (first 1/2 step) approximation:");
      printVector_gb(OMC_LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
      printVector_gb(OMC_LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
      messageClose(OMC_LOG_GBODE);
    }
    gbData->time += gbData->stepSize;
    gbData->lastStepSize = gbData->stepSize;
    memcpy(gbData->yOld, gbData->y, nStates * sizeof(double));

    // prepare for the extrapolation
    if (!gbData->isExplicit) {
      sData->timeValue = gbData->time;
      memcpy(sData->realVars, gbData->y, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
      gbData->tv[1] = gbData->tv[0];
      memcpy(gbData->yv + nStates, gbData->yv, nStates * sizeof(double));
      memcpy(gbData->kv + nStates, gbData->kv, nStates * sizeof(double));
      gbData->tv[0] = gbData->time;
      memcpy(gbData->yv, gbData->y, nStates * sizeof(double));
      memcpy(gbData->kv, fODE, nStates * sizeof(double));
    }

    step_info = gbData->step_fun(data, threadData, solverInfo);
    if (step_info != 0) {
      stepSize = stepSize/2;
      lastStepSize = lastStepSize/2;
      if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (second half step)");
    } else {
      // debug the approximations after performed step
      if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
        infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (second 1/2 step) approximation:");
        printVector_gb(OMC_LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
        printVector_gb(OMC_LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
        messageClose(OMC_LOG_GBODE);
      }
      memcpy(gbData->y1, gbData->y, nStates * sizeof(double));

      // prepare for the extrapolation
      if (!gbData->isExplicit) {
        sData->timeValue = gbData->time + gbData->stepSize;
        memcpy(sData->realVars, gbData->y, nStates*sizeof(double));
        gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));
        gbData->tv[0] = gbData->time;
        memcpy(gbData->yv, gbData->y, nStates * sizeof(double));
        memcpy(gbData->kv, fODE, nStates * sizeof(double));
      }

      // restore yOld
      gbData->time = timeValue;
      gbData->stepSize = stepSize;
      gbData->lastStepSize = lastStepSize;
      memcpy(gbData->yOld, gbData->yLeft, nStates * sizeof(double));
      step_info = gbData->step_fun(data, threadData, solverInfo);
      if (step_info != 0) {
        stepSize = stepSize/2;
        lastStepSize = lastStepSize/2;
        if (OMC_ACTIVE_STREAM(OMC_LOG_SOLVER)) warningStreamPrint(OMC_LOG_SOLVER, 0, "Failure: gbode Richardson extrapolation (full step)");
      } else {
        if (OMC_ACTIVE_STREAM(OMC_LOG_GBODE)) {
          infoStreamPrint(OMC_LOG_GBODE, 1, "Richardson extrapolation (full step) approximation");
          printVector_gb(OMC_LOG_GBODE, " y",  gbData->y,  nStates, gbData->time + gbData->stepSize);
          printVector_gb(OMC_LOG_GBODE, "yt", gbData->yt, nStates, gbData->time + gbData->stepSize);
          messageClose(OMC_LOG_GBODE);
        }
      }
    }
  }

  // Restore time values and step size
  gbData->time = timeValue;
  gbData->stepSize = stepSize;
  gbData->lastStepSize = lastStepSize;
  memcpy(gbData->yOld, gbData->yLeft, nStates * sizeof(double));

  if (!gbData->isExplicit) {
    // Restore ring buffer
    for (i = 0; i < 2; i++) {
      gbData->tv[i] = gbData->tr[i];
      memcpy(gbData->yv + i * nStates, gbData->yr + i * nStates, nStates * sizeof(double));
      memcpy(gbData->kv + i * nStates, gbData->kr + i * nStates, nStates * sizeof(double));
    }
  }

  if (!step_info) {
    // Extrapolate values based on order of the scheme
    for (i = 0; i < nStates; i++) {
      gbData->yt[i] = (pow(2.,p) * gbData->y1[i] - gbData->y[i]) / (pow(2.,p) - 1);
    }
  }

  return step_info;
}
