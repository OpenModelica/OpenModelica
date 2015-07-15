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

/*! \file newtonIteration.c
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
#include "newtonIteration.h"

#include "external_input.h"


extern double enorm_(int *n, double *x);
int solveLinearSystem(int* n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData);
void calculatingErrors(DATA_NEWTON* solverData, double* delta_x, double* delta_x_scaled, double* delta_f, double* error_f,
    double* scaledError_f, int* n, double* x, double* fvec);
void scaling_residual_vector(DATA_NEWTON* solverData);
void damping_heuristic(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, double* lambda, int* k, DATA_NEWTON* solverData, void* userdata);
void damping_heuristic2(double damping_parameter, double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, int* k, DATA_NEWTON* solverData, void* userdata);
void LineSearch(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, int* k, DATA_NEWTON* solverData, void* userdata);
void Backtracking(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, DATA_NEWTON* solverData, void* userdata);
void printErrors(double delta_x, double delta_x_scaled, double delta_f, double error_f, double scaledError_f, double* eps);


#ifdef __cplusplus
extern "C" {
#endif

extern int dgesv_(int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);
extern void dgetrf_(int *m, int *n, doublereal *fjac, int *lda, int* iwork, int *info);
extern void dgetrs_(char *trans, int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);

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
  assertStreamPrint(NULL, NULL != data, "allocationNewtonData() failed!");

  data->resScaling = (double*) malloc(size*sizeof(double));
  data->fvecScaled = (double*) malloc(size*sizeof(double));

  data->n = size;
  data->x = (double*) malloc(size*sizeof(double));
  data->fvec = (double*) calloc(size,sizeof(double));
  data->xtol = 1e-6;
  data->ftol = 1e-6;
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

  data->factorization = 0;
  data->calculate_jacobian = 1;
  data->numberOfIterations = 0;
  data->numberOfFunctionEvaluations = 0;

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

  /* damped newton */
  free(data->x_new);
  free(data->x_increment);
  free(data->f_old);
  free(data->fvec_minimum);
  free(data->delta_f);
  free(data->delta_x_vec);

  return 0;
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
 *				  [calculate_jacobian] flag which decides whether Jacobian is calculated
 *					(0)  once for the first calculation
 * 					(i)  every i steps (=1 means original newton method)
 * 					(-1) never, factorization has to be given in A
 *
 */
