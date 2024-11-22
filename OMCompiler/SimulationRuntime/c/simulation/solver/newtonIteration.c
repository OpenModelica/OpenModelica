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

#include "simulation/simulation_info_json.h"
#include "model_help.h"
#include "omc_math.h"
#include "util/omc_error.h"
#include "util/varinfo.h"

#include "nonlinearSystem.h"
#include "newtonIteration.h"

#include "external_input.h"

/* Private function prototypes */

int solveLinearSystem(int n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData);
void calculatingErrors(DATA_NEWTON* solverData, double* delta_x, double* delta_x_scaled, double* delta_f, double* error_f,
                       double* scaledError_f, int n, double* x, double* fvec);
void scaling_residual_vector(DATA_NEWTON* solverData);
void damping_heuristic(double* x, genericResidualFunc f,
                       double current_fvec_enorm, int n, double* fvec, double* lambda, int* k,
                       DATA_NEWTON* solverData, NLS_USERDATA* userData);
void damping_heuristic2(double damping_parameter, double* x, genericResidualFunc f,
                        double current_fvec_enorm, int n, double* fvec, int* k,
                        DATA_NEWTON* solverData, NLS_USERDATA* userdata);
void LineSearch(double* x, genericResidualFunc f,
                double current_fvec_enorm, int n, double* fvec, int* k,
                DATA_NEWTON* solverData, NLS_USERDATA* userdata);
void Backtracking(double* x, genericResidualFunc f, double current_fvec_enorm,
                  int n, double* fvec, DATA_NEWTON* solverData,
                  NLS_USERDATA* userdata);
void printErrors(double delta_x, double delta_x_scaled, double delta_f, double error_f, double scaledError_f, double* eps);

/* Extern function prototypes */

extern double enorm_(int *n, double *x);
extern int dgesv_(int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);
extern void dgetrf_(int *m, int *n, doublereal *fjac, int *lda, int* iwork, int *info);
extern void dgetrs_(char *trans, int *n, int *nrhs, doublereal *a, int *lda, int *ipiv, doublereal *b, int *ldb, int *info);

/**
 * @brief Allocate NLS Newton data.
 *
 * @param size            Size of non-linear system.
 * @param userData        Pointer to set NLS user data.
 * @return DATA_NEWTON*   Allocated memory.
 */
DATA_NEWTON* allocateNewtonData(int size, NLS_USERDATA* userData)
{
  DATA_NEWTON* newtonData = (DATA_NEWTON*) malloc(sizeof(DATA_NEWTON));
  assertStreamPrint(NULL, NULL != newtonData, "allocationNewtonData() failed. Out of memory.");

  newtonData->resScaling = (double*) malloc(size*sizeof(double));
  newtonData->fvecScaled = (double*) malloc(size*sizeof(double));

  newtonData->n = size;
  newtonData->x = (double*) malloc((size+1)*sizeof(double));
  newtonData->fvec = (double*) calloc(size,sizeof(double));
  newtonData->xtol = 1e-6;
  newtonData->ftol = 1e-6;
  newtonData->maxfev = size*100;
  newtonData->epsfcn = DBL_EPSILON;
  newtonData->fjac = (double*) malloc((size*(size+1))*sizeof(double));

  newtonData->rwork = (double*) malloc((size)*sizeof(double));
  newtonData->iwork = (int*) malloc(size*sizeof(int));

  /* damped newton */
  newtonData->x_new = (double*) malloc((size+1)*sizeof(double));
  newtonData->x_increment = (double*) malloc(size*sizeof(double));
  newtonData->f_old = (double*) calloc(size,sizeof(double));
  newtonData->fvec_minimum = (double*) calloc(size,sizeof(double));
  newtonData->delta_f = (double*) calloc(size,sizeof(double));
  newtonData->delta_x_vec = (double*) calloc(size,sizeof(double));

  newtonData->factorization = 0;
  newtonData->calculate_jacobian = 1;
  newtonData->numberOfIterations = 0;
  newtonData->numberOfFunctionEvaluations = 0;

  newtonData->userData = userData;

  return newtonData;
}

/**
 * @brief Free NLS Newton data.
 *
 * @param newtonData  Pointer to Newton data.
 */
