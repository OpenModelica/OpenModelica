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

/*! \file nonlinear_solver.c
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "../simulation_info_json.h"
#include "../../util/omc_error.h"
#include "../../util/varinfo.h"
#include "model_help.h"
#include "../../gc/omc_gc.h"
#include "../../meta/meta_modelica.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverHybrd.h"

extern double enorm_(integer *n, double *x);

static void wrapper_fvec_hybrj(const integer *n_p, const double* x, double* f, double* fjac, const integer* ldjac, const integer* iflag, void* userData);

/**
 * @brief Allocate memory for non-linear hybrid solver.
 *
 * @param size            Size of non-linear system.
 * @return DATA_HYBRD*    Pointer to allocated hybrid data.
 */
DATA_HYBRD* allocateHybrdData(size_t size, NLS_USERDATA* userData)
{
  DATA_HYBRD* hybrdData = (DATA_HYBRD*) malloc(sizeof(DATA_HYBRD));
  assertStreamPrint(NULL, hybrdData != NULL, "allocationHybrdData() failed!");

  hybrdData->initialized = FALSE;
  hybrdData->resScaling = (double*) malloc(size*sizeof(double));
  hybrdData->fvecScaled = (double*) malloc(size*sizeof(double));
  hybrdData->useXScaling = 1;
  hybrdData->xScalefactors = (double*) malloc(size*sizeof(double));

  hybrdData->n = size;
  hybrdData->x = (double*) malloc((size+1)*sizeof(double));
  hybrdData->xSave = (double*) malloc((size+1)*sizeof(double));
  hybrdData->xScaled = (double*) malloc((size+1)*sizeof(double));
  hybrdData->fvec = (double*) calloc(size, sizeof(double));
  hybrdData->fvecSave = (double*) calloc(size, sizeof(double));
  hybrdData->xtol = 1e-12;
  hybrdData->maxfev = size*10000;
  hybrdData->ml = size - 1;
  hybrdData->mu = size - 1;
  hybrdData->epsfcn = 1e-12;
  hybrdData->diag = (double*) malloc(size*sizeof(double));
  hybrdData->diagres = (double*) malloc(size*sizeof(double));
  hybrdData->mode = 1;
  hybrdData->factor = 100.0;
  hybrdData->nprint = -1;
  hybrdData->info = 0;
  hybrdData->nfev = 0;
  hybrdData->njev = 0;
  hybrdData->fjac = (double*) calloc((size*(size+1)), sizeof(double));
  hybrdData->fjacobian = (double*) calloc((size*(size+1)), sizeof(double));
  hybrdData->ldfjac = size;
  hybrdData->r__ = (double*) malloc(((size*(size+1))/2)*sizeof(double));
  hybrdData->lr = (size*(size + 1)) / 2;
  hybrdData->qtf = (double*) malloc(size*sizeof(double));
  hybrdData->wa1 = (double*) malloc(size*sizeof(double));
  hybrdData->wa2 = (double*) malloc(size*sizeof(double));
  hybrdData->wa3 = (double*) malloc(size*sizeof(double));
  hybrdData->wa4 = (double*) malloc(size*sizeof(double));

  hybrdData->numberOfIterations = 0;
  hybrdData->numberOfFunctionEvaluations = 0;

  hybrdData->userData = userData;

  return hybrdData;
}

/**
 * @brief Free hybrid solver data.
 *
 * @param hybrdData   Pointer to hybrid data.
 */
void freeHybrdData(DATA_HYBRD* hybrdData)
{
  free(hybrdData->resScaling);
  free(hybrdData->fvecScaled);
  free(hybrdData->xScalefactors);
  free(hybrdData->x);
  free(hybrdData->xSave);
  free(hybrdData->xScaled);
  free(hybrdData->fvec);
  free(hybrdData->fvecSave);
  free(hybrdData->diag);
  free(hybrdData->diagres);
  free(hybrdData->fjac);
  free(hybrdData->fjacobian);
  free(hybrdData->r__);
  free(hybrdData->qtf);
  free(hybrdData->wa1);
  free(hybrdData->wa2);
  free(hybrdData->wa3);
  free(hybrdData->wa4);

  freeNlsUserData(hybrdData->userData);

  free(hybrdData);
  return;
}

