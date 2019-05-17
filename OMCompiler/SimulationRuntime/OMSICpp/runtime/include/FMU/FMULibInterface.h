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

#include <FMU/IFMUInterface.h>
#include <FMU/fmiModelFunctions.h>
#include <FMU/FMUWrapper.h>
//#include "FMU/log.hpp"
#include <iostream>



//#define LOG_FMI()   EmptyLog()
//#define DO_LOG_FMI  false

// ---------------------------------------------------------------------------
// FMI functions: class methods not depending of a specific model instance
// ---------------------------------------------------------------------------

extern "C" const char* fmiGetModelTypesPlatform() {
  //LOG_FMI() << "Entry: fmiGetModelTypesPlatform" << endl;
  return fmiModelTypesPlatform;
}

extern "C" const char* fmiGetVersion() {
  //LOG_FMI() << "Entry: fmiGetVersion" << endl;
  return fmiVersion;
}

extern "C" fmiComponent fmiInstantiateModel(fmiString instanceName, fmiString GUID,
    fmiCallbackFunctions functions, fmiBoolean loggingOn)
{
  //LOG_FMI() << "Entry: fmiInstantiateModel" << endl;
  return reinterpret_cast<fmiComponent>
    (new FMUWrapper(instanceName, GUID, functions, loggingOn));
}

extern "C" fmiStatus fmiSetDebugLogging(fmiComponent c, fmiBoolean loggingOn) {
  //LOG_FMI() << "Entry: fmiSetDebugLogging" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setDebugLogging(loggingOn);
}

extern "C" void fmiFreeModelInstance(fmiComponent c) {
  //LOG_FMI() << "Entry: fmiModelInstance" << endl;
  delete reinterpret_cast<IFMUInterface*>(c);
}

// ---------------------------------------------------------------------------
// FMI functions: set variable values in the FMU
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiSetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiReal value[]){
  //LOG_FMI() << "Entry: fmiSetReal nvr=" << nvr << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setReal(vr, nvr, value);
}

extern "C" fmiStatus fmiSetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiInteger value[]){
  //LOG_FMI() << "Entry: fmiSetInteger nvr=" << nvr << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setInteger(vr, nvr, value);
}

extern "C" fmiStatus fmiSetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiBoolean value[]){
  //LOG_FMI() << "Entry: fmiBoolean nvr=" << nvr << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setBoolean(vr, nvr, value);
}

extern "C" fmiStatus fmiSetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, const fmiString value[]){
  //LOG_FMI() << "Entry: fmiString nvr=" << nvr << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setString(vr, nvr, value);
}

extern "C" fmiStatus fmiSetTime(fmiComponent c, fmiReal time) {
  //LOG_FMI() << "Entry: **fmiSetTime is called: fmiComponent=" << c << " time=" << time << endl;
  if(!c) return fmiFatal; // TODO OpenModelica produces this Error if loading an FMI Model.
  return reinterpret_cast<IFMUInterface*>(c)->setTime(time);
}

extern "C" fmiStatus fmiSetContinuousStates(fmiComponent c, const fmiReal x[], size_t nx){
  //LOG_FMI() << "Entry: **fmiSetContinuousState nx=" << nx << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setContinuousStates(x, nx);
}

// ---------------------------------------------------------------------------
// FMI functions: get variable values from the FMU
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiGetReal(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiReal value[]) {
  //LOG_FMI() << "Entry: fmiGetReal nvr=" << nvr << "value references=" << printArray(vr, nvr, " ") << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getReal(vr, nvr, value);
}

extern "C" fmiStatus fmiGetInteger(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiInteger value[]) {
  //LOG_FMI() << "Entry: fmiGetInteger nvr=" << nvr << "value references=" << printArray(vr, nvr, " ") << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getInteger(vr, nvr, value);
}

extern "C" fmiStatus fmiGetBoolean(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiBoolean value[]) {
  //LOG_FMI() << "Entry: fmiGetBoolean nvr=" << nvr << "value references=" << printArray(vr, nvr, " ") << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getBoolean(vr, nvr, value);
}

extern "C" fmiStatus fmiGetString(fmiComponent c, const fmiValueReference vr[], size_t nvr, fmiString  value[]) {
  //LOG_FMI() << "Entry: fmiString nvr=" << nvr << "value references=" << printArray(vr, nvr, " ") << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getString(vr, nvr, value);
}

extern "C" fmiStatus fmiGetStateValueReferences(fmiComponent c, fmiValueReference vrx[], size_t nx){
  //LOG_FMI() << "Entry: fmiGetStateValueReferences nx=" << nx << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getStateValueReferences(vrx, nx);
}

extern "C" fmiStatus fmiGetContinuousStates(fmiComponent c, fmiReal states[], size_t nx){
  //LOG_FMI() << "Entry: fmiGetContinuousStates nx=" << nx << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getContinuousStates(states, nx);
}

extern "C" fmiStatus fmiGetNominalContinuousStates(fmiComponent c, fmiReal x_nominal[], size_t nx){
  //LOG_FMI() << "Entry: fmiGetNominalContinuousStates" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getNominalContinuousStates(x_nominal, nx);
}

extern "C" fmiStatus fmiGetDerivatives(fmiComponent c, fmiReal derivatives[], size_t nx) {
  //LOG_FMI() << "Entry: fmiGetDerivates nx = " << nx << endl;
  return reinterpret_cast<IFMUInterface*>(c)->getDerivatives(derivatives, nx);
}

extern "C" fmiStatus fmiGetEventIndicators(fmiComponent c, fmiReal eventIndicators[], size_t ni) {
  //if(DO_LOG_FMI)
  //{
  //  LOG_FMI() << "Entry: fmiGetEventIndicators ni=" << ni << endl;
  //  fmiStatus result = reinterpret_cast<IFMUInterface*>(c)->getEventIndicators(eventIndicators, ni);
  //  LOG_FMI() << "Return values eventIndicators =" << printArray(eventIndicators, ni, " ") << endl;
  //  return result;
  //}
  //else
  //{
    return reinterpret_cast<IFMUInterface*>(c)->getEventIndicators(eventIndicators, ni);
  //}
}

// ---------------------------------------------------------------------------
// FMI functions: initialization, event handling, stepping and termination
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiInitialize(fmiComponent c, fmiBoolean toleranceControlled,
    fmiReal relativeTolerance, fmiEventInfo* eventInfo)
{
  //LOG_FMI() << "Entry: fmiInitialize" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->initialize(toleranceControlled,
      relativeTolerance, *eventInfo);
}

extern "C" fmiStatus fmiEventUpdate(fmiComponent c, fmiBoolean intermediateResults, fmiEventInfo* eventInfo) {
  //LOG_FMI() << "Entry: ****fmiEventUpdate" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->eventUpdate(intermediateResults, *eventInfo);
}

extern "C" fmiStatus fmiCompletedIntegratorStep(fmiComponent c, fmiBoolean* callEventUpdate){
  //LOG_FMI() << "Entry: ***fmiCompletedIntegratorStep" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->completedIntegratorStep(*callEventUpdate);
}

extern "C" fmiStatus fmiTerminate(fmiComponent c){
  //LOG_FMI() << "Entry: fmiTerminate" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->terminate();
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

extern "C" fmiStatus fmiSetExternalFunction(fmiComponent c, fmiValueReference vr[], size_t nvr, const void* value[]) {
  //LOG_FMI() << "Entry: fmiSetExternalFunction" << endl;
  return reinterpret_cast<IFMUInterface*>(c)->setExternalFunction(vr, nvr, value);
}

