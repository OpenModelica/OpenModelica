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

/** @addtogroup fmu3
 *
 *  @{
 */

/*
 * Implement the FMI 3.0 calling interface for the Cpp runtime as a thin layer
 * on top of FMU3Wrapper (compiled alongside this file). Only the
 * Model Exchange interface is functional, mirroring the Cpp FMI 2.0 export
 * (Co-Simulation requests are downgraded to Model Exchange by the scripting
 * front-end); the Co-Simulation and Scheduled Execution entry points are still
 * exported (so importers that resolve all symbols can load the FMU) but return
 * fmi3Error.
 *
 * FMI 3.0 requires globally unique value references whereas the Cpp runtime
 * assigns per-base-type value references. The generated OMCpp<model>FMU.cpp
 * defines the FMI3_*_VR_OFFSET macros (matching SimCodeUtil.getFMI3TypeOffset)
 * before including this file; here we subtract the offset again to recover the
 * per-type value reference understood by FMU3Wrapper.
 */

#include "FMU3Wrapper.h"
#include "fmi3Functions.h"

#include <cstdarg>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <exception>

#ifndef FMI3_CPP_LOG_BUFFER_SIZE
#define FMI3_CPP_LOG_BUFFER_SIZE 2048
#endif

/* Wrapper around the FMI 3.0 FMU3Wrapper, carrying the FMI 3.0 callback. */
typedef struct {
  FMU3Wrapper *wrapper;
  fmi3LogMessageCallback logMessage;
  fmi3InstanceEnvironment instanceEnvironment;
  fmi3Float64 time;
  int interfaceType; /* 0 = ME, 1 = CS, 2 = SE */
} FMU3CppInstance;

#define FMI3_INTERFACE_ME 0
#define FMI3_INTERFACE_CS 1
#define FMI3_INTERFACE_SE 2

#define FMU3_W(instance) (reinterpret_cast<FMU3CppInstance*>(instance))

#define FMU3_CATCH(inst) \
  catch (std::exception &e) { \
    if ((inst) != NULL && (inst)->logMessage != NULL) \
      (inst)->logMessage((inst)->instanceEnvironment, fmi3Error, "logStatusError", e.what()); \
    return fmi3Error; \
  }

static fmi3Instance fmu3CppInstantiate(int interfaceType, fmi3String instanceName,
    fmi3String instantiationToken, fmi3Boolean loggingOn,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage)
{
  FMU3CppInstance *inst = reinterpret_cast<FMU3CppInstance*>(calloc(1, sizeof(FMU3CppInstance)));
  if (inst == NULL) {
    if (logMessage != NULL)
      logMessage(instanceEnvironment, fmi3Fatal, "logStatusFatal", "fmi3Instantiate: out of memory.");
    return NULL;
  }
  inst->logMessage = logMessage;
  inst->instanceEnvironment = instanceEnvironment;
  inst->time = 0.0;
  inst->interfaceType = interfaceType;

  try {
    inst->wrapper = new FMU3Wrapper(instanceName, instantiationToken,
                                    instanceEnvironment, logMessage, loggingOn);
  }
  catch (std::exception &e) {
    if (logMessage != NULL)
      logMessage(instanceEnvironment, fmi3Error, "logStatusError", e.what());
    free(inst);
    return NULL;
  }
  return reinterpret_cast<fmi3Instance>(inst);
}

extern "C"
{

// ---------------------------------------------------------------------------
// Inquire version and set debug logging
// ---------------------------------------------------------------------------
const char* fmi3GetVersion(void)
{
  return fmi3Version;
}

fmi3Status fmi3SetDebugLogging(fmi3Instance instance, fmi3Boolean loggingOn,
    size_t nCategories, const fmi3String categories[])
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try {
    return (fmi3Status)inst->wrapper->setDebugLogging(loggingOn ? fmi3True : fmi3False,
                                                      nCategories, categories);
  } FMU3_CATCH(inst)
}

// ---------------------------------------------------------------------------
// Creation and destruction of FMU instances
// ---------------------------------------------------------------------------
fmi3Instance fmi3InstantiateModelExchange(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage)
{
  (void)resourcePath; (void)visible;
  return fmu3CppInstantiate(FMI3_INTERFACE_ME, instanceName, instantiationToken,
                            loggingOn, instanceEnvironment, logMessage);
}

