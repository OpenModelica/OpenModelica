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

/*! \file nonlinearSolverNewton.c
 */

#ifdef __cplusplus
extern "C" {
#endif

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "simulation/simulation_info_xml.h"
#include "util/omc_error.h"
#include "util/varinfo.h"
#include "model_help.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverNewton.h"
#include "newtonIteration.h"

#include "external_input.h"


extern double enorm_(int *n, double *x);
int wrapper_fvec_newton(int* n, double* x, double* fvec, void* userdata, int fj);


#ifdef __cplusplus
extern "C" {
#endif

extern int dgesv_(int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);

#ifdef __cplusplus
}
#endif


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
int getAnalyticalJacobianNewton(DATA* data, double* jac, int sysNumber)
{
  int i,j,k,l,ii,currentSys = sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);
  const int index = systemData->jacobianIndex;

  memset(jac, 0, (solverData->n)*(solverData->n)*sizeof(double));

  for(i=0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1;

    systemData->analyticalJacobianColumn(data);

    for(j = 0; j < data->simulationInfo.analyticJacobians[index].sizeCols; j++)
    {
      if(data->simulationInfo.analyticJacobians[index].seedVars[j] == 1)
      {
        if(j==0)
          ii = 0;
        else
          ii = data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j-1];
        while(ii < data->simulationInfo.analyticJacobians[index].sparsePattern.leadindex[j])
        {
          l  = data->simulationInfo.analyticJacobians[index].sparsePattern.index[ii];
          k  = j*data->simulationInfo.analyticJacobians[index].sizeRows + l;
          jac[k] = data->simulationInfo.analyticJacobians[index].resultVars[l];
          ii++;
        };
      }
      /* de-activate seed variable for the corresponding color */
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[j]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[j] = 0;
    }

  }

  return 0;
}


/*! \fn wrapper_fvec_newton for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *	fj decides whether the function values or the jacobian matrix shall be calculated
 *  fj = 1 ==> calculate function values
 *   fj = 0 ==> calculate jacobian matrix
 */
int wrapper_fvec_newton(int* n, double* x, double* fvec, void* userdata, int fj)
{
  DATA_USER* uData = (DATA_USER*) userdata;
  DATA* data = (DATA*)(uData->data);
  int currentSys = ((DATA_USER*)userdata)->sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);
  int flag = 1;
  int *iflag=&flag;

  if (fj)
  {
    (data->simulationInfo.nonlinearSystemData[currentSys].residualFunc)(data, x, fvec, iflag);
  }
  else
  {
    if(systemData->jacobianIndex != -1)
    {
      getAnalyticalJacobianNewton(data, solverData->fjac, currentSys);
    }
    else
    {
      double delta_h = sqrt(solverData->epsfcn);
      double delta_hh;
      double xsave;

      int i,j,l, linear=0;
      linear = systemData->method;

      for(i = 0; i < *n; i++)
      {
        if(linear)
        {
          delta_hh = 1;
        }
        else
        {

          delta_hh = fmax(delta_h * fmax(fabs(x[i]), fabs(fvec[i])), delta_h);
          delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
          delta_hh = x[i] + delta_hh - x[i];
        }
        xsave = x[i];
        x[i] += delta_hh;
        delta_hh = 1. / delta_hh;

        wrapper_fvec_newton(n, x, solverData->rwork, userdata, 1);
        solverData->nfev++;

        for(j = 0; j < *n; j++)
        {
          l = i * *n + j;
          solverData->fjac[l] = (solverData->rwork[j] - fvec[j]) * delta_hh;
        }
        x[i] = xsave;
      }
    }
  }
  return *iflag;
}

/*! \fn solve non-linear system with newton method
 *
 *  \param [in]  [data]
 *                [sysNumber] index of the corresponding non-linear system
 *
 *  \author wbraun
 */
