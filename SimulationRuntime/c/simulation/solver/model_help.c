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


#include <stdlib.h>
#include <string.h>
#include <float.h>

#include "simulation_data.h"
#include "model_help.h"
#include "openmodelica_func.h"
#include "omc_error.h"
#include "delay.h"
#include "varinfo.h"

static const int IterationMax = 200;
const size_t SIZERINGBUFFER = 3;

/*! \fn updateDiscreteSystem
 *
 *  Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 *
 *  \param [ref] [data]
 */
void updateDiscreteSystem(DATA *data)
{

  int IterationNum = 0;
  int discreteChanged = 0;
  modelica_boolean relationChanged = 0;
  data->simulationInfo.needToIterate = 0;

  if (DEBUG_STREAM(LOG_EVENTS))
    printRelations(data);

  functionDAE(data);
  INFO(LOG_EVENTS, "updated discrete System.");

  if(DEBUG_STREAM(LOG_EVENTS))
    printRelations(data);

  relationChanged = checkRelations(data);
  discreteChanged = checkForDiscreteChanges(data);
  while(discreteChanged || data->simulationInfo.needToIterate || relationChanged)
  {
    if (data->simulationInfo.needToIterate)
      INFO(LOG_EVENTS, "| reinit() call. Iteration needed!");
    if (relationChanged)
      INFO(LOG_EVENTS,"| relations changed. Iteration needed.");
    if (discreteChanged)
      INFO(LOG_EVENTS, "| discrete Variable changed. Iteration needed.");

    storePreValues(data);
    storeRelations(data);
    if (DEBUG_STREAM(LOG_EVENTS))
      printRelations(data);

    functionDAE(data);

    IterationNum++;
    if(IterationNum > IterationMax)
      THROW("ERROR: Too many event iterations. System is inconsistent. Simulation terminate.");

    relationChanged = checkRelations(data);
    discreteChanged = checkForDiscreteChanges(data);
  }
}



/*! \fn updateContinuousSystem
 *
 *  Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 *
 *  \param [ref] [data]
 */
void updateContinuousSystem(DATA *data)
{
  functionODE(data);
  functionAlgebraics(data);
  output_function(data);
  function_storeDelayed(data);
  storePreValues(data);
}

/*! \fn saveZeroCrossings
 *
 * Function saves all ZeroCrossing Values
 *
 *  \param [ref] [data]
 */
void saveZeroCrossings(DATA* data)
{
  long i = 0;

  INFO(LOG_ZEROCROSSINGS, "save all zerocrossings");

  for(i=0;i<data->modelData.nZeroCrossings;i++)
    data->simulationInfo.zeroCrossingsPre[i] = data->simulationInfo.zeroCrossings[i];

  function_ZeroCrossings(data, data->simulationInfo.zeroCrossings, &(data->localData[0]->timeValue));
}

/*! \fn copyStartValuestoInitValues
 *
 *  Function to copy all start values to initial values
 *
 *  \param [ref] [data]
 */
void copyStartValuestoInitValues(DATA *data)
{
  /* just copy all start values to initial */
  setAllParamsToStart(data);
  setAllVarsToStart(data);
  storePreValues(data);
  overwriteOldSimulationData(data);
}

/*! \fn printAllVars
 *
 *  prints all variable values
 *
 *  \param [in]  [data]
 *  \param [in]  [ringSegment]
 *
 *  \author wbraun
 */
void printAllVars(DATA *data, int ringSegment)
{
  long i;
  MODEL_DATA *mData = &(data->modelData);

  INFO2(LOG_STDOUT, "Print values for buffer segment %d regarding point in time : %e", ringSegment, data->localData[ringSegment]->timeValue);
  INDENT(LOG_STDOUT);

  INFO(LOG_STDOUT, "states variables");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nStates; ++i)
  {
    INFO3(LOG_STDOUT, "%ld: %s = %.10e", i, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i]);
  }
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "derivatives variables");
  INDENT(LOG_STDOUT);
  for(i=mData->nStates; i<2*mData->nStates; ++i)
  {
    INFO3(LOG_STDOUT, "%ld: %s = %.10e", i, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i]);
  }
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "other real values");
  INDENT(LOG_STDOUT);
  for(i=2*mData->nStates; i<mData->nVariablesReal; ++i){
    INFO3(LOG_STDOUT, "%ld: %s = %.10e", i, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i]);
  }
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "integer variables");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nVariablesInteger; ++i){
    INFO3(LOG_STDOUT, "%ld: %s = %ld", i, mData->integerVarsData[i].info.name, data->localData[ringSegment]->integerVars[i]);
  }
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "boolean variables");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nVariablesBoolean; ++i){
    INFO3(LOG_STDOUT, "%ld: %s = %s", i, mData->booleanVarsData[i].info.name, data->localData[ringSegment]->booleanVars[i] ? "true" : "false");
  }
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "string variables");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nVariablesString; ++i)
  {
    INFO3(LOG_STDOUT, "%ld: %s = %s", i, mData->stringVarsData[i].info.name, data->localData[ringSegment]->stringVars[i]);
  }
  RELEASE(LOG_STDOUT);
}


