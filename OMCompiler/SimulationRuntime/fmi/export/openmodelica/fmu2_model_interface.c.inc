/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "fmu2_model_interface.h"
#include "fmu_read_flags.h"
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
#include "../simulation/solver/cvode_solver.h"
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
#include "../simulation/solver/fmi_events.h"
#include "../simulation/simulation_info_json.h"
#include "../simulation/simulation_input_xml.h"
#include "../simulation/solver/synchronous.h"
#include "../simulation/options.h"
#include "../util/simulation_options.h"
#include "../util/omc_error.h"

/*
DLLExport pthread_key_t fmu2_thread_data_key;
*/

fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex);

static fmi2String logCategoriesNames[] = {"logEvents", "logSingularLinearSystems", "logNonlinearSystems", "logDynamicStateSelection",
    "logStatusWarning", "logStatusDiscard", "logStatusError", "logStatusFatal", "logStatusPending", "logAll", "logFmi2Call"};

// macro to be used to log messages. The macro check if current
// log category is valid and, if true, call the logger provided by simulator.
#define FILTERED_LOG(instance, status, categoryIndex, message, ...) if (isCategoryLogged(instance, categoryIndex)) { \
    instance->functions->logger(instance->functions->componentEnvironment, instance->instanceName, status, \
        logCategoriesNames[categoryIndex], message, ##__VA_ARGS__); }

// array of value references of states
#if NUMBER_OF_STATES>0
fmi2ValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmi2ValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif

// ---------------------------------------------------------------------------
// Private helpers used below to validate function arguments
// ---------------------------------------------------------------------------
static fmi2Boolean isModelExchange(ModelInstance *comp)
{
  return (fmi2ModelExchange == comp->type);
}

static fmi2Boolean isCoSimulation(ModelInstance *comp)
{
  return (fmi2CoSimulation == comp->type);
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

static fmi2Boolean invalidNumber(ModelInstance *comp, const char *func, const char *arg, int n, int nExpected)
{
  if (n != nExpected)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Invalid argument %s = %d. Expected %d.", func, arg, n, nExpected)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Boolean invalidState(ModelInstance *comp, const char *func, int meStates, int csStates)
{
  if (!comp)
    return fmi2True;

  if (isModelExchange(comp))
  {
    if (!(comp->state & meStates))
    {
      FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Illegal model exchange call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmi2True;
    }
  }

  if (isCoSimulation(comp))
  {
    if (!(comp->state & csStates))
    {
      FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Illegal co-simulation call sequence. %s is not allowed in %s state.", func, func, stateToString(comp))
      comp->state = model_state_error;
      return fmi2True;
    }
  }

  return fmi2False;
}

static fmi2Boolean nullPointer(ModelInstance* comp, const char *func, const char *arg, const void *p)
{
  if (!p)
  {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Invalid argument %s = NULL.", func, arg)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Boolean vrOutOfRange(ModelInstance *comp, const char *func, fmi2ValueReference vr, int end)
{
  if (vr >= end) {
    comp->state = model_state_error;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Illegal value reference %u.", func, vr)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Status unsupportedFunction(ModelInstance *comp, const char *func)
{
  FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Function not implemented.", func)
  return fmi2Error;
}

// ---------------------------------------------------------------------------
// Private helpers logger
// ---------------------------------------------------------------------------
// return fmi2True if logging category is on. Else return fmi2False.
fmi2Boolean isCategoryLogged(ModelInstance *comp, int categoryIndex)
{
  if (categoryIndex < NUMBER_OF_CATEGORIES && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
    return fmi2True;
  }
  return fmi2False;
}

static void omc_assert_fmi_common(threadData_t *threadData, fmi2Status status, int categoryIndex, FILE_INFO info, const char *msg, va_list args)
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
  omc_assert_fmi_common(threadData, fmi2Error, LOG_STATUSERROR, info, msg, args);
  va_end(args);
  MMC_THROW_INTERNAL();
}

static void omc_assert_fmi_warning(FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  omc_assert_fmi_common((threadData_t*)pthread_getspecific(mmc_thread_data_key), fmi2Warning, LOG_STATUSWARNING, info, msg, args);
  va_end(args);
}

// ---------------------------------------------------------------------------
// Private helpers functions
// ---------------------------------------------------------------------------
static inline void resetThreadData(ModelInstance* comp)
{
  if (comp->threadDataParent) {
    pthread_setspecific(mmc_thread_data_key, comp->threadDataParent);
  }
  /* Clear the extra memory pools */
  omc_alloc_interface.collect_a_little();
}

static inline void setThreadData(ModelInstance* comp)
{
  if (comp->threadDataParent) {
    pthread_setspecific(mmc_thread_data_key, comp->threadData);
  }
}

fmi2Status internalEventUpdate(fmi2Component c, fmi2EventInfo* eventInfo)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  fmi2Real nextSampleEvent;
  fmi2Boolean nextSampleEventDefined;
  fmi2Boolean nextTimerDefined;
  fmi2Real nextTimerActivationTime;
  int syncRet;

  if (nullPointer(comp, "internalEventUpdate", "eventInfo", eventInfo)) {
    return fmi2Error;
  }

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "internalEventUpdate: Start Event Update! Next Sample Event %g", eventInfo->nextEventTime)

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 1)) {
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "internalEventUpdate: Need to iterate state values changed!")
      /* if new set is calculated reinit the solver */
      eventInfo->valuesOfContinuousStatesChanged = fmi2True;
    }
#endif
    storePreValues(comp->fmuData);

    /* activate sample event */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i) {
      if (comp->fmuData->simulationInfo->nextSampleTimes[i] <= comp->fmuData->localData[0]->timeValue) {
        comp->fmuData->simulationInfo->samples[i] = 1;
        infoStreamPrint(LOG_EVENTS, 0, "[%ld] sample(%g, %g)", comp->fmuData->modelData->samplesInfo[i].index, comp->fmuData->modelData->samplesInfo[i].start, comp->fmuData->modelData->samplesInfo[i].interval);
      }
    }

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
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "internalEventUpdate: Need to iterate(discrete changes)!")
      eventInfo->newDiscreteStatesNeeded = fmi2True;
      eventInfo->valuesOfContinuousStatesChanged = fmi2True;
      eventInfo->terminateSimulation = fmi2False;
    } else {
      eventInfo->newDiscreteStatesNeeded = fmi2False;
      eventInfo->terminateSimulation = fmi2False;
    }
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "internalEventUpdate: newDiscreteStatesNeeded %s",eventInfo->newDiscreteStatesNeeded?"true":"false");

    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    /* TODO: check the event iteration for relation
     * in fmi2 import and export. This is an workaround,
     * since the iteration seem not starting.
     */
    storePreValues(comp->fmuData);
    updateRelationsPre(comp->fmuData);

    nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);

    /* Get next event time */
    if (nextSampleEventDefined && !nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi2True;
      eventInfo->nextEventTime = nextSampleEvent;
    }
    else if (!nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi2True;
      eventInfo->nextEventTime = nextTimerActivationTime;
    }
    else if (nextSampleEventDefined && nextTimerDefined) {
      eventInfo->nextEventTimeDefined = fmi2True;
      eventInfo->nextEventTime = fmin(nextSampleEvent,nextTimerActivationTime);
    }
    else {
      if (eventInfo->nextEventTime <= comp->fmuData->localData[0]->timeValue) {
        eventInfo->nextEventTimeDefined = fmi2False;
      }
    }
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "internalEventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime)

    done=1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  resetThreadData(comp);

  if (done) {
    return fmi2OK;
  }
  FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "internalEventUpdate: terminated by an assertion.")
  comp->_need_update = 1;
  return fmi2Error;
}


