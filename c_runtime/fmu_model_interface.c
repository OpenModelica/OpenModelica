#ifndef __FMU_MODEL_INTERFACE_C__
#define __FMU_MODEL_INTERFACE_C__

#include <string>
#include "solver_main.h"

extern "C" {

// array of value references of states
#if NUMBER_OF_STATES>0
fmiValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmiValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif


static fmiBoolean invalidNumber(ModelInstance* comp, const char* f, const char* arg, int n, int nExpected){
  if (n != nExpected) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
      "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean invalidState(ModelInstance* comp, const char* f, int statesExpected){
  if (!comp)
    return fmiTrue;
  if (!(comp->state & statesExpected)) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
      "%s: Illegal call sequence.", f);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean nullPointer(ModelInstance* comp, const char* f, const char* arg, const void* p){
  if (!p) {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
      "%s: Invalid argument %s = NULL.", f, arg);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean vrOutOfRange(ModelInstance* comp, const char* f, fmiValueReference vr, unsigned int end) {
  if (vr >= end) {
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
      "%s: Illegal value reference %u.", f, vr);
    comp->state = modelError;
    return fmiTrue;
  }
  return fmiFalse;
}

// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

const char* fmiGetModelTypesPlatform() {
  return fmiModelTypesPlatform;
}

const char* fmiGetVersion() {
  return fmiVersion;
}

// ---------------------------------------------------------------------------
// FMI functions: creation and destruction of a model instance
// ---------------------------------------------------------------------------

static DATA *initializeDataStruc2(DATA *returnData)
{
  if (returnData->nStates) {
    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nStates);
    returnData->states_old = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->states_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->states&&returnData->states_old&&returnData->states_old2);
    memset(returnData->states,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesFilterOutput,0,sizeof(modelica_boolean)*returnData->nStates);
    memset(returnData->states_old,0,sizeof(double)*returnData->nStates);
    memset(returnData->states_old2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->states = 0;
    returnData->statesFilterOutput = 0;
    returnData->states_old = 0;
    returnData->states_old2 = 0;
  }

  if (returnData->nStates) {
    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivativesFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nStates);
    returnData->statesDerivatives_old = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivatives_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivativesBackup = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->statesDerivatives&&returnData->statesDerivatives_old&&returnData->statesDerivatives_old2&&returnData->statesDerivativesBackup);
    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivativesFilterOutput,0,sizeof(modelica_boolean)*returnData->nStates);
    memset(returnData->statesDerivatives_old,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivatives_old2,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivativesBackup,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->statesDerivatives = 0;
    returnData->statesDerivativesFilterOutput = 0;
    returnData->statesDerivatives_old = 0;
    returnData->statesDerivatives_old2 = 0;
    returnData->statesDerivativesBackup = 0;
  }

  if (returnData->nHelpVars) {
    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);
    assert(returnData->helpVars);
    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);
  } else {
    returnData->helpVars = 0;
  }

  if (returnData->nAlgebraic) {
    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nAlgebraic);
    returnData->algebraics_old = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->algebraics_old2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    assert(returnData->algebraics&&returnData->algebraics_old&&returnData->algebraics_old2);
    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->nAlgebraic);
    memset(returnData->algebraics_old,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->algebraics_old2,0,sizeof(double)*returnData->nAlgebraic);
  } else {
    returnData->algebraics = 0;
    returnData->algebraicsFilterOutput = 0;
    returnData->algebraics_old = 0;
    returnData->algebraics_old2 = 0;
  }

  if (returnData->stringVariables.nAlgebraic) {
    returnData->stringVariables.algebraics = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);
    assert(returnData->stringVariables.algebraics);
    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);
  } else {
    returnData->stringVariables.algebraics=0;
  }
  
  if (returnData->intVariables.nAlgebraic) {
    returnData->intVariables.algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraics_old = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraics_old2 = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    assert(returnData->intVariables.algebraics&&returnData->intVariables.algebraics_old&&returnData->intVariables.algebraics_old2);
    memset(returnData->intVariables.algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraics_old,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraics_old2,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
  } else {
    returnData->intVariables.algebraics=0;
    returnData->intVariables.algebraicsFilterOutput=0;
    returnData->intVariables.algebraics_old = 0;
    returnData->intVariables.algebraics_old2 = 0;
  }

  if (returnData->boolVariables.nAlgebraic) {
    returnData->boolVariables.algebraics = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraics_old = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraics_old2 = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    assert(returnData->boolVariables.algebraics&&returnData->boolVariables.algebraics_old&&returnData->boolVariables.algebraics_old2);
    memset(returnData->boolVariables.algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraics_old,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraics_old2,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
  } else {
    returnData->boolVariables.algebraics=0;
    returnData->boolVariables.algebraicsFilterOutput=0;
    returnData->boolVariables.algebraics_old = 0;
    returnData->boolVariables.algebraics_old2 = 0;
  }
  
  if (returnData->nParameters) {
    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);
    assert(returnData->parameters);
    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);
  } else {
    returnData->parameters = 0;
  }

  if (returnData->stringVariables.nParameters) {
    returnData->stringVariables.parameters = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);
      assert(returnData->stringVariables.parameters);
      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);
  } else {
      returnData->stringVariables.parameters=0;
  }
  
  if (returnData->intVariables.nParameters) {
    returnData->intVariables.parameters = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nParameters);
      assert(returnData->intVariables.parameters);
      memset(returnData->intVariables.parameters,0,sizeof(modelica_integer)*returnData->intVariables.nParameters);
  } else {
      returnData->intVariables.parameters=0;
  }
  
  if (returnData->boolVariables.nParameters) {
    returnData->boolVariables.parameters = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
      assert(returnData->boolVariables.parameters);
      memset(returnData->boolVariables.parameters,0,sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
  } else {
      returnData->boolVariables.parameters=0;
  }
  
  if (returnData->nOutputVars) {
    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);
    assert(returnData->outputVars);
    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);
  } else {
    returnData->outputVars = 0;
  }

  if (returnData->nInputVars) {
    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);
    assert(returnData->inputVars);
    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);
  } else {
    returnData->inputVars = 0;
  }

  if (returnData->nAlias) {
    returnData->realAlias = (DATA_REAL_ALIAS*) malloc(sizeof(DATA_REAL_ALIAS)*returnData->nAlias);
    assert(returnData->realAlias);
    returnData->aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nAlias);
    assert(returnData->aliasFilterOutput);
    memset(returnData->realAlias,0,sizeof(DATA_REAL_ALIAS)*returnData->nAlias);
    memset(returnData->aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->nAlias);
  } else {
    returnData->realAlias = 0;
    returnData->aliasFilterOutput = 0;
  }

  if (returnData->intVariables.nAlias) {
    returnData->intVariables.alias = (DATA_INT_ALIAS*) malloc(sizeof(DATA_INT_ALIAS)*returnData->intVariables.nAlias);
    assert(returnData->intVariables.alias);
    returnData->intVariables.aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->intVariables.nAlias);
    assert(returnData->intVariables.aliasFilterOutput);
    memset(returnData->intVariables.alias,0,sizeof(DATA_INT_ALIAS)*returnData->intVariables.nAlias);
    memset(returnData->intVariables.aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->intVariables.nAlias);
  } else {
    returnData->intVariables.alias = 0;
    returnData->intVariables.aliasFilterOutput=0;
  }

  if (returnData->boolVariables.nAlias) {
    returnData->boolVariables.alias = (DATA_BOOL_ALIAS*) malloc(sizeof(DATA_BOOL_ALIAS)*returnData->boolVariables.nAlias);
    assert(returnData->boolVariables.alias);
    returnData->boolVariables.aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlias);
    assert(returnData->boolVariables.aliasFilterOutput);
    memset(returnData->boolVariables.alias,0,sizeof(DATA_BOOL_ALIAS)*returnData->boolVariables.nAlias);
    memset(returnData->boolVariables.aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlias);
  } else {
    returnData->boolVariables.alias = 0;
    returnData->boolVariables.aliasFilterOutput=0;
  }

  if (returnData->stringVariables.nAlias) {
    returnData->stringVariables.alias = (DATA_STRING_ALIAS*) malloc(sizeof(DATA_STRING_ALIAS)*returnData->stringVariables.nAlias);
    assert(returnData->stringVariables.alias);
    memset(returnData->stringVariables.alias,0,sizeof(DATA_STRING_ALIAS)*returnData->stringVariables.nAlias);
  } else {
    returnData->stringVariables.alias = 0;
  }
    
  if (returnData->nJacobianvars) {
    returnData->jacobianVars = (double*) malloc(sizeof(double)*returnData->nJacobianvars);
    assert(returnData->jacobianVars);
    memset(returnData->jacobianVars,0,sizeof(double)*returnData->nJacobianvars);
  } else {
    returnData->jacobianVars = 0;
  }

  if (returnData->nInitialResiduals) {
    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);
    assert(returnData->initialResiduals);
    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);
  } else {
    returnData->initialResiduals = 0;
  }

  if (returnData->nRawSamples) {
    returnData->rawSampleExps = (sample_raw_time*) malloc(sizeof(sample_raw_time)*returnData->nRawSamples);
    assert(returnData->rawSampleExps);
    memset(returnData->rawSampleExps,0,sizeof(sample_raw_time)*returnData->nRawSamples);
  } else {
    returnData->rawSampleExps = 0;
  }
  return returnData;
}

fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID,
                 fmiCallbackFunctions functions, fmiBoolean loggingOn) {
                   ModelInstance* comp;
                   if (!functions.logger)
                     return NULL;
                   if (!functions.allocateMemory || !functions.freeMemory){
                     functions.logger(NULL, instanceName, fmiError, "error",
                       "fmiInstantiateModel: Missing callback function.");
                     return NULL;
                   }
                   if (!instanceName || strlen(instanceName)==0) {
                     functions.logger(NULL, instanceName, fmiError, "error",
                       "fmiInstantiateModel: Missing instance name.");
                     return NULL;
                   }
                   if (strcmp(GUID, MODEL_GUID)) {
                     functions.logger(NULL, instanceName, fmiError, "error",
                       "fmiInstantiateModel: Wrong GUID %s. Expected %s.", GUID, MODEL_GUID);
                     return NULL;
                   }
                   comp = (ModelInstance *)functions.allocateMemory(1, sizeof(ModelInstance));
                   if (comp) {
                     comp->r = (fmiReal*)functions.allocateMemory(NUMBER_OF_REALS,    sizeof(fmiReal));
                     comp->i = (fmiInteger*)functions.allocateMemory(NUMBER_OF_INTEGERS, sizeof(fmiInteger));
                     comp->b = (fmiBoolean*)functions.allocateMemory(NUMBER_OF_BOOLEANS, sizeof(fmiBoolean));
                     comp->s = (fmiString*)functions.allocateMemory(NUMBER_OF_STRINGS,  sizeof(fmiString));
                     comp->isPositive = (fmiBoolean*)calloc(NUMBER_OF_EVENT_INDICATORS, sizeof(fmiBoolean));
                   }
                   if (!comp || !comp->r || !comp->i || !comp->b || !comp->s || !comp->isPositive) {
                     functions.logger(NULL, instanceName, fmiError, "error",
                       "fmiInstantiateModel: Out of memory.");
                     return NULL;
                   }
                   if (comp->loggingOn) comp->functions.logger(NULL, instanceName, fmiOK, "log",
                     "fmiInstantiateModel: GUID=%s", GUID);
                   comp->instanceName = instanceName;
                   comp->GUID = GUID;
                   comp->functions = functions;
                   comp->loggingOn = loggingOn;
                   comp->state = modelInstantiated;
                   comp->eventInfo.iterationConverged = fmiTrue;
                   comp->eventInfo.stateValueReferencesChanged = fmiTrue;
                   comp->eventInfo.stateValuesChanged = fmiTrue;
                   comp->eventInfo.terminateSimulation = fmiFalse;
                   comp->eventInfo.upcomingTimeEvent = fmiFalse;
                   comp->eventInfo.nextEventTime = 0;

                   globalData = NULL;
                   globalData = initializeDataStruc2(initializeDataStruc());
                   if (!globalData) {
                       functions.logger(NULL, instanceName, fmiError, "error",
                       "fmiInstantiateModel: Error: Could not initialize the global data structure file.");
                       return NULL;
                    }
                   comp->time = &globalData->timeValue;
                   setLocalData(globalData);
                   sim_verbose = comp->loggingOn?1:0;
                   sim_noemit = 0;
                   jac_flag = 0;
                   num_jac_flag = 0;
                   warningLevelAssert = 1;

                   setStartValues(comp); // to be implemented by the includer of this file

                   callExternalObjectConstructors(globalData);
                   return comp;
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetDebugLogging", not_modelError))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiSetDebugLogging: loggingOn=%d", loggingOn);
  comp->loggingOn = loggingOn;
  return fmiOK;
}

