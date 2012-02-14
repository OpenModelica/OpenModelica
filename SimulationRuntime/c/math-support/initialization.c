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

/*! \file initialization.c
 */

#include "initialization.h"
#include "simulation_data.h"
#include "error.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "model_help.h"

#include <math.h>
#include <string.h>

enum INIT_INIT_METHOD
{
  IIM_UNKNOWN = 0,
  IIM_STATE
};

const char *initMethodStr[2] = {"unknown", "state"};

enum INIT_OPTI_METHOD
{
  IOM_UNKNOWN = 0,
  IOM_NELDER_MEAD_EX
};

const char *optiMethodStr[2] = {"unknown", "nelder_mead_ex"};

/*! \fn leastSquareWithLambda
 *
 *  This function calculates the residual value
 *  as the sum of squared residual equations.
 *
 *  \param [ref] [data]
 *  \param [in]  [nz] number of unfixed states and unfixed parameters
 *  \param [in]  [z] vector of unfixed states and unfixed parameters
 *  \param [in]  [zNominal] vector of nominal-values for z or NULL
 *  \param [in]  [initialResidualScalingCoefficients] vector of scaling-coefficients for initial_residuals or NULL
 *  \param [in]  [lambda] E [0; 1]
 *  \param [out] [initialResiduals]
 */
static double leastSquareWithLambda(DATA* data, long nz, double* z, double* zNominal, double* initialResidualScalingCoefficients, double lambda, double* initialResiduals)
{
  int indz = 0;
  fortran_integer i = 0;
  long j = 0;
  double funcValue = 0.0;
  double scalingCoefficient;

  for(i=0; i<data->modelData.nStates; ++i)
  {
    if(data->modelData.realVarsData[i].attribute.fixed==0)
    {
      data->localData[0]->realVars[i] = z[indz] * (zNominal ? zNominal[indz] : 1.0);
      indz++;
    }
  }

  /* for real parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
  {
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
    {
      data->simulationInfo.realParameter[i] = z[indz] * (zNominal ? zNominal[indz] : 1.0);
      indz++;
    }
  }

  updateBoundParameters(data);
  functionODE(data);
  functionAlgebraics(data);
  initial_residual(data, lambda, initialResiduals);

  if (initialResidualScalingCoefficients)
  {
    /* use scaling coefficients */
    for(j=0; j<data->modelData.nResiduals; ++j)
    {
      scalingCoefficient = initialResidualScalingCoefficients[j];
      if(scalingCoefficient > 0.0)
        funcValue += (initialResiduals[j] / scalingCoefficient) * (initialResiduals[j] / scalingCoefficient);
    }
  }
  else
  {
    /* no scaling coefficients given */
    for(j=0; j<data->modelData.nResiduals; ++j)
    {
      funcValue += initialResiduals[j] * initialResiduals[j];
    }
  }

  return funcValue;
}

/*! \fn computeInitialResidualScalingCoefficients
 *
 *  This function calculates coefficients for every initial_residual.
 *  They describe the order of magnitude.
 *
 *  \param [ref] [data]
 *  \param [in]  [nz] number of unfixed states and unfixed parameters
 *  \param [in]  [z] vector of unfixed states and unfixed parameters
 *  \param [in]  [zNominal] vector of nominal-values for z or NULL
 *  \param [out] [initialResidualScalingCoefficients] vector of scaling-coefficients for initial_residuals
 *
 *  \author lochel
 */
