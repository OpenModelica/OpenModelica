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

#include "simulation_data.h"
#include "simulation/solver/stateset.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/nonlinearSystem.h"
#include "simulation/solver/linearSystem.h"
#include "simulation/solver/mixedSystem.h"
#include "simulation/solver/delay.h"
#include "simulation/simulation_info_xml.h"
#include "simulation/simulation_input_xml.h"

// macro to be used to log messages. The macro check if current
// log category is valid and, if true, call the logger provided by simulator.
#define FILTERED_LOG(instance, status, categoryIndex, message, ...) if (isCategoryLogged(instance, categoryIndex)) \
    instance->functions->logger(instance->functions->componentEnvironment, instance->instanceName, status, \
        logCategoriesNames[categoryIndex], message, ##__VA_ARGS__);

static fmiString logCategoriesNames[] = {"logEvents", "logSingularLinearSystems", "logNonlinearSystems", "logDynamicStateSelection",
    "logStatusWarning", "logStatusDiscard", "logStatusError", "logStatusFatal", "logStatusPending", "logAll", "logFmiCall"};

// array of value references of states
#if NUMBER_OF_REALS>0
fmiValueReference vrStates[NUMBER_OF_STATES] = STATES;
#endif

// ---------------------------------------------------------------------------
// Private helpers used below to validate function arguments
// ---------------------------------------------------------------------------
static fmiBoolean invalidNumber(ModelInstance *comp, const char *f, const char *arg, int n, int nExpected) {
  if (n != nExpected) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected)
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean invalidState(ModelInstance *comp, const char *f, int statesExpected) {
  if (!comp)
    return fmiTrue;
  if (!(comp->state & statesExpected)) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "%s: Illegal call sequence.", f)
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean nullPointer(ModelInstance* comp, const char *f, const char *arg, const void *p) {
  if (!p) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "%s: Invalid argument %s = NULL.", f, arg)
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean vrOutOfRange(ModelInstance *comp, const char *f, fmiValueReference vr, int end) {
  if (vr >= end) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "%s: Illegal value reference %u.", f, vr)
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiStatus unsupportedFunction(fmiComponent c, const char *fName, int statesExpected) {
  ModelInstance *comp = (ModelInstance *)c;
  fmiCallbackLogger log = comp->functions->logger;
  if (invalidState(comp, fName, statesExpected))
    return fmiError;
  FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "%s: Function not implemented.", fName)
  return fmiError;
}

fmiStatus setString(fmiComponent comp, fmiValueReference vr, fmiString value) {
  return fmiSetString(comp, &vr, 1, &value);
}

// ---------------------------------------------------------------------------
// Private helpers logger
// ---------------------------------------------------------------------------
// return fmiTrue if logging category is on. Else return fmiFalse.
fmiBoolean isCategoryLogged(ModelInstance *comp, int categoryIndex) {
  if (categoryIndex < NUMBER_OF_CATEGORIES && (comp->logCategories[categoryIndex] || comp->logCategories[LOG_ALL])) {
    return fmiTrue;
  }
  return fmiFalse;
}

/***************************************************
Common Functions
****************************************************/
const char* fmiGetTypesPlatform() {
  return fmiTypesPlatform;
}

const char* fmiGetVersion() {
  return fmiVersion;
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn, size_t nCategories, const fmiString categories[]) {
  int i, j;
  ModelInstance *comp = (ModelInstance *)c;
  comp->loggingOn = loggingOn;

  for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
    comp->logCategories[j] = fmiFalse;
  }
  for (i = 0; i < nCategories; i++) {
    fmiBoolean categoryFound = fmiFalse;
    for (j = 0; j < NUMBER_OF_CATEGORIES; j++) {
      if (strcmp(logCategoriesNames[j], categories[i]) == 0) {
        comp->logCategories[j] = loggingOn;
        categoryFound = fmiTrue;
        break;
      }
    }
    if (!categoryFound) {
      comp->functions->logger(comp->componentEnvironment, comp->instanceName, fmiWarning, logCategoriesNames[LOG_STATUSERROR],
          "logging category '%s' is not supported by model", categories[i]);
    }
  }

  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetDebugLogging")
  return fmiOK;
}

