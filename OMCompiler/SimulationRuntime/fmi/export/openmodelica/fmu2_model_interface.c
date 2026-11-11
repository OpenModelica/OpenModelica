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

#include <math.h>

#include "fmu2_model_interface.h"
#include "../simulation/arrayIndex.h"
#include "../simulation/solver/initialization/initialization.h"
#include "../simulation/solver/stateset.h"
#include "../simulation/solver/model_help.h"
#ifdef OMC_FMI_CO_SIMULATION
#include "../simulation/solver/cvode_solver.h"
#endif
#ifdef OMC_FMI_DAE_MODE
#include "../simulation/solver/dae_mode.h"
#endif
#ifdef OMC_FMI_HAVE_IDA
#include "../simulation/solver/ida_solver.h"
#endif
#if !defined(OMC_NUM_NONLINEAR_SYSTEMS) || OMC_NUM_NONLINEAR_SYSTEMS>0
#include "../simulation/solver/nonlinearSystem.h"
#endif
#if !defined(OMC_NUM_LINEAR_SYSTEMS) || OMC_NUM_LINEAR_SYSTEMS>0
#include "../simulation/solver/linearSystem.h"
#endif
#if !defined(OMC_NUM_MIXED_SYSTEMS) || OMC_NUM_MIXED_SYSTEMS>0
#include "../simulation/solver/mixedSystem.h"
#endif
#include "../simulation/solver/delay.h"
#include "../simulation/solver/spatialDistribution.h"
#include "../simulation/solver/discrete_changes.h"
#include "../simulation/solver/epsilon.h"
#include "../simulation/solver/events.h"
#include "../simulation/simulation_info_json.h"
#include "../simulation/simulation_input_xml.h"
#include "../simulation/solver/synchronous.h"
#include "../simulation/options.h"
#include "../util/simulation_options.h"
#include "../util/omc_error.h"

#include <math.h>

#include "fmu2_dummy_model_defines.h" // get's replaced in SimCodeMain.mo

/*
DLLExport pthread_key_t fmu2_thread_data_key;
*/

// array of value references of states
#if NUMBER_OF_STATES > 0
fmi2ValueReference vrStates[NUMBER_OF_STATES] = STATES;
fmi2ValueReference vrStatesDerivatives[NUMBER_OF_STATES] = STATESDERIVATIVES;
#endif

#define OMC_FMI_VERSION 2
typedef fmi2Status fmiXStatus;
typedef fmi2Component fmiXComponent;
typedef fmi2Real fmiXReal;
typedef fmi2Integer fmiXInteger;
typedef fmi2Boolean fmiXBoolean;
typedef fmi2String fmiXString;
typedef fmi2Byte fmiXByte;
typedef fmi2ValueReference fmiXValueReference;
typedef fmi2FMUstate fmiXFMUstate;
typedef fmi2EventInfo fmiXEventInfo;
#define fmiXOK fmi2OK
#define fmiXWarning fmi2Warning
#define fmiXDiscard fmi2Discard
#define fmiXError fmi2Error
#define fmiXFatal fmi2Fatal
#define fmiXTrue fmi2True
#define fmiXFalse fmi2False
#define FMIX(name) fmi2##name
#define FMIX_STR "fmi2"
#define FMIX_ME fmi2ModelExchange
#define FMIX_CS fmi2CoSimulation
#define LOG_FMIX_CALL LOG_FMI2_CALL
#define FMIX_SETUP_DATA_STRUC fmu2_model_interface_setupDataStruc

#include "fmu_model_interface.c.inc"

const char* fmi2GetTypesPlatform()
{
  return fmi2TypesPlatform;
}

const char* fmi2GetVersion()
{
  return fmi2Version;
}

/**
 * @brief FMI 2 doStep function.
 *
 * Compute time step to next communication point with explicit Euler or CVODE.
 *
 * @param c                                   FMU component.
 * @param currentCommunicationPoint           Current communication point of master algorithm.
 * @param communicationStepSize               Communication step size.
 * @param noSetFMUStatePriorToCurrentPoint    Unused.
 * @return fmi2Status                         Returns fmi2OK if communication point was reached successfully.
 *                                            Returns fmi2Error if something went wrong.
 */
