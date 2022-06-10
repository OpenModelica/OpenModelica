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
 */

#include "gbode_main.h"

int gbode_fODE(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE);


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
int full_implicit_MS(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  int i;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbData->tableau->nStages;
  modelica_boolean solved = FALSE;

  /* Predictor Schritt */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->yt[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                          gbData->k[stage_ * nStates + i] * gbData->tableau->bt[stage_] *  gbData->stepSize;
    }
    gbData->yt[i] += gbData->k[stage_ * nStates + i] * gbData->tableau->bt[stage_] * gbData->stepSize;
    gbData->yt[i] /= gbData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->res_const[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                                 gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] *  gbData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbData->time + gbData->stepSize;

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gbData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gbData->multi_rate_phase = 0;

  if (ACTIVE_STREAM(LOG_M_NLS)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_M_NLS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (i = 0; i < nStates; i++)
  {
    // BB ToDo: check the formula with respect to gbData->k[]
    gbData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbData->y[i] += -gbData->x[stage_ * nStates + i] * gbData->tableau->c[stage_] +
                         gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] *  gbData->stepSize;
    }
    gbData->y[i] += gbData->k[stage_ * nStates + i] * gbData->tableau->b[stage_] * gbData->stepSize;
    gbData->y[i] /= gbData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gbData->x + stage_ * nStates, gbData->y, nStates*sizeof(double));

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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage, stage_;
  int nStates = data->modelData->nStates;
  int nStages = gbfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  /* Predictor Schritt */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->yt[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->yt[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                          gbfData->k[stage_ * nStates + i] * gbfData->tableau->bt[stage_] *  gbfData->stepSize;
    }
    gbfData->yt[i] += gbfData->k[stage_ * nStates + i] * gbfData->tableau->bt[stage_] * gbfData->stepSize;
    gbfData->yt[i] /= gbfData->tableau->c[stage_];
  }


  /* Constant part of the multistep method */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->res_const[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->res_const[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                                 gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] *  gbfData->stepSize;
    }
  }
  // printVector_gb("res_const:  ", gbData->res_const, nStates, gbData->time);

  /* Compute intermediate step k, explicit if diagonal element is zero, implicit otherwise
    * k[i] = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..i)) */
  // here, it yields:   stage == stage_, and stage * nStages + stage_ is index of the diagonal element

  // set simulation time with respect to the current stage
  sData->timeValue = gbfData->time + gbfData->stepSize;
  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
