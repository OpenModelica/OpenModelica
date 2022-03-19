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
 * 1) Check pointer, especially, if there is no memory leak!
 * 2) Check necessary function evaluation and counting of it (use userdata->f, userdata->fOld)
 * 3) Use analytical Jacobian of the functionODE, if available
 * 4) Use sparsity pattern and kinsol solver
 * 5) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 6) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 7) Implement other ESDIRK methods
 *
 *
*/

/*! \file esdirkmr.c
 *  % Implementation of  multirate  DIRK method  ESDIRK2(1)3L[2]SA
 * (section 4.1.1 of the Carpenter & Kennedy NASA review), with variable time
 * step. Uses embedded method of order 1 for error estimation.
 *
 * Based on work from S. Fernandez Garcia, U. Sevilla
 * and L.Bonaventura,  Polimi  2020-22
 *
 *  \author bbachmann
 */

#include <string.h>
#include <float.h>

#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"
#include "external_input.h"
#include "newtonIteration.h"
#include "esdirkmr.h"

//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void printVector_ESDIRKMR(char name[], double* a, int n, double time);

/*! \fn allocateESDIRKMR
 *
 *   Function allocates memory needed for ESDIRK method.
 *
 */

int allocateESDIRKMR(SOLVER_INFO* solverInfo, int size, int zcSize)
{
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*) malloc(sizeof(DATA_ESDIRKMR));
  solverInfo->solverData = (void*) userdata;

  allocateNewtonData(size, &(userdata->solverData));
  userdata->firstStep = 1;
  userdata->y = malloc(sizeof(double)*size);
  userdata->yOld = malloc(sizeof(double)*size);
  userdata->yt = malloc(sizeof(double)*size);
  userdata->f = malloc(sizeof(double)*size);
  userdata->fOld = malloc(sizeof(double)*size);
  userdata->k1 = malloc(sizeof(double)*size);
  userdata->k2 = malloc(sizeof(double)*size);
  userdata->k3 = malloc(sizeof(double)*size);
  userdata->errest = malloc(sizeof(double)*size);
  userdata->errtol = malloc(sizeof(double)*size);

  /* initialize values of the Butcher tableau */
  userdata->gam = (2.0-sqrt(2.0))*0.5;
  userdata->c2 = 2.0*userdata->gam;
  userdata->b1 = sqrt(2.0)/4.0;
  userdata->b2 = userdata->b1;
  userdata->b3 = userdata->gam;
  userdata->bt1 = 1.75-sqrt(2.0);
  userdata->bt2 = userdata->bt1;
  userdata->bt3 = 2.0*sqrt(2.0)-2.5;
  userdata->bh1 = userdata->b1 - userdata->bt1;
  userdata->bh2 = userdata->b2 - userdata->bt2;
  userdata->bh3 = userdata->b3 - userdata->bt3;
  infoStreamPrint(LOG_SOLVER, 1, "Butcher tableau of ESDIRK-method:");
  infoStreamPrint(LOG_SOLVER, 0, "%10d | %10d",0,0);
  infoStreamPrint(LOG_SOLVER, 0, "%10g | %10g %10g",userdata->c2,userdata->gam,userdata->gam);
  infoStreamPrint(LOG_SOLVER, 0, "%10d | %10g %10g %10g",1,userdata->b1,userdata->b2,userdata->b3);
  infoStreamPrint(LOG_SOLVER, 0, "------------------------------------------------");
  infoStreamPrint(LOG_SOLVER, 0, "%10s | %10g %10g %10g","",userdata->b1,userdata->b2,userdata->b3);
  infoStreamPrint(LOG_SOLVER, 0, "%10s | %10g %10g %10g","",userdata->bt1,userdata->bt2,userdata->bt3);

  /* initialize stats */
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;

  return 0;
}

/*! \fn freeESDIRKmr
 *
 *   Memory needed for solver is set free.
 */
int freeESDIRKMR(SOLVER_INFO* solverInfo)
{
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*) solverInfo->solverData;
  freeNewtonData(&(userdata->solverData));

  free(userdata->y);
  free(userdata->yOld);
  free(userdata->yt);
  free(userdata->f);
  free(userdata->fOld);
  free(userdata->k1);
  free(userdata->k2);
  free(userdata->k3);
  free(userdata->errest);
  free(userdata->errtol);

  return 0;
}

