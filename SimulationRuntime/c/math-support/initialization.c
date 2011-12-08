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
#include <string.h> /* strcmp */

/*
#ifndef NEWUOA
#define NEWUOA newuoa_
#endif

#ifndef NELMEAD
#define NELMEAD nelmead_
#endif

void NEWUOA(long *nz,
  long *NPT,
  double *z,
  double *RHOBEG,
  double *RHOEND,
  long *IPRINT,
  long *MAXFUN,
  double *W,
  void (*leastSquare) (long *nz, double *z, double *funcValue));

void NELMEAD(double *z,
  double *STEP,
  long *nz,
  double *funcValue,
  long *MAXF,
  long *IPRINT,
  double *STOPCR,
  long *NLOOP,
  long *IQUAD,
  double *SIMP,
  double *VAR,
  void (*leastSquare) (long *nz, double *z, double *funcValue),
  long *IFAULT);
*/

enum INIT_INIT_METHOD
{
  IIM_UNKNOWN = 0,
  IIM_STATE,
  IIM_OLD
};

const char *initMethodStr[3] = {"unknown", "state", "old"};

enum INIT_OPTI_METHOD
{
  IOM_UNKNOWN = 0,
  IOM_SIMPLEX,
  IOM_NELDER_MEAD_EX,
  IOM_NEWUOA
};

const char *optiMethodStr[4] = {"unknown", "simplex", "nelder_mead_ex", "newuoa"};

/*! \fn double leastSquareWithLambda(long nz, double *z, double lambda)
*
*  This function calculates the residual value 
*  as the sum of squared residual equations.
*
*  \param nz [in] number of variables
*  \param z [in] vector of variables
*  \param z [in] vector of scaling-factors or NULL
*  \param lambda [in]
*/
static double leastSquareWithLambda(long nz, double* z, double* zNominal, double lambda, _X_DATA* data, double* initialResiduals)
{
  int indz = 0;
  fortran_integer i = 0;
  long j = 0;
  double funcValue = 0;

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

  bound_parameters(data);            /* evaluate parameters with respect to other parameters */
  functionODE(data);
  functionAlgebraics(data);

  initial_residual(data, lambda, initialResiduals);
  for(j=0; j<data->modelData.nResiduals; ++j)
  {
    funcValue += initialResiduals[j] * initialResiduals[j];
  }
  return funcValue;
}

