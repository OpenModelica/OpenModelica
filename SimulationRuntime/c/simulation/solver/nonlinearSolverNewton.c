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

#include "nonlinearSystem.h"
#include "nonlinearSolverNewton.h"
#include "f2c.h"
extern doublereal enorm_(integer *n, doublereal *x);

typedef struct DATA_NEWTON
{
  int initialized; /* 1 = initialized, else = 0*/
  double* resScaling;
  double* fvecScaled;

  integer n;
  double* x;
  double* fvec;
  double xtol;
  double ftol;
  integer nfev;
  integer maxfev;
  integer info;
  double epsfcn;
  double* fjac;
  double* rwork;
  integer* iwork;
} DATA_NEWTON;


static int _omc_newton(integer* n, double *x, double *fvec, double* eps, double* fdeps, integer* maxfev,
                       integer* nfev, int(*f)(integer*, double*, double*, integer*, void*, int),
                       double* fjac, double* rwork, integer* iwork,
                       integer* info, void* userdata, int sysNumber);

#ifdef __cplusplus
extern "C" {
#endif

extern int dgesv_(integer *n, integer *nrhs, doublereal *a, integer *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

#ifdef __cplusplus
}
#endif

/*! \fn allocateNewtonData
 * allocate memory for nonlinear system solver
 */
int allocateNewtonData(int size, void** voiddata)
{
  DATA_NEWTON* data = (DATA_NEWTON*) malloc(sizeof(DATA_NEWTON));

  *voiddata = (void*)data;
  ASSERT(data, "allocationNewtonData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc(size*sizeof(double));
  data->fvec = (double*) calloc(size,sizeof(double));
  data->xtol = 1e-8;
  data->ftol = 1e-8;
  data->maxfev = size*100;
  data->epsfcn = DBL_EPSILON;
  data->fjac = (double*) malloc((size*size)*sizeof(double));

  data->rwork = (double*) malloc((size)*sizeof(double));
  data->iwork = (integer*) malloc(size*sizeof(integer));

  ASSERT(*voiddata, "allocationNewtonData() voiddata failed!");
  return 0;
}

/*! \fn freeNewtonData
 *
 * free memory for nonlinear solver newton
 *
 */
int freeNewtonData(void **voiddata)
{
  DATA_NEWTON* data = (DATA_NEWTON*) *voiddata;

  free(data->resScaling);
  free(data->fvecScaled);
  free(data->x);
  free(data->fvec);
  free(data->fjac);
  free(data->rwork);
  free(data->iwork);

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

    ((systemData->analyticalJacobianColumn))(data);

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


/*! \fn wrapper_fvec_hybrd for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
static int wrapper_fvec_newton(integer* n, double* x, double* f, integer* iflag, void* data, int sysNumber)
{
  int currentSys = sysNumber;
  /* NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]); */
  /* DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData); */

  (*((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys].residualFunc)(data, x, f, iflag);
  return 0;
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
  /*
   * We are given the number of the non-linear system.
   * We want to look it up among all equations.
   */
  int eqSystemNumber = systemData->equationIndex;

  int i;
  double xerror, xerror_scaled;
  int success = 0;
  int nfunc_evals = 0;
  int continuous = 1;

  int giveUp = 0;
  int retries = 0;

  solverData->nfev = 0;

  /* set x vector */
  memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS))
  {
    INFO2(LOG_NLS, "Start solving Non-Linear System %s at time %g with Newton Solver",
        modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber).name,
        data->localData[0]->timeValue);

    INDENT(LOG_NLS);
    for(i = 0; i < solverData->n; i++)
    {
      INDENT(LOG_NLS);
      INFO2(LOG_NLS, "x[%d] = %.15e", i, systemData->nlsx[i]);
      INDENT(LOG_NLS);
      INFO3(LOG_NLS, "scaling = %f +++ old = %e +++ extrapolated = %e",
            systemData->nominal[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      RELEASE(LOG_NLS);
      RELEASE(LOG_NLS);
    }
  }

  /* start solving loop */
  while(!giveUp && !success)
  {
    /* set residual function continuous */
    if(continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 1; //TODO: Handle non global
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 0;

    giveUp = 1;
    _omc_newton(&solverData->n, solverData->x, solverData->fvec, &solverData->xtol,
                &solverData->epsfcn, &solverData->maxfev, &solverData->nfev,
                wrapper_fvec_newton, solverData->fjac, solverData->rwork,
                solverData->iwork, &solverData->info, data, sysNumber);

    /* set residual function continuous */
    if(continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 0;
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 1;

    /* check for proper inputs */
    if(solverData->info == 0)
      printErrorEqSyst(IMPROPER_INPUT, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);

    /* check for error  */
    xerror_scaled = enorm_(&solverData->n, solverData->resScaling);
    xerror = enorm_(&solverData->n, solverData->fvec);
    
    /* solution found */
    if((xerror <= solverData->ftol || xerror_scaled <= solverData->ftol) && solverData->info > 0)
    {
      success = 1;
      nfunc_evals += solverData->nfev;
      if(ACTIVE_STREAM(LOG_NLS))
      {
        INFO1(LOG_NLS, "*** System solved ***\n%d restarts", retries);
        INFO3(LOG_NLS, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        for(i = 0; i < solverData->n; i++)
          INFO3(LOG_NLS, "x[%d] = %.15e\n\tresidual = %e", i, solverData->x[i], solverData->fvec[i]);
      }
    /* Then try with old values (instead of extrapolating )*/
    }
    else if(retries < 1)
    {
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      INFO(LOG_NLS, " - iteration making no progress:\t try old values.");
    /* try to vary the initial values */
    }
    else if(retries < 2)
    {
      for(i = 0; i < solverData->n; i++)
        solverData->x[i] += systemData->nominal[i] * 0.01;
      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      INFO(LOG_NLS, " - iteration making no progress:\t vary solution point by 1%%.");
      /* try to vary the initial values */
      }
      else if(retries < 2)
      {
        for(i = 0; i < solverData->n; i++)
          solverData->x[i] = systemData->nominal[i];
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        INFO(LOG_NLS, " - iteration making no progress:\t try nominal values as initial solution.");
    }
    else
    {
      printErrorEqSyst(ERROR_AT_TIME, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);
      if(ACTIVE_STREAM(LOG_NLS))
      {
        INFO1(LOG_NLS, "### No Solution! ###\n after %d restarts", retries);
        INFO3(LOG_NLS, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        if(ACTIVE_STREAM(LOG_NLS))
          for(i = 0; i < solverData->n; i++)
            INFO3(LOG_NLS, "x[%d] = %.15e\n\tresidual = %e", i, solverData->x[i], solverData->fvec[i]);
      }
    }
  }
  
  if(ACTIVE_STREAM(LOG_NLS))
    RELEASE(LOG_NLS);

  /* take the best approximation */
  memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));
  return success;
}

/*! \fn fdjac
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static int fdjac(integer* n, int(*f)(integer*, double*, double*, integer*, void*, int), double *x,
       double* fvec, double *fjac, double* eps, integer* iflag, double* wa,
       void* userdata, int sysNumber)
{
  double delta_h = sqrt(*eps);
  double delta_hh;
  double xsave;

  int i,j,l;

  int currentSys = sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[currentSys]);

  int linear = systemData->method;

  for(i = 0; i < *n; i++) {
    if(linear){
      delta_hh = 1;
    } else {
      delta_hh = delta_h * fmax(1, abs(x[i]));
      delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
      delta_hh = x[i] + delta_hh - x[i];
    }
    xsave = x[i];
    x[i] += delta_hh;
    delta_hh = 1. / delta_hh;
    f(n, x, wa, iflag, userdata, currentSys);

    for(j = 0; j < *n; j++) {
      l = i * *n + j;
      fjac[l] = (wa[j] - fvec[j]) * delta_hh;
    }
    x[i] = xsave;
  }

  return *iflag;
}

/*! \fn solve system with Newton-Raphson
 *
 *  \param [in]  [n] size of equation
 *                [eps] tolerance for x
 *                [h] tolerance for f'
 *                [k] maximum number of iterations
 *                [work] work array size of (n*X)
 *                [f] user provided function
 *                [data] userdata
 *                [info]
 *
 */
static int _omc_newton(integer* n, double *x, double *fvec, double* eps, double* fdeps, integer* maxfev,
                       integer* nfev, int(*f)(integer*, double*, double*, integer*, void*, int),
                       double* fjac, double* work, integer* iwork, integer* info, void* userdata, int sysNumber)
{
  int currentSys = sysNumber;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);

  int i, j, l;
  integer iflag;
  double error_x, error_f, scaledError_f;
  double tol_x = *eps, tol_f = solverData->ftol;
  double *wa;
  integer nrsh = 1;
  integer lapackinfo = 1;

  wa = work;
  l = *maxfev;
  error_x = 1.0 + tol_x;
  error_f = 1.0 + tol_f;
  scaledError_f = 1.0 + tol_f;

  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    INFO1(LOG_NLS_V, "######### Start Newton maxfev: %d #########", (int)*maxfev);
    for(i=0; i<*n; i++)
      INFO2(LOG_NLS_V, "x[%d]: %e ", i, x[i]);
  }
  *info = 1;

  while(*info >= 0)
  {
    DEBUG1(LOG_NLS_V, "**** start Iteration: %d  *****", *maxfev-l);
    /* calculate the function values */
    (*f)(n, x, fvec, &iflag, userdata,currentSys);
    (*nfev)++;

    /*  Debug output */
    if(ACTIVE_STREAM(LOG_NLS_V))
      for(i=0; i<*n; i++)
        DEBUG2(LOG_NLS_V, "fvec[%d]: %e: ", i, fvec[i]);

    /* calculate jacobian */
    if(systemData->jacobianIndex != -1){
      getAnalyticalJacobianNewton(userdata, fjac, currentSys);
    } else {
      fdjac(n, f, x, fvec, fjac, fdeps, &iflag, wa, userdata, currentSys);
      (*nfev)=(*nfev)+*n;
    }

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_JAC))
    {
      char buffer[4096];

      INFO2(LOG_NLS_JAC, "jacobian matrix [%dx%d]", (int)*n, (int)*n);
      INDENT(LOG_NLS_JAC);
      for(i=0; i<solverData->n;i++)
      {
        buffer[0] = 0;
        for(j=0; j<solverData->n; j++)
          sprintf(buffer, "%s%10g ", buffer, fjac[i*(*n)+j]);
        INFO1(LOG_NLS_JAC, "%s", buffer);
      }
      RELEASE(LOG_NLS_JAC);
    }

    /* scaling residual vector */
    {
      int i,j,l=0;
      for(i=0; i<solverData->n; ++i)
      {
        solverData->resScaling[i] = 1e-16;
        for(j=0; j<solverData->n; ++j)
        {
          solverData->resScaling[i] = (fabs(solverData->fjac[l]) > solverData->resScaling[i])
              ? fabs(solverData->fjac[l]) : solverData->resScaling[i];
          l++;
        }
        solverData->fvecScaled[i] = solverData->fvec[i] * (1 / solverData->resScaling[i]);
      }
    }

    /* calculate error by 2-norm */
    scaledError_f = enorm_(n, solverData->fvecScaled);
    error_f = enorm_(n, fvec);
    DEBUG1(LOG_NLS_V, "scaled error = %e", scaledError_f);
    DEBUG1(LOG_NLS_V, "error = %e", error_f);
    if(scaledError_f <= tol_f) break;
    if(error_f <= tol_f) break;

    /* solve J*(x_{n+1} - x_n)=f */
    dgesv_(n, &nrsh, fjac, n, iwork, fvec, n, &lapackinfo);

    if(ACTIVE_STREAM(LOG_NLS_V))
    {
      DEBUG(LOG_NLS_V, "Solved J*x=b");
      for(i=0; i<*n; i++)
        DEBUG2(LOG_NLS_V, "b[%d] = %e ", i, fvec[i]);
    }

    if(lapackinfo > 0)
    {
      *info = -1;
      WARNING(LOG_NLS, "Jacobian Matrix singular!");
    }
    else if(lapackinfo < 0)
    {
      *info = -1;
      WARNING1(LOG_NLS, "illegal  input in argument %d", (int)lapackinfo);
    }
    else
    {
      /* if no error occurs update x vector */
      for(i = 0; i<*n; i++)
        x[i] = x[i] - fvec[i];

      /* break if root convergence if reached */
      error_x = enorm_(n, fvec);
      if(error_x <= tol_x)
        break;
    }

    if(ACTIVE_STREAM(LOG_NLS_V))
      for(i=0; i<*n; i++)
        DEBUG2(LOG_NLS_V, "x[%d] = %e ", i, x[i]);

    /* check if maximum iteration is reached */
    l--;
    if(l < 0)
    {
      *info = -1;
      break;
    }
  }
  return 0;
}