fmi2Status internalEventIteration(fmi2Component c, fmi2EventInfo *eventInfo)
{
  fmi2Status status = fmi2OK;
  eventInfo->newDiscreteStatesNeeded = fmi2True;
  eventInfo->terminateSimulation     = fmi2False;
  while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation) {
    status = internalEventUpdate((ModelInstance *)c, eventInfo);
  }
  return status;
}

/**
 * @brief Helper function for fmi2GetXXX to update the component if needed.
 *
 * @param comp          FMI component
 * @param func          Name of fmi2GetXXX function calling this function.
 * @return fmi2Status   Returns fmi2Error if an error was caught, fmi2OK otherwise.
 */
fmi2Status updateIfNeeded(ModelInstance *comp, const char *func)
{
  /* Variables */
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;
  int success = 0;

  if (comp->_need_update)
  {
    setThreadData(comp);

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

    resetThreadData(comp);
    if (!success)
    {
      FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "%s: terminated by an assertion.", func)
      // TODO: Check if fmi2Error or fmi2Discard should be returned
      return fmi2Error;
    }
  }

  return fmi2OK;
}


/***************************************************
Common Functions
****************************************************/
const char* fmi2GetTypesPlatform()
{
  return fmi2TypesPlatform;
}

const char* fmi2GetVersion()
{
  return fmi2Version;
}

fmi2Status fmi2SetDebugLogging(fmi2Component c, fmi2Boolean loggingOn, size_t nCategories, const fmi2String categories[])
{
  int i, j;
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "fmi2SetDebugLogging", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_in_progress|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi2Error;

  comp->loggingOn = loggingOn;
  for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
    comp->logCategories[j] = fmi2False;
  }
  for (i = 0; i < nCategories; i++) {
    fmi2Boolean categoryFound = fmi2False;
    for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
      if (strcmp(logCategoriesNames[j], categories[i]) == 0) {
        comp->logCategories[j] = loggingOn;
        categoryFound = fmi2True;
        break;
      }
    }
    if (!categoryFound) {
      comp->functions->logger(comp->componentEnvironment, comp->instanceName, fmi2Warning, logCategoriesNames[LOG_STATUSERROR],
          "logging category '%s' is not supported by model", categories[i]);
    }
  }

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetDebugLogging")
  return fmi2OK;
}

fmi2Component fmi2Instantiate(fmi2String instanceName, fmi2Type fmuType, fmi2String fmuGUID, fmi2String fmuResourceLocation, const fmi2CallbackFunctions* functions,
    fmi2Boolean visible, fmi2Boolean loggingOn)
{
  /*
  TODO: We should set the interface, but we can't until it's no longer a global variable.
  * The problem is that we might overwrite the main simulation's copy of the interface...
  */
  threadData_t *threadDataParent = (threadData_t*) pthread_getspecific(mmc_thread_data_key);
  ModelInstance *comp;
  if (!functions->logger) {
    return NULL;
  }
  if (!functions->allocateMemory || !functions->freeMemory) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error", "fmi2Instantiate: Missing callback function.");
    return NULL;
  }
  if (0==threadDataParent) {
    /* We can only disable GC if the parent is not OM */
    omc_alloc_interface = omc_alloc_interface_pooled;
    /* TODO: omc_alloc_interface.malloc_uncollectable = functions->allocateMemory; // Note that the interface is wrong. Should pass threadData to all allocations instead, and have the interface in there. */
  }
  mmc_init_nogc();
  omc_alloc_interface.init();

  // ignoring arguments: fmuResourceLocation, visible
  if (!instanceName || strlen(instanceName) == 0) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error", "fmi2Instantiate: Missing instance name.");
    return NULL;
  }
  if (strcmp(fmuGUID, MODEL_GUID) != 0) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error", "fmi2Instantiate: Wrong GUID %s. Expected %s.", fmuGUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)functions->allocateMemory(1, sizeof(ModelInstance));
  if (comp) {
    DATA* fmudata = NULL;
    MODEL_DATA* modelData = NULL;
    SIMULATION_INFO* simInfo = NULL;
    threadData_t *threadData = NULL;
    int i;

    comp->state = model_state_start_end;
    comp->instanceName = (fmi2String)functions->allocateMemory(1 + strlen(instanceName), sizeof(char));
    comp->GUID = (fmi2String)functions->allocateMemory(1 + strlen(fmuGUID), sizeof(char));
    comp->functions = (fmi2CallbackFunctions*)functions->allocateMemory(1, sizeof(fmi2CallbackFunctions));
    fmudata = (DATA *)functions->allocateMemory(1, sizeof(DATA));
    modelData = (MODEL_DATA *)functions->allocateMemory(1, sizeof(MODEL_DATA));
    simInfo = (SIMULATION_INFO *)functions->allocateMemory(1, sizeof(SIMULATION_INFO));
    fmudata->modelData = modelData;
    fmudata->simulationInfo = simInfo;

    threadData = (threadData_t *)functions->allocateMemory(1, sizeof(threadData_t));
    memset(threadData, 0, sizeof(threadData_t));
    /*
    pthread_key_create(&fmu2_thread_data_key,NULL);
    pthread_setspecific(fmu2_thread_data_key, threadData);
    */

    comp->threadData = threadData;
    comp->threadDataParent = threadDataParent;
    comp->fmuData = fmudata;
    threadData->localRoots[LOCAL_ROOT_FMI_DATA] = comp;
    if (!comp->fmuData) {
      functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error", "fmi2Instantiate: Could not initialize the global data structure file.");
      return NULL;
    }
    // set all categories to on or off. fmi2SetDebugLogging should be called to choose specific categories.
    for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
      comp->logCategories[i] = loggingOn;
    }
  }

  if (!comp || !comp->instanceName || !comp->GUID || !comp->functions) {
    functions->logger(functions->componentEnvironment, instanceName, fmi2Error, "error", "fmi2Instantiate: Out of memory.");
    return NULL;
  }

  pthread_setspecific(mmc_thread_data_key, comp->threadData);
  omc_assert = omc_assert_fmi;
  omc_assert_warning = omc_assert_fmi_warning;

  strcpy((char*)comp->instanceName, (const char*)instanceName);
  comp->type = fmuType;
  strcpy((char*)comp->GUID, (const char*)fmuGUID);
  memcpy((void*)comp->functions, (void*)functions, sizeof(fmi2CallbackFunctions));
  comp->componentEnvironment = functions->componentEnvironment;
  comp->loggingOn = loggingOn;
  comp->state = model_state_instantiated;

  /* Add the resourcesDir */
  fmuResourceLocation = OpenModelica_parseFmuResourcePath(fmuResourceLocation);
  if (fmuResourceLocation) {
    comp->fmuData->modelData->resourcesDir = functions->allocateMemory(1 + strlen(fmuResourceLocation), sizeof(char));
    strcpy(comp->fmuData->modelData->resourcesDir, fmuResourceLocation);
  } else {
    FILTERED_LOG(comp, fmi2OK, LOG_STATUSWARNING, "fmi2Instantiate: Ignoring unknown resource URI: %s", fmuResourceLocation)
  }

  /* initialize modelData */
  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;
  fmu2_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  initializeDataStruc(comp->fmuData, comp->threadData);

  /* setup model data with default start data */
  setDefaultStartValues(comp);
  setAllParamsToStart(comp->fmuData);
  setAllVarsToStart(comp->fmuData);
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData, comp->fmuData->simulationInfo);

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
    comp->fmiDerJac = (ANALYTIC_JACOBIAN*) functions->allocateMemory(1, sizeof(ANALYTIC_JACOBIAN));
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
    comp->fmiDerJacInitialization = (ANALYTIC_JACOBIAN*) functions->allocateMemory(1, sizeof(ANALYTIC_JACOBIAN));
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

  comp->states = (fmi2Real*)functions->allocateMemory(NUMBER_OF_STATES, sizeof(fmi2Real));
  comp->states_der = (fmi2Real*)functions->allocateMemory(NUMBER_OF_STATES, sizeof(fmi2Real));
  comp->event_indicators = (fmi2Real*)functions->allocateMemory(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi2Real));
  comp->event_indicators_prev = (fmi2Real*)functions->allocateMemory(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi2Real));
  if (NUMBER_OF_REAL_INPUTS == 0)
    comp->input_real_derivative = NULL; // initialize to 0
  else
    comp->input_real_derivative = (fmi2Real*)functions->allocateMemory(NUMBER_OF_REAL_INPUTS, sizeof(fmi2Real));

  comp->_need_update = 1;

  /* Initialize solverInfo */
  if (fmi2CoSimulation == comp->type) {
    FMI2CS_initializeSolverData(comp);
  } else {
    comp->solverInfo = NULL;
  }

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Instantiate: GUID=%s", fmuGUID)
  resetThreadData(comp);
  return comp;
}

