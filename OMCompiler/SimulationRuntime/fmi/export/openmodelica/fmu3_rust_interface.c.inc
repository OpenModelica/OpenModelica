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

/* The FMI 3.0 API of a C+Rust FMU, which libSimulationRuntimeRust implements
 * (src/fmi3_capi.rs). Defined here so the names follow FMI3_FUNCTION_PREFIX. */

fmi3SetDebugLoggingTYPE omc_fmi3SetDebugLogging;
fmi3InstantiateModelExchangeTYPE omc_fmi3InstantiateModelExchange;
fmi3InstantiateCoSimulationTYPE omc_fmi3InstantiateCoSimulation;
fmi3InstantiateScheduledExecutionTYPE omc_fmi3InstantiateScheduledExecution;
fmi3FreeInstanceTYPE omc_fmi3FreeInstance;
fmi3EnterInitializationModeTYPE omc_fmi3EnterInitializationMode;
fmi3ExitInitializationModeTYPE omc_fmi3ExitInitializationMode;
fmi3EnterEventModeTYPE omc_fmi3EnterEventMode;
fmi3TerminateTYPE omc_fmi3Terminate;
fmi3ResetTYPE omc_fmi3Reset;
fmi3GetFloat32TYPE omc_fmi3GetFloat32;
fmi3GetFloat64TYPE omc_fmi3GetFloat64;
fmi3GetInt8TYPE omc_fmi3GetInt8;
fmi3GetUInt8TYPE omc_fmi3GetUInt8;
fmi3GetInt16TYPE omc_fmi3GetInt16;
fmi3GetUInt16TYPE omc_fmi3GetUInt16;
fmi3GetInt32TYPE omc_fmi3GetInt32;
fmi3GetUInt32TYPE omc_fmi3GetUInt32;
fmi3GetInt64TYPE omc_fmi3GetInt64;
fmi3GetUInt64TYPE omc_fmi3GetUInt64;
fmi3GetBooleanTYPE omc_fmi3GetBoolean;
fmi3GetStringTYPE omc_fmi3GetString;
fmi3GetBinaryTYPE omc_fmi3GetBinary;
fmi3GetClockTYPE omc_fmi3GetClock;
fmi3SetFloat32TYPE omc_fmi3SetFloat32;
fmi3SetFloat64TYPE omc_fmi3SetFloat64;
fmi3SetInt8TYPE omc_fmi3SetInt8;
fmi3SetUInt8TYPE omc_fmi3SetUInt8;
fmi3SetInt16TYPE omc_fmi3SetInt16;
fmi3SetUInt16TYPE omc_fmi3SetUInt16;
fmi3SetInt32TYPE omc_fmi3SetInt32;
fmi3SetUInt32TYPE omc_fmi3SetUInt32;
fmi3SetInt64TYPE omc_fmi3SetInt64;
fmi3SetUInt64TYPE omc_fmi3SetUInt64;
fmi3SetBooleanTYPE omc_fmi3SetBoolean;
fmi3SetStringTYPE omc_fmi3SetString;
fmi3SetBinaryTYPE omc_fmi3SetBinary;
fmi3SetClockTYPE omc_fmi3SetClock;
fmi3GetNumberOfVariableDependenciesTYPE omc_fmi3GetNumberOfVariableDependencies;
fmi3GetVariableDependenciesTYPE omc_fmi3GetVariableDependencies;
fmi3GetFMUStateTYPE omc_fmi3GetFMUState;
fmi3SetFMUStateTYPE omc_fmi3SetFMUState;
fmi3FreeFMUStateTYPE omc_fmi3FreeFMUState;
fmi3SerializedFMUStateSizeTYPE omc_fmi3SerializedFMUStateSize;
fmi3SerializeFMUStateTYPE omc_fmi3SerializeFMUState;
fmi3DeserializeFMUStateTYPE omc_fmi3DeserializeFMUState;
fmi3GetDirectionalDerivativeTYPE omc_fmi3GetDirectionalDerivative;
fmi3GetAdjointDerivativeTYPE omc_fmi3GetAdjointDerivative;
fmi3EnterConfigurationModeTYPE omc_fmi3EnterConfigurationMode;
fmi3ExitConfigurationModeTYPE omc_fmi3ExitConfigurationMode;
fmi3GetIntervalDecimalTYPE omc_fmi3GetIntervalDecimal;
fmi3GetIntervalFractionTYPE omc_fmi3GetIntervalFraction;
fmi3GetShiftDecimalTYPE omc_fmi3GetShiftDecimal;
fmi3GetShiftFractionTYPE omc_fmi3GetShiftFraction;
fmi3SetIntervalDecimalTYPE omc_fmi3SetIntervalDecimal;
fmi3SetIntervalFractionTYPE omc_fmi3SetIntervalFraction;
fmi3SetShiftDecimalTYPE omc_fmi3SetShiftDecimal;
fmi3SetShiftFractionTYPE omc_fmi3SetShiftFraction;
fmi3EvaluateDiscreteStatesTYPE omc_fmi3EvaluateDiscreteStates;
fmi3UpdateDiscreteStatesTYPE omc_fmi3UpdateDiscreteStates;
fmi3EnterContinuousTimeModeTYPE omc_fmi3EnterContinuousTimeMode;
fmi3CompletedIntegratorStepTYPE omc_fmi3CompletedIntegratorStep;
fmi3SetTimeTYPE omc_fmi3SetTime;
fmi3SetContinuousStatesTYPE omc_fmi3SetContinuousStates;
fmi3GetContinuousStateDerivativesTYPE omc_fmi3GetContinuousStateDerivatives;
fmi3GetEventIndicatorsTYPE omc_fmi3GetEventIndicators;
fmi3GetContinuousStatesTYPE omc_fmi3GetContinuousStates;
fmi3GetNominalsOfContinuousStatesTYPE omc_fmi3GetNominalsOfContinuousStates;
fmi3GetNumberOfEventIndicatorsTYPE omc_fmi3GetNumberOfEventIndicators;
fmi3GetNumberOfContinuousStatesTYPE omc_fmi3GetNumberOfContinuousStates;
fmi3EnterStepModeTYPE omc_fmi3EnterStepMode;
fmi3GetOutputDerivativesTYPE omc_fmi3GetOutputDerivatives;
fmi3DoStepTYPE omc_fmi3DoStep;
fmi3ActivateModelPartitionTYPE omc_fmi3ActivateModelPartition;

