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
 * FMI 3.0 model interface for OpenModelica generated FMUs: the FMI 3.0 C API
 * on top of the model interface that it shares with FMI 2.0
 * (fmu_model_interface.c.inc).
 */

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <stdlib.h>
#include <math.h>
#include "fmu3_model_interface.h"
#include "../simulation/arrayIndex.h"
#include "../simulation/solver/initialization/initialization.h"
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
#ifdef OMC_FMI_HAVE_CVODE
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
#include "../simulation/solver/spatialDistribution.h"
#include "../simulation/solver/discrete_changes.h"
#include "../simulation/solver/events.h"
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

#define OMC_FMI_VERSION 3
typedef fmi3Status fmiXStatus;
typedef ModelInstance* fmiXComponent;
typedef fmi3Float64 fmiXReal;
typedef fmi3Int32 fmiXInteger;
typedef fmi3Boolean fmiXBoolean;
typedef fmi3String fmiXString;
typedef fmi3Byte fmiXByte;
typedef fmi3ValueReference fmiXValueReference;
typedef fmi3FMUState fmiXFMUstate;
typedef EventInfo fmiXEventInfo;
#define fmiXOK fmi3OK
#define fmiXWarning fmi3Warning
#define fmiXDiscard fmi3Discard
#define fmiXError fmi3Error
#define fmiXFatal fmi3Fatal
#define fmiXTrue fmi3True
#define fmiXFalse fmi3False
#define FMIX(name) omc##name
#define FMIX_STR "fmi3"
#define FMIX_ME OMC_ME
#define FMIX_CS OMC_CS
#define FMIX_LOG(comp, status, categoryIndex, message, ...) omc_fmi3_logMessage(comp, status, categoryIndex, message, ##__VA_ARGS__)
#define LOG_FMIX_CALL LOG_FMI3_CALL
#define FMIX_SETUP_DATA_STRUC fmu3_model_interface_setupDataStruc

#include "fmu_model_interface.c.inc"

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

/* Scheduled Execution runs on the Model Exchange code path: after initialization
   its instance stays in model_state_me_event_mode, which there stands for Clock
   Activation Mode. Sets the error state and returns true for a call that only
   Model Exchange or Co-Simulation may make. */
static fmiXBoolean fmu3InScheduledExecution(fmi3Instance instance, const char *func)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  if (!inst || inst->interfaceType != FMI3_INTERFACE_SE) return fmiXFalse;
  FILTERED_LOG(inst->comp, fmi3Error, LOG_STATUSERROR, "%s: Illegal call sequence. %s is not allowed in Scheduled Execution.", func, func)
  inst->comp->state = model_state_error;
  return fmiXTrue;
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
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  fmi3Status status = (fmi3Status)omcExitInitializationMode(fmu3InnerComp(instance));
  if (inst && inst->eventModeUsed && inst->comp->state == model_state_cs_step_complete) {
    inst->comp->state = model_state_cs_event_mode;
  }
  return status;
}

