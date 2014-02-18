/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file nonlinear_solver.c
 */

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "simulation_info_xml.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"
#include "memory_pool.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverHybrd.h"
extern doublereal enorm_(integer *n, doublereal *x);

typedef struct DATA_HYBRD
{
  int initialized; /* 1 = initialized, else = 0*/
  double* resScaling;
  int useXScaling;
  double* xScalefactors;
  double* fvecScaled;

  integer n;
  double* x;
  double* fvec;
  double xtol;
  integer maxfev;
  int ml;
  int mu;
  double epsfcn;
  double* diag;
  double* diagres;
  integer mode;
  double factor;
  integer nprint;
  integer info;
  integer nfev;
  integer njev;
  double* fjac;
  double* fjacobian;
  integer ldfjac;
  double* r__;
  integer lr;
  double* qtf;
  double* wa1;
  double* wa2;
  double* wa3;
  double* wa4;

} DATA_HYBRD;

static int wrapper_fvec_hybrj(integer* n, double* x, double* f, double* fjac, integer* ldjac, integer* iflag, void* data, int sysNumber);

/*! \fn allocate memory for nonlinear system solver hybrd
 *
 */
int allocateHybrdData(int size, void** voiddata)
{
  DATA_HYBRD* data = (DATA_HYBRD*) malloc(sizeof(DATA_HYBRD));

  *voiddata = (void*)data;
  assertStreamPrint(0 != data, "allocationHybrdData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));
  data->useXScaling = 1;
  data->xScalefactors = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc(size*sizeof(double));
  data->fvec = (double*) calloc(size, sizeof(double));
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
  data->fjac = (double*) calloc((size*size), sizeof(double));
  data->fjacobian = (double*) calloc((size*size), sizeof(double));
  data->ldfjac = size;
  data->r__ = (double*) malloc(((size*(size+1))/2)*sizeof(double));
  data->lr = (size*(size + 1)) / 2;
  data->qtf = (double*) malloc(size*sizeof(double));
  data->wa1 = (double*) malloc(size*sizeof(double));
  data->wa2 = (double*) malloc(size*sizeof(double));
  data->wa3 = (double*) malloc(size*sizeof(double));
  data->wa4 = (double*) malloc(size*sizeof(double));

  assertStreamPrint(0 != *voiddata, "allocationHybrdData() voiddata failed!");
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
  free(data->fvec);
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
static void printVector(const double *vector, integer *size, const int logLevel, const char *name)
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
static void printStatus(DATA_HYBRD *solverData, const int *nfunc_evals, const double *xerror, const double *xerror_scaled, const int logLevel)
{
  int i;

  if (!ACTIVE_STREAM(logLevel)) return;
  infoStreamPrint(logLevel, 1, "nls status");

  infoStreamPrint(logLevel, 1, "variables");
  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logLevel, 0, "x[%d] = %.20e [scaling factor = %16e]", i, solverData->x[i], solverData->diag[i]);
  messageClose(logLevel);

  infoStreamPrint(logLevel, 1, "functions");
  for(i=0; i<solverData->n; i++)
    infoStreamPrint(logLevel, 0, "res[%d] = %.20e [scaling factor = %16e]", i, solverData->fvec[i], solverData->resScaling[i]);
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
static int getNumericalJacobian(DATA* data, double* jac, double* x, double* f, int sysNumber)
{
  int currentSys = sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);

  double delta_h = sqrt(solverData->epsfcn);
  double delta_hh, delta_hhh, deltaInv;
  double xsave;
  integer iflag = 1;
  int i, j, l;

  for(i = 0; i < solverData->n ; ++i)
  {
    delta_hhh = solverData->epsfcn * f[i];
    delta_hh = fmax(delta_h * fmax(abs(x[i]), abs(delta_hhh)), delta_h);
    delta_hh = ((f[i] >= 0) ? delta_hh : -delta_hh);
    delta_hh = x[i] + delta_hh - x[i];
    deltaInv = 1. / delta_hh;
    xsave = x[i];
    x[i] += delta_hh;

    wrapper_fvec_hybrj(&solverData->n, x, solverData->wa1, solverData->fjacobian, &solverData->ldfjac, &iflag, data, sysNumber);

    for(j = 0; j < solverData->n; ++j)
    {
      l = i*solverData->n+j;
      solverData->fjacobian[l] = jac[l] = (solverData->wa1[j] - f[j]) * deltaInv;
    }
    x[i] = xsave;
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
static int getAnalyticalJacobian(DATA* data, double* jac, int sysNumber)
{
  int i, j, k, l, ii, currentSys = sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);
  const int index = systemData->jacobianIndex;

  memset(jac, 0, (solverData->n)*(solverData->n)*sizeof(double));
  memset(solverData->fjacobian, 0, (solverData->n)*(solverData->n)*sizeof(double));

  for(i=0; i < data->simulationInfo.analyticJacobians[index].sparsePattern.maxColors; i++)
  {
    /* activate seed variable for the corresponding color */
    for(ii=0; ii < data->simulationInfo.analyticJacobians[index].sizeCols; ii++)
      if(data->simulationInfo.analyticJacobians[index].sparsePattern.colorCols[ii]-1 == i)
        data->simulationInfo.analyticJacobians[index].seedVars[ii] = 1;

    ((systemData->analyticalJacobianColumn))(data);

    for(j=0; j<data->simulationInfo.analyticJacobians[index].sizeCols; j++)
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
          solverData->fjacobian[k] = jac[k] = data->simulationInfo.analyticJacobians[index].resultVars[l];
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

/*! \fn wrapper function of the residual Function
 *   non-linear solver calls this subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
static int wrapper_fvec_hybrj(integer* n, double* x, double* f, double* fjac, integer* ldjac, integer* iflag, void* data, int sysNumber)
{
  int i,j;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[sysNumber]);
  DATA_HYBRD* solverData = (DATA_HYBRD*)(systemData->solverData);
  int continuous = ((DATA*)data)->simulationInfo.solveContinuous;

  switch(*iflag)
  {
  case 1:
    /* re-scaling x vector */
    if(solverData->useXScaling)
      for(i=0; i<*n; i++)
        x[i] = x[i]*solverData->xScalefactors[i];

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_RES)) {
      infoStreamPrint(LOG_NLS_RES, 0, "-- residual function call %d --", solverData->nfev);
      printVector(x, n, LOG_NLS_RES, "x vector");
    }
        
    /* call residual function */
    (systemData->residualFunc)(data, x, f, iflag);

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_RES)) {
      printVector(f, n, LOG_NLS_RES, "residuals");
      infoStreamPrint(LOG_NLS_RES, 0, "-- end of residual function call %d --", solverData->nfev);
    }
    
    /* Scaling x vector */
    if(solverData->useXScaling)
      for(i=0; i<*n; i++)
        x[i] = (1.0/solverData->xScalefactors[i]) * x[i];
    break;

  case 2:
    /* set residual function continuous for jacobian calculation */
    if(continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 0;

    if(ACTIVE_STREAM(LOG_NLS_RES))
      infoStreamPrint(LOG_NLS_RES, 0, "-- begin calculating jacobian --");
      
    /* call apropreated jacobain function */
    if(systemData->jacobianIndex != -1)
      getAnalyticalJacobian(data, fjac, sysNumber);
    else
      getNumericalJacobian(data, fjac, x, f, sysNumber);

    if (ACTIVE_STREAM(LOG_NLS_RES)) {
      infoStreamPrint(LOG_NLS_RES, 0, "-- end calculating jacobian --");
      
      if(ACTIVE_STREAM(LOG_NLS_JAC))
      {
        char buffer[16384];
        infoStreamPrint(LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", *n, *n);
        for(i=0; i<*n; i++)
        {
          buffer[0] = 0;
          for(j=0; j<*n; j++)
            sprintf(buffer, "%s%20.12g ", buffer, fjac[i*solverData->n+j]);
          infoStreamPrint(LOG_NLS_JAC, 0, "%s", buffer);
        }
        messageClose(LOG_NLS_JAC);
      }
    }
    /* reset residual function again */
    if(continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 1;
    break;

  default:
    throwStreamPrint(&(((DATA*)data)->simulationInfo.errorHandler.globalJumpBuffer), "Well, this is embarrasing. The non-linear solver should never call this case.%d", *iflag);
    break;
  }
  
  return 0;
}

/*! \fn solve non-linear system with hybrd method
 *
 *  \param [in]  [data]
 *                [sysNumber] index of the corresponing non-linear system
 *
 *  \author wbraun
 */
int solveHybrd(DATA *data, int sysNumber)
{
  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
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

  jmp_buf backupJmpbufer;

  modelica_boolean* relationsPreBackup;
  relationsPreBackup = (modelica_boolean*) malloc(data->modelData.nRelations*sizeof(modelica_boolean));

  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS))
  {
    infoStreamPrint(LOG_NLS, 1, "start solving non-linear system >>%s<< at time %g",
      modelInfoXmlGetEquation(&data->modelData.modelDataXml, eqSystemNumber, &(data->simulationInfo.errorHandler.globalJumpBuffer)).name,
      data->localData[0]->timeValue);
    for(i=0; i<solverData->n; i++)
    {
      infoStreamPrint(LOG_NLS, 1, "x[%d] = %f", i, systemData->nlsx[i]);
      infoStreamPrint(LOG_NLS, 0, "scaling = %f\nold = %f\nextrapolated = %f",
            systemData->nominal[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      messageClose(LOG_NLS);
    }
    messageClose(LOG_NLS);
  }

  /* set x vector */
  if(data->simulationInfo.discreteCall)
    memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
  else
    memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  for(i=0; i<solverData->n; i++)
    solverData->xScalefactors[i] = fmax(fabs(solverData->x[i]), systemData->nominal[i]);

  /* evaluate with discontinuities */
  {
    int scaling = solverData->useXScaling;
    if(scaling)
      solverData->useXScaling = 0;
#ifndef OMC_EMCC
    /* try */
    memcpy(data->simulationInfo.errorHandler.simulationJumpBuffer, backupJmpbufer, sizeof(jmp_buf));
    if(!setjmp(data->simulationInfo.errorHandler.simulationJumpBuffer))
    {
#endif
      wrapper_fvec_hybrj(&solverData->n, solverData->x, solverData->fvec, solverData->fjac, &solverData->ldfjac, &iflag, data, sysNumber);
#ifndef OMC_EMCC
    } else { /* catch */
      warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");
    }
    memcpy(data->simulationInfo.errorHandler.simulationJumpBuffer, backupJmpbufer, sizeof(jmp_buf));
#endif
    if(scaling) {
      solverData->useXScaling = 1;
    }
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
      ((DATA*)data)->simulationInfo.solveContinuous = 1;
    } else {
      ((DATA*)data)->simulationInfo.solveContinuous = 0;
    }

    giveUp = 1;

    /* try */
#ifndef OMC_EMCC
    memcpy(data->simulationInfo.errorHandler.simulationJumpBuffer, backupJmpbufer, sizeof(jmp_buf));
    if(!setjmp(data->simulationInfo.errorHandler.simulationJumpBuffer))
    {
#endif
      _omc_hybrj_(wrapper_fvec_hybrj, &solverData->n, solverData->x,
          solverData->fvec, solverData->fjac, &solverData->ldfjac, &solverData->xtol,
          &solverData->maxfev, solverData->diag, &solverData->mode,
          &solverData->factor, &solverData->nprint, &solverData->info,
          &solverData->nfev, &solverData->njev, solverData->r__,
          &solverData->lr, solverData->qtf, solverData->wa1,
          solverData->wa2, solverData->wa3, solverData->wa4, data, sysNumber);
#ifndef OMC_EMCC
      if(assertCalled) {
        infoStreamPrint(LOG_NLS, 0, "After assertions failed, found a solution for which assertions did not fail.");
        memcpy(systemData->nlsxOld, solverData->x, solverData->n*(sizeof(double)));
      }
      assertRetries = 0;
      assertCalled = 0;
    }
    else
    { /* catch */
      if(!assertMessage)
      {
        if (ACTIVE_WARNING_STREAM(LOG_STDOUT)) {
          warningStreamPrint(LOG_STDOUT, 1, "While solving non-linear system an assertion failed.");
          warningStreamPrint(LOG_STDOUT, 0, "The non-linear solver tries to solve the problem that could take some time.");
          warningStreamPrint(LOG_STDOUT, 0, "It could help to provide better start-values for the iteration variables.");
          if (!ACTIVE_STREAM(LOG_NLS)) {
            warningStreamPrint(LOG_STDOUT, 0, "For more information simulate with -lv LOG_NLS");
          }
          messageClose(LOG_STDOUT);
        }
        assertMessage = 1;
      }

      solverData->info = -1;
      xerror_scaled = 1;
      xerror = 1;
      assertCalled = 1;
    }
    memcpy(data->simulationInfo.errorHandler.simulationJumpBuffer, backupJmpbufer, sizeof(jmp_buf));
#endif

    /* set residual function continuous */
    if(continuous)
    {
      ((DATA*)data)->simulationInfo.solveContinuous = 0;
    }
    else
    {
      ((DATA*)data)->simulationInfo.solveContinuous = 1;
    }

    /* re-scaling x vector */
    if(solverData->useXScaling)
      for(i=0; i<solverData->n; i++)
        solverData->x[i] = solverData->x[i]*solverData->xScalefactors[i];

    /* check for proper inputs */
    if(solverData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, modelInfoXmlGetEquation(&data->modelData.modelDataXml, eqSystemNumber, &(data->simulationInfo.errorHandler.globalJumpBuffer)),
          data->localData[0]->timeValue);
    }

    if(solverData->info != -1)
    {
      /* evaluate with discontinuities */
      if(data->simulationInfo.discreteCall){
        int scaling = solverData->useXScaling;
        if(scaling)
          solverData->useXScaling = 0;

        ((DATA*)data)->simulationInfo.solveContinuous = 0;

        /* try */
#ifndef OMC_EMCC
        if(!setjmp(nonlinearJmpbuf))
        {
#endif
          wrapper_fvec_hybrj(&solverData->n, solverData->x, solverData->fvec, solverData->fjac, &solverData->ldfjac, &iflag, data, sysNumber);
#ifndef OMC_EMCC
        } else { /* catch */
          warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

          solverData->info = -1;
          xerror_scaled = 1;
          xerror = 1;
          assertCalled = 1;
        }
#endif

        if(scaling)
          solverData->useXScaling = 1;

        storeRelations(data);
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
          char buffer[4096];

          infoStreamPrint(LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", (int)solverData->n, (int)solverData->n);
          for(i=0; i<solverData->n; i++)
          {
            buffer[0] = 0;
            for(j=0; j<solverData->n; j++)
              sprintf(buffer, "%s%10g ", buffer, solverData->fjacobian[i*solverData->n+j]);
            infoStreamPrint(LOG_NLS_JAC, 0, "%s", buffer);
          }
          messageClose(LOG_NLS_JAC);
        }

        /* check for error  */
        xerror_scaled = enorm_(&solverData->n, solverData->fvecScaled);
        xerror = enorm_(&solverData->n, solverData->fvec);
      }
    }

    /* reset non-contunuousCase */
    if(nonContinuousCase && xerror > local_tol && xerror_scaled > local_tol)
    {
      memcpy(data->simulationInfo.relationsPre, relationsPreBackup, sizeof(modelica_boolean)*data->modelData.nRelations);
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
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 1, "system solved");
        infoStreamPrint(LOG_NLS, 0, "%d retries\n%d restarts", retries, retries2+retries3);
        messageClose(LOG_NLS);

        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS);

      }
      scaling = solverData->useXScaling;
      if(scaling)
        solverData->useXScaling = 0;

      /* take the solution */
      memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));
 
      /* try */