fmi2Status fmi2DoStep(fmi2Component c, fmi2Real currentCommunicationPoint, fmi2Real communicationStepSize, fmi2Boolean noSetFMUStatePriorToCurrentPoint)
{
#ifndef OMC_FMI_CO_SIMULATION
  return unsupportedFunction((ModelInstance *)c, "fmi2DoStep");
#else
  ModelInstance *comp = (ModelInstance *)c;
  fmi2Boolean terminateSimulation = fmi2False;
  fmi2Status status;

  if (invalidState(comp, "fmi2DoStep", 0, model_state_cs_step_complete))
    return fmi2Error;

  status = doStepInternal(comp, currentCommunicationPoint, communicationStepSize, noSetFMUStatePriorToCurrentPoint,
                          fmi2False, fmi2False, NULL, &terminateSimulation, NULL, NULL);

  comp->lastSuccessfulTime = comp->fmuData->localData[0]->timeValue;
  /* FMI 2.0, 4.2.3: a slave that wants to stop returns fmi2Discard and reports
     the reason through fmi2GetBooleanStatus(fmi2Terminated). */
  if (terminateSimulation && status <= fmi2Warning) {
    comp->terminated = fmi2True;
    comp->state = model_state_cs_step_failed;
    status = fmi2Discard;
    FILTERED_LOG(comp, fmi2Discard, LOG_STATUSDISCARD, "fmi2DoStep: the model terminated the simulation at time %.15g.", comp->lastSuccessfulTime)
  }

  return status;
#endif
}

fmi2Status fmi2CancelStep(fmi2Component c)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2CancelStep");
}

fmi2Status fmi2GetStatus(fmi2Component c, const fmi2StatusKind s, fmi2Status* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetStatus");
}

#define CS_STATUS_STATES (model_state_cs_step_complete|model_state_cs_step_in_progress|model_state_cs_step_failed|model_state_terminated)

fmi2Status fmi2GetRealStatus(fmi2Component c, const fmi2StatusKind s, fmi2Real* value)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetRealStatus", 0, CS_STATUS_STATES) || nullPointer(comp, "fmi2GetRealStatus", "value", value))
    return fmi2Error;
  if (s != fmi2LastSuccessfulTime) {
    FILTERED_LOG(comp, fmi2Discard, LOG_STATUSDISCARD, "fmi2GetRealStatus: status kind %d is not supported.", (int)s)
    return fmi2Discard;
  }
  *value = comp->lastSuccessfulTime;
  return fmi2OK;
}

fmi2Status fmi2GetIntegerStatus(fmi2Component c, const fmi2StatusKind s, fmi2Integer* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetIntegerStatus");
}

fmi2Status fmi2GetBooleanStatus(fmi2Component c, const fmi2StatusKind s, fmi2Boolean* value)
{
  ModelInstance *comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2GetBooleanStatus", 0, CS_STATUS_STATES) || nullPointer(comp, "fmi2GetBooleanStatus", "value", value))
    return fmi2Error;
  if (s != fmi2Terminated) {
    FILTERED_LOG(comp, fmi2Discard, LOG_STATUSDISCARD, "fmi2GetBooleanStatus: status kind %d is not supported.", (int)s)
    return fmi2Discard;
  }
  *value = comp->terminated;
  return fmi2OK;
}

fmi2Status fmi2GetStringStatus(fmi2Component c, const fmi2StatusKind s, fmi2String* value)
{
  // TODO Write code here
  return unsupportedFunction((ModelInstance *)c, "fmi2GetStringStatus");
}

// ---------------------------------------------------------------------------
// FMI functions: set external functions
// ---------------------------------------------------------------------------

fmi2Status fmi2SetExternalFunction(fmi2Component c, fmi2ValueReference vr[], size_t nvr, const void* value[])
{
  unsigned int i=0;
  ModelInstance* comp = (ModelInstance *)c;
  if (invalidState(comp, "fmi2SetExternalFunction", model_state_instantiated, ~0))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "vr[]", vr))
    return fmi2Error;
  if (nvr>0 && nullPointer(comp, "fmi2SetExternalFunction", "value[]", value))
    return fmi2Error;
  FILTERED_LOG(comp, fmi2OK, LOG_FMI2_CALL, "fmi2SetExternalFunction")
  // no check whether setting the value is allowed in the current state
  for (i=0; i<nvr; i++) {
    if (vrOutOfRange(comp, "fmi2SetExternalFunction", vr[i], NUMBER_OF_EXTERNALFUNCTIONS))
      return fmi2Error;
    if (setExternalFunction(comp, vr[i],value[i]) != fmi2OK) // to be implemented by the includer of this file
      return fmi2Error;
  }
  return fmi2OK;
}
