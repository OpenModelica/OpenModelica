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

#include "initialization_data.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <string.h>

enum INIT_INIT_METHOD
{
  IIM_UNKNOWN = 0,
  IIM_NONE,
  IIM_STATE,
  IIM_MAX
};

const char *initMethodStr[IIM_MAX] = {
  "unknown",
  "none",
  "state"
};
const char *initMethodDescStr[IIM_MAX] = {
  "unknown",
  "no initialization method",
  "default initialization method"
};

enum INIT_OPTI_METHOD
{
  IOM_UNKNOWN = 0,
  IOM_SIMPLEX,
  IOM_NEWUOA,
  IOM_NELDER_MEAD_EX,
  IOM_NELDER_MEAD_EX2,
  IOM_KINSOL,
  IOM_KINSOL_SCALED,
  IOM_IPOPT,
  IOM_MAX
};

const char *optiMethodStr[IOM_MAX] = {
  "unknown",
  "simplex",
  "newuoa",
  "nelder_mead_ex",
  "nelder_mead_ex2",
  "kinsol",
  "kinsol_scaled",
  "ipopt"
};
const char *optiMethodDescStr[IOM_MAX] = {
  "unknown",
  "Nelder-Mead method",
  "Brent's method",
  "Nelder-Mead method with global homotopy",
  "Nelder-Mead method without global homotopy",
  "sundials/kinsol",
  "sundials/kinsol with scaling",
  "Interior Point OPTimizer"
};

/*! \fn int reportResidualValue(INIT_DATA *initData)
 *
 *  return 1: if funcValue >  1e-5 and prints appropriate error message
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
    DEBUG_INFO(LOG_INIT, "error in initialization. System of initial equations are not consistent");
    DEBUG_INFO_AL1(LOG_INIT, "(least square function value is %g)", funcValue);

    for(i=0; i<initData->nInitResiduals; i++)
      if(1e-5 < fabs(initData->initialResiduals[i]))
        DEBUG_INFO_AL2(LOG_INIT, "| residual[%ld] = %g", i+1, initData->initialResiduals[i]);
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
  functionODE(data);
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

          funcValue += (1.0-lambda)*((data->modelData.realParameterData[i].attribute.start-data->localData[0]->realVars[i])/scalingCoefficient)*((data->modelData.realParameterData[i].attribute.start-data->localData[0]->realVars[i])/scalingCoefficient);
        }
  }

  return funcValue;
}

/*! \fn static int initialize(DATA *data, int optiMethod)
 *
 *  This is a helper function for initialize.
 *
 *  \param [ref] [initData]
 *  \param [in]  [optiMethod] specified optimization method
 *
 *  \author lochel
 */
static int initialize2(INIT_DATA *initData, int optiMethod)
{
  DATA *data = initData->simData;

  double STOPCR = 1.e-12;
  double lambda = (optiMethod == IOM_NELDER_MEAD_EX2) ? 1.0 : 0.0;
  double funcValue;

  long i, j;

  int retVal;

  double *bestZ = (double*)malloc(initData->nVars * sizeof(double));
  double bestFuncValue;

  funcValue = leastSquareWithLambda(initData, 1.0);

  bestFuncValue = funcValue;
  for(i=0; i<initData->nVars; i++)
    bestZ[i] = initData->vars[i] = initData->start[i];

  for(j=1; j<=200 && STOPCR < funcValue; j++)
  {
    DEBUG_INFO1(LOG_INIT, "initialization-nr. %ld", j);

    if(optiMethod == IOM_SIMPLEX)
      retVal = simplex_initialization(initData);
    else if(optiMethod == IOM_NEWUOA)
      retVal = newuoa_initialization(initData);
    else if(optiMethod == IOM_NELDER_MEAD_EX)
      retVal = nelderMeadEx_initialization(initData, &lambda);
    else if(optiMethod == IOM_NELDER_MEAD_EX2)
      retVal = nelderMeadEx_initialization(initData, &lambda);
    else if(optiMethod == IOM_KINSOL)
      retVal = kinsol_initialization(initData);
    else if(optiMethod == IOM_KINSOL_SCALED)
      retVal = kinsol_initialization(initData);
    else if(optiMethod == IOM_IPOPT)
      retVal = ipopt_initialization(initData, 0);
    else
      THROW("unsupported option -iom");

    storePreValues(data);                       /* save pre-values */
    overwriteOldSimulationData(data);           /* if there are non-linear equations */
    updateDiscreteSystem(data);                 /* evaluate discrete variables */

    /* valid system for the first time! */
    saveZeroCrossings(data);
    storePreValues(data);
    overwriteOldSimulationData(data);

    funcValue = leastSquareWithLambda(initData, 1.0);

    DEBUG_INFO1(LOG_INIT, "ending with funcValue = %g", funcValue);
    DEBUG_INFO_AL1(LOG_INIT, "| lambda: %g", lambda);
    DEBUG_INFO_AL(LOG_INIT, "| unfixed variables");
    for(i=0; i<initData->nVars; i++)
      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] %s = %g [scaled: %g]", i+1, initData->name[i], initData->vars[i], initData->nominal ? initData->vars[i]/initData->nominal[i] : initData->vars[i]);
    DEBUG_INFO_AL(LOG_INIT, "| residuals (> 0.001)");
    for(i=0; i<data->modelData.nInitResiduals; i++)
      if(fabs(initData->initialResiduals[i]) > 1e-3)
        DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] %g [scaled: %g]", i+1, initData->initialResiduals[i], initData->residualScalingCoefficients ? initData->initialResiduals[i]/initData->residualScalingCoefficients[i] : initData->initialResiduals[i]);

    if(retVal >= 0 && funcValue < bestFuncValue)
    {
      bestFuncValue = funcValue;
      for(i=0; i<initData->nVars; i++)
        bestZ[i] = initData->vars[i];
    }
    else if(retVal >= 0 && funcValue == bestFuncValue)
    {
      /*WARNING("local minimum");*/
      break;
    }
  }

  setZ(initData, bestZ);
  free(bestZ);

  DEBUG_INFO1(LOG_INIT, "optimization-calls: %ld", j-1);

  return retVal;
}

