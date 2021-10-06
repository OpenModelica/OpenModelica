/** @addtogroup fmu2
 *
 *  @{
 */
/*
 * Implement the FMI 2.0 calling interface to FMU2Wrapper.
 *
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "FMU2Wrapper.h"

/* FMI extension for multi-rate sampled data systems */
typedef fmi2Status fmi2GetClockTYPE(fmi2Component, const int fmi2Integer[],
                                    size_t, fmi2Boolean[]);
typedef fmi2Status fmi2SetClockTYPE(fmi2Component, const int fmiInteger[],
                                    size_t, const fmi2Boolean[],
                                    const fmi2Boolean*);
typedef fmi2Status fmi2GetIntervalTYPE(fmi2Component, const int fmiInteger[],
                                       size_t, fmi2Real[]);
typedef fmi2Status fmi2SetIntervalTYPE(fmi2Component, const int fmiInteger[],
                                       size_t, const fmi2Real[]);

extern "C"
{
  FMI2_Export fmi2GetClockTYPE fmi2GetClock;
  FMI2_Export fmi2SetClockTYPE fmi2SetClock;
  FMI2_Export fmi2GetIntervalTYPE fmi2GetInterval;
  FMI2_Export fmi2SetIntervalTYPE fmi2SetInterval;
}

/* Common definitions */
#define LOG_CALL(w, ...) \
  FMU2_LOG(w, fmi2OK, logFmi2Call, __VA_ARGS__)

#define CATCH_EXCEPTION(w) \
  catch (std::exception &e) { \
    FMU2_LOG(w, fmi2Error, logStatusError, e.what()); \
    return fmi2Error; \
  }

// ---------------------------------------------------------------------------
// Common Functions
// ---------------------------------------------------------------------------

//
// Inquire version numbers of header files
//

