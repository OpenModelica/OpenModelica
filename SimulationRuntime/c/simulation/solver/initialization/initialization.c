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

#include "method_simplex.h"
#include "method_newuoa.h"
#include "method_nelderMeadEx.h"
#include "method_kinsol.h"
#include "method_ipopt.h"

#include "simulation_data.h"
#include "omc_error.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "model_help.h"
#include "read_matlab4.h"
#include "events.h"
#include "stateset.h"

#include "initialization_data.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

/*! \fn int reportResidualValue(INIT_DATA *initData)
 *
 *  return 1: if funcValue >  1e-5
 *         0: if funcValue <= 1e-5
 *
 *  \param [in]  [initData]
 */
int reportResidualValue(INIT_DATA *initData)
{
  long i = 0;
  double funcValue = leastSquareWithLambda(initData, 1.0);

  if(1e-5 < funcValue)
  {
    INFO1(LOG_INIT, "error in initialization. System of initial equations are not consistent\n(least square function value is %g)", funcValue);

    INDENT(LOG_INIT);
    for(i=0; i<initData->nInitResiduals; i++)
      if(1e-5 < fabs(initData->initialResiduals[i]))
        INFO2(LOG_INIT, "residual[%ld] = %g", i+1, initData->initialResiduals[i]);
    RELEASE(LOG_INIT);

    return 1;
  }
  return 0;
}

/*! \fn double leastSquareWithLambda(INIT_DATA *initData, double lambda)
 *
 *  This function calculates the residual value as the sum of squared residual equations.
 *
 *  \param [ref] [initData]
 *  \param [in]  [lambda] E [0; 1]
 */
double leastSquareWithLambda(INIT_DATA *initData, double lambda)
{
  DATA *data = initData->simData;

  long i = 0, ix;
  double funcValue = 0.0;
  double scalingCoefficient;

  updateSimData(initData);

  updateBoundParameters(data);
  /*functionODE(data);*/
  functionDAE(data);
  functionAlgebraics(data);
  initial_residual(data, initData->initialResiduals);

  for(i=0; i<data->modelData.nInitResiduals; ++i)
  {
    if(initData->residualScalingCoefficients)
      scalingCoefficient = initData->residualScalingCoefficients[i]; /* use scaling coefficients */
    else
      scalingCoefficient = 1.0; /* no scaling coefficients given */

    funcValue += (initData->initialResiduals[i] / scalingCoefficient) * (initData->initialResiduals[i] / scalingCoefficient);
  }

  if(lambda < 1.0)
  {
    funcValue *= lambda;
    ix = 0;

    /* for real variables */
    for(i=0; i<data->modelData.nVariablesReal; ++i)
      if(data->modelData.realVarsData[i].attribute.useStart)
      {
        if(initData->startValueResidualScalingCoefficients)
          scalingCoefficient = initData->startValueResidualScalingCoefficients[ix++]; /* use scaling coefficients */
        else
          scalingCoefficient = 1.0; /* no scaling coefficients given */

        funcValue += (1.0-lambda)*((data->modelData.realVarsData[i].attribute.start-data->localData[0]->realVars[i])/scalingCoefficient)*((data->modelData.realVarsData[i].attribute.start-data->localData[0]->realVars[i])/scalingCoefficient);
      }

      /* for real parameters */
      for(i=0; i<data->modelData.nParametersReal; ++i)
        if(data->modelData.realParameterData[i].attribute.useStart && !data->modelData.realParameterData[i].attribute.fixed)
        {
          if(initData->startValueResidualScalingCoefficients)
            scalingCoefficient = initData->startValueResidualScalingCoefficients[ix++]; /* use scaling coefficients */
          else
            scalingCoefficient = 1.0; /* no scaling coefficients given */

          funcValue += (1.0-lambda)*((data->modelData.realParameterData[i].attribute.start-data->simulationInfo.realParameter[i])/scalingCoefficient)*((data->modelData.realParameterData[i].attribute.start-data->simulationInfo.realParameter[i])/scalingCoefficient);
        }

      /* for real discrete */
      for(i=data->modelData.nVariablesReal-data->modelData.nDiscreteReal; i<data->modelData.nDiscreteReal; ++i)
          if(data->modelData.realVarsData[i].attribute.useStart && !data->modelData.realVarsData[i].attribute.fixed)
          {
              if(initData->startValueResidualScalingCoefficients)
                  scalingCoefficient = initData->startValueResidualScalingCoefficients[ix++]; /* use scaling coefficients */
              else
                  scalingCoefficient = 1.0; /* no scaling coefficients given */

              funcValue += (1.0-lambda)*((data->modelData.realVarsData[i].attribute.start-data->simulationInfo.realParameter[i])/scalingCoefficient)*((data->modelData.realVarsData[i].attribute.start-data->simulationInfo.realParameter[i])/scalingCoefficient);
          }
  }

  return funcValue;
}

