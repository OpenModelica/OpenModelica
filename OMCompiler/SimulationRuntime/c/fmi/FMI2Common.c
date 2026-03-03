/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC),
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

#include "FMI2Common.h"

/**
 * @brief FMU 2.0 internal logger callback.
 *
 * Forwards log messages from the FMU to the FMI library logging machinery.
 *
 * @param c            FMU component instance.
 * @param instanceName Name of the FMU instance.
 * @param status       Severity status of the message.
 * @param category     Log category string.
 * @param message      Printf-style format string.
 */
void fmi2logger(fmi2_component_t c, fmi2_string_t instanceName, fmi2_status_t status, fmi2_string_t category, fmi2_string_t message, ...)
{
  va_list argp;
  va_start(argp, message);
  fmi2_log_forwarding_v(c, instanceName, status, category, message, argp);
  va_end(argp);
  fflush(NULL);
}

/**
 * @brief Convert an array of double-encoded value references to fmi2_value_reference_t.
 *
 * OpenModelica represents value references as Real (double) to avoid signed/unsigned
 * integer mismatches with the FMI specification. This function converts them back to
 * the unsigned integer type required by FMI functions.
 *
 * @param numberOfValueReferences Number of value references to convert.
 * @param valuesReferences        Input array of value references encoded as doubles.
 * @return Newly allocated array of fmi2_value_reference_t; caller must free().
 */
fmi2_value_reference_t* real_to_fmi2_value_reference(int numberOfValueReferences, double* valuesReferences)
{
  fmi2_value_reference_t* valuesReferences_int = malloc(sizeof(fmi2_value_reference_t)*numberOfValueReferences);
  int i;
  for (i = 0 ; i < numberOfValueReferences ; i++) {
    valuesReferences_int[i] = (int)valuesReferences[i];
  }
  return valuesReferences_int;
}

/**
 * @brief Convert Modelica boolean array (signed char) to FMI boolean array (int).
 *
 * @param modelicaBoolean Input array of Modelica booleans.
 * @param fmiBoolean      Output array of FMI booleans.
 * @param size            Number of elements to convert.
 * @return Always returns 0.
 */
int signedchar_to_int(signed char* modelicaBoolean, int* fmiBoolean, int size)
{
  int i;
  for (i = 0; i < size; i++) {
    fmiBoolean[i] = (int) modelicaBoolean[i];
  }
  return 0;
}
/**
 * @brief Convert FMI boolean array (int) to Modelica boolean array (signed char).
 *
 * @param fmiBoolean      Input array of FMI booleans.
 * @param modelicaBoolean Output array of Modelica booleans.
 * @param size            Number of elements to convert.
 * @return Always returns 0.
 */
int int_to_signedchar(int* fmiBoolean, signed char* modelicaBoolean, int size)
{
  int i;
  for (i = 0; i < size; i++) {
    modelicaBoolean[i] = (signed char) fmiBoolean[i];
  }
  return 0;
}

/**
 * @brief Wrapper for fmi2GetReal.
 *
 * @param in_fmi2                 FMI2 model exchange instance.
 * @param numberOfValueReferences Number of value references.
 * @param realValuesReferences    Value references encoded as doubles.
 * @param flowStatesInput         Dummy parameter used to enforce equation ordering.
 * @param realValues              Output array for the retrieved real values.
 */
void fmi2GetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double flowStatesInput, double* realValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
  fmi2_status_t status = fmi2_import_get_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
  free(valuesReferences_int);
  if (status != fmi2_status_ok && status != fmi2_status_warning) {
    ModelicaFormatError("fmi2GetReal failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi2SetReal.
 *
 * Only sets values in instantiated, initialization, event, or continuous-time mode.
 *
 * @param in_fmi2                 FMI2 model exchange instance.
 * @param numberOfValueReferences Number of value references.
 * @param realValuesReferences    Value references encoded as doubles.
 * @param realValues              Real values to set.
 */
void fmi2SetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double* realValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode || FMI2ME->FMISolvingMode == fmi2_continuousTime_mode) {
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
    fmi2_status_t status = fmi2_import_set_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2SetReal failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi2GetInteger.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param integerValuesReferences  Value references encoded as doubles.
 * @param flowStatesInput          Dummy parameter used to enforce equation ordering.
 * @param integerValues            Output array for the retrieved integer values.
 */
void fmi2GetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, double flowStatesInput, int* integerValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
  fmi2_status_t status = fmi2_import_get_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
  free(valuesReferences_int);
  if (status != fmi2_status_ok && status != fmi2_status_warning) {
    ModelicaFormatError("fmi2GetInteger failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi2SetInteger.
 *
 * Only sets values in instantiated, initialization, or event mode.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param integerValuesReferences  Value references encoded as doubles.
 * @param integerValues            Integer values to set.
 */
void fmi2SetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, int* integerValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode) {
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi2_status_t status = fmi2_import_set_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2SetInteger failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi2GetBoolean.
 *
 * Retrieves boolean values and converts them from FMI int to Modelica signed char.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param booleanValuesReferences  Value references encoded as doubles.
 * @param flowStatesInput          Dummy parameter used to enforce equation ordering.
 * @param booleanValues            Output array for the retrieved boolean values.
 */
void fmi2GetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, double flowStatesInput, signed char* booleanValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, booleanValuesReferences);
  int* fmiBoolean = malloc(sizeof(int)*numberOfValueReferences);
  fmi2_status_t status = fmi2_import_get_boolean(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, fmiBoolean);
  int_to_signedchar(fmiBoolean, booleanValues, numberOfValueReferences);
  free(fmiBoolean);
  free(valuesReferences_int);


  if (status != fmi2_status_ok && status != fmi2_status_warning) {
    ModelicaFormatError("fmi2GetBoolean failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi2SetBoolean.
 *
 * Converts Modelica signed char booleans to FMI int before setting.
 * Only sets values in instantiated, initialization, or event mode.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param booleanValuesReferences  Value references encoded as doubles.
 * @param booleanValues            Boolean values to set.
 */
void fmi2SetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, signed char* booleanValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode) {
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, booleanValuesReferences);
    int* fmiBoolean = malloc(sizeof(int)*numberOfValueReferences);
    fmi2_status_t status;
    signedchar_to_int(booleanValues, fmiBoolean, numberOfValueReferences);
    status = fmi2_import_set_boolean(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, fmiBoolean);
    free(fmiBoolean);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2SetBoolean failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi2GetString.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param stringValuesReferences   Value references encoded as doubles.
 * @param flowStatesInput          Dummy parameter used to enforce equation ordering.
 * @param stringValues             Output array for the retrieved string values.
 */
void fmi2GetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, double flowStatesInput, char** stringValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
  fmi2_status_t status = fmi2_import_get_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
  free(valuesReferences_int);
  if (status != fmi2_status_ok && status != fmi2_status_warning) {
    ModelicaFormatError("fmi2GetString failed with status : %s\n", fmi2_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi2SetString.
 *
 * Only sets values in instantiated, initialization, or event mode.
 *
 * @param in_fmi2                  FMI2 model exchange instance.
 * @param numberOfValueReferences  Number of value references.
 * @param stringValuesReferences   Value references encoded as doubles.
 * @param stringValues             String values to set.
 */
void fmi2SetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, char** stringValues)
{
  FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
  if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode) {
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi2_status_t status = fmi2_import_set_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2SetString failed with status : %s\n", fmi2_status_to_string(status));
    }
  }
}

#ifdef __cplusplus
}
#endif