#ifndef OMC_EMCC
      if(!setjmp(nonlinearJmpbuf))
      {
#endif
        wrapper_fvec_hybrj(&solverData->n, solverData->x, solverData->fvec, solverData->fjac, &solverData->ldfjac, &iflag, data, sysNumber);
#ifndef OMC_EMCC
      }
      else
      { /* catch */
        warningStreamPrint(LOG_STDOUT, 0, "Non-Linear Solver try to handle a problem with a called assert.");

        solverData->info = 4;
        xerror_scaled = 1;
        xerror = 1;
        assertCalled = 1;
        success = 0;
        giveUp = 0;
      }
#endif
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
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, " - try to handle a problem with a called assert vary initial value a bit. (Retry: %d)",assertRetries);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 3)
    {
      /* first try to decrease factor */

      /* set x vector */
      if(data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      solverData->factor = solverData->factor / 10.0;

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t decreasing initial step bound to %f.", solverData->factor);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
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

      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, "iteration making no progress:\t vary solution point by 1%%.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 5)
    {
      /* try old values as x-Scaling factors */

      /* set x vector */
      if(data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));


      for(i=0; i<solverData->n; i++)
        solverData->xScalefactors[i] = fmax(fabs(systemData->nlsxOld[i]), systemData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, "iteration making no progress:\t try old values as scaling factors.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 6)
    {
      int scaling = 0;
      /* try to disable x-Scaling */

      /* set x vector */
      if(data->simulationInfo.discreteCall)
        memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
      else
        memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

      scaling = solverData->useXScaling;
      if(scaling)
        solverData->useXScaling = 0;

      /* reset x-scalling factors */
      for(i=0; i<solverData->n; i++)
        solverData->xScalefactors[i] = fmax(fabs(solverData->x[i]), systemData->nominal[i]);

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;

      if(ACTIVE_STREAM(LOG_NLS))
      {
        infoStreamPrint(LOG_NLS, 0, "iteration making no progress:\t try without scaling at all.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    }
    else if((solverData->info == 4 || solverData->info == 5) && retries < 7  && data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try to solve a discontinuous system.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t use old values instead extrapolated.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 2) {
      /* set x vector */
      if(data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0,
            " - iteration making no progress:\t vary initial point by adding 1%%.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 3) {
      /* set x vector */
      if(data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t vary initial point by -1%%.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to vary the initial values */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 4) {
      /* set x vector */
      memcpy(solverData->x, systemData->nominal, solverData->n*(sizeof(double)));
      retries = 0;
      retries2++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try scaling factor as initial point.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try own scaling factors */
    } else if((solverData->info == 4 || solverData->info == 5) && retries2 < 5 && !assertCalled) {
      /* set x vector */
      if(data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try with own scaling factors.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try without internal scaling */
    } else if((solverData->info == 4 || solverData->info == 5) && retries3 < 1) {
      /* set x vector */
      if(data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t disable solver internal scaling.");
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    /* try to reduce the tolerance a bit */
    } else if((solverData->info == 4 || solverData->info == 5) && retries3 < 6) {
      /* set x vector */
      if(data->simulationInfo.discreteCall)
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
      if(ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t reduce the tolerance slightly to %e.", local_tol);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS_V);
      }
    } else if(solverData->info >= 2 && solverData->info <= 5) {

      /* while the initialization it's ok to every time a solution */
      if(!data->simulationInfo.initial){
        printErrorEqSyst(ERROR_AT_TIME, modelInfoXmlGetEquation(&data->modelData.modelDataXml, eqSystemNumber, &(data->simulationInfo.errorHandler.globalJumpBuffer)), data->localData[0]->timeValue);
      }
      if (ACTIVE_STREAM(LOG_NLS)) {
        infoStreamPrint(LOG_NLS, 0, "### No Solution! ###\n after %d restarts", retries*retries2*retries3);
        printStatus(solverData, &nfunc_evals, &xerror, &xerror_scaled, LOG_NLS);
      }
      /* take the best approximation */
      memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));
    }
  }

  /* reset some solving data */
  solverData->factor = initial_factor;
  solverData->mode = 1;

  free(relationsPreBackup);

  return success;
}