void fmiFreeModelInstance(fmiComponent c) {
  ModelInstance* comp = (ModelInstance *)c;
  if (!comp) return;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiFreeModelInstance");
  if (comp->r) comp->functions.freeMemory(comp->r);
  if (comp->i) comp->functions.freeMemory(comp->i);
  if (comp->b) comp->functions.freeMemory(comp->b);
  if (comp->s) {
    int i;
    for (i=0; i<NUMBER_OF_STRINGS; i++){
      if (comp->s[i]) comp->functions.freeMemory((void*)comp->s[i]);
    }
    comp->functions.freeMemory(comp->s);
  }
  comp->functions.freeMemory(comp);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetReal", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetReal", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetReal", "value[]", value))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiSetReal: nvr = %d", nvr);
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetReal: #r%d# = %.16g", vr[i], value[i]);
    if (setReal(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  comp->outputsvalid = fmiFalse;
  comp->eventInfo.stateValuesChanged = fmiTrue;
  return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetInteger", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetInteger", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetInteger", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetInteger: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetInteger: #i%d# = %d", vr[i], value[i]);
    if (setInteger(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  comp->outputsvalid = fmiFalse;
  comp->eventInfo.stateValuesChanged = fmiTrue;
  return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetBoolean", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetBoolean", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetBoolean: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetBoolean: #b%d# = %s", vr[i], value[i] ? "true" : "false");
    if (setBoolean(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  comp->outputsvalid = fmiFalse;
  comp->eventInfo.stateValuesChanged = fmiTrue;
  return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetString", modelInstantiated|modelInitialized))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiSetString", "value[]", value))
    return fmiError;
  if (comp->loggingOn)
    comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiSetString: nvr = %d",  nvr);
  for (i=0; i<nvr; i++) {
    char* string = (char*)comp->s[vr[i]];
    if (vrOutOfRange(comp, "fmiSetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetString: #s%d# = '%s'", vr[i], value[i]);
    if (nullPointer(comp, "fmiSetString", "value[i]", value[i]))
      return fmiError;
    if (string==NULL || strlen(string) < strlen(value[i])) {
      if (string) comp->functions.freeMemory(string);
      comp->s[vr[i]] = *(fmiString*)comp->functions.allocateMemory(1+strlen(value[i]), sizeof(char));
      if (!comp->s[vr[i]]) {
        comp->state = modelError;
        comp->functions.logger(NULL, comp->instanceName, fmiError, "error", "fmiSetString: Out of memory.");
        return fmiError;
      }
    }
    strcpy((char*)comp->s[vr[i]], (char*)value[i]);
  }
  comp->outputsvalid = fmiFalse;
  comp->eventInfo.stateValuesChanged = fmiTrue;
  return fmiOK;
}

fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetTime", modelInstantiated|modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiSetTime: time=%.16g", time);
  *comp->time = time;
  return fmiOK;
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx){
  ModelInstance* comp = (ModelInstance *)c;
  unsigned int i=0;
  if (invalidState(comp, "fmiSetContinuousStates", modelInitialized))
    return fmiError;
  if (invalidNumber(comp, "fmiSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiSetContinuousStates", "x[]", x))
    return fmiError;
#if NUMBER_OF_STATES>0
  comp->eventInfo.stateValuesChanged = fmiTrue;
  comp->outputsvalid = fmiFalse;
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetContinuousStates: #r%d#=%.16g", vr, x[i]);
    assert(vr>=0 && vr<NUMBER_OF_REALS);
    if (setReal(comp, vr,x[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
#endif
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetReal", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "value[]", value))
    return fmiError;
#if NUMBER_OF_REALS>0
  // calculate new values
  if (comp->eventInfo.stateValuesChanged == fmiTrue)
  {
    int needToIterate = 0;
    functionDAE(&needToIterate);
    comp->eventInfo.stateValuesChanged = fmiFalse;
  }
  if (comp->outputsvalid == fmiFalse)
  {
     functionAliasEquations();
     comp->outputsvalid = fmiTrue;
  }
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    value[i] = getReal(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetReal: #r%u# = %.16g", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiError;
#endif
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetInteger", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "value[]", value))
    return fmiError;
#if NUMBER_OF_INTEGERS>0
  // calculate new values
  if (comp->eventInfo.stateValuesChanged == fmiTrue)
  {
    int needToIterate = 0;
    functionDAE(&needToIterate);
    comp->eventInfo.stateValuesChanged = fmiFalse;
  }
  if (comp->outputsvalid == fmiFalse)
  {
     functionAliasEquations();
     comp->outputsvalid = fmiTrue;
  }
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetInteger: #i%u# = %d", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiError;
#endif
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetBoolean", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "value[]", value))
    return fmiError;
#if NUMBER_OF_BOOLEANS>0
  // calculate new values
  if (comp->eventInfo.stateValuesChanged == fmiTrue)
  {
    int needToIterate = 0;
    functionDAE(&needToIterate);
    comp->eventInfo.stateValuesChanged = fmiFalse;
  }
  if (comp->outputsvalid == fmiFalse)
  {
     functionAliasEquations();
     comp->outputsvalid = fmiTrue;
  }
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
     value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false");
  }
  return fmiOK;
#else
  return fmiError;
#endif
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetString", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "value[]", value))
    return fmiError;
#if NUMBER_OF_STRINGS>0
  // calculate new values
  if (comp->eventInfo.stateValuesChanged == fmiTrue)
  {
    functionODE();
    comp->eventInfo.stateValuesChanged == fmiFalse;
  }
  if (comp->outputsvalid == fmiFalse)
  {
     functionAlgebraics();
     functionAliasEquations();
     comp->outputsvalid = fmiTrue;
  }
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
     value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetString: #s%u# = '%s'", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiError;
#endif
}

fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetStateValueReferences", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetStateValueReferences", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetStateValueReferences", "vrx[]", vrx))
    return fmiError;
#if NUMBER_OF_STATES>0
  for (i=0; i<nx; i++) {
    vrx[i] = vrStates[i];
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetStateValueReferences: vrx[%d] = %d", i, vrx[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetContinuousStates", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetContinuousStates", "states[]", states))
    return fmiError;
#if NUMBER_OF_STATES>0
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    states[i] = getReal(comp, vr); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetContinuousStates: #r%u# = %.16g", vr, states[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx){
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetNominalContinuousStates", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetNominalContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetNominalContinuousStates", "x_nominal[]", x_nominal))
    return fmiError;
  x_nominal[0] = 1;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiGetNominalContinuousStates: x_nominal[0..%d] = 1.0", nx-1);
  for (i=0; i<nx; i++)
    x_nominal[i] = 1;
  return fmiOK;
}

fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetDerivatives", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetDerivatives", "derivatives[]", derivatives))
    return fmiError;
