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
 * 0) Update comments for better readability, delete stuff no longer necessary
 * 1) Check pointer, especially, if there is no memory leak!
 * 2) Check necessary function evaluation and counting of it (use userdata->f, userdata->fOld)
 * 3) Use analytical Jacobian of the functionODE, if available
 *    Check calculation for a highly nonlinear test problem (VDP, etc.)
 * 4) Use sparsity pattern and kinsol solver
 * 5) Optimize evaluation of the Jacobian (e.g. in case it is constant)
 * 6) Introduce generic multirate-method, that might also be used for higher order
 *    ESDIRK and explicit RK methods
 * 7) Implement other ESDIRK methods
 * 8) configure userdata->fac with respect to the accuracy prediction
 * 9) ...
 *
*/

/*! \file genericRK.c
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

//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void printVector_genericRK(char name[], double* a, int n, double time);
void printMatrix_genericRK(char name[], double* a, int n, double time);

// singlerate step function
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

/**
 * @brief Get Runge-Kutta method from simulation flag FLAG_RK.
 *
 * Defaults to RK_DOPRI45 if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_SINGLERATE_METHOD    Runge-Kutta method.
 */
enum RK_SINGLERATE_METHOD getRK_Method() {
  enum RK_SINGLERATE_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK];
  char* RK_method_string;

  if (flag_value != NULL) {
    RK_method_string = GC_strdup(flag_value);
    for (method=RK_UNKNOWN; method<RK_MAX; method++) {
      if (strcmp(RK_method_string, RK_SINGLERATE_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: %s", RK_SINGLERATE_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow Runge-Kutta method %s.", RK_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK method: %s [from command line]", RK_method_string);
    return RK_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: dopri45 [default]");
    return RK_DOPRI45;
  }
}

/**
 * @brief Get non-linear solver method for Runge-Kutta from flag FLAG_RK_NLS.
 *
 * Defaults to Newton if flag is not set.
 * Returns RK_UNKNOWN if flag is not known.
 *
 * @return enum RK_NLS_METHOD   NLS method.
 */
enum RK_NLS_METHOD getRK_NLS_Method() {
  enum RK_NLS_METHOD method;
  const char* flag_value;
  flag_value = omc_flagValue[FLAG_RK_NLS];
  char* RK_NLS_method_string;

  if (flag_value != NULL) {
    RK_NLS_method_string = GC_strdup(flag_value);
    for (method=RK_NLS_UNKNOWN; method<RK_NLS_MAX; method++) {
      if (strcmp(RK_NLS_method_string, RK_NLS_METHOD_NAME[method]) == 0){
        infoStreamPrint(LOG_SOLVER, 0, "Chosen RK NLS method: %s", RK_NLS_METHOD_NAME[method]);
        return method;
      }
    }
    errorStreamPrint(LOG_STDOUT, 0, "Error: Unknow non-linear solver method %s for Runge-Kutta method.", RK_NLS_method_string);
    errorStreamPrint(LOG_STDOUT, 0, "Choose RK NLS method: %s [from command line]", RK_NLS_method_string);
    return RK_NLS_UNKNOWN;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "Chosen RK method: omc_newton [default]");
    return RK_NLS_NEWTON;
  }
}

/**
 * @brief Function allocates memory needed for ESDIRK method.
 *
 * @param data          Runtime data struct.
 * @param threadData    Thread data for error handling.
 * @param solverInfo    Information about main solver.
 * @return int          Return 0 on success, -1 on failure.
 */
int allocateDataGenericRK(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*) malloc(sizeof(DATA_GENERIC_RK));
  solverInfo->solverData = (void*) userdata;

  userdata->nStates = data->modelData->nStates;

  ANALYTIC_JACOBIAN* jacobian = NULL;
  analyticalJacobianColumn_func_ptr analyticalJacobianColumn = NULL;

  userdata->RK_method = getRK_Method();
  userdata->tableau = initButcherTableau(userdata->RK_method);
  if (userdata->tableau == NULL){
    // ERROR
    return -1;
  }

  // Check explicit, diagonally implicit or fully implicit status and fix solver settings
  enum RK_type expl;
  analyseButcherTableau(userdata->tableau, userdata->nStates, &userdata->nlSystemSize, &expl);

  switch (expl)
  {
  case RK_TYPE_EXPLICIT:
    userdata->isExplicit = TRUE;
    userdata->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_DIRK:
    userdata->isExplicit = FALSE;
    userdata->step_fun = &(expl_diag_impl_RK);
    break;
  case RK_TYPE_IMPLICIT:
    userdata->isExplicit = FALSE;
    userdata->step_fun = &(full_implicit_RK);
    break;
  default:
    // Error
    break;
  }

  infoStreamPrint(LOG_STATS, 0, "Step control factor is set to %g", userdata->tableau->fac);


  // adapt decision for testing of the fully implicit implementation
  if (userdata->RK_method == RK_ESDIRK2_test || userdata->RK_method == RK_ESDIRK3_test) {
    userdata->nlSystemSize = userdata->tableau->stages*userdata->nStates;
    userdata->step_fun = &(full_implicit_RK);
  }

  // allocate memory for te generic RK method
  userdata->firstStep = 1;
  userdata->y = malloc(sizeof(double)*userdata->nStates);
  userdata->yOld = malloc(sizeof(double)*userdata->nStates);
  userdata->yt = malloc(sizeof(double)*userdata->nStates);
  userdata->f = malloc(sizeof(double)*userdata->nStates);
  userdata->Jf = malloc(sizeof(double)*userdata->nStates*userdata->nStates);
  userdata->k = malloc(sizeof(double)*userdata->nStates*userdata->tableau->stages);
  userdata->res_const = malloc(sizeof(double)*userdata->nStates);
  userdata->errest = malloc(sizeof(double)*userdata->nStates);
  userdata->errtol = malloc(sizeof(double)*userdata->nStates);

  printButcherTableau(userdata->tableau);

  /* initialize statistic counter */
  // TODO AHeu: Use calloc instead?
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;
  userdata->errorTestFailures = 0;
  userdata->convergenceFailures = 0;

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

  /* Allocate memory for the nonlinear solver */
  // TODO AHeu: Do we always need a NLS solver or only for implicit RK methods?
  userdata->nlsSolverMethod = getRK_NLS_Method();
  switch (userdata->nlsSolverMethod) {
  case RK_NLS_NEWTON:
    userdata->nlsSolverData = (void*) allocateNewtonData(userdata->nlSystemSize);
    break;
  case RK_NLS_KINSOL:
    userdata->nlsSolverData = (void*) nlsKinsolAllocate(userdata->nlSystemSize, NLS_LS_KLU);
    if (userdata->symJacAvailable) {
      resetKinsolMemory(userdata->nlsSolverData, jacobian->sparsePattern->numberOfNonZeros, data->callback->functionJacA_column);
    } else {
      resetKinsolMemory(userdata->nlsSolverData, userdata->nlSystemSize*userdata->nlSystemSize, NULL);
    }
    break;
  default:
    errorStreamPrint(LOG_STDOUT, 0, "Memory allocation for NLS method %s not yet implemented.", RK_NLS_METHOD_NAME[userdata->RK_method]);
    return -1;
    break;
  }

  return 0;
}