void freeNewtonData(DATA_NEWTON* newtonData)
{
  free(newtonData->resScaling);
  free(newtonData->fvecScaled);
  free(newtonData->x);
  free(newtonData->fvec);
  free(newtonData->fjac);
  free(newtonData->rwork);
  free(newtonData->iwork);

  /* damped newton */
  free(newtonData->x_new);
  free(newtonData->x_increment);
  free(newtonData->f_old);
  free(newtonData->fvec_minimum);
  free(newtonData->delta_f);
  free(newtonData->delta_x_vec);

  freeNlsUserData(newtonData->userData);
  free(newtonData);
}

/**
 * @brief Solve system with Newton-Raphson.
 *
 * @param f             Residual function.
 * @param solverData    Solver data for containing information for Newton solver.
 * @param userData      Void pointer containing user data for supplied function f and damping heuristics.
 * @return int          Returns 0.
 */

int _omc_newton(genericResidualFunc f, DATA_NEWTON* solverData, void* userData)
{
  int i, j, k = 0, l = 0, nrsh = 1;
  int n = solverData->n;    /* size of equation */
  double *x = solverData->x;
  double *fvec = solverData->fvec;
  double *eps = &(solverData->ftol);  /* tolerance for x */
  double *fdeps = &(solverData->epsfcn);
  int * maxfev = &(solverData->maxfev);
  double *fjac = solverData->fjac;
  double *work = solverData->rwork;
  int *iwork = solverData->iwork;
  int *info = &(solverData->info);
  int calc_jac = 1;

  double error_f  = 1.0 + *eps, scaledError_f = 1.0 + *eps, delta_x = 1.0 + *eps, delta_f = 1.0 + *eps, delta_x_scaled = 1.0 + *eps, lambda = 1.0;
  double current_fvec_enorm, enorm_new;

  if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
  {
    infoStreamPrint(OMC_LOG_NLS_V, 1, "######### Start Newton maxfev: %d #########", (int)*maxfev);

    infoStreamPrint(OMC_LOG_NLS_V, 1, "x vector");
    for(i=0; i<n; i++)
      infoStreamPrint(OMC_LOG_NLS_V, 0, "x[%d]: %e ", i, x[i]);
    messageClose(OMC_LOG_NLS_V);

    messageClose(OMC_LOG_NLS_V);
  }

  *info = 1;

  /* calculate the function values */
  (*f)(n, x, fvec, userData, 1);

  solverData->nfev++;

  /* save current fvec in f_old*/
  memcpy(solverData->f_old, fvec, n*sizeof(double));

  error_f = current_fvec_enorm = enorm_(&n, fvec);

  memcpy(solverData->fvecScaled, solverData->fvec, n*sizeof(double));

  while(error_f > *eps && scaledError_f > *eps  &&  delta_x > *eps  &&  delta_f > *eps  && delta_x_scaled > *eps)
  {
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
    {
      infoStreamPrint(OMC_LOG_NLS_V, 0, "\n**** start Iteration: %d  *****", (int) l);

      /*  Debug output */
      infoStreamPrint(OMC_LOG_NLS_V, 1, "function values");
      for(i=0; i<n; i++)
        infoStreamPrint(OMC_LOG_NLS_V, 0, "fvec[%d]: %e ", i, fvec[i]);
      messageClose(OMC_LOG_NLS_V);
    }

    /* calculate jacobian if no matrix is given */
    if (calc_jac == 1 && solverData->calculate_jacobian >= 0)
    {
      (*f)(n, x, fvec, userData, 0);
      solverData->factorization = 0;
      calc_jac = solverData->calculate_jacobian;
    }
    else
    {
      solverData->factorization = 1;
      calc_jac--;
    }


    /* debug output */
    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_JAC))
    {
      char *buffer = (char*)malloc(sizeof(char)*solverData->n*15);

      infoStreamPrint(OMC_LOG_NLS_JAC, 1, "jacobian matrix [%dx%d]", n, n);
      for(i=0; i<solverData->n;i++)
      {
        buffer[0] = 0;
        for(j=0; j<solverData->n; j++)
          sprintf(buffer, "%s%10g ", buffer, fjac[i*n+j]);
        infoStreamPrint(OMC_LOG_NLS_JAC, 0, "%s", buffer);
      }
      messageClose(OMC_LOG_NLS_JAC);
      free(buffer);
    }

    if (solveLinearSystem(n, iwork, fvec, fjac, solverData) != 0)
    {
      *info=-1;
      break;
    }
    else
    {
      for (i = 0; i < n; i++)
        solverData->x_new[i] = x[i]-solverData->x_increment[i];

      if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V)) {
        infoStreamPrint(OMC_LOG_NLS_V, 1, "x_increment");
        for(i = 0; i < n; i++) {
          infoStreamPrint(OMC_LOG_NLS_V, 0, "x_increment[%d] = %e ", i, solverData->x_increment[i]);
        }
        messageClose(OMC_LOG_NLS_V);
      }

      if (solverData->newtonStrategy == NEWTON_DAMPED)
      {
        damping_heuristic(x, f, current_fvec_enorm, n, fvec, &lambda, &k, solverData, userData);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED2)
      {
        damping_heuristic2(0.75, x, f, current_fvec_enorm, n, fvec, &k, solverData, userData);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED_LS)
      {
        LineSearch(x, f, current_fvec_enorm, n, fvec, &k, solverData, userData);
      }
      else if (solverData->newtonStrategy == NEWTON_DAMPED_BT)
      {
        Backtracking(x, f, current_fvec_enorm, n, fvec, solverData, userData);
      }
      else
      {
        /* calculate the function values */
        (*f)(n, solverData->x_new, fvec, userData, 1);
        solverData->nfev++;
      }

      calculatingErrors(solverData, &delta_x, &delta_x_scaled, &delta_f, &error_f, &scaledError_f, n, x, fvec);

      /* updating x */
      memcpy(x, solverData->x_new, n*sizeof(double));

      /* updating f_old */
      memcpy(solverData->f_old, fvec, n*sizeof(double));

      current_fvec_enorm = error_f;

      /* check if maximum iteration is reached */
      if (++l > *maxfev)
      {
        *info = -1;
        if (solverData->initial) {
          warningStreamPrint(OMC_LOG_NLS_V, 0, "Newton iteration: Maximal number of iteration reached at initialization, but no root found.");
        } else {
          warningStreamPrint(OMC_LOG_NLS_V, 0, "Newton iteration: Maximal number of iteration reached at time %f, but no root found.", solverData->time);
        }
        break;
      }
      /* check if maximum iteration is reached */
      if (k > 5)
      {
        *info = -1;
        warningStreamPrint(OMC_LOG_NLS_V, 0, "Newton iteration: Maximal number of iterations reached.");
        break;
      }
    }

    if(OMC_ACTIVE_STREAM(OMC_LOG_NLS_V))
    {
      infoStreamPrint(OMC_LOG_NLS_V, 1, "x vector");
      for(i = 0; i < n; i++)
        infoStreamPrint(OMC_LOG_NLS_V, 0, "x[%d] = %e ", i, x[i]);
      messageClose(OMC_LOG_NLS_V);
      printErrors(delta_x, delta_x_scaled, delta_f, error_f, scaledError_f, eps);
    }
  }

  solverData->numberOfIterations += l;
  solverData->numberOfFunctionEvaluations += solverData->nfev;

  return 0;
}

