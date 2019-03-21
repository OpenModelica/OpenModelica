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

#include "../../openmodelica.h"
#include "../../simulation_data.h"
#include "../../openmodelica_func.h"
#include "../../util/omc_error.h"
#include "../../util/varinfo.h"
#include "model_help.h"
#include "../options.h"
#include "../simulation_info_json.h"
#include "../../util/omc_msvc.h" /* for freaking round! */
#include "nonlinearSystem.h"
#include "linearSystem.h"
#include "mixedSystem.h"
#include "delay.h"
#include "epsilon.h"
#include "fmi_events.h"
#include "stateset.h"
#include "../../meta/meta_modelica.h"

int maxEventIterations = 20;
double linearSparseSolverMaxDensity = 0.2;
int linearSparseSolverMinSize = 201;
double nonlinearSparseSolverMaxDensity = 0.2;
int nonlinearSparseSolverMinSize = 10001;
double maxStepFactor = 1e12;
double newtonXTol = 1e-12;
double newtonFTol = 1e-12;
double steadyStateTol = 1e-3;
const size_t SIZERINGBUFFER = 3;
int compiledInDAEMode = 0;
int compiledWithSymSolver = 0;
double numericalDifferentiationDeltaXlinearize = 1e-8;
double numericalDifferentiationDeltaXsolver = 1e-8;
double homAdaptBend = 0.5;
double homHEps = 1e-5;
int homMaxLambdaSteps = 0;
int homMaxNewtonSteps = 20;
int homMaxTries = 10;
double homTauDecreasingFactor = 10.0;
double homTauDecreasingFactorPredictor = 2.0;
double homTauIncreasingFactor = 2.0;
double homTauIncreasingThreshold = 10.0;
double homTauMax = 10.0;
double homTauMin = 1e-4;
double homTauStart = 0.2;
int homBacktraceStrategy = 1;

static double tolZC;

/*! \fn updateDiscreteSystem
 *
 *  Function to update the whole system with event iteration.
 *  Evaluates functionDAE()
 *
 *  \param [ref] [data]
 */
void updateDiscreteSystem(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  int numEventIterations = 0;
  int discreteChanged = 0;
  modelica_boolean relationChanged = 0;
  data->simulationInfo->needToIterate = 0;

  data->simulationInfo->callStatistics.updateDiscreteSystem++;

  data->callback->function_updateRelations(data, threadData, 1);
  updateRelationsPre(data);
  storeRelations(data);

  data->callback->functionDAE(data, threadData);
  debugStreamPrint(LOG_EVENTS_V, 0, "updated discrete System");

  relationChanged = checkRelations(data);
  discreteChanged = checkForDiscreteChanges(data, threadData);
  while(discreteChanged || data->simulationInfo->needToIterate || relationChanged)
  {
    if(data->simulationInfo->needToIterate) {
      debugStreamPrint(LOG_EVENTS_V, 0, "reinit() call. Iteration needed!");
    }
    if(relationChanged) {
      debugStreamPrint(LOG_EVENTS_V, 0, "relations changed. Iteration needed.");
    }
    if(discreteChanged) {
      debugStreamPrint(LOG_EVENTS_V, 0, "discrete Variable changed. Iteration needed.");
    }

    storePreValues(data);
    updateRelationsPre(data);

    printRelations(data, LOG_EVENTS_V);
    printZeroCrossings(data, LOG_EVENTS_V);

    data->callback->functionDAE(data, threadData);

    numEventIterations++;
    if(numEventIterations > maxEventIterations) {
      throwStreamPrint(threadData, "Simulation terminated due to too many, i.e. %d, event iterations.\nThis could either indicate an inconsistent system or an undersized limit of event iterations.\nThe limit of event iterations can be specified using the runtime flag '–%s=<value>'.", maxEventIterations, FLAG_NAME[FLAG_MAX_EVENT_ITERATIONS]);
    }

    relationChanged = checkRelations(data);
    discreteChanged = checkForDiscreteChanges(data, threadData);
  }
  storeRelations(data);

  TRACE_POP
}

/*! \fn saveZeroCrossings
 *
 * Function saves all zero-crossing values
 *
 *  \param [ref] [data]
 */
void saveZeroCrossings(DATA* data, threadData_t *threadData)
{
  TRACE_PUSH
  long i = 0;

  debugStreamPrint(LOG_ZEROCROSSINGS, 0, "save all zero-crossings");

  for(i=0;i<data->modelData->nZeroCrossings;i++)
    data->simulationInfo->zeroCrossingsPre[i] = data->simulationInfo->zeroCrossings[i];

  data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);

  TRACE_POP
}

/*! \fn copyStartValuestoInitValues
 *
 *  Function to copy all start values to initial values
 *
 *  \param [ref] [data]
 */