static void computeInitialResidualScalingCoefficients(DATA *data, double nz, double *z, double *zNominal, double *initialResidualScalingCoefficients)
{
  int i, j;

  double *tmpInitialResidual1 = (double*)malloc(data->modelData.nResiduals * sizeof(double));
  double *tmpInitialResidual2 = (double*)malloc(data->modelData.nResiduals * sizeof(double));
  double *states = (double*)malloc(nz * sizeof(double));

  const double h = 1e-6;

  for(j=0; j<data->modelData.nResiduals; ++j)
    initialResidualScalingCoefficients[j] = 0.0;

  if (zNominal)
  {
    for(i=0; i<nz; ++i)
      states[i] = z[i] * zNominal[i];
  }
  else
  {
    for(i=0; i<nz; ++i)
      states[i] = z[i];
  }

  /* lambda = 1.0 */
  leastSquareWithLambda(data, nz, states, NULL, NULL, 1.0, tmpInitialResidual1);

  for(i=0; i<nz; ++i)
  {
    states[i] += h;
    leastSquareWithLambda(data, nz, states, NULL, NULL, 1.0, tmpInitialResidual2);

    for(j=0; j<data->modelData.nResiduals; ++j)
    {
      double f = fabs(zNominal[i] * (tmpInitialResidual2[j] - tmpInitialResidual1[j]) / h /* / tmpInitialResidual2[j] */ );
      if(f > initialResidualScalingCoefficients[j])
        initialResidualScalingCoefficients[j] = f;
    }
    states[i] -= h;
  }

  /* lambda = 0.0 */
  leastSquareWithLambda(data, nz, states, NULL, NULL, 0.0, tmpInitialResidual1);

  for(i=0; i<nz; ++i)
  {
    states[i] += h;
    leastSquareWithLambda(data, nz, states, NULL, NULL, 0.0, tmpInitialResidual2);

    for(j=0; j<data->modelData.nResiduals; ++j)
    {
      double f = fabs(zNominal[i] * (tmpInitialResidual2[j] - tmpInitialResidual1[j]) / h /* / tmpInitialResidual2[j] */ );
      if(f > initialResidualScalingCoefficients[j])
        initialResidualScalingCoefficients[j] = f;
    }
    states[i] -= h;
  }

  DEBUG_INFO(LOG_INIT, "initial residuals scaling coefficients");
  for(j=0; j<data->modelData.nResiduals; ++j)
  {
    if(initialResidualScalingCoefficients[j] < 1e-42)
    {
      initialResidualScalingCoefficients[j] = 0.0;
      DEBUG_INFO_AL2(LOG_INIT, "   initial residual no. %d: %g [ineffective]", j, initialResidualScalingCoefficients[j]);
    }
    else
    {
      DEBUG_INFO_AL2(LOG_INIT, "   initial residual no. %d: %g", j, initialResidualScalingCoefficients[j]);
    }
  }

  free(tmpInitialResidual1);
  free(tmpInitialResidual2);
  free(states);
}

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
static void NelderMeadOptimization(long N,
  double* var,
  double* scale,
  double* initialResidualScalingCoefficients,
  double lambda_step,
  double acc,
  long maxIt,
  long dump,
  double* pLambda,
  long* pIteration,
  double (*leastSquare)(DATA*, long, double*, double*, double*, double, double*),
  DATA* data,
  double* initialResiduals)
{
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
      simplex[x*N + i] = var[i];
    }
  }
  for(i=0; i<N; i++)
  {
    simplex[i*N + i] += 1.0;    /* canonical simplex */
  }

  computeInitialResidualScalingCoefficients(data, N, simplex, scale, initialResidualScalingCoefficients);

  do
  {
    /* lambda-control */
    double sigma = 0.0;
    double average = 0.0;
    double g = 1e-8;

    iteration++;

    /* func-values for the simplex */
    for(x=0; x<N+1; x++)
      fvalues[x] = leastSquare(data, N, &simplex[x*N], scale, initialResidualScalingCoefficients, lambda, initialResiduals);

    /* calculate xb, xs, xz */
    xb = 0;
    for(x=1; x<N+1; x++)
    {
      if(fvalues[x] < fvalues[xb])
        xb = x;
    }

    if(fvalues[xb] < acc)
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
    fxr = leastSquare(data, N, xr, scale, initialResidualScalingCoefficients, lambda, initialResiduals);

    if(fvalues[xb] <= fxr && fxr <= fvalues[xz])
    {
      /* replace xs by xr */
      for(i=0; i<N; i++)
        simplex[xs*N+i] = xr[i];
    }
    else if(fxr < fvalues[xb])
    {
      for(i=0; i<N; i++)
        xe[i] = xbar[i] + beta*(xr[i] - xbar[i]);
      fxe = leastSquare(data, N, xe, scale, initialResidualScalingCoefficients, lambda, initialResiduals);

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
    else if(fxr > fvalues[xz])
    {
      if(fxr >= fvalues[xs])
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(simplex[xs*N+i] - xbar[i]);
        fxk = leastSquare(data, N, xk, scale, initialResidualScalingCoefficients, lambda, initialResiduals);
      }
      else
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(xr[i] - xbar[i]);
        fxk = leastSquare(data, N, xk, scale, initialResidualScalingCoefficients, lambda, initialResiduals);
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
      INFO("not possible to be here");
    }
  }while(1.0);

  /* copying solution */
  for(i=0; i<N; i++)
    var[i] = simplex[xb*N+i];

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