/*! \fn void dumpInitialization(INIT_DATA *initData)
 *
 *  \param [in]  [initData]
 *
 *  \author lochel
 */
void dumpInitialization(INIT_DATA *initData)
{
  long i;
  double fValueScaled = leastSquareWithLambda(initData, 1.0);
  double fValue = 0.0;

  for(i=0; i<initData->nInitResiduals; ++i)
    fValue += initData->initialResiduals[i] * initData->initialResiduals[i];

  INFO(LOG_INIT, "initialization status");
  INDENT(LOG_INIT);
  if(initData->residualScalingCoefficients)
    INFO2(LOG_INIT, "least square value: %g [scaled: %g]", fValue, fValueScaled);
  else
    INFO1(LOG_INIT, "least square value: %g", fValue);

  INFO(LOG_INIT, "unfixed variables");
  INDENT(LOG_INIT);
  for(i=0; i<initData->nStates; ++i)
    if(initData->nominal)
      INFO4(LOG_INIT, "[%ld] [%15g] := %s [scaling coefficient: %g]", i+1, initData->vars[i], initData->name[i], initData->nominal[i]);
    else
      INFO3(LOG_INIT, "[%ld] [%15g] := %s", i+1, initData->vars[i], initData->name[i]);

  for(; i<initData->nStates+initData->nParameters; ++i)
    if(initData->nominal)
      INFO4(LOG_INIT, "[%ld] [%15g] := %s (parameter) [scaling coefficient: %g]", i+1, initData->vars[i], initData->name[i], initData->nominal[i]);
    else
      INFO3(LOG_INIT, "[%ld] [%15g] := %s (parameter)", i+1, initData->vars[i], initData->name[i]);

  for(; i<initData->nVars; ++i)
    if(initData->nominal)
      INFO4(LOG_INIT, "[%ld] [%15g] := %s (discrete) [scaling coefficient: %g]", i+1, initData->vars[i], initData->name[i], initData->nominal[i]);
    else
      INFO3(LOG_INIT, "[%ld] [%15g] := %s (discrete)", i+1, initData->vars[i], initData->name[i]);
  RELEASE(LOG_INIT);

  INFO(LOG_INIT, "initial residuals");
  INDENT(LOG_INIT);
  for(i=0; i<initData->nInitResiduals; ++i)
    if(initData->residualScalingCoefficients)
      INFO4(LOG_INIT, "[%ld] [%15g] := %s [scaling coefficient: %g]", i+1, initData->initialResiduals[i], initialResidualDescription[i], initData->residualScalingCoefficients[i]);
    else
      INFO3(LOG_INIT, "[%ld] [%15g] := %s", i+1, initData->initialResiduals[i], initialResidualDescription[i]);
  RELEASE(LOG_INIT); RELEASE(LOG_INIT);
}

/*! \fn void dumpInitializationStatus(DATA *data)
 *
 *  \param [in]  [data]
 *
 *  \author lochel
 */
