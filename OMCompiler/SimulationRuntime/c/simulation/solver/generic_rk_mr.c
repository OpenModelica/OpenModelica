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

/*! \file genericRKmr.c
 *  Implementation of  a generic (implicit and explicit) Runge Kutta solver, which works for any
 *  order and stage based on a provided Butcher tableau
 *
 *  \author bbachmann
 */

#include "generic_rk.h"

#include <float.h>
#include <math.h>
#include <string.h>

#include "external_input.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "simulation/options.h"
#include "simulation/results/simulation_result.h"
#include "util/omc_error.h"
#include "util/simulation_options.h"
#include "util/varinfo.h"

// help functions
void printVector_genericRK(char name[], double* a, int n, double time);
void printIntVector_genericRK(char name[], int* a, int n, double time);
void printVector_genericRK_MR_fs(char name[], double* a, int n, double time, int nIndx, int* indx);
void printMatrix_genericRK(char name[], double* a, int n, double time);


// singlerate step function
int expl_diag_impl_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK_MR(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

// step size control function
double IController(double* err_values, double err_order);
double PIController(double* err_values, double err_order);

double checkForEvents(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double timeLeft, double* leftValues, double timeRight, double* rightValues);

/**
 * @brief Function allocates memory needed for chosen RK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGenericRK_MR(DATA* data, threadData_t *threadData, DATA_GENERIC_RK* genericRKData)
{
  DATA_GENERIC_RK_MR* userdata = (DATA_GENERIC_RK_MR*) malloc(sizeof(DATA_GENERIC_RK_MR));
  genericRKData->dataRKmr = userdata;

  userdata->nStates = genericRKData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  userdata->RK_method = getRK_Method(FLAG_RK_MR);
  userdata->tableau = initButcherTableau(userdata->RK_method);
  if (userdata->tableau == NULL){
    // ERROR
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }
  // Check explicit, diagonally implicit or fully implicit status and fix solver settings
  enum RK_type expl;
  analyseButcherTableau(userdata->tableau, userdata->nStates, &userdata->nlSystemSize, &expl);

  switch (expl)
  {
  case RK_TYPE_EXPLICIT:
    userdata->isExplicit = TRUE;
    userdata->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case RK_TYPE_DIRK:
    userdata->isExplicit = FALSE;
    userdata->step_fun = &(expl_diag_impl_RK_MR);
    break;
  case RK_TYPE_IMPLICIT:
    errorStreamPrint(LOG_STDOUT, 0, "Fully Implicit RK method is not supported for the fast states integration!");
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);

    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_SOLVER, 0, "Step control factor is set to %g", userdata->tableau->fac);

  const char* flag_StepSize_ctrl = omc_flagValue[FLAG_RK_STEPSIZE_CTRL];

  if (flag_StepSize_ctrl != NULL) {
    userdata->stepSize_control = &(PIController);
    infoStreamPrint(LOG_SOLVER, 0, "PIController is use for step size control");
  } else
  {
    userdata->stepSize_control = &(IController);
    infoStreamPrint(LOG_SOLVER, 0, "IController is use for step size control");
  }

  // allocate memory for the generic RK method
  userdata->firstStep = 1;
  userdata->y = malloc(sizeof(double)*userdata->nStates);
  userdata->yOld = malloc(sizeof(double)*userdata->nStates);
  //userdata->yStart = malloc(sizeof(double)*userdata->nStates);
  //userdata->yEnd = malloc(sizeof(double)*userdata->nStates);
  userdata->yt = malloc(sizeof(double)*userdata->nStates);
  userdata->f = malloc(sizeof(double)*userdata->nStates);
  if (!userdata->isExplicit) {
    userdata->Jf = malloc(sizeof(double)*userdata->nStates*userdata->nStates);
    for (int i=0; i<userdata->nStates*userdata->nStates; i++)
      userdata->Jf[i] = 0;

  } else {
    userdata->Jf = NULL;
  }
  userdata->k = malloc(sizeof(double)*userdata->nStates*userdata->tableau->nStages);
  userdata->res_const = malloc(sizeof(double)*userdata->nStates);
  userdata->errest = malloc(sizeof(double)*userdata->nStates);
  userdata->errtol = malloc(sizeof(double)*userdata->nStates);
  userdata->err = malloc(sizeof(double)*userdata->nStates);
  //userdata->fastStates = malloc(sizeof(int)*userdata->nStates);
  //userdata->slowStates = malloc(sizeof(int)*userdata->nStates);

  userdata->nFastStates = userdata->nStates;
  userdata->nSlowStates = 0;

  printButcherTableau(userdata->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;
  userdata->errorTestFailures = 0;
  userdata->convergenceFailures = 0;

  userdata->err_new = -1;

  /* initialize analytic Jacobian, if available and needed */
  if (!userdata->isExplicit) {
    jacobian = &(data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A]);
    if (data->callback->initialAnalyticJacobianA(data, threadData, jacobian)) {
      userdata->symJacAvailable = FALSE;
      infoStreamPrint(LOG_STDOUT, 0, "Jacobian or SparsePattern is not generated or failed to initialize! Switch back to normal.");
    } else {
      userdata->symJacAvailable = TRUE;
      // TODO AHeu: Is there a reason we get the jacobian again? Did data->callback->initialAnalyticJacobianA change the pointer?
      // ANALYTIC_JACOBIAN* jac = &data->simulationInfo->analyticJacobians[data->callback->INDEX_JAC_A];
      infoStreamPrint(LOG_SOLVER, 1, "Initialized colored Jacobian:");
      infoStreamPrint(LOG_SOLVER, 0, "columns: %d rows: %d", jacobian->sizeCols, jacobian->sizeRows);
      infoStreamPrint(LOG_SOLVER, 0, "NNZ:  %d colors: %d", jacobian->sparsePattern->numberOfNonZeros, jacobian->sparsePattern->maxColors);
      messageClose(LOG_SOLVER);
    }
  }

  // BB ToDo: Fix nls solver for multirate part
  userdata->nlsSolverMethod = RK_NLS_NEWTON;
  userdata->nlsSolverData = (void*) allocateNewtonData(userdata->nlSystemSize);
  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK_MR(DATA_GENERIC_RK_MR* data) {
  freeNewtonData(data->nlsSolverData);

  freeButcherTableau(data->tableau);

  free(data->y);
  free(data->yOld);
  //free(data->yStart);
  //free(data->yEnd);
  free(data->yt);
  free(data->f);
  free(data->Jf);
  free(data->k);
  free(data->res_const);
  free(data->errest);
  free(data->errtol);
  free(data->err);
  //free(data->fastStates);
  //free(data->slowStates);

  free(data);
  data = NULL;

  return;
}

