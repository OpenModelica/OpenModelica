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
#include "../arrayIndex.h"
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

/* Private function prototypes */
void* syncTimerListAlloc(const void* data);
void syncTimerListFree(void* data);
void syncTimerListCopy(void* dest, const void* src);

int maxEventIterations = 20;
double linearSparseSolverMaxDensity = DEFAULT_FLAG_LSS_MAX_DENSITY;
int linearSparseSolverMinSize = DEFAULT_FLAG_LSS_MIN_SIZE;
double nonlinearSparseSolverMaxDensity = DEFAULT_FLAG_NLSS_MAX_DENSITY;
int nonlinearSparseSolverMinSize = DEFAULT_FLAG_NLSS_MIN_SIZE;
double maxStepFactor = 1e12;
double newtonXTol = 1e-12;
double newtonFTol = 1e-12;
int newtonMaxSteps = DEFAULT_FLAG_NEWTON_MAX_STEPS;
int maxJacUpdate[4] = {10,3,1,1};
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
  int numEventIterations = 0;
  modelica_boolean discreteChanged = FALSE;
  modelica_boolean relationChanged = FALSE;
  data->simulationInfo->needToIterate = FALSE;

  data->simulationInfo->callStatistics.updateDiscreteSystem++;

  data->callback->function_updateRelations(data, threadData, 1);
  updateRelationsPre(data);
  storeRelations(data);

  data->callback->functionDAE(data, threadData);

  relationChanged = checkRelations(data);
  discreteChanged = checkForDiscreteChanges(data, threadData);
  while(discreteChanged || data->simulationInfo->needToIterate || relationChanged)
  {
    storePreValues(data);
    updateRelationsPre(data);

    printRelations(data, OMC_LOG_EVENTS_V);
    printZeroCrossings(data, OMC_LOG_EVENTS_V);

    data->callback->functionDAE(data, threadData);

    numEventIterations++;
    if(numEventIterations > maxEventIterations) {
      throwStreamPrint(threadData, "Simulation terminated due to too many, i.e. %d, event iterations.\nThis could either indicate an inconsistent system or an undersized limit of event iterations.\nThe limit of event iterations can be specified using the runtime flag '–%s=<value>'.", maxEventIterations, FLAG_NAME[FLAG_MAX_EVENT_ITERATIONS]);
    }

    relationChanged = checkRelations(data);
    discreteChanged = checkForDiscreteChanges(data, threadData);
  }
  storeRelations(data);

}

/*! \fn saveZeroCrossings
 *
 * Function saves all zero-crossing values
 *
 *  \param [ref] [data]
 */