static void NelderMeadOptimization(long N,
  double* var,
  double* scale,
  double lambda_step,
  double acc,
  long maxIt,
  long dump,
  double* pLambda,
  long* pIteration,
  double (*leastSquare)(long, double*, double*, double, _X_DATA*, double*),
  _X_DATA* data,
  double* initialResiduals)
{
  double alpha    = 1.0;        /* 0 < alpha */
  double beta     = 2;        	/* 1 < beta */
  double gamma    = 0.5;        /* 0 < gamma < 1 */

  double* simplex = (double*)calloc((N+1)*N, sizeof(double));
  double* fvalues = (double*)calloc(N+1, sizeof(double));

  double* xr = (double*)calloc(N, sizeof(double));
  double* xe = (double*)calloc(N, sizeof(double));
  double* xk = (double*)calloc(N, sizeof(double));
  double* xbar = (double*)calloc(N, sizeof(double));

  double fxr;
  double fxe;
  double fxk;

  long xb = 0;        /* best vertex */
  long xs = 0;        /* worst vertex */
  long xz = 0;        /* second-worst vertex */

  long x = 0;
  long i = 0;

  double lambda = 0.0;
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
      simplex[x*N + i] = var[i] + ((x==i) ? 1.0 : 0.0);    /* canonical simplex */
    }
  }

  do
  {
    /* lambda-control */
    double sigma = 0.0;
    double average = 0.0;
    double g = 0.000001;

    iteration++;

    /* dump every dump-th step */
    if(dump && !(iteration % dump))
      INFO3("NelderMeadOptimization | lambda=%g / step=%d / f=%g", lambda, (int)iteration, leastSquare(N, simplex, scale, lambda, data, initialResiduals));

    /* func-values for the simplex */
    for(x=0; x<N+1; x++)
      fvalues[x] = leastSquare(N, &simplex[x*N], scale, lambda, data, initialResiduals);

    for(x=0; x<N+1; x++)
      average += fvalues[x];
    average /= (N+1);

    for(x=0; x<N+1; x++)
      sigma += (fvalues[x] - average) * (fvalues[x] - average);
    sigma /= N;

    if(sigma < g*g && lambda < 1.0)
    {
      lambda += lambda_step;
      if(lambda > 1.0)
        lambda = 1.0;
      
      DEBUG_INFO3(LOG_INIT, "NelderMeadOptimization | increasing lambda to %g in step %d at f=%g", lambda, (int)iteration, leastSquare(N, simplex, scale, lambda, data, initialResiduals));
      continue;
    }

    /* calculate xb, xs, xz */
    xb = 0;
    for(x=1; x<N+1; x++)
    {
      if(fvalues[x] < fvalues[xb])
        xb = x;
    }

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
    fxr = leastSquare(N, xr, scale, lambda, data, initialResiduals);

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
      fxe = leastSquare(N, xe, scale, lambda, data, initialResiduals);

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
        fxk = leastSquare(N, xk, scale, lambda, data, initialResiduals);
      }
      else
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(xr[i] - xbar[i]);
        fxk = leastSquare(N, xk, scale, lambda, data, initialResiduals);
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
  }while((lambda < 1.0 || fvalues[xb] > acc) && iteration < maxIt);

  /* copying solution */
  for(i=0; i<N; i++)
    var[i] = simplex[xs*N+i];

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

/*! \fn int reportResidualValue(double funcValue)
*
*  Returns 1 if residual is non-zero and prints appropriate error message.
*
*  \param funcValue [in] leastSquare-Value
*/
static int reportResidualValue(double funcValue, _X_DATA* data, double* initialResiduals)
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

/*! \fn int nelderMeadEx_initialization(_X_DATA* data, long nz, double *z)
*
*  This function performs initialization by using an extend version of the
*  nelderMead algorithm.
*  This does not require a jacobian for the residuals.
*/
static int nelderMeadEx_initialization(_X_DATA *data, long nz, double *z, double *zNominal, double* initialResiduals)
{
  double STOPCR = 1.e-16;
  double lambda_step = 0.1;
  long NLOOP = 10000 * nz;

  double funcValue = leastSquareWithLambda(nz, z, zNominal, 1.0, data, initialResiduals);

  double lambda = 0;
  long iteration = 0;

  long l=0, i=0;

  for(l=0; l<100 && funcValue > STOPCR; l++)
  {
    DEBUG_INFO1(LOG_INIT, "nelderMeadEx_initialization | initialization-nr. %d", (int)l);

    /* down-scale */
    for(i=0; i<nz; i++)
      z[i] /= zNominal[i];

    NelderMeadOptimization(nz, z, zNominal, lambda_step, STOPCR, NLOOP, DEBUG_FLAG(LOG_INIT) ? 100000 : 0, &lambda, &iteration, leastSquareWithLambda, data, initialResiduals);

    /* up-scale */
    for(i=0; i<nz; i++)
      z[i] *= zNominal[i];

    if(DEBUG_FLAG(LOG_INIT))
    {
      INFO3("nelderMeadEx_initialization | iteration=%d / lambda=%g / f=%g", (int) iteration, lambda, leastSquareWithLambda(nz, z, zNominal, lambda, data, initialResiduals));
      for(i=0; i<nz; i++)
      {
        INFO_AL2("nelderMeadEx_initialization | states | %d: %g", (int) i, z[i]);
      }
    }

    storePreValues(data);                       /* save pre-values */
    overwriteOldSimulationData(data);           /* if there are non-linear equations */

    update_DAEsystem(data);                     /* evaluate discrete variables */

    /* valid system for the first time! */

    SaveZeroCrossings(data);
    storePreValues(data);
    overwriteOldSimulationData(data);

    funcValue = leastSquareWithLambda(nz, z, zNominal, 1.0, data, initialResiduals);
  }

  DEBUG_INFO1(LOG_INIT, "nelderMeadEx_initialization | leastSquare=%g", funcValue);

  if(lambda < 1.0 && funcValue > STOPCR)
  {
    DEBUG_INFO1(LOG_INIT, "nelderMeadEx_initialization | lambda = %g", lambda);
    return -1;
  }

  return reportResidualValue(funcValue, data, initialResiduals);
}

