/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */


#include <stdlib.h>
#include <string.h>
#include <float.h>
#include <math.h>

#include "simulation_data.h"
#include "openmodelica_func.h"
#include "omc_error.h"
#include "varinfo.h"
#include "model_help.h"
#include "simulation_info_xml.h"
#include "omc_msvc.h" /* for freaking round! */
#include "nonlinearSystem.h"
#include "linearSystem.h"
#include "mixedSystem.h"
#include "delay.h"
#include "epsilon.h"

static const int IterationMax = 200;
const size_t SIZERINGBUFFER = 3;

static double tolZC;

/*! \fn updateDiscreteSystem
 *
 *  Function to update the whole system with event iteration.
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

  data->callback->function_updateRelations(data, 1);
  storeRelations(data);
  updateHysteresis(data);

  /* should we print the relations before functionDAE?
   * printRelations(data, LOG_EVENTS_V);
   */

  data->callback->functionDAE(data);
  debugStreamPrint(LOG_EVENTS_V, 0, "updated discrete System");

  printRelations(data, LOG_EVENTS_V);

  relationChanged = checkRelations(data);
  discreteChanged = data->callback->checkForDiscreteChanges(data);
  while(!initial() && (discreteChanged || data->simulationInfo.needToIterate || relationChanged))
  {
    if(data->simulationInfo.needToIterate)
      debugStreamPrint(LOG_EVENTS_V, 0, "reinit() call. Iteration needed!");
    if(relationChanged)
      debugStreamPrint(LOG_EVENTS_V, 0, "relations changed. Iteration needed.");
    if(discreteChanged)
      debugStreamPrint(LOG_EVENTS_V, 0, "discrete Variable changed. Iteration needed.");

    storePreValues(data);
    storeRelations(data);

    printRelations(data, LOG_EVENTS_V);

    data->callback->functionDAE(data);

    IterationNum++;
    if(IterationNum > IterationMax)
      throwStreamPrint(data->threadData, "ERROR: Too many event iterations. System is inconsistent. Simulation terminate.");

    relationChanged = checkRelations(data);
    discreteChanged = data->callback->checkForDiscreteChanges(data);
  }
  updateHysteresis(data);
}

/*! \fn updateContinuousSystem
 *
 *  Function to update the whole system with EventIteration.
 *  Evaluate the functionDAE()
 *
 *  \param [ref] [data]
 */

/*!
 *  Moved to perform_simulation.c and omp_perform_simulation.c
 *  and included in the generrated code. The things we do for
 *  OPENMP.
 */

/*
void updateContinuousSystem(DATA *data)
{
  functionODE(data);
  functionAlgebraics(data);
  output_function(data);
  function_storeDelayed(data);
  storePreValues(data);
}

*/

/*! \fn saveZeroCrossings
 *
 * Function saves all ZeroCrossing Values
 *
 *  \param [ref] [data]
 */
