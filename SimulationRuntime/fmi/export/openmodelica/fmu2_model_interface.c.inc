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
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
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
const char* stateToString(ModelInstance *comp)
{
  switch (comp->state)
  {
    case modelInstantiated: return "Instantiated";
    case modelInitializationMode: return "Initialization Mode";
    case modelEventMode: return "Event Mode";
    case modelContinuousTimeMode: return "Continuous-Time Mode";
    case modelTerminated: return "Terminated";
    case modelError: return "Error";
  }
  return "Unknown";
}

static fmi2Boolean invalidNumber(ModelInstance *comp, const char *f, const char *arg, int n, int nExpected)
{
  if (n != nExpected) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Boolean invalidState(ModelInstance *comp, const char *f, int meStates, int csStates)
{
  if (!comp)
    return fmi2True;

  int statesExpected;
  if (fmi2ModelExchange == comp->type)
    statesExpected = meStates;
  else /* fmi2CoSimulation */
    statesExpected = csStates;

  if (!(comp->state & statesExpected))
  {
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Illegal call sequence. %s is not allowed in %s state.", f, f, stateToString(comp))
    comp->state = modelError;
    return fmi2True;
  }

  return fmi2False;
}

static fmi2Boolean nullPointer(ModelInstance* comp, const char *f, const char *arg, const void *p)
{
  if (!p) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Invalid argument %s = NULL.", f, arg)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Boolean vrOutOfRange(ModelInstance *comp, const char *f, fmi2ValueReference vr, int end)
{
  if (vr >= end) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Illegal value reference %u.", f, vr)
    return fmi2True;
  }
  return fmi2False;
}

static fmi2Status unsupportedFunction(fmi2Component c, const char *fName, int statesExpected)
{
  ModelInstance *comp = (ModelInstance *)c;
  fmi2CallbackLogger log = comp->functions->logger;
  if (invalidState(comp, fName, statesExpected, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2Error, LOG_STATUSERROR, "%s: Function not implemented.", fName)
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
  char *str;
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

fmi2Status fmi2EventUpdate(fmi2Component c, fmi2EventInfo* eventInfo)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;

  if (nullPointer(comp, "fmi2EventUpdate", "eventInfo", eventInfo)) {
    return fmi2Error;
  }
  eventInfo->valuesOfContinuousStatesChanged = fmi2False;

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EventUpdate: Start Event Update! Next Sample Event %g", eventInfo->nextEventTime)

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 1)) {
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EventUpdate: Need to iterate state values changed!")
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

    if (checkForDiscreteChanges(comp->fmuData, comp->threadData) || comp->fmuData->simulationInfo->needToIterate || checkRelations(comp->fmuData) || eventInfo->valuesOfContinuousStatesChanged) {
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EventUpdate: Need to iterate(discrete changes)!")
      eventInfo->newDiscreteStatesNeeded  = fmi2True;
      eventInfo->nominalsOfContinuousStatesChanged = fmi2False;
      eventInfo->valuesOfContinuousStatesChanged  = fmi2True;
      eventInfo->terminateSimulation = fmi2False;
    } else {
      eventInfo->newDiscreteStatesNeeded  = fmi2False;
      eventInfo->nominalsOfContinuousStatesChanged = fmi2False;
      eventInfo->terminateSimulation = fmi2False;
    }
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EventUpdate: newDiscreteStatesNeeded %s",eventInfo->newDiscreteStatesNeeded?"true":"false");

    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    /* TODO: check the event iteration for relation
     * in fmi2 import and export. This is an workaround,
     * since the iteration seem not starting.
     */
    storePreValues(comp->fmuData);
    updateRelationsPre(comp->fmuData);

    //Get Next Event Time
    double nextSampleEvent=0;
    nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
    if (nextSampleEvent == -1) {
      eventInfo->nextEventTimeDefined = fmi2False;
    } else {
      eventInfo->nextEventTimeDefined = fmi2True;
      eventInfo->nextEventTime = nextSampleEvent;
    }
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime)

    done=1;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)
  resetThreadData(comp);

  if (done) {
    return fmi2OK;
  }
  FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2EventUpdate: terminated by an assertion.")
  comp->_need_update = 1;
  return fmi2Error;
}


