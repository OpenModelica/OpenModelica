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

#include "FMICommon.h"
#include "FMI2Common.h"

void* FMI2ModelExchangeConstructor_OMC(int fmi_log_level, char* working_directory, char* instanceName, int debugLogging)
{
  FMI2ModelExchange* FMI2ME = malloc(sizeof(FMI2ModelExchange));
  FMI2ME->FMILogLevel = fmi_log_level;
  /* JM callbacks */
  FMI2ME->JMCallbacks.malloc = malloc;
  FMI2ME->JMCallbacks.calloc = calloc;
  FMI2ME->JMCallbacks.realloc = realloc;
  FMI2ME->JMCallbacks.free = free;
  FMI2ME->JMCallbacks.logger = importlogger;
  FMI2ME->JMCallbacks.log_level = FMI2ME->FMILogLevel;
  FMI2ME->JMCallbacks.context = 0;
  FMI2ME->FMIImportContext = fmi_import_allocate_context(&FMI2ME->JMCallbacks);
  /* FMI callback functions */
  FMI2ME->FMICallbackFunctions.logger = fmi2logger;
  FMI2ME->FMICallbackFunctions.allocateMemory = calloc;
  FMI2ME->FMICallbackFunctions.freeMemory = free;
  /* parse the xml file */
  FMI2ME->FMIWorkingDirectory = (char*) malloc(strlen(working_directory)+1);
  strcpy(FMI2ME->FMIWorkingDirectory, working_directory);
  FMI2ME->FMIImportInstance = fmi2_import_parse_xml(FMI2ME->FMIImportContext, FMI2ME->FMIWorkingDirectory, NULL);
  if(!FMI2ME->FMIImportInstance) {
    fprintf(stderr, "Error parsing the XML file contained in %s\n", FMI2ME->FMIWorkingDirectory);
    return 0;
  }
  /* Load the binary (dll/so) */
  jm_status_enu_t status;
  status = fmi2_import_create_dllfmu(FMI2ME->FMIImportInstance, fmi2_import_get_fmu_kind(FMI2ME->FMIImportInstance), &FMI2ME->FMICallbackFunctions);
  if (status == jm_status_error) {
    fprintf(stderr, "Could not create the DLL loading mechanism(C-API).\n");
    return 0;
  }
  FMI2ME->FMIInstanceName = (char*) malloc(strlen(instanceName)+1);
  strcpy(FMI2ME->FMIInstanceName, instanceName);
  FMI2ME->FMIDebugLogging = debugLogging;
  fmi2_import_instantiate_model(FMI2ME->FMIImportInstance, FMI2ME->FMIInstanceName, NULL, fmi2_false);
  fmi2_import_set_debug_logging(FMI2ME->FMIImportInstance, FMI2ME->FMIDebugLogging, 0, NULL);
  FMI2ME->FMIToleranceControlled = fmi2_true;
  FMI2ME->FMIRelativeTolerance = 0.001;
  FMI2ME->FMIEventInfo = malloc(sizeof(fmi2_event_info_t));
  fmi2_import_initialize_model(FMI2ME->FMIImportInstance, FMI2ME->FMIToleranceControlled, FMI2ME->FMIRelativeTolerance, FMI2ME->FMIEventInfo);
  return FMI2ME;
}

void FMI2ModelExchangeDestructor_OMC(void* in_fmi2me)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_terminate(FMI2ME->FMIImportInstance);
  fmi2_import_free_model_instance(FMI2ME->FMIImportInstance);
  fmi2_import_destroy_dllfmu(FMI2ME->FMIImportInstance);
  fmi2_import_free(FMI2ME->FMIImportInstance);
  fmi_import_free_context(FMI2ME->FMIImportContext);
  free(FMI2ME->FMIWorkingDirectory);
  free(FMI2ME->FMIInstanceName);
  free(FMI2ME->FMIEventInfo);
}

/*
 * Wrapper for the FMI function fmiSetTime.
 * Returns status.
 */
double fmi2SetTime_OMC(void* in_fmi2me, double time)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_set_time(FMI2ME->FMIImportInstance, time);
  return time;
}

/*
 * Wrapper for the FMI function fmiGetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi2GetContinuousStates_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_get_continuous_states(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
}

/*
 * Wrapper for the FMI function fmiSetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns status.
 */
double fmi2SetContinuousStates_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_set_continuous_states(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
  return flowParams;
}

/*
 * Wrapper for the FMI function fmiGetEventIndicators.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns events.
 */
void fmi2GetEventIndicators_OMC(void* in_fmi2me, int numberOfEventIndicators, double flowStates, double* events)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_get_event_indicators(FMI2ME->FMIImportInstance, (fmi2_real_t*)events, numberOfEventIndicators);
}

/*
 * Wrapper for the FMI function fmiGetDerivatives.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi2GetDerivatives_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowStates, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_get_derivatives(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI Event Info i.e fmi2_event_info_t
 */
int fmi2EventUpdate_OMC(void* in_fmi2me, int intermediateResults, double flowStates)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_eventUpdate(FMI2ME->FMIImportInstance, intermediateResults, FMI2ME->FMIEventInfo);
  return FMI2ME->FMIEventInfo->stateValuesChanged;
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI EventInfo nextEventTime
 */
double fmi2nextEventTime_OMC(void* in_fmi2me, double flowStates)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  return FMI2ME->FMIEventInfo->nextEventTime;
}

/*
 * Wrapper for the FMI function fmiCompletedIntegratorStep.
 */
int fmi2CompletedIntegratorStep_OMC(void* in_fmi2me, double flowStates)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_boolean_t callEventUpdate = fmi2_false;
  fmi2_import_completed_integrator_step(FMI2ME->FMIImportInstance, &callEventUpdate);
  return callEventUpdate;
}

#ifdef __cplusplus
}
#endif
