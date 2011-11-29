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
    ASSERT(tmpSimData.realVars,"out of memory");
    tmpSimData.integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    ASSERT(tmpSimData.integerVars,"out of memory");
    tmpSimData.booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    ASSERT(tmpSimData.booleanVars,"out of memory");
    tmpSimData.stringVars = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
    ASSERT(tmpSimData.stringVars,"out of memory");
    appendRingData(data->simulationData,&tmpSimData);
  }
  data->localData = (SIMULATION_DATA**) calloc(SIZERINGBUFFER, sizeof(SIMULATION_DATA*));
  rotateRingBuffer(data->simulationData, 0, (void**) data->localData);

  /* create modelData var arrays */
  data->modelData.realVarsData = (STATIC_REAL_DATA*) calloc(data->modelData.nVariablesReal, sizeof(STATIC_REAL_DATA));
  data->modelData.integerVarsData = (STATIC_INTEGER_DATA*) calloc(data->modelData.nVariablesInteger, sizeof(STATIC_INTEGER_DATA));
  data->modelData.booleanVarsData = (STATIC_BOOLEAN_DATA*) calloc(data->modelData.nVariablesBoolean, sizeof(STATIC_BOOLEAN_DATA));
  data->modelData.stringVarsData = (STATIC_STRING_DATA*) calloc(data->modelData.nVariablesString, sizeof(STATIC_STRING_DATA));

  data->modelData.realParameterData = (STATIC_REAL_DATA*) calloc(data->modelData.nParametersReal, sizeof(STATIC_REAL_DATA));
  data->modelData.integerParameterData = (STATIC_INTEGER_DATA*) calloc(data->modelData.nParametersInteger, sizeof(STATIC_INTEGER_DATA));
  data->modelData.booleanParameterData = (STATIC_BOOLEAN_DATA*) calloc(data->modelData.nParametersBoolean, sizeof(STATIC_BOOLEAN_DATA));
  data->modelData.stringParameterData = (STATIC_STRING_DATA*) calloc(data->modelData.nParametersString, sizeof(STATIC_STRING_DATA));

  data->modelData.realAlias = (_X_DATA_REAL_ALIAS*) calloc(data->modelData.nAliasReal, sizeof(_X_DATA_REAL_ALIAS));
  data->modelData.integerAlias = (_X_DATA_INTEGER_ALIAS*) calloc(data->modelData.nAliasInteger, sizeof(_X_DATA_INTEGER_ALIAS));
  data->modelData.booleanAlias = (_X_DATA_BOOLEAN_ALIAS*) calloc(data->modelData.nAliasBoolean, sizeof(_X_DATA_BOOLEAN_ALIAS));
  data->modelData.stringAlias = (_X_DATA_STRING_ALIAS*) calloc(data->modelData.nAliasString, sizeof(_X_DATA_STRING_ALIAS));

  data->simulationInfo.rawSampleExps = (SAMPLE_RAW_TIME*) calloc(data->modelData.nSamples, sizeof(SAMPLE_RAW_TIME));

  data->simulationInfo.zeroCrossings = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.zeroCrossingsPre = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.backupRelations = (modelica_boolean*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_boolean));
  data->simulationInfo.zeroCrossingEnabled = (modelica_boolean*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_boolean));

  data->simulationInfo.helpVars = (modelica_boolean*) calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));
  data->simulationInfo.helpVarsPre = (modelica_boolean*) calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));

  /* buffer for all variable pre values */
  data->simulationInfo.realVarsPre = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
  data->simulationInfo.integerVarsPre = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
  data->simulationInfo.booleanVarsPre = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
  data->simulationInfo.stringVarsPre = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));

  /* buffer for all parameters values */
  data->simulationInfo.realParameter = (modelica_real*) calloc(data->modelData.nParametersReal, sizeof(modelica_real));
  data->simulationInfo.integerParameter = (modelica_integer*) calloc(data->modelData.nParametersInteger, sizeof(modelica_integer));
  data->simulationInfo.booleanParameter = (modelica_boolean*) calloc(data->modelData.nParametersBoolean, sizeof(modelica_boolean));
  data->simulationInfo.stringParameter = (modelica_string*) calloc(data->modelData.nParametersString, sizeof(modelica_string));

  data->simulationInfo.jacobianVars = (modelica_real*) calloc(data->modelData.nJacobianVars, sizeof(modelica_real));
  data->simulationInfo.inputVars = (modelica_real*) calloc(data->modelData.nInputVars, sizeof(modelica_real));
  data->simulationInfo.outputVars = (modelica_real*) calloc(data->modelData.nOutputVars, sizeof(modelica_real));

  /* buffer for equations and fucntions */
  data->modelData.functionNames = (FUNCTION_INFO*) malloc(data->modelData.nFunctions*sizeof(FUNCTION_INFO));
  data->modelData.equationInfo = (EQUATION_INFO*) malloc(data->modelData.nEquations*sizeof(EQUATION_INFO));

  /* buffer for external objects */
  data->simulationInfo.extObjs = NULL;
  data->simulationInfo.extObjs = (void**) calloc(data->modelData.nExtObjs, sizeof(void*));
  ASSERT(data->simulationInfo.extObjs,"error allocating external objects");

  /* initial build calls terminal, initial */
  data->simulationInfo.terminal = 0;
  data->simulationInfo.initial = 0;

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
  }
  free(data->localData);

  /* free modelData var arrays */
  free(data->modelData.realVarsData);
  free(data->modelData.integerVarsData);
  free(data->modelData.booleanVarsData);
  free(data->modelData.stringVarsData);

  free(data->modelData.realParameterData);
  free(data->modelData.integerParameterData);
  free(data->modelData.booleanParameterData);
  free(data->modelData.stringParameterData);

  free(data->modelData.realAlias);
  free(data->modelData.integerAlias);
  free(data->modelData.booleanAlias);
  free(data->modelData.stringAlias);

  /* free simulationInfo arrays */
  free(data->simulationInfo.rawSampleExps);
  free(data->simulationInfo.sampleTimes);

  free(data->simulationInfo.helpVars);
  free(data->simulationInfo.helpVarsPre);
  free(data->simulationInfo.zeroCrossings);
  free(data->simulationInfo.zeroCrossingsPre);
  free(data->simulationInfo.backupRelations);
  free(data->simulationInfo.zeroCrossingEnabled);

  /* free buffer for all variable pre values */
  free(data->simulationInfo.realVarsPre);
  free(data->simulationInfo.integerVarsPre);
  free(data->simulationInfo.booleanVarsPre);
  free(data->simulationInfo.stringVarsPre);

  /* free buffer for all parameters values */
  free(data->simulationInfo.realParameter);
  free(data->simulationInfo.integerParameter);
  free(data->simulationInfo.booleanParameter);
  free(data->simulationInfo.stringParameter);

  /* free buffer jacobians */
  free(data->simulationInfo.jacobianVars);

  /* free inputs and output */
  free(data->simulationInfo.inputVars);
  free(data->simulationInfo.outputVars);

  /* free external objects buffer */
  free(data->simulationInfo.extObjs);

  /* free functionNames */
  free(data->modelData.functionNames);
  /* free equationInfo */
  for(i=0;i<data->modelData.nEquations;++i)
    free(data->modelData.equationInfo[i].vars);
  free(data->modelData.equationInfo);


}

