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

/*! \file simulation_init.c
 */

#include "initialization.h"
#include "simulation_runtime.h"
#include "solver_main.h"

#include <math.h>
#include <assert.h>

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

/*! \fn void leastSquare(long nz, double *z, double *funcValue)
 *
 *  This function calculates the residual value 
 *  as the sum of squared residual equations.
 *
 *  \param nz [in] number of variables
 *  \param z [in] vector of variables
 *  \param funcValue [out] result
 */
void leastSquare(long *nz, double *z, double *funcValue)
{
  int indz = 0;
  fortran_integer i = 0;
  long j=0;
  int shiftForInitFixed = 0;
  int shiftForVar_attr = 0;

  for(i=0; i<globalData->nStates; i++)
    if(globalData->initFixed[i]==0)
      globalData->states[i] = z[indz++];

  /* for real parameters */
  shiftForInitFixed = 2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  shiftForVar_attr = globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  for(i=0; i<globalData->nParameters; i++)
    if(globalData->initFixed[i+shiftForInitFixed] == 0 && globalData->var_attr[i+shiftForVar_attr] == 1)
      globalData->parameters[i] = z[indz++];

  bound_parameters();            /* evaluate parameters with respect to other parameters */
  functionODE();
  functionAlgebraics();

  initial_residual(1.0);

  *funcValue = 0;
  for(j=0; i<globalData->nInitialResiduals; j++)
    *funcValue += globalData->initialResiduals[j] * globalData->initialResiduals[j];

  if(useVerboseOutput(LOG_INIT))
  {
    fprintf(stdout, "info    | leastSquare | leastSquare-Value: %g\n", *funcValue);
    fflush(NULL);
  }
}

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
double leastSquareWithLambda(long nz, double* z, double* scale, double lambda)
{
  int indz = 0;
  fortran_integer i = 0;
  int shiftForInitFixed = 0;
  int shiftForVar_attr = 0;
  long j = 0;
  double funcValue = 0;

  for(i=0; i<globalData->nStates; i++)
    if(globalData->initFixed[i]==0)
    {
      globalData->states[i] = z[indz] * (scale ? scale[indz] : 1.0);
      indz++;
    }

  /* for real parameters */
  shiftForInitFixed = 2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  shiftForVar_attr = globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  for(i=0; i<globalData->nParameters; i++)
    if(globalData->initFixed[i+shiftForInitFixed] == 0 && globalData->var_attr[i+shiftForVar_attr] == 1)
    {
      globalData->parameters[i] = z[indz] * (scale ? scale[indz] : 1.0);
      indz++;
    }
    
  bound_parameters();            /* evaluate parameters with respect to other parameters */
  functionODE();
  functionAlgebraics();
  
  initial_residual(lambda);

  for(j=0; j<globalData->nInitialResiduals; j++)
    funcValue += globalData->initialResiduals[j] * globalData->initialResiduals[j];
  return funcValue;
}

