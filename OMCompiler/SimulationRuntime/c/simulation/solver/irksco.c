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

/*! \file irksco.c
 *  implicit solver for the numerical solution of ordinary differential equations (with step size control)
 *  \author kbalzereit, wbraun
 */


#include <string.h>
#include <float.h>

#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "external_input.h"
#include "newtonIteration.h"
#include "irksco.h"

int wrapper_fvec_irksco(int n, double* x, double* f, DATA_IRKSCO* userdata, int fj);
static int refreshModel(DATA* data, threadData_t *threadData, double* x, double time);
void irksco_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int rk_imp_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double* y_new);


/**
 * @brief Allocate memory for implicit Runge-Kutta with step size control solver.
 *
 * Integration methods of higher order can be used by increasing userdata->order:
 *   (1) implicit euler method
 *
 * @param data        Pointer to data struct.
 * @param threadData  Pointer to thread data.
 * @param solverInfo  Pointer to solver info.
 * @param size        Size of ODE.
 * @param zcSize      Number of zero-crossings-
 * @return int        Return 0 on success.
 */
int allocateIrksco(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, int size, int zcSize)
{
  DATA_IRKSCO* irkscoData = (DATA_IRKSCO*) malloc(sizeof(DATA_IRKSCO));
  solverInfo->solverData = (void*) irkscoData;
  irkscoData->order = 1;
  irkscoData->ordersize = 1;

  NLS_USERDATA* newtonUserData = initNlsUserData(data, threadData, -1, NULL, NULL);
  irkscoData->newtonData = allocateNewtonData(irkscoData->ordersize*size, newtonUserData);
  irkscoData->firstStep = 1;
  irkscoData->y0 = malloc(sizeof(double)*size);
  irkscoData->y05= malloc(sizeof(double)*size);
  irkscoData->y1 = malloc(sizeof(double)*size);
  irkscoData->y2 = malloc(sizeof(double)*size);
  irkscoData->der_x0 = malloc(sizeof(double)*size);
  irkscoData->radauVarsOld = malloc(sizeof(double)*size);
  irkscoData->radauVars = malloc(sizeof(double)*size);
  irkscoData->zeroCrossingValues = malloc(sizeof(double)*zcSize);
  irkscoData->zeroCrossingValuesOld = malloc(sizeof(double)*zcSize);

  irkscoData->m = malloc(sizeof(double)*size);
  irkscoData->n = malloc(sizeof(double)*size);

  irkscoData->A = malloc(sizeof(double)*irkscoData->ordersize*irkscoData->ordersize);
  irkscoData->Ainv = malloc(sizeof(double)*irkscoData->ordersize*irkscoData->ordersize);
  irkscoData->c = malloc(sizeof(double)*irkscoData->ordersize);
  irkscoData->d = malloc(sizeof(double)*irkscoData->ordersize);

  /* initialize stats */
  irkscoData->stepsDone = 0;
  irkscoData->evalFunctionODE = 0;
  irkscoData->evalJacobians = 0;

  irkscoData->radauStepSizeOld = 0;
  irkscoData->A[0] = 1;
  irkscoData->c[0] = 1;
  irkscoData->d[0] = 1;

  /* Set user data */
  irkscoData->data = data;
  irkscoData->threadData = threadData;

  return 0;
}

/*! \fn freeIrksco
 *
 *   Memory needed for solver is set free.
 */
void freeIrksco(SOLVER_INFO* solverInfo)
{
  DATA_IRKSCO* userdata = (DATA_IRKSCO*) solverInfo->solverData;
  freeNewtonData(userdata->newtonData);

  free(userdata->y0);
  free(userdata->y05);
  free(userdata->y1);
  free(userdata->y2);
  free(userdata->der_x0);
  free(userdata->radauVarsOld);
  free(userdata->radauVars);
  free(userdata->zeroCrossingValues);
  free(userdata->zeroCrossingValuesOld);
}