void copyStartValuestoInitValues(DATA *data)
{
  TRACE_PUSH

  /* just copy all start values to initial */
  setAllParamsToStart(data);
  setAllVarsToStart(data);
  storePreValues(data);
  overwriteOldSimulationData(data);

  TRACE_POP
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
  TRACE_PUSH
  long i;
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  if (!ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "Print values for buffer segment %d regarding point in time : %g", ringSegment, data->localData[ringSegment]->timeValue);

  infoStreamPrint(stream, 1, "states variables");
  for(i=0; i<mData->nStates; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  messageClose(stream);

  infoStreamPrint(stream, 1, "derivatives variables");
  for(i=mData->nStates; i<2*mData->nStates; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  messageClose(stream);

  infoStreamPrint(stream, 1, "other real values");
  for(i=2*mData->nStates; i<mData->nVariablesReal; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %g (pre: %g)", i+1, mData->realVarsData[i].info.name, data->localData[ringSegment]->realVars[i], sInfo->realVarsPre[i]);
  messageClose(stream);

  infoStreamPrint(stream, 1, "integer variables");
  for(i=0; i<mData->nVariablesInteger; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %ld (pre: %ld)", i+1, mData->integerVarsData[i].info.name, data->localData[ringSegment]->integerVars[i], sInfo->integerVarsPre[i]);
  messageClose(stream);

  infoStreamPrint(stream, 1, "boolean variables");
  for(i=0; i<mData->nVariablesBoolean; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->booleanVarsData[i].info.name, data->localData[ringSegment]->booleanVars[i] ? "true" : "false", sInfo->booleanVarsPre[i] ? "true" : "false");
  messageClose(stream);

#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  infoStreamPrint(stream, 1, "string variables");
  for(i=0; i<mData->nVariablesString; ++i)
    infoStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1,
        mData->stringVarsData[i].info.name,
        MMC_STRINGDATA(data->localData[ringSegment]->stringVars[i]),
        MMC_STRINGDATA(sInfo->stringVarsPre[i]));
  messageClose(stream);
#endif
  messageClose(stream);

  TRACE_POP
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
  TRACE_PUSH
  long i;
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

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
  messageClose(stream);

  debugStreamPrint(stream, 1, "integer variables");
  for(i=0; i<mData->nVariablesInteger; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %ld (pre: %ld)", i+1, mData->integerVarsData[i].info.name, data->localData[ringSegment]->integerVars[i], sInfo->integerVarsPre[i]);
  messageClose(stream);

  debugStreamPrint(stream, 1, "boolean variables");
  for(i=0; i<mData->nVariablesBoolean; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->booleanVarsData[i].info.name, data->localData[ringSegment]->booleanVars[i] ? "true" : "false", sInfo->booleanVarsPre[i] ? "true" : "false");
  messageClose(stream);

#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  debugStreamPrint(stream, 1, "string variables");
  for(i=0; i<mData->nVariablesString; ++i)
    debugStreamPrint(stream, 0, "%ld: %s = %s (pre: %s)", i+1, mData->stringVarsData[i].info.name, data->localData[ringSegment]->stringVars[i], sInfo->stringVarsPre[i]);
  messageClose(stream);
#endif
  messageClose(stream);

  TRACE_POP
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
  TRACE_PUSH
  long i;
  MODEL_DATA *mData = data->modelData;

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
                                 data->simulationInfo->realParameter[i]);
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
                                 data->simulationInfo->integerParameter[i]);
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
                                 data->simulationInfo->booleanParameter[i] ? "true" : "false");
    messageClose(stream);
  }

  if (0 < mData->nParametersString)
  {
    infoStreamPrint(stream, 1, "string parameters");
    for(i=0; i<mData->nParametersString; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter String %s(start=\"%s\") = \"%s\"", i+1,
                                 mData->stringParameterData[i].info.name,
                                 MMC_STRINGDATA(mData->stringParameterData[i].attribute.start),
                                 MMC_STRINGDATA(data->simulationInfo->stringParameter[i]));
    messageClose(stream);
  }

  messageClose(stream);

  TRACE_POP
}

/*! \fn printSparseStructure
 *
 *  prints sparse structure of jacobian A
 *
 *  \param [in]  [sparsePattern]
 *  \param [in]  [sizeRow]
 *  \param [in]  [sizeCol]
 *  \param [in]  [stream]
 *
 */
void printSparseStructure(SPARSE_PATTERN *sparsePattern, int sizeRows, int sizeCols, int stream, const char* name)
{
  unsigned int row, col, i, j;
  /* Will crash with a static size array */
  char *buffer = NULL;

  if (!ACTIVE_STREAM(stream))
    return;

  buffer = (char*)omc_alloc_interface.malloc(sizeof(char)* 2*sizeCols + 4);

  infoStreamPrint(stream, 1, "sparse structure of %s [size: %ux%u]", name, sizeRows, sizeCols);
  infoStreamPrint(stream, 0, "%u nonzero elements", sparsePattern->numberOfNoneZeros);

  infoStreamPrint(stream, 1, "transposed sparse structure (rows: states)");
  i=0;
  for(row=0; row < sizeRows; row++)
  {
    j=0;
    for(col=0; i < sparsePattern->leadindex[row+1]; col++)
    {
      if(sparsePattern->index[i] == col)
      {
        buffer[j++] = '*';
        ++i;
      }
      else
      {
        buffer[j++] = ' ';
      }
      buffer[j++] = ' ';
    }
    buffer[j] = '\0';
    infoStreamPrint(stream, 0, "%s", buffer);
  }
  messageClose(stream);
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
  TRACE_PUSH
  long i;

  debugStreamPrint(stream, 1, "status of relations at time=%.12g", data->localData[0]->timeValue);
  for(i=0; i<data->modelData->nRelations; i++)
    debugStreamPrint(stream, 0, "[%ld] %s = %c | pre(%s) = %c", i, data->callback->relationDescription(i), data->simulationInfo->relations[i] ? 'T' : 'F', data->callback->relationDescription(i), data->simulationInfo->relationsPre[i] ? 'T' : 'F');
  messageClose(stream);

  TRACE_POP
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
  TRACE_PUSH
  long i;

  if (!ACTIVE_STREAM(stream))
  {
    TRACE_POP
    return;
  }

  infoStreamPrint(stream, 1, "status of relations at time=%.12g", data->localData[0]->timeValue);
  for(i=0; i<data->modelData->nRelations; i++)
  {
    infoStreamPrint(stream, 0, "[%ld] (pre: %s) %s = %s", i+1, data->simulationInfo->relationsPre[i] ? " true" : "false", data->simulationInfo->relations[i] ? " true" : "false", data->callback->relationDescription(i));
  }
  messageClose(stream);

  TRACE_POP
}

/*! \fn printZeroCrossings
 *
 *  print all zero crossings
 *
 *  \param [in]  [data]
 *  \param [in]  [stream]
 */
void printZeroCrossings(DATA *data, int stream)
{
  TRACE_PUSH
  long i;

  if (!ACTIVE_STREAM(stream))
  {
    TRACE_POP
    return;
  }

  infoStreamPrint(stream, 1, "status of zero crossings at time=%.12g", data->localData[0]->timeValue);
  for(i=0; i<data->modelData->nZeroCrossings; i++)
  {
    int *eq_indexes;
    const char *exp_str = data->callback->zeroCrossingDescription(i,&eq_indexes);
    infoStreamPrintWithEquationIndexes(stream, 0, eq_indexes, "[%ld] (pre: %2.g) %2.g = %s", i+1, data->simulationInfo->zeroCrossingsPre[i], data->simulationInfo->zeroCrossings[i], exp_str);
  }
  messageClose(stream);

  TRACE_POP
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
  TRACE_PUSH
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i)
  {
    data->localData[i]->timeValue = data->localData[i-1]->timeValue;
    memcpy(data->localData[i]->realVars, data->localData[i-1]->realVars, sizeof(modelica_real)*data->modelData->nVariablesReal);
    memcpy(data->localData[i]->integerVars, data->localData[i-1]->integerVars, sizeof(modelica_integer)*data->modelData->nVariablesInteger);
    memcpy(data->localData[i]->booleanVars, data->localData[i-1]->booleanVars, sizeof(modelica_boolean)*data->modelData->nVariablesBoolean);
    memcpy(data->localData[i]->stringVars, data->localData[i-1]->stringVars, sizeof(modelica_string)*data->modelData->nVariablesString);
  }

  TRACE_POP
}