/*!	\fn wrapper_Jf_genericRK
 *
 *  calculate the Jacobian of functionODE with respect to the fast states
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      n              pointer to number of states
 *  \param [in]      x              pointer to state vector
 *  \param [in]      fvec           pointer to corresponding fODE-values usually
 *                                  stored in userdata->f (verify before calling)
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK_MR)
 *  \param [out]     fODE           pointer to state derivatives
 *
 *  result of the Jacobian is stored in solverData->fjac (DATA_NEWTON) ???????
 *
 */
int wrapper_Jf_genericRK_MR(int n, double t, double* x, double* fODE, void* genericRKData)
{
  DATA_GENERIC_RK_MR* userdata = (DATA_GENERIC_RK_MR*) genericRKData;

  DATA* data = userdata->data;
  threadData_t* threadData = userdata->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;

  int i,ii,j,jj,l,callJacColumns;

  // if ((solverData->calculate_jacobian >= 0) && (userdata->evalJacobians==0))
  {
    /* profiling */
    rt_tick(SIM_TIMER_JACOBIAN);

    userdata->evalJacobians++;

    if (userdata->symJacAvailable)
    {
      const int index = data->callback->INDEX_JAC_A;
      ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);
      unsigned int columns = jac->sizeCols;
      unsigned int rows = jac->sizeRows;
      unsigned int sizeTmpVars = jac->sizeTmpVars;
      unsigned int currentIndex, nth;
      SPARSE_PATTERN* spp = jac->sparsePattern;

      /* Evaluate constant equations if available */
      // BB: Do I need this?
      if (jac->constantEqns != NULL) {
        jac->constantEqns(data, threadData, jac, NULL);
      }
      // genericColoredSymbolicJacobianEvaluation(rows, columns, spp, userdata->Jf, jac,
      //                                     data, threadData, &setJacElementESDIRKSparse_MR);
      /* Reset seed vector */
      // This is necessary, when memory is allocated
      for (j=0; j < columns; j++) {
        jac->seedVars[j] = 0;
      }
      for (i=0; i < spp->maxColors; i++) {
        callJacColumns = FALSE;
        for (jj=0; jj < userdata->nFastStates; jj++) {
          j = userdata->fastStates[jj];
          if (spp->colorCols[j]-1 == i) {
            callJacColumns = TRUE;
            jac->seedVars[j] = 1;
          }
        }

        if (callJacColumns) {
          /* Evaluate with updated seed vector */
          data->callback->functionJacA_column(data, threadData, jac, NULL);
          for (jj=0; jj < userdata->nFastStates; jj++) {
            j = userdata->fastStates[jj];
            if (jac->seedVars[j] == 1) {
              nth = spp->leadindex[j];
              while (nth < spp->leadindex[j+1]) {
                currentIndex = spp->index[nth];
                userdata->Jf[j*rows + currentIndex] = jac->resultVars[currentIndex];
                nth++;
              }
            }
          }

          /* Reset seed vector */
          for (j=0; j < columns; j++) {
            jac->seedVars[j] = 0;
          }
        }
      }
    }
    else
    {
      warningStreamPrint(LOG_STDOUT, 0, "Numerical Jacobian is used");

      double delta_h = sqrt(solverData->epsfcn);
      double delta_hh;
      double xsave;

      memcpy(userdata->f, fODE, n * sizeof(double));
      for(ii = 0; ii < userdata->nFastStates; ii++)
      {
        i = userdata->fastStates[ii];
        delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(userdata->f[i])), delta_h);
        delta_hh = ((userdata->f[i] >= 0) ? delta_hh : -delta_hh);
        delta_hh = x[i] + delta_hh - x[i];
        xsave = x[i];
        x[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        wrapper_f_genericRK(data, threadData, &(userdata->evalFunctionODE), fODE);
        // this should not count on function evaluation, since
        // it belongs to jacobian evaluation
        userdata->evalFunctionODE--;

        /* BB: Is this necessary for the statistics? */
        solverData->nfev++;

        for(j = 0; j < n; j++)
        {
          l = i * n + j;
          userdata->Jf[l] = (fODE[j] - userdata->f[j]) * delta_hh;
        }
        x[i] = xsave;
      }
    }

    /* profiling */
    rt_accumulate(SIM_TIMER_JACOBIAN);
  }
  return 0;
}