void saveZeroCrossings(DATA* data)
{
  long i = 0;

  debugStreamPrint(LOG_ZEROCROSSINGS, 0, "save all zerocrossings"); /* ??? */

  for(i=0;i<data->modelData.nZeroCrossings;i++)
    data->simulationInfo.zeroCrossingsPre[i] = data->simulationInfo.zeroCrossings[i];

  data->callback->function_ZeroCrossings(data, data->simulationInfo.zeroCrossings);
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
 *  \param [in]  [stream]
 *
 *  \author wbraun
 */
void printAllVars(DATA *data, int ringSegment, int stream)
{
  long i;
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  if (!ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "Print values for buffer segment %d regarding point in time : %e", ringSegment, data->localData[ringSegment]->timeValue);

  infoStreamPrint(stream, 1, "states variables");
  for(i=0; i<mData->nStates; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  }
  messageClose(stream);

  infoStreamPrint(stream, 1, "derivatives variables");
  for(i=mData->nStates; i<2*mData->nStates; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  }
  messageClose(stream);

  infoStreamPrint(stream, 1, "other real values");
  for(i=2*mData->nStates; i<mData->nVariablesReal; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  }
  messageClose(stream);

  infoStreamPrint(stream, 1, "integer variables");
  for(i=0; i<mData->nVariablesInteger; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %ld (pre: %ld)", i+1, mData->integerVarsData[i].info.name, data->localData[ringSegment]->integerVars[i], sInfo->integerVarsPre[i]);
  }
  messageClose(stream);

  infoStreamPrint(stream, 1, "boolean variables");
  for(i=0; i<mData->nVariablesBoolean; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->booleanVarsData[i].info.name, data->localData[ringSegment]->booleanVars[i] ? "true" : "false", sInfo->booleanVarsPre[i] ? "true" : "false");
  }
  messageClose(stream);

  infoStreamPrint(stream, 1, "string variables");
  for(i=0; i<mData->nVariablesString; ++i) {
    infoStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->stringVarsData[i].info.name, data->localData[ringSegment]->stringVars[i], sInfo->stringVarsPre[i]);
  }
  messageClose(stream);

  messageClose(stream);
}

#ifdef USE_DEBUG_OUTPUT
/*! \fn printAllVarsDebug
 *
 *  prints all variable values
 *
 *  \param [in]  [data]
 *  \param [in]  [ringSegment]
 */
