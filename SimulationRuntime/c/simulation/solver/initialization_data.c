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

/*! \fn initializeInitData
 *
 *  \param [in]  [data]
 *
 *  \author lochel
 */
INIT_DATA *initializeInitData(DATA *data)
{
  long i, j;
  long iz;
  INIT_DATA* initData = NULL;

  initData = (INIT_DATA*)malloc(sizeof(INIT_DATA));
  ASSERT(initData, "out of memory");

  initData->nz = 0;
  initData->nStates = 0;
  initData->nParameters = 0;
  initData->z = NULL;
  initData->zScaled = NULL;
  initData->start = NULL;
  initData->min = NULL;
  initData->max = NULL;
  initData->nominal = NULL;
  initData->name = NULL;

  initData->nInitResiduals = 0;
  initData->nStartValueResiduals = 0;
  initData->residualScalingCoefficients = NULL;
  initData->startValueResidualScalingCoefficients = NULL;

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
    return NULL;

  initData->z = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->z, "out of memory");

  initData->zScaled = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->zScaled, "out of memory");

  initData->start = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->start, "out of memory");

  initData->min = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->min, "out of memory");

  initData->max = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->max, "out of memory");

  initData->nominal = (double*)calloc(initData->nz, sizeof(double));
  ASSERT(initData->nominal, "out of memory");

  initData->name = (char**)calloc(initData->nz, sizeof(char*));
  ASSERT(initData->name, "out of memory");

  /* setup initData */
  DEBUG_INFO(LOG_INIT, "initial problem:");
  DEBUG_INFO_AL3(LOG_INIT, "| number of unfixed variables:  %ld (%ld states + %ld parameters)", initData->nz, initData->nStates, initData->nParameters);
  for(i=0, iz=0; i<data->modelData.nStates; ++i)
  {
    if(data->modelData.realVarsData[i].attribute.fixed == 0)
    {
      initData->name[iz] = (char*)data->modelData.realVarsData[i].info.name;
      initData->nominal[iz] = data->modelData.realVarsData[i].attribute.useNominal ? fabs(data->modelData.realVarsData[i].attribute.nominal) : 1.0;
      if(initData->nominal[iz] == 0.0)
      {
        /* adrpo 2012-05-08 disable the warning for now until the whole infrastructure is in place
         *                  because this breaks the FMI tests with these kind of messages:
         *                  warning | (null)(nominal=0)
         *                          | nominal value is set to 1.0
         * put it back when everything works fine.
        WARNING2("%s(nominal=%g)", initData->name[iz], initData->nominal[iz]);
        WARNING_AL("nominal value is set to 1.0");
        */
        initData->nominal[iz] = 1.0;
      }

      initData->z[iz] = data->modelData.realVarsData[i].attribute.start;
      initData->start[iz] = data->modelData.realVarsData[i].attribute.start;
      initData->min[iz] = data->modelData.realVarsData[i].attribute.min;
      initData->max[iz] = data->modelData.realVarsData[i].attribute.max;

      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] Real %s(start=%g, nominal=%g)", iz+1, initData->name[iz], initData->start[iz], initData->nominal[iz]);
      iz++;
    }
  }

  for(i=0; i<data->modelData.nParametersReal; ++i)
  {
    if(data->modelData.realParameterData[i].attribute.fixed == 0)
    {
      initData->name[iz] = (char*)data->modelData.realParameterData[i].info.name;
      initData->nominal[iz] = fabs(data->modelData.realParameterData[i].attribute.nominal);
      if(initData->nominal[iz] == 0.0)
      {
        /* adrpo 2012-05-08 disable the warning for now until the whole infrastructure is in place
         *                  because this breaks the FMI tests with these kind of messages:
         *                  warning | (null)(nominal=0)
         *                          | nominal value is set to 1.0
         * put it back when everything works fine.
        WARNING2("%s(nominal=%g)", initData->name[iz], initData->nominal[iz]);
        WARNING_AL("nominal value is set to 1.0");
        */
        initData->nominal[iz] = 1.0;
      }

      initData->z[iz] = data->modelData.realParameterData[i].attribute.start;
      initData->start[iz] = data->modelData.realParameterData[i].attribute.start;
      initData->min[iz] = data->modelData.realParameterData[i].attribute.min;
      initData->max[iz] = data->modelData.realParameterData[i].attribute.max;

      DEBUG_INFO_AL4(LOG_INIT, "| | [%ld] parameter Real %s(start=%g, nominal=%g)", iz+1, initData->name[iz], initData->start[iz], initData->nominal[iz]);
      iz++;
    }
  }

  updateZScaled(initData);

  /* equations */
  initData->nInitResiduals = data->modelData.nInitResiduals;
  initData->nStartValueResiduals = 0;

  /* for real variables */
  for(i=0; i<data->modelData.nVariablesReal; ++i)
    if(data->modelData.realVarsData[i].attribute.useStart)
      initData->nStartValueResiduals++;
  /* for real parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
    if(data->modelData.realParameterData[i].attribute.useStart && !data->modelData.realParameterData[i].attribute.fixed)
      initData->nStartValueResiduals++;

  DEBUG_INFO_AL3(LOG_INIT, "| number of initial residuals:  %ld (%ld equations + %ld algorithms)", initData->nInitResiduals, data->modelData.nInitEquations, data->modelData.nInitAlgorithms);
  DEBUG_INFO_AL1(LOG_INIT, "| number of start value residuals: %ld", initData->nStartValueResiduals);

  initData->initialResiduals = (double*)calloc(initData->nInitResiduals, sizeof(double));
  ASSERT(initData->initialResiduals, "out of memory");

  initData->residualScalingCoefficients = (double*)calloc(initData->nInitResiduals, sizeof(double));
  ASSERT(initData->residualScalingCoefficients, "out of memory");

  initData->startValueResidualScalingCoefficients = (double*)calloc(initData->nStartValueResiduals, sizeof(double));
  ASSERT(initData->startValueResidualScalingCoefficients, "out of memory");

  for(i=0; i<initData->nInitResiduals; ++i)
    initData->residualScalingCoefficients[i] = 1.0;
  for(i=0; i<initData->nStartValueResiduals; ++i)
    initData->startValueResidualScalingCoefficients[i] = 1.0;

  /* for real variables */
  j=0;
  for(i=0; i<data->modelData.nVariablesReal; ++i)
    if(data->modelData.realVarsData[i].attribute.useStart)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] Real %s(start=%g)", ++j, data->modelData.realVarsData[i].info.name, data->modelData.realVarsData[i].attribute.start);
  /* for real parameters */
  for(i=0; i<data->modelData.nParametersReal; ++i)
    if(data->modelData.realParameterData[i].attribute.useStart && !data->modelData.realParameterData[i].attribute.fixed)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] parameter Real %s(start=%g)", ++j, data->modelData.realParameterData[i].info.name, data->modelData.realParameterData[i].attribute.start);

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
  free(initData->z);
  free(initData->zScaled);
  free(initData->start);
  free(initData->min);
  free(initData->max);
  free(initData->nominal);
  free(initData->name);

  free(initData->initialResiduals);
  free(initData->residualScalingCoefficients);
  free(initData->startValueResidualScalingCoefficients);

  free(initData);
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
void computeInitialResidualScalingCoefficients(DATA *data, INIT_DATA *initData)
{
  long i, j, ix;

  double *tmpResidual1 = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *tmpResidual2 = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *tmpStartResidual1 = (double*)calloc(initData->nStartValueResiduals, sizeof(double));
  double *tmpStartResidual2 = (double*)calloc(initData->nStartValueResiduals, sizeof(double));
  double *residualScalingCoefficients = (double*)calloc(initData->nInitResiduals, sizeof(double));
  double *startValueResidualScalingCoefficients = (double*)calloc(initData->nStartValueResiduals, sizeof(double));

  const double h = 1e-6;

  for(i=0; i<initData->nInitResiduals; ++i)
    initData->residualScalingCoefficients[i] = 1.0;
  for(i=0; i<initData->nStartValueResiduals; ++i)
    initData->startValueResidualScalingCoefficients[i] = 1.0;

  /* lambda = 1.0 */
  leastSquareWithLambda(data, initData, NULL, 1.0);
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

  for(i=0; i<initData->nz; ++i)
  {
    initData->z[i] += h;
    updateZScaled(initData);

    leastSquareWithLambda(data, initData, NULL, 1.0);
    for(j=0; j<initData->nInitResiduals; ++j)
      tmpResidual2[j] = initData->initialResiduals[j];

    ix = 0;
    /* for real variables */
    for(j=0; j<data->modelData.nVariablesReal; ++j)
      if(data->modelData.realVarsData[j].attribute.useStart)
        tmpStartResidual2[ix++] = data->modelData.realVarsData[j].attribute.start - data->localData[0]->realVars[j];
    /* for real parameters */
    for(j=0; j<data->modelData.nParametersReal; ++j)
      if(data->modelData.realParameterData[j].attribute.useStart && !data->modelData.realParameterData[j].attribute.fixed)
        tmpStartResidual2[ix++] = data->modelData.realParameterData[j].attribute.start - data->localData[0]->realVars[j];

    for(j=0; j<initData->nInitResiduals; ++j)
    {
      double f = fabs(initData->nominal[i] * (tmpResidual2[j] - tmpResidual1[j]) / h /* / tmpResidual2[j] */ );
      if(f > residualScalingCoefficients[j])
        residualScalingCoefficients[j] = f;
    }

    for(j=0; j<initData->nStartValueResiduals; ++j)
    {
      double f = fabs(initData->nominal[i] * (tmpStartResidual2[j] - tmpStartResidual1[j]) / h /* / tmpResidual2[j] */ );
      if(f > startValueResidualScalingCoefficients[j])
        startValueResidualScalingCoefficients[j] = f;
    }
    initData->z[i] -= h;
    updateZScaled(initData);
  }

  for(i=0; i<initData->nInitResiduals; ++i)
  {
    if(residualScalingCoefficients[i] < 1e-42)
      initData->residualScalingCoefficients[i] = 0.0;
    else
      initData->residualScalingCoefficients[i] = residualScalingCoefficients[i];
  }

  for(i=0; i<initData->nStartValueResiduals; ++i)
  {
    if(residualScalingCoefficients[i] < 1e-42)
      initData->startValueResidualScalingCoefficients[i] = 0.0;
    else
      initData->startValueResidualScalingCoefficients[i] = startValueResidualScalingCoefficients[i];
  }

  free(tmpResidual1);
  free(tmpResidual2);
  free(tmpStartResidual1);
  free(tmpStartResidual2);
  free(residualScalingCoefficients);
  free(startValueResidualScalingCoefficients);

  /* dump */
  DEBUG_INFO(LOG_INIT, "scaling coefficients:");
  DEBUG_INFO_AL(LOG_INIT, "| initial residuals");
  for(i=0; i<initData->nInitResiduals; ++i)
    DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] %g %s", i+1, initData->residualScalingCoefficients[i], initData->residualScalingCoefficients[i] == 0.0 ? "[ineffective]" : "");

  DEBUG_INFO_AL(LOG_INIT, "| start value residuals");
    for(i=0; i<initData->nStartValueResiduals; ++i)
      DEBUG_INFO_AL3(LOG_INIT, "| | [%ld] %g %s", i+1, initData->startValueResidualScalingCoefficients[i], initData->startValueResidualScalingCoefficients[i] == 0.0 ? "[ineffective]" : "");
}

void updateZ(INIT_DATA *data)
{
  long i;

  if(data->nominal)
    for(i=0; i<data->nz; ++i)
      data->z[i] = data->zScaled[i] * data->nominal[i];
  else
    THROW("updateZ failed");
}

void updateZScaled(INIT_DATA *data)
{
  long i;

  if(data->nominal)
    for(i=0; i<data->nz; ++i)
      data->zScaled[i] = data->z[i] / data->nominal[i];
  else
    THROW("updateZScaled failed");
}

void setZ(INIT_DATA *data, double *z)
{
  long i;

  for(i=0; i<data->nz; ++i)
    data->z[i] = z[i];

  updateZScaled(data);
}

void setZScaled(INIT_DATA *data,  double *zScaled)
{
  long i;

  for(i=0; i<data->nz; ++i)
    data->zScaled[i] = zScaled[i];

  updateZ(data);
}

