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

void importlogger(jm_callbacks* c, jm_string module, jm_log_level_enu_t log_level, jm_string message)
{
#ifdef FMI_DEBUG
  printf("module = %s, log level = %d: %s\n", module, log_level, message);
#endif
}

/* Logger function used by the FMU internally */
void fmilogger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...)
{
#ifdef FMI_DEBUG
  char msg[BUFFER];
  va_list argp;
  va_start(argp, message);
  vsprintf(msg, message, argp);
  printf("fmiStatus = %d;  %s (%s): %s\n", status, instanceName, category, msg);
#endif
}

void* jm_callbacks_OMC()
{
  void* callbacks = malloc(sizeof(jm_callbacks));
  ((jm_callbacks*) callbacks)->malloc = malloc;
  ((jm_callbacks*) callbacks)->calloc = calloc;
  ((jm_callbacks*) callbacks)->realloc = realloc;
  ((jm_callbacks*) callbacks)->free = free;
  ((jm_callbacks*) callbacks)->logger = importlogger;
  ((jm_callbacks*) callbacks)->context = 0;
  return callbacks;
}

void* fmi_import_allocate_context_OMC(void* callbacks)
{
  fprintf(stderr, "0\n"); fflush(NULL);
  fprintf(stderr, "YEssss %s", jm_get_last_error((jm_callbacks*) callbacks)); fflush(NULL);
  fmi_import_allocate_context((jm_callbacks*) callbacks);
  fprintf(stderr, "1\n"); fflush(NULL);
  void* context = fmi_import_allocate_context((jm_callbacks*) callbacks);
  return context;
}

void* fmiImportInstance_OMC(char* workingDirectory)
{
  // JM callbacks
  jm_callbacks callbacks;
  callbacks.malloc = malloc;
  callbacks.calloc = calloc;
  callbacks.realloc = realloc;
  callbacks.free = free;
  callbacks.logger = importlogger;
  callbacks.context = 0;
  // FMI function callbacks
  fmi1_callback_functions_t callBackFunctions;
  callBackFunctions.logger = fmilogger;
  callBackFunctions.allocateMemory = calloc;
  callBackFunctions.freeMemory = free;
  // FMI context
  fmi_import_context_t *context;
  context = fmi_import_allocate_context(&callbacks);
  // parse the xml file
  fmi1_import_t *fmu;
  fmu = fmi1_import_parse_xml(context, workingDirectory);
  if(!fmu) {
    fprintf(stderr, "Error parsing the XML file contained in %s\n", workingDirectory);
    return 0;
  }
  // Load the dll
  jm_status_enu_t status;
  status = fmi1_import_create_dllfmu(fmu, callBackFunctions, 0);
  if (status == jm_status_error) {
    fprintf(stderr, "Could not create the DLL loading mechanism(C-API).\n");
    return 0;
  }
  return (void*)fmu;
}

void fmiImportFreeInstance_OMC(void* fmu)
{
  fmi1_import_t* fmu1 = (fmi1_import_t*)fmu;
  fprintf(stderr, "0\n"); fflush(NULL);
  fmi1_import_destroy_dllfmu((fmi1_import_t*)fmu);
  fprintf(stderr, "1\n"); fflush(NULL);
  fmi1_import_free((fmi1_import_t*)fmu);
}

#ifdef __cplusplus
}
#endif

