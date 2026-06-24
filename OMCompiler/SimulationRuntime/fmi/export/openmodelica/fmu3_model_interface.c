/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linkopings
 * universitet, Department of Computer and Information Science, SE-58183 Linkoping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

/*
 * FMI 3.0 model interface for OpenModelica generated FMUs.
 *
 * This file is self-contained and does NOT depend on fmu2_model_interface.* or
 * fmu_read_flags.*, so that the FMI 3.0 and FMI 2.0 interfaces can evolve
 * independently. It bundles its own copy of the model engine, the Co-Simulation
 * solver setup, and the FMI 3.0 C API layered on top.
 */

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include "fmu3_model_interface.h"
#include "../simulation/arrayIndex.h"
#include "../simulation/solver/initialization/initialization.h"
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
#ifdef WITH_SUNDIALS
#include "../simulation/solver/cvode_solver.h"
#endif
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
#include "../simulation/solver/nonlinearSystem.h"
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
#include "../simulation/solver/linearSystem.h"
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
#include "../simulation/solver/mixedSystem.h"
#endif
#include "../simulation/solver/delay.h"
#include "../simulation/solver/discrete_changes.h"
#include "../simulation/simulation_info_json.h"
#include "../simulation/simulation_input_xml.h"
#include "../simulation/solver/synchronous.h"
#include "../simulation/options.h"
#include "../util/simulation_options.h"
#include "../util/omc_error.h"

#include "../util/omc_mmap.h"
#include "../util/omc_file.h"

/* gets replaced by SimCodeMain.mo with the model specific ../<model>_FMU.h */
#include "fmu3_dummy_model_defines.h"

/* forward declarations for the inlined Co-Simulation solver setup (below) */
void parseFlags(SOLVER_INFO *solverInfo, const char *str);
int FMI3CS_initializeSolverData(ModelInstance* comp);
int FMI3CS_deInitializeSolverData(ModelInstance* comp);
 // get's replaced in SimCodeMain.mo

/*
DLLExport pthread_key_t fmu3_thread_data_key;
*/

// array of value references of states
#if NUMBER_OF_STATES > 0
fmi3ValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmi3ValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif

// ---------------------------------------------------------------------------
// FMI 3.0 logging helpers
// ---------------------------------------------------------------------------
/* Format a printf-style message and forward it to a raw fmi3LogMessageCallback
   (used before a ModelInstance exists, e.g. during instantiation). */
void omc_fmi3_logCallback(fmi3LogMessageCallback logMessage, fmi3InstanceEnvironment instanceEnvironment,
    fmi3Status status, const char* category, const char* message, ...)
{
  char buffer[2048];
  va_list args;
  if (!logMessage) {
    return;
  }
  va_start(args, message);
  vsnprintf(buffer, sizeof(buffer), message, args);
  va_end(args);
  logMessage(instanceEnvironment, status, category, buffer);
}

/* Format a printf-style message and forward it to the instance log callback.
   The FMI 3.0 logger expects a pre-formatted message (no varargs), so the
   formatting that the FMI 2.0 logger used to do is done here. */
void omc_fmi3_logMessage(ModelInstance* comp, fmi3Status status, int categoryIndex, const char* message, ...)
{
  char buffer[2048];
  va_list args;
  if (!comp || !comp->logMessage) {
    return;
  }
  va_start(args, message);
  vsnprintf(buffer, sizeof(buffer), message, args);
  va_end(args);
  comp->logMessage(comp->instanceEnvironment, status, logCategoriesNames[categoryIndex], buffer);
}

// ---------------------------------------------------------------------------
// Private helpers used below to validate function arguments
// ---------------------------------------------------------------------------
static fmi3Boolean isModelExchange(ModelInstance *comp)
{
  return (OMC_ME == comp->type);
}

static fmi3Boolean isCoSimulation(ModelInstance *comp)
{
  return (OMC_CS == comp->type);
}

const char* stateToString(ModelInstance *comp)
{
  if (isModelExchange(comp))
  {
    switch (comp->state)
    {
      case model_state_start_end:               return "model_state_start_end";
      case model_state_instantiated:            return "model_state_instantiated";
      case model_state_initialization_mode:     return "model_state_initialization_mode";
      case model_state_cs_step_complete:        return "model_state_cs_step_complete (invalid!)";
      case model_state_cs_step_in_progress:     return "model_state_cs_step_in_progress (invalid!)";
      case model_state_cs_step_failed:          return "model_state_cs_step_failed (invalid!)";
      case model_state_cs_step_canceled:        return "model_state_cs_step_canceled (invalid!)";
      case model_state_me_event_mode:           return "model_state_me_event_mode";
      case model_state_me_continuous_time_mode: return "model_state_me_continuous_time_mode";
      case model_state_terminated:              return "model_state_terminated";
      case model_state_error:                   return "model_state_error";
      case model_state_fatal:                   return "model_state_fatal";
    }
  }

  if (isCoSimulation(comp))
  {
    switch (comp->state)
    {
      case model_state_start_end:               return "model_state_start_end";
      case model_state_instantiated:            return "model_state_instantiated";
      case model_state_initialization_mode:     return "model_state_initialization_mode";
      case model_state_cs_step_complete:        return "model_state_cs_step_complete";
      case model_state_cs_step_in_progress:     return "model_state_cs_step_in_progress";
      case model_state_cs_step_failed:          return "model_state_cs_step_failed";
      case model_state_cs_step_canceled:        return "model_state_cs_step_canceled";
      case model_state_me_event_mode:           return "model_state_me_event_mode (invalid!)";
      case model_state_me_continuous_time_mode: return "model_state_me_continuous_time_mode (invalid!)";
      case model_state_terminated:              return "model_state_terminated";
      case model_state_error:                   return "model_state_error";
      case model_state_fatal:                   return "model_state_fatal";
    }
  }

  return "Unknown";
}

static fmi3Boolean invalidNumber(ModelInstance *comp, const char *func, const char *arg, int n, int nExpected)
{
  if (n != nExpected)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Invalid argument %s = %d. Expected %d.", func, arg, n, nExpected)
    return fmi3True;
  }
  return fmi3False;
}

static fmi3Boolean invalidState(ModelInstance *comp, const char *func, int meStates, int csStates)
{
  if (!comp)
    return fmi3True;

  if (isModelExchange(comp))
  {
    if (!(comp->state & meStates))
    {
      FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Illegal model exchange call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmi3True;
    }
  }

  if (isCoSimulation(comp))
  {
    if (!(comp->state & csStates))
    {
      FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Illegal co-simulation call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmi3True;
    }
  }

  return fmi3False;
}

static fmi3Boolean nullPointer(ModelInstance* comp, const char *func, const char *arg, const void *p)
{
  if (!p)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Invalid argument %s = NULL.", func, arg)
    return fmi3True;
  }
  return fmi3False;
}

static fmi3Boolean vrOutOfRange(ModelInstance *comp, const char *func, fmi3ValueReference vr, int end)
{
  if (vr >= end) {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Illegal value reference %u.", func, vr)
    return fmi3True;
  }
  return fmi3False;
}

static fmi3Status unsupportedFunction(ModelInstance *comp, const char *func)
{
  FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "%s: Function not implemented.", func)
  return fmi3Error;
}

/**
 * @brief Helper for macro FILTERED_LOG
 *
 * @param comp            Pointer to FMU component.
 * @param categoryIndex   Logging category index.
 * @return fmi3Boolean    Return `fmi3True` if logging category is enabled,
 *                        otherwise return `fmi3False`.
 */
fmi3Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex)
{
  if (categoryIndex < NUMBER_OF_CATEGORIES && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
    return fmi3True;
  }
  return fmi3False;
}

static void omc_assert_fmi_common(threadData_t *threadData, fmi3Status status, int categoryIndex, FILE_INFO info, const char *msg, va_list args)
{
  const char *str;
  ModelInstance* c = (ModelInstance*) threadData->localRoots[LOCAL_ROOT_FMI_DATA];
  GC_vasprintf(&str, msg, args);
  if (info.lineStart) {
    FILTERED_LOG(c, status, categoryIndex, "%s:%d: %s", info.filename, info.lineStart, str)
  } else {
    FILTERED_LOG(c, status, categoryIndex, "%s", str)
  }
}

static void omc_assert_fmi(threadData_t *threadData, FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
static void omc_assert_fmi(threadData_t *threadData, FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_fmi_common(threadData, fmi3Error, LOG_STATUSERROR, info, msg, args);
  va_end(args);
  MMC_THROW_INTERNAL();
}

static void omc_assert_fmi_warning(FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_fmi_common((threadData_t*)pthread_getspecific(mmc_thread_data_key), fmi3Warning, LOG_STATUSWARNING, info, msg, args);
  va_end(args);
}

// ---------------------------------------------------------------------------
// Private helpers functions
// ---------------------------------------------------------------------------
static inline void resetThreadData(ModelInstance* comp)
{
#if defined(OM_HAVE_PTHREADS)
  if (comp->threadDataParent) {
    pthread_setspecific(mmc_thread_data_key, comp->threadDataParent);
  }
#endif
}

static inline void setThreadData(ModelInstance* comp)
{
#if defined(OM_HAVE_PTHREADS)
  if (comp->threadDataParent) {
    pthread_setspecific(mmc_thread_data_key, comp->threadData);
  }
#endif
}

fmi3Status internalEventUpdate(ModelInstance* c, EventInfo* eventInfo)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  fmi3Float64 nextSampleEvent;
  fmi3Boolean nextSampleEventDefined;
  modelica_boolean nextTimerDefined;
  fmi3Float64 nextTimerActivationTime;
  int syncRet;

  if (nullPointer(comp, "internalEventUpdate", "eventInfo", eventInfo)) {
    return fmi3Error;
  }

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "internalEventUpdate: Start Event Update! Next Sample Event %g", eventInfo->nextEventTime)

  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 1)) {
      FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "internalEventUpdate: Need to iterate state values changed!")
      /* if new set is calculated reinit the solver */
      eventInfo->valuesOfContinuousStatesChanged = fmi3True;
    }
#endif

    /* store pre-values after events are handled, this will override pre values
     * soon and there is no chance of event triggering for conditons change(u) (i.e) u <> pre(u)
     *https://github.com/OpenModelica/OpenModelica/issues/13811
     */
    //storePreValues(comp->fmuData);

    /* activate sample event */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if (comp->fmuData->simulationInfo->nextSampleTimes[i] <= comp->fmuData->localData[0]->timeValue) {
        comp->fmuData->simulationInfo->samples[i] = 1;
        infoStreamPrint(LOG_EVENTS, 0, "[%ld] sample(%g, %g)", comp->fmuData->modelData->samplesInfo[i].index, comp->fmuData->modelData->samplesInfo[i].start, comp->fmuData->modelData->samplesInfo[i].interval);
      }
    }

    /* fix issue https://github.com/OpenModelica/OpenModelica/issues/12350
     * we need to update discreteSystem during event update, before evaluating functionDAE
    */
    updateDiscreteSystem(comp->fmuData, threadData);

    comp->fmuData->callback->functionDAE(comp->fmuData, comp->threadData);

    /* deactivate sample events */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if (comp->fmuData->simulationInfo->samples[i]) {
        comp->fmuData->simulationInfo->samples[i] = 0;
        comp->fmuData->simulationInfo->nextSampleTimes[i] += comp->fmuData->modelData->samplesInfo[i].interval;
      }
    }

    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if ((i == 0) || (comp->fmuData->simulationInfo->nextSampleTimes[i] < comp->fmuData->simulationInfo->nextSampleEvent)) {
        comp->fmuData->simulationInfo->nextSampleEvent = comp->fmuData->simulationInfo->nextSampleTimes[i];
      }
    }

    /* Handle clock timers */
    syncRet = handleTimersFMI(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, &nextTimerDefined, &nextTimerActivationTime);

    if (checkForDiscreteChanges(comp->fmuData, comp->threadData) || comp->fmuData->simulationInfo->needToIterate || checkRelations(comp->fmuData) || syncRet==2 ) {
      FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "internalEventUpdate: Need to iterate(discrete changes)!")
      eventInfo->newDiscreteStatesNeeded = fmi3True;
      eventInfo->valuesOfContinuousStatesChanged = fmi3True;
      eventInfo->terminateSimulation = fmi3False;
    } else {
      eventInfo->newDiscreteStatesNeeded = fmi3False;
      eventInfo->terminateSimulation = fmi3False;
    }
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "internalEventUpdate: newDiscreteStatesNeeded %s",eventInfo->newDiscreteStatesNeeded?"true":"false");


    /* TODO: check the event iteration for relation
     * in FMI import and export. This is an workaround,
     * since the iteration seem not starting.
     */
    storePreValues(comp->fmuData);
    updateRelationsPre(comp->fmuData);
    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);

    /* Get next event time */
    if (nextSampleEventDefined && !nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi3True;
      eventInfo->nextEventTime = nextSampleEvent;
    }
    else if (!nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi3True;
      eventInfo->nextEventTime = nextTimerActivationTime;
    }
    else if (nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi3True;
      eventInfo->nextEventTime = fmin(nextSampleEvent,nextTimerActivationTime);
    }
    else {
      if (eventInfo->nextEventTime <= comp->fmuData->localData[0]->timeValue) {
        eventInfo->nextEventTimeDefined = fmi3False;
      }
    }
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "internalEventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime)

    done=1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  if (done) {
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "internalEventUpdate: terminated by an assertion.")
  comp->_need_update = 1;
  return fmi3Error;
}


fmi3Status internalEventIteration(ModelInstance* c, EventInfo *eventInfo)
{
  fmi3Status status = fmi3OK;
  eventInfo->newDiscreteStatesNeeded = fmi3True;
  eventInfo->terminateSimulation     = fmi3False;
  while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation && status != fmi3Error) {
    status = internalEventUpdate((ModelInstance *)c, eventInfo);
  }
  return status;
}

/********************************************************************
 * Private helpers for (modelica_)string array handling             *
 ********************************************************************/

  /* size of array of strings is not known at compile-time!      */
  /* figure out total size by repeatedly scanning with strlen(). */
  /* this code relies on the assumption of 1 char = 1 byte.      */

size_t getStringArraySize(char *stringArray, int elements) {
    size_t totalSize = 0;
    char *currStr = stringArray;
    int currStrLen;
    for (int j = 0; j < elements; j++) {
        currStrLen = strlen(currStr) + 1;
        currStr   += currStrLen;
        totalSize += currStrLen;
    }
    return totalSize;
}

size_t copyStringArray(char* destination, char *stringArray, int elements) {
    size_t copiedBytes = 0;
    char *currStr = stringArray;
    int currStrLen;
    for (int j = 0; j < elements; j++) {
        currStrLen = strlen(currStr) + 1;
        memcpy(destination, currStr, currStrLen);
        currStr     += currStrLen;
        copiedBytes += currStrLen;
    }
    return copiedBytes;
}

/**
 * @brief Helper function for omcGetXXX to update the component if needed.
 *
 * @param comp          FMI component
 * @param func          Name of omcGetXXX function calling this function.
 * @return fmi3Status   Returns fmi3Error if an error was caught, fmi3OK otherwise.
 */
fmi3Status updateIfNeeded(ModelInstance *comp, const char *func)
{
  /* Variables */
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;
  int success = 0;

  if (comp->_need_update)
  {
    setThreadData(comp);
    MemPoolState mem_pool_state = omc_util_get_pool_state();

    /* TRY */
#if !defined(OMC_EMCC)
    MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
#endif

    if (model_state_initialization_mode == comp->state)
    {
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeSpatialDistribution(comp->fmuData, threadData);
      storePreValues(comp->fmuData);
    }
    comp->_need_update = 0;
    success = 1;

    /* CATCH */
#if !defined(OMC_EMCC)
    MMC_CATCH_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = old_jmp;
#endif

    omc_util_restore_pool_state(mem_pool_state);
    resetThreadData(comp);
    if (!success)
    {
      FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "%s: terminated by an assertion.", func)
      // TODO: Check if fmi3Error or fmi3Discard should be returned
      return fmi3Error;
    }
  }

  return fmi3OK;
}


