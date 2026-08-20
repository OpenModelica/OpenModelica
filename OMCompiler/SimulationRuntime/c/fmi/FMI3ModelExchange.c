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

#ifdef __cplusplus
extern "C" {
#endif

#include <float.h>

#include "FMICommon.h"
#include "FMI3Common.h"

/*
 * FMI version 3.0 ModelExchange functions
 *
 * These follow the FMI 2.0 ones next door, with the differences FMI 3.0 introduced:
 *
 *   - there is no fmi3SetupExperiment. What it did is now arguments of
 *     fmi3EnterInitializationMode.
 *   - fmi3UpdateDiscreteStates replaces fmi2NewDiscreteStates and reports through out
 *     parameters rather than filling in an event info structure.
 *   - the instance is created with an instance environment and one log callback
 *     instead of a table of callback functions.
 *   - fmi3GetContinuousStateDerivatives replaces fmi2GetDerivatives.
 */

void* FMI3ModelExchangeConstructor_OMC(int fmi_log_level, char* working_directory, char* instanceName, int debugLogging)
{
  FMI3ModelExchange* FMI3ME = malloc(sizeof(FMI3ModelExchange));
  jm_status_enu_t status, instantiateModelStatus;
  FMI3ME->FMILogLevel = fmi_log_level;
  /* JM callbacks */
  FMI3ME->JMCallbacks.malloc = malloc;
  FMI3ME->JMCallbacks.calloc = calloc;
  FMI3ME->JMCallbacks.realloc = realloc;
  FMI3ME->JMCallbacks.free = free;
  FMI3ME->JMCallbacks.logger = importlogger;
  FMI3ME->JMCallbacks.log_level = FMI3ME->FMILogLevel;
  FMI3ME->JMCallbacks.context = 0;
  FMI3ME->FMIImportContext = fmi_import_allocate_context(&FMI3ME->JMCallbacks);
  /* parse the xml file */
  FMI3ME->FMIWorkingDirectory = (char*) malloc(strlen(working_directory)+1);
  strcpy(FMI3ME->FMIWorkingDirectory, working_directory);
  FMI3ME->FMIImportInstance = fmi3_import_parse_xml(FMI3ME->FMIImportContext, FMI3ME->FMIWorkingDirectory, NULL);
  if (!FMI3ME->FMIImportInstance) {
    FMI3ME->FMISolvingMode = fmi3_none_mode;
    ModelicaFormatError("Error parsing the XML file contained in %s\n", FMI3ME->FMIWorkingDirectory);
    return 0;
  }
  /* Load the binary (dll/so) */
  status = fmi3_import_create_dllfmu(FMI3ME->FMIImportInstance, fmi3_fmu_kind_me, FMI3ME->FMIImportInstance, fmi3logger);
  if (status == jm_status_error) {
    FMI3ME->FMISolvingMode = fmi3_none_mode;
    ModelicaFormatError("Loading of FMU dynamic link library failed");
    return 0;
  }
  FMI3ME->FMIInstanceName = (char*) malloc(strlen(instanceName)+1);
  strcpy(FMI3ME->FMIInstanceName, instanceName);
  FMI3ME->FMIDebugLogging = debugLogging;
  instantiateModelStatus = fmi3_import_instantiate_model_exchange(FMI3ME->FMIImportInstance, FMI3ME->FMIInstanceName, NULL, fmi3_false, FMI3ME->FMIDebugLogging ? fmi3_true : fmi3_false);
  if (instantiateModelStatus == jm_status_error) {
    FMI3ME->FMISolvingMode = fmi3_none_mode;
    ModelicaFormatError("fmi3InstantiateModelExchange failed");
    return 0;
  }
  /* Only call fmi3SetDebugLogging if debugLogging is true */
  if (FMI3ME->FMIDebugLogging) {
    size_t i;
    size_t categoriesSize = fmi3_import_get_log_categories_num(FMI3ME->FMIImportInstance);
    fmi3_string_t* categories = (fmi3_string_t*)malloc(categoriesSize*sizeof(fmi3_string_t));
    fmi3_status_t debugLoggingStatus;
    for (i = 0 ; i < categoriesSize ; i++) {
      categories[i] = fmi3_import_get_log_category(FMI3ME->FMIImportInstance, i);
    }
    debugLoggingStatus = fmi3_import_set_debug_logging(FMI3ME->FMIImportInstance, fmi3_true, categoriesSize, categories);
    free(categories);
    if (debugLoggingStatus != fmi3_status_ok && debugLoggingStatus != fmi3_status_warning) {
      ModelicaFormatMessage("fmi3SetDebugLogging failed with status : %s\n", fmi3_status_to_string(debugLoggingStatus));
    }
  }
  FMI3ME->FMIToleranceControlled = fmi3_true;
  FMI3ME->FMIRelativeTolerance = 0.001;
  memset(&FMI3ME->FMIEventInfo, 0, sizeof(fmi3_event_info_omc_t));
  FMI3ME->FMISolvingMode = fmi3_instantiated_mode;
  return FMI3ME;
}

void FMI3ModelExchangeDestructor_OMC(void* in_fmi3me)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_import_terminate(FMI3ME->FMIImportInstance);
  fmi3_import_free_instance(FMI3ME->FMIImportInstance);
  fmi3_import_destroy_dllfmu(FMI3ME->FMIImportInstance);
  fmi3_import_free(FMI3ME->FMIImportInstance);
  fmi_import_free_context(FMI3ME->FMIImportContext);
  free(FMI3ME->FMIWorkingDirectory);
  free(FMI3ME->FMIInstanceName);
}