void fmi2FreeInstance(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  fmi2CallbackFreeMemory freeMemory = comp->functions->freeMemory;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  if (invalidState(comp, "fmi2FreeInstance", meStates, csStates))
    return;

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2FreeInstance")

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
  deInitializeDataStruc(comp->fmuData);     /* TODO: Use comp->functions->freeMemory inside deInitializeDataStruc to be FMI comform */

  /* Free jacobian data */
  if (comp->_has_jacobian == 1) {
    /* TODO: Use comp->functions->freeMemory insted of free,
     * but generated code uses malloc / calloc instead of comp->functions->allocateMemory */
    free(comp->fmiDerJac->seedVars); comp->fmiDerJac->seedVars = NULL;
    free(comp->fmiDerJac->resultVars); comp->fmiDerJac->resultVars = NULL;
    free(comp->fmiDerJac->tmpVars); comp->fmiDerJac->tmpVars = NULL;

    free(comp->fmiDerJac->sparsePattern->leadindex); comp->fmiDerJac->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJac->sparsePattern->index); comp->fmiDerJac->sparsePattern->index = NULL;
    free(comp->fmiDerJac->sparsePattern->colorCols); comp->fmiDerJac->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJac->sparsePattern); comp->fmiDerJac->sparsePattern = NULL;

    freeMemory(comp->fmiDerJac); comp->fmiDerJac=NULL;
  }


  /* Free jacobian data */
  if (comp->_has_jacobian_intialization == 1) {
    /* TODO: Use comp->functions->freeMemory insted of free,
     * but generated code uses malloc / calloc instead of comp->functions->allocateMemory */
    free(comp->fmiDerJacInitialization->seedVars); comp->fmiDerJacInitialization->seedVars = NULL;
    free(comp->fmiDerJacInitialization->resultVars); comp->fmiDerJacInitialization->resultVars = NULL;
    free(comp->fmiDerJacInitialization->tmpVars); comp->fmiDerJacInitialization->tmpVars = NULL;

    free(comp->fmiDerJacInitialization->sparsePattern->leadindex); comp->fmiDerJacInitialization->sparsePattern->leadindex = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->index); comp->fmiDerJacInitialization->sparsePattern->index = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern->colorCols); comp->fmiDerJacInitialization->sparsePattern->colorCols = NULL;
    free(comp->fmiDerJacInitialization->sparsePattern); comp->fmiDerJacInitialization->sparsePattern = NULL;

    freeMemory(comp->fmiDerJacInitialization); comp->fmiDerJacInitialization=NULL;
  }

  freeMemory(comp->states); comp->states = NULL;
  freeMemory(comp->states_der); comp->states_der = NULL;
  freeMemory(comp->event_indicators); comp->event_indicators = NULL;
  freeMemory(comp->event_indicators_prev); comp->event_indicators_prev = NULL;
  freeMemory(comp->input_real_derivative); comp->input_real_derivative = NULL;

  freeMemory(comp->fmuData->modelData->resourcesDir);
  if (comp->solverInfo) {
    FMI2CS_deInitializeSolverData(comp);
  }

  /* free simuation data */
  freeMemory(comp->fmuData->modelData);
  freeMemory(comp->fmuData->simulationInfo);

  /* free fmuData */
  freeMemory(comp->threadData);
  freeMemory(comp->fmuData);
  /* free instanceName & GUID */
  if (comp->instanceName) freeMemory((void*)comp->instanceName);
  if (comp->GUID) freeMemory((void*)comp->GUID);
  if (comp->functions) freeMemory((void*)comp->functions);
  /* free comp */
  freeMemory(comp);
  free_memory_pool();
}