void saveZeroCrossings(DATA* data, threadData_t *threadData)
{
  long i = 0;

  for(i=0;i<data->modelData->nZeroCrossings;i++)
    data->simulationInfo->zeroCrossingsPre[i] = data->simulationInfo->zeroCrossings[i];

  data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);
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
  setAllParamsToStart(data->simulationInfo, data->modelData);
  setAllVarsToStart(data->localData[0], data->simulationInfo, data->modelData);
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
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  if (!OMC_ACTIVE_STREAM(stream)) return;

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
}

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
  MODEL_DATA *mData = data->modelData;

  if (!OMC_ACTIVE_STREAM(stream)) return;

  infoStreamPrint(stream, 1, "parameter values");

  if (0 < mData->nParametersReal)
  {
    infoStreamPrint(stream, 1, "real parameters");
    for(i=0; i<mData->nParametersReal; ++i)
      infoStreamPrint(stream, 0, "[%ld] parameter Real %s(start=%s, fixed=%s) = %g", i+1,
                                 mData->realParameterData[i].info.name,
                                 real_vector_to_string(&mData->realParameterData[i].attribute.start, mData->realParameterData[i].dimension.numberOfDimensions == 0),
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

  if (!OMC_ACTIVE_STREAM(stream))
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

  if (!OMC_ACTIVE_STREAM(stream))
  {
    return;
  }

  infoStreamPrint(stream, 1, "status of relations at time=%.12g", data->localData[0]->timeValue);
  for(i=0; i<data->modelData->nRelations; i++)
  {
    infoStreamPrint(stream, 0, "[%ld] (pre: %s) %s = %s", i+1, data->simulationInfo->relationsPre[i] ? " true" : "false", data->simulationInfo->relations[i] ? " true" : "false", data->callback->relationDescription(i));
  }
  messageClose(stream);
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
  long i;

  if (!OMC_ACTIVE_STREAM(stream))
  {
    return;
  }

  infoStreamPrint(stream, 1, "status of zero crossings at time=%.12g", data->localData[0]->timeValue);
  for(i=0; i<data->modelData->nZeroCrossings; i++)
  {
    int *eq_indexes;
    const char *exp_str = data->callback->zeroCrossingDescription(i,&eq_indexes);
    infoStreamPrintWithEquationIndexes(stream, omc_dummyFileInfo, 0, eq_indexes, "[%ld] (pre: %2.g) %2.g = %s", i+1, data->simulationInfo->zeroCrossingsPre[i], data->simulationInfo->zeroCrossings[i], exp_str);
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
    memcpy(data->localData[i]->realVars, data->localData[i-1]->realVars, sizeof(modelica_real)*data->modelData->nVariablesReal);
    memcpy(data->localData[i]->integerVars, data->localData[i-1]->integerVars, sizeof(modelica_integer)*data->modelData->nVariablesInteger);
    memcpy(data->localData[i]->booleanVars, data->localData[i-1]->booleanVars, sizeof(modelica_boolean)*data->modelData->nVariablesBoolean);
    memcpy(data->localData[i]->stringVars, data->localData[i-1]->stringVars, sizeof(modelica_string)*data->modelData->nVariablesString);
  }
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
}

/*
* print information about ring buffer simulation data
*/
void printRingBufferSimulationData(RINGBUFFER *rb, DATA* data)
{
  for (int i = 0; i < ringBufferLength(rb); i++)
  {
    messageClose(OMC_LOG_STDOUT); // FIXME what does this belong to?
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(rb, i);
    infoStreamPrint(OMC_LOG_STDOUT, 1, "Time: %g ", sdata->timeValue);

    infoStreamPrint(OMC_LOG_STDOUT, 1, "RingBuffer Real Variable");
    for (int j = 0; j < data->modelData->nVariablesReal; ++j)
    {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "%d: %s = %g ", j+1, data->modelData->realVarsData[j].info.name, sdata->realVars[j]);
    }
    messageClose(OMC_LOG_STDOUT);

    infoStreamPrint(OMC_LOG_STDOUT, 1, "RingBuffer Integer Variable");
    for (int j = 0; j < data->modelData->nVariablesInteger; ++j)
    {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "%d: %s = %li ", j+1, data->modelData->integerVarsData[j].info.name, sdata->integerVars[j]);
    }
    messageClose(OMC_LOG_STDOUT);

    infoStreamPrint(OMC_LOG_STDOUT, 1, "RingBuffer Boolean Variable");
    for(int j = 0; j < data->modelData->nVariablesBoolean; ++j)
    {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "%d: %s = %s ", j+1, data->modelData->booleanVarsData[j].info.name, sdata->booleanVars[j] ? "true" : "false");
    }
    messageClose(OMC_LOG_STDOUT);
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
    memcpy(data->localData[i-1]->realVars, data->localData[i]->realVars, sizeof(modelica_real)*data->modelData->nVariablesReal);
    memcpy(data->localData[i-1]->integerVars, data->localData[i]->integerVars, sizeof(modelica_integer)*data->modelData->nVariablesInteger);
    memcpy(data->localData[i-1]->booleanVars, data->localData[i]->booleanVars, sizeof(modelica_boolean)*data->modelData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
    memcpy(data->localData[i-1]->stringVars, data->localData[i]->stringVars, sizeof(modelica_string)*data->modelData->nVariablesString);
#endif
  }
}

 /**
  * @brief Set all variables to their start attribute.
  *
  * @param simulationData Simulation data with variable start values to update.
  * @param simulationInfo Simulation info with array variable mapping to scalar
  *                       simulation data.
  * @param modelData      Model data with start attributes.
  */