/***************************************************
Common Functions
****************************************************/
fmi3Status omcSetDebugLogging(ModelInstance* c, fmi3Boolean loggingOn, size_t nCategories, const fmi3String categories[])
{
  int i, j;
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "omcSetDebugLogging", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_in_progress|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi3Error;

  comp->loggingOn = loggingOn;
  for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
    comp->logCategories[j] = fmi3False;
  }
  for (i = 0; i < nCategories; i++) {
    fmi3Boolean categoryFound = fmi3False;
    for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
      if (strcmp(logCategoriesNames[j], categories[i]) == 0) {
        comp->logCategories[j] = loggingOn;
        categoryFound = fmi3True;
        break;
      }
    }
    if (!categoryFound) {
      omc_fmi3_logMessage(comp, fmi3Warning, LOG_STATUSERROR,
          "logging category '%s' is not supported by model", categories[i]);
    }
  }

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetDebugLogging")
  return fmi3OK;
}

ModelInstance* omcInstantiate(fmi3String instanceName, OMC_FmuType fmuType, fmi3String fmuGUID, fmi3String fmuResourceLocation,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage, fmi3Boolean visible, fmi3Boolean loggingOn)
{
  /*
  TODO: We should set the interface, but we can't until it's no longer a global variable.
  * The problem is that we might overwrite the main simulation's copy of the interface...
  */
  threadData_t *threadDataParent = (threadData_t*) pthread_getspecific(mmc_thread_data_key);
  ModelInstance *comp;
  if (!logMessage) {
    return NULL;
  }
  if (0==threadDataParent) {
    /* We can only disable GC if the parent is not OM */
    omc_alloc_interface = omc_alloc_interface_pooled;
    /* TODO: omc_alloc_interface.malloc_uncollectable = calloc; // Note that the interface is wrong. Should pass threadData to all allocations instead, and have the interface in there. */
  }
  mmc_init_nogc();
  omc_alloc_interface.init();

  // ignoring arguments: fmuResourceLocation, visible
  if (!instanceName || strlen(instanceName) == 0) {
    omc_fmi3_logCallback(logMessage, instanceEnvironment, fmi3Error, "logStatusError", "omcInstantiate: Missing instance name.");
    return NULL;
  }
  if (strcmp(fmuGUID, MODEL_GUID) != 0) {
    omc_fmi3_logCallback(logMessage, instanceEnvironment, fmi3Error, "logStatusError", "omcInstantiate: Wrong GUID %s. Expected %s.", fmuGUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)calloc(1, sizeof(ModelInstance));
  if (comp) {
    DATA* fmudata = NULL;
    MODEL_DATA* modelData = NULL;
    SIMULATION_INFO* simInfo = NULL;
    threadData_t *threadData = NULL;
    int i;

    comp->state = model_state_start_end;
    comp->instanceName = (fmi3String)calloc(1 + strlen(instanceName), sizeof(char));
    comp->GUID = (fmi3String)calloc(1 + strlen(fmuGUID), sizeof(char));
    fmudata = (DATA *)calloc(1, sizeof(DATA));
    modelData = (MODEL_DATA *)calloc(1, sizeof(MODEL_DATA));
    simInfo = (SIMULATION_INFO *)calloc(1, sizeof(SIMULATION_INFO));
    fmudata->modelData = modelData;
    fmudata->simulationInfo = simInfo;

    threadData = (threadData_t *)calloc(1, sizeof(threadData_t));
    memset(threadData, 0, sizeof(threadData_t));
    /*
    pthread_key_create(&fmu3_thread_data_key,NULL);
    pthread_setspecific(fmu3_thread_data_key, threadData);
    */

    comp->threadData = threadData;
    comp->threadDataParent = threadDataParent;
    comp->fmuData = fmudata;
    threadData->localRoots[LOCAL_ROOT_FMI_DATA] = comp;
    if (!comp->fmuData) {
      omc_fmi3_logCallback(logMessage, instanceEnvironment, fmi3Error, "logStatusError", "omcInstantiate: Could not initialize the global data structure file.");
      return NULL;
    }
    // set all categories to on or off. omcSetDebugLogging should be called to choose specific categories.
    for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
      comp->logCategories[i] = loggingOn;
    }
  }

  if (!comp || !comp->instanceName || !comp->GUID) {
    omc_fmi3_logCallback(logMessage, instanceEnvironment, fmi3Error, "logStatusError", "omcInstantiate: Out of memory.");
    return NULL;
  }
#if defined(OM_HAVE_PTHREADS)
  pthread_setspecific(mmc_thread_data_key, comp->threadData);
#endif
  omc_assert = omc_assert_fmi;
  omc_assert_warning = omc_assert_fmi_warning;

  strcpy((char*)comp->instanceName, (const char*)instanceName);
  comp->type = fmuType;
  strcpy((char*)comp->GUID, (const char*)fmuGUID);
  comp->logMessage = logMessage;
  comp->instanceEnvironment = instanceEnvironment;
  comp->loggingOn = loggingOn;
  comp->state = model_state_instantiated;

  /* Add the resourcesDir */
  fmuResourceLocation = OpenModelica_parseFmuResourcePath(fmuResourceLocation);
  if (fmuResourceLocation) {
    comp->fmuData->modelData->resourcesDir = calloc(1 + strlen(fmuResourceLocation), sizeof(char));
    strcpy(comp->fmuData->modelData->resourcesDir, fmuResourceLocation);
    free((void*)fmuResourceLocation);
  } else {
    FILTERED_LOG(comp, fmi3OK, LOG_STATUSWARNING, "omcInstantiate: Ignoring unknown resource URI: %s", fmuResourceLocation)
  }

  /* initialize modelData */
  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  fmu3_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  /*
   * load the simulation settings before initializing the DataStruct for fmus
   * fix issue #11855, always take the startTime provided in modeldescription.xml
   * to handle model that have startTime > 0 (e.g) startTime = 0.2
   */
  comp->fmuData->callback->read_simulation_info(comp->fmuData->simulationInfo);
  allocModelDataVars(comp->fmuData->modelData, FALSE, comp->threadData);
  scalarAllocArrayAttributes(comp->fmuData->modelData);
  calculateAllScalarLength(comp->fmuData->modelData);

  /* setup model data with default start data */
  setDefaultStartValues(comp);
  initializeDataStruc(comp->fmuData, comp->threadData);

  setAllParamsToStart(comp->fmuData->simulationInfo, comp->fmuData->modelData);
  setAllVarsToStart(comp->fmuData->localData[0], comp->fmuData->simulationInfo, comp->fmuData->modelData);
  /* read_input_fmu sets the per-variable info and attribute values (parameter
     start values etc.). It must run AFTER initializeDataStruc/computeVarIndices
     has built the variable->global-array index maps, otherwise the start values
     it writes never reach simulationInfo->realParameter[realParamsIndex[...]]
     and parameters stay 0 (issue #15686). This mirrors fmu2_model_interface.c /
     fmu1_model_interface.c.inc (#15838). */
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData);


#if !defined(OMC_MINIMAL_METADATA)
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));
#endif

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeLinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* allocate memory for mixed system solvers */
  initializeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(comp->fmuData, comp->threadData);
#endif

  /* allocate memory for Jacobian */
  comp->_has_jacobian = 0;
  comp->fmiDerJac = NULL;
  if (comp->fmuData->callback->initialPartialFMIDER != NULL)
  {
    comp->fmiDerJac = (JACOBIAN*) calloc(1, sizeof(JACOBIAN));
    if (! comp->fmuData->callback->initialPartialFMIDER(comp->fmuData, comp->threadData, comp->fmiDerJac))
    {
      comp->_has_jacobian = 1;
    }
  }

  /* allocate memory for Jacobian during initialization DAE */
  comp->_has_jacobian_intialization = 0;
  comp->fmiDerJacInitialization = NULL;
  if (comp->fmuData->callback->initialPartialFMIDERINIT != NULL)
  {
    comp->fmiDerJacInitialization = (JACOBIAN*) calloc(1, sizeof(JACOBIAN));
    if (! comp->fmuData->callback->initialPartialFMIDERINIT(comp->fmuData, comp->threadData, comp->fmiDerJacInitialization))
    {
      comp->_has_jacobian_intialization = 1;
    }
  }

  // int cols = comp->fmiDerJac->sizeCols;
  // int rows = comp->fmiDerJac->sizeRows;
  // printf("\nFMIDER number of rows and colums");
  // printf("\nNumber of rows   : %i", rows);
  // printf("\nNumber of columns: %i", cols);
  // printf("\n");

  // int cols_ = comp->fmiDerJacInitialization->sizeCols;
  // int rows_ = comp->fmiDerJacInitialization->sizeRows;
  // printf("\nFMIDER INITIALIZATION number of rows and colums");
  // printf("\nNumber of rows   : %i", rows_);
  // printf("\nNumber of columns: %i", cols_);
  // printf("\n");

#if NUMBER_OF_STATES > 0
  comp->states = (fmi3Float64*)calloc(NUMBER_OF_STATES, sizeof(fmi3Float64));
  comp->states_der = (fmi3Float64*)calloc(NUMBER_OF_STATES, sizeof(fmi3Float64));
#else
  comp->states = NULL;
  comp->states_der = NULL;
#endif
#if NUMBER_OF_EVENT_INDICATORS > 0
  comp->event_indicators = (fmi3Float64*)calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi3Float64));
  comp->event_indicators_prev = (fmi3Float64*)calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi3Float64));
#else
  comp->event_indicators = NULL;
  comp->event_indicators_prev = NULL;
#endif
#if NUMBER_OF_REAL_INPUTS > 0
  comp->input_real_derivative = (fmi3Float64*)calloc(NUMBER_OF_REAL_INPUTS, sizeof(fmi3Float64));
#else
  comp->input_real_derivative = NULL;
#endif

  comp->_need_update = 1;

  /* Initialize solverInfo */
  if (OMC_CS == comp->type) {
    FMI3CS_initializeSolverData(comp);
  } else {
    comp->solverInfo = NULL;
  }

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcInstantiate: GUID=%s", fmuGUID)
  resetThreadData(comp);
  return comp;
}

void omcFreeInstance(ModelInstance* c)
{
  ModelInstance *comp = (ModelInstance *)c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  if (invalidState(comp, "omcFreeInstance", meStates, csStates))
    return;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcFreeInstance...")

  /* call external objects destructors */
  comp->fmuData->callback->callExternalObjectDestructors(comp->fmuData, comp->threadData);
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* free nonlinear system data */
  freeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* free mixed system data */
  freeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* free linear system data */
  freeLinearSystems(comp->fmuData, comp->threadData);
#endif
  /* free data struct */
  deInitializeDataStruc(comp->fmuData);     /* TODO: Use free inside deInitializeDataStruc to be FMI comform */

  /* Free jacobian data */
  if (comp->_has_jacobian == 1) {
    /* TODO: Use free insted of free,
     * but generated code uses malloc / calloc instead of comp->calloc */
    free(comp->fmiDerJac->seedVars); comp->fmiDerJac->seedVars = NULL;
    free(comp->fmiDerJac->resultVars); comp->fmiDerJac->resultVars = NULL;
    free(comp->fmiDerJac->tmpVars); comp->fmiDerJac->tmpVars = NULL;

    free(comp->fmiDerJac->sparsePattern->leadindex); comp->fmiDerJac->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJac->sparsePattern->index); comp->fmiDerJac->sparsePattern->index = NULL;
    free(comp->fmiDerJac->sparsePattern->colorCols); comp->fmiDerJac->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJac->sparsePattern); comp->fmiDerJac->sparsePattern = NULL;

    free(comp->fmiDerJac); comp->fmiDerJac=NULL;
  }


  /* Free jacobian data */
  if (comp->_has_jacobian_intialization == 1) {
    /* TODO: Use free insted of free,
     * but generated code uses malloc / calloc instead of comp->calloc */
    free(comp->fmiDerJacInitialization->seedVars); comp->fmiDerJacInitialization->seedVars = NULL;
    free(comp->fmiDerJacInitialization->resultVars); comp->fmiDerJacInitialization->resultVars = NULL;
    free(comp->fmiDerJacInitialization->tmpVars); comp->fmiDerJacInitialization->tmpVars = NULL;

    free(comp->fmiDerJacInitialization->sparsePattern->leadindex); comp->fmiDerJacInitialization->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->index); comp->fmiDerJacInitialization->sparsePattern->index = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->colorCols); comp->fmiDerJacInitialization->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern); comp->fmiDerJacInitialization->sparsePattern = NULL;

    free(comp->fmiDerJacInitialization); comp->fmiDerJacInitialization=NULL;
  }

  free(comp->states); comp->states = NULL;
  free(comp->states_der); comp->states_der = NULL;
  free(comp->event_indicators); comp->event_indicators = NULL;
  free(comp->event_indicators_prev); comp->event_indicators_prev = NULL;
  free(comp->input_real_derivative); comp->input_real_derivative = NULL;

  free(comp->fmuData->modelData->resourcesDir);
  if (comp->solverInfo) {
    FMI3CS_deInitializeSolverData(comp);
  }

  /* free simuation data */
  free(comp->fmuData->modelData);
  free(comp->fmuData->simulationInfo);

  /* free fmuData */
  free(comp->threadData);
  free(comp->fmuData);
  /* free instanceName & GUID */
  if (comp->instanceName) free((void*)comp->instanceName);
  if (comp->GUID) free((void*)comp->GUID);
  /* free comp */
  free(comp);
  free_memory_pool();
}

fmi3Status omcSetupExperiment(ModelInstance* c, fmi3Boolean toleranceDefined, fmi3Float64 tolerance, fmi3Float64 startTime, fmi3Boolean stopTimeDefined, fmi3Float64 stopTime)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "omcSetupExperiment", model_state_instantiated, model_state_instantiated))
    return fmi3Error;

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL,
    "omcSetupExperiment: toleranceDefined=%d tolerance=%g startTime=%g stopTimeDefined=%d stopTime=%g",
    toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime)

  comp->toleranceDefined = toleranceDefined;
  comp->tolerance = tolerance;
  comp->startTime = startTime;
  comp->stopTimeDefined = stopTimeDefined;
  comp->stopTime = stopTime;
  /* fix issue https://github.com/OpenModelica/OpenModelica/issues/12561
    update the startTime values provided by users (e.g) OMSimulator test.fmu --startTime=2.5
  */
  comp->fmuData->localData[0]->timeValue = startTime;
  return fmi3OK;
}

fmi3Status omcEnterInitializationMode(ModelInstance* c)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "omcEnterInitializationMode", model_state_instantiated, model_state_instantiated))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcEnterInitializationMode...")

  setZCtol(comp->tolerance); /* set zero-crossing tolerance */
  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);
  comp->state = model_state_initialization_mode;

  return fmi3OK;
}

fmi3Status omcExitInitializationMode(ModelInstance* c)
{
  fmi3Status res = fmi3Error;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  fmi3Float64 nextSampleEvent;
  fmi3Boolean nextSampleEventDefined;
  int done=0;

  threadData->currentErrorStage = ERROR_SIMULATION;
  if (invalidState(comp, "omcExitInitializationMode", model_state_initialization_mode, model_state_initialization_mode))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcExitInitializationMode...")

  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = threadData->simulationJumpBuffer;

  if (comp->_need_update)
  {
    if (initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0))
    {
      comp->state = model_state_error;
      resetThreadData(comp);
      FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "omcExitInitializationMode: failed")
      return fmi3Error;
    }
  }

  /* use defined stopTime, if stopTimeDefined is given to calculate the sample events beforehand.
   * TODO: when stopTime is not defined we use an arbitrary constant 100.0, maybe issue a warning
   */
  initSample(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, comp->stopTimeDefined ? comp->stopTime : 100.0 /* default stopTime */);
  /* overwrite old values due to an event */
  overwriteOldSimulationData(comp->fmuData);

  comp->eventInfo.terminateSimulation = fmi3False;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmi3True;

  /* get next event time (sample calls) */
  nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);
  if (nextSampleEventDefined)
  {
    comp->eventInfo.nextEventTimeDefined = fmi3True;
    comp->eventInfo.nextEventTime = nextSampleEvent;
    internalEventUpdate(comp, &(comp->eventInfo));
  }
  else
  {
    comp->eventInfo.nextEventTimeDefined = fmi3False;
  }
  res = fmi3OK;

  done = 1;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;

  if (!done)
  {
    FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "omcExitInitializationMode: terminated by an assertion.")
  }

  comp->state = isCoSimulation(comp) ? model_state_cs_step_complete : model_state_me_event_mode;
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcExitInitializationMode: succeed")
  return res;
}