/*!	\fn wrapper_f_ESDIRKMR
 *
 *  calculate function values of function ODE f(t,y)
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      data           data of the underlying DAE
 *  \param [in]      threadData     data for error handling
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [out]     stateDer       pointer to state derivatives
 *
 */
int wrapper_f_ESDIRKMR(DATA* data, threadData_t *threadData, void* userdata, modelica_real* stateDer)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  stateDer = sData->realVars + data->modelData->nStates;

  ESDIRKMRData->evalFunctionODE++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/*!	\fn wrapper_Jf_ESDIRKMR
 *
 *  calculate the Jacobian of functionODE with respect to the states
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      n              pointer to number of states
 *  \param [in]      x              pointer to state vector
 *  \param [in]      fvec           pointer to corresponding fODE-values usually
 *                                  stored in userdata->f (verify before calling)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [out]     fODE           pointer to state derivatives
 *
 *  result of the Jacobian is stored in solverData->fjac (DATA_NEWTON)
 *
 */
int wrapper_Jf_ESDIRKMR(int* n, double* x, double* fvec, void* userdata, double* fODE)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh;
  double xsave;

  int i,j,l;

  /* profiling */
  rt_tick(SIM_TIMER_JACOBIAN);

  ESDIRKMRData->evalJacobians++;

  for(i = 0; i < *n; i++)
  {
    delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(fvec[i])), delta_h);
    delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
    delta_hh = x[i] + delta_hh - x[i];
    xsave = x[i];
    x[i] += delta_hh;
    delta_hh = 1. / delta_hh;

    wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
    // this should not count on function evaluation, since
    // it belongs to jacobian evaluation
    ESDIRKMRData->evalFunctionODE--;

    /* BB: Is this necessary for the statistics? */
    solverData->nfev++;

    for(j = 0; j < *n; j++)
    {
      l = i * *n + j;
      solverData->fjac[l] = (fODE[j] - fvec[j]) * delta_hh;
    }
    x[i] = xsave;
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
  return 0;
}

/*!	\fn wrapper_G2_ESDIRKMR
 *      residual function res = yOld-y+gam*h*(k1+f(tOld+c2*h,y)); c2=2*gam;
 *      i.e. solve for:
 *           y1g = yOld+gam*h*(k1+f(tOld+c2*h,y1g)) = yOld+gam*h*(k1+k2)
 *      <=>  k2  = f(tOld+c2*h,yOld+gam*h*(k1+k2))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_G2_ESDIRKMR(int* n_p, double* x, double* res, void* userdata, int fj)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = (*n_p);

  int i, j, l;

  if (fj)
  {
    // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
    // set correct time value and states of simulation system
    sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c2*ESDIRKMRData->stepSize;
    memcpy(sData->realVars, x, n*sizeof(double));
    wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
     for (j=0; j<n; j++)
    {
      res[j] = ESDIRKMRData->yOld[j] - x[j] + ESDIRKMRData->gam * ESDIRKMRData->stepSize * (ESDIRKMRData->k1[j] + fODE[j]);
    }
  }
  else
  {
    /*!
     *  fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
     *  set correct time value and states of simulation system
     *  this should not count on function evaluation, since
     *  it belongs to the jacobian evaluation
     *  \ToBeChecked: This calculation maybe not be necessary since f has already
     *                just evaluated!
     */
    // sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->c2*ESDIRKMRData->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
    // ESDIRKMRData->evalFunctionODE--;

    /* store values for finite differences scheme*/
    memcpy(ESDIRKMRData->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, result is in solverData->fjac */
    wrapper_Jf_ESDIRKMR(n_p, x, ESDIRKMRData->f, userdata, fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(i = 0; i < n; i++)
    {
      for(j = 0; j < n; j++)
      {
        l = i * n + j;
        solverData->fjac[l] = ESDIRKMRData->gam * ESDIRKMRData->stepSize * solverData->fjac[l];
        if (i==j) solverData->fjac[l] -= 1;
      }
    }
  }
  return 0;
}

