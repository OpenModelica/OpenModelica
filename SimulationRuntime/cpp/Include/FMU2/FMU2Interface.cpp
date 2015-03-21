/*
 * Implement the FMI 2.0 calling interface to FMU2Wrapper.
 *
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

#include "FMU2Wrapper.h"

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
    return reinterpret_cast<fmi2Component>(OBJECTCONSTRUCTOR);
  }

  void fmi2FreeInstance(fmi2Component c)
  {
    delete reinterpret_cast<FMU2Wrapper*>(c);
  }

  fmi2Status fmi2SetDebugLogging(fmi2Component c,
				 fmi2Boolean loggingOn,
				 size_t nCategories,
				 const fmi2String categories[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setDebugLogging(loggingOn);
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
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setupExperiment(toleranceDefined, tolerance, startTime,
			   stopTimeDefined, stopTime);
  }

  fmi2Status fmi2EnterInitializationMode(fmi2Component c)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->initialize();
  }

  fmi2Status fmi2ExitInitializationMode(fmi2Component c)
  {
    return fmi2OK;
  }

  fmi2Status fmi2Terminate(fmi2Component c)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->terminate();
  }

  fmi2Status fmi2Reset(fmi2Component c)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->reset();
  }

  //
  // Getting and setting variable values
  //

  fmi2Status fmi2GetReal(fmi2Component c,
			 const fmi2ValueReference vr[], size_t nvr,
			 fmi2Real value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getReal(vr, nvr, value);
  }

  fmi2Status fmi2GetInteger(fmi2Component c,
			    const fmi2ValueReference vr[], size_t nvr,
			    fmi2Integer value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getInteger(vr, nvr, value);
  }

  fmi2Status fmi2GetBoolean(fmi2Component c,
			    const fmi2ValueReference vr[], size_t nvr,
			    fmi2Boolean value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getBoolean(vr, nvr, value);
  }

  fmi2Status fmi2GetString(fmi2Component c,
			   const fmi2ValueReference vr[], size_t nvr,
			   fmi2String  value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getString(vr, nvr, value);
  }

  fmi2Status fmi2SetReal(fmi2Component c,
			 const fmi2ValueReference vr[], size_t nvr,
			 const fmi2Real value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setReal(vr, nvr, value);
  }

  fmi2Status fmi2SetInteger(fmi2Component c,
			    const fmi2ValueReference vr[], size_t nvr,
			    const fmi2Integer value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setInteger(vr, nvr, value);
  }

  fmi2Status fmi2SetBoolean(fmi2Component c,
			    const fmi2ValueReference vr[], size_t nvr,
			    const fmi2Boolean value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setBoolean(vr, nvr, value);
  }

  fmi2Status fmi2SetString(fmi2Component c,
			   const fmi2ValueReference vr[], size_t nvr,
			   const fmi2String value[])
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setString(vr, nvr, value);
  }

  //
  // Getting and setting the internal FMU state
  //

  fmi2Status fmi2GetFMUstate (fmi2Component c, fmi2FMUstate* FMUstate)
  {
    return fmi2Error; // not implemented
  }

  fmi2Status fmi2SetFMUstate (fmi2Component c, fmi2FMUstate  FMUstate)
  {
    return fmi2Error; // not implemented
  }

  fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate)
  {
    return fmi2Error; // not implemented
  }

  fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate,
					size_t *size)
  {
    return fmi2Error; // not implemented
  }

  fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate,
				   fmi2Byte serializedState[], size_t size)
  {
    return fmi2Error; // not implemented
  }

  fmi2Status fmi2DeSerializeFMUstate(fmi2Component c,
				     const fmi2Byte serializedState[],
				     size_t size, fmi2FMUstate* FMUstate)
  {
    return fmi2Error; // not implemented
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
    return fmi2Error; // not implemented
  }

  // ---------------------------------------------------------------------------
  // Types for Functions for FMI2 for Model Exchange
  // ---------------------------------------------------------------------------

  //
  // Enter and exit the different modes
  //

  fmi2Status fmi2EnterEventMode(fmi2Component c)
  {
    return fmi2OK;
  }

  fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo *eventInfo)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->newDiscreteStates(eventInfo);
  }

  fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c)
  {
    return fmi2OK;
  }

  fmi2Status fmi2CompletedIntegratorStep(fmi2Component c,
					 fmi2Boolean noSetFMUStatePriorToCurrentPoint,
					 fmi2Boolean* enterEventMode,
					 fmi2Boolean* terminateSimulation)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->completedIntegratorStep(noSetFMUStatePriorToCurrentPoint,
				   enterEventMode, terminateSimulation);
  }

  //
  // Providing independent variables and re-initialization of caching
  //

  fmi2Status fmi2SetTime(fmi2Component c, fmi2Real time)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setTime(time);
  }

  fmi2Status fmi2SetContinuousStates(fmi2Component c,
				     const fmi2Real x[], size_t nx)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->setContinuousStates(x, nx);
  }

  //
  // Evaluation of the model equations
  //

  fmi2Status fmi2GetDerivatives(fmi2Component c,
				fmi2Real derivatives[], size_t nx)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getDerivatives(derivatives, nx);
  }

  fmi2Status fmi2GetEventIndicators(fmi2Component c,
				    fmi2Real eventIndicators[], size_t ni)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getEventIndicators(eventIndicators, ni);
  }

  fmi2Status fmi2GetContinuousStates(fmi2Component c,
				     fmi2Real states[], size_t nx)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getContinuousStates(states, nx);
  }

  fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c,
					       fmi2Real x_nominal[], size_t nx)
  {
    return reinterpret_cast<FMU2Wrapper*>
      (c)->getNominalsOfContinuousStates(x_nominal, nx);
  }
}