extern "C"
{
  const char* fmi2GetTypesPlatform()
  {
    return fmi2TypesPlatform;
  }

  const char* fmi2GetVersion()
  {
    return fmi2Version;
  }

  //
  // Creation and destruction of FMU instances and setting logging status
  //

  fmi2Component fmi2Instantiate(fmi2String instanceName,
                                fmi2Type fmuType,
                                fmi2String GUID,
                                fmi2String fmuResourceLocation,
                                const fmi2CallbackFunctions *functions,
                                fmi2Boolean visible,
                                fmi2Boolean loggingOn)
  {
    FMU2Wrapper *w;
    try {
      w = new FMU2Wrapper(instanceName, GUID, functions, loggingOn);
    }
    catch (std::exception &e) {
      if (functions && functions->logger)
        functions->logger(functions->componentEnvironment,
                          instanceName, fmi2Error,
                          FMU2Wrapper::LogCategoryFMUName(logStatusError),
                          e.what());
      return NULL;
    }
    LOG_CALL(w, "fmi2Instantiate");
    return reinterpret_cast<fmi2Component>(w);
  }

  void fmi2FreeInstance(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2FreeInstance");
    delete w;
  }

  fmi2Status fmi2SetDebugLogging(fmi2Component c,
                                 fmi2Boolean loggingOn,
                                 size_t nCategories,
                                 const fmi2String categories[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetDebugLogging(%s, nCategories = %d)",
             loggingOn? "true": "false", nCategories);
    try {
      return w->setDebugLogging(loggingOn, nCategories, categories);
    }
    CATCH_EXCEPTION(w);
  }

  //
  // Enter and exit initialization mode, terminate and reset
  //

  fmi2Status fmi2SetupExperiment(fmi2Component c,
                                 fmi2Boolean toleranceDefined,
                                 fmi2Real tolerance,
                                 fmi2Real startTime,
                                 fmi2Boolean stopTimeDefined,
                                 fmi2Real stopTime)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetupExperiment(startTime = %g)", startTime);
    try {
      return w->setupExperiment(toleranceDefined, tolerance, startTime,
                                stopTimeDefined, stopTime);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2EnterInitializationMode(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2EnterInitializationMode");
    try {
      return w->enterInitializationMode();
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2ExitInitializationMode(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2ExitInitializationMode");
    try {
      return w->exitInitializationMode();
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2Terminate(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2Terminate");
    try {
      return w->terminate();
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2Reset(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2Reset");
    try {
      return w->reset();
    }
    CATCH_EXCEPTION(w);
  }

  //
  // Getting and setting variable values
  //

  fmi2Status fmi2GetReal(fmi2Component c,
                         const fmi2ValueReference vr[], size_t nvr,
                         fmi2Real value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetReal(nvr = %d)", nvr);
    try {
      return w->getReal(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetInteger(fmi2Component c,
                            const fmi2ValueReference vr[], size_t nvr,
                            fmi2Integer value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetInteger(nvr = %d)", nvr);
    try {
      return w->getInteger(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetBoolean(fmi2Component c,
                            const fmi2ValueReference vr[], size_t nvr,
                            fmi2Boolean value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetBoolean(nvr = %d)", nvr);
    try {
      return w->getBoolean(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetString(fmi2Component c,
                           const fmi2ValueReference vr[], size_t nvr,
                           fmi2String  value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetString(nvr = %d)", nvr);
    try {
      return w->getString(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetClock(fmi2Component c,
                          const fmi2Integer clockIndex[],
                          size_t nClockIndex, fmi2Boolean tick[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetClock(nClockIndex = %d)", nClockIndex);
    try {
      return w->getClock(clockIndex, nClockIndex, tick);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetInterval(fmi2Component c,
                             const fmi2Integer clockIndex[],
                             size_t nClockIndex, fmi2Real interval[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetInterval(nClockIndex = %d)", nClockIndex);
    try {
      return w->getInterval(clockIndex, nClockIndex, interval);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetReal(fmi2Component c,
                         const fmi2ValueReference vr[], size_t nvr,
                         const fmi2Real value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetReal(nvr = %d)", nvr);
    try {
      return w->setReal(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetInteger(fmi2Component c,
                            const fmi2ValueReference vr[], size_t nvr,
                            const fmi2Integer value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetInteger(nvr = %d)", nvr);
    try {
      return w->setInteger(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetBoolean(fmi2Component c,
                            const fmi2ValueReference vr[], size_t nvr,
                            const fmi2Boolean value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetBoolean(nvr = %d)", nvr);
    try {
      return w->setBoolean(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetString(fmi2Component c,
                           const fmi2ValueReference vr[], size_t nvr,
                           const fmi2String value[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetString(nvr = %d)", nvr);
    try {
      return w->setString(vr, nvr, value);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetClock(fmi2Component c,
                          const fmi2Integer clockIndex[],
                          size_t nClockIndex, const fmi2Boolean tick[],
                          const fmi2Boolean subactive[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetClock(nClockIndex = %d)", nClockIndex);
    try {
      return w->setClock(clockIndex, nClockIndex, tick, subactive);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetInterval(fmi2Component c,
                             const fmi2Integer clockIndex[],
                             size_t nClockIndex, const fmi2Real interval[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetInterval(nClockIndex = %d)", nClockIndex);
    try {
      return w->setInterval(clockIndex, nClockIndex, interval);
    }
    CATCH_EXCEPTION(w);
  }

  //
  // Getting and setting the internal FMU state
  //

  fmi2Status fmi2GetFMUstate (fmi2Component c, fmi2FMUstate* FMUstate)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetFMUstate not implemented");
    return fmi2Error;
  }

  fmi2Status fmi2SetFMUstate (fmi2Component c, fmi2FMUstate  FMUstate)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetFMUstate not implemented");
    return fmi2Error;
  }

  fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2FreeFMUstate not implemented");
    return fmi2Error;
  }

  fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate,
                                        size_t *size)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SerializedFMUstateSize not implemented");
    return fmi2Error;
  }

  fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate,
                                   fmi2Byte serializedState[], size_t size)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SerializeFMUstate not implemented");
    return fmi2Error;
  }

  fmi2Status fmi2DeSerializeFMUstate(fmi2Component c,
                                     const fmi2Byte serializedState[],
                                     size_t size, fmi2FMUstate* FMUstate)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2DeSerializeFMUstate not implemented");
    return fmi2Error;
  }

  //
  // Getting directional derivatives
  //

  fmi2Status fmi2GetDirectionalDerivative(fmi2Component c,
                                          const fmi2ValueReference vUnknown_ref[],
                                          size_t nUnknown,
                                          const fmi2ValueReference vKnown_ref[],
                                          size_t nKnown,
                                          const fmi2Real dvKnown[],
                                          fmi2Real dvUnknown[])
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetDirectionalDerivative(nUnknown = %d, nKnown = %d)", nUnknown, nKnown);
    try {
      return w->getDirectionalDerivative(vUnknown_ref, nUnknown,
                                         vKnown_ref, nKnown, dvKnown,
                                         dvUnknown);
    }
    CATCH_EXCEPTION(w);
  }

  // ---------------------------------------------------------------------------
  // Types for Functions for FMI2 for Model Exchange
  // ---------------------------------------------------------------------------

  //
  // Enter and exit the different modes
  //

  fmi2Status fmi2EnterEventMode(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2EnterEventMode");
    return fmi2OK;
  }

  fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo *eventInfo)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2NewDiscreteStates");
    try {
      return w->newDiscreteStates(eventInfo);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2EnterContinuousTimeMode");
    return fmi2OK;
  }

  fmi2Status fmi2CompletedIntegratorStep(fmi2Component c,
                                         fmi2Boolean noSetFMUStatePriorToCurrentPoint,
                                         fmi2Boolean* enterEventMode,
                                         fmi2Boolean* terminateSimulation)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2CompletedIntegratorStep");
    try {
      return w->completedIntegratorStep(noSetFMUStatePriorToCurrentPoint,
                                        enterEventMode, terminateSimulation);
    }
    CATCH_EXCEPTION(w);
  }

  //
  // Providing independent variables and re-initialization of caching
  //

  fmi2Status fmi2SetTime(fmi2Component c, fmi2Real time)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetTime(%g)", time);
    try {
      return w->setTime(time);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2SetContinuousStates(fmi2Component c,
                                     const fmi2Real x[], size_t nx)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2SetContinuousStates(nx = %d)", nx);
    try {
      return w->setContinuousStates(x, nx);
    }
    CATCH_EXCEPTION(w);
  }

  //
  // Evaluation of the model equations
  //

  fmi2Status fmi2GetDerivatives(fmi2Component c,
                                fmi2Real derivatives[], size_t nx)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetDerivatives(nx = %d)", nx);
    try {
      return w->getDerivatives(derivatives, nx);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetEventIndicators(fmi2Component c,
                                    fmi2Real eventIndicators[], size_t ni)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetEventIndicators(ni = %d)", ni);
    try {
      return w->getEventIndicators(eventIndicators, ni);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetContinuousStates(fmi2Component c,
                                     fmi2Real states[], size_t nx)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetContinuousStates(nx = %d)", nx);
    try {
      return w->getContinuousStates(states, nx);
    }
    CATCH_EXCEPTION(w);
  }

  fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c,
                                               fmi2Real x_nominal[], size_t nx)
  {
    FMU2Wrapper *w = reinterpret_cast<FMU2Wrapper*>(c);
    LOG_CALL(w, "fmi2GetNominalsOfContinuousStates(nx = %d)", nx);
    try {
      return w->getNominalsOfContinuousStates(x_nominal, nx);
    }
    CATCH_EXCEPTION(w);
  }
}
/** @} */ // end of fmu2