/*! \fn copyRingBufferSimulationData
 *
 *  Copy RingBuffer simulation data from DATA to a new ring buffer.
 *
 *  This function is used to initialize the ring buffer of dassl after events.
 *
 *  \param [in] [data]
 *  \param [out] [destData]
 *  \param [out] [destRing]
 *
 *
 *  \author wbraun
 */
void copyRingBufferSimulationData(DATA *data, threadData_t *threadData, SIMULATION_DATA **destData, RINGBUFFER* destRing)
{
  TRACE_PUSH
  long i;

  assertStreamPrint(threadData, ringBufferLength(data->simulationData) == ringBufferLength(destRing), "copy ring buffer failed, because of different sizes.");

  for(i=0; i<ringBufferLength(data->simulationData); ++i)
  {
    destData[i]->timeValue = data->localData[i]->timeValue;
    memcpy(destData[i]->realVars, data->localData[i]->realVars, sizeof(modelica_real)*data->modelData->nVariablesReal);
    memcpy(destData[i]->integerVars, data->localData[i]->integerVars, sizeof(modelica_integer)*data->modelData->nVariablesInteger);
    memcpy(destData[i]->booleanVars, data->localData[i]->booleanVars, sizeof(modelica_boolean)*data->modelData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
    memcpy(destData[i]->stringVars, data->localData[i]->stringVars, sizeof(modelica_string)*data->modelData->nVariablesString);
#endif
  }


  TRACE_POP
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
  TRACE_PUSH
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i)
  {
    data->localData[i-1]->timeValue = data->localData[i]->timeValue;
    memcpy(data->localData[i-1]->realVars, data->localData[i]->realVars, sizeof(modelica_real)*data->modelData->nVariablesReal);
    memcpy(data->localData[i-1]->integerVars, data->localData[i]->integerVars, sizeof(modelica_integer)*data->modelData->nVariablesInteger);
    memcpy(data->localData[i-1]->booleanVars, data->localData[i]->booleanVars, sizeof(modelica_boolean)*data->modelData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
    memcpy(data->localData[i-1]->stringVars, data->localData[i]->stringVars, sizeof(modelica_string)*data->modelData->nVariablesString);
#endif
  }

  TRACE_POP
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
  TRACE_PUSH
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
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
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  for(i=0; i<mData->nVariablesString; ++i)
  {
    sData->stringVars[i] = mmc_mk_scon_persist(mData->stringVarsData[i].attribute.start);
    debugStreamPrint(LOG_DEBUG, 0, "set String var %s = %s", mData->stringVarsData[i].info.name, MMC_STRINGDATA(sData->stringVars[i]));
  }
#endif
  TRACE_POP
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
  TRACE_PUSH
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
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
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  for(i=0; i<mData->nVariablesString; ++i)
  {
    mData->stringVarsData[i].attribute.start = MMC_STRINGDATA(sData->stringVars[i]);
    debugStreamPrint(LOG_DEBUG, 0, "String var %s(start=%s)", mData->stringVarsData[i].info.name, MMC_STRINGDATA(sData->stringVars[i]));
  }
#endif
  if (DEBUG_STREAM(LOG_DEBUG)) {
    messageClose(LOG_DEBUG);
  }

  TRACE_POP
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
  TRACE_PUSH
  SIMULATION_INFO *sInfo = data->simulationInfo;
  MODEL_DATA      *mData = data->modelData;
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
    debugStreamPrint(LOG_DEBUG, 0, "set String var %s = %s", mData->stringParameterData[i].info.name, MMC_STRINGDATA(sInfo->stringParameter[i]));
  }

  TRACE_POP
}