/*! \fn printVector
 *
 *  \param [in]  [vector]
 *  \param [in]  [size]
 *  \param [in]  [logLevel]
 *  \param [in]  [name]
 *
 *  \author wbraun
 */
static void printVector(const double *vector, const integer size, const int logLevel, const char *name)
{
  int i;
  if (!OMC_ACTIVE_STREAM(logLevel)) return;
  infoStreamPrint(logLevel, 1, "%s", name);
  for(i=0; i<size; i++)
    infoStreamPrint(logLevel, 0, "[%2d] %20.12g", i, vector[i]);
  messageClose(logLevel);
}

/*! \fn printStatus
 *
 *  \param [in]  [solverData]
 *  \param [in]  [nfunc_evals]
 *  \param [in]  [xerror]
 *  \param [in]  [xerror_scaled]
 *  \param [in]  [logLevel]
 *
 *  \author wbraun
 */
static void printStatus(DATA *data, DATA_HYBRD *solverData, int eqSystemNumber, const int *nfunc_evals, const double *xerror, const double *xerror_scaled, const int logLevel)
{
  long i;

  if (!OMC_ACTIVE_STREAM(logLevel)) return;
  infoStreamPrint(logLevel, 1, "nls status");

  infoStreamPrint(logLevel, 1, "variables");
  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logLevel, 0, "[%ld] %s  = %.20e\n - scaling factor internal = %.16e\n"
                    " - scaling factor external = %.16e", i+1,
                    modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],
                    solverData->x[i], solverData->diag[i], solverData->xScalefactors[i]);
  messageClose(logLevel);

  infoStreamPrint(logLevel, 1, "functions");
  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logLevel, 0, "res[%ld] = %.20e [scaling factor = %.16e]", i+1, solverData->fvec[i], solverData->resScaling[i]);
  messageClose(logLevel);

  infoStreamPrint(logLevel, 1, "statistics");
  infoStreamPrint(logLevel, 0, "nfunc = %d\nerror = %.20e\nerror_scaled = %.20e", *nfunc_evals, *xerror, *xerror_scaled);
  messageClose(logLevel);

  messageClose(logLevel);

}

/**
 * @brief Calculate numeric Jacobian matrix J(x).
 *
 * Using finite differences method.
 *
 * @param hybrdUserData   Pointer to hybrid solver user data.
 * @param jac             Contains values of Jacobian J(x) on exit.
 * @param x               Vector x.
 * @param f               Residual values f(x).
 * @return int            Return 0 on success.
 */
static int getNumericalJacobian(NLS_USERDATA* hybrdUserData, double* jac, const double* x, double* f)
{
  NONLINEAR_SYSTEM_DATA* systemData = hybrdUserData->nlsData;
  DATA_HYBRD* solverData = (DATA_HYBRD*) systemData->solverData;

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh, delta_hhh, deltaInv;
  integer iflag = 1;
  int i, j, l;

  memcpy(solverData->xSave, x, solverData->n*sizeof(double));

  for(i = 0; i < solverData->n ; ++i)
  {
    delta_hhh = solverData->epsfcn * f[i];
    delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(delta_hhh)), delta_h);
    delta_hh = ((f[i] >= 0) ? delta_hh : -delta_hh);
    delta_hh = x[i] + delta_hh - x[i];
    deltaInv = 1. / delta_hh;
    solverData->xSave[i] = x[i] + delta_hh;

    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC))
    {
      infoStreamPrint(OMC_LOG_NLS_JAC, 0, "%d. %s = %f (delta_hh = %f)", i+1, modelInfoGetEquation(&hybrdUserData->data->modelData->modelDataXml, systemData->equationIndex).vars[i], solverData->xSave[i], delta_hh);
    }
    wrapper_fvec_hybrj(&solverData->n, (const double*) solverData->xSave, solverData->fvecSave, solverData->fjacobian, &solverData->ldfjac, &iflag, hybrdUserData);

    for(j = 0; j < solverData->n; ++j)
    {
      l = i*solverData->n+j;
      solverData->fjacobian[l] = jac[l] = (solverData->fvecSave[j] - f[j]) * deltaInv;
    }
    solverData->xSave[i] = x[i];
  }

  return 0;
}