/**
 * @brief Free generic RK data.
 *
 * @param data    Pointer to generik Runge-Kutta data struct.
 */
void freeDataGenericRK(DATA_GENERIC_RK* data) {
  switch (data->nlsSolverMethod)
  {
  case RK_NLS_NEWTON:
    freeNewtonData(data->nlsSolverData);
    break;
  case RK_NLS_KINSOL:
    nlsKinsolFree(data->nlsSolverData);
    break;
  default:
    warningStreamPrint(LOG_SOLVER, 0, "Not handled RK_NLS_METHOD in freeDataGenericRK. Are we leaking memroy?");
    break;
  }

  freeButcherTableau(data->tableau);

  free(data->y);
  free(data->yOld);
  free(data->yt);
  free(data->f);
  free(data->Jf);
  free(data->k);
  free(data->res_const);
  free(data->errest);
  free(data->errtol);

  free(data);
  data = NULL;

  return;
}

/*!	\fn wrapper_f_genericRK
 *
 *  calculate function values of function ODE f(t,y)
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      data           data of the underlying DAE
 *  \param [in]      threadData     data for error handling
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK)
 *  \param [out]     fODE       pointer to state derivatives
 *
 */
int wrapper_f_genericRK(DATA* data, threadData_t *threadData, void* genericRKData, modelica_real* fODE)
{
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*) genericRKData;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  fODE = sData->realVars + data->modelData->nStates;

  userdata->evalFunctionODE++;

  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  data->callback->functionODE(data, threadData);

  return 0;
}