void printAllVarsDebug(DATA *data, int ringSegment, int stream)
{
  long i;
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  debugStreamPrint(stream, 1, "Print values for buffer segment %d regarding point in time : %e", ringSegment, data->localData[ringSegment]->timeValue);

  debugStreamPrint(stream, 1, "states variables");
  for(i=0; i<mData->nStates; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  messageClose(stream);

  debugStreamPrint(stream, 1, "derivatives variables");
  for(i=mData->nStates; i<2*mData->nStates; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  messageClose(stream);

  debugStreamPrint(stream, 1, "other real values");
  for(i=2*mData->nStates; i<mData->nVariablesReal; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);

  debugStreamPrint(stream, 1, "integer variables");
  for(i=0; i<mData->nVariablesInteger; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %ld (pre: %ld)", i+1, mData->integerVarsData[i].info.name, data->localData[ringSegment]->integerVars[i], sInfo->integerVarsPre[i]);

  debugStreamPrint(stream, 1, "boolean variables");
  for(i=0; i<mData->nVariablesBoolean; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->booleanVarsData[i].info.name, data->localData[ringSegment]->booleanVars[i] ? "true" : "false", sInfo->booleanVarsPre[i] ? "true" : "false");

  debugStreamPrint(stream, 1, "string variables");
  for(i=0; i<mData->nVariablesString; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->stringVarsData[i].info.name, data->localData[ringSegment]->stringVars[i], sInfo->stringVarsPre[i]);
  messageClose(stream);

  messageClose(stream);
}
#endif

/*! \fn printParameters
 *
 *  prints all parameter values
 *
 *  \param [in]  [data]
 *  \param [in]  [stream]
 *
 *  \author wbraun
 */
void printParameters(DATA *data, int stream)
{
  long i;
  MODEL_DATA *mData = &(data->modelData);

  if (!ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "parameter values");

  if (0 < mData->nParametersReal)
  {
    infoStreamPrint(stream, 1, "real parameters");
    for(i=0; i<mData->nParametersReal; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter Real %s(start=%g, fixed=%s) = %g", i+1,
                                 mData->realParameterData[i].info.name,
                                 mData->realParameterData[i].attribute.start,
                                 mData->realParameterData[i].attribute.fixed ? "true" : "false",
                                 data->simulationInfo.realParameter[i]);
    messageClose(stream);
  }

  if (0 < mData->nParametersInteger)
  {
    infoStreamPrint(stream, 1, "integer parameters");
    for(i=0; i<mData->nParametersInteger; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter Integer %s(start=%ld, fixed=%s) = %ld", i+1,
                                 mData->integerParameterData[i].info.name,
                                 mData->integerParameterData[i].attribute.start,
                                 mData->integerParameterData[i].attribute.fixed ? "true" : "false",
                                 data->simulationInfo.integerParameter[i]);
    messageClose(stream);
  }

  if (0 < mData->nParametersBoolean)
  {
    infoStreamPrint(stream, 1, "boolean parameters");
    for(i=0; i<mData->nParametersBoolean; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter Boolean %s(start=%s, fixed=%s) = %s", i+1,
                                 mData->booleanParameterData[i].info.name,
                                 mData->booleanParameterData[i].attribute.start ? "true" : "false",
                                 mData->booleanParameterData[i].attribute.fixed ? "true" : "false",
                                 data->simulationInfo.booleanParameter[i] ? "true" : "false");
    messageClose(stream);
  }

  if (0 < mData->nParametersString)
  {
    infoStreamPrint(stream, 1, "string parameters");
    for(i=0; i<mData->nParametersString; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter String %s(start=\"%s\") = \"%s\"", i+1,
                                 mData->stringParameterData[i].info.name,
                                 mData->stringParameterData[i].attribute.start,
                                 data->simulationInfo.stringParameter[i]);
    messageClose(stream);
  }

  messageClose(stream);
}

#ifdef USE_DEBUG_OUTPUT
/*! \fn printRelationsDebug
 *
 *  print all relations
 *
 *  \param [in]  [data]
 *  \param [in]  [stream]
 */
void printRelationsDebug(DATA *data, int stream)
{
  long i;

  debugStreamPrint(stream, 1, "status of relations at time=%.12g", data->localData[0]->timeValue);

  for(i=0; i<data->modelData.nRelations; i++)
    debugStreamPrint(stream, 0, "[%ld] %s = %c | pre(%s) = %c", i, data->callback->relationDescription(i), data->simulationInfo.relations[i] ? 'T' : 'F', data->callback->relationDescription(i), data->simulationInfo.relationsPre[i] ? 'T' : 'F');

  messageClose(stream);
}
#endif

/*! \fn printRelations
 *
 *  print all relations
 *
 *  \param [in]  [data]
 *  \param [in]  [stream]
 */
void printRelations(DATA *data, int stream)
{
  long i;

  if (!ACTIVE_STREAM(stream)) return;
  infoStreamPrint(stream, 1, "status of relations at time=%.12g", data->localData[0]->timeValue);

  for(i=0; i<data->modelData.nRelations; i++) {
    infoStreamPrint(stream, 0, "[%ld] %s = %c | pre(%s) = %c", i, data->callback->relationDescription(i), data->simulationInfo.relations[i] ? 'T' : 'F', data->callback->relationDescription(i), data->simulationInfo.relationsPre[i] ? 'T' : 'F');
  }
  messageClose(stream);
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
    debugStreamPrint(LOG_DEBUG, 0, "set Real var %s = %g", mData->realVarsData[i].info.name, sData->realVars[i]);
  }
  for(i=0; i<mData->nVariablesInteger; ++i)
  {
    sData->integerVars[i] = mData->integerVarsData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set Integer var %s = %ld", mData->integerVarsData[i].info.name, sData->integerVars[i]);
  }
  for(i=0; i<mData->nVariablesBoolean; ++i)
  {
    sData->booleanVars[i] = mData->booleanVarsData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set Boolean var %s = %s", mData->booleanVarsData[i].info.name, sData->booleanVars[i] ? "true" : "false");
  }
  for(i=0; i<mData->nVariablesString; ++i)
  {
    sData->stringVars[i] = mData->stringVarsData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set String var %s = %s", mData->stringVarsData[i].info.name, sData->stringVars[i]);
  }
}

/*! \fn setAllStartToVars
 *
 *  This function sets the start-attribute of all variables to their current values.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void setAllStartToVars(DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  long i;
  debugStreamPrint(LOG_DEBUG, 1, "the start-attribute of all variables to their current values:");
  for(i=0; i<mData->nVariablesReal; ++i)
  {
    mData->realVarsData[i].attribute.start = sData->realVars[i];
    debugStreamPrint(LOG_DEBUG, 0, "Real var %s(start=%g)", mData->realVarsData[i].info.name, sData->realVars[i]);
  }
  for(i=0; i<mData->nVariablesInteger; ++i)
  {
    mData->integerVarsData[i].attribute.start = sData->integerVars[i];
    debugStreamPrint(LOG_DEBUG, 0, "Integer var %s(start=%ld)", mData->integerVarsData[i].info.name, sData->integerVars[i]);
  }
  for(i=0; i<mData->nVariablesBoolean; ++i)
  {
    mData->booleanVarsData[i].attribute.start = sData->booleanVars[i];
    debugStreamPrint(LOG_DEBUG, 0, "Boolean var %s(start=%s)", mData->booleanVarsData[i].info.name, sData->booleanVars[i] ? "true" : "false");
  }
  for(i=0; i<mData->nVariablesString; ++i)
  {
    mData->stringVarsData[i].attribute.start = sData->stringVars[i];
    debugStreamPrint(LOG_DEBUG, 0, "String var %s(start=%s)", mData->stringVarsData[i].info.name, sData->stringVars[i]);
  }
  if (DEBUG_STREAM(LOG_DEBUG)) {
    messageClose(LOG_DEBUG);
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
    debugStreamPrint(LOG_DEBUG, 0, "set Real var %s = %g", mData->realParameterData[i].info.name, sInfo->realParameter[i]);
  }
  for(i=0; i<mData->nParametersInteger; ++i)
  {
    sInfo->integerParameter[i] = mData->integerParameterData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set Integer var %s = %ld", mData->integerParameterData[i].info.name, sInfo->integerParameter[i]);
  }
  for(i=0; i<mData->nParametersBoolean; ++i)
  {
    sInfo->booleanParameter[i] = mData->booleanParameterData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set Boolean var %s = %s", mData->booleanParameterData[i].info.name, sInfo->booleanParameter[i] ? "true" : "false");
  }
  for(i=0; i<mData->nParametersString; ++i)
  {
    sInfo->stringParameter[i] = mData->stringParameterData[i].attribute.start;
    debugStreamPrint(LOG_DEBUG, 0, "set String var %s = %s", mData->stringParameterData[i].info.name, sInfo->stringParameter[i]);
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
  memcpy(sInfo->realVarsOld, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sInfo->integerVarsOld, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sInfo->booleanVarsOld, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
  memcpy(sInfo->stringVarsOld, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
}

/*! \fn restoreOldValues
 *
 *  This function copys old-values to currenct localData
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void restoreOldValues(DATA *data)
{
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  sData->timeValue = sInfo->timeValueOld;
  memcpy(sData->realVars, sInfo->realVarsOld, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sData->integerVars, sInfo->integerVarsOld, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sData->booleanVars, sInfo->booleanVarsOld,  sizeof(modelica_boolean)*mData->nVariablesBoolean);
  memcpy( sData->stringVars, sInfo->stringVarsOld, sizeof(modelica_string)*mData->nVariablesString);
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

  memcpy(sInfo->relationsPre, sInfo->relations, sizeof(modelica_boolean)*mData->nRelations);
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
    if(sInfo->relationsPre[i] != sInfo->relations[i]){
      check = 1;
      break;
    }
  }

  return check;
}

/*! \fn printHysteresisRelations
 *
 *
 *  \param [out] [data]
 *
 *  \author wbraun
 */
void printHysteresisRelations(DATA *data)
{
  long i;

  if (ACTIVE_STREAM(LOG_STDOUT)) {
    infoStreamPrint(LOG_STDOUT, 1, "Status of hysteresisEnabled:");
    for(i=0; i<data->modelData.nRelations; i++)
    {
      infoStreamPrint(LOG_STDOUT, 0, "[%ld] %s = %c | relation(%s) = %c", i, data->callback->relationDescription(i), data->simulationInfo.hysteresisEnabled[i]>0 ? 'T' : 'F', data->callback->relationDescription(i), data->simulationInfo.relations[i] ? 'T' : 'F');
    }
    messageClose(LOG_STDOUT);
  }
}

/*! \fn activateHysteresis
 *
 *
 *  \param [out] [data]
 *
 *  \author wbraun
 */
void activateHysteresis(DATA* data){

  int i;

  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  for(i=0;i<mData->nRelations;++i){
    sInfo->hysteresisEnabled[i] = sInfo->relations[i]?0:1;
  }
}

/*! \fn updateHysteresis
 *
 *
 *  \param [out] [data]
 *
 *  \author wbraun
 */
void updateHysteresis(DATA* data){

  int i;

  MODEL_DATA      *mData = &(data->modelData);
  SIMULATION_INFO *sInfo = &(data->simulationInfo);

  for(i=0;i<mData->nRelations;++i){
    sInfo->hysteresisEnabled[i] = sInfo->relations[i]?1:0;
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
  if(0 < data->modelData.nSamples){
    infoStreamPrint(LOG_EVENTS, 0, "Next event time = %f", data->simulationInfo.nextSampleEvent);
    return data->simulationInfo.nextSampleEvent;
  }

  return -1;
}

/*! \fn initializeDataStruc
 *
 *  function initialize DATA structure
 *
 *  \param [ref] [data]
 *
 */
void initializeDataStruc(DATA *data)
{
  SIMULATION_DATA tmpSimData;
  size_t i = 0;
  /* RingBuffer */
  data->simulationData = 0;
  data->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if(!data->simulationData)
  {
    throwStreamPrint(data->threadData, "Your memory is not strong enough for our Ringbuffer!");
  }

  /* prepare RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    /* set time value */
    tmpSimData.timeValue = 0;
    /* buffer for all variable values */
    tmpSimData.realVars = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
    assertStreamPrint(data->threadData, 0 != tmpSimData.realVars, "out of memory");
    tmpSimData.integerVars = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
    assertStreamPrint(data->threadData, 0 != tmpSimData.integerVars, "out of memory");
    tmpSimData.booleanVars = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
    assertStreamPrint(data->threadData, 0 != tmpSimData.booleanVars, "out of memory");
    tmpSimData.stringVars = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));
    assertStreamPrint(data->threadData, 0 != tmpSimData.stringVars, "out of memory");
    appendRingData(data->simulationData, &tmpSimData);
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

  data->modelData.samplesInfo = (SAMPLE_INFO*) calloc(data->modelData.nSamples, sizeof(SAMPLE_INFO));
  data->simulationInfo.nextSampleEvent = data->simulationInfo.startTime;
  data->simulationInfo.nextSampleTimes = (double*) calloc(data->modelData.nSamples, sizeof(double));
  data->simulationInfo.samples = (modelica_boolean*) calloc(data->modelData.nSamples, sizeof(modelica_boolean));

  /* set default solvers for algebraic loops */
  data->simulationInfo.nlsMethod = NLS_HYBRID;
  data->simulationInfo.lsMethod = LS_LAPACK;
  data->simulationInfo.mixedMethod = MIXED_SEARCH;

  data->simulationInfo.zeroCrossings = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.zeroCrossingsPre = (modelica_real*) calloc(data->modelData.nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo.relations = (modelica_boolean*) calloc(data->modelData.nRelations, sizeof(modelica_boolean));
  data->simulationInfo.relationsPre = (modelica_boolean*) calloc(data->modelData.nRelations, sizeof(modelica_boolean));
  data->simulationInfo.hysteresisEnabled = (modelica_boolean*) calloc(data->modelData.nRelations, sizeof(modelica_boolean));
  data->simulationInfo.zeroCrossingIndex = (long*) malloc(data->modelData.nZeroCrossings*sizeof(long));
  data->simulationInfo.mathEventsValuePre = (modelica_real*) malloc(data->modelData.nMathEvents*sizeof(modelica_real));
  /* initialize zeroCrossingsIndex with corresponding index is used by events lists */
  for(i=0; i<data->modelData.nZeroCrossings; i++)
    data->simulationInfo.zeroCrossingIndex[i] = (long)i;

  /* buffer for old values */
  data->simulationInfo.realVarsOld = (modelica_real*)calloc(data->modelData.nVariablesReal, sizeof(modelica_real));
  data->simulationInfo.integerVarsOld = (modelica_integer*)calloc(data->modelData.nVariablesInteger, sizeof(modelica_integer));
  data->simulationInfo.booleanVarsOld = (modelica_boolean*)calloc(data->modelData.nVariablesBoolean, sizeof(modelica_boolean));
  data->simulationInfo.stringVarsOld = (modelica_string*)calloc(data->modelData.nVariablesString, sizeof(modelica_string));

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

  /* buffer for mixed systems */
  data->simulationInfo.mixedSystemData = (MIXED_SYSTEM_DATA*) malloc(data->modelData.nMixedSystems*sizeof(MIXED_SYSTEM_DATA));
  data->callback->initialMixedSystem(data->simulationInfo.mixedSystemData);

  /* buffer for linear systems */
  data->simulationInfo.linearSystemData = (LINEAR_SYSTEM_DATA*) malloc(data->modelData.nLinearSystems*sizeof(LINEAR_SYSTEM_DATA));
  data->callback->initialLinearSystem(data->simulationInfo.linearSystemData);

  /* buffer for non-linear systems */
  data->simulationInfo.nonlinearSystemData = (NONLINEAR_SYSTEM_DATA*) malloc(data->modelData.nNonLinearSystems*sizeof(NONLINEAR_SYSTEM_DATA));
  data->callback->initialNonLinearSystem(data->simulationInfo.nonlinearSystemData);

  /* buffer for state sets */
  data->simulationInfo.stateSetData = (STATE_SET_DATA*) malloc(data->modelData.nStateSets*sizeof(STATE_SET_DATA));
  data->callback->initializeStateSets(data->simulationInfo.stateSetData, data);

  /* buffer for analytical jacobains */
  data->simulationInfo.analyticJacobians = (ANALYTIC_JACOBIAN*) malloc(data->modelData.nJacobians*sizeof(ANALYTIC_JACOBIAN));

  data->modelData.modelDataXml.functionNames = NULL;
  data->modelData.modelDataXml.equationInfo = NULL;

  /* buffer for external objects */
  data->simulationInfo.extObjs = NULL;
  data->simulationInfo.extObjs = (void**) calloc(data->modelData.nExtObjs, sizeof(void*));

  assertStreamPrint(data->threadData, 0 != data->simulationInfo.extObjs, "error allocating external objects");

  /* initial chattering info */
  data->simulationInfo.chatteringInfo.numEventLimit = 100;
  data->simulationInfo.chatteringInfo.lastSteps = (int*) calloc(data->simulationInfo.chatteringInfo.numEventLimit, sizeof(int));
  data->simulationInfo.chatteringInfo.lastTimes = (modelica_real*) calloc(data->simulationInfo.chatteringInfo.numEventLimit, sizeof(double));
  data->simulationInfo.chatteringInfo.currentIndex = 0;
  data->simulationInfo.chatteringInfo.lastStepsNumStateEvents = 0;
  data->simulationInfo.chatteringInfo.messageEmitted = 0;

  data->simulationInfo.lambda = 1.0;

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
  assertStreamPrint(data->threadData, 0 != data->simulationInfo.delayStructure, "out of memory");

  for(i=0; i<data->modelData.nDelayExpressions; i++) {
    data->simulationInfo.delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));
  }
}

/*! \fn deInitializeDataStruc
 *
 *  function de-initialize DATA structure
 *
 *  \param [ref] [data]
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

  free(data->modelData.samplesInfo);
  free(data->simulationInfo.nextSampleTimes);
  free(data->simulationInfo.samples);

  /* free simulationInfo arrays */
  free(data->simulationInfo.zeroCrossings);
  free(data->simulationInfo.zeroCrossingsPre);
  free(data->simulationInfo.relations);
  free(data->simulationInfo.relationsPre);
  free(data->simulationInfo.hysteresisEnabled);
  free(data->simulationInfo.zeroCrossingIndex);

  /* free buffer for old state variables */
  free(data->simulationInfo.realVarsOld);
  free(data->simulationInfo.integerVarsOld);
  free(data->simulationInfo.booleanVarsOld);
  free(data->simulationInfo.stringVarsOld);

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

  /* free buffer for state sets */
  free(data->simulationInfo.stateSetData);

  /* free buffer of mixed systems */
  free(data->simulationInfo.mixedSystemData);

  /* free buffer of linear systems */
  free(data->simulationInfo.linearSystemData);

  /* free buffer of non-linear systems */
  free(data->simulationInfo.nonlinearSystemData);

  /* free buffer jacobians */
  free(data->simulationInfo.analyticJacobians);

  /* free inputs and output */
  free(data->simulationInfo.inputVars);
  free(data->simulationInfo.outputVars);

  /* free external objects buffer */
  free(data->simulationInfo.extObjs);

  /* free chattering info */
  free(data->simulationInfo.chatteringInfo.lastSteps);
  free(data->simulationInfo.chatteringInfo.lastTimes);

  /* TODO: Make a free xml function */
  freeModelInfoXml(&data->modelData.modelDataXml);

  /* free delay structure */
  for(i=0; i<data->modelData.nDelayExpressions; i++)
    freeRingBuffer(data->simulationInfo.delayStructure[i]);

  free(data->simulationInfo.delayStructure);
}