/**
 * @brief Calculate analytic Jacobian J(x).
 *
 * Using symbolic Jacobian and sparsity + coloring.
 * x has to be set before calling this function.
 *
 * @param hybrdUserData   Pointer to hybrid solver user data.
 * @param jac             Contains values of Jacobian J(x) on exit.
 * @return int            Return 0 on success.
 */
static int getAnalyticalJacobian(NLS_USERDATA* hybrdUserData, double* jac)
{
  int i, j, k, l, ii;
  DATA *data = hybrdUserData->data;
  threadData_t *threadData = hybrdUserData->threadData;
  NONLINEAR_SYSTEM_DATA* systemData = hybrdUserData->nlsData;
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);
  ANALYTIC_JACOBIAN* jacobian = hybrdUserData->analyticJacobian;

  memset(jac, 0, (solverData->n)*(solverData->n)*sizeof(double));
  memset(solverData->fjacobian, 0, (solverData->n)*(solverData->n)*sizeof(double));

  if (jacobian->constantEqns != NULL) {
    jacobian->constantEqns(data, threadData, jacobian, NULL);
  }

  for(i=0; i < jacobian->sparsePattern->maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < jacobian->sizeCols; ii++)
      if(jacobian->sparsePattern->colorCols[ii]-1 == i)
        jacobian->seedVars[ii] = 1;

    systemData->analyticalJacobianColumn(data, threadData, jacobian, NULL);

    for(j = 0; j < jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        ii = jacobian->sparsePattern->leadindex[j];
        while(ii < jacobian->sparsePattern->leadindex[j+1])
        {
          l  = jacobian->sparsePattern->index[ii];
          k  = j*jacobian->sizeRows + l;
          solverData->fjacobian[k] = jac[k] = jacobian->resultVars[l];
          ii++;
        };
      }
      /* de-activate seed variable for the corresponding color */
      if(jacobian->sparsePattern->colorCols[j]-1 == i)
        jacobian->seedVars[j] = 0;
    }
  }

  return 0;
}

/**
 * @brief Residual and Jacobian function.
 *
 * @param n               Size of arrays x and f.
 * @param x               Vector x.
 * @param f               Residual vector f(x).
 *                        Set to residual vector on exit, if iflag=1.
 *                        Needs to be set as input, if iflag=2.
 * @param fjac            Array for Jacobian J(x)
 * @param ldjac           Leading dimension of Jacobian.
 * @param iflag           Flag signaling if residual or Jacobian should be evaluated.
 *                        iflag = 1 ==> Residual evaluation
 *                        iflag = 2 ==> Jacobian evaluation
 * @param userDataIn      User data. Get's typecasted to NLS_USERDATA
 */