/*
 * Sets element (i,j) in matrixA to given value val.
 */
void setJacElementESDIRKSparse(int i, int j, int nth, double val, void* Jf,
                              int rows)
{
  int l  = j*rows + i;
  ((double*) Jf)[l]=val;
}

/*!	\fn wrapper_Jf_genericRK
 *
 *  calculate the Jacobian of functionODE with respect to the states
 *  IMPORTANT: assuming the correct values of the time value and the states are set
 *  \param [in]      n              pointer to number of states
 *  \param [in]      x              pointer to state vector
 *  \param [in]      fvec           pointer to corresponding fODE-values usually
 *                                  stored in userdata->f (verify before calling)
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK)
 *  \param [out]     fODE           pointer to state derivatives
 *
 *  result of the Jacobian is stored in solverData->fjac (DATA_NEWTON) ???????
 *
 */
int wrapper_Jf_genericRK(int n, double t, double* x, double* fODE, void* genericRKData)
{
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*) genericRKData;

  DATA* data = userdata->data;
  threadData_t* threadData = userdata->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh;
  double xsave;

  int i,j,l;

  /* profiling */
  rt_tick(SIM_TIMER_JACOBIAN);

  if (solverData->calculate_jacobian>=0)
  {
    userdata->evalJacobians++;

    if (userdata->symJacAvailable)
    {
      const int index = data->callback->INDEX_JAC_A;
      ANALYTIC_JACOBIAN* jac = &(data->simulationInfo->analyticJacobians[index]);

#ifdef USE_PARJAC
      //ANALYTIC_JACOBIAN* t_jac = (dasslData->jacColumns);
      ANALYTIC_JACOBIAN* t_jac = jac;
#else
      ANALYTIC_JACOBIAN* t_jac = jac;
#endif

      unsigned int columns = jac->sizeCols;
      unsigned int rows = jac->sizeRows;
      unsigned int sizeTmpVars = jac->sizeTmpVars;
      SPARSE_PATTERN* spp = jac->sparsePattern;

       /* Evaluate constant equations if available */
       // BB: Do I need this?
       if (jac->constantEqns != NULL) {
         jac->constantEqns(data, threadData, jac, NULL);
       }
       genericColoredSymbolicJacobianEvaluation(rows, columns, spp, userdata->Jf, t_jac,
                                           data, threadData, &setJacElementESDIRKSparse);
    }
    else
    {
      memcpy(userdata->f, fODE, n * sizeof(double));
      for(i = 0; i < n; i++)
      {
        delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(userdata->f[i])), delta_h);
        delta_hh = ((userdata->f[i] >= 0) ? delta_hh : -delta_hh);
        delta_hh = x[i] + delta_hh - x[i];
        xsave = x[i];
        x[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        wrapper_f_genericRK(data, threadData, userdata, fODE);
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
    // Has to be refactured for general RK method
    if (solverData->calculate_jacobian==0)
      solverData->calculate_jacobian = 1;
  }

  /* profiling */
  rt_accumulate(SIM_TIMER_JACOBIAN);
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
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_DIRK(int* n_p, double* x, double* res, void* genericRKData, int fj)
{
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*) genericRKData;

  DATA* data = userdata->data;
  threadData_t* threadData = userdata->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = (*n_p);

  int i, j, l, k;

  // index of diagonal element of A
  k = userdata->act_stage * userdata->tableau->stages + userdata->act_stage;
  if (fj)
  {
    // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
    // set correct time value and states of simulation system
    sData->timeValue = userdata->time + userdata->tableau->c[userdata->act_stage]*userdata->stepSize;
    memcpy(sData->realVars, x, n*sizeof(double));
    wrapper_f_genericRK(data, threadData, userdata, fODE);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    for (j=0; j<n; j++)
    {
      res[j] = userdata->res_const[j] - x[j] + userdata->stepSize * userdata->tableau->A[k]  * fODE[j];
    }
  }
  else
  {
    if (solverData->calculate_jacobian>=0)
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
    wrapper_Jf_genericRK(n, sData->timeValue, sData->realVars, fODE, userdata);

    // residual function res = yOld-x+gam*h*(k1+f(tk+c2*h,x))
    // jacobian          Jac = -E + gam*h*Jf(tk+c2*h,x))
    for(i = 0; i < n; i++)
    {
      for(j = 0; j < n; j++)
      {
        l = i * n + j;
        solverData->fjac[l] = userdata->stepSize * userdata->tableau->A[k] * userdata->Jf[l];
        if (i==j) solverData->fjac[l] -= 1;
      }
    }
    solverData->calculate_jacobian=-1;
    }
  }
  return 0;
}