/*
 * fmi3Status omcTerminate(ModelInstance* c);
 * Informs the FMU that the simulation run is terminated. After calling this function, the final
 * values of all variables can be inquired with the omcGetXXX(..) functions. It is not allowed
 * to call this function after one of the functions returned with a status flag of fmi3Error or
 * fmi3Fatal.
 *
 */
fmi3Status omcTerminate(ModelInstance* c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcTerminate", model_state_me_event_mode|model_state_me_continuous_time_mode, model_state_cs_step_complete|model_state_cs_step_failed))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcTerminate...")

  setThreadData(comp);
  comp->state = model_state_terminated;
  resetThreadData(comp);
  return fmi3OK;
}

/*!
 * Is called by the environment to reset the FMU after a simulation run. Before starting a new run, omcEnterInitializationMode has to be called.
 */
fmi3Status omcReset(ModelInstance* c)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "omcReset", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcReset")

  setThreadData(comp);
  /* Free modelData */
  if (!(comp->state & model_state_terminated)) {
    /* call external objects destructors */
    comp->fmuData->callback->callExternalObjectDestructors(comp->fmuData, comp->threadData);
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
    /* free nonlinear system data */
    freeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
    /* free mixed system data */
    freeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
    /* free linear system data */
    freeLinearSystems(comp->fmuData, comp->threadData);
#endif
    /* free data struct */
    deInitializeDataStruc(comp->fmuData);
  }

  /* Free CS simulator */
  if (comp->solverInfo) {
    FMI3CS_deInitializeSolverData(comp);
  }

  /* Initialize modelData */
  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  fmu3_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  comp->fmuData->callback->read_simulation_info(comp->fmuData->simulationInfo);
  initializeDataStruc(comp->fmuData, comp->threadData);

  /* reset model data with default start data */
  setDefaultStartValues(comp);
  setAllParamsToStart(comp->fmuData->simulationInfo, comp->fmuData->modelData);
  setAllVarsToStart(comp->fmuData->localData[0], comp->fmuData->simulationInfo ,comp->fmuData->modelData);
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData);
#if !defined(OMC_MINIMAL_METADATA)
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));
#endif

#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  /* allocate memory for non-linear system solvers */
  initializeLinearSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  /* allocate memory for mixed system solvers */
  initializeMixedSystems(comp->fmuData, comp->threadData);
#endif
#if !defined(OMC_NO_STATESELECTION)
  /* allocate memory for state selection */
  initializeStateSetJacobians(comp->fmuData, comp->threadData);
#endif

  /* Initialize solverInfo */
  if (OMC_CS == comp->type) {
    FMI3CS_initializeSolverData(comp);
  } else {
    comp->solverInfo = NULL;
  }

  comp->_need_update = 1;
  comp->state = model_state_instantiated;
  resetThreadData(comp);
  return fmi3OK;
}

fmi3Status omcGetReal(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, fmi3Float64 value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  // Model exchange
  // - initialization mode (2) for a variable with causality = "output", or continuous-time states or state derivatives
  // - event mode
  // - continuous-time mode
  // - terminated
  // - error (7) always, but retrieved values are usable for debugging only
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;

  // Co-simulation
  // - initialization mode (2) for a variable with causality = "output" or continuous-time states or state derivatives (if element <Derivatives> is present)
  // - stepComplete
  // - stepFailed (8) always, but if status is other than terminated, retrieved values are useable for debugging only
  // - stepCanceled (7) always, but retrieved values are usable for debugging only
  // - terminated
  // - error (7) always, but retrieved values are usable for debugging only
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  /* Check for valid call sequence */
  if (invalidState(comp, "omcGetReal", meStates, csStates))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetReal", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetReal", "value[]", value))
    return fmi3Error;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, "omcGetReal") != fmi3OK)
    return fmi3Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcGetReal", vr[i], NUMBER_OF_REALS)) {
      return fmi3Error;
    }
    value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetReal: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmi3OK;
}

fmi3Status omcGetInteger(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, fmi3Int32 value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "omcGetInteger", meStates, csStates))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetInteger", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetInteger", "value[]", value))
    return fmi3Error;

#if NUMBER_OF_INTEGERS > 0
  if (updateIfNeeded(comp, "omcGetInteger") != fmi3OK)
    return fmi3Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcGetInteger", vr[i], NUMBER_OF_INTEGERS)) {
      return fmi3Error;
    }
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetInteger: #i%u# = %d", vr[i], value[i])
  }
#endif
  return fmi3OK;
}

fmi3Status omcGetBoolean(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, fmi3Boolean value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "omcGetBoolean", meStates, csStates))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetBoolean", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetBoolean", "value[]", value))
    return fmi3Error;

#if NUMBER_OF_BOOLEANS > 0
  if (updateIfNeeded(comp, "omcGetBoolean") != fmi3OK)
    return fmi3Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcGetBoolean", vr[i], NUMBER_OF_BOOLEANS)) {
      return fmi3Error;
    }
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
  }
#endif
  return fmi3OK;
}

fmi3Status omcGetString(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, fmi3String value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "omcGetString", meStates, csStates))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcGetString", "vr[]", vr))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcGetString", "value[]", value))
    return fmi3Error;

#if NUMBER_OF_STRINGS > 0
  if (updateIfNeeded(comp, "omcGetString") != fmi3OK)
    return fmi3Error;

  for (i=0; i<nvr; i++)
  {
    if (vrOutOfRange(comp, "omcGetString", vr[i], NUMBER_OF_STRINGS))
      return fmi3Error;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetString: #s%u# = '%s'", vr[i], value[i])
  }
#endif
  return fmi3OK;
}

fmi3Status omcSetReal(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3Float64 value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  // Model exchange
  // - instantiated (1) for a variable with variability != "constant" that has initial = "exact" or "approx"
  // - initialization mode (3) for a variable with variability != "constant" that has initial = "exact", or causality = "input"
  // - event mode (4) for a variable with causality = "input", or (causality = "parameter" and variability = "tunable")
  // - continuous-time mode (5) for a variable with causality = "input" and variability = "continuous"
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode;

  // Co-simulation
  // - instantiated (1) for a variable with variability != "constant" that has initial = "exact" or "approx"
  // - initialization mode (3) for a variable with variability != "constant" that has initial = "exact", or causality = "input"
  // - stepComplete (6) for a variable with causality = "input" or (causality = "parameter" and variability = "tunable")
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "omcSetReal", meStates, csStates))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetReal", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetReal", "value[]", value))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetReal: nvr = %d", nvr)
  // no check whether setting the value is allowed in the current state
  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcSetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmi3Error;
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetReal: #r%d# = %.16g", vr[i], value[i])
    if (setReal(comp, vr[i], value[i]) != fmi3OK) // to be implemented by the includer of this file
      return fmi3Error;
  }
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcSetInteger(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3Int32 value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcSetInteger", meStates, csStates))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetInteger", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetInteger", "value[]", value))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetInteger: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcSetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmi3Error;
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetInteger: #i%d# = %d", vr[i], value[i])
    if (setInteger(comp, vr[i], value[i]) != fmi3OK) // to be implemented by the includer of this file
      return fmi3Error;
  }
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcSetBoolean(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3Boolean value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcSetBoolean", meStates, csStates))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcSetBoolean", "vr[]", vr))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcSetBoolean", "value[]", value))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetBoolean: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcSetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmi3Error;
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false")
    if (setBoolean(comp, vr[i], value[i]) != fmi3OK) // to be implemented by the includer of this file
      return fmi3Error;
  }
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcSetString(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3String value[])
{
  int i, n;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcSetString", meStates, csStates))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcSetString", "vr[]", vr))
    return fmi3Error;
  if (nvr>0 && nullPointer(comp, "omcSetString", "value[]", value))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetString: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcSetString", vr[i], NUMBER_OF_STRINGS))
      return fmi3Error;
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetString: #s%d# = '%s'", vr[i], value[i])
    if (setString(comp, vr[i], value[i]) != fmi3OK) // to be implemented by the includer of this file
      return fmi3Error;
  }
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcFreeFMUstate(ModelInstance* c, fmi3FMUState* FMUstate);