/*! \fn int initialize(_X_DATA *data, int optiMethod)
 *
 *  author: lochel
 */
static int initialize(_X_DATA *data, int optiMethod)
{
  long i = 0;
  long iz = 0;
  long nz = 0;
  int retVal = 0;
  double *z = NULL;
  double *zNominal = NULL;
  double *initialResiduals = NULL;

  DEBUG_INFO1(LOG_INIT, "initialization by method: %s", optiMethodStr[optiMethod]);

  /* count unfixed states */
  DEBUG_INFO(LOG_INIT, "fixed attribute for states:");
  for(i=0; i<data->modelData.nStates; ++i)
  {
    DEBUG_INFO2(LOG_INIT, "state %s(fixed=%s)", data->modelData.realVarsData[i].info.name, (data->modelData.realVarsData[i].attribute.fixed ? "true" : "false"));
    if(data->modelData.realVarsData[i].attribute.fixed == 0)
      ++nz;
  }

  /* plus unfixed real-parameters */
  DEBUG_INFO(LOG_INIT, "fixed attribute for parameters:");
  for(i=0; i<data->modelData.nParametersReal; ++i)
  {
    DEBUG_INFO2(LOG_INIT, "parameter %s(fixed=%s)", data->modelData.realParameterData[i].info.name, (data->modelData.realParameterData[i].attribute.fixed ? "true" : "false"));
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
      ++nz;
  }

  DEBUG_INFO1(LOG_INIT, "number of non-fixed variables: %d", (int)nz);

  /* No initial values to calculate. */
  if(nz == 0)
  {
    DEBUG_INFO(LOG_INIT, "no initial values to calculate");
    return 0;
  }

  z = (double*)calloc(nz, sizeof(double));
  zNominal = (double*)calloc(nz, sizeof(double));
  initialResiduals = (double*) calloc(data->modelData.nResiduals, sizeof(double));
  ASSERT(z, "out of memory");
  ASSERT(zNominal, "out of memory");
  ASSERT(initialResiduals, "out of memory");

  /* fill z with the non-fixed variables from x and p */
  for(i=0, iz=0; i<data->modelData.nStates; ++i)
  {
    if(data->modelData.realVarsData[i].attribute.fixed == 0)
    {
      zNominal[iz] = fabs(data->modelData.realVarsData[i].attribute.nominal);

      if(zNominal[iz] == 0.0)
      {
        WARNING1("nominal for real parameter is zero > nominal(%s) := 1.0", data->modelData.realParameterData[i].info.name);
        zNominal[iz] = 1.0;
      }

      z[iz++] = data->modelData.realVarsData[i].attribute.start;
    }
  }

  /* for real parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
  {
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
    {
      zNominal[iz] = fabs(data->modelData.realParameterData[i].attribute.nominal);

      if(zNominal[iz] == 0.0)
      {
        WARNING1("nominal for real parameter is zero > nominal(%s) := 1.0", data->modelData.realParameterData[i].info.name);
        zNominal[iz] = 1.0;
      }

      z[iz++] = data->modelData.realParameterData[i].attribute.start;
    }
  }

  if(optiMethod == IOM_NELDER_MEAD_EX)
  {
    retVal = nelderMeadEx_initialization(data, nz, z, zNominal, initialResiduals);
  }
  /*
  else if(optiMethod == IOM_SIMPLEX)
  {
    retVal = simplex_initialization(data, nz, z);
  } 
  else if(optiMethod == IOM_NEWUOA)
  {
    retVal = newuoa_initialization(data, nz, z);
  }
  */
  else
  {
    WARNING1("unrecognized option -iom %s", optiMethodStr[optiMethod]);
    WARNING_AL("current options are: nelder_mead_ex");   /* WARNING_AL("current options are: nelder_mead_ex, simplex or newuoa"); */
    retVal= -1;
  }

  free(z);
  free(zNominal);
  free(initialResiduals);
  return retVal;
}

