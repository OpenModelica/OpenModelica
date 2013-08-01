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

/*! \file initialization_data.c
 */

#include "initialization_data.h"
#include "initialization.h"
#include <math.h>

/*! \fn initializeInitData
 *
 *  This function initialize the init-data struct.
 *
 *  \param [in]  [simData]
 *
 *  return NULL: no vars to initialize
 *         else: initialized init-data struct
 *
 *  \author lochel
 */
INIT_DATA *initializeInitData(DATA *simData)
{
  long i, j;
  INIT_DATA *initData = NULL;

  initData = (INIT_DATA*)malloc(sizeof(INIT_DATA));
  ASSERT(initData, "out of memory");

  initData->nVars = 0;
  initData->nStates = 0;
  initData->nParameters = 0;
  initData->nDiscreteReal = 0;
  initData->nInitResiduals = 0;
  initData->nStartValueResiduals = 0;

  initData->vars = NULL;
  initData->start = NULL;
  initData->min = NULL;
  initData->max = NULL;
  initData->nominal = NULL;
  initData->name = NULL;

  initData->initialResiduals = NULL;
  initData->residualScalingCoefficients = NULL;
  initData->startValueResidualScalingCoefficients = NULL;

  initData->simData = simData;

  /* count unfixed states */
  for(i=0; i<simData->modelData.nStates; ++i)
    if(simData->modelData.realVarsData[i].attribute.fixed == 0)
      ++initData->nStates;

  /* plus unfixed real-parameters */
  for(i=0; i<simData->modelData.nParametersReal; ++i)
    if(simData->modelData.realParameterData[i].attribute.fixed == 0)
      ++initData->nParameters;

  /* plus unfixed real-Discrete */
  for(i=simData->modelData.nVariablesReal-simData->modelData.nDiscreteReal; i<simData->modelData.nVariablesReal; ++i)
    if(simData->modelData.realVarsData[i].attribute.fixed == 0)
      ++initData->nDiscreteReal;

  initData->nVars = initData->nStates + initData->nParameters + initData->nDiscreteReal;

  if(initData->nVars == 0)
  {
    return initData;
  }

  initData->vars = (double*)calloc(initData->nVars, sizeof(double));
  ASSERT(initData->vars, "out of memory");

  initData->start = (double*)calloc(initData->nVars, sizeof(double));
  ASSERT(initData->start, "out of memory");

  initData->min = (double*)calloc(initData->nVars, sizeof(double));
  ASSERT(initData->min, "out of memory");

  initData->max = (double*)calloc(initData->nVars, sizeof(double));
  ASSERT(initData->max, "out of memory");

  initData->nominal = (double*)calloc(initData->nVars, sizeof(double));
  ASSERT(initData->nominal, "out of memory");

  initData->name = (char**)calloc(initData->nVars, sizeof(char*));
  ASSERT(initData->name, "out of memory");

  /* setup initData */
  INFO(LOG_INIT, "initial problem:");
  INFO4(LOG_INIT, "| number of unfixed variables:  %ld (%ld states + %ld parameters + %ld discrete reals)", initData->nVars, initData->nStates, initData->nParameters, initData->nDiscreteReal);

  /* i: all states; j: all unfixed vars */
  for(i=0, j=0; i<simData->modelData.nStates; ++i)
  {
    if(simData->modelData.realVarsData[i].attribute.fixed == 0)
    {
      initData->name[j] = (char*)simData->modelData.realVarsData[i].info.name;
      initData->nominal[j] = simData->modelData.realVarsData[i].attribute.useNominal ? fabs(simData->modelData.realVarsData[i].attribute.nominal) : 1.0;
      if(initData->nominal[j] == 0.0)
      {
        /* adrpo 2012-05-08 disable the warning for now until the whole infrastructure is in place
         *                  because this breaks the FMI tests with these kind of messages:
         *                  warning | (null)(nominal=0)
         *                          | nominal value is set to 1.0
         * put it back when everything works fine.
         * WARNING2("%s(nominal=%g)", initData->name[iz], initData->nominal[iz]);
         * WARNING_AL("nominal value is set to 1.0");
         */
        initData->nominal[j] = 1.0;
      }

      initData->vars[j] = simData->modelData.realVarsData[i].attribute.start;
      initData->start[j] = simData->modelData.realVarsData[i].attribute.start;
      initData->min[j] = simData->modelData.realVarsData[i].attribute.min;
      initData->max[j] = simData->modelData.realVarsData[i].attribute.max;

      INFO5(LOG_INIT, "| | [%ld] Real %s(start=%g, nominal=%g) = %g", j+1, initData->name[j], initData->start[j], initData->nominal[j], initData->vars[j]);
      j++;
    }
  }

  /* i: all parameters; j: all unfixed vars */
  for(i=0; i<simData->modelData.nParametersReal; ++i)
  {
    if(simData->modelData.realParameterData[i].attribute.fixed == 0)
    {
      initData->name[j] = (char*)simData->modelData.realParameterData[i].info.name;
      initData->nominal[j] = fabs(simData->modelData.realParameterData[i].attribute.nominal);
      if(initData->nominal[j] == 0.0)
      {
        /* adrpo 2012-05-08 disable the warning for now until the whole infrastructure is in place
         *                  because this breaks the FMI tests with these kind of messages:
         *                  warning | (null)(nominal=0)
         *                          | nominal value is set to 1.0
         * put it back when everything works fine.
         * WARNING2("%s(nominal=%g)", initData->name[iz], initData->nominal[iz]);
         * WARNING_AL("nominal value is set to 1.0");
         */
        initData->nominal[j] = 1.0;
      }

      initData->vars[j] = simData->modelData.realParameterData[i].attribute.start;
      initData->start[j] = simData->modelData.realParameterData[i].attribute.start;
      initData->min[j] = simData->modelData.realParameterData[i].attribute.min;
      initData->max[j] = simData->modelData.realParameterData[i].attribute.max;

      INFO5(LOG_INIT, "| | [%ld] parameter Real %s(start=%g, nominal=%g) = %g", j+1, initData->name[j], initData->start[j], initData->nominal[j], initData->vars[j]);
      j++;
    }
  }

/* i: all DiscreteReal; j: all unfixed vars */
  for(i=simData->modelData.nVariablesReal-simData->modelData.nDiscreteReal; i<simData->modelData.nVariablesReal; ++i)
  {
    if(simData->modelData.realVarsData[i].attribute.fixed == 0)
    {
      initData->name[j] = (char*)simData->modelData.realVarsData[i].info.name;
      initData->nominal[j] = simData->modelData.realVarsData[i].attribute.useNominal ? fabs(simData->modelData.realVarsData[i].attribute.nominal) : 1.0;
      if(initData->nominal[j] == 0.0)
      {
        /* adrpo 2012-05-08 disable the warning for now until the whole infrastructure is in place
         *                  because this breaks the FMI tests with these kind of messages:
         *                  warning | (null)(nominal=0)
         *                          | nominal value is set to 1.0
         * put it back when everything works fine.
         * WARNING2("%s(nominal=%g)", initData->name[iz], initData->nominal[iz]);
         * WARNING_AL("nominal value is set to 1.0");
         */
        initData->nominal[j] = 1.0;
      }

      initData->vars[j] = simData->modelData.realVarsData[i].attribute.start;
      initData->start[j] = simData->modelData.realVarsData[i].attribute.start;
      initData->min[j] = simData->modelData.realVarsData[i].attribute.min;
      initData->max[j] = simData->modelData.realVarsData[i].attribute.max;

      INFO5(LOG_INIT, "| | [%ld] discrete Real %s(start=%g, nominal=%g) = %g", j+1, initData->name[j], initData->start[j], initData->nominal[j], initData->vars[j]);
      j++;
    }
  }

  /* equations */
  initData->nInitResiduals = simData->modelData.nInitResiduals;
  initData->nStartValueResiduals = 0;

  /* for real variables */
  for(i=0; i<simData->modelData.nVariablesReal; ++i)
    if(simData->modelData.realVarsData[i].attribute.useStart)
      initData->nStartValueResiduals++;
  /* for real parameters */
  for(i=0; i<simData->modelData.nParametersReal; ++i)
    if(simData->modelData.realParameterData[i].attribute.useStart && !simData->modelData.realParameterData[i].attribute.fixed)
      initData->nStartValueResiduals++;
  /* for real discrete */
  for(i=simData->modelData.nVariablesReal-simData->modelData.nDiscreteReal; i<simData->modelData.nVariablesReal; ++i)
    if(simData->modelData.realVarsData[i].attribute.useStart && !simData->modelData.realVarsData[i].attribute.fixed)
      initData->nStartValueResiduals++;

  INFO3(LOG_INIT, "| number of initial residuals:  %ld (%ld equations + %ld algorithms)", initData->nInitResiduals, simData->modelData.nInitEquations, simData->modelData.nInitAlgorithms);
  INFO1(LOG_INIT, "| number of start value residuals: %ld", initData->nStartValueResiduals);

  initData->initialResiduals = (double*)calloc(initData->nInitResiduals, sizeof(double));
  ASSERT(initData->initialResiduals, "out of memory");

  initData->residualScalingCoefficients = (double*)malloc(initData->nInitResiduals * sizeof(double));
  ASSERT(initData->residualScalingCoefficients, "out of memory");

  initData->startValueResidualScalingCoefficients = (double*)malloc(initData->nStartValueResiduals * sizeof(double));
  ASSERT(initData->startValueResidualScalingCoefficients, "out of memory");

  for(i=0; i<initData->nInitResiduals; ++i)
    initData->residualScalingCoefficients[i] = 1.0;
  for(i=0; i<initData->nStartValueResiduals; ++i)
    initData->startValueResidualScalingCoefficients[i] = 1.0;

  return initData;
}