static void wrapper_fvec_hybrj(const integer *n_p, const double* x, double* f, double* fjac, const integer* ldjac, const integer* iflag, void* userDataIn)
{
  int i,j;
  int n = *n_p;
  NLS_USERDATA* userData = (NLS_USERDATA*) userDataIn;
  DATA* data = userData->data;
  threadData_t* threadData = userData->threadData;
  NONLINEAR_SYSTEM_DATA* systemData = userData->nlsData;
  DATA_HYBRD* hybrdData = (DATA_HYBRD*)(systemData->solverData);
  modelica_boolean continuous = data->simulationInfo->solveContinuous;
  RESIDUAL_USERDATA resUserData = {.data=data, .threadData=threadData, .solverData=userData->solverData};

  switch(*iflag)
  {
  case 1:
    /* re-scaling x vector */
    if(hybrdData->useXScaling)
      for(i=0; i<n; i++)
        hybrdData->xScaled[i] = x[i]*hybrdData->xScalefactors[i];

    /* debug output */
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_RES)) {
      infoStreamPrint(OMC_LOG_NLS_RES, 0, "-- residual function call %d -- scaling = %d", (int)hybrdData->nfev, hybrdData->useXScaling);
      printVector(x, n, OMC_LOG_NLS_RES, "x vector (scaled)");
      printVector(hybrdData->xScaled, n, OMC_LOG_NLS_RES, "x vector");
    }

    /* call residual function */
    if(hybrdData->useXScaling){
      (systemData->residualFunc)(&resUserData, (const double*) hybrdData->xScaled, f, (const int*)iflag);
    } else {
      (systemData->residualFunc)(&resUserData, x, f, (const int*)iflag);
    }

    /* debug output */
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_RES)) {
      printVector(f, n, OMC_LOG_NLS_RES, "residuals");
      infoStreamPrint(OMC_LOG_NLS_RES, 0, "-- end of residual function call %d --", (int)hybrdData->nfev);
    }

    hybrdData->numberOfFunctionEvaluations++;
    break;
  case 2:
    /* set residual function continuous for jacobian calculation */
    if(continuous)
      data->simulationInfo->solveContinuous = FALSE;

    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_RES))
      infoStreamPrint(OMC_LOG_NLS_RES, 0, "-- begin calculating jacobian --");

    /* performance measurement */
    rt_ext_tp_tick(&systemData->jacobianTimeClock);

    /* call apropreated jacobian function */
    if(systemData->jacobianIndex != -1){
      integer iflagtmp = 1;
      wrapper_fvec_hybrj(n_p, x, f, fjac, ldjac, &iflagtmp, userData);

      getAnalyticalJacobian(userData, fjac);
    }
    else{
      getNumericalJacobian(userData, fjac, x, f);
    }

    /* debug output */
    if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_RES)) {
      infoStreamPrint(OMC_LOG_NLS_RES, 0, "-- end calculating jacobian --");

      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC))
      {
        char *buffer = (char*)malloc(sizeof(char)*n*25);
        infoStreamPrint(OMC_LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", n, n);
        for(i=0; i<n; i++)
        {
          buffer[0] = 0;
          for(j=0; j<n; j++)
            sprintf(buffer, "%s%20.12g ", buffer, fjac[i*hybrdData->n+j]);
          infoStreamPrint(OMC_LOG_NLS_JAC, 0, "%s", buffer);
        }
        messageClose(OMC_LOG_NLS_JAC);
        free(buffer);
      }
    }
    /* reset residual function again */
    if(continuous)
      data->simulationInfo->solveContinuous = TRUE;

    /* performance measurement and statistics */
    systemData->jacobianTime += rt_ext_tp_tock(&(systemData->jacobianTimeClock));
    systemData->numberOfJEval++;

    break;

  default:
    throwStreamPrint(NULL, "Well, this is embarrasing. The non-linear solver should never call this case.%d", (int)*iflag);
    break;
  }
}

/**
 * @brief Solve non-linear system with hybrid method.
 *
 * @param data                Runtime data struct.
 * @param threadData          Thread data for error handling.
 * @param nlsData             Pointer to non-linear system data.
 * @return NLS_SOLVER_STATUS  Return NLS_SOLVED on success and NLS_FAILED otherwise.
 */