fmi3Instance fmi3InstantiateCoSimulation(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn, fmi3Boolean eventModeUsed,
    fmi3Boolean earlyReturnAllowed, const fmi3ValueReference requiredIntermediateVariables[],
    size_t nRequiredIntermediateVariables, fmi3InstanceEnvironment instanceEnvironment,
    fmi3LogMessageCallback logMessage, fmi3IntermediateUpdateCallback intermediateUpdate)
{
  (void)resourcePath; (void)visible; (void)eventModeUsed; (void)earlyReturnAllowed;
  (void)requiredIntermediateVariables; (void)nRequiredIntermediateVariables; (void)intermediateUpdate;
  return fmu3CppInstantiate(FMI3_INTERFACE_CS, instanceName, instantiationToken,
                            loggingOn, instanceEnvironment, logMessage);
}

fmi3Instance fmi3InstantiateScheduledExecution(fmi3String instanceName, fmi3String instantiationToken,
    fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn,
    fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage,
    fmi3ClockUpdateCallback clockUpdate, fmi3LockPreemptionCallback lockPreemption,
    fmi3UnlockPreemptionCallback unlockPreemption)
{
  (void)resourcePath; (void)visible; (void)clockUpdate; (void)lockPreemption; (void)unlockPreemption;
  return fmu3CppInstantiate(FMI3_INTERFACE_SE, instanceName, instantiationToken,
                            loggingOn, instanceEnvironment, logMessage);
}

void fmi3FreeInstance(fmi3Instance instance)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (inst == NULL)
    return;
  if (inst->wrapper != NULL)
    delete inst->wrapper;
  free(inst);
}

// ---------------------------------------------------------------------------
// Enter and exit initialization mode, terminate and reset
// ---------------------------------------------------------------------------
fmi3Status fmi3EnterInitializationMode(fmi3Instance instance, fmi3Boolean toleranceDefined,
    fmi3Float64 tolerance, fmi3Float64 startTime, fmi3Boolean stopTimeDefined, fmi3Float64 stopTime)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  inst->time = startTime;
  try {
    fmi3Status s = inst->wrapper->setupExperiment(toleranceDefined ? fmi3True : fmi3False,
        tolerance, startTime, stopTimeDefined ? fmi3True : fmi3False, stopTime);
    if (s > fmi3Warning)
      return (fmi3Status)s;
    return (fmi3Status)inst->wrapper->enterInitializationMode();
  } FMU3_CATCH(inst)
}

fmi3Status fmi3ExitInitializationMode(fmi3Instance instance)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->exitInitializationMode(); } FMU3_CATCH(inst)
}

fmi3Status fmi3EnterEventMode(fmi3Instance instance)
{
  (void)instance;
  return fmi3OK;
}

fmi3Status fmi3Terminate(fmi3Instance instance)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->terminate(); } FMU3_CATCH(inst)
}

fmi3Status fmi3Reset(fmi3Instance instance)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->reset(); } FMU3_CATCH(inst)
}

