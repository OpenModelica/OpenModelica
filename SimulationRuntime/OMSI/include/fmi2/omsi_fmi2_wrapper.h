/*
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

/*
 * ToDo: insert description
 */


#ifndef OSI_FMI2_WRAPPER_H
#define OSI_FMI2_WRAPPER_H

/* FMI2 interface */
#include <fmi2Functions.h>
#include <fmi2FunctionTypes.h>
#include <fmi2TypesPlatform.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function prototypes */
FMI2_Export const char* fmi2GetTypesPlatform(void);
FMI2_Export const char* fmi2GetVersion(void);
FMI2_Export fmi2Status fmi2SetDebugLogging(fmi2Component c,fmi2Boolean loggingOn,size_t  nCategories,const fmi2String categories[]);
FMI2_Export fmi2Component fmi2Instantiate(fmi2String instanceName,fmi2Type   fmuType,fmi2String fmuGUID,fmi2String fmuResourceLocation,const fmi2CallbackFunctions* functions, fmi2Boolean visible,fmi2Boolean loggingOn);
FMI2_Export void fmi2FreeInstance(fmi2Component c);
FMI2_Export fmi2Status fmi2SetupExperiment(fmi2Component c, fmi2Boolean toleranceDefined,fmi2Real tolerance, fmi2Real tartTime, fmi2Boolean stopTimeDefined, fmi2Real stopTime);
FMI2_Export fmi2Status fmi2EnterInitializationMode(fmi2Component c);
FMI2_Export fmi2Status fmi2ExitInitializationMode(fmi2Component c);
FMI2_Export fmi2Status fmi2Terminate(fmi2Component c);
FMI2_Export fmi2Status fmi2Reset(fmi2Component c);
FMI2_Export fmi2Status fmi2GetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, fmi2Real value[]);
FMI2_Export fmi2Status fmi2GetInteger(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2Integer value[]);
FMI2_Export fmi2Status fmi2GetBoolean(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2Boolean value[]);
FMI2_Export fmi2Status fmi2GetString(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, fmi2String value[]);
FMI2_Export fmi2Status fmi2SetReal(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2Real value[]);
FMI2_Export fmi2Status fmi2SetInteger(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, const fmi2Integer value[]);
FMI2_Export fmi2Status fmi2SetBoolean(fmi2Component c, const fmi2ValueReference vr[],size_t nvr, const fmi2Boolean value[]);
FMI2_Export fmi2Status fmi2SetString(fmi2Component c, const fmi2ValueReference vr[], size_t nvr, const fmi2String value[]);
FMI2_Export fmi2Status fmi2GetFMUstate(fmi2Component c, fmi2FMUstate* FMUstate);
FMI2_Export fmi2Status fmi2SetFMUstate(fmi2Component c, fmi2FMUstate FMUstate);
FMI2_Export fmi2Status fmi2FreeFMUstate(fmi2Component c, fmi2FMUstate* FMUstate);
FMI2_Export fmi2Status fmi2SerializedFMUstateSize(fmi2Component c, fmi2FMUstate FMUstate,size_t* size);
FMI2_Export fmi2Status fmi2SerializeFMUstate(fmi2Component c, fmi2FMUstate FMUstate,fmi2Byte serializedState[], size_t size);
FMI2_Export fmi2Status fmi2DeSerializeFMUstate(fmi2Component c, const fmi2Byte serializedState[],size_t size, fmi2FMUstate* FMUstate);
FMI2_Export fmi2Status fmi2GetDirectionalDerivative(fmi2Component c,const fmi2ValueReference vUnknown_ref[], size_t nUnknown,const fmi2ValueReference vKnown_ref[],   size_t nKnown, const fmi2Real dvKnown[], fmi2Real dvUnknown[]);
FMI2_Export fmi2Status fmi2EnterEventMode(fmi2Component c);
FMI2_Export fmi2Status fmi2NewDiscreteStates(fmi2Component c, fmi2EventInfo* fmiEventInfo);
FMI2_Export fmi2Status fmi2EnterContinuousTimeMode(fmi2Component c);
FMI2_Export fmi2Status fmi2CompletedIntegratorStep(fmi2Component c,fmi2Boolean   noSetFMUStatePriorToCurrentPoint, fmi2Boolean*  enterEventMode, fmi2Boolean*   terminateSimulation);
FMI2_Export fmi2Status fmi2SetTime(fmi2Component c, fmi2Real time);
FMI2_Export fmi2Status fmi2SetContinuousStates(fmi2Component c, const fmi2Real x[],size_t nx);
FMI2_Export fmi2Status fmi2GetDerivatives(fmi2Component c, fmi2Real derivatives[], size_t nx);
FMI2_Export fmi2Status fmi2GetEventIndicators(fmi2Component c, fmi2Real eventIndicators[], size_t ni);
FMI2_Export fmi2Status fmi2GetContinuousStates(fmi2Component c, fmi2Real x[],size_t nx);
FMI2_Export fmi2Status fmi2GetNominalsOfContinuousStates(fmi2Component c,fmi2Real x_nominal[],size_t nx);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