/*! \fn checkForZeroCrossingsIrksco
 *
 *   This function checks for ZeroCrossings.
 */
int checkForZeroCrossingsIrksco(DATA* data, threadData_t *threadData, DATA_IRKSCO* irkscoData, double *gout)
{
  TRACE_PUSH

  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations*/
  data->callback->function_ZeroCrossingsEquations(data, threadData);

  data->callback->function_ZeroCrossings(data, threadData, gout);

  TRACE_POP
  return 0;
}

/*! \fn compareZeroCrossings
 *
 *  This function compares gout vs. gout_old and return 1,
 *  if they are not equal, otherwise it returns 0,
 *
 *  \param [ref] [data]
 *  \param [in] [gout]
 *  \param [in] [gout_old]
 *
 */
int compareZeroCrossings(DATA* data, double* gout, double* gout_old)
{
  TRACE_PUSH
  int i;

  for(i=0; i<data->modelData->nZeroCrossings; ++i)
    if(gout[i] != gout_old[i])
      return 1;

  TRACE_POP
  return 0;
}

/*!	\fn rk_imp_step
 *
 *  function does one implicit euler step with the stepSize given in radauStepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y_new
 *
 */
int rk_imp_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double* y_new)
{
  int i, j, n=data->modelData->nStates;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  NONLINEAR_SYSTEM_DATA* nonlinsys = data->simulationInfo->nonlinearSystemData;
  DATA_IRKSCO* irkscoData = (DATA_IRKSCO*)solverInfo->solverData;
  DATA_NEWTON* newtonData = irkscoData->newtonData;

  /* Set rest of user data */
  newtonData->userData->nlsData = nonlinsys;
  newtonData->userData->analyticJacobian = NULL;

  double a,b;

  sData->timeValue = irkscoData->radauTime + irkscoData->radauStepSize;
  solverInfo->currentTime = sData->timeValue;

  newtonData->initialized = 1;
  newtonData->numberOfIterations = 0;
  newtonData->numberOfFunctionEvaluations = 0;
  newtonData->n = n*irkscoData->ordersize;


  /* linear extrapolation for start value of newton iteration */
  for (i=0; i<n; i++)
  {
    if (irkscoData->radauStepSizeOld > 1e-16)
    {
      irkscoData->m[i] = (irkscoData->radauVars[i] - irkscoData->radauVarsOld[i]) / irkscoData->radauStepSizeOld;
      irkscoData->n[i] = irkscoData->radauVars[i] - irkscoData->radauTime * irkscoData->m[i];
    }
    else
    {
      irkscoData->m[i] = 0;
      irkscoData->n[i] = 0;
    }
  }

  /* initial guess calculated via linear extrapolation */
  for (i=0; i<irkscoData->ordersize; i++)
  {
    if (irkscoData->radauStepSizeOld > 1e-16)
    {
      for (j=0; j<n; j++)
      {
        newtonData->x[i*n+j] = irkscoData->m[j] * (irkscoData->radauTimeOld + irkscoData->c[i] * irkscoData->radauStepSize )+ irkscoData->n[j] - irkscoData->y0[j];
      }
    }
    else
    {
      for (j=0; j<n; j++)
      {
        newtonData->x[i*n+j] = irkscoData->radauVars[i];
      }
    }
  }

  newtonData->newtonStrategy = NEWTON_DAMPED2;
  _omc_newton((genericResidualFunc*)wrapper_fvec_irksco, newtonData, irkscoData);

  /* if newton solver did not converge, do iteration again but calculate jacobian in every step */
  if (newtonData->info == -1)
  {
    for (i=0; i<irkscoData->ordersize; i++)
    {
      for (j=0; j<n; j++)
      {
        newtonData->x[i*n+j] = irkscoData->m[j] * (irkscoData->radauTimeOld + irkscoData->c[i] * irkscoData->radauStepSize )+ irkscoData->n[j] - irkscoData->y0[j];
      }
    }
    newtonData->numberOfIterations = 0;
    newtonData->numberOfFunctionEvaluations = 0;
    newtonData->calculate_jacobian = 1;

    warningStreamPrint(LOG_SOLVER, 0, "nonlinear solver did not converge at time %e, do iteration again with calculating jacobian in every step", solverInfo->currentTime);
    _omc_newton((genericResidualFunc*)wrapper_fvec_irksco, newtonData, irkscoData);

    newtonData->calculate_jacobian = -1;
  }

  for (j=0; j<n; j++)
  {
    y_new[j] = irkscoData->y0[j];
  }

  for (i=0; i<irkscoData->ordersize; i++)
  {
    if (irkscoData->d[i] != 0)
    {
      for (j=0; j<n; j++)
      {
        y_new[j] += irkscoData->d[i] * newtonData->x[i*n+j];
      }
    }
  }


  return 0;
}


