/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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
  for (i = 0 ; i < numberOfValueReferences ; i++) {
    valuesReferences_int[i] = (int)valuesReferences[i];
  }
  return valuesReferences_int;
}

/*
 * OpenModelica uses signed char for boolean and according to FMI specifications boolean are ints.
 * So to this function converts signed char into int
 */
int signedchar_to_int(signed char* modelicaBoolean, int* fmiBoolean, int size)
{
  int i;
  for (i = 0; i < size; i++) {
    fmiBoolean[i] = (int) modelicaBoolean[i];
  }
  return 0;
}
/*
 * OpenModelica uses signed char for boolean and according to FMI specifications boolean are ints.
 * So to this function converts int into signed char
 */
int int_to_signedchar(int* fmiBoolean, signed char* modelicaBoolean, int size)
{
  int i;
  for (i = 0; i < size; i++) {
    modelicaBoolean[i] = (signed char) fmiBoolean[i];
  }
  return 0;
}

/*
 * Wrapper for the FMI function fmi2GetReal.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns realValues.
 */
void fmi2GetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double flowStatesInput, double* realValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
    fmi2_status_t status = fmi2_import_get_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2GetReal failed with status : %s\n", fmi2_status_to_string(status));
    }
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2SetReal.
 * Returns status.
 */
void fmi2SetReal_OMC(void* in_fmi2, int numberOfValueReferences, double* realValuesReferences, double* realValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode || FMI2ME->FMISolvingMode == fmi2_continuousTime_mode) {
      fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, realValuesReferences);
      fmi2_status_t status = fmi2_import_set_real(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_real_t*)realValues);
      free(valuesReferences_int);
      if (status != fmi2_status_ok && status != fmi2_status_warning) {
        ModelicaFormatError("fmi2SetReal failed with status : %s\n", fmi2_status_to_string(status));
      }
    }
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2GetInteger.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns integerValues.
 */
void fmi2GetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, double flowStatesInput, int* integerValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi2_status_t status = fmi2_import_get_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2GetInteger failed with status : %s\n", fmi2_status_to_string(status));
    }
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2SetInteger.
 * Returns status.
 */
void fmi2SetInteger_OMC(void* in_fmi2, int numberOfValueReferences, double* integerValuesReferences, int* integerValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode) {
      fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, integerValuesReferences);
      fmi2_status_t status = fmi2_import_set_integer(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_integer_t*)integerValues);
      free(valuesReferences_int);
      if (status != fmi2_status_ok && status != fmi2_status_warning) {
        ModelicaFormatError("fmi2SetInteger failed with status : %s\n", fmi2_status_to_string(status));
      }
    }
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2GetBoolean.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns booleanValues.
 */
void fmi2GetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, double flowStatesInput, signed char* booleanValues, int fmiType)
{
  if (fmiType == 1) {
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
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2SetBoolean.
 * Returns status.
 */
void fmi2SetBoolean_OMC(void* in_fmi2, int numberOfValueReferences, double* booleanValuesReferences, signed char* booleanValues, int fmiType)
{
  if (fmiType == 1) {
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
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2GetString.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns stringValues.
 */
void fmi2GetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, double flowStatesInput, char** stringValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi2_status_t status = fmi2_import_get_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi2_status_ok && status != fmi2_status_warning) {
      ModelicaFormatError("fmi2GetString failed with status : %s\n", fmi2_status_to_string(status));
    }
  } else if (fmiType == 2) {

  }
}

/*
 * Wrapper for the FMI function fmi2SetString.
 * Returns status.
 */
void fmi2SetString_OMC(void* in_fmi2, int numberOfValueReferences, double* stringValuesReferences, char** stringValues, int fmiType)
{
  if (fmiType == 1) {
    FMI2ModelExchange* FMI2ME = (FMI2ModelExchange*)in_fmi2;
    if (FMI2ME->FMISolvingMode == fmi2_instantiated_mode || FMI2ME->FMISolvingMode == fmi2_initialization_mode || FMI2ME->FMISolvingMode == fmi2_event_mode) {
      fmi2_value_reference_t* valuesReferences_int = real_to_fmi2_value_reference(numberOfValueReferences, stringValuesReferences);
      fmi2_status_t status = fmi2_import_set_string(FMI2ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi2_string_t*)stringValues);
      free(valuesReferences_int);
      if (status != fmi2_status_ok && status != fmi2_status_warning) {
        ModelicaFormatError("fmi2SetString failed with status : %s\n", fmi2_status_to_string(status));
      }
    }
  } else if (fmiType == 2) {

  }
}

#ifdef __cplusplus
}
#endif