/**
 * @brief Print errors.
 *
 * Print if tolerance is reached.
 * Errors computed by calculatingErrors.
 *
 * @param delta_x         delta_x := ||x_new - x_old||
 * @param delta_x_scaled  delta_x_scaled := delta_x / scaling_factor
 * @param delta_f         delta_f := || f_old - f_new ||
 * @param error_f         enorm_(n,fvec)
 * @param scaledError_f
 * @param eps
 */
void printErrors(double delta_x, double delta_x_scaled, double delta_f, double error_f, double scaledError_f, double* eps)
{
  infoStreamPrint(OMC_LOG_NLS_V, 1, "errors ");
  infoStreamPrint(OMC_LOG_NLS_V, 0, "delta_x = %e \ndelta_x_scaled = %e \ndelta_f = %e \nerror_f = %e \nscaledError_f = %e", delta_x, delta_x_scaled, delta_f, error_f, scaledError_f);

  if (delta_x < *eps)
    infoStreamPrint(OMC_LOG_NLS_V, 0, "delta_x reached eps");
  if (delta_x_scaled < *eps)
    infoStreamPrint(OMC_LOG_NLS_V, 0, "delta_x_scaled reached eps");
  if (delta_f < *eps)
    infoStreamPrint(OMC_LOG_NLS_V, 0, "delta_f reached eps");
  if (error_f < *eps)
    infoStreamPrint(OMC_LOG_NLS_V, 0, "error_f reached eps");
  if (scaledError_f < *eps)
    infoStreamPrint(OMC_LOG_NLS_V, 0, "scaledError_f reached eps");

  messageClose(OMC_LOG_NLS_V);
}