/*! \fn freeInitData
 *
 *  \param [ref] [initData]
 *
 *  \author lochel
 */
void freeInitData(INIT_DATA *initData)
{
  if(initData->vars)
    free(initData->vars);
  if(initData->start)
    free(initData->start);
  if(initData->min)
    free(initData->min);
  if(initData->max)
    free(initData->max);
  if(initData->nominal)
    free(initData->nominal);
  if(initData->name)
    free(initData->name);

  if(initData->initialResiduals)
    free(initData->initialResiduals);
  if(initData->residualScalingCoefficients)
    free(initData->residualScalingCoefficients);
  if(initData->startValueResidualScalingCoefficients)
    free(initData->startValueResidualScalingCoefficients);

  free(initData);
}

/*! \fn computeInitialResidualScalingCoefficients
 *
 *  This function calculates scaling coefficients for every initial_residual.
 *
 *  \param [ref] [initData]
 *
 *  \author lochel
 */
void computeInitialResidualScalingCoefficients(INIT_DATA *initData)
{
  long i, j, ix;

  double *tmpResidual1 = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *tmpResidual2 = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *tmpStartResidual1 = (double*)calloc(initData->nStartValueResiduals, sizeof(double));
  double *tmpStartResidual2 = (double*)calloc(initData->nStartValueResiduals, sizeof(double));
  double *residualScalingCoefficients = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *startValueResidualScalingCoefficients = (double*)calloc(initData->nStartValueResiduals, sizeof(double));

  const double h = 1e-6;

  DATA *data = initData->simData;

  if(!(initData->nominal && initData->residualScalingCoefficients && initData->startValueResidualScalingCoefficients))
    return;

  for(i=0; i<initData->nInitResiduals; ++i)
    initData->residualScalingCoefficients[i] = 1.0;
  for(i=0; i<initData->nStartValueResiduals; ++i)
    initData->startValueResidualScalingCoefficients[i] = 1.0;

  /* lambda = 1.0 */
  leastSquareWithLambda(initData, 1.0);
  for(i=0; i<initData->nInitResiduals; ++i)
    tmpResidual1[i] = initData->initialResiduals[i];

  ix = 0;
  /* for real variables */
  for(i=0; i<data->modelData.nVariablesReal; ++i)
    if(data->modelData.realVarsData[i].attribute.useStart)
      tmpStartResidual1[ix++] = data->modelData.realVarsData[i].attribute.start - data->localData[0]->realVars[i];
  /* for real parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
    if(data->modelData.realParameterData[i].attribute.useStart && !data->modelData.realParameterData[i].attribute.fixed)
      tmpStartResidual1[ix++] = data->modelData.realParameterData[i].attribute.start - data->localData[0]->realVars[i];
  /* for real discrete */
  for(i=data->modelData.nVariablesReal-data->modelData.nDiscreteReal; i<data->modelData.nDiscreteReal; ++i)
    if(data->modelData.realVarsData[j].attribute.useStart && !data->modelData.realVarsData[j].attribute.fixed)
      tmpStartResidual1[ix++] = data->modelData.realVarsData[i].attribute.start - data->localData[0]->realVars[i];
  
    for(i=0; i<initData->nVars; ++i)
  {
    initData->vars[i] += h;

    leastSquareWithLambda(initData, 1.0);
    for(j=0; j<initData->nInitResiduals; ++j)
      tmpResidual2[j] = initData->initialResiduals[j];

    ix = 0;
    
    /* TODO: is data->localData[0]->realVars[j] correct??? */
    /* for real variables */
    for(j=0; j<data->modelData.nVariablesReal; ++j)
      if(data->modelData.realVarsData[j].attribute.useStart)
        tmpStartResidual2[ix++] = data->modelData.realVarsData[j].attribute.start - data->localData[0]->realVars[j];
    /* for real parameters */
    for(j=0; j<data->modelData.nParametersReal; ++j)
      if(data->modelData.realParameterData[j].attribute.useStart && !data->modelData.realParameterData[j].attribute.fixed)
        tmpStartResidual2[ix++] = data->modelData.realParameterData[j].attribute.start - data->localData[0]->realVars[j];
    /* for real discrete */
    for(j=data->modelData.nVariablesReal-data->modelData.nDiscreteReal; j<data->modelData.nDiscreteReal; ++j)
      if(data->modelData.realVarsData[j].attribute.useStart && !data->modelData.realVarsData[j].attribute.fixed)
        tmpStartResidual2[ix++] = data->modelData.realVarsData[j].attribute.start - data->localData[0]->realVars[j];

    for(j=0; j<initData->nInitResiduals; ++j)
    {
      double f = fabs(initData->nominal[i] * (tmpResidual2[j] - tmpResidual1[j]) / h);
      if(f > residualScalingCoefficients[j])
        residualScalingCoefficients[j] = f;
    }

    for(j=0; j<initData->nStartValueResiduals; ++j)
    {
      double f = fabs(initData->nominal[i] * (tmpStartResidual2[j] - tmpStartResidual1[j]) / h);
      if(f > startValueResidualScalingCoefficients[j])
        startValueResidualScalingCoefficients[j] = f;
    }
    initData->vars[i] -= h;
  }

  for(i=0; i<initData->nInitResiduals; ++i)
  {
    if(residualScalingCoefficients[i] < 1e-42)
    {
      initData->residualScalingCoefficients[i] = 1.0;
      INFO1(LOG_INIT, "| | [%ld] residual is ineffective (scaling coefficient is set to 1.0)", i+1);
    }
    else
      initData->residualScalingCoefficients[i] = residualScalingCoefficients[i];
  }

  for(i=0; i<initData->nStartValueResiduals; ++i)
  {
    if(startValueResidualScalingCoefficients[i] < 1e-42)
    {
      initData->startValueResidualScalingCoefficients[i] = 1.0;
      /* TODO invent new log-system
       * INFO1(LOG_INIT, "| | [%ld] start-value residual is ineffective (scaling coefficient is set to 1.0)", i+1);
       */
    }
    else
      initData->startValueResidualScalingCoefficients[i] = startValueResidualScalingCoefficients[i];
  }

  free(tmpResidual1);
  free(tmpResidual2);
  free(tmpStartResidual1);
  free(tmpStartResidual2);
  free(residualScalingCoefficients);
  free(startValueResidualScalingCoefficients);

  /* TODO invent new log-system
   * INFO(LOG_INIT, "scaling coefficients:");
   * INFO(LOG_INIT, "| initial residuals");
   * for(i=0; i<initData->nInitResiduals; ++i)
   *   INFO2(LOG_INIT, "| | [%ld] %g", i+1, initData->residualScalingCoefficients[i]);
   *
   * INFO(LOG_INIT, "| start value residuals");
   * for(i=0; i<initData->nStartValueResiduals; ++i)
   *   INFO2(LOG_INIT, "| | [%ld] %g", i+1, initData->startValueResidualScalingCoefficients[i]);
   */
}