fmi3Status omcGetFMUstate(ModelInstance* c, fmi3FMUState* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcGetFMUstate", meStates, csStates))
    return fmi3Error;

  INTERNAL_FMU_STATE* internal_state = (INTERNAL_FMU_STATE*) calloc(1, sizeof(INTERNAL_FMU_STATE));
  internal_state->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));

  DATA* fmudata = (DATA *) comp->fmuData;

  /* prepare RingBuffer, by allocating memory for real Vars
   * copy the ring buffer data to INTERNAL_FMU_STATE
  */
  SIMULATION_DATA tmpSimData = {0};
  for (int i = 0; i < ringBufferLength(fmudata->simulationData); i++)
  {
    tmpSimData.timeValue = fmudata->localData[i]->timeValue;
    /* allocate memory for all Real variables */
    tmpSimData.realVars = (modelica_real *)calloc(fmudata->modelData->nVariablesReal, sizeof(modelica_real));
    memcpy(tmpSimData.realVars, fmudata->localData[i]->realVars, sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    /* allocate memory for all Integer variables */
    tmpSimData.integerVars = (modelica_integer*)calloc(fmudata->modelData->nVariablesInteger, sizeof(modelica_integer));
    memcpy(tmpSimData.integerVars, fmudata->localData[i]->integerVars, sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    /* allocate memory for all boolean variables */
    tmpSimData.booleanVars = (modelica_boolean*)calloc(fmudata->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    memcpy(tmpSimData.booleanVars, fmudata->localData[i]->booleanVars, sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    /* allocate memory for all string variables */
    #if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
      tmpSimData.stringVars = (modelica_string*) omc_alloc_interface.malloc_uncollectable(fmudata->modelData->nVariablesString * sizeof(modelica_string));
      memcpy(tmpSimData.stringVars, fmudata->localData[i]->stringVars, sizeof(modelica_string)*fmudata->modelData->nVariablesString);
    #endif
    appendRingData(internal_state->simulationData, &tmpSimData);
  }

  // copy real parameter variables
  internal_state->realParameter = (modelica_real*)calloc(fmudata->modelData->nParametersReal, sizeof(modelica_real));
  for (int i = 0; i < fmudata->modelData->nParametersReal; ++i)
  {
    modelica_real *start = (modelica_real *) &fmudata->modelData->realParameterData[i].attribute.start.data;
    internal_state->realParameter[i] = start[0];
    // infoStreamPrint(LOG_STDOUT, 0, "Copy Real parameter %s = %g", fmudata->modelData->realParameterData[i].info.name, internal_state->realParameters[i]);
  }

  // copy Integer parameter variables
  internal_state->integerParameter = (modelica_integer*)calloc(fmudata->modelData->nParametersInteger, sizeof(modelica_integer));
  for (int i = 0; i < fmudata->modelData->nParametersInteger; ++i)
  {
    internal_state->integerParameter[i] = fmudata->modelData->integerParameterData[i].attribute.start;
    // infoStreamPrint(LOG_STDOUT, 0, "Copy Integer parameter %s = %ld", fmudata->modelData->integerParameterData[i].info.name, internal_state->integerParameters[i]);
  }

  // copy Boolean parameter variables
  internal_state->booleanParameter = (modelica_boolean*)calloc(fmudata->modelData->nParametersBoolean, sizeof(modelica_boolean));
  for (int i = 0; i < fmudata->modelData->nParametersBoolean; ++i)
  {
    internal_state->booleanParameter[i] = fmudata->modelData->booleanParameterData[i].attribute.start;
    //infoStreamPrint(LOG_STDOUT, 0, "copy Boolean parameter %s = %s", fmudata->modelData->booleanParameterData[i].info.name, internal_state->booleanParameters[i] ? "true" : "false");
  }

  // copy String parameter variables
  internal_state->stringParameter = (modelica_string*) omc_alloc_interface.malloc_uncollectable(fmudata->modelData->nParametersString * sizeof(modelica_string));
  for (int i = 0; i < fmudata->modelData->nParametersString; ++i)
  {
    internal_state->stringParameter[i] = fmudata->modelData->stringParameterData[i].attribute.start;
    //infoStreamPrint(LOG_STDOUT, 0, "copy String parameter %s = %s", fmudata->modelData->stringParameterData[i].info.name, MMC_STRINGDATA(internal_state->stringParameters[i]));
  }

  //infoRingBuffer( fmudata->simulationData);
  //printRingBufferSimulationData(fmudata->simulationData, fmudata); // original ringBuffer data
  //printRingBufferSimulationData(internal_state->simulationData, fmudata); // copied ringBuffer data

  /* release previous fmu state if existent */
  /* TODO: ideally, previous state's memory should be re-used instead of re-allocation */
  if (*FMUstate != NULL) omcFreeFMUstate(c, FMUstate);

  // return the fmu state
  *FMUstate = (fmi3FMUState) internal_state;
  return fmi3OK;
}

fmi3Status omcSetFMUstate(ModelInstance* c, fmi3FMUState FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcGetFMUstate", meStates, csStates))
    return fmi3Error;

  INTERNAL_FMU_STATE * internal_state = (INTERNAL_FMU_STATE *) FMUstate;
  DATA* fmudata = (DATA *) comp->fmuData;

  //printRingBufferSimulationData(internal_state->simulationData, fmudata); // copied ringBuffer data

  // override the SIMULATION_DATA with INTERNAL_FMU_STATE
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++)
  {
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    fmudata->localData[i]->timeValue = sdata->timeValue;
    memcpy(fmudata->localData[i]->realVars, sdata->realVars, sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    memcpy(fmudata->localData[i]->integerVars, sdata->integerVars, sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    memcpy(fmudata->localData[i]->booleanVars, sdata->booleanVars, sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    memcpy(fmudata->localData[i]->stringVars, sdata->stringVars, sizeof(modelica_string)*fmudata->modelData->nVariablesString);
  }

  // override realParameter data
  for (int i = 0; i < fmudata->modelData->nParametersReal; i++)
  {
    fmudata->simulationInfo->realParameter[i] = internal_state->realParameter[i];
  }
  // override integerParameter data
  for (int i = 0; i < fmudata->modelData->nParametersInteger; i++)
  {
    fmudata->simulationInfo->integerParameter[i] = internal_state->integerParameter[i];
  }
  // override booleanParameter data
  for (int i = 0; i < fmudata->modelData->nParametersBoolean; i++)
  {
    fmudata->simulationInfo->booleanParameter[i] = internal_state->booleanParameter[i];
  }
  // override stringParameter data
  for (int i = 0; i < fmudata->modelData->nParametersString; i++)
  {
    fmudata->simulationInfo->stringParameter[i] = internal_state->stringParameter[i];
  }

  return fmi3OK;
}

fmi3Status omcFreeFMUstate(ModelInstance* c, fmi3FMUState* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_terminated;

  if (invalidState(comp, "omcFreeFMUstate", meStates, csStates))
    return fmi3Error;

  if (*FMUstate)
  {
    INTERNAL_FMU_STATE* internal_state = (INTERNAL_FMU_STATE*) *FMUstate;
    // free the SIMULATION_DATA variable buffers
    for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++)
    {
      SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
      free(sdata->realVars);
      free(sdata->integerVars);
      free(sdata->booleanVars);
      free(sdata->stringVars);
    }
    freeRingBuffer(internal_state->simulationData);
    free(internal_state->realParameter);
    free(internal_state->integerParameter);
    free(internal_state->booleanParameter);
    free(internal_state->stringParameter);
    free(*FMUstate);
    *FMUstate = NULL;
  }
  return fmi3OK;
}

fmi3Status omcSerializedFMUstateSize(ModelInstance* c, fmi3FMUState FMUstate, size_t *size)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  DATA *fmudata = (DATA *) comp->fmuData;
  INTERNAL_FMU_STATE *internal_state = (INTERNAL_FMU_STATE *) FMUstate;

  size_t stateSize = 0;

  /* space for ringbuffer / simulation data contents */
  stateSize += ringBufferLength(internal_state->simulationData)    /* timeValue */
                   * sizeof(modelica_real);
  stateSize += ringBufferLength(internal_state->simulationData)    /* realVars */
                   * fmudata->modelData->nVariablesReal
                   * sizeof(modelica_real);
  stateSize += ringBufferLength(internal_state->simulationData)    /* integerVars */
                   * fmudata->modelData->nVariablesInteger
                   * sizeof(modelica_integer);
  stateSize += ringBufferLength(internal_state->simulationData)    /* booleanVars */
                   * fmudata->modelData->nVariablesBoolean
                   * sizeof(modelica_boolean);
                                                            /* stringVars */
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++) {
    SIMULATION_DATA *sdata = (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    stateSize += getStringArraySize((char *)(sdata->stringVars),
                                    fmudata->modelData->nVariablesString);
  }

  /* space for model parameters */
  stateSize += fmudata->modelData->nParametersReal * sizeof(modelica_real);
  stateSize += fmudata->modelData->nParametersInteger * sizeof(modelica_integer);
  stateSize += fmudata->modelData->nParametersBoolean * sizeof(modelica_boolean);
  stateSize += getStringArraySize((char *)(internal_state->stringParameter),
                                  fmudata->modelData->nParametersString);

  *size = stateSize;
  return fmi3OK;
}

fmi3Status omcSerializeFMUstate(ModelInstance* c, fmi3FMUState FMUstate, fmi3Byte serializedState[], size_t size)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  DATA *fmudata = (DATA *) comp->fmuData;
  INTERNAL_FMU_STATE *internal_state = (INTERNAL_FMU_STATE *) FMUstate;

  /* assumption sizeof(fmi3Byte) == sizeof(char) */
  /* probably true for most modern platforms     */
  fmi3Byte *serialVec = serializedState;

  fmi3Byte *currElement = serialVec;
  char *currStr;
  int currStrLen;
  for (int i = 0; i < ringBufferLength(internal_state->simulationData); i++) {
    SIMULATION_DATA *sdata =
                        (SIMULATION_DATA *)getRingData(internal_state->simulationData, i);
    memcpy(currElement, &(sdata->timeValue), sizeof(modelica_real));
    currElement += sizeof(modelica_real);
    memcpy(currElement, sdata->realVars,
                        sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    currElement += sizeof(modelica_real)*fmudata->modelData->nVariablesReal;
    memcpy(currElement, sdata->integerVars,
                        sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    currElement += sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger;
    memcpy(currElement, sdata->booleanVars,
                        sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    currElement += sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean;

    currElement += copyStringArray( (char *)currElement, (char *)(sdata->stringVars),
                                    fmudata->modelData->nVariablesString);
  }
  memcpy(currElement, internal_state->realParameter,
                      sizeof(modelica_real)*fmudata->modelData->nParametersReal);
  currElement += sizeof(modelica_real)*fmudata->modelData->nParametersReal;
  memcpy(currElement, internal_state->integerParameter,
                      sizeof(modelica_integer)*fmudata->modelData->nParametersInteger);
  currElement += sizeof(modelica_integer)*fmudata->modelData->nParametersInteger;
  memcpy(currElement, internal_state->booleanParameter,
                      sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean);
  currElement += sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean;
  currElement += copyStringArray( (char *)currElement, (char *)(internal_state->stringParameter),
                                  fmudata->modelData->nParametersString);

  return fmi3OK;
}

fmi3Status omcDeSerializeFMUstate(ModelInstance* c, const fmi3Byte serializedState[], size_t size, fmi3FMUState* FMUstate)
{
  /* portable serialization is tricky. for now only x86_64 tested!          */
  /* TODO: make serialization format architecture- & endianness-independent */

  ModelInstance *comp = (ModelInstance *) c;
  INTERNAL_FMU_STATE *internal_state =
            (INTERNAL_FMU_STATE *) calloc(1, sizeof(INTERNAL_FMU_STATE));
  internal_state->simulationData = allocRingBuffer(SIZERINGBUFFER, sizeof(SIMULATION_DATA));
  DATA *fmudata = (DATA *) comp->fmuData;

  fmi3Byte *currElement = (fmi3Byte *) serializedState;

  SIMULATION_DATA tmpSimData = {0};
  for (int i = 0; i < ringBufferLength(fmudata->simulationData); i++) {

    /* timeValue */
    memcpy(&(tmpSimData.timeValue), currElement, sizeof(modelica_real));
    currElement += sizeof(modelica_real);

    /* realVars */
    tmpSimData.realVars = (modelica_real *) calloc(fmudata->modelData->nVariablesReal, sizeof(modelica_real));
    memcpy(tmpSimData.realVars, currElement,
                                sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    currElement += sizeof(modelica_real)*fmudata->modelData->nVariablesReal;

    /* integerVars */
    tmpSimData.integerVars = (modelica_integer *) calloc(fmudata->modelData->nVariablesInteger, sizeof(modelica_integer));
    memcpy(tmpSimData.integerVars, currElement,
                                   sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    currElement += sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger;

    /* booleanVars */
    tmpSimData.booleanVars = (modelica_boolean *) calloc(fmudata->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    memcpy(tmpSimData.booleanVars, currElement,
                                   sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    currElement += sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean;

    /* stringVars */
    size_t strArraySize = getStringArraySize(currElement, fmudata->modelData->nVariablesString);
    tmpSimData.stringVars = (modelica_string *) calloc(1, strArraySize);
    memcpy(tmpSimData.stringVars, currElement, strArraySize);
    currElement += strArraySize;

    appendRingData(internal_state->simulationData, &tmpSimData);
  }

  /* realParameter */
  internal_state->realParameter = (modelica_real *) calloc(fmudata->modelData->nParametersReal, sizeof(modelica_real));
  memcpy(internal_state->realParameter, currElement,
                                        sizeof(modelica_real)*fmudata->modelData->nParametersReal);
  currElement += sizeof(modelica_real)*fmudata->modelData->nParametersReal;

  /* integerParameter */
  internal_state->integerParameter = (modelica_integer *) calloc(fmudata->modelData->nParametersInteger, sizeof(modelica_integer));
  memcpy(internal_state->integerParameter, currElement,
                                   sizeof(modelica_integer)*fmudata->modelData->nParametersInteger);
  currElement += sizeof(modelica_integer)*fmudata->modelData->nParametersInteger;

  /* booleanParameter */
  internal_state->booleanParameter = (modelica_boolean *) calloc(fmudata->modelData->nParametersBoolean, sizeof(modelica_boolean));
  memcpy(internal_state->booleanParameter, currElement,
                                   sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean);
  currElement += sizeof(modelica_boolean)*fmudata->modelData->nParametersBoolean;

  /* stringParameter */
  size_t strArraySize = getStringArraySize(currElement, fmudata->modelData->nParametersString);
  internal_state->stringParameter = (modelica_string *) calloc(1, strArraySize);
  memcpy(internal_state->stringParameter, currElement, strArraySize);
  currElement += strArraySize;

  *FMUstate = (fmi3FMUState) internal_state;
  return fmi3OK;
}

fmi3Status omcGetDirectionalDerivativeForInitialization(ModelInstance* c,
    const fmi3ValueReference vUnknown_ref[], size_t nUnknown,
    const fmi3ValueReference vKnown_ref[] , size_t nKnown,
    const fmi3Float64 dvKnown[], fmi3Float64 dvUnknown[])
{
  ModelInstance *comp = (ModelInstance *)c;
  DATA* fmudata = (DATA *) comp->fmuData;
  SIMULATION_INFO* simInfo = (SIMULATION_INFO*) fmudata->simulationInfo;
  MODEL_DATA* modelData = (MODEL_DATA*) fmudata->modelData;
  threadData_t* td = comp->threadData;

  /***************************************/
  /* This code assumes that the FMU variables are always sorted,
     states first and then derivatives.
     This is true for the actual OMC FMUs.
     The input values references are mapped with mapInputReference2InputNumber
     and mapOutputReference2OutputNumber functions
  */
  /* eval constant part of jacobian */

  int i,j;

  int independent = comp->fmiDerJacInitialization->sizeCols;
  int dependent = comp->fmiDerJacInitialization->sizeRows;

  /* TODO: Evaluate only once for one evaluation of jacobian */
  if (comp->fmiDerJacInitialization->constantEqns != NULL) {
    comp->fmiDerJacInitialization->constantEqns(fmudata, td, comp->fmiDerJacInitialization, NULL);
  }

  /* clear out the seeds */
  for (i = 0; i < independent; i++)
  {
    comp->fmiDerJacInitialization->seedVars[i] = 0;
  }

  for (i = 0; i < nKnown; i++)
  {
    // map the known ValueReferences to an internal index
    int idx = mapInitialUnknownsIndependentIndex(vKnown_ref[i]);
    if (vrOutOfRange(comp, "omcGetDirectionalDerivative input index during initialization", idx, independent))
      return fmi3Error;
    /* Put the supplied value in the seeds */
    comp->fmiDerJacInitialization->seedVars[idx] = dvKnown[i];
  }

  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  fmudata->callback->functionJacFMIDERINIT_column(fmudata, td, comp->fmiDerJacInitialization, NULL);
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  /* Write the results to dvUnknown array */
  for (i=0;i<nUnknown; i++)
  {
    // map the Unknown ValueReferences to an internal index
    int idx = mapInitialUnknownsdependentIndex(vUnknown_ref[i]);
    if (vrOutOfRange(comp, "omcGetDirectionalDerivative output index during initialization", idx, dependent))
      return fmi3Error;
    dvUnknown[i] = comp->fmiDerJacInitialization->resultVars[idx];
  }

  return fmi3OK;
}

fmi3Status omcGetDirectionalDerivative(ModelInstance* c,
    const fmi3ValueReference vUnknown_ref[], size_t nUnknown,
    const fmi3ValueReference vKnown_ref[] , size_t nKnown,
    const fmi3Float64 dvKnown[], fmi3Float64 dvUnknown[])
{
  ModelInstance *comp = (ModelInstance *)c;
  DATA* fmudata = (DATA *) comp->fmuData;
  SIMULATION_INFO* simInfo = (SIMULATION_INFO*) fmudata->simulationInfo;
  MODEL_DATA* modelData = (MODEL_DATA*) fmudata->modelData;
  threadData_t* td = comp->threadData;

  int i,j;

  int independent = modelData->nStates+modelData->nInputVars;
  int dependent = modelData->nStates+modelData->nOutputVars;

  if (invalidState(comp, "omcGetDirectionalDerivative", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi3Error;
  if (!comp->_has_jacobian)
    return unsupportedFunction(comp, "omcGetDirectionalDerivative");

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetDirectionalDerivative")

  if (updateIfNeeded(comp, "omcGetDirectionalDerivative") != fmi3OK)
    return fmi3Error;

  if (model_state_initialization_mode == comp->state)
  {
    // directional derivative in initialization mode
    return omcGetDirectionalDerivativeForInitialization(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown);
  }

  /***************************************/
  /* This code assumes that the FMU variables are always sorted,
     states first and then derivatives.
     This is true for the actual OMC FMUs.
     The input values references are mapped with mapInputReference2InputNumber
     and mapOutputReference2OutputNumber functions
  */
  /* eval constant part of jacobian */
  /* TODO: Evaluate only once for one evaluation of jacobian */
  if (comp->fmiDerJac->constantEqns != NULL) {
    comp->fmiDerJac->constantEqns(fmudata, td, comp->fmiDerJac, NULL);
  }

  /* clear out the seeds */
  for (i=0;i<independent; i++) {
    comp->fmiDerJac->seedVars[i]=0;
  }
  for (i=0;i<nKnown; i++) {
    int idx = vKnown_ref[i];
    /* if idx is > nStates it's an input so we need a mapping */
    if (idx >= modelData->nStates){
      idx = mapInputReference2InputNumber(vKnown_ref[i]);
      idx = modelData->nStates + idx;
    }
    if (vrOutOfRange(comp, "omcGetDirectionalDerivative input index", idx, independent))
      return fmi3Error;
    /* Put the supplied value in the seeds */
    comp->fmiDerJac->seedVars[idx]=dvKnown[i];
  }
  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  fmudata->callback->functionJacFMIDER_column(fmudata, td, comp->fmiDerJac, NULL);
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  /* Write the results to dvUnknown array */
  for (i=0;i<nUnknown; i++) {
    /* derivatives are behind the states */
    int idx = vUnknown_ref[i] - modelData->nStates;
    /* if idx is > nStates it's an output so we need a mapping */
    if (idx >= modelData->nStates){
      idx = mapOutputReference2OutputNumber(vUnknown_ref[i]);
      idx = modelData->nStates + idx;
    }
    if (vrOutOfRange(comp, "omcGetDirectionalDerivative output index", idx, dependent))
      return fmi3Error;
    dvUnknown[i] = comp->fmiDerJac->resultVars[idx];
  }
  /***************************************/
  return fmi3OK;
}



/***************************************************
Functions for FMI2 for Model Exchange
****************************************************/
fmi3Status omcEnterEventMode(ModelInstance* c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcEnterEventMode", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_EVENTS, "omcEnterEventMode")
  comp->state = model_state_me_event_mode;

  // Reset eventInfo
  comp->eventInfo.newDiscreteStatesNeeded = fmi3False;
  comp->eventInfo.terminateSimulation = fmi3False;
  comp->eventInfo.nominalsOfContinuousStatesChanged = fmi3False;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmi3False;
  comp->eventInfo.nextEventTimeDefined = fmi3False;
  comp->eventInfo.nextEventTime = 0;

  return fmi3OK;
}

fmi3Status omcNewDiscreteStates(ModelInstance* c, EventInfo* eventInfo)
{
  ModelInstance *comp = (ModelInstance *)c;
  double nextSampleEvent = 0;
  fmi3Status returnValue = fmi3OK;

  if (invalidState(comp, "omcNewDiscreteStates", model_state_me_event_mode, 0))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcNewDiscreteStates")

  returnValue = internalEventUpdate(comp, eventInfo);

  return returnValue;
}

fmi3Status omcEnterContinuousTimeMode(ModelInstance* c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcEnterContinuousTimeMode", model_state_me_event_mode, 0))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcEnterContinuousTimeMode")
  comp->state = model_state_me_continuous_time_mode;
  return fmi3OK;
}

fmi3Status internal_CompletedIntegratorStep(ModelInstance* c, fmi3Boolean noSetFMUStatePriorToCurrentPoint, fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{
  int done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;

  if (nullPointer(comp, "omcCompletedIntegratorStep", "enterEventMode", enterEventMode))
    return fmi3Error;
  if (nullPointer(comp, "omcCompletedIntegratorStep", "terminateSimulation", terminateSimulation))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcCompletedIntegratorStep")

  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
    comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeSpatialDistribution(comp->fmuData, threadData);
    storePreValues(comp->fmuData);
    *enterEventMode = fmi3False;
    *terminateSimulation = fmi3False;
    /******** check state selection ********/
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 0))
    {
      /* if new set is calculated reinit the solver */
      *enterEventMode = fmi3True;
      FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcCompletedIntegratorStep: Need to iterate state values changed!")
    }
#endif
    /* TODO: fix the extrapolation in non-linear system
     *       then we can stop to save all variables in
     *       in the whole ringbuffer
     */
    overwriteOldSimulationData(comp->fmuData);
    done=1;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;
  resetThreadData(comp);
  omc_util_restore_pool_state(mem_pool_state);

  if (done) {
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "omcCompletedIntegratorStep: terminated by an assertion.")
  return fmi3Error;
}

fmi3Status omcCompletedIntegratorStep(ModelInstance* c, fmi3Boolean noSetFMUStatePriorToCurrentPoint, fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "omcCompletedIntegratorStep", model_state_me_continuous_time_mode, 0))
    return fmi3Error;

  return internal_CompletedIntegratorStep(c, noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation);
}

fmi3Status omcSetTime(ModelInstance* c, fmi3Float64 t)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcSetTime", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetTime: time=%.16g", t)
  comp->fmuData->localData[0]->timeValue = t;
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status internalSetContinuousStates(ModelInstance* c, const fmi3Float64 x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  int i;
  if (invalidNumber(comp, "omcSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi3Error;
  if (nullPointer(comp, "omcSetContinuousStates", "x[]", x))
    return fmi3Error;
#if NUMBER_OF_STATES > 0
  for (i = 0; i < nx; i++) {
    fmi3ValueReference vr = vrStates[i];
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetContinuousStates: #r%d# = %.16g", vr, x[i])
    if (vr < 0 || vr >= NUMBER_OF_REALS|| setReal(comp, vr, x[i]) != fmi3OK) { // to be implemented by the includer of this file
      return fmi3Error;
    }
  }
#endif
  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcSetContinuousStates(ModelInstance* c, const fmi3Float64 x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification omcSetContinuousStates should only be allowed in Continuous-Time Mode.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call omcSetContinuousStates after omcEnterInitializationMode.
   */
  if (invalidState(comp, "omcSetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi3Error;

  return internalSetContinuousStates(c, x, nx);
}

fmi3Status internalGetDerivatives(ModelInstance* c, fmi3Float64 derivatives[], size_t nx)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  if (invalidNumber(comp, "omcGetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmi3Error;
  if (nullPointer(comp, "omcGetDerivatives", "derivatives[]", derivatives))
    return fmi3Error;

  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->_need_update = 0;
    }

#if NUMBER_OF_STATES > 0
    for (i = 0; i < nx; i++) {
      fmi3ValueReference vr = vrStatesDerivatives[i];
      derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
      FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetDerivatives: #r%d# = %.16g", vr, derivatives[i])
    }
#endif

    done=1;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

  threadData->mmc_jumper = old_jmp;
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  if (done) {
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "omcGetDerivatives: terminated by an assertion.")
  return fmi3Error;
}

fmi3Status omcGetDerivatives(ModelInstance* c, fmi3Float64 derivatives[], size_t nx)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "omcGetDerivatives", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi3Error;

  return internalGetDerivatives(c, derivatives, nx);
}

fmi3Status internalGetEventIndicators(ModelInstance* c, fmi3Float64 eventIndicators[], size_t nx)
{
  int i, done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  if (invalidNumber(comp, "omcGetEventIndicators", "nx", nx, NUMBER_OF_EVENT_INDICATORS))
    return fmi3Error;

  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

#if NUMBER_OF_EVENT_INDICATORS > 0
    /* eval needed equations*/
    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      comp->_need_update = 0;
    }
    comp->fmuData->callback->function_ZeroCrossings(comp->fmuData, comp->threadData, comp->fmuData->simulationInfo->zeroCrossings);
    for (i = 0; i < nx; i++) {
      eventIndicators[i] = comp->fmuData->simulationInfo->zeroCrossings[i];
      FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetEventIndicators: z%d = %.16g", i, eventIndicators[i])
    }
#endif
    done=1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  if (done) {
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetEventIndicators: terminated by an assertion.")
  return fmi3Error;
}

fmi3Status omcGetEventIndicators(ModelInstance* c, fmi3Float64 eventIndicators[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification omcGetEventIndicators should only be allowed in Event Mode, Continuous-Time Mode & terminated.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call omcGetEventIndicators after omcEnterInitializationMode.
   */
  if (invalidState(comp, "omcGetEventIndicators", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
  /*if (invalidState(comp, "omcGetEventIndicators", model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error))*/
    return fmi3Error;

  return internalGetEventIndicators(c, eventIndicators, nx);
}

fmi3Status internalGetContinuousStates(ModelInstance* c, fmi3Float64 x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, "omcGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi3Error;
  if (nullPointer(comp, "omcGetContinuousStates", "states[]", x))
    return fmi3Error;
#if NUMBER_OF_STATES > 0
  for (i = 0; i < nx; i++)
  {
    fmi3ValueReference vr = vrStates[i];
    x[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetContinuousStates: #r%u# = %.16g", vr, x[i])
  }
#endif
  return fmi3OK;
}

fmi3Status omcGetContinuousStates(ModelInstance* c, fmi3Float64 x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcGetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi3Error;

  return internalGetContinuousStates(c, x, nx);
}

fmi3Status internalGetNominalsOfContinuousStates(ModelInstance* c, fmi3Float64 x_nominal[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, "omcGetNominalsOfContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi3Error;
  if (nullPointer(comp, "omcGetNominalsOfContinuousStates", "x_nominal[]", x_nominal))
    return fmi3Error;
  x_nominal[0] = 1;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetNominalsOfContinuousStates: x_nominal[0..%d] = 1.0", nx-1)
  for (i = 0; i < nx; i++)
    x_nominal[i] = 1;
  return fmi3OK;
}

fmi3Status omcGetNominalsOfContinuousStates(ModelInstance* c, fmi3Float64 x_nominal[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "omcGetNominalsOfContinuousStates", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi3Error;

  return internalGetNominalsOfContinuousStates(c, x_nominal, nx);
}

/***************************************************
Functions for FMI2 for Co-Simulation
****************************************************/
fmi3Status omcSetRealInputDerivatives(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3Int32 order[], const fmi3Float64 value[])
{
  /* Variables */
  int i;
  int mappedIndex;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  if (invalidState(comp, "omcSetRealInputDerivatives", 0, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetRealInputDerivatives", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcSetRealInputDerivatives", "value[]", value))
    return fmi3Error;

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetRealInputDerivatives: nvr = %d", nvr)

#if NUMBER_OF_REAL_INPUTS > 0
  for (i = 0; i < nvr; i++)
  {
    if (order[i] > 1) // currently first order derivative is supported
      return fmi3Error;
    if (vrOutOfRange(comp, "omcSetRealInputDerivatives", vr[i], NUMBER_OF_REALS))
      return fmi3Error;
    // check valueReference is an input of type Real
    mappedIndex = mapInputReference2InputNumber(vr[i]);
    if (mappedIndex == -1)
      return fmi3Error;
    comp->input_real_derivative[mappedIndex] = value[i]; // store the values in an external array
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcSetRealInputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif

  comp->_need_update = 1;
  return fmi3OK;
}

fmi3Status omcGetRealOutputDerivatives(ModelInstance* c, const fmi3ValueReference vr[], size_t nvr, const fmi3Int32 order[], fmi3Float64 value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  if (invalidState(comp, "omcGetRealOutputDerivatives", 0, model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetRealOutputDerivatives", "vr[]", vr))
    return fmi3Error;
  if (nvr > 0 && nullPointer(comp, "omcGetRealOutputDerivatives", "value[]", value))
    return fmi3Error;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, "omcGetRealOutputDerivatives") != fmi3OK)
    return fmi3Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "omcGetRealOutputDerivatives", vr[i], NUMBER_OF_REALS)) {
      return fmi3Error;
    }
    fmi3ValueReference mappedVR = mapOutputReference2RealOutputDerivatives(vr[i]);
    value[i] = getReal(comp, mappedVR); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "omcGetRealOutputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmi3OK;
}

/**
 * @brief FMI 2 doStep function.
 *
 * Compute time step to next communication point with explicit Euler or CVODE.
 *
 * @param c                                   FMU component.
 * @param currentCommunicationPoint           Current communication point of master algorithm.
 * @param communicationStepSize               Communication step size.
 * @param noSetFMUStatePriorToCurrentPoint    Unused.
 * @return fmi3Status                         Returns fmi3OK if communication point was reached successfully.
 *                                            Returns fmi3Error if something went wrong.
 */
/**
 * @brief Internal Co-Simulation step shared by omcDoStep and fmi3DoStep.
 *
 * When @p eventModeUsed and @p earlyReturnAllowed are both true (FMI 3.0
 * Co-Simulation with Event Mode), the step stops at the first encountered event
 * (state event, time event or state-selection event) and reports it through
 * @p eventEncountered / @p earlyReturn / @p lastSuccessfulTime instead of
 * resolving it internally. The master is then expected to call
 * fmi3EnterEventMode / fmi3UpdateDiscreteStates / fmi3EnterStepMode and resume
 * with a new step from @p lastSuccessfulTime. Otherwise events are handled
 * internally (FMI 2.0 behaviour) and the step always advances to the
 * communication point.
 */
static fmi3Status fmu3DoStepInternal(ModelInstance* c, fmi3Float64 currentCommunicationPoint,
    fmi3Float64 communicationStepSize, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean eventModeUsed, fmi3Boolean earlyReturnAllowed,
    fmi3Boolean* eventEncountered, fmi3Boolean* terminateSimulationOut,
    fmi3Boolean* earlyReturn, fmi3Float64* lastSuccessfulTime)
{
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  int i, zc_event = 0, time_event = 0;
  int flag;
  int done = 0;
  fmi3Boolean ev = fmi3False;   /* event encountered and deferred to the master */
  fmi3Boolean term = fmi3False; /* simulation terminated by an internal event */

  fmi3Status status = fmi3OK;
  fmi3Float64* states = comp->states;
  fmi3Float64* states_der = comp->states_der;
  fmi3Float64* event_indicators = comp->event_indicators;
  fmi3Float64* event_indicators_prev = comp->event_indicators_prev;
  fmi3Float64 t = comp->fmuData->localData[0]->timeValue;
  fmi3Float64 tNext, tEnd;
  fmi3Boolean enterEventMode = fmi3False, terminateSimulation = fmi3False;

  EventInfo eventInfo;

  if (eventEncountered)       *eventEncountered = fmi3False;
  if (terminateSimulationOut) *terminateSimulationOut = fmi3False;
  if (earlyReturn)            *earlyReturn = fmi3False;
  if (lastSuccessfulTime)     *lastSuccessfulTime = currentCommunicationPoint + communicationStepSize;

  if (invalidState(comp, "omcDoStep", 0, model_state_cs_step_complete))
    return fmi3Error;

  MemPoolState doStep_pool_state = omc_util_get_pool_state();

  setThreadData(comp);

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;

  eventInfo.newDiscreteStatesNeeded           = fmi3False;
  eventInfo.terminateSimulation               = fmi3False;
  eventInfo.nominalsOfContinuousStatesChanged = fmi3False;
  eventInfo.valuesOfContinuousStatesChanged   = fmi3True;
  eventInfo.nextEventTimeDefined              = fmi3False;
  eventInfo.nextEventTime                     = 0.0;

  comp->fmuData->localData[0]->timeValue = currentCommunicationPoint;
  tEnd = currentCommunicationPoint + communicationStepSize;
  if (comp->stopTimeDefined && (tEnd > comp->stopTime))
    status=fmi3Error;

  // copy the input values
#if NUMBER_OF_REAL_INPUTS > 0
  fmi3Float64 realInputDerivatives[NUMBER_OF_REAL_INPUTS];
  for (int i = 0; i < NUMBER_OF_REALS; ++i)
  {
    int mappedIndex = mapInputReference2InputNumber(i);
    if (mappedIndex != -1)
      realInputDerivatives[mappedIndex] = getReal(comp, i);
  }
#endif

  status = internalEventIteration(c, &eventInfo);
  if (status != fmi3OK) goto doStep_cleanup;

  /* Integration loop */
  while (status == fmi3OK && comp->fmuData->localData[0]->timeValue < tEnd)
  {
    /* fprintf(stderr, "DoStep %g -> %g State: %s\n", comp->fmuData->localData[0]->timeValue, tNext, stateToString(comp)); */

    // set the real Inputs with output_derivative values
#if NUMBER_OF_REAL_INPUTS > 0
    for (int i = 0; i < NUMBER_OF_REALS; ++i)
    {
      int mappedIndex = mapInputReference2InputNumber(i);
      if (mapInputReference2InputNumber(i) != -1)
      {
        double dt = comp->fmuData->localData[0]->timeValue - t;
        double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
        if (setReal(comp, i, new_input_value) != fmi3OK) // to be implemented by the includer of this file
        {
          status = fmi3Error;
          goto doStep_cleanup;
        }
      }
    }
#endif

#if NUMBER_OF_STATES > 0
    status = internalGetDerivatives(c, states_der, NUMBER_OF_STATES);
  if (status != fmi3OK) goto doStep_cleanup;

    status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
  if (status != fmi3OK) goto doStep_cleanup;
#endif

#if NUMBER_OF_EVENT_INDICATORS > 0
    status = internalGetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
  if (status != fmi3OK) goto doStep_cleanup;
#endif

    /* adjust for time events */
    if (eventInfo.nextEventTimeDefined && (eventInfo.nextEventTime <= tEnd))
    {
      tNext = eventInfo.nextEventTime;
      time_event = 1;
    }
    else
    {
      tNext = tEnd;
    }

    /* integrate */
    switch(comp->solverInfo->solverMethod)
    {
      case S_EULER:
        for (i = 0; i < NUMBER_OF_STATES; i++)
        {
          states[i] = states[i] + (tNext - comp->fmuData->localData[0]->timeValue) * states_der[i];
        }
        break;
      case S_CVODE:
#ifdef WITH_SUNDIALS
        flag = cvode_solver_fmi_step(comp, tNext, states);
        if (flag < 0)
        {
          FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcDoStep: CVODE integrator step failed.")
          status = fmi3Fatal;
          goto doStep_cleanup;
        }
#else
        FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcDoStep: FMU not compiled with SUNDIALS but solver CVODE selected.")
        status = fmi3Fatal;
        goto doStep_cleanup;
#endif /* WITH_SUNDIALS */
        break;
      default:
        FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcDoStep: Unknown solver method %d.", comp->solverInfo->solverMethod)
        status = fmi3Fatal;
        goto doStep_cleanup;
    }

    // update time
    comp->fmuData->localData[0]->timeValue = tNext;
    comp->_need_update = 1;

    // set the real Inputs with output_derivative values
#if (NUMBER_OF_REAL_INPUTS > 0)
    for (int i = 0; i < NUMBER_OF_REALS; ++i)
    {
      int mappedIndex = mapInputReference2InputNumber(i);
      if (mapInputReference2InputNumber(i) != -1)
      {
        double dt = comp->fmuData->localData[0]->timeValue - t;
        double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
        if (setReal(comp, i, new_input_value) != fmi3OK) // to be implemented by the includer of this file
        {
          status = fmi3Error;
          goto doStep_cleanup;
        }
      }
    }
#endif

    /* set the continuous states */
#if NUMBER_OF_STATES > 0
    status = internalSetContinuousStates(c, states, NUMBER_OF_STATES);
    if (status != fmi3OK) goto doStep_cleanup;
#endif

    /* signal completed integrator step */
    status = internal_CompletedIntegratorStep(c, fmi3True, &enterEventMode, &terminateSimulation);
    if (status != fmi3OK) goto doStep_cleanup;

    /* check for events */
#if NUMBER_OF_EVENT_INDICATORS > 0
    status = internalGetEventIndicators(c, event_indicators, NUMBER_OF_EVENT_INDICATORS);
  if (status != fmi3OK) goto doStep_cleanup;

    for (i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
    {
      if (event_indicators[i]*event_indicators_prev[i] < 0)
      {
        zc_event = 1;
        break;
      }
    }
#endif

    comp->solverInfo->didEventStep = 0;

    if (enterEventMode || zc_event || time_event)
    {
      /* fprintf(stderr, "enterEventMode = %d, zc_event = %d, time_event = %d\n", enterEventMode, zc_event, time_event); */

      if (eventModeUsed &&
          (earlyReturnAllowed || comp->fmuData->localData[0]->timeValue >= tEnd))
      {
        /* FMI 3.0 Co-Simulation with Event Mode: do not resolve the event here.
           Stop the step at the event and let the master handle it via
           fmi3EnterEventMode / fmi3UpdateDiscreteStates / fmi3EnterStepMode. The
           continuous states have already been advanced to and stored at this
           point, so the deferred event update operates on a consistent state.
           An event landing exactly at the communication point is reported
           without an early return; an event strictly inside the step is only
           deferred when the master allows early return, otherwise it is handled
           internally below. */
        ev = fmi3True;
        FILTERED_LOG(comp, fmi3OK, LOG_EVENTS, "omcDoStep: event encountered at %g, deferring to the master", comp->fmuData->localData[0]->timeValue)
        break;
      }

      // Reset eventInfo
      eventInfo.newDiscreteStatesNeeded           = fmi3False;
      eventInfo.terminateSimulation               = fmi3False;
      eventInfo.nominalsOfContinuousStatesChanged = fmi3False;
      eventInfo.valuesOfContinuousStatesChanged   = fmi3True;
      eventInfo.nextEventTimeDefined              = fmi3False;
      eventInfo.nextEventTime                     = 0.0;
      status = internalEventIteration(c, &eventInfo);
      if (status != fmi3OK) goto doStep_cleanup;

      if (eventInfo.valuesOfContinuousStatesChanged)
      {
        #if NUMBER_OF_STATES > 0
          status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
          if (status != fmi3OK) goto doStep_cleanup;
        #endif
      }

      if (eventInfo.nominalsOfContinuousStatesChanged)
      {
        #if NUMBER_OF_STATES > 0
          status = internalGetNominalsOfContinuousStates(c, states, NUMBER_OF_STATES);
          if (status != fmi3OK) goto doStep_cleanup;
        #endif
      }

      #if NUMBER_OF_EVENT_INDICATORS > 0
        status = internalGetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
        if (status != fmi3OK) goto doStep_cleanup;
      #endif

      comp->solverInfo->didEventStep = 1;

      if (eventInfo.terminateSimulation)
      {
        term = fmi3True;
        break;
      }
    }
  }

  done = 1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

doStep_cleanup:
  threadData->mmc_jumper = old_jmp;
  omc_util_restore_pool_state(doStep_pool_state);
  resetThreadData(comp);

  if (!done)
  {
    if (status == fmi3OK)
    {
      FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "omcDoStep: terminated by an assertion.")
      status = fmi3Error;
    }
  }

  if (status <= fmi3Warning)
  {
    fmi3Float64 reached = comp->fmuData->localData[0]->timeValue;
    if (lastSuccessfulTime)     *lastSuccessfulTime = reached;
    if (eventEncountered)       *eventEncountered = ev;
    if (terminateSimulationOut) *terminateSimulationOut = term;
    /* An early return happened when the step stopped (for an event) before the
       requested communication point. */
    if (earlyReturn)            *earlyReturn = (ev && reached < tEnd) ? fmi3True : fmi3False;
  }

  return status;
}

/* FMI 2.0 Co-Simulation doStep: events are always handled internally. */
fmi3Status omcDoStep(ModelInstance* c, fmi3Float64 currentCommunicationPoint, fmi3Float64 communicationStepSize, fmi3Boolean noSetFMUStatePriorToCurrentPoint)
{
  return fmu3DoStepInternal(c, currentCommunicationPoint, communicationStepSize,
      noSetFMUStatePriorToCurrentPoint, fmi3False, fmi3False, NULL, NULL, NULL, NULL);
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

/* =====================================================================
 * Co-Simulation solver setup (previously in fmu_read_flags.c, inlined here
 * to keep the FMI 3.0 interface independent of the FMI 2.0 files).
 * ===================================================================== */

static inline const char* skipTo(const char *str, char c)
{
  while(*str != c && *str != '\0') {
    str++;
  }
  return str;
}

/**
  * @brief Puts double quotes around a string
 *
  * @param str      Null terminated string.
  * @return char*   Newly allocated string with double quotes around `str`.
  *                 Needs to be freed with `free`
 */
static inline char* quote(const char *str)
{
  size_t len = strlen(str) + 3; // +2 for quotes, +1 for null terminator
  char* tmp = (char*) malloc(len);
  if (tmp == NULL) {
    return NULL;
  }
  snprintf(tmp, len, "\"%s\"", str);
  return tmp;
 }

/**
 * @brief Parse and sets the solver method string
 *
 * @param  solverInfo   Solver info to set solver method in.
 * @param  str          string that starts at solver method string
 * @return const char*  input string skipped to endline
 */
static inline const char* setSolverMethod(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i;
  char* value;
  for(i=1; i<S_MAX; i++)
  {
    value = quote(SOLVER_METHOD_NAME[i]);
    if (value == NULL) {
      continue;
    }
    if (strncmp(str, value, strlen(SOLVER_METHOD_NAME[i]) + 2) == 0)
    {
      solverInfo->solverMethod = i;
      free(value);
      break;
    }
    free(value);
  }
  return skipTo(str, '\n');
}

/**
 * @brief parses flags from resources/modelName_flags.json
 *
 * @param solverInfo
 * @param str           string read from file
 */
void parseFlags(SOLVER_INFO *solverInfo, const char *str)
{
  /* Variables */
  int i, k;
  const int k_max = 1000;
  char* value;

  str = skipTo(str, '\"');
  k = 0;
  while(*str != '\0' && k < k_max)
  {
    k++;
    for(i=1; i<FMU_FLAG_MAX; i++)
    {
      // map the fmu flags to regular flags
      value = quote(FLAG_NAME[FMU_FLAG_MAP[i]]);
      if (value == NULL) {
        /* If allocation failed, skip this entry */
        continue;
      }

      if (strncmp(str, value, strlen(FLAG_NAME[FMU_FLAG_MAP[i]]) + 2) == 0)
      {
        str = skipTo(str, ':');
        str = skipTo(str, '\"');

        switch(i) {
          case FMU_FLAG_SOLVER: str = setSolverMethod(solverInfo, str); break;
          default: str = skipTo(str, '\n'); break;
        }
      }

      free(value);
    }
    str = skipTo(str, '\"');
   }
}

/**
 * @brief Initialize solver data.
 *
 * Reads optional FMU simulation flags from <fmiPrefix>.fmu/resources/<fmiPrefix>_flags.json.
 * Initialize solver euler or CVODE.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 when an error occurred.
 */
int FMI3CS_initializeSolverData(ModelInstance* comp)
{
  /* Variables */
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;

  int retValue;

  data = comp->fmuData;
  threadData = comp->threadData;

  /* Allocate memory */
  solverInfo = (SOLVER_INFO*) calloc(1, sizeof(SOLVER_INFO));

  /* Initialize solverInfo */
  solverInfo->currentTime = 0;
  solverInfo->currentStepSize = 0;
  solverInfo->laststep = 0;
  solverInfo->solverMethod = 0;
  solverInfo->solverRootFinding = 0;
  solverInfo->solverNoEquidistantGrid = FALSE;
  solverInfo->lastdesiredStep = solverInfo->currentTime + solverInfo->currentStepSize;
  solverInfo->eventLst = NULL;
  solverInfo->didEventStep = 0;
  solverInfo->stateEvents = 0;
  solverInfo->sampleEvents = 0;

  /* read fmu flags from flags.json */
  size_t filename_len = strlen(comp->fmuData->modelData->resourcesDir) + strlen(comp->fmuData->modelData->modelFilePrefix) + 13;
  char* flags_filename = calloc(filename_len, sizeof(char));
  snprintf(flags_filename, filename_len, "%s/%s_flags.json",
           comp->fmuData->modelData->resourcesDir,
           comp->fmuData->modelData->modelFilePrefix);
  FILTERED_LOG(comp, fmi3OK, LOG_ALL, "omcInstantiate: Trying to find simulation settings %s.", flags_filename)

  if( omc_file_exists( flags_filename) )
  {
    FILTERED_LOG(comp, fmi3OK, LOG_ALL, "omcInstantiate: Found simulation settings %s.", flags_filename)
    omc_mmap_read mmap_reader = {0};
    mmap_reader = omc_mmap_open_read(flags_filename);
    parseFlags(solverInfo, mmap_reader.data);
    omc_mmap_close_read(mmap_reader);
  }
  else
  {
    FILTERED_LOG(comp, fmi3OK, LOG_ALL, "omcInstantiate: Using default simulation settings.")
    solverInfo->solverMethod = S_EULER;
  }

  /* If no states are present, we can use Euler's method since it is doing nothing. */
  if (data->modelData->nStates < 1)
  {
    FILTERED_LOG(comp, fmi3OK, LOG_ALL, "omcInstantiate: No states present, continuing without ODE solver.")
    solverInfo->solverMethod = S_EULER;
  }

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no initialization */
      retValue = 0;
      break;
      case S_CVODE:
#ifdef WITH_SUNDIALS
      omc_useStream[OMC_LOG_SOLVER] = 1;
      CVODE_SOLVER* cvodeData = NULL;
      FILTERED_LOG(comp, fmi3OK, LOG_ALL, "Initializing CVODE ODE Solver")
      cvodeData = (CVODE_SOLVER*) calloc(1, sizeof(CVODE_SOLVER));
      if (!cvodeData) {
        FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcInstantiate: Out of memory.")
        free(solverInfo);
        return -1;
        retValue = -1;
      } else {
        retValue = cvode_solver_initial(data, threadData, solverInfo, cvodeData, 1 /* is FMI */);   /* TODO: cvode_solver_initial needs to use malloc and free */
      }
      solverInfo->solverData = cvodeData;
      omc_useStream[OMC_LOG_SOLVER] = 0;
#else
      solverInfo->solverData = NULL;
      FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcInstantiate: FMU not compiled with SUNDIALS but solver CVODE selected.")
      retValue = -1;
#endif /* WITH_SUNDIALS */
      break;
    default:
      FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcInstantiate: Unknown solver method.")
      retValue = -1;
  }

  free(flags_filename);

  comp->solverInfo = solverInfo;

  return retValue;
}

/**
 * @brief Deinitialize solver data.
 *
 * Use for solver data allocated with FMI3CS_initializeSolverData.
 * Frees everything inside comp->solverInfo.
 *
 * @param comp          FMU component.
 * @return int          Return 0 on success and -1 else.
 */
int FMI3CS_deInitializeSolverData(ModelInstance* comp)
{
  /* Variables */
  DATA* data;
  threadData_t* threadData;
  SOLVER_INFO* solverInfo;
  int retValue;

  data = comp->fmuData;
  threadData = comp->threadData;
  solverInfo = comp->solverInfo;

  /* Log function call */
  FILTERED_LOG(comp, fmi3OK, LOG_ALL, "omcFreeInstance: Freeing solver data.")

  switch (solverInfo->solverMethod)
  {
    case S_EULER:
      /* Needs no freeing */
      retValue = 0;
      break;
    case S_CVODE:
#ifdef WITH_SUNDIALS
      retValue = cvode_solver_deinitial(solverInfo->solverData);
      break;
#else
      FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcInstantiate: FMU not compiled with SUNDIALS but solver CVODE selected.")
      retValue = -1;
      break;
#endif /* WITH_SUNDIALS */
    default:
      FILTERED_LOG(comp, fmi3Fatal, LOG_STATUSFATAL, "omcFreeInstance: Unknown solver method.")
      retValue = -1;
  }

  free(comp->solverInfo);
  comp->solverInfo = NULL;

  return retValue;
}


/* =====================================================================
 * FMI 3.0 public API (layered on the engine above).
 * ===================================================================== */

#ifndef FMU3_LOG_BUFFER_SIZE
#define FMU3_LOG_BUFFER_SIZE 2048
#endif

/* ---------------------------------------------------------------------------
 * Helpers
 * ------------------------------------------------------------------------- */

static ModelInstance *fmu3InnerComp(fmi3Instance instance)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  return inst ? (ModelInstance *)inst->comp : NULL;
}

/* Generic instantiation shared by ME, CS and SE. */
static fmi3Instance fmu3InstantiateCommon(int interfaceType, fmi3String instanceName,
    fmi3String instantiationToken, fmi3String resourcePath, fmi3Boolean visible,
    fmi3Boolean loggingOn, fmi3InstanceEnvironment instanceEnvironment,
    fmi3LogMessageCallback logMessage, fmi3IntermediateUpdateCallback intermediateUpdate)
{
  OMC_FmuType fmuType;
  ModelInstance3 *inst = (ModelInstance3 *)calloc(1, sizeof(ModelInstance3));
  if (!inst) {
    if (logMessage) {
      logMessage(instanceEnvironment, fmi3Fatal, "logStatusFatal", "fmi3Instantiate: out of memory.");
    }
    return NULL;
  }

  inst->logMessage = logMessage;
  inst->instanceEnvironment = instanceEnvironment;
  inst->intermediateUpdate = intermediateUpdate;
  inst->interfaceType = interfaceType;

  /* FMI 3.0 has no ScheduledExecution in the FMI 2.0 runtime; map it to the
     ModelExchange code path (scheduled execution is clock activated ME). */
  fmuType = (interfaceType == FMI3_INTERFACE_CS) ? OMC_CS : OMC_ME;

  /* In FMI 3.0 resourcePath is a plain absolute directory path, whereas the FMI
     2.0 omcInstantiate expects a "file://" URI (OpenModelica_parseFmuResourcePath
     only accepts URIs). Wrap a plain path into a file URI so the resources
     directory is resolved (required by the Co-Simulation solver setup, which
     otherwise dereferences a NULL resourcesDir). */
  const char *resourceUri = resourcePath;
  char *resourceUriBuf = NULL;
  if (resourcePath && strncmp(resourcePath, "file:", 5) != 0) {
    size_t n = strlen(resourcePath) + strlen("file://") + 1;
    resourceUriBuf = (char *)malloc(n);
    if (resourceUriBuf) {
      snprintf(resourceUriBuf, n, "file://%s", resourcePath);
      resourceUri = resourceUriBuf;
    }
  }

  /* The FMI 3.0 instantiationToken corresponds to the FMI 2.0 GUID. */
  inst->comp = omcInstantiate(instanceName, fmuType, instantiationToken, resourceUri,
      instanceEnvironment, logMessage, visible, loggingOn);
  if (resourceUriBuf) {
    free(resourceUriBuf);
  }
  if (!inst->comp) {
    free(inst);
    return NULL;
  }
  return (fmi3Instance)inst;
}

/* ---------------------------------------------------------------------------
 * Inquire version numbers and set debug logging
 * ------------------------------------------------------------------------- */
const char* fmi3GetVersion(void)
{
  return fmi3Version;
}

fmi3Status fmi3SetDebugLogging(fmi3Instance instance, fmi3Boolean loggingOn,
    size_t nCategories, const fmi3String categories[])
{
  return (fmi3Status)omcSetDebugLogging(fmu3InnerComp(instance), loggingOn, nCategories, categories);
}

/* ---------------------------------------------------------------------------
 * Creation and destruction of FMU instances
 * ------------------------------------------------------------------------- */
fmi3Instance fmi3InstantiateModelExchange(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage)
{
  return fmu3InstantiateCommon(FMI3_INTERFACE_ME, instanceName, instantiationToken, resourcePath,
      visible, loggingOn, instanceEnvironment, logMessage, NULL);
}

fmi3Instance fmi3InstantiateCoSimulation(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn, fmi3Boolean eventModeUsed,
    fmi3Boolean earlyReturnAllowed, const fmi3ValueReference requiredIntermediateVariables[],
    size_t nRequiredIntermediateVariables, fmi3InstanceEnvironment instanceEnvironment,
    fmi3LogMessageCallback logMessage, fmi3IntermediateUpdateCallback intermediateUpdate)
{
  (void)requiredIntermediateVariables;
  (void)nRequiredIntermediateVariables;
  fmi3Instance instance = fmu3InstantiateCommon(FMI3_INTERFACE_CS, instanceName, instantiationToken,
      resourcePath, visible, loggingOn, instanceEnvironment, logMessage, intermediateUpdate);
  if (instance) {
    ModelInstance3 *inst = (ModelInstance3 *)instance;
    inst->eventModeUsed = eventModeUsed ? 1 : 0;
    inst->earlyReturnAllowed = earlyReturnAllowed ? 1 : 0;
  }
  return instance;
}

fmi3Instance fmi3InstantiateScheduledExecution(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage,
    fmi3ClockUpdateCallback clockUpdate, fmi3LockPreemptionCallback lockPreemption,
    fmi3UnlockPreemptionCallback unlockPreemption)
{
  (void)clockUpdate;
  (void)lockPreemption;
  (void)unlockPreemption;
  return fmu3InstantiateCommon(FMI3_INTERFACE_SE, instanceName, instantiationToken, resourcePath,
      visible, loggingOn, instanceEnvironment, logMessage, NULL);
}

void fmi3FreeInstance(fmi3Instance instance)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  if (!inst) {
    return;
  }
  if (inst->comp) {
    omcFreeInstance(inst->comp);
  }
  free(inst);
}

/* ---------------------------------------------------------------------------
 * Enter and exit initialization mode, terminate and reset
 * ------------------------------------------------------------------------- */
fmi3Status fmi3EnterInitializationMode(fmi3Instance instance, fmi3Boolean toleranceDefined,
    fmi3Float64 tolerance, fmi3Float64 startTime, fmi3Boolean stopTimeDefined, fmi3Float64 stopTime)
{
  ModelInstance* c = fmu3InnerComp(instance);
  fmi3Status status = omcSetupExperiment(c, toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime);
  if (status > fmi3Warning) {
    return (fmi3Status)status;
  }
  return (fmi3Status)omcEnterInitializationMode(c);
}

fmi3Status fmi3ExitInitializationMode(fmi3Instance instance)
{
  return (fmi3Status)omcExitInitializationMode(fmu3InnerComp(instance));
}

fmi3Status fmi3EnterEventMode(fmi3Instance instance)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  ModelInstance *comp = fmu3InnerComp(instance);
  if (!inst || !comp) return fmi3Error;
  if (inst->interfaceType == FMI3_INTERFACE_CS) {
    /* Co-Simulation with Event Mode: the instance stays in Step Mode
       (model_state_cs_step_complete); the event is resolved by the following
       fmi3UpdateDiscreteStates calls, which drive the event iteration directly
       (the Model-Exchange Event Mode state is not valid for a CS instance). */
    return fmi3OK;
  }
  return (fmi3Status)omcEnterEventMode(comp);
}

fmi3Status fmi3Terminate(fmi3Instance instance)
{
  return (fmi3Status)omcTerminate(fmu3InnerComp(instance));
}

fmi3Status fmi3Reset(fmi3Instance instance)
{
  return (fmi3Status)omcReset(fmu3InnerComp(instance));
}

/* ---------------------------------------------------------------------------
 * Getting and setting variable values
 *
 * The FMI 3.0 value references are the per-base-type FMI 2.0 value references
 * shifted by FMI3_*_VR_OFFSET. The independent variable time uses FMI3_TIME_VR
 * and the synthetic event indicator variables occupy
 * [FMI3_EVENT_INDICATOR_VR_START, FMI3_EVENT_INDICATOR_VR_START + NUMBER_OF_EVENT_INDICATORS).
 * ------------------------------------------------------------------------- */
fmi3Status fmi3GetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 values[], size_t nValues)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!comp) {
    return fmi3Error;
  }
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference vr = valueReferences[i];
    /* Array variables occupy a contiguous block of scalar value references. When
       a single (array) variable is requested the master passes nValues scalar
       elements for it; otherwise there is one value per value reference. */
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference evr = vr + (fmi3ValueReference)j;
      if (evr == (fmi3ValueReference)FMI3_TIME_VR) {
        values[k] = (fmi3Float64)comp->fmuData->localData[0]->timeValue;
      } else if (evr >= (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START) {
#if NUMBER_OF_EVENT_INDICATORS > 0
        fmi3Float64 ei[NUMBER_OF_EVENT_INDICATORS];
        fmi3Status s = omcGetEventIndicators((ModelInstance*)comp, ei, NUMBER_OF_EVENT_INDICATORS);
        if (s > fmi3Warning) return (fmi3Status)s;
        values[k] = (fmi3Float64)ei[evr - (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START];
#else
        return fmi3Error;
#endif
      } else {
        fmi3ValueReference lvr = (fmi3ValueReference)(evr - FMI3_REAL_VR_OFFSET);
        fmi3Float64 value;
        fmi3Status s = omcGetReal((ModelInstance*)comp, &lvr, 1, &value);
        if (s > fmi3Warning) return (fmi3Status)s;
        values[k] = (fmi3Float64)value;
      }
    }
  }
  return fmi3OK;
}

fmi3Status fmi3GetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Int32 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_INTEGER_VR_OFFSET);
      fmi3Int32 value;
      fmi3Status s = omcGetInteger(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[k] = (fmi3Int32)value;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3GetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Boolean values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_BOOLEAN_VR_OFFSET);
      fmi3Boolean value;
      fmi3Status s = omcGetBoolean(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[k] = value ? fmi3True : fmi3False;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3GetString(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3String values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_STRING_VR_OFFSET);
      fmi3String value;
      fmi3Status s = omcGetString(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[k] = (fmi3String)value;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3SetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference vr = valueReferences[i];
    /* Array variables occupy a contiguous block of scalar value references (see
       fmi3GetFloat64). */
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference evr = vr + (fmi3ValueReference)j;
      fmi3ValueReference lvr;
      fmi3Float64 value;
      /* time and event indicators are not settable */
      if (evr == (fmi3ValueReference)FMI3_TIME_VR || evr >= (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START) {
        continue;
      }
      lvr = (fmi3ValueReference)(evr - FMI3_REAL_VR_OFFSET);
      value = (fmi3Float64)values[k];
      fmi3Status s = omcSetReal(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3SetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int32 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_INTEGER_VR_OFFSET);
      fmi3Int32 value = (fmi3Int32)values[k];
      fmi3Status s = omcSetInteger(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3SetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Boolean values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_BOOLEAN_VR_OFFSET);
      fmi3Boolean value = values[k] ? fmi3True : fmi3False;
      fmi3Status s = omcSetBoolean(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3SetString(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3String values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_STRING_VR_OFFSET);
      fmi3String value = (fmi3String)values[k];
      fmi3Status s = omcSetString(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
  }
  return fmi3OK;
}

/* The remaining typed get/set functions are for base types that OpenModelica
 * does not generate (Float32, the smaller / unsigned integer types, Binary and
 * Clock). A well-formed master never calls them for an OpenModelica FMU (there
 * are no such variables), so they only need to return fmi3OK for the empty case
 * and an error otherwise. */
#define FMU3_UNSUPPORTED_GETSET(NAME, CTYPE)                                                   \
fmi3Status NAME(fmi3Instance instance, const fmi3ValueReference valueReferences[],             \
    size_t nValueReferences, CTYPE values[], size_t nValues) {                                 \
  (void)instance; (void)valueReferences; (void)values; (void)nValues;                         \
  return nValueReferences == 0 ? fmi3OK : fmi3Error;                                           \
}
#define FMU3_UNSUPPORTED_SET(NAME, CTYPE)                                                      \
fmi3Status NAME(fmi3Instance instance, const fmi3ValueReference valueReferences[],             \
    size_t nValueReferences, const CTYPE values[], size_t nValues) {                           \
  (void)instance; (void)valueReferences; (void)values; (void)nValues;                         \
  return nValueReferences == 0 ? fmi3OK : fmi3Error;                                           \
}

FMU3_UNSUPPORTED_GETSET(fmi3GetFloat32, fmi3Float32)
FMU3_UNSUPPORTED_GETSET(fmi3GetInt8,   fmi3Int8)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt8,  fmi3UInt8)
FMU3_UNSUPPORTED_GETSET(fmi3GetInt16,  fmi3Int16)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt16, fmi3UInt16)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt32, fmi3UInt32)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt64, fmi3UInt64)
FMU3_UNSUPPORTED_SET(fmi3SetFloat32, fmi3Float32)
FMU3_UNSUPPORTED_SET(fmi3SetInt8,   fmi3Int8)
FMU3_UNSUPPORTED_SET(fmi3SetUInt8,  fmi3UInt8)
FMU3_UNSUPPORTED_SET(fmi3SetInt16,  fmi3Int16)
FMU3_UNSUPPORTED_SET(fmi3SetUInt16, fmi3UInt16)
FMU3_UNSUPPORTED_SET(fmi3SetUInt32, fmi3UInt32)
FMU3_UNSUPPORTED_SET(fmi3SetUInt64, fmi3UInt64)

/* Modelica enumeration variables are exported as FMI 3.0 <Enumeration>, which
 * are accessed through fmi3Get/SetInt64. OpenModelica stores enumerations in the
 * same integer storage as Int32 variables, so their value references live in the
 * integer block and map through FMI3_INTEGER_VR_OFFSET / omcGet/SetInteger, just
 * like fmi3GetInt32/fmi3SetInt32. */
fmi3Status fmi3GetInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Int64 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_INTEGER_VR_OFFSET);
      fmi3Int32 value;
      fmi3Status s = omcGetInteger(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[k] = (fmi3Int64)value;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3SetInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int64 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = (nValueReferences == 1) ? nValues : 1;
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference lvr = (fmi3ValueReference)((valueReferences[i] + j) - FMI3_INTEGER_VR_OFFSET);
      fmi3Int32 value = (fmi3Int32)values[k];
      fmi3Status s = omcSetInteger(c, &lvr, 1, &value);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
  }
  return fmi3OK;
}

/* A Modelica ExternalObject is an opaque handle (void*) constructed by its
 * constructor and stored in fmuData->simulationInfo->extObjs. It is exported as
 * an FMI 3.0 Binary variable whose value is the raw bytes of that handle. The
 * value reference is shifted by FMI3_BINARY_VR_OFFSET to recover the index into
 * the extObjs array. Each binary value is sizeof(void*) bytes. */
fmi3Status fmi3GetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, size_t valueSizes[], fmi3Binary values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  if (!c) return fmi3Error;
  if (nValueReferences > 0 && (nullPointer(c, "fmi3GetBinary", "vr[]", valueReferences) ||
      nullPointer(c, "fmi3GetBinary", "valueSizes[]", valueSizes) ||
      nullPointer(c, "fmi3GetBinary", "values[]", values)))
    return fmi3Error;
  /* one binary value per value reference (each external object is a scalar handle) */
  if (nValueReferences != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_BINARY_VR_OFFSET);
    if (lvr >= (fmi3ValueReference)c->fmuData->modelData->nExtObjs) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3GetBinary: illegal value reference %u.", valueReferences[i])
      return fmi3Error;
    }
    valueSizes[i] = sizeof(void*);
    values[i]     = (fmi3Binary)&c->fmuData->simulationInfo->extObjs[lvr];
    FILTERED_LOG(c, fmi3OK, LOG_FMI3_CALL, "fmi3GetBinary: #b%u# (%zu bytes)", valueReferences[i], valueSizes[i])
  }
  return fmi3OK;
}

fmi3Status fmi3SetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const size_t valueSizes[], const fmi3Binary values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  if (!c) return fmi3Error;
  if (nValueReferences > 0 && (nullPointer(c, "fmi3SetBinary", "vr[]", valueReferences) ||
      nullPointer(c, "fmi3SetBinary", "valueSizes[]", valueSizes) ||
      nullPointer(c, "fmi3SetBinary", "values[]", values)))
    return fmi3Error;
  if (nValueReferences != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_BINARY_VR_OFFSET);
    if (lvr >= (fmi3ValueReference)c->fmuData->modelData->nExtObjs) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3SetBinary: illegal value reference %u.", valueReferences[i])
      return fmi3Error;
    }
    /* the external object handle is a single void*; only that exact size is accepted */
    if (valueSizes[i] != sizeof(void*)) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3SetBinary: value reference %u expects %zu bytes, got %zu.", valueReferences[i], sizeof(void*), valueSizes[i])
      return fmi3Error;
    }
    memcpy(&c->fmuData->simulationInfo->extObjs[lvr], values[i], sizeof(void*));
    FILTERED_LOG(c, fmi3OK, LOG_FMI3_CALL, "fmi3SetBinary: #b%u# (%zu bytes)", valueReferences[i], valueSizes[i])
  }
  return fmi3OK;
}