/*! \fn storeOldValues
 *
 *  This function copies states and time into their old-values for event handling.
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void storeOldValues(DATA *data)
{
  TRACE_PUSH
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  sInfo->timeValueOld = sData->timeValue;
  memcpy(sInfo->realVarsOld, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sInfo->integerVarsOld, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sInfo->booleanVarsOld, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  memcpy(sInfo->stringVarsOld, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
#endif
  TRACE_POP
}

/*! \fn restoreOldValues
 *
 *  This function copies old-values to current localData
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
void restoreOldValues(DATA *data)
{
  TRACE_PUSH
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  sData->timeValue = sInfo->timeValueOld;
  memcpy(sData->realVars, sInfo->realVarsOld, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sData->integerVars, sInfo->integerVarsOld, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sData->booleanVars, sInfo->booleanVarsOld,  sizeof(modelica_boolean)*mData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  memcpy( sData->stringVars, sInfo->stringVarsOld, sizeof(modelica_string)*mData->nVariablesString);
#endif
  TRACE_POP
}

/*! \fn storePreValues
 *
 *  This function copies all the values into their pre-values.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void storePreValues(DATA *data)
{
  TRACE_PUSH
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  memcpy(sInfo->realVarsPre, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sInfo->integerVarsPre, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sInfo->booleanVarsPre, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  memcpy(sInfo->stringVarsPre, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
#endif
  TRACE_POP
}

/*! \fn checkRelations
 *
 *  This function check if at least one backupRelation has changed
 *
 *  \param [ref] [data]
 *
 *  \author wbraun
 */
modelica_boolean checkRelations(DATA *data)
{
  TRACE_PUSH
  int i;

  for(i=0; i<data->modelData->nRelations; ++i)
    if(data->simulationInfo->relationsPre[i] != data->simulationInfo->relations[i])
      return 1;

  TRACE_POP
  return 0;
}

/*! \fn updateRelationsPre
 *
 *  This function stores a copy of relations into relationsPre.
 *
 *  \param [ref] [data]
 *
 *  \author lochel
 */
void updateRelationsPre(DATA *data)
{
  TRACE_PUSH

  memcpy(data->simulationInfo->relationsPre, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);

  TRACE_POP
}

/*! \fn storeRelations
 *
 *  This function stores a copy of relationPre. This is needed for the event
 *  iteration.
 *
 *  \param [out] [data]
 *
 *  \author lochel
 */
void storeRelations(DATA* data)
{
  TRACE_PUSH

  memcpy(data->simulationInfo->storedRelations, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);

  TRACE_POP
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
  TRACE_PUSH

  if(0 < data->modelData->nSamples)
  {
    infoStreamPrint(LOG_EVENTS, 0, "Next event time = %f", data->simulationInfo->nextSampleEvent);
    TRACE_POP
    return data->simulationInfo->nextSampleEvent;
  }

  TRACE_POP
  return -1;
}

/*! \fn initializeDataStruc
 *
 *  function initialize DATA structure
 *
 *  \param [ref] [data]
 *
 */
void initializeDataStruc(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  SIMULATION_DATA tmpSimData = {0};
  size_t i = 0;

  /* RingBuffer */
  data->simulationData = 0;
  data->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if(!data->simulationData)
  {
    throwStreamPrint(threadData, "Your memory is not strong enough for our ringbuffer!");
  }

  /* prepare RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    /* set time value */
    tmpSimData.timeValue = 0;
    /* buffer for all variable values */
    tmpSimData.realVars = (modelica_real*) calloc(data->modelData->nVariablesReal, sizeof(modelica_real));
    assertStreamPrint(threadData, 0 == data->modelData->nVariablesReal || 0 != tmpSimData.realVars, "out of memory");
    tmpSimData.integerVars = (modelica_integer*) calloc(data->modelData->nVariablesInteger, sizeof(modelica_integer));
    assertStreamPrint(threadData, 0 == data->modelData->nVariablesInteger || 0 != tmpSimData.integerVars, "out of memory");
    tmpSimData.booleanVars = (modelica_boolean*) calloc(data->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    assertStreamPrint(threadData, 0 == data->modelData->nVariablesBoolean || 0 != tmpSimData.booleanVars, "out of memory");
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
    tmpSimData.stringVars = (modelica_string*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesString * sizeof(modelica_string));
    assertStreamPrint(threadData, 0 == data->modelData->nVariablesString || 0 != tmpSimData.stringVars, "out of memory");
#endif
    appendRingData(data->simulationData, &tmpSimData);
  }
  data->localData = (SIMULATION_DATA**) omc_alloc_interface.malloc_uncollectable(SIZERINGBUFFER * sizeof(SIMULATION_DATA));
  memset(data->localData, 0, SIZERINGBUFFER * sizeof(SIMULATION_DATA));
  rotateRingBuffer(data->simulationData, 0, (void**) data->localData);

  /* create modelData var arrays */
  data->modelData->realVarsData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesReal * sizeof(STATIC_REAL_DATA));
  data->modelData->integerVarsData = (STATIC_INTEGER_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesInteger * sizeof(STATIC_INTEGER_DATA));
  data->modelData->booleanVarsData = (STATIC_BOOLEAN_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesBoolean * sizeof(STATIC_BOOLEAN_DATA));
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  data->modelData->stringVarsData = (STATIC_STRING_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesString * sizeof(STATIC_STRING_DATA));
#endif
  data->modelData->realParameterData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nParametersReal * sizeof(STATIC_REAL_DATA));
  data->modelData->integerParameterData = (STATIC_INTEGER_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nParametersInteger * sizeof(STATIC_INTEGER_DATA));
  data->modelData->booleanParameterData = (STATIC_BOOLEAN_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nParametersBoolean * sizeof(STATIC_BOOLEAN_DATA));
  data->modelData->stringParameterData = (STATIC_STRING_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nParametersString * sizeof(STATIC_STRING_DATA));

  data->modelData->realAlias = (DATA_REAL_ALIAS*) omc_alloc_interface.malloc_uncollectable(data->modelData->nAliasReal * sizeof(DATA_REAL_ALIAS));
  data->modelData->integerAlias = (DATA_INTEGER_ALIAS*) omc_alloc_interface.malloc_uncollectable(data->modelData->nAliasInteger * sizeof(DATA_INTEGER_ALIAS));
  data->modelData->booleanAlias = (DATA_BOOLEAN_ALIAS*) omc_alloc_interface.malloc_uncollectable(data->modelData->nAliasBoolean * sizeof(DATA_BOOLEAN_ALIAS));
  data->modelData->stringAlias = (DATA_STRING_ALIAS*) omc_alloc_interface.malloc_uncollectable(data->modelData->nAliasString * sizeof(DATA_STRING_ALIAS));

  data->modelData->samplesInfo = (SAMPLE_INFO*) omc_alloc_interface.malloc_uncollectable(data->modelData->nSamples * sizeof(SAMPLE_INFO));
  data->simulationInfo->nextSampleEvent = data->simulationInfo->startTime;
  data->simulationInfo->nextSampleTimes = (double*) calloc(data->modelData->nSamples, sizeof(double));
  data->simulationInfo->samples = (modelica_boolean*) calloc(data->modelData->nSamples, sizeof(modelica_boolean));

  data->modelData->clocksInfo = (CLOCK_INFO*) omc_alloc_interface.malloc_uncollectable(data->modelData->nClocks * sizeof(CLOCK_INFO));
  data->modelData->subClocksInfo = (SUBCLOCK_INFO*) omc_alloc_interface.malloc_uncollectable(data->modelData->nSubClocks * sizeof(SUBCLOCK_INFO));
  data->simulationInfo->clocksData = (CLOCK_DATA*) calloc(data->modelData->nClocks, sizeof(CLOCK_DATA));

  /* set default solvers for algebraic loops */