/*! \fn static int initialize(DATA *data, int optiMethod)
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *
 *  \author lochel
 */
static int initialize(DATA *data, int optiMethod)
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
  if(initData == NULL)
  {
    DEBUG_INFO(LOG_INIT, "no variables to initialize");
    return 0;
  }

  /* no initial equations given */
  if(data->modelData.nInitResiduals == 0)
  {
    DEBUG_INFO(LOG_INIT, "no initial residuals (neither initial equations nor initial algorithms)");
    return 0;
  }

  if(initData->nInitResiduals < initData->nVars)
  {
    DEBUG_INFO_AL(LOG_INIT, "under-determined");

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
    DEBUG_INFO(LOG_INIT, "| setting fixed=true for:");
    for(i=0; i<data->modelData.nStates; ++i)
    {
      if(data->modelData.realVarsData[i].attribute.fixed == 0)
      {
        if(z_f[k] >= 0.0)
        {
          data->modelData.realVarsData[i].attribute.fixed = 1;
          DEBUG_INFO2(LOG_INIT, "| | %s(fixed=true) = %g", initData->name[k], initData->vars[k]);
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
          DEBUG_INFO2(LOG_INIT, "| | %s(fixed=true) = %g", initData->name[k], initData->vars[k]);
        }
        k++;
      }
    }

    free(z_f);

    freeInitData(initData);
    /* FIX */
    initData = initializeInitData(data);
    /* no initial values to calculate. (not possible to be here) */
    if(initData == NULL)
    {
      DEBUG_INFO(LOG_INIT, "no initial values to calculate");
      return 0;
    }
  }
  else if(data->modelData.nInitResiduals > initData->nVars)
  {
    DEBUG_INFO_AL(LOG_INIT, "over-determined");

    /*
     * INFO("initial problem is [over-determined]");
     * if(optiMethod == IOM_KINSOL)
     * {
     *   optiMethod = IOM_NELDER_MEAD_EX;
     *   INFO("kinsol-method is unable to solve over-determined problems.");
     *   INFO_AL2("| using %-15s [%s]", optiMethodStr[optiMethod], optiMethodDescStr[optiMethod]);
     * }
    */
  }

  /* with scaling */
  if(optiMethod == IOM_KINSOL_SCALED ||
    optiMethod == IOM_NELDER_MEAD_EX ||
    optiMethod == IOM_NELDER_MEAD_EX2)
  {
    DEBUG_INFO(LOG_INIT, "start with scaling");

    computeInitialResidualScalingCoefficients(initData);
    initialize2(initData, optiMethod);

    /* dump interim solution */
    DEBUG_INFO(LOG_INIT, "interim initial solution");
    DEBUG_INFO_AL(LOG_INIT, "| unfixed variables");
    for(i=0; i<initData->nStates; ++i)
      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] Real %s = %g [scaled: %g]", i+1, initData->name[i], initData->vars[i], initData->vars[i]/initData->nominal[i]);
    for(; i<initData->nVars; ++i)
      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] parameter Real %s = %g [scaled: %g]", i+1, initData->name[i], initData->vars[i], initData->vars[i]/initData->nominal[i]);

    DEBUG_INFO_AL(LOG_INIT, "| initial residuals");
    for(i=0; i<initData->nInitResiduals; ++i)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] %g [scaling coefficient: %g]", i+1, initData->initialResiduals[i], initData->residualScalingCoefficients[i]);

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

    initialize2(initData, optiMethod);

    /* dump final solution */
    DEBUG_INFO(LOG_INIT, "final initial solution");
    DEBUG_INFO_AL(LOG_INIT, "| unfixed variables");
    for(i=0; i<initData->nStates; ++i)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] Real %s = %g", i+1, initData->name[i], initData->vars[i]);
    for(; i<initData->nVars; ++i)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] parameter Real %s = %g", i+1, initData->name[i], initData->vars[i]);

    DEBUG_INFO_AL(LOG_INIT, "| initial residuals");
    for(i=0; i<initData->nInitResiduals; ++i)
      DEBUG_INFO_AL2(LOG_INIT, "| | [%ld] %g", i+1, initData->initialResiduals[i]);

    funcValue = leastSquareWithLambda(initData, 1.0);
  }
  else
    DEBUG_INFO(LOG_INIT, "skip w/o scaling");

  retVal = reportResidualValue(initData);
  freeInitData(initData);

  return retVal;
}

