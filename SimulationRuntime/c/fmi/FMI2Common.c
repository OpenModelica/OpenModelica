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

#include "FMI2Common.h"

/*
 * Used for logging FMU messages.
 * Logger function used by the FMU 2.0 internally.
 */
void fmi2logger(fmi2_component_t c, fmi2_string_t instanceName, fmi2_status_t status, fmi2_string_t category, fmi2_string_t message, ...)
{
  va_list argp;
  va_start(argp, message);
  fmi2_log_forwarding_v(c, instanceName, status, category, message, argp);
  va_end(argp);
  fflush(NULL);
}

/*
 * OpenModelica uses signed integers and according to FMI specifications the value references should be unsigned integers.
 * So to overcome this we use value references as Real in the Modelica code.
 * This function converts back the value references from double to int and use them in FMI specific functions.
 */
fmi2_value_reference_t* real_to_fmi2_value_reference(int numberOfValueReferences, double* valuesReferences)
{
  fmi2_value_reference_t* valuesReferences_int = malloc(sizeof(fmi2_value_reference_t)*numberOfValueReferences);
  int i;
  for (i = 0 ; i < numberOfValueReferences ; i++)
    valuesReferences_int[i] = (int)valuesReferences[i];
  return valuesReferences_int;
}

/*
 * Wrapper for the FMI function fmiGetReal.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns realValues.
 */
void fmi2GetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double flowStatesInput, double* realValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
    fmi2_import_get_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
    free(valuesReferences_int);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiSetReal.
 * Returns status.
 */
void fmi2SetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double* realValues, double* out_Values, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
    fmi2_import_set_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiGetInteger.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns integerValues.
 */
void fmi2GetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, double flowStatesInput, int* integerValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi2_import_get_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
    free(valuesReferences_int);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiSetInteger.
 * Returns status.
 */
void fmi2SetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, int* integerValues, double* out_Values, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi2_import_set_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiGetBoolean.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns booleanValues.
 */
void fmi2GetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, double flowStatesInput, int* booleanValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, booleanValuesReferences);
    fmi2_import_get_boolean(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_boolean_t*)booleanValues);
    free(valuesReferences_int);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiSetBoolean.
 * Returns status.
 */
void fmi2SetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, int* booleanValues, double* out_Values, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, booleanValuesReferences);
    fmi2_import_set_boolean(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_boolean_t*)booleanValues);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiGetString.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns stringValues.
 */
void fmi2GetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, double flowStatesInput, char** stringValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi2_import_get_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
    free(valuesReferences_int);
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmiSetString.
 * Returns status.
 */
void fmi2SetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, char** stringValues, double* out_Values, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi2_import_set_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
  } else if (fmiType == 2) {

  }
}

#ifdef __cplusplus
}
#endif