#if !defined(OMC_MINIMAL_RUNTIME)
  data->simulationInfo->nlsMethod = NLS_MIXED;
#else
  data->simulationInfo->nlsMethod = NLS_HOMOTOPY;
#endif
  data->simulationInfo->nlsLinearSolver = NLS_LS_DEFAULT;
  data->simulationInfo->lsMethod = LS_DEFAULT;
  data->simulationInfo->lssMethod = LSS_DEFAULT;
  data->simulationInfo->mixedMethod = MIXED_SEARCH;
  data->simulationInfo->newtonStrategy = NEWTON_DAMPED2;
  data->simulationInfo->nlsCsvInfomation = 0;
  data->simulationInfo->currentContext = CONTEXT_ALGEBRAIC;
  data->simulationInfo->jacobianEvals = data->modelData->nStates;

  data->simulationInfo->zeroCrossings = (modelica_real*) calloc(data->modelData->nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo->zeroCrossingsPre = (modelica_real*) calloc(data->modelData->nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo->zeroCrossingsBackup = (modelica_real*) calloc(data->modelData->nZeroCrossings, sizeof(modelica_real));
  data->simulationInfo->relations = (modelica_boolean*) calloc(data->modelData->nRelations, sizeof(modelica_boolean));
  data->simulationInfo->relationsPre = (modelica_boolean*) calloc(data->modelData->nRelations, sizeof(modelica_boolean));
  data->simulationInfo->storedRelations = (modelica_boolean*) calloc(data->modelData->nRelations, sizeof(modelica_boolean));
  data->simulationInfo->zeroCrossingIndex = (long*) malloc(data->modelData->nZeroCrossings*sizeof(long));
  data->simulationInfo->mathEventsValuePre = (modelica_real*) malloc(data->modelData->nMathEvents*sizeof(modelica_real));
  /* initialize zeroCrossingsIndex with corresponding index is used by events lists */
  for(i=0; i<data->modelData->nZeroCrossings; i++)
    data->simulationInfo->zeroCrossingIndex[i] = (long)i;

  /* buffer for old values */
  data->simulationInfo->realVarsOld = (modelica_real*) calloc(data->modelData->nVariablesReal, sizeof(modelica_real));
  data->simulationInfo->integerVarsOld = (modelica_integer*) calloc(data->modelData->nVariablesInteger, sizeof(modelica_integer));
  data->simulationInfo->booleanVarsOld = (modelica_boolean*) calloc(data->modelData->nVariablesBoolean, sizeof(modelica_boolean));
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  data->simulationInfo->stringVarsOld = (modelica_string*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesString * sizeof(modelica_string));
#endif
  /* buffer for all variable pre values */
  data->simulationInfo->realVarsPre = (modelica_real*) calloc(data->modelData->nVariablesReal, sizeof(modelica_real));
  data->simulationInfo->integerVarsPre = (modelica_integer*) calloc(data->modelData->nVariablesInteger, sizeof(modelica_integer));
  data->simulationInfo->booleanVarsPre = (modelica_boolean*) calloc(data->modelData->nVariablesBoolean, sizeof(modelica_boolean));
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  data->simulationInfo->stringVarsPre = (modelica_string*) omc_alloc_interface.malloc_uncollectable(data->modelData->nVariablesString * sizeof(modelica_string));
#endif
  /* buffer for all parameters values */
  data->simulationInfo->realParameter = (modelica_real*) calloc(data->modelData->nParametersReal, sizeof(modelica_real));
  data->simulationInfo->integerParameter = (modelica_integer*) calloc(data->modelData->nParametersInteger, sizeof(modelica_integer));
  data->simulationInfo->booleanParameter = (modelica_boolean*) calloc(data->modelData->nParametersBoolean, sizeof(modelica_boolean));
  data->simulationInfo->stringParameter = (modelica_string*) omc_alloc_interface.malloc_uncollectable(data->modelData->nParametersString * sizeof(modelica_string));
  /* buffer for inputs and outputs values */
  data->simulationInfo->inputVars = (modelica_real*) calloc(data->modelData->nInputVars, sizeof(modelica_real));
  data->simulationInfo->outputVars = (modelica_real*) calloc(data->modelData->nOutputVars, sizeof(modelica_real));
  data->simulationInfo->setcVars = (modelica_real*) calloc(data->modelData->nSetcVars, sizeof(modelica_real));

#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* buffer for mixed systems */
#if !defined(OMC_NUM_MIXED_SYSTEMS)
  if (data->modelData->nMixedSystems)
#endif
  {
    data->simulationInfo->mixedSystemData = (MIXED_SYSTEM_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nMixedSystems*sizeof(MIXED_SYSTEM_DATA));
    data->callback->initialMixedSystem(data->modelData->nMixedSystems, data->simulationInfo->mixedSystemData);
  }
#endif

#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* buffer for linear systems */
#if !defined(OMC_NUM_LINEAR_SYSTEMS)
  if (data->modelData->nLinearSystems)
#endif
  {
    data->simulationInfo->linearSystemData = (LINEAR_SYSTEM_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nLinearSystems*sizeof(LINEAR_SYSTEM_DATA));
    data->callback->initialLinearSystem(data->modelData->nLinearSystems, data->simulationInfo->linearSystemData);
  }
#endif

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* buffer for non-linear systems */
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS)
  if (data->modelData->nNonLinearSystems)
#endif
  {
    data->simulationInfo->nonlinearSystemData = (NONLINEAR_SYSTEM_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nNonLinearSystems*sizeof(NONLINEAR_SYSTEM_DATA));
    data->callback->initialNonLinearSystem(data->modelData->nNonLinearSystems, data->simulationInfo->nonlinearSystemData);
  }
#endif

#if !defined(OMC_NO_STATESELECTION)
  /* buffer for state sets */
  if (data->modelData->nStateSets) {
    data->simulationInfo->stateSetData = (STATE_SET_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nStateSets*sizeof(STATE_SET_DATA));
    data->callback->initializeStateSets(data->modelData->nStateSets, data->simulationInfo->stateSetData, data);
  }
#endif

  /* buffer for daeMode */
  data->simulationInfo->daeModeData = (DAEMODE_DATA*) omc_alloc_interface.malloc_uncollectable(sizeof(DAEMODE_DATA));
  data->callback->initializeDAEmodeData(data, data->simulationInfo->daeModeData);

  /* buffer for inline Data */
  data->simulationInfo->inlineData = (INLINE_DATA*) omc_alloc_interface.malloc_uncollectable(sizeof(INLINE_DATA));
  data->simulationInfo->inlineData->algVars = (modelica_real*) calloc(data->modelData->nStates, sizeof(modelica_real));
  data->simulationInfo->inlineData->algOldVars = (modelica_real*) calloc(data->modelData->nStates, sizeof(modelica_real));

  /* buffer for analytical jacobians */
  data->simulationInfo->analyticJacobians = (ANALYTIC_JACOBIAN*) omc_alloc_interface.malloc_uncollectable(data->modelData->nJacobians*sizeof(ANALYTIC_JACOBIAN));

  data->modelData->modelDataXml.functionNames = NULL;
  data->modelData->modelDataXml.equationInfo = NULL;

  /* buffer for external objects */
  data->simulationInfo->extObjs = NULL;
  data->simulationInfo->extObjs = (void**) calloc(data->modelData->nExtObjs, sizeof(void*));

  assertStreamPrint(threadData, 0 == data->modelData->nExtObjs || 0 != data->simulationInfo->extObjs, "error allocating external objects");

#if !defined(OMC_MINIMAL_LOGGING)
  /* initial chattering info */
  data->simulationInfo->chatteringInfo.numEventLimit = 100;
  data->simulationInfo->chatteringInfo.lastSteps = (int*) calloc(data->simulationInfo->chatteringInfo.numEventLimit, sizeof(int));
  data->simulationInfo->chatteringInfo.lastTimes = (modelica_real*) calloc(data->simulationInfo->chatteringInfo.numEventLimit, sizeof(double));
  data->simulationInfo->chatteringInfo.currentIndex = 0;
  data->simulationInfo->chatteringInfo.lastStepsNumStateEvents = 0;
  data->simulationInfo->chatteringInfo.messageEmitted = 0;
#endif

  /* initial call statistics */
  data->simulationInfo->callStatistics.functionODE = 0;
  data->simulationInfo->callStatistics.functionEvalDAE = 0;
  data->simulationInfo->callStatistics.updateDiscreteSystem = 0;
  data->simulationInfo->callStatistics.functionZeroCrossingsEquations = 0;
  data->simulationInfo->callStatistics.functionZeroCrossings = 0;
  data->simulationInfo->callStatistics.functionAlgebraics = 0;

  data->simulationInfo->lambda = 1.0;

  /* initial build calls terminal, initial */
  data->simulationInfo->terminal = 0;
  data->simulationInfo->initial = 0;
  data->simulationInfo->sampleActivated = 0;

  /*  switches used to evaluate the system */
  data->simulationInfo->solveContinuous = 0;
  data->simulationInfo->noThrowDivZero = 0;
  data->simulationInfo->discreteCall = 0;

  /* initialize model error code */
  data->simulationInfo->simulationSuccess = 0;

  /* initial delay */
#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0
  data->simulationInfo->delayStructure = (RINGBUFFER**)malloc(data->modelData->nDelayExpressions * sizeof(RINGBUFFER*));
  assertStreamPrint(threadData, 0 == data->modelData->nDelayExpressions || 0 != data->simulationInfo->delayStructure, "out of memory");

  for(i=0; i<data->modelData->nDelayExpressions; i++)
    data->simulationInfo->delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));
