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
        "%s: Illegal call sequence. Expected State: %d.", f, statesExpected);
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
  // TODO Write code here
  return fmiOK;
}

fmiComponent fmiInstantiate(fmiString instanceName, fmiType fmuType, fmiString fmuGUID, fmiString fmuResourceLocation, const fmiCallbackFunctions* functions,
    fmiBoolean visible, fmiBoolean loggingOn) {
  // TODO Write code here
  return NULL;
}

void fmiFreeInstance(fmiComponent c) {

}

fmiStatus fmiSetupExperiment(fmiComponent c, fmiBoolean toleranceDefined, fmiReal tolerance, fmiReal startTime, fmiBoolean stopTimeDefined, fmiReal stopTime) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiEnterInitializationMode(fmiComponent c) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiExitInitializationMode(fmiComponent c) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiTerminate(fmiComponent c) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiReset(fmiComponent c) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]){
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetFMUstate(fmiComponent c, fmiFMUstate* FMUstate) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSetFMUstate(fmiComponent c, fmiFMUstate FMUstate) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiFreeFMUstate(fmiComponent c, fmiFMUstate* FMUstate) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSerializedFMUstateSize(fmiComponent c, fmiFMUstate FMUstate, size_t *size) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiSerializeFMUstate(fmiComponent c, fmiFMUstate FMUstate, fmiByte serializedState[], size_t size) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiDeSerializeFMUstate(fmiComponent c, const fmiByte serializedState[], size_t size, fmiFMUstate* FMUstate) {
  // TODO Write code here
  return fmiOK;
}

fmiStatus fmiGetDirectionalDerivative(fmiComponent c, const fmiValueReference vUnknown_ref[], size_t nUnknown, const fmiValueReference vKnown_ref[] , size_t nKnown,
    const fmiReal dvKnown[], fmiReal dvUnknown[]) {
  // TODO Write code here
  return fmiOK;
}

/***************************************************
Functions for FMI for Model Exchange
****************************************************/

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
