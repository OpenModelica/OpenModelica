/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF AGPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GNU AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs:
 * http://www.openmodelica.org or
 * https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica,
 * and in the OpenModelica distribution.
 *
 * GNU AGPL version 3 is obtained from:
 * https://www.gnu.org/licenses/licenses.html#GPL
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifdef __cplusplus
extern "C" {
#endif

#include "omc_config.h"

#ifdef NO_FMIL
void FMIImpl__initializeFMI1Import(void* fmi, void** fmiInfo, int version, void** typeDefinitionsList, void** experimentAnnotation, void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  MMC_THROW();
}
void FMIImpl__initializeFMI2Import(void* fmi, void** fmiInfo, int version, void** typeDefinitionsList, void** experimentAnnotation, void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  MMC_THROW();
}
void FMIImpl__initializeFMI3Import(void* fmi, void** fmiInfo, int version, void** typeDefinitionsList, void** experimentAnnotation, void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  MMC_THROW();
}
int FMIImpl__initializeFMIImport(const char* file_name, const char* working_directory, int fmi_log_level, int input_connectors, int output_connectors, void** fmiContext, void** fmiInstance, void** fmiInfo, void** typeDefinitionsList, void** experimentAnnotation, void** modelVariablesInstance, void** modelVariablesList)
{
  MMC_THROW();
}
void FMIImpl__releaseFMIImport(void *ptr1, void *ptr2, void *ptr3, const char* fmiVersion)
{
  MMC_THROW();
}
#else

#include <stdio.h>
#include <stdint.h>

#include "systemimpl.h"
#include "errorext.h"
#include "util/modelica_string.h"
#include "util/omc_strdup.h"

#define FMILIB_BUILDING_LIBRARY
#include "fmilib.h"

#define mmc_mk_scon_check_null(s) s?mmc_mk_scon(s):mmc_mk_scon("")

static void importlogger(jm_callbacks* c, jm_string module, jm_log_level_enu_t log_level, jm_string message)
{
  const char* tokens[3] = {module,jm_log_level_to_string(log_level),message};
  switch (log_level) {
    case jm_log_level_fatal:
    case jm_log_level_error:
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("module = %s, log level = %s: %s"), tokens, 3);
      break;
    case jm_log_level_warning:
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_warning, gettext("module = %s, log level = %s: %s"), tokens, 3);
      break;
    case jm_log_level_info:
    case jm_log_level_verbose:
    case jm_log_level_debug:
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_notification, gettext("module = %s, log level = %s: %s"), tokens, 3);
      break;
    default:
      printf("module = %s, log level = %d: %s\n", module, log_level, message);fflush(NULL);
      break;
  }
}

/* Logger function used by the FMU 1.0 internally */
static void fmi1logger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...)
{
  va_list argp;
  va_start(argp, message);
  fmi1_log_forwarding_v(c, instanceName, status, category, message, argp);
  va_end(argp);
  fflush(NULL);
}