#endif

#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(data, threadData);
#endif

  /* allocate memory for sensitivity analysis */
  if (omc_flag[FLAG_IDAS])
  {
    data->simulationInfo->sensitivityParList = (int*) calloc(data->modelData->nSensitivityParamVars, sizeof(int));
    data->simulationInfo->sensitivityMatrix = (modelica_real*) calloc(data->modelData->nSensitivityVars-data->modelData->nSensitivityParamVars, sizeof(modelica_real));
    data->modelData->realSensitivityData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(data->modelData->nSensitivityVars * sizeof(STATIC_REAL_DATA));
  }


  TRACE_POP
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
  TRACE_PUSH
  size_t i = 0;
  int needToFree = !data->callback->read_input_fmu;

  /* prepare RingBuffer */
  for(i=0; i<SIZERINGBUFFER; i++)
  {
    SIMULATION_DATA* tmpSimData = (SIMULATION_DATA*) data->localData[i];
    /* free buffer for all variable values */
    free(tmpSimData->realVars);
    free(tmpSimData->integerVars);
    free(tmpSimData->booleanVars);
    omc_alloc_interface.free_uncollectable(tmpSimData->stringVars);
  }
  omc_alloc_interface.free_uncollectable(data->localData);
  freeRingBuffer(data->simulationData);

  /* free modelData var arrays */
  #define FREE_VARS(n,vars) { if (needToFree) { \
    for(i=0; i < data->modelData->n; i++) { \
      freeVarInfo(&((data->modelData->vars[i]).info)); \
    } \
  } \
  omc_alloc_interface.free_uncollectable(data->modelData->vars); }

  FREE_VARS(nVariablesReal,realVarsData)
  FREE_VARS(nVariablesInteger,integerVarsData)
  FREE_VARS(nVariablesBoolean,booleanVarsData)
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  FREE_VARS(nVariablesString,stringVarsData)
#endif
  FREE_VARS(nParametersReal,realParameterData)
  FREE_VARS(nParametersInteger,integerParameterData)
  FREE_VARS(nParametersBoolean,booleanParameterData)
  FREE_VARS(nParametersString,stringParameterData)
  FREE_VARS(nAliasReal,realAlias)
  FREE_VARS(nAliasInteger,integerAlias)
  FREE_VARS(nAliasBoolean,booleanAlias)
  FREE_VARS(nAliasString,stringAlias)

  omc_alloc_interface.free_uncollectable(data->modelData->samplesInfo);
  free(data->simulationInfo->nextSampleTimes);
  free(data->simulationInfo->samples);

  omc_alloc_interface.free_uncollectable(data->modelData->clocksInfo);
  omc_alloc_interface.free_uncollectable(data->modelData->subClocksInfo);

  /* free simulationInfo arrays */
  free(data->simulationInfo->zeroCrossings);
  free(data->simulationInfo->zeroCrossingsPre);
  free(data->simulationInfo->zeroCrossingsBackup);
  free(data->simulationInfo->relations);
  free(data->simulationInfo->relationsPre);
  free(data->simulationInfo->storedRelations);
  free(data->simulationInfo->zeroCrossingIndex);

  /* free buffer for old state variables */
  free(data->simulationInfo->realVarsOld);
  free(data->simulationInfo->integerVarsOld);
  free(data->simulationInfo->booleanVarsOld);
  omc_alloc_interface.free_uncollectable(data->simulationInfo->stringVarsOld);

  /* free buffer for all variable pre values */
  free(data->simulationInfo->realVarsPre);
  free(data->simulationInfo->integerVarsPre);
  free(data->simulationInfo->booleanVarsPre);
  omc_alloc_interface.free_uncollectable(data->simulationInfo->stringVarsPre);

  /* free buffer for all parameters values */
  free(data->simulationInfo->realParameter);
  free(data->simulationInfo->integerParameter);
  free(data->simulationInfo->booleanParameter);
  omc_alloc_interface.free_uncollectable(data->simulationInfo->stringParameter);

  if (data->modelData->nMixedSystems) {
    /* free buffer of mixed systems */
    omc_alloc_interface.free_uncollectable(data->simulationInfo->mixedSystemData);
  }

  if (data->modelData->nLinearSystems) {
    /* free buffer of linear systems */
    omc_alloc_interface.free_uncollectable(data->simulationInfo->linearSystemData);
  }

  if (data->modelData->nNonLinearSystems)
  {
    /* free buffer of non-linear systems */
    omc_alloc_interface.free_uncollectable(data->simulationInfo->nonlinearSystemData);
  }

  /* free buffer jacobians */
  omc_alloc_interface.free_uncollectable(data->simulationInfo->analyticJacobians);

  /* free buffer for state sets */
  omc_alloc_interface.free_uncollectable(data->simulationInfo->daeModeData);

  /* free inputs and output */
  free(data->simulationInfo->inputVars);
  free(data->simulationInfo->outputVars);
  free(data->simulationInfo->setcVars);

  /* free external objects buffer */
  free(data->simulationInfo->extObjs);

  /* free chattering info */
  free(data->simulationInfo->chatteringInfo.lastSteps);
  free(data->simulationInfo->chatteringInfo.lastTimes);

  /* free delay structure */
  for(i=0; i<data->modelData->nDelayExpressions; i++)
    freeRingBuffer(data->simulationInfo->delayStructure[i]);

  free(data->simulationInfo->delayStructure);