/*! \fn printParameters
 *
 *  prints all parameter values
 *
 *  \param [in]  [data]
 *  \param [in]  [ringSegment]
 *
 *  \author wbraun
 */
void printParameters(DATA *data)
{
  long i;
  MODEL_DATA *mData = &(data->modelData);

  INFO(LOG_STDOUT, "Print parameter values");
  INDENT(LOG_STDOUT);

  INFO(LOG_STDOUT, "real parameters");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nParametersReal; ++i)
    INFO3(LOG_STDOUT, "%ld: %s = %g", i+1, mData->realParameterData[i].info.name, data->simulationInfo.realParameter[i]);
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "integer parameters");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nParametersInteger; ++i)
    INFO3(LOG_STDOUT, " | | %ld: %s = %ld", i+1, mData->integerParameterData[i].info.name, data->simulationInfo.integerParameter[i]);
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "boolean parameters");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nParametersBoolean; ++i)
    INFO3(LOG_STDOUT, "%ld: %s = %s", i+1, mData->booleanParameterData[i].info.name, data->simulationInfo.booleanParameter[i] ? "true" : "false");
  RELEASE(LOG_STDOUT);

  INFO(LOG_STDOUT, "string parameters");
  INDENT(LOG_STDOUT);
  for(i=0; i<mData->nParametersString; ++i)
    INFO3(LOG_STDOUT, "%ld: %s = %s", i+1, mData->stringParameterData[i].info.name, data->simulationInfo.stringParameter[i]);
  RELEASE(LOG_STDOUT);
}