fmi2Status fmi2SetupExperiment(fmi2Component c, fmi2Boolean toleranceDefined, fmi2Real tolerance, fmi2Real startTime, fmi2Boolean stopTimeDefined, fmi2Real stopTime)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "fmi2SetupExperiment", model_state_instantiated, model_state_instantiated))
    return fmi2Error;

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetupExperiment: toleranceDefined=%d tolerance=%g startTime=%g stopTimeDefined=%d stopTime=%g", toleranceDefined, tolerance,
      startTime, stopTimeDefined, stopTime)

  comp->toleranceDefined = toleranceDefined;
  comp->tolerance = tolerance;
  comp->startTime = startTime;
  comp->stopTimeDefined = stopTimeDefined;
  comp->stopTime = stopTime;
  return fmi2OK;
}

fmi2Status fmi2EnterInitializationMode(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "fmi2EnterInitializationMode", model_state_instantiated, model_state_instantiated))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EnterInitializationMode...")

  setZCtol(comp->tolerance); /* set zero-crossing tolerance */
  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);
  comp->state = model_state_initialization_mode;

  return fmi2OK;
}

fmi2Status fmi2ExitInitializationMode(fmi2Component c)
{
  fmi2Status res = fmi2Error;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  fmi2Real nextSampleEvent;
  fmi2Boolean nextSampleEventDefined;
  int done=0;

  threadData->currentErrorStage = ERROR_SIMULATION;
  if (invalidState(comp, "fmi2ExitInitializationMode", model_state_initialization_mode, model_state_initialization_mode))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2ExitInitializationMode...")

  setThreadData(comp);

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = threadData->simulationJumpBuffer;

  if (comp->_need_update)
  {
    if (initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0))
    {
      comp->state = model_state_error;
      resetThreadData(comp);
      FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2EnterInitializationMode: failed")
      return fmi2Error;
    }
  }

  /* use defined stopTime, if stopTimeDefined is given to calculate the sample events beforehand.
   * TODO: when stopTime is not defined we use an arbitrary constant 100.0, maybe issue a warning
   */
  initSample(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, comp->stopTimeDefined ? comp->stopTime : 100.0 /* default stopTime */);
  /* overwrite old values due to an event */
  overwriteOldSimulationData(comp->fmuData);

  comp->eventInfo.terminateSimulation = fmi2False;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmi2True;

  /* get next event time (sample calls) */
  nextSampleEventDefined = getNextSampleTimeFMU(comp->fmuData, &nextSampleEvent);
  if (nextSampleEventDefined)
  {
    comp->eventInfo.nextEventTimeDefined = fmi2True;
    comp->eventInfo.nextEventTime = nextSampleEvent;
    internalEventUpdate(comp, &(comp->eventInfo));
  }
  else
  {
    comp->eventInfo.nextEventTimeDefined = fmi2False;
  }
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EnterInitializationMode: succeed")
  res = fmi2OK;

  done = 1;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = old_jmp;

  if (!done)
  {
    FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2EnterInitializationMode: terminated by an assertion.")
  }

  comp->state = isCoSimulation(comp) ? model_state_cs_step_complete : model_state_me_event_mode;
  resetThreadData(comp);

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2ExitInitializationMode: succeed")
  return res;
}

/*
 * fmi2Status fmi2Terminate(fmi2Component c);
 * Informs the FMU that the simulation run is terminated. After calling this function, the final
 * values of all variables can be inquired with the fmi2GetXXX(..) functions. It is not allowed
 * to call this function after one of the functions returned with a status flag of fmi2Error or
 * fmi2Fatal.
 *
 */
fmi2Status fmi2Terminate(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2Terminate", model_state_me_event_mode|model_state_me_continuous_time_mode, model_state_cs_step_complete|model_state_cs_step_failed))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Terminate")

  setThreadData(comp);
  comp->state = model_state_terminated;
  resetThreadData(comp);
  return fmi2OK;
}

/*!
 * Is called by the environment to reset the FMU after a simulation run. Before starting a new run, fmi2EnterInitializationMode has to be called.
 */
fmi2Status fmi2Reset(fmi2Component c)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2Reset", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Reset")

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
    FMI2CS_deInitializeSolverData(comp);
  }

  /* Initialize modelData */
  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;
  fmu2_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  initializeDataStruc(comp->fmuData, comp->threadData);

  /* reset model data with default start data */
  setDefaultStartValues(comp);
  setAllParamsToStart(comp->fmuData);
  setAllVarsToStart(comp->fmuData);
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData, comp->fmuData->simulationInfo);
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
  if (fmi2CoSimulation == comp->type) {
    FMI2CS_initializeSolverData(comp);
  } else {
    comp->solverInfo = NULL;
  }

  comp->_need_update = 1;
  comp->state = model_state_instantiated;
  resetThreadData(comp);
  return fmi2OK;
}

fmi2Status fmi2GetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Real value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance*)c;

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
  // - stepFailed (8) always, but if status is other than fmi2Terminated, retrieved values are useable for debugging only
  // - stepCanceled (7) always, but retrieved values are usable for debugging only
  // - terminated
  // - error (7) always, but retrieved values are usable for debugging only
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;

  /* Check for valid call sequence */
  if (invalidState(comp, "fmi2GetReal", meStates, csStates))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "value[]", value))
    return fmi2Error;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, "fmi2GetReal") != fmi2OK)
    return fmi2Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetReal", vr[i], NUMBER_OF_REALS)) {
      return fmi2Error;
    }
    value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetReal: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2GetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Integer value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "fmi2GetInteger", meStates, csStates))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "value[]", value))
    return fmi2Error;

#if NUMBER_OF_INTEGERS > 0
  if (updateIfNeeded(comp, "fmi2GetInteger") != fmi2OK)
    return fmi2Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetInteger", vr[i], NUMBER_OF_INTEGERS)) {
      return fmi2Error;
    }
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetInteger: #i%u# = %d", vr[i], value[i])
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "fmi2GetBoolean", meStates, csStates))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "value[]", value))
    return fmi2Error;

#if NUMBER_OF_BOOLEANS > 0
  if (updateIfNeeded(comp, "fmi2GetBoolean") != fmi2OK)
    return fmi2Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetBoolean", vr[i], NUMBER_OF_BOOLEANS)) {
      return fmi2Error;
    }
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance *)c;

  /* Check for valid call sequence */
  int meStates = model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error;
  int csStates = model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error;
  if (invalidState(comp, "fmi2GetString", meStates, csStates))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2GetString", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2GetString", "value[]", value))
    return fmi2Error;