/*! \fn reportResidualValue
 *
 *  Returns 1 if residual is non-zero and prints appropriate error message.
 *
 *  \param [ref] [data]
 *  \param [in]  [funcValue] leastSquare-Value
 *  \param [in]  [initialResiduals]
 */
static int reportResidualValue(DATA* data, double funcValue, double* initialResiduals)
{
  long i = 0;
  if(funcValue > 1e-5)
  {
    WARNING("reportResidualValue | error in initialization. System of initial equations are not consistent");
    WARNING1("reportResidualValue | (Least Square function value is %g)", funcValue);

    for(i=0; i<data->modelData.nResiduals; i++)
    {
      if(fabs(initialResiduals[i]) > 1e-6)
      {
        INFO2("reportResidualValue | residual[%d] = %g", (int) i, initialResiduals[i]);
      }
    }
    return 1;
  }
  return 0;
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
static int nelderMeadEx_initialization(DATA *data, long nz, double *z, char** zName, double *zNominal, double* initialResiduals)
{
  double STOPCR = 1.e-12;
  double lambda_step = 0.2;
  long NLOOP = 1000 * nz;

  double funcValue;

  double lambda = 0;
  long iteration = 0;

  long l=0, i=0;

  double* initialResidualScalingCoefficients = (double*)malloc(data->modelData.nResiduals * sizeof(double));
  double* bestZ = (double*)malloc(nz * sizeof(double));
  double bestFuncValue;

  /* down-scale */
  for(i=0; i<nz; i++)
    z[i] /= zNominal[i];

  funcValue = leastSquareWithLambda(data, nz, z, zNominal, NULL, 1.0, initialResiduals);

  bestFuncValue = funcValue;
  for(i=0; i<nz; i++)
	  bestZ[i] = z[i];

  DEBUG_INFO(LOG_INIT, "starting with...");
  for(i=0; i<nz; i++)
    DEBUG_INFO_AL4(LOG_INIT, "   z[%ld]: %s(nominal=%g) = %g", i, zName[i], zNominal[i], z[i]);
  DEBUG_INFO_AL1(LOG_INIT, "   funcValue = %g", funcValue);

  for(l=0; l<100 && funcValue > STOPCR; l++)
  {
    DEBUG_INFO1(LOG_INIT, "initialization-nr. %ld", l);

    NelderMeadOptimization(nz, z, zNominal, initialResidualScalingCoefficients, lambda_step, STOPCR, NLOOP, DEBUG_FLAG(LOG_INIT) ? 10000 : 0, &lambda, &iteration, leastSquareWithLambda, data, initialResiduals);

    storePreValues(data);                       /* save pre-values */
    overwriteOldSimulationData(data);           /* if there are non-linear equations */
    update_DAEsystem(data);                     /* evaluate discrete variables */

    /* valid system for the first time! */
    SaveZeroCrossings(data);
    storePreValues(data);
    overwriteOldSimulationData(data);

    funcValue = leastSquareWithLambda(data, nz, z, zNominal, initialResidualScalingCoefficients, 1.0, initialResiduals);

    DEBUG_INFO1(LOG_INIT, "ending with funcValue = %g", funcValue);
    DEBUG_INFO_AL1(LOG_INIT, "   iterations: %ld", iteration);
    DEBUG_INFO_AL1(LOG_INIT, "   lambda: %g", lambda);
    for(i=0; i<nz; i++)
      DEBUG_INFO_AL3(LOG_INIT, "   z[%ld]: %s = %g", i, zName[i], z[i] * (zNominal ? zNominal[i] : 1.0));
    for(i=0; i<data->modelData.nResiduals; i++)
      if(fabs(initialResiduals[i]) > 1e-3)
        DEBUG_INFO_AL2(LOG_INIT, "   residual[%ld] = %g", i, initialResiduals[i]);

    if(funcValue < bestFuncValue)
    {
      bestFuncValue = funcValue;
      for(i=0; i<nz; i++)
        bestZ[i] = z[i];
    }
    else if(funcValue == bestFuncValue)
    {
      WARNING("local minimum");
      break;
    }
  }
  free(initialResidualScalingCoefficients);
  free(bestZ);

  DEBUG_INFO_AL1(LOG_INIT, "   optimization-calls: %ld", l);

  /* up-scale */
  for(i=0; i<nz; i++)
    z[i] *= zNominal[i];

  if(lambda < 1.0 && funcValue > STOPCR)
    return -1;

  return reportResidualValue(data, funcValue, initialResiduals);
}

typedef struct INIT_DATA
{
  long nz;
  long nStates;
  long nParameters;
  double *z;
  double *zNominal;
  char** zName;
}INIT_DATA;

/*! \fn freeInitData
 *
 *  \param [ref] [initData]
 *
 *  \author lochel
 */
static void freeInitData(INIT_DATA *initData)
{
  free(initData->z);
  free(initData->zNominal);
  free(initData->zName);
  free(initData);
}

/*! \fn initializeInitData
 *
 *  \param [in]  [data]
 *
 *  \author lochel
 */
static INIT_DATA *initializeInitData(DATA *data)
{
  long i;
  long iz;
  INIT_DATA *initData = (INIT_DATA*) malloc(sizeof(INIT_DATA));

  initData->nz = 0;
  initData->nStates = 0;
  initData->nParameters = 0;
  initData->z = NULL;
  initData->zNominal = NULL;
  initData->zName = NULL;

  /* count unfixed states */
  for(i=0; i<data->modelData.nStates; ++i)
    if(data->modelData.realVarsData[i].attribute.fixed == 0)
      ++initData->nz;
  initData->nStates = initData->nz;

  /* plus unfixed real-parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
      ++initData->nz;
  initData->nParameters = initData->nz - initData->nStates;

  if(initData->nz == 0)
  {
    freeInitData(initData);
    return NULL;
  }

  initData->z = (double*)calloc(initData->nz, sizeof(double));
  initData->zNominal = (double*)calloc(initData->nz, sizeof(double));
  initData->zName = (char**)calloc(initData->nz, sizeof(char*));
  ASSERT(initData->z, "out of memory");
  ASSERT(initData->zNominal, "out of memory");
  ASSERT(initData->zName, "out of memory");

  /* setup initData */
  for(i=0, iz=0; i<data->modelData.nStates; ++i)
  {
    if(data->modelData.realVarsData[i].attribute.fixed == 0)
    {
      initData->zNominal[iz] = fabs(data->modelData.realVarsData[i].attribute.nominal);
      if(initData->zNominal[iz] == 0.0)
        initData->zNominal[iz] = 1.0;
      initData->z[iz] = data->modelData.realVarsData[i].attribute.start;
      initData->zName[iz] = data->modelData.realVarsData[i].info.name;
      iz++;
    }
  }

  for(i=0; i<data->modelData.nParametersReal; ++i)
  {
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
    {
      initData->zNominal[iz] = fabs(data->modelData.realParameterData[i].attribute.nominal);
      if(initData->zNominal[iz] == 0.0)
        initData->zNominal[iz] = 1.0;
      initData->z[iz] = data->modelData.realParameterData[i].attribute.start;
      initData->zName[iz] = data->modelData.realParameterData[i].info.name;
      iz++;
    }
  }

  return initData;
}

/*! \fn initialize
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *
 *  \author lochel
 */
static int initialize(DATA *data, int optiMethod)
{
  int retVal = -1;
  const double h = 1e-6;
  double *initialResiduals = NULL;
  long i, j, k;
  double f;
  double *z_f = NULL;

  INIT_DATA *initData = initializeInitData(data);

  /* no initial values to calculate. */
  if(initData == NULL)
  {
    DEBUG_INFO(LOG_INIT, "no variables to initialize");
    return 0;
  }

  if(data->modelData.nInitEquations == 0)
  {
    DEBUG_INFO(LOG_INIT, "no initial equations");
    return 0;
  }

  initialResiduals = (double*) calloc(data->modelData.nResiduals, sizeof(double));
  ASSERT(initialResiduals, "out of memory");

  DEBUG_INFO(LOG_INIT, "initial problem:");
  DEBUG_INFO_AL1(LOG_INIT, "   number of unfixed variables: %ld", initData->nz);
  DEBUG_INFO_AL1(LOG_INIT, "   number of initial equations: %ld", data->modelData.nInitEquations);

  if(data->modelData.nInitEquations < initData->nz)
  {
    DEBUG_INFO_AL(LOG_INIT, "   [under-determined]");

    z_f = (double*)calloc(initData->nz, sizeof(double));
    f = leastSquareWithLambda(data, initData->nz, initData->z, NULL, NULL, 1.0, initialResiduals);
    for(i=0; i<initData->nz; ++i)
    {
      initData->z[i] += h;
      z_f[i] = fabs(leastSquareWithLambda(data, initData->nz, initData->z, NULL, NULL, 1.0, initialResiduals) - f) / h;
      initData->z[i] -= h;
    }

    for(j=0; j < data->modelData.nInitEquations; ++j)
    {
      k = 0;
      for(i=1; i<initData->nz; ++i)
        if(z_f[i] > z_f[k])
          k = i;
      z_f[k] = -1.0;
    }

    k = 0;
    DEBUG_INFO(LOG_INIT, "setting fixed=true for:");
    for(i=0; i<data->modelData.nStates; ++i)
    {
      if(data->modelData.realVarsData[i].attribute.fixed == 0)
      {
        if(z_f[k] >= 0.0)
        {
          data->modelData.realVarsData[i].attribute.fixed = 1;
          DEBUG_INFO2(LOG_INIT, "   %s(fixed=true) = %g", initData->zName[k], initData->z[k]);
        }
        k++;
      }
    }
    for(i=0; i<data->modelData.nParametersReal; ++i)
    {
      if(data->modelData.realParameterData[i].attribute.fixed == 0)
      {
        if(z_f[k] >= 0.0)
        {
          data->modelData.realParameterData[i].attribute.fixed = 1;
          DEBUG_INFO2(LOG_INIT, "   %s(fixed=true) = %g", initData->zName[k], initData->z[k]);
        }
        k++;
      }
    }

    free(z_f);

    freeInitData(initData);
    initData = initializeInitData(data);
    /* no initial values to calculate. (not possible to be here)*/
    if(initData == NULL)
    {
      DEBUG_INFO(LOG_INIT, "no initial values to calculate");
      return 0;
    }
  }
  else if(data->modelData.nInitEquations > initData->nz)
    DEBUG_INFO_AL(LOG_INIT, "   [over-determined]");

  DEBUG_INFO1(LOG_INIT, "%ld unfixed states:", initData->nStates);
  for(i=0; i<initData->nStates; ++i)
    DEBUG_INFO_AL2(LOG_INIT, "   [%ld] %s", i, initData->zName[i]);
  DEBUG_INFO1(LOG_INIT, "%ld unfixed parameters:", initData->nParameters);
  for(; i<initData->nz; ++i)
    DEBUG_INFO_AL2(LOG_INIT, "   [%ld] %s", i, initData->zName[i]);

  if(optiMethod == IOM_NELDER_MEAD_EX)
    retVal = nelderMeadEx_initialization(data, initData->nz, initData->z, initData->zName, initData->zNominal, initialResiduals);
  else
  {
    WARNING1("unrecognized option -iom %s", optiMethodStr[optiMethod]);
  }

  free(initialResiduals);
  freeInitData(initData);
  return retVal;
}

/*! \fn state_initialization
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *
 *  \author lochel
 */
static int state_initialization(DATA *data, int optiMethod)
{
  int retVal = 0, i;

  /* set up all variables and parameters with their start-values */
  setAllVarsToStart(data);
  setAllParamsToStart(data);
  updateBoundStartValues(data);
  updateBoundParameters(data);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);
  update_DAEsystem(data);

  /* and restore start values and helpvars */
  restoreExtrapolationDataOld(data);
  resetAllHelpVars(data);
  storePreValues(data);

  /* debug print */
  if(DEBUG_FLAG(LOG_DEBUG))
    for(i=0; i<3;i++)
      printAllVars(data, i);

  /* start with the real initialization */
  data->simulationInfo.initial = 1;             /* to evaluate when-equations with initial()-conditions */
  retVal = initialize(data, optiMethod);

  /* debug print */
  if(DEBUG_FLAG(LOG_DEBUG))
    for(i=0; i<3;i++)
      printAllVars(data, i);

  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */
  update_DAEsystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  SaveZeroCrossings(data);
  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */

  data->simulationInfo.initial = 0;

  return retVal;
}

