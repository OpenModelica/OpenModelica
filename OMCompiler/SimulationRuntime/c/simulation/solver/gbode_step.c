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

  // printVector_gb("k:  ", gbData->k + 0 * nStates, nStates, gbData->time);
  // printVector_gb("k:  ", gbData->k + 1 * nStates, nStates, gbData->time);
  // printVector_gb("x:  ", gbData->x + 0 * nStates, nStates, gbData->time);
  // printVector_gb("x:  ", gbData->x + 1 * nStates, nStates, gbData->time);
  // BB ToDo: correct setting of nominal values crucial
  for(int i=0; i<nStates; i++) {
    // Get the nominal values of the states
    gbData->nlsData->nominal[i] = fabs(data->modelData->realVarsData[i].attribute.nominal);
    gbData->nlsData->nominal[i] = fmax(fmin(gbData->nlsData->nominal[i],gbData->yOld[i]), 1e-32);
  }


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
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_M_NLS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
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

  // printVector_gb("yt: ", gbData->yt, nStates, gbData->time);
  // printVector_gb("y:  ", gbData->y, nStates, gbData->time);

  // printVector_gb("k:  ", gbData->k + 0 * nStates, nStates, gbData->time);
  // printVector_gb("k:  ", gbData->k + 1 * nStates, nStates, gbData->time);


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

  // printVector_gb("k:  ", gbfData->k + 0 * nStates, nStates, gbfData->time);
  // printVector_gb("k:  ", gbfData->k + 1 * nStates, nStates, gbfData->time);
  // printVector_gb("x:  ", gbfData->x + 0 * nStates, nStates, gbfData->time);
  // printVector_gb("x:  ", gbfData->x + 1 * nStates, nStates, gbfData->time);

  // Is this necessary???
  // gbfData->data = (void*) data;
  // gbfData->threadData = threadData;

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
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
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

  memcpy(gbData->nlsxLeft, gbData->x, nStates*sizeof(double));
  memcpy(gbData->nlskLeft, gbData->k, nStates*sizeof(double));
  memcpy(gbData->nlsxRight, gbData->x + nStages * nStates, nStates*sizeof(double));
  memcpy(gbData->nlskRight, gbData->k + nStages * nStates, nStates*sizeof(double));

  if (!gbData->isExplicit) {
    for(int i=0; i<nStates; i++) {
      // Get the nominal values of the states
        gbData->nlsData->nominal[i] = fmax(fmin(fabs(data->modelData->realVarsData[i].attribute.nominal),gbData->nlsxRight[i]), 1e-32);
    }
  }

  if (ACTIVE_STREAM(LOG_M_BB)) {
    printf("Nonlinear interpolation\n");
    printVector_gb("gb->nlsx:    ", gbData->nlsxLeft, nStates, gbData->time);
    printVector_gb("gb->nlsx:    ", gbData->nlsxRight, nStates, gbData->time);
    printVector_gb("gb->nlsk:    ", gbData->nlskLeft, nStates, gbData->time);
    printVector_gb("gb->nlsk:    ", gbData->nlskRight, nStates, gbData->time);
  }

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  // BB ToDo: this is no longer necessary, since x and k are storing these values from the las step
  sData->timeValue = gbData->time;
  memcpy(sData->realVars, gbData->yOld, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k, fODE, nStates*sizeof(double));

  /* Runge-Kutta step */
  for (stage = 0; stage < nStages; stage++)
  {
    gbData->act_stage = stage;
    /* Set constant parts or residual input
     * res = f(tOld + c[i]*h, yOld + h*sum(A[i,j]*k[j], i=j..stage-1)) */

    for (i = 0; i < nStates; i++)
    {
      // BB ToDo: check the formula with respect to gbData->k[]
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

    if (gbData->tableau->A[stage * nStages + stage_] == 0)
    {
      if (stage>0) {
        memcpy(sData->realVars, gbData->res_const, nStates*sizeof(double));
        gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
      }
      memcpy(gbData->x + stage_ * nStates, gbData->res_const, nStates*sizeof(double));
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      // for (i=0; i<nStates; i++) {
      //     nlsData->nlsx[i] = gbData->yOld[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->k[i];
      // }
      //memcpy(nlsData->nlsx, gbData->yOld, nStates*sizeof(modelica_real));
      // this is actually extrapolation...
      hermite_interpolation_gb(gbData->time,                    gbData->nlsxLeft, gbData->nlskLeft,
                            gbData->time + gbData->stepSize, gbData->nlsxRight, gbData->nlskRight,
                            gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsx, nStates);
      // linear_interpolation_gb(gbData->time,                    gbData->nlsxLeft,
      //                      gbData->time + gbData->stepSize, gbData->nlsxRight,
      //                      gbData->time + gbData->tableau->c[stage_] * gbData->stepSize, nlsData->nlsx, nStates);
      // for (i=0; i<nStates; i++) {
      //     nlsData->nlsx[i] = gbData->nlsxRight[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->nlskRight[i];
      // }
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gbData->multi_rate_phase = 0;

      if (ACTIVE_STREAM(LOG_M_NLS)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();
        solved = solveNLS(data, threadData, nlsData, -1);
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_M_NLS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
      } else {
        solved = solveNLS(data, threadData, nlsData, -1);
      }

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

  int nStates = data->modelData->nStates;
  int nFastStates = gbfData->nFastStates;
  int nStages = gbfData->tableau->nStages;
  modelica_boolean solved = FALSE;

  // interpolate the slow states on the current time of gbfData->yOld for correct evaluation of gbfData->res_const
    if (gbfData->interpolation == 1) {
    linear_interpolation_gbf(gbfData->startTime, gbfData->yStart,
                            gbfData->endTime,    gbfData->yEnd,
                            gbfData->time,       gbfData->yOld,
                            gbfData->nSlowStates, gbfData->slowStates);

  } else {
    hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                              gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                              gbfData->time,      gbfData->yOld,
                              gbfData->nSlowStates, gbfData->slowStates);

  }
  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  sData->timeValue = gbfData->time;
  memcpy(sData->realVars, gbfData->yOld, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbfData->evalFunctionODE), fODE);
  memcpy(gbfData->k, fODE, nStates*sizeof(double));

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
      if (stage>0) {
        memcpy(sData->realVars, gbfData->res_const, nStates*sizeof(double));
        gbode_fODE(data, threadData, &(gbfData->evalFunctionODE), fODE);
      }
//      memcpy(gbfData->x + stage_ * nStates, gbfData->res_const, nStates*sizeof(double));
    }
    else
    {
      // interpolate the slow states on the time of the current stage
    if (gbfData->interpolation == 1) {
      linear_interpolation_gbf(gbfData->startTime,  gbfData->yStart,
                               gbfData->endTime,    gbfData->yEnd,
                               sData->timeValue,    sData->realVars,
                               gbfData->nSlowStates, gbfData->slowStates);
      } else {
        hermite_interpolation_gbf(gbfData->startTime, gbfData->yStart, gbfData->kStart,
                                  gbfData->endTime,   gbfData->yEnd,   gbfData->kEnd,
                                  sData->timeValue,   sData->realVars,
                                  gbfData->nSlowStates, gbfData->slowStates);

      }
      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<nFastStates; i++)
      //   solverData->x[i] = gbfData->yOld[gbfData->fastStates[i]];
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      NONLINEAR_SYSTEM_DATA* nlsData = gbfData->nlsData;
      // Set start vector, BB ToDo: Ommit extrapolation after event!!!
      for (ii=0; ii<nFastStates; ii++) {
          i = gbfData->fastStates[ii];
          nlsData->nlsx[ii] = gbfData->yOld[i] + gbfData->tableau->c[stage_] * gbfData->stepSize * gbfData->k[i];
      }
      //memcpy(nlsData->nlsx, gbfData->yOld, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxOld, nlsData->nlsx, nStates*sizeof(modelica_real));
      memcpy(nlsData->nlsxExtrapolation, nlsData->nlsx, nStates*sizeof(modelica_real));
      gbData->multi_rate_phase = 1;

      if (ACTIVE_STREAM(LOG_MULTIRATE_V)) {
        clock_t start, end;
        double cpu_time_used;

        start = clock();
        solved = solveNLS(data, threadData, nlsData, -1);
        end = clock();
        cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

        infoStreamPrint(LOG_STATS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
      } else {
        solved = solveNLS(data, threadData, nlsData, -1);
      }

      if (!solved) {
        errorStreamPrint(LOG_STDOUT, 0, "gbodef error: Failed to solve NLS in expl_diag_impl_RK in stage %d", stage_);
        return -1;
      }
    }
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

  /* Set start values for non-linear solver */
  for (stage_=0; stage_<nStages; stage_++) {
    // BB ToDo: Ommit extrapolation after event!!!
    for (i=0; i<nStates; i++)
      nlsData->nominal[stage_*nStates +i] = fmax(fmin(fabs(data->modelData->realVarsData[i].attribute.nominal),gbData->yOld[i]), 1e-32);
  }

  // First try for better starting values, only necessary after restart
  // BB ToDo: Or maybe necessary for RK methods, where b is not equal to the last row of A
  memcpy(sData->realVars, gbData->yOld, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->k, fODE, nStates*sizeof(double));

  /* Set start values for non-linear solver */
  for (stage_=0; stage_<nStages; stage_++) {
    // BB ToDo: Ommit extrapolation after event!!!
    for (i=0; i<nStates; i++)
      nlsData->nlsx[stage_*nStates +i] = gbData->yOld[i] + gbData->tableau->c[stage_] * gbData->stepSize * gbData->k[i];

    // memcpy(&nlsData->nlsx[stage_*nStates], gbData->yOld, nStates*sizeof(double));
    memcpy(&nlsData->nlsxOld[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
    memcpy(&nlsData->nlsxExtrapolation[stage_*nStates], &nlsData->nlsx[stage_*nStates], nStates*sizeof(double));
  }
  gbData->multi_rate_phase = 0;

  if (ACTIVE_STREAM(LOG_M_NLS)) {
    clock_t start, end;
    double cpu_time_used;

    start = clock();
    solved = solveNLS(data, threadData, nlsData, -1);
    end = clock();
    cpu_time_used = ((double) (end - start)) / CLOCKS_PER_SEC;

    infoStreamPrint(LOG_M_NLS, 0, "time needed for a solving NLS:  %20.16g", cpu_time_used);
  } else {
    solved = solveNLS(data, threadData, nlsData, -1);
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

  return 0;
}