#if NUMBER_OF_STRINGS > 0
  if (updateIfNeeded(comp, "fmi2GetString") != fmi2OK)
    return fmi2Error;

  for (i=0; i<nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetString", vr[i], NUMBER_OF_STRINGS))
      return fmi2Error;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetString: #s%u# = '%s'", vr[i], value[i])
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real value[])
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

  if (invalidState(comp, "fmi2SetReal", meStates, csStates))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetReal", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetReal", "value[]", value))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetReal: nvr = %d", nvr)
  // no check whether setting the value is allowed in the current state
  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2SetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmi2Error;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetReal: #r%d# = %.16g", vr[i], value[i])
    if (setReal(comp, vr[i], value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2SetInteger", meStates, csStates))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetInteger", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetInteger", "value[]", value))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetInteger: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2SetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmi2Error;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetInteger: #i%d# = %d", vr[i], value[i])
    if (setInteger(comp, vr[i], value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Boolean value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2SetBoolean", meStates, csStates))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetBoolean", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetBoolean", "value[]", value))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetBoolean: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2SetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmi2Error;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false")
    if (setBoolean(comp, vr[i], value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String value[])
{
  int i, n;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2SetString", meStates, csStates))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetString", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetString", "value[]", value))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetString: nvr = %d", nvr)

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2SetString", vr[i], NUMBER_OF_STRINGS))
      return fmi2Error;
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetString: #s%d# = '%s'", vr[i], value[i])
    if (setString(comp, vr[i], value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2GetFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;
  fmi2CallbackFunctions* functions = (fmi2CallbackFunctions*) comp->functions;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2GetFMUstate", meStates, csStates))
    return fmi2Error;

  INTERNAL_FMU_STATE* internal_state = (INTERNAL_FMU_STATE*) functions->allocateMemory(1, sizeof(INTERNAL_FMU_STATE));
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
    tmpSimData.realVars = (modelica_real *)functions->allocateMemory(fmudata->modelData->nVariablesReal, sizeof(modelica_real));
    memcpy(tmpSimData.realVars, fmudata->localData[i]->realVars, sizeof(modelica_real)*fmudata->modelData->nVariablesReal);
    /* allocate memory for all Integer variables */
    tmpSimData.integerVars = (modelica_integer*)functions->allocateMemory(fmudata->modelData->nVariablesInteger, sizeof(modelica_integer));
    memcpy(tmpSimData.integerVars, fmudata->localData[i]->integerVars, sizeof(modelica_integer)*fmudata->modelData->nVariablesInteger);
    /* allocate memory for all boolean variables */
    tmpSimData.booleanVars = (modelica_boolean*)functions->allocateMemory(fmudata->modelData->nVariablesBoolean, sizeof(modelica_boolean));
    memcpy(tmpSimData.booleanVars, fmudata->localData[i]->booleanVars, sizeof(modelica_boolean)*fmudata->modelData->nVariablesBoolean);
    /* allocate memory for all string variables */
    #if !defined(OMC_NVAR_STRING) || OMC_NVAR_STRING>0
      tmpSimData.stringVars = (modelica_string*) omc_alloc_interface.malloc_uncollectable(fmudata->modelData->nVariablesString * sizeof(modelica_string));
      memcpy(tmpSimData.stringVars, fmudata->localData[i]->stringVars, sizeof(modelica_string)*fmudata->modelData->nVariablesString);
    #endif
    appendRingData(internal_state->simulationData, &tmpSimData);
  }

  // copy real parameter variables
  internal_state->realParameter = (modelica_real*)functions->allocateMemory(fmudata->modelData->nParametersReal, sizeof(modelica_real));
  for (int i = 0; i < fmudata->modelData->nParametersReal; ++i)
  {
    internal_state->realParameter[i] = fmudata->modelData->realParameterData[i].attribute.start;
    // infoStreamPrint(LOG_STDOUT, 0, "Copy Real parameter %s = %g", fmudata->modelData->realParameterData[i].info.name, internal_state->realParameters[i]);
  }

  // copy Integer parameter variables
  internal_state->integerParameter = (modelica_integer*)functions->allocateMemory(fmudata->modelData->nParametersInteger, sizeof(modelica_integer));
  for (int i = 0; i < fmudata->modelData->nParametersInteger; ++i)
  {
    internal_state->integerParameter[i] = fmudata->modelData->integerParameterData[i].attribute.start;
    // infoStreamPrint(LOG_STDOUT, 0, "Copy Integer parameter %s = %ld", fmudata->modelData->integerParameterData[i].info.name, internal_state->integerParameters[i]);
  }

  // copy Boolean parameter variables
  internal_state->booleanParameter = (modelica_boolean*)functions->allocateMemory(fmudata->modelData->nParametersBoolean, sizeof(modelica_boolean));
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

  // return the fmu state
  *FMUstate = (fmi2FMUstate) internal_state;
  return fmi2OK;
}

fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2GetFMUstate", meStates, csStates))
    return fmi2Error;

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

  return fmi2OK;
}

fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
{
  ModelInstance *comp = (ModelInstance *) c;
  fmi2CallbackFunctions* functions = (fmi2CallbackFunctions*) comp->functions;

  int meStates = model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode;
  int csStates = model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete;

  if (invalidState(comp, "fmi2FreeFMUstate", meStates, csStates))
    return fmi2Error;

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
    functions->freeMemory(*FMUstate);
    *FMUstate = NULL;
  }
  return fmi2OK;
}

fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate, size_t *size)
{
  return unsupportedFunction((ModelInstance *)c, "fmi2SerializedFMUstateSize");
}

fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate, fmi2Byte serializedState[], size_t size)
{
  return unsupportedFunction((ModelInstance *)c, "fmi2SerializeFMUstate");
}

fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte serializedState[], size_t size, fmi2FMUstate* FMUstate)
{
  return unsupportedFunction((ModelInstance *)c, "fmi2DeSerializeFMUstate");
}

fmi2Status fmi2GetDirectionalDerivativeForInitialization(fmi2Component c,
    const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
    const fmi2ValueReference vKnown_ref[] , size_t nKnown,
    const fmi2Real dvKnown[], fmi2Real dvUnknown[])
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
    if (vrOutOfRange(comp, "fmi2GetDirectionalDerivative input index during initialization", idx, independent))
      return fmi2Error;
    /* Put the supplied value in the seeds */
    comp->fmiDerJacInitialization->seedVars[idx] = dvKnown[i];
  }

  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  fmudata->callback->functionJacFMIDERINIT_column(fmudata, td, comp->fmiDerJacInitialization, NULL);
  resetThreadData(comp);

  /* Write the results to dvUnknown array */
  for (i=0;i<nUnknown; i++)
  {
    // map the Unknown ValueReferences to an internal index
    int idx = mapInitialUnknownsdependentIndex(vUnknown_ref[i]);
    if (vrOutOfRange(comp, "fmi2GetDirectionalDerivative output index during initialization", idx, dependent))
      return fmi2Error;
    dvUnknown[i] = comp->fmiDerJacInitialization->resultVars[idx];
  }

  return fmi2OK;
}

