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
void* fmi_import_allocate_context_OMC(int fmi_log_level)
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
void fmi_import_free_context_OMC(void* context)
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

int fmiInstantiateModel_OMC(void* fmi, const char* instanceName)
{
  return fmi1_import_instantiate_model((fmi1_import_t*)fmi, instanceName);
}

int fmiSetTime_OMC(void* fmi, double time)
{
  return fmi1_import_set_time((fmi1_import_t*)fmi, time);
}

int fmiInitialize_OMC(void* fmi)
{
  fmi1_boolean_t toleranceControlled = fmi1_true;
  fmi1_real_t relativeTolerance = 0.001;
  fmi1_event_info_t eventInfo;
  return fmi1_import_initialize((fmi1_import_t*)fmi, toleranceControlled, relativeTolerance, &eventInfo);
}

int fmiGetContinuousStates_OMC(void* fmi, const double* states, int numberOfContinuousStates)
{
  return fmi1_import_get_continuous_states((fmi1_import_t*)fmi, (fmi1_real_t*)states, numberOfContinuousStates);
}

int fmiGetEventIndicators_OMC(void* fmi, const double* events, int numberOfEventIndicators)
{
  return fmi1_import_get_event_indicators((fmi1_import_t*)fmi, (fmi1_real_t*)events, numberOfEventIndicators);
}

#ifdef __cplusplus
}
#endif
