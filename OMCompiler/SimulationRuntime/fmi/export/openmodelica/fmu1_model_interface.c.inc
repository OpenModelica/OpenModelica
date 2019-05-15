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

#include "../simulation_data.h"
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
#include "../simulation/solver/nonlinearSystem.h"
#include "../simulation/solver/linearSystem.h"
#include "../simulation/solver/mixedSystem.h"
#include "../simulation/solver/delay.h"
#include "../simulation/solver/fmi_events.h"
#include "../simulation/simulation_info_json.h"
#include "../simulation/simulation_input_xml.h"

/*
DLLExport pthread_key_t fmu1_thread_data_key;
*/

// array of value references of states
#if NUMBER_OF_STATES>0
fmiValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmiValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif

static fmiBoolean invalidNumber(ModelInstance* comp, const char* f, const char* arg, int n, int nExpected)
{
  if (n != nExpected)
  {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Invalid argument %s = %d. Expected %d.", f, arg, n, nExpected);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean invalidState(ModelInstance* comp, const char* f, int statesExpected)
{
  if (!comp)
    return fmiTrue;
  if (!(comp->state & statesExpected))
  {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Illegal call sequence. Expected State: %d.", f, statesExpected);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean nullPointer(ModelInstance* comp, const char* f, const char* arg, const void* p)
{
  if (!p)
  {
    comp->state = modelError;
    comp->functions.logger(comp, comp->instanceName, fmiError, "error",
        "%s: Invalid argument %s = NULL.", f, arg);
    return fmiTrue;
  }
  return fmiFalse;
}

static fmiBoolean vrOutOfRange(ModelInstance* comp, const char* f, fmiValueReference vr, unsigned int end)
{
  if (vr >= end)
  {
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
/***************************************************
Common Functions
****************************************************/
const char* fmiGetModelTypesPlatform()
{
  return fmiModelTypesPlatform;
}

const char* fmiGetTypesPlatform()
{
  return fmiPlatform;
}

const char* fmiGetVersion()
{
  return fmiVersion;
}

/***************************************************
Functions for FMI for Model Exchange
****************************************************/
fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn)
{
  ModelInstance* comp;
  if (!functions.logger)
    return NULL;
  if (!functions.allocateMemory || !functions.freeMemory){
    functions.logger(NULL, instanceName, fmiError, "error",
        "fmiInstantiateModel: Missing callback function.");
    return NULL;
  }
  if (!instanceName || strlen(instanceName)==0) {
    functions.logger(NULL, instanceName, fmiWarning, "Warning",
        "fmiInstantiateModel: Missing instance name.");
  }
  if (strcmp(GUID, MODEL_GUID) != 0) {
    functions.logger(NULL, instanceName, fmiError, "error",
        "fmiInstantiateModel: Wrong GUID %s. Expected %s.", GUID, MODEL_GUID);
    return NULL;
  }
  comp = (ModelInstance *)functions.allocateMemory(1, sizeof(ModelInstance));
  if (comp) {
    DATA* fmudata = NULL;
  MODEL_DATA* modelData = NULL;
  SIMULATION_INFO* simInfo = NULL;
  threadData_t *threadData = NULL;

    comp->functions = functions;
    comp->loggingOn = loggingOn;
    comp->state = modelInstantiated;
    comp->instanceName = functions.allocateMemory(1 + strlen(instanceName), sizeof(char));
    comp->GUID = functions.allocateMemory(1 + strlen(GUID), sizeof(char));
    /* Cannot use functions.allocateMemory since the pointer might not be stored on the stack of the parent */
    fmudata = (DATA *)functions.allocateMemory(1, sizeof(DATA));
    modelData = (MODEL_DATA *)functions.allocateMemory(1, sizeof(MODEL_DATA));
    simInfo = (SIMULATION_INFO *)functions.allocateMemory(1, sizeof(SIMULATION_INFO));
    fmudata->modelData = modelData;
    fmudata->simulationInfo = simInfo;


    threadData = (threadData_t *)functions.allocateMemory(1, sizeof(threadData_t));
    memset(threadData, 0, sizeof(threadData_t));
    /*
    pthread_key_create(&fmu1_thread_data_key,NULL);
    pthread_setspecific(fmu1_thread_data_key, threadData);
    */

    comp->threadData = threadData;
    comp->fmuData = fmudata;

    if (!comp->fmuData) {
      functions.logger(NULL, instanceName, fmiError, "error",
          "fmiInstantiateModel: Error: Could not initialize the global data structure file.");
      return NULL;
    }
  }
  if (!comp || !comp->instanceName || !comp->GUID) {
    functions.logger(NULL, instanceName, fmiError, "error", "fmiInstantiateModel: Out of memory.");
    return NULL;
  }
  /* intialize modelData */
  fmu1_model_interface_setupDataStruc(comp->fmuData, comp->threadData);
  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;
  initializeDataStruc(comp->fmuData, comp->threadData);
  /* setup model data with default start data */
  setDefaultStartValues(comp);
  setAllVarsToStart(comp->fmuData);
  setAllParamsToStart(comp->fmuData);
  comp->fmuData->callback->read_input_fmu(comp->fmuData->modelData, comp->fmuData->simulationInfo);
  modelInfoInit(&(comp->fmuData->modelData->modelDataXml));

  strcpy((char*)comp->instanceName, (const char*)instanceName);
  strcpy((char*)comp->GUID, (const char*)GUID);

  /* read input vars */
  /* input_function(comp->fmuData);*/
  /* allocate memory for non-linear system solvers */
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
  initializeNonlinearSystems(comp->fmuData, comp->threadData);
#endif
  /* allocate memory for non-linear system solvers */
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
  initializeLinearSystems(comp->fmuData, comp->threadData);
#endif
  /* allocate memory for mixed system solvers */
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
  initializeMixedSystems(comp->fmuData, comp->threadData);
#endif
  /* allocate memory for state selection */
#if !defined(OMC_NO_STATESELECTION)
  initializeStateSetJacobians(comp->fmuData, comp->threadData);
#endif
  return comp;
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetDebugLogging", not_modelError))
    return fmiError;
  comp->loggingOn = loggingOn;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetDebugLogging: loggingOn=%d", loggingOn);
  return fmiOK;
}

void fmiFreeModelInstance(fmiComponent c)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (!comp) return;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiFreeModelInstance");

  /* free instanceName & GUID */
  if (comp->instanceName) comp->functions.freeMemory((void*)comp->instanceName);
  if (comp->GUID) comp->functions.freeMemory((void*)comp->GUID);

  /* free comp */
  comp->functions.freeMemory(comp);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[])
{
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

  return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
{
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

  return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
{
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

  return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[])
{
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
    if (vrOutOfRange(comp, "fmiSetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetString: #s%d# = '%s'", vr[i], value[i]);
    if (setString(comp, vr[i],value[i]) != fmiOK) // to be implemented by the includer of this file
      return fmiError;
  }
  return fmiOK;
}

fmiStatus fmiSetTime(fmiComponent c, fmiReal t)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiSetTime", modelInstantiated|modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiSetTime: time=%.16g", t);
  comp->fmuData->localData[0]->timeValue = t;
  return fmiOK;
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx)
{
  ModelInstance* comp = (ModelInstance *)c;
  unsigned int i=0;
  if (invalidState(comp, "fmiSetContinuousStates", modelInitialized))
    return fmiError;
  if (invalidNumber(comp, "fmiSetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
#if NUMBER_OF_STATES>0
  if (nullPointer(comp, "fmiSetContinuousStates", "x[]", x))
    return fmiError;
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiSetContinuousStates: #r%d#=%.16g", vr, x[i]);
    if (vr<0 || vr>=NUMBER_OF_REALS || setReal(comp, vr, x[i]) != fmiOK) { // to be implemented by the includer of this file
      return fmiError;
    }
  }
#endif
  return fmiOK;
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetReal", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetReal", "value[]", value))
    return fmiError;
#if NUMBER_OF_REALS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetReal", vr[i], NUMBER_OF_REALS+NUMBER_OF_STATES))
      return fmiError;
    value[i] = getReal(comp, vr[i]);
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetReal: #r%u# = %.16g", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetInteger", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetInteger", "value[]", value))
    return fmiError;
#if NUMBER_OF_INTEGERS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetInteger", vr[i], NUMBER_OF_INTEGERS))
      return fmiError;
    value[i] = getInteger(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetInteger: #i%u# = %d", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetBoolean", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetBoolean", "value[]", value))
    return fmiError;
#if NUMBER_OF_BOOLEANS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetBoolean", vr[i], NUMBER_OF_BOOLEANS))
      return fmiError;
    value[i] = getBoolean(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetBoolean: #b%u# = %s", vr[i], value[i]? "true" : "false");
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetString", not_modelError))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "vr[]", vr))
    return fmiError;
  if (nvr>0 && nullPointer(comp, "fmiGetString", "value[]", value))
    return fmiError;
#if NUMBER_OF_STRINGS>0
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmiGetString", vr[i], NUMBER_OF_STRINGS))
      return fmiError;
    value[i] = getString(comp, vr[i]); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetString: #s%u# = '%s'", vr[i], value[i]);
  }
  return fmiOK;
#else
  return fmiOK;
#endif
}

fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx)
{
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

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx)
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiGetContinuousStates", not_modelError))
    return fmiError;
#if NUMBER_OF_STATES>0
  if (invalidNumber(comp, "fmiGetContinuousStates", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetContinuousStates", "states[]", states))
    return fmiError;
  for (i=0; i<nx; i++) {
    fmiValueReference vr = vrStates[i];
    states[i] = getReal(comp, vr); // to be implemented by the includer of this file
    if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
        "fmiGetContinuousStates: #r%u# = %.16g", vr, states[i]);
  }
#endif
  return fmiOK;
}

fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx)
{
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

fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx)
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidState(comp, "fmiGetDerivatives", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetDerivatives", "nx", nx, NUMBER_OF_STATES))
    return fmiError;
  if (nullPointer(comp, "fmiGetDerivatives", "derivatives[]", derivatives))
    return fmiError;

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

    comp->fmuData->callback->functionODE(comp->fmuData, comp->threadData);
  #if (NUMBER_OF_STATES>0)
    for (i=0; i<nx; i++) {
      fmiValueReference vr = vrStatesDerivatives[i];
      derivatives[i] = getReal(comp, vr); // to be implemented by the includer of this file
      if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
          "fmiGetDerivatives: #r%d# = %.16g", vr, derivatives[i]);
    }
  #endif
    return fmiOK;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

    comp->functions.logger(c, comp->instanceName, fmiError, "error", "fmiGetDerivatives: terminated by an assertion.");
    return fmiError;
}

fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni)
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;

  if (invalidState(comp, "fmiGetEventIndicators", not_modelError))
    return fmiError;
  if (invalidNumber(comp, "fmiGetEventIndicators", "ni", ni, NUMBER_OF_EVENT_INDICATORS))
    return fmiError;

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