/* Output clocks: each base clock of the model's clocked partitions is exported
 * as an FMI 3.0 output <Clock>. The value reference is shifted by
 * FMI3_CLOCK_VR_OFFSET to recover the base-clock index. The clocks are ticked by
 * the engine in internalEventUpdate (handleTimersFMI), which records the
 * activation in baseClocks[i].stats; a clock is "active" when it fired at the
 * current event time. */
fmi3Status fmi3GetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Clock values[])
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  double t, d;
  if (!c) return fmi3Error;
  if (nValueReferences > 0 && (nullPointer(c, "fmi3GetClock", "vr[]", valueReferences) ||
      nullPointer(c, "fmi3GetClock", "values[]", values)))
    return fmi3Error;
  t = c->fmuData->localData[0]->timeValue;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_CLOCK_VR_OFFSET);
    BASECLOCK_DATA* bc;
    if (lvr >= (fmi3ValueReference)c->fmuData->modelData->nBaseClocks) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3GetClock: illegal value reference %u.", valueReferences[i])
      return fmi3Error;
    }
    bc = &c->fmuData->simulationInfo->baseClocks[lvr];
    d = bc->stats.lastActivationTime - t;
    if (d < 0) d = -d;
    values[i] = (bc->stats.count > 0 && d <= 1e-10) ? fmi3ClockActive : fmi3ClockInactive;
    FILTERED_LOG(c, fmi3OK, LOG_FMI3_CALL, "fmi3GetClock: #c%u# = %d", valueReferences[i], (int)values[i])
  }
  return fmi3OK;
}

