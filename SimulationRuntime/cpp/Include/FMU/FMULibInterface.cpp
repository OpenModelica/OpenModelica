/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "IFMUInterface.h"
#include "FMU/fmiModelFunctions.h"
#include <iostream>

using namespace std;

// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

extern "C" const char* fmiGetModelTypesPlatform() {
  return fmiModelTypesPlatform;
}

extern "C" const char* fmiGetVersion() {
  return fmiVersion;
}

extern "C" fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID,
    fmiCallbackFunctions functions, fmiBoolean loggingOn)
{
  //cout << "fmiInstantiateModel called" << endl;
  return reinterpret_cast<fmiComponent> (OBJECTCONSTRUCTOR);
}

extern "C" fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn) {
  return reinterpret_cast<IFMUInterface*>(c)->setDebugLogging(loggingOn);
}

extern "C" void fmiFreeModelInstance(fmiComponent c) {
  delete reinterpret_cast<IFMUInterface*>(c);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]){
  return reinterpret_cast<IFMUInterface*>(c)->setReal(vr, nvr, value);
}

extern "C" fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]){
  return reinterpret_cast<IFMUInterface*>(c)->setInteger(vr, nvr, value);
}

extern "C" fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]){
  return reinterpret_cast<IFMUInterface*>(c)->setBoolean(vr, nvr, value);
}

extern "C" fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]){
  return reinterpret_cast<IFMUInterface*>(c)->setString(vr, nvr, value);
}

extern "C" fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
  //cout << "setTime is called: fmiComponent=" << c << " time=" << time << endl;
  if(!c) return fmiFatal; // TODO OpenModelica produces this Error if loading an FMI Model.
  return reinterpret_cast<IFMUInterface*>(c)->setTime(time);
}

extern "C" fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx){
  return reinterpret_cast<IFMUInterface*>(c)->setContinuousStates(x, nx);
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  return reinterpret_cast<IFMUInterface*>(c)->getReal(vr, nvr, value);
}

extern "C" fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  return reinterpret_cast<IFMUInterface*>(c)->getInteger(vr, nvr, value);
}

extern "C" fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) {
  return reinterpret_cast<IFMUInterface*>(c)->getBoolean(vr, nvr, value);
}

extern "C" fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]) {
  return reinterpret_cast<IFMUInterface*>(c)->getString(vr, nvr, value);
}

extern "C" fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx){
  return reinterpret_cast<IFMUInterface*>(c)->getStateValueReferences(vrx, nx);
}

extern "C" fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx){
  return reinterpret_cast<IFMUInterface*>(c)->getContinuousStates(states, nx);
}

extern "C" fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx){
  return reinterpret_cast<IFMUInterface*>(c)->getNominalContinuousStates(x_nominal, nx);
}

extern "C" fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
  return reinterpret_cast<IFMUInterface*>(c)->getDerivatives(derivatives, nx);
}

extern "C" fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni) {
  return reinterpret_cast<IFMUInterface*>(c)->getEventIndicators(eventIndicators, ni);
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled, fmiReal relativeTolerance,
    fmiEventInfo* eventInfo) {
  return reinterpret_cast<IFMUInterface*>(c)->initialize(toleranceControlled, relativeTolerance, *eventInfo);
}

extern "C" fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo) {
  return reinterpret_cast<IFMUInterface*>(c)->eventUpdate(intermediateResults, *eventInfo);
}

extern "C" fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate){
  return reinterpret_cast<IFMUInterface*>(c)->completedIntegratorStep(callEventUpdate);
}

extern "C" fmiStatus fmiTerminate(fmiComponent c){
  return reinterpret_cast<IFMUInterface*>(c)->terminate();
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiSetExternalFunction(fmiComponent c, fmiValueReference vr[], size_t nvr, const void* value[]) {
  return reinterpret_cast<IFMUInterface*>(c)->setExternalFunction(vr, nvr, value);
}