/*! \fn wrapper_fvec_irksco
 *
 *  calculate function values or jacobian matrix
 *  fj = 1 ==> calculate function values
 *  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_fvec_irksco(int n, double* x, double* fvec, DATA_IRKSCO* userData, int fj)
{
  DATA* data = userData->data;
  threadData_t* threadData = userData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userData->newtonData;
  if (fj)
  {
    int i, j, k;
    int n0 = n/userData->ordersize;
    SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
    modelica_real* stateDer = sData->realVars + data->modelData->nStates;

    userData->evalFunctionODE++;

    for (k=0; k < userData->ordersize; k++)
    {
      for (j=0; j<n0; j++)
      {
        fvec[k*n0+j] = x[k*n0+j];
      }
    }

    for (i=0; i < userData->ordersize; i++)
    {
      sData->timeValue = userData->radauTimeOld + userData->c[i] * userData->radauStepSize;

      for (j=0; j < n0; j++)
      {
        sData->realVars[j] = userData->y0[j] + x[n0*i+j];
      }


      externalInputUpdate(data);
      data->callback->input_function(data, threadData);
      data->callback->functionODE(data, threadData);

      for (k=0; k < userData->ordersize; k++)
      {
        for (j=0; j<n0; j++)
        {
          fvec[k*n0+j] -= userData->A[i*userData->ordersize+k] * userData->radauStepSize * stateDer[j];
        }
      }

    }
  }
  else
  {
    double delta_h = sqrt(solverData->epsfcn);
    double delta_hh;
    double xsave;

    int i,j,l;

    /* profiling */
    rt_tick(SIM_TIMER_JACOBIAN);

    userData->evalJacobians++;

    for(i = 0; i < n; i++)
    {
      delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(fvec[i])), delta_h);
      delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
      delta_hh = x[i] + delta_hh - x[i];
      xsave = x[i];
      x[i] += delta_hh;
      delta_hh = 1. / delta_hh;

      wrapper_fvec_irksco(n, x, solverData->rwork, userData, 1);
      solverData->nfev++;

      for(j = 0; j < n; j++)
      {
        l = i * n + j;
        solverData->fjac[l] = (solverData->rwork[j] - fvec[j]) * delta_hh;
      }
      x[i] = xsave;
    }

    /* profiling */
    rt_accumulate(SIM_TIMER_JACOBIAN);
  }
  return 0;
}

/*! \fn refreshModel
 *
 *  function updates values in sData->realVars
 *
 *  used for solver 'irksco'
 */
static
int refreshModel(DATA* data, threadData_t *threadData, double* x, double time)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  memcpy(sData->realVars, x, sizeof(double)*data->modelData->nStates);
  sData->timeValue = time;
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/*! \fn irksco_midpoint_rule
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'irksco'
 */