#if NUMBER_OF_EVENT_INDICATORS>0
    /* eval needed equations*/
    comp->fmuData->callback->function_ZeroCrossingsEquations(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_ZeroCrossings(comp->fmuData, comp->threadData, comp->fmuData->simulationInfo->zeroCrossings);
    for (i=0; i<ni; i++) {
      /* retVal = getEventIndicator(comp, i, eventIndicators[i]); // to be implemented by the includer of this file
       * getEventIndicator(comp, eventIndicators); // to be implemented by the includer of this file */
      eventIndicators[i] = comp->fmuData->simulationInfo->zeroCrossings[i];
      if (comp->loggingOn){
        comp->functions.logger(c, comp->instanceName, fmiOK, "log",
            "fmiGetEventIndicators: z%d = %.16g", i, eventIndicators[i]);
      }
    }
#endif
    return fmiOK;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

    comp->functions.logger(c, comp->instanceName, fmiError, "error", "fmiGetEventIndicators: terminated by an assertion.");
    return fmiError;
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo* eventInfo)
{
  double nextSampleEvent=0;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  threadData->currentErrorStage = ERROR_SIMULATION;

  if (invalidState(comp, "fmiInitialize", modelInstantiated))
    return fmiError;
  if (nullPointer(comp, "fmiInitialize", "eventInfo", eventInfo))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiInitialize: toleranceControlled=%d relativeTolerance=%g",
      toleranceControlled, relativeTolerance);

  /* set zero-crossing tolerance */
  setZCtol(relativeTolerance);

  setStartValues(comp);
  copyStartValuestoInitValues(comp->fmuData);

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

    if(initialization(comp->fmuData, comp->threadData, "", "", 0.0))
    {
      comp->state = modelError;
      if(comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
          "fmiInitialization: failed");
    }
    else
    {
      comp->state = modelInitialized;
      if(comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
          "fmiInitialization: succeed");
    }

    /*TODO: Simulation stop time is need to calculate in before hand all sample events
            We shouldn't generate them all in beforehand */
    initSample(comp->fmuData, comp->threadData, comp->fmuData->localData[0]->timeValue, 100 /*should be stopTime*/);
