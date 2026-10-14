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

/* The FMI 2.0 API of a C+Rust FMU, which libSimulationRuntimeRust implements
 * (src/fmi2_capi.rs). Defined here so the names follow FMI2_FUNCTION_PREFIX. */

fmi2SetDebugLoggingTYPE omc_fmi2SetDebugLogging;
fmi2InstantiateTYPE omc_fmi2Instantiate;
fmi2FreeInstanceTYPE omc_fmi2FreeInstance;
fmi2SetupExperimentTYPE omc_fmi2SetupExperiment;
fmi2EnterInitializationModeTYPE omc_fmi2EnterInitializationMode;
fmi2ExitInitializationModeTYPE omc_fmi2ExitInitializationMode;
fmi2TerminateTYPE omc_fmi2Terminate;
fmi2ResetTYPE omc_fmi2Reset;
fmi2GetRealTYPE omc_fmi2GetReal;
fmi2GetIntegerTYPE omc_fmi2GetInteger;
fmi2GetBooleanTYPE omc_fmi2GetBoolean;
fmi2GetStringTYPE omc_fmi2GetString;
fmi2SetRealTYPE omc_fmi2SetReal;
fmi2SetIntegerTYPE omc_fmi2SetInteger;
fmi2SetBooleanTYPE omc_fmi2SetBoolean;
fmi2SetStringTYPE omc_fmi2SetString;
fmi2GetFMUstateTYPE omc_fmi2GetFMUstate;
fmi2SetFMUstateTYPE omc_fmi2SetFMUstate;
fmi2FreeFMUstateTYPE omc_fmi2FreeFMUstate;
fmi2SerializedFMUstateSizeTYPE omc_fmi2SerializedFMUstateSize;
fmi2SerializeFMUstateTYPE omc_fmi2SerializeFMUstate;
fmi2DeSerializeFMUstateTYPE omc_fmi2DeSerializeFMUstate;
fmi2GetDirectionalDerivativeTYPE omc_fmi2GetDirectionalDerivative;
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
fmi2SetRealInputDerivativesTYPE omc_fmi2SetRealInputDerivatives;
fmi2GetRealOutputDerivativesTYPE omc_fmi2GetRealOutputDerivatives;
fmi2DoStepTYPE omc_fmi2DoStep;
fmi2CancelStepTYPE omc_fmi2CancelStep;
fmi2GetStatusTYPE omc_fmi2GetStatus;
fmi2GetRealStatusTYPE omc_fmi2GetRealStatus;
fmi2GetIntegerStatusTYPE omc_fmi2GetIntegerStatus;
fmi2GetBooleanStatusTYPE omc_fmi2GetBooleanStatus;
fmi2GetStringStatusTYPE omc_fmi2GetStringStatus;

const char* fmi2GetTypesPlatform(void) { return fmi2TypesPlatform; }
const char* fmi2GetVersion(void) { return fmi2Version; }

fmi2Status fmi2SetDebugLogging(fmi2Component c, fmi2Boolean loggingOn, size_t nCategories, const fmi2String categories[])
{ return omc_fmi2SetDebugLogging(c, loggingOn, nCategories, categories); }

fmi2Component fmi2Instantiate(fmi2String instanceName, fmi2Type fmuType, fmi2String fmuGUID, fmi2String fmuResourceLocation,
                              const fmi2CallbackFunctions* functions, fmi2Boolean visible, fmi2Boolean loggingOn)
{ return omc_fmi2Instantiate(instanceName, fmuType, fmuGUID, fmuResourceLocation, functions, visible, loggingOn); }

void fmi2FreeInstance(fmi2Component c) { omc_fmi2FreeInstance(c); }

fmi2Status fmi2SetupExperiment(fmi2Component c, fmi2Boolean toleranceDefined, fmi2Real tolerance, fmi2Real startTime,
                               fmi2Boolean stopTimeDefined, fmi2Real stopTime)
{ return omc_fmi2SetupExperiment(c, toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime); }

fmi2Status fmi2EnterInitializationMode(fmi2Component c) { return omc_fmi2EnterInitializationMode(c); }
fmi2Status fmi2ExitInitializationMode(fmi2Component c) { return omc_fmi2ExitInitializationMode(c); }
fmi2Status fmi2Terminate(fmi2Component c) { return omc_fmi2Terminate(c); }
fmi2Status fmi2Reset(fmi2Component c) { return omc_fmi2Reset(c); }

fmi2Status fmi2GetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Real value[])
{ return omc_fmi2GetReal(c, vr, nvr, value); }
fmi2Status fmi2GetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Integer value[])
{ return omc_fmi2GetInteger(c, vr, nvr, value); }
fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Boolean value[])
{ return omc_fmi2GetBoolean(c, vr, nvr, value); }
fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2String value[])
{ return omc_fmi2GetString(c, vr, nvr, value); }
fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real value[])
{ return omc_fmi2SetReal(c, vr, nvr, value); }
fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Integer value[])
{ return omc_fmi2SetInteger(c, vr, nvr, value); }
fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Boolean value[])
{ return omc_fmi2SetBoolean(c, vr, nvr, value); }
fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String value[])
{ return omc_fmi2SetString(c, vr, nvr, value); }

