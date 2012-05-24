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

#include "nelderMeadEx_initialization.h"
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
 *  \param [in]  [N] number of unfixed states and unfixed parameters
 *  \param [in]  [var] vector of unfixed states and unfixed parameters
 *  \param [in]  [scale] vector of nominal-values for var or NULL
 *  \param [in]  [initialResidualScalingCoefficients] vector of scaling-coefficients for initial_residuals or NULL
 *  \param [in]  [lambda_step]
 *  \param [in]  [acc]
 *  \param [in]  [maxIt]
 *  \param [in]  [dump]
 *  \param [in]  [pLambda]
 *  \param [in]  [pIteration]
 *  \param [in]  [leastSquare]
 *  \param [ref] [data]
 *  \param [in]  [initialResiduals]
 *
 *  \author lochel
 */
static void NelderMeadOptimization(INIT_DATA* initData,
    double lambda_step, double acc,
    long maxIt, long dump, double* pLambda, long* pIteration,
    double (*leastSquare)(DATA*, INIT_DATA*, double),
    DATA* data)
{
  long N = initData->nz;

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
  double fxk;

  long xb = 0;        /* best vertex */
  long xs = 0;        /* worst vertex */
  long xz = 0;        /* second-worst vertex */

  long x = 0;
  long i = 0;

  double lambda = *pLambda;
  long iteration = 0;

  /* check Memory */
  ASSERT(simplex, "out of memory");
  ASSERT(fvalues, "out of memory");
  ASSERT(xr, "out of memory");
  ASSERT(xe, "out of memory");
  ASSERT(xk, "out of memory");
  ASSERT(xbar, "out of memory");

  /* initialize simplex */
  for(x=0; x<N+1; x++)
  {
    for(i=0; i<N; i++)
    {
      /* vertex x / var i */
      simplex[x*N + i] = initData->zScaled[i];
    }
  }
  for(i=0; i<N; i++)
  {
    simplex[i*N + i] += 1.0;    /* canonical simplex */
  }

  setZScaled(initData, simplex);
  computeInitialResidualScalingCoefficients(data, initData);

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
      fvalues[x] = leastSquare(data, initData, lambda);
    }

    /* calculate xb, xs, xz */
    xb = 0;
    for(x=1; x<N+1; x++)
    {
      if(fvalues[x] < fvalues[xb])
        xb = x;
    }

    if(lambda >= 1.0 && fvalues[xb] < acc)
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
      INFO4("NelderMeadOptimization | lambda=%g / step=%d / f=%g [%g]", lambda, (int)iteration, fvalues[xb], fvalues[xs]);

    if(sigma < g)
    {
      if(lambda < 1.0)
      {
        lambda += lambda_step;
        if(lambda >= 1.0)
          break;

        DEBUG_INFO3(LOG_INIT, "NelderMeadOptimization | increasing lambda to %g in step %d at f=%g", lambda, (int)iteration, fvalues[xb]);
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
    fxr = leastSquare(data, initData, lambda);

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
      fxe = leastSquare(data, initData, lambda);

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
        fxk = leastSquare(data, initData, lambda);
      }
      else
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(xr[i] - xbar[i]);

        setZScaled(initData, xk);
        fxk = leastSquare(data, initData, lambda);
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
      WARNING1("fxr = %g", fxr);
      WARNING1("fxk = %g", fxk);

      THROW("undefined error in NelderMeadOptimization");
    }
  }while(1.0);

  /* copying solution */
  setZScaled(initData, &simplex[xb*N]);

  if(pLambda)
    *pLambda = lambda;

  if(pIteration)
    *pIteration = iteration;

  free(xe);
  free(xr);
  free(xk);
  free(xbar);
  free(fvalues);
  free(simplex);
}

/*! \fn nelderMeadEx_initialization
 *
 *  This function performs initialization by using an extend version of the
 *  nelderMead algorithm.
 *  This does not require a jacobian for the residuals.
 *
 *  \param [ref] [data]
 *  \param [in]  [nz] number of unfixed states and unfixed parameters
 *  \param [in]  [z] vector of unfixed states and unfixed parameters
 *  \param [in]  [zName] variable names
 *  \param [in]  [zNominal] vector of nominal-values for z
 *  \param [in]  [initialResiduals]
 *
 *  \author lochel
 */
int nelderMeadEx_initialization(DATA *data, INIT_DATA* initData, double lambdaStart)
{
  double STOPCR = 1.e-12;
  double lambda_step = 0.2;
  long NLOOP = 1000 * initData->nz;

  double funcValue;

  double lambda = lambdaStart;
  long iteration = 0;

  long l=0, i=0;

  double* bestZ = (double*)malloc(initData->nz * sizeof(double));
  double bestFuncValue;

  /* down-scale */
  updateZScaled(initData);

  funcValue = leastSquareWithLambda(data, initData, 1.0);

  bestFuncValue = funcValue;
  for(i=0; i<initData->nz; i++)
    bestZ[i] = initData->z[i];

  for(l=0; l<200 && funcValue > STOPCR; l++)
  {
    DEBUG_INFO1(LOG_INIT, "initialization-nr. %ld", l);

    NelderMeadOptimization(initData, lambda_step, STOPCR, NLOOP, DEBUG_FLAG(LOG_INIT) ? 10000 : 0, &lambda, &iteration, leastSquareWithLambda, data);

    storePreValues(data);                       /* save pre-values */
    overwriteOldSimulationData(data);           /* if there are non-linear equations */
    update_DAEsystem(data);                     /* evaluate discrete variables */

    /* valid system for the first time! */
    SaveZeroCrossings(data);
    storePreValues(data);
    overwriteOldSimulationData(data);

    funcValue = leastSquareWithLambda(data, initData, 1.0);

    DEBUG_INFO1(LOG_INIT, "ending with funcValue = %g", funcValue);
    DEBUG_INFO_AL1(LOG_INIT, "| iterations: %ld", iteration);
    DEBUG_INFO_AL1(LOG_INIT, "| lambda: %g", lambda);
    DEBUG_INFO_AL(LOG_INIT, "| unfixed variables");
    for(i=0; i<initData->nz; i++)
      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] %s = %g [scaled: %g]", i+1, initData->name[i], initData->z[i], initData->zScaled[i]);
    DEBUG_INFO_AL(LOG_INIT, "| residuals (> 0.001)");
    for(i=0; i<data->modelData.nInitResiduals; i++)
      if(fabs(initData->initialResiduals[i]) > 1e-3)
        DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] %g [scaled: %g]", i+1, initData->initialResiduals[i], (initData->residualScalingCoefficients[i] != 0.0) ? initData->initialResiduals[i]/initData->residualScalingCoefficients[i] : 0.0);

    if(funcValue < bestFuncValue)
    {
      bestFuncValue = funcValue;
      for(i=0; i<initData->nz; i++)
        bestZ[i] = initData->z[i];
    }
    else if(funcValue == bestFuncValue)
    {
      WARNING("local minimum");
      break;
    }
  }
  free(bestZ);

  DEBUG_INFO1(LOG_INIT, "optimization-calls: %ld", l);

  /* up-scale */
  updateZ(initData);

  if(lambda < 1.0 && funcValue > STOPCR)
    return -1;

  return reportResidualValue(data, initData, funcValue);
}