/* Logger function used by the FMU 2.0 internally */
static void fmi2logger(fmi2_component_t c, fmi2_string_t instanceName, fmi2_status_t status, fmi2_string_t category, fmi2_string_t message, ...)
{
  va_list argp;
  va_start(argp, message);
  fmi2_log_forwarding_v(c, instanceName, status, category, message, argp);
  va_end(argp);
  fflush(NULL);
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
const char* getFMI1ModelVariableVariability(fmi1_import_variable_t* variable)
{
  fmi1_variability_enu_t variability = fmi1_import_get_variability(variable);
  switch (variability) {
    case fmi1_variability_enu_constant:
      return "constant";
    case fmi1_variability_enu_parameter:
      return "parameter";
    case fmi1_variability_enu_discrete:
    case fmi1_variability_enu_continuous:
    case fmi1_variability_enu_unknown:
    default:
      return "";
  }
}

/*
 * Reads the model variable variability.
 */
const char* getFMI2ModelVariableVariability(fmi2_import_variable_t* variable)
{
  fmi2_variability_enu_t variability = fmi2_import_get_variability(variable);
  switch (variability) {
    case fmi2_variability_enu_constant:
      return "constant";
    case fmi2_variability_enu_tunable:
    case fmi2_variability_enu_discrete:
    case fmi2_variability_enu_continuous:
    case fmi2_variability_enu_unknown:
    default:
      return "";
  }
}

/*
 * Reads the model variable causality.
 */
const char* getFMI1ModelVariableCausality(fmi1_import_variable_t* variable)
{
  fmi1_causality_enu_t causality = fmi1_import_get_causality(variable);
  switch (causality) {
    case fmi1_causality_enu_input:
      return "input";
    case fmi1_causality_enu_output:
      return "output";
    case fmi1_causality_enu_internal:
    case fmi1_causality_enu_none:
    case fmi1_causality_enu_unknown:
    default:
      return "";
  }
}

/*
 * Reads the model variable causality.
 */
const char* getFMI2ModelVariableCausality(fmi2_import_variable_t* variable)
{
  fmi2_causality_enu_t causality = fmi2_import_get_causality(variable);
  switch (causality) {
    case fmi2_causality_enu_input:
      return "input";
    case fmi2_causality_enu_output:
      return "output";
    case fmi2_causality_enu_parameter:
      return "parameter";
    case fmi2_causality_enu_local:
    case fmi2_causality_enu_unknown:
    default:
      return "";
  }
}

/*
 * Reads the model variable base type.
 */
const char* getFMI1ModelVariableBaseType(fmi1_import_variable_t* variable)
{
  fmi1_base_type_enu_t type = fmi1_import_get_variable_base_type(variable);
  fmi1_import_variable_typedef_t* variableTypeDefinition = NULL;
  switch (type) {
    case fmi1_base_type_real:
      return "Real";
    case fmi1_base_type_int:
      return "Integer";
    case fmi1_base_type_bool:
      return "Boolean";
    case fmi1_base_type_str:
      return "String";
    case fmi1_base_type_enum:
      variableTypeDefinition = fmi1_import_get_variable_declared_type(variable);
      return fmi1_import_get_type_name(variableTypeDefinition);
    default:                    /* Should never be reached. */
      return "";
  }
}

/*
 * Reads the model variable base type.
 */
const char* getFMI2ModelVariableBaseType(fmi2_import_variable_t* variable)
{
  fmi2_base_type_enu_t type = fmi2_import_get_variable_base_type(variable);
  fmi2_import_variable_typedef_t* variableTypeDefinition = NULL;
  switch (type) {
    case fmi2_base_type_real:
      return "Real";
    case fmi2_base_type_int:
      return "Integer";
    case fmi2_base_type_bool:
      return "Boolean";
    case fmi2_base_type_str:
      return "String";
    case fmi2_base_type_enum:
      variableTypeDefinition = fmi2_import_get_variable_declared_type(variable);
      return fmi2_import_get_type_name(variableTypeDefinition);
    default:                    /* Should never be reached. */
      return "";
  }
}

/*
 * Reads the model variable variability, FMI 3.0.
 *
 * Only the values the wrapper writes out are named; the rest map to "", which the
 * templates read as "take the Modelica default", exactly as for FMI 1.0 and 2.0.
 */
const char* getFMI3ModelVariableVariability(fmi3_import_variable_t* variable)
{
  switch (fmi3_import_get_variable_variability(variable)) {
    case fmi3_variability_enu_constant:
      return "constant";
    case fmi3_variability_enu_fixed:
    case fmi3_variability_enu_tunable:
    case fmi3_variability_enu_discrete:
    case fmi3_variability_enu_continuous:
    case fmi3_variability_enu_unknown:
    default:
      return "";
  }
}

/*
 * Reads the model variable causality, FMI 3.0.
 *
 * FMI 3.0 adds structuralParameter, which has no counterpart in the wrapper and is
 * reported as a parameter: it is a parameter that happens to size an array.
 */
const char* getFMI3ModelVariableCausality(fmi3_import_variable_t* variable)
{
  switch (fmi3_import_get_variable_causality(variable)) {
    case fmi3_causality_enu_input:
      return "input";
    case fmi3_causality_enu_output:
      return "output";
    case fmi3_causality_enu_parameter:
    case fmi3_causality_enu_structural_parameter:
      return "parameter";
    /* FMI 3.0 requires the independent variable to be declared, which FMI 2.0 did not.
       It is named so that the wrapper can leave it out: it is Modelica's own time, and
       declaring it would clash with the built-in. */
    case fmi3_causality_enu_independent:
      return "independent";
    case fmi3_causality_enu_calculated_parameter:
    case fmi3_causality_enu_local:
    case fmi3_causality_enu_unknown:
    default:
      return "";
  }
}

/*
 * The Modelica type an FMI 3.0 variable maps to.
 *
 * All the float types become Real and all the integer types Integer; the element the
 * FMU actually used is kept separately in the record's fmiType. Binary and Clock have
 * no Modelica type, and say so rather than pretending to be something.
 */
const char* getFMI3ModelVariableBaseType(fmi3_import_variable_t* variable)
{
  fmi3_import_variable_typedef_t* variableTypeDefinition = NULL;
  switch (fmi3_import_get_variable_base_type(variable)) {
    case fmi3_base_type_float64:
    case fmi3_base_type_float32:
      return "Real";
    case fmi3_base_type_int64:
    case fmi3_base_type_int32:
    case fmi3_base_type_int16:
    case fmi3_base_type_int8:
    case fmi3_base_type_uint64:
    case fmi3_base_type_uint32:
    case fmi3_base_type_uint16:
    case fmi3_base_type_uint8:
      return "Integer";
    case fmi3_base_type_bool:
      return "Boolean";
    case fmi3_base_type_str:
      return "String";
    case fmi3_base_type_enum:
      variableTypeDefinition = fmi3_import_get_variable_declared_type(variable);
      return variableTypeDefinition ? fmi3_import_get_type_name(variableTypeDefinition) : "";
    case fmi3_base_type_binary:
    case fmi3_base_type_clock:
    default:
      return "";
  }
}

/*
 * The intervalVariability of an FMI 3.0 Clock, as the string the standard uses.
 * FMI Library has no to_string for this enumeration.
 */
const char* getFMI3IntervalVariability(fmi3_interval_variability_enu_t intervalVariability)
{
  switch (intervalVariability) {
    case fmi3_interval_variability_constant:  return "constant";
    case fmi3_interval_variability_fixed:     return "fixed";
    case fmi3_interval_variability_tunable:   return "tunable";
    case fmi3_interval_variability_changing:  return "changing";
    case fmi3_interval_variability_countdown: return "countdown";
    case fmi3_interval_variability_triggered: return "triggered";
    case fmi3_interval_variability_unknown:
    default:                                  return "";
  }
}

/*
 * The array dimensions of an FMI 3.0 variable, as a list of Integer.
 *
 * The list is empty for a scalar. A dimension given by a valueReference instead of a
 * fixed size is only known once the FMU is instantiated, and is reported as 0.
 */
void* getFMI3ModelVariableDimensions(fmi3_import_variable_t* variable)
{
  void* dimensions = mmc_mk_nil();
  fmi3_import_dimension_list_t* dimensionList = fmi3_import_get_variable_dimension_list(variable);
  size_t dimensionListSize = dimensionList ? fmi3_import_get_dimension_list_size(dimensionList) : 0;
  size_t i;

  for (i = dimensionListSize; i > 0; --i) {
    fmi3_import_dimension_t* dimension = fmi3_import_get_dimension(dimensionList, i - 1);
    fmi3_uint64_t size = fmi3_import_get_dimension_has_start(dimension) ? fmi3_import_get_dimension_start(dimension) : 0;
    dimensions = mmc_mk_cons(mmc_mk_icon((int)size), dimensions);
  }
  return dimensions;
}

/*
 * The start value of an FMI 3.0 variable, as a one element list, or the empty list
 * when it has none.
 *
 * The records take a list because an FMI 3.0 variable can be an array. Only the scalar
 * start is read here: the length of an array start is the product of its dimensions,
 * which is not known for a dimension given by a valueReference, and nothing generates
 * array wrappers yet. Clock variables have no start at all.
 */
void* getFMI3ModelVariableStartValue(fmi3_import_variable_t* variable, int hasStartValue)
{
  fmi3_base_type_enu_t type = fmi3_import_get_variable_base_type(variable);
  fmi3_import_dimension_list_t* dimensions = fmi3_import_get_variable_dimension_list(variable);

  /* nothing to read: no start at all, or an array, whose start is not read yet */
  if (!hasStartValue || (dimensions && fmi3_import_get_dimension_list_size(dimensions) > 0)) {
    return mmc_mk_nil();
  }

  switch (type) {
    case fmi3_base_type_float64:
      return mmc_mk_cons(mmc_mk_rcon(fmi3_import_get_float64_variable_start(fmi3_import_get_variable_as_float64(variable))), mmc_mk_nil());
    case fmi3_base_type_float32:
      return mmc_mk_cons(mmc_mk_rcon((double)fmi3_import_get_float32_variable_start(fmi3_import_get_variable_as_float32(variable))), mmc_mk_nil());
    case fmi3_base_type_int64:
      return mmc_mk_cons(mmc_mk_icon((int)fmi3_import_get_int64_variable_start(fmi3_import_get_variable_as_int64(variable))), mmc_mk_nil());
    case fmi3_base_type_int32:
      return mmc_mk_cons(mmc_mk_icon(fmi3_import_get_int32_variable_start(fmi3_import_get_variable_as_int32(variable))), mmc_mk_nil());
    case fmi3_base_type_int16:
      return mmc_mk_cons(mmc_mk_icon(fmi3_import_get_int16_variable_start(fmi3_import_get_variable_as_int16(variable))), mmc_mk_nil());
    case fmi3_base_type_int8:
      return mmc_mk_cons(mmc_mk_icon(fmi3_import_get_int8_variable_start(fmi3_import_get_variable_as_int8(variable))), mmc_mk_nil());
    case fmi3_base_type_uint64:
      return mmc_mk_cons(mmc_mk_icon((int)fmi3_import_get_uint64_variable_start(fmi3_import_get_variable_as_uint64(variable))), mmc_mk_nil());
    case fmi3_base_type_uint32:
      return mmc_mk_cons(mmc_mk_icon((int)fmi3_import_get_uint32_variable_start(fmi3_import_get_variable_as_uint32(variable))), mmc_mk_nil());
    case fmi3_base_type_uint16:
      return mmc_mk_cons(mmc_mk_icon(fmi3_import_get_uint16_variable_start(fmi3_import_get_variable_as_uint16(variable))), mmc_mk_nil());
    case fmi3_base_type_uint8:
      return mmc_mk_cons(mmc_mk_icon(fmi3_import_get_uint8_variable_start(fmi3_import_get_variable_as_uint8(variable))), mmc_mk_nil());
    case fmi3_base_type_bool:
      return mmc_mk_cons(mmc_mk_bcon(fmi3_import_get_boolean_variable_start(fmi3_import_get_variable_as_boolean(variable))), mmc_mk_nil());
    case fmi3_base_type_str:
      return mmc_mk_cons(mmc_mk_scon_check_null(fmi3_import_get_string_variable_start(fmi3_import_get_variable_as_string(variable))), mmc_mk_nil());
    case fmi3_base_type_enum:
      return mmc_mk_cons(mmc_mk_icon((int)fmi3_import_get_enum_variable_start(fmi3_import_get_variable_as_enum(variable))), mmc_mk_nil());
    case fmi3_base_type_binary:
    case fmi3_base_type_clock:
    default:
      return mmc_mk_nil();
  }
}

/*
 * Makes the string safe by removing special characters. Returns a malloc'd string that should be
 * free'd.
 */
char* makeStringFMISafe(const char* str) {
  char* res = omc_strdup(str);
  int length = strlen(res);

  charReplace(res, length, '.', '_');
  charReplace(res, length, '[', '_');
  charReplace(res, length, ']', '_');
  charReplace(res, length, ' ', '_');
  charReplace(res, length, ',', '_');
  charReplace(res, length, '(', '_');
  charReplace(res, length, ')', '_');
  return res;
}

/*
 * Reads the model variable name. Returns a malloc'd string that should be
 * free'd.
 */
char* getFMI1ModelVariableName(fmi1_import_variable_t* variable)
{
  const char* name = fmi1_import_get_variable_name(variable);
  return makeStringFMISafe(name);
}

/*
 * Reads the model variable name. Returns a malloc'd string that should be
 * free'd.
 */
char* getFMI2ModelVariableName(fmi2_import_variable_t* variable)
{
  const char* name = fmi2_import_get_variable_name(variable);
  return makeStringFMISafe(name);
}

/*
 * Reads the model variable name, FMI 3.0. Returns a malloc'd string that should be
 * free'd.
 */
char* getFMI3ModelVariableName(fmi3_import_variable_t* variable)
{
  const char* name = fmi3_import_get_variable_name(variable);
  return makeStringFMISafe(name);
}

/*
 * Reads the model variable start value.
 */
void* getFMI1ModelVariableStartValue(fmi1_import_variable_t* variable, int hasStartValue)
{
  fmi1_base_type_enu_t type = fmi1_import_get_variable_base_type(variable);
  fmi1_import_real_variable_t* fmiRealModelVariable;
  fmi1_import_integer_variable_t* fmiIntegerModelVariable;
  fmi1_import_bool_variable_t* fmiBooleanModelVariable;
  fmi1_import_string_variable_t* fmiStringModelVariable;
  fmi1_import_enum_variable_t* fmiEnumerationModelVariable;
  switch (type) {
    case fmi1_base_type_real:
      if (!hasStartValue) return mmc_mk_rcon(0);
      fmiRealModelVariable = fmi1_import_get_variable_as_real(variable);
      return fmiRealModelVariable ? mmc_mk_rcon(fmi1_import_get_real_variable_start(fmiRealModelVariable)) : mmc_mk_rcon(0);
    case fmi1_base_type_int:
      if (!hasStartValue) return mmc_mk_icon(0);
      fmiIntegerModelVariable = fmi1_import_get_variable_as_integer(variable);
      return fmiIntegerModelVariable ? mmc_mk_icon(fmi1_import_get_integer_variable_start(fmiIntegerModelVariable)) : mmc_mk_icon(0);
    case fmi1_base_type_bool:
      if (!hasStartValue) return mmc_mk_bcon(0);
      fmiBooleanModelVariable = fmi1_import_get_variable_as_boolean(variable);
      return fmiBooleanModelVariable ? mmc_mk_bcon(fmi1_import_get_boolean_variable_start(fmiBooleanModelVariable)) : mmc_mk_bcon(0);
    case fmi1_base_type_str:
      if (!hasStartValue) return mmc_mk_scon_check_null("");
      fmiStringModelVariable = fmi1_import_get_variable_as_string(variable);
      return mmc_mk_scon_check_null(fmi1_import_get_string_variable_start(fmiStringModelVariable));
    case fmi1_base_type_enum:
      if (!hasStartValue) return mmc_mk_icon(0);
      fmiEnumerationModelVariable = fmi1_import_get_variable_as_enum(variable);
      return fmiEnumerationModelVariable ? mmc_mk_icon(fmi1_import_get_enum_variable_start(fmiEnumerationModelVariable)) : mmc_mk_icon(0);
    default:
      return 0;
  }
}

/*
 * Reads the model variable start value.
 */
void* getFMI2ModelVariableStartValue(fmi2_import_variable_t* variable, int hasStartValue)
{
  fmi2_base_type_enu_t type = fmi2_import_get_variable_base_type(variable);
  fmi2_import_real_variable_t* fmiRealModelVariable;
  fmi2_import_integer_variable_t* fmiIntegerModelVariable;
  fmi2_import_bool_variable_t* fmiBooleanModelVariable;
  fmi2_import_string_variable_t* fmiStringModelVariable;
  fmi2_import_enum_variable_t* fmiEnumerationModelVariable;
  switch (type) {
    case fmi2_base_type_real:
      if (!hasStartValue) return mmc_mk_rcon(0);
      fmiRealModelVariable = fmi2_import_get_variable_as_real(variable);
      return fmiRealModelVariable ? mmc_mk_rcon(fmi2_import_get_real_variable_start(fmiRealModelVariable)) : mmc_mk_rcon(0);
    case fmi2_base_type_int:
      if (!hasStartValue) return mmc_mk_icon(0);
      fmiIntegerModelVariable = fmi2_import_get_variable_as_integer(variable);
      return fmiIntegerModelVariable ? mmc_mk_icon(fmi2_import_get_integer_variable_start(fmiIntegerModelVariable)) : mmc_mk_icon(0);
    case fmi2_base_type_bool:
      if (!hasStartValue) return mmc_mk_bcon(0);
      fmiBooleanModelVariable = fmi2_import_get_variable_as_boolean(variable);
      return fmiBooleanModelVariable ? mmc_mk_bcon(fmi2_import_get_boolean_variable_start(fmiBooleanModelVariable)) : mmc_mk_bcon(0);
    case fmi2_base_type_str:
      if (!hasStartValue) return mmc_mk_scon_check_null("");
      fmiStringModelVariable = fmi2_import_get_variable_as_string(variable);
      return mmc_mk_scon_check_null(fmi2_import_get_string_variable_start(fmiStringModelVariable));
    case fmi2_base_type_enum:
      if (!hasStartValue) return mmc_mk_icon(0);
      fmiEnumerationModelVariable = fmi2_import_get_variable_as_enum(variable);
      return fmiEnumerationModelVariable ? mmc_mk_icon(fmi2_import_get_enum_variable_start(fmiEnumerationModelVariable)) : mmc_mk_icon(0);
    default:
      return 0;
  }
}

/*
 * Initializes FMI 1.0 Import.
 */
void FMIImpl__initializeFMI1Import(fmi1_import_t* fmi, void** fmiInfo, fmi_version_enu_t version, void** typeDefinitionsList, void** experimentAnnotation,
    void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  /* Read the model name from FMU's modelDescription.xml file. */
  const char* modelName = fmi1_import_get_model_name(fmi);
  /* Read the FMI type */
  fmi1_fmu_kind_enu_t fmiType = fmi1_import_get_fmu_kind(fmi);
  /* Read the model identifier from FMU's modelDescription.xml file. */
  const char* modelIdentifier = fmi1_import_get_model_identifier(fmi);
  /* Read the FMI GUID from FMU's modelDescription.xml file. */
  const char* guid = fmi1_import_get_GUID(fmi);
  /* Read the FMI description from FMU's modelDescription.xml file. */
  const char* description = fmi1_import_get_description(fmi);
  /* Read the FMI generation tool from FMU's modelDescription.xml file. */
  const char* generationTool = fmi1_import_get_generation_tool(fmi);
  /* Read the FMI generation date and time from FMU's modelDescription.xml file. */
  const char* generationDateAndTime = fmi1_import_get_generation_date_and_time(fmi);
  /* Read the FMI Variable Naming convention from FMU's modelDescription.xml file. */
  const char* namingConvention = fmi1_naming_convention_to_string(fmi1_import_get_naming_convention(fmi));
  /* Read the FMI number of continuous states from FMU's modelDescription.xml file. */
  unsigned int numberOfContinuousStates = fmi1_import_get_number_of_continuous_states(fmi);
  /* Read the FMI number of event indicators from FMU's modelDescription.xml file. */
  unsigned int numberOfEventIndicators = fmi1_import_get_number_of_event_indicators(fmi);
  /* construct continuous states list record */
  int i = 1;
  void* continuousStatesList = mmc_mk_nil();
  void* eventIndicatorsList = mmc_mk_nil();
  void* enumItems = mmc_mk_nil();
  fmi1_import_type_definitions_t* typeDefinitions = NULL;
  size_t typeDefinitionsSize;
  /* Read the FMI Default Experiment Start value from FMU's modelDescription.xml file. */
  double experimentStartTime = fmi1_import_get_default_experiment_start(fmi);
  /* Read the FMI Default Experiment Stop value from FMU's modelDescription.xml file. */
  double experimentStopTime = fmi1_import_get_default_experiment_stop(fmi);
  /* Read the FMI Default Experiment Tolerance value from FMU's modelDescription.xml file. */
  double experimentTolerance = fmi1_import_get_default_experiment_tolerance(fmi);
  /* Read the model variables from the FMU's modelDescription.xml file and create a list of it. */
  fmi1_import_variable_list_t* model_variables_list = fmi1_import_get_variable_list(fmi);
  size_t model_variables_list_size = fmi1_import_get_variable_list_size(model_variables_list);
  /* get model variables value reference list */
  const fmi1_value_reference_t* model_variables_value_reference_list = fmi1_import_get_value_referece_list(model_variables_list);
  int xInputPlacement = -120;
  int yInputPlacement = 60;
  int xOutputPlacement = 100;
  int yOutputPlacement = 60;

  if (description != NULL) {
    int hasEscape = 0;
    omc__escapedStringLength(description,0,&hasEscape);
    if (hasEscape) {
      description = (const char*)omc__escapedString(description,0);
    }
  } else {
    description = "";
  }

  for (; i <= numberOfContinuousStates ; i++) {
    continuousStatesList = mmc_mk_cons(mmc_mk_icon(i), continuousStatesList);
  }
  /* construct event indicators list record */
  i = 1;
  for (; i <= numberOfEventIndicators ; i++) {
    eventIndicatorsList = mmc_mk_cons(mmc_mk_icon(i), eventIndicatorsList);
  }
  /* construct FMIINFO record */
  *fmiInfo = FMI__INFO(mmc_mk_scon_check_null(fmi_version_to_string(version)), mmc_mk_icon(fmiType), mmc_mk_scon_check_null(modelName), mmc_mk_scon_check_null(modelIdentifier), mmc_mk_scon_check_null(guid), mmc_mk_scon_check_null(description),
      mmc_mk_scon_check_null(generationTool), mmc_mk_scon_check_null(generationDateAndTime), mmc_mk_scon_check_null(namingConvention), continuousStatesList, eventIndicatorsList);
  /* get the type definitions */
  typeDefinitions = fmi1_import_get_type_definitions(fmi);
  typeDefinitionsSize = typeDefinitions ? fmi1_import_get_type_definition_number(typeDefinitions) : 0;
  i = 0;
  *typeDefinitionsList = mmc_mk_nil();
  for (; i < typeDefinitionsSize ; i++) {
    fmi1_import_variable_typedef_t* variableTypeDef = fmi1_import_get_typedef(typeDefinitions, i);
    const char* name = fmi1_import_get_type_name(variableTypeDef);
    char* name_safe = makeStringFMISafe(name);
    void* typeName = mmc_mk_scon_check_null(name_safe);
    fmi1_import_enumeration_typedef_t* enumTypeDef = NULL;
    const char* description = fmi1_import_get_type_description(variableTypeDef);
    const char* quantity = "";
    int min = 0;
    int max = 0;
    unsigned int itemsSize = 0;
    free(name_safe);
    /* check if type is enum */
    if (fmi1_import_get_base_type(variableTypeDef) != fmi1_base_type_enum) {
      continue;
    }
    /* get the TypeDefinition as EnumerationType */
    enumTypeDef = fmi1_import_get_type_as_enum(variableTypeDef);
    enumItems = mmc_mk_nil();
    if (enumTypeDef) {
      void* enumItem = NULL;
      unsigned int j;
      quantity = fmi1_import_get_type_quantity(variableTypeDef);
      min = fmi1_import_get_enum_type_min(enumTypeDef);
      max = fmi1_import_get_enum_type_max(enumTypeDef);
      itemsSize = fmi1_import_get_enum_type_size(enumTypeDef);
      /* get the enumeration items. Loop the items in reverse order so that they are stored in correct order. */
      for (j = itemsSize; j > 0 ; j--) {
        const char* itemName = fmi1_import_get_enum_type_item_name(enumTypeDef, j);
        const char* itemDescription = fmi1_import_get_enum_type_item_description(enumTypeDef, j);
        enumItem = FMI__ENUMERATIONITEM(mmc_mk_scon_check_null(itemName), mmc_mk_scon_check_null(itemDescription));
        enumItems = mmc_mk_cons(enumItem, enumItems);
      }
    }
    *typeDefinitionsList = mmc_mk_cons(FMI__ENUMERATIONTYPE(typeName, mmc_mk_scon_check_null(description), mmc_mk_scon_check_null(quantity), mmc_mk_icon(min), mmc_mk_icon(max), enumItems), *typeDefinitionsList);
  }
  /* construct FMIEXPERIMENTANNOTATION record */
  *experimentAnnotation = FMI__EXPERIMENTANNOTATION(mmc_mk_rcon(experimentStartTime), mmc_mk_rcon(experimentStopTime), mmc_mk_rcon(experimentTolerance));
  *modelVariablesInstance = mmc_mk_some(model_variables_list);
  i = 0;
  *modelVariablesList = mmc_mk_nil();
  for (; i < model_variables_list_size ; i++) {
    fmi1_import_variable_t* model_variable = fmi1_import_get_variable(model_variables_list, i);
    void* variable_instance = mmc_mk_icon((intptr_t)model_variable);
    char *name = getFMI1ModelVariableName(model_variable);
    void* variable_name = mmc_mk_scon_check_null(name);
    const char* description = fmi1_import_get_variable_description(model_variable);
    const char* base_type = getFMI1ModelVariableBaseType(model_variable);
    char* base_type_safe = makeStringFMISafe(base_type);
    void* variable_base_type = mmc_mk_scon_check_null(base_type_safe);
    void* variable_variability = mmc_mk_scon_check_null(getFMI1ModelVariableVariability(model_variable));
    const char* causality = getFMI1ModelVariableCausality(model_variable);
    void* variable_causality = mmc_mk_scon_check_null(causality);
    int hasStartValue = fmi1_import_get_variable_has_start(model_variable);
    void* variable_has_start_value = mmc_mk_bcon(hasStartValue);
    void* variable_start_value = getFMI1ModelVariableStartValue(model_variable, hasStartValue);
    void* variable_is_fixed = mmc_mk_bcon(fmi1_import_get_variable_is_fixed(model_variable));
    void* variable_value_reference = mmc_mk_rcon((double)model_variables_value_reference_list[i]);
    void* variable_x1_placement = mmc_mk_icon(0);
    void* variable_x2_placement = mmc_mk_icon(0);
    void* variable_y1_placement = mmc_mk_icon(0);
    void* variable_y2_placement = mmc_mk_icon(0);
    void* variable_description = NULL;
    void* variable = NULL;
    fmi1_base_type_enu_t type = fmi1_import_get_variable_base_type(model_variable);
    free(base_type_safe);
    free(name);
    if (description != NULL) {
      int hasEscape = 0;
      omc__escapedStringLength(description,0,&hasEscape);
      if (hasEscape) {
        description = (const char*)omc__escapedString(description,0);
      }
    } else {
      description = "";
    }
    variable_description = mmc_mk_scon_check_null(description);
    if ((strcmp(causality,"input") == 0) && input_connectors) {
      variable_x1_placement = mmc_mk_icon(xInputPlacement);
      variable_x2_placement = mmc_mk_icon(xInputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yInputPlacement);
      variable_y2_placement = mmc_mk_icon(yInputPlacement+20);
      yInputPlacement -= 25;
    } else if ((strcmp(causality,"output") == 0) && output_connectors) {
      variable_x1_placement = mmc_mk_icon(xOutputPlacement);
      variable_x2_placement = mmc_mk_icon(xOutputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yOutputPlacement);
      variable_y2_placement = mmc_mk_icon(yOutputPlacement+20);
      yOutputPlacement -= 25;
    }
    //fprintf(stderr, "%s Variable name = %s, valueReference = %d\n", getFMI1ModelVariableBaseType(model_variable), getFMI1ModelVariableName(model_variable), model_variables_value_reference_list[i]);fflush(NULL);
    switch (type) {
      case fmi1_base_type_real:
        variable = FMI__REALVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi1_base_type_int:
        variable = FMI__INTEGERVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi1_base_type_bool:
        variable = FMI__BOOLEANVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi1_base_type_str:
        variable = FMI__STRINGVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi1_base_type_enum:
        variable = FMI__ENUMERATIONVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
    }
    *modelVariablesList = mmc_mk_cons(variable, *modelVariablesList);
  }
}

void FMIImpl__initializeFMI2Import(fmi2_import_t* fmi, void** fmiInfo, fmi_version_enu_t version, void** typeDefinitionsList, void** experimentAnnotation,
    void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  /* Read the model name from FMU's modelDescription.xml file. */
  const char* modelName = fmi2_import_get_model_name(fmi);
  /* Read the FMI type */
  fmi2_fmu_kind_enu_t fmiType = fmi2_import_get_fmu_kind(fmi);
  /* Read the FMI GUID from FMU's modelDescription.xml file. */
  const char* guid = fmi2_import_get_GUID(fmi);
  /* Read the FMI description from FMU's modelDescription.xml file. */
  const char* description = fmi2_import_get_description(fmi);
  /* Read the model identifier from FMU's modelDescription.xml file. */
  const char* modelIdentifier = NULL;
  /* Read the FMI generation tool from FMU's modelDescription.xml file. */
  const char* generationTool = fmi2_import_get_generation_tool(fmi);
  /* Read the FMI generation date and time from FMU's modelDescription.xml file. */
  const char* generationDateAndTime = fmi2_import_get_generation_date_and_time(fmi);
  /* Read the FMI Variable Naming convention from FMU's modelDescription.xml file. */
  const char* namingConvention = fmi2_naming_convention_to_string(fmi2_import_get_naming_convention(fmi));
  /* Read the FMI number of continuous states from FMU's modelDescription.xml file. */
  unsigned int numberOfContinuousStates = fmi2_import_get_number_of_continuous_states(fmi);
  /* Read the FMI number of event indicators from FMU's modelDescription.xml file. */
  unsigned int numberOfEventIndicators = fmi2_import_get_number_of_event_indicators(fmi);
  /* construct continuous states list record */
  int i = 1;
  void* continuousStatesList = mmc_mk_nil();
  void* eventIndicatorsList = mmc_mk_nil();
  fmi2_import_type_definitions_t* typeDefinitions = fmi2_import_get_type_definitions(fmi);
  size_t typeDefinitionsSize = typeDefinitions ? fmi2_import_get_type_definition_number(typeDefinitions) : 0;
  void* enumItems = mmc_mk_nil();
  /* Read the FMI Default Experiment Start value from FMU's modelDescription.xml file. */
  double experimentStartTime = fmi2_import_get_default_experiment_start(fmi);
  /* Read the FMI Default Experiment Stop value from FMU's modelDescription.xml file. */
  double experimentStopTime = fmi2_import_get_default_experiment_stop(fmi);
  /* Read the FMI Default Experiment Tolerance value from FMU's modelDescription.xml file. */
  double experimentTolerance = fmi2_import_get_default_experiment_tolerance(fmi);
  /* Read the model variables from the FMU's modelDescription.xml file and create a list of it. */
  int sortOrder = 0;
  /* sortOrder specifies the order of the variables in the list: 0 - original order as found
  in the XML file; 1 - sorted alfabetically by variable name; 2 sorted by
  types/value references. */
  fmi2_import_variable_list_t* model_variables_list = fmi2_import_get_variable_list(fmi, sortOrder);
  size_t model_variables_list_size = fmi2_import_get_variable_list_size(model_variables_list);
  /* get model variables value reference list */
  const fmi2_value_reference_t* model_variables_value_reference_list = fmi2_import_get_value_referece_list(model_variables_list);
  int xInputPlacement = -120;
  int yInputPlacement = 60;
  int xOutputPlacement = 100;
  int yOutputPlacement = 60;

  switch (fmiType) {
    case fmi2_fmu_kind_me:
    case fmi2_fmu_kind_me_and_cs:
      modelIdentifier = fmi2_import_get_model_identifier_ME(fmi);
      fmiType = fmi2_fmu_kind_me;
      break;
    case fmi2_fmu_kind_cs:
      modelIdentifier = fmi2_import_get_model_identifier_CS(fmi);
      break;
    default: break;
  }
  if (description != NULL) {
    int hasEscape = 0;
    omc__escapedStringLength(description,0,&hasEscape);
    if (hasEscape) {
      description = (const char*)omc__escapedString(description,0);
    }
  } else {
    description = "";
  }
  for (; i <= numberOfContinuousStates ; i++) {
    continuousStatesList = mmc_mk_cons(mmc_mk_icon(i), continuousStatesList);
  }
  /* construct event indicators list record */
  i = 1;
  for (; i <= numberOfEventIndicators ; i++) {
    eventIndicatorsList = mmc_mk_cons(mmc_mk_icon(i), eventIndicatorsList);
  }
  /* construct FMIINFO record */
  *fmiInfo = FMI__INFO(mmc_mk_scon_check_null(fmi_version_to_string(version)), mmc_mk_icon(fmiType), mmc_mk_scon_check_null(modelName), mmc_mk_scon_check_null(modelIdentifier), mmc_mk_scon_check_null(guid), mmc_mk_scon_check_null(description),
      mmc_mk_scon_check_null(generationTool), mmc_mk_scon_check_null(generationDateAndTime), mmc_mk_scon_check_null(namingConvention), continuousStatesList, eventIndicatorsList);

  *typeDefinitionsList = mmc_mk_nil();

  for(i = 0; i < typeDefinitionsSize; ++i) {
    fmi2_import_variable_typedef_t* variableTypeDef = fmi2_import_get_typedef(typeDefinitions, i);
    const char* name = fmi2_import_get_type_name(variableTypeDef);
    char* name_safe = makeStringFMISafe(name);
    void* typeName = mmc_mk_scon_check_null(name_safe);
    const char* description = fmi2_import_get_type_description(variableTypeDef);
    fmi2_import_enumeration_typedef_t* enumTypeDef = NULL;
    const char* quantity = "";
    int min = 0;
    int max = 0;
    unsigned itemsSize = 0;
    void* enumItem = NULL;

    enumItems = mmc_mk_nil();

    free(name_safe);

    /* check if type is enum */
    if(fmi2_import_get_base_type(variableTypeDef) != fmi1_base_type_enum) {
      continue;
    }

    /* get the TypeDefinition as EnumerationType */
    enumTypeDef = fmi2_import_get_type_as_enum(variableTypeDef);

    if(enumTypeDef) {
      unsigned j;
      quantity = fmi2_import_get_type_quantity(variableTypeDef);
      min = fmi2_import_get_enum_type_min(enumTypeDef);
      max = fmi2_import_get_enum_type_max(enumTypeDef);
      itemsSize = fmi2_import_get_enum_type_size(enumTypeDef);

      for(j = itemsSize; j > 0; --j) {
        const char* itemName = fmi2_import_get_enum_type_item_name(enumTypeDef, j);
        const char* itemDescription = fmi2_import_get_enum_type_item_description(enumTypeDef, j);
        enumItem = FMI__ENUMERATIONITEM(mmc_mk_scon_check_null(itemName), mmc_mk_scon_check_null(itemDescription));
        enumItems = mmc_mk_cons(enumItem, enumItems);
      }
    }

    *typeDefinitionsList = mmc_mk_cons(FMI__ENUMERATIONTYPE(typeName, mmc_mk_scon_check_null(description), mmc_mk_scon_check_null(quantity), mmc_mk_icon(min), mmc_mk_icon(max), enumItems), *typeDefinitionsList);
  }

  *experimentAnnotation = FMI__EXPERIMENTANNOTATION(mmc_mk_rcon(experimentStartTime), mmc_mk_rcon(experimentStopTime), mmc_mk_rcon(experimentTolerance));
  *modelVariablesInstance = mmc_mk_some(model_variables_list);
  i = 0;
  *modelVariablesList = mmc_mk_nil();
  for (; i < model_variables_list_size ; i++) {
    fmi2_import_variable_t* model_variable = fmi2_import_get_variable(model_variables_list, i);
    void* variable_instance = mmc_mk_icon((intptr_t)model_variable);
    char *name = getFMI2ModelVariableName(model_variable);
    void* variable_name = mmc_mk_scon_check_null(name);
    const char* description = fmi2_import_get_variable_description(model_variable);
    void* variable_description = NULL;
    const char* base_type = getFMI2ModelVariableBaseType(model_variable);
    char* base_type_safe = makeStringFMISafe(base_type);
    void* variable_base_type = mmc_mk_scon_check_null(base_type_safe);
    void* variable_variability = mmc_mk_scon_check_null(getFMI2ModelVariableVariability(model_variable));
    const char* causality = getFMI2ModelVariableCausality(model_variable);
    void* variable_causality = mmc_mk_scon_check_null(causality);
    int hasStartValue = fmi2_import_get_variable_has_start(model_variable);
    void* variable_has_start_value = mmc_mk_bcon(hasStartValue);
    void* variable_start_value = getFMI2ModelVariableStartValue(model_variable, hasStartValue);
    void* variable_is_fixed = (fmi2_import_get_variability(model_variable) == fmi2_variability_enu_fixed) ? mmc_mk_bcon(1) : mmc_mk_bcon(0);
    void* variable_value_reference = mmc_mk_rcon((double)model_variables_value_reference_list[i]);
    void* variable_x1_placement = mmc_mk_icon(0);
    void* variable_x2_placement = mmc_mk_icon(0);
    void* variable_y1_placement = mmc_mk_icon(0);
    void* variable_y2_placement = mmc_mk_icon(0);
    void* variable = NULL;
    fmi2_base_type_enu_t type = fmi2_import_get_variable_base_type(model_variable);
    free(base_type_safe);
    free(name);
    if (description != NULL) {
      int hasEscape = 0;
      omc__escapedStringLength(description,0,&hasEscape);
      if (hasEscape) {
        description = (const char*)omc__escapedString(description,0);
      }
    } else {
      description = "";
    }
    variable_description = mmc_mk_scon_check_null(description);
    if ((strcmp(causality,"input") == 0) && input_connectors) {
      variable_x1_placement = mmc_mk_icon(xInputPlacement);
      variable_x2_placement = mmc_mk_icon(xInputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yInputPlacement);
      variable_y2_placement = mmc_mk_icon(yInputPlacement+20);
      yInputPlacement -= 25;
    } else if ((strcmp(causality,"output") == 0) && output_connectors) {
      variable_x1_placement = mmc_mk_icon(xOutputPlacement);
      variable_x2_placement = mmc_mk_icon(xOutputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yOutputPlacement);
      variable_y2_placement = mmc_mk_icon(yOutputPlacement+20);
      yOutputPlacement -= 25;
    }
    //fprintf(stderr, "%s Variable name = %s, valueReference = %d\n", getFMI2ModelVariableBaseType(model_variable), getFMI2ModelVariableName(model_variable), model_variables_value_reference_list[i]);fflush(NULL);
    switch (type) {
      case fmi2_base_type_real:
        variable = FMI__REALVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi2_base_type_int:
        variable = FMI__INTEGERVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi2_base_type_bool:
        variable = FMI__BOOLEANVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi2_base_type_str:
        variable = FMI__STRINGVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi2_base_type_enum:
        variable = FMI__ENUMERATIONVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_variability, variable_causality,
            variable_has_start_value, variable_start_value, variable_is_fixed, variable_value_reference, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
    }
    *modelVariablesList = mmc_mk_cons(variable, *modelVariablesList);
  }
}

/*
 * Reads an FMI 3.0 modelDescription.xml into the records FMI.mo declares for it.
 *
 * The shape follows initializeFMI2Import above; what differs is FMI 3.0's variable
 * model, which has one element per concrete type instead of ScalarVariable with a
 * nested type, allows any variable to be an array, and adds Binary and Clock. Each
 * of those maps to its own record, see FMI.mo.
 */
void FMIImpl__initializeFMI3Import(fmi3_import_t* fmi, void** fmiInfo, fmi_version_enu_t version, void** typeDefinitionsList, void** experimentAnnotation,
    void** modelVariablesInstance, void** modelVariablesList, int input_connectors, int output_connectors)
{
  const char* modelName = fmi3_import_get_model_name(fmi);
  fmi3_fmu_kind_enu_t fmiType = fmi3_import_get_fmu_kind(fmi);
  /* FMI 3.0 calls the GUID an instantiation token */
  const char* instantiationToken = fmi3_import_get_instantiation_token(fmi);
  const char* description = fmi3_import_get_description(fmi);
  const char* modelIdentifier = NULL;
  const char* generationTool = fmi3_import_get_generation_tool(fmi);
  const char* generationDateAndTime = fmi3_import_get_generation_date_and_time(fmi);
  const char* namingConvention = fmi3_naming_convention_to_string(fmi3_import_get_naming_convention(fmi));
  /* FMI 3.0 has no scalar counts in the model description: the numbers come from the
     ModelStructure lists. fmi3_import_get_number_of_continuous_states is a CAPI call
     that needs an instantiated FMU, which we do not have here. */
  fmi3_import_variable_list_t* continuousStateDerivatives = fmi3_import_get_continuous_state_derivatives_list(fmi);
  fmi3_import_variable_list_t* eventIndicators = fmi3_import_get_event_indicators_list(fmi);
  unsigned int numberOfContinuousStates = continuousStateDerivatives ? (unsigned int)fmi3_import_get_variable_list_size(continuousStateDerivatives) : 0;
  unsigned int numberOfEventIndicators = eventIndicators ? (unsigned int)fmi3_import_get_variable_list_size(eventIndicators) : 0;
  int i = 1;
  void* continuousStatesList = mmc_mk_nil();
  void* eventIndicatorsList = mmc_mk_nil();
  fmi3_import_type_definition_list_t* typeDefinitions = fmi3_import_get_type_definition_list(fmi);
  size_t typeDefinitionsSize = typeDefinitions ? fmi3_import_get_type_definition_list_size(typeDefinitions) : 0;
  void* enumItems = mmc_mk_nil();
  double experimentStartTime = fmi3_import_get_default_experiment_start(fmi);
  double experimentStopTime = fmi3_import_get_default_experiment_stop(fmi);
  double experimentTolerance = fmi3_import_get_default_experiment_tolerance(fmi);
  int sortOrder = 0; /* the order the variables appear in the XML */
  fmi3_import_variable_list_t* model_variables_list = fmi3_import_get_variable_list(fmi, sortOrder);
  size_t model_variables_list_size = model_variables_list ? fmi3_import_get_variable_list_size(model_variables_list) : 0;
  int xInputPlacement = -120;
  int yInputPlacement = 60;
  int xOutputPlacement = 100;
  int yOutputPlacement = 60;

  /* An FMU may offer several interface types; take the model identifier of the one we
     import, preferring Model Exchange as the FMI 1.0 and 2.0 paths do. */
  if (fmiType & fmi3_fmu_kind_me) {
    modelIdentifier = fmi3_import_get_model_identifier_ME(fmi);
    fmiType = fmi3_fmu_kind_me;
  } else if (fmiType & fmi3_fmu_kind_cs) {
    modelIdentifier = fmi3_import_get_model_identifier_CS(fmi);
    fmiType = fmi3_fmu_kind_cs;
  } else if (fmiType & fmi3_fmu_kind_se) {
    modelIdentifier = fmi3_import_get_model_identifier_SE(fmi);
    fmiType = fmi3_fmu_kind_se;
  }

  if (description != NULL) {
    int hasEscape = 0;
    omc__escapedStringLength(description,0,&hasEscape);
    if (hasEscape) {
      description = (const char*)omc__escapedString(description,0);
    }
  } else {
    description = "";
  }

  for (; i <= numberOfContinuousStates ; i++) {
    continuousStatesList = mmc_mk_cons(mmc_mk_icon(i), continuousStatesList);
  }
  i = 1;
  for (; i <= numberOfEventIndicators ; i++) {
    eventIndicatorsList = mmc_mk_cons(mmc_mk_icon(i), eventIndicatorsList);
  }

  *fmiInfo = FMI__INFO(mmc_mk_scon_check_null(fmi_version_to_string(version)), mmc_mk_icon(fmiType), mmc_mk_scon_check_null(modelName),
      mmc_mk_scon_check_null(modelIdentifier), mmc_mk_scon_check_null(instantiationToken), mmc_mk_scon_check_null(description),
      mmc_mk_scon_check_null(generationTool), mmc_mk_scon_check_null(generationDateAndTime), mmc_mk_scon_check_null(namingConvention),
      continuousStatesList, eventIndicatorsList);

  *typeDefinitionsList = mmc_mk_nil();
  for (i = 0; i < typeDefinitionsSize; ++i) {
    fmi3_import_variable_typedef_t* variableTypeDef = fmi3_import_get_typedef(typeDefinitions, i);
    const char* name = fmi3_import_get_type_name(variableTypeDef);
    char* name_safe = makeStringFMISafe(name);
    void* typeName = mmc_mk_scon_check_null(name_safe);
    const char* typeDescription = fmi3_import_get_type_description(variableTypeDef);
    fmi3_import_enumeration_typedef_t* enumTypeDef = NULL;
    const char* quantity = "";
    int min = 0;
    int max = 0;

    enumItems = mmc_mk_nil();
    free(name_safe);

    if (fmi3_import_get_base_type(variableTypeDef) != fmi3_base_type_enum) {
      continue;
    }
    enumTypeDef = fmi3_import_get_type_as_enum(variableTypeDef);
    if (enumTypeDef) {
      unsigned j;
      unsigned itemsSize = fmi3_import_get_enum_type_size(enumTypeDef);
      quantity = fmi3_import_get_type_quantity(variableTypeDef);
      min = (int)fmi3_import_get_enum_type_min(enumTypeDef);
      max = (int)fmi3_import_get_enum_type_max(enumTypeDef);
      for (j = itemsSize; j > 0; --j) {
        const char* itemName = fmi3_import_get_enum_type_item_name(enumTypeDef, j);
        const char* itemDescription = fmi3_import_get_enum_type_item_description(enumTypeDef, j);
        enumItems = mmc_mk_cons(FMI__ENUMERATIONITEM(mmc_mk_scon_check_null(itemName), mmc_mk_scon_check_null(itemDescription)), enumItems);
      }
    }
    *typeDefinitionsList = mmc_mk_cons(FMI__ENUMERATIONTYPE(typeName, mmc_mk_scon_check_null(typeDescription), mmc_mk_scon_check_null(quantity),
        mmc_mk_icon(min), mmc_mk_icon(max), enumItems), *typeDefinitionsList);
  }

  *experimentAnnotation = FMI__EXPERIMENTANNOTATION(mmc_mk_rcon(experimentStartTime), mmc_mk_rcon(experimentStopTime), mmc_mk_rcon(experimentTolerance));
  *modelVariablesInstance = mmc_mk_some(model_variables_list);
  *modelVariablesList = mmc_mk_nil();

  for (i = 0; i < model_variables_list_size ; i++) {
    fmi3_import_variable_t* model_variable = fmi3_import_get_variable(model_variables_list, i);
    void* variable_instance = mmc_mk_icon((intptr_t)model_variable);
    char* name = getFMI3ModelVariableName(model_variable);
    void* variable_name = mmc_mk_scon_check_null(name);
    const char* variableDescription = fmi3_import_get_variable_description(model_variable);
    void* variable_description = NULL;
    const char* base_type = getFMI3ModelVariableBaseType(model_variable);
    char* base_type_safe = makeStringFMISafe(base_type);
    void* variable_base_type = mmc_mk_scon_check_null(base_type_safe);
    fmi3_base_type_enu_t type = fmi3_import_get_variable_base_type(model_variable);
    /* the element the FMU used, which the wrapper needs to pick the right setter */
    void* variable_fmi_type = mmc_mk_scon_check_null(fmi3_base_type_to_string(type));
    void* variable_variability = mmc_mk_scon_check_null(getFMI3ModelVariableVariability(model_variable));
    const char* causality = getFMI3ModelVariableCausality(model_variable);
    void* variable_causality = mmc_mk_scon_check_null(causality);
    int hasStartValue = fmi3_import_get_variable_has_start(model_variable);
    void* variable_has_start_value = mmc_mk_bcon(hasStartValue);
    void* variable_start_value = getFMI3ModelVariableStartValue(model_variable, hasStartValue);
    void* variable_is_fixed = (fmi3_import_get_variable_variability(model_variable) == fmi3_variability_enu_fixed) ? mmc_mk_bcon(1) : mmc_mk_bcon(0);
    /* FMI 3.0 value references are UInt32, so they stay integers here */
    void* variable_value_reference = mmc_mk_icon((int)fmi3_import_get_variable_vr(model_variable));
    void* variable_dimensions = getFMI3ModelVariableDimensions(model_variable);
    void* variable_x1_placement = mmc_mk_icon(0);
    void* variable_x2_placement = mmc_mk_icon(0);
    void* variable_y1_placement = mmc_mk_icon(0);
    void* variable_y2_placement = mmc_mk_icon(0);
    void* variable = NULL;

    free(base_type_safe);
    free(name);

    if (variableDescription != NULL) {
      int hasEscape = 0;
      omc__escapedStringLength(variableDescription,0,&hasEscape);
      if (hasEscape) {
        variableDescription = (const char*)omc__escapedString(variableDescription,0);
      }
    } else {
      variableDescription = "";
    }
    variable_description = mmc_mk_scon_check_null(variableDescription);

    if ((strcmp(causality,"input") == 0) && input_connectors) {
      variable_x1_placement = mmc_mk_icon(xInputPlacement);
      variable_x2_placement = mmc_mk_icon(xInputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yInputPlacement);
      variable_y2_placement = mmc_mk_icon(yInputPlacement+20);
      yInputPlacement -= 25;
    } else if ((strcmp(causality,"output") == 0) && output_connectors) {
      variable_x1_placement = mmc_mk_icon(xOutputPlacement);
      variable_x2_placement = mmc_mk_icon(xOutputPlacement+20);
      variable_y1_placement = mmc_mk_icon(yOutputPlacement);
      variable_y2_placement = mmc_mk_icon(yOutputPlacement+20);
      yOutputPlacement -= 25;
    }

    switch (type) {
      case fmi3_base_type_float64:
      case fmi3_base_type_float32:
        variable = FMI__FMI3REALVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_int64:
      case fmi3_base_type_int32:
      case fmi3_base_type_int16:
      case fmi3_base_type_int8:
      case fmi3_base_type_uint64:
      case fmi3_base_type_uint32:
      case fmi3_base_type_uint16:
      case fmi3_base_type_uint8:
        variable = FMI__FMI3INTEGERVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_bool:
        variable = FMI__FMI3BOOLEANVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_str:
        variable = FMI__FMI3STRINGVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions, variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_binary:
        variable = FMI__FMI3BINARYVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions,
            mmc_mk_scon_check_null(fmi3_import_get_binary_variable_mime_type(fmi3_import_get_variable_as_binary(model_variable))),
            mmc_mk_icon((int)fmi3_import_get_binary_variable_max_size(fmi3_import_get_variable_as_binary(model_variable))),
            variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_clock:
        variable = FMI__FMI3CLOCKVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions,
            mmc_mk_scon_check_null(getFMI3IntervalVariability(fmi3_import_get_clock_variable_interval_variability(fmi3_import_get_variable_as_clock(model_variable)))),
            mmc_mk_rcon(fmi3_import_get_clock_variable_interval_decimal(fmi3_import_get_variable_as_clock(model_variable))),
            mmc_mk_bcon(fmi3_import_get_clock_variable_has_interval_decimal(fmi3_import_get_variable_as_clock(model_variable))),
            variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      case fmi3_base_type_enum:
        variable = FMI__FMI3ENUMERATIONVARIABLE(variable_instance, variable_name, variable_description, variable_base_type, variable_fmi_type,
            variable_variability, variable_causality, variable_has_start_value, variable_start_value, variable_is_fixed,
            variable_value_reference, variable_dimensions, variable_base_type,
            variable_x1_placement, variable_x2_placement, variable_y1_placement, variable_y2_placement);
        break;
      default:
        break;
    }
    if (variable) {
      *modelVariablesList = mmc_mk_cons(variable, *modelVariablesList);
    }
  }
}

/*
 * Initializes FMI Import.
 * Reads the Model Identifier name.
 * Reads the experiment annotation.
 * Reads the model variables.
 */
int FMIImpl__initializeFMIImport(const char* file_name, const char* working_directory, int fmi_log_level, int input_connectors, int output_connectors, int isModelDescriptionImport,
    void** fmiContext, void** fmiInstance, void** fmiInfo, void** typeDefinitionsList, void** experimentAnnotation, void** modelVariablesInstance, void** modelVariablesList)
{
  // JM callbacks
  static jm_callbacks callbacks;
  static int init_jm_callbacks = 0;
  fmi_import_context_t* context;
  fmi_version_enu_t version;
  *fmiContext = mmc_mk_some(0);
  *fmiInstance = mmc_mk_some(0);
  *fmiInfo = NULL;
  *typeDefinitionsList = NULL;
  *experimentAnnotation = NULL;
  *modelVariablesInstance = mmc_mk_some(0);
  *modelVariablesList = NULL;
  if (!init_jm_callbacks) {
    init_jm_callbacks = 1;
    callbacks.malloc = malloc;
    callbacks.calloc = calloc;
    callbacks.realloc = realloc;
    callbacks.free = free;
    callbacks.logger = importlogger;
    callbacks.log_level = fmi_log_level;
    callbacks.context = 0;
  }
  context = fmi_import_allocate_context(&callbacks);
  *fmiContext = mmc_mk_some(context);
  // extract the fmu file and read the version
  version = fmi_import_get_fmi_version(context, file_name, working_directory);
  if ((version <= fmi_version_unknown_enu) || (version >= fmi_version_unsupported_enu)) {
    const char* tokens[1] = {fmi_version_to_string(version)};
    fmi_import_free_context(context);
    c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("The FMU version is %s. Unknown/Unsupported FMU version."), tokens, 1);
    return 0;
  }
  if (version == fmi_version_1_enu) {
    static int init_fmi1_callback_functions = 0;
    // FMI callback functions
    static fmi1_callback_functions_t fmi1_callback_functions;
    fmi1_import_t* fmi;
    if (!init_fmi1_callback_functions) {
      init_fmi1_callback_functions = 1;
      fmi1_callback_functions.logger = fmi1logger;
      fmi1_callback_functions.allocateMemory = calloc;
      fmi1_callback_functions.freeMemory = free;
    }
    // parse the xml file
    fmi = fmi1_import_parse_xml(context, working_directory);
    if(!fmi) {
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing the modelDescription.xml file."), NULL, 0);
      return 0;
    }
    *fmiInstance = mmc_mk_some(fmi);
    /* Loading the binary (dll/so) can mess up the compiler, and the information is unused in the compiler */
#if 0
    jm_status_enu_t status;
    status = fmi1_import_create_dllfmu(fmi, fmi1_callback_functions, 0);
    if (status == jm_status_error) {
      fmi1_import_free(fmi);
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Loading of FMU dynamic link library failed."), NULL, 0);
      return 0;
    }
#endif
    FMIImpl__initializeFMI1Import(fmi, fmiInfo, version, typeDefinitionsList, experimentAnnotation, modelVariablesInstance, modelVariablesList, input_connectors, output_connectors);
  } else if (version == fmi_version_2_0_enu) {
    static int init_fmi2_callback_functions = 0;
    // FMI callback functions
    static fmi2_callback_functions_t fmi2_callback_functions;
    fmi2_import_t* fmi;
    fmi2_fmu_kind_enu_t fmiType;
    if (!init_fmi2_callback_functions) {
      init_fmi2_callback_functions = 1;
      fmi2_callback_functions.logger = fmi2logger;
      fmi2_callback_functions.allocateMemory = calloc;
      fmi2_callback_functions.freeMemory = free;
    }
    // parse the xml file
    fmi = fmi2_import_parse_xml(context, working_directory, NULL);
    if(!fmi) {
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing the modelDescription.xml file."), NULL, 0);
      return 0;
    }
    /* remove the following block once we have support for FMI 2.0 CS. */
    fmiType = fmi2_import_get_fmu_kind(fmi);
    if (!isModelDescriptionImport && (fmiType == fmi2_fmu_kind_cs)) {
      const char* tokens[1] = {fmi2_fmu_kind_to_string(fmiType)};
      fmi2_import_free(fmi);
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("The FMU version is 2.0 and FMU type is %s. Unsupported FMU type. Only FMI 2.0 ModelExchange is supported."), tokens, 1);
      return 0;
    }
    *fmiInstance = mmc_mk_some(fmi);
    /* Loading the binary (dll/so) can mess up the compiler, and the information is unused in the compiler */
#if 0
    jm_status_enu_t status;
    status = fmi2_import_create_dllfmu(fmi, fmi2_fmu_kind_me, &fmi2_callback_functions);
    if (status == jm_status_error) {
      fmi2_import_free(fmi);
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Loading of FMU dynamic link library failed."), NULL, 0);
      return 0;
    }
#endif
    FMIImpl__initializeFMI2Import(fmi, fmiInfo, version, typeDefinitionsList, experimentAnnotation, modelVariablesInstance, modelVariablesList, input_connectors, output_connectors);
  } else if (version == fmi_version_3_0_enu) {
    fmi3_import_t* fmi;
    /* parse the xml file */
    fmi = fmi3_import_parse_xml(context, working_directory, NULL);
    if (!fmi) {
      fmi_import_free_context(context);
      c_add_message(NULL,-1, ErrorType_scripting, ErrorLevel_error, gettext("Error parsing the modelDescription.xml file."), NULL, 0);
      return 0;
    }
    *fmiInstance = mmc_mk_some(fmi);
    /* The binary is not loaded here for the same reason as in FMI 1.0 and 2.0 above:
       it can upset the compiler and the information is not used. */
    FMIImpl__initializeFMI3Import(fmi, fmiInfo, version, typeDefinitionsList, experimentAnnotation, modelVariablesInstance, modelVariablesList, input_connectors, output_connectors);
  }
  /* everything is OK return success */
  return 1;
}