/*! \fn printAllHelpVars
 *
 *  print all helpVars and corresponding pre values
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void printAllHelpVars(DATA *data)
{
  long i;

  INFO(LOG_STDOUT, "Status of help vars:");
  INDENT(LOG_STDOUT);
  for(i=0; i<data->modelData.nHelpVars; i++)
  {
    INFO3(LOG_STDOUT, "[%ld] helpVars = %c | helpVarsPre = %c", i, data->simulationInfo.helpVars[i] ? 'T' : 'F', data->simulationInfo.helpVarsPre[i] ? 'T' : 'F');
  }
  RELEASE(LOG_STDOUT);
}


/*! \fn printRelations
 *
 *  print all relations
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void printRelations(DATA *data)
{
  long i;

  INFO(LOG_STDOUT, "Status of relations:");
  INDENT(LOG_STDOUT);
  for(i=0; i<data->modelData.nRelations; i++)
  {
    INFO5(LOG_STDOUT, "[%ld] %s = %c | pre(%s) = %c", i, relationDescription[i], data->simulationInfo.backupRelations[i] ? 'T' : 'F', relationDescription[i], data->simulationInfo.backupRelationsPre[i] ? 'T' : 'F');
  }
  RELEASE(LOG_STDOUT);
}

/*! \fn overwriteOldSimulationData
 *
 *  Stores variables (states, derivatives and algebraic) to be used
 *  by e.g. numerical solvers to extrapolate values as start values.
 *
 *  This function overwrites all old value with the current.
 *  This function is called after events.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void overwriteOldSimulationData(DATA *data)
{
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i)
  {
    data->localData[i]->timeValue = data->localData[i-1]->timeValue;
    memcpy(data->localData[i]->realVars, data->localData[i-1]->realVars, sizeof(modelica_real)*data->modelData.nVariablesReal);
    memcpy(data->localData[i]->integerVars, data->localData[i-1]->integerVars, sizeof(modelica_integer)*data->modelData.nVariablesInteger);
    memcpy(data->localData[i]->booleanVars, data->localData[i-1]->booleanVars, sizeof(modelica_boolean)*data->modelData.nVariablesBoolean);
    memcpy(data->localData[i]->stringVars, data->localData[i-1]->stringVars, sizeof(modelica_string)*data->modelData.nVariablesString);
  }
}

/* \fn restoreExtrapolationDataOld
 *
 *  Restores variables (states, derivatives and algebraic).
 *
 *  This function overwrites all variable with old values.
 *  This function is called while the initialization to be ab lvalue required as left operand of assignmentle
 *  initialize all ZeroCrossing relations.
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void restoreExtrapolationDataOld(DATA *data)
{
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i)
  {
    data->localData[i-1]->timeValue = data->localData[i]->timeValue;
    memcpy(data->localData[i-1]->realVars, data->localData[i]->realVars, sizeof(modelica_real)*data->modelData.nVariablesReal);
    memcpy(data->localData[i-1]->integerVars, data->localData[i]->integerVars, sizeof(modelica_integer)*data->modelData.nVariablesInteger);
    memcpy(data->localData[i-1]->booleanVars, data->localData[i]->booleanVars, sizeof(modelica_boolean)*data->modelData.nVariablesBoolean);
    memcpy(data->localData[i-1]->stringVars, data->localData[i]->stringVars, sizeof(modelica_string)*data->modelData.nVariablesString);
  }
}

/*! \fn setAllVarsToStart
 *
 *  This function sets all variables to their start-attribute.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void setAllVarsToStart(DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  long i;

  for(i=0; i<mData->nVariablesReal; ++i)
  {
    sData->realVars[i] = mData->realVarsData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Real var %s = %g", mData->realVarsData[i].info.name, sData->realVars[i]);
  }
  for(i=0; i<mData->nVariablesInteger; ++i)
  {
    sData->integerVars[i] = mData->integerVarsData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Integer var %s = %ld", mData->integerVarsData[i].info.name, sData->integerVars[i]);
  }
  for(i=0; i<mData->nVariablesBoolean; ++i)
  {
    sData->booleanVars[i] = mData->booleanVarsData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Boolean var %s = %s", mData->booleanVarsData[i].info.name, sData->booleanVars[i] ? "true" : "false");
  }
  for(i=0; i<mData->nVariablesString; ++i)
  {
    sData->stringVars[i] = mData->stringVarsData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set String var %s = %s", mData->stringVarsData[i].info.name, sData->stringVars[i]);
  }
}

/*! \fn setAllParamsToStart
 *
 *  This function sets all parameters and their initial values to their start-attribute.
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void setAllParamsToStart(DATA *data)
{
  SIMULATION_INFO *sInfo = &(data->simulationInfo);
  MODEL_DATA      *mData = &(data->modelData);
  long i;

  for(i=0; i<mData->nParametersReal; ++i)
  {
    sInfo->realParameter[i] = mData->realParameterData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Real var %s = %g", mData->realParameterData[i].info.name, sInfo->realParameter[i]);
  }
  for(i=0; i<mData->nParametersInteger; ++i)
  {
    sInfo->integerParameter[i] = mData->integerParameterData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Integer var %s = %ld", mData->integerParameterData[i].info.name, sInfo->integerParameter[i]);
  }
  for(i=0; i<mData->nParametersBoolean; ++i)
  {
    sInfo->booleanParameter[i] = mData->booleanParameterData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set Boolean var %s = %s", mData->booleanParameterData[i].info.name, sInfo->booleanParameter[i] ? "true" : "false");
  }
  for(i=0; i<mData->nParametersString; ++i)
  {
    sInfo->stringParameter[i] = mData->stringParameterData[i].attribute.start;
    INFO2(LOG_DEBUG, "Set String var %s = %s", mData->stringParameterData[i].info.name, sInfo->stringParameter[i]);
  }
}

/*! \fn storeOldValues
 *
 *  This function copys states and time into their old-values for event handling.
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void storeOldValues(DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  sInfo->timeValueOld = sData->timeValue;
  memcpy(sInfo->realVarsOld, sData->realVars, sizeof(modelica_real)*mData->nStates);
}

/*! \fn storePreValues
 *
 *  This function copys all the values into their pre-values.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void storePreValues(DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  memcpy(sInfo->realVarsPre, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sInfo->integerVarsPre, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sInfo->booleanVarsPre, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
  memcpy(sInfo->stringVarsPre, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
  memcpy(sInfo->helpVarsPre, sInfo->helpVars, sizeof(modelica_boolean)*mData->nHelpVars);
}

/*! \fn storeRelations
 *
 *  This function copys all the relations results  into their pre-values.
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void storeRelations(DATA *data){

  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  memcpy(sInfo->backupRelationsPre, sInfo->backupRelations, sizeof(modelica_boolean)*mData->nRelations);
}

/*! \fn checkRelations
 *
 *  This function check if at least one backupRelation has changed
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
modelica_boolean checkRelations(DATA *data){

  int i;
  modelica_boolean check=0;

  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  for(i=0;i<mData->nRelations;++i){
    if (sInfo->backupRelationsPre[i] != sInfo->backupRelations[i]){
      check = 1;
      break;
    }
  }

  return check;
}

/*! \fn resetAllHelpVars
 *
 *  workaround function to reset all helpvar that are used for when-equations.
 *  Need be done before initialization, to ensure the continuous integration.
 *
 *  \param [out] [data]
 *
 *  \author wbraun
 */
