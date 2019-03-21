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

struct dataAndSys {
  DATA* data;
  threadData_t *threadData;
  int sysNumber;
};

static void wrapper_fvec_hybrj(const integer* n, const double* x, double* f, double* fjac, const integer* ldjac, const integer* iflag, void* data);

/*! \fn allocate memory for nonlinear system solver hybrd
 *
 */
int allocateHybrdData(int size, void** voiddata)
{
  DATA_HYBRD* data = (DATA_HYBRD*) malloc(sizeof(DATA_HYBRD));

  *voiddata = (void*)data;
  assertStreamPrint(NULL, 0 != data, "allocationHybrdData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));
  data->useXScaling = 1;
  data->xScalefactors = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc((size+1)*sizeof(double));
  data->xSave = (double*) malloc((size+1)*sizeof(double));
  data->xScaled = (double*) malloc((size+1)*sizeof(double));
  data->fvec = (double*) calloc(size, sizeof(double));
  data->fvecSave = (double*) calloc(size, sizeof(double));
  data->xtol = 1e-12;
  data->maxfev = size*10000;
  data->ml = size - 1;
  data->mu = size - 1;
  data->epsfcn = 1e-12;
  data->diag = (double*) malloc(size*sizeof(double));
  data->diagres = (double*) malloc(size*sizeof(double));
  data->mode = 1;
  data->factor = 100.0;
  data->nprint = -1;
  data->info = 0;
  data->nfev = 0;
  data->njev = 0;
  data->fjac = (double*) calloc((size*(size+1)), sizeof(double));
  data->fjacobian = (double*) calloc((size*(size+1)), sizeof(double));
  data->ldfjac = size;
  data->r__ = (double*) malloc(((size*(size+1))/2)*sizeof(double));
  data->lr = (size*(size + 1)) / 2;
  data->qtf = (double*) malloc(size*sizeof(double));
  data->wa1 = (double*) malloc(size*sizeof(double));
  data->wa2 = (double*) malloc(size*sizeof(double));
  data->wa3 = (double*) malloc(size*sizeof(double));
  data->wa4 = (double*) malloc(size*sizeof(double));

  data->numberOfIterations = 0;
  data->numberOfFunctionEvaluations = 0;

  assertStreamPrint(NULL, 0 != *voiddata, "allocationHybrdData() voiddata failed!");
  return 0;
}

/*! \fn free memory for nonlinear solver hybrd
 *
 */
int freeHybrdData(void **voiddata)
{
  DATA_HYBRD* data = (DATA_HYBRD*) *voiddata;

  free(data->resScaling);
  free(data->fvecScaled);
  free(data->xScalefactors);
  free(data->x);
  free(data->xSave);
  free(data->xScaled);
  free(data->fvec);
  free(data->fvecSave);
  free(data->diag);
  free(data->diagres);
  free(data->fjac);
  free(data->fjacobian);
  free(data->r__);
  free(data->qtf);
  free(data->wa1);
  free(data->wa2);
  free(data->wa3);
  free(data->wa4);

  return 0;
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
static void printVector(const double *vector, const integer *size, const int logLevel, const char *name)
{
  int i;
  if (!ACTIVE_STREAM(logLevel)) return;
  infoStreamPrint(logLevel, 1, "%s", name);
  for(i=0; i<*size; i++)
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

  if (!ACTIVE_STREAM(logLevel)) return;
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


/*! \fn getAnalyticalJacobian
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 *
 *  \param [ref] [data]
 *  \param [out] [jac]
 *
 *  \author wbraun
 *
 */
static int getNumericalJacobian(struct dataAndSys* dataAndSysNum, double* jac, const double* x, double* f)
{
  struct dataAndSys *dataSys = (struct dataAndSys*) dataAndSysNum;
  NONLINEAR_SYSTEM_DATA* systemData = &(dataSys->data->simulationInfo->nonlinearSystemData[dataSys->sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);

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

    infoStreamPrint(LOG_NLS_JAC, 0, "%d. %s = %f (delta_hh = %f)", i+1, modelInfoGetEquation(&dataSys->data->modelData->modelDataXml,systemData->equationIndex).vars[i], solverData->xSave[i], delta_hh);
    wrapper_fvec_hybrj(&solverData->n, (const double*) solverData->xSave, solverData->fvecSave, solverData->fjacobian, &solverData->ldfjac, &iflag, dataSys);

    for(j = 0; j < solverData->n; ++j)
    {
      l = i*solverData->n+j;
      solverData->fjacobian[l] = jac[l] = (solverData->fvecSave[j] - f[j]) * deltaInv;
    }
    solverData->xSave[i] = x[i];
  }

  return 0;
}

/*! \fn getAnalyticalJacobian
 *
 *  function calculates analytical jacobian
 *
 *  \param [ref] [data]
 *  \param [out] [jac]
 *
 *  \author wbraun
 *
 */
static int getAnalyticalJacobian(struct dataAndSys* dataSys, double* jac)
{
  int i, j, k, l, ii;
  DATA *data = (dataSys->data);
  threadData_t *threadData = dataSys->threadData;
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[dataSys->sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);
  const int index = systemData->jacobianIndex;
  ANALYTIC_JACOBIAN* jacobian = &(data->simulationInfo->analyticJacobians[systemData->jacobianIndex]);

  memset(jac, 0, (solverData->n)*(solverData->n)*sizeof(double));
  memset(solverData->fjacobian, 0, (solverData->n)*(solverData->n)*sizeof(double));

  for(i=0; i < jacobian->sparsePattern.maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < jacobian->sizeCols; ii++)
      if(jacobian->sparsePattern.colorCols[ii]-1 == i)
        jacobian->seedVars[ii] = 1;

    ((systemData->analyticalJacobianColumn))(data, threadData, jacobian, NULL);

    for(j=0; j<jacobian->sizeCols; j++)
    {
      if(jacobian->seedVars[j] == 1)
      {
        ii = jacobian->sparsePattern.leadindex[j];
        while(ii < jacobian->sparsePattern.leadindex[j+1])
        {
          l  = jacobian->sparsePattern.index[ii];
          k  = j*jacobian->sizeRows + l;
          solverData->fjacobian[k] = jac[k] = jacobian->resultVars[l];
          ii++;
        };
      }
      /* de-activate seed variable for the corresponding color */
      if(jacobian->sparsePattern.colorCols[j]-1 == i)
        jacobian->seedVars[j] = 0;
    }

  }

  return 0;
}

/*! \fn wrapper function of the residual Function
 *   non-linear solver calls this subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
static void wrapper_fvec_hybrj(const integer* n, const double* x, double* f, double* fjac, const integer* ldjac, const integer* iflag, void* dataAndSysNum)
{
  int i,j;
  struct dataAndSys *dataSys = (struct dataAndSys*) dataAndSysNum;
  DATA *data = (dataSys->data);
  void *dataAndThreadData[2] = {data, dataSys->threadData};
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[dataSys->sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);
  int continuous = data->simulationInfo->solveContinuous;

  switch(*iflag)
  {
  case 1:
    /* re-scaling x vector */
    if(solverData->useXScaling)
      for(i=0; i<*n; i++)
        solverData->xScaled[i] = x[i]*solverData->xScalefactors[i];

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_RES)) {
      infoStreamPrint(LOG_NLS_RES, 0, "-- residual function call %d -- scaling = %d", (int)solverData->nfev, solverData->useXScaling);
      printVector(x, n, LOG_NLS_RES, "x vector (scaled)");
      printVector(solverData->xScaled, n, LOG_NLS_RES, "x vector");
    }

    /* call residual function */
    if(solverData->useXScaling){
      (systemData->residualFunc)(dataAndThreadData, (const double*) solverData->xScaled, f, (const int*)iflag);
    } else {
      (systemData->residualFunc)(dataAndThreadData, x, f, (const int*)iflag);
    }

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_RES)) {
      printVector(f, n, LOG_NLS_RES, "residuals");
      infoStreamPrint(LOG_NLS_RES, 0, "-- end of residual function call %d --", (int)solverData->nfev);
    }

    solverData->numberOfFunctionEvaluations++;
    break;
  case 2:
    /* set residual function continuous for jacobian calculation */
    if(continuous)
      data->simulationInfo->solveContinuous = 0;

    if(ACTIVE_STREAM(LOG_NLS_RES))
      infoStreamPrint(LOG_NLS_RES, 0, "-- begin calculating jacobian --");

    /* performance measurement */
    rt_ext_tp_tick(&systemData->jacobianTimeClock);

    /* call apropreated jacobian function */
    if(systemData->jacobianIndex != -1){
      integer iflagtmp = 1;
      wrapper_fvec_hybrj(n, x, f, fjac, ldjac, &iflagtmp, dataSys);

      getAnalyticalJacobian(dataSys, fjac);
    }
    else{
      getNumericalJacobian(dataSys, fjac, x, f);
    }

    /* debug output */
    if (ACTIVE_STREAM(LOG_NLS_RES)) {
      infoStreamPrint(LOG_NLS_RES, 0, "-- end calculating jacobian --");

      if(ACTIVE_STREAM(LOG_NLS_JAC))
      {
        char *buffer = (char*)malloc(sizeof(char)*(*n)*25);
        infoStreamPrint(LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", (int)*n, (int)*n);
        for(i=0; i<*n; i++)
        {
          buffer[0] = 0;
          for(j=0; j<*n; j++)
            sprintf(buffer, "%s%20.12g ", buffer, fjac[i*solverData->n+j]);
          infoStreamPrint(LOG_NLS_JAC, 0, "%s", buffer);
        }
        messageClose(LOG_NLS_JAC);
        free(buffer);
      }
    }
    /* reset residual function again */
    if(continuous)
      data->simulationInfo->solveContinuous = 1;

    /* performance measurement and statistics */
    systemData->jacobianTime += rt_ext_tp_tock(&(systemData->jacobianTimeClock));
    systemData->numberOfJEval++;

    break;

  default:
    throwStreamPrint(NULL, "Well, this is embarrasing. The non-linear solver should never call this case.%d", (int)*iflag);
    break;
  }
}