fmi2Status fmi2EventIteration(fmi2Component c, fmi2EventInfo *eventInfo)
{
  fmi2Status status = fmi2OK;
  eventInfo->newDiscreteStatesNeeded = fmi2True;
  eventInfo->terminateSimulation     = fmi2False;
  while (eventInfo->newDiscreteStatesNeeded && !eventInfo->terminateSimulation) {
    status = fmi2NewDiscreteStates(c, eventInfo);
  }
  return status;
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
  comp->state = modelInstantiated;

  /* Add the resourcesDir */
  fmuResourceLocation = OpenModelica_parseFmuResourcePath(fmuResourceLocation);
  if (fmuResourceLocation) {
    comp->fmuData->modelData->resourcesDir = functions->allocateMemory(1 + strlen(fmuResourceLocation), sizeof(char));
    strcpy(comp->fmuData->modelData->resourcesDir, fmuResourceLocation);
  } else {
    FILTERED_LOG(comp, fmi2OK, LOG_STATUSWARNING, "fmi2Instantiate: Ignoring unknown resource URI: %s", fmuResourceLocation)
  }

  /* intialize modelData */
  fmu2_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;
  initializeDataStruc(comp->fmuData, comp->threadData);
  /* setup model data with default start data */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData, comp->fmuData->simulationInfo);
#if !defined(OMC_MINIMAL_METADATA)
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));
#endif

  /* read input vars */
  /* input_function(comp->fmuData); */
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
  if (comp->fmuData->callback->initialPartialFMIDER != NULL){
    if (! comp->fmuData->callback->initialPartialFMIDER(comp->fmuData, comp->threadData, comp->fmiDerJac)) {
      comp->_has_jacobian = 1;
    }
  }

  comp->_need_update = 1;

  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Instantiate: GUID=%s", fmuGUID)
  resetThreadData(comp);
  return comp;
}

void fmi2FreeInstance(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  fmi2CallbackFreeMemory freeMemory = comp->functions->freeMemory;
  int meStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError;
  int csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError;

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
  deInitializeDataStruc(comp->fmuData);

  comp->functions->freeMemory(comp->fmuData->modelData->resourcesDir);

  /* free simuation data */
  comp->functions->freeMemory(comp->fmuData->modelData);
  comp->functions->freeMemory(comp->fmuData->simulationInfo);

  /* free fmuData */
  comp->functions->freeMemory(comp->threadData);
  comp->functions->freeMemory(comp->fmuData);
  /* free instanceName & GUID */
  if (comp->instanceName) comp->functions->freeMemory((void*)comp->instanceName);
  if (comp->GUID) comp->functions->freeMemory((void*)comp->GUID);
  if (comp->functions) comp->functions->freeMemory((void*)comp->functions);
  /* free comp */
  freeMemory(comp);
  free_memory_pool();
}

fmi2Status fmi2SetupExperiment(fmi2Component c, fmi2Boolean toleranceDefined, fmi2Real tolerance, fmi2Real startTime, fmi2Boolean stopTimeDefined, fmi2Real stopTime)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2SetupExperiment", modelInstantiated, ~0))
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

  if (invalidState(comp, "fmi2EnterInitializationMode", modelInstantiated, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2EnterInitializationMode...")

  setZCtol(comp->tolerance); /* set zero-crossing tolerance */
  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);
  comp->state = modelInitializationMode;

  return fmi2OK;
}