/*! \fn setZ
 *
 *  This function copies the given vars vector into the init-data struct.
 *
 *  \param [ref] [initData]
 *  \param [in]  [vars]
 *
 *  \author lochel
 */
void setZ(INIT_DATA *data, double *vars)
{
  long i;

  for(i=0; i<data->nVars; ++i)
    data->vars[i] = vars[i];
}

/*! \fn setZScaled
 *
 *  This function copies the given scaledVars vector into the init-data struct.
 *
 *  \param [ref] [initData]
 *  \param [in]  [scaledVars]
 *
 *  \author lochel
 */
void setZScaled(INIT_DATA *data,  double *scaledVars)
{
  long i;

  for(i=0; i<data->nVars; ++i)
    data->vars[i] = data->nominal ? scaledVars[i] * data->nominal[i] : scaledVars[i];
}

/*! \fn updateSimData
 *
 *  This function copies the vars vector into the simulation data struct.
 *
 *  \param [ref] [initData]
 *
 *  \author lochel
 */
void updateSimData(INIT_DATA *initData)
{
  long i, j;

  /* for states */
  for(i=0, j=0; i<initData->simData->modelData.nStates; ++i)
    if(initData->simData->modelData.realVarsData[i].attribute.fixed==0)
      initData->simData->localData[0]->realVars[i] = initData->vars[j++];

  /* for real parameters */
  for(i=0; i<initData->simData->modelData.nParametersReal; ++i)
    if(initData->simData->modelData.realParameterData[i].attribute.fixed == 0)
      initData->simData->simulationInfo.realParameter[i] = initData->vars[j++];
    
  /* for real discrete */
  for(i=initData->simData->modelData.nVariablesReal-initData->simData->modelData.nDiscreteReal; i<initData->simData->modelData.nVariablesReal; ++i)
    if(initData->simData->modelData.realVarsData[i].attribute.fixed == 0)
      /* initData->simData->localData[0]->realVars[i] = initData->vars[j++]; */
      initData->simData->simulationInfo.realVarsPre[i] = initData->vars[j++];
}