void dumpInitialSolution(DATA *simData)
{
  long i, j;

  const MODEL_DATA      *mData = &(simData->modelData);
  const SIMULATION_INFO *sInfo = &(simData->simulationInfo);

  INFO(LOG_SOTI, "### SOLUTION OF THE INITIALIZATION ###");
  INDENT(LOG_SOTI);

  INFO(LOG_SOTI, "states variables");
  INDENT(LOG_SOTI);
  for(i=0; i<mData->nStates; ++i)
  {
    INFO6(LOG_SOTI, "[%ld] Real %s(start=%g, nominal=%g) = %g (pre: %g)", i+1,
                                                                          mData->realVarsData[i].info.name,
                                                                          mData->realVarsData[i].attribute.start,
                                                                          mData->realVarsData[i].attribute.nominal,
                                                                          simData->localData[0]->realVars[i],
                                                                          sInfo->realVarsPre[i]);
  }
  RELEASE(LOG_SOTI);

  INFO(LOG_SOTI, "derivatives variables");
  INDENT(LOG_SOTI);
  for(i=mData->nStates; i<2*mData->nStates; ++i)
  {
    INFO4(LOG_SOTI, "[%ld] Real %s = %g (pre: %g)", i+1,
                                                    mData->realVarsData[i].info.name,
                                                    simData->localData[0]->realVars[i],
                                                    sInfo->realVarsPre[i]);
  }
  RELEASE(LOG_SOTI);

  INFO(LOG_SOTI, "other real variables");
  INDENT(LOG_SOTI);
  for(i=2*mData->nStates; i<mData->nVariablesReal; ++i)
  {
    INFO6(LOG_SOTI, "[%ld] Real %s(start=%g, nominal=%g) = %g (pre: %g)", i+1,
                                                                          mData->realVarsData[i].info.name,
                                                                          mData->realVarsData[i].attribute.start,
                                                                          mData->realVarsData[i].attribute.nominal,
                                                                          simData->localData[0]->realVars[i],
                                                                          sInfo->realVarsPre[i]);
  }
  RELEASE(LOG_SOTI);

  INFO(LOG_SOTI, "integer variables");
  INDENT(LOG_SOTI);
  for(i=0; i<mData->nVariablesInteger; ++i)
  {
    INFO5(LOG_SOTI, "[%ld] Integer %s(start=%ld) = %ld (pre: %ld)", i+1,
                                                                    mData->integerVarsData[i].info.name,
                                                                    mData->integerVarsData[i].attribute.start,
                                                                    simData->localData[0]->integerVars[i],
                                                                    sInfo->integerVarsPre[i]);
  }
  RELEASE(LOG_SOTI);

  INFO(LOG_SOTI, "boolean variables");
  INDENT(LOG_SOTI);
  for(i=0; i<mData->nVariablesBoolean; ++i)
  {
    INFO5(LOG_SOTI, "[%ld] Boolean %s(start=%s) = %s (pre: %s)", i+1,
                                                                 mData->booleanVarsData[i].info.name,
                                                                 mData->booleanVarsData[i].attribute.start ? "true" : "false",
                                                                 simData->localData[0]->booleanVars[i] ? "true" : "false",
                                                                 sInfo->booleanVarsPre[i] ? "true" : "false");
  }
  RELEASE(LOG_SOTI);

  INFO(LOG_SOTI, "string variables");
  INDENT(LOG_SOTI);
  for(i=0; i<mData->nVariablesString; ++i)
  {
    INFO5(LOG_SOTI, "[%ld] String %s(start=%s) = %s (pre: %s)", i+1,
                                                                mData->stringVarsData[i].info.name,
                                                                mData->stringVarsData[i].attribute.start,
                                                                simData->localData[0]->stringVars[i],
                                                                sInfo->stringVarsPre[i]);
  }
  RELEASE(LOG_SOTI);

  RELEASE(LOG_SOTI);
}

/*! \fn static int initialize2(INIT_DATA *initData, int optiMethod, int useScaling, int lambda_steps)
 *
 *  This is a helper function for initialize.
 *
 *  \param [ref] [initData]
 *  \param [in]  [optiMethod] specified optimization method
 *  \param [in]  [useScaling] specifies whether scaling should be used or not
 *  \param [in]  [lambda_steps] number of steps
 *
 *  \author lochel
 */
static int initialize2(INIT_DATA *initData, int optiMethod, int useScaling, int lambda_steps)
{
  DATA *data = initData->simData;

  double STOPCR = 1.e-12;
  double lambda = 0.0;
  double funcValue;

  long i, j;

  int retVal = 0;

  double *bestZ = (double*)malloc(initData->nVars * sizeof(double));
  double bestFuncValue;

  funcValue = leastSquareWithLambda(initData, 1.0);

  bestFuncValue = funcValue;
  for(i=0; i<initData->nVars; i++)
    bestZ[i] = initData->vars[i] = initData->start[i];

  for(j=1; j<=200 && STOPCR < funcValue; j++)
  {
    INFO1(LOG_INIT, "initialization-nr. %ld", j);

    if(useScaling)
      computeInitialResidualScalingCoefficients(initData);

    if(optiMethod == IOM_SIMPLEX)
      retVal = simplex_initialization(initData);
    else if(optiMethod == IOM_NEWUOA)
      retVal = newuoa_initialization(initData);
    else if(optiMethod == IOM_NELDER_MEAD_EX)
      retVal = nelderMeadEx_initialization(initData, &lambda, lambda_steps);
    else if(optiMethod == IOM_KINSOL)
      retVal = kinsol_initialization(initData);
    else if(optiMethod == IOM_KINSOL_SCALED)
      retVal = kinsol_initialization(initData);
    else if(optiMethod == IOM_IPOPT)
      retVal = ipopt_initialization(initData, 0);
    else
      THROW("unsupported option -iom");

    /*storePreValues(data);*/                       /* save pre-values */
    overwriteOldSimulationData(data);           /* if there are non-linear equations */
    updateDiscreteSystem(data);                 /* evaluate discrete variables */

    /* valid system for the first time! */
    saveZeroCrossings(data);
    /*storePreValues(data);*/                       /* save pre-values */
    overwriteOldSimulationData(data);

    funcValue = leastSquareWithLambda(initData, 1.0);

    if(retVal >= 0 && funcValue < bestFuncValue)
    {
      bestFuncValue = funcValue;
      for(i=0; i<initData->nVars; i++)
        bestZ[i] = initData->vars[i];
      INFO(LOG_INIT, "updating bestZ");
      dumpInitialization(initData);
    }
    else if(retVal >= 0 && funcValue == bestFuncValue)
    {
      /* WARNING("local minimum"); */
      INFO(LOG_INIT, "not updating bestZ");
      break;
    }
    else
      INFO(LOG_INIT, "not updating bestZ");
  }

  setZ(initData, bestZ);
  free(bestZ);

  INFO1(LOG_INIT, "optimization-calls: %ld", j-1);

  return retVal;
}