#if NUMBER_OF_STATES>0
  if (comp->eventInfo.stateValuesChanged == fmiTrue)
  {
    // calculate new values
    int needToIterate = 0;
    functionDAE(&needToIterate);
    for (i=0; i<nx; i++) {
      fmiValueReference vr = vrStatesDerivatives[i];
      derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
      if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetDerivatives: #r%d# = %.16g", vr, derivatives[i]);
    }
    comp->eventInfo.stateValuesChanged = fmiFalse;
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni) {
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetEventIndicators", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetEventIndicators", "ni", ni, NUMBER_OF_EVENT_INDICATORS))
    return fmiError;
#if NUMBER_OF_EVENT_INDICATORS>0
 // for (i=0; i<ni; i++) {
    //eventIndicators[i] = getEventIndicator(comp, i); // to be implemented by the includer of this file
    getEventIndicator(comp, eventIndicators); // to be implemented by the includer of this file
    if (comp->loggingOn)
      {
      for (i=0; i<ni; i++) {
        comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiGetEventIndicators: z%d = %.16g", i, eventIndicators[i]);
      }
  }
#endif
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance,
            fmiEventInfo* eventInfo) {
              int sampleEvent_actived = 0;
              ModelInstance* comp = (ModelInstance *)c;
              if (invalidState(comp, "fmiInitialize", modelInstantiated))
                return fmiError;
              if (nullPointer(comp, "fmiInitialize", "eventInfo", eventInfo))
                return fmiError;
              if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
                "fmiInitialize: toleranceControlled=%d relativeTolerance=%g",
                toleranceControlled, relativeTolerance);
              eventInfo->iterationConverged  = comp->eventInfo.iterationConverged;
              eventInfo->stateValueReferencesChanged = comp->eventInfo.stateValueReferencesChanged;
              eventInfo->stateValuesChanged  = comp->eventInfo.stateValuesChanged;
              eventInfo->terminateSimulation = comp->eventInfo.terminateSimulation;
              eventInfo->upcomingTimeEvent   = comp->eventInfo.upcomingTimeEvent;
              globalData->lastEmittedTime = *comp->time;
              globalData->forceEmit = 0;
              initSample(*comp->time, 1e10);
              initDelay(*comp->time);

              if (initializeEventData()) {
                comp->functions.logger(c, comp->instanceName, fmiError, "log",
                "fmiInitialize: initializeEventData failed");
                return fmiError;
              }

              if(bound_parameters()) {
                comp->functions.logger(c, comp->instanceName, fmiError, "log",
                "fmiInitialize: bound_parameters failed");
                return fmiError;
              }

              // Evaluate all constant equations
              functionAliasEquations();

              std::string init_method = std::string("simplex");

              try{
                if (main_initialize(&init_method))
                  {
                    comp->functions.logger(c, comp->instanceName, fmiError, "log",
                    "fmiInitialize: main_initialize failed");
                    return fmiError;
                  }

                SaveZeroCrossings();
                saveall();

                //Activate sample and evaluate again
                if (globalData->curSampleTimeIx < globalData->nSampleTimes)
                  {
                    sampleEvent_actived = checkForSampleEvent();
                    activateSampleEvents();
                  }
                update_DAEsystem();
                SaveZeroCrossings();
                if (sampleEvent_actived)
                  {
                    deactivateSampleEventsandEquations();
                    sampleEvent_actived = 0;
                  }
                saveall();
                storeExtrapolationData();
                storeExtrapolationData();
              }
              catch (TerminateSimulationException &e)
              {
                comp->functions.logger(c, comp->instanceName, fmiError, "log",
                "fmiInitialize: fmiInitialize failed!");
                return fmiError;
              }
              // Initialization complete

              comp->state = modelInitialized;
              return fmiOK;
}

fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo) {
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiEventUpdate", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiEventUpdate", "eventInfo", eventInfo))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiEventUpdate: intermediateResults = %d", intermediateResults);
  eventInfo->iterationConverged  = fmiTrue;
  eventInfo->stateValueReferencesChanged = fmiFalse;
  eventInfo->stateValuesChanged  = fmiFalse;
  eventInfo->terminateSimulation = fmiFalse;
  eventInfo->upcomingTimeEvent   = fmiFalse;
  eventUpdate(comp, eventInfo); // to be implemented by the includer of this file
  return fmiOK;
}

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate){
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiCompletedIntegratorStep", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiCompletedIntegratorStep", "callEventUpdate", callEventUpdate))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiCompletedIntegratorStep");
  *callEventUpdate = fmiFalse;
  return fmiOK;
}

fmiStatus fmiTerminate(fmiComponent c){
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiTerminate");

  deinitDelay();
  deInitializeDataStruc(globalData);
  free(globalData);

  comp->state = modelTerminated;
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
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
    "fmiSetExternalFunction");
  // no check wether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiSetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmiError;
    if (setExternalFunction(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
};

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


#endif