void setAllVarsToStart(SIMULATION_DATA *simulationData, const SIMULATION_INFO *simulationInfo, const MODEL_DATA *modelData)
{
  long array_idx;

  for (array_idx = 0; array_idx < modelData->nVariablesRealArray; ++array_idx)
  {
    copy_real_array_data_mem(
      modelData->realVarsData[array_idx].attribute.start,
      &simulationData->realVars[simulationInfo->realVarsIndex[array_idx]]);
  }

  for (array_idx = 0; array_idx < modelData->nVariablesInteger; ++array_idx)
  {
    simulationData->integerVars[array_idx] = modelData->integerVarsData[array_idx].attribute.start;
  }

  for (array_idx = 0; array_idx < modelData->nVariablesBoolean; ++array_idx)
  {
    simulationData->booleanVars[array_idx] = modelData->booleanVarsData[array_idx].attribute.start;
  }

#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING > 0
  for (array_idx = 0; array_idx < modelData->nVariablesString; ++array_idx)
  {
    simulationData->stringVars[array_idx] = mmc_mk_scon_persist(modelData->stringVarsData[array_idx].attribute.start);
  }
#endif
}

/**
  * @brief Set all parameters to their start attribute.
  *
  * @param simulationInfo Simulation info with parameter start values to update
  *                       and array variable mapping to scalar representation.
  * @param modelData      Model data with start attributes.
  */
void setAllParamsToStart(SIMULATION_INFO *simulationInfo, const MODEL_DATA *modelData)
{
  long array_idx;

  for (array_idx = 0; array_idx < modelData->nParametersRealArray; ++array_idx)
  {
    copy_real_array_data_mem(
      modelData->realParameterData[array_idx].attribute.start,
      &simulationInfo->realParameter[simulationInfo->realParamsIndex[array_idx]]);
  }

  for (array_idx = 0; array_idx < modelData->nParametersInteger; ++array_idx)
  {
    simulationInfo->integerParameter[array_idx] = modelData->integerParameterData[array_idx].attribute.start;
  }

  for (array_idx = 0; array_idx < modelData->nParametersBoolean; ++array_idx)
  {
    simulationInfo->booleanParameter[array_idx] = modelData->booleanParameterData[array_idx].attribute.start;
  }

  for (array_idx = 0; array_idx < modelData->nParametersString; ++array_idx)
  {
    simulationInfo->stringParameter[array_idx] = modelData->stringParameterData[array_idx].attribute.start;
  }
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
  SIMULATION_DATA *sData = data->localData[0];
  MODEL_DATA      *mData = data->modelData;
  SIMULATION_INFO *sInfo = data->simulationInfo;

  memcpy(sInfo->realVarsPre, sData->realVars, sizeof(modelica_real)*mData->nVariablesReal);
  memcpy(sInfo->integerVarsPre, sData->integerVars, sizeof(modelica_integer)*mData->nVariablesInteger);
  memcpy(sInfo->booleanVarsPre, sData->booleanVars, sizeof(modelica_boolean)*mData->nVariablesBoolean);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  memcpy(sInfo->stringVarsPre, sData->stringVars, sizeof(modelica_string)*mData->nVariablesString);
#endif
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
  int i;

  for(i=0; i<data->modelData->nRelations; ++i)
    if(data->simulationInfo->relationsPre[i] != data->simulationInfo->relations[i])
      return 1;

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
  memcpy(data->simulationInfo->relationsPre, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);
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
  memcpy(data->simulationInfo->storedRelations, data->simulationInfo->relations, sizeof(modelica_boolean)*data->modelData->nRelations);
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
  if(0 < data->modelData->nSamples)
  {
    infoStreamPrint(OMC_LOG_EVENTS, 0, "Next event time = %f", data->simulationInfo->nextSampleEvent);
    *nextSampleEvent = data->simulationInfo->nextSampleEvent;
    return 1 /* TRUE */;
  }

  return 0 /* FALSE */;
}

/**
 * @brief Allocates static model data.
 *
 * Allocate memory for model data of variables, parameters, sensitivity
 * parameters and alias variables.
 * Won't allocate memory for dynamic memory inside struct.
 *
 * Free with `freeModelDataVars`.
 *
 * @param modelData   Pointer to model data.
 * @param allocAlias  If true allocate memory for `modelData->realAlias`, ... , `modelData->stringAlias`.
 *                    Alias variables aren't used in FMI C runtime.
 * @param threadData  Thread data for error handling, can be `NULL`.
 *
 */