int solveNewton(DATA *data, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);
  int eqSystemNumber = 0;
  int i;
  double xerror = -1, xerror_scaled = -1;
  int success = 0;
  int nfunc_evals = 0;
  int continuous = 1;
  double local_tol = solverData->ftol;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int nonContinuousCase = 0;
  modelica_boolean *relationsPreBackup = NULL;
  int casualTearingSet = data->simulationInfo.nonlinearSystemData[sysNumber].strictTearingFunctionCall != NULL;

  DATA_USER* userdata = (DATA_USER*)malloc(sizeof(DATA_USER));
  assert(userdata != NULL);

  userdata->data = (void*)data;
  userdata->sysNumber = sysNumber;

  /*
   * We are given the number of the non-linear system.
   * We want to look it up among all equations.
   */
  eqSystemNumber = systemData->equationIndex;

  local_tol = solverData->ftol;

  relationsPreBackup = (modelica_boolean*) malloc(data->modelData.nRelations*sizeof(modelica_boolean));

  solverData->nfev = 0;

  /* try to calculate jacobian only once at the beginning of the iteration */
  solverData->calculate_jacobian = 0;

  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    int indexes[2] = {1,eqSystemNumber};
    infoStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "Start solving Non-Linear System %d at time %g with Newton Solver",
        eqSystemNumber, data->localData[0]->timeValue);

    for(i = 0; i < solverData->n; i++)
    {
      infoStreamPrint(LOG_NLS_V, 1, "x[%d] = %.15e", i, data->simulationInfo.discreteCall ? systemData->nlsx[i] : systemData->nlsxExtrapolation[i]);
      infoStreamPrint(LOG_NLS_V, 0, "nominal = %g +++ nlsx = %g +++ old = %g +++ extrapolated = %g",
          systemData->nominal[i], systemData->nlsx[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      messageClose(LOG_NLS_V);
    }
    messageClose(LOG_NLS_V);
  }

  /* set x vector */
  if(data->simulationInfo.discreteCall)
    memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
  else
    memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  /* start solving loop */
  while(!giveUp && !success)
  {

    giveUp = 1;
    solverData->newtonStrategy = data->simulationInfo.newtonStrategy;
    _omc_newton(wrapper_fvec_newton, solverData, (void*)userdata);

    /* check for proper inputs */
    if(solverData->info == 0)
      printErrorEqSyst(IMPROPER_INPUT, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);

    /* reset non-contunuousCase */
    if(nonContinuousCase && xerror > local_tol && xerror_scaled > local_tol)
    {
      memcpy(data->simulationInfo.relationsPre, relationsPreBackup, sizeof(modelica_boolean)*data->modelData.nRelations);
      nonContinuousCase = 0;
    }

    /* check for error  */
    xerror_scaled = enorm_(&solverData->n, solverData->fvecScaled);
    xerror = enorm_(&solverData->n, solverData->fvec);

    /* solution found */
    if((xerror <= local_tol || xerror_scaled <= local_tol) && solverData->info > 0)
    {
      success = 1;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, "*** System solved ***\n%d restarts", retries);
        infoStreamPrint(LOG_NLS, 0, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        for(i = 0; i < solverData->n; i++)
          infoStreamPrint(LOG_NLS, 0, "x[%d] = %.15e\n\tresidual = %e", i, solverData->x[i], solverData->fvec[i]);
      }

      /* take the solution */
      memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));

      /* Then try with old values (instead of extrapolating )*/
    }
    else if(retries < 1 && casualTearingSet)
    {
      giveUp = 1;
      infoStreamPrint(LOG_NLS, 0, "### No Solution for the casual tearing set at the first try! ###");
    }
    else if(retries < 1)
    {
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try old values.");
      /* try to vary the initial values */

      /* evaluate jacobian in every step now */
      solverData->calculate_jacobian = 1;
    }
    else if(retries < 2)
    {
      for(i = 0; i < solverData->n; i++)
        solverData->x[i] += systemData->nominal[i] * 0.01;
      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t vary solution point by 1%%.");
      /* try to vary the initial values */
    }
    else if(retries < 3)
    {
      for(i = 0; i < solverData->n; i++)
        solverData->x[i] = systemData->nominal[i];
      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try nominal values as initial solution.");
    }
    else if(retries < 4  && data->simulationInfo.discreteCall)
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
      memcpy(relationsPreBackup, data->simulationInfo.relationsPre, sizeof(modelica_boolean)*data->modelData.nRelations);

      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try to solve a discontinuous system.");
    }
    else if(retries2 < 4)
    {
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));
      /* reduce tolarance */
      local_tol = local_tol*10;

      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t reduce the tolerance slightly to %e.", local_tol);
    }
    else
    {
      printErrorEqSyst(ERROR_AT_TIME, modelInfoGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, "### No Solution! ###\n after %d restarts", retries);
        infoStreamPrint(LOG_NLS, 0, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        if(ACTIVE_STREAM(LOG_NLS))
          for(i = 0; i < solverData->n; i++)
            infoStreamPrint(LOG_NLS, 0, "x[%d] = %.15e\n\tresidual = %e", i, solverData->x[i], solverData->fvec[i]);
      }
    }
  }
  if(ACTIVE_STREAM(LOG_NLS))
    messageClose(LOG_NLS);

  free(relationsPreBackup);

  /* write statistics */
  systemData->numberOfFEval = solverData->numberOfFunctionEvaluations;
  systemData->numberOfIterations = solverData->numberOfIterations;

  return success;
}