int irksco_midpoint_rule(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  DATA_IRKSCO* userdata = (DATA_IRKSCO*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->newtonData;

  double sc, err, a, b, diff;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i;
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double saveTime = sDataOld->timeValue;
  double targetTime;



  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps)
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
    targetTime = sDataOld->timeValue + solverInfo->currentStepSize;
  }

  if (userdata->firstStep  || solverInfo->didEventStep == 1)
  {
    irksco_first_step(data, threadData, solverInfo);
    userdata->radauStepSizeOld = 0;
  }

  memcpy(userdata->y0, sDataOld->realVars, data->modelData->nStates*sizeof(double));

  while (userdata->radauTime < targetTime)
  {
    infoStreamPrint(LOG_SOLVER, 1, "new step to %f -> targetTime: %f", userdata->radauTime, targetTime);

    do
    {
      /*** do one step with original step size ***/
      /* set y0 */
      memcpy(userdata->y0, userdata->radauVars, data->modelData->nStates*sizeof(double));

      /* calculate jacobian once for the first iteration */
      if (userdata->stepsDone == 0)
        solverData->calculate_jacobian = 0;

      /* solve nonlinear system */
      rk_imp_step(data, threadData, solverInfo, userdata->y05);

      /* extrapolate values in y1 */
      for (i=0; i<data->modelData->nStates; i++)
      {
        userdata->y1[i] = 2.0*userdata->y05[i] - userdata->radauVars[i];
      }

      /*** do another step with original step size ***/

      /* update y0 */
      memcpy(userdata->y0, userdata->y05, data->modelData->nStates*sizeof(double));

      /* update time */
      userdata->radauTime += userdata->radauStepSize;

      /* do not calculate jacobian again */
      solverData->calculate_jacobian = -1;

      /* solve nonlinear system */
      rk_imp_step(data, threadData, solverInfo, userdata->y2);

      /* reset time */
      userdata->radauTime -= userdata->radauStepSize;


      /*** calculate error ***/
      for (i=0, err=0.0; i<data->modelData->nStates; i++)
      {
        sc = Atol + fmax(fabs(userdata->y2[i]),fabs(userdata->y1[i]))*Rtol;
        diff = userdata->y2[i]-userdata->y1[i];
        err += (diff*diff)/(sc*sc);
      }

      err /= data->modelData->nStates;
      err = sqrt(err);

      userdata->stepsDone += 1;
      /* debug
      infoStreamPrint(LOG_SOLVER, 0, "err = %e", err);
      infoStreamPrint(LOG_SOLVER, 0, "min(facmax, max(facmin, fac*sqrt(1/err))) = %e",  fmin(facmax, fmax(facmin, fac*sqrt(1.0/err))));
      */
      /* update step size */
      userdata->radauStepSizeOld = 2.0*userdata->radauStepSize;
      userdata->radauStepSize *=  fmin(facmax, fmax(facmin, fac*sqrt(1.0/err)));

      if (isnan(userdata->radauStepSize))
      {
        userdata->radauStepSize = 1e-6;
      }
      if (err>1)
      {
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        userdata->radauTimeOld, userdata->radauTime, err, userdata->radauStepSize);
      }


    } while  (err > 1.0 );

    userdata->radauTimeOld = userdata->radauTime;

    userdata->radauTime += userdata->radauStepSizeOld;
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    userdata->radauTimeOld, userdata->radauTime, err, userdata->radauStepSize);

    memcpy(userdata->radauVarsOld, userdata->radauVars, data->modelData->nStates*sizeof(double));
    memcpy(userdata->radauVars, userdata->y2, data->modelData->nStates*sizeof(double));

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = userdata->radauTime;
      memcpy(sData->realVars, userdata->radauVars, data->modelData->nStates*sizeof(double));
      /*
       * to emit consistent value we need to update the whole
       * continuous system with algebraic variables.
       */
      data->callback->updateContinuousSystem(data, threadData);
      sim_result.emit(&sim_result, data, threadData);
    }
    messageClose(LOG_SOLVER);
  }

  if (!solverInfo->integratorSteps)
  {
    solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
    sData->timeValue = solverInfo->currentTime;
    /* linear interpolation */
    for (i=0; i<data->modelData->nStates; i++)
    {
      a = (userdata->radauVars[i] - userdata->radauVarsOld[i]) / userdata->radauStepSizeOld;
      b = userdata->radauVars[i] - userdata->radauTime * a;
      sData->realVars[i] = a * sData->timeValue + b;
    }
  }else{
    solverInfo->currentTime = userdata->radauTime;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }


  if(ACTIVE_STREAM(LOG_SOLVER))
  {
    infoStreamPrint(LOG_SOLVER, 1, "irksco call statistics: ");
    infoStreamPrint(LOG_SOLVER, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER, 0, "current integration time value: %0.4g", userdata->radauTime);
    infoStreamPrint(LOG_SOLVER, 0, "step size H to be attempted on next step: %0.4g", userdata->radauStepSize);
    infoStreamPrint(LOG_SOLVER, 0, "number of steps taken so far: %d", userdata->stepsDone);
    infoStreamPrint(LOG_SOLVER, 0, "number of calls of functionODE() : %d", userdata->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER, 0, "number of calculation of jacobian : %d", userdata->evalJacobians);
    messageClose(LOG_SOLVER);
  }

  /* write stats */
  solverInfo->solverStatsTmp.nStepsTaken = userdata->stepsDone;
  solverInfo->solverStatsTmp.nCallsODE = userdata->evalFunctionODE;
  solverInfo->solverStatsTmp.nCallsJacobian = userdata->evalJacobians;

  infoStreamPrint(LOG_SOLVER, 0, "Finished irksco step.");

  return 0;
}