fmiComponent fmiInstantiate(fmiString instanceName, fmiType fmuType, fmiString fmuGUID, fmiString fmuResourceLocation, const fmiCallbackFunctions* functions,
    fmiBoolean visible, fmiBoolean loggingOn) {
  // ignoring arguments: fmuResourceLocation, visible
  ModelInstance *comp;
  if (!functions->logger) {
    return NULL;
  }

  if (!functions->allocateMemory || !functions->freeMemory) {
    functions->logger(functions->componentEnvironment, instanceName, fmiError, "error", "fmiInstantiate: Missing callback function.");
    return NULL;
  }
  if (!instanceName || strlen(instanceName) == 0) {
    functions->logger(functions->componentEnvironment, instanceName, fmiError, "error", "fmiInstantiate: Missing instance name.");
    return NULL;
  }
  if (strcmp(fmuGUID, MODEL_GUID)) {
    functions->logger(functions->componentEnvironment, instanceName, fmiError, "error", "fmiInstantiate: Wrong GUID %s. Expected %s.", fmuGUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)functions->allocateMemory(1, sizeof(ModelInstance));
  if (comp) {
    comp->instanceName = functions->allocateMemory(1 + strlen(instanceName), sizeof(char));
    comp->GUID = functions->allocateMemory(1 + strlen(fmuGUID), sizeof(char));
    DATA* fmudata = (DATA *)functions->allocateMemory(1, sizeof(DATA));
    threadData_t *threadData = (threadData_t *)functions->allocateMemory(1, sizeof(threadData));
    fmudata->threadData = threadData;
    comp->fmuData = fmudata;
    if (!comp->fmuData) {
      functions->logger(functions->componentEnvironment, instanceName, fmiError, "error", "fmiInstantiate: Could not initialize the global data structure file.");
      return NULL;
    }
    // set all categories to on or off. fmiSetDebugLogging should be called to choose specific categories.
    int i;
    for (i = 0; i < NUMBER_OF_CATEGORIES; i++) {
      comp->logCategories[i] = loggingOn;
    }
  }
  if (!comp || !comp->instanceName || !comp->GUID) {
    functions->logger(functions->componentEnvironment, instanceName, fmiError, "error", "fmiInstantiate: Out of memory.");
    return NULL;
  }
  strcpy(comp->instanceName, instanceName);
  comp->type = fmuType;
  strcpy(comp->GUID, fmuGUID);
  comp->functions = functions;
  comp->componentEnvironment = functions->componentEnvironment;
  comp->loggingOn = loggingOn;
  comp->state = modelInstantiated;
  /* intialize modelData */
  fmu2_model_interface_setupDataStruc(comp->fmuData);
  initializeDataStruc(comp->fmuData);
  /* setup model data with default start data */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);
  read_input_xml(&(comp->fmuData->modelData), &(comp->fmuData->simulationInfo));
  modelInfoXmlInit(&(comp->fmuData->modelData.modelDataXml));
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiInstantiate: GUID=%s", fmuGUID)
  return comp;
}

void fmiFreeInstance(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (!comp) return;
  if (invalidState(comp, "fmiFreeInstance", modelTerminated))
    return;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiFreeInstance")

  /* deinitDelay(comp->fmuData); */
  comp->fmuData->callback->callExternalObjectDestructors(comp->fmuData);
  /* free nonlinear system data */
  freeNonlinearSystem(comp->fmuData);
  /* free mixed system data */
  freemixedSystem(comp->fmuData);
  /* free linear system data */
  freelinearSystem(comp->fmuData);
  /* free stateset data */
  freeStateSetData(comp->fmuData);
  deInitializeDataStruc(comp->fmuData);
  /* free fmuData */
  comp->functions->freeMemory(comp->fmuData->threadData);
  comp->functions->freeMemory(comp->fmuData);
  /* free instanceName & GUID */
  if (comp->instanceName) comp->functions->freeMemory(comp->instanceName);
  if (comp->GUID) comp->functions->freeMemory(comp->GUID);
  /* free comp */
  comp->functions->freeMemory(comp);
}