/*
 * Releases all the instances of FMI Import.
 * From FMIL docs; Free a variable list. Note that variable lists are allocated dynamically and must be freed when not needed any longer.
 */
void FMIImpl__releaseFMIImport(void *ptr1, void *ptr2, void *ptr3, const char* fmiVersion)
{
  intptr_t fmiModeVariablesInstance = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(ptr1),1));
  intptr_t fmiInstance = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(ptr2),1));
  intptr_t fmiContext = (intptr_t)MMC_FETCH(MMC_OFFSET(MMC_UNTAGPTR(ptr3),1));
  if (strcmp(fmiVersion, "1.0") == 0) {
    fmi1_import_t* fmi = (fmi1_import_t*)fmiInstance;
    free((fmi1_import_variable_list_t*)fmiModeVariablesInstance);
    fmi1_import_free(fmi);
  } else if (strcmp(fmiVersion, "2.0") == 0) {
    fmi2_import_t* fmi = (fmi2_import_t*)fmiInstance;
    free((fmi2_import_variable_list_t*)fmiModeVariablesInstance);
    fmi2_import_free(fmi);
  } else if (strcmp(fmiVersion, "3.0") == 0) {
    fmi3_import_t* fmi = (fmi3_import_t*)fmiInstance;
    free((fmi3_import_variable_list_t*)fmiModeVariablesInstance);
    fmi3_import_free(fmi);
  }
  fmi_import_free_context((fmi_import_context_t*)fmiContext);
}

#endif

#ifdef __cplusplus
}
#endif