// ---------------------------------------------------------------------------
// Getting and setting variable values (per-base-type value references with the
// FMI3_*_VR_OFFSET shift applied)
// ---------------------------------------------------------------------------
fmi3Status fmi3GetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      fmi3ValueReference vr = valueReferences[i];
      if (vr == (fmi3ValueReference)FMI3_TIME_VR) {
        values[i] = inst->time;
      } else if (vr >= (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START) {
#if NUMBER_OF_EVENT_INDICATORS > 0
        double ei[NUMBER_OF_EVENT_INDICATORS];
        fmi3Status s = inst->wrapper->getEventIndicators(ei, NUMBER_OF_EVENT_INDICATORS);
        if (s > fmi3Warning) return (fmi3Status)s;
        values[i] = ei[vr - (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START];
#else
        return fmi3Error;
#endif
      } else {
        unsigned int lvr = (unsigned int)(vr - FMI3_REAL_VR_OFFSET);
        double v;
        fmi3Status s = inst->wrapper->getReal(&lvr, 1, &v);
        if (s > fmi3Warning) return (fmi3Status)s;
        values[i] = v;
      }
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3GetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Int32 values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_INTEGER_VR_OFFSET);
      int v;
      fmi3Status s = inst->wrapper->getInteger(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[i] = (fmi3Int32)v;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3GetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Boolean values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_BOOLEAN_VR_OFFSET);
      int v;
      fmi3Status s = inst->wrapper->getBoolean(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[i] = v ? fmi3True : fmi3False;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3GetString(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3String values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_STRING_VR_OFFSET);
      fmi3String v;
      fmi3Status s = inst->wrapper->getString(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
      values[i] = (fmi3String)v;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Float64 values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      fmi3ValueReference vr = valueReferences[i];
      if (vr == (fmi3ValueReference)FMI3_TIME_VR || vr >= (fmi3ValueReference)FMI3_EVENT_INDICATOR_VR_START)
        continue; /* time and event indicators are not settable */
      unsigned int lvr = (unsigned int)(vr - FMI3_REAL_VR_OFFSET);
      double v = values[i];
      fmi3Status s = inst->wrapper->setReal(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int32 values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_INTEGER_VR_OFFSET);
      int v = (int)values[i];
      fmi3Status s = inst->wrapper->setInteger(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Boolean values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_BOOLEAN_VR_OFFSET);
      int v = values[i] ? 1 : 0;
      fmi3Status s = inst->wrapper->setBoolean(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetString(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3String values[], size_t nValues)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  (void)nValues;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      unsigned int lvr = (unsigned int)(valueReferences[i] - FMI3_STRING_VR_OFFSET);
      fmi3String v = (fmi3String)values[i];
      fmi3Status s = inst->wrapper->setString(&lvr, 1, &v);
      if (s > fmi3Warning) return (fmi3Status)s;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

/* Base types that OpenModelica does not generate (Float32, the smaller/unsigned
 * integer types, Binary, Clock). A well-formed importer never calls them for an
 * OpenModelica FMU, so they only need to succeed for the empty case. */
#define FMU3_CPP_UNSUPPORTED_GET(NAME, CTYPE) \
fmi3Status NAME(fmi3Instance instance, const fmi3ValueReference valueReferences[], \
    size_t nValueReferences, CTYPE values[], size_t nValues) { \
  (void)instance; (void)valueReferences; (void)values; (void)nValues; \
  return nValueReferences == 0 ? fmi3OK : fmi3Error; }
#define FMU3_CPP_UNSUPPORTED_SET(NAME, CTYPE) \
fmi3Status NAME(fmi3Instance instance, const fmi3ValueReference valueReferences[], \
    size_t nValueReferences, const CTYPE values[], size_t nValues) { \
  (void)instance; (void)valueReferences; (void)values; (void)nValues; \
  return nValueReferences == 0 ? fmi3OK : fmi3Error; }

FMU3_CPP_UNSUPPORTED_GET(fmi3GetFloat32, fmi3Float32)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetInt8,   fmi3Int8)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetUInt8,  fmi3UInt8)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetInt16,  fmi3Int16)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetUInt16, fmi3UInt16)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetUInt32, fmi3UInt32)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetInt64,  fmi3Int64)
FMU3_CPP_UNSUPPORTED_GET(fmi3GetUInt64, fmi3UInt64)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetFloat32, fmi3Float32)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetInt8,   fmi3Int8)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetUInt8,  fmi3UInt8)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetInt16,  fmi3Int16)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetUInt16, fmi3UInt16)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetUInt32, fmi3UInt32)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetInt64,  fmi3Int64)
FMU3_CPP_UNSUPPORTED_SET(fmi3SetUInt64, fmi3UInt64)

fmi3Status fmi3GetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, size_t valueSizes[], fmi3Binary values[], size_t nValues)
{ (void)instance; (void)valueReferences; (void)valueSizes; (void)values; (void)nValues;
  return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3SetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const size_t valueSizes[], const fmi3Binary values[], size_t nValues)
{ (void)instance; (void)valueReferences; (void)valueSizes; (void)values; (void)nValues;
  return nValueReferences == 0 ? fmi3OK : fmi3Error; }

