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

static void importlogger(jm_callbacks* c, jm_string module, jm_log_level_enu_t log_level, jm_string message)
{
  printf("module = %s, log level = %d: %s\n", module, log_level, message);
}

/* Logger function used by the FMU internally */
static void fmilogger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...)
{
  char msg[BUFFER];
  va_list argp;
  va_start(argp, message);
  vsprintf(msg, message, argp);
  printf("fmiStatus = %d;  %s (%s): %s\n", status, instanceName, category, msg);
}

/*
 * functions that replaces the given character old with the character new in a string
 */
void charReplace(char* variable_name, unsigned int len, char old, char new)
{
  char* res = NULL;
  res = strchr(variable_name, old);
  while (res != NULL) {
    *res = new;
    res = strchr(variable_name, old);
  }
  variable_name[len] = '\0';
}

/*
 * Reads the model variable variability.
 */
char* getModelVariableVariability(fmi1_import_variable_t* variable)
{
  fmi1_variability_enu_t variability = fmi1_import_get_variability(variable);
  switch (variability) {
    case fmi1_variability_enu_constant:
      return "constant ";
    case fmi1_variability_enu_parameter:
      return "parameter ";
    case fmi1_variability_enu_discrete:
      return "discrete ";
    case fmi1_variability_enu_continuous:
    case fmi1_variability_enu_unknown:
      return "";
  }
}

/*
 * Reads the model variable causality.
 */
char* getModelVariableCausality(fmi1_import_variable_t* variable)
{
  fmi1_causality_enu_t causality = fmi1_import_get_causality(variable);
  switch (causality) {
    case fmi1_causality_enu_input:
      return "input ";
    case fmi1_causality_enu_output:
      return "output ";
    case fmi1_causality_enu_internal:
    case fmi1_causality_enu_none:
    case fmi1_causality_enu_unknown:
      return "";
  }
}

/*
 * Reads the model variable base type.
 */
char* getModelVariableBaseType(fmi1_import_variable_t* variable)
{
  fmi1_base_type_enu_t type = fmi1_import_get_variable_base_type(variable);
  switch (type) {
    case fmi1_base_type_real:
      return "Real ";
    case fmi1_base_type_int:
      return "Integer ";
    case fmi1_base_type_bool:
      return "Boolean ";
    case fmi1_base_type_str:
      return "String ";
    case fmi1_base_type_enum:
      return "enumeration ";
  }
}

/*
 * Reads the model variable base type.
 */
char* getModelVariableName(fmi1_import_variable_t* variable)
{
  char* variable_name = fmi1_import_get_variable_name(variable);
  int len = strlen(variable_name);
  charReplace(variable_name, len, '.', '_');
  charReplace(variable_name, len, '[', '_');
  charReplace(variable_name, len, ']', '_');
  charReplace(variable_name, len, ',', '_');
  charReplace(variable_name, len, '(', '_');
  charReplace(variable_name, len, ')', '_');
  return variable_name;
}

/*
 * Generate Modelica code
 */