fmi2Status fmi2ExitInitializationMode(fmi2Component c)
{
  fmi2Status res = fmi2Error;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp = threadData->mmc_jumper;
  double nextSampleEvent;
  int done=0;

  threadData->currentErrorStage = ERROR_SIMULATION;
  if (invalidState(comp, "fmi2ExitInitializationMode", modelInitializationMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2ExitInitializationMode...")

  setThreadData(comp);

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
  threadData->mmc_jumper = threadData->simulationJumpBuffer;

  if (comp->_need_update)
  {
    comp->fmuData->callback->updateBoundParameters(comp->fmuData, comp->threadData);
    comp->fmuData->callback->updateBoundVariableAttributes(comp->fmuData, comp->threadData);
    if (initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0))
    {
      comp->state = modelError;
      resetThreadData(comp);
      FILTERED_LOG(comp, fmi2Error, LOG_FMI2_CALL, "fmi2EnterInitializationMode: failed")
      return fmi2Error;
    }
  }

  /* TODO: Simulation stop time is needed to calculate the sample events beforehand. */
  initSample(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, 100 /*should be stopTime*/);
#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0
  initDelay(comp->fmuData, comp->fmuData->localData[0]->timeValue);
#endif
  /* overwrite old values due to an event */
  overwriteOldSimulationData(comp->fmuData);

  comp->eventInfo.terminateSimulation = fmi2False;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmi2True;

  /* get next event time (sample calls) */
  nextSampleEvent = 0;
  nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
  if (nextSampleEvent == -1)
  {
    comp->eventInfo.nextEventTimeDefined = fmi2False;
  }
  else
  {
    comp->eventInfo.nextEventTimeDefined = fmi2True;
    comp->eventInfo.nextEventTime = nextSampleEvent;
    fmi2EventUpdate(comp, &(comp->eventInfo));
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

  comp->state = modelEventMode;
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
  if (invalidState(comp, "fmi2Terminate", modelEventMode|modelContinuousTimeMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Terminate")

  setThreadData(comp);
  comp->state = modelTerminated;
  resetThreadData(comp);
  return fmi2OK;
}

/*!
 * Is called by the environment to reset the FMU after a simulation run. Before starting a new run, fmi2EnterInitializationMode has to be called.
 */
fmi2Status fmi2Reset(fmi2Component c)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2Reset", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2Reset")

  setThreadData(comp);

  if (comp->state & modelTerminated) {
    /* intialize modelData */
    fmu2_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
    initializeDataStruc(comp->fmuData, comp->threadData);
  }
  /* reset the values to start */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);

  comp->state = modelInstantiated;
  resetThreadData(comp);
  return fmi2OK;
}

fmi2Status fmi2GetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Real value[])
{
  int i;
  ModelInstance *comp = (ModelInstance*)c;

  if (invalidState(comp, "fmi2GetReal", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetReal", "value[]", value))
    return fmi2Error;

  setThreadData(comp);
#if NUMBER_OF_REALS > 0
  if (comp->_need_update)
  {
    if (modelInitializationMode == comp->state)
    {
      comp->fmuData->callback->updateBoundParameters(comp->fmuData, comp->threadData);
      comp->fmuData->callback->updateBoundVariableAttributes(comp->fmuData, comp->threadData);
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      storePreValues(comp->fmuData);
    }
    comp->_need_update = 0;
  }

  resetThreadData(comp);
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
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetInteger", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetInteger", "value[]", value))
    return fmi2Error;

  setThreadData(comp);
  if (comp->_need_update)
  {
    if (modelInitializationMode == comp->state)
    {
      comp->fmuData->callback->updateBoundParameters(comp->fmuData, comp->threadData);
      comp->fmuData->callback->updateBoundVariableAttributes(comp->fmuData, comp->threadData);
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      storePreValues(comp->fmuData);
    }
    comp->_need_update = 0;
  }

  resetThreadData(comp);
  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetInteger", vr[i], NUMBER_OF_INTEGERS)) {
      return fmi2Error;
    }
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetInteger: #i%u# = %d", vr[i], value[i])
  }
  return fmi2OK;
}

fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetBoolean", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "vr[]", vr))
    return fmi2Error;
  if (nvr > 0 && nullPointer(comp, "fmi2GetBoolean", "value[]", value))
    return fmi2Error;

  setThreadData(comp);
  if (comp->_need_update)
  {
    if (modelInitializationMode == comp->state)
    {
      comp->fmuData->callback->updateBoundParameters(comp->fmuData, comp->threadData);
      comp->fmuData->callback->updateBoundVariableAttributes(comp->fmuData, comp->threadData);
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      storePreValues(comp->fmuData);
    }
    comp->_need_update = 0;
  }

  resetThreadData(comp);
  for (i = 0; i < nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetBoolean", vr[i], NUMBER_OF_BOOLEANS)) {
      return fmi2Error;
    }
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
  }
  return fmi2OK;
}

fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetString", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2GetString", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2GetString", "value[]", value))
    return fmi2Error;

  setThreadData(comp);
  if (comp->_need_update)
  {
    if (modelInitializationMode == comp->state)
    {
      comp->fmuData->callback->updateBoundParameters(comp->fmuData, comp->threadData);
      comp->fmuData->callback->updateBoundVariableAttributes(comp->fmuData, comp->threadData);
      initialization(comp->fmuData, comp->threadData, "fmi", "", 0.0);
    }
    else
    {
      comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
      overwriteOldSimulationData(comp->fmuData);
      comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
      comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
      comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
      storePreValues(comp->fmuData);
    }
    comp->_need_update = 0;
  }
  resetThreadData(comp);

  for (i=0; i<nvr; i++)
  {
    if (vrOutOfRange(comp, "fmi2GetString", vr[i], NUMBER_OF_STRINGS))
      return fmi2Error;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetString: #s%u# = '%s'", vr[i], value[i])
  }
  return fmi2OK;
}

fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real value[])
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  int meStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;
  int csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

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
  int meStates = modelInstantiated|modelInitializationMode|modelEventMode;
  int csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

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
  int meStates = modelInstantiated|modelInitializationMode|modelEventMode;
  int csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

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
  int meStates = modelInstantiated|modelInitializationMode|modelEventMode;
  int csStates = modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode;

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
  return unsupportedFunction(c, "fmi2GetFMUstate", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
}

fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate FMUstate)
{
  return unsupportedFunction(c, "fmi2SetFMUstate", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
}

fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
{
  return unsupportedFunction(c, "fmi2FreeFMUstate", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
}

fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate, size_t *size)
{
  return unsupportedFunction(c, "fmi2SerializedFMUstateSize", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
}

fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate, fmi2Byte serializedState[], size_t size)
{
  return unsupportedFunction(c, "fmi2SerializeFMUstate", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
}

fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte serializedState[], size_t size, fmi2FMUstate* FMUstate)
{
  return unsupportedFunction(c, "fmi2DeSerializeFMUstate", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
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

  if (invalidState(comp, "fmi2GetDirectionalDerivative", modelInstantiated|modelEventMode|modelContinuousTimeMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetDirectionalDerivative")
  if (!comp->_has_jacobian)
    return unsupportedFunction(c, "fmi2GetDirectionalDerivative", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError);
  /***************************************/
  /* This code assumes that the FMU variables are always sorted,
     states first and then derivatives.
     This is true for the actual OMC FMUs.
     The input values references are mapped with mapInputReference2InputNumber
     and mapOutputReference2OutputNumber functions
  */
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
  if (invalidState(comp, "fmi2EnterEventMode", modelInitializationMode|modelContinuousTimeMode|modelEventMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_EVENTS, "fmi2EnterEventMode")
  comp->state = modelEventMode;
  return fmi2OK;
}

fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo* eventInfo)
{
  ModelInstance *comp = (ModelInstance *)c;
  double nextSampleEvent = 0;
  fmi2Status returnValue = fmi2OK;

  if (invalidState(comp, "fmi2NewDiscreteStates", modelEventMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2NewDiscreteStates")

  eventInfo->newDiscreteStatesNeeded = fmi2False;
  eventInfo->terminateSimulation = fmi2False;
  eventInfo->nominalsOfContinuousStatesChanged = fmi2False;
  eventInfo->valuesOfContinuousStatesChanged = fmi2False;
  eventInfo->nextEventTimeDefined = fmi2False;
  eventInfo->nextEventTime = 0;

  returnValue = fmi2EventUpdate(comp, eventInfo);

  return returnValue;
}

fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2EnterContinuousTimeMode", modelEventMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL,"fmi2EnterContinuousTimeMode")
  comp->state = modelContinuousTimeMode;
  return fmi2OK;
}

fmi2Status fmi2CompletedIntegratorStep(fmi2Component c, fmi2Boolean noSetFMUStatePriorToCurrentPoint, fmi2Boolean* enterEventMode, fmi2Boolean* terminateSimulation)
{
  int done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  jmp_buf *old_jmp=threadData->mmc_jumper;
  if (invalidState(comp, "fmi2CompletedIntegratorStep", modelContinuousTimeMode, ~0))
    return fmi2Error;
  if (nullPointer(comp, "fmi2CompletedIntegratorStep", "enterEventMode", enterEventMode))
    return fmi2Error;
  if (nullPointer(comp, "fmi2CompletedIntegratorStep", "terminateSimulation", terminateSimulation))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL,"fmi2CompletedIntegratorStep")

  setThreadData(comp);
  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)
    threadData->mmc_jumper = threadData->simulationJumpBuffer;
    comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
    comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
    storePreValues(comp->fmuData);
    *enterEventMode = fmi2False;
    *terminateSimulation = fmi2False;
    /******** check state selection ********/
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 0))
    {
      /* if new set is calculated reinit the solver */
      *enterEventMode = fmi2True;
      FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL,"fmi2CompletedIntegratorStep: Need to iterate state values changed!")
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

fmi2Status fmi2SetTime(fmi2Component c, fmi2Real t)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2SetTime", modelInstantiated|modelEventMode|modelContinuousTimeMode, ~0))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetTime: time=%.16g", t)
  comp->fmuData->localData[0]->timeValue = t;
  comp->_need_update = 1;
  return fmi2OK;
}

fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real x[], size_t nx)
{
  ModelInstance *comp = (ModelInstance *)c;
  int i;
  /* According to FMI RC2 specification fmi2SetContinuousStates should only be allowed in Continuous-Time Mode.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call fmi2SetContinuousStates after fmi2EnterInitializationMode.
   */
  if (invalidState(comp, "fmi2SetContinuousStates", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode, ~0))
  /*if (invalidState(comp, "fmi2SetContinuousStates", modelContinuousTimeMode))*/
    return fmi2Error;
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

fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx)
{
  int i, done=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidState(comp, "fmi2GetDerivatives", modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
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

fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t nx)
{
  int i, done=0;
  ModelInstance *comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  /* According to FMI RC2 specification fmi2GetEventIndicators should only be allowed in Event Mode, Continuous-Time Mode & terminated.
   * The following code is done only to make the FMUs compatible with Dymola because Dymola is trying to call fmi2GetEventIndicators after fmi2EnterInitializationMode.
   */
  if (invalidState(comp, "fmi2GetEventIndicators", modelInstantiated|modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
  /*if (invalidState(comp, "fmi2GetEventIndicators", modelEventMode|modelContinuousTimeMode|modelTerminated|modelError))*/
    return fmi2Error;
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

fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real x[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetContinuousStates", modelInitializationMode|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
  if (invalidNumber(comp, "fmi2GetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmi2Error;
  if (nullPointer(comp, "fmi2GetContinuousStates", "states[]", x))
    return fmi2Error;
#if NUMBER_OF_STATES>0
  for (i = 0; i < nx; i++) {
    fmi2ValueReference vr = vrStates[i];
    x[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2GetContinuousStates: #r%u# = %.16g", vr, x[i])
  }
#endif
  return fmi2OK;
}

fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c, fmi2Real x_nominal[], size_t nx)
{
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetNominalsOfContinuousStates", modelInstantiated|modelEventMode|modelContinuousTimeMode|modelTerminated|modelError, ~0))
    return fmi2Error;
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

/***************************************************
Functions for FMI2 for Co-Simulation
****************************************************/
fmi2Status fmi2SetRealInputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer order[], const fmi2Real value[])
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2SetRealInputDerivatives", ~0);
}

fmi2Status fmi2GetRealOutputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer order[], fmi2Real value[])
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetRealOutputDerivatives", ~0);
}

fmi2Status fmi2DoStep(fmi2Component c, fmi2Real currentCommunicationPoint, fmi2Real communicationStepSize, fmi2Boolean noSetFMUStatePriorToCurrentPoint)
{
  ModelInstance *comp = (ModelInstance *)c;
  fmi2CallbackFunctions* functions = (fmi2CallbackFunctions*)comp->functions;
  int i, zc_event = 0, time_event = 0;
  fmi2Status status = fmi2OK;
  fmi2Real* states = (fmi2Real*)functions->allocateMemory(NUMBER_OF_STATES, sizeof(fmi2Real));
  fmi2Real* states_der = (fmi2Real*)functions->allocateMemory(NUMBER_OF_STATES, sizeof(fmi2Real));
  fmi2Real* event_indicators = (fmi2Real*)functions->allocateMemory(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi2Real));
  fmi2Real* event_indicators_prev = (fmi2Real*)functions->allocateMemory(NUMBER_OF_EVENT_INDICATORS, sizeof(fmi2Real));
  fmi2Real t = comp->fmuData->localData[0]->timeValue;
  fmi2Real tNext, tEnd;
  fmi2Boolean enterEventMode = fmi2False, terminateSimulation = fmi2False;
  fmi2Real tCommunication;

  fmi2EventInfo eventInfo;
  eventInfo.newDiscreteStatesNeeded           = fmi2False;
  eventInfo.terminateSimulation               = fmi2False;
  eventInfo.nominalsOfContinuousStatesChanged = fmi2False;
  eventInfo.valuesOfContinuousStatesChanged   = fmi2True;
  eventInfo.nextEventTimeDefined              = fmi2False;
  eventInfo.nextEventTime                     = -0.0;

  if (comp->stopTimeDefined)
    tEnd = comp->stopTime;
  else
    tEnd = currentCommunicationPoint + communicationStepSize;
  tCommunication = currentCommunicationPoint;

  fmi2EnterEventMode(c);
  fmi2EventIteration(c, &eventInfo);
  fmi2EnterContinuousTimeMode(c);

  while (status == fmi2OK && comp->fmuData->localData[0]->timeValue < tEnd)
  {
    while (tCommunication <= comp->fmuData->localData[0]->timeValue)
    {
      tCommunication += communicationStepSize;
    }

    /* fprintf(stderr, "DoStep %g -> %g State: %s\n", comp->fmuData->localData[0]->timeValue, tNext, stateToString(comp)); */

    if (NUMBER_OF_STATES > 0)
    {
      status = fmi2GetDerivatives(c, states_der, NUMBER_OF_STATES);
      if (status != fmi2OK) {status=fmi2Error; break;}


      status = fmi2GetContinuousStates(c, states, NUMBER_OF_STATES);
      if (status != fmi2OK) {status=fmi2Error; break;}
    }

    if (NUMBER_OF_EVENT_INDICATORS > 0)
    {
      status = fmi2GetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) {status=fmi2Error; break;}
    }

    /* adjust tNext step to get tEnd exactly */
    if (tCommunication > tEnd - communicationStepSize/1e16)
      tNext = tEnd;
    else
      tNext = tCommunication;

    /* adjust for time events */
    if (eventInfo.nextEventTimeDefined && (eventInfo.nextEventTime <= tNext))
    {
      tNext = eventInfo.nextEventTime;
      time_event = 1;
    }

    /* integrate */
    for (i = 0; i < NUMBER_OF_STATES; i++)
    {
      states[i] = states[i] + (tNext - comp->fmuData->localData[0]->timeValue) * states_der[i];
    }
    fmi2SetTime(c, tNext);

    /* set the continuous states */
    if (NUMBER_OF_STATES > 0)
    {
      status = fmi2SetContinuousStates(c, states, NUMBER_OF_STATES);
      if (status != fmi2OK) {status=fmi2Error; break;}
    }

    /* signal completed integrator step */
    status = fmi2CompletedIntegratorStep(c, fmi2True, &enterEventMode, &terminateSimulation);
    if (status != fmi2OK) {status=fmi2Error; break;}

    /* check for events */
    if (NUMBER_OF_EVENT_INDICATORS > 0)
    {
      status = fmi2GetEventIndicators(c, event_indicators, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) {status=fmi2Error; break;}

      for (i = 0; i < NUMBER_OF_EVENT_INDICATORS; i++)
      {
        if (event_indicators[i]*event_indicators_prev[i] < 0)
        {
          zc_event = 1;
          break;
        }
      }
    }

    if (enterEventMode || zc_event || time_event)
    {
      /* fprintf(stderr, "enterEventMode = %d, zc_event = %d, time_event = %d\n", enterEventMode, zc_event, time_event); */

      fmi2EnterEventMode(c);
      fmi2EventIteration(c, &eventInfo);

      if (eventInfo.valuesOfContinuousStatesChanged)
      {
        status = fmi2GetContinuousStates(c, states, NUMBER_OF_STATES);
        if (status != fmi2OK) {status=fmi2Error; break;}
      }

      if (eventInfo.nominalsOfContinuousStatesChanged)
      {
        status = fmi2GetNominalsOfContinuousStates(c, states, NUMBER_OF_STATES);
        if (status != fmi2OK) {status=fmi2Error; break;}
      }

      status = fmi2GetEventIndicators(c, event_indicators_prev, NUMBER_OF_EVENT_INDICATORS);
      if (status != fmi2OK) {status=fmi2Error; break;}

      status = fmi2EnterContinuousTimeMode(c);
      if (status != fmi2OK) {status=fmi2Error; break;}
    }
  }

  functions->freeMemory(states);
  functions->freeMemory(states_der);
  functions->freeMemory(event_indicators);
  functions->freeMemory(event_indicators_prev);

  return status;
}

fmi2Status fmi2CancelStep(fmi2Component c)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2CancelStep", ~0);
}