/*! \fn static int initialize(DATA *data, int optiMethod)
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *
 *  \author lochel
 */
static int initialize(DATA *data, int optiMethod, int lambda_steps)
{
  const double h = 1e-6;

  int retVal = -1;
  long i, j, k;
  double f;
  double *z_f = NULL;
  double* nominal;
  double funcValue;

  /* set up initData struct */
  INIT_DATA *initData = initializeInitData(data);

  /* no initial values to calculate */
  if(initData->nVars == 0)
  {
    INFO(LOG_INIT, "no variables to initialize");
    /* call initial_residual to execute algorithms with no counted outputs, for examples external objects as used in modelica3d */
    if(data->modelData.nInitResiduals == 0)
      initial_residual(data, initData->initialResiduals);
    free(initData);
    return 0;
  }

  /* no initial equations given */
  if(data->modelData.nInitResiduals == 0)
  {
    INFO(LOG_INIT, "no initial residuals (neither initial equations nor initial algorithms)");
    /* call initial_residual to execute algorithms with no counted outputs, for examples external objects as used in modelica3d */
    initial_residual(data, initData->initialResiduals);
    free(initData);
    return 0;
  }

  if(initData->nInitResiduals < initData->nVars)
  {
    INFO(LOG_INIT, "under-determined");
    INDENT(LOG_INIT);

    z_f = (double*)malloc(initData->nVars * sizeof(double));
    nominal = initData->nominal;
    initData->nominal = NULL;
    f = leastSquareWithLambda(initData, 1.0);
    initData->nominal = nominal;
    for(i=0; i<initData->nVars; ++i)
    {
      initData->vars[i] += h;
      nominal = initData->nominal;
      initData->nominal = NULL;
      z_f[i] = fabs(leastSquareWithLambda(initData, 1.0) - f) / h;
      initData->nominal = nominal;
      initData->vars[i] -= h;
    }

    for(j=0; j < data->modelData.nInitResiduals; ++j)
    {
      k = 0;
      for(i=1; i<initData->nVars; ++i)
        if(z_f[i] > z_f[k])
          k = i;
      z_f[k] = -1.0;
    }

    k = 0;
    INFO(LOG_INIT, "setting fixed=true for:");
    INDENT(LOG_INIT);
    for(i=0; i<data->modelData.nStates; ++i)
    {
      if(data->modelData.realVarsData[i].attribute.fixed == 0)
      {
        if(z_f[k] >= 0.0)
        {
          data->modelData.realVarsData[i].attribute.fixed = 1;
          INFO2(LOG_INIT, "%s(fixed=true) = %g", initData->name[k], initData->vars[k]);
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
          INFO2(LOG_INIT, "%s(fixed=true) = %g", initData->name[k], initData->vars[k]);
        }
        k++;
      }
    for(i=data->modelData.nVariablesReal-data->modelData.nDiscreteReal; i<data->modelData.nDiscreteReal; ++i)
    {
      if(data->modelData.realParameterData[i].attribute.fixed == 0)
      {
        if(z_f[k] >= 0.0)
        {
          data->modelData.realParameterData[i].attribute.fixed = 1;
          INFO2(LOG_INIT, "%s(fixed=true) = %g", initData->name[k], initData->vars[k]);
        }
        k++;
      }
    }

    }
    RELEASE(LOG_INIT); RELEASE(LOG_INIT);

    free(z_f);

    freeInitData(initData);
    /* FIX */
    initData = initializeInitData(data);
    /* no initial values to calculate. (not possible to be here) */
    if(initData->nVars == 0)
    {
      INFO(LOG_INIT, "no initial values to calculate");
      free(initData);
      return 0;
    }
  }
  else if(data->modelData.nInitResiduals > initData->nVars)
  {
    INFO(LOG_INIT, "over-determined");

    /*
     * INFO("initial problem is [over-determined]");
     * if(optiMethod == IOM_KINSOL)
     * {
     *   optiMethod = IOM_NELDER_MEAD_EX;
     *   INFO("kinsol-method is unable to solve over-determined problems.");
     *   INFO2("| using %-15s [%s]", OPTI_METHOD_NAME[optiMethod], OPTI_METHOD_DESC[optiMethod]);
     * }
    */
  }

  /* with scaling */
  if(optiMethod == IOM_KINSOL_SCALED ||
     optiMethod == IOM_NELDER_MEAD_EX)
  {
    INFO(LOG_INIT, "start with scaling");

    initialize2(initData, optiMethod, 1, lambda_steps);

    dumpInitialization(initData);

    for(i=0; i<initData->nVars; ++i)
      initData->start[i] = initData->vars[i];
  }

  /* w/o scaling */
  funcValue = leastSquareWithLambda(initData, 1.0);
  if(1e-9 < funcValue)
  {
    if(initData->nominal)
    {
      free(initData->nominal);
      initData->nominal = NULL;
    }

    if(initData->residualScalingCoefficients)
    {
      free(initData->residualScalingCoefficients);
      initData->residualScalingCoefficients = NULL;
    }

    if(initData->startValueResidualScalingCoefficients)
    {
      free(initData->startValueResidualScalingCoefficients);
      initData->startValueResidualScalingCoefficients = NULL;
    }

    initialize2(initData, optiMethod, 0, lambda_steps);

    /* dump final solution */
    dumpInitialization(initData);

    funcValue = leastSquareWithLambda(initData, 1.0);
  }
  else
    INFO(LOG_INIT, "skip w/o scaling");

  INFO(LOG_INIT, "### FINAL INITIALIZATION RESULTS ###");
  INDENT(LOG_INIT);
  dumpInitialization(initData);
  retVal = reportResidualValue(initData);
  RELEASE(LOG_INIT);
  freeInitData(initData);

  return retVal;
}