fmi3Status fmi3SetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Clock values[])
{
  (void)instance; (void)valueReferences; (void)values;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

/* ---------------------------------------------------------------------------
 * Getting Variable Dependency Information (not provided per-element)
 * ------------------------------------------------------------------------- */
fmi3Status fmi3GetNumberOfVariableDependencies(fmi3Instance instance, fmi3ValueReference valueReference,
    size_t* nDependencies)
{
  (void)instance; (void)valueReference; (void)nDependencies;
  return fmi3Error;
}

fmi3Status fmi3GetVariableDependencies(fmi3Instance instance, fmi3ValueReference dependent,
    size_t elementIndicesOfDependent[], fmi3ValueReference independents[],
    size_t elementIndicesOfIndependents[], fmi3DependencyKind dependencyKinds[], size_t nDependencies)
{
  (void)instance; (void)dependent; (void)elementIndicesOfDependent; (void)independents;
  (void)elementIndicesOfIndependents; (void)dependencyKinds; (void)nDependencies;
  return fmi3Error;
}

/* ---------------------------------------------------------------------------
 * Getting and setting the internal FMU state (not yet supported)
 * ------------------------------------------------------------------------- */
/* FMU state get/set/free and (de)serialization. These delegate to the native
 * omc*FMUstate helpers above, which snapshot/restore the simulation ring buffer
 * (timeValue + real/integer/boolean/string variables) and the model parameters. */
fmi3Status fmi3GetFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  if (nullPointer(c, "fmi3GetFMUState", "FMUState", FMUState)) return fmi3Error;
  return omcGetFMUstate(c, FMUState);
}