/*! \fn static int none_initialization(DATA *data, int updateStartValues)
 *
 *  \param [ref] [data]
 *  \param [in]  [updateStartValues]
 *
 *  \author lochel
 */
static int none_initialization(DATA *data, int updateStartValues)
{
  /*INIT_DATA *initData = NULL;*/

  /* set up all variables and parameters with their start-values */
  setAllVarsToStart(data);
  setAllParamsToStart(data);
  if(updateStartValues)
  {
    updateBoundParameters(data);
    updateBoundStartValues(data);
  }

  /* initial sample and delay before initial the system */
  initSample(data, data->simulationInfo.startTime, data->simulationInfo.stopTime);
  initDelay(data, data->simulationInfo.startTime);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);
  updateDiscreteSystem(data);

  /* and restore start values and helpvars */
  restoreExtrapolationDataOld(data);
  resetAllHelpVars(data);
  storePreValues(data);

  /* dump some information
  initData = initializeInitData(data);
  if(initData)
    freeInitData(initData);*/

  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */
  updateDiscreteSystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  saveZeroCrossings(data);
  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);             /* save pre-values */
  overwriteOldSimulationData(data); /* if there are non-linear equations */

  return 0;
}

/*! \fn static int state_initialization(DATA *data, int optiMethod, int updateStartValues)
 *
 *  \param [ref] [data]
 *  \param [in]  [optiMethod] specified optimization method
 *  \param [in]  [updateStartValues]
 *
 *  \author lochel
 */
