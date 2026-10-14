/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
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

/* The FMI 1.0 Model Exchange API of a C+Rust FMU, over the FMI 2.0 one
 * libSimulationRuntimeRust implements (src/fmi2_capi.rs). */

#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include "fmi2FunctionTypes.h"

fmi2SetDebugLoggingTYPE omc_fmi2SetDebugLogging;
fmi2InstantiateTYPE omc_fmi2Instantiate;
fmi2FreeInstanceTYPE omc_fmi2FreeInstance;
fmi2SetupExperimentTYPE omc_fmi2SetupExperiment;
fmi2EnterInitializationModeTYPE omc_fmi2EnterInitializationMode;
fmi2ExitInitializationModeTYPE omc_fmi2ExitInitializationMode;
fmi2TerminateTYPE omc_fmi2Terminate;
fmi2GetRealTYPE omc_fmi2GetReal;
fmi2GetIntegerTYPE omc_fmi2GetInteger;
fmi2GetBooleanTYPE omc_fmi2GetBoolean;
fmi2GetStringTYPE omc_fmi2GetString;
fmi2SetRealTYPE omc_fmi2SetReal;
fmi2SetIntegerTYPE omc_fmi2SetInteger;
fmi2SetBooleanTYPE omc_fmi2SetBoolean;
fmi2SetStringTYPE omc_fmi2SetString;
fmi2EnterEventModeTYPE omc_fmi2EnterEventMode;
fmi2NewDiscreteStatesTYPE omc_fmi2NewDiscreteStates;
fmi2EnterContinuousTimeModeTYPE omc_fmi2EnterContinuousTimeMode;
fmi2CompletedIntegratorStepTYPE omc_fmi2CompletedIntegratorStep;
fmi2SetTimeTYPE omc_fmi2SetTime;
fmi2SetContinuousStatesTYPE omc_fmi2SetContinuousStates;
fmi2GetDerivativesTYPE omc_fmi2GetDerivatives;
fmi2GetEventIndicatorsTYPE omc_fmi2GetEventIndicators;
fmi2GetContinuousStatesTYPE omc_fmi2GetContinuousStates;
fmi2GetNominalsOfContinuousStatesTYPE omc_fmi2GetNominalsOfContinuousStates;

typedef struct {
  fmi2Component inner;
  fmiCallbackFunctions functions;
  fmiReal time;
  /* fmiEventUpdate is inside an event iteration: FMI 2.0's Event Mode. */
  fmiBoolean inEventMode;
  fmiBoolean initialized;
} omc_fmi1_component;

/* The FMI 2.0 logger's environment is the FMI 1.0 component the importer knows. */
static void omc_fmi1_logger(fmi2ComponentEnvironment env, fmi2String instanceName, fmi2Status status,
                            fmi2String category, fmi2String message, ...)
{
  omc_fmi1_component *w = (omc_fmi1_component *) env;
  va_list ap;
  int n;
  char *buf;

  va_start(ap, message);
  n = vsnprintf(NULL, 0, message, ap);
  va_end(ap);
  if (n < 0 || !(buf = (char *) malloc((size_t) n + 1))) {
    return;
  }
  va_start(ap, message);
  vsnprintf(buf, (size_t) n + 1, message, ap);
  va_end(ap);
  w->functions.logger((fmiComponent) w, instanceName, (fmiStatus) status, category, "%s", buf);
  free(buf);
}

#define OMC_FMI1_INNER(c) (((omc_fmi1_component *) (c))->inner)

const char* fmiGetModelTypesPlatform() { return fmiModelTypesPlatform; }
const char* fmiGetVersion() { return fmiVersion; }

fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID, fmiCallbackFunctions functions, fmiBoolean loggingOn)
{
  omc_fmi1_component *w;
  fmi2CallbackFunctions cb;

  if (!functions.logger || !functions.allocateMemory || !functions.freeMemory) {
    return NULL;
  }
  w = (omc_fmi1_component *) functions.allocateMemory(1, sizeof(omc_fmi1_component));
  if (!w) {
    return NULL;
  }
  w->functions = functions;
  w->time = 0.0;
  w->inEventMode = fmiFalse;
  w->initialized = fmiFalse;
  cb.logger = omc_fmi1_logger;
  cb.allocateMemory = functions.allocateMemory;
  cb.freeMemory = functions.freeMemory;
  cb.stepFinished = NULL;
  cb.componentEnvironment = w;
  /* No resource location: the runtime finds the FMU's resources next to this binary. */
  w->inner = omc_fmi2Instantiate(instanceName, fmi2ModelExchange, GUID, NULL, &cb, fmi2False, loggingOn);
  if (!w->inner) {
    functions.freeMemory(w);
    return NULL;
  }
  return w;
}

void fmiFreeModelInstance(fmiComponent c)
{
  omc_fmi1_component *w = (omc_fmi1_component *) c;
  if (!w) {
    return;
  }
  omc_fmi2FreeInstance(w->inner);
  w->functions.freeMemory(w);
}

fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn)
{ return (fmiStatus) omc_fmi2SetDebugLogging(OMC_FMI1_INNER(c), loggingOn, 0, NULL); }

/* Before fmiInitialize FMI 1.0 sets the start time here, which FMI 2.0 takes
 * from fmi2SetupExperiment. */
fmiStatus fmiSetTime(fmiComponent c, fmiReal t)
{
  omc_fmi1_component *w = (omc_fmi1_component *) c;
  if (!w->initialized) {
    w->time = t;
    return fmiOK;
  }
  return (fmiStatus) omc_fmi2SetTime(w->inner, t);
}

fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx)
{ return (fmiStatus) omc_fmi2SetContinuousStates(OMC_FMI1_INNER(c), x, nx); }

fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate)
{
  fmi2Boolean enterEventMode = fmi2False, terminateSimulation = fmi2False;
  fmi2Status status = omc_fmi2CompletedIntegratorStep(OMC_FMI1_INNER(c), fmi2True, &enterEventMode, &terminateSimulation);
  if (callEventUpdate) {
    *callEventUpdate = enterEventMode ? fmiTrue : fmiFalse;
  }
  return (fmiStatus) status;
}

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[])
{ return (fmiStatus) omc_fmi2SetReal(OMC_FMI1_INNER(c), vr, nvr, value); }
fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[])
{ return (fmiStatus) omc_fmi2SetInteger(OMC_FMI1_INNER(c), vr, nvr, value); }
fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[])
{ return (fmiStatus) omc_fmi2SetString(OMC_FMI1_INNER(c), vr, nvr, value); }

/* fmiBoolean is a char, fmi2Boolean an int. */
fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[])
{
  fmi2Boolean *v = (fmi2Boolean *) malloc((nvr ? nvr : 1) * sizeof(fmi2Boolean));
  fmi2Status status;
  size_t i;
  if (!v) {
    return fmiError;
  }
  for (i = 0; i < nvr; i++) {
    v[i] = value[i] ? fmi2True : fmi2False;
  }
  status = omc_fmi2SetBoolean(OMC_FMI1_INNER(c), vr, nvr, v);
  free(v);
  return (fmiStatus) status;
}

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[])
{ return (fmiStatus) omc_fmi2GetReal(OMC_FMI1_INNER(c), vr, nvr, value); }
fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[])
{ return (fmiStatus) omc_fmi2GetInteger(OMC_FMI1_INNER(c), vr, nvr, value); }
fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString value[])
{ return (fmiStatus) omc_fmi2GetString(OMC_FMI1_INNER(c), vr, nvr, value); }

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[])
{
  fmi2Boolean *v = (fmi2Boolean *) malloc((nvr ? nvr : 1) * sizeof(fmi2Boolean));
  fmi2Status status;
  size_t i;
  if (!v) {
    return fmiError;
  }
  status = omc_fmi2GetBoolean(OMC_FMI1_INNER(c), vr, nvr, v);
  for (i = 0; i < nvr; i++) {
    value[i] = v[i] ? fmiTrue : fmiFalse;
  }
  free(v);
  return (fmiStatus) status;
}

fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx)
{
#if NUMBER_OF_STATES > 0
  static const fmiValueReference states[NUMBER_OF_STATES] = STATES;
  size_t i;
  if (nx != NUMBER_OF_STATES || !vrx) {
    return fmiError;
  }
  for (i = 0; i < nx; i++) {
    vrx[i] = states[i];
  }
#else
  (void) vrx;
  if (nx != 0) {
    return fmiError;
  }
#endif
  (void) c;
  return fmiOK;
}

fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx)
{ return (fmiStatus) omc_fmi2GetContinuousStates(OMC_FMI1_INNER(c), states, nx); }
fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx)
{ return (fmiStatus) omc_fmi2GetNominalsOfContinuousStates(OMC_FMI1_INNER(c), x_nominal, nx); }
fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx)
{ return (fmiStatus) omc_fmi2GetDerivatives(OMC_FMI1_INNER(c), derivatives, nx); }
fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni)
{ return (fmiStatus) omc_fmi2GetEventIndicators(OMC_FMI1_INNER(c), eventIndicators, ni); }

/* FMI 2.0's event iteration in Event Mode, reported as FMI 1.0's eventInfo. A
 * converged iteration leaves Event Mode; `intermediateResults` stops after one
 * pass, and the next fmiEventUpdate carries on from there. */
static fmiStatus omc_fmi1_iterate(omc_fmi1_component *w, fmiBoolean intermediateResults, fmiEventInfo* eventInfo)
{
  fmi2EventInfo e2;
  fmi2Status status;

  eventInfo->iterationConverged = fmiFalse;
  eventInfo->stateValueReferencesChanged = fmiFalse;
  eventInfo->stateValuesChanged = fmiFalse;
  eventInfo->terminateSimulation = fmiFalse;
  eventInfo->upcomingTimeEvent = fmiFalse;
  eventInfo->nextEventTime = 0.0;
  do {
    status = omc_fmi2NewDiscreteStates(w->inner, &e2);
    if (status > fmi2Warning) {
      return (fmiStatus) status;
    }
    if (e2.valuesOfContinuousStatesChanged) {
      eventInfo->stateValuesChanged = fmiTrue;
    }
    if (e2.terminateSimulation) {
      eventInfo->terminateSimulation = fmiTrue;
      return (fmiStatus) status;
    }
  } while (e2.newDiscreteStatesNeeded && !intermediateResults);
  eventInfo->upcomingTimeEvent = e2.nextEventTimeDefined ? fmiTrue : fmiFalse;
  eventInfo->nextEventTime = e2.nextEventTime;
  if (e2.newDiscreteStatesNeeded) {
    return (fmiStatus) status;
  }
  eventInfo->iterationConverged = fmiTrue;
  w->inEventMode = fmiFalse;
  return (fmiStatus) omc_fmi2EnterContinuousTimeMode(w->inner);
}

fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance, fmiEventInfo* eventInfo)
{
  omc_fmi1_component *w = (omc_fmi1_component *) c;
  fmi2Status status;

  if (!eventInfo) {
    return fmiError;
  }
  status = omc_fmi2SetupExperiment(w->inner, toleranceControlled, relativeTolerance, w->time, fmi2False, 0.0);
  if (status <= fmi2Warning) {
    status = omc_fmi2EnterInitializationMode(w->inner);
  }
  if (status <= fmi2Warning) {
    status = omc_fmi2ExitInitializationMode(w->inner);
  }
  if (status > fmi2Warning) {
    return (fmiStatus) status;
  }
  w->inEventMode = fmiTrue;
  w->initialized = fmiTrue;
  return omc_fmi1_iterate(w, fmiFalse, eventInfo);
}

fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo)
{
  omc_fmi1_component *w = (omc_fmi1_component *) c;

  if (!eventInfo) {
    return fmiError;
  }
  if (!w->inEventMode) {
    fmi2Status status = omc_fmi2EnterEventMode(w->inner);
    if (status > fmi2Warning) {
      return (fmiStatus) status;
    }
    w->inEventMode = fmiTrue;
  }
  return omc_fmi1_iterate(w, intermediateResults, eventInfo);
}

fmiStatus fmiTerminate(fmiComponent c)
{ return (fmiStatus) omc_fmi2Terminate(OMC_FMI1_INNER(c)); }
