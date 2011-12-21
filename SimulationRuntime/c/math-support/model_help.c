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

#include "simulation_data.h"
#include "model_help.h"
#include "openmodelica_func.h"
#include "error.h"
#include "varinfo.h"
#include "delay.h"


/*  function: update_DAEsystem
 *
 *  ! Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 */
static const int IterationMax = 200;
void update_DAEsystem(_X_DATA *data)
{
  int needToIterate = 0;
  int IterationNum = 0;

  functionDAE(data, &needToIterate);
  functionAliasEquations(data);
  /*
  if (DEBUG_FLAG(LOG_EVENTS)) {
    sim_result_emit(data);
  }
  */
  while(checkForDiscreteChanges(data) || needToIterate)
  {
    if(needToIterate)
    {
      DEBUG_INFO(LOG_EVENTS, "reinit() call. Iteration needed!");
    }
    else
    {
      DEBUG_INFO(LOG_EVENTS, "discrete Variable changed. Iteration needed!");
    }
    storePreValues(data);
    functionDAE(data, &needToIterate);
    functionAliasEquations(data);
    /*
    if (DEBUG_FLAG(LOG_EVENTS)) {
      sim_result_emit(data);
    }
    */
    IterationNum++;
    if(IterationNum > IterationMax)
    {
      THROW("ERROR: Too many event iterations. System is inconsistent!");
    }
  }
}

/* function: SaveZeroCrossings
 *
 * ! Function saves all ZeroCrossing Values
 *
 */
void
SaveZeroCrossings(_X_DATA* simData)
{
  long i = 0;

  DEBUG_INFO(LOG_ZEROCROSSINGS, "Save ZeroCrossings!");

  for(i=0;i<simData->modelData.nZeroCrossings;i++){
      simData->simulationInfo.zeroCrossingsPre[i] = simData->simulationInfo.zeroCrossings[i];
  }
  function_onlyZeroCrossings(simData, simData->simulationInfo.zeroCrossings, &(simData->localData[0]->timeValue));
}

/* function: copyStartValuestoInitValues
 *
 * ! Function to copy all start values to initial values
 *
 */
void copyStartValuestoInitValues(_X_DATA *data)
{

  /* just copy all start values to initial */
  storeStartValuesParam(data);
  storeStartValues(data);
  storePreValues(data);
  overwriteOldSimulationData(data);

}

/*! \fn void printAllVars(_X_DATA *data, int )
 *
 *  prints all values as arguments it need data
 *  and which part of the ring should printed.
 *
 *  author: wbraun
 */
void printAllVars(_X_DATA *data, int ringSegment)
{
  long i;
  MODEL_DATA      *mData = &(data->modelData);
  INFO1("all real variables regarding point in time: %g", data->localData[ringSegment]->timeValue);
  for(i=0; i<mData->nVariablesReal; ++i){
    INFO3("localData->realVars[%ld] = %s = %g",i,mData->realVarsData[i].info.name,data->localData[ringSegment]->realVars[i]);
  }
  INFO("all integer variables");
  for(i=0; i<mData->nVariablesInteger; ++i){
    INFO3("localData->integerVars[%ld] = %s = %ld",i,mData->integerVarsData[i].info.name,data->localData[ringSegment]->integerVars[i]);
  }
  INFO("all boolean variables");
  for(i=0; i<mData->nVariablesBoolean; ++i){
    INFO3("localData->booleanVars[%ld] = %s = %s",i,mData->booleanVarsData[i].info.name,data->localData[ringSegment]->booleanVars[i]?"true":"false");
  }
  INFO("all string variables");
  for(i=0; i<mData->nVariablesString; ++i){
    INFO3("localData->stringVars[%ld] = %s = %s",i,mData->stringVarsData[i].info.name,data->localData[ringSegment]->stringVars[i]);
  }
  INFO("all real parameters");
  for(i=0; i<mData->nParametersReal; ++i){
    INFO3("mData->realParameterData[%ld] = %s = %g",i,mData->realParameterData[i].info.name,mData->realParameterData[i].attribute.initial);
  }
  INFO("all integer parameters");
  for(i=0; i<mData->nParametersInteger; ++i){
    INFO3("mData->integerParameterData[%ld] = %s = %ld",i,mData->integerParameterData[i].info.name,mData->integerParameterData[i].attribute.initial);
  }
  INFO("all boolean parameters");
  for(i=0; i<mData->nParametersBoolean; ++i){
    INFO3("mData->booleanParameterData[%ld] = %s = %s",i,mData->booleanParameterData[i].info.name,mData->booleanParameterData[i].attribute.initial?"true":"false");
  }
  INFO("all string parameters");
  for(i=0; i<mData->nParametersString; ++i){
    INFO3("mData->stringParameterData[%ld] = %s = %s",i,mData->stringParameterData[i].info.name,mData->stringParameterData[i].attribute.initial);
  }
}