#if !defined(OMC_NO_STATESELECTION)
  /* free stateset data */
  freeStateSetData(data);
#endif
  if (data->modelData->nStateSets) {
    /* free buffer for state sets */
    omc_alloc_interface.free_uncollectable(data->simulationInfo->stateSetData);
  }

  /* free parameter sensitivities */
  if (omc_flag[FLAG_IDAS])
  {
    free(data->simulationInfo->sensitivityParList);
    free(data->simulationInfo->sensitivityMatrix);
    FREE_VARS(nSensitivityVars, realSensitivityData)
  }

  TRACE_POP
}

/* relation functions used in zero crossing detection
 * Less is for case LESS and GREATEREQ
 * Greater is for case LESSEQ and GREATER
 */

void setZCtol(double relativeTol)
{
  TRACE_PUSH

  /* lochel: force tolZC > 0 */
  tolZC = TOL_HYSTERESIS_ZEROCROSSINGS * fmax(relativeTol, MINIMAL_STEP_SIZE);
  infoStreamPrint(LOG_EVENTS_V, 0, "Set tolerance for zero-crossing hysteresis to: %e", tolZC);

  TRACE_POP
}

/* TODO: fix this */
modelica_boolean LessZC(double a, double b, modelica_boolean direction)
{
  double eps = tolZC * fmax(fabs(a), fabs(b)) + tolZC;
  return direction ? (a - b <= eps) : (a - b <= -eps);
}

