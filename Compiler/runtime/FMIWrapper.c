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

#include <stdio.h>
#include <stdlib.h>

#include "fmilib.h"

#define BUFFER 1000
#define FMI_DEBUG

static void importlogger(jm_callbacks* c, jm_string module, jm_log_level_enu_t log_level, jm_string message)
{
#ifdef FMI_DEBUG
  printf("module = %s, log level = %d: %s\n", module, log_level, message);
#endif
}

/* Logger function used by the FMU internally */
static void fmilogger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...)
{
#ifdef FMI_DEBUG
  char msg[BUFFER];
  va_list argp;
  va_start(argp, message);
  vsprintf(msg, message, argp);
  printf("fmiStatus = %d;  %s (%s): %s\n", status, instanceName, category, msg);
#endif
}

/*
 * Creates an instance of the FMI Import Context i.e fmi_import_context_t
 */
void* fmiImportContext_OMC(int fmi_log_level)
{
  // JM callbacks
  static int init = 0;
  static jm_callbacks callbacks;
  if (!init) {
    init = 1;
    callbacks.malloc = malloc;
    callbacks.calloc = calloc;
    callbacks.realloc = realloc;
    callbacks.free = free;
    callbacks.logger = importlogger;
    callbacks.log_level = fmi_log_level;
    callbacks.context = 0;
  }
  fmi_import_context_t* context = fmi_import_allocate_context(&callbacks);
  return context;
}

/*
 * Destroys the instance of the FMI Import Context i.e fmi_import_context_t
 */
void fmiImportFreeContext_OMC(void* context)
{
  fmi_import_free_context(context);
}

/*
 * Creates an instance of the FMI Import i.e fmi1_import_t
 * Reads the xml.
 * Loads the binary (dll/so).
 */
void* fmiImportInstance_OMC(void* context, char* working_directory)
{
  // FMI callback functions
  static int init = 0;
  fmi1_callback_functions_t callback_functions;
  if (!init) {
    init = 1;
    callback_functions.logger = fmilogger;
    callback_functions.allocateMemory = calloc;
    callback_functions.freeMemory = free;
  }
  // parse the xml file
  fmi1_import_t* fmi;
  fmi = fmi1_import_parse_xml((fmi_import_context_t*)context, working_directory);
  if(!fmi) {
    fprintf(stderr, "Error parsing the XML file contained in %s\n", working_directory);
    return 0;
  }
  // Load the binary (dll/so)
  jm_status_enu_t status;
  status = fmi1_import_create_dllfmu(fmi, callback_functions, 0);
  if (status == jm_status_error) {
    fprintf(stderr, "Could not create the DLL loading mechanism(C-API).\n");
    return 0;
  }
  return fmi;
}

/*
 * Destroys the instance of the FMI Import i.e fmi1_import_t
 * Also destroys the loaded binary (dll/so).
 */
void fmiImportFreeInstance_OMC(void* fmi)
{
  fmi1_import_t* fmi1 = (fmi1_import_t*)fmi;
  fmi1_import_destroy_dllfmu(fmi1);
  fmi1_import_free(fmi1);
}

/*
 * Destroys the instance of the FMI Event Info i.e fmi1_event_info_t
 */
void fmiFreeEventInfo_OMC(void* eventInfo)
{
  if ((fmi1_event_info_t*)eventInfo != NULL)
    free((fmi1_event_info_t*)eventInfo);
}

/*
 * Wrapper for the FMI function fmiInstantiateModel.
 */
void fmiInstantiateModel_OMC(void* fmi, const char* instanceName)
{
  jm_status_enu_t status = fmi1_import_instantiate_model((fmi1_import_t*)fmi, instanceName);
  if (status == jm_status_error) {
    fprintf(stderr, "FMI Import Error: Error in fmiInstantiateModel_OMC.\n");fflush(NULL);
  }
}

/*
 * Wrapper for the FMI function fmiSetTime.
 * Returns status.
 */
int fmiSetTime_OMC(void* fmi, double time)
{
  return fmi1_import_set_time((fmi1_import_t*)fmi, time);
}

/*
 * Wrapper for the FMI function fmiInitialize.
 * Returns FMI Event Info i.e fmi1_event_info_t.
 */
void* fmiInitialize_OMC(void* fmi)
{
  fmi1_boolean_t toleranceControlled = fmi1_true;
  fmi1_real_t relativeTolerance = 0.001;
  fmi1_event_info_t* eventInfo = malloc(sizeof(fmi1_event_info_t));
  fmi1_status_t fmistatus = fmi1_import_initialize((fmi1_import_t*)fmi, toleranceControlled, relativeTolerance, eventInfo);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiInitialize_OMC.\n");fflush(NULL);
      break;
  }
  return eventInfo;
}

/*
 * Wrapper for the FMI function fmiSetDebugLogging.
 * Returns status.
 */
int fmiSetDebugLogging_OMC(void* fmi, int debugLogging)
{
  return fmi1_import_set_debug_logging((fmi1_import_t*)fmi, debugLogging);
}

/*
 * Wrapper for the FMI function fmiGetContinuousStates.
 * Returns states.
 */