/*! \fn void overwriteOldSimulationData(_X_DATA *data)
 *
 * Stores variables (states, derivatives and algebraic) to be used
 * by e.g. numerical solvers to extrapolate values as start values.
 *
 * This function overwrites all old value with the current.
 * This function is called after events.
 *
 *  author: lochel
 */
void overwriteOldSimulationData(_X_DATA *data)
{
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i){
    data->localData[i]->timeValue = data->localData[i-1]->timeValue;
    memcpy(data->localData[i]->realVars, data->localData[i-1]->realVars, sizeof(modelica_real)*data->modelData.nVariablesReal);
    memcpy(data->localData[i]->integerVars, data->localData[i-1]->integerVars, sizeof(modelica_integer)*data->modelData.nVariablesInteger);
    memcpy(data->localData[i]->booleanVars, data->localData[i-1]->booleanVars, sizeof(modelica_boolean)*data->modelData.nVariablesBoolean);
    memcpy(data->localData[i]->stringVars, data->localData[i-1]->stringVars, sizeof(modelica_string)*data->modelData.nVariablesString);
  }
}


/*! \fn void storeStartValues(_X_DATA *data)
 *
 *  sets all values to their start-attribute
 *
 *  author: lochel
 */
void storeStartValues(_X_DATA* data)
{
  long i;
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);

  for(i=0; i<mData->nVariablesReal; ++i){
    sData->realVars[i] = mData->realVarsData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Real var %s = %g",mData->realVarsData[i].info.name, sData->realVars[i]);
  }
  for(i=0; i<mData->nVariablesInteger; ++i){
    sData->integerVars[i] = mData->integerVarsData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Integer var %s = %ld",mData->integerVarsData[i].info.name, sData->integerVars[i]);
  }
  for(i=0; i<mData->nVariablesBoolean; ++i){
    sData->booleanVars[i] = mData->booleanVarsData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Boolean var %s = %s",mData->booleanVarsData[i].info.name, sData->booleanVars[i]?"true":"false");
  }
  for(i=0; i<mData->nVariablesString; ++i){
    sData->stringVars[i] = copy_modelica_string((modelica_string_const)mData->stringVarsData[i].attribute.start);
    DEBUG_INFO2(LOG_DEBUG,"Set String var %s = %s",mData->stringVarsData[i].info.name, sData->stringVars[i]);
  }
}

/*! \fn void storeStartValuesParam(_X_DATA *data)
 *
 *  sets all parameter initial values to their start-attribute
 *
 *  author: wbraun
 */
void storeStartValuesParam(_X_DATA *data)
{
  long i;
  MODEL_DATA      *mData = &(data->modelData);

  for(i=0; i<mData->nParametersReal; ++i){
    mData->realParameterData[i].attribute.initial = mData->realParameterData[i].attribute.start;
    data->simulationInfo.realParameter[i] = mData->realParameterData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Real var %s = %g",mData->realParameterData[i].info.name,data->simulationInfo.realParameter[i]);
  }
  for(i=0; i<mData->nParametersInteger; ++i){
    mData->integerParameterData[i].attribute.initial = mData->integerParameterData[i].attribute.start;
    data->simulationInfo.integerParameter[i] = mData->integerParameterData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Integer var %s = %ld",mData->integerParameterData[i].info.name, data->simulationInfo.integerParameter[i]);
  }
  for(i=0; i<mData->nParametersBoolean; ++i){
    mData->booleanParameterData[i].attribute.initial = mData->booleanParameterData[i].attribute.start;
    data->simulationInfo.booleanParameter[i] = mData->booleanParameterData[i].attribute.start;
    DEBUG_INFO2(LOG_DEBUG,"Set Boolean var %s = %s",mData->booleanParameterData[i].info.name, data->simulationInfo.booleanParameter[i]?"true":"false");
  }
  for(i=0; i<mData->nParametersString; ++i){
    mData->stringParameterData[i].attribute.initial = copy_modelica_string((modelica_string_const)mData->stringParameterData[i].attribute.start);
    data->simulationInfo.stringParameter[i] = copy_modelica_string((modelica_string_const)mData->stringParameterData[i].attribute.start);
    DEBUG_INFO2(LOG_DEBUG,"Set String var %s = %s",mData->stringParameterData[i].info.name, data->simulationInfo.stringParameter[i]);
  }
}