void resetAllHelpVars(DATA *data)
{
  int i;
  for(i=0; i<data->modelData.nHelpVars; i++)
  {
    data->simulationInfo.helpVars[i] = 0;
  }
}

/*! \fn getNextSampleTimeFMU
 *
 *  function return next sample time.
 *
 *  \param [in]  [data]
 *
 *  \author wbraun
 */
double getNextSampleTimeFMU(DATA *data)
{
  if (data->simulationInfo.curSampleTimeIx < data->simulationInfo.nSampleTimes)
  {
    return((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).events);
  }
  else
  {
    return -1;
  }
}

/*! \fn initializeDataStruc
 *
 *  function initialize DATA structure
 *
 *  \param [ref]  [data]
 *
 */
void initializeDataStruc(DATA *data)
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

  /* prepare RingBuffer */
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

  data->modelData.realAlias = (DATA_REAL_ALIAS*) calloc(data->modelData.nAliasReal, sizeof(DATA_REAL_ALIAS));
  data->modelData.integerAlias = (DATA_INTEGER_ALIAS*) calloc(data->modelData.nAliasInteger, sizeof(DATA_INTEGER_ALIAS));
  data->modelData.booleanAlias = (DATA_BOOLEAN_ALIAS*) calloc(data->modelData.nAliasBoolean, sizeof(DATA_BOOLEAN_ALIAS));
  data->modelData.stringAlias = (DATA_STRING_ALIAS*) calloc(data->modelData.nAliasString, sizeof(DATA_STRING_ALIAS));

  /* initialized in events.c initSample */
  data->simulationInfo.sampleTimes = 0;
  data->simulationInfo.rawSampleExps = (SAMPLE_RAW_TIME*) calloc(data->modelData.nSamples, sizeof(SAMPLE_RAW_TIME));

  data->simulationInfo.zeroCrossings = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.zeroCrossingsPre = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.backupRelations = (modelica_boolean*) calloc(data->modelData.nRelations, sizeof(modelica_boolean));
  data->simulationInfo.backupRelationsPre = (modelica_boolean*) calloc(data->modelData.nRelations, sizeof(modelica_boolean));
  data->simulationInfo.zeroCrossingEnabled = (modelica_boolean*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_boolean));
  data->simulationInfo.zeroCrossingIndex = (long*) malloc(data->modelData.nZeroCrossings*sizeof(long));
  /* initialize zeroCrossingsIndex with corresponding index is used by events lists */
  for(i=0; i<data->modelData.nZeroCrossings; i++)
    data->simulationInfo.zeroCrossingIndex[i] = (long)i;

  data->simulationInfo.helpVars = (modelica_boolean*) calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));
  data->simulationInfo.helpVarsPre = (modelica_boolean*) calloc(data->modelData.nHelpVars, sizeof(modelica_boolean));

  /* buffer for old state variables */
  data->simulationInfo.realVarsOld = (modelica_real*)calloc(data->modelData.nStates, sizeof(modelica_real));

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
  /* buffer for inputs and outputs values */
  data->simulationInfo.inputVars = (modelica_real*) calloc(data->modelData.nInputVars, sizeof(modelica_real));
  data->simulationInfo.outputVars = (modelica_real*) calloc(data->modelData.nOutputVars, sizeof(modelica_real));

  /* buffer for non-linear systems */
  data->simulationInfo.nonlinearSystemData = (NONLINEAR_SYSTEM_DATA*) malloc(data->modelData.nNonLinearSystems*sizeof(NONLINEAR_SYSTEM_DATA));
  initialNonLinearSystem(data->simulationInfo.nonlinearSystemData);

  /* buffer for analytical jacobains */
  data->simulationInfo.analyticJacobians = (ANALYTIC_JACOBIAN*) malloc(data->modelData.nJacobians*sizeof(ANALYTIC_JACOBIAN));

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
  data->simulationInfo.sampleActivated = 0;

  /*  switches used to evaluate the system */
  data->simulationInfo.solveContinuous = 0;
  data->simulationInfo.noThrowDivZero = 0;
  data->simulationInfo.discreteCall = 0;

  /* initialize model error code */
  data->simulationInfo.simulationSuccess = 0;

  /* initial delay */
  data->simulationInfo.delayStructure = (RINGBUFFER**)malloc(data->modelData.nDelayExpressions * sizeof(RINGBUFFER*));
  ASSERT(data->simulationInfo.delayStructure, "out of memory");

  for(i=0; i<data->modelData.nDelayExpressions; i++)
    data->simulationInfo.delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));

}

