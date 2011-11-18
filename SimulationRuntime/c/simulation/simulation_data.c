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

#include "simulation_data.h"
#include "error.h"

#include <stdlib.h>

const size_t SIZERINGBUFFER = 3;

void initializeXDataStruc(_X_DATA *data)
{
  SIMULATION_DATA tmpSimData;
  size_t i = 0;
  /* RingBuffer */
  data->simulationData = 0;
  data->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if (!data->simulationData)
  {
    THROW("Your memory is not strong enough for our Ringbuffer!");
  }

  /* prepair RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    /* set time value */
    tmpSimData.timeValue = 0;
    /* buffer for all variable values */
    tmpSimData.realVars = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    tmpSimData.integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    tmpSimData.booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    tmpSimData.stringVars = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
    tmpSimData.helpVars = (modelica_boolean*)calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));
    /* buffer for all variable pre values */
    tmpSimData.realVarsPre = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    tmpSimData.integerVarsPre = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    tmpSimData.booleanVarsPre = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    tmpSimData.stringVarsPre = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
    tmpSimData.helpVarsPre = (modelica_boolean*)calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));
    appendRingData(data->simulationData,&tmpSimData);
  }
  data->localData = (SIMULATION_DATA**) calloc(SIZERINGBUFFER, sizeof(SIMULATION_DATA*));
  rotateRingBuffer(data->simulationData, 0, (void**) data->localData);

  /* create modelData var arrays */
  data->modelData.realData = (STATIC_REAL_DATA*) calloc(data->modelData.nVariablesReal,sizeof(STATIC_REAL_DATA));
  data->modelData.integerData = (STATIC_INTEGER_DATA*) calloc(data->modelData.nVariablesInteger,sizeof(STATIC_INTEGER_DATA));
  data->modelData.booleanData = (STATIC_BOOLEAN_DATA*) calloc(data->modelData.nVariablesBoolean,sizeof(STATIC_BOOLEAN_DATA));
  data->modelData.stringData = (STATIC_STRING_DATA*) calloc(data->modelData.nVariablesString,sizeof(STATIC_STRING_DATA));

  data->modelData.realParameter = (STATIC_REAL_DATA*) calloc(data->modelData.nParametersReal,sizeof(STATIC_REAL_DATA));
  data->modelData.integerParameter = (STATIC_INTEGER_DATA*) calloc(data->modelData.nParametersInteger,sizeof(STATIC_INTEGER_DATA));
  data->modelData.booleanParameter = (STATIC_BOOLEAN_DATA*) calloc(data->modelData.nParametersBoolean,sizeof(STATIC_BOOLEAN_DATA));
  data->modelData.stringParameter = (STATIC_STRING_DATA*) calloc(data->modelData.nParametersString,sizeof(STATIC_STRING_DATA));

  data->modelData.realAlias = (_X_DATA_REAL_ALIAS*) calloc(data->modelData.nAliasReal,sizeof(_X_DATA_REAL_ALIAS));
  data->modelData.integerAlias = (_X_DATA_INTEGER_ALIAS*) calloc(data->modelData.nAliasInteger,sizeof(_X_DATA_INTEGER_ALIAS));
  data->modelData.booleanAlias = (_X_DATA_BOOLEAN_ALIAS*) calloc(data->modelData.nAliasBoolean,sizeof(_X_DATA_BOOLEAN_ALIAS));
  data->modelData.stringAlias = (_X_DATA_STRING_ALIAS*) calloc(data->modelData.nAliasString,sizeof(_X_DATA_STRING_ALIAS));

  data->simulationInfo.rawSampleExps = (sample_raw_time*) calloc(data->modelData.nSamples,sizeof(sample_raw_time));

  data->simulationInfo.zeroCrossings = (modelica_real*) calloc(data->modelData.nZeroCrossings,sizeof(modelica_real));
  data->simulationInfo.zeroCrossingsPre = (modelica_real*) calloc(data->modelData.nZeroCrossings,sizeof(modelica_real));
  data->simulationInfo.backupRelations = (modelica_boolean*) calloc(data->modelData.nZeroCrossings,sizeof(modelica_boolean));
  data->simulationInfo.zeroCrossingEnabled = (modelica_boolean*) calloc(data->modelData.nZeroCrossings,sizeof(modelica_boolean));

}

void DeinitializeXDataStruc(_X_DATA *data)
{
  size_t i = 0;

  /* prepair RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    SIMULATION_DATA* tmpSimData = (SIMULATION_DATA*) data->localData[i];
    /* free buffer for all variable values */
    free(tmpSimData->realVars);
    free(tmpSimData->integerVars);
    free(tmpSimData->booleanVars);
    free(tmpSimData->stringVars);
    free(tmpSimData->helpVars);
    /* free buffer for all variable pre values */
    free(tmpSimData->realVarsPre);
    free(tmpSimData->integerVarsPre);
    free(tmpSimData->booleanVarsPre);
    free(tmpSimData->stringVarsPre);
    free(tmpSimData->helpVarsPre);

  }

  /* create modelData var arrays */
  free(data->modelData.realData);
  free(data->modelData.integerData);
  free(data->modelData.booleanData);
  free(data->modelData.stringData);

  free(data->modelData.realParameter);
  free(data->modelData.integerParameter);
  free(data->modelData.booleanParameter);
  free(data->modelData.stringParameter);

  free(data->modelData.realAlias);
  free(data->modelData.integerAlias);
  free(data->modelData.booleanAlias);
  free(data->modelData.stringAlias);

  free(data->localData);

  free(data->simulationInfo.rawSampleExps);
  free(data->simulationInfo.sampleTimes);

}
