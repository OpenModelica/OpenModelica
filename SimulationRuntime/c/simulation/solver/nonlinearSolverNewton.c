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

#include "simulation_data.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"

#include "nonlinearSystem.h"
#include "nonlinearSolverNewton.h"

typedef struct DATA_NEWTON
{
  int initialized; /* 1 = initialized, else = 0*/
  double* resScaling;
  int useXScaling;
  double* xScalefactors;
  double* fvecScaled;

  int n;
  double* x;
  double* fvec;
  double xtol;
  int nfev;
  int maxfev;
  int info;
  double epsfcn;
  double* fjac;
  double* rwork;
  int* iwork;
} DATA_NEWTON;


int _omc_newton(int* n, double *x, double *fvec, double* eps, double* fdeps, int* maxfev,
                  int* nfev, void(*f)(int*, double*, double*, int*, void*),
                  double* fjac, double* rwork, int* iwork,
                  int* info, void* userdata);

#ifdef __cplusplus
extern "C" {
#endif

extern
int _omc_dgesv_(integer *n, integer *nrhs, doublereal *a, integer
     *lda, integer *ipiv, doublereal *b, integer *ldb, integer *info);

#ifdef __cplusplus
}
#endif

/*! \fn allocateNewtonData
 * allocate memory for nonlinear system solver
 */
int allocateNewtonData(int size, void** voiddata){

  DATA_NEWTON* data = (DATA_NEWTON*) malloc(sizeof(DATA_NEWTON));

  *voiddata = (void*)data;
  ASSERT(data, "allocationHybrdData() failed!");

  data->initialized = 0;
  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));
  data->useXScaling = 1;
  data->xScalefactors = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc(size*sizeof(double));
  data->fvec = (double*) calloc(size,sizeof(double));
  data->xtol = 1e-10;
  data->maxfev = size*100;
  data->epsfcn = DBL_EPSILON;
  data->fjac = (double*) malloc((size*size)*sizeof(double));

  data->rwork = (double*) malloc((size)*sizeof(double));
  data->iwork = (int*) malloc(size*sizeof(int));

  ASSERT(*voiddata, "allocationNewtonData() voiddata failed!");
  return 0;
}

/*! \fn freeNewtonData
 *
 * free memory for nonlinear solver newton
 *
 */
int freeNewtonData(void **voiddata){

  DATA_NEWTON* data = (DATA_NEWTON*) *voiddata;

  free(data->resScaling);
  free(data->fvecScaled);
  free(data->xScalefactors);
  free(data->x);
  free(data->fvec);
  free(data->fjac);
  free(data->rwork);
  free(data->iwork);

  return 0;
}


/*! \fn wrapper_fvec_hybrd for the residual Function
 *   tensolve calls for the subroutine fcn(n, x, fvec, iflag, data)
 *
 *
 */