fmi3Status fmi3GetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Clock values[])
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (nValueReferences == 0) return fmi3OK;
  if (valueReferences == NULL || values == NULL) return fmi3Error;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      // the wrapper uses 1-based clock indices
      int idx = (int)(valueReferences[i] - FMI3_CLOCK_VR_OFFSET) + 1;
      int tick = 0;
      fmi3Status s = (fmi3Status)inst->wrapper->getClock(&idx, 1, &tick);
      if (s > fmi3Warning) return s;
      values[i] = tick ? fmi3ClockActive : fmi3ClockInactive;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Clock values[])
{ (void)instance; (void)valueReferences; (void)values;
  return nValueReferences == 0 ? fmi3OK : fmi3Error; }

// ---------------------------------------------------------------------------
// Variable dependency information / FMU state / configuration (not provided)
// ---------------------------------------------------------------------------
fmi3Status fmi3GetNumberOfVariableDependencies(fmi3Instance instance, fmi3ValueReference valueReference, size_t* nDependencies)
{ (void)instance; (void)valueReference; (void)nDependencies; return fmi3Error; }

fmi3Status fmi3GetVariableDependencies(fmi3Instance instance, fmi3ValueReference dependent,
    size_t elementIndicesOfDependent[], fmi3ValueReference independents[],
    size_t elementIndicesOfIndependents[], fmi3DependencyKind dependencyKinds[], size_t nDependencies)
{ (void)instance; (void)dependent; (void)elementIndicesOfDependent; (void)independents;
  (void)elementIndicesOfIndependents; (void)dependencyKinds; (void)nDependencies; return fmi3Error; }

fmi3Status fmi3GetFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (FMUState == NULL) return fmi3Error;
  try { return (fmi3Status)inst->wrapper->getFMUState(FMUState); } FMU3_CATCH(inst)
}
fmi3Status fmi3SetFMUState(fmi3Instance instance, fmi3FMUState FMUState)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (FMUState == NULL) return fmi3Error;
  try { return (fmi3Status)inst->wrapper->setFMUState(FMUState); } FMU3_CATCH(inst)
}
fmi3Status fmi3FreeFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (FMUState == NULL || *FMUState == NULL) return fmi3OK; /* freeing NULL is a no-op */
  try { return (fmi3Status)inst->wrapper->freeFMUState(FMUState); } FMU3_CATCH(inst)
}
fmi3Status fmi3SerializedFMUStateSize(fmi3Instance instance, fmi3FMUState FMUState, size_t* size)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (FMUState == NULL || size == NULL) return fmi3Error;
  try { return (fmi3Status)inst->wrapper->serializedFMUStateSize(FMUState, size); } FMU3_CATCH(inst)
}
fmi3Status fmi3SerializeFMUState(fmi3Instance instance, fmi3FMUState FMUState, fmi3Byte serializedState[], size_t size)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (FMUState == NULL || serializedState == NULL) return fmi3Error;
  try { return (fmi3Status)inst->wrapper->serializeFMUState(FMUState, serializedState, size); } FMU3_CATCH(inst)
}
fmi3Status fmi3DeserializeFMUState(fmi3Instance instance, const fmi3Byte serializedState[], size_t size, fmi3FMUState* FMUState)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (serializedState == NULL || FMUState == NULL) return fmi3Error;
  try { return (fmi3Status)inst->wrapper->deSerializeFMUState(serializedState, size, FMUState); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetDirectionalDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[],
    size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[],
    size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (nUnknowns == 0) return fmi3OK;
  if (unknowns == NULL || knowns == NULL || seed == NULL || sensitivity == NULL) return fmi3Error;
  if (nSeed != nKnowns || nSensitivity != nUnknowns) return fmi3Error;
  try {
    // unknowns (derivatives/outputs) and knowns (states/inputs) are Float64;
    // recover the per-real-type value reference the wrapper expects
    std::vector<unsigned int> u(nUnknowns), k(nKnowns);
    for (size_t i = 0; i < nUnknowns; i++) u[i] = (unsigned int)(unknowns[i] - FMI3_REAL_VR_OFFSET);
    for (size_t i = 0; i < nKnowns;   i++) k[i] = (unsigned int)(knowns[i]   - FMI3_REAL_VR_OFFSET);
    return (fmi3Status)inst->wrapper->getDirectionalDerivative(&u[0], nUnknowns, &k[0], nKnowns, seed, sensitivity);
  } FMU3_CATCH(inst)
}