/*! \fn solveLinearSystem
 *
 *  function solves linear system J*(x_{n+1} - x_n) = f using lapack
 */
int solveLinearSystem(int n, int* iwork, double* fvec, double *fjac, DATA_NEWTON* solverData)
{
  int i, nrsh=1, lapackinfo;
  char trans = 'N';

  /* if no factorization is given, calculate it */
  if (solverData->factorization == 0)
  {
    /* solve J*(x_{n+1} - x_n)=f */
    dgetrf_(&n, &n, fjac, &n, iwork, &lapackinfo);
    solverData->factorization = 1;
    dgetrs_(&trans, &n, &nrsh, fjac, &n, iwork, fvec, &n, &lapackinfo);
  }
  else
  {
    dgetrs_(&trans, &n, &nrsh, fjac, &n, iwork, fvec, &n, &lapackinfo);
  }

  if(lapackinfo > 0)
  {
    warningStreamPrint(OMC_LOG_NLS, 0, "Newton iteration linear solver: Jacobian matrix singular.");
    return -1;
  }
  else if(lapackinfo < 0)
  {
    warningStreamPrint(OMC_LOG_NLS, 0, "illegal  input in argument %d", (int)lapackinfo);
    return -1;
  }
  else
  {
    /* save solution of J*(x_{n+1} - x_n)=f */
    memcpy(solverData->x_increment, fvec, n*sizeof(double));
  }

  return 0;
}

/**
 * @brief Calculate delta and error.
 *
 * Current value of x from input `x`, old value from `solverData->x_new`.
 * Current value of f(x) from input `fvec`, old value from `solverData->fvecScaled`
 *
 * @param solverData      Newton solver data.
 * @param delta_x         delta_x := ||x_new - x_old||
 * @param delta_x_scaled  delta_x_scaled := delta_x / scaling_factor, where
 *                        scaling_factor := ||x||
 * @param delta_f         delta_f := ||f_old - f_new||
 * @param error_f         error_f := ||fvec||
 * @param scaledError_f   scaledError_f := || fvec ./ resScaling||, where
 *                        resScaling is from solverData.
 * @param n               Length of arrays x and fvec.
 * @param x               New vector x.
 * @param fvec            New vector f(x).
 */
void calculatingErrors(DATA_NEWTON* solverData, double* delta_x, double* delta_x_scaled, double* delta_f, double* error_f,
                       double* scaledError_f, int n, double* x, double* fvec)
{
  int i=0;
  double scaling_factor;

  /* delta_x = || x_new-x_old || */
  for (i=0; i<n; i++)
    solverData->delta_x_vec[i] = x[i]-solverData->x_new[i];

  *delta_x = enorm_(&n,solverData->delta_x_vec);

  scaling_factor = enorm_(&n,x);
  if (scaling_factor > 1) {
    *delta_x_scaled = *delta_x * 1./ scaling_factor;
  } else {
    *delta_x_scaled = *delta_x;
  }

  /* delta_f = || f_old - f_new || */
  for (i=0; i<n; i++)
    solverData->delta_f[i] = solverData->f_old[i]-fvec[i];

  *delta_f=enorm_(&n, solverData->delta_f);

  *error_f = enorm_(&n,fvec);

  /* scaling residual vector */
  scaling_residual_vector(solverData);

  for (i=0; i<n; i++) {
    solverData->fvecScaled[i]=fvec[i]/solverData->resScaling[i];
  }
  *scaledError_f = enorm_(&n,solverData->fvecScaled);
}

/**
 * @brief Compute residual scaling vector.
 *
 * scalingVector[i] = 1 / ||Jac(i,:)||
 * Warn if Jacobian row is all zeros i.e. the Jacobian is singular.
 *
 * @param solverData      Newton solver data.
 * @param scalingVector   Residual scaling vector.
 */
void compute_scaling_vector(DATA_NEWTON* solverData, double* scalingVector) {
  int i;
  int jac_row_start;

  for(i=0; i<solverData->n; i++)
  {
    jac_row_start = i*solverData->n;
    scalingVector[i] = _omc_gen_maximumVectorNorm(&(solverData->fjac[jac_row_start]), solverData->n);
    if(scalingVector[i] <= 0.0) {
      warningStreamPrint(OMC_LOG_NLS_V, 1, "Jacobian matrix is singular.");
      scalingVector[i] = 1e-16;
    }
  }
}