fmiStatus fmiSetupExperiment(fmiComponent c, fmiBoolean toleranceDefined, fmiReal tolerance, fmiReal startTime, fmiBoolean stopTimeDefined, fmiReal stopTime) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetupExperiment", modelInstantiated))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetupExperiment: toleranceDefined=%d tolerance=%g startTime=%g stopTimeDefined=%d stopTime=%g", toleranceDefined, tolerance,
      startTime, stopTimeDefined, stopTime)

  comp->toleranceDefined = toleranceDefined;
  comp->tolerance = tolerance;
  comp->startTime = startTime;
  comp->stopTimeDefined = stopTimeDefined;
  comp->stopTime = stopTime;
  return fmiOK;
}

fmiStatus fmiEnterInitializationMode(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiEnterInitializationMode", modelInstantiated))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiEnterInitializationMode")
  comp->state = modelInitializationMode;
  /* set zero-crossing tolerance */
  setZCtol(comp->tolerance);

  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);
  /* read input vars */
  //input_function(comp->fmuData);
  /* initial sample and delay before initial the system */
  comp->fmuData->callback->callExternalObjectConstructors(comp->fmuData);
  /* allocate memory for non-linear system solvers */
  allocateNonlinearSystem(comp->fmuData);
  /* allocate memory for non-linear system solvers */
  allocatelinearSystem(comp->fmuData);
  /* allocate memory for mixed system solvers */
  allocatemixedSystem(comp->fmuData);
  /* allocate memory for state selection */
  initializeStateSetJacobians(comp->fmuData);
  if (initialization(comp->fmuData, "", "", "", 0.0, 5)) {
    comp->state = modelError;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiEnterInitializationMode: failed")
  }
  else
  {
    comp->state = modelInitializationMode;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiEnterInitializationMode: succeed")
  }
  /*TODO: Simulation stop time is need to calculate in before hand all sample events
            We shouldn't generate them all in beforehand */
  initSample(comp->fmuData, comp->fmuData->localData[0]->timeValue, 100 /*should be stopTime*/);
  initDelay(comp->fmuData, comp->fmuData->localData[0]->timeValue);

  /* due to an event overwrite old values */
  overwriteOldSimulationData(comp->fmuData);

  comp->eventInfo.terminateSimulation = fmiFalse;
  comp->eventInfo.valuesOfContinuousStatesChanged = fmiTrue;

  /* Get next event time (sample calls)*/
  double nextSampleEvent = 0;
  nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
  if (nextSampleEvent == -1){
    comp->eventInfo.nextEventTimeDefined = fmiFalse;
  }else{
    comp->eventInfo.nextEventTimeDefined = fmiTrue;
    comp->eventInfo.nextEventTime = nextSampleEvent;
    //fmiEventUpdate(comp, fmiFalse, &(comp->eventInfo));
  }
  return fmiOK;
}

fmiStatus fmiExitInitializationMode(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiExitInitializationMode", modelInitializationMode))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiExitInitializationMode")

  comp->state = modelInitialized;
  return fmiOK;
}

fmiStatus fmiTerminate(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInitialized|modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiTerminate")

  comp->state = modelTerminated;
  return fmiOK;
}

/*!
 * Is called by the environment to reset the FMU after a simulation run. Before starting a new run, fmiEnterInitializationMode has to be called.
 */
fmiStatus fmiReset(fmiComponent c) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiReset", modelInitialized|modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiReset")

  comp->state = modelInstantiated;
  /* reset the values to start */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);
  return fmiOK;
}

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetReal", modelInitializationMode|modelInitialized|modelStepping|modelError))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetReal", "vr[]", vr))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetReal", "value[]", value))
    return fmiError;