/*! \fn irksco_first_step
 *
 *  function initializes values and calculates
 *  initial step size at the beginning or after an event
 *
 */
void irksco_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_IRKSCO* userdata = (DATA_IRKSCO*)solverInfo->solverData;
  const int n = data->modelData->nStates;
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = 1e-6, Rtol = 1e-3;

  int i,j;

  /* initialize radau values */
  for (i=0; i<data->modelData->nStates; i++)
  {
    userdata->radauVars[i] = sData->realVars[i];
    userdata->radauVarsOld[i] = sDataOld->realVars[i];
  }

  userdata->radauTime = sDataOld->timeValue;
  userdata->radauTimeOld = sDataOld->timeValue;

  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;


  /* calculate starting step size 1st Version */

  refreshModel(data, threadData, sDataOld->realVars, sDataOld->timeValue);


  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((stateDer[i] * stateDer[i]) / (sc*sc));
  }
  d0 /= data->modelData->nStates;
  d1 /= data->modelData->nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);


  for (i=0; i<data->modelData->nStates; i++)
  {
    userdata->der_x0[i] = stateDer[i];
  }

  if (d0 < 1e-5 || d1 < 1e-5)
  {
    h0 = 1e-6;
  }
  else
  {
    h0 = 0.01 * d0/d1;
  }


  for (i=0; i<data->modelData->nStates; i++)
  {
    sData->realVars[i] = userdata->radauVars[i] + stateDer[i] * h0;
  }
  sData->timeValue += h0;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);


  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(userdata->radauVars[i])*Rtol;
    d2 += ((stateDer[i]-userdata->der_x0[i])*(stateDer[i]-userdata->der_x0[i])/(sc*sc));
  }

  d2 /= h0;
  d2 = sqrt(d2);


  d = fmax(d1,d2);

  if (d > 1e-15)
  {
    h1 = sqrt(0.01/d);
  }
  else
  {
    h1 = fmax(1e-6, h0*1e-3);
  }

  userdata->radauStepSize = 0.5*fmin(100*h0,h1);

  /* end calculation new step size */

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e", userdata->radauStepSize);
}
