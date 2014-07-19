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

#include <math.h>
#include <stdlib.h>
#include <string.h> /* memcpy */

#include "simulation_info_xml.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverNewton.h"

extern double enorm_(int *n, double *x);

typedef struct DATA_NEWTON
{
  int initialized; /* 1 = initialized, else = 0*/
  double* resScaling;
  double* fvecScaled;

  int n;
  double* x;
  double* fvec;
  double xtol;
  double ftol;
  int nfev;
  int maxfev;
  int info;
  double epsfcn;
  double* fjac;
  double* rwork;
  int* iwork;
  int numberOfIterations; /* over the whole simulation time */
  int numberOfFunctionEvaluations; /* over the whole simulation time */

  /* damped newton */
  double* x_new;
  double* x_increment;
  double* f_old;
  double* fvec_minimum;
  double* delta_f;
  double* delta_x_vec;


} DATA_NEWTON;


static int _omc_newton(int* n, double *x, double *fvec, double* eps, double* fdeps, int* maxfev,
                       int(*f)(int*, double*, double*, int*, void*, int), double* fjac,
                       double* rwork, int* iwork, int* info, void* userdata, int sysNumber);


int solveLinearSystem(int* n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData);
void calculatingErrors(DATA_NEWTON* solverData, double* delta_x, double* delta_x_scaled, double* delta_f, double* error_f,
        double* scaledError_f, int* n, double* x, double* fvec);
void scaling_residual_vector(DATA_NEWTON* solverData);
void damping_heuristic(void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, double* lambda, int* k);
void damping_heuristic2(double damping_parameter, void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, int* k);
void LineSearch(void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, int* k);
void printErrors(double delta_x, double delta_x_scaled, double delta_f, double error_f, double scaledError_f, double* eps);