/*!	\fn wrapper_RK_genericRK
 *      residual function res = yOld-y+h*(b1*k1+b2*k2+b3*f(tk+h,y));
 *      i.e. solve for:
 *           y2g = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g)) = yOld+h*(b1*k1+b2*k2+b3*f(tOld+h,y2g))
 *      <=>  k3  = f(tOld+h,yOld+h*(b1*k1+b2*k2+b3*k3))
 *
 *  calculate function values or jacobian matrix for Newton-solver
 *  \param [in]      n_p            pointer to number of states
 *  \param [in]      x              pointer to unknowns (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  res            pointer to residual function (BB: storage in DATA_NEWTON?)
 *  \param [in/out]  userdata       data of the integrator (DATA_GENERIC_RK)
 *  \param [in]      fj             fj = 1 ==> calculate function values
 *                                  fj = 0 ==> calculate jacobian matrix
 */
int wrapper_RK(int* n_p, double* x, double* res, void* genericRKData, int fj)
{
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*) genericRKData;

  DATA* data = userdata->data;
  threadData_t* threadData = userdata->threadData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  int n = data->modelData->nStates;

  int i, j, k, l, ind, stages = userdata->tableau->stages;
  double sum;

  if (fj)
  {
    // k[i] = f(tOld + c[i]*h,x); x ~ yOld + h*(a[i][1]*k[1]+...+a[i][stages]*k[stages])
    // set correct time value and states of simulation system
    // residual function res = yOld-x[i]+h*(a[l][1]*k[1]+...+a[l][stages]*k[stages])
    // residual function res = yOld-x[i]+h*(a[l][1]*f(t[1],x[1])+...+a[l][stages]*f(t[stages],x[stages]))
    //printVector_genericRK("x ", x, stages * n, sData->timeValue);
    for (l=0; l<stages; l++)
    {
      for (i=0; i<n; i++)
      {
        res[l * n + i] = userdata->yOld[i] - x[l * n + i];
      }
    }
    for (k=0; k<stages; k++)
    {
      // calculate f[k] and sweap over the stages
      //printf("c[k] = %g\n",userdata->c[k]);
      sData->timeValue = userdata->time + userdata->tableau->c[k] * userdata->stepSize;
      memcpy(sData->realVars, (x + k * n), n*sizeof(double));
      wrapper_f_genericRK(data, threadData, userdata, fODE);
      memcpy(userdata->k + k * n, fODE, n*sizeof(double));
      for (l=0; l<stages; l++)
      {
        //printf("A[%d,%d] = %g  ",l,k,userdata->A[l * stages + k]);
        for (i=0; i<n; i++)
        {
          res[l * n + i] += userdata->stepSize * userdata->tableau->A[l * stages + k] * fODE[i];
        }
      }
      //printf("\n");
    }
    //printVector_genericRK("res ", res, stages * n, sData->timeValue);
  }
  else
  {
    if (solverData->calculate_jacobian>=0)
    {
    /*!
     *  fODE = f(tOld + h,x); x ~ yOld + h*(b1*k1+b2*k2+b3*k3)
     *  set correct time value and states of simulation system
     *  this should not count on function evaluation, since
     *  it belongs to the jacobian evaluation
     *  \ToBeChecked: This calculation maybe not be necessary since f has already
     *                just evaluated! works so far
     */
    // sData->timeValue = userdata->time + userdata->stepSize;
    // memcpy(sData->realVars, x, n*sizeof(double));
    // wrapper_f_genericRK(data, threadData, userdata, fODE);
    // userdata->evalFunctionODE--;

    /* store values for finite differences scheme
     * not necessary for analytic Jacobian */
    //memcpy(userdata->f, fODE, n*sizeof(double));

    /* Calculate Jacobian of the ODE system, stored in  solverData->fjac */
    //wrapper_Jf_genericRK(&n, x, userdata->f, userdata, fODE);
    // set correct time value and states of simulation system

    // residual function res = yOld-x[i]+h*(a[l][1]*k[1]+...+a[l][stages]*k[stages])
    // residual function res = yOld-x[i]+h*(a[l][1]*f(t[1],x[1])+...+a[l][stages]*f(t[stages],x[stages]))
    // jacobian          Jac = -E + h*(a[l][1]*Jf(t[1],x[1])+...+a[l][stages]*Jf(t[stages],x[stages]))
    for (i=0; i < stages * n; i++)
    {
      for (j=0; j < stages * n; j++)
      {
        if (i==j)
          solverData->fjac[i * stages*n + j] = -1;
        else
          solverData->fjac[i * stages*n + j] = 0;
      }
    }
    //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, userdata->time);
    for (k=0; k<stages && !userdata->isExplicit; k++)
    {
      // calculate Jf[k] and sweap over the stages
      sData->timeValue = userdata->time + userdata->tableau->c[k] * userdata->stepSize;
      memcpy(sData->realVars, (x + k * n), n*sizeof(double));
      // works only for analytical Jacobian!!!
      //printf("Hier: %d\n", k);
      // BB: needs to be verified, that for the numerical Jacobian fODE is actual!!
      wrapper_Jf_genericRK(n, sData->timeValue, sData->realVars, fODE, userdata);
      //printMatrix_genericRK("Jacobian of system", userdata->Jf, n, sData->timeValue);
      //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, sData->timeValue);
      for (l=0; l<stages; l++)
      {
        for (i=0; i<n; i++)
        {
          for (j=0; j<n; j++)
          {
            ind = l * stages * n * n + i * stages * n + j + k*n;
            solverData->fjac[ind] += userdata->stepSize * userdata->tableau->A[l * stages + k] * userdata->Jf[i * n + j];
            //solverData->fjac[ind] += userdata->Jf[i * n + j];
            //printf("Hier2: l=%d i=%d j=%d\n", l,i,j);
            //printMatrix_genericRK("Jacobian of solver", solverData->fjac, stages * n, ind);
          }
        }
      }
    }
    solverData->calculate_jacobian=-1;
    }
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
int expl_diag_impl_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, l, k, n=data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->nlsSolverData;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  solverData->initialized = 1;
  solverData->numberOfIterations = 0;
  solverData->numberOfFunctionEvaluations = 0;
  solverData->n = n;

  // setting the start vector for the newton step
  memcpy(solverData->x, userdata->yOld, n*sizeof(double));

  // sweep over the stages
  for (userdata->act_stage = 0; userdata->act_stage < userdata->tableau->stages; userdata->act_stage++)
  {
    // k[i] = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i))
    // residual constant part:
    // res = f(tOld + c[i]*h, yOld + h*sum(a[i,j]*k[j], i=j..i-i))
    k = userdata->act_stage * userdata->tableau->stages;
    for (j=0; j<n; j++)
    {
      userdata->res_const[j] = userdata->yOld[j];
      for (l=0; l<userdata->act_stage; l++)
        userdata->res_const[j] += userdata->stepSize * userdata->tableau->A[k + l] * (userdata->k + l * n)[j];
    }

    // index of diagonal element of A
    k = userdata->act_stage * userdata->tableau->stages + userdata->act_stage;
    if (userdata->tableau->A[k] == 0)
    {
      // fODE = f(tOld + c2*h,x); x ~ yOld + gam*h*(k1+k2)
      // set correct time value and states of simulation system
      sData->timeValue = userdata->time + userdata->tableau->c[userdata->act_stage]*userdata->stepSize;
      memcpy(sData->realVars, userdata->res_const, n*sizeof(double));
      wrapper_f_genericRK(data, threadData, userdata, fODE);
    }
    else
    {
      // solve for x: 0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
      // set good starting values for the newton solver (solution of the last newton iteration!)
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

        solverData->calculate_jacobian = -1;
      }
    }
    // copy last calculation of fODE, which should coincide with k[i]
    memcpy(userdata->k + userdata->act_stage * n, fODE, n*sizeof(double));

  }

  return 0;
}