fmi3Status fmi3GetAdjointDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[],
    size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[],
    size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{ (void)instance; (void)unknowns; (void)nUnknowns; (void)knowns; (void)nKnowns;
  (void)seed; (void)nSeed; (void)sensitivity; (void)nSensitivity; return fmi3Error; }

fmi3Status fmi3EnterConfigurationMode(fmi3Instance instance) { (void)instance; return fmi3OK; }
fmi3Status fmi3ExitConfigurationMode(fmi3Instance instance) { (void)instance; return fmi3OK; }

fmi3Status fmi3GetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3Float64 intervals[], fmi3IntervalQualifier qualifiers[])
{
  FMU3CppInstance *inst = FMU3_W(instance);
  if (nValueReferences == 0) return fmi3OK;
  if (valueReferences == NULL || intervals == NULL) return fmi3Error;
  try {
    for (size_t i = 0; i < nValueReferences; i++) {
      int idx = (int)(valueReferences[i] - FMI3_CLOCK_VR_OFFSET) + 1;
      double iv = 0.0;
      fmi3Status s = (fmi3Status)inst->wrapper->getInterval(&idx, 1, &iv);
      if (s > fmi3Warning) return s;
      intervals[i] = iv;
      if (qualifiers) qualifiers[i] = fmi3IntervalUnchanged;
    }
    return fmi3OK;
  } FMU3_CATCH(inst)
}
fmi3Status fmi3GetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[], fmi3IntervalQualifier qualifiers[])
{ (void)instance; (void)valueReferences; (void)counters; (void)resolutions; (void)qualifiers; return nValueReferences == 0 ? fmi3OK : fmi3Error; }
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

fmi3Status fmi3EvaluateDiscreteStates(fmi3Instance instance) { (void)instance; return fmi3OK; }

fmi3Status fmi3UpdateDiscreteStates(fmi3Instance instance, fmi3Boolean* discreteStatesNeedUpdate,
    fmi3Boolean* terminateSimulation, fmi3Boolean* nominalsOfContinuousStatesChanged,
    fmi3Boolean* valuesOfContinuousStatesChanged, fmi3Boolean* nextEventTimeDefined,
    fmi3Float64* nextEventTime)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  FMU3EventInfo eventInfo;
  memset(&eventInfo, 0, sizeof(eventInfo));
  try {
    fmi3Status status = inst->wrapper->newDiscreteStates(&eventInfo);
    if (discreteStatesNeedUpdate)          *discreteStatesNeedUpdate = eventInfo.newDiscreteStatesNeeded ? fmi3True : fmi3False;
    if (terminateSimulation)               *terminateSimulation = eventInfo.terminateSimulation ? fmi3True : fmi3False;
    if (nominalsOfContinuousStatesChanged) *nominalsOfContinuousStatesChanged = eventInfo.nominalsOfContinuousStatesChanged ? fmi3True : fmi3False;
    if (valuesOfContinuousStatesChanged)   *valuesOfContinuousStatesChanged = eventInfo.valuesOfContinuousStatesChanged ? fmi3True : fmi3False;
    if (nextEventTimeDefined)              *nextEventTimeDefined = eventInfo.nextEventTimeDefined ? fmi3True : fmi3False;
    if (nextEventTime)                     *nextEventTime = eventInfo.nextEventTime;
    return (fmi3Status)status;
  } FMU3_CATCH(inst)
}

// ---------------------------------------------------------------------------
// Functions for Model Exchange
// ---------------------------------------------------------------------------
fmi3Status fmi3EnterContinuousTimeMode(fmi3Instance instance)
{
  (void)instance;
  return fmi3OK;
}

fmi3Status fmi3CompletedIntegratorStep(fmi3Instance instance, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  fmi3Boolean enterEventMode2 = fmi3False;
  fmi3Boolean terminate2 = fmi3False;
  try {
    fmi3Status s = inst->wrapper->completedIntegratorStep(
        noSetFMUStatePriorToCurrentPoint ? fmi3True : fmi3False, &enterEventMode2, &terminate2);
    if (enterEventMode)      *enterEventMode = enterEventMode2 ? fmi3True : fmi3False;
    if (terminateSimulation) *terminateSimulation = terminate2 ? fmi3True : fmi3False;
    return (fmi3Status)s;
  } FMU3_CATCH(inst)
}