/*
 * Wrapper for the FMI function fmi3EnterInitializationMode.
 *
 * FMI 3.0 has no fmi3SetupExperiment; what it carried is passed here instead, so the
 * generated code calls this where it called fmi2SetupExperiment and
 * fmi2EnterInitializationMode in turn.
 */
void fmi3EnterInitializationModel_OMC(void* in_fmi3me, int toleranceDefined, double tolerance, double startTime, int stopTimeDefined, double stopTime)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_status_t status = fmi3_import_enter_initialization_mode(FMI3ME->FMIImportInstance,
      toleranceDefined ? fmi3_true : fmi3_false, tolerance,
      startTime,
      stopTimeDefined ? fmi3_true : fmi3_false, stopTime);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3EnterInitializationMode failed with status : %s\n", fmi3_status_to_string(status));
  }
  FMI3ME->FMISolvingMode = fmi3_initialization_mode;
}

/*
 * Wrapper for the FMI function fmi3ExitInitializationMode.
 *
 * An FMI 3.0 Model Exchange FMU is in Event Mode when initialization ends, which is
 * where FMI 2.0 needed an explicit fmi2EnterEventMode.
 */
void fmi3ExitInitializationModel_OMC(void* in_fmi3me)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_status_t status = fmi3_import_exit_initialization_mode(FMI3ME->FMIImportInstance);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3ExitInitializationMode failed with status : %s\n", fmi3_status_to_string(status));
  }
  FMI3ME->FMISolvingMode = fmi3_event_mode;
}

/*
 * Wrapper for the FMI function fmi3SetTime.
 */
void fmi3SetTime_OMC(void* in_fmi3me, double time)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  if (FMI3ME->FMISolvingMode == fmi3_continuousTime_mode || FMI3ME->FMISolvingMode == fmi3_event_mode) {
    fmi3_status_t status = fmi3_import_set_time(FMI3ME->FMIImportInstance, time);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetTime failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmi3GetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 */
void fmi3GetContinuousStates_OMC(void* in_fmi3me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_status_t status = fmi3_import_get_continuous_states(FMI3ME->FMIImportInstance, (fmi3_float64_t*)states, numberOfContinuousStates);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetContinuousStates failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi3SetContinuousStates.
 * parameter flowParams is dummy and is only used to run the equations in sequence.
 */
double fmi3SetContinuousStates_OMC(void* in_fmi3me, int numberOfContinuousStates, double flowParams, double* states)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  if (FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_status_t status = fmi3_import_set_continuous_states(FMI3ME->FMIImportInstance, (const fmi3_float64_t*)states, numberOfContinuousStates);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetContinuousStates failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
  return flowParams;
}

/*
 * Wrapper for the FMI function fmi3GetEventIndicators.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 */
void fmi3GetEventIndicators_OMC(void* in_fmi3me, int numberOfEventIndicators, double flowStates, double* events)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_status_t status = fmi3_import_get_event_indicators(FMI3ME->FMIImportInstance, (fmi3_float64_t*)events, numberOfEventIndicators);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetEventIndicators failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi3GetContinuousStateDerivatives, which is what FMI 2.0
 * called fmi2GetDerivatives.
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 */
void fmi3GetDerivatives_OMC(void* in_fmi3me, int numberOfContinuousStates, double flowStates, double* states)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  /* FMI Library still calls this fmi3_import_get_derivatives, though FMI 3.0 renamed
     the function it wraps to fmi3GetContinuousStateDerivatives. */
  fmi3_status_t status = fmi3_import_get_derivatives(FMI3ME->FMIImportInstance, (fmi3_float64_t*)states, numberOfContinuousStates);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetContinuousStateDerivatives failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/*
 * Wrapper for the FMI function fmi3EnterEventMode.
 */
void fmi3StartEventUpdate_OMC(void* in_fmi3me)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_status_t status = fmi3_import_enter_event_mode(FMI3ME->FMIImportInstance);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3EnterEventMode failed with status : %s\n", fmi3_status_to_string(status));
  }
  FMI3ME->FMISolvingMode = fmi3_event_mode;
  FMI3ME->FMIEventInfo.discreteStatesNeedUpdate = fmi3_true;
  FMI3ME->FMIEventInfo.terminateSimulation = fmi3_false;
}