void NelderMeadOptimization(long N, 
    double* var,
    double* scale,
    double lambda_step,
    double acc,
    long maxIt,
    long dump,
    double* pLambda,
    long* pIteration,
    double (*leastSquare)(long, double*, double*, double))
{
  double alpha    = 1.0;        /* 0 < alpha */
  double beta     = 2;        	/* 1 < beta */
  double gamma    = 0.5;        /* 0 < gamma < 1 */

  double* simplex = (double*)calloc((N+1) * N,sizeof(double));
  double* fvalues = (double*)calloc(N+1,sizeof(double));

  double* xr = (double*)calloc(N,sizeof(double));
  double* xe = (double*)calloc(N,sizeof(double));
  double* xk = (double*)calloc(N,sizeof(double));
  double* xbar = (double*)calloc(N,sizeof(double));

  double fxr;
  double fxe;
  double fxk;

  long xb = 0;        /* best vertex */
  long xs = 0;        /* worst vertex */
  long xz = 0;        /* second-worst vertex */

  long x = 0;
  long i = 0;

  double lambda = 0.0;    /* no lambda-control is activated */
  long iteration = 0;

  /* check Memory */
  assert(xr);
  assert(xe);
  assert(xk);
  assert(xbar);

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
    {
      fprintf(stdout, "info    | NelderMeadOptimization | lambda=%g / step=%d / f=%g\n", lambda, (int)iteration, leastSquare(N, simplex, scale, lambda));
    }

    /* func-values for the simplex */
    for(x=0; x<N+1; x++)
      fvalues[x] = leastSquare(N, &simplex[x*N], scale, lambda);


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
      if(useVerboseOutput(LOG_INIT))
      {
        fprintf(stdout, "info    | NelderMeadOptimization | increasing lambda to %g in step %d at f=%g\n", lambda, (int)iteration, leastSquare(N, simplex, scale, lambda)); fflush(NULL);
      }
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
    fxr = leastSquare(N, xr, scale, lambda);

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
      fxe = leastSquare(N, xe, scale, lambda);

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
        fxk = leastSquare(N, xk, scale, lambda);
      }
      else
      {
        for(i=0; i<N; i++)
          xk[i] = xbar[i] + gamma*(xr[i] - xbar[i]);
        fxk = leastSquare(N, xk, scale, lambda);
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
int reportResidualValue(double funcValue)
{
  long i = 0;
  if(funcValue > 1e-5)
  {
    fprintf(stderr, "error   | reportResidualValue | error in initialization. System of initial equations are not consistent.\n");
    fprintf(stderr, "error   | reportResidualValue | (Least Square function value is %g)\n", funcValue);

    for(i=0; i<globalData->nInitialResiduals; i++)
    {
      if(fabs(globalData->initialResiduals[i]) > 1e-6)
      {
        fprintf(stderr, "info    | reportResidualValue | residual[%d] = %g\n", (int) i, globalData->initialResiduals[i]);
      }
    }
    return 1;
  }
  return 0;
}

/*! \fn int newuoa_initialization(long nz, double *z)
 *
 *  This function performs initialization using the newuoa function, which is
 *  a trust region method that forms quadratic models by interpolation.
 */
int newuoa_initialization(long nz, double *z)
{
  long IPRINT = sim_verbose >= LOG_INIT? 2 : 0;
  long MAXFUN=50000;
  double RHOEND=1.0e-6;
  double RHOBEG=10; /* This should be about one tenth of the greatest
     expected value of a variable. Perhaps the nominal
     value can be used for this. */
  long NPT = 2*nz+1;
  double funcValue=0; 
  double *W = (double*)calloc((NPT+13)*(NPT+nz)+3*nz*(nz+3)/2, sizeof(double));
  assert(W);
  NEWUOA(&nz, &NPT, z, &RHOBEG, &RHOEND, &IPRINT, &MAXFUN, W, leastSquare);

  /* Calculate the residual to verify that equations are consistent. */
  leastSquare(&nz, z, &funcValue);


  free(W);
  return reportResidualValue(funcValue);
}

/*! \fn int simplex_initialization(long nz,double *z)
 *
 *  This function performs initialization by using the simplex algorithm.
 *  This does not require a jacobian for the residuals.
 */
int simplex_initialization(long nz, double *z)
{
  int ind = 0;
  double funcValue = 0;
  double *STEP = (double*)calloc(nz, sizeof(double));
  double *VAR = (double*)calloc(nz, sizeof(double));
  double STOPCR = 0,SIMP=0;
  long IPRINT = 0, NLOOP = 0, IQUAD = 0, IFAULT = 0, MAXF = 0;
  assert(STEP);
  assert(VAR);

  /* Start with stepping .5 in each direction. */
  for (ind = 0; ind < nz; ind++)
  {
    /* some kind of scaling */
    STEP[ind] = (z[ind]!=0.0 ? fabs(z[ind])/1000.0 : 1);    /* 1.0 */
    VAR[ind]  = 0.0;
  }

  /* Set max. no. of function evaluations = 5000, print every 100. */

  MAXF = 5000 * nz;
  IPRINT = sim_verbose >= LOG_INIT ? 100 : -1;

  /* Set value for stopping criterion.   Stopping occurs when the
   * standard deviation of the values of the objective function at
   * the points of the current simplex < stopcr. */

  STOPCR = 1.e-12;
  NLOOP = nz;

  /* Fit a quadratic surface to be sure a minimum has been found. */

  IQUAD = 0;

  /* As function value is being evaluated in DOUBLE PRECISION, it
   * should be accurate to about 15 decimals.   If we set simp = 1.d-6,
   * we should get about 9 dec. digits accuracy in fitting the surface. */

  SIMP = 1.e-12;

  /* Now call NELMEAD to do the work. */

  leastSquare(&nz, z, &funcValue);

  if ( fabs(funcValue) != 0)
  {
    NELMEAD(z,STEP, &nz, &funcValue, &MAXF, &IPRINT, &STOPCR,
        &NLOOP,&IQUAD,&SIMP,VAR,leastSquare,&IFAULT);
  }
  else
  {
    if (sim_verbose >= LOG_INIT)
    {
      fprintf(stderr, "info    | simplex_initialization | Result of leastSquare method = %g. The initial guess fits to the system\n", funcValue); fflush(NULL);
    }
  }

  leastSquare(&nz, z, &funcValue);
  if(useVerboseOutput(LOG_INIT))
  {
    printf("info    | leastSquare=%g\n", funcValue); fflush(NULL);
  }

  if (IFAULT == 1)
  {
    if (funcValue > SIMP) {
      printf("Error in initialization. Solver iterated %d times without finding a solution\n",(int)MAXF); fflush(NULL);
      return -1;
    }
  } else if(IFAULT == 2 ) {
    printf("Error in initialization. Inconsistent initial conditions.\n"); fflush(NULL);
    return -1;
  } else if (IFAULT == 3) {
    printf("Error in initialization. Number of initial values to calculate < 1\n"); fflush(NULL);
    return -1;
  } else if (IFAULT == 4) {
    printf("Error in initialization. Internal error, NLOOP < 1.\n"); fflush(NULL);
    return -1;
  }
  return reportResidualValue(funcValue);
}

/*! \fn int simplex_initialization(long nz,double *z)
 *
 *  This function performs initialization by using the simplex algorithm.
 *  This does not require a jacobian for the residuals.
 */
int nelderMeadEx_initialization(long nz, double *z, double *scale)
{
  double STOPCR = 1.e-16;
  double lambda_step = 0.1;
  long NLOOP = 10000 * nz;

  double funcValue = leastSquareWithLambda(nz, z, NULL, 1.0);

  double lambda = 0;
  long iteration = 0;

  long l=0,i=0;

  for(l=0; l<100 && funcValue > STOPCR; l++)
  {
    if(useVerboseOutput(LOG_INIT))
    {
      printf("info    | nelderMeadEx_initialization | initialization-nr. %d\n", (int)l);
      fflush(NULL);
    }

    /* down-scale */
    for(i=0; i<nz; i++)
      z[i] /= scale[i];
    NelderMeadOptimization(nz, z, scale, lambda_step, STOPCR, NLOOP, useVerboseOutput(LOG_INIT) ? 100000 : 0, &lambda, &iteration, leastSquareWithLambda);
    /* up-scale */
    for(i=0; i<nz; i++)
      z[i] *= scale[i];

    if(useVerboseOutput(LOG_INIT))
    {
      printf("info    | nelderMeadEx_initialization | iteration=%d / lambda=%g / f=%g\n", (int) iteration, lambda, leastSquareWithLambda(nz, z, NULL, lambda));
      for(i=0; i<nz; i++)
        printf("info    | nelderMeadEx_initialization | states | %d: %g\n", (int) i, z[i]);
      fflush(NULL);
    }

    saveall();                      /* save pre-values */
    storeExtrapolationDataEvent();  /* if there are non-linear equations */

    update_DAEsystem();             /* evaluate discrete variables */

    /* valid system for the first time! */

    SaveZeroCrossings();
    saveall();
    storeExtrapolationDataEvent();

    funcValue = leastSquareWithLambda(nz, z, NULL, 1.0);
  }

  if(useVerboseOutput(LOG_INIT))
  {
    printf("info    | nelderMeadEx_initialization | leastSquare=%g\n", funcValue);
    fflush(NULL);
  }

  if(lambda < 1.0)
  {
    if(useVerboseOutput(LOG_INIT))
    {
      printf("error   | nelderMeadEx_initialization | lambda = %g\n", lambda);
      fflush(NULL);
    }
    return -1;
  }

  return reportResidualValue(funcValue);
}

/*! \fn int initialize(int optiMethod)
 *
 * Perform initialization of the problem. It reads the global variable
 * globalData->initFixed to find out which variables are fixed.
 * It uses the generated function initial_residual, which calcualtes the
 * residual of all equations (both continuous time eqns and initial eqns).
 */
int initialize(int optiMethod)
{
  long nz = 0;
  int ind = 0, indAct = 0, indz = 0;
  int retVal = 0;
  int startIndPar = 0;
  int endIndPar = 0;
  double *z = 0;
  double *scale = 0;
  fortran_integer i = 0;

  for(ind=0, nz=0; ind<globalData->nStates; ind++)
  {
    if(globalData->initFixed[ind]==0)
    {
      if(sim_verbose >= LOG_INIT)
      {
        fprintf(stdout, "info    | state %s is unfixed.\n", globalData->statesNames[ind].name);
        fflush(NULL);
      }
      nz++;
    }
  }

  startIndPar = 2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;
  endIndPar = startIndPar+globalData->nParameters;
  for(ind = startIndPar; ind < endIndPar; ind++)
  {
    if(globalData->initFixed[ind]==0 && globalData->var_attr[ind-globalData->nStates]==1)
    {
      if(sim_verbose >= LOG_INIT)
      {
          fprintf(stdout, "info    | parameter %s is unfixed.\n", globalData->parametersNames[ind-startIndPar].name);
          fflush(NULL);
      }
      nz++;
    }
  }

  if(sim_verbose >= LOG_INIT)
  {
    fprintf(stdout, "info    | initialize | initialization by method: %s\n", optiMethodStr[optiMethod]);
    fprintf(stdout, "info    | initialize | fixed attribute for states:\n");
    for(i=0;i<globalData->nStates; i++)
      fprintf(stdout, "info    | initialize | %s(fixed=%s)\n", globalData->statesNames[i].name, (globalData->initFixed[i] ? "true" : "false"));
    fprintf(stdout, "info    | initialize | number of non-fixed variables: %d\n", (int)nz);
    fflush(NULL);
  }

  /* No initial values to calculate. */
  if(nz ==  0)
  {
    if(sim_verbose >= LOG_INIT)
    {
        fprintf(stdout, "info    | no initial values to calculate\n"); fflush(NULL);
    }
    return 0;
  }

  z = (double*)calloc(nz, sizeof(double));
  scale = (double*)calloc(nz, sizeof(double));
  assert(z);
  assert(scale);

  /* Fill z with the non-fixed variables from x and p */
  for(ind=0, indAct=0, indz=0; ind<globalData->nStates; ind++)
  {
    if(globalData->initFixed[indAct++] == 0)
    {
      scale[indz] = hasNominalValue[ind] ? fabs(nominalValue[ind]) : 1;
      z[indz++] = globalData->states[ind];
    }
  }

  /* for real parameters */
  for(ind=0, indAct=startIndPar; ind<globalData->nParameters; ind++)
  {
    if(globalData->initFixed[indAct++]==0 && globalData->var_attr[indAct-globalData->nStates]==1)
    {
      scale[indz] = hasNominalValue[globalData->nStates+globalData->nAlgebraic+ind] ? fabs(nominalValue[globalData->nStates+globalData->nAlgebraic+ind]) : 1;
      z[indz++] = globalData->parameters[ind];
    }
  }

  if(optiMethod == IOM_SIMPLEX)
  {
    retVal = simplex_initialization(nz, z);
  }
  else if(optiMethod == IOM_NELDER_MEAD_EX)
  {
    retVal = nelderMeadEx_initialization(nz, z, scale);
  }
  else if(optiMethod == IOM_NEWUOA)
  {
    retVal = newuoa_initialization(nz, z);
  }
  else
  {
    fprintf(stderr, "error   | unrecognized option -iom %s\n", optiMethodStr[optiMethod]);
    fprintf(stderr, "        | current options are: simplex, nelder_mead_ex or newuoa\n");
    fflush(NULL);
    retVal= -1;
  }

  free(z);
  free(scale);
  return retVal;
}

int old_initialization(int optiMethod)
{
  int retVal = 0;
  /* call initialize function and save start values */
  saveall();                        /* if initial_function() uses pre-values */
  initial_function();               /* set all start-Values */
  storeExtrapolationDataEvent();
  saveall();                        /* to provide all valid pre-values */

  /* Initialize all relations that are ZeroCrossings */
  update_DAEsystem();
  /* start with the real initialization */
  globalData->init = 1;

  /* And restore start values and helpvars */
  restoreExtrapolationDataOld();
  restoreHelpVars();
  saveall();
  /* start with the real initialization */
  globalData->init = 1;             /* to evaluate when-equations with initial()-conditions */

  /* first try with the given method as default simplex and */
  /* then try with the other one */
  retVal = initialize(optiMethod);

  if(retVal != 0)
  {
    if(optiMethod == IOM_SIMPLEX)
      retVal = initialize(IOM_NEWUOA);
    else if(optiMethod == IOM_NEWUOA)
      retVal = initialize(IOM_SIMPLEX);

    if(retVal != 0)
    {
      fprintf(stdout, "info    | Initialization of the current initial set of equations and initial guesses fails!\n");
      fprintf(stdout, "        | Try with better Initial guesses for the states.\n"); fflush(NULL);
    }
  }

  saveall();                        /* save pre-values */
  storeExtrapolationDataEvent();    /* if there are non-linear equations */

  update_DAEsystem();               /* evaluate discrete variables */

  /* valid system for the first time! */

  SaveZeroCrossings();
  saveall();
  storeExtrapolationDataEvent();

  globalData->init = 0;

  return retVal;
}

int state_initialization(int optiMethod)
{
  int retVal = 0;
  /* call initialize function and save start values */
  saveall();                        /* if initial_function() uses pre-values */
  initial_function();               /* set all start-Values */
  storeExtrapolationDataEvent();
  saveall();                        /* to provide all valid pre-values */

  /* Initialize all relations that are ZeroCrossings */
  update_DAEsystem();

  /* And restore start values and helpvars */
  restoreExtrapolationDataOld();
  restoreHelpVars();
  saveall();

  /* start with the real initialization */
  globalData->init = 1;             /* to evaluate when-equations with initial()-conditions */

  retVal = initialize(IOM_NELDER_MEAD_EX);

  saveall();                        /* save pre-values */
  storeExtrapolationDataEvent();    /* if there are non-linear equations */

  update_DAEsystem();               /* evaluate discrete variables */

  /* valid system for the first time! */

  SaveZeroCrossings();
  saveall();
  storeExtrapolationDataEvent();

  globalData->init = 0;

  /* fall-back case */
  if(retVal)
  {
    if(useVerboseOutput(LOG_INIT))
    {
        fprintf(stdout, "warning | state_initialization | init. failed! use old initialization method\n");
        fflush(NULL);
    }
    return old_initialization(optiMethod);
  }

  return retVal;
}

int initialization(const char* pInitMethod, const char* pOptiMethod)
{
    int initMethod = IIM_STATE;			/* default method */
	int optiMethod = IOM_SIMPLEX;	    /* default method */

	/* if there are user-specified options, use them! */
	if(pInitMethod)
	{
		if(!strcmp(pInitMethod, "state"))
			initMethod = IIM_STATE;
		else if(!strcmp(pInitMethod, "old"))
			initMethod = IIM_OLD;
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

	if(useVerboseOutput(LOG_INIT))
	{
		fprintf(stdout, "info    | initialization | initialization method: %s\n", initMethodStr[initMethod]);
		fprintf(stdout, "info    | initialization | optimization method:   %s\n", optiMethodStr[optiMethod]);
		fflush(NULL);
	}

	/* select the right initialization-method */
	if(initMethod == IIM_OLD)
	{
		/* the 'old' initialization-method */
		return old_initialization(optiMethod);
	}
	else if(initMethod == IIM_STATE)
	{
		/* the 'new' initialization-method */
		return state_initialization(optiMethod);
	}

	/* unrecognized initialization-method */
	fprintf(stderr, "error   | unrecognized option -iim %s\n", initMethodStr[initMethod]);
	fprintf(stderr, "        | current options are: state or old\n");
	fflush(NULL);
	return -1;
}