/*!	\fn full_implicit_RK
 *
 *  function does one implicit ESDIRK2 step with the stepSize given in stepSize
 *  function omc_newton is used for solving nonlinear system
 *  results will be saved in y and the embedded result in yt
 *
 */
int full_implicit_RK(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  int i, j, k, l, n=data->modelData->nStates;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;

  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*) userdata->nlsSolverData;

  userdata->data = (void*) data;
  userdata->threadData = threadData;

  sData->timeValue = userdata->time;
  solverInfo->currentTime = sData->timeValue;

  solverData->initialized = 1;
  solverData->numberOfIterations = 0;
  solverData->numberOfFunctionEvaluations = 0;
  solverData->n = userdata->tableau->stages*n;

  // set good starting values for the newton solver
  for (k=0; k<userdata->tableau->stages; k++)
    memcpy((solverData->x + k*n), userdata->yOld, n*sizeof(double));
  // set newton strategy
  solverData->newtonStrategy = NEWTON_DAMPED2;
  _omc_newton(wrapper_RK, solverData, (void*)userdata);

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
    _omc_newton(wrapper_RK, solverData, (void*)userdata);

    solverData->calculate_jacobian = -1;
  }

  return 0;
}

/*! \fn genericRK_first_step
 *
 *  function initializes values and calculates
 *  initial step size at the beginning or after an event
 *  BB: ToDo: lookup the reference in Hairers book
 *
 */