void allocModelDataVars(MODEL_DATA* modelData, modelica_boolean allocAlias, threadData_t* threadData)
{
  // Variables
  modelData->realVarsData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nVariablesRealArray * sizeof(STATIC_REAL_DATA));
  assertStreamPrint(threadData, modelData->nVariablesRealArray == 0 || modelData->realVarsData != NULL, "Out of memory");

  modelData->integerVarsData = (STATIC_INTEGER_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nVariablesIntegerArray * sizeof(STATIC_INTEGER_DATA));
  assertStreamPrint(threadData, modelData->nVariablesIntegerArray == 0 || modelData->integerVarsData != NULL, "Out of memory");

  modelData->booleanVarsData = (STATIC_BOOLEAN_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nVariablesBooleanArray * sizeof(STATIC_BOOLEAN_DATA));
  assertStreamPrint(threadData, modelData->nVariablesBooleanArray == 0 || modelData->booleanVarsData != NULL, "Out of memory");

#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  modelData->stringVarsData = (STATIC_STRING_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nVariablesStringArray * sizeof(STATIC_STRING_DATA));
  assertStreamPrint(threadData, modelData->nVariablesStringArray == 0 || modelData->stringVarsData != NULL, "Out of memory");
#endif

  // Parameter
  modelData->realParameterData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nParametersRealArray * sizeof(STATIC_REAL_DATA));
  assertStreamPrint(threadData, modelData->nParametersRealArray == 0 || modelData->realParameterData != NULL, "Out of memory");

  modelData->integerParameterData = (STATIC_INTEGER_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nParametersIntegerArray * sizeof(STATIC_INTEGER_DATA));
  assertStreamPrint(threadData, modelData->nParametersIntegerArray == 0 || modelData->integerParameterData != NULL, "Out of memory");

  modelData->booleanParameterData = (STATIC_BOOLEAN_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nParametersBooleanArray * sizeof(STATIC_BOOLEAN_DATA));
  assertStreamPrint(threadData, modelData->nParametersBooleanArray == 0 || modelData->booleanParameterData != NULL, "Out of memory");

  modelData->stringParameterData = (STATIC_STRING_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nParametersStringArray * sizeof(STATIC_STRING_DATA));
  assertStreamPrint(threadData, modelData->nParametersStringArray == 0 || modelData->stringParameterData != NULL, "Out of memory");

  // Sensitivity
  modelData->realSensitivityData = (STATIC_REAL_DATA*) omc_alloc_interface.malloc_uncollectable(modelData->nSensitivityVars * sizeof(STATIC_REAL_DATA));
  assertStreamPrint(threadData, modelData->nSensitivityVars == 0 || modelData->realSensitivityData != NULL, "Out of memory");

  // Alias Variables
  // TODO: alias variables aren't used at all for FMUs.
  if (allocAlias) {
    modelData->realAlias = (DATA_REAL_ALIAS*) omc_alloc_interface.malloc_uncollectable(modelData->nAliasRealArray * sizeof(DATA_REAL_ALIAS));
    assertStreamPrint(threadData, modelData->nAliasRealArray == 0 || modelData->realAlias != NULL, "Out of memory");

    modelData->integerAlias = (DATA_INTEGER_ALIAS*) omc_alloc_interface.malloc_uncollectable(modelData->nAliasIntegerArray * sizeof(DATA_INTEGER_ALIAS));
    assertStreamPrint(threadData, modelData->nAliasIntegerArray == 0 || modelData->integerAlias != NULL, "Out of memory");

    modelData->booleanAlias = (DATA_BOOLEAN_ALIAS*) omc_alloc_interface.malloc_uncollectable(modelData->nAliasBooleanArray * sizeof(DATA_BOOLEAN_ALIAS));
    assertStreamPrint(threadData, modelData->nAliasBooleanArray == 0 || modelData->booleanAlias != NULL, "Out of memory");

    modelData->stringAlias = (DATA_STRING_ALIAS*) omc_alloc_interface.malloc_uncollectable(modelData->nAliasStringArray * sizeof(DATA_STRING_ALIAS));
    assertStreamPrint(threadData, modelData->nAliasStringArray == 0 || modelData->stringAlias != NULL, "Out of memory");
  }
  else {
    modelData->realAlias = NULL;
    modelData->integerAlias = NULL;
    modelData->booleanAlias = NULL;
    modelData->stringAlias = NULL;
  }
}

