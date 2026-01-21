/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#include "MatVer4.h"
#include "util/omc_error.h"
#include "util/omc_file.h"
#include "util/rtclock.h"
#include "simulation/options.h"
#include "simulation_result_mat4.h"

#include <cassert>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>

extern "C"
{

typedef struct mat_data
{
  FILE *pFile;
  long data2HdrPos; /* position of data_2 matrix's header in a file */

  size_t nData1;
  size_t nData2;
  size_t nSignals;
  size_t nEmits;
  size_t sync;
  void *data_2;
  MatVer4Type_t type;
} mat_data;

struct variableCount
{
  size_t maxLengthName; /* Length of longest variable name */
  size_t maxLengthDesc; /* Length of longest variable description */
  size_t nSignals;      /* Number of signals */
};

enum channel_t : int32_t
{
  CHANNEL_TIME = 0,           /* Special case: Variable is time */
  CHANNEL_TIME_INVARIANT = 1, /* Variable stored in data_1 matrix */
  CHANNEL_TIME_VARIANT = 2    /* Variable stored in data_2 matrix */
};

enum interpolation_t : int32_t
{
  INTERPOLATION_LINEAR = 0 /* Variable interpolated linear */
};

enum extrapolation_t : int32_t
{
  EXTRAPOLATION_NOT_ALLOWED = -1, /* Variable can't be extrapolated outside time interval */
  EXTRAPOLATION_CONSTANT = 0,     /* Variable is constant outside time interval */
  EXTRAPOLATION_LINEAR = 1        /* Variable is extrapolated linear by first/last two points */
};

/**
 * @brief DataInfo
 *
 * Information for each variable. See
 * doc/UsersGuide/source/technical_details.rst for details.
 */
typedef struct DataInfo
{
  /* Channel: 0=time, 1=data_1 (time-invariant), 2=data_2 (time-variant) */
  channel_t channel;

  /* 1 based variable index in data_1 or data_2 matrix. Multiple variables
   * pointing to the same index are alias variables. A negative values is a
   * negated alias. */
  int32_t index;

  /* Interpolation:
   * 0 = linear interpolation.
   * In other tools, this is the number of times a variable is
   * differentiable. */
  interpolation_t interpolation;

  /* Extrapolation of variable:
   * -1 = variable not defined outside time range,
   * 0 = keep first/last value when outside time range,
   * 1 = linear extrapolation on first/last two points */
  extrapolation_t extrapolation;
} DataInfo;

static const char timeName[] = "time";
static const char timeDesc[] = "Simulation time [s]";
static const char cpuTimeName[] = "$cpuTime";
static const char cpuTimeDesc[] = "cpu time [s]";
static const char solverStepsName[] = "$solverSteps";
static const char solverStepsDesc[] = "number of steps taken by the integrator";

/**
 * @brief Number of digits in non-negative number.
 *
 * @param number    Natural number.
 * @return size_t   Number of digist.
 */
static inline size_t numDigits(size_t number)
{
  if (number == 0)
  {
    return 1;
  }
  return floor(log10(number)) + 1;
}

/**
 * @brief Length of name including array index.
 *
 * @param name        Name of variable.
 * @param dimension   Optional dimension of variable.
 * @return size_t     Length of string "<name>[dim1][dim2]...[dimN]" including trailing null character.
 */
static size_t lengthName(const char *name, const DIMENSION_INFO *dimension)
{
  size_t len = strlen(name) + 1;

  /* Add optional array index */
  if (dimension != NULL && dimension->numberOfDimensions > 0)
  {
    for (size_t i = 0; i < dimension->numberOfDimensions; i++)
    {
      /* Number of digits of size plus brackets "[", and "]"" */
      len += numDigits(dimension->dimensions[i].start) + 2;
    }
  }

  return len;
}

/**
 * @brief Length of description string `"<comment> [<unit>]"`.
 *
 * When no unit is provided return length of string `"<comment>"`.
 *
 * @param comment   Comment part of description.
 * @param unit      Optional unit part of description.
 * @return size_t   Length of string "<comment> [<unit>]" including trailing null character.
 */
static size_t lengthDescription(const char *comment, modelica_string *unit)
{
  /* Length unit */
  size_t unitLength = 0;
  if (unit != NULL)
  {
    const char *unitStr = MMC_STRINGDATA(*unit);
    unitLength = unitStr ? strlen(unitStr) + 3 : 0; /* Lenght of " [<unit>]" */
  }

  /* Length description */
  return strlen(comment) + unitLength + 1;
}

/**
 * @brief Length of longest variable name, description and number of signals.
 *
 * @param mData                   Model data containing names and description of
 *                                variables.
 * @param cpuTime                 True is CPU-time shall be recorded in result
 *                                file.
 * @return struct variableCount   Length of longest variable name, description
 *                                and number of signal
 */
struct variableCount count_name_description_signals(const MODEL_DATA *mData,
                                                    modelica_boolean cpuTime)
{
  struct variableCount count = {
    .maxLengthName = strlen(timeName) + 1,
    .maxLengthDesc = strlen(timeDesc) + 1,
    .nSignals = 1};

  /* CPU-time */
  if (cpuTime)
  {
    count.maxLengthName = fmax(lengthName(cpuTimeName, NULL), count.maxLengthName);
    count.maxLengthDesc = fmax(lengthDescription(cpuTimeDesc, NULL), count.maxLengthDesc);
    count.nSignals++;
  }

  /* Solver steps */
  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    count.maxLengthName = fmax(lengthName(solverStepsName, NULL), count.maxLengthName);
    count.maxLengthDesc = fmax(lengthDescription(solverStepsDesc, NULL), count.maxLengthDesc);
    count.nSignals++;
  }

  /* Real variables */
  for (int i = 0; i < mData->nVariablesRealArray; i++)
  {
    if (!mData->realVarsData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->realVarsData[i].info.name, &mData->realVarsData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->realVarsData[i].info.comment, &mData->realVarsData[i].attribute.unit), count.maxLengthDesc);
      count.nSignals += mData->realVarsData[i].dimension.scalar_length;
    }
  }

  /* Sensitivity parameters */
  if (omc_flag[FLAG_IDAS])
  {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      count.maxLengthName = fmax(lengthName(mData->realSensitivityData[i].info.name, NULL), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->realSensitivityData[i].info.comment, NULL), count.maxLengthDesc);
      count.nSignals++;
    }
  }

  /* Integer variables */
  for (int i = 0; i < mData->nVariablesIntegerArray; i++)
  {
    if (!mData->integerVarsData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->integerVarsData[i].info.name, &mData->integerVarsData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->integerVarsData[i].info.comment, NULL), count.maxLengthDesc);
      count.nSignals += mData->integerVarsData[i].dimension.scalar_length;
    }
  }

  /* Boolean variables */
  for (int i = 0; i < mData->nVariablesBooleanArray; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->booleanVarsData[i].info.name, &mData->booleanVarsData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->booleanVarsData[i].info.comment, NULL), count.maxLengthDesc);
      count.nSignals += mData->booleanVarsData[i].dimension.scalar_length;
    }
  }

  /* Real parameters */
  for (int i = 0; i < mData->nParametersRealArray; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->realParameterData[i].info.name, &mData->realParameterData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->realParameterData[i].info.comment, &mData->realParameterData[i].attribute.unit), count.maxLengthDesc);
      count.nSignals += mData->realParameterData[i].dimension.scalar_length;
    }
  }

  /* Integer parameters */
  for (int i = 0; i < mData->nParametersIntegerArray; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->integerParameterData[i].info.name, &mData->integerParameterData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->integerParameterData[i].info.comment, NULL), count.maxLengthDesc);
      count.nSignals += mData->integerParameterData[i].dimension.scalar_length;
    }
  }

  /* Boolean parameter */
  for (int i = 0; i < mData->nParametersBooleanArray; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      count.maxLengthName = fmax(lengthName(mData->booleanParameterData[i].info.name, &mData->booleanParameterData[i].dimension), count.maxLengthName);
      count.maxLengthDesc = fmax(lengthDescription(mData->booleanParameterData[i].info.comment, NULL), count.maxLengthDesc);
      count.nSignals += mData->booleanParameterData[i].dimension.scalar_length;
    }
  }

  /* Real aliases */
  for (int i = 0; i < mData->nAliasRealArray; i++)
  {
    if (!mData->realAlias[i].filterOutput)
    {
      switch (mData->realAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        count.maxLengthName = fmax(lengthName(mData->realAlias[i].info.name, &mData->realVarsData[mData->realAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->realAlias[i].info.comment, &mData->realVarsData[mData->realAlias[i].nameID].attribute.unit), count.maxLengthDesc);
        count.nSignals += mData->realVarsData[mData->realAlias[i].nameID].dimension.scalar_length;
        break;
      case ALIAS_TYPE_PARAMETER:
        count.maxLengthName = fmax(lengthName(mData->realAlias[i].info.name, &mData->realParameterData[mData->realAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->realAlias[i].info.comment, &mData->realParameterData[mData->realAlias[i].nameID].attribute.unit), count.maxLengthDesc);
        count.nSignals += mData->realParameterData[mData->realAlias[i].nameID].dimension.scalar_length;
        break;
      case ALIAS_TYPE_TIME:
        count.maxLengthName = fmax(lengthName(mData->realAlias[i].info.name, NULL), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->realAlias[i].info.comment, NULL) + 4 /* " (s)" */, count.maxLengthDesc);
        count.nSignals++;
        break;
      default:
        throwStreamPrint(NULL, "count_name_description_signals: Unknown alias type for real alias.");
      }
    }
  }

  /* Integer aliases */
  for (int i = 0; i < mData->nAliasIntegerArray; i++)
  {
    if (!mData->integerAlias[i].filterOutput)
    {
      switch (mData->integerAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        count.maxLengthName = fmax(lengthName(mData->integerAlias[i].info.name, &mData->integerVarsData[mData->integerAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->integerAlias[i].info.comment, NULL), count.maxLengthDesc);
        count.nSignals += mData->integerVarsData[mData->integerAlias[i].nameID].dimension.scalar_length;
        break;
      case ALIAS_TYPE_PARAMETER:
        count.maxLengthName = fmax(lengthName(mData->integerAlias[i].info.name, &mData->integerParameterData[mData->integerAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->integerAlias[i].info.comment, NULL), count.maxLengthDesc);
        count.nSignals += mData->integerParameterData[mData->integerAlias[i].nameID].dimension.scalar_length;
        break;
      default:
        throwStreamPrint(NULL, "count_name_description_signals: Unknown alias type for integer alias.");
      }
    }
  }

  /* Boolean aliases */
  for (int i = 0; i < mData->nAliasBooleanArray; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      switch (mData->booleanAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        count.maxLengthName = fmax(lengthName(mData->booleanAlias[i].info.name, &mData->booleanVarsData[mData->booleanAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->booleanAlias[i].info.comment, NULL), count.maxLengthDesc);
        count.nSignals += mData->booleanVarsData[mData->booleanAlias[i].nameID].dimension.scalar_length;
        break;
      case ALIAS_TYPE_PARAMETER:
        count.maxLengthName = fmax(lengthName(mData->booleanAlias[i].info.name, &mData->booleanParameterData[mData->booleanAlias[i].nameID].dimension), count.maxLengthName);
        count.maxLengthDesc = fmax(lengthDescription(mData->booleanAlias[i].info.comment, NULL), count.maxLengthDesc);
        count.nSignals += mData->booleanParameterData[mData->booleanAlias[i].nameID].dimension.scalar_length;
        break;
      default:
        throwStreamPrint(NULL, "count_name_description_signals: Unknown alias type for boolean alias.");
      }
    }
  }

  return count;
}

/**
 * @brief Print name(s) of scalar or array variable.
 *
 * For array variables names for all array elements are printed in the form
 * `"<name>[dim1][dim2]...[dimN]"` and for state derivatives in
 * `"der(<name>[dim1][dim2]...[dimN])"`.
 *
 * If array variable is a state derivative assumes that `name` has format
 * `"der(<name>)"`. Will overwrite last character of `name` with array suffix
 * `"[dim1][dim2]...[dimN])"`.
 *
 * TODO: Move to a place where CSV can use it as well.
 *
 * @param buffer              Buffer to print name to.
 * @param maxlen              Maximum length of single name.
 * @param name                Variable name.
 * @param dimension           (Optional) Dimension of array variables.
 *                            Can be `NULL`.
 * @param isStateDerivative   True if variable is a state derivative.
 * @return char*              Return pointer to buffer after writing variable
 *                            name.
 */
char *printArrayName(char *buffer,
                     size_t maxlen,
                     const char *name,
                     const DIMENSION_INFO *dimension,
                     modelica_boolean isStateDerivative)
{
  /* Scalar case */
  if (dimension == NULL || dimension->numberOfDimensions == 0)
  {
    snprintf(buffer, maxlen, "%s", name);
    buffer += maxlen;
    return buffer;
  }

  /* Array case */
  size_t *idx = (size_t *)calloc(dimension->numberOfDimensions, sizeof(size_t));
  assertStreamPrint(NULL, idx != NULL, "Out of memory");

  for (size_t linear = 0; linear < dimension->scalar_length; linear++)
  {
    /* compute multi-dimensional indices for this linear index (row-major) */
    size_t rem = linear;
    for (size_t k = 0; k < dimension->numberOfDimensions; k++)
    {
      /* stride = product of sizes of dimensions after k */
      size_t stride = 1;
      for (size_t j = k + 1; j < dimension->numberOfDimensions; j++)
      {
        stride *= (size_t)dimension->dimensions[j].start;
      }
      idx[k] = rem / stride + 1;
      rem = rem % stride;
    }

    /* write full name */
    size_t written = snprintf(buffer, maxlen, "%s", name);
    if (isStateDerivative) {
      written--;
    }
    for (size_t k = 0; k < dimension->numberOfDimensions; ++k)
    {
      written += snprintf(buffer + written, maxlen - written, "[%zu]", idx[k]);
    }
    if (isStateDerivative)
    {
      written += snprintf(buffer + written, maxlen - written, ")");
    }
    buffer += maxlen;
  }

  free(idx);
  return buffer;
}

/**
 * @brief Print description(s) of scalar or array variable into buffer.
 *
 * Print `"<description> [<unit>]"` if a unit is available, otherwise print
 * `"<description>"`. Print same description `dimension->scalar_length` times.
 *
 * TODO: Move to a place where CSV can use it as well.
 *
 * @param buffer              Buffer to print description to.
 * @param maxlen              Maximum length of single description.
 * @param description         Variable description.
 * @param dimension           (Optional) Dimension of array variables.
 *                            Can be `NULL`.
 * @param unit                (Optional) Unit of variable. Can be NULL.
 * @return char*              Return pointer to buffer after writing variable
 *                            description.
 */
char * printArrayDescription(char *buffer,
                             size_t maxlen,
                             const char *description,
                             const DIMENSION_INFO *dimension,
                             const modelica_string *unit)
{
  /* Optional unit */
  modelica_boolean hasUnit = FALSE;
  char *unitStr = NULL;
  if (unit != NULL) {
    unitStr = MMC_STRINGDATA(*unit);
    hasUnit = unitStr != NULL && strlen(unitStr) > 0;
  }

  /* Print description string */
  size_t scalar_length = dimension ? dimension->scalar_length : 1;
  for (size_t i = 0; i < scalar_length; i++)
  {
    if (hasUnit) {
      snprintf(buffer, maxlen, "%s [%s]", description, unitStr);
    }
    else {
      snprintf(buffer, maxlen, "%s", description);
    }
    buffer += maxlen;
  }
  return buffer;
}

/**
 * @brief Initialize MAT v4 output for a simulation run.
 *
 * Prepares MAT v4 matrices (name, description, data headers) and opens
 * the output file. Allocates internal storage attached to `self->storage`.
 *
 * @param self        Writer instance containing filename and options.
 * @param data        Simulation data structures (model and simulation info).
 * @param threadData  Thread-local data used for error reporting.
 */
void mat4_init4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  const MODEL_DATA *mData = data->modelData;
  mat_data *matData = new mat_data();
  self->storage = matData;

  assert(sizeof(char) == 1);

  rt_tick(SIM_TIMER_OUTPUT);

  matData->type = omc_flag[FLAG_SINGLE_PRECISION] ? MatVer4Type_SINGLE : MatVer4Type_DOUBLE;

  matData->pFile = omc_fopen(self->filename, "wb+");
  if (!matData->pFile)
  {
    throwStreamPrint(threadData, "Cannot open file %s for writing", self->filename);
  }

  //       Name: Aclass
  //       Rank: 2
  // Dimensions: 4 x 11
  // Class Type: Character Array
  //  Data Type: 8-bit, unsigned integer
  const char Aclass[] = "A1\0bt.\0ir1\0na\0\0Tj\0\0re\0\0ac\0\0nt\0\0so\0\0\0r\0\0\0y\0\0\0";
  writeMatrix_matVer4(matData->pFile, "Aclass", 4, 11, Aclass, MatVer4Type_CHAR);

  /* Find the longest var name and description. */
  struct variableCount count = count_name_description_signals(mData, self->cpuTime);
  size_t maxLengthName = count.maxLengthName;
  size_t maxLengthDesc = count.maxLengthDesc;
  matData->nSignals = count.nSignals;

  /* Copy all the var names and descriptions to "name" and "description". */
  char *name = (char *)calloc(maxLengthName * matData->nSignals, sizeof(char));
  char *description = (char *)calloc(maxLengthDesc * matData->nSignals, sizeof(char));
  if (!name || !description)
  {
    free(name);
    free(description);
    throwStreamPrint(threadData, "Failed to allocate memory for name/description buffers");
  }
  static_assert(sizeof(char) == sizeof(uint8_t), "This code assumes uint8_t and char have the same size.");
  char *name_head = name;
  char *description_head = description;

  name_head = printArrayName(name_head,
                             maxLengthName,
                             timeName,
                             NULL,
                             FALSE);
  description_head = printArrayDescription(description_head,
                                           maxLengthDesc,
                                           timeDesc,
                                           NULL,
                                           NULL);

  if (self->cpuTime)
  {
    name_head = printArrayName(name_head,
                              maxLengthName,
                              cpuTimeName,
                              NULL,
                              FALSE);
    description_head = printArrayDescription(description_head,
                                             maxLengthDesc,
                                             cpuTimeDesc,
                                             NULL,
                                             NULL);
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    name_head = printArrayName(name_head,
                              maxLengthName,
                              solverStepsName,
                              NULL,
                              FALSE);
    description_head = printArrayDescription(description_head,
                                             maxLengthDesc,
                                             solverStepsDesc,
                                             NULL,
                                             NULL);
  }

  /* States, state derivatives, real variables */
  for (int i = 0; i < mData->nVariablesRealArray; i++)
  {
    if (!mData->realVarsData[i].filterOutput)
    {
      modelica_boolean isStateDerivative = mData->nStatesArray <= i && i < 2 * mData->nStatesArray;
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->realVarsData[i].info.name,
                                 &mData->realVarsData[i].dimension,
                                 isStateDerivative);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->realVarsData[i].info.comment,
                                               &mData->realVarsData[i].dimension,
                                               &mData->realVarsData[i].attribute.unit);
    }
  }

  /* Sensitivity parameters */
  if (omc_flag[FLAG_IDAS])
  {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->realSensitivityData[i].info.name,
                                 &mData->realSensitivityData[i].dimension,
                                 FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->realSensitivityData[i].info.comment,
                                               &mData->realSensitivityData[i].dimension,
                                               NULL);
    }
  }

  /* Integer variables */
  for (int i = 0; i < mData->nVariablesIntegerArray; i++)
  {
    if (!mData->integerVarsData[i].filterOutput)
    {
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->integerVarsData[i].info.name,
                                 &mData->integerVarsData[i].dimension,
                                 FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->integerVarsData[i].info.comment,
                                               &mData->integerVarsData[i].dimension,
                                               NULL);
    }
  }

  /* Boolean variables */
  for (int i = 0; i < mData->nVariablesBooleanArray; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput)
    {
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->booleanVarsData[i].info.name,
                                 &mData->booleanVarsData[i].dimension,
                                 FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->booleanVarsData[i].info.comment,
                                               &mData->booleanVarsData[i].dimension,
                                               NULL);
    }
  }

  /* Real parameters */
  for (int i = 0; i < mData->nParametersRealArray; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->realParameterData[i].info.name,
                                 &mData->realParameterData[i].dimension,
                                 FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->realParameterData[i].info.comment,
                                               &mData->realParameterData[i].dimension,
                                               &mData->realParameterData[i].attribute.unit);
    }
  }

  /* Integer parameters */
  for (int i = 0; i < mData->nParametersIntegerArray; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      name_head = printArrayName(name_head,
                                        maxLengthName,
                                        mData->integerParameterData[i].info.name,
                                        &mData->integerParameterData[i].dimension,
                                        FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->integerParameterData[i].info.comment,
                                               &mData->integerParameterData[i].dimension,
                                               NULL);
    }
  }

  /* Boolean parameters */
  for (int i = 0; i < mData->nParametersBooleanArray; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      name_head = printArrayName(name_head,
                                 maxLengthName,
                                 mData->booleanParameterData[i].info.name,
                                 &mData->booleanParameterData[i].dimension,
                                 FALSE);
      description_head = printArrayDescription(description_head,
                                               maxLengthDesc,
                                               mData->booleanParameterData[i].info.comment,
                                               &mData->booleanParameterData[i].dimension,
                                               NULL);
    }
  }

  /* Real alias */
  for (int i = 0; i < mData->nAliasRealArray; i++)
  {
    if (!mData->realAlias[i].filterOutput)
    {
      modelica_boolean isStateDerivative;

      switch (mData->realAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        isStateDerivative = mData->nStatesArray <= mData->realAlias[i].nameID
                         && mData->realAlias[i].nameID < 2 * mData->nStatesArray;
        name_head = printArrayName(name_head,
                                   maxLengthName,
                                   mData->realAlias[i].info.name,
                                   &mData->realVarsData[mData->realAlias[i].nameID].dimension,
                                   isStateDerivative);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->realVarsData[i].info.comment,
                                                 &mData->realVarsData[mData->realAlias[i].nameID].dimension,
                                                 &mData->realVarsData[mData->realAlias[i].nameID].attribute.unit);
        break;
      case ALIAS_TYPE_PARAMETER:
        name_head = printArrayName(name_head,
                                   maxLengthName,
                                   mData->realAlias[i].info.name,
                                   &mData->realParameterData[mData->realAlias[i].nameID].dimension,
                                   FALSE);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->realAlias[i].info.comment,
                                                 &mData->realParameterData[mData->realAlias[i].nameID].dimension,
                                                 &mData->realParameterData[mData->realAlias[i].nameID].attribute.unit);
        break;
      case ALIAS_TYPE_TIME:
      {
        name_head = printArrayName(name_head,
                                   maxLengthName,
                                   mData->realAlias[i].info.name,
                                   NULL,
                                   FALSE);
        modelica_string unitStr = mmc_mk_scon("s");
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->realAlias[i].info.comment,
                                                 NULL,
                                                 &unitStr);
        break;
      }
      default:
        throwStreamPrint(NULL, "mat4_init4: Unknown alias type for real variable.");
      }
    }
  }

  /* Integer alias */
  for (int i = 0; i < mData->nAliasIntegerArray; i++)
  {
    if (!mData->integerAlias[i].filterOutput)
    {
      switch (mData->integerAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        name_head = printArrayName(name_head,
                                   maxLengthName,
                                   mData->integerAlias[i].info.name,
                                   &mData->integerVarsData[mData->integerAlias[i].nameID].dimension,
                                   FALSE);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->integerAlias[i].info.comment,
                                                 &mData->integerVarsData[mData->integerAlias[i].nameID].dimension,
                                                 NULL);
        break;
      case ALIAS_TYPE_PARAMETER:
        name_head = printArrayName(name_head,
                                   maxLengthName,
                                   mData->integerAlias[i].info.name,
                                   &mData->integerParameterData[mData->integerAlias[i].nameID].dimension,
                                   FALSE);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->integerAlias[i].info.comment,
                                                 &mData->integerParameterData[mData->integerAlias[i].nameID].dimension,
                                                 NULL);
        break;
      default:
        throwStreamPrint(NULL, "mat4_init4: Unknown alias type for integer variable.");
      }
    }
  }

  /* Boolean alias */
  for (int i = 0; i < mData->nAliasBooleanArray; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      switch (mData->booleanAlias[i].aliasType)
      {
      case ALIAS_TYPE_VARIABLE:
        name_head = printArrayName(name_head,
                                          maxLengthName,
                                          mData->booleanAlias[i].info.name,
                                          &mData->booleanVarsData[mData->booleanAlias[i].nameID].dimension,
                                          FALSE);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->booleanAlias[i].info.comment,
                                                 &mData->booleanVarsData[mData->booleanAlias[i].nameID].dimension,
                                                 NULL);
        break;
      case ALIAS_TYPE_PARAMETER:
        name_head = printArrayName(name_head,
                                          maxLengthName,
                                          mData->booleanAlias[i].info.name,
                                          &mData->booleanParameterData[mData->booleanAlias[i].nameID].dimension,
                                          FALSE);
        description_head = printArrayDescription(description_head,
                                                 maxLengthDesc,
                                                 mData->booleanAlias[i].info.comment,
                                                 &mData->booleanParameterData[mData->booleanAlias[i].nameID].dimension,
                                                 NULL);
        break;
      default:
        throwStreamPrint(NULL, "mat4_init4: Unknown alias type for boolean variable.");
      }
    }
  }

  //       Name: name
  //       Rank: 2
  // Dimensions: maxLength x nVars
  // Class Type: Character Array
  //  Data Type: 8-bit, unsigned integer
  writeMatrix_matVer4(matData->pFile, "name", maxLengthName, matData->nSignals, name, MatVer4Type_CHAR);
  free(name);

  //       Name: description
  //       Rank: 2
  // Dimensions: maxLength x nVars
  // Class Type: Character Array
  //  Data Type: 8-bit, unsigned integer
  writeMatrix_matVer4(matData->pFile, "description", maxLengthDesc, matData->nSignals, description, MatVer4Type_CHAR);
  free(description);

  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * @brief Write matrix dataInfo.
 *
 * See doc/UsersGuide/source/technical_details.rst for data format.
 *
 * @param self      Simulation result.
 * @param matData   MAT data.
 * @param mData     Model data.
 */