#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0
    initDelay(comp->fmuData, comp->fmuData->localData[0]->timeValue);
#endif

    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    eventInfo->iterationConverged = fmiTrue;
    eventInfo->stateValueReferencesChanged = fmiFalse;
    eventInfo->stateValuesChanged = fmiTrue;
    eventInfo->terminateSimulation = fmiFalse;

    /* Get next event time (sample calls)*/
    nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
    if (nextSampleEvent == -1){
      eventInfo->upcomingTimeEvent = fmiFalse;
    }else{
      eventInfo->upcomingTimeEvent = fmiTrue;
      eventInfo->nextEventTime = nextSampleEvent;
      fmiEventUpdate(comp, fmiFalse, eventInfo);
    }

    return fmiOK;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

    comp->functions.logger(c, comp->instanceName, fmiError, "error", "fmiInitialize: terminated by an assertion.");
    return fmiError;
}

fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo)
{
  int i;
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidState(comp, "fmiEventUpdate", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiEventUpdate", "eventInfo", eventInfo))
    return fmiError;
  eventInfo->stateValuesChanged = fmiFalse;

  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiEventUpdate: Start Event Update! Next Sample Event %g", eventInfo->nextEventTime);

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, threadData, 1, 1))
    {
      if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
          "fmiEventUpdate: Need to iterate state values changed!");
      /* if new set is calculated reinit the solver */
      eventInfo->stateValuesChanged = fmiTrue;
    }