/*! \fn solve non-linear system with hybrd method
 *
 *  \param [in]  [data]
 *               [sysNumber] index of the corresponing non-linear system
 *
 *  \author wbraun
 */
int solveHybrd(DATA *data, threadData_t *threadData, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo->nonlinearSystemData[sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)systemData->solverData;
  /*
   * We are given the number of the non-linear system.
   * We want to look it up among all equations.
   */
  int eqSystemNumber = systemData->equationIndex;

  int i, j;
  integer iflag = 1;
  double xerror, xerror_scaled;
  int success = 0;
  double local_tol = 1e-12;
  double initial_factor = solverData->factor;
  int nfunc_evals = 0;
  int continuous = 1;
  int nonContinuousCase = 0;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int retries3 = 0;
  int assertCalled = 0;
  int assertRetries = 0;
  int assertMessage = 0;

  modelica_boolean* relationsPreBackup;

  struct dataAndSys dataAndSysNumber = {data, threadData, sysNumber};

  relationsPreBackup = (modelica_boolean*) malloc(data->modelData->nRelations*sizeof(modelica_boolean));

  solverData->numberOfFunctionEvaluations = 0;

  // Initialize lambda variable
  if (data->simulationInfo->nonlinearSystemData[sysNumber].homotopySupport) {
    solverData->x[solverData->n] = 1.0;
    solverData->xSave[solverData->n] = 1.0;
    solverData->xScaled[solverData->n] = 1.0;
  }
  else {
    solverData->x[solverData->n] = 0.0;
    solverData->xSave[solverData->n] = 0.0;
    solverData->xScaled[solverData->n] = 0.0;
  }

  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    int indexes[2] = {1,eqSystemNumber};
    infoStreamPrintWithEquationIndexes(LOG_NLS_V, 1, indexes, "Start solving non-linear system >>%d<< using Hybrd solver at time %g", eqSystemNumber, data->localData[0]->timeValue);
    for(i=0; i<solverData->n; i++)
    {
      infoStreamPrint(LOG_NLS_V, 1, "%d. %s = %f", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i], systemData->nlsx[i]);
      infoStreamPrint(LOG_NLS_V, 0, "    nominal = %f\nold = %f\nextrapolated = %f",
          systemData->nominal[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      messageClose(LOG_NLS_V);
    }
    messageClose(LOG_NLS_V);
  }

  /* set x vector */
  if(data->simulationInfo->discreteCall)
    memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
  else
    memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  for(i=0; i<solverData->n; i++){
    solverData->xScalefactors[i] = fmax(fabs(solverData->x[i]), systemData->nominal[i]);
  }

  /* start solving loop */
  while(!giveUp && !success)
  {
    for(i=0; i<solverData->n; i++)
      solverData->xScalefactors[i] = fmax(fabs(solverData->x[i]), systemData->nominal[i]);

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_V)) {
      printVector(solverData->xScalefactors, &(solverData->n), LOG_NLS_V, "scaling factors x vector");
      printVector(solverData->x, &(solverData->n), LOG_NLS_V, "Iteration variable values");
    }

    /* Scaling x vector */
    if(solverData->useXScaling) {
      for(i=0; i<solverData->n; i++) {
        solverData->x[i] = (1.0/solverData->xScalefactors[i]) * solverData->x[i];
      }
    }

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_V))
    {
      printVector(solverData->x, &solverData->n, LOG_NLS_V, "Iteration variable values (scaled)");
    }

    /* set residual function continuous
     */
    if(continuous) {
      ((DATA*)data)->simulationInfo->solveContinuous = 1;
    } else {
      ((DATA*)data)->simulationInfo->solveContinuous = 0;
    }

    giveUp = 1;

    /* try */
    {
      int success = 0;
#ifndef OMC_EMCC
      MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
      hybrj_(wrapper_fvec_hybrj, &solverData->n, solverData->x,
          solverData->fvec, solverData->fjac, &solverData->ldfjac, &solverData->xtol,
          &solverData->maxfev, solverData->diag, &solverData->mode, &solverData->factor,
          &solverData->nprint, &solverData->info, &solverData->nfev, &solverData->njev, solverData->r__,
          &solverData->lr, solverData->qtf, solverData->wa1, solverData->wa2,
          solverData->wa3, solverData->wa4, (void*) &dataAndSysNumber);

      success = 1;
      if(assertCalled)
      {
        infoStreamPrint(LOG_NLS_V, 0, "After assertions failed, found a solution for which assertions did not fail.");
        /* re-scaling x vector */
        for(i=0; i<solverData->n; i++){
          if(solverData->useXScaling)
            systemData->nlsxOld[i] = solverData->x[i]*solverData->xScalefactors[i];
          else
            systemData->nlsxOld[i] = solverData->x[i];
        }
      }
      assertRetries = 0;
      assertCalled = 0;
      success = 1;
#ifndef OMC_EMCC
      MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
      /* catch */
      if (!success)
      {
        if (!assertMessage)
        {
          if (ACTIVE_WARNING_STREAM(LOG_STDOUT))
          {
            if(data->simulationInfo->initial)
              warningStreamPrint(LOG_STDOUT, 1, "While solving non-linear system an assertion failed during initialization.");
            else
              warningStreamPrint(LOG_STDOUT, 1, "While solving non-linear system an assertion failed at time %g.", data->localData[0]->timeValue);
            warningStreamPrint(LOG_STDOUT, 0, "The non-linear solver tries to solve the problem that could take some time.");
            warningStreamPrint(LOG_STDOUT, 0, "It could help to provide better start-values for the iteration variables.");
            if (!ACTIVE_STREAM(LOG_NLS_V))
              warningStreamPrint(LOG_STDOUT, 0, "For more information simulate with -lv LOG_NLS_V");
            messageClose(LOG_STDOUT);
          }
          assertMessage = 1;
        }

        solverData->info = -1;
        xerror_scaled = 1;
        xerror = 1;
        assertCalled = 1;
      }
    }

    /* set residual function continuous */
    if(continuous)
    {
      ((DATA*)data)->simulationInfo->solveContinuous = 0;
    }
    else
    {
      ((DATA*)data)->simulationInfo->solveContinuous = 1;
    }

    /* re-scaling x vector */
    if(solverData->useXScaling)
      for(i=0; i<solverData->n; i++)
        solverData->x[i] = solverData->x[i]*solverData->xScalefactors[i];

    /* check for proper inputs */
    if(solverData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber),
          data->localData[0]->timeValue);
    }

    if(solverData->info != -1)
    {
      /* evaluate with discontinuities */
      if(data->simulationInfo->discreteCall){
        int scaling = solverData->useXScaling;
        int success = 0;
        if(scaling)
          solverData->useXScaling = 0;

        ((DATA*)data)->simulationInfo->solveContinuous = 0;

        /* try */
#ifndef OMC_EMCC
        MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        wrapper_fvec_hybrj(&solverData->n, solverData->x, solverData->fvec, solverData->fjac, &solverData->ldfjac, &iflag, (void*) &dataAndSysNumber);
        success = 1;
#ifndef OMC_EMCC
        MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        /* catch */
        if (!success)
        {
          warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

          solverData->info = -1;
          xerror_scaled = 1;
          xerror = 1;
          assertCalled = 1;
        }

        if(scaling)
          solverData->useXScaling = 1;

        updateRelationsPre(data);
      }
    }

    if(solverData->info != -1)
    {
      /* scaling residual vector */
      {
        int l=0;
        for(i=0; i<solverData->n; i++){
          solverData->resScaling[i] = 1e-16;
          for(j=0; j<solverData->n; j++){
            solverData->resScaling[i] = (fabs(solverData->fjacobian[l]) > solverData->resScaling[i])
                    ? fabs(solverData->fjacobian[l]) : solverData->resScaling[i];
            l++;
          }
          solverData->fvecScaled[i] = solverData->fvec[i] * (1 / solverData->resScaling[i]);
        }
        /* debug output */
        if(ACTIVE_STREAM(LOG_NLS_V))
        {
          infoStreamPrint(LOG_NLS_V, 1, "scaling factors for residual vector");
          for(i=0; i<solverData->n; i++)
          {
            infoStreamPrint(LOG_NLS_V, 1, "scaled residual [%d] : %.20e", i, solverData->fvecScaled[i]);
            infoStreamPrint(LOG_NLS_V, 0, "scaling factor [%d] : %.20e", i, solverData->resScaling[i]);
            messageClose(LOG_NLS_V);
          }
          messageClose(LOG_NLS_V);
        }

        /* debug output */
        if(ACTIVE_STREAM(LOG_NLS_JAC))
        {
          char *buffer = (char*)malloc(sizeof(char)*solverData->n*15);

          infoStreamPrint(LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", (int)solverData->n, (int)solverData->n);
          for(i=0; i<solverData->n; i++)
          {
            buffer[0] = 0;
            for(j=0; j<solverData->n; j++)
              sprintf(buffer, "%s%10g ", buffer, solverData->fjacobian[i*solverData->n+j]);
            infoStreamPrint(LOG_NLS_JAC, 0, "%s", buffer);
          }
          messageClose(LOG_NLS_JAC);
          free(buffer);
        }

        /* check for error  */
        xerror_scaled = enorm_(&solverData->n, solverData->fvecScaled);
        xerror = enorm_(&solverData->n, solverData->fvec);
      }
    }

    /* reset non-contunuousCase */
    if(nonContinuousCase && xerror > local_tol && xerror_scaled > local_tol)
    {
      memcpy(data->simulationInfo->relationsPre, relationsPreBackup, sizeof(modelica_boolean)*data->modelData->nRelations);
      nonContinuousCase = 0;
    }

    if(solverData->info < 4 && xerror > local_tol && xerror_scaled > local_tol)
      solverData->info = 4;

    /* solution found */
    if(solverData->info == 1 || xerror <= local_tol || xerror_scaled <= local_tol)
    {
      int scaling;

      success = 1;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        int indexes[2] = {1,eqSystemNumber};
        /* output solution */
        infoStreamPrintWithEquationIndexes(LOG_NLS_V, 1, indexes, "solution for NLS %d at t=%g", eqSystemNumber, data->localData[0]->timeValue);
        for(i=0; i<solverData->n; ++i)
        {
          infoStreamPrint(LOG_NLS_V, 0, "[%d] %s = %g", i+1, modelInfoGetEquation(&data->modelData->modelDataXml,eqSystemNumber).vars[i],  solverData->x[i]);
        }
        messageClose(LOG_NLS_V);
      }else if (ACTIVE_STREAM(LOG_NLS_V)){
        infoStreamPrint(LOG_NLS_V, 1, "system solved");
        infoStreamPrint(LOG_NLS_V, 0, "%d retries\n%d restarts", retries, retries2+retries3);
        messageClose(LOG_NLS_V);
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
      scaling = solverData->useXScaling;
      if(scaling)
        solverData->useXScaling = 0;

      /* take the solution */
      memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));

      /* try */
      {
        int success = 0;
#ifndef OMC_EMCC
        MMC_TRY_INTERNAL(simulationJumpBuffer)
#endif
        wrapper_fvec_hybrj(&solverData->n, solverData->x, solverData->fvec, solverData->fjac, &solverData->ldfjac, &iflag, (void*) &dataAndSysNumber);
        success = 1;
#ifndef OMC_EMCC
        MMC_CATCH_INTERNAL(simulationJumpBuffer)
#endif
        /* catch */
        if (!success) {
          warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

          solverData->info = 4;
          xerror_scaled = 1;
          xerror = 1;
          assertCalled = 1;
          success = 0;
          giveUp = 0;
        }
      }
      if(scaling)
        solverData->useXScaling = 1;
    }
    else if((solverData->info == 4 || solverData->info == 5) && assertRetries < 1+solverData->n && assertCalled)
    {
      /* case only used, when the Modelica code called an assert
       * then, we try to modify start values to avoid the assert call.*/
      int i;

      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      /* set all zero values to nominal values */
      if(assertRetries < 1)
      {
        for(i=0; i<solverData->n; i++)
        {
          if(systemData->nlsx[i] == 0)
          {
            systemData->nlsx[i] = systemData->nominal[i];
            solverData->x[i] = systemData->nominal[i];
          }
        }
      }
      /* change initial guess values one by one */
      else if(assertRetries < solverData->n+1)
      {
        i = assertRetries-1;
        solverData->x[i] += 0.01*systemData->nominal[i];
      }

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      assertRetries++;
      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        infoStreamPrint(LOG_NLS_V, 0, " - try to handle a problem with a called assert vary initial value a bit. (Retry: %d)",assertRetries);
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 3)
    {
      /* first try to decrease factor */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      solverData->factor = solverData->factor / 10.0;

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t decreasing initial step bound to %f.", solverData->factor);
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 4)
    {
      /* try to vary the initial values */

      for(i = 0; i < solverData->n; i++)
        solverData->x[i] += systemData->nominal[i] * 0.1;

      solverData->factor = initial_factor;
      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;

      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        infoStreamPrint(LOG_NLS_V, 0, "iteration making no progress:\t vary solution point by 1%%.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 5)
    {
      /* try old values as x-Scaling factors */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));


      for(i=0; i<solverData->n; i++)
        solverData->xScalefactors[i] = fmax(fabs(systemData->nlsxOld[i]), systemData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        infoStreamPrint(LOG_NLS_V, 0, "iteration making no progress:\t try old values as scaling factors.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 6)
    {
      int scaling = 0;
      /* try to disable x-Scaling */

      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      scaling = solverData->useXScaling;
      if(scaling)
        solverData->useXScaling = 0;

      /* reset x-scaling factors */
      for(i=0; i<solverData->n; i++)
        solverData->xScalefactors[i] = fmax(fabs(solverData->x[i]), systemData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;

      if(ACTIVE_STREAM(LOG_NLS_V))
      {
        infoStreamPrint(LOG_NLS_V, 0, "iteration making no progress:\t try without scaling at all.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 7  && data->simulationInfo->discreteCall)
    {
      /* try to solve non-continuous
       * work-a-round: since other wise some model does
       * stuck in event iteration. e.g.: Modelica.Mechanics.Rotational.Examples.HeatLosses
       */

      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));
      retries++;

      /* try to solve a discontinuous system */
      continuous = 0;

      nonContinuousCase = 1;
      memcpy(relationsPreBackup, data->simulationInfo->relationsPre, sizeof(modelica_boolean)*data->modelData->nRelations);

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t try to solve a discontinuous system.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* Then try with old values (instead of extrapolating )*/
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 1) {
      int scaling = 0;
      /* set x vector */
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      scaling = solverData->useXScaling;
      if(!scaling)
        solverData->useXScaling = 1;

      continuous = 1;
      solverData->factor = initial_factor;

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t use old values instead extrapolated.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 2) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));
      for(i = 0; i < solverData->n; i++) {
        solverData->x[i] *= 1.01;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0,
            " - iteration making no progress:\t vary initial point by adding 1%%.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 3) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));
      for(i = 0; i < solverData->n; i++) {
        solverData->x[i] *= 0.99;
      };

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t vary initial point by -1%%.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 4) {
      /* set x vector */
      memcpy(solverData->x, systemData->nominal, solverData->n*(sizeof(double)));
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t try scaling factor as initial point.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try own scaling factors */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 5 && !assertCalled) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      for(i = 0; i < solverData->n; i++) {
        solverData->diag[i] = fabs(solverData->resScaling[i]);
        if(solverData->diag[i] <= 1e-16)
          solverData->diag[i] = 1e-16;
      }
      retries = 0;
      retries2++;
      giveUp = 0;
      solverData->mode = 2;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t try with own scaling factors.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try without internal scaling */
    } else if((solverData->info == 4 || solverData->info == 5) && retries3 < 1) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      for(i = 0; i < solverData->n; i++)
        solverData->diag[i] = 1.0;

      solverData->useXScaling = 1;
      retries = 0;
      retries2 = 0;
      retries3++;
      solverData->mode = 2;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t disable solver internal scaling.");
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to reduce the tolerance a bit */
    } else if((solverData->info == 4 || solverData->info == 5) && retries3 < 6) {
      /* set x vector */
      if(data->simulationInfo->discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      /* reduce tolarance */
      local_tol = local_tol*10;

      solverData->factor = initial_factor;
      solverData->mode = 1;

      retries = 0;
      retries2 = 0;
      retries3++;

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, " - iteration making no progress:\t reduce the tolerance slightly to %e.", local_tol);
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    } else if(solverData->info >= 2 && solverData->info <= 5) {

      /* while the initialization it's ok to every time a solution */
      if(!data->simulationInfo->initial){
        printErrorEqSyst(ERROR_AT_TIME, modelInfoGetEquation(&data->modelData->modelDataXml, eqSystemNumber), data->localData[0]->timeValue);
      }
      if (ACTIVE_STREAM(LOG_NLS_V)) {
        infoStreamPrint(LOG_NLS_V, 0, "### No Solution! ###\n after %d restarts", retries*retries2*retries3);
        printStatus(data, solverData, eqSystemNumber, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
      /* take the best approximation */
      memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));
    }
  }

  /* reset some solving data */
  solverData->factor = initial_factor;
  solverData->mode = 1;

  /* write statistics */
  systemData->numberOfFEval += solverData->numberOfFunctionEvaluations;
  /* iteration in hybrid are equal to the nfev numbers */
  systemData->numberOfIterations += nfunc_evals;

  free(relationsPreBackup);

  return success;
}

#ifdef __cplusplus
}
#endif