/*! \fn static int numeric_initialization(DATA *data, int optiMethod, int lambda_steps)
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *  \param [in]  [lambda_steps] number of steps
 *
 *  \author lochel
 */
static int numeric_initialization(DATA *data, int optiMethod, int lambda_steps)
{
  int retVal = 0;

  /* initial sample and delay before initial the system */
  initDelay(data, data->simulationInfo.startTime);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);

  updateDiscreteSystem(data);

  /* and restore start values */
  restoreExtrapolationDataOld(data);
  initializeStateSetPivoting(data);   /* reset state selection */
  storeRelations(data);
  storePreValues(data);

  retVal = initialize(data, optiMethod, lambda_steps);

  /*storePreValues(data);*/                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */
  updateDiscreteSystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  saveZeroCrossings(data);
  /*storePreValues(data);*/                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */

  return retVal;
}

/*! \fn static int symbolic_initialization(DATA *data)
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
static int symbolic_initialization(DATA *data, long numLambdaSteps)
{
  long step;

  /* initial sample and delay before initial the system */
  initDelay(data, data->simulationInfo.startTime);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);

  /* do pivoting for dynamic state selection */
  stateSelection(data, 0, 1);

  if(useHomotopy && numLambdaSteps > 1)
  {
    long i;
    char buffer[4096];
    FILE *pFile = NULL;

    modelica_real* realVars = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    modelica_integer* integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    modelica_boolean* booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    modelica_string* stringVars = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
    MODEL_DATA *mData = &(data->modelData);

    ASSERT(realVars, "out of memory");
    ASSERT(integerVars, "out of memory");
    ASSERT(booleanVars, "out of memory");
    ASSERT(stringVars, "out of memory");

    for(i=0; i<mData->nVariablesReal; ++i)
      realVars[i] = mData->realVarsData[i].attribute.start;
    for(i=0; i<mData->nVariablesInteger; ++i)
      integerVars[i] = mData->integerVarsData[i].attribute.start;
    for(i=0; i<mData->nVariablesBoolean; ++i)
      booleanVars[i] = mData->booleanVarsData[i].attribute.start;
    for(i=0; i<mData->nVariablesString; ++i)
      stringVars[i] = mData->stringVarsData[i].attribute.start;

    if(ACTIVE_STREAM(LOG_INIT))
    {
      sprintf(buffer, "%s_homotopy.csv", mData->modelFilePrefix);
      pFile = fopen(buffer, "wt");
      fprintf(pFile, "%s,", "lambda");
      for(i=0; i<mData->nVariablesReal; ++i)
        fprintf(pFile, "%s,", mData->realVarsData[i].info.name);
      fprintf(pFile, "\n");
    }

    INFO(LOG_INIT, "homotopy process");
    INDENT(LOG_INIT);
    for(step=0; step<numLambdaSteps; ++step)
    {
      data->simulationInfo.lambda = ((double)step)/(numLambdaSteps-1);

      if(data->simulationInfo.lambda > 1.0)
        data->simulationInfo.lambda = 1.0;

      functionInitialEquations(data);

      INFO1(LOG_INIT, "lambda = %g done", data->simulationInfo.lambda);

      if(ACTIVE_STREAM(LOG_INIT))
      {
        fprintf(pFile, "%.16g,", data->simulationInfo.lambda);
        for(i=0; i<mData->nVariablesReal; ++i)
          fprintf(pFile, "%.16g,", data->localData[0]->realVars[i]);
        fprintf(pFile, "\n");
      }

      if(check_nonlinear_solutions(data, 0) ||
         check_linear_solutions(data, 0) ||
         check_mixed_solutions(data, 0))
        break;

      setAllStartToVars(data);
    }
    RELEASE(LOG_INIT);

    if(ACTIVE_STREAM(LOG_INIT))
      fclose(pFile);

    for(i=0; i<mData->nVariablesReal; ++i)
      mData->realVarsData[i].attribute.start = realVars[i];
    for(i=0; i<mData->nVariablesInteger; ++i)
      mData->integerVarsData[i].attribute.start = integerVars[i];
    for(i=0; i<mData->nVariablesBoolean; ++i)
      mData->booleanVarsData[i].attribute.start = booleanVars[i];
    for(i=0; i<mData->nVariablesString; ++i)
      mData->stringVarsData[i].attribute.start = stringVars[i];

    free(realVars);
    free(integerVars);
    free(booleanVars);
    free(stringVars);
  }
  else
  {
    data->simulationInfo.lambda = 1.0;
    functionInitialEquations(data);
  }

  /* update saved value for
     hysteresis relations */
  updateHysteresis(data);

  /* do pivoting for dynamic state selection if selection changed try again an */
  if(stateSelection(data, 1, 1) == 1)
  {
    functionInitialEquations(data);
    updateHysteresis(data);

    /* report a warning about strange start values */
    if(stateSelection(data, 1, 1) == 1)
      WARNING(LOG_STDOUT, "Cannot initialize unique the dynamic state selection. Use -lv LOG_DSS to see the switching state set.");
  }

  return 0;
}