#endif

    storePreValues(comp->fmuData);

    /* activate sample event */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i)
    {
      if(comp->fmuData->simulationInfo->nextSampleTimes[i] <= comp->fmuData->localData[0]->timeValue)
      {
        comp->fmuData->simulationInfo->samples[i] = 1;
        infoStreamPrint(LOG_EVENTS, 0, "[%ld] sample(%g, %g)", comp->fmuData->modelData->samplesInfo[i].index, comp->fmuData->modelData->samplesInfo[i].start, comp->fmuData->modelData->samplesInfo[i].interval);
      }
    }

    comp->fmuData->callback->functionDAE(comp->fmuData, threadData);

    /* deactivate sample events */
    for(i=0; i<comp->fmuData->modelData->nSamples; ++i)
    {
      if(comp->fmuData->simulationInfo->samples[i])
      {
        comp->fmuData->simulationInfo->samples[i] = 0;
        comp->fmuData->simulationInfo->nextSampleTimes[i] += comp->fmuData->modelData->samplesInfo[i].interval;
      }
    }

    for(i=0; i<comp->fmuData->modelData->nSamples; ++i)
      if((i == 0) || (comp->fmuData->simulationInfo->nextSampleTimes[i] < comp->fmuData->simulationInfo->nextSampleEvent))
        comp->fmuData->simulationInfo->nextSampleEvent = comp->fmuData->simulationInfo->nextSampleTimes[i];

    if (checkForDiscreteChanges(comp->fmuData, threadData) || comp->fmuData->simulationInfo->needToIterate || checkRelations(comp->fmuData) || eventInfo->stateValuesChanged)
    {
      intermediateResults = fmiTrue;
      if (comp->loggingOn)
        comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiEventUpdate: Need to iterate(discrete changes)!");
      eventInfo->iterationConverged  = fmiTrue;
      eventInfo->stateValueReferencesChanged = fmiFalse;
      eventInfo->stateValuesChanged  = fmiTrue;
      eventInfo->terminateSimulation = fmiFalse;
    }
    else
    {
      intermediateResults = fmiFalse;
      eventInfo->iterationConverged  = fmiTrue;
      eventInfo->stateValueReferencesChanged = fmiFalse;
      eventInfo->terminateSimulation = fmiFalse;
    }

    /* due to an event overwrite old values */
    overwriteOldSimulationData(comp->fmuData);

    /* TODO: check the event iteration for relation
     * in fmi import and export. This is an workaround,
     * since the iteration seem not starting.
     */
    storePreValues(comp->fmuData);
    updateRelationsPre(comp->fmuData);

    if (comp->loggingOn)
      comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiEventUpdate: intermediateResults = %d", intermediateResults);

    //Get Next Event Time
    double nextSampleEvent=0;
    nextSampleEvent = getNextSampleTimeFMU(comp->fmuData);
    if (nextSampleEvent == -1)
    {
      eventInfo->upcomingTimeEvent = fmiFalse;
    }
    else
    {
      eventInfo->upcomingTimeEvent = fmiTrue;
      eventInfo->nextEventTime = nextSampleEvent;
    }
    if (comp->loggingOn)
      comp->functions.logger(c, comp->instanceName, fmiOK, "log", "fmiEventUpdate: Checked for Sample Events! Next Sample Event %g",eventInfo->nextEventTime);

    return fmiOK;

  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

  comp->functions.logger(c, comp->instanceName, fmiError, "error", "fmiEventUpdate: terminated by an assertion.");
  return fmiError;
}

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate)
{
  ModelInstance* comp = (ModelInstance *)c;
  threadData_t *threadData = comp->threadData;
  if (invalidState(comp, "fmiCompletedIntegratorStep", modelInitialized))
    return fmiError;
  if (nullPointer(comp, "fmiCompletedIntegratorStep", "callEventUpdate", callEventUpdate))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiCompletedIntegratorStep");

  /* try */
  MMC_TRY_INTERNAL(simulationJumpBuffer)

    comp->fmuData->callback->functionAlgebraics(comp->fmuData, comp->threadData);
    comp->fmuData->callback->output_function(comp->fmuData, comp->threadData);
    comp->fmuData->callback->function_storeDelayed(comp->fmuData, comp->threadData);
    storePreValues(comp->fmuData);
    *callEventUpdate  = fmiFalse;
    /******** check state selection ********/
#if !defined(OMC_NO_STATESELECTION)
    if (stateSelection(comp->fmuData, comp->threadData, 1, 0))
    {
      if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
          "fmiEventUpdate: Need to iterate state values changed!");
      /* if new set is calculated reinit the solver */
      *callEventUpdate = fmiTrue;
    }