void genericRK_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*)solverInfo->solverData;
  const int n = data->modelData->nStates;
  modelica_real* fODE = sData->realVars + data->modelData->nStates;

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = 1e-6, Rtol = 1e-3;

  int i,j;

  /* store Startime of the simulation */
  userdata->time = sDataOld->timeValue;

  /* set correct flags in order to calculate initial step size */
  userdata->firstStep = 0;
  solverInfo->didEventStep = 0;

 /* reset statistics because it is accumulated in solver_main.c */
  userdata->stepsDone = 0;
  userdata->evalFunctionODE = 0;
  userdata->evalJacobians = 0;
  userdata->errorTestFailures = 0;
  userdata->convergenceFailures = 0;

  /* calculate starting step size 1st Version */
  /* BB: What is the difference between sData and sDataOld at this time instance?
         Is this important for the restart after an event?
         And should this also been copied to userdata->old (see above?)
  */
  /* initialize start values of the integrator and calculate ODE function*/
  //printVector_genericRK("sData->realVars: ", sData->realVars, data->modelData->nStates, sData->timeValue);
  //printVector_genericRK("sDataOld->realVars: ", sDataOld->realVars, data->modelData->nStates, sDataOld->timeValue);
  memcpy(userdata->yOld, sData->realVars, data->modelData->nStates*sizeof(double));
  wrapper_f_genericRK(data, threadData, userdata, fODE);
  /* store values of the state derivatives at initial or event time */
  memcpy(userdata->f, fODE, data->modelData->nStates*sizeof(double));

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((fODE[i] * fODE[i]) / (sc*sc));
  }
  d0 /= data->modelData->nStates;
  d1 /= data->modelData->nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);

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
    sData->realVars[i] = userdata->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  wrapper_f_genericRK(data, threadData, userdata, fODE);

  for (i=0; i<data->modelData->nStates; i++)
  {
    sc = Atol + fabs(userdata->yOld[i])*Rtol;
    d2 += ((fODE[i]-userdata->f[i])*(fODE[i]-userdata->f[i])/(sc*sc));
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

  infoStreamPrint(LOG_SOLVER, 0, "initial step size = %e at time %g", userdata->stepSize, userdata->time);
}

