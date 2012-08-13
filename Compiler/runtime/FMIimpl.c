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

#include "systemimpl.h"
#include "errorext.h"
#define FMILIB_BUILDING_LIBRARY
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

int FMIImpl__importFMU(char *fileName, char* workingDirectory)
{
  // check the if the fmu file exists
  if (!SystemImpl__regularFileExists(fileName)) {
    const char *c_tokens[1]={fileName};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("File not Found: %s."), c_tokens, 1);
    return 0;
  }
  fmi1_callback_functions_t callBackFunctions;
  jm_callbacks callbacks;
  fmi_import_context_t *context;
  fmi_version_enu_t version;
  jm_status_enu_t status;
  fmi1_import_t *fmu;

  callbacks.malloc = malloc;
  callbacks.calloc = calloc;
  callbacks.realloc = realloc;
  callbacks.free = free;
  callbacks.logger = importlogger;
  callbacks.context = 0;

  callBackFunctions.logger = fmilogger;
  callBackFunctions.allocateMemory = calloc;
  callBackFunctions.freeMemory = free;

  context = fmi_import_allocate_context(&callbacks);
  // extract the fmu file and read the version
  version = fmi_import_get_fmi_version(context, fileName, workingDirectory);
  if (version != fmi_version_1_enu) {
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Only version 1.0 is supported so far."), NULL, 1);
    return 0;
  }
  // parse the xml file
  fmu = fmi1_import_parse_xml(context, workingDirectory);
  if(!fmu) {
    const char *c_tokens[1]={fileName};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing the XML file contained in %s."), c_tokens, 1);
    return 0;
  }
  status = fmi1_import_create_dllfmu(fmu, callBackFunctions, 0);
  if (status == jm_status_error) {
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not create the DLL loading mechanism(C-API)."), NULL, 1);
    return 0;
  }
  /*
   * Write the code generation code
   */
  fmi1_import_destroy_dllfmu(fmu);
  fmi1_import_free(fmu);
  fmi_import_free_context(context);
  return 1;
}

#ifdef __cplusplus
}
#endif