/**
 * @brief Scale residual vector.
 *
 * Save result in solverData->fvecScaled.
 *
 * @param solverData  Newton solver data.
 */
void scaling_residual_vector(DATA_NEWTON* solverData)
{
  int i;

  compute_scaling_vector(solverData, solverData->resScaling);
  for(i=0; i<solverData->n; i++)
  {
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
void damping_heuristic(double* x, genericResidualFunc f,
                       double current_fvec_enorm, int n, double* fvec, double* lambda, int* k,
                       DATA_NEWTON* solverData, NLS_USERDATA* userData)
{
  int i,j=0;
  double enorm_new, treshold = 1e-2;
  modelica_boolean startDamping = FALSE; /* remember to close log message */

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userData, 1);
  solverData->nfev++;

  enorm_new=enorm_(&n,fvec);

  if (enorm_new >= current_fvec_enorm) {
    startDamping = TRUE;
    infoStreamPrint(OMC_LOG_NLS_V, 1, "Start Damping: enorm_new : %e; current_fvec_enorm: %e ", enorm_new, current_fvec_enorm);
  }

  while (enorm_new >= current_fvec_enorm)
  {
    j++;

    *lambda*=0.5;


    for (i=0; i<n; i++)
      solverData->x_new[i]=x[i]-*lambda*solverData->x_increment[i];


    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userData, 1);
    solverData->nfev++;

    enorm_new=enorm_(&n,fvec);

    if (*lambda <= treshold)
    {
      warningStreamPrint(OMC_LOG_NLS_V, 0, "Warning: lambda reached a threshold.");

      /* if damping is without success, trying full newton step;
         after 5 full newton steps try a very little step */
      if (*k >= 5)
        for (i=0; i<n; i++)
          solverData->x_new[i]=x[i]-*lambda*solverData->x_increment[i];
      else
        for (i=0; i<n; i++)
          solverData->x_new[i]=x[i]-solverData->x_increment[i];

      /* calculate new function values */
      (*f)(n, solverData->x_new, fvec, userData, 1);
      solverData->nfev++;

      (*k)++;

      break;
    }
  }

  *lambda = 1;

  if (startDamping)
    messageClose(OMC_LOG_NLS_V);
}

/*! \fn damping_heuristic2
 *
 *  second (default) damping heuristic:
 *  x_increment will be multiplied by 3/4 until the Euclidean norm of the
 *  residual function is smaller than the Euclidean norm of the current point
 *
 *  treshold for damping = 0.0001
 *  compiler flag: -newton = damped2
 */
void damping_heuristic2(double damping_parameter, double* x, genericResidualFunc f,
                        double current_fvec_enorm, int n, double* fvec, int* k,
                        DATA_NEWTON* solverData, NLS_USERDATA* userdata)
{
  int i,j=0;
  double enorm_new, treshold = 1e-4, lambda=1;
  modelica_boolean startDamping = FALSE; /* remember to close log message */

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userdata, 1);
  solverData->nfev++;

  enorm_new=enorm_(&n,fvec);

  if (enorm_new >= current_fvec_enorm) {
    startDamping = TRUE;
    infoStreamPrint(OMC_LOG_NLS_V, 1, "StartDamping:");
  }

  while (enorm_new >= current_fvec_enorm)
  {
    j++;

    lambda*=damping_parameter;

    infoStreamPrint(OMC_LOG_NLS_V, 0, "lambda = %e, k = %d", lambda, *k);

    for (i=0; i<n; i++)
      solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];


    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;

    enorm_new=enorm_(&n,fvec);

    if (lambda <= treshold)
    {
      warningStreamPrint(OMC_LOG_NLS_V, 0, "Warning: lambda reached a threshold.");

      /* if damping is without success, trying full newton step;
         after 5 full newton steps try a very little step */
      if (*k >= 5)
        for (i=0; i<n; i++)
          solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];
      else
        for (i=0; i<n; i++)
          solverData->x_new[i]=x[i]-solverData->x_increment[i];

      /* calculate new function values */
      (*f)(n, solverData->x_new, fvec, userdata, 1);
      solverData->nfev++;

      (*k)++;

      break;
    }
  }

  if (startDamping)
    messageClose(OMC_LOG_NLS_V);
}