/*! \fn esdirkmr_step
 *
 *  function does one integration step and calculates
 *  next step size by the implicit midpoint rule
 *
 *  used for solver 'genericRK'
 */
int genericRK_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1]; // BB: Is this the ring buffer???
  modelica_real* fODE = sData->realVars + data->modelData->nStates;
  DATA_GENERIC_RK* userdata = (DATA_GENERIC_RK*)solverInfo->solverData;
  DATA_NEWTON* solverData = (DATA_NEWTON*)userdata->nlsSolverData;

  double err;
  double Atol = data->simulationInfo->tolerance, Rtol = data->simulationInfo->tolerance;
  int i, l, n=data->modelData->nStates;
  int esdirk_imp_step_info;
  // find appropriate value using the TestAnalytic.mo example
  //double fac = 0.9;
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
    genericRK_first_step(data, threadData, solverInfo);
    // side effect:
    //    sData->realVars, userdata->yOld, and userdata->f are consistent
    //    userdata->time and userdata->stepSize are defined
  }

  while (userdata->time < targetTime)
  {
    do
    {
      /* calculate jacobian:
       *    once for the first iteration after initial or an event
       *    solverData->calculate_jacobian = 0
       *    always
       *    solverData->calculate_jacobian = 1
       *
       * BB: How does this actually works in combination with the Newton method?
       */
      if (userdata->stepsDone == 0)
        solverData->calculate_jacobian = 0;

      // calculate one step of the integrator
      esdirk_imp_step_info = userdata->step_fun(data, threadData, solverInfo);

      // printVector_genericRK("y ", userdata->y, data->modelData->nStates, userdata->time);
      // printVector_genericRK("yt ", userdata->yt, data->modelData->nStates, userdata->time);
      // y       = yold+h*sum(b[i]*k[i], i=1..stages);
      // yt      = yold+h*sum(bt[i]*k[i], i=1..stages);
      // calculate corresponding values for error estimator and step size control
      for (i=0; i<n; i++)
      {
        userdata->y[i]  = userdata->yOld[i];
        userdata->yt[i] = userdata->yOld[i];
        for (l=0; l<userdata->tableau->stages; l++)
        {
          userdata->y[i]  += userdata->stepSize * userdata->tableau->b[l]  * (userdata->k + l * n)[i];
          userdata->yt[i] += userdata->stepSize * userdata->tableau->bt[l] * (userdata->k + l * n)[i];
        }
        //userdata->errtol[i] = Rtol*fabs(userdata->yOld[i]) + Atol;
        userdata->errtol[i] = Rtol*fmax(fabs(userdata->y[i]),fabs(userdata->yt[i])) + Atol;
        userdata->errest[i] = fabs(userdata->y[i] - userdata->yt[i]);
      }

      //printVector_genericRK("y ", userdata->y, n, userdata->time);
      //printVector_genericRK("yt ", userdata->yt, n, userdata->time);



      /*** calculate error (infinity norm!)***/
      // norm_errtol = 0;
      // norm_errest = 0;
      // for (i=0; i<data->modelData->nStates; i++)
      // {
      //    norm_errtol = fmax(norm_errtol, userdata->errtol[i]);
      //    norm_errest = fmax(norm_errest, userdata->errest[i]);
      // }
      // err = norm_errest/norm_errtol;
      /*** calculate error (euclidian norm) ***/
      for (i=0, err=0.0; i<n; i++)
      {
        err += (userdata->errest[i]*userdata->errest[i])/(userdata->errtol[i]*userdata->errtol[i]);
      }

      err /= n;
      err = sqrt(err);

      // Store performed stepSize for adjusting the time and interpolation purposes
      userdata->lastStepSize = userdata->stepSize;
      userdata->stepSize *= fmin(facmax, fmax(facmin, userdata->tableau->fac*pow(1.0/err, 1./userdata->tableau->error_order)));
      /*
       * step size control from Luca, etc.:
       * stepSize = seccoeff*sqrt(norm_errtol/fmax(norm_errest,errmin));
       * printf("Error:  %g, New stepSize: %g from %g to  %g\n", err, userdata->stepSize, userdata->time, userdata->time+stepSize);
       */
      if (err>1)
      {
        userdata->errorTestFailures++;
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
    // printVector_genericRK("yOld: ", userdata->yt, data->modelData->nStates, userdata->time-userdata->lastStepSize);
    // printVector_genericRK("y:    ", userdata->y, data->modelData->nStates, userdata->time);
    // printVector_genericRK("y_int:", sData->realVars, data->modelData->nStates, solverInfo->currentTime);
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
    infoStreamPrint(LOG_SOLVER, 1, "genericRK call statistics: ");
    infoStreamPrint(LOG_SOLVER, 0, "current time value: %0.4g", solverInfo->currentTime);
    infoStreamPrint(LOG_SOLVER, 0, "current integration time value: %0.4g", userdata->time);
    infoStreamPrint(LOG_SOLVER, 0, "step size h to be attempted on next step: %0.4g", userdata->stepSize);
    infoStreamPrint(LOG_SOLVER, 0, "number of steps taken so far: %d", userdata->stepsDone);
    infoStreamPrint(LOG_SOLVER, 0, "number of calls of functionODE() : %d", userdata->evalFunctionODE);
    infoStreamPrint(LOG_SOLVER, 0, "number of calculation of jacobian : %d", userdata->evalJacobians);
    infoStreamPrint(LOG_SOLVER, 0, "error test failure : %d", userdata->errorTestFailures);
    infoStreamPrint(LOG_SOLVER, 0, "convergence failure : %d", userdata->convergenceFailures);
    messageClose(LOG_SOLVER);
  }

  /* write statistics to the solverInfo data structure */
  solverInfo->solverStatsTmp[0] = userdata->stepsDone;
  solverInfo->solverStatsTmp[1] = userdata->evalFunctionODE;
  solverInfo->solverStatsTmp[2] = userdata->evalJacobians;
  solverInfo->solverStatsTmp[3] = userdata->errorTestFailures;
  solverInfo->solverStatsTmp[4] = userdata->convergenceFailures;

  infoStreamPrint(LOG_SOLVER, 0, "Finished genericRK step.");

  return 0;
}


// TODO AHeu: For sure ther is already a linear interpolation function somewhere
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

void printVector_genericRK(char name[], double* a, int n, double time)
{
  printf("\n%s at time: %g: \n", name, time);
  for (int i=0;i<n;i++)
    printf("%6g ", a[i]);
  printf("\n");
}

void printMatrix_genericRK(char name[], double* a, int n, double time)
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