/*! \fn int state_initialization(_X_DATA *data, int optiMethod)
 *
 *  author: lochel
 */
static int state_initialization(_X_DATA *data, int optiMethod)
{
  int retVal = 0, i;

  /* call initialize function and save start values */
  storeStartValues(data);
  storePreValues(data);             /* if initial_function() uses pre-values */
  storeStartValuesParam(data);
  initial_function(data);           /* set all start-Values */

  storePreValues(data);             /* to provide all valid pre-values */
  overwriteOldSimulationData(data);

  /* initialize all relations that are ZeroCrossings */
  bound_parameters(data);
  update_DAEsystem(data);

  /* and restore start values and helpvars */
  resetAllHelpVars(data);
  storePreValues(data);

  /* debug print */
  if (DEBUG_FLAG(LOG_DEBUG)){
    for (i=0; i<3;i++){
      INFO1("Print values for buffer segment = %d",i);
      printAllVars(data,i);
    }
  }
  /* start with the real initialization */
  data->simulationInfo.initial = 1;             /* to evaluate when-equations with initial()-conditions */

  retVal = initialize(data, optiMethod);


  /* debug print */
  if (DEBUG_FLAG(LOG_DEBUG)){
    for (i=0; i<3;i++){
      INFO1("Print values for buffer segment = %d",i);
      printAllVars(data,i);
    }
  }
  storeInitialValuesParam(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */

  update_DAEsystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  SaveZeroCrossings(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */

  data->simulationInfo.initial = 0;

  return retVal;
}

/*! \fn int initialization(_X_DATA *data, const char* pInitMethod, const char* pOptiMethod)
 *
 *  author: lochel
 */
int initialization(_X_DATA *data, const char* pInitMethod, const char* pOptiMethod)
{
  int initMethod = IIM_STATE;			  /* default method */
  int optiMethod = IOM_SIMPLEX;	    /* default method */

  /* if there are user-specified options, use them! */
  if(pInitMethod)
  {
    if(!strcmp(pInitMethod, "state"))
      initMethod = IIM_STATE;
    else
      initMethod = IIM_UNKNOWN;
  }

  if(pOptiMethod)
  {
    if(!strcmp(pOptiMethod, "simplex"))
      optiMethod = IOM_SIMPLEX;
    else if(!strcmp(pOptiMethod, "nelder_mead_ex"))
      optiMethod = IOM_NELDER_MEAD_EX;
    else if(!strcmp(pOptiMethod, "newuoa"))
      optiMethod = IOM_NEWUOA;
    else
      optiMethod = IOM_UNKNOWN;
  }

  DEBUG_INFO1(LOG_INIT,    "initialization | initialization method: %s", initMethodStr[initMethod]);
  DEBUG_INFO_AL1(LOG_INIT, "                 optimization method:   %s", optiMethodStr[optiMethod]);

  /* select the right initialization-method */
  if(initMethod == IIM_STATE)
  {
    /* the 'new' initialization-method */
    int result = state_initialization(data, optiMethod);

    if(result)
    {
      WARNING("state-initialization fails");
    }

    return result;
  }

  /* unrecognized initialization-method */
  WARNING1("unrecognized option -iim %s", initMethodStr[initMethod]);
  WARNING_AL("current options are: state");
  return -1;
}