#endif
    /* TODO: fix the extrapolation in non-linear system
     *       then we can stop to save all variables in
     *       in the whole ringbuffer
     */
    overwriteOldSimulationData(comp->fmuData);
    return fmiOK;
  /* catch */
  MMC_CATCH_INTERNAL(simulationJumpBuffer)

  comp->functions.logger(c, comp->instanceName, fmiError, "error", "fmiCompletedIntegratorStep: terminated by an assertion.");
  return fmiError;
}

fmiStatus fmiTerminate(fmiComponent c)
{
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmiTerminate", modelInitialized))
    return fmiError;
  if (comp->loggingOn) comp->functions.logger(c, comp->instanceName, fmiOK, "log",
      "fmiTerminate");

  comp->state = modelTerminated;
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

  /* free stateset data */
  deInitializeDataStruc(comp->fmuData);
  /* free simuation data */
  comp->functions.freeMemory(comp->fmuData->modelData);
  comp->functions.freeMemory(comp->fmuData->simulationInfo);

  comp->functions.freeMemory(comp->threadData);
  comp->functions.freeMemory(comp->fmuData);

  comp->state = modelTerminated;
  return fmiOK;
}

/***************************************************
Functions for FMI for Co-Simulation
****************************************************/
fmiComponent fmiInstantiateSlave(fmiString instanceName, fmiString fmuGUID, fmiString fmuLocation, fmiString mimeType, fmiReal timeout, fmiBoolean visible,
                                 fmiBoolean interactive, fmiCallbackFunctions functions, fmiBoolean loggingOn)
{
  // TODO Write code here
  return 0;
}

fmiStatus fmiInitializeSlave(fmiComponent c, fmiReal tStart, fmiBoolean StopTimeDefined, fmiReal tStop)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiTerminateSlave(fmiComponent c)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiResetSlave(fmiComponent c)
{
  // TODO Write code here
  return fmiOK;
}

void fmiFreeSlaveInstance(fmiComponent c)
{
  // TODO Write code here
}

fmiStatus fmiSetRealInputDerivatives(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger order[], const fmiReal value[])
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetRealOutputDerivatives(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger order[], fmiReal value[])
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiCancelStep(fmiComponent c)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiDoStep(fmiComponent c, fmiReal currentCommunicationPoint, fmiReal communicationStepSize, fmiBoolean newStep)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetStatus(fmiComponent c, const fmiStatusKind s, fmiStatus* value)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetRealStatus(fmiComponent c, const fmiStatusKind s, fmiReal* value)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetIntegerStatus(fmiComponent c, const fmiStatusKind s, fmiInteger* value)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetBooleanStatus(fmiComponent c, const fmiStatusKind s, fmiBoolean* value)
{
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetStringStatus(fmiComponent c, const fmiStatusKind s, fmiString* value)
{
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
}