fmi2Status fmi2GetDirectionalDerivative(fmi2Component c,
    const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
    const fmi2ValueReference vKnown_ref[] , size_t nKnown,
    const fmi2Real dvKnown[], fmi2Real dvUnknown[])
{
  ModelInstance *comp = (ModelInstance *)c;
  DATA* fmudata = (DATA *) comp->fmuData;
  SIMULATION_INFO* simInfo = (SIMULATION_INFO*) fmudata->simulationInfo;
  MODEL_DATA* modelData = (MODEL_DATA*) fmudata->modelData;
  threadData_t* td = comp->threadData;

  int i,j;

  int independent = modelData->nStates+modelData->nInputVars;
  int dependent = modelData->nStates+modelData->nOutputVars;

  if (invalidState(comp, "fmi2GetDirectionalDerivative", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, model_state_initialization_mode|model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi2Error;
  if (!comp->_has_jacobian)
    return unsupportedFunction(comp, "fmi2GetDirectionalDerivative");

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetDirectionalDerivative")

  if (updateIfNeeded(comp, "fmi2GetDirectionalDerivative") != fmi2OK)
    return fmi2Error;

  if (model_state_initialization_mode == comp->state)
  {
    // directional derivative in initialization mode
    return fmi2GetDirectionalDerivativeForInitialization(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown);
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
    if (vrOutOfRange(comp, "fmi2GetDirectionalDerivative input index", idx, independent))
      return fmi2Error;
    /* Put the supplied value in the seeds */
    comp->fmiDerJac->seedVars[idx]=dvKnown[i];
  }
  /* Call the Jacobian evaluation function. This function evaluates the whole column of the Jacobian.
   * More efficient code could only evaluate the equations needed for the
   * known variables only */
  setThreadData(comp);
  fmudata->callback->functionJacFMIDER_column(fmudata, td, comp->fmiDerJac, NULL);
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
    if (vrOutOfRange(comp, "fmi2GetDirectionalDerivative output index", idx, dependent))
      return fmi2Error;
    dvUnknown[i] = comp->fmiDerJac->resultVars[idx];
  }
  /***************************************/
  return fmi2OK;
}



/***************************************************
Functions for FMI2 for Model Exchange
****************************************************/
fmi2Status fmi2EnterEventMode(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2EnterEventMode", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_EVENTS, "fmi2EnterEventMode")
  comp->state = model_state_me_event_mode;

  // Reset eventInfo
  comp->eventInfo.newDiscreteStatesNeeded = fmi2False;
  comp->eventInfo.terminateSimulation = fmi2False;
  comp->eventInfo.nominalsOfContinuousStatesChanged = fmi2False;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmi2False;
  comp->eventInfo.nextEventTimeDefined = fmi2False;
  comp->eventInfo.nextEventTime = 0;

  return fmi2OK;
}

fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo* eventInfo)
{
  ModelInstance *comp = (ModelInstance *)c;
  double nextSampleEvent = 0;
  fmi2Status returnValue = fmi2OK;

  if (invalidState(comp, "fmi2NewDiscreteStates", model_state_me_event_mode, 0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2NewDiscreteStates")

  returnValue = internalEventUpdate(comp, eventInfo);

  return returnValue;
}

fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2EnterContinuousTimeMode", model_state_me_event_mode, 0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EnterContinuousTimeMode")
  comp->state = model_state_me_continuous_time_mode;
  return fmi2OK;
}

fmi2Status internal_CompletedIntegratorStep(fmi2Component c, fmi2Boolean noSetFMUStatePriorToCurrentPoint, fmi2Boolean* enterEventMode, fmi2Boolean* terminateSimulation)
{
  int done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;

  if (nullPointer(comp, "fmi2CompletedIntegratorStep", "enterEventMode", enterEventMode))
    return fmi2Error;
  if (nullPointer(comp, "fmi2CompletedIntegratorStep", "terminateSimulation", terminateSimulation))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2CompletedIntegratorStep")

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
    comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeSpatialDistribution(comp->fmuData, threadData);
    storePreValues(comp->fmuData);
    *enterEventMode = fmi2False;
    *terminateSimulation = fmi2False;
    /******** check state selection ********/
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 0))
    {
      /* if new set is calculated reinit the solver */
      *enterEventMode = fmi2True;
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2CompletedIntegratorStep: Need to iterate state values changed!")
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

  if (done) {
    return fmi2OK;
  }
  FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2CompletedIntegratorStep: terminated by an assertion.")
  return fmi2Error;
}

fmi2Status fmi2CompletedIntegratorStep(fmi2Component c, fmi2Boolean noSetFMUStatePriorToCurrentPoint, fmi2Boolean* enterEventMode, fmi2Boolean* terminateSimulation)
{
  ModelInstance *comp = (ModelInstance *)c;

  if (invalidState(comp, "fmi2CompletedIntegratorStep", model_state_me_continuous_time_mode, 0))
    return fmi2Error;

  return internal_CompletedIntegratorStep(c, noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation);
}

fmi2Status fmi2SetTime(fmi2Component c, fmi2Real t)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2SetTime", model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetTime: time=%.16g", t)
  comp->fmuData->localData[0]->timeValue = t;
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status internalSetContinuousStates(fmi2Component c, const fmi2Real x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  int i;
  if (invalidNumber(comp, "fmi2SetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi2Error;
  if (nullPointer(comp, "fmi2SetContinuousStates", "x[]", x))
    return fmi2Error;
#if NUMBER_OF_STATES>0
  for (i = 0; i < nx; i++) {
    fmi2ValueReference vr = vrStates[i];
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetContinuousStates: #r%d# = %.16g", vr, x[i])
    if (vr < 0 || vr >= NUMBER_OF_REALS|| setReal(comp, vr, x[i]) != fmi2OK) { // to be implemented by the includer of this file
      return fmi2Error;
    }
  }
#endif
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification fmi2SetContinuousStates should only be allowed in Continuous-Time Mode.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call fmi2SetContinuousStates after fmi2EnterInitializationMode.
   */
  if (invalidState(comp, "fmi2SetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode, 0))
    return fmi2Error;

  return internalSetContinuousStates(c, x, nx);
}

fmi2Status internalGetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidNumber(comp, "fmi2GetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmi2Error;
  if (nullPointer(comp, "fmi2GetDerivatives", "derivatives[]", derivatives))
    return fmi2Error;

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->_need_update = 0;
    }

#if NUMBER_OF_STATES>0
    for (i = 0; i < nx; i++) {
      fmi2ValueReference vr = vrStatesDerivatives[i];
      derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetDerivatives: #r%d# = %.16g", vr, derivatives[i])
    }
#endif

    done=1;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  resetThreadData(comp);

  if (done) {
    return fmi2OK;
  }
  FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2GetDerivatives: terminated by an assertion.")
  return fmi2Error;
}

fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetDerivatives", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi2Error;

  return internalGetDerivatives(c, derivatives, nx);
}

fmi2Status internalGetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t nx)
{
  int i, done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidNumber(comp, "fmi2GetEventIndicators", "nx", nx, NUMBER_OF_EVENT_INDICATORS))
    return fmi2Error;

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

#if NUMBER_OF_EVENT_INDICATORS>0
    /* eval needed equations*/
    if (comp->_need_update)
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      comp->_need_update = 0;
    }
    comp->fmuData->callback->function_ZeroCrossings(comp->fmuData, comp->threadData, comp->fmuData->simulationInfo->zeroCrossings);
    for (i = 0; i < nx; i++) {
      eventIndicators[i] = comp->fmuData->simulationInfo->zeroCrossings[i];
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetEventIndicators: z%d = %.16g", i, eventIndicators[i])
    }