static int state_initialization(DATA *data, int optiMethod, int updateStartValues)
{
  int retVal = 0;
  int i;

  /* set up all variables and parameters with their start-values */
  setAllVarsToStart(data);
  setAllParamsToStart(data);
  if(updateStartValues)
  {
    updateBoundParameters(data);
    updateBoundStartValues(data);
  }

  /* initial sample and delay before initial the system */
  initSample(data, data->simulationInfo.startTime, data->simulationInfo.stopTime);
  initDelay(data, data->simulationInfo.startTime);

  /* initialize all relations that are ZeroCrossings */
  storePreValues(data);
  overwriteOldSimulationData(data);
  updateDiscreteSystem(data);

  /* and restore start values and helpvars */
  restoreExtrapolationDataOld(data);
  resetAllHelpVars(data);
  storePreValues(data);

  /* debug print */
  if(DEBUG_FLAG(LOG_DEBUG))
    for(i=0; i<3;i++)
      printAllVars(data, i);

  retVal = initialize(data, optiMethod);

  /* debug print */
  if(DEBUG_FLAG(LOG_DEBUG))
    for(i=0; i<3;i++)
      printAllVars(data, i);

  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */
  updateDiscreteSystem(data);           /* evaluate discrete variables */

  /* valid system for the first time! */
  saveZeroCrossings(data);
  storeInitialValues(data);
  storeInitialValuesParam(data);
  storePreValues(data);                 /* save pre-values */
  overwriteOldSimulationData(data);     /* if there are non-linear equations */

  return retVal;
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

  DEBUG_INFO    (LOG_INIT, "import start values");
  DEBUG_INFO_AL1(LOG_INIT, "| file: %s", pInitFile);
  DEBUG_INFO_AL1(LOG_INIT, "| time: %g", initTime);

  pError = omc_new_matlab4_reader(pInitFile, &reader);
  if(pError)
  {
    THROW2("unable to read input-file <%s> [%s]", pInitFile, pError);
    return 1;
  }
  else
  {
    DEBUG_INFO(LOG_INIT, "import real variables");
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
        DEBUG_INFO_AL2(LOG_INIT, "| %s(start=%g)", mData->realVarsData[i].info.name, mData->realVarsData[i].attribute.start);
      }
      else
      {
        /* skipp warnings about self generated variables */
        if (((strncmp (mData->realVarsData[i].info.name,"$ZERO.",6) != 0) && (strncmp (mData->realVarsData[i].info.name,"$pDER.",6) != 0)) || DEBUG_FLAG(LOG_INIT))
          WARNING1("unable to import real variable %s from given file", mData->realVarsData[i].info.name);
      }
    }

    DEBUG_INFO(LOG_INIT, "import real parameters");
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
        DEBUG_INFO_AL2(LOG_INIT, "| %s(start=%g)", mData->realParameterData[i].info.name, mData->realParameterData[i].attribute.start);
      }
      else
        WARNING1("unable to import real parameter %s from given file", mData->realParameterData[i].info.name);
    }

    DEBUG_INFO(LOG_INIT, "import integer parameters");
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
        DEBUG_INFO_AL2(LOG_INIT, "| %s(start=%ld)", mData->integerParameterData[i].info.name, mData->integerParameterData[i].attribute.start);
      }
      else
        WARNING1("unable to import integer parameter %s from given file", mData->integerParameterData[i].info.name);
    }

    DEBUG_INFO(LOG_INIT, "import boolean parameters");
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
        DEBUG_INFO_AL2(LOG_INIT, "| %s(start=%s)", mData->booleanParameterData[i].info.name, mData->booleanParameterData[i].attribute.start ? "true" : "false");
      }
      else
        WARNING1("unable to import boolean parameter %s from given file", mData->booleanParameterData[i].info.name);
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
int initialization(DATA *data, const char* pInitMethod, const char* pOptiMethod, const char* pInitFile, double initTime)
{
  int initMethod = IIM_STATE;               /* default method */
  int optiMethod = IOM_NELDER_MEAD_EX;      /* default method */
  int retVal = -1;
  int updateStartValues = 1;
  int i;

  DEBUG_INFO(LOG_INIT, "### START INITIALIZATION ###");

  /* import start values from extern mat-file */
  if(pInitFile && strcmp(pInitFile, ""))
  {
    importStartValues(data, pInitFile, initTime);
    updateStartValues = 0;
  }

  /* if there are user-specified options, use them! */
  if(pInitMethod && strcmp(pInitMethod, ""))
  {
    initMethod = IIM_UNKNOWN;

    for(i=1; i<IIM_MAX; ++i)
    {
      if(!strcmp(pInitMethod, initMethodStr[i]))
        initMethod = i;
    }

    if(initMethod == IIM_UNKNOWN)
    {
      WARNING1("unrecognized option -iim %s", pInitMethod);
      WARNING_AL("current options are:");
      for(i=1; i<IIM_MAX; ++i)
        WARNING_AL2("| %-15s [%s]", initMethodStr[i], initMethodDescStr[i]);
      THROW("see last warning");
    }
  }

  if(pOptiMethod && strcmp(pOptiMethod, ""))
  {
    optiMethod = IOM_UNKNOWN;

    for(i=1; i<IOM_MAX; ++i)
    {
      if(!strcmp(pOptiMethod, optiMethodStr[i]))
        optiMethod = i;
    }

    if(optiMethod == IOM_UNKNOWN)
    {
      WARNING1("unrecognized option -iom %s", pOptiMethod);
      WARNING_AL("current options are:");
      for(i=1; i<IOM_MAX; ++i)
        WARNING_AL2("| %-15s [%s]", optiMethodStr[i], optiMethodDescStr[i]);
      THROW("see last warning");
    }
  }

  DEBUG_INFO2(LOG_INIT,    "initialization method: %-15s [%s]", initMethodStr[initMethod], initMethodDescStr[initMethod]);
  DEBUG_INFO_AL2(LOG_INIT, "optimization method:   %-15s [%s]", optiMethodStr[optiMethod], optiMethodDescStr[optiMethod]);
  DEBUG_INFO_AL1(LOG_INIT, "update start values:   %s", updateStartValues ? "true" : "false");

  /* start with the real initialization */
  data->simulationInfo.initial = 1;             /* to evaluate when-equations with initial()-conditions */

  /* select the right initialization-method */
  if(initMethod == IIM_NONE)
    retVal = none_initialization(data, updateStartValues);
  else if(initMethod == IIM_STATE)
    retVal = state_initialization(data, optiMethod, updateStartValues);
  else
    THROW("unsupported option -iim");

  data->simulationInfo.initial = 0;

  DEBUG_INFO(LOG_INIT, "### END INITIALIZATION ###");
  return retVal;
}