/*!	\fn wrapper_G3_ESDIRKMR
 *      residual function res = yOld-y+h*(b1*k1+b2*k2+b3*f(tk+h,y));
 *      i.e. solve for:
 *           y2g = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g)) = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g))
 *      <=>  k3  = f(tOld+h,yOld+h*(b1*k1+b2*k2+b3*k3))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_ESDIRKMR)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_G3_ESDIRKMR(int* n_p, double* x, double* res, void* userdata, int fj)
{
  DATA_ESDIRKMR* ESDIRKMRData = (DATA_ESDIRKMR*) userdata;

  DATA* data = ESDIRKMRData->data;
  threadData_t* threadData = ESDIRKMRData->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)ESDIRKMRData->solverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = (*n_p);

  int i, j, l;

  if (fj)
  {
    // fODE = f(tOld + h,x); x ~ yOld + h*(b1*k1+b2*k2+b3*k3)
    // set correct time value and states of simulation system
    sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->stepSize;
    memcpy(sData->realVars, x, n*sizeof(double));
    wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);

    // residual function res = yOld-x+h*(b1*k1+b2*k2+b3*f(tk+h,x))
    for (j=0; j<n; j++)
    {
      res[j] = ESDIRKMRData->yOld[j] - x[j] + ESDIRKMRData->stepSize *
               (ESDIRKMRData->b1 * ESDIRKMRData->k1[j] + ESDIRKMRData->b2 * ESDIRKMRData->k2[j] + ESDIRKMRData->b3 * fODE[j]);
    }
  }
  else
  {
    /*!
     *  fODE = f(tOld + h,x); x ~ yOld + h*(b1*k1+b2*k2+b3*k3)
     *  set correct time value and states of simulation system
     *  this should not count on function evaluation, since
     *  it belongs to the jacobian evaluation
     *  \ToBeChecked: This calculation maybe not be necessary since f has already
     *                just evaluated! works so far
     */
    // sData->timeValue = ESDIRKMRData->time + ESDIRKMRData->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_ESDIRKMR(data, threadData, userdata, fODE);
    // ESDIRKMRData->evalFunctionODE--;

    /* store values for finite differences scheme*/
    memcpy(ESDIRKMRData->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, stored in  solverData->fjac */
    wrapper_Jf_ESDIRKMR(n_p, x, ESDIRKMRData->f, userdata, fODE);

    // residual function res = yOld-x+h*(b1*k1+b2*k2+b3*f(tk+h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(i = 0; i < n; i++)
    {
      for(j = 0; j < n; j++)
      {
        l = i * n + j;
        solverData->fjac[l] = ESDIRKMRData->stepSize * ESDIRKMRData->b3 * solverData->fjac[l];
        if (i==j) solverData->fjac[l] -= 1;
      }
    }
  }
  return 0;
}


/*! \fn ESDIRKMR_first_step
 *
 *  function initializes values and calculates
 *  initial step size at the beginning or after an event
 *  BB: ToDo: lookup the reference in Hairers book
 *
 */
void ESDIRKMR_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  const int n = data->modelData->nStates;
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = 1e-6, Rtol = 1e-3;

  int i,j;

  /* initialize start values of the integrator*/
  memcpy(userdata->yOld, sData->realVars, data->modelData->nStates*sizeof(double));

  /* store Startime of the simulation */
  userdata->time = sDataOld->timeValue;

  /* set correct flags in order to calculate initial step size */
  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;


  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  memcpy(sData->realVars, sDataOld->realVars, sizeof(double)*data->modelData->nStates);
  sData->timeValue = sDataOld->timeValue;
  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);

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

  /* store values of the state derivatives for the starting values */
  memcpy(userdata->f, stateDer, data->modelData->nStates*sizeof(double));

  /* calculate first guess of the initial step size */
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
    sData->realVars[i] = userdata->yOld[i] + stateDer[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(userdata->yOld[i])*Rtol;
    d2 += ((stateDer[i]-userdata->f[i])*(stateDer[i]-userdata->f[i])/(sc*sc));
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

  userdata->stepSize = 0.5*fmin(100*h0,h1);

  /* end calculation new step size */

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e", userdata->stepSize);
}