fmi3Status fmi3SetFMUState(fmi3Instance instance, fmi3FMUState FMUState)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  if (nullPointer(c, "fmi3SetFMUState", "FMUState", FMUState)) return fmi3Error;
  return omcSetFMUstate(c, FMUState);
}

fmi3Status fmi3FreeFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  /* per the FMI spec freeing a NULL state (or *FMUState == NULL) is a no-op */
  if (FMUState == NULL || *FMUState == NULL) return fmi3OK;
  return omcFreeFMUstate(c, FMUState);
}

fmi3Status fmi3SerializedFMUStateSize(fmi3Instance instance, fmi3FMUState FMUState, size_t* size)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  if (nullPointer(c, "fmi3SerializedFMUStateSize", "FMUState", FMUState) ||
      nullPointer(c, "fmi3SerializedFMUStateSize", "size", size)) return fmi3Error;
  return omcSerializedFMUstateSize(c, FMUState, size);
}

fmi3Status fmi3SerializeFMUState(fmi3Instance instance, fmi3FMUState FMUState, fmi3Byte serializedState[], size_t size)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  if (nullPointer(c, "fmi3SerializeFMUState", "FMUState", FMUState) ||
      nullPointer(c, "fmi3SerializeFMUState", "serializedState", serializedState)) return fmi3Error;
  return omcSerializeFMUstate(c, FMUState, serializedState, size);
}

fmi3Status fmi3DeserializeFMUState(fmi3Instance instance, const fmi3Byte serializedState[], size_t size, fmi3FMUState* FMUState)
{
  ModelInstance* c = fmu3InnerComp(instance);
  if (!c) return fmi3Error;
  if (nullPointer(c, "fmi3DeserializeFMUState", "serializedState", serializedState) ||
      nullPointer(c, "fmi3DeserializeFMUState", "FMUState", FMUState)) return fmi3Error;
  return omcDeSerializeFMUstate(c, serializedState, size, FMUState);
}

/* ---------------------------------------------------------------------------
 * Partial derivatives
 * ------------------------------------------------------------------------- */
fmi3Status fmi3GetDirectionalDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[],
    size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[],
    size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  fmi3ValueReference *u, *k;
  fmi3Status status;
  if (!c) return fmi3Error;
  if (nUnknowns == 0) return fmi3OK;
  if (nullPointer(c, "fmi3GetDirectionalDerivative", "unknowns", unknowns) ||
      nullPointer(c, "fmi3GetDirectionalDerivative", "knowns", knowns) ||
      nullPointer(c, "fmi3GetDirectionalDerivative", "seed", seed) ||
      nullPointer(c, "fmi3GetDirectionalDerivative", "sensitivity", sensitivity))
    return fmi3Error;
  /* the directional-derivative unknowns (derivatives/outputs) and knowns
     (states/inputs) are all Float64 variables. Recover the per-real-type value
     reference understood by omcGetDirectionalDerivative by subtracting the real
     base-type offset. The FMI 3.0 seed maps to dvKnown and sensitivity to
     dvUnknown. */
  if (nSeed != nKnowns || nSensitivity != nUnknowns) return fmi3Error;
  u = (fmi3ValueReference*) calloc(nUnknowns, sizeof(fmi3ValueReference));
  k = (fmi3ValueReference*) calloc(nKnowns,   sizeof(fmi3ValueReference));
  if (!u || !k) { free(u); free(k); return fmi3Error; }
  for (i = 0; i < nUnknowns; i++) u[i] = (fmi3ValueReference)(unknowns[i] - FMI3_REAL_VR_OFFSET);
  for (i = 0; i < nKnowns;   i++) k[i] = (fmi3ValueReference)(knowns[i]   - FMI3_REAL_VR_OFFSET);
  status = omcGetDirectionalDerivative(c, u, nUnknowns, k, nKnowns, seed, sensitivity);
  free(u);
  free(k);
  return status;
}