/*! \fn void storeInitialValuesParam(_X_DATA *data)
 *
 *  sets all parameter initial values to their start-attribute
 *
 *  author: wbraun
 */
void storeInitialValuesParam(_X_DATA *data)
{
  long i;
  MODEL_DATA      *mData = &(data->modelData);

  for(i=0; i<mData->nParametersReal; ++i){
    mData->realParameterData[i].attribute.initial = data->simulationInfo.realParameter[i];
    DEBUG_INFO2(LOG_DEBUG,"Set Real Parameter var %s = %g",mData->realParameterData[i].info.name,data->simulationInfo.realParameter[i]);
  }
  for(i=0; i<mData->nParametersInteger; ++i){
    mData->integerParameterData[i].attribute.initial = data->simulationInfo.integerParameter[i];
    DEBUG_INFO2(LOG_DEBUG,"Set Integer Parameter var %s = %ld",mData->integerParameterData[i].info.name, data->simulationInfo.integerParameter[i]);
  }
  for(i=0; i<mData->nParametersBoolean; ++i){
    mData->booleanParameterData[i].attribute.initial = data->simulationInfo.booleanParameter[i];
    DEBUG_INFO2(LOG_DEBUG,"Set Boolean Parameter var %s = %s",mData->booleanParameterData[i].info.name, data->simulationInfo.booleanParameter[i]?"true":"false");
  }
  for(i=0; i<mData->nParametersString; ++i){
    mData->stringParameterData[i].attribute.initial = copy_modelica_string((modelica_string_const)data->simulationInfo.stringParameter[i]);
    DEBUG_INFO2(LOG_DEBUG,"Set String Parameter var %s = %s",mData->stringParameterData[i].info.name, data->simulationInfo.stringParameter[i]);
  }
}


/*! \fn void storePreValues(_X_DATA *data)
 *
 *  copys all the values into their pre-values
 *
 *  author: lochel
 */
void storePreValues(_X_DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *siData = &(data->simulationInfo);

  memcpy(siData->realVarsPre, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(siData->integerVarsPre, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(siData->booleanVarsPre, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
  memcpy(siData->stringVarsPre, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
  memcpy(siData->helpVarsPre, siData->helpVars, sizeof(modelica_boolean)*mData->nHelpVars);

}

/** function resetAllHelpVars
 *  author: wbraun
 *
 *  workaround function to reset all helpvar that are used for when-equations.
 *  Need be done before initialization, to ensure the continuous integration.
 */
void resetAllHelpVars(_X_DATA* data)
{
  int i = 0;
  for(i = 0; i < data->modelData.nHelpVars; i++)
  {
    data->simulationInfo.helpVars[i] = 0;
  }
}


/** function getNextSampleTimeFMU
 *  author: wbraun
 *
 *  function return next sample time.
 */
double getNextSampleTimeFMU(_X_DATA *data)
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

  /* initial delay */
  data->simulationInfo.delayStructure = (RINGBUFFER**)malloc(data->modelData.nDelayExpressions * sizeof(RINGBUFFER*));
  ASSERT(data->simulationInfo.delayStructure, "out of memory");

  for(i=0; i<data->modelData.nDelayExpressions; i++)
    data->simulationInfo.delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));

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

  free(data->modelData.equationInfo_reverse_prof_index);

  /* free delay structure */
  for(i=0; i<data->modelData.nDelayExpressions; i++)
    freeRingBuffer(data->simulationInfo.delayStructure[i]);

  free(data->simulationInfo.delayStructure);

  pop_memory_states(NULL);

}

/* relation functions used in zero crossing detection */
double Less(double a, double b)
{
  return a - b - DBL_EPSILON;
}

double LessEq(double a, double b)
{
  return a - b;
}

double Greater(double a, double b)
{
  return b - a + DBL_EPSILON;
}

double GreaterEq(double a, double b)
{
  return b - a;
}

