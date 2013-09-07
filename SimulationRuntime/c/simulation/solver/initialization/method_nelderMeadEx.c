/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*! \file nelderMeadEx_initialization.c
 */

#include "method_nelderMeadEx.h"
#include "simulation_data.h"
#include "omc_error.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "model_help.h"
#include "read_matlab4.h"
#include "events.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/*! \fn NelderMeadOptimization
 *
 *  This function performs a Nelder-Mead-Optimization with some
 *  special changes for initialization.
 *
 *  \param [ref] [initData] number of unfixed states and unfixed parameters
 *  \param [in]  [lambda_steps] number of steps for homotopy process
 *  \param [in]  [acc]
 *  \param [in]  [maxIt]
 *  \param [in]  [dump]
 *  \param [in]  [pLambda]
 *  \param [in]  [pIteration]
 *  \param [in]  [leastSquare] pointer to objective function
 *
 *  \author lochel
 */
static void NelderMeadOptimization(INIT_DATA* initData,
  long lambda_steps, double acc, long maxIt, long dump, double* pLambda, long* pIteration,
  double (*leastSquare)(INIT_DATA*, double))
{
  long N = initData->nVars;

  const double alpha    = 1.0;        /* 0 < alpha */
  const double beta     = 2;          /* 1 < beta */
  const double gamma    = 0.5;        /* 0 < gamma < 1 */

  double* simplex = (double*)malloc((N+1)*N*sizeof(double));
  double* fvalues = (double*)malloc((N+1)*sizeof(double));

  double* xr = (double*)malloc(N * sizeof(double));
  double* xe = (double*)malloc(N * sizeof(double));
  double* xk = (double*)malloc(N * sizeof(double));
  double* xbar = (double*)malloc(N * sizeof(double));

  double fxr;
  double fxe;
  double fxk = 0;

  long xb = 0;        /* best vertex */
  long xs = 0;        /* worst vertex */
  long xz = 0;        /* second-worst vertex */

  long x = 0;
  long i = 0;

  double resMax;

  double lambda = *pLambda;
  long iteration = 0;

  FILE *pFile = NULL;

  if(ACTIVE_STREAM(LOG_INIT) && (lambda < 1.0))
  {
    char buffer[4096];
    sprintf(buffer, "%s_initPath.csv", initData->simData->modelData.modelFilePrefix);
    pFile = fopen(buffer, "wt");
    fprintf(pFile, "%s,", "iteration");
    fprintf(pFile, "%s,", "lambda");
    for(i=0; i<initData->nVars; ++i)
      fprintf(pFile, "%s,", initData->name[i]);
    fprintf(pFile, "\n");

    fprintf(pFile, "%ld,", iteration);
    fprintf(pFile, "%.16g,", lambda);
    for(i=0; i<initData->nVars; ++i)
      fprintf(pFile, "%.16g,", initData->vars[i]);
    fprintf(pFile, "\n");
  }

  /* check Memory */
  ASSERT(simplex, "out of memory");
  ASSERT(fvalues, "out of memory");
  ASSERT(xr, "out of memory");
  ASSERT(xe, "out of memory");
  ASSERT(xk, "out of memory");
  ASSERT(xbar, "out of memory");

  /* initialize simplex */
  if(initData->nominal)
  {
    for(i=0; i<N; i++)
    {
      double sx = initData->vars[i] / initData->nominal[i];
      for(x=0; x<N+1; x++)
      {
        /* vertex x / var i */
        simplex[x*N + i] = sx;
      }
    }
  }
  else
  {
    for(i=0; i<N; i++)
    {
      for(x=0; x<N+1; x++)
      {
        /* vertex x / var i */
        simplex[x*N + i] = initData->vars[i];
      }
    }
  }
  for(i=0; i<N; i++)
  {
    simplex[i*N + i] += 1.0;    /* canonical simplex */
  }

  do
  {
    /* lambda-control */
    double sigma = 0.0;
    double average = 0.0;
    double g = 1e-8;

    iteration++;

    /* func-values for the simplex */
    for(x=0; x<N+1; x++)
    {
      setZScaled(initData, &simplex[x*N]);
      fvalues[x] = leastSquare(initData, lambda);
    }

    /* calculate xb, xs, xz */
    xb = 0;
    for(x=1; x<N+1; x++)
    {
      if(fvalues[x] < fvalues[xb])
        xb = x;
    }

    /* calc residuals for xb */
    setZScaled(initData, &simplex[xb*N]);
    leastSquare(initData, lambda);
    /* finx max */
    resMax = 0.0;
    for(x=0; x<initData->nInitResiduals; x++)
      if(fabs(initData->initialResiduals[x]) > resMax)
        resMax = fabs(initData->initialResiduals[x]);

    if(lambda >= 1.0 && resMax < acc)
      break;

    if(maxIt < iteration)
      break;

    xs = xb;
    xz = xb;
    for(x=0; x<N+1; x++)
    {
      if(fvalues[x] > fvalues[xs])
      {
        xz = xs;
        xs = x;
      }

      if(fvalues[x] > fvalues[xz] && (x != xs))
        xz = x;
    }

    for(x=0; x<N+1; x++)
      average += fvalues[x];
    average /= (N+1);

    for(x=0; x<N+1; x++)
      sigma += (fvalues[x] - average) * (fvalues[x] - average);
    sigma /= N;

    /* dump every dump-th step */
    if(dump && !(iteration % dump))
      INFO4(LOG_INIT, "lambda is %-3g in step=%6d at f=%g [%g]", lambda, (int)iteration, fvalues[xb], fvalues[xs]);

    if(sigma < g)
    {
      if(lambda < 1.0)
      {
        lambda += ((double)1.0)/(lambda_steps-1);
        if(lambda > 1.0)
          lambda = 1.0;

        INFO3(LOG_INIT, "increasing lambda to %-3g in step %6d at f=%g", lambda, (int)iteration, fvalues[xb]);
        if(pFile)
        {
          fprintf(pFile, "%ld,", iteration);
          fprintf(pFile, "%.16g,", lambda);
          for(i=0; i<initData->nVars; ++i)
            fprintf(pFile, "%.16g,", initData->vars[i]);
          fprintf(pFile, "\n");
        }
        continue;
      }
    }

    /* calculate central point for the n best vertices */
    for(i=0; i<N; i++)
      xbar[i] = 0;

    for(x=0; x<N+1; x++)
    {
      if(x != xs)            /* leaving worst vertex */
      {
        for(i=0; i<N; i++)
          xbar[i] += simplex[x*N+i];
      }
    }

    for(i=0; i<N; i++)
      xbar[i] /= N;

    /* reflect worst vertex at xbar */
    for(i=0; i<N; i++)
      xr[i] = xbar[i] + alpha*(xbar[i] - simplex[xs*N + i]);

    setZScaled(initData, xr);
    fxr = leastSquare(initData, lambda);

    if(fvalues[xb] <= fxr && fxr <= fvalues[xz])
    {
      /* replace xs by xr */
      for(i=0; i<N; i++)
        simplex[xs*N+i] = xr[i];
    }
    else if(fxr <= fvalues[xb])
    {
      for(i=0; i<N; i++)
        xe[i] = xbar[i] + beta*(xr[i] - xbar[i]);

      setZScaled(initData, xe);
      fxe = leastSquare(initData, lambda);

      if(fxe < fxr)    /* if(fxe < fvalues[xb]) */
      {
        /* replace xs by xe */
        for(i=0; i<N; i++)
          simplex[xs*N+i] = xe[i];
      }
      else
      {
        /* replace xs by xr */
        for(i=0; i<N; i++)
          simplex[xs*N+i] = xr[i];
      }
    }
    else if(fvalues[xz] <= fxr)
    {
      if(fxr >= fvalues[xs])
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(simplex[xs*N+i] - xbar[i]);

        setZScaled(initData, xk);
        fxk = leastSquare(initData, lambda);
      }
      else
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(xr[i] - xbar[i]);

        setZScaled(initData, xk);
        fxk = leastSquare(initData, lambda);
      }

      if(fxk < fvalues[xs])
      {
        /* replace xs by xk */
        for(i=0; i<N; i++)
          simplex[xs*N+i] = xk[i];
      }
      else
      {
        /* constrict simplex around xb */
        for(x=0; x<N+1; x++)
        {
          for(i=0; i<N; i++)
          {
            simplex[x*N+i] = (simplex[x*N+i] + simplex[xb*N+i]) / 2.0;
          }
        }
      }
    }
    else
    {
      /* not possible to be here */
      WARNING1(LOG_INIT, "fxr = %g", fxr);
      WARNING1(LOG_INIT, "fxk = %g", fxk);

      THROW("undefined error in NelderMeadOptimization");
    }
  }while(1.0);

  /* copying solution */
  setZScaled(initData, &simplex[xb*N]);

  if(pLambda)
    *pLambda = lambda;

  if(pIteration)
    *pIteration = iteration;

  if(pFile)
  {
    fprintf(pFile, "%ld,", iteration);
    fprintf(pFile, "%.16g,", lambda);
    for(i=0; i<initData->nVars; ++i)
      fprintf(pFile, "%.16g,", initData->vars[i]);
    fprintf(pFile, "\n");
    fclose(pFile);
  }

  free(xe);
  free(xr);
  free(xk);
  free(xbar);
  free(fvalues);
  free(simplex);
}

/*! \fn int nelderMeadEx_initialization(INIT_DATA *initData, double lambdaStart)
 *
 *  This function performs initialization by using an extended version of the
 *  nelderMead algorithm.
 *  This does not require a jacobian for the residuals.
 *
 *  \param [ref] [initData]
 *  \param [in]  [lambda]
 *
 *  \author lochel
 */
int nelderMeadEx_initialization(INIT_DATA *initData, double *lambda, long lambda_steps)
{
  double STOPCR = 1.e-12;
  long NLOOP = 1000 * initData->nVars * lambda_steps;
  long iteration = 0;
  int retVal;

  INFO(LOG_INIT, "NelderMeadOptimization");
  INDENT(LOG_INIT);
  NelderMeadOptimization(initData, lambda_steps, STOPCR, NLOOP, ACTIVE_STREAM(LOG_INIT) ? NLOOP/10 : 0, lambda, &iteration, leastSquareWithLambda);
  INFO1(LOG_INIT, "iterations: %ld", iteration);
  RELEASE(LOG_INIT);

  if(*lambda < 1.0)
    return -1;

  retVal = reportResidualValue(initData);
  
  if(0 != retVal)
    WARNING(LOG_INIT, "try -ils to activate start value homotopy");
    
  return retVal;
}
