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
#include "FMI2Common.h"

/*
 * FMI version 2.0 ModelExchange functions
 */

void* FMI2ModelExchangeConstructor_OMC(int fmi_log_level, char* working_directory, char* instanceName, int debugLogging)
{
  FMI2ModelExchange* FMI2ME = malloc(sizeof(FMI2ModelExchange));
  jm_status_enu_t status, instantiateModelStatus;
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
  /* parse the xml file */
  FMI2ME->FMIWorkingDirectory = (char*) malloc(strlen(working_directory)+1);
  strcpy(FMI2ME->FMIWorkingDirectory, working_directory);
  FMI2ME->FMIImportInstance = fmi2_import_parse_xml(FMI2ME->FMIImportContext, FMI2ME->FMIWorkingDirectory, NULL);
  if(!FMI2ME->FMIImportInstance) {
    FMI2ME->FMISolvingMode = fmi2_none_mode;
    ModelicaFormatError("Error parsing the XML file contained in %s\n", FMI2ME->FMIWorkingDirectory);
    return 0;
  }
  /* FMI callback functions */
  FMI2ME->FMICallbackFunctions.logger = fmi2logger;
  FMI2ME->FMICallbackFunctions.allocateMemory = calloc;
  FMI2ME->FMICallbackFunctions.freeMemory = free;
  FMI2ME->FMICallbackFunctions.componentEnvironment = FMI2ME->FMIImportInstance;
  /* Load the binary (dll/so) */
  status = fmi2_import_create_dllfmu(FMI2ME->FMIImportInstance, fmi2_fmu_kind_me, &FMI2ME->FMICallbackFunctions);
  if (status == jm_status_error) {
    FMI2ME->FMISolvingMode = fmi2_none_mode;
    ModelicaFormatError("Loading of FMU dynamic link library failed with status : %s\n", jm_log_level_to_string(status));
    return 0;
  }
  FMI2ME->FMIInstanceName = (char*) malloc(strlen(instanceName)+1);
  strcpy(FMI2ME->FMIInstanceName, instanceName);
  FMI2ME->FMIDebugLogging = debugLogging;
  instantiateModelStatus = fmi2_import_instantiate(FMI2ME->FMIImportInstance, FMI2ME->FMIInstanceName, fmi2_model_exchange, NULL, fmi2_false);
  if (instantiateModelStatus == jm_status_error) {
    FMI2ME->FMISolvingMode = fmi2_none_mode;
    ModelicaFormatError("fmi2InstantiateModel failed with status : %s\n", jm_log_level_to_string(instantiateModelStatus));
    return 0;
  }
  /* Only call fmi2SetDebugLogging if debugLogging is true */
  if (FMI2ME->FMIDebugLogging) {
    int i;
    size_t categoriesSize = 0;
    fmi2_status_t debugLoggingStatus;
    fmi2_string_t *categories;
    /* Read the log categories size */
    categoriesSize = fmi2_import_get_log_categories_num(FMI2ME->FMIImportInstance);
    categories = (fmi2_string_t*)malloc(categoriesSize*sizeof(fmi2_string_t));
    for (i = 0 ; i < categoriesSize ; i++) {
      categories[i] = fmi2_import_get_log_category(FMI2ME->FMIImportInstance, i);
    }
    debugLoggingStatus = fmi2_import_set_debug_logging(FMI2ME->FMIImportInstance, FMI2ME->FMIDebugLogging, categoriesSize, categories);
    if (debugLoggingStatus != fmi2_status_ok && debugLoggingStatus != fmi2_status_warning) {
      ModelicaFormatMessage("fmi2SetDebugLogging failed with status : %s\n", fmi1_status_to_string(debugLoggingStatus));
    }
  }
  FMI2ME->FMIToleranceControlled = fmi2_true;
  FMI2ME->FMIRelativeTolerance = 0.001;
  FMI2ME->FMIEventInfo = malloc(sizeof(fmi2_event_info_t));
  FMI2ME->FMISolvingMode = fmi2_instantiated_mode;
  return FMI2ME;
}

void FMI2ModelExchangeDestructor_OMC(void* in_fmi2me)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_import_terminate(FMI2ME->FMIImportInstance);
  fmi2_import_free_instance(FMI2ME->FMIImportInstance);
  fmi2_import_destroy_dllfmu(FMI2ME->FMIImportInstance);
  fmi2_import_free(FMI2ME->FMIImportInstance);
  fmi_import_free_context(FMI2ME->FMIImportContext);
  free(FMI2ME->FMIWorkingDirectory);
  free(FMI2ME->FMIInstanceName);
  free(FMI2ME->FMIEventInfo);
}