if (gbfData->interpolation == 1) {
    linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                            gbfData->endTime,    gbfData->yEnd,
                            sData->timeValue,    sData->realVars,
                            gbfData->nSlowStates, gbfData->slowStates);

  } else {
    hermite_interpolation_gbf(gbfData->startTime,  gbfData->yStart, gbfData->kStart,
                              gbfData->endTime,    gbfData->yEnd,   gbfData->kEnd,
                              sData->timeValue,    sData->realVars,
                              gbfData->nSlowStates, gbfData->slowStates);
  }

  // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
  NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;
  // Set start vector, BB ToDo: Ommit extrapolation after event!!!

  memcpy(nlsData->nlsx, gbfData->yt, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
  memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
  gbData->multi_rate_phase = 1;

  if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbodef error: Failed to solve NLS in full_implicit_MS");
    return -1;
  }

  memcpy(gbfData->k + stage_ * nStates, fODE, nStates*sizeof(double));

  /* Corrector Schritt */
  for (ii = 0; ii < gbfData->nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // BB ToDo: check the formula with respect to gbData->k[]
    gbfData->y[i] = 0;
    for (stage_ = 0; stage_ < nStages-1; stage_++)
    {
      gbfData->y[i] += -gbfData->x[stage_ * nStates + i] * gbfData->tableau->c[stage_] +
                         gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] *  gbfData->stepSize;
    }
    gbfData->y[i] += gbfData->k[stage_ * nStates + i] * gbfData->tableau->b[stage_] * gbfData->stepSize;
    gbfData->y[i] /= gbfData->tableau->c[stage_];
  }
  // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
  memcpy(gbfData->x + stage_ * nStates, gbfData->y, nStates*sizeof(double));

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
  modelica_boolean solved = FALSE;

  if (!gbData->isExplicit) {
    memcpy(gbData->nlsxLeft, gbData->x, nStates*sizeof(double));
    memcpy(gbData->nlskLeft, gbData->k, nStates*sizeof(double));
    memcpy(gbData->nlsxRight, gbData->x + nStages * nStates, nStates*sizeof(double));
    memcpy(gbData->nlskRight, gbData->k + nStages * nStates, nStates*sizeof(double));

    infoStreamPrint(LOG_M_NLS, 1, "NLS - used values for extrapolation:");
    printVector_gb(LOG_M_NLS, "xL", gbData->nlsxLeft, nStates, gbData->time - gbData->lastStepSize);
    printVector_gb(LOG_M_NLS, "kL", gbData->nlskLeft, nStates, gbData->time - gbData->lastStepSize);
    printVector_gb(LOG_M_NLS, "xR", gbData->nlsxRight, nStates, gbData->time);
    printVector_gb(LOG_M_NLS, "kR", gbData->nlskRight, nStates, gbData->time);
    messageClose(LOG_M_NLS);
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

      // Calculate the fODE values for the explicit stage
      memcpy(sData->realVars, gbData->res_const, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
    } else {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;

      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      // for (i=0; i<nStates; i++) {
      //     nlsData->nlsx[i] = gbData->yOld[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->k[i];
      // }
      memcpy(nlsData->nlsx,    gbData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, gbData->yOld, nStates*sizeof(modelica_real));
      // this is actually extrapolation...
      if (gbData->stepRejected) {
        hermite_interpolation_gb(gbData->time + gbData->tableau->c[0] * gbData->stepSize, gbData->nlsxLeft,  gbData->nlskLeft,
                                 gbData->time + gbData->stepSize,                          gbData->nlsxRight, gbData->nlskRight,
                                 gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsxExtrapolation, nStates);

      } else {
        hermite_interpolation_gb(gbData->time - (1 - gbData->tableau->c[0]) * gbData->lastStepSize, gbData->nlsxLeft,  gbData->nlskLeft,
                                gbData->time,                        gbData->nlsxRight, gbData->nlskRight,
                                gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsxExtrapolation, nStates);
      }

      // This is a hack and needed, since nonlinear solver is based on numbered equation systems
      gbData->multi_rate_phase = 0;

      // Debug nonlinear solution process
      if (ACTIVE_STREAM(LOG_M_NLS)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();

        //Solve nonlinear equation system
        solved = solveNLS(data, threadData, nlsData);

        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_M_NLS, 0, "time needed for solving the NLS:  %20.16g", cpu_time_used);
      } else {
        //Solve nonlinear equation system
        solved = solveNLS(data, threadData, nlsData);
      }

      infoStreamPrint(LOG_M_NLS, 1, "NLS - start values and solution of the NLS:");
      printVector_gb(LOG_M_NLS, "xS", nlsData->nlsxExtrapolation, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      printVector_gb(LOG_M_NLS, "xL", nlsData->nlsx,              nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      messageClose(LOG_M_NLS);

      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
      memcpy(gbData->x + stage_ * nStates, nlsData->nlsx, nStates*sizeof(double));
    }
    // copy last calculation of fODE, which should coincide with k[i], here, it yields stage == stage_
    memcpy(gbData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gbData->y[i]  = gbData->yOld[i];
    gbData->yt[i] = gbData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
      gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
    }
  }
  memcpy(gbData->x + nStages * nStates, gbData->y, nStates*sizeof(double));

  sData->timeValue = gbData->time + gbData->stepSize;
  memcpy(sData->realVars, gbData->y, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k + nStages* nStates, fODE, nStates*sizeof(double));

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
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  int i, ii;
  int stage, stage_;

  int nStates = gbfData->nStates;
  int nFastStates = gbfData->nFastStates;
  int nStages = gbfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
  hermite_interpolation_gbf(gbfData->startTime,   gbfData->yStart, gbfData->kStart,
                            gbfData->endTime,     gbfData->yEnd,   gbfData->kEnd,
                            gbfData->time,        gbfData->yOld,
                            gbfData->nSlowStates, gbfData->slowStates);

  if (!gbfData->isExplicit) {
    memcpy(gbData->nlsxLeft, gbfData->x, nStates*sizeof(double));
    memcpy(gbData->nlskLeft, gbfData->k, nStates*sizeof(double));
    memcpy(gbData->nlsxRight, gbfData->x + nStages * nStates, nStates*sizeof(double));
    memcpy(gbData->nlskRight, gbfData->k + nStages * nStates, nStates*sizeof(double));

    infoStreamPrint(LOG_M_NLS, 1, "NLS - used values for extrapolation:");
    printVector_gb(LOG_M_NLS, "xL", gbData->nlsxLeft, nStates, gbfData->time - gbfData->lastStepSize);
    printVector_gb(LOG_M_NLS, "kL", gbData->nlskLeft, nStates, gbfData->time - gbfData->lastStepSize);
    printVector_gb(LOG_M_NLS, "xR", gbData->nlsxRight, nStates, gbfData->time);
    printVector_gb(LOG_M_NLS, "kR", gbData->nlskRight, nStates, gbfData->time);
    messageClose(LOG_M_NLS);
  }

  for (stage = 0; stage < nStages; stage++)
  {
    gbfData->act_stage = stage;
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    // yOld from integrator is correct for the fast states

    for (i=0; i < nStates; i++)
    {
      gbfData->res_const[i] = gbfData->yOld[i];
      for (stage_ = 0; stage_ < stage; stage_++)
        gbfData->res_const[i] += gbfData->stepSize * gbfData->tableau->A[stage * nStages + stage_] * gbfData->k[stage_ * nStates + i];
    }

    // set simulation time with respect to the current stage
    sData->timeValue = gbfData->time + gbfData->tableau->c[stage]*gbfData->stepSize;

    // index of diagonal element of A
    if (gbfData->tableau->A[stage * nStages + stage_] == 0)
    {
      // Calculate the fODE values for the explicit stage
      memcpy(sData->realVars, gbfData->res_const, nStates*sizeof(double));
      gbode_fODE(data, threadData, &(gbfData->evalFunctionODE), fODE);
    }
    else
    {
      // interpolate the slow states on the time of the current stage
      hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                                gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                                sData->timeValue,   sData->realVars,
                                gbfData->nSlowStates, gbfData->slowStates);

      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gbfData->yOld[gbfData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;

      projVector_gbf(nlsData->nlsx, gbfData->yOld, nFastStates, gbfData->fastStates);
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nFastStates*sizeof(modelica_real));
      // this is actually extrapolation...
      if (gbfData->stepRejected) {
        hermite_interpolation_gbf(gbfData->time + gbfData->tableau->c[0] * gbfData->stepSize, gbData->nlsxLeft,  gbData->nlskLeft,
                                  gbfData->time + gbfData->stepSize,                          gbData->nlsxRight, gbData->nlskRight,
                                  gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize, sData->realVars, nFastStates, gbfData->fastStates);

      } else {
        hermite_interpolation_gbf(gbfData->time - (1 - gbfData->tableau->c[0]) * gbfData->lastStepSize, gbData->nlsxLeft,  gbData->nlskLeft,
                                  gbfData->time,                                                        gbData->nlsxRight, gbData->nlskRight,
                                  gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize, sData->realVars, nFastStates, gbfData->fastStates);
      }
      projVector_gbf(nlsData->nlsxExtrapolation, sData->realVars, nFastStates, gbfData->fastStates);

      gbData->multi_rate_phase = 1;

      if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();
        solved = solveNLS(data, threadData, nlsData);
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
      } else {
        solved = solveNLS(data, threadData, nlsData);
      }

      infoStreamPrint(LOG_M_NLS, 1, "NLS - start values and solution of the NLS:");
      printVector_gb(LOG_M_NLS, "xS", nlsData->nlsxExtrapolation, nFastStates, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
      printVector_gb(LOG_M_NLS, "xL", nlsData->nlsx,              nFastStates, gbfData->time + gbfData->tableau->c[stage_] * gbfData->stepSize);
      messageClose(LOG_M_NLS);

      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "gbodef error: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
    // copy last values of sData->realVars, which should coincide with x[i]
    memcpy(gbfData->x + stage_ * nStates, sData->realVars, nStates*sizeof(double));
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(gbfData->k + stage_ * nStates, fODE, nStates*sizeof(double));
  }

  for (ii=0; ii<nFastStates; ii++)
  {
    i = gbfData->fastStates[ii];
    // y   is the new approximation
    // yt  is the approximation of the embedded method for error estimation
    gbfData->y[i]  = gbfData->yOld[i];
    gbfData->yt[i] = gbfData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbfData->y[i]  += gbfData->stepSize * gbfData->tableau->b[stage_]  * (gbfData->k + stage_ * nStates)[i];
      gbfData->yt[i] += gbfData->stepSize * gbfData->tableau->bt[stage_] * (gbfData->k + stage_ * nStates)[i];
    }
  }

  // set time value to the right hand side of the actual interval
  sData->timeValue = gbfData->time + gbfData->stepSize;
  // interpolate the slow states, respectively
  hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                            gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                            sData->timeValue,   gbfData->y,
                            gbfData->nSlowStates, gbfData->slowStates);

  // store corresponding values in the ring buffer
  memcpy(gbfData->x + nStages * nStates, gbfData->y, nStates*sizeof(double));

  memcpy(sData->realVars, gbfData->y, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbfData->evalFunctionODE), fODE);
  memcpy(gbfData->k + nStages* nStates, fODE, nStates*sizeof(double));

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
  modelica_boolean solved = FALSE;

  // NLS - used values for extrapolation
  infoStreamPrint(LOG_M_NLS, 1, "NLS - used values for extrapolation:");
  printVector_gb(LOG_M_NLS, "xL", gbData->x, nStates, gbData->time - (1 - gbData->tableau->c[0]) * gbData->lastStepSize);
  printVector_gb(LOG_M_NLS, "kL", gbData->k, nStates, gbData->time - (1 - gbData->tableau->c[0]) * gbData->lastStepSize);
  printVector_gb(LOG_M_NLS, "xR", gbData->x + nStages * nStates, nStates, gbData->time);
  printVector_gb(LOG_M_NLS, "kR", gbData->k + nStages * nStates, nStates, gbData->time);
  messageClose(LOG_M_NLS);

  /* Set start values for non-linear solver */
  for (stage_=0; stage_<nStages; stage_++) {
    memcpy(nlsData->nlsx + stage_*nStates,    gbData->yOld, nStates*sizeof(modelica_real));
    memcpy(nlsData->nlsxOld + stage_*nStates, gbData->yOld, nStates*sizeof(modelica_real));
    // this is actually extrapolation...
    if (gbData->stepRejected) {
      hermite_interpolation_gb(gbData->time + gbData->tableau->c[0] * gbData->stepSize, gbData->x,  gbData->k,
                               gbData->time + gbData->stepSize,                        gbData->x + nStages * nStates, gbData->k + nStages * nStates,
                               gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsxExtrapolation + stage_*nStates, nStates);

    } else {
      hermite_interpolation_gb(gbData->time - (1 - gbData->tableau->c[0]) * gbData->lastStepSize, gbData->x,  gbData->k,
                               gbData->time,                       gbData->x + nStages * nStates, gbData->k + nStages * nStates,
                               gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsxExtrapolation + stage_*nStates, nStates);
    }
  }

  // This is a hack and needed, since nonlinear solver is based on numbered equation systems
  gbData->multi_rate_phase = 0;
  if (ACTIVE_STREAM(LOG_M_NLS)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_M_NLS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData);
  }

  if (ACTIVE_STREAM(LOG_M_NLS)) {
    infoStreamPrint(LOG_M_NLS, 1, "NLS - start values and solution of the NLS:");
    for (stage_=0; stage_<nStages; stage_++) {
      printVector_gb(LOG_M_NLS, "xS", nlsData->nlsxExtrapolation + stage_*nStates, nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
      printVector_gb(LOG_M_NLS, "xL", nlsData->nlsx + stage_*nStates,              nStates, gbData->time + gbData->tableau->c[stage_] * gbData->stepSize);
    }
    messageClose(LOG_M_NLS);
  }

  if (!solved) {
    errorStreamPrint(LOG_STDOUT, 0, "gbode error: Failed to solve NLS in full_implicit_RK");
    return -1;
  }

  // Apply RK-scheme for determining the approximations at (gbData->time + gbData->stepSize)
  // y       = yold+h*sum(b[stage_]  * k[stage_], stage_=1..nStages);
  // yt      = yold+h*sum(bt[stage_] * k[stage_], stage_=1..nStages);
  for (i=0; i<nStates; i++)
  {
    gbData->y[i]  = gbData->yOld[i];
    gbData->yt[i] = gbData->yOld[i];
    for (stage_=0; stage_<nStages; stage_++)
    {
      gbData->y[i]  += gbData->stepSize * gbData->tableau->b[stage_]  * (gbData->k + stage_ * nStates)[i];
      gbData->yt[i] += gbData->stepSize * gbData->tableau->bt[stage_] * (gbData->k + stage_ * nStates)[i];
    }
  }
  memcpy(gbData->x, nlsData->nlsx, nlsData->size*sizeof(double));
  memcpy(gbData->x + nStages * nStates, gbData->y, nStates*sizeof(double));

  sData->timeValue = gbData->time + gbData->stepSize;
  memcpy(sData->realVars, gbData->y, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k + nStages* nStates, fODE, nStates*sizeof(double));

  return 0;
}