/*! \fn static char *mapToDymolaVars(const char *varname)
 *
 *  \param [in]  [varname]
 *
 *  converts a given variable name into dymola style
 *  ** der(foo.foo2) -> foo.der(foo2)
 *  ** foo.foo2[1,2,3] -> foo.foo2[1, 2, 3]
 *
 *  \author lochel
 */
static char *mapToDymolaVars(const char *varname)
{
  unsigned int varnameSize = strlen(varname);
  unsigned int level = 0;
  unsigned int i=0, j=0, pos=0;
  char* newVarname = NULL;
  unsigned int newVarnameSize = 0;

  newVarnameSize = varnameSize;
  for(i=0; i<varnameSize; i++)
  {
    if(varname[i] == '[')
      level++;
    else if(varname[i] == ']')
      level--;

    if(level > 0 && varname[i] == ',' && varname[i+1] != ' ')
      newVarnameSize++;
  }

  newVarname = (char*)malloc((newVarnameSize+1) * sizeof(char));
  for(i=0,j=0; i<newVarnameSize; i++,j++)
  {
    if(varname[j] == '[')
      level++;
    else if(varname[j] == ']')
      level--;

    newVarname[i] = varname[j];
    if(level > 0 && varname[j] == ',' && varname[j+1] != ' ')
    {
      i++;
      newVarname[i] = ' ';
    }
  }
  newVarname[newVarnameSize] = '\0';

  while(!memcmp((const void*)newVarname, (const void*)"der(", 4*sizeof(char)))
  {
    for(pos=newVarnameSize; pos>=4; pos--)
      if(newVarname[pos] == '.')
        break;

    if(pos == 3)
      break;

    memcpy((void*)newVarname, (const void*)(newVarname+4), (pos-3)*sizeof(char));
    memcpy((void*)(newVarname+pos-3), (const void*)"der(", 4*sizeof(char));
  }

  return newVarname;
}

/*! \fn static int importStartValues(DATA *data, const char *pInitFile, double initTime)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitFile]
 *  \param [in]  [initTime]
 *
 *  \author lochel
 */