/* relation functions used in zero crossing detection
 * Less is for case LESS and GREATEREQ
 * Greater is for case LESSEQ and GREATER
 */

void setZCtol(double relativeTol)
{
  /* lochel: force tolZC > 0 */
  tolZC = max(TOL_HYSTERESIS_ZEROCROSSINGS*relativeTol, TOL_HYSTERESIS_ZEROCROSSINGS*MINIMAL_STEP_SIZE);
  infoStreamPrint(LOG_EVENTS_V, 0, "Set tolerance for zero-crossing hysteresis to: %e", tolZC);
}

modelica_boolean LessZC(double a, double b, modelica_boolean direction)
{
  double eps = (direction) ? tolZC*fabs(b)+tolZC : tolZC*fabs(a)+tolZC;
  return (direction) ? (a - b <= eps) : (a - b <= -eps);
}

modelica_boolean LessEqZC(double a, double b, modelica_boolean direction)
{
  return (!GreaterZC(a, b, !direction));
}

modelica_boolean GreaterZC(double a, double b, modelica_boolean direction)
{
  double eps = (direction) ? tolZC*fabs(a)+tolZC : tolZC*fabs(b)+tolZC;
  return (direction) ? (a - b >= -eps ) : (a - b >= eps);
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


/*! \fn _event_integer
 *
 *  \param [in]  [x]
 *  \param [in]  [index]
 *  \param [ref] [data]
 *
 * Returns the largest integer not greater than x.
 */
modelica_integer _event_integer(modelica_real x, modelica_integer index, DATA *data)
{
  modelica_real value;
  if(data->simulationInfo.discreteCall == 0 || data->simulationInfo.solveContinuous)
  {
    value = data->simulationInfo.mathEventsValuePre[index];
  }
  else
  {
    data->simulationInfo.mathEventsValuePre[index] = (modelica_integer)floor(x);
    value = data->simulationInfo.mathEventsValuePre[index];
  }
  return value;
}

/*! \fn _event_floor
 *
 *  \param [in]  [x]
 *  \param [in]  [index]
 *  \param [ref] [data]
 *
 * Returns the largest integer not greater than x.
 * Result and argument shall have type Real.
 */
modelica_real _event_floor(modelica_real x, modelica_integer index, DATA *data)
{
  modelica_real value;
  if(data->simulationInfo.discreteCall == 0 || data->simulationInfo.solveContinuous)
    value = data->simulationInfo.mathEventsValuePre[index];
  else
  {
    data->simulationInfo.mathEventsValuePre[index] = x;
    value = data->simulationInfo.mathEventsValuePre[index];
  }
  return (modelica_real)floor(value);
}

/*! \fn _event_ceil
 *
 *  \param [in]  [x]
 *  \param [in]  [index]
 *  \param [ref] [data]
 *
 * Returns the smallest integer not less than x.
 * Result and argument shall have type Real.
 */
modelica_real _event_ceil(modelica_real x, modelica_integer index, DATA *data)
{
  modelica_real value;
  if(data->simulationInfo.discreteCall == 0 || data->simulationInfo.solveContinuous)
    value = data->simulationInfo.mathEventsValuePre[index];
  else
  {
    data->simulationInfo.mathEventsValuePre[index] = x;
    value = data->simulationInfo.mathEventsValuePre[index];
  }
  return (modelica_real)ceil(value);
}

/*! \fn _event_div_integer
 *
 *  \param [in]  [x1]
 *  \param [in]  [x2]
 *  \param [in]  [index]
 *  \param [ref] [data]
 *
 * Returns the algebraic quotient x/y with any fractional part discarded.
 */
modelica_integer _event_div_integer(modelica_integer x1, modelica_integer x2, modelica_integer index, DATA *data)
{
  modelica_integer value1, value2;
  if(data->simulationInfo.discreteCall == 0 || data->simulationInfo.solveContinuous)
  {
    value1 = (modelica_integer)data->simulationInfo.mathEventsValuePre[index];
    value2 = (modelica_integer)data->simulationInfo.mathEventsValuePre[index+1];
  }
  else
  {
    data->simulationInfo.mathEventsValuePre[index] = (modelica_real)x1;
    data->simulationInfo.mathEventsValuePre[index+1] = (modelica_real)x2;
    value1 = (modelica_integer)data->simulationInfo.mathEventsValuePre[index];
    value2 = (modelica_integer)data->simulationInfo.mathEventsValuePre[index+1];
  }
  assertStreamPrint(data->threadData, value2 != 0, "event_div_integer failt at time %f because x2 is zero!", data->localData[0]->timeValue);
  return ldiv(value1, value2).quot;
}

/*! \fn _event_div_real
 *
 *  \param [in]  [x1]
 *  \param [in]  [x2]
 *  \param [in]  [index]
 *  \param [ref] [data]
 *
 * Returns the algebraic quotient x/y with any fractional part discarded.
 */
modelica_real _event_div_real(modelica_real x1, modelica_real x2, modelica_integer index, DATA *data)
{
  modelica_real value1, value2;
  if(data->simulationInfo.discreteCall == 0 || data->simulationInfo.solveContinuous)
  {
    value1 = data->simulationInfo.mathEventsValuePre[index];
    value2 = data->simulationInfo.mathEventsValuePre[index+1];
  }
  else
  {
    data->simulationInfo.mathEventsValuePre[index] = x1;
    data->simulationInfo.mathEventsValuePre[index+1] = x2;
    value1 = data->simulationInfo.mathEventsValuePre[index];
    value2 = data->simulationInfo.mathEventsValuePre[index+1];
  }
#if defined(_MSC_VER)
  {
    modelica_real rtmp = value1/value2;
    modelica_integer tmp = (modelica_integer)(rtmp);
    return (modelica_real)tmp;
  }
#else
  return trunc(value1/value2);
#endif
}