#ifdef __cplusplus
extern "C" {
#endif

extern int dgesv_(int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);

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
  assertStreamPrint(NULL, 0 != data, "allocationNewtonData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc(size*sizeof(double));
  data->fvec = (double*) calloc(size,sizeof(double));
  data->xtol = 1e-12;
  data->ftol = 1e-12;
  data->maxfev = size*100;
  data->epsfcn = DBL_EPSILON;
  data->fjac = (double*) malloc((size*size)*sizeof(double));

  data->rwork = (double*) malloc((size)*sizeof(double));
  data->iwork = (int*) malloc(size*sizeof(int));

  /* damped newton */
  data->x_new = (double*) malloc(size*sizeof(double));
  data->x_increment = (double*) malloc(size*sizeof(double));
  data->f_old = (double*) calloc(size,sizeof(double));
  data->fvec_minimum = (double*) calloc(size,sizeof(double));
  data->delta_f = (double*) calloc(size,sizeof(double));
  data->delta_x_vec = (double*) calloc(size,sizeof(double));


  assertStreamPrint(NULL, 0 != *voiddata, "allocationNewtonData() voiddata failed!");
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

  infoStreamPrint(LOG_STATS_V, 0, ":number of function evaluations: %d", (data->numberOfFunctionEvaluations));
  infoStreamPrint(LOG_STATS_V, 0, ":number of iterations: %d", data->numberOfIterations);

  free(data->resScaling);
  free(data->fvecScaled);
  free(data->x);
  free(data->fvec);
  free(data->fjac);
  free(data->rwork);
  free(data->iwork);

  /* damped newton */
  free(data->x_new);
  free(data->x_increment);
  free(data->f_old);
  free(data->fvec_minimum);
  free(data->delta_f);
  free(data->delta_x_vec);

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
static int wrapper_fvec_newton(int* n, double* x, double* f, int* iflag, void* data, int sysNumber)
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
  double xerror = -1, xerror_scaled = -1;
  int success = 0;
  int nfunc_evals = 0;
  int continuous = 1;
  double local_tol = solverData->ftol;

  int giveUp = 0;
  int retries = 0;
  int retries2 = 0;
  int iflag = 1;

  solverData->nfev = 0;

  /* debug output */
  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    int indexes[2] = {1,eqSystemNumber};
    infoStreamPrintWithEquationIndexes(LOG_NLS, 1, indexes, "Start solving Non-Linear System %d at time %g with Newton Solver",
        eqSystemNumber,
        data->localData[0]->timeValue);

    for(i = 0; i < solverData->n; i++)
    {
      infoStreamPrint(LOG_NLS_V, 1, "x[%d] = %.15e", i, systemData->nlsx[i]);
      infoStreamPrint(LOG_NLS_V, 0, "scaling = %f +++ old = %e +++ extrapolated = %e",
            systemData->nominal[i], systemData->nlsxOld[i], systemData->nlsxExtrapolation[i]);
      messageClose(LOG_NLS_V);
    }
    messageClose(LOG_NLS_V);
  }

  /* set x vector */
  if(data->simulationInfo.discreteCall)
    memcpy(solverData->x, systemData->nlsx, solverData->n*(sizeof(double)));
  else
    memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  /* evaluate with discontinuities */
  if(data->simulationInfo.discreteCall){
    ((DATA*)data)->simulationInfo.solveContinuous = 0;
    /* evaluate with discontinuities */
    wrapper_fvec_newton(&solverData->n, solverData->x, solverData->fvec, &iflag, data, sysNumber);
    ((DATA*)data)->simulationInfo.solveContinuous = 1;
  }

  /* start solving loop */
  while(!giveUp && !success)
  {

    giveUp = 1;
    _omc_newton(&solverData->n, solverData->x, solverData->fvec, &local_tol,
                &solverData->epsfcn, &solverData->maxfev,
                wrapper_fvec_newton, solverData->fjac, solverData->rwork,
                solverData->iwork, &solverData->info, data, sysNumber);

    /* check for proper inputs */
    if(solverData->info == 0)
      printErrorEqSyst(IMPROPER_INPUT, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);

    if(solverData->info > 0)
    {
      /* evaluate with discontinuities */
      if(data->simulationInfo.discreteCall)
      {
        ((DATA*)data)->simulationInfo.solveContinuous = 0;
        wrapper_fvec_newton(&solverData->n, solverData->x, solverData->fvec, &iflag, data, sysNumber);

        ((DATA*)data)->simulationInfo.solveContinuous = 1;
        updateRelationsPre(data);
      }
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
      wrapper_fvec_newton(&solverData->n, solverData->x, solverData->fvec, &iflag, data, sysNumber);

    /* Then try with old values (instead of extrapolating )*/
    }
    else if(retries < 1)
    {
      memcpy(solverData->x, systemData->nlsxOld, solverData->n*(sizeof(double)));

      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      infoStreamPrint(LOG_NLS, 0, " - iteration making no progress:\t try old values.");
    /* try to vary the initial values */
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
    else if(retries2 < 3)
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
      printErrorEqSyst(ERROR_AT_TIME, modelInfoXmlGetEquation(&data->modelData.modelDataXml,eqSystemNumber), data->localData[0]->timeValue);
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

  return success;
}

/*! \fn fdjac
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
static int fdjac(int* n, int(*f)(int*, double*, double*, int*, void*, int), double *x,
       double* fvec, double *fjac, double* eps, int* iflag, double* wa,
       void* userdata, int sysNumber)
{
  double delta_h = sqrt(*eps);
  double delta_hh;
  double delta_hhh;
  double xsave;

  int i,j,l;

  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[sysNumber]);

  int linear = systemData->method;

  for(i = 0; i < *n; i++) {
    if(linear){
      delta_hh = 1;
    } else {
      delta_hh = fmax(delta_h * fmax(abs(x[i]), abs(fvec[i])), delta_h);
      delta_hh = ((fvec[i] >= 0) ? delta_hh : -delta_hh);
      delta_hh = x[i] + delta_hh - x[i];
    }
    xsave = x[i];
    x[i] += delta_hh;
    delta_hh = 1. / delta_hh;
    f(n, x, wa, iflag, userdata, sysNumber);

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
static int _omc_newton(int* n, double *x, double *fvec, double* eps, double* fdeps, int* maxfev,
                       int(*f)(int*, double*, double*, int*, void*, int),
                       double* fjac, double* work, int* iwork, int* info, void* userdata, int sysNumber)
{
  DATA* data = (DATA*) userdata;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[sysNumber]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);

  int i, j, k = 0, l = 0, iflag, nrsh = 1;
  double error_f  = 1.0 + *eps, scaledError_f = 1.0 + *eps, delta_x = 1.0 + *eps, delta_f = 1.0 + *eps, delta_x_scaled = 1.0 + *eps, lambda = 1.0;
  double current_fvec_enorm, enorm_new;

  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    infoStreamPrint(LOG_NLS_V, 1, "######### Start Newton maxfev: %d #########", (int)*maxfev);

    infoStreamPrint(LOG_NLS_V, 1, "x vector");
    for(i=0; i<*n; i++)
      infoStreamPrint(LOG_NLS_V, 0, "x[%d]: %e ", i, x[i]);
    messageClose(LOG_NLS_V);
  }

  *info = 1;

  /* calculate the function values */
  (*f)(n, x, fvec, &iflag, userdata,sysNumber);
  solverData->nfev++;

  /* save current fvec in f_old*/
  memcpy(solverData->f_old, fvec, *n*sizeof(double));

  error_f = current_fvec_enorm = enorm_(n, fvec);

  while(error_f > *eps && scaledError_f > *eps  &&  delta_x > *eps  &&  delta_f > *eps  && delta_x_scaled > *eps  )
  {
    if(ACTIVE_STREAM(LOG_NLS_V))
    {
        infoStreamPrint(LOG_NLS_V, 0, "\n**** start Iteration: %d  *****", (int) l);

       /*  Debug output */
       infoStreamPrint(LOG_NLS_V, 1, "function values");
       for(i=0; i<*n; i++)
         infoStreamPrint(LOG_NLS_V, 0, "fvec[%d]: %e ", i, fvec[i]);
       messageClose(LOG_NLS_V);
    }

    /* calculate jacobian */
    if(systemData->jacobianIndex != -1)
    {
      getAnalyticalJacobianNewton(userdata, fjac, sysNumber);
    }
    else
    {
      fdjac(n, f, x, fvec, fjac, fdeps, &iflag, work, userdata, sysNumber);
      solverData->nfev=solverData->nfev+*n;
    }

    /* debug output */
    if(ACTIVE_STREAM(LOG_NLS_JAC))
    {
      char buffer[4096];

      infoStreamPrint(LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", (int)*n, (int)*n);
      for(i=0; i<solverData->n;i++)
      {
        buffer[0] = 0;
        for(j=0; j<solverData->n; j++)
          sprintf(buffer, "%s%10g ", buffer, fjac[i*(*n)+j]);
        infoStreamPrint(LOG_NLS_JAC, 0, "%s", buffer);
      }
      messageClose(LOG_NLS_JAC);
    }

    if (solveLinearSystem(n, iwork, fvec, fjac, solverData) != 0)
    {
        *info=-1;
        break;
    }
    else
    {

        for (i =0; i<*n; i++)
            solverData->x_new[i]=x[i]-solverData->x_increment[i];


        infoStreamPrint(LOG_NLS_V,1,"x_increment");
              for(i=0; i<*n; i++)
                infoStreamPrint(LOG_NLS_V, 0, "x_increment[%d] = %e ", i, solverData->x_increment[i]);
        messageClose(LOG_NLS_V);


        if (data->simulationInfo.newtonStrategy == NEWTON_DAMPED){
          damping_heuristic(userdata, sysNumber, x, f, current_fvec_enorm, n, fvec, &lambda, &k);
        } else if (data->simulationInfo.newtonStrategy == NEWTON_DAMPED2){
          damping_heuristic2(0.75, userdata, sysNumber, x, f, current_fvec_enorm, n, fvec, &k);
        } else if (data->simulationInfo.newtonStrategy == NEWTON_DAMPED_LS){
          LineSearch(userdata, sysNumber, x, f, current_fvec_enorm, n, fvec, &k);
        } else {
          /* calculate new function values */
          (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
          solverData->nfev++;
        }

        calculatingErrors(solverData, &delta_x, &delta_x_scaled, &delta_f, &error_f, &scaledError_f, n, x, fvec);

        /* updating x */
        memcpy(x, solverData->x_new, *n*sizeof(double));

        /* updating f_old */
        memcpy(solverData->f_old, fvec, *n*sizeof(double));

        current_fvec_enorm = error_f;

        /* check if maximum iteration is reached */
        if (++l > *maxfev)
        {
            *info = -1;
            warningStreamPrint(LOG_NLS_V, 0, "Warning: maximal number of iteration reached but no root found");
            break;
        }
    }

    if(ACTIVE_STREAM(LOG_NLS_V))
    {
      infoStreamPrint(LOG_NLS_V,1,"x vector");
      for(i=0; i<*n; i++)
        infoStreamPrint(LOG_NLS_V, 0, "x[%d] = %e ", i, x[i]);
      messageClose(LOG_NLS_V);
      printErrors(delta_x, delta_x_scaled, delta_f, error_f, scaledError_f, eps);
    }

  }

  solverData->numberOfIterations += l;
  solverData->numberOfFunctionEvaluations += solverData->nfev;

  return 0;
}


void printErrors(double delta_x, double delta_x_scaled, double delta_f, double error_f, double scaledError_f, double* eps)
{
    infoStreamPrint(LOG_NLS_V, 1, "errors ");
    infoStreamPrint(LOG_NLS_V, 0, "delta_x = %e \ndelta_x_scaled = %e \ndelta_f = %e \nerror_f = %e \nscaledError_f = %e", delta_x, delta_x_scaled, delta_f, error_f, scaledError_f);

    if (delta_x < *eps)
        infoStreamPrint(LOG_NLS_V, 0, "delta_x reached eps");
    if (delta_x_scaled < *eps)
            infoStreamPrint(LOG_NLS_V, 0, "delta_x_scaled reached eps");
    if (delta_f < *eps)
            infoStreamPrint(LOG_NLS_V, 0, "delta_f reached eps");
    if (error_f < *eps)
            infoStreamPrint(LOG_NLS_V, 0, "error_f reached eps");
    if (scaledError_f < *eps)
            infoStreamPrint(LOG_NLS_V, 0, "scaledError_f reached eps");

    messageClose(LOG_NLS_V);
}

int solveLinearSystem(int* n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData)
{
   int i, nrsh=1, lapackinfo=1;

   /* solve J*(x_{n+1} - x_n)=f */
   dgesv_(n, &nrsh, fjac, n, iwork, fvec, n, &lapackinfo);

   if(lapackinfo > 0)
   {
        warningStreamPrint(LOG_NLS, 0, "Jacobian Matrix singular!");
        return -1;
   }
   else if(lapackinfo < 0)
   {
        warningStreamPrint(LOG_NLS, 0, "illegal  input in argument %d", (int)lapackinfo);
        return -1;
   }
   else
   {
       /* save solution of J*(x_{n+1} - x_n)=f */
       memcpy(solverData->x_increment, fvec, *n*sizeof(double));
   }

   return 0;
}

void calculatingErrors(DATA_NEWTON* solverData, double* delta_x, double* delta_x_scaled, double* delta_f, double* error_f,
        double* scaledError_f, int* n, double* x, double* fvec)
{
    int i=0;
    double scaling_factor;

    /* delta_x = || x_new-x_old || */
    for (i=0; i<*n; i++)
            solverData->delta_x_vec[i] = x[i]-solverData->x_new[i];

    *delta_x = enorm_(n,solverData->delta_x_vec);

    scaling_factor = enorm_(n,x);
    if (scaling_factor > 1)
        *delta_x_scaled = *delta_x * 1./ scaling_factor;
    else
        *delta_x_scaled = *delta_x;

    /* delta_f = || f_old - f_new || */
    for (i=0; i<*n; i++)
        solverData->delta_f[i] = solverData->f_old[i]-fvec[i];

    *delta_f=enorm_(n, solverData->delta_f);

    *error_f = enorm_(n,fvec);

    /* scaling residual vector */
    scaling_residual_vector(solverData);

    for (i=0; i<*n; i++)
        solverData->fvecScaled[i]=fvec[i]/solverData->resScaling[i];
    *scaledError_f = enorm_(n,solverData->fvecScaled);

}

void scaling_residual_vector(DATA_NEWTON* solverData)
{
    int i,j,k;
    for(i=0, k=0; i<solverData->n; i++)
    {
        solverData->resScaling[i] = 0.0;
        for(j=0; j<solverData->n; j++, ++k)
        {
          solverData->resScaling[i] = fmax(fabs(solverData->fjac[k]), solverData->resScaling[i]);
        }
        if(solverData->resScaling[i] <= 0.0){
          warningStreamPrint(LOG_NLS_V, 1, "Jacobian matrix is singular.");
          solverData->resScaling[i] = 1e-16;
        }
        solverData->fvecScaled[i] = solverData->fvec[i] / solverData->resScaling[i];
    }
}

void damping_heuristic(void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, double* lambda, int* k)
{
    int i,j=0, iflag;
    double enorm_new, treshold = 1e-2;


    NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[sysNumber]);
    DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);


    /* calculate new function values */
    (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
    solverData->nfev++;

    enorm_new=enorm_(n,fvec);

    if (enorm_new >= current_fvec_enorm)
        infoStreamPrint(LOG_NLS_V, 1, "Start Damping: enorm_new : %e; current_fvec_enorm: %e ", enorm_new, current_fvec_enorm);

    while (enorm_new >= current_fvec_enorm)
    {
        j++;

        *lambda*=0.5;


        for (i=0; i<*n; i++)
            solverData->x_new[i]=x[i]-*lambda*solverData->x_increment[i];


        /* calculate new function values */
        (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
        solverData->nfev++;

        enorm_new=enorm_(n,fvec);

        if (*lambda <= treshold)
        {
            warningStreamPrint(LOG_NLS_V, 0, "Warning: lambda reached a threshold.");

            /* if damping is without success, trying full newton step; after 5 full newton steps try a very little step */
            if (*k >= 5)
                for (i=0; i<*n; i++)
                    solverData->x_new[i]=x[i]-*lambda*solverData->x_increment[i];
            else
                for (i=0; i<*n; i++)
                    solverData->x_new[i]=x[i]-solverData->x_increment[i];

            /* calculate new function values */
            (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
            solverData->nfev++;

            (*k)++;

            break;
        }
    }

    *lambda = 1;


   messageClose(LOG_NLS_V);
}

void damping_heuristic2(double damping_parameter, void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, int* k)
{
    int i,j=0, iflag;
    double enorm_new, treshold = 1e-4, lambda=1;


    NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[sysNumber]);
    DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);


    /* calculate new function values */
    (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
    solverData->nfev++;

    enorm_new=enorm_(n,fvec);

    if (enorm_new >= current_fvec_enorm)
        infoStreamPrint(LOG_NLS_V, 1, "StartDamping: ");

    while (enorm_new >= current_fvec_enorm)
    {
        j++;

        lambda*=damping_parameter;

        infoStreamPrint(LOG_NLS_V, 0, "lambda = %e, k = %d", lambda, *k);

        for (i=0; i<*n; i++)
            solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];


        /* calculate new function values */
        (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
        solverData->nfev++;

        enorm_new=enorm_(n,fvec);

        if (lambda <= treshold)
        {
            warningStreamPrint(LOG_NLS_V, 0, "Warning: lambda reached a threshold.");

            /* if damping is without success, trying full newton step; after 5 full newton steps try a very little step */
            if (*k >= 5)
                for (i=0; i<*n; i++)
                        solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];
            else
                for (i=0; i<*n; i++)
                    solverData->x_new[i]=x[i]-solverData->x_increment[i];

            /* calculate new function values */
            (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
            solverData->nfev++;

            (*k)++;

            break;
        }
    }

   messageClose(LOG_NLS_V);
}

void LineSearch(void* userdata, int sysNumber, double* x, int(*f)(int*, double*, double*, int*, void*, int),
        double current_fvec_enorm, int* n, double* fvec, int* k)
{
    int i,j, iflag;
    double enorm_new, treshold = 1e-2, enorm_minimum=current_fvec_enorm, lambda_minimum=0;
    double lambda[5]={1.25,1,0.75,0.5,0.25};


    NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)userdata)->simulationInfo.nonlinearSystemData[sysNumber]);
    DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);

    for (j=0; j<5; j++)
    {
        for (i=0; i<*n; i++)
             solverData->x_new[i]=x[i]-lambda[j]*solverData->x_increment[i];

        /* calculate new function values */
        (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
        solverData->nfev++;

        enorm_new=enorm_(n,fvec);

        /* searching minimal enorm */
        if (enorm_new < enorm_minimum)
        {
            enorm_minimum = enorm_new;
            lambda_minimum = lambda[j];
            memcpy(solverData->fvec_minimum, fvec,*n*sizeof(double));
        }
    }

    infoStreamPrint(LOG_NLS_V,0,"lambda_minimum = %e", lambda_minimum);

    if (lambda_minimum == 0)
    {
        warningStreamPrint(LOG_NLS_V, 0, "Warning: lambda_minimum = 0 ");

        /* if damping is without success, trying full newton step; after 5 full newton steps try a very little step */
        if (*k >= 5)
        {
            lambda_minimum = 0.125;

            /* calculate new function values */
            (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
            solverData->nfev++;
        }
        else
        {
            lambda_minimum = 1;

            /* calculate new function values */
            (*f)(n,solverData->x_new,fvec,&iflag,userdata,sysNumber);
            solverData->nfev++;
        }

        (*k)++;
    }
    else
    {
        /* save new function values */
        memcpy(fvec, solverData->fvec_minimum, *n*sizeof(double));
    }

    for (i=0; i<*n; i++)
        solverData->x_new[i]=x[i]-lambda_minimum*solverData->x_increment[i];

}