void fmiGetContinuousStates_OMC(void* fmi, int numberOfContinuousStates, double* states)
{
  fmi1_status_t fmistatus = fmi1_import_get_continuous_states((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetContinuousStates_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiSetContinuousStates.
 * Returns status.
 */
int fmiSetContinuousStates_OMC(void* fmi, int numberOfContinuousStates, double* states)
{
  return fmi1_import_set_continuous_states((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
}

/*
 * Wrapper for the FMI function fmiGetEventIndicators.
 * Returns events.
 */
void fmiGetEventIndicators_OMC(void* fmi, int numberOfEventIndicators, double* events)
{
  fmi1_status_t fmistatus = fmi1_import_get_event_indicators((fmi1_import_t*)fmi, (fmi1_real_t*)events, numberOfEventIndicators);
  int i = 0;
  for (i;i<numberOfEventIndicators;i++)
  {
    //fprintf(stderr, "%d value in fmiGetEventIndicators_OMC is = %f\n", i, events[i]);fflush(NULL);
  }
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetEventIndicators_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiGetDerivatives.
 * Returns states.
 */
void fmiGetDerivatives_OMC(void* fmi, int numberOfContinuousStates, double* states)
{
  fmi1_status_t fmistatus = fmi1_import_get_derivatives((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetDerivatives_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiGetReal.
 * Returns realValues.
 */
void fmiGetReal_OMC(void* fmi, int numberOfValueReferences, int* realValuesReferences, double* realValues)
{
  fmi1_status_t fmistatus = fmi1_import_get_real((fmi1_import_t*)fmi, (fmi1_value_reference_t*)realValuesReferences, numberOfValueReferences, (fmi1_real_t*)realValues);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetReal_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiSetReal.
 * Returns status.
 */
int fmiSetReal_OMC(void* fmi, int numberOfValueReferences, int* realValuesReferences, double* realValues)
{
  return fmi1_import_set_real((fmi1_import_t*)fmi, (fmi1_value_reference_t*)realValuesReferences, numberOfValueReferences, (fmi1_real_t*)realValues);
}

/*
 * Wrapper for the FMI function fmiGetInteger.
 * Returns integerValues.
 */
void fmiGetInteger_OMC(void* fmi, int numberOfValueReferences, int* integerValuesReferences, int* integerValues)
{
  fmi1_status_t fmistatus = fmi1_import_get_integer((fmi1_import_t*)fmi, (fmi1_value_reference_t*)integerValuesReferences, numberOfValueReferences, (fmi1_integer_t*)integerValues);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetInteger_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiSetInteger.
 * Returns status.
 */
int fmiSetInteger_OMC(void* fmi, int numberOfValueReferences, int* integerValuesReferences, int* integerValues)
{
  return fmi1_import_set_integer((fmi1_import_t*)fmi, (fmi1_value_reference_t*)integerValuesReferences, numberOfValueReferences, (fmi1_integer_t*)integerValues);
}

/*
 * Wrapper for the FMI function fmiGetBoolean.
 * Returns booleanValues.
 */
void fmiGetBoolean_OMC(void* fmi, int numberOfValueReferences, int* booleanValuesReferences, int* booleanValues)
{
  fmi1_status_t fmistatus = fmi1_import_get_boolean((fmi1_import_t*)fmi, (fmi1_value_reference_t*)booleanValuesReferences, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetBoolean_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiSetBoolean.
 * Returns status.
 */
int fmiSetBoolean_OMC(void* fmi, int numberOfValueReferences, int* booleanValuesReferences, int* booleanValues)
{
  return fmi1_import_set_boolean((fmi1_import_t*)fmi, (fmi1_value_reference_t*)booleanValuesReferences, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
}

/*
 * Wrapper for the FMI function fmiGetString.
 * Returns stringValues.
 */
void fmiGetString_OMC(void* fmi, int numberOfValueReferences, int* stringValuesReferences, char** stringValues)
{
  fmi1_status_t fmistatus = fmi1_import_get_string((fmi1_import_t*)fmi, (fmi1_value_reference_t*)stringValuesReferences, numberOfValueReferences, (fmi1_string_t*)stringValues);
  switch (fmistatus) {
    case fmi1_status_warning:
    case fmi1_status_error:
    case fmi1_status_fatal:
      fprintf(stderr, "FMI Import Error: Error in fmiGetString_OMC.\n");fflush(NULL);
      break;
  }
}

/*
 * Wrapper for the FMI function fmiSetString.
 * Returns status.
 */
int fmiSetString_OMC(void* fmi, int numberOfValueReferences, int* stringValuesReferences, char** stringValues)
{
  return fmi1_import_set_string((fmi1_import_t*)fmi, (fmi1_value_reference_t*)stringValuesReferences, numberOfValueReferences, (fmi1_string_t*)stringValues);
}

/*
 * Wrapper for the FMI function fmiEventUpdate.
 * Returns FMI Event Info i.e fmi1_event_info_t
 */
void* fmiEventUpdate_OMC(void* fmi, int intermediateResults, void* eventInfo)
{
  //fprintf(stderr, "yesss in fmiEventUpdate\n");fflush(NULL);
  fmi1_import_eventUpdate((fmi1_import_t*)fmi, intermediateResults, (fmi1_event_info_t*)eventInfo);
  return eventInfo;
}

/*
 * Wrapper for the FMI function fmiCompletedIntegratorStep.
 */
int fmiCompletedIntegratorStep_OMC(void* fmi, int in_callEventUpdate)
{
  fmi1_status_t fmistatus = fmi1_import_completed_integrator_step((fmi1_import_t*)fmi, (fmi1_boolean_t*)&in_callEventUpdate);
  //fprintf(stderr, "fmiCompletedIntegratorStep_OMC in_callEventUpdate = %d\n", in_callEventUpdate);fflush(NULL);
  return in_callEventUpdate;
}

void printZ_OMC(int len, int* zVals)
{
//  fprintf(stderr, "yesss in fmiEventUpdate %d \n", len);fflush(NULL);
//  int i = 0;
//  for (i;i<len;i++)
//  {
//    fprintf(stderr, "%d value is = %d\n", i, zVals[i]);fflush(NULL);
//  }
}

#ifdef __cplusplus
}
#endif