/*!	\fn esdirkmr_imp_step
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int esdirkmr_imp_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, n=data->modelData->nStates;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->solverData;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  double a,b;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  solverData->initialized = 1;
  solverData->numberOfIterations = 0;
  solverData->numberOfFunctionEvaluations = 0;
  solverData->n = n;

  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  // k1 = f(tOld,yOld)
  // set correct time value and states of simulation system
  sData->timeValue = userdata->time;
  memcpy(sData->realVars, userdata->yOld, n*sizeof(double));
  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);
  memcpy(userdata->k1, stateDer, n*sizeof(double));

  // solve for y1g: 0 = yold-y1g+gam*h*(k1+f(tOld+2*gam*h,y1g))
  // set good starting values for the newton solver
  // set newton strategy
  memcpy(solverData->x, userdata->yOld, n*sizeof(double));
  solverData->newtonStrategy = NEWTON_DAMPED2;
  _omc_newton(wrapper_G2_ESDIRKMR, solverData, (void*)userdata);

  /* if newton solver did not converge, do ??? */
  if (solverData->info == -1)
  {
    // to be defined!
    // reject and reduce time step would be an option
    // or influence the calculation of the Jacobian during the newton steps
    // solverData->calculate_jacobian = 1;

    printf("What to do?\n");
  }

  // k2 = f(tOld + 2*gam*h,y1g)
  // set correct time value and states of simulation system
  sData->timeValue = userdata->time + userdata->c2 * userdata->stepSize;
  memcpy(sData->realVars, solverData->x, n*sizeof(double));
  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);
  memcpy(userdata->k2, stateDer, n*sizeof(double));

  // solve for y2g: 0 = yold-y2g+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g))
  // set good starting values for the newton solver (solution of the last newton iteration!)
  // set newton strategy
  solverData->newtonStrategy = NEWTON_DAMPED2;
  _omc_newton(wrapper_G3_ESDIRKMR, solverData, (void*)userdata);
 /* if newton solver did not converge, do ??? */
  if (solverData->info == -1)
  {
    // to be defined!
    // reject and reduce time step would be an option
    // or influence the calculation of the Jacobian during the newton steps
    // solverData->calculate_jacobian = 1;
    printf("What to do?\n");
  }

  // k3 = f(tOld + h,y2g)
  // set correct time value and states of simulation system
  sData->timeValue = userdata->time + userdata->stepSize;
  memcpy(sData->realVars, solverData->x, n*sizeof(double));
  wrapper_f_ESDIRKMR(data, threadData, userdata, stateDer);
  memcpy(userdata->k3, stateDer, n*sizeof(double));

  // y      = yold+h*(b1*k1 +b2*k2 +b3*k3);
  // yt     = yold+h*(b1*k1 +b2*k2 +b3*k3);
  // errest = dt*abs(bh1*k1+bh2*k2+bh3*k3) = abs(y-yt);
  // errtol = rtol*abs(yold)+atol;
  // calculate corresponding values for error estimator and step size control
  for (i=0; i<n; i++)
  {
    userdata->y[i] = userdata->yOld[i] + userdata->stepSize *
                     (userdata->b1 * userdata->k1[i] + userdata->b2 * userdata->k2[i] + userdata->b3 * userdata->k3[i]);
    userdata->errtol[i] = Rtol*fabs(userdata->yOld[i]) + Atol;
    userdata->errest[i] = userdata->stepSize *
                     fabs(userdata->bh1 * userdata->k1[i] + userdata->bh2 * userdata->k2[i] + userdata->bh3 * userdata->k3[i]);
    // alternative calculation
    // userdata->yt[i] = userdata->yOld[i] + userdata->stepSize *
    //                 (userdata->bt1 * userdata->k1[i] + userdata->bt2 * userdata->k2[i] + userdata->bt3 * userdata->k3[i]);
    // userdata->errest[i] = fabs(userdata->y[i] - userdata->yt[i]);
  }

  return 0;
}

/*! \fn esdirkmr_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'ESDIRKMR'
 */