static void generateModelicaCode(fmi1_import_t* fmu, char* file_name, const char* working_directory)
{
  FILE* file;
  const char* model_identifier = fmi1_import_get_model_identifier(fmu);
  /* create the Modelica File. */
  file = fopen(file_name, "w");
  if (!file) {
    const char *c_tokens[1]={file_name};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Unable to create the file: %s."), c_tokens, 1);
    return;
  } else {
    const char* fmu_template_str =
        #include "FMIModelica.h"
        ;
    fprintf(file, "package FMUImportNew_%s\n", model_identifier);
    fputs(fmu_template_str, file);
    /* generate the code for FMUBlock */
    fprintf(file, "public\nmodel FMUModel\n");
    /* get the model description */
    const char* model_description = fmi1_import_get_description(fmu);
    if (strcmp(model_description, "") != 0)
      fprintf(file, "\t\"%s\"\n", model_description);
    /* get the model experiment annotation */
    fprintf(file, "\tannotation(experiment(StartTime = %f, StopTime = %f, Tolerance = %f));\n",
        fmi1_import_get_default_experiment_start(fmu),
        fmi1_import_get_default_experiment_stop(fmu),
        fmi1_import_get_default_experiment_tolerance(fmu));
    fprintf(file, "\tconstant String FMUPath = \"%s\";\n", working_directory);
    fprintf(file, "\tconstant String instanceName = \"%s\";\n", model_identifier);
    /* Get the model variables */
    fmi1_import_variable_list_t* variables_list = fmi1_import_get_variable_list(fmu);
    size_t variables_list_size = fmi1_import_get_variable_list_size(variables_list);
    int i = 0;
    for (i ; i < variables_list_size ; i++) {
      fmi1_import_variable_t* variable = fmi1_import_get_variable(variables_list, i);
      /* get the variable variability */
      fprintf(file, "\t%s", getModelVariableVariability(variable));
      /* get the variable causality */
      fprintf(file, "%s", getModelVariableCausality(variable));
      /* get the variable type */
      fprintf(file, "%s", getModelVariableBaseType(variable));
      /* get the variable name and description/comment */
      fprintf(file, "%s \"%s\";\n", getModelVariableName(variable), fmi1_import_get_variable_description(variable));
      /* check variable        */
    }
    /*
     * From FMIL docs,
     * Free a variable list. Note that variable lists are allocated dynamically and must be freed when not needed any longer.
     */
    free(variables_list);
    fprintf(file, "protected\n");
    fprintf(file, "\tfmiImportInstance fmu = fmiImportInstance(context, FMUPath);\n");
    fprintf(file, "\tfmiImportContext context = fmiImportContext();\n");
    fprintf(file, "\t//Integer status = fmiImportInstantiateModel(fmu, instanceName);\n");
    fprintf(file, "end FMUModel;\n");
    fprintf(file, "end FMUImportNew_%s;", model_identifier);
  }
  fclose(file);
}

/*
 * Reads the FMU, extract and generates Modelica code.
 */
char* FMIImpl__importFMU(const char* file_name, const char* working_directory)
{
  // check the if the fmu file exists
  if (!SystemImpl__regularFileExists(file_name)) {
    const char* c_tokens[1]={file_name};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("File not Found: %s."), c_tokens, 1);
    return strdup("");
  }
  // JM callbacks
  jm_callbacks callbacks;
  callbacks.malloc = malloc;
  callbacks.calloc = calloc;
  callbacks.realloc = realloc;
  callbacks.free = free;
  callbacks.logger = importlogger;
  callbacks.context = 0;
  // FMI callback functions
  fmi1_callback_functions_t callback_functions;
  callback_functions.logger = fmilogger;
  callback_functions.allocateMemory = calloc;
  callback_functions.freeMemory = free;
  // FMI context
  fmi_import_context_t *context;
  context = fmi_import_allocate_context(&callbacks);
  // extract the fmu file and read the version
  fmi_version_enu_t version;
  version = fmi_import_get_fmi_version(context, file_name, working_directory);
  if (version != fmi_version_1_enu) {
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Only version 1.0 is supported so far."), NULL, 0);
    return strdup("");
  }
  // parse the xml file
  fmi1_import_t *fmu;
  fmu = fmi1_import_parse_xml(context, working_directory);
  if(!fmu) {
    const char* c_tokens[1]={file_name};
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing the XML file contained in %s."), c_tokens, 1);
    return strdup("");
  }
  // Load the dll
  jm_status_enu_t status;
  status = fmi1_import_create_dllfmu(fmu, callback_functions, 0);
  if (status == jm_status_error) {
    c_add_message(-1, ErrorType_scripting, ErrorLevel_error, gettext("Could not create the DLL loading mechanism(C-API)."), NULL, 0);
    return strdup("");
  }
  // create a file name for generated Modelica code
  char* generated_file_name;
  // read the model identifier from FMI.
  const char* model_identifier = fmi1_import_get_model_identifier(fmu);
  int len = strlen(working_directory) + strlen(model_identifier);
  generated_file_name = (char*) malloc(len + 16);
  strcpy(generated_file_name, working_directory);
  strcat(generated_file_name, "/");
  strcat(generated_file_name, model_identifier);
  strcat(generated_file_name, "FMUImportNew");
  strcat(generated_file_name, ".mo");
  // Generate Modelica code and save the file
  generateModelicaCode(fmu, generated_file_name, working_directory);
  fmi1_import_destroy_dllfmu(fmu);
  fmi1_import_free(fmu);
  fmi_import_free_context(context);
  return generated_file_name;
}

#ifdef __cplusplus
}
#endif