/**
 * @brief Free var info and var data.
 *
 * VAR_INFO strings get allocated in `read_var_info`.
 *
 * @param modelData   Pointer to model data.
 */
void freeModelDataVars(MODEL_DATA* modelData)
{
  unsigned int i;

  // Variables
  for(i=0; i < modelData->nVariablesReal; i++) {
    freeVarInfo(&modelData->realVarsData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->realVarsData);

  for(i=0; i < modelData->nVariablesInteger; i++) {
    freeVarInfo(&modelData->integerVarsData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->integerVarsData);

  for(i=0; i < modelData->nVariablesBoolean; i++) {
    freeVarInfo(&modelData->booleanVarsData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->booleanVarsData);

#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  for(i=0; i < modelData->nVariablesString; i++) {
    freeVarInfo(&modelData->stringVarsData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->stringVarsData);
#endif

  // Parameters
  for(i=0; i < modelData->nParametersReal; i++) {
    freeVarInfo(&modelData->realParameterData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->realParameterData);

  for(i=0; i < modelData->nParametersInteger; i++) {
    freeVarInfo(&modelData->integerParameterData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->integerParameterData);

  for(i=0; i < modelData->nParametersBoolean; i++) {
    freeVarInfo(&modelData->booleanParameterData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->booleanParameterData);

  for(i=0; i < modelData->nParametersString; i++) {
    freeVarInfo(&modelData->stringParameterData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->stringParameterData);

  // Sensitivity
  for(i=0; i < modelData->nSensitivityVars; i++) {
    freeVarInfo(&modelData->realSensitivityData[i].info);
  }
  omc_alloc_interface.free_uncollectable(modelData->realSensitivityData);

  // Alias Variables
  if (modelData->realAlias != NULL) {
    for(i=0; i < modelData->nAliasReal; i++) {
      freeVarInfo(&modelData->realAlias[i].info);
    }
    omc_alloc_interface.free_uncollectable(modelData->realAlias);
  }

  if (modelData->integerAlias != NULL) {
    for(i=0; i < modelData->nAliasInteger; i++) {
      freeVarInfo(&modelData->integerAlias[i].info);
    }
    omc_alloc_interface.free_uncollectable(modelData->integerAlias);
  }

  if (modelData->booleanAlias != NULL) {
    for(i=0; i < modelData->nAliasBoolean; i++) {
      freeVarInfo(&modelData->booleanAlias[i].info);
    }
    omc_alloc_interface.free_uncollectable(modelData->booleanAlias);
  }

  if (modelData->stringAlias != NULL) {
    for(i=0; i < modelData->nAliasString; i++) {
      freeVarInfo(&modelData->stringAlias[i].info);
    }
    omc_alloc_interface.free_uncollectable(modelData->stringAlias);
  }
}

/**
 * @brief Allocate memory for scalar attributes.
 *
 * Only allocate arrays of length 1 for the scalar case.
 * Used for scalar only FMI case.
 *
 * Memory is freed with `freeModelDataVars`.
 *
 * @param modelData   Pointer to model data.
 */
void scalarAllocArrayAttributes(MODEL_DATA* modelData) {
  size_t i;

  // Variables
  for(i = 0; i < modelData->nVariablesRealArray; i++) {
    simple_alloc_1d_real_array(&modelData->realVarsData[i].attribute.start, 1);
  }

  // Parameter
  for(i = 0; i < modelData->nParametersRealArray; i++) {
    simple_alloc_1d_real_array(&modelData->realParameterData[i].attribute.start, 1);
  }
}

 /*!
  * @brief Initialize `data` struct.
  *
  * Simulation data:
  *
  *   - Allocate ring buffer.
  *
  * Model data:
  *
  *   - Allocate variable and parameter arrays.
  *
  * Simulation info:
  *
  *   - Allocate clocks.
  *   - Allocate zero crossings.
  *   - Buffer for pre variables.
  *   - Buffer for linear and non-linear solvers.
  *
  * @param data         Partially initialized struct `DATA` to initialize.
  *                     Uses information about number of variables from `data->modelData`.
  * @param threadData   Used for error handling.
  */
void initializeDataStruc(DATA *data, threadData_t *threadData)
{
  SIMULATION_DATA tmpSimData = {0};
  size_t i = 0;

  /* RingBuffer */
  data->simulationData = 0;
  data->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  if (!data->simulationData) {
    throwStreamPrint(threadData, "Your memory is not strong enough for our ringbuffer!");
  }

  /* Index map for array variables */
  allocateArrayIndexMaps(data->modelData, data->simulationInfo, threadData);
  computeVarIndices(data->simulationInfo, data->modelData);

  data->modelData->nStates           = data->simulationInfo->realVarsIndex[data->modelData->nStatesArray];
  data->modelData->nVariablesReal    = data->simulationInfo->realVarsIndex[data->modelData->nVariablesRealArray];
  data->modelData->nVariablesInteger = data->simulationInfo->integerVarsIndex[data->modelData->nVariablesIntegerArray];
  data->modelData->nVariablesBoolean = data->simulationInfo->booleanVarsIndex[data->modelData->nVariablesBooleanArray];
  data->modelData->nVariablesString  = data->simulationInfo->stringVarsIndex[data->modelData->nVariablesStringArray];

  data->modelData->nParametersReal    = data->simulationInfo->realParamsIndex[data->modelData->nParametersRealArray];
  data->modelData->nParametersInteger = data->simulationInfo->integerParamsIndex[data->modelData->nParametersIntegerArray];
  data->modelData->nParametersBoolean = data->simulationInfo->booleanParamsIndex[data->modelData->nParametersBooleanArray];
  data->modelData->nParametersString  = data->simulationInfo->stringParamsIndex[data->modelData->nParametersStringArray];

  data->modelData->nAliasReal    = data->simulationInfo->realAliasIndex[data->modelData->nAliasRealArray];
  data->modelData->nAliasInteger = data->simulationInfo->integerAliasIndex[data->modelData->nAliasIntegerArray];
  data->modelData->nAliasBoolean = data->simulationInfo->booleanAliasIndex[data->modelData->nAliasBooleanArray];
  data->modelData->nAliasString  = data->simulationInfo->stringAliasIndex[data->modelData->nAliasStringArray];

  /* Reverse map for scalarized variables */
  allocateArrayReverseIndexMaps(data->modelData, data->simulationInfo, threadData);
  computeVarReverseIndices(data->simulationInfo, data->modelData);

  /* prepare RingBuffer */
  for (i = 0; i < SIZERINGBUFFER; i++) {
    /* set time value */
    /*
    * fix issue #11855, always take the startTime provided in modeldescription.xml
    * to handle models that have startTime > 0 (e.g) startTime = 0.2
    */
    tmpSimData.timeValue = data->simulationInfo->startTime;
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

  /* modelData vars, parameter and alias arrays are already allocated in read_input_xml */

  data->modelData->samplesInfo = (SAMPLE_INFO*) omc_alloc_interface.malloc_uncollectable(data->modelData->nSamples * sizeof(SAMPLE_INFO));
  data->simulationInfo->nextSampleEvent = data->simulationInfo->startTime;
  data->simulationInfo->nextSampleTimes = (double*) calloc(data->modelData->nSamples, sizeof(double));
  data->simulationInfo->samples = (modelica_boolean*) calloc(data->modelData->nSamples, sizeof(modelica_boolean));

  if (data->modelData->nBaseClocks > 0) {
    data->simulationInfo->baseClocks = (BASECLOCK_DATA*) calloc(data->modelData->nBaseClocks, sizeof(BASECLOCK_DATA));
    data->simulationInfo->intvlTimers = allocList(syncTimerListAlloc, syncTimerListFree, syncTimerListCopy);
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
  data->simulationInfo->setbVars = (modelica_real*) calloc(data->modelData->nSetbVars, sizeof(modelica_real));

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
  data->simulationInfo->analyticJacobians = (JACOBIAN*) omc_alloc_interface.malloc_uncollectable(data->modelData->nJacobians*sizeof(JACOBIAN));

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
    // can be estimated by lower bound delayMax/stepSize
    data->simulationInfo->delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));
  }
#endif

#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(data, threadData);
#endif
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

  if (needToFree) {
    freeModelDataVars(data->modelData);
  }

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

  freeArrayIndexMaps(data->simulationInfo);
  freeArrayReverseIndexMaps(data->simulationInfo);

  /* free buffer for old state variables */
  free(data->simulationInfo->realVarsOld);
  free(data->simulationInfo->integerVarsOld);
  free(data->simulationInfo->booleanVarsOld);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  omc_alloc_interface.free_uncollectable(data->simulationInfo->stringVarsOld);
#endif

  /* free buffer for all variable pre values */
  free(data->simulationInfo->realVarsPre);
  free(data->simulationInfo->integerVarsPre);
  free(data->simulationInfo->booleanVarsPre);
#if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
  omc_alloc_interface.free_uncollectable(data->simulationInfo->stringVarsPre);
#endif

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
  free(data->simulationInfo->setbVars);

  /* free external objects buffer */
  free(data->simulationInfo->extObjs);

  /* free chattering info */
  free(data->simulationInfo->chatteringInfo.lastSteps);
  free(data->simulationInfo->chatteringInfo.lastTimes);

  /* free delay structure */
  for(i=0; i<data->modelData->nDelayExpressions; i++)
    freeRingBuffer(data->simulationInfo->delayStructure[i]);

#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0
  free(data->simulationInfo->delayStructure);
#endif

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
  }

  /* Free model info xml data */
  modelInfoDeinit(&(data->modelData->modelDataXml));
}

/* relation functions used in zero crossing detection
 * Less is for case LESS and GREATEREQ
 * Greater is for case LESSEQ and GREATER
 */

void setZCtol(double relativeTol)
{
  /* lochel: force tolZC > 0 */
  tolZC = TOL_HYSTERESIS_ZEROCROSSINGS * fmax(relativeTol, MINIMAL_STEP_SIZE);
  infoStreamPrint(OMC_LOG_EVENTS_V, 0, "Set tolerance for zero-crossing hysteresis to: %e", tolZC);
}

/* TODO: fix this */
modelica_boolean LessZC(double a, double b, double a_nominal, double b_nominal, modelica_boolean direction)
{
  double eps = tolZC * (fmax(fabs(a), fabs(b)) + fmax(fabs(a_nominal), fabs(b_nominal)));
  return direction ? (a - b <= eps) : (a - b <= -eps);
}

modelica_boolean LessEqZC(double a, double b, double a_nominal, double b_nominal, modelica_boolean direction)
{
  return !GreaterZC(a, b, a_nominal, b_nominal, !direction);
}

/* TODO: fix this */
modelica_boolean GreaterZC(double a, double b, double a_nominal, double b_nominal, modelica_boolean direction)
{
  double eps = tolZC * (fmax(fabs(a), fabs(b)) + fmax(fabs(a_nominal), fabs(b_nominal)));
  return direction ? (a - b >= -eps ) : (a - b >= eps);
}

modelica_boolean GreaterEqZC(double a, double b, double a_nominal, double b_nominal, modelica_boolean direction)
{
  return !LessZC(a, b, a_nominal, b_nominal, !direction);
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


/**
 * @brief Allocate memory for syncTimerList elements.
 *
 * @param data      Unused.
 * @return void*    Allocated memory for LIST_NODE data.
 */
void* syncTimerListAlloc(const void* data) {
  void* newElem = malloc(sizeof(SYNC_TIMER));
  assertStreamPrint(NULL, newElem != NULL, "syncTimerListAlloc: Out of memory");
  return newElem;
}

/**
 * @brief Free memory allocated with syncTimerListAlloc.
 *
 * @param data      Void pointer, representing SYNC_TIMER.
 */
void syncTimerListFree(void* data) {
  free(data);
}

/**
 * @brief Copy data of syncTimerList elements.
 *
 * @param dest    Void pointer of destination data, representing SYNC_TIMER.
 * @param src     Void pointer of source data, representing SYNC_TIMER.
 */
void syncTimerListCopy(void* dest, const void* src) {
  memcpy(dest, src, sizeof(SYNC_TIMER));
}


int measure_time_flag=0;