fmi3Status fmi3EnterEventMode(fmi3Instance instance)
{
  ModelInstance3 *inst = (ModelInstance3 *)instance;
  ModelInstance *comp = fmu3InnerComp(instance);
  if (!inst || !comp) return fmi3Error;
  if (fmu3InScheduledExecution(instance, "fmi3EnterEventMode")) return fmi3Error;
  /* Only from Step Mode, and only for an importer that said it uses Event Mode. */
  if (invalidState(comp, "fmi3EnterEventMode", model_state_me_continuous_time_mode,
      inst->eventModeUsed ? model_state_cs_step_complete : 0))
    return fmi3Error;
  if (inst->interfaceType == FMI3_INTERFACE_CS) {
    comp->state = model_state_cs_event_mode;
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
#ifndef FMI3_NUMBER_OF_ARRAYS
#define FMI3_NUMBER_OF_ARRAYS 0
#endif

/* The values a value reference stands for: an array variable's element count
 * (FMI3_ARRAY_VRS / FMI3_ARRAY_LENGTHS, sorted by value reference), else 1. */
static size_t fmi3ArrayLength(fmi3ValueReference vr)
{
#if FMI3_NUMBER_OF_ARRAYS > 0
  static const fmi3ValueReference vrs[FMI3_NUMBER_OF_ARRAYS] = FMI3_ARRAY_VRS;
  static const size_t lens[FMI3_NUMBER_OF_ARRAYS] = FMI3_ARRAY_LENGTHS;
  size_t lo = 0, hi = FMI3_NUMBER_OF_ARRAYS;
  while (lo < hi) {
    size_t mid = lo + (hi - lo) / 2;
    if (vrs[mid] < vr) lo = mid + 1; else hi = mid;
  }
  if (lo < FMI3_NUMBER_OF_ARRAYS && vrs[lo] == vr) return lens[lo];
#else
  (void)vr;
#endif
  return 1;
}

static size_t fmi3NumValues(const fmi3ValueReference valueReferences[], size_t nValueReferences)
{
  size_t i, n = 0;
  for (i = 0; i < nValueReferences; i++) n += fmi3ArrayLength(valueReferences[i]);
  return n;
}

/* invalidState for fmi3Set{VariableType}. Configuration Mode takes structural
 * parameters only, and an FMU from this runtime has none, so any variable there
 * is refused while a call with none is legal. */
static int fmu3InvalidSet(ModelInstance *comp, const char *func, int meStates, int csStates, size_t nValueReferences)
{
  if (comp->state == model_state_configuration_mode && nValueReferences == 0) return 0;
  return invalidState(comp, func, meStates, csStates);
}

fmi3Status fmi3GetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 values[], size_t nValues)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  size_t i, j, k = 0;
  if (!comp) {
    return fmi3Error;
  }
  if (invalidState(comp, "fmi3GetFloat64", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference vr = valueReferences[i];
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
    for (j = 0; j < cnt; j++, k++) {
      fmi3ValueReference evr = vr + (fmi3ValueReference)j;
      if (evr == (fmi3ValueReference)FMI3_TIME_VR) {
        values[k] = (fmi3Float64)comp->fmuData->localData[0]->timeValue;
      } else if (evr >= (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START) {
#if NUMBER_OF_EVENT_INDICATORS > 0
        /* Not omcGetEventIndicators, which is Model Exchange only: these are
           ordinary variables here, whatever the interface. */
        fmi3Float64 ei[NUMBER_OF_EVENT_INDICATORS];
        fmi3Status s;
        if (evr - (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START >= NUMBER_OF_EVENT_INDICATORS) return fmi3Error;
        s = internalGetEventIndicators((ModelInstance*)comp, "fmi3GetFloat64", ei, NUMBER_OF_EVENT_INDICATORS);
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
  if (invalidState(c, "fmi3GetInt32", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (invalidState(c, "fmi3GetBoolean", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (invalidState(c, "fmi3GetString", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (fmu3InvalidSet(c, "fmi3SetFloat64", SET_REAL_ME_STATES, SET_REAL_CS_STATES, nValueReferences)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    fmi3ValueReference vr = valueReferences[i];
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (fmu3InvalidSet(c, "fmi3SetInt32", SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES, nValueReferences)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (fmu3InvalidSet(c, "fmi3SetBoolean", SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES, nValueReferences)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (fmu3InvalidSet(c, "fmi3SetString", SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES, nValueReferences)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  ModelInstance* c = fmu3InnerComp(instance);                                                  \
  (void)valueReferences; (void)values; (void)nValues;                                          \
  if (!c) return fmi3Error;                                                                    \
  if (invalidState(c, #NAME, GET_ME_STATES, GET_CS_STATES)) return fmi3Error;                  \
  return nValueReferences == 0 ? fmi3OK : fmi3Error;                                           \
}
#define FMU3_UNSUPPORTED_SET(NAME, CTYPE, ME_STATES, CS_STATES)                                \
fmi3Status NAME(fmi3Instance instance, const fmi3ValueReference valueReferences[],             \
    size_t nValueReferences, const CTYPE values[], size_t nValues) {                           \
  ModelInstance* c = fmu3InnerComp(instance);                                                  \
  (void)valueReferences; (void)values; (void)nValues;                                          \
  if (!c) return fmi3Error;                                                                    \
  if (fmu3InvalidSet(c, #NAME, ME_STATES, CS_STATES, nValueReferences)) return fmi3Error;      \
  return nValueReferences == 0 ? fmi3OK : fmi3Error;                                           \
}

FMU3_UNSUPPORTED_GETSET(fmi3GetFloat32, fmi3Float32)
FMU3_UNSUPPORTED_GETSET(fmi3GetInt8,   fmi3Int8)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt8,  fmi3UInt8)
FMU3_UNSUPPORTED_GETSET(fmi3GetInt16,  fmi3Int16)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt16, fmi3UInt16)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt32, fmi3UInt32)
FMU3_UNSUPPORTED_GETSET(fmi3GetUInt64, fmi3UInt64)
FMU3_UNSUPPORTED_SET(fmi3SetFloat32, fmi3Float32, SET_REAL_ME_STATES, SET_REAL_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetInt8,   fmi3Int8,   SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetUInt8,  fmi3UInt8,  SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetInt16,  fmi3Int16,  SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetUInt16, fmi3UInt16, SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetUInt32, fmi3UInt32, SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)
FMU3_UNSUPPORTED_SET(fmi3SetUInt64, fmi3UInt64, SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES)

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
  if (invalidState(c, "fmi3GetInt64", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (fmu3InvalidSet(c, "fmi3SetInt64", SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES, nValueReferences)) return fmi3Error;
  if (fmi3NumValues(valueReferences, nValueReferences) != nValues) return fmi3Error;
  for (i = 0; i < nValueReferences; i++) {
    size_t cnt = fmi3ArrayLength(valueReferences[i]);
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
  if (invalidState(c, "fmi3GetBinary", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
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
  if (fmu3InvalidSet(c, "fmi3SetBinary", SET_DISCRETE_ME_STATES, SET_DISCRETE_CS_STATES, nValueReferences)) return fmi3Error;
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
  /* Scheduled Execution reads Clocks in Clock Update Mode, which this FMU never enters. */
  if (fmu3InScheduledExecution(instance, "fmi3GetClock")) return fmi3Error;
  if (invalidState(c, "fmi3GetClock", model_state_me_event_mode, model_state_cs_event_mode)) return fmi3Error;
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
  (void)valueReferences; (void)values;
  if (fmu3InScheduledExecution(instance, "fmi3SetClock")) return fmi3Error;
  if (invalidState(fmu3InnerComp(instance), "fmi3SetClock", model_state_me_event_mode, model_state_cs_event_mode)) return fmi3Error;
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
  if (invalidState(c, "fmi3GetDirectionalDerivative", GET_ME_STATES, GET_CS_STATES)) return fmi3Error;
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
  ModelInstance* c = fmu3InnerComp(instance);
  (void)unknowns; (void)nUnknowns; (void)knowns; (void)nKnowns;
  (void)seed; (void)nSeed; (void)sensitivity; (void)nSensitivity;
  if (c) invalidState(c, "fmi3GetAdjointDerivative", GET_ME_STATES, GET_CS_STATES);
  return fmi3Error;
}

/* ---------------------------------------------------------------------------
 * Configuration Mode. Every structural parameter of an exported FMU is `fixed`,
 * so it is only open from Instantiated: there is no Reconfiguration Mode, which
 * a `tunable` one would need, from Event Mode or Step Mode. FMI 3.0 forbids
 * entering it on an FMU without a structural parameter, and an FMU of this
 * runtime declares none (FMI3_HAS_STRUCTURAL_PARAMETERS).
 * ------------------------------------------------------------------------- */
#ifndef FMI3_HAS_STRUCTURAL_PARAMETERS
#define FMI3_HAS_STRUCTURAL_PARAMETERS 0
#endif

fmi3Status fmi3EnterConfigurationMode(fmi3Instance instance)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  if (!comp) return fmi3Error;
  if (!FMI3_HAS_STRUCTURAL_PARAMETERS) {
    FILTERED_LOG(comp, fmi3Error, LOG_STATUSERROR, "fmi3EnterConfigurationMode: Illegal call sequence. fmi3EnterConfigurationMode is not allowed for an FMU without a structural parameter.")
    comp->state = model_state_error;
    return fmi3Error;
  }
  if (invalidState(comp, "fmi3EnterConfigurationMode", model_state_instantiated, model_state_instantiated))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "fmi3EnterConfigurationMode")
  comp->state = model_state_configuration_mode;
  return fmi3OK;
}

fmi3Status fmi3ExitConfigurationMode(fmi3Instance instance)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  if (invalidState(comp, "fmi3ExitConfigurationMode", model_state_configuration_mode, model_state_configuration_mode))
    return fmi3Error;
  FILTERED_LOG(comp, fmi3OK, LOG_FMI3_CALL, "fmi3ExitConfigurationMode")
  comp->state = model_state_instantiated;
  return fmi3OK;
}

/* ---------------------------------------------------------------------------
 * Clock related functions (no clocks exposed yet)
 * ------------------------------------------------------------------------- */
fmi3Status fmi3GetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 intervals[], fmi3IntervalQualifier qualifiers[])
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  if (!c) return fmi3Error;
  if (invalidState(c, "fmi3GetIntervalDecimal", model_state_initialization_mode|model_state_me_event_mode, model_state_initialization_mode|model_state_cs_event_mode)) return fmi3Error;
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
  if (invalidState(c, "fmi3GetIntervalFraction", model_state_initialization_mode|model_state_me_event_mode, model_state_initialization_mode|model_state_cs_event_mode)) return fmi3Error;
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
{
  (void)valueReferences; (void)shifts;
  if (invalidState(fmu3InnerComp(instance), "fmi3GetShiftDecimal", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3GetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[])
{
  (void)valueReferences; (void)counters; (void)resolutions;
  if (invalidState(fmu3InnerComp(instance), "fmi3GetShiftFraction", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3SetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 intervals[])
{
  (void)valueReferences; (void)intervals;
  if (invalidState(fmu3InnerComp(instance), "fmi3SetIntervalDecimal", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3SetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{
  (void)valueReferences; (void)counters; (void)resolutions;
  if (invalidState(fmu3InnerComp(instance), "fmi3SetIntervalFraction", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3SetShiftDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 shifts[])
{
  (void)valueReferences; (void)shifts;
  if (invalidState(fmu3InnerComp(instance), "fmi3SetShiftDecimal", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3SetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{
  (void)valueReferences; (void)counters; (void)resolutions;
  if (invalidState(fmu3InnerComp(instance), "fmi3SetShiftFraction", model_state_initialization_mode, model_state_initialization_mode)) return fmi3Error;
  return nValueReferences == 0 ? fmi3OK : fmi3Error;
}

fmi3Status fmi3EvaluateDiscreteStates(fmi3Instance instance)
{
  ModelInstance *comp = fmu3InnerComp(instance);
  if (!comp) return fmi3Error;
  if (fmu3InScheduledExecution(instance, "fmi3EvaluateDiscreteStates")) return fmi3Error;
  if (invalidState(comp, "fmi3EvaluateDiscreteStates", model_state_me_event_mode, model_state_cs_event_mode)) return fmi3Error;
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
  if (fmu3InScheduledExecution(instance, "fmi3UpdateDiscreteStates")) return fmi3Error;
  if (invalidState(c, "fmi3UpdateDiscreteStates", model_state_me_event_mode, model_state_cs_event_mode)) return fmi3Error;
  memset(&eventInfo, 0, sizeof(eventInfo));
  if (inst->interfaceType == FMI3_INTERFACE_CS) {
    /* Co-Simulation Event Mode: run one event-update iteration directly, since
       omcNewDiscreteStates is Model Exchange only. Carry over any pending next
       event time so time events keep being scheduled. */
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
  if (fmu3InScheduledExecution(instance, "fmi3EnterContinuousTimeMode")) return fmi3Error;
  return (fmi3Status)omcEnterContinuousTimeMode(fmu3InnerComp(instance));
}

fmi3Status fmi3CompletedIntegratorStep(fmi3Instance instance, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{
  ModelInstance* c = fmu3InnerComp(instance);
  fmi3Boolean enterEventMode2 = fmi3False;
  fmi3Boolean terminate2 = fmi3False;
  fmi3Status status;
  if (fmu3InScheduledExecution(instance, "fmi3CompletedIntegratorStep")) return fmi3Error;
  status = omcCompletedIntegratorStep(c, noSetFMUStatePriorToCurrentPoint, &enterEventMode2, &terminate2);
  if (enterEventMode)      *enterEventMode = enterEventMode2 ? fmi3True : fmi3False;
  if (terminateSimulation) *terminateSimulation = terminate2 ? fmi3True : fmi3False;
  return (fmi3Status)status;
}

fmi3Status fmi3SetTime(fmi3Instance instance, fmi3Float64 time)
{
  if (fmu3InScheduledExecution(instance, "fmi3SetTime")) return fmi3Error;
  return (fmi3Status)omcSetTime(fmu3InnerComp(instance), (fmi3Float64)time);
}

fmi3Status fmi3SetContinuousStates(fmi3Instance instance, const fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  if (fmu3InScheduledExecution(instance, "fmi3SetContinuousStates")) return fmi3Error;
  return (fmi3Status)omcSetContinuousStates(fmu3InnerComp(instance), (const fmi3Float64*)continuousStates, nContinuousStates);
}

fmi3Status fmi3GetContinuousStateDerivatives(fmi3Instance instance, fmi3Float64 derivatives[], size_t nContinuousStates)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetContinuousStateDerivatives")) return fmi3Error;
  return (fmi3Status)omcGetDerivatives(fmu3InnerComp(instance), (fmi3Float64*)derivatives, nContinuousStates);
}

fmi3Status fmi3GetEventIndicators(fmi3Instance instance, fmi3Float64 eventIndicators[], size_t nEventIndicators)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetEventIndicators")) return fmi3Error;
  return (fmi3Status)omcGetEventIndicators(fmu3InnerComp(instance), (fmi3Float64*)eventIndicators, nEventIndicators);
}

fmi3Status fmi3GetContinuousStates(fmi3Instance instance, fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetContinuousStates")) return fmi3Error;
  return (fmi3Status)omcGetContinuousStates(fmu3InnerComp(instance), (fmi3Float64*)continuousStates, nContinuousStates);
}

fmi3Status fmi3GetNominalsOfContinuousStates(fmi3Instance instance, fmi3Float64 nominals[], size_t nContinuousStates)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetNominalsOfContinuousStates")) return fmi3Error;
  return (fmi3Status)omcGetNominalsOfContinuousStates(fmu3InnerComp(instance), (fmi3Float64*)nominals, nContinuousStates);
}

fmi3Status fmi3GetNumberOfEventIndicators(fmi3Instance instance, size_t* nEventIndicators)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetNumberOfEventIndicators")) return fmi3Error;
  if (invalidState(fmu3InnerComp(instance), "fmi3GetNumberOfEventIndicators", model_state_instantiated|model_state_me_event_mode, 0)) return fmi3Error;
  if (!nEventIndicators) return fmi3Error;
  *nEventIndicators = (size_t)NUMBER_OF_EVENT_INDICATORS;
  return fmi3OK;
}

fmi3Status fmi3GetNumberOfContinuousStates(fmi3Instance instance, size_t* nContinuousStates)
{
  if (fmu3InScheduledExecution(instance, "fmi3GetNumberOfContinuousStates")) return fmi3Error;
  if (invalidState(fmu3InnerComp(instance), "fmi3GetNumberOfContinuousStates", model_state_instantiated|model_state_me_event_mode, 0)) return fmi3Error;
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
  if (invalidState(comp, "fmi3EnterStepMode", 0, model_state_cs_event_mode)) return fmi3Error;
  comp->state = model_state_cs_step_complete;
  /* Inputs and states can change discontinuously in Event Mode (FMI 3.0 4.1.1),
     so the solver restarts. */
  if (comp->solverInfo) {
    comp->solverInfo->didEventStep = 1;
  }
  return fmi3OK;
}

fmi3Status fmi3GetOutputDerivatives(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int32 orders[], fmi3Float64 values[], size_t nValues)
{
  ModelInstance* c = fmu3InnerComp(instance);
  size_t i;
  (void)nValues;
  if (!c) return fmi3Error;
  if (invalidState(c, "fmi3GetOutputDerivatives", 0, GET_OUTPUT_DERIVATIVES_CS_STATES)) return fmi3Error;
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
  status = doStepInternal(c, (fmi3Float64)currentCommunicationPoint,
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
  /* Clock Activation Mode, see fmu3InScheduledExecution. */
  if (invalidState(comp, "fmi3ActivateModelPartition",
      ((ModelInstance3 *)instance)->interfaceType == FMI3_INTERFACE_SE ? model_state_me_event_mode : 0, 0))
    return fmi3Error;

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
  /* try */
  OMC_TRY_INTERNAL(simulationJumpBuffer)

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
  OMC_CATCH_INTERNAL(simulationJumpBuffer)
  if (OMC_ERROR_RAISED()) { OMC_ERROR_CLEAR(); done = 0; }
  threadData->mmc_jumper = old_jmp;

  if (done) {
    /* FMI 3.0, 5.2: after fmi3Discard the importer starts no new model partition. */
    if (comp->_terminate_simulation_requested) {
      comp->_terminate_simulation_requested = 0;
      FILTERED_LOG(comp, fmi3Discard, LOG_EVENTS, "fmi3ActivateModelPartition: terminate simulation requested by the model.")
      return fmi3Discard;
    }
    return fmi3OK;
  }
  FILTERED_LOG(comp, fmi3Error, LOG_FMI3_CALL, "fmi3ActivateModelPartition: terminated by an assertion.")
  return fmi3Error;
}