static int importStartValues(DATA *data, const char *pInitFile, double initTime)
{
  ModelicaMatReader reader;
  ModelicaMatVariable_t *pVar = NULL;
  double value;
  const char *pError = NULL;
  char* newVarname = NULL;

  MODEL_DATA *mData = &(data->modelData);
  long i;

  INFO2(LOG_INIT, "import start values\nfile: %s\ntime: %g", pInitFile, initTime);

  pError = omc_new_matlab4_reader(pInitFile, &reader);
  if(pError)
  {
    ASSERT2(0, "unable to read input-file <%s> [%s]", pInitFile, pError);
    return 1;
  }
  else
  {
    INFO(LOG_INIT, "import real variables");
    for(i=0; i<mData->nVariablesReal; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->realVarsData[i].info.name);

      if(!pVar)
      {
        newVarname = mapToDymolaVars(mData->realVarsData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar)
      {
        omc_matlab4_val(&(mData->realVarsData[i].attribute.start), &reader, pVar, initTime);
        INFO2(LOG_INIT, "| %s(start=%g)", mData->realVarsData[i].info.name, mData->realVarsData[i].attribute.start);
      }
      else
      {
        /* skipp warnings about self generated variables */
        if(((strncmp (mData->realVarsData[i].info.name,"$ZERO.",6) != 0) && (strncmp (mData->realVarsData[i].info.name,"$pDER.",6) != 0)) || ACTIVE_STREAM(LOG_INIT))
          WARNING1(LOG_INIT, "unable to import real variable %s from given file", mData->realVarsData[i].info.name);
      }
    }

    INFO(LOG_INIT, "import real parameters");
    for(i=0; i<mData->nParametersReal; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->realParameterData[i].info.name);

      if(!pVar)
      {
        newVarname = mapToDymolaVars(mData->realParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar)
      {
        omc_matlab4_val(&(mData->realParameterData[i].attribute.start), &reader, pVar, initTime);
        INFO2(LOG_INIT, "| %s(start=%g)", mData->realParameterData[i].info.name, mData->realParameterData[i].attribute.start);
      }
      else
        WARNING1(LOG_INIT, "unable to import real parameter %s from given file", mData->realParameterData[i].info.name);
    }

    INFO(LOG_INIT, "import real discrete");
    for(i=mData->nVariablesReal-mData->nDiscreteReal; i<mData->nDiscreteReal; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->realParameterData[i].info.name);

      if(!pVar)
      {
        newVarname = mapToDymolaVars(mData->realParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar)
      {
        omc_matlab4_val(&(mData->realParameterData[i].attribute.start), &reader, pVar, initTime);
        INFO2(LOG_INIT, "| %s(start=%g)", mData->realParameterData[i].info.name, mData->realParameterData[i].attribute.start);
      }
      else
        WARNING1(LOG_INIT, "unable to import real parameter %s from given file", mData->realParameterData[i].info.name);
      }


    INFO(LOG_INIT, "import integer parameters");
    for(i=0; i<mData->nParametersInteger; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->integerParameterData[i].info.name);

      if(!pVar)
      {
        newVarname = mapToDymolaVars(mData->integerParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar)
      {
        omc_matlab4_val(&value, &reader, pVar, initTime);
        mData->integerParameterData[i].attribute.start = (modelica_integer)value;
        INFO2(LOG_INIT, "| %s(start=%ld)", mData->integerParameterData[i].info.name, mData->integerParameterData[i].attribute.start);
      }
      else
        WARNING1(LOG_INIT, "unable to import integer parameter %s from given file", mData->integerParameterData[i].info.name);
    }

    INFO(LOG_INIT, "import boolean parameters");
    for(i=0; i<mData->nParametersBoolean; ++i)
    {
      pVar = omc_matlab4_find_var(&reader, mData->booleanParameterData[i].info.name);

      if(!pVar)
      {
        newVarname = mapToDymolaVars(mData->booleanParameterData[i].info.name);
        pVar = omc_matlab4_find_var(&reader, newVarname);
        free(newVarname);
      }

      if(pVar)
      {
        omc_matlab4_val(&value, &reader, pVar, initTime);
        mData->booleanParameterData[i].attribute.start = (modelica_boolean)value;
        INFO2(LOG_INIT, "| %s(start=%s)", mData->booleanParameterData[i].info.name, mData->booleanParameterData[i].attribute.start ? "true" : "false");
      }
      else
        WARNING1(LOG_INIT, "unable to import boolean parameter %s from given file", mData->booleanParameterData[i].info.name);
    }
    omc_free_matlab4_reader(&reader);
  }

  return 0;
}

/*! \fn int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod, const char* pInitFile, double initTime)
 *
 *  \param [ref] [data]
 *  \param [in]  [pInitMethod] user defined initialization method
 *  \param [in]  [pOptiMethod] user defined optimization method
 *  \param [in]  [pInitFile] extra argument for initialization-method "file"
 *  \param [in]  [initTime] extra argument for initialization-method "file"
 *
 *  \author lochel
 */