#if NUMBER_OF_REALS > 0
  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetReal", vr[i], NUMBER_OF_REALS))
      return fmiError;
    value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetReal: #r%u# = %.16g", vr[i], value[i])
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetInteger", modelInitializationMode|modelInitialized|modelStepping|modelError))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetInteger", "vr[]", vr))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetInteger", "value[]", value))
    return fmiError;
  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetInteger: #i%u# = %d", vr[i], value[i])
  }
  return fmiOK;
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]){
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetBoolean", modelInitializationMode|modelInitialized|modelStepping|modelError))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiGetBoolean", "value[]", value))
    return fmiError;
  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false")
  }
  return fmiOK;
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetString", modelInitializationMode|modelInitialized|modelStepping|modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "value[]", value))
    return fmiError;
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetString: #s%u# = '%s'", vr[i], value[i])
  }
  return fmiOK;
}

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetReal", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiSetReal", "vr[]", vr))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiSetReal", "value[]", value))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetReal: nvr = %d", nvr)
  // no check whether setting the value is allowed in the current state
  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetReal: #r%d# = %.16g", vr[i], value[i])
    if (setReal(comp, vr[i], value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetInteger", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiSetInteger", "vr[]", vr))
    return fmiError;
  if (nvr > 0 && nullPointer(comp, "fmiSetInteger", "value[]", value))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetInteger: nvr = %d", nvr)

  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetInteger: #i%d# = %d", vr[i], value[i])
    if (setInteger(comp, vr[i], value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetBoolean", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "value[]", value))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetBoolean: nvr = %d", nvr)

  for (i = 0; i < nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false")
    if (setBoolean(comp, vr[i], value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]) {
  int i, n;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetString", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "value[]", value))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetString: nvr = %d", nvr)

  for (i = 0; i < nvr; i++) {
    char* string = (char*)comp->fmuData->localData[0]->stringVars[vr[i]];
    if (vrOutOfRange(comp, "fmiSetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetString: #s%d# = '%s'", vr[i], value[i])

    if (nullPointer(comp, "fmiSetString", "value[i]", value[i]))
      return fmiError;
    if (string == NULL || strlen(string) < strlen(value[i])) {
      if (string) comp->functions->freeMemory(string);
      comp->fmuData->localData[0]->stringVars[vr[i]] = *(fmiString*)comp->functions->allocateMemory(1 + strlen(value[i]), sizeof(char));
      if (!comp->fmuData->localData[0]->stringVars[vr[i]]) {
        comp->state = modelError;
        FILTERED_LOG(comp, fmiError, LOG_STATUSERROR, "fmiSetString: Out of memory.")
        return fmiError;
      }
    }
    strcpy((char*)comp->fmuData->localData[0]->stringVars[vr[i]], (char*)value[i]);
  }
  return fmiOK;
}

fmiStatus fmiGetFMUstate(fmiComponent c, fmiFMUstate* FMUstate) {
  return unsupportedFunction(c, "fmiGetFMUstate", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiSetFMUstate(fmiComponent c, fmiFMUstate FMUstate) {
  return unsupportedFunction(c, "fmiSetFMUstate", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiFreeFMUstate(fmiComponent c, fmiFMUstate* FMUstate) {
  return unsupportedFunction(c, "fmiFreeFMUstate", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiSerializedFMUstateSize(fmiComponent c, fmiFMUstate FMUstate, size_t *size) {
  return unsupportedFunction(c, "fmiSerializedFMUstateSize", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiSerializeFMUstate(fmiComponent c, fmiFMUstate FMUstate, fmiByte serializedState[], size_t size) {
  return unsupportedFunction(c, "fmiSerializeFMUstate", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiDeSerializeFMUstate(fmiComponent c, const fmiByte serializedState[], size_t size, fmiFMUstate* FMUstate) {
  return unsupportedFunction(c, "fmiDeSerializeFMUstate", modelInstantiated|modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

fmiStatus fmiGetDirectionalDerivative(fmiComponent c, const fmiValueReference vUnknown_ref[], size_t nUnknown, const fmiValueReference vKnown_ref[] , size_t nKnown,
    const fmiReal dvKnown[], fmiReal dvUnknown[]) {
  return unsupportedFunction(c, "fmiGetDirectionalDerivative", modelInitializationMode|modelInitialized|modelStepping|modelTerminated|modelError);
}

/***************************************************
Functions for FMI for Model Exchange
****************************************************/
fmiStatus fmiEnterEventMode(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiEnterEventMode", modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_EVENTS, "fmiEnterEventMode")
  return fmiOK;
}

fmiStatus fmiNewDiscreteStates(fmiComponent c, fmiEventInfo* eventInfo) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiNewDiscreteStates", modelInitialized|modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiNewDiscreteStates")

  if (comp->state == modelStepping) {
    comp->eventInfo.newDiscreteStatesNeeded = fmiFalse;
    comp->eventInfo.terminateSimulation = fmiFalse;
    comp->eventInfo.nominalsOfContinuousStatesChanged = fmiFalse;
    comp->eventInfo.valuesOfContinuousStatesChanged = fmiFalse;
    double nextSampleEvent = 0;
    nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
    if (nextSampleEvent == -1){
      comp->eventInfo.nextEventTimeDefined = fmiFalse;
    }else{
      comp->eventInfo.nextEventTimeDefined = fmiTrue;
      comp->eventInfo.nextEventTime = nextSampleEvent;
      //fmiEventUpdate(comp, fmiFalse, &(comp->eventInfo));
    }
  }
  // model in stepping state
  comp->state = modelStepping;
  // copy internal eventInfo of component to output eventInfo
  eventInfo->newDiscreteStatesNeeded = comp->eventInfo.newDiscreteStatesNeeded;
  eventInfo->terminateSimulation = comp->eventInfo.terminateSimulation;
  eventInfo->nominalsOfContinuousStatesChanged = comp->eventInfo.nominalsOfContinuousStatesChanged;
  eventInfo->valuesOfContinuousStatesChanged = comp->eventInfo.valuesOfContinuousStatesChanged;
  eventInfo->nextEventTimeDefined = comp->eventInfo.nextEventTimeDefined;
  eventInfo->nextEventTime = comp->eventInfo.nextEventTime;

  return fmiOK;
}

fmiStatus fmiEnterContinuousTimeMode(fmiComponent c) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiEnterContinuousTimeMode", modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL,"fmiEnterContinuousTimeMode")
  return fmiOK;
}

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean noSetFMUStatePriorToCurrentPoint, fmiBoolean* enterEventMode, fmiBoolean* terminateSimulation) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiCompletedIntegratorStep", modelStepping))
    return fmiError;
  if (nullPointer(comp, "fmiCompletedIntegratorStep", "enterEventMode", enterEventMode))
    return fmiError;
  if (nullPointer(comp, "fmiCompletedIntegratorStep", "terminateSimulation", terminateSimulation))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL,"fmiCompletedIntegratorStep")

  comp->fmuData->callback->functionAlgebraics(comp->fmuData);
  comp->fmuData->callback->output_function(comp->fmuData);
  comp->fmuData->callback->function_storeDelayed(comp->fmuData);
  storePreValues(comp->fmuData);
  *enterEventMode = fmiFalse;
  *terminateSimulation = fmiFalse;
  /******** check state selection ********/
  if (stateSelection(comp->fmuData,1, 0))
  {
    /* if new set is calculated reinit the solver */
    *enterEventMode = fmiTrue;
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL,"fmiEventUpdate: Need to iterate state values changed!")
  }
  /* TODO: fix the extrapolation in non-linear system
   *       then we can stop to save all variables in
   *       in the whole ringbuffer
   */
  overwriteOldSimulationData(comp->fmuData);
  return fmiOK;
}

fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetTime", modelInstantiated|modelInitialized|modelStepping))
    return fmiError;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetTime: time=%.16g", time)
  comp->fmuData->localData[0]->timeValue = time;
  return fmiOK;
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx) {
  ModelInstance *comp = (ModelInstance *)c;
  int i;
  if (invalidState(comp, "fmiSetContinuousStates", modelStepping))
    return fmiError;
  if (invalidNumber(comp, "fmiSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiSetContinuousStates", "x[]", x))
    return fmiError;
#if NUMBER_OF_REALS>0
  for (i = 0; i < nx; i++) {
    fmiValueReference vr = vrStates[i];
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiSetContinuousStates: #r%d#=%.16g", vr, x[i])
    assert(vr >= 0 && vr < NUMBER_OF_REALS);
    if (setReal(comp, vr, x[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
  int i;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetDerivatives", modelInitialized|modelStepping|modelTerminated))
    return fmiError;
  if (invalidNumber(comp, "fmiGetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetDerivatives", "derivatives[]", derivatives))
    return fmiError;
#if NUMBER_OF_STATES>0
  for (i = 0; i < nx; i++) {
    fmiValueReference vr = vrStates[i] + 1;
    derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetDerivatives: #r%d# = %.16g", vr, derivatives[i])
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t nx) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetEventIndicators", modelInitialized|modelStepping|modelTerminated))
    return fmiError;
  if (invalidNumber(comp, "fmiGetEventIndicators", "nx", nx, NUMBER_OF_EVENT_INDICATORS))
    return fmiError;
#if NUMBER_OF_EVENT_INDICATORS>0
  /* eval needed equations*/
  comp->fmuData->callback->function_ZeroCrossingsEquations(comp->fmuData);
  comp->fmuData->callback->function_ZeroCrossings(comp->fmuData,comp->fmuData->simulationInfo.zeroCrossings);
  for (i = 0; i < ni; i++) {
    eventIndicators[i] = comp->fmuData->simulationInfo.zeroCrossings[i];
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetEventIndicators: z%d = %.16g", i, eventIndicators[i])
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal x[], size_t nx) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetContinuousStates", modelInitialized|modelStepping|modelTerminated))
    return fmiError;
  if (invalidNumber(comp, "fmiGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetContinuousStates", "states[]", x))
    return fmiError;
#if NUMBER_OF_REALS>0
  for (i = 0; i < nx; i++) {
    fmiValueReference vr = vrStates[i];
    x[i] = getReal(comp, vr); // to be implemented by the includer of this file
    FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetContinuousStates: #r%u# = %.16g", vr, x[i])
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetNominalsOfContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx) {
  int i;
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetNominalsOfContinuousStates", modelInstantiated|modelInitialized|modelStepping|modelTerminated))
    return fmiError;
  if (invalidNumber(comp, "fmiGetNominalsOfContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetNominalsOfContinuousStates", "x_nominal[]", x_nominal))
    return fmiError;
  x_nominal[0] = 1;
  FILTERED_LOG(comp, fmiOK, LOG_FMI_CALL, "fmiGetNominalsOfContinuousStates: x_nominal[0..%d] = 1.0", nx-1)
  for (i = 0; i < nx; i++)
    x_nominal[i] = 1;
  return fmiOK;
}

/***************************************************
Functions for FMI for Co-Simulation
****************************************************/
fmiStatus fmiSetRealInputDerivatives(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger order[], const fmiReal value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetRealOutputDerivatives (fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger order[], fmiReal value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiDoStep(fmiComponent c, fmiReal currentCommunicationPoint, fmiReal communicationStepSize, fmiBoolean noSetFMUStatePriorToCurrentPoint) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiCancelStep(fmiComponent c) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetStatus(fmiComponent c, const fmiStatusKind s, fmiStatus* value) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetRealStatus(fmiComponent c, const fmiStatusKind s, fmiReal* value) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetIntegerStatus(fmiComponent c, const fmiStatusKind s, fmiInteger* value) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetBooleanStatus(fmiComponent c, const fmiStatusKind s, fmiBoolean* value) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetStringStatus(fmiComponent c, const fmiStatusKind s, fmiString* value) {
  // TODO Write code here
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

fmiStatus fmiSetExternalFunction(fmiComponent c, fmiValueReference vr[], size_t nvr, const void* value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInstantiated))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetExternalFunction", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetExternalFunction", "value[]", value))
    return fmiError;
  if (comp->loggingOn) comp->functions->logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetExternalFunction");
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmiError;
    if (setExternalFunction(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

// relation functions used in zero crossing detection
fmiReal
FmiLess(fmiReal a, fmiReal b)
{
  return a - b;
}

fmiReal
FmiLessEq(fmiReal a, fmiReal b)
{
  return a - b;
}

fmiReal
FmiGreater(fmiReal a, fmiReal b)
{
  return b - a;
}

fmiReal
FmiGreaterEq(fmiReal a, fmiReal b)
{
  return b - a;
}