int gbodef_richardson(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo) {
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  DATA_GBODEF* gbfData = gbData->gbfData;

  double stepSize;
  int step_info, p;
  int nStates = gbfData->nStates;
  int nFastStates = gbfData->nFastStates;
  int i, ii;

  // assumption yLeft and yOld coincide!!!
  stepSize = gbfData->stepSize;
  p = gbfData->tableau->order_b;

  step_info = gbfData->step_fun(data, threadData, solverInfo);
  memcpy(gbfData->y1, gbfData->y, nStates * sizeof(double));

  gbfData->stepSize = gbfData->stepSize/2;
  step_info = gbfData->step_fun(data, threadData, solverInfo);
  memcpy(gbfData->yOld, gbfData->y, nStates * sizeof(double));
  step_info = gbfData->step_fun(data, threadData, solverInfo);

  memcpy(gbfData->yOld, gbfData->yLeft, nStates * sizeof(double));
  for (ii=0; ii<nFastStates; ii++) {
    i = gbfData->fastStates[ii];
    gbfData->yt[i] = (pow(2.,p) * gbfData->y[i] - gbfData->y1[i]) / (pow(2.,p) - 1);
  }
  gbfData->stepSize = stepSize;
  return step_info;
}

int gbode_richardson(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo) {
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;

  double stepSize;
  int step_info, p;
  int nStates = gbData->nStates;
  int i;

  // assumption yLeft and yOld coincide!!!
  stepSize = gbData->stepSize;
  p = gbData->tableau->order_b;

  step_info = gbData->step_fun(data, threadData, solverInfo);
  memcpy(gbData->y1, gbData->y, nStates * sizeof(double));

  gbData->stepSize = gbData->stepSize/2;
  step_info = gbData->step_fun(data, threadData, solverInfo);
  memcpy(gbData->yOld, gbData->y, nStates * sizeof(double));
  step_info = gbData->step_fun(data, threadData, solverInfo);

  memcpy(gbData->yOld, gbData->yLeft, nStates * sizeof(double));
  for (i=0; i<nStates; i++) {
    gbData->yt[i] = (pow(2.,p) * gbData->y[i] - gbData->y1[i]) / (pow(2.,p) - 1);
  }
  gbData->stepSize = stepSize;
  return step_info;
}