NLS_SOLVER_STATUS solveHybrd(DATA *data, threadData_t *threadData, NONLINEAR_SYSTEM_DATA* nlsData)
{
  DATA_HYBRD* hybrdData = (DATA_HYBRD*)nlsData->solverData;
  int eqSystemNumber = nlsData->equationIndex;

  int i, j;
  integer iflag = 1;
  double xerror, xerror_scaled;
  NLS_SOLVER_STATUS success = NLS_FAILED;
  modelica_boolean catchedError;
  double local_tol = 1e-12;
  double initial_factor = hybrdData->factor;
  int nfunc_evals = 0;
  modelica_boolean continuous = TRUE;
  int nonContinuousCase = 0;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int retries3 = 0;
  int assertCalled = 0;
  int assertRetries = 0;
  int assertMessage = 0;

  modelica_boolean* relationsPreBackup;

  relationsPreBackup = (modelica_boolean*) malloc(data->modelData->nRelations*sizeof(modelica_boolean));

  hybrdData->numberOfFunctionEvaluations = 0;

  // Initialize lambda variable
  if (nlsData->homotopySupport) {
    hybrdData->x[hybrdData->n] = 1.0;
    hybrdData->xSave[hybrdData->n] = 1.0;
    hybrdData->xScaled[hybrdData->n] = 1.0;
  }
  else {
    hybrdData->x[hybrdData->n] = 0.0;
    hybrdData->xSave[hybrdData->n] = 0.0;
    hybrdData->xScaled[hybrdData->n] = 0.0;
  }

  /* debug output */
  if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
  {
    int indexes[2] = {1,eqSystemNumber};
    infoStreamPrintWithEquationIndexes(OMC_LOG_NLS_V, omc_dummyFileInfo, 1, indexes,
      "Start solving Non-Linear System %d (size %d) at time %g with Hybrd Solver",
      eqSystemNumber, (int) nlsData->size, data->localData[0]->timeValue);

    for(i = 0; i < hybrdData->n; i++) {
      infoStreamPrint(OMC_LOG_NLS_V, 1, "%d. %s = %f", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], nlsData->nlsx[i]);
      infoStreamPrint(OMC_LOG_NLS_V, 0, "    nominal = %f\nold = %f\nextrapolated = %f",
          nlsData->nominal[i], nlsData->nlsxOld[i], nlsData->nlsxExtrapolation[i]);
      messageClose(OMC_LOG_NLS_V);
    }
    messageClose(OMC_LOG_NLS_V);
  }

  /* set x vector */
  if(data->simulationInfo->discreteCall)
    memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
  else
    memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

  for(i=0; i<hybrdData->n; i++){
    hybrdData->xScalefactors[i] = fmax(fabs(hybrdData->x[i]), nlsData->nominal[i]);
  }

  /* start solving loop */
  while(!giveUp && !success)
  {
    /* constrain x */
    for(i=0; i<hybrdData->n; i++)
      hybrdData->x[i] = fmax(nlsData->min[i], fmin(hybrdData->x[i], nlsData->max[i]));

    for(i=0; i<hybrdData->n; i++)
      hybrdData->xScalefactors[i] = fmax(fabs(hybrdData->x[i]), nlsData->nominal[i]);

    /* debug output */
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
      printVector(hybrdData->xScalefactors, (hybrdData->n), OMC_LOG_NLS_V, "scaling factors x vector");
      printVector(hybrdData->x, (hybrdData->n), OMC_LOG_NLS_V, "Iteration variable values");
    }

    /* Scaling x vector */
    if(hybrdData->useXScaling) {
      for(i=0; i<hybrdData->n; i++) {
        hybrdData->x[i] = (1.0/hybrdData->xScalefactors[i]) * hybrdData->x[i];
      }
    }

    /* debug output */
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
    {
      printVector(hybrdData->x, hybrdData->n, OMC_LOG_NLS_V, "Iteration variable values (scaled)");
    }

    /* set residual function continuous */
    data->simulationInfo->solveContinuous = continuous;

    giveUp = 1;

    /* try */
    {
      catchedError = TRUE;
#ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      hybrj_(wrapper_fvec_hybrj, &hybrdData->n, hybrdData->x,
          hybrdData->fvec, hybrdData->fjac, &hybrdData->ldfjac, &hybrdData->xtol,
          &hybrdData->maxfev, hybrdData->diag, &hybrdData->mode, &hybrdData->factor,
          &hybrdData->nprint, &hybrdData->info, &hybrdData->nfev, &hybrdData->njev, hybrdData->r__,
          &hybrdData->lr, hybrdData->qtf, hybrdData->wa1, hybrdData->wa2,
          hybrdData->wa3, hybrdData->wa4, hybrdData->userData);

      if(assertCalled)
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, "After assertions failed, found a solution for which assertions did not fail.");
        /* re-scaling x vector */
        for(i=0; i<hybrdData->n; i++){
          if(hybrdData->useXScaling)
            nlsData->nlsxOld[i] = hybrdData->x[i]*hybrdData->xScalefactors[i];
          else
            nlsData->nlsxOld[i] = hybrdData->x[i];
        }
      }
      assertRetries = 0;
      assertCalled = 0;
      catchedError = FALSE;
#ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      /* catch */
      if (catchedError)
      {
        if (!assertMessage)
        {
          if (OMC_ACTIVE_WARNING_STREAM(OMC_LOG_STDOUT))
          {
            if(data->simulationInfo->initial)
              warningStreamPrint(OMC_LOG_STDOUT, 1, "While solving non-linear system an assertion failed during initialization.");
            else
              warningStreamPrint(OMC_LOG_STDOUT, 1, "While solving non-linear system an assertion failed at time %g.", data->localData[0]->timeValue);
            warningStreamPrint(OMC_LOG_STDOUT, 0, "The non-linear solver tries to solve the problem that could take some time.");
            warningStreamPrint(OMC_LOG_STDOUT, 0, "It could help to provide better start-values for the iteration variables.");
            if (!OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
              warningStreamPrint(OMC_LOG_STDOUT, 0, "For more information simulate with -lv LOG_NLS_V");
            messageClose(OMC_LOG_STDOUT);
          }
          assertMessage = 1;
        }

        hybrdData->info = -1;
        xerror_scaled = 1;
        xerror = 1;
        assertCalled = 1;
      }
    }

    /* reset residual function continuous */
    data->simulationInfo->solveContinuous = !continuous;

    /* re-scaling x vector */
    if(hybrdData->useXScaling)
      for(i=0; i<hybrdData->n; i++)
        hybrdData->x[i] = hybrdData->x[i]*hybrdData->xScalefactors[i];

    /* check for proper inputs */
    if(hybrdData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber),
                       data->localData[0]->timeValue);
    }

    if(hybrdData->info != -1)
    {
      /* evaluate with discontinuities */
      if(data->simulationInfo->discreteCall){
        int scaling = hybrdData->useXScaling;
        catchedError = TRUE;
        if(scaling)
          hybrdData->useXScaling = 0;

        data->simulationInfo->solveContinuous = FALSE;

        /* try */
#ifndef OMC_EMCC
        MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        wrapper_fvec_hybrj(&hybrdData->n, hybrdData->x, hybrdData->fvec, hybrdData->fjac, &hybrdData->ldfjac, &iflag, hybrdData->userData);
        catchedError = FALSE;
#ifndef OMC_EMCC
        MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        /* catch */
        if (catchedError)
        {
          warningStreamPrint(OMC_LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

          hybrdData->info = -1;
          xerror_scaled = 1;
          xerror = 1;
          assertCalled = 1;
        }

        if(scaling)
          hybrdData->useXScaling = 1;

        updateRelationsPre(data);
      }
    }

    if(hybrdData->info != -1)
    {
      /* scaling residual vector */
      {
        int l=0;
        for(i=0; i<hybrdData->n; i++){
          hybrdData->resScaling[i] = 1e-16;
          for(j=0; j<hybrdData->n; j++){
            hybrdData->resScaling[i] = (fabs(hybrdData->fjacobian[l]) > hybrdData->resScaling[i])
                    ? fabs(hybrdData->fjacobian[l]) : hybrdData->resScaling[i];
            l++;
          }
          hybrdData->fvecScaled[i] = hybrdData->fvec[i] * (1 / hybrdData->resScaling[i]);
        }
        /* debug output */
        if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
        {
          infoStreamPrint(OMC_LOG_NLS_V, 1, "scaling factors for residual vector");
          for(i=0; i<hybrdData->n; i++)
          {
            infoStreamPrint(OMC_LOG_NLS_V, 1, "scaled residual [%d] : %.20e", i, hybrdData->fvecScaled[i]);
            infoStreamPrint(OMC_LOG_NLS_V, 0, "scaling factor [%d] : %.20e", i, hybrdData->resScaling[i]);
            messageClose(OMC_LOG_NLS_V);
          }
          messageClose(OMC_LOG_NLS_V);
        }

        /* debug output */
        if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC))
        {
          char *buffer = (char*)malloc(sizeof(char)*hybrdData->n*15);

          infoStreamPrint(OMC_LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", (int)hybrdData->n, (int)hybrdData->n);
          for(i=0; i<hybrdData->n; i++)
          {
            buffer[0] = 0;
            for(j=0; j<hybrdData->n; j++)
              sprintf(buffer, "%s%10g ", buffer, hybrdData->fjacobian[i*hybrdData->n+j]);
            infoStreamPrint(OMC_LOG_NLS_JAC, 0, "%s", buffer);
          }
          messageClose(OMC_LOG_NLS_JAC);
          free(buffer);
        }

        /* check for error  */
        xerror_scaled = enorm_(&hybrdData->n, hybrdData->fvecScaled);
        xerror = enorm_(&hybrdData->n, hybrdData->fvec);
      }
    }

    /* reset non-contunuousCase */
    if(nonContinuousCase && xerror > local_tol && xerror_scaled > local_tol)
    {
      memcpy(data->simulationInfo->relationsPre, relationsPreBackup, sizeof(modelica_boolean)*data->modelData->nRelations);
      nonContinuousCase = 0;
    }

    if(hybrdData->info < 4 && xerror > local_tol && xerror_scaled > local_tol)
      hybrdData->info = 4;

    /* solution found */
    if(hybrdData->info == 1 || xerror <= local_tol || xerror_scaled <= local_tol)
    {
      int scaling;

      success = NLS_SOLVED;
      nfunc_evals += hybrdData->nfev;
      if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)){
        infoStreamPrint(OMC_LOG_NLS_V, 1, "System solved");
        infoStreamPrint(OMC_LOG_NLS_V, 0, "%d retries\n%d restarts", retries, retries2+retries3);
        messageClose(OMC_LOG_NLS_V);
      }
      scaling = hybrdData->useXScaling;
      if(scaling)
        hybrdData->useXScaling = 0;

      /* take the solution */
      memcpy(nlsData->nlsx, hybrdData->x, hybrdData->n*(sizeof(double)));

      /* try */
      {
        catchedError = TRUE;
#ifndef OMC_EMCC
        MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        wrapper_fvec_hybrj(&hybrdData->n, hybrdData->x, hybrdData->fvec, hybrdData->fjac, &hybrdData->ldfjac, &iflag, hybrdData->userData);
        catchedError = FALSE;
#ifndef OMC_EMCC
        MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        /* catch */
        if (catchedError) {
          warningStreamPrint(OMC_LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

          hybrdData->info = 4;
          xerror_scaled = 1;
          xerror = 1;
          assertCalled = 1;
          success = NLS_FAILED;
          giveUp = 0;
        }
      }
      if(scaling)
        hybrdData->useXScaling = 1;
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && assertRetries < 1+hybrdData->n && assertCalled)
    {
      /* case only used, when the Modelica code called an assert
       * then, we try to modify start values to avoid the assert call.*/
      int i;

      memcpy(hybrdData->x, nlsData->nlsxOld, hybrdData->n*(sizeof(double)));

      /* set all zero values to nominal values */
      if(assertRetries < 1)
      {
        for(i=0; i<hybrdData->n; i++)
        {
          if(nlsData->nlsx[i] == 0)
          {
            nlsData->nlsx[i] = nlsData->nominal[i];
            hybrdData->x[i] = nlsData->nominal[i];
          }
        }
      }
      /* change initial guess values one by one */
      else if(assertRetries < hybrdData->n+1)
      {
        i = assertRetries-1;
        hybrdData->x[i] += 0.01*nlsData->nominal[i];
      }

      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      assertRetries++;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - try to handle a problem with a called assert vary initial value a bit. (Retry: %d)",assertRetries);
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && retries < 3)
    {
      /* first try to decrease factor */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

      hybrdData->factor = hybrdData->factor / 10.0;

      retries++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t decreasing initial step bound to %f.", hybrdData->factor);
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && retries < 4)
    {
      /* try to vary the initial values */

      for(i = 0; i < hybrdData->n; i++)
        hybrdData->x[i] += nlsData->nominal[i] * 0.1;

      hybrdData->factor = initial_factor;
      retries++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;

      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, "iteration making no progress:\t vary solution point by 1%%.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && retries < 5)
    {
      /* try old values as x-Scaling factors */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));


      for(i=0; i<hybrdData->n; i++)
        hybrdData->xScalefactors[i] = fmax(fabs(nlsData->nlsxOld[i]), nlsData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, "iteration making no progress:\t try old values as scaling factors.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && retries < 6)
    {
      int scaling = 0;
      /* try to disable x-Scaling */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

      scaling = hybrdData->useXScaling;
      if(scaling)
        hybrdData->useXScaling = 0;

      /* reset x-scaling factors */
      for(i=0; i<hybrdData->n; i++)
        hybrdData->xScalefactors[i] = fmax(fabs(hybrdData->x[i]), nlsData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;

      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
      {
        infoStreamPrint(OMC_LOG_NLS_V, 0, "iteration making no progress:\t try without scaling at all.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    }
    else if((hybrdData->info == 4 || hybrdData->info == 5) && retries < 7  && data->simulationInfo->discreteCall)
    {
      /* try to solve non-continuous
       * work-a-round: since other wise some model does
       * stuck in event iteration. e.g.: Modelica.Mechanics.Rotational.Examples.HeatLosses
       */

      memcpy(hybrdData->x, nlsData->nlsxOld, hybrdData->n*(sizeof(double)));
      retries++;

      /* try to solve a discontinuous system */
      continuous = FALSE;

      nonContinuousCase = 1;
      memcpy(relationsPreBackup, data->simulationInfo->relationsPre, sizeof(modelica_boolean)*data->modelData->nRelations);

      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t try to solve a discontinuous system.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* Then try with old values (instead of extrapolating )*/
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries2 < 1) {
      int scaling = 0;
      /* set x vector */
      memcpy(hybrdData->x, nlsData->nlsxOld, hybrdData->n*(sizeof(double)));

      scaling = hybrdData->useXScaling;
      if(!scaling)
        hybrdData->useXScaling = 1;

      continuous = TRUE;
      hybrdData->factor = initial_factor;

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t use old values instead extrapolated.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries2 < 2) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));
      for(i = 0; i < hybrdData->n; i++) {
        hybrdData->x[i] *= 1.01;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0,
            " - iteration making no progress:\t vary initial point by adding 1%%.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries2 < 3) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));
      for(i = 0; i < hybrdData->n; i++) {
        hybrdData->x[i] *= 0.99;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t vary initial point by -1%%.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries2 < 4) {
      /* set x vector */
      memcpy(hybrdData->x, nlsData->nominal, hybrdData->n*(sizeof(double)));
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t try scaling factor as initial point.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try own scaling factors */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries2 < 5 && !assertCalled) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

      for(i = 0; i < hybrdData->n; i++) {
        hybrdData->diag[i] = fabs(hybrdData->resScaling[i]);
        if(hybrdData->diag[i] <= 1e-16)
          hybrdData->diag[i] = 1e-16;
      }
      retries = 0;
      retries2++;
      giveUp = 0;
      hybrdData->mode = 2;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t try with own scaling factors.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try without internal scaling */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries3 < 1) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

      for(i = 0; i < hybrdData->n; i++)
        hybrdData->diag[i] = 1.0;

      hybrdData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      retries3++;
      hybrdData->mode = 2;
      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t disable solver internal scaling.");
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    /* try to reduce the tolerance a bit */
    } else if((hybrdData->info == 4 || hybrdData->info == 5) && retries3 < 6) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(hybrdData->x, nlsData->nlsx, hybrdData->n*(sizeof(double)));
      else
        memcpy(hybrdData->x, nlsData->nlsxExtrapolation, hybrdData->n*(sizeof(double)));

      /* reduce tolarance */
      local_tol = local_tol*10;

      hybrdData->factor = initial_factor;
      hybrdData->mode = 1;

      retries = 0;
      retries2 = 0;
      retries3++;

      giveUp = 0;
      nfunc_evals += hybrdData->nfev;
      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, " - iteration making no progress:\t reduce the tolerance slightly to %e.", local_tol);
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
    } else if(hybrdData->info >= 2 && hybrdData->info <= 5) {

      /* while the initialization it's ok to every time a solution */
      if(!data->simulationInfo->initial){
        printErrorEqSyst(ERROR_AT_TIME, modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber), data->localData[0]->timeValue);
      }
      if (OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 0, "### No Solution! ###\n after %d restarts", retries*retries2*retries3);
        printStatus(data, hybrdData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, OMC_LOG_NLS_V);
      }
      /* take the best approximation */
      memcpy(nlsData->nlsx, hybrdData->x, hybrdData->n*(sizeof(double)));

      giveUp = 1;
      success = NLS_FAILED;
      break;
    }
  }

  /* reset some solving data */
  hybrdData->factor = initial_factor;
  hybrdData->mode = 1;

  /* write statistics */
  nlsData->numberOfFEval += hybrdData->numberOfFunctionEvaluations;
  /* iteration in hybrid are equal to the nfev numbers */
  nlsData->numberOfIterations += nfunc_evals;

  free(relationsPreBackup);

  return success;
}

#ifdef __cplusplus
}
#endif
