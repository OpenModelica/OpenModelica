/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#ifdef __cplusplus
extern "C" {
#endif

#include "FMICommon.h"
#include "FMI1Common.h"

/*
 * FMI version 1.0 ModelExchange functions
 */

void* FMI1ModelExchangeConstructor_OMC(int fmi_log_level, char* working_directory, char* instanceName, int debugLogging)
{
  FMI1ModelExchange* FMI1ME = malloc(sizeof(FMI1ModelExchange));
  jm_status_enu_t status, instantiateModelStatus;
  fmi1_status_t debugLoggingStatus;
  FMI1ME->FMILogLevel = fmi_log_level;
  /* JM callbacks */
  FMI1ME->JMCallbacks.malloc = malloc;
  FMI1ME->JMCallbacks.calloc = calloc;
  FMI1ME->JMCallbacks.realloc = realloc;
  FMI1ME->JMCallbacks.free = free;
  FMI1ME->JMCallbacks.logger = importlogger;
  FMI1ME->JMCallbacks.log_level = FMI1ME->FMILogLevel;
  FMI1ME->JMCallbacks.context = 0;
  FMI1ME->FMIImportContext = fmi_import_allocate_context(&FMI1ME->JMCallbacks);
  /* FMI callback functions */
  FMI1ME->FMICallbackFunctions.logger = fmi1logger;
  FMI1ME->FMICallbackFunctions.allocateMemory = calloc;
  FMI1ME->FMICallbackFunctions.freeMemory = free;
  /* parse the xml file */
  FMI1ME->FMIWorkingDirectory = (char*) malloc(strlen(working_directory)+1);
  strcpy(FMI1ME->FMIWorkingDirectory, working_directory);
  FMI1ME->FMIImportInstance = fmi1_import_parse_xml(FMI1ME->FMIImportContext, FMI1ME->FMIWorkingDirectory);
  if(!FMI1ME->FMIImportInstance) {
    ModelicaFormatError("Error parsing the XML file contained in %s\n", FMI1ME->FMIWorkingDirectory);
    return 0;
  }
  /* Load the binary (dll/so) */
  status = fmi1_import_create_dllfmu(FMI1ME->FMIImportInstance, FMI1ME->FMICallbackFunctions, 0);
  if (status == jm_status_error) {
    ModelicaFormatError("Loading of FMU dynamic link library failed");
    return 0;
  }
  FMI1ME->FMIInstanceName = (char*) malloc(strlen(instanceName)+1);
  strcpy(FMI1ME->FMIInstanceName, instanceName);
  FMI1ME->FMIDebugLogging = debugLogging;
  instantiateModelStatus = fmi1_import_instantiate_model(FMI1ME->FMIImportInstance, FMI1ME->FMIInstanceName);
  if (instantiateModelStatus == jm_status_error) {
    ModelicaFormatError("fmiInstantiateModel failed");
    return 0;
  }
  debugLoggingStatus = fmi1_import_set_debug_logging(FMI1ME->FMIImportInstance, FMI1ME->FMIDebugLogging);
  if (debugLoggingStatus != fmi1_status_ok && debugLoggingStatus != fmi1_status_warning) {
    ModelicaFormatMessage("fmiSetDebugLogging failed with status : %s\n", fmi1_status_to_string(debugLoggingStatus));
  }
  FMI1ME->FMIToleranceControlled = fmi1_true;
  FMI1ME->FMIRelativeTolerance = 0.001;
  FMI1ME->FMIEventInfo = malloc(sizeof(fmi1_event_info_t));
  return FMI1ME;
}

void FMI1ModelExchangeDestructor_OMC(void* in_fmi1me)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_import_terminate(FMI1ME->FMIImportInstance);
  fmi1_import_free_model_instance(FMI1ME->FMIImportInstance);
  fmi1_import_destroy_dllfmu(FMI1ME->FMIImportInstance);
  fmi1_import_free(FMI1ME->FMIImportInstance);
  fmi_import_free_context(FMI1ME->FMIImportContext);
  free(FMI1ME->FMIWorkingDirectory);
  free(FMI1ME->FMIInstanceName);
  free(FMI1ME->FMIEventInfo);
}

/*
 * Wrapper for the FMI function fmiInitialize.
 */
void fmi1Initialize_OMC(void* in_fmi1me)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_initialize(FMI1ME->FMIImportInstance, FMI1ME->FMIToleranceControlled, FMI1ME->FMIRelativeTolerance, FMI1ME->FMIEventInfo);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiInitialize failed with status : %s\n", fmi1_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmiSetTime.
 * Returns status.
 */
void fmi1SetTime_OMC(void* in_fmi1me, double time)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_set_time(FMI1ME->FMIImportInstance, time);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiSetTime failed with status : %s\n", fmi1_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmiGetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi1GetContinuousStates_OMC(void* in_fmi1me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_get_continuous_states(FMI1ME->FMIImportInstance, (fmi1_real_t*)states, numberOfContinuousStates);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiGetContinuousStates failed with status : %s\n", fmi1_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmiSetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns status.
 */
double fmi1SetContinuousStates_OMC(void* in_fmi1me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_set_continuous_states(FMI1ME->FMIImportInstance, (fmi1_real_t*)states, numberOfContinuousStates);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiSetContinuousStates failed with status : %s\n", fmi1_status_to_string(status));
  }
  return flowParams;
}

/*
 * Wrapper for the FMI function fmiGetEventIndicators.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns events.
 */
void fmi1GetEventIndicators_OMC(void* in_fmi1me, int numberOfEventIndicators, double flowStates, double* events)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_get_event_indicators(FMI1ME->FMIImportInstance, (fmi1_real_t*)events, numberOfEventIndicators);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiGetEventIndicators failed with status : %s\n", fmi1_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmiGetDerivatives.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi1GetDerivatives_OMC(void* in_fmi1me, int numberOfContinuousStates, double flowStates, double* states)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_get_derivatives(FMI1ME->FMIImportInstance, (fmi1_real_t*)states, numberOfContinuousStates);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiGetDerivatives failed with status : %s\n", fmi1_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * Returns stateValuesChanged.
 */
int fmi1EventUpdate_OMC(void* in_fmi1me, int intermediateResults)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_status_t status = fmi1_import_eventUpdate(FMI1ME->FMIImportInstance, intermediateResults, FMI1ME->FMIEventInfo);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiEventUpdate failed with status : %s\n", fmi1_status_to_string(status));
  }
  return FMI1ME->FMIEventInfo->stateValuesChanged;
}

/*
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI EventInfo nextEventTime
 */
double fmi1nextEventTime_OMC(void* in_fmi1me, double flowStates)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  return FMI1ME->FMIEventInfo->nextEventTime;
}

/*
 * Wrapper for the FMI function fmiCompletedIntegratorStep.
 */
int fmi1CompletedIntegratorStep_OMC(void* in_fmi1me, double flowStates)
{
  FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1me;
  fmi1_boolean_t callEventUpdate = fmi1_false;
  fmi1_status_t status = fmi1_import_completed_integrator_step(FMI1ME->FMIImportInstance, &callEventUpdate);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmiCompletedIntegratorStep failed with status : %s\n", fmi1_status_to_string(status));
  }
  return callEventUpdate;
}

#ifdef __cplusplus
}
#endif