/*
 * Wrapper for the FMI function fmi2EnterInitializationMode.
 */
void fmi2EnterInitializationModel_OMC(void* in_fmi2me)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_status_t status = fmi2_import_enter_initialization_mode(FMI2ME->FMIImportInstance);
  FMI2ME->FMISolvingMode = fmi2_initialization_mode;
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2EnterInitializationMode failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi2ExitInitializationMode.
 */
void fmi2ExitInitializationModel_OMC(void* in_fmi2me)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_status_t status = fmi2_import_exit_initialization_mode(FMI2ME->FMIImportInstance);
  FMI2ME->FMISolvingMode = fmi2_event_mode;
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2ExitInitializationMode failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi2SetTime.
 * Returns status.
 */
void fmi2SetTime_OMC(void* in_fmi2me, double time)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_event_mode || FMI2ME->FMISolvingMode == fmi2_continuousTime_mode) {
    fmi2_status_t status = fmi2_import_set_time(FMI2ME->FMIImportInstance, time);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmi2SetTime failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmi2GetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi2GetContinuousStates_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_status_t status = fmi2_import_get_continuous_states(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2GetContinuousStates failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi2SetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 * Returns status.
 */
double fmi2SetContinuousStates_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  if (numberOfContinuousStates > 0) {
    fmi2_status_t status = fmi2_import_set_continuous_states(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmi2SetContinuousStates failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
  return flowParams;
}

/*
 * Wrapper for the FMI function fmi2GetEventIndicators.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns events.
 */
void fmi2GetEventIndicators_OMC(void* in_fmi2me, int numberOfEventIndicators, double flowStates, double* events)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_status_t status = fmi2_import_get_event_indicators(FMI2ME->FMIImportInstance, (fmi2_real_t*)events, numberOfEventIndicators);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2GetEventIndicators failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi2GetDerivatives.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns states.
 */
void fmi2GetDerivatives_OMC(void* in_fmi2me, int numberOfContinuousStates, double flowStates, double* states)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  if (FMI2ME->FMISolvingMode == fmi2_continuousTime_mode){
    fmi2_status_t status = fmi2_import_get_derivatives(FMI2ME->FMIImportInstance, (fmi2_real_t*)states, numberOfContinuousStates);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmi2GetDerivatives failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmi2NewDiscreteStates.
 * Returns valuesOfContinuousStatesChanged
 */
int fmi2EventUpdate_OMC(void* in_fmi2me)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  fmi2_event_info_t *eventInfo = FMI2ME->FMIEventInfo;
  fmi2_status_t status = fmi2_import_enter_event_mode(FMI2ME->FMIImportInstance);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2EnterEventMode failed with status : %s\n", fmi2_status_to_string(status));
  }
  FMI2ME->FMISolvingMode = fmi2_event_mode;

  eventInfo->newDiscreteStatesNeeded = fmi2_true;
  eventInfo->terminateSimulation = fmi2_false;
  status = fmi2_import_new_discrete_states(FMI2ME->FMIImportInstance, eventInfo);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2NewDiscreteStates failed with status : %s\n", fmi2_status_to_string(status));
  }

  status = fmi2_import_enter_continuous_time_mode(FMI2ME->FMIImportInstance);
  if (status != fmi1_status_ok && status != fmi1_status_warning) {
    ModelicaFormatError("fmi2EnterContinuousTimeMode failed with status : %s\n", fmi2_status_to_string(status));
  }
  FMI2ME->FMISolvingMode = fmi2_continuousTime_mode;
  return eventInfo->valuesOfContinuousStatesChanged;
}

/*
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns FMI EventInfo nextEventTime
 */
double fmi2nextEventTime_OMC(void* in_fmi2me, double flowStates)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  return FMI2ME->FMIEventInfo->nextEventTime;
}

/*
 * Wrapper for the FMI function fmi2CompletedIntegratorStep.
 */
int fmi2CompletedIntegratorStep_OMC(void* in_fmi2me, double flowStates)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2me;
  if (FMI2ME->FMISolvingMode == fmi2_continuousTime_mode){
    fmi2_boolean_t callEventUpdate = fmi2_false;
    fmi2_boolean_t terminateSimulation = fmi2_false;
    fmi2_status_t status = fmi2_import_completed_integrator_step(FMI2ME->FMIImportInstance, fmi2_true, &callEventUpdate, &terminateSimulation);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmi2CompletedIntegratorStep failed with status : %s\n", fmi2_status_to_string(status));
    }
    return callEventUpdate;
  }
  return fmi2_false;
}

#ifdef __cplusplus
}
#endif
