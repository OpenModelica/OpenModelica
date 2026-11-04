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

/*
 * The C simulation runtime's reader for <prefix>_init.bin, the variables and
 * default experiment of a model, written by omc. Plain C with no dependencies
 * on the rest of the runtime, because C FMUs are built from C sources. The
 * format is described in SimulationRuntime/rust/openmodelica_init_file/include/omc_init_file.h;
 * everything else reads the file through that library.
 */

#ifndef OMC_INIT_BIN_H
#define OMC_INIT_BIN_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

#define OMC_INIT_BIN_VERSION 1

enum omc_init_bin_class_type {
  OMC_INIT_BIN_REAL_STATE, OMC_INIT_BIN_REAL_DERIVATIVE, OMC_INIT_BIN_REAL_ALGEBRAIC,
  OMC_INIT_BIN_REAL_PARAMETER, OMC_INIT_BIN_REAL_ALIAS, OMC_INIT_BIN_INTEGER_ALGEBRAIC,
  OMC_INIT_BIN_INTEGER_PARAMETER, OMC_INIT_BIN_INTEGER_ALIAS, OMC_INIT_BIN_BOOLEAN_ALGEBRAIC,
  OMC_INIT_BIN_BOOLEAN_PARAMETER, OMC_INIT_BIN_BOOLEAN_ALIAS, OMC_INIT_BIN_STRING_ALGEBRAIC,
  OMC_INIT_BIN_STRING_PARAMETER, OMC_INIT_BIN_STRING_ALIAS, OMC_INIT_BIN_REAL_SENSITIVITY,
  OMC_INIT_BIN_NUM_CLASS_TYPES
};

enum omc_init_bin_base_type {
  OMC_INIT_BIN_REAL, OMC_INIT_BIN_INTEGER, OMC_INIT_BIN_BOOLEAN, OMC_INIT_BIN_STRING,
  OMC_INIT_BIN_ENUMERATION, OMC_INIT_BIN_EXTERNAL_OBJECT
};

enum omc_init_bin_variability {
  OMC_INIT_BIN_CONTINUOUS, OMC_INIT_BIN_DISCRETE, OMC_INIT_BIN_PARAMETER, OMC_INIT_BIN_CONSTANT
};

enum omc_init_bin_causality {
  OMC_INIT_BIN_LOCAL, OMC_INIT_BIN_NONE, OMC_INIT_BIN_OUTPUT, OMC_INIT_BIN_INPUT,
  OMC_INIT_BIN_CAUSALITY_PARAMETER, OMC_INIT_BIN_CALCULATED_PARAMETER
};

enum omc_init_bin_alias {
  OMC_INIT_BIN_NO_ALIAS, OMC_INIT_BIN_ALIAS, OMC_INIT_BIN_NEGATED_ALIAS
};

enum omc_init_bin_hide_result {
  OMC_INIT_BIN_HIDE_RESULT_UNSET, OMC_INIT_BIN_HIDE_RESULT_FALSE, OMC_INIT_BIN_HIDE_RESULT_TRUE
};

enum omc_init_bin_flag {
  OMC_INIT_BIN_DISCRETE_FLAG = 1,
  OMC_INIT_BIN_VALUE_CHANGEABLE = 2,
  OMC_INIT_BIN_PROTECTED = 4,
  OMC_INIT_BIN_ENCRYPTED = 8,
  OMC_INIT_BIN_INIT_NONLINEAR = 16,
  OMC_INIT_BIN_FIXED = 32,
  OMC_INIT_BIN_RELATIVE_QUANTITY = 64,
  OMC_INIT_BIN_FILE_WRITABLE = 128,
  OMC_INIT_BIN_ARRAY = 256,
  OMC_INIT_BIN_USE_NOMINAL = 512
};

typedef struct omc_init_bin_values {
  uint32_t count;
  uint32_t index;
} omc_init_bin_values;

typedef struct omc_init_bin_variable {
  const char *name, *description, *fileName, *unit, *displayUnit, *declaredType, *aliasVariable;
  int32_t valueReference, inputIndex, classIndex;
  int32_t startLine, startColumn, endLine, endColumn;
  uint8_t classType, baseType, variability, causality, alias, hideResult;
  uint16_t flags;
  uint32_t numDimensions, firstDimension;
  omc_init_bin_values start, min, max, nominal;
} omc_init_bin_variable;

typedef struct omc_init_bin_model {
  const char *modelName, *modelIdentifier, *description, *guid, *generationTool, *generationDateAndTime, *omhome;
  int32_t numberOfContinuousStates, numberOfRealAlgebraicVariables, numberOfRealAlgebraicAliasVariables,
          numberOfRealParameters, numberOfIntegerAlgebraicVariables, numberOfIntegerAliasVariables,
          numberOfIntegerParameters, numberOfBooleanAlgebraicVariables, numberOfBooleanAliasVariables,
          numberOfBooleanParameters, numberOfStringAlgebraicVariables, numberOfStringAliasVariables,
          numberOfStringParameters, numberOfEventIndicators, numberOfTimeEvents, numberOfInputVariables,
          numberOfOutputVariables, numberOfExternalObjects, numberOfFunctions;
} omc_init_bin_model;

typedef struct omc_init_bin_experiment {
  double startTime, stopTime, stepSize, tolerance;
  const char *solver, *outputFormat, *variableFilter;
} omc_init_bin_experiment;

typedef struct omc_init_bin_enumeration {
  const char *name;
  uint32_t numLiterals;
  uint32_t firstLiteral;
} omc_init_bin_enumeration;

typedef struct omc_init_bin {
  unsigned char *data;
  size_t size;
  omc_init_bin_model model;
  omc_init_bin_experiment experiment;
  size_t numEnumerations;
  omc_init_bin_enumeration *enumerations;
  size_t numVariables;
  omc_init_bin_variable *variables;
  /* the first variable of each class type, and their number */
  size_t classStart[OMC_INIT_BIN_NUM_CLASS_TYPES];
  size_t classCount[OMC_INIT_BIN_NUM_CLASS_TYPES];
  size_t numReals, numIntegers, stringsSize;
  const unsigned char *reals, *integers;
  const char *strings;
  char error[256];
} omc_init_bin;

/* Return 0 on success, else non-zero with the reason in bin->error. Strings
 * point into bin->data, which stays valid until omc_init_bin_free. A buffer
 * passed to omc_init_bin_load_buffer is copied. */
int omc_init_bin_load_file(omc_init_bin *bin, const char *fileName);
int omc_init_bin_load_buffer(omc_init_bin *bin, const void *data, size_t size);
void omc_init_bin_free(omc_init_bin *bin);

double omc_init_bin_real(const omc_init_bin *bin, size_t index);
int64_t omc_init_bin_integer(const omc_init_bin *bin, size_t index);
/* A string offset from INTEGERS, e.g. a start value of a String variable. */
const char *omc_init_bin_string(const omc_init_bin *bin, size_t integerIndex);

#ifdef __cplusplus
}
#endif

#endif