#endif
    done=1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  resetThreadData(comp);
  if (done) {
    return fmi2OK;
  }
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "error", "fmi2GetEventIndicators: terminated by an assertion.");
  return fmi2Error;
}

fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  /* According to FMI RC2 specification fmi2GetEventIndicators should only be allowed in Event Mode, Continuous-Time Mode & terminated.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call fmi2GetEventIndicators after fmi2EnterInitializationMode.
   */
  if (invalidState(comp, "fmi2GetEventIndicators", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
  /*if (invalidState(comp, "fmi2GetEventIndicators", model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error))*/
    return fmi2Error;

  return internalGetEventIndicators(c, eventIndicators, nx);
}

fmi2Status internalGetContinuousStates(fmi2Component c, fmi2Real x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, "fmi2GetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi2Error;
  if (nullPointer(comp, "fmi2GetContinuousStates", "states[]", x))
    return fmi2Error;
#if NUMBER_OF_STATES>0
  for (i = 0; i < nx; i++)
  {
    fmi2ValueReference vr = vrStates[i];
    x[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetContinuousStates: #r%u# = %.16g", vr, x[i])
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetContinuousStates", model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi2Error;

  return internalGetContinuousStates(c, x, nx);
}

fmi2Status internalGetNominalsOfContinuousStates(fmi2Component c, fmi2Real x_nominal[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidNumber(comp, "fmi2GetNominalsOfContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi2Error;
  if (nullPointer(comp, "fmi2GetNominalsOfContinuousStates", "x_nominal[]", x_nominal))
    return fmi2Error;
  x_nominal[0] = 1;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetNominalsOfContinuousStates: x_nominal[0..%d] = 1.0", nx-1)
  for (i = 0; i < nx; i++)
    x_nominal[i] = 1;
  return fmi2OK;
}

fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c, fmi2Real x_nominal[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetNominalsOfContinuousStates", model_state_instantiated|model_state_initialization_mode|model_state_me_event_mode|model_state_me_continuous_time_mode|model_state_terminated|model_state_error, 0))
    return fmi2Error;

  return internalGetNominalsOfContinuousStates(c, x_nominal, nx);
}

/***************************************************
Functions for FMI2 for Co-Simulation
****************************************************/
fmi2Status fmi2SetRealInputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer order[], const fmi2Real value[])
{
  /* Variables */
  int i;
  int mappedIndex;
  ModelInstance *comp = (ModelInstance*)c;

  /* Check for valid call sequence */
  if (invalidState(comp, "fmi2SetRealInputDerivatives", 0, model_state_instantiated|model_state_initialization_mode|model_state_cs_step_complete))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetRealInputDerivatives", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2SetRealInputDerivatives", "value[]", value))
    return fmi2Error;

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetRealInputDerivatives: nvr = %d", nvr)

#if NUMBER_OF_REAL_INPUTS > 0
  for (i = 0; i < nvr; i++)
  {
    if (order[i] > 1) // currently first order derivative is supported
      return fmi2Error;
    if (vrOutOfRange(comp, "fmi2SetRealInputDerivatives", vr[i], NUMBER_OF_REALS))
      return fmi2Error;
    // check valueReference is an input of type Real
    mappedIndex = mapInputReference2InputNumber(vr[i]);
    if (mappedIndex == -1)
      return fmi2Error;
    comp->input_real_derivative[mappedIndex] = value[i]; // store the values in an external array
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetRealInputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif

  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2GetRealOutputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer order[], fmi2Real value[])
{
  /* Variables */
  int i;
  ModelInstance *comp = (ModelInstance*)c;

  /* Check for valid call sequence */
  if (invalidState(comp, "fmi2GetRealOutputDerivatives", 0, model_state_cs_step_complete|model_state_cs_step_failed|model_state_cs_step_canceled|model_state_terminated|model_state_error))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetRealOutputDerivatives", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetRealOutputDerivatives", "value[]", value))
    return fmi2Error;

#if NUMBER_OF_REALS > 0
  if (updateIfNeeded(comp, "fmi2GetRealOutputDerivatives") != fmi2OK)
    return fmi2Error;

  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetRealOutputDerivatives", vr[i], NUMBER_OF_REALS)) {
      return fmi2Error;
    }
    fmi2ValueReference mappedVR = mapOutputReference2RealOutputDerivatives(vr[i]);
    value[i] = getReal(comp, mappedVR); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetRealOutputDerivatives: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmi2OK;
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
 * @return fmi2Status                         Returns fmi2OK if communication point was reached successfully.
 *                                            Returns fmi2Error if something went wrong.
 */
fmi2Status fmi2DoStep(fmi2Component c, fmi2Real currentCommunicationPoint, fmi2Real communicationStepSize, fmi2Boolean noSetFMUStatePriorToCurrentPoint)
{
  ModelInstance *comp = (ModelInstance *)c;
  fmi2CallbackFunctions* functions = (fmi2CallbackFunctions*)comp->functions;
  int i, zc_event = 0, time_event = 0;
  int flag;

  CVODE_SOLVER* cvodeData;
  fmi2Status status = fmi2OK;
  fmi2Real* states = comp->states;
  fmi2Real* states_der = comp->states_der;
  fmi2Real* event_indicators = comp->event_indicators;
  fmi2Real* event_indicators_prev = comp->event_indicators_prev;
  fmi2Real t = comp->fmuData->localData[0]->timeValue;
  fmi2Real tNext, tEnd;
  fmi2Boolean enterEventMode = fmi2False, terminateSimulation = fmi2False;

  fmi2EventInfo eventInfo;

  if (invalidState(comp, "fmi2DoStep", 0, model_state_cs_step_complete))
    return fmi2Error;

  eventInfo.newDiscreteStatesNeeded           = fmi2False;
  eventInfo.terminateSimulation               = fmi2False;
  eventInfo.nominalsOfContinuousStatesChanged = fmi2False;
  eventInfo.valuesOfContinuousStatesChanged   = fmi2True;
  eventInfo.nextEventTimeDefined              = fmi2False;
  eventInfo.nextEventTime                     = 0.0;

  comp->fmuData->localData[0]->timeValue = currentCommunicationPoint;
  tEnd = currentCommunicationPoint + communicationStepSize;
  if (comp->stopTimeDefined && (tEnd > comp->stopTime))
    status=fmi2Error;

  // copy the input values
  fmi2Real realInputDerivatives[NUMBER_OF_REAL_INPUTS];
  if (NUMBER_OF_REAL_INPUTS > 0)
  {
    for (int i = 0; i < NUMBER_OF_REALS; ++i)
    {
      int mappedIndex = mapInputReference2InputNumber(i);
      if (mappedIndex != -1)
        realInputDerivatives[mappedIndex] = getReal(comp, i);
    }
  }

  internalEventIteration(c, &eventInfo);

  /* Integration loop */
  while (status == fmi2OK && comp->fmuData->localData[0]->timeValue < tEnd)
  {
    /* fprintf(stderr, "DoStep %g -> %g State: %s\n", comp->fmuData->localData[0]->timeValue, tNext, stateToString(comp)); */

    // set the real Inputs with output_derivative values
    if (NUMBER_OF_REAL_INPUTS > 0)
    {
      for (int i = 0; i < NUMBER_OF_REALS; ++i)
      {
        int mappedIndex = mapInputReference2InputNumber(i);
        if (mapInputReference2InputNumber(i) != -1)
        {
          double dt = comp->fmuData->localData[0]->timeValue - t;
          double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
          if (setReal(comp, i, new_input_value) != fmi2OK) // to be implemented by the includer of this file
            return fmi2Error;
        }
      }
    }

    if (NUMBER_OF_STATES > 0)
    {
      status = internalGetDerivatives(c, states_der, NUMBER_OF_STATES);
      if (status != fmi2OK) return fmi2Error;


      status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
      if (status != fmi2OK) return fmi2Error;
    }

    if (NUMBER_OF_EVENT_INDICATORS > 0)
    {
      status = internalGetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) return fmi2Error;
    }

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
        flag = cvode_solver_fmi_step(comp->fmuData, comp->threadData, comp->solverInfo, tNext, states, comp);
        if (flag < 0)
        {
          FILTERED_LOG(comp, fmi2Fatal, LOG_STATUSFATAL, "fmi2DoStep: CVODE integrator step failed.")
          return fmi2Fatal;
        }
        break;
      default:
        FILTERED_LOG(comp, fmi2Fatal, LOG_STATUSFATAL, "fmi2DoStep: Unknown solver method %d.", comp->solverInfo->solverMethod)
        return fmi2Fatal;
    }

    // update time
    comp->fmuData->localData[0]->timeValue = tNext;
    comp->_need_update = 1;

    // set the real Inputs with output_derivative values
    if (NUMBER_OF_REAL_INPUTS > 0)
    {
      for (int i = 0; i < NUMBER_OF_REALS; ++i)
      {
        int mappedIndex = mapInputReference2InputNumber(i);
        if (mapInputReference2InputNumber(i) != -1)
        {
          double dt = comp->fmuData->localData[0]->timeValue - t;
          double new_input_value = realInputDerivatives[mappedIndex] + comp->input_real_derivative[mappedIndex] * dt;
          if (setReal(comp, i, new_input_value) != fmi2OK) // to be implemented by the includer of this file
            return fmi2Error;
        }
      }
    }

    /* set the continuous states */
    if (NUMBER_OF_STATES > 0)
    {
      status = internalSetContinuousStates(c, states, NUMBER_OF_STATES);
      if (status != fmi2OK) return fmi2Error;
    }

    /* signal completed integrator step */
    status = internal_CompletedIntegratorStep(c, fmi2True, &enterEventMode, &terminateSimulation);
    if (status != fmi2OK) return fmi2Error;

    /* check for events */
    if (NUMBER_OF_EVENT_INDICATORS > 0)
    {
      status = internalGetEventIndicators(c, event_indicators, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) return fmi2Error;

      for (i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
      {
        if (event_indicators[i]*event_indicators_prev[i] < 0)
        {
          zc_event = 1;
          break;
        }
      }
    }

    comp->solverInfo->didEventStep = 0;

    if (enterEventMode || zc_event || time_event)
    {
      /* fprintf(stderr, "enterEventMode = %d, zc_event = %d, time_event = %d\n", enterEventMode, zc_event, time_event); */

      // Reset eventInfo
      eventInfo.newDiscreteStatesNeeded           = fmi2False;
      eventInfo.terminateSimulation               = fmi2False;
      eventInfo.nominalsOfContinuousStatesChanged = fmi2False;
      eventInfo.valuesOfContinuousStatesChanged   = fmi2True;
      eventInfo.nextEventTimeDefined              = fmi2False;
      eventInfo.nextEventTime                     = 0.0;
      internalEventIteration(c, &eventInfo);

      if (eventInfo.valuesOfContinuousStatesChanged)
      {
        status = internalGetContinuousStates(c, states, NUMBER_OF_STATES);
        if (status != fmi2OK) return fmi2Error;
      }

      if (eventInfo.nominalsOfContinuousStatesChanged)
      {
        status = internalGetNominalsOfContinuousStates(c, states, NUMBER_OF_STATES);
        if (status != fmi2OK) return fmi2Error;
      }

      status = internalGetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) return fmi2Error;

      comp->solverInfo->didEventStep = 1;
    }
  }

  return status;
}