/*!	\fn wrapper_DIRK
 *      residual function res = yOld-y+gam*h*(k1+f(tOld+c2*h,y)); c2=2*gam;
 *      i.e. solve for:
 *           y1g = yOld+gam*h*(k1+f(tOld+c2*h,y1g)) = yOld+gam*h*(k1+k2)
 *      <=>  k2  = f(tOld+c2*h,yOld+gam*h*(k1+k2))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK_MR)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_DIRK(int* n_p, double* x, double* res, void* genericRKData, int fj)
{
  DATA_GENERIC_RK_MR* userdata = (DATA_GENERIC_RK_MR*) genericRKData;

  DATA* data = userdata->data;
  threadData_t* threadData = userdata->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int nStates = userdata->nStates;
  int nFastStates = userdata->nFastStates;

  //printf("Dimensionen nFastStates = %d, n_nonlinear = %d\n", n, *n_p);

  int i, ii, j, jj, l, ll, k;

  // index of diagonal element of A
  k = userdata->act_stage * userdata->tableau->nStages + userdata->act_stage;
  if (fj)
  {
    for (j=0; j<nFastStates;j++)
      sData->realVars[userdata->fastStates[j]] = x[j];
    // fODE = f(tOld + c2*h,x); x ~ yOld + h*(ai1*k1+ai2*k2+...+aii*ki)
    // res_const = yOld + h*(ai1*k1+ai2*k2+...+ai{i-1}*k{i-1})
    // set correct time value and states of simulation system
    // BB: Need to have the interpolated values in sData->realVars!!!! check,check,check
    // sData->timeValue = userdata->time + userdata->tableau->c[userdata->act_stage]*userdata->stepSize;
    wrapper_f_genericRK(data, threadData, &(userdata->evalFunctionODE), fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    for (j=0; j<nFastStates; j++)
    {
      jj = userdata->fastStates[j];
      res[j] = userdata->res_const[jj] - x[j] + userdata->stepSize * userdata->tableau->A[k]  * fODE[jj];
    }
    // printVector_genericRK("sData->realVars (fast states)", sData->realVars, userdata->nStates, sData->timeValue);
    // printVector_genericRK("fODE            (fast states)", fODE, userdata->nStates, sData->timeValue);
    // printVector_genericRK("res_const       (fast states)", userdata->res_const, userdata->nStates, sData->timeValue);
    // printVector_genericRK("res             (fast states)", res, userdata->nStates, sData->timeValue);
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
    // sData->timeValue = userdata->time + userdata->c2*userdata->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_genericRK(data, threadData, userdata, fODE);
    // userdata->evalFunctionODE--;

    /* store values for finite differences scheme
     * not necessary for analytic Jacobian */
    //memcpy(userdata->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, result is in solverData->fjac */
    // set correct time value and states of simulation system
    // BB: Need to have the interpolated values in sData->realVars!!!! check,check,check
    // sData->timeValue = userdata->time + userdata->tableau->c[userdata->act_stage]*userdata->stepSize;
    // fODE correct?
    wrapper_Jf_genericRK_MR(userdata->nStates, sData->timeValue, sData->realVars, fODE, userdata);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(i = 0; i < nFastStates; i++)
    {
      for(j = 0; j < nFastStates; j++)
      {
        l = i * nFastStates + j;
        ii = userdata->fastStates[i];
        jj = userdata->fastStates[j];
        ll = ii * userdata->nStates + jj;
        solverData->fjac[l] = userdata->stepSize * userdata->tableau->A[k] * userdata->Jf[ll];
        if (i==j) solverData->fjac[l] -= 1;
      }
    }
    // printMatrix_genericRK("Jacobian (fast states)", solverData->fjac, userdata->nStates, userdata->time);
    // printMatrix_genericRK("Jacobian (fast states)", userdata->Jf, userdata->nStates, userdata->time);
  }
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
  int i, ii, j, jj, l, k, nStates = data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* genericRKData = (DATA_GENERIC_RK*)solverInfo->solverData;
  DATA_GENERIC_RK_MR* userdata = genericRKData->dataRKmr;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->nlsSolverData;

  int nStages = userdata->tableau->nStages;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  // interpolate the slow states on the current time of userdata->yOld for correct evaluation of userdata->res_const
  linear_interpolation_MR(userdata->startTime, userdata->yStart,
                          userdata->endTime,   userdata->yEnd,
                          userdata->time, userdata->yOld, userdata->nSlowStates, userdata->slowStates);
  // printVector_genericRK("yOld", userdata->yOld, userdata->nStates, userdata->time);

  for (userdata->act_stage = 0; userdata->act_stage < userdata->tableau->nStages; userdata->act_stage++)
  {
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    k = userdata->act_stage * userdata->tableau->nStages;

    // set simulation time with respect to the current stage
    sData->timeValue = userdata->time + userdata->tableau->c[userdata->act_stage]*userdata->stepSize;
    solverInfo->currentTime = sData->timeValue;

    // yOld from integrator is correct for the fast states
    // BB ToDo: k[i] should be correct for the previous stages! Check!!
    for (j=0; j<nStates; j++)
    {
      userdata->res_const[j] = userdata->yOld[j];
      for (l=0; l<userdata->act_stage; l++)
        userdata->res_const[j] += userdata->stepSize * userdata->tableau->A[k + l] * (userdata->k + l * nStates)[j];
    }

    // index of diagonal element of A
    k = userdata->act_stage * userdata->tableau->nStages + userdata->act_stage;

    if (userdata->tableau->A[k] == 0)
    {
      // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
      // set correct time value and states of simulation system
      memcpy(sData->realVars, userdata->res_const, nStates*sizeof(double));
      wrapper_f_genericRK(data, threadData, &(userdata->evalFunctionODE), fODE);
    }
    else
    {
      solverData->initialized = 1;
      solverData->numberOfIterations = 0;
      solverData->numberOfFunctionEvaluations = 0;
      solverData->n = userdata->nFastStates;

      // interpolate the slow states on the time of the current stage
      linear_interpolation_MR(userdata->startTime, userdata->yStart,
                              userdata->endTime,   userdata->yEnd,
                              sData->timeValue, sData->realVars, userdata->nSlowStates, userdata->slowStates);

      // BB ToDo: set good starting values for the newton solver (solution of the last newton iteration!)
      // setting the start vector for the newton step
      // for (i=0; i<userdata->nFastStates; i++)
      //   solverData->x[i] = userdata->yOld[userdata->fastStates[i]];

      for (i=0; i<userdata->nFastStates; i++) {
        ii = userdata->fastStates[i];
        solverData->x[i] = userdata->yOld[ii] + userdata->tableau->c[userdata->act_stage] * userdata->stepSize * (userdata->k + (nStages-1)*nStates)[ii];
      }
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      // set newton strategy
      solverData->newtonStrategy = NEWTON_DAMPED2;
      _omc_newton(wrapper_DIRK, solverData, (void*)userdata);

      /* if newton solver did not converge, do ??? */
      if (solverData->info == -1)
      {
        userdata->convergenceFailures++;
        // to be defined!
        // reject and reduce time step would be an option
        // or influence the calculation of the Jacobian during the newton steps
        solverData->numberOfIterations = 0;
        solverData->numberOfFunctionEvaluations = 0;
        solverData->calculate_jacobian = 1;

        warningStreamPrint(LOG_SOLVER, 0, "nonlinear solver did not converge at time %e, do iteration again with calculating jacobian in every step", solverInfo->currentTime);
        _omc_newton(wrapper_DIRK, solverData, (void*)userdata);

        //solverData->calculate_jacobian = -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(userdata->k + userdata->act_stage * nStates, fODE, nStates*sizeof(double));

  }

  return 0;
}

/*! \fn genericRK_MR_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'genericRK'
 */
int genericRK_MR_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double targetTime)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* genericRKData = (DATA_GENERIC_RK*)solverInfo->solverData;
  DATA_GENERIC_RK_MR* userdata = genericRKData->dataRKmr;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;

  double err, err_values[2], eventTime;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i, ii, l, nStates = data->modelData->nStates;
  int integrator_step_info;
  double outerStopTime = genericRKData->time + genericRKData->lastStepSize;
  // This is the target time of the main integrator
  targetTime = fmin(targetTime, outerStopTime);
  //  targetTime = genericRKData->time + genericRKData->lastStepSize;

  // BB ToDo: Use this to handel last step of the embedded integrator
  double stopTime = data->simulationInfo->stopTime;

  // BB ToDo: needs to be performed also after an event!!!
  if (solverInfo->didEventStep == 1 || userdata->stepsDone == 0)
  {
    userdata->time = genericRKData->time;
    userdata->stepSize = genericRKData->lastStepSize*0.5;
  }
  userdata->stepSize = fmin(userdata->stepSize, outerStopTime - userdata->time);
  memcpy(userdata->yOld, genericRKData->yOld, sizeof(double)*genericRKData->nStates);
  memcpy(userdata->y, genericRKData->y, sizeof(double)*genericRKData->nStates);
  userdata->startTime   = genericRKData->timeLeft;
  userdata->endTime     = genericRKData->timeRight;
  userdata->yStart      = genericRKData->yLeft;
  userdata->yEnd        = genericRKData->y;
  userdata->fastStates  = genericRKData->fastStates;
  userdata->slowStates  = genericRKData->slowStates;
  userdata->nFastStates = genericRKData->nFastStates;
  userdata->nSlowStates = genericRKData->nSlowStates;
  //printf("userdata->time: %g, userdata->stepSize: %g, targetTime: %g\n", userdata->time, userdata->stepSize, targetTime);

  infoStreamPrint(LOG_SOLVER, 1, "generic Runge-Kutta method (fast states):");
  //printIntVector_genericRK("fast states:", userdata->fastStates, userdata->nFastStates, userdata->time);
  while (userdata->time < targetTime)
  {
    do
    {
      if (userdata->stepsDone == 0)
        solverData->calculate_jacobian = 1;
    // calculate one step of the integrator
      integrator_step_info = userdata->step_fun(data, threadData, solverInfo);

      for (i=0; i<userdata->nFastStates; i++)
      {
        ii = userdata->fastStates[i];
        // y   is the new approximation
        // yt  is the approximation of the embedded method for error estimation
        userdata->y[ii]  = userdata->yOld[ii];
        userdata->yt[ii] = userdata->yOld[ii];
        for (l=0; l<userdata->tableau->nStages; l++)
        {
          userdata->y[ii]  += userdata->stepSize * userdata->tableau->b[l]  * (userdata->k + l * nStates)[ii];
          userdata->yt[ii] += userdata->stepSize * userdata->tableau->bt[l] * (userdata->k + l * nStates)[ii];
        }
        // calculate corresponding values for the error estimator and step size control
        userdata->errtol[ii] = Rtol*fmax(fabs(userdata->y[ii]),fabs(userdata->yt[ii])) + Atol;
        userdata->errest[ii] = fabs(userdata->y[ii] - userdata->yt[ii]);
      }

      /*** calculate error (infinity norm!)***/
      err = 0;
      for (i=0; i < userdata->nFastStates; i++)
      {
        ii = userdata->fastStates[i];
        userdata->err[ii] = userdata->errest[ii]/userdata->errtol[ii];
        err = fmax(err, userdata->err[ii]);
      }

      //Store error history for the different stepSize controller
      if (userdata->err_new == -1) userdata->err_new = err;
      userdata->err_old = userdata->err_new;
      userdata->err_new = err;

      err_values[0] = userdata->err_new;
      err_values[1] = userdata->err_old;

      // Store performed stepSize for adjusting the time and interpolation purposes
      userdata->lastStepSize = userdata->stepSize;

      // Call the step size control
      // Asynchronous step size allowed!!!
      userdata->stepSize *= userdata->stepSize_control(err_values, userdata->tableau->error_order);
      // printVector_genericRK("yt     (fast states)", userdata->yt, userdata->nStates, sData->timeValue);
      // printVector_genericRK("errest (fast states)", userdata->errest, userdata->nStates, sData->timeValue);
      // printVector_genericRK("errtol (fast states)", userdata->errtol, userdata->nStates, sData->timeValue);
      // printVector_genericRK("err    (fast states)", userdata->err, userdata->nStates, sData->timeValue);


      // Re-do step, if error is larger than requested
      if (err>1)
      {
        userdata->errorTestFailures++;
        infoStreamPrint(LOG_SOLVER, 0, "reject step from %10g to %10g, error %10g, new stepsize %10g",
                        userdata->time, userdata->time + userdata->lastStepSize, err, userdata->stepSize);
      } else {
        // Last step is limited by the simulation stopTime
        userdata->stepSize_old = userdata->stepSize;
        userdata->stepSize = fmin(userdata->stepSize, outerStopTime - (userdata->time + userdata->lastStepSize));
      }
      // printf("old: %10g, last: %10g, act: %10g\n", userdata->stepSize_old, userdata->lastStepSize, userdata->stepSize);
    } while  (err>1);

    // Count succesful integration steps
    userdata->stepsDone += 1;

    linear_interpolation_MR(userdata->startTime, userdata->yStart,
                            userdata->endTime,   userdata->yEnd,
                            userdata->time + userdata->lastStepSize, userdata->y, userdata->nSlowStates, userdata->slowStates);
    linear_interpolation_MR(userdata->startTime, userdata->yStart,
                            userdata->endTime,   userdata->yEnd,
                            userdata->time, userdata->yOld, userdata->nSlowStates, userdata->slowStates);
    eventTime = checkForEvents(data, threadData, solverInfo, userdata->time, userdata->yOld, userdata->time + userdata->lastStepSize, userdata->y);
    if (eventTime > 0)
    {
      linear_interpolation_MR(userdata->startTime, userdata->yStart,
                              userdata->endTime,   userdata->yEnd,
                              eventTime, userdata->y, userdata->nSlowStates, userdata->slowStates);
      linear_interpolation_MR(userdata->time, userdata->yOld,
                              userdata->time + userdata->lastStepSize, userdata->y,
                              eventTime, userdata->y, userdata->nFastStates, userdata->fastStates);

      userdata->lastStepSize = eventTime - userdata->time;
      userdata->time = eventTime;

      genericRKData->lastStepSize = eventTime - genericRKData->time;
      genericRKData->time = eventTime;
      solverInfo->currentTime = sData->timeValue;

      memcpy(genericRKData->y, userdata->y, userdata->nStates * sizeof(double));

      if(ACTIVE_STREAM(LOG_SOLVER))
      {
        // printIntVector_genericRK("fast states:", rk_data->fastStates, rk_data->nFastStates, solverInfo->currentTime);
        // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
        messageClose(LOG_SOLVER);
      }
      return 1;
    }
    /* update time with performed stepSize */
    userdata->time += userdata->lastStepSize;

    // printVector_genericRK_MR("yOld", userdata->yOld, userdata->nStates, userdata->time, userdata->nFastStates, userdata->fastStates);
    // printVector_genericRK_MR("y   ", userdata->y, userdata->nStates, userdata->time, userdata->nFastStates, userdata->fastStates);
    // printVector_genericRK("yOld", userdata->yOld, userdata->nStates, userdata->time - userdata->lastStepSize);
    // printVector_genericRK("y   ", userdata->y, userdata->nStates, userdata->time);
    /* step is accepted and yOld needs to be updated, store yOld for later interpolation... */
    copyVector_genericRK_MR(userdata->yt, userdata->yOld, userdata->nFastStates, userdata->fastStates);

    /* step is accepted and yOld needs to be updated */
    copyVector_genericRK_MR(userdata->yOld, userdata->y, userdata->nFastStates, userdata->fastStates);
    infoStreamPrint(LOG_SOLVER, 0, "accept step from %10g to %10g, error %10g, new stepsize %10g",
                    userdata->time- userdata->lastStepSize, userdata->time, err, userdata->stepSize);
  }

  userdata->stepSize = userdata->stepSize_old;
  // copy error of the fastStates to the outer integrator routine
  copyVector_genericRK_MR(genericRKData->err, userdata->err, userdata->nFastStates, userdata->fastStates);
  genericRKData->err_fast = err;
  copyVector_genericRK_MR(genericRKData->y, userdata->y, userdata->nFastStates, userdata->fastStates);
  copyVector_genericRK_MR(genericRKData->yOld, userdata->yOld, userdata->nFastStates, userdata->fastStates);

  // interpolate the values on the time grid of the outer integration
  // if (userdata->time >= genericRKData->time + genericRKData->lastStepSize) {
    // linear_interpolation_MR(userdata->time-userdata->lastStepSize, userdata->yt,
    //                         userdata->time, userdata->y,
    //                         genericRKData->time + genericRKData->lastStepSize, genericRKData->y,
    //                         userdata->nFastStates, userdata->fastStates);
  // }
  if (!solverInfo->integratorSteps)
  {
    /* Integrator does large steps and needs to interpolate results with respect to the output grid */
    linear_interpolation_MR(userdata->time-userdata->lastStepSize, userdata->yt,
                            userdata->time, userdata->y,
                            targetTime, sData->realVars,
                            userdata->nFastStates, userdata->fastStates);
    // printVector_genericRK("yOld: ", userdata->yt, data->modelData->nStates, userdata->time-userdata->lastStepSize);
    // printVector_genericRK("y:    ", userdata->y, data->modelData->nStates, userdata->time);
    // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
  }

  if(ACTIVE_STREAM(LOG_SOLVER_V))
  {
    infoStreamPrint(LOG_SOLVER_V, 1, "genericRKmr call statistics: ");
    infoStreamPrint(LOG_SOLVER_V, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER_V, 0, "current integration time value: %0.4g", userdata->time);
    infoStreamPrint(LOG_SOLVER_V, 0, "step size h to be attempted on next step: %0.4g", userdata->stepSize);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of steps taken so far: %d", userdata->stepsDone);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calls of functionODE() : %d", userdata->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER_V, 0, "number of calculation of jacobian : %d", userdata->evalJacobians);
    infoStreamPrint(LOG_SOLVER_V, 0, "error test failure : %d", userdata->errorTestFailures);
    infoStreamPrint(LOG_SOLVER_V, 0, "convergence failure : %d", userdata->convergenceFailures);
    messageClose(LOG_SOLVER_V);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = userdata->stepsDone;
  solverInfo->solverStatsTmp[1] = userdata->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = userdata->evalJacobians;
  solverInfo->solverStatsTmp[3] = userdata->errorTestFailures;
  solverInfo->solverStatsTmp[4] = userdata->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished genericRKmr step.");
  messageClose(LOG_SOLVER);

  return 0;
}

//Interpolation only some entries (indices given by idx[nIdx])
void linear_interpolation_MR(double ta, double* fa, double tb, double* fb, double t, double* f, int nIdx, int* idx)
{
  double lambda, h0, h1;
  int ii;

  lambda = (t-ta)/(tb-ta);
  h0 = 1-lambda;
  h1 = lambda;

  for (int i=0; i<nIdx; i++)
  {
    ii = idx[i];
    f[ii] = h0*fa[ii] + h1*fb[ii];
  }
}

void printVector_genericRK_MR(char name[], double* a, int n, double time, int nIndx, int* indx)
{
  printf("%s at time: %g: ", name, time);
  for (int i=0;i<nIndx;i++)
    printf("%6g ", a[indx[i]]);
  printf("\n");
}

void printMatrix_genericRK_MR(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n ", name, time);
  for (int i=0;i<n;i++)
  {
    for (int j=0;j<n;j++)
      printf("%6g ", a[i*n + j]);
    printf("\n");
  }
  printf("\n");
}