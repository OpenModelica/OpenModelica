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

#include "FMI3Common.h"

/**
 * @brief FMU 3.0 internal logger callback.
 *
 * FMI 3.0 hands the callback an instance environment rather than a component and an
 * instance name, and the message is already formatted, so there is no va_list to
 * forward as there was in FMI 2.0.
 *
 * @param instanceEnvironment  What was given to fmi3_import_create_dllfmu.
 * @param status               Severity status of the message.
 * @param category             Log category string.
 * @param message              The message.
 */
void fmi3logger(fmi3_instance_environment_t instanceEnvironment, fmi3_status_t status, fmi3_string_t category, fmi3_string_t message)
{
  fmi3_log_forwarding(instanceEnvironment, status, category, message);
  fflush(NULL);
}

/**
 * @brief Convert an array of double-encoded value references to fmi3_value_reference_t.
 *
 * The generated Modelica code carries value references as Real, as it does for FMI 1.0
 * and 2.0, so that it does not have to model an unsigned integer.
 *
 * @param numberOfValueReferences Number of value references to convert.
 * @param valuesReferences        Input array of value references encoded as doubles.
 * @return Newly allocated array of fmi3_value_reference_t; caller must free().
 */
fmi3_value_reference_t* real_to_fmi3_value_reference(int numberOfValueReferences, double* valuesReferences)
{
  fmi3_value_reference_t* valuesReferences_int = malloc(sizeof(fmi3_value_reference_t)*numberOfValueReferences);
  int i;
  for (i = 0 ; i < numberOfValueReferences ; i++) {
    valuesReferences_int[i] = (fmi3_value_reference_t)valuesReferences[i];
  }
  return valuesReferences_int;
}

/*
 * The get and set wrappers below all take nValues as well as nvr, which FMI 3.0 needs
 * because a variable can be an array. Only scalars are imported so far, so the two are
 * the same; when arrays arrive nValues becomes the sum of their sizes.
 */

/**
 * @brief Wrapper for fmi3GetFloat64.
 */
void fmi3GetReal_OMC(void* in_fmi3, int numberOfValueReferences, double* realValuesReferences, double flowStatesInput, double* realValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, realValuesReferences);
  fmi3_status_t status = fmi3_import_get_float64(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                 (fmi3_float64_t*)realValues, numberOfValueReferences);
  free(valuesReferences_int);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetFloat64 failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi3SetFloat64.
 *
 * Only sets values in instantiated, initialization, event, or continuous-time mode.
 */
void fmi3SetReal_OMC(void* in_fmi3, int numberOfValueReferences, double* realValuesReferences, double* realValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  if (FMI3ME->FMISolvingMode == fmi3_instantiated_mode || FMI3ME->FMISolvingMode == fmi3_initialization_mode || FMI3ME->FMISolvingMode == fmi3_event_mode || FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, realValuesReferences);
    fmi3_status_t status = fmi3_import_set_float64(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                   (const fmi3_float64_t*)realValues, numberOfValueReferences);
    free(valuesReferences_int);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetFloat64 failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi3GetInt32.
 */
void fmi3GetInteger_OMC(void* in_fmi3, int numberOfValueReferences, double* integerValuesReferences, double flowStatesInput, int* integerValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, integerValuesReferences);
  fmi3_status_t status = fmi3_import_get_int32(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                               (fmi3_int32_t*)integerValues, numberOfValueReferences);
  free(valuesReferences_int);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetInt32 failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi3SetInt32.
 */
void fmi3SetInteger_OMC(void* in_fmi3, int numberOfValueReferences, double* integerValuesReferences, int* integerValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  if (FMI3ME->FMISolvingMode == fmi3_instantiated_mode || FMI3ME->FMISolvingMode == fmi3_initialization_mode || FMI3ME->FMISolvingMode == fmi3_event_mode || FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi3_status_t status = fmi3_import_set_int32(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                 (const fmi3_int32_t*)integerValues, numberOfValueReferences);
    free(valuesReferences_int);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetInt32 failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi3GetBoolean.
 *
 * Modelica booleans are signed char and FMI 3.0 ones are fmi3_boolean_t, so the values
 * are read into a buffer of the FMI type and copied over.
 */
void fmi3GetBoolean_OMC(void* in_fmi3, int numberOfValueReferences, double* booleanValuesReferences, double flowStatesInput, signed char* booleanValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, booleanValuesReferences);
  fmi3_boolean_t* fmiBooleans = malloc(sizeof(fmi3_boolean_t)*numberOfValueReferences);
  fmi3_status_t status = fmi3_import_get_boolean(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                 fmiBooleans, numberOfValueReferences);
  int i;
  for (i = 0; i < numberOfValueReferences; i++) {
    booleanValues[i] = (signed char)fmiBooleans[i];
  }
  free(fmiBooleans);
  free(valuesReferences_int);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetBoolean failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi3SetBoolean.
 */
void fmi3SetBoolean_OMC(void* in_fmi3, int numberOfValueReferences, double* booleanValuesReferences, signed char* booleanValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  if (FMI3ME->FMISolvingMode == fmi3_instantiated_mode || FMI3ME->FMISolvingMode == fmi3_initialization_mode || FMI3ME->FMISolvingMode == fmi3_event_mode || FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, booleanValuesReferences);
    fmi3_boolean_t* fmiBooleans = malloc(sizeof(fmi3_boolean_t)*numberOfValueReferences);
    fmi3_status_t status;
    int i;
    for (i = 0; i < numberOfValueReferences; i++) {
      fmiBooleans[i] = (fmi3_boolean_t)booleanValues[i];
    }
    status = fmi3_import_set_boolean(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                     fmiBooleans, numberOfValueReferences);
    free(fmiBooleans);
    free(valuesReferences_int);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetBoolean failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
}

/**
 * @brief Wrapper for fmi3GetString.
 */
void fmi3GetString_OMC(void* in_fmi3, int numberOfValueReferences, double* stringValuesReferences, double flowStatesInput, char** stringValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, stringValuesReferences);
  fmi3_status_t status = fmi3_import_get_string(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                (fmi3_string_t*)stringValues, numberOfValueReferences);
  free(valuesReferences_int);
  if (status != fmi3_status_ok && status != fmi3_status_warning) {
    ModelicaFormatError("fmi3GetString failed with status : %s\n", fmi3_status_to_string(status));
  }
}

/**
 * @brief Wrapper for fmi3SetString.
 */
void fmi3SetString_OMC(void* in_fmi3, int numberOfValueReferences, double* stringValuesReferences, char** stringValues)
{
  FMI3ModelExchange* FMI3ME = (FMI3ModelExchange*)in_fmi3;
  if (FMI3ME->FMISolvingMode == fmi3_instantiated_mode || FMI3ME->FMISolvingMode == fmi3_initialization_mode || FMI3ME->FMISolvingMode == fmi3_event_mode || FMI3ME->FMISolvingMode == fmi3_continuousTime_mode) {
    fmi3_value_reference_t* valuesReferences_int = real_to_fmi3_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi3_status_t status = fmi3_import_set_string(FMI3ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences,
                                                  (const fmi3_string_t*)stringValues, numberOfValueReferences);
    free(valuesReferences_int);
    if (status != fmi3_status_ok && status != fmi3_status_warning) {
      ModelicaFormatError("fmi3SetString failed with status : %s\n", fmi3_status_to_string(status));
    }
  }
}

#ifdef __cplusplus
}
#endif