fmi3Status fmi3GetAdjointDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[],
    size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[],
    size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{
  (void)instance; (void)unknowns; (void)nUnknowns; (void)knowns; (void)nKnowns;
  (void)seed; (void)nSeed; (void)sensitivity; (void)nSensitivity;
  return fmi3Error;
}

/* ---------------------------------------------------------------------------
 * Configuration / Reconfiguration Mode (no structural parameters)
 * ------------------------------------------------------------------------- */
fmi3Status fmi3EnterConfigurationMode(fmi3Instance instance) { (void)instance; return fmi3OK; }
fmi3Status fmi3ExitConfigurationMode(fmi3Instance instance) { (void)instance; return fmi3OK; }

/* ---------------------------------------------------------------------------
 * Clock related functions (no clocks exposed yet)
 * ------------------------------------------------------------------------- */
fmi3Status fmi3GetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 intervals[], fmi3IntervalQualifier qualifiers[])
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  if (!c) return fmi3Error;
  if (nValueReferences > 0 && (nullPointer(c, "fmi3GetIntervalDecimal", "vr[]", valueReferences) ||
      nullPointer(c, "fmi3GetIntervalDecimal", "intervals[]", intervals)))
    return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_CLOCK_VR_OFFSET);
    BASECLOCK_DATA* bc;
    if (lvr >= (fmi3ValueReference)c->fmuData->modelData->nBaseClocks) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3GetIntervalDecimal: illegal value reference %u.", valueReferences[i])
      return fmi3Error;
    }
    bc = &c->fmuData->simulationInfo->baseClocks[lvr];
    if (bc->isEventClock) {
      /* triggered clock: the interval is only meaningful once it has fired */
      intervals[i] = (bc->stats.count > 0) ? bc->stats.previousInterval : 0.0;
      if (qualifiers) qualifiers[i] = (bc->stats.count > 0) ? fmi3IntervalChanged : fmi3IntervalNotYetKnown;
    } else {
      /* periodic clock: constant period */
      intervals[i] = bc->interval;
      if (qualifiers) qualifiers[i] = fmi3IntervalUnchanged;
    }
  }
  return fmi3OK;
}

fmi3Status fmi3GetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[], fmi3IntervalQualifier qualifiers[])
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  if (!c) return fmi3Error;
  if (nValueReferences > 0 && (nullPointer(c, "fmi3GetIntervalFraction", "vr[]", valueReferences) ||
      nullPointer(c, "fmi3GetIntervalFraction", "counters[]", counters) ||
      nullPointer(c, "fmi3GetIntervalFraction", "resolutions[]", resolutions)))
    return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_CLOCK_VR_OFFSET);
    BASECLOCK_DATA* bc;
    if (lvr >= (fmi3ValueReference)c->fmuData->modelData->nBaseClocks) {
      FILTERED_LOG(c, fmi3Error, LOG_STATUSERROR, "fmi3GetIntervalFraction: illegal value reference %u.", valueReferences[i])
      return fmi3Error;
    }
    bc = &c->fmuData->simulationInfo->baseClocks[lvr];
    counters[i]    = (fmi3UInt64)bc->intervalCounter;
    resolutions[i] = (fmi3UInt64)bc->resolution;
    if (qualifiers) qualifiers[i] = fmi3IntervalUnchanged;
  }
  return fmi3OK;
}

fmi3Status fmi3GetShiftDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 shifts[])
{ (void)instance; (void)valueReferences; (void)shifts; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3GetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[])
{ (void)instance; (void)valueReferences; (void)counters; (void)resolutions; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3SetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 intervals[])
{ (void)instance; (void)valueReferences; (void)intervals; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3SetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{ (void)instance; (void)valueReferences; (void)counters; (void)resolutions; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3SetShiftDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 shifts[])
{ (void)instance; (void)valueReferences; (void)shifts; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3SetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{ (void)instance; (void)valueReferences; (void)counters; (void)resolutions; return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3EvaluateDiscreteStates(fmi3Instance instance)
{
  (void)instance;
  return fmi3OK;
}

fmi3Status fmi3UpdateDiscreteStates(fmi3Instance instance, fmi3Boolean* discreteStatesNeedUpdate,
    fmi3Boolean* terminateSimulation, fmi3Boolean* nominalsOfContinuousStatesChanged,
    fmi3Boolean* valuesOfContinuousStatesChanged, fmi3Boolean* nextEventTimeDefined,
    fmi3Float64* nextEventTime)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  ModelInstance* c = fmu3InnerComp(instance);
  EventInfo eventInfo;
  fmi3Status status;
  if (!inst || !c) return fmi3Error;
  memset(&eventInfo, 0, sizeof(eventInfo));
  if (inst->interfaceType == FMI3_INTERFACE_CS) {
    /* Co-Simulation Event Mode: run one event-update iteration directly. The
       instance stays in Step Mode, so the Model-Exchange-only state checks of
       omcNewDiscreteStates must be bypassed. Carry over any pending next event
       time so time events keep being scheduled. */
    ModelInstance *comp = (ModelInstance *)c;
    eventInfo.nextEventTimeDefined = comp->eventInfo.nextEventTimeDefined;
    eventInfo.nextEventTime        = comp->eventInfo.nextEventTime;
    status = internalEventUpdate(comp, &eventInfo);
    comp->eventInfo = eventInfo;
  } else {
    status = omcNewDiscreteStates(c, &eventInfo);
  }
  if (discreteStatesNeedUpdate)          *discreteStatesNeedUpdate = eventInfo.newDiscreteStatesNeeded ? fmi3True : fmi3False;
  if (terminateSimulation)               *terminateSimulation = eventInfo.terminateSimulation ? fmi3True : fmi3False;
  if (nominalsOfContinuousStatesChanged) *nominalsOfContinuousStatesChanged = eventInfo.nominalsOfContinuousStatesChanged ? fmi3True : fmi3False;
  if (valuesOfContinuousStatesChanged)   *valuesOfContinuousStatesChanged = eventInfo.valuesOfContinuousStatesChanged ? fmi3True : fmi3False;
  if (nextEventTimeDefined)              *nextEventTimeDefined = eventInfo.nextEventTimeDefined ? fmi3True : fmi3False;
  if (nextEventTime)                     *nextEventTime = (fmi3Float64)eventInfo.nextEventTime;
  return (fmi3Status)status;
}

/* ---------------------------------------------------------------------------
 * Functions for Model Exchange
 * ------------------------------------------------------------------------- */
fmi3Status fmi3EnterContinuousTimeMode(fmi3Instance instance)
{
  return (fmi3Status)omcEnterContinuousTimeMode(fmu3InnerComp(instance));
}

fmi3Status fmi3CompletedIntegratorStep(fmi3Instance instance, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{
  ModelInstance* c = fmu3InnerComp(instance);
  fmi3Boolean enterEventMode2 = fmi3False;
  fmi3Boolean terminate2 = fmi3False;
  fmi3Status status = omcCompletedIntegratorStep(c, noSetFMUStatePriorToCurrentPoint, &enterEventMode2, &terminate2);
  if (enterEventMode)      *enterEventMode = enterEventMode2 ? fmi3True : fmi3False;
  if (terminateSimulation) *terminateSimulation = terminate2 ? fmi3True : fmi3False;
  return (fmi3Status)status;
}

fmi3Status fmi3SetTime(fmi3Instance instance, fmi3Float64 time)
{
  return (fmi3Status)omcSetTime(fmu3InnerComp(instance), (fmi3Float64)time);
}

fmi3Status fmi3SetContinuousStates(fmi3Instance instance, const fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  return (fmi3Status)omcSetContinuousStates(fmu3InnerComp(instance), (const fmi3Float64*)continuousStates, nContinuousStates);
}

fmi3Status fmi3GetContinuousStateDerivatives(fmi3Instance instance, fmi3Float64 derivatives[], size_t nContinuousStates)
{
  return (fmi3Status)omcGetDerivatives(fmu3InnerComp(instance), (fmi3Float64*)derivatives, nContinuousStates);
}

fmi3Status fmi3GetEventIndicators(fmi3Instance instance, fmi3Float64 eventIndicators[], size_t nEventIndicators)
{
  return (fmi3Status)omcGetEventIndicators(fmu3InnerComp(instance), (fmi3Float64*)eventIndicators, nEventIndicators);
}

fmi3Status fmi3GetContinuousStates(fmi3Instance instance, fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  return (fmi3Status)omcGetContinuousStates(fmu3InnerComp(instance), (fmi3Float64*)continuousStates, nContinuousStates);
}

fmi3Status fmi3GetNominalsOfContinuousStates(fmi3Instance instance, fmi3Float64 nominals[], size_t nContinuousStates)
{
  return (fmi3Status)omcGetNominalsOfContinuousStates(fmu3InnerComp(instance), (fmi3Float64*)nominals, nContinuousStates);
}

fmi3Status fmi3GetNumberOfEventIndicators(fmi3Instance instance, size_t* nEventIndicators)
{
  (void)instance;
  if (!nEventIndicators) return fmi3Error;
  *nEventIndicators = (size_t)NUMBER_OF_EVENT_INDICATORS;
  return fmi3OK;
}

fmi3Status fmi3GetNumberOfContinuousStates(fmi3Instance instance, size_t* nContinuousStates)
{
  (void)instance;
  if (!nContinuousStates) return fmi3Error;
  *nContinuousStates = (size_t)NUMBER_OF_STATES;
  return fmi3OK;
}

/* ---------------------------------------------------------------------------
 * Functions for Co-Simulation
 * ------------------------------------------------------------------------- */
fmi3Status fmi3EnterStepMode(fmi3Instance instance)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  if (!comp) return fmi3Error;
  /* The Co-Simulation instance never left Step Mode (model_state_cs_step_complete);
     the continuous states and event indicators changed by the event are re-read
     at the start of the next fmi3DoStep, so nothing needs to be restored here. */
  return fmi3OK;
}

fmi3Status fmi3GetOutputDerivatives(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int32 orders[], fmi3Float64 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  (void)nValues;
  if (!c) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference lvr = (fmi3ValueReference)(valueReferences[i] - FMI3_REAL_VR_OFFSET);
    fmi3Int32 order = (fmi3Int32)orders[i];
    fmi3Float64 value;
    fmi3Status s = omcGetRealOutputDerivatives(c, &lvr, 1, &order, &value);
    if (s > fmi3Warning) return (fmi3Status)s;
    values[i] = (fmi3Float64)value;
  }
  return fmi3OK;
}

fmi3Status fmi3DoStep(fmi3Instance instance, fmi3Float64 currentCommunicationPoint,
    fmi3Float64 communicationStepSize, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean* eventHandlingNeeded, fmi3Boolean* terminateSimulation, fmi3Boolean* earlyReturn,
    fmi3Float64* lastSuccessfulTime)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  ModelInstance* c = fmu3InnerComp(instance);
  fmi3Boolean eventEncountered = fmi3False;
  fmi3Boolean terminate2 = fmi3False;
  fmi3Boolean early2 = fmi3False;
  fmi3Float64 lastTime = currentCommunicationPoint + communicationStepSize;
  fmi3Status status;
  if (!inst) return fmi3Error;
  status = fmu3DoStepInternal(c, (fmi3Float64)currentCommunicationPoint,
      (fmi3Float64)communicationStepSize, noSetFMUStatePriorToCurrentPoint,
      inst->eventModeUsed ? fmi3True : fmi3False,
      inst->earlyReturnAllowed ? fmi3True : fmi3False,
      &eventEncountered, &terminate2, &early2, &lastTime);
  if (eventHandlingNeeded)  *eventHandlingNeeded = eventEncountered ? fmi3True : fmi3False;
  if (terminateSimulation)  *terminateSimulation = terminate2 ? fmi3True : fmi3False;
  if (earlyReturn)          *earlyReturn = early2 ? fmi3True : fmi3False;
  if (lastSuccessfulTime)   *lastSuccessfulTime = (fmi3Float64)lastTime;
  return (fmi3Status)status;
}

/* ---------------------------------------------------------------------------
 * Functions for Scheduled Execution
 * ------------------------------------------------------------------------- */
fmi3Status fmi3ActivateModelPartition(fmi3Instance instance, fmi3ValueReference clockReference,
    fmi3Float64 activationTime)
{
  /* Scheduled Execution: the simulation algorithm activates one model partition
     at a time. Each base clock is one model partition (its value reference is
     FMI3_CLOCK_VR_OFFSET + base-clock index, the same scheme as fmi3GetClock).
     The simple strategy here advances the model to the activation time and runs
     that clocked partition (its synchronous equations + interval update) via the
     same engine used by Model Exchange event mode. */
  ModelInstance* comp = fmu3InnerComp(instance);
  threadData_t *threadData;
  jmp_buf *old_jmp;
  fmi3ValueReference lvr;
  int done = 0;

  if (!comp) {
    return fmi3Error;
  }

  lvr = (fmi3ValueReference)(clockReference - FMI3_CLOCK_VR_OFFSET);
  if (lvr >= (fmi3ValueReference)comp->fmuData->modelData->nBaseClocks) {
    FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "fmi3ActivateModelPartition: illegal clock reference %u.", clockReference)
    return fmi3Error;
  }

  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "fmi3ActivateModelPartition: #c%u# at t=%g", clockReference, activationTime)

  /* Flush any pending continuous/algebraic evaluation first (manages its own
     thread data). This must happen before the clocked partition runs: otherwise
     the deferred update would be triggered by the next fmi3Get* and would
     overwrite the partition's freshly computed clocked outputs. */
  if (updateIfNeeded(comp, "fmi3ActivateModelPartition") != fmi3OK) {
    return fmi3Error;
  }

  threadData = comp->threadData;
  old_jmp = threadData->mmc_jumper;
  setThreadData(comp);
  MemPoolState mem_pool_state = omc_util_get_pool_state();
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

    {
      DATA* fmuData = comp->fmuData;
      BASECLOCK_DATA* bc = &fmuData->simulationInfo->baseClocks[lvr];

      /* Advance to the activation time and run this base clock's partition. We
         drive the partition directly rather than via handleBaseClock(): in
         Scheduled Execution the importer owns the scheduling, so we don't want
         handleBaseClock's internal sub-clock timer bookkeeping (nor its
         initialization-time special case, which would defer the first tick to an
         event loop that does not exist here). We still update the clock stats so
         fmi3GetClock / fmi3GetInterval* report this activation. */
      fmuData->localData[0]->timeValue = activationTime;

      bc->stats.count++;
      if (bc->isEventClock) {
        if (bc->stats.count > 1) {
          bc->stats.previousInterval = activationTime - bc->stats.lastActivationTime;
        }
      } else {
        bc->stats.previousInterval = bc->interval;
      }
      bc->stats.lastActivationTime = activationTime;
      if (bc->subClocks != NULL && bc->nSubClocks > 0) {
        SUBCLOCK_DATA* sc = &bc->subClocks[0];
        sc->stats.count++;
        sc->stats.previousInterval = bc->stats.previousInterval;
        sc->stats.lastActivationTime = activationTime;
      }

      fmuData->callback->function_equationsSynchronous(fmuData, comp->threadData, (long)lvr, 0);
      if (!bc->isEventClock) {
        fmuData->callback->function_updateSynchronous(fmuData, comp->threadData, (long)lvr);
      }

      /* The partition's clocked outputs are now current; keep them. Clearing the
         flag stops the next fmi3Get* from re-running the continuous/algebraic
         evaluation (which would clobber the just-computed clocked values). */
      comp->_need_update = 0;
    }
    done = 1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;
  omc_util_restore_pool_state(mem_pool_state);
  resetThreadData(comp);

  if (done) {
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "fmi3ActivateModelPartition: terminated by an assertion.")
  return fmi3Error;
}