/*
 * Wrapper for the FMI function fmi3UpdateDiscreteStates, which is what FMI 2.0 called
 * fmi2NewDiscreteStates. It reports through out parameters, which are kept in the
 * external object so that fmi3nextEventTime_OMC can read them afterwards.
 *
 * The FMU may need more than one pass before the discrete states settle, which is what
 * discreteStatesNeedUpdate says; iterate until it does.
 *
 * Returns valuesOfContinuousStatesChanged.
 */
int fmi3EndEventUpdate_OMC(void* in_fmi3me)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  fmi3_event_info_omc_t* eventInfo = &FMI3ME->FMIEventInfo;
  fmi3_boolean_t valuesOfContinuousStatesChanged = fmi3_false;
  fmi3_status_t status;

  eventInfo->discreteStatesNeedUpdate = fmi3_true;
  eventInfo->terminateSimulation = fmi3_false;
  while (eventInfo->discreteStatesNeedUpdate && !eventInfo->terminateSimulation) {
    status = fmi3_import_update_discrete_states(FMI3ME->FMIImportInstance,
        &eventInfo->discreteStatesNeedUpdate,
        &eventInfo->terminateSimulation,
        &eventInfo->nominalsOfContinuousStatesChanged,
        &eventInfo->valuesOfContinuousStatesChanged,
        &eventInfo->nextEventTimeDefined,
        &eventInfo->nextEventTime);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3UpdateDiscreteStates failed with status : %s\n", fmi3_status_to_string(status));
    }
    /* any pass that moved the states counts, not only the last one */
    if (eventInfo->valuesOfContinuousStatesChanged) {
      valuesOfContinuousStatesChanged = fmi3_true;
    }
  }

  status = fmi3_import_enter_continuous_time_mode(FMI3ME->FMIImportInstance);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3EnterContinuousTimeMode failed with status : %s\n", fmi3_status_to_string(status));
  }
  FMI3ME->FMISolvingMode = fmi3_continuousTime_mode;
  return valuesOfContinuousStatesChanged;
}

/*
 * parameter flowStates is dummy and is only used to run the equations in sequence.
 * Returns the next event time, or infinity when the FMU did not give one, which is
 * what the generated code expects for "no event scheduled".
 */
double fmi3nextEventTime_OMC(void* in_fmi3me, double flowStates)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  if (FMI3ME->FMIEventInfo.nextEventTimeDefined) {
    return FMI3ME->FMIEventInfo.nextEventTime;
  }
  return DBL_MAX;
}

/*
 * Wrapper for the FMI function fmi3CompletedIntegratorStep.
 */
int fmi3CompletedIntegratorStep_OMC(void* in_fmi3me, double flowStates)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3me;
  if (FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_boolean_t callEventUpdate = fmi3_false;
    fmi3_boolean_t terminateSimulation = fmi3_false;
    fmi3_status_t status = fmi3_import_completed_integrator_step(FMI3ME->FMIImportInstance, fmi3_true, &callEventUpdate, &terminateSimulation);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3CompletedIntegratorStep failed with status : %s\n", fmi3_status_to_string(status));
    }
    return callEventUpdate;
  }
  return fmi3_false;
}

#ifdef __cplusplus
}
#endif