int esdirkmr_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* stateDer = sData->realVars + data->modelData->nStates;
  DATA_ESDIRKMR* userdata = (DATA_ESDIRKMR*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->solverData;

  double err;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i;
  int esdirk_imp_step_info;
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.3;
  double norm_errtol;
  double norm_errest;
  double targetTime;

  /* Calculate steps until targetTime is reached */
  if (solverInfo->integratorSteps) // 1 => stepSizeControl; 0 => equidistant grid
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
    ESDIRKMR_first_step(data, threadData, solverInfo);
  }

  while (userdata->time < targetTime)
  {
    do
    {
      /* calculate jacobian once for the first iteration
       * BB: How does this actually works in comination with the Newton method?
       */
      if (userdata->stepsDone == 0)
        solverData->calculate_jacobian = 0;

      esdirk_imp_step_info = esdirkmr_imp_step(data, threadData, solverInfo);

      /*** calculate error (infinity norm!)***/
      norm_errtol = 0;
      norm_errest = 0;
      for (i=0; i<data->modelData->nStates; i++)
      {
         norm_errtol = fmax(norm_errtol, userdata->errtol[i]);
         norm_errest = fmax(norm_errest, userdata->errest[i]);
      }
      err = norm_errest/norm_errtol;

      // Store performed stepSize for adjusting the time and interpolation purposes
      userdata->lastStepSize = userdata->stepSize;

      userdata->stepSize *= fmin(facmax, fmax(facmin, fac*sqrt(1.0/err)));
      /*
       * step size control from Luca, etc.:
       * stepSize = seccoeff*sqrt(norm_errtol/fmax(norm_errest,errmin));
       * printf("Error:  %g, New stepSize: %g from %g to  %g\n", err, userdata->stepSize, userdata->time, userdata->time+stepSize);
       */
      if (err>1)
      {
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        userdata->time, userdata->time + userdata->lastStepSize, err, userdata->stepSize);
      }
      userdata->stepsDone += 1;
    } while  (err>1);

    /* update time with performed stepSize */
    userdata->time += userdata->lastStepSize;

    /* store yOld in yt for interpolation purposes, if necessary
     * BB: Check condition
     */
    if (userdata->time > targetTime )
      memcpy(userdata->yt, userdata->yOld, data->modelData->nStates*sizeof(double));

    /* step is accepted and yOld needs to be updated */
    memcpy(userdata->yOld, userdata->y, data->modelData->nStates*sizeof(double));
    infoStreamPrint(LOG_SOLVER, 1, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    userdata->time- userdata->lastStepSize, userdata->time, err, userdata->stepSize);

    /* emit step, if integratorSteps is selected */
    if (solverInfo->integratorSteps)
    {
      sData->timeValue = userdata->time;
      memcpy(sData->realVars, userdata->y, data->modelData->nStates*sizeof(double));
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
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    solverInfo->currentTime = sDataOld->timeValue + solverInfo->currentStepSize;
    sData->timeValue = solverInfo->currentTime;
    linear_interpolation(userdata->time-userdata->lastStepSize, userdata->yt, userdata->time, userdata->y, sData->timeValue, sData->realVars, data->modelData->nStates);
    // printVector_ESDIRKMR("yOld: ", userdata->yt, data->modelData->nStates, userdata->time-userdata->lastStepSize);
    // printVector_ESDIRKMR("y:    ", userdata->y, data->modelData->nStates, userdata->time);
    // printVector_ESDIRKMR("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
  }else{
    // Integrator emits result on the simulation grid
    solverInfo->currentTime = userdata->time;
  }

  /* if a state event occurs than no sample event does need to be activated  */
  if (data->simulationInfo->sampleActivated && solverInfo->currentTime < data->simulationInfo->nextSampleEvent)
  {
    data->simulationInfo->sampleActivated = 0;
  }

  if(ACTIVE_STREAM(LOG_SOLVER))
  {
    infoStreamPrint(LOG_SOLVER, 1, "ESDIRKMR call statistics: ");
    infoStreamPrint(LOG_SOLVER, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER, 0, "current integration time value: %0.4g", userdata->time);
    infoStreamPrint(LOG_SOLVER, 0, "step size h to be attempted on next step: %0.4g", userdata->stepSize);
    infoStreamPrint(LOG_SOLVER, 0, "number of steps taken so far: %d", userdata->stepsDone);
    infoStreamPrint(LOG_SOLVER, 0, "number of calls of functionODE() : %d", userdata->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER, 0, "number of calculation of jacobian : %d", userdata->evalJacobians);
    messageClose(LOG_SOLVER);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = userdata->stepsDone;
  solverInfo->solverStatsTmp[1] = userdata->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = userdata->evalJacobians;

  infoStreamPrint(LOG_SOLVER, 0, "Finished ESDIRKMR step.");

  return 0;
}

//auxiliary vector functions for better code structure
void linear_interpolation(double ta, double* fa, double tb, double* fb, double t, double* f, int n)
{
  double lambda, h0, h1;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<n; i++)
  {
    f[i] = h0*fa[i] + h1*fb[i];
  }
}

void printVector_ESDIRKMR(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: ", name, time);
  for (int i=0;i<n;i++)
    printf("%g ", a[i]);
  printf("\n");
}