int _omc_newton(int(*f)(int*, double*, double*, void*, int), DATA_NEWTON* solverData, void* userdata)
{

  int i, j, k = 0, l = 0, nrsh = 1;
  int *n = &(solverData->n);
  double *x = solverData->x;
  double *fvec = solverData->fvec;
  double *eps = &(solverData->ftol);
  double *fdeps = &(solverData->epsfcn);
  int * maxfev = &(solverData->maxfev);
  double *fjac = solverData->fjac;
  double *work = solverData->rwork;
  int *iwork = solverData->iwork;
  int *info = &(solverData->info);
  int calc_jac = 1;

  double error_f  = 1.0 + *eps, scaledError_f = 1.0 + *eps, delta_x = 1.0 + *eps, delta_f = 1.0 + *eps, delta_x_scaled = 1.0 + *eps, lambda = 1.0;
  double current_fvec_enorm, enorm_new;


  if(ACTIVE_STREAM(LOG_NLS_V))
  {
    infoStreamPrint(LOG_NLS_V, 1, "######### Start Newton maxfev: %d #########", (int)*maxfev);

    infoStreamPrint(LOG_NLS_V, 1, "x vector");
    for(i=0; i<*n; i++)
      infoStreamPrint(LOG_NLS_V, 0, "x[%d]: %e ", i, x[i]);
    messageClose(LOG_NLS_V);

    messageClose(LOG_NLS_V);
  }

  *info = 1;

  /* calculate the function values */
  (*f)(n, x, fvec, userdata, 1);

  solverData->nfev++;

  /* save current fvec in f_old*/
  memcpy(solverData->f_old, fvec, *n*sizeof(double));

  error_f = current_fvec_enorm = enorm_(n, fvec);

  while(error_f > *eps && scaledError_f > *eps  &&  delta_x > *eps  &&  delta_f > *eps  && delta_x_scaled > *eps)
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

    /* calculate jacobian if no matrix is given */
    if (calc_jac == 1 && solverData->calculate_jacobian >= 0)
    {
      (*f)(n, x, fvec, userdata, 0);
      solverData->factorization = 0;
      calc_jac = solverData->calculate_jacobian;
    }
    else
    {
      solverData->factorization = 1;
      calc_jac--;
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

      if (solverData->newtonStrategy == NEWTON_DAMPED)
      {
        damping_heuristic(x, f, current_fvec_enorm, n, fvec, &lambda, &k, solverData, userdata);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED2)
      {
        damping_heuristic2(0.75, x, f, current_fvec_enorm, n, fvec, &k, solverData, userdata);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED_LS)
      {
        LineSearch(x, f, current_fvec_enorm, n, fvec, &k, solverData, userdata);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED_BT)
      {
        Backtracking(x, f, current_fvec_enorm, n, fvec, solverData, userdata);
      }
      else
      {
        /* calculate the function values */
        (*f)(n, solverData->x_new, fvec, userdata, 1);
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

  solverData->numberOfIterations  += l;
  solverData->numberOfFunctionEvaluations += solverData->nfev;

  return 0;
}


/*! \fn printErrors
 *
 *  function prints errors, that reached tolerance
 */

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

/*! \fn solveLinearSystem
 *
 *  function solves linear system J*(x_{n+1} - x_n) = f using lapack
 */
int solveLinearSystem(int* n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData)
{
  int i, nrsh=1, lapackinfo;
  char trans = 'N';

  /* if no factorization is given, calculate it */
  if (solverData->factorization == 0)
  {
    /* solve J*(x_{n+1} - x_n)=f */
    dgetrf_(n, n, fjac, n, iwork, &lapackinfo);
    solverData->factorization = 1;
    dgetrs_(&trans, n, &nrsh, fjac, n, iwork, fvec, n, &lapackinfo);
  }
  else
  {
    dgetrs_(&trans, n, &nrsh, fjac, n, iwork, fvec, n, &lapackinfo);
  }

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

/*! \fn calculatingErrors
 *
 *  function calculates the errors
 */
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

/*! \fn calculatingErrors
 *
 *  function scales the residual vector using the jacobian (heuristic)
 */
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

/*! \fn damping_heuristic
 *
 *  first damping heuristic:
 *  x_increment will be halved until the Euclidean norm of the residual function
 *  is smaller than the Euclidean norm of the current point
 *
 *  treshold for damping = 0.01
 *  compiler flag: -newton = damped
 */
void damping_heuristic(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, double* lambda, int* k, DATA_NEWTON* solverData, void* userdata)
{
  int i,j=0;
  double enorm_new, treshold = 1e-2;

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userdata, 1);
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
    (*f)(n, solverData->x_new, fvec, userdata, 1);
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
      (*f)(n, solverData->x_new, fvec, userdata, 1);
      solverData->nfev++;

      (*k)++;

      break;
    }
  }

  *lambda = 1;

  messageClose(LOG_NLS_V);
}

/*! \fn damping_heuristic2
 *
 *  second (default) damping heuristic:
 *  x_increment will be multiplied by 3/4 until the Euclidean norm of the residual function
 *  is smaller than the Euclidean norm of the current point
 *
 *  treshold for damping = 0.0001
 *  compiler flag: -newton = damped2
 */
void damping_heuristic2(double damping_parameter, double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, int* k, DATA_NEWTON* solverData, void* userdata)
{
  int i,j=0;
  double enorm_new, treshold = 1e-4, lambda=1;

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userdata, 1);
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
    (*f)(n, solverData->x_new, fvec, userdata, 1);
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
      (*f)(n, solverData->x_new, fvec, userdata, 1);
      solverData->nfev++;

      (*k)++;

      break;
    }
  }

  messageClose(LOG_NLS_V);
}

/*! \fn LineSearch
 *
 *  third damping heuristic:
 *  Along the tangent 5 five points are selected. For every point the Euclidean norm of
 *  the residual function will be calculated and the minimum is chosen for the further iteration.
 *
 *  compiler flag: -newton = damped_ls
 */