void writeDataInfo(simulation_result *self, mat_data *matData, const MODEL_DATA *mData)
{
  static_assert(sizeof(DataInfo) == 4 * sizeof(int32_t), "DataInfo must be 4x32-bit");

  DataInfo *dataInfo = (DataInfo *)malloc(sizeof(DataInfo) * matData->nSignals);
  size_t index_time_invariant = 1; // Count time-invariant series, stored in data_1
  size_t index_time_variant = 0;   // Count time-variant series, stored in data_2
  size_t cur = 1;

  /* alias lookups */
  size_t *realLookup = (size_t *)malloc(sizeof(size_t) * mData->nVariablesReal);
  size_t *integerLookup = (size_t *)malloc(sizeof(size_t) * mData->nVariablesInteger);
  size_t *boolLookup = (size_t *)malloc(sizeof(size_t) * mData->nVariablesBoolean);

  size_t *realParameterLookup = (size_t *)malloc(sizeof(size_t) * mData->nParametersReal);
  size_t *integerParameterLookup = (size_t *)malloc(sizeof(size_t) * mData->nParametersInteger);
  size_t *boolParameterLookup = (size_t *)malloc(sizeof(size_t) * mData->nParametersBoolean);

  /* time */
  dataInfo[0].channel = CHANNEL_TIME;
  dataInfo[0].index = ++index_time_variant;
  dataInfo[0].interpolation = INTERPOLATION_LINEAR;
  dataInfo[0].extrapolation = EXTRAPOLATION_NOT_ALLOWED;

  if (self->cpuTime)
  {
    dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
    dataInfo[cur].index = ++index_time_variant;
    dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
    dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
    cur++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
    dataInfo[cur].index = ++index_time_variant;
    dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
    dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
    cur++;
  }

  for (int i = 0; i < mData->nVariablesReal; i++)
  {
    if (!mData->realVarsData[i].filterOutput)
    {
      realLookup[i] = cur;
      dataInfo[cur].channel = mData->realVarsData[i].time_unvarying ? CHANNEL_TIME_INVARIANT : CHANNEL_TIME_VARIANT;
      dataInfo[cur].index = mData->realVarsData[i].time_unvarying ? ++index_time_invariant : ++index_time_variant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  if (omc_flag[FLAG_IDAS])
  {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
      dataInfo[cur].index = ++index_time_variant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesInteger; i++)
  {
    if (!mData->integerVarsData[i].filterOutput)
    {
      integerLookup[i] = cur;
      dataInfo[cur].channel = mData->integerVarsData[i].time_unvarying ? CHANNEL_TIME_INVARIANT : CHANNEL_TIME_VARIANT;
      dataInfo[cur].index = mData->integerVarsData[i].time_unvarying ? ++index_time_invariant : ++index_time_variant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesBoolean; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput)
    {
      boolLookup[i] = cur;
      dataInfo[cur].channel = mData->booleanVarsData[i].time_unvarying ? CHANNEL_TIME_INVARIANT : CHANNEL_TIME_VARIANT;
      dataInfo[cur].index = mData->booleanVarsData[i].time_unvarying ? ++index_time_invariant : ++index_time_variant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersReal; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      realParameterLookup[i] = cur;
      dataInfo[cur].channel = CHANNEL_TIME_INVARIANT;
      dataInfo[cur].index = ++index_time_invariant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersInteger; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      integerParameterLookup[i] = cur;
      dataInfo[cur].channel = CHANNEL_TIME_INVARIANT;
      dataInfo[cur].index = ++index_time_invariant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersBoolean; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      boolParameterLookup[i] = cur;
      dataInfo[cur].channel = CHANNEL_TIME_INVARIANT;
      dataInfo[cur].index = ++index_time_invariant;
      dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
      dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
      cur++;
    }
  }

  for (int i = 0; i < mData->nAliasReal; i++)
  {
    if (!mData->realAlias[i].filterOutput)
    {
      if (mData->realAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      { /* variable */
        dataInfo[cur].channel = dataInfo[realLookup[mData->realAlias[i].nameID]].channel;
        dataInfo[cur].index = dataInfo[realLookup[mData->realAlias[i].nameID]].index;
        dataInfo[cur].interpolation = dataInfo[realLookup[mData->realAlias[i].nameID]].interpolation;
        dataInfo[cur].extrapolation = dataInfo[realLookup[mData->realAlias[i].nameID]].extrapolation;

        if (mData->realAlias[i].negate)
        {
          dataInfo[cur].index = -dataInfo[cur].index;
        }
        cur++;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_PARAMETER)
      { /* parameter */
        dataInfo[cur].channel = dataInfo[realParameterLookup[mData->realAlias[i].nameID]].channel;
        dataInfo[cur].index = dataInfo[realParameterLookup[mData->realAlias[i].nameID]].index;
        dataInfo[cur].interpolation = dataInfo[realParameterLookup[mData->realAlias[i].nameID]].interpolation;
        dataInfo[cur].extrapolation = dataInfo[realParameterLookup[mData->realAlias[i].nameID]].extrapolation;

        if (mData->realAlias[i].negate)
        {
          dataInfo[cur].index = -dataInfo[cur].index;
        }
        cur++;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_TIME)
      { /* time */
        dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
        dataInfo[cur].index = 1;
        dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
        dataInfo[cur].extrapolation = EXTRAPOLATION_NOT_ALLOWED;

        if (mData->realAlias[i].negate)
        {
          dataInfo[cur].index = -dataInfo[cur].index;
        }
        cur++;
      }
    }
  }

  for (int i = 0; i < mData->nAliasInteger; i++)
  {
    if (!mData->integerAlias[i].filterOutput)
    {
      if (mData->integerAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      { /* variable */
        dataInfo[cur].channel = dataInfo[integerLookup[mData->integerAlias[i].nameID]].channel;
        dataInfo[cur].index = dataInfo[integerLookup[mData->integerAlias[i].nameID]].index;
        dataInfo[cur].interpolation = dataInfo[integerLookup[mData->integerAlias[i].nameID]].interpolation;
        dataInfo[cur].extrapolation = dataInfo[integerLookup[mData->integerAlias[i].nameID]].extrapolation;

        if (mData->integerAlias[i].negate)
        {
          dataInfo[cur].index = -dataInfo[cur].index;
        }
        cur++;
      }
      else if (mData->integerAlias[i].aliasType == ALIAS_TYPE_PARAMETER)
      { /* parameter */
        dataInfo[cur].channel = dataInfo[integerParameterLookup[mData->integerAlias[i].nameID]].channel;
        dataInfo[cur].index = dataInfo[integerParameterLookup[mData->integerAlias[i].nameID]].index;
        dataInfo[cur].interpolation = dataInfo[integerParameterLookup[mData->integerAlias[i].nameID]].interpolation;
        dataInfo[cur].extrapolation = dataInfo[integerParameterLookup[mData->integerAlias[i].nameID]].extrapolation;

        if (mData->integerAlias[i].negate)
        {
          dataInfo[cur].index = -dataInfo[cur].index;
        }
        cur++;
      }
    }
  }

  for (int i = 0; i < mData->nAliasBoolean; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      if (mData->booleanAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      { /* variable */
        if (mData->booleanAlias[i].negate)
        {
          dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
          dataInfo[cur].index = ++index_time_variant;
          dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
          dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
          cur++;
        }
        else
        {
          dataInfo[cur].channel = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].channel;
          dataInfo[cur].index = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].index;
          dataInfo[cur].interpolation = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].interpolation;
          dataInfo[cur].extrapolation = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].extrapolation;
          cur++;
        }
      }
      else if (mData->booleanAlias[i].aliasType == ALIAS_TYPE_PARAMETER)
      { /* parameter */
        if (mData->booleanAlias[i].negate)
        {
          dataInfo[cur].channel = CHANNEL_TIME_INVARIANT;
          dataInfo[cur].index = ++index_time_invariant;
          dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
          dataInfo[cur].extrapolation = EXTRAPOLATION_CONSTANT;
          cur++;
        }
        else
        {
          dataInfo[cur].channel = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].channel;
          dataInfo[cur].index = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].index;
          dataInfo[cur].interpolation = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].interpolation;
          dataInfo[cur].extrapolation = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].extrapolation;
          cur++;
        }
      }
    }
  }

  free(realLookup);
  free(integerLookup);
  free(boolLookup);

  free(realParameterLookup);
  free(integerParameterLookup);
  free(boolParameterLookup);

  matData->nData1 = index_time_invariant;
  matData->nData2 = index_time_variant;
  matData->nEmits = 0;
  matData->sync = 0;

  if (omc_flag[FLAG_MAT_SYNC])
  {
    matData->sync = atoi(omc_flagValue[FLAG_MAT_SYNC]);
  }

  //       Name: dataInfo
  //       Rank: 2
  // Dimensions: 4 x nVars
  // Class Type: 32-bit, signed integer array
  //  Data Type: 32-bit, signed integer
  writeMatrix_matVer4(matData->pFile, "dataInfo", 4, matData->nSignals, dataInfo, MatVer4Type_INT32);

  free(dataInfo);
}