fmi2Status fmi2GetStatus(fmi2Component c, const fmi2StatusKind s, fmi2Status* value)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetStatus", ~0);
}

fmi2Status fmi2GetRealStatus(fmi2Component c, const fmi2StatusKind s, fmi2Real* value)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetRealStatus", ~0);
}

fmi2Status fmi2GetIntegerStatus(fmi2Component c, const fmi2StatusKind s, fmi2Integer* value)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetIntegerStatus", ~0);
}

fmi2Status fmi2GetBooleanStatus(fmi2Component c, const fmi2StatusKind s, fmi2Boolean* value)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetBooleanStatus", ~0);
}

fmi2Status fmi2GetStringStatus(fmi2Component c, const fmi2StatusKind s, fmi2String* value)
{
  // TODO Write code here
  return unsupportedFunction(c, "fmi2GetStringStatus", ~0);
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

fmi2Status fmi2SetExternalFunction(fmi2Component c, fmi2ValueReference vr[], size_t nvr, const void* value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2Terminate", modelInstantiated, ~0))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "value[]", value))
    return fmi2Error;
  if (comp->loggingOn) comp->functions->logger(c, comp->instanceName, fmi2OK, "log",
      "fmi2SetExternalFunction");
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmi2SetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmi2Error;
    if (setExternalFunction(comp, vr[i],value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  return fmi2OK;
}
