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

#include "FMI1Common.h"

/*
 * Used for logging FMU messages.
 * Logger function used by the FMU internally.
 */
void fmi1logger(fmi1_component_t c, fmi1_string_t instanceName, fmi1_status_t status, fmi1_string_t category, fmi1_string_t message, ...)
{
  va_list argp;
  va_start(argp, message);
  fmi1_log_forwarding_v(c, instanceName, status, category, message, argp);
  va_end(argp);
  fflush(NULL);
}

/*
 * OpenModelica uses signed integers and according to FMI specifications the value references should be unsigned integers.
 * So to overcome this we use value references as Real in the Modelica code.
 * This function converts back the value references from double to int and use them in FMI specific functions.
 */
fmi1_value_reference_t* real_to_fmi1_value_reference(int numberOfValueReferences, double* valuesReferences)
{
  fmi1_value_reference_t* valuesReferences_int = malloc(sizeof(fmi1_value_reference_t)*numberOfValueReferences);
  int i;
  for (i = 0 ; i < numberOfValueReferences ; i++) {
    valuesReferences_int[i] = (int)valuesReferences[i];
  }
  return valuesReferences_int;
}

/*
 * Wrapper for the FMI function fmiGetReal.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns realValues.
 */
void fmi1GetReal_OMC(void* in_fmi1, int numberOfValueReferences, double* realValuesReferences, double flowStatesInput, double* realValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, realValuesReferences);
    fmi1_status_t status = fmi1_import_get_real(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetReal failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, realValuesReferences);
    fmi1_status_t status = fmi1_import_get_real(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetReal failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiSetReal.
 * Returns status.
 */
void fmi1SetReal_OMC(void* in_fmi1, int numberOfValueReferences, double* realValueReferences, double* realValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, realValueReferences);
    fmi1_status_t status = fmi1_import_set_real(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetReal failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, realValueReferences);
    fmi1_status_t status = fmi1_import_set_real(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_real_t*)realValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetReal failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiGetInteger.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns integerValues.
 */
void fmi1GetInteger_OMC(void* in_fmi1, int numberOfValueReferences, double* integerValuesReferences, double flowStatesInput, int* integerValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi1_status_t status = fmi1_import_get_integer(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetInteger failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, integerValuesReferences);
    fmi1_status_t status = fmi1_import_get_integer(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetInteger failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiSetInteger.
 * Returns status.
 */
void fmi1SetInteger_OMC(void* in_fmi1, int numberOfValueReferences, double* integerValueReferences, int* integerValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, integerValueReferences);
    fmi1_status_t status = fmi1_import_set_integer(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetInteger failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, integerValueReferences);
    fmi1_status_t status = fmi1_import_set_integer(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_integer_t*)integerValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetInteger failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiGetBoolean.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns booleanValues.
 */
void fmi1GetBoolean_OMC(void* in_fmi1, int numberOfValueReferences, double* booleanValuesReferences, double flowStatesInput, int* booleanValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, booleanValuesReferences);
    fmi1_status_t status = fmi1_import_get_boolean(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetBoolean failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, booleanValuesReferences);
    fmi1_status_t status = fmi1_import_get_boolean(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetBoolean failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiSetBoolean.
 * Returns status.
 */
void fmi1SetBoolean_OMC(void* in_fmi1, int numberOfValueReferences, double* booleanValueReferences, int* booleanValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, booleanValueReferences);
    fmi1_status_t status = fmi1_import_set_boolean(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetBoolean failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, booleanValueReferences);
    fmi1_status_t status = fmi1_import_set_boolean(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_boolean_t*)booleanValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetBoolean failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiGetString.
 * parameter flowStatesInput is dummy and is only used to run the equations in sequence.
 * Returns stringValues.
 */
void fmi1GetString_OMC(void* in_fmi1, int numberOfValueReferences, double* stringValuesReferences, double flowStatesInput, char** stringValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi1_status_t status = fmi1_import_get_string(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetString failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, stringValuesReferences);
    fmi1_status_t status = fmi1_import_get_string(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiGetString failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

/*
 * Wrapper for the FMI function fmiSetString.
 * Returns status.
 */
void fmi1SetString_OMC(void* in_fmi1, int numberOfValueReferences, double* stringValueReferences, char** stringValues, int fmiType)
{
  if (fmiType == 1) {
    FMI1ModelExchange* FMI1ME = (FMI1ModelExchange*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, stringValueReferences);
    fmi1_status_t status = fmi1_import_set_string(FMI1ME->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetString failed with status : %s\n", fmi1_status_to_string(status));
    }
  } else if (fmiType == 2) {
    FMI1CoSimulation* FMI1CS = (FMI1CoSimulation*)in_fmi1;
    fmi1_value_reference_t* valuesReferences_int = real_to_fmi1_value_reference(numberOfValueReferences, stringValueReferences);
    fmi1_status_t status = fmi1_import_set_string(FMI1CS->FMIImportInstance, valuesReferences_int, numberOfValueReferences, (fmi1_string_t*)stringValues);
    free(valuesReferences_int);
    if (status != fmi1_status_ok && status != fmi1_status_warning) {
      ModelicaFormatError("fmiSetString failed with status : %s\n", fmi1_status_to_string(status));
    }
  }
}

#ifdef __cplusplus
}
#endif