/*! \fn initialization
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pOptiMethod] user defined optimization method
 *
 *  \author lochel
 */
int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod)
{
  int initMethod = IIM_STATE;               /* default method */
  int optiMethod = IOM_NELDER_MEAD_EX;      /* default method */
  int retVal = -1;

  DEBUG_INFO(LOG_INIT, "### START INITIALIZATION ###");

  /* if there are user-specified options, use them! */
  if(pInitMethod)
  {
    if(!strcmp(pInitMethod, "state"))
      initMethod = IIM_STATE;
    else
    {
      WARNING1("unrecognized option -iim %s", pInitMethod);
      WARNING_AL("current options are: state");
      initMethod = IIM_UNKNOWN;
    }
  }

  if(pOptiMethod)
  {
    if(!strcmp(pOptiMethod, "nelder_mead_ex"))
      optiMethod = IOM_NELDER_MEAD_EX;
    else
    {
      WARNING1("unrecognized option -iom %s", pOptiMethod);
      WARNING_AL("current options are: nelder_mead_ex");
      optiMethod = IOM_UNKNOWN;
    }
  }

  DEBUG_INFO1(LOG_INIT,    "initialization method: %s", initMethodStr[initMethod]);
  DEBUG_INFO_AL1(LOG_INIT, "optimization method:   %s", optiMethodStr[optiMethod]);

  /* select the right initialization-method */
  if(initMethod == IIM_STATE)
  {
    retVal = state_initialization(data, optiMethod);
  }
  else
  {
    WARNING1("unrecognized option -iim %s", initMethodStr[initMethod]);
  }

  DEBUG_INFO(LOG_INIT, "### END INITIALIZATION ###");
  return retVal;
}