#define WRITE_REAL_VALUE(data, offset, value)                                      \
{                                                                                \
  if (omc_flag[FLAG_SINGLE_PRECISION])                                           \
  {                                                                              \
    float f = (value);                                                           \
    memcpy(((uint8_t *)(data)) + (offset) * sizeof(float), &f, sizeof(float));   \
  }                                                                              \
  else                                                                           \
  {                                                                              \
    double d = (value);                                                          \
    memcpy(((uint8_t *)(data)) + (offset) * sizeof(double), &d, sizeof(double)); \
  }                                                                              \
}

/**
 * @brief Write parameter and time-invariant series into MAT v4 structures.
 *
 * This function populates `data_1` and `data_2` headers with parameter values
 * and allocates the in-memory buffers used for subsequent emits. It is
 * typically called after parameters have been updated
 * (`updateBoundParameters`).
 *
 * ## Implementation Details
 *
 * - `data_1` represents time-invariant series (parameters, time-invariant variables)
 * - `data_2` represents time-variant series (time, CPU-time, solver steps, time-variant variables)
 *
 * @param self        Writer instance containing storage and filename.
 * @param data        Simulation data structures (model and simulation info).
 * @param threadData  Thread-local data used for error reporting.
 */
void mat4_writeParameterData4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data *)self->storage;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const MODEL_DATA *mData = data->modelData;

  if (!matData->pFile)
  {
    return;
  }

  rt_tick(SIM_TIMER_OUTPUT);

  /* Write dataInfo*/
  writeDataInfo(self, matData, mData);

  /* Write data_1 */
  size_t size = sizeofMatVer4Type(matData->type);
  size_t cur = 0;
  void *data_1 = malloc(size * matData->nData1 * 2);

  WRITE_REAL_VALUE(data_1, cur, data->simulationInfo->startTime);
  WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->simulationInfo->stopTime);
  cur++;

  for (int i = 0; i < mData->nVariablesReal; i++)
  {
    if (!mData->realVarsData[i].filterOutput && mData->realVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(data_1, cur, data->localData[0]->realVars[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->realVars[i]);
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesInteger; i++)
  {
    if (!mData->integerVarsData[i].filterOutput && mData->integerVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(data_1, cur, data->localData[0]->integerVars[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->integerVars[i]);
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesBoolean; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput && mData->booleanVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(data_1, cur, data->localData[0]->booleanVars[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->booleanVars[i]);
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersReal; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      WRITE_REAL_VALUE(data_1, cur, sInfo->realParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->realParameter[i]);
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersInteger; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      WRITE_REAL_VALUE(data_1, cur, sInfo->integerParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->integerParameter[i]);
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersBoolean; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      WRITE_REAL_VALUE(data_1, cur, sInfo->booleanParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->booleanParameter[i]);
      cur++;
    }
  }

  //       Name: data_1
  //       Rank: 2
  // Dimensions: nParams x 2
  // Class Type: Double Precision Array
  //  Data Type: IEEE 754 double-precision
  writeMatrix_matVer4(matData->pFile, "data_1", matData->nData1, 2, data_1, matData->type);
  if (data_1)
  {
    free(data_1);
    data_1 = NULL;
  }

  /* Write 0 columns of data_2 */

  //       Name: data_2
  //       Rank: 2
  // Dimensions: nSeries x nPoints
  // Class Type: Double Precision Array
  //  Data Type: IEEE 754 double-precision
  matData->data2HdrPos = ftell(matData->pFile);
  matData->data_2 = malloc(size * matData->nData2);
  writeMatrix_matVer4(matData->pFile, "data_2", matData->nData2, 0, NULL, matData->type);
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * @brief Emit one simulation sample (time step) into the MAT v4 file.
 *
 * Appends the current time, optional CPU time and solver steps, and
 * all enabled variable values to the in-memory `data_2` buffer and
 * flushes it to disk when appropriate.
 *
 * @param self        Writer instance containing storage and filename.
 * @param data        Simulation data structures (model and current values).
 * @param threadData  Thread-local data used for error reporting.
 */
void mat4_emit4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data *)self->storage;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const MODEL_DATA *mData = data->modelData;

  if (!matData->pFile)
    return;

  rt_tick(SIM_TIMER_OUTPUT);
  rt_accumulate(SIM_TIMER_TOTAL);
  double cpuTimeValue = rt_accumulated(SIM_TIMER_TOTAL);
  rt_tick(SIM_TIMER_TOTAL);

  size_t cur = 0;
  /* time */
  WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->timeValue);

  if (self->cpuTime)
  {
    WRITE_REAL_VALUE(matData->data_2, cur++, cpuTimeValue);
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    WRITE_REAL_VALUE(matData->data_2, cur++, data->simulationInfo->solverSteps);
  }

  for (int i = 0; i < mData->nVariablesReal; i++)
  {
    if (!mData->realVarsData[i].filterOutput && !mData->realVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->realVars[i]);
    }
  }

  if (omc_flag[FLAG_IDAS])
  {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      WRITE_REAL_VALUE(matData->data_2, cur++, data->simulationInfo->sensitivityMatrix[i]);
    }
  }

  for (int i = 0; i < mData->nVariablesInteger; i++)
  {
    if (!mData->integerVarsData[i].filterOutput && !mData->integerVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->integerVars[i]);
    }
  }

  for (int i = 0; i < mData->nVariablesBoolean; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput && !mData->booleanVarsData[i].time_unvarying)
    {
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->booleanVars[i]);
    }
  }

  for (int i = 0; i < mData->nAliasBoolean; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      if (mData->booleanAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      {
        if (mData->booleanAlias[i].negate)
        {
          WRITE_REAL_VALUE(matData->data_2, cur++, (1 - data->localData[0]->booleanVars[mData->booleanAlias[i].nameID]));
        }
      }
    }
  }

  fwrite(matData->data_2, sizeofMatVer4Type(matData->type), matData->nData2, matData->pFile);
  matData->nEmits++;

  if (matData->sync > 0 && matData->nEmits > matData->sync)
  {
    updateHeader_matVer4(matData->pFile, matData->data2HdrPos, "data_2", matData->nData2, matData->nEmits, matData->type);
    matData->nEmits = 0;
  }

  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * @brief Finalize MAT v4 output and release resources.
 *
 * Writes any remaining buffered samples, updates headers and frees
 * allocated buffers and file handles stored in `self->storage`.
 *
 * @param self        Writer instance containing storage and filename.
 * @param data        Simulation data structures (not modified).
 * @param threadData  Thread-local data used for error reporting.
 */
void mat4_free4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data *)self->storage;

  rt_tick(SIM_TIMER_OUTPUT);

  if (!matData->pFile)
  {
    rt_accumulate(SIM_TIMER_OUTPUT);
    return;
  }

  if (matData->nEmits > 0)
  {
    updateHeader_matVer4(matData->pFile, matData->data2HdrPos, "data_2", matData->nData2, matData->nEmits, matData->type);
    matData->nEmits = 0;
  }

  if (matData->data_2)
  {
    free(matData->data_2);
    matData->data_2 = NULL;
  }

  fclose(matData->pFile);
  matData->pFile = NULL;

  rt_accumulate(SIM_TIMER_OUTPUT);
}

} // extern "C"
