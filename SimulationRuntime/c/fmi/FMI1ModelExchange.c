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

#ifdef __cplusplus
extern "C" {
#endif

#include <stdlib.h>

#include "fmilib.h"

/*
 * Wrapper for the FMI function fmiInstantiateModel.
 */
double fmi1InstantiateModel_OMC(void* fmi, char* instanceName, int debugLogging)
{
  static int init = 0;
  if (!init) {
    init = 1;
    fmi1_import_instantiate_model((fmi1_import_t*)fmi, instanceName);
    fmi1_import_set_debug_logging((fmi1_import_t*)fmi, debugLogging);
  }
  return 1;
}

/*
 * Wrapper for the FMI function fmiSetTime.
 * Returns status.
 */
double fmi1SetTime_OMC(void* fmi, double time)
{
  fmi1_import_set_time((fmi1_import_t*)fmi, time);
  return time;
}

/*
 * Wrapper for the FMI function fmiInitialize.
 * Returns FMI Event Info i.e fmi1_event_info_t.
 */
void* fmi1Initialize_OMC(void* fmi, void* inEventInfo)
{
  static int init = 0;
  if (!init) {
    init = 1;
    fmi1_boolean_t toleranceControlled = fmi1_true;
    fmi1_real_t relativeTolerance = 0.001;
    fmi1_event_info_t* eventInfo = malloc(sizeof(fmi1_event_info_t));
    fmi1_import_initialize((fmi1_import_t*)fmi, toleranceControlled, relativeTolerance, eventInfo);
    return eventInfo;
  }
  return inEventInfo;
}

/*
 * Wrapper for the FMI function fmiGetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi1GetContinuousStates_OMC(void* fmi, int numberOfContinuousStates, double flowParams, double* states)
{
  fmi1_import_get_continuous_states((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
}

/*
 * Wrapper for the FMI function fmiSetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns status.
 */
double fmi1SetContinuousStates_OMC(void* fmi, int numberOfContinuousStates, double flowParams, double* states)
{
  fmi1_import_set_continuous_states((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
  return flowParams;
}

/*
 * Wrapper for the FMI function fmiGetEventIndicators.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns events.
 */
void fmi1GetEventIndicators_OMC(void* fmi, int numberOfEventIndicators, double flowStates, double* events)
{
  fmi1_import_get_event_indicators((fmi1_import_t*)fmi, (fmi1_real_t*)events, numberOfEventIndicators);
}

/*
 * Wrapper for the FMI function fmiGetDerivatives.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi1GetDerivatives_OMC(void* fmi, int numberOfContinuousStates, double flowStates, double* states)
{
  fmi1_import_get_derivatives((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI Event Info i.e fmi1_event_info_t
 */
int fmi1EventUpdate_OMC(void* fmi, int intermediateResults, void* eventInfo, double flowStates)
{
  fmi1_event_info_t* e = (fmi1_event_info_t*)eventInfo;
  fmi1_import_eventUpdate((fmi1_import_t*)fmi, intermediateResults, e);
  return e->stateValuesChanged;
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI EventInfo nextEventTime
 */
double fmi1nextEventTime_OMC(void* fmi, void* eventInfo, double flowStates)
{
  fmi1_event_info_t* e = (fmi1_event_info_t*)eventInfo;
  return e->nextEventTime;
}

/*
 * Wrapper for the FMI function fmiCompletedIntegratorStep.
 */
int fmi1CompletedIntegratorStep_OMC(void* fmi, double flowStates)
{
  fmi1_boolean_t callEventUpdate = fmi1_false;
  fmi1_import_completed_integrator_step((fmi1_import_t*)fmi, &callEventUpdate);
  return callEventUpdate;
}

/*
 * Wrapper for the FMI function fmiTerminate.
 */
int fmi1Terminate_OMC(void* fmi)
{
//  fmi1_status_t fmistatus = fmi1_import_terminate((fmi1_import_t*)fmi);
//  return fmistatus;
  return 0;
}

#ifdef __cplusplus
}
#endif