fmi2Status fmi2CancelStep(fmi2Component c)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2CancelStep");
}

fmi2Status fmi2GetStatus(fmi2Component c, const fmi2StatusKind s, fmi2Status* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetStatus");
}

fmi2Status fmi2GetRealStatus(fmi2Component c, const fmi2StatusKind s, fmi2Real* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetRealStatus");
}

fmi2Status fmi2GetIntegerStatus(fmi2Component c, const fmi2StatusKind s, fmi2Integer* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetIntegerStatus");
}

fmi2Status fmi2GetBooleanStatus(fmi2Component c, const fmi2StatusKind s, fmi2Boolean* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetBooleanStatus");
}

fmi2Status fmi2GetStringStatus(fmi2Component c, const fmi2StatusKind s, fmi2String* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetStringStatus");
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

fmi2Status fmi2SetExternalFunction(fmi2Component c, fmi2ValueReference vr[], size_t nvr, const void* value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2SetExternalFunction", model_state_instantiated, ~0))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "value[]", value))
    return fmi2Error;
  if (comp->loggingOn) comp->functions->logger(c, comp->instanceName, fmi2OK, "log", "fmi2SetExternalFunction");
  // no check whether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmi2SetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmi2Error;
    if (setExternalFunction(comp, vr[i],value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  return fmi2OK;
}