/*! \fn deInitializeDataStruc
 *
 *  function de-initialize DATA structure
 *
 *  \param [ref]  [data]
 *
 */
void deInitializeDataStruc(DATA *data)
{
  size_t i = 0;

  /* prepair RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++){
    SIMULATION_DATA* tmpSimData = (SIMULATION_DATA*) data->localData[i];
    /* free buffer for all variable values */
    free(tmpSimData->realVars);
    free(tmpSimData->integerVars);
    free(tmpSimData->booleanVars);
    free(tmpSimData->stringVars);
  }
  free(data->localData);
  freeRingBuffer(data->simulationData);

  /* free modelData var arrays */
  for(i=0; i < data->modelData.nVariablesReal;i++)
    freeVarInfo(&((data->modelData.realVarsData[i]).info));
  free(data->modelData.realVarsData);

  for(i=0; i < data->modelData.nVariablesInteger;i++)
    freeVarInfo(&((data->modelData.integerVarsData[i]).info));
  free(data->modelData.integerVarsData);

  for(i=0; i < data->modelData.nVariablesBoolean;i++)
    freeVarInfo(&((data->modelData.booleanVarsData[i]).info));
  free(data->modelData.booleanVarsData);

  for(i=0; i < data->modelData.nVariablesString;i++)
    freeVarInfo(&((data->modelData.stringVarsData[i]).info));
  free(data->modelData.stringVarsData);

  /* free modelica parameter static data */
  for(i=0; i < data->modelData.nParametersReal;i++)
    freeVarInfo(&((data->modelData.realParameterData[i]).info));
  free(data->modelData.realParameterData);

  for(i=0; i < data->modelData.nParametersInteger;i++)
    freeVarInfo(&((data->modelData.integerParameterData[i]).info));
  free(data->modelData.integerParameterData);

  for(i=0; i < data->modelData.nParametersBoolean;i++)
    freeVarInfo(&((data->modelData.booleanParameterData[i]).info));
  free(data->modelData.booleanParameterData);

  for(i=0; i < data->modelData.nParametersString;i++)
    freeVarInfo(&((data->modelData.stringParameterData[i]).info));
  free(data->modelData.stringParameterData);

  /* free alias static data */
  for(i=0; i < data->modelData.nAliasReal;i++)
    freeVarInfo(&((data->modelData.realAlias[i]).info));
  free(data->modelData.realAlias);
  for(i=0; i < data->modelData.nAliasInteger;i++)
    freeVarInfo(&((data->modelData.integerAlias[i]).info));
  free(data->modelData.integerAlias);
  for(i=0; i < data->modelData.nAliasBoolean;i++)
    freeVarInfo(&((data->modelData.booleanAlias[i]).info));
  free(data->modelData.booleanAlias);
  for(i=0; i < data->modelData.nAliasString;i++)
    freeVarInfo(&((data->modelData.stringAlias[i]).info));
  free(data->modelData.stringAlias);

  /* free simulationInfo arrays */
  free(data->simulationInfo.sampleTimes);
  free(data->simulationInfo.rawSampleExps);

  free(data->simulationInfo.helpVars);
  free(data->simulationInfo.helpVarsPre);
  free(data->simulationInfo.zeroCrossings);
  free(data->simulationInfo.zeroCrossingsPre);
  free(data->simulationInfo.backupRelations);
  free(data->simulationInfo.zeroCrossingEnabled);
  free(data->simulationInfo.zeroCrossingIndex);

  /* free buffer for old state variables */
  free(data->simulationInfo.realVarsOld);

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
  free(data->simulationInfo.nonlinearSystemData);

  /* free buffer jacobians */
  free(data->simulationInfo.analyticJacobians);

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

  free(data->modelData.equationInfo_reverse_prof_index);

  /* free delay structure */
  for(i=0; i<data->modelData.nDelayExpressions; i++)
    freeRingBuffer(data->simulationInfo.delayStructure[i]);

  free(data->simulationInfo.delayStructure);

  pop_memory_states(NULL);
}