void LineSearch(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, int* k, DATA_NEWTON* solverData, void* userdata)
{
  int i,j;
  double enorm_new, enorm_minimum=current_fvec_enorm, lambda_minimum=0;
  double lambda[5]={1.25,1,0.75,0.5,0.25};


  for (j=0; j<5; j++)
  {
    for (i=0; i<*n; i++)
      solverData->x_new[i]=x[i]-lambda[j]*solverData->x_increment[i];

    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userdata, 1);
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
      (*f)(n, solverData->x_new, fvec, userdata, 1);
      solverData->nfev++;
    }
    else
    {
      lambda_minimum = 1;

      /* calculate new function values */
      (*f)(n, solverData->x_new, fvec, userdata, 1);
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

/*! \fn Backtracking
 *
 *  forth damping heuristic:
 *  Calculate new function h:R^n->R ;  h(x) = 1/2 * ||f(x)|| ^2
 *  g(lambda) = h(x_old + lambda * x_increment)
 *  find minimum of g with golden ratio method
 *  tau = golden ratio
 *
 *  compiler flag: -newton = damped_bt
 */
void Backtracking(double* x, int(*f)(int*, double*, double*, void*, int),
    double current_fvec_enorm, int* n, double* fvec, DATA_NEWTON* solverData, void* userdata)
{
  int i,j;
  double enorm_new, enorm_f, lambda, a1, b1, a, b, tau, g1, g2;
  double tolerance = 1e-3;

  /* saving current function values in f_old */
  memcpy(solverData->f_old, fvec, *n*sizeof(double));

  for (i=0; i<*n; i++)
    solverData->x_new[i]=x[i]-solverData->x_increment[i];

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userdata, 1);
  solverData->nfev++;


  /* calculate new enorm */
  enorm_new = enorm_(n,fvec);

  /* Backtracking only if full newton step is useless */
  if (enorm_new >= current_fvec_enorm)
  {
    infoStreamPrint(LOG_NLS_V, 0, "Start Backtracking\n enorm_new= %f \t current_fvec_enorm=%f",enorm_new, current_fvec_enorm);

    /* h(x) = 1/2 * ||f(x)|| ^2
     * g(lambda) = h(x_old + lambda * x_increment)
     * find minimum of g with golden ratio method
     * tau = golden ratio
     * */

    a = 0;
    b = 1;
    tau = 0.61803398875;

    a1 = a + (1-tau)*(b-a);
    /* g1 = g(a1) = h(x_old - a1 * x_increment) = 1/2 * ||f(x_old- a1 * x_increment)||^2 */
    solverData->x_new[i] = x[i]- a1 * solverData->x_increment[i];
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
    enorm_f= enorm_(n,fvec);
    g1 = 0.5 * enorm_f * enorm_f;


    b1 = a + tau * (b-a);
    /* g2 = g(b1) = h(x_old - b1 * x_increment) = 1/2 * ||f(x_old- b1 * x_increment)||^2 */
    solverData->x_new[i] = x[i]- b1 * solverData->x_increment[i];
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
    enorm_f= enorm_(n,fvec);
    g2 = 0.5 * enorm_f * enorm_f;

    while ( (b - a) > tolerance)
    {
      if (g1<g2)
      {
        b = b1;
        b1 = a1;
        a1 = a + (1-tau)*(b-a);
        g2 = g1;

        /* g1 = g(a1) = h(x_old - a1 * x_increment) = 1/2 * ||f(x_old- a1 * x_increment)||^2 */
        solverData->x_new[i] = x[i]- a1 * solverData->x_increment[i];
        (*f)(n, solverData->x_new, fvec, userdata, 1);
        solverData->nfev++;
        enorm_f= enorm_(n,fvec);
        g1 = 0.5 * enorm_f * enorm_f;
      }
      else
      {
        a = a1;
        a1 = b1;
        b1 = a + tau * (b-a);
        g1 = g2;

        /* g2 = g(b1) = h(x_old - b1 * x_increment) = 1/2 * ||f(x_old- b1 * x_increment)||^2 */
        solverData->x_new[i] = x[i]- b1 * solverData->x_increment[i];
        (*f)(n, solverData->x_new, fvec, userdata, 1);
        solverData->nfev++;
        enorm_f= enorm_(n,fvec);
        g2 = 0.5 * enorm_f * enorm_f;
      }
    }


    lambda = (a+b)/2;


    /* print lambda */
    infoStreamPrint(LOG_NLS_V, 0, "Backtracking - lambda = %e", lambda);

    for (i=0; i<*n; i++)
      solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];

    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
  }
}


#ifdef __cplusplus
}
#endif