/*! \fn LineSearch
 *
 *  third damping heuristic:
 *  Along the tangent 5 five points are selected. For every point the Euclidean
 *  norm of the residual function will be calculated and the minimum is chosen
 *  for the further iteration.
 *
 *  compiler flag: -newton = damped_ls
 */
void LineSearch(double* x, genericResidualFunc f,
                double current_fvec_enorm, int n, double* fvec, int* k,
                DATA_NEWTON* solverData, NLS_USERDATA* userdata)
{
  int i,j;
  double enorm_new, enorm_minimum=current_fvec_enorm, lambda_minimum=0;
  double lambda[5]={1.25,1,0.75,0.5,0.25};


  for (j=0; j<5; j++)
  {
    for (i=0; i<n; i++)
      solverData->x_new[i]=x[i]-lambda[j]*solverData->x_increment[i];

    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;

    enorm_new=enorm_(&n,fvec);

    /* searching minimal enorm */
    if (enorm_new < enorm_minimum)
    {
      enorm_minimum = enorm_new;
      lambda_minimum = lambda[j];
      memcpy(solverData->fvec_minimum, fvec,n*sizeof(double));
    }
  }

  infoStreamPrint(OMC_LOG_NLS_V,0,"lambda_minimum = %e", lambda_minimum);

  if (lambda_minimum == 0)
  {
    warningStreamPrint(OMC_LOG_NLS_V, 0, "Warning: lambda_minimum = 0 ");

    /* if damping is without success, trying full newton step;
       after 5 full newton steps try a very little step */
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
    memcpy(fvec, solverData->fvec_minimum, n*sizeof(double));
  }

  for (i=0; i<n; i++)
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
void Backtracking(double* x,
                  genericResidualFunc f,
                  double current_fvec_enorm,
                  int n,
                  double* fvec,
                  DATA_NEWTON* solverData,
                  NLS_USERDATA* userdata)
{
  int i,j;
  double enorm_new, enorm_f, lambda, a1, b1, a, b, tau, g1, g2;
  double tolerance = 1e-3;

  /* saving current function values in f_old */
  memcpy(solverData->f_old, fvec, n*sizeof(double));

  for (i=0; i<n; i++)
    solverData->x_new[i]=x[i]-solverData->x_increment[i];

  /* calculate new function values */
  (*f)(n, solverData->x_new, fvec, userdata, 1);
  solverData->nfev++;


  /* calculate new enorm */
  enorm_new = enorm_(&n,fvec);

  /* Backtracking only if full newton step is useless */
  if (enorm_new >= current_fvec_enorm)
  {
    infoStreamPrint(OMC_LOG_NLS_V, 0, "Start Backtracking\n enorm_new= %f \t current_fvec_enorm=%f", enorm_new, current_fvec_enorm);

    /* h(x) = 1/2 * ||f(x)|| ^2
     * g(lambda) = h(x_old + lambda * x_increment)
     * find minimum of g with golden ratio method
     * tau = golden ratio
     * */

    a = 0;
    b = 1;
    tau = 0.618033988749894848;

    a1 = a + (1-tau)*(b-a);
    /* g1 = g(a1) = h(x_old - a1 * x_increment) = 1/2 * ||f(x_old- a1 * x_increment)||^2 */
    solverData->x_new[i] = x[i]- a1 * solverData->x_increment[i];
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
    enorm_f= enorm_(&n,fvec);
    g1 = 0.5 * enorm_f * enorm_f;


    b1 = a + tau * (b-a);
    /* g2 = g(b1) = h(x_old - b1 * x_increment) = 1/2 * ||f(x_old- b1 * x_increment)||^2 */
    solverData->x_new[i] = x[i]- b1 * solverData->x_increment[i];
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
    enorm_f= enorm_(&n,fvec);
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
        enorm_f= enorm_(&n,fvec);
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
        enorm_f= enorm_(&n,fvec);
        g2 = 0.5 * enorm_f * enorm_f;
      }
    }

    lambda = (a+b)/2;

    /* print lambda */
    infoStreamPrint(OMC_LOG_NLS_V, 0, "Backtracking - lambda = %e", lambda);

    for (i=0; i<n; i++)
      solverData->x_new[i]=x[i]-lambda*solverData->x_increment[i];

    /* calculate new function values */
    (*f)(n, solverData->x_new, fvec, userdata, 1);
    solverData->nfev++;
  }
}

#ifdef __cplusplus
}
#endif