fmi3Status fmi3SetTime(fmi3Instance instance, fmi3Float64 time)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  inst->time = time;
  try { return (fmi3Status)inst->wrapper->setTime(time); } FMU3_CATCH(inst)
}

fmi3Status fmi3SetContinuousStates(fmi3Instance instance, const fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->setContinuousStates(continuousStates, nContinuousStates); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetContinuousStateDerivatives(fmi3Instance instance, fmi3Float64 derivatives[], size_t nContinuousStates)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->getDerivatives(derivatives, nContinuousStates); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetEventIndicators(fmi3Instance instance, fmi3Float64 eventIndicators[], size_t nEventIndicators)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->getEventIndicators(eventIndicators, nEventIndicators); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetContinuousStates(fmi3Instance instance, fmi3Float64 continuousStates[], size_t nContinuousStates)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->getContinuousStates(continuousStates, nContinuousStates); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetNominalsOfContinuousStates(fmi3Instance instance, fmi3Float64 nominals[], size_t nContinuousStates)
{
  FMU3CppInstance *inst = FMU3_W(instance);
  try { return (fmi3Status)inst->wrapper->getNominalsOfContinuousStates(nominals, nContinuousStates); } FMU3_CATCH(inst)
}

fmi3Status fmi3GetNumberOfEventIndicators(fmi3Instance instance, size_t* nEventIndicators)
{
  (void)instance;
  if (nEventIndicators == NULL) return fmi3Error;
  *nEventIndicators = (size_t)NUMBER_OF_EVENT_INDICATORS;
  return fmi3OK;
}

fmi3Status fmi3GetNumberOfContinuousStates(fmi3Instance instance, size_t* nContinuousStates)
{
  (void)instance;
  if (nContinuousStates == NULL) return fmi3Error;
  *nContinuousStates = (size_t)FMI3_NUMBER_OF_STATES;
  return fmi3OK;
}

// ---------------------------------------------------------------------------
// Functions for Co-Simulation / Scheduled Execution
// The Cpp FMU export is Model Exchange only (Co-Simulation is downgraded to ME
// by the scripting front-end), so these are exported but not functional.
// ---------------------------------------------------------------------------
fmi3Status fmi3EnterStepMode(fmi3Instance instance) { (void)instance; return fmi3OK; }

fmi3Status fmi3GetOutputDerivatives(fmi3Instance instance, const fmi3ValueReference valueReferences[],
    size_t nValueReferences, const fmi3Int32 orders[], fmi3Float64 values[], size_t nValues)
{ (void)instance; (void)valueReferences; (void)nValueReferences; (void)orders; (void)values; (void)nValues;
  return fmi3Error; }

fmi3Status fmi3DoStep(fmi3Instance instance, fmi3Float64 currentCommunicationPoint,
    fmi3Float64 communicationStepSize, fmi3Boolean noSetFMUStatePriorToCurrentPoint,
    fmi3Boolean* eventHandlingNeeded, fmi3Boolean* terminateSimulation, fmi3Boolean* earlyReturn,
    fmi3Float64* lastSuccessfulTime)
{
  (void)instance; (void)currentCommunicationPoint; (void)communicationStepSize;
  (void)noSetFMUStatePriorToCurrentPoint;
  if (eventHandlingNeeded)  *eventHandlingNeeded = fmi3False;
  if (terminateSimulation)  *terminateSimulation = fmi3False;
  if (earlyReturn)          *earlyReturn = fmi3False;
  if (lastSuccessfulTime)   *lastSuccessfulTime = currentCommunicationPoint;
  return fmi3Error;
}

fmi3Status fmi3ActivateModelPartition(fmi3Instance instance, fmi3ValueReference clockReference,
    fmi3Float64 activationTime)
{ (void)instance; (void)clockReference; (void)activationTime; return fmi3Error; }

} // extern "C"
/** @} */ // end of fmu3