modelica_boolean LessEqZC(double a, double b, modelica_boolean direction)
{
  return !GreaterZC(a, b, !direction);
}

/* TODO: fix this */
modelica_boolean GreaterZC(double a, double b, modelica_boolean direction)
{
  double eps = tolZC * fmax(fabs(a), fabs(b)) + tolZC;
  return direction ? (a - b >= -eps ) : (a - b >= eps);
}

modelica_boolean GreaterEqZC(double a, double b, modelica_boolean direction)
{
  return !LessZC(a, b, !direction);
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
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = (modelica_integer)floor(x);
  }

  value = data->simulationInfo->mathEventsValuePre[index];

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
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = x;
  }

  value = data->simulationInfo->mathEventsValuePre[index];

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
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = x;
  }

  value = data->simulationInfo->mathEventsValuePre[index];

  return (modelica_real)ceil(value);
}

/*! \fn _event_mod_integer
 *
 *  \param [in]  [x1]
 *  \param [in]  [x2]
 *  \param [in]  [index]
 *  \param [ref] [data]
 */
modelica_integer _event_mod_integer(modelica_integer x1, modelica_integer x2, modelica_integer index, DATA *data, threadData_t *threadData)
{
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = (modelica_real)x1;
    data->simulationInfo->mathEventsValuePre[index+1] = (modelica_real)x2;
  }

  return x1 - (x1 / x2) * x2;
}

/*! \fn _event_mod_real
 *
 *  \param [in]  [x1]
 *  \param [in]  [x2]
 *  \param [in]  [index]
 *  \param [ref] [data]
 */
modelica_real _event_mod_real(modelica_real x1, modelica_real x2, modelica_integer index, DATA *data, threadData_t *threadData)
{
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = x1;
    data->simulationInfo->mathEventsValuePre[index+1] = x2;
  }

  return x1 - floor(x1 / x2) * x2;
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
modelica_integer _event_div_integer(modelica_integer x1, modelica_integer x2, modelica_integer index, DATA *data, threadData_t *threadData)
{
  modelica_integer value1, value2;
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = (modelica_real)x1;
    data->simulationInfo->mathEventsValuePre[index+1] = (modelica_real)x2;
  }

  value1 = (modelica_integer)data->simulationInfo->mathEventsValuePre[index];
  value2 = (modelica_integer)data->simulationInfo->mathEventsValuePre[index+1];

  assertStreamPrint(threadData, value2 != 0, "event_div_integer failt at time %f because x2 is zero!", data->localData[0]->timeValue);
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
modelica_real _event_div_real(modelica_real x1, modelica_real x2, modelica_integer index, DATA *data, threadData_t *threadData)
{
  modelica_real value1, value2;
  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = x1;
    data->simulationInfo->mathEventsValuePre[index+1] = x2;
  }

  value1 = data->simulationInfo->mathEventsValuePre[index];
  value2 = data->simulationInfo->mathEventsValuePre[index+1];

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

int measure_time_flag=0;

const char *context_string[CONTEXT_MAX] = {
 "context UNKNOWN",
 "context ODE evaluation",
 "context algebraic evaluation",
 "context event search",
 "context jacobian evaluation",
 "context symbolica jacobian evaluation"
};

/*! \fn setContext
 *
 *  \param [ref] [data]
 *  \param [in]  [currentTime]
 *  \param [in]  [currentContext]
 *
 * Set current context in simulation info object
 */
void setContext(DATA* data, double* currentTime, int currentContext){
  data->simulationInfo->currentContextOld =  data->simulationInfo->currentContext;
  data->simulationInfo->currentContext =  currentContext;
  infoStreamPrint(LOG_SOLVER_CONTEXT, 0, "+++ Set context %s +++ at time %f", context_string[currentContext], *currentTime);
  if (currentContext == CONTEXT_JACOBIAN ||
      currentContext == CONTEXT_SYM_JACOBIAN)
  {
    data->simulationInfo->currentJacobianEval = 0;
  }
}

/*! \fn increaseJacContext
 *
 *  \param [ref] [data]
 *
 * Increase Jacobian column context in simulation info object
 */
void increaseJacContext(DATA* data){
  int currentContext = data->simulationInfo->currentContext;
  if (currentContext == CONTEXT_JACOBIAN ||
      currentContext == CONTEXT_SYM_JACOBIAN)
  {
    data->simulationInfo->currentJacobianEval++;
    infoStreamPrint(LOG_SOLVER_CONTEXT, 0, "+++ Increase Jacobian column context %s +++ to %d", context_string[currentContext], data->simulationInfo->currentJacobianEval);
  }
}

/*! \fn unsetContext
 *
 *  \param [ref] [data]
 *
 * Restores previous context in simulation info object
 */
void unsetContext(DATA* data){
  infoStreamPrint(LOG_SOLVER_CONTEXT, 0, "--- Unset context %s ---", context_string[data->simulationInfo->currentContext]);
  data->simulationInfo->currentContext =  data->simulationInfo->currentContextOld;
}
