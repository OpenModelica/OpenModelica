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
#include "spatialDistribution.h"
#include "../../meta/meta_modelica.h"

#ifdef USE_PARJAC
  #include <omp.h>
#endif

int maxEventIterations = 20;
double linearSparseSolverMaxDensity = DEFAULT_FLAG_LSS_MAX_DENSITY;
int linearSparseSolverMinSize = DEFAULT_FLAG_LSS_MIN_SIZE;
double nonlinearSparseSolverMaxDensity = DEFAULT_FLAG_NLSS_MAX_DENSITY;
int nonlinearSparseSolverMinSize = DEFAULT_FLAG_NLSS_MIN_SIZE;
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

/**
 * @brief Prints sparse structure.
 *
 * Use to print e.g. sparse Jacobian matrix.
 * Only prints if stream is active and sparse pattern is non NULL and of size > 0.
 *
 * @param sparsePattern   Matrix to print.
 * @param sizeRows        Number of rows of matrix.
 * @param sizeCols        Number of columns of matrix.
 * @param stream          Steam to print to.
 * @param name            Name of matrix.
 */
void printSparseStructure(SPARSE_PATTERN *sparsePattern, int sizeRows, int sizeCols, int stream, const char* name)
{
  /* Variables */
  unsigned int row, col, i, j;
  char *buffer;

  if (!ACTIVE_STREAM(stream))
  {
    return;
  }

  /* Catch empty sparsePattern */
  if (sparsePattern == NULL || sizeRows <= 0 || sizeCols <= 0)
  {
    infoStreamPrint(stream, 0, "No sparse structure available for \"%s\".", name);
    return;
  }

  buffer = (char*)omc_alloc_interface.malloc(sizeof(char)* 2*sizeCols + 4);

  infoStreamPrint(stream, 1, "Sparse structure of %s [size: %ux%u]", name, sizeRows, sizeCols);
  infoStreamPrint(stream, 0, "%u non-zero elements", sparsePattern->numberOfNonZeros);

  infoStreamPrint(stream, 1, "Transposed sparse structure (rows: states)");
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

/**
 * @brief Check if sparsity pattern can describe regular matrix.
 *
 * @param sparsePattern       Sparsity pattern.
 * @param nlsSize             size of non-linear loop / size of square matrix.
 * @param stream              Stream for logging.
 * @return modelica_boolean   False if sparsity pattern can't describe regular matrix, true otherwise.
 */
modelica_boolean sparsitySanityCheck(SPARSE_PATTERN *sparsePattern, int nlsSize, int stream)
{
  int i;
  char *colCheck;

  if (sparsePattern == NULL || nlsSize <= 0)
  {
    warningStreamPrint(stream, 0, "No sparse structure available.");
    return FALSE;
  }

  if (sparsePattern->numberOfNonZeros < nlsSize) {
    warningStreamPrint(stream, 0, "Sparsity pattern of %dx%d has ony %d non-zero elements.", nlsSize,nlsSize, sparsePattern->numberOfNonZeros);
    return FALSE;
  }

  /* check rows (or cols?) */
  for(i=1; i < nlsSize; i++)
  {
    if(sparsePattern->leadindex[i] == sparsePattern->leadindex[i-1]) {
      warningStreamPrint(stream, 0, "Sparsity pattern row %d has no non-zero elements.", i);
      return FALSE;
    }
  }

  /* check cols (or rows?) */
  colCheck = (char*) calloc(nlsSize, sizeof(char));

  for(i=0; i < sparsePattern->leadindex[nlsSize]; i++)
  {
    colCheck[sparsePattern->index[i]] = TRUE;
  }

  for(i=0; i < nlsSize; i++)
  {
    if(!colCheck[i]) {
      warningStreamPrint(stream, 0, "Sparsity pattern column %d has no non-zero elements.", i);
      free(colCheck);
      return FALSE;
    }
  }

  free(colCheck);
  return TRUE;
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

/*
* print information about ring buffer simulation data
*/
void printRingBufferSimulationData(RINGBUFFER *rb, DATA* data)
{
  TRACE_PUSH

  for (int i = 0; i < ringBufferLength(rb); i++)
  {
    messageClose(LOG_STDOUT);
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(rb, i);
    infoStreamPrint(LOG_STDOUT, 1, "Time: %g ", sdata->timeValue);

    infoStreamPrint(LOG_STDOUT, 1, "RingBuffer Real Variable");
    for (int j = 0; j < data->modelData->nVariablesReal; ++j)
    {
      infoStreamPrint(LOG_STDOUT, 0, "%d: %s = %g ", j+1, data->modelData->realVarsData[j].info.name, sdata->realVars[j]);
    }
    messageClose(LOG_STDOUT);

    infoStreamPrint(LOG_STDOUT, 1, "RingBuffer Integer Variable");
    for (int j = 0; j < data->modelData->nVariablesInteger; ++j)
    {
      infoStreamPrint(LOG_STDOUT, 0, "%d: %s = %li ", j+1, data->modelData->integerVarsData[j].info.name, sdata->integerVars[j]);
    }
    messageClose(LOG_STDOUT);

    infoStreamPrint(LOG_STDOUT, 1, "RingBuffer Boolean Variable");
    for(int j = 0; j < data->modelData->nVariablesBoolean; ++j)
    {
      infoStreamPrint(LOG_STDOUT, 0, "%d: %s = %s ", j+1, data->modelData->booleanVarsData[j].info.name, sdata->booleanVars[j] ? "true" : "false");
    }
    messageClose(LOG_STDOUT);
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

/**
 * @brief Get time of next sample event if one is defined.
 *
 * Function returns 0 if a time is defined and -1 otherwise.
 *
 * @param data                  Data
 * @param nextSampleEvent       On output time of next sample event.
 * @return int                  1 if a sample event is defined, 0 otherwise
 */
int getNextSampleTimeFMU(DATA *data, double *nextSampleEvent)
{
  TRACE_PUSH

  if(0 < data->modelData->nSamples)
  {
    infoStreamPrint(LOG_EVENTS, 0, "Next event time = %f", data->simulationInfo->nextSampleEvent);
    TRACE_POP
    *nextSampleEvent = data->simulationInfo->nextSampleEvent;
    return 1 /* TRUE */;
  }

  TRACE_POP
  return 0 /* FALSE */;
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
  lookupRingBuffer(data->simulationData, (void**) data->localData);

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

  if (data->modelData->nBaseClocks > 0) {
    data->simulationInfo->baseClocks = (BASECLOCK_DATA*) calloc(data->modelData->nBaseClocks, sizeof(BASECLOCK_DATA));
    data->simulationInfo->intvlTimers = allocList(sizeof(SYNC_TIMER));
  } else {
    data->simulationInfo->baseClocks = NULL;
    data->simulationInfo->intvlTimers = NULL;
  }

  data->simulationInfo->spatialDistributionData = allocSpatialDistribution(data->modelData->nSpatialDistributions);

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
  data->simulationInfo->mathEventsValuePre = (modelica_real*) malloc(data->modelData->nMathEvents*sizeof(modelica_real));
  data->simulationInfo->zeroCrossingIndex = (long*) malloc(data->modelData->nZeroCrossings*sizeof(long));
  /* initialize zeroCrossingsIndex with corresponding index is used by events lists */
  for(i=0; i<data->modelData->nZeroCrossings; i++)
    data->simulationInfo->zeroCrossingIndex[i] = (long)i;
  data->simulationInfo->states_left = (modelica_real*) malloc(data->modelData->nStates * sizeof(modelica_real));
  data->simulationInfo->states_right = (modelica_real*) malloc(data->modelData->nStates * sizeof(modelica_real));

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
  data->simulationInfo->datainputVars = (modelica_real*) calloc(data->modelData->ndataReconVars, sizeof(modelica_real));

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
  data->simulationInfo->noThrowAsserts = 0;
  data->simulationInfo->needToReThrow = 0;
  data->simulationInfo->discreteCall = 0;

  /* initialize model error code */
  data->simulationInfo->simulationSuccess = 0;

  /* initial delay */
#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0
  data->simulationInfo->delayStructure = (RINGBUFFER**)malloc(data->modelData->nDelayExpressions * sizeof(RINGBUFFER*));
  assertStreamPrint(threadData, 0 == data->modelData->nDelayExpressions || 0 != data->simulationInfo->delayStructure, "out of memory");

  for(i=0; i<data->modelData->nDelayExpressions; i++)
  {
    // TODO: Calculate how big ringbuffer should be for each delay expression
    data->simulationInfo->delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));
  }
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

  free(data->simulationInfo->baseClocks);
  freeList(data->simulationInfo->intvlTimers);
  data->simulationInfo->intvlTimers = NULL;

  freeSpatialDistribution(data->simulationInfo->spatialDistributionData, data->modelData->nSpatialDistributions);
  free(data->simulationInfo->spatialDistributionData);

  /* free simulationInfo arrays */
  free(data->simulationInfo->zeroCrossings);
  free(data->simulationInfo->zeroCrossingsPre);
  free(data->simulationInfo->zeroCrossingsBackup);
  free(data->simulationInfo->relations);
  free(data->simulationInfo->relationsPre);
  free(data->simulationInfo->storedRelations);
  free(data->simulationInfo->mathEventsValuePre);
  free(data->simulationInfo->zeroCrossingIndex);
  free(data->simulationInfo->states_left);
  free(data->simulationInfo->states_right);

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

  /* buffer for inline Data */
  free(data->simulationInfo->inlineData->algVars);
  free(data->simulationInfo->inlineData->algOldVars);
  omc_alloc_interface.free_uncollectable(data->simulationInfo->inlineData);

  /* free inputs and output */
  free(data->simulationInfo->inputVars);
  free(data->simulationInfo->outputVars);
  free(data->simulationInfo->setcVars);
  free(data->simulationInfo->datainputVars);

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

  /* Free model info xml data */
  modelInfoDeinit(&(data->modelData->modelDataXml));

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
  modelica_integer tmp = x1 % x2;
  return ((x2 > 0 && tmp < 0) || (x2 < 0 && tmp > 0)) ? (tmp + x2) : tmp;
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
  modelica_real value;

  if(data->simulationInfo->discreteCall && !data->simulationInfo->solveContinuous)
  {
    data->simulationInfo->mathEventsValuePre[index] = x1;
    data->simulationInfo->mathEventsValuePre[index+1] = x2;
  }

  value = _event_floor(x1 / x2, index+2, data);

  return x1 - value * x2;
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

  assertStreamPrint(threadData, value2 != 0, "event_div_integer failed at time %f because x2 is zero!", data->localData[0]->timeValue);
  return modelica_div_integer(value1, value2).quot;
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