void wrapper_fvec_newton(int* n, double* x, double* f, int* iflag, void* data){

  int i,currentSys = ((DATA*)data)->simulationInfo.currentNonlinearSystemIndex;
  NONLINEAR_SYSTEM_DATA* systemData = &(((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);

  /* re-scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = x[i]*solverData->xScalefactors[i];
    }
  }

  (*((DATA*)data)->simulationInfo.nonlinearSystemData[currentSys].residualFunc)(data,
      x, f, iflag);

  /* Scaling x vector */
  if (solverData->useXScaling ){
    for(i=0;i<*n;i++){
      x[i] = (1.0/solverData->xScalefactors[i]) * x[i];
    }
  }
}




/*! \fn solve non-linear system with newton method
 *
 *  \param  [in]  [data]
 *                [sysNumber] index of the corresponding non-linear system
 *
 *  \author wbraun
 */
int solveNewton(DATA *data, int sysNumber) {


  NONLINEAR_SYSTEM_DATA* systemData = &(data->simulationInfo.nonlinearSystemData[sysNumber]);
  DATA_NEWTON* solverData = (DATA_NEWTON*)(systemData->solverData);
  /*
   * We are given the number of the non-linear system.
   * We want to look it up among all equations.
   */
  int eqSystemNumber = data->modelData.equationInfo_reverse_prof_index[systemData->simProfEqNr];

  int i, iflag=0;
  double xerror, xerror_scaled;
  char success = 0;
  double local_tol = 1e-10;
  int nfunc_evals = 0;
  int continuous = 1;

  int giveUp = 0;
  int retries = 0;

  solverData->nfev = 0;

  /* set x vector */
  memcpy(solverData->x, systemData->nlsxExtrapolation, solverData->n*(sizeof(double)));

  for(i=0;i<solverData->n;i++){
    solverData->xScalefactors[i] = fmax(solverData->x[i], systemData->nominal[i]);
  }

  /* debug output */
  if(DEBUG_STREAM(LOG_NLS))
  {
    INFO2(LOG_NLS, "Start solving Non-Linear System %s at time %e with Newton Solver",
        data->modelData.equationInfo[eqSystemNumber].name,
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
    RELEASE(LOG_NLS);
  }

  /* start solving loop */
  while (!giveUp && !success) {

    /* Scaling x vector */
    if(solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = (1.0/solverData->xScalefactors[i]) * solverData->x[i];
      }
    }

    /* set residual function continuous
     */
    if (continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 1;
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 0;


    giveUp = 1;
    _omc_newton(&solverData->n, solverData->x, solverData->fvec, &solverData->xtol,
                &solverData->epsfcn, &solverData->maxfev, &solverData->nfev,
                wrapper_fvec_newton, solverData->fjac, solverData->rwork,
                solverData->iwork, &solverData->info, data);


    /* set residual function continuous */
    if (continuous)
      ((DATA*)data)->simulationInfo.solveContinuous = 0;
    else
      ((DATA*)data)->simulationInfo.solveContinuous = 1;


    /* re-scaling x vector */
    if(solverData->useXScaling){
      for(i=0;i<solverData->n;i++){
        solverData->x[i] = solverData->x[i]*solverData->xScalefactors[i];
      }
    }

    /* check for proper inputs */
    if (solverData->info == 0) {
      printErrorEqSyst(IMPROPER_INPUT, data->modelData.equationInfo[systemData->simProfEqNr],
          data->localData[0]->timeValue);
      data->simulationInfo.found_solution = -1;
    }

    if (DEBUG_STREAM(LOG_NLS_JAC)) {
      int i,j,l=0;
      printf("Jacobi-Matrix\n");
      for(i=0;i<solverData->n;i++){
        printf("%d : ", i);
        for(j=0;j<solverData->n;j++){
          printf("%e ",solverData->fjac[l++]);
        }
        printf("\n");
      }
    }

    /* Scaling Residual vector */
    {
      int i,j,l=0;
      for(i=0;i<solverData->n;++i){
        solverData->resScaling[i] = 1e-16;
        for(j=0;j<solverData->n;++j){
          solverData->resScaling[i] = (fabs(solverData->fjac[l]) > solverData->resScaling[i])
              ? fabs(solverData->fjac[l]) : solverData->resScaling[i];
          l++;
        }
        solverData->resScaling[i] = solverData->fvec[i] * (1 / solverData->resScaling[i]);
      }
    }

    /* check for error  */
    xerror_scaled = enorm_(&solverData->n, solverData->resScaling);
    xerror = enorm_(&solverData->n, solverData->fvec);

    /* solution found */
    if ((xerror <= local_tol || xerror_scaled <= local_tol) && solverData->info > 0) {
      success = 1;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NLS)) {
        INFO1(LOG_NLS, "*** System solved ***\n%d restarts", retries);
        INFO3(LOG_NLS, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        if (DEBUG_STREAM(LOG_NLS)) {
          for (i = 0; i < solverData->n; i++) {
            INFO3(LOG_NLS, "x[%d] = %.15e\n\ttresidual = %e", i, solverData->x[i], solverData->fvec[i]);
          }
        }
      }
    /* Then try with old values (instead of extrapolating )*/
    } else if (retries < 1){
      for (i=0; i< solverData->n; ++i){
        solverData->x[i] = systemData->nlsxOld[i];
      }
      retries++;
      giveUp = 0;
      nfunc_evals += solverData->nfev;
      if (DEBUG_STREAM(LOG_NLS)) {
        INFO(LOG_NLS, " - iteration making no progress:\t try old values.");
      }
    /* try to vary the initial values */
    } else if(retries < 2) {
      for(i = 0; i < solverData->n; i++) {
          solverData->x[i] += systemData->nominal[i] * 0.1;
        };
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if(DEBUG_STREAM(LOG_NLS)) {
          INFO(LOG_NLS,
              " - iteration making no progress:\t vary solution point by 1%%.");
        }
    /* try old values as x-Scaling factors */
    } else if(retries < 3) {

        for(i=0;i<solverData->n;i++){
          solverData->xScalefactors[i] = fmax(systemData->nlsxOld[i], systemData->nominal[i]);
        }
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if(DEBUG_STREAM(LOG_NLS)) {
          INFO(LOG_NLS,
              " - iteration making no progress:\t try without scaling at all.");
        }
    /* try to disable x-Scaling */
    } else if(retries < 4) {
        int scaling = solverData->useXScaling;
        if(scaling)
          solverData->useXScaling = 0;
        memcpy(solverData->xScalefactors, systemData->nominal, solverData->n*(sizeof(double)));
        retries++;
        giveUp = 0;
        nfunc_evals += solverData->nfev;
        if(DEBUG_STREAM(LOG_NLS)) {
          INFO(LOG_NLS,
              " - iteration making no progress:\t try without scaling at all.");
        }
    } else {
      data->simulationInfo.found_solution = -1;

      printErrorEqSyst(ERROR_AT_TIME, data->modelData.equationInfo[eqSystemNumber], data->localData[0]->timeValue);

      if (DEBUG_STREAM(LOG_NLS)) {
        INFO1(LOG_NLS, "### No Solution! ###\n after %d restarts", retries);
        INFO3(LOG_NLS, "nfunc = %d +++ error = %.15e +++ error_scaled = %.15e", nfunc_evals, xerror, xerror_scaled);
        if (DEBUG_STREAM(LOG_NLS)) {
          for (i = 0; i < solverData->n; i++) {
            INFO3(LOG_NLS, "x[%d] = %.15e\n\ttresidual = %e", i, solverData->x[i], solverData->fvec[i]);
          }
        }
      }
    }
  }


  /* take the best approximation */
  memcpy(systemData->nlsx, solverData->x, solverData->n*(sizeof(double)));

  return success;
}

/*! \fn fdjac
 *
 *  function calculates a jacobian matrix by
 *  numerical method finite differences
 */
int
fdjac(int* n, void(*f)(int*, double*, double*, int*, void*), double *x,
       double* fvec, double *fjac, double* eps, int* iflag, double* wa,
       void* userdata)
{
  double delta_h = sqrt(*eps);
  double delta_hh,delta_hhh;
  double xsave;

  int i,j,l;

  for (i = 0; i < *n; i++) {
    delta_hhh = delta_h * fvec[i];
    delta_hh = delta_h * abs(x[i]);
    delta_hh = delta_h * abs(x[i]);
    delta_hh = fmax(delta_h, delta_hh);
    delta_hh = ((delta_hhh >= 0) ? delta_hh : -delta_hh);
    delta_hh = x[i] + delta_hh - x[i];
    xsave = x[i];
    x[i] += delta_hh;
    delta_hh = 1. / delta_hh;
    f(n, x, wa, iflag, userdata);

    for (j = 0; j < *n; j++) {
      l = i * *n + j;
      fjac[l] = (wa[j] - fvec[j]) * delta_hh;
    }
    x[i] = xsave;
  }

  return *iflag;
}

/*! \fn solve system with Newton-Raphson
 *
 *  \param  [in]  [n] size of equation
 *                [eps] tolerance for x
 *                [h] tolerance for f'
 *                [k] maximum number of iterations
 *                [work] work array size of (n*X)
 *                [f] user provided function
 *                [data] userdata
 *                [info]
 *
 */
int _omc_newton(int* n, double *x, double *fvec, double* eps, double* fdeps, int* maxfev,
                  int* nfev, void(*f)(int*, double*, double*, int*, void*),
                  double* fjac, double* work, int* iwork, int* info, void* userdata)
{
  int i, j, l, k;
  int iflag;
  double error, tmp;
  double *wa;
  int nrsh = 1;
  int lapackinfo = 1;
  wa = work;
  l = *maxfev;
  error = 1.0 + *eps;

  if (DEBUG_STREAM(LOG_NLS_V)) {
    INFO1(LOG_NLS_V,"######### Start Newton maxfev :%d #########", *maxfev);
    for(i=0;i<*n;i++)
      INFO2(LOG_NLS_V,"x[%d] : %e ", i, x[i]);
  }
  *info = 1;

  while (error >= *eps && *info >= 0)
  {

    DEBUG1(LOG_NLS_V, "**** start Iteration : %d  *****", *maxfev-l);
    /* calculate the function values */
    (*f)(n, x, fvec, &iflag, userdata);
    (*nfev)++;

    if (DEBUG_STREAM(LOG_NLS_V)) {
      for(i=0;i<*n;i++)
        DEBUG2(LOG_NLS_V,"fvec[%d] : %e: ", i, fvec[i]);
    }

    /* calculate jacobian */
    fdjac(n, f, x, fvec, fjac, fdeps, &iflag, wa, userdata);
    (*nfev)=(*nfev)+*n;
    /* (*df)(x, a, n); */

    /*  Debug output */
    if(DEBUG_STREAM(LOG_NLS_JAC))
    {
      DEBUG(LOG_NLS_JAC,"Print jacobian matrix:");
      for(i=0;  i < *n;i++)
      {
        printf("%d : ", i);
        for(j=0;  j < *n;j++)
          printf("%f ", fjac[i*(*n)+j]);
        printf("\n");
      }
    }

    /* solve J*(x_{n+1} - x_n)=f */
    _omc_dgesv_(n, &nrsh, fjac, n, iwork, fvec, n, &lapackinfo);


    if (DEBUG_STREAM(LOG_NLS_V)) {
      DEBUG(LOG_NLS_V,"Solved J*x=b");
      for(i=0;i<*n;i++)
        DEBUG2(LOG_NLS_V,"b[%d] = %e ", i, fvec[i]);;
    }

    if (lapackinfo > 0){
      *info = -1;
      WARNING(LOG_NLS,"Jacobian Matrix singular!");
    }else if (lapackinfo < 0){
      *info = -1;
      WARNING1(LOG_NLS,"illegal  input in argument %d", lapackinfo);
    }else{
      /* if no error occurs update x vector */
      for (i = 0; i < *n; i++)
        x[i] = x[i] - fvec[i];
    }

    if (DEBUG_STREAM(LOG_NLS_V)) {
      for(i=0;i<*n;i++)
        DEBUG2(LOG_NLS_V,"x[%d] = %e ", i, x[i]);
    }

    /* calculate the function values */
    (*f)(n, x, fvec, &iflag, userdata);
    (*nfev)++;

    if (DEBUG_STREAM(LOG_NLS_V)) {
      for(i=0;i<*n;i++)
        DEBUG2(LOG_NLS_V,"fvec[%d] : %e: ", i, fvec[i]);
    }

    if (DEBUG_STREAM(LOG_NLS_V)) {
      for(i=0;i<*n;i++)
        INFO2(LOG_NLS_V,"x[%d] : %e ", i, x[i]);
    }

    /* calculate error by maximum norm */
    error = 0.0;
    for (i = 0; i < *n; i++) {
      tmp = fabs(fvec[i]);
      if (tmp > error)
        error = tmp;
    }
    DEBUG2(LOG_NLS_V,"z = %e\t error = %e", z, error);


    /* check if maximum iteration is reached */
    if (error >= *eps) {
      l = l - 1;
      if (l < 0) {
        *info = -1;
        return 0;
      }
    }
  }
  return 0;
}