int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod, const char* pInitFile, double initTime, int lambda_steps)
{
  int initMethod = useSymbolicInitialization ? IIM_SYMBOLIC : IIM_NUMERIC;  /* default method */
  int optiMethod = IOM_NELDER_MEAD_EX;                                      /* default method */
  int retVal = -1;
  int i;

  INFO(LOG_INIT, "### START INITIALIZATION ###");

  /* import start values from extern mat-file */
  if(pInitFile && strcmp(pInitFile, ""))
  {
    importStartValues(data, pInitFile, initTime);
  }

  /* set up all variables and parameters with their start-values */
  setAllParamsToStart(data);
  setAllVarsToStart(data);

  if(!(pInitFile && strcmp(pInitFile, "")))
  {
    updateBoundParameters(data);
    updateBoundStartValues(data);
  }

  /* if there are user-specified options, use them! */
  if(pInitMethod && strcmp(pInitMethod, ""))
  {
    initMethod = IIM_UNKNOWN;

    for(i=1; i<IIM_MAX; ++i)
    {
      if(!strcmp(pInitMethod, INIT_METHOD_NAME[i]))
        initMethod = i;
    }

    if(initMethod == IIM_UNKNOWN)
    {
      WARNING1(LOG_STDOUT, "unrecognized option -iim %s", pInitMethod);
      WARNING(LOG_STDOUT, "current options are:");
      for(i=1; i<IIM_MAX; ++i)
        WARNING2(LOG_STDOUT, "| %-15s [%s]", INIT_METHOD_NAME[i], INIT_METHOD_DESC[i]);
      THROW("see last warning");
    }
  }

  if(pOptiMethod && strcmp(pOptiMethod, ""))
  {
    optiMethod = IOM_UNKNOWN;

    for(i=1; i<IOM_MAX; ++i)
    {
      if(!strcmp(pOptiMethod, OPTI_METHOD_NAME[i]))
        optiMethod = i;
    }

    if(optiMethod == IOM_UNKNOWN)
    {
      WARNING1(LOG_STDOUT, "unrecognized option -iom %s", pOptiMethod);
      WARNING(LOG_STDOUT, "current options are:");
      for(i=1; i<IOM_MAX; ++i)
        WARNING2(LOG_STDOUT, "| %-15s [%s]", OPTI_METHOD_NAME[i], OPTI_METHOD_DESC[i]);
      THROW("see last warning");
    }
  }

  INFO2(LOG_INIT, "initialization method: %-15s [%s]", INIT_METHOD_NAME[initMethod], INIT_METHOD_DESC[initMethod]);
  if(initMethod == IIM_NUMERIC)
    INFO2(LOG_INIT, "optimization method:   %-15s [%s]", OPTI_METHOD_NAME[optiMethod], OPTI_METHOD_DESC[optiMethod]);

  /* start with the real initialization */
  data->simulationInfo.initial = 1;             /* to evaluate when-equations with initial()-conditions */

  /* initialize all (nonlinear|linear|mixed) systems
   * This is a workaround and should be removed as soon as possible.
   */
  for(i=0; i<data->modelData.nNonLinearSystems; ++i)
    data->simulationInfo.nonlinearSystemData[i].solved = 1;
  for(i=0; i<data->modelData.nLinearSystems; ++i)
    data->simulationInfo.linearSystemData[i].solved = 1;
  for(i=0; i<data->modelData.nMixedSystems; ++i)
    data->simulationInfo.mixedSystemData[i].solved = 1;
  /* end workaround */

  /* select the right initialization-method */
  if(initMethod == IIM_NONE)
    retVal = 0;
  else if(initMethod == IIM_NUMERIC)
    retVal = numeric_initialization(data, optiMethod, lambda_steps);
  else if(initMethod == IIM_SYMBOLIC)
    retVal = symbolic_initialization(data, lambda_steps);
  else
    THROW("unsupported option -iim");

  /* check for unsolved (nonlinear|linear|mixed) systems
   * This is a workaround and should be removed as soon as possible.
   */
  if(check_nonlinear_solutions(data, 1))
    retVal = -2;
  else if(check_linear_solutions(data, 1))
    retVal = -3;
  else if(check_mixed_solutions(data, 1))
    retVal = -4;
  /* end workaround */

  dumpInitialSolution(data);
  INFO(LOG_INIT, "### END INITIALIZATION ###");

  data->simulationInfo.initial = 0;

  /* initialization is done */
  initSample(data, data->simulationInfo.startTime, data->simulationInfo.stopTime);

  /* TODO: remove following lines */
  storePreValues(data);                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */
  updateDiscreteSystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  saveZeroCrossings(data);
  storePreValues(data);                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */

  return retVal;
}