/* relation functions used in zero crossing detection
 * Less is for case LESS and GREATEREQ
 * Greater is for case LESSEQ and GREATER
 */
static const double tolZC = 1e-10;

modelica_boolean LessZC(double a, double b, modelica_boolean direction)
{
  modelica_boolean retVal;
  double eps = (direction) ? tolZC*fabs(b)+tolZC: tolZC*fabs(a)+tolZC;
  INFO4(LOG_EVENTS, "Relation LESS:  %.20e < %.20e = %c (%c)",a, b, (a < b)?'t':'f' , direction?'t':'f');
  retVal = (direction)? (a < b + eps):(a + eps < b);
  INFO1(LOG_EVENTS, "Result := %c", retVal?'t':'f');
  return retVal;
}

modelica_boolean LessEqZC(double a, double b, modelica_boolean direction)
{
  return (!GreaterZC(a, b, !direction));
}

modelica_boolean GreaterZC(double a, double b, modelica_boolean direction)
{
  modelica_boolean retVal;
  double eps = (direction) ? tolZC*fabs(a)+tolZC: tolZC*fabs(b)+tolZC;
  INFO4(LOG_EVENTS, "Relation GREATER:  %.20e > %.20e = %c (%c)",a, b, (a > b)?'t':'f' , direction?'t':'f');
  retVal = (direction)? (a + eps > b ):(a  > b + eps);
  INFO1(LOG_EVENTS, "Result := %c", retVal?'t':'f');
  return retVal;
}

modelica_boolean GreaterEqZC(double a, double b, modelica_boolean direction)
{
  return (!LessZC(a, b, !direction));
}

modelica_boolean Less(double a, double b)
{
  return a < b;
}

modelica_boolean LessEq(double a, double b)
{
  return a <= b;
}

modelica_boolean Greater(double a, double b)
{
  return a > b;
}

modelica_boolean GreaterEq(double a, double b)
{
  return a >= b;
}

/*! \fn deInitializeDataStruc
 *
 *  function is used in generated code for mixed equation systems
 *  to generate next combination of boolean variables.
 *  Example: for n = 3
 *           generates sequence: 000, 100, 010, 001, 110, 101, 011, 111
 *
 *  \param [ref]  [data]
 *
 * \author Jan Silar
 *
 * \brief
 */
modelica_boolean nextVar(modelica_boolean *b, int n) {
  /*number of "1" */
  int n1 = 0;
  int i;
  int last;
  for (i = 0; i < n; i++){
    if (b[i] == 1)
      n1++;
  }
  /*index of last element with "1"*/
  last = n - 1;
  while (last >= 0 && !b[last])
    last--;
  if (n1 == n) /*exit - all combination were already generated*/
    return 0;
  else if (last == -1) { /* 0000 -> 1000 */
    b[0] = 1;
    return 1;
  } else if (last < n - 1) { /* e.g. 1010 -> 1001 */
    b[last] = 0;
    b[last + 1] = 1;
    return 1;
  } else { /*at the end of the array is "1"*/
    /*detect position of last ocurenc of sequence 10 */
    int ip = n - 2; /*actual position in array*/
    int nr1 = 1; /*count of "1"*/
    while (ip >= 0) {
      if (b[ip] && !b[ip + 1]) { /*we found*/
        nr1++;
        break;
      } else if (b[ip]) { /*we didn't find, but 1 - increase nr1*/
        nr1++;
        ip--;
      } else { /*we didnt't find, 0*/
        ip--;
      }
    }
    if (ip >= 0) { /*e.g. 1001 -> 0110*/
      int pn = ip + nr1;
      b[ip] = 0;
      for (i = ip + 1; i <= pn; i++)
        b[i] = 1;
      for (i = pn + 1; i <= n - 1; i++)
        b[i] = 0;
      return 1;
    } else {
      for (i = 0; i <= n1; i++)
        b[i] = 1;
      for (i = n1 + 1; i <= n - 1; i++)
        b[i] = 0;
      return 1;
    }
  }
}