const char* fmi3GetVersion(void) { return fmi3Version; }

fmi3Status fmi3SetDebugLogging(fmi3Instance instance, fmi3Boolean loggingOn, size_t nCategories, const fmi3String categories[])
{ return omc_fmi3SetDebugLogging(instance, loggingOn, nCategories, categories); }
fmi3Instance fmi3InstantiateModelExchange(fmi3String instanceName, fmi3String instantiationToken, fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn, fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage)
{ return omc_fmi3InstantiateModelExchange(instanceName, instantiationToken, resourcePath, visible, loggingOn, instanceEnvironment, logMessage); }
fmi3Instance fmi3InstantiateCoSimulation(fmi3String instanceName, fmi3String instantiationToken, fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn, fmi3Boolean eventModeUsed, fmi3Boolean earlyReturnAllowed, const fmi3ValueReference requiredIntermediateVariables[], size_t nRequiredIntermediateVariables, fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage, fmi3IntermediateUpdateCallback intermediateUpdate)
{ return omc_fmi3InstantiateCoSimulation(instanceName, instantiationToken, resourcePath, visible, loggingOn, eventModeUsed, earlyReturnAllowed, requiredIntermediateVariables, nRequiredIntermediateVariables, instanceEnvironment, logMessage, intermediateUpdate); }
fmi3Instance fmi3InstantiateScheduledExecution(fmi3String instanceName, fmi3String instantiationToken, fmi3String resourcePath, fmi3Boolean visible, fmi3Boolean loggingOn, fmi3InstanceEnvironment instanceEnvironment, fmi3LogMessageCallback logMessage, fmi3ClockUpdateCallback clockUpdate, fmi3LockPreemptionCallback lockPreemption, fmi3UnlockPreemptionCallback unlockPreemption)
{ return omc_fmi3InstantiateScheduledExecution(instanceName, instantiationToken, resourcePath, visible, loggingOn, instanceEnvironment, logMessage, clockUpdate, lockPreemption, unlockPreemption); }
void fmi3FreeInstance(fmi3Instance instance)
{ omc_fmi3FreeInstance(instance); }
fmi3Status fmi3EnterInitializationMode(fmi3Instance instance, fmi3Boolean toleranceDefined, fmi3Float64 tolerance, fmi3Float64 startTime, fmi3Boolean stopTimeDefined, fmi3Float64 stopTime)
{ return omc_fmi3EnterInitializationMode(instance, toleranceDefined, tolerance, startTime, stopTimeDefined, stopTime); }
fmi3Status fmi3ExitInitializationMode(fmi3Instance instance)
{ return omc_fmi3ExitInitializationMode(instance); }
fmi3Status fmi3EnterEventMode(fmi3Instance instance)
{ return omc_fmi3EnterEventMode(instance); }
fmi3Status fmi3Terminate(fmi3Instance instance)
{ return omc_fmi3Terminate(instance); }
fmi3Status fmi3Reset(fmi3Instance instance)
{ return omc_fmi3Reset(instance); }
fmi3Status fmi3GetFloat32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Float32 values[], size_t nValues)
{ return omc_fmi3GetFloat32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Float64 values[], size_t nValues)
{ return omc_fmi3GetFloat64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetInt8(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Int8 values[], size_t nValues)
{ return omc_fmi3GetInt8(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetUInt8(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt8 values[], size_t nValues)
{ return omc_fmi3GetUInt8(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetInt16(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Int16 values[], size_t nValues)
{ return omc_fmi3GetInt16(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetUInt16(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt16 values[], size_t nValues)
{ return omc_fmi3GetUInt16(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Int32 values[], size_t nValues)
{ return omc_fmi3GetInt32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetUInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt32 values[], size_t nValues)
{ return omc_fmi3GetUInt32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Int64 values[], size_t nValues)
{ return omc_fmi3GetInt64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetUInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt64 values[], size_t nValues)
{ return omc_fmi3GetUInt64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Boolean values[], size_t nValues)
{ return omc_fmi3GetBoolean(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetString(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3String values[], size_t nValues)
{ return omc_fmi3GetString(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3GetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, size_t valueSizes[], fmi3Binary values[], size_t nValues)
{ return omc_fmi3GetBinary(instance, valueReferences, nValueReferences, valueSizes, values, nValues); }
fmi3Status fmi3GetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Clock values[])
{ return omc_fmi3GetClock(instance, valueReferences, nValueReferences, values); }
fmi3Status fmi3SetFloat32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Float32 values[], size_t nValues)
{ return omc_fmi3SetFloat32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetFloat64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Float64 values[], size_t nValues)
{ return omc_fmi3SetFloat64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetInt8(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Int8 values[], size_t nValues)
{ return omc_fmi3SetInt8(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetUInt8(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt8 values[], size_t nValues)
{ return omc_fmi3SetUInt8(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetInt16(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Int16 values[], size_t nValues)
{ return omc_fmi3SetInt16(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetUInt16(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt16 values[], size_t nValues)
{ return omc_fmi3SetUInt16(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Int32 values[], size_t nValues)
{ return omc_fmi3SetInt32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetUInt32(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt32 values[], size_t nValues)
{ return omc_fmi3SetUInt32(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Int64 values[], size_t nValues)
{ return omc_fmi3SetInt64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetUInt64(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt64 values[], size_t nValues)
{ return omc_fmi3SetUInt64(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetBoolean(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Boolean values[], size_t nValues)
{ return omc_fmi3SetBoolean(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetString(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3String values[], size_t nValues)
{ return omc_fmi3SetString(instance, valueReferences, nValueReferences, values, nValues); }
fmi3Status fmi3SetBinary(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const size_t valueSizes[], const fmi3Binary values[], size_t nValues)
{ return omc_fmi3SetBinary(instance, valueReferences, nValueReferences, valueSizes, values, nValues); }
fmi3Status fmi3SetClock(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Clock values[])
{ return omc_fmi3SetClock(instance, valueReferences, nValueReferences, values); }
fmi3Status fmi3GetNumberOfVariableDependencies(fmi3Instance instance, fmi3ValueReference valueReference, size_t* nDependencies)
{ return omc_fmi3GetNumberOfVariableDependencies(instance, valueReference, nDependencies); }
fmi3Status fmi3GetVariableDependencies(fmi3Instance instance, fmi3ValueReference dependent, size_t elementIndicesOfDependent[], fmi3ValueReference independents[], size_t elementIndicesOfIndependents[], fmi3DependencyKind dependencyKinds[], size_t nDependencies)
{ return omc_fmi3GetVariableDependencies(instance, dependent, elementIndicesOfDependent, independents, elementIndicesOfIndependents, dependencyKinds, nDependencies); }
fmi3Status fmi3GetFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{ return omc_fmi3GetFMUState(instance, FMUState); }
fmi3Status fmi3SetFMUState(fmi3Instance instance, fmi3FMUState FMUState)
{ return omc_fmi3SetFMUState(instance, FMUState); }
fmi3Status fmi3FreeFMUState(fmi3Instance instance, fmi3FMUState* FMUState)
{ return omc_fmi3FreeFMUState(instance, FMUState); }
fmi3Status fmi3SerializedFMUStateSize(fmi3Instance instance, fmi3FMUState FMUState, size_t* size)
{ return omc_fmi3SerializedFMUStateSize(instance, FMUState, size); }
fmi3Status fmi3SerializeFMUState(fmi3Instance instance, fmi3FMUState FMUState, fmi3Byte serializedState[], size_t size)
{ return omc_fmi3SerializeFMUState(instance, FMUState, serializedState, size); }
fmi3Status fmi3DeserializeFMUState(fmi3Instance instance, const fmi3Byte serializedState[], size_t size, fmi3FMUState* FMUState)
{ return omc_fmi3DeserializeFMUState(instance, serializedState, size, FMUState); }
fmi3Status fmi3GetDirectionalDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[], size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[], size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{ return omc_fmi3GetDirectionalDerivative(instance, unknowns, nUnknowns, knowns, nKnowns, seed, nSeed, sensitivity, nSensitivity); }
fmi3Status fmi3GetAdjointDerivative(fmi3Instance instance, const fmi3ValueReference unknowns[], size_t nUnknowns, const fmi3ValueReference knowns[], size_t nKnowns, const fmi3Float64 seed[], size_t nSeed, fmi3Float64 sensitivity[], size_t nSensitivity)
{ return omc_fmi3GetAdjointDerivative(instance, unknowns, nUnknowns, knowns, nKnowns, seed, nSeed, sensitivity, nSensitivity); }
fmi3Status fmi3EnterConfigurationMode(fmi3Instance instance)
{ return omc_fmi3EnterConfigurationMode(instance); }
fmi3Status fmi3ExitConfigurationMode(fmi3Instance instance)
{ return omc_fmi3ExitConfigurationMode(instance); }
fmi3Status fmi3GetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Float64 intervals[], fmi3IntervalQualifier qualifiers[])
{ return omc_fmi3GetIntervalDecimal(instance, valueReferences, nValueReferences, intervals, qualifiers); }
fmi3Status fmi3GetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[], fmi3IntervalQualifier qualifiers[])
{ return omc_fmi3GetIntervalFraction(instance, valueReferences, nValueReferences, counters, resolutions, qualifiers); }
fmi3Status fmi3GetShiftDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3Float64 shifts[])
{ return omc_fmi3GetShiftDecimal(instance, valueReferences, nValueReferences, shifts); }
fmi3Status fmi3GetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, fmi3UInt64 counters[], fmi3UInt64 resolutions[])
{ return omc_fmi3GetShiftFraction(instance, valueReferences, nValueReferences, counters, resolutions); }
fmi3Status fmi3SetIntervalDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Float64 intervals[])
{ return omc_fmi3SetIntervalDecimal(instance, valueReferences, nValueReferences, intervals); }
fmi3Status fmi3SetIntervalFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{ return omc_fmi3SetIntervalFraction(instance, valueReferences, nValueReferences, counters, resolutions); }
fmi3Status fmi3SetShiftDecimal(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Float64 shifts[])
{ return omc_fmi3SetShiftDecimal(instance, valueReferences, nValueReferences, shifts); }
fmi3Status fmi3SetShiftFraction(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3UInt64 counters[], const fmi3UInt64 resolutions[])
{ return omc_fmi3SetShiftFraction(instance, valueReferences, nValueReferences, counters, resolutions); }
fmi3Status fmi3EvaluateDiscreteStates(fmi3Instance instance)
{ return omc_fmi3EvaluateDiscreteStates(instance); }
fmi3Status fmi3UpdateDiscreteStates(fmi3Instance instance, fmi3Boolean* discreteStatesNeedUpdate, fmi3Boolean* terminateSimulation, fmi3Boolean* nominalsOfContinuousStatesChanged, fmi3Boolean* valuesOfContinuousStatesChanged, fmi3Boolean* nextEventTimeDefined, fmi3Float64* nextEventTime)
{ return omc_fmi3UpdateDiscreteStates(instance, discreteStatesNeedUpdate, terminateSimulation, nominalsOfContinuousStatesChanged, valuesOfContinuousStatesChanged, nextEventTimeDefined, nextEventTime); }
fmi3Status fmi3EnterContinuousTimeMode(fmi3Instance instance)
{ return omc_fmi3EnterContinuousTimeMode(instance); }
fmi3Status fmi3CompletedIntegratorStep(fmi3Instance instance, fmi3Boolean noSetFMUStatePriorToCurrentPoint, fmi3Boolean* enterEventMode, fmi3Boolean* terminateSimulation)
{ return omc_fmi3CompletedIntegratorStep(instance, noSetFMUStatePriorToCurrentPoint, enterEventMode, terminateSimulation); }
fmi3Status fmi3SetTime(fmi3Instance instance, fmi3Float64 time)
{ return omc_fmi3SetTime(instance, time); }
fmi3Status fmi3SetContinuousStates(fmi3Instance instance, const fmi3Float64 continuousStates[], size_t nContinuousStates)
{ return omc_fmi3SetContinuousStates(instance, continuousStates, nContinuousStates); }
fmi3Status fmi3GetContinuousStateDerivatives(fmi3Instance instance, fmi3Float64 derivatives[], size_t nContinuousStates)
{ return omc_fmi3GetContinuousStateDerivatives(instance, derivatives, nContinuousStates); }
fmi3Status fmi3GetEventIndicators(fmi3Instance instance, fmi3Float64 eventIndicators[], size_t nEventIndicators)
{ return omc_fmi3GetEventIndicators(instance, eventIndicators, nEventIndicators); }
fmi3Status fmi3GetContinuousStates(fmi3Instance instance, fmi3Float64 continuousStates[], size_t nContinuousStates)
{ return omc_fmi3GetContinuousStates(instance, continuousStates, nContinuousStates); }
fmi3Status fmi3GetNominalsOfContinuousStates(fmi3Instance instance, fmi3Float64 nominals[], size_t nContinuousStates)
{ return omc_fmi3GetNominalsOfContinuousStates(instance, nominals, nContinuousStates); }
fmi3Status fmi3GetNumberOfEventIndicators(fmi3Instance instance, size_t* nEventIndicators)
{ return omc_fmi3GetNumberOfEventIndicators(instance, nEventIndicators); }
fmi3Status fmi3GetNumberOfContinuousStates(fmi3Instance instance, size_t* nContinuousStates)
{ return omc_fmi3GetNumberOfContinuousStates(instance, nContinuousStates); }
fmi3Status fmi3EnterStepMode(fmi3Instance instance)
{ return omc_fmi3EnterStepMode(instance); }
fmi3Status fmi3GetOutputDerivatives(fmi3Instance instance, const fmi3ValueReference valueReferences[], size_t nValueReferences, const fmi3Int32 orders[], fmi3Float64 values[], size_t nValues)
{ return omc_fmi3GetOutputDerivatives(instance, valueReferences, nValueReferences, orders, values, nValues); }
fmi3Status fmi3DoStep(fmi3Instance instance, fmi3Float64 currentCommunicationPoint, fmi3Float64 communicationStepSize, fmi3Boolean noSetFMUStatePriorToCurrentPoint, fmi3Boolean* eventHandlingNeeded, fmi3Boolean* terminateSimulation, fmi3Boolean* earlyReturn, fmi3Float64* lastSuccessfulTime)
{ return omc_fmi3DoStep(instance, currentCommunicationPoint, communicationStepSize, noSetFMUStatePriorToCurrentPoint, eventHandlingNeeded, terminateSimulation, earlyReturn, lastSuccessfulTime); }
fmi3Status fmi3ActivateModelPartition(fmi3Instance instance, fmi3ValueReference clockReference, fmi3Float64 activationTime)
{ return omc_fmi3ActivateModelPartition(instance, clockReference, activationTime); }