fmi2Status fmi2GetFMUstate(fmi2Component c, fmi2FMUstate* FMUstate) { return omc_fmi2GetFMUstate(c, FMUstate); }
fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate FMUstate) { return omc_fmi2SetFMUstate(c, FMUstate); }
fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate) { return omc_fmi2FreeFMUstate(c, FMUstate); }
fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate, size_t* size)
{ return omc_fmi2SerializedFMUstateSize(c, FMUstate, size); }
fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate, fmi2Byte serializedState[], size_t size)
{ return omc_fmi2SerializeFMUstate(c, FMUstate, serializedState, size); }
fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte serializedState[], size_t size, fmi2FMUstate* FMUstate)
{ return omc_fmi2DeSerializeFMUstate(c, serializedState, size, FMUstate); }

fmi2Status fmi2GetDirectionalDerivative(fmi2Component c, const fmi2ValueReference vUnknown_ref[], size_t nUnknown,
                                        const fmi2ValueReference vKnown_ref[], size_t nKnown,
                                        const fmi2Real dvKnown[], fmi2Real dvUnknown[])
{ return omc_fmi2GetDirectionalDerivative(c, vUnknown_ref, nUnknown, vKnown_ref, nKnown, dvKnown, dvUnknown); }

fmi2Status fmi2EnterEventMode(fmi2Component c) { return omc_fmi2EnterEventMode(c); }
fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo* fmi2eventInfo) { return omc_fmi2NewDiscreteStates(c, fmi2eventInfo); }
fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c) { return omc_fmi2EnterContinuousTimeMode(c); }
fmi2Status fmi2CompletedIntegratorStep(fmi2Component c, fmi2Boolean noSetFMUStatePriorToCurrentPoint,
                                       fmi2Boolean* enterEventMode, fmi2Boolean* terminateSimulation)
{ return omc_fmi2CompletedIntegratorStep(c, noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation); }
fmi2Status fmi2SetTime(fmi2Component c, fmi2Real time) { return omc_fmi2SetTime(c, time); }
fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real x[], size_t nx) { return omc_fmi2SetContinuousStates(c, x, nx); }
fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx) { return omc_fmi2GetDerivatives(c, derivatives, nx); }
fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t ni)
{ return omc_fmi2GetEventIndicators(c, eventIndicators, ni); }
fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real x[], size_t nx) { return omc_fmi2GetContinuousStates(c, x, nx); }
fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c, fmi2Real x_nominal[], size_t nx)
{ return omc_fmi2GetNominalsOfContinuousStates(c, x_nominal, nx); }

fmi2Status fmi2SetRealInputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr,
                                       const fmi2Integer order[], const fmi2Real value[])
{ return omc_fmi2SetRealInputDerivatives(c, vr, nvr, order, value); }
fmi2Status fmi2GetRealOutputDerivatives(fmi2Component c, const fmi2ValueReference vr[], size_t nvr,
                                        const fmi2Integer order[], fmi2Real value[])
{ return omc_fmi2GetRealOutputDerivatives(c, vr, nvr, order, value); }
fmi2Status fmi2DoStep(fmi2Component c, fmi2Real currentCommunicationPoint, fmi2Real communicationStepSize,
                      fmi2Boolean noSetFMUStatePriorToCurrentPoint)
{ return omc_fmi2DoStep(c, currentCommunicationPoint, communicationStepSize, noSetFMUStatePriorToCurrentPoint); }
fmi2Status fmi2CancelStep(fmi2Component c) { return omc_fmi2CancelStep(c); }
fmi2Status fmi2GetStatus(fmi2Component c, const fmi2StatusKind s, fmi2Status* value) { return omc_fmi2GetStatus(c, s, value); }
fmi2Status fmi2GetRealStatus(fmi2Component c, const fmi2StatusKind s, fmi2Real* value) { return omc_fmi2GetRealStatus(c, s, value); }
fmi2Status fmi2GetIntegerStatus(fmi2Component c, const fmi2StatusKind s, fmi2Integer* value)
{ return omc_fmi2GetIntegerStatus(c, s, value); }
fmi2Status fmi2GetBooleanStatus(fmi2Component c, const fmi2StatusKind s, fmi2Boolean* value)
{ return omc_fmi2GetBooleanStatus(c, s, value); }
fmi2Status fmi2GetStringStatus(fmi2Component c, const fmi2StatusKind s, fmi2String* value)
{ return omc_fmi2GetStringStatus(c, s, value); }
