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

/*! \file arrayIndex.c
 *
 * Handling of Index mapping between array variables and scalar representation
 * in simulation data.
 */

#include "arrayIndex.h"
#include "../util/omc_error.h"

/**
 * @brief Allocate memory for index maps.
 *
 * Free with `freeArrayIndexMaps`.
 *
 * @param modelData         Model data containing number of variables.
 * @param simulationInfo    Simulation information with index arrays to allocate
 *                          memory for.
 * @param threadData        Thread data for error handling.
 */
void allocateArrayIndexMaps(MODEL_DATA *modelData,
                            SIMULATION_INFO *simulationInfo,
                            threadData_t *threadData)
{
  // Variables
  simulationInfo->realVarsIndex = (size_t *)calloc(modelData->nVariablesRealArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->realVarsIndex != NULL, "Out of memory");
  simulationInfo->integerVarsIndex = (size_t *)calloc(modelData->nVariablesIntegerArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->integerVarsIndex != NULL, "Out of memory");
  simulationInfo->booleanVarsIndex = (size_t *)calloc(modelData->nVariablesBooleanArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->booleanVarsIndex != NULL, "Out of memory");
  simulationInfo->stringVarsIndex = (size_t *)calloc(modelData->nVariablesStringArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->stringVarsIndex != NULL, "Out of memory");

  // Parameters
  simulationInfo->realParamsIndex = (size_t *)calloc(modelData->nParametersRealArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->realParamsIndex != NULL, "Out of memory");
  simulationInfo->integerParamsIndex = (size_t *)calloc(modelData->nParametersIntegerArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->integerParamsIndex != NULL, "Out of memory");
  simulationInfo->booleanParamsIndex = (size_t *)calloc(modelData->nParametersBooleanArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->booleanParamsIndex != NULL, "Out of memory");
  simulationInfo->stringParamsIndex = (size_t *)calloc(modelData->nParametersStringArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->stringParamsIndex != NULL, "Out of memory");

  // Alias variables
  simulationInfo->realAliasIndex = (size_t *)calloc(modelData->nAliasRealArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->realAliasIndex != NULL, "Out of memory");
  simulationInfo->integerAliasIndex = (size_t *)calloc(modelData->nAliasIntegerArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->integerAliasIndex != NULL, "Out of memory");
  simulationInfo->booleanAliasIndex = (size_t *)calloc(modelData->nAliasBooleanArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->booleanAliasIndex != NULL, "Out of memory");
  simulationInfo->stringAliasIndex = (size_t *)calloc(modelData->nAliasStringArray + 1, sizeof(size_t));
  assertStreamPrint(threadData, simulationInfo->stringAliasIndex != NULL, "Out of memory");
}

/**
 * @brief Free memory of variable index maps.
 *
 * Free memory allocated by `allocateArrayIndexMaps`.
 *
 * @param simulationInfo    Simulation info with index arrays to free.
 */
void freeArrayIndexMaps(SIMULATION_INFO *simulationInfo)
{
  // Variables
  free(simulationInfo->realVarsIndex);
  free(simulationInfo->integerVarsIndex);
  free(simulationInfo->booleanVarsIndex);
  free(simulationInfo->stringVarsIndex);

  // Parameters
  free(simulationInfo->realParamsIndex);
  free(simulationInfo->integerParamsIndex);
  free(simulationInfo->booleanParamsIndex);
  free(simulationInfo->stringParamsIndex);

  // Alias variables
  free(simulationInfo->realAliasIndex);
  free(simulationInfo->integerAliasIndex);
  free(simulationInfo->booleanAliasIndex);
  free(simulationInfo->stringAliasIndex);
}

/**
 * @brief Allocate memory for reverse index maps.
 *
 * Free with `freeArrayReverseIndexMaps`.
 *
 * @param modelData         Model data containing number of scalarized variables.
 * @param simulationInfo    Simulation information with reverse index arrays to
 *                          allocate memory for.
 * @param threadData        Thread data for error handling.
 */
void allocateArrayReverseIndexMaps(MODEL_DATA *modelData,
                                   SIMULATION_INFO *simulationInfo,
                                   threadData_t *threadData)
{
  // Variables
  simulationInfo->realVarsReverseIndex = (array_index_t *)calloc(modelData->nVariablesReal, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->realVarsReverseIndex != NULL, "Out of memory");
  simulationInfo->integerVarsReverseIndex = (array_index_t *)calloc(modelData->nVariablesInteger, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->integerVarsReverseIndex != NULL, "Out of memory");
  simulationInfo->booleanVarsReverseIndex = (array_index_t *)calloc(modelData->nVariablesBoolean, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->booleanVarsReverseIndex != NULL, "Out of memory");
  simulationInfo->stringVarsReverseIndex = (array_index_t *)calloc(modelData->nVariablesString, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->stringVarsReverseIndex != NULL, "Out of memory");

  // Parameters
  simulationInfo->realParamsReverseIndex = (array_index_t *)calloc(modelData->nParametersReal, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->realParamsReverseIndex != NULL, "Out of memory");
  simulationInfo->integerParamsReverseIndex = (array_index_t *)calloc(modelData->nParametersInteger, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->integerParamsReverseIndex != NULL, "Out of memory");
  simulationInfo->booleanParamsReverseIndex = (array_index_t *)calloc(modelData->nParametersBoolean, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->booleanParamsReverseIndex != NULL, "Out of memory");
  simulationInfo->stringParamsReverseIndex = (array_index_t *)calloc(modelData->nParametersString, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->stringParamsReverseIndex != NULL, "Out of memory");

  // Alias variables
  simulationInfo->realAliasReverseIndex = (array_index_t *)calloc(modelData->nAliasReal, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->realAliasReverseIndex != NULL, "Out of memory");
  simulationInfo->integerAliasReverseIndex = (array_index_t *)calloc(modelData->nAliasInteger, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->integerAliasReverseIndex != NULL, "Out of memory");
  simulationInfo->booleanAliasReverseIndex = (array_index_t *)calloc(modelData->nAliasBoolean, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->booleanAliasReverseIndex != NULL, "Out of memory");
  simulationInfo->stringAliasReverseIndex = (array_index_t *)calloc(modelData->nAliasString, sizeof(array_index_t));
  assertStreamPrint(threadData, simulationInfo->stringAliasReverseIndex != NULL, "Out of memory");
}

/**
 * @brief Free memory of reverse variable index maps.
 *
 * Free memory allocated by `allocateArrayReverseIndexMaps`.
 *
 * @param simulationInfo    Simulation info with reverse index arrays to free.
 */
void freeArrayReverseIndexMaps(SIMULATION_INFO *simulationInfo)
{
  // Variables
  free(simulationInfo->realVarsReverseIndex);
  free(simulationInfo->integerVarsReverseIndex);
  free(simulationInfo->booleanVarsReverseIndex);
  free(simulationInfo->stringVarsReverseIndex);

  // Parameters
  free(simulationInfo->realParamsReverseIndex);
  free(simulationInfo->integerParamsReverseIndex);
  free(simulationInfo->booleanParamsReverseIndex);
  free(simulationInfo->stringParamsReverseIndex);

  // Alias variables
  free(simulationInfo->realAliasReverseIndex);
  free(simulationInfo->integerAliasReverseIndex);
  free(simulationInfo->booleanAliasReverseIndex);
  free(simulationInfo->stringAliasReverseIndex);
}

/**
 * @brief Get parameter by ID.
 *
 * @param id                    Identifier (value reference) to search for.
 * @param integerParameters     Array of parameters to search in.
 * @param nParameters           Length of array `integerParameters`.
 * @return STATIC_INTEGER_DATA* Return reference to parameter with identifier
 *                              `ID`. Will return NULL if no matching parameter
 *                              can be found.
 */
STATIC_INTEGER_DATA *getParamById(int id,
                                  STATIC_INTEGER_DATA *integerParameters,
                                  long nParameters)
{
  long i;
  for (i = 0; i < nParameters; i++)
  {
    if (integerParameters[i].info.id == id)
    {
      return &integerParameters[i];
    }
  }

  return NULL;
}

/**
 * @brief Calculate length of multi-dimensional array.
 *
 * #### Example
 *
 * Tensor T[2][3][4]:
 *   <dimension start="2">
 *   <dimension start="3">
 *   <dimension start="4">
 * will result in length 2*3*4 = 24
 *
 * Array a[p]:
 *   <dimension valueReference="1001">
 *   <dimension start="2">
 * will result in length p.start*2
 *
 * A scalar variable with no dimension info will always be size 1.
 *
 * @param dimensionInfo           Information about model dimension
 * @param integerParameterData    Used to look up start value of structural
 *                                parameters for start value by value reference.
 * @param nParametersIntegerArray Number of parameters in `integerParameterData`.
 * @return size_t                 Scalar length (product of dimensions).
 */
size_t calculateLength(DIMENSION_INFO *dimensionInfo,
                       STATIC_INTEGER_DATA *integerParameterData,
                       long nParametersIntegerArray)
{
  size_t length = 1;
  size_t dim_idx;
  DIMENSION_ATTRIBUTE *dimensionAttribute;
  STATIC_INTEGER_DATA *structuralParameter;

  if (dimensionInfo == NULL || dimensionInfo->numberOfDimensions == 0 || dimensionInfo->dimensions == NULL)
  {
    return length;
  }

  for (dim_idx = 0; dim_idx < dimensionInfo->numberOfDimensions; dim_idx++)
  {
    dimensionAttribute = &dimensionInfo->dimensions[dim_idx];
    assertStreamPrint(NULL, dimensionAttribute != NULL, "DIMENSION_ATTRIBUTE is NULL");

    switch (dimensionAttribute->type)
    {
    case DIMENSION_BY_START:
      length = length * dimensionAttribute->start;
      break;

    case DIMENSION_BY_VALUE_REFERENCE:
      structuralParameter = getParamById(dimensionAttribute->valueReference, integerParameterData, nParametersIntegerArray);
      assertStreamPrint(NULL, structuralParameter != NULL,
                        "Could not find parameter with id '%ld'.\n"
                        "Failed to calculate length of variable.",
                        dimensionAttribute->valueReference);

      dimensionAttribute->start = structuralParameter->attribute.start;
      length = length * structuralParameter->attribute.start;
      break;

    default:
      throwStreamPrint(NULL, "calculateLength: Illegal dimension attribute type case!");
      break;
    }
  }

  return length;
}

/**
 * @brief Print flattened names of array variable `name` to `stream`.
 *
 * @param stream          Stream to write to.
 * @param separator       Seperator to use, e.g. `", "`.
 * @param name            Name of array variable.
 * @param dimension_info  Dimension info for array variable.
 */
void printFlattenedNames(FILE *stream, const char* separator, const char *name, DIMENSION_INFO *dimension_info)
{
  if (dimension_info == NULL || dimension_info->numberOfDimensions <= 0 || dimension_info->dimensions == NULL)
  {
    throwStreamPrint(NULL, "Invalid dimension info.");
  }
  if (stream == NULL)
  {
    throwStreamPrint(NULL, "Invalid stream.");
  }
  if (separator == NULL)
  {
    throwStreamPrint(NULL, "Invalid separator.");
  }

  /* Temporary index array */
  size_t *idx = (size_t *)calloc(dimension_info->numberOfDimensions, sizeof(size_t));
  if (!idx)
  {
    throwStreamPrint(NULL, "Out of memory.");
  }

  for (size_t linear = 0; linear < dimension_info->scalar_length; linear++)
  {
    /* compute multi-dimensional indices for this linear index (row-major) */
    size_t rem = linear;
    for (size_t k = 0; k < dimension_info->numberOfDimensions; k++)
    {
      /* stride = product of sizes of dimensions after k */
      size_t stride = 1;
      for (size_t j = k + 1; j < dimension_info->numberOfDimensions; j++)
      {
        stride *= (size_t)dimension_info->dimensions[j].start;
      }
      idx[k] = rem / stride;
      rem = rem % stride;
    }

    /* write indices */
    fprintf(stream, "%s", name);
    for (size_t k = 0; k < dimension_info->numberOfDimensions; ++k)
    {
      fprintf(stream, "[%zu]", idx[k]);
    }
    fprintf(stream, "%s", separator);
  }

  free(idx);
}

/**
 * @brief Convert index from linear to lexicographical access order.
 *
 * The linear storage assumes row-major-order representation.
 * Linear version of an array is also called flattened or scalarized version.
 *
 * #### Example:
 *
 * For a 2x3 Matrix A =
 * ```txt
 *     a_{1,1} a_{1,2} a_{1,3}
 *     a_{2,1} a_{2,2} a_{2,3}
 * ```
 *
 * convert `Address` to `Access` according to
 *
 * ```txt
 * Address | Access  | Value
 * --------|---------|--------
 *    0    | A[0][0] | a_{1,1}
 *    1    | A[0][1] | a_{1,2}
 *    2    | A[0][2] | a_{1,3}
 *    3    | A[1][0] | a_{2,1}
 *    4    | A[1][1] | a_{2,2}
 *    5    | A[1][2] | a_{2,3}
 * ```
 *
 * @param dimension_info    Dimensions of multi-dimensional array.
 * @param linear_address    Linear array address.
 * @return size_t*          Array of indices,
 *                          caller is responsible to free with `free`.
 */
size_t *linearToMultiDimArrayIndex(DIMENSION_INFO *dimension_info, size_t linear_address)
{
  size_t k;

  if (dimension_info == NULL || dimension_info->numberOfDimensions <= 0 || dimension_info->dimensions == NULL)
  {
    throwStreamPrint(NULL, "Invalid dimension info.");
  }

  if(linear_address >= dimension_info->scalar_length) {
    throwStreamPrint(NULL, "Array out of range: %zu not in [0, %zu]", linear_address, dimension_info->scalar_length);
  }

  /* Allocate array for indices; caller is responsible for freeing */
  size_t *array_index = (size_t *)calloc(dimension_info->numberOfDimensions, sizeof(size_t));
  if (!array_index)
  {
    throwStreamPrint(NULL, "Out of memory.");
  }

  /* Compute sizes of later dimensions for row-major ordering */
  size_t *stride = (size_t *)calloc(dimension_info->numberOfDimensions, sizeof(size_t));
  if (!stride)
  {
    free(array_index);
    throwStreamPrint(NULL, "Out of memory.");
  }

  /* stride[k] = product of dimensions[k+1..dimension->numberOfDimensions-1];
   * last stride = 1 */
  stride[dimension_info->numberOfDimensions - 1] = 1;
  for (k = dimension_info->numberOfDimensions - 2; k > 0; k--)
  {
    stride[k] = stride[k + 1] * dimension_info->dimensions[k + 1].start;
  }
  stride[0] = stride[1] * dimension_info->dimensions[1].start;

  size_t remaining = linear_address;
  for (k = 0; k < dimension_info->numberOfDimensions; k++)
  {
    array_index[k] = remaining / stride[k];
    remaining = remaining % stride[k];
  }

  free(stride);
  return array_index;
}

/**
 * @brief Convert index from lexicographical access order to linear.
 *
 * The linear storage assumes row-major-order representation, see
 * https://en.wikipedia.org/wiki/Row-_and_column-major_order.
 * Linear version of an array is also called flattened or scalarized version.
 *
 * #### Example:
 *
 * For a 2x3 Matrix A =
 * ```txt
 *     a_{1,1} a_{1,2} a_{1,3}
 *     a_{2,1} a_{2,2} a_{2,3}
 * ```
 *
 * convert `Access` to `Address` according to
 *
 * ```txt
 * Address | Access  | Value
 * --------|---------|--------
 *    0    | A[0][0] | a_{1,1}
 *    1    | A[0][1] | a_{1,2}
 *    2    | A[0][2] | a_{1,3}
 *    3    | A[1][0] | a_{2,1}
 *    4    | A[1][1] | a_{2,2}
 *    5    | A[1][2] | a_{2,3}
 * ```
 *
 * @param dimension_info    Dimensions of multi-dimensional array.
 * @param array_index       Array of indices
 * @return size_t           Linear array address.
 */
size_t multiDimArrayToLinearIndex(DIMENSION_INFO* dimension_info, size_t* array_index) {
  size_t linear_address = 0;
  size_t dim_product;

  if (dimension_info == NULL || dimension_info->numberOfDimensions <= 0 || dimension_info->dimensions == NULL)
  {
    throwStreamPrint(NULL, "Invalid dimension info.");
  }

  if (array_index == NULL)
  {
    throwStreamPrint(NULL, "Array index pointer is NULL.");
  }

   for (size_t k = 0; k < dimension_info->numberOfDimensions; k++) {
     if (array_index[k] >= dimension_info->dimensions[k].start) {
       throwStreamPrint(NULL, "Index out of bounds: array_index[%zu] = %zu >= %zu",
                        k, array_index[k], dimension_info->dimensions[k].start);
     }

     dim_product = 1;
     /* multiply sizes of later dimensions (k+1 .. n-1) for row-major */
     for (size_t l = k + 1; l < dimension_info->numberOfDimensions; l++) {
       dim_product *= dimension_info->dimensions[l].start;
     }
     linear_address += dim_product * array_index[k];
   }

  return linear_address;
}

/**
 * @brief Calculate scalar length of all array variables.
 *
 * Needs all start values of structural parameters to be set.
 *
 * @param modelData Model data containing variable data with array variables to
 *                  update.
 */
void calculateAllScalarLength(MODEL_DATA *modelData)
{
  long i;

  // Update variables
  for (i = 0; i < modelData->nVariablesRealArray; i++)
  {
    modelData->realVarsData[i].dimension.scalar_length = calculateLength(&modelData->realVarsData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nVariablesIntegerArray; i++)
  {
    modelData->integerVarsData[i].dimension.scalar_length = calculateLength(&modelData->integerVarsData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nVariablesBooleanArray; i++)
  {
    modelData->booleanVarsData[i].dimension.scalar_length = calculateLength(&modelData->booleanVarsData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nVariablesStringArray; i++)
  {
    modelData->stringVarsData[i].dimension.scalar_length = calculateLength(&modelData->stringVarsData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }

  // Update parameters
  for (i = 0; i < modelData->nParametersRealArray; i++)
  {
    modelData->realParameterData[i].dimension.scalar_length = calculateLength(&modelData->realParameterData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nParametersIntegerArray; i++)
  {
    modelData->integerParameterData[i].dimension.scalar_length = calculateLength(&modelData->integerParameterData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nParametersBooleanArray; i++)
  {
    modelData->booleanParameterData[i].dimension.scalar_length = calculateLength(&modelData->booleanParameterData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
  for (i = 0; i < modelData->nParametersStringArray; i++)
  {
    modelData->stringParameterData[i].dimension.scalar_length = calculateLength(&modelData->stringParameterData[i].dimension, modelData->integerParameterData, modelData->nParametersIntegerArray);
  }
}

/**
 * @brief Compute variable index of one type.
 *
 * Compute where in `SIMULATION_DATA-><TYPE>Vars` a variable starts.
 *
 * Assumes order of array `variableData` is identical to order in `varsIndex`
 * and SIMULATION_DATA arrays.
 *
 * #### Example
 *
 * We have variables `x[3]`, `y`, `z[2]` where `x` is an array of length 3, `y`
 * a scalar and `z` an array of length 3. Then: `varsIndex = [0, 3, 4, 6]`.
 *
 * @param variableData    Model variable data. Is of type `STATIC_REAL_DATA*`,
 *                        `STATIC_INTEGER_DATA*`, `STATIC_BOOLEAN_DATA*` or
 *                        `STATIC_STRING_DATA*`.
 * @param type            Specifies type of model variable `variableData`.
 * @param num_variables   Number of variables in array `variableData`.
 * @param varsIndex       Variable index to compute. Will be set on return.
 */
void computeVarsIndex(void *variableData,
                      enum var_type type,
                      size_t num_variables,
                      size_t *varsIndex)
{
  size_t i;
  int id;
  int previous_id = -1;
  DIMENSION_INFO *dimensionInfo;
  size_t scalar_length;

  varsIndex[0] = 0;
  for (i = 0; i < num_variables; i++)
  {
    switch (type)
    {
    case T_REAL:
      dimensionInfo = &((STATIC_REAL_DATA *)variableData)[i].dimension;
      id = ((STATIC_REAL_DATA *)variableData)[i].info.id;
      break;
    case T_INTEGER:
      dimensionInfo = &((STATIC_INTEGER_DATA *)variableData)[i].dimension;
      id = ((STATIC_INTEGER_DATA *)variableData)[i].info.id;
      break;
    case T_BOOLEAN:
      dimensionInfo = &((STATIC_BOOLEAN_DATA *)variableData)[i].dimension;
      id = ((STATIC_BOOLEAN_DATA *)variableData)[i].info.id;
      break;
    case T_STRING:
      dimensionInfo = &((STATIC_STRING_DATA *)variableData)[i].dimension;
      id = ((STATIC_STRING_DATA *)variableData)[i].info.id;
      break;
    default:
      throwStreamPrint(NULL, "computeVarsIndex: Illegal variable type case.");
    }

    assertStreamPrint(NULL, id == 0 || id > previous_id,      // TODO: FMUs don't set id
                      "Value reference not increasing. "
                      "`realVarsData` isn't sorted correctly!");
    previous_id = id;

    scalar_length = dimensionInfo != NULL ? dimensionInfo->scalar_length : 1;
    varsIndex[i + 1] = varsIndex[i] + scalar_length;
  }
}

/**
 * @brief Compute alias index for array variables.
 *
 * Returns identity array mapping.
 *
 * This assumes we only create alias variables for scalar variables.
 *
 * @param varsIndex     Alias index to set.
 * @param num_variables Number of variables.
 */
void computeAliasIndex(size_t *varsIndex,
                       size_t num_variables)
{
  unsigned int i;
  for (i = 0; i < num_variables + 1; i++)
  {
    varsIndex[i] = i;
  }
}

/**
 * @brief Compute all array mappings for scalarized variables.
 *
 * TODO: Handle sensitivity parameters.
 *
 * @param simulationInfo  Simulation info with index maps to set.
 * @param modelData       Model data with number of variables.
 */
void computeVarIndices(SIMULATION_INFO *simulationInfo,
                       MODEL_DATA *modelData)
{
  // Variables
  computeVarsIndex(modelData->realVarsData, T_REAL, modelData->nVariablesRealArray, simulationInfo->realVarsIndex);
  // TODO: Are states, state derivatives, algebraic variables and discrete algebraic variables handled with this?
  computeVarsIndex(modelData->integerVarsData, T_INTEGER, modelData->nVariablesIntegerArray, simulationInfo->integerVarsIndex);
  computeVarsIndex(modelData->booleanVarsData, T_BOOLEAN, modelData->nVariablesBooleanArray, simulationInfo->booleanVarsIndex);
  computeVarsIndex(modelData->stringVarsData, T_STRING, modelData->nVariablesStringArray, simulationInfo->stringVarsIndex);

  // Parameters
  computeVarsIndex(modelData->realParameterData, T_REAL, modelData->nParametersRealArray, simulationInfo->realParamsIndex);
  computeVarsIndex(modelData->integerParameterData, T_INTEGER, modelData->nParametersIntegerArray, simulationInfo->integerParamsIndex);
  computeVarsIndex(modelData->booleanParameterData, T_BOOLEAN, modelData->nParametersBooleanArray, simulationInfo->booleanParamsIndex);
  computeVarsIndex(modelData->stringParameterData, T_STRING, modelData->nParametersStringArray, simulationInfo->stringParamsIndex);

  // TODO: Sensitivity parameter array + index

  // Alias
  computeAliasIndex(simulationInfo->realAliasIndex, modelData->nAliasRealArray);
  computeAliasIndex(simulationInfo->integerAliasIndex, modelData->nAliasIntegerArray);
  computeAliasIndex(simulationInfo->booleanAliasIndex, modelData->nAliasBooleanArray);
  computeAliasIndex(simulationInfo->stringAliasIndex, modelData->nAliasStringArray);
}

/**
 * @brief Compute variable reverse index map of one type.
 *
 * Compute where a variable `SIMULATION_DATA-><TYPE>Vars` originates from in
 * `MODEL_DATA-><TYPE>VarsData`. So for every scalarized index this functions
 * computes a look up to get the index of the corresponding scalar/ array
 * varible and the index inside the array variable.
 *
 * @param variableData    Model variable data. Is of type `STATIC_REAL_DATA*`,
 *                        `STATIC_INTEGER_DATA*`, `STATIC_BOOLEAN_DATA*` or
 *                        `STATIC_STRING_DATA*`.
 * @param type            Specifies type of model variable `variableData`.
 * @param num_variables   Number of variables after flattening.
 * @param reverseIndex    Variable reverse index to compute.
 */
void computeVarsReverseIndex(void *variableData,
                             enum var_type type,
                             size_t num_variables,
                             array_index_t* reverseIndex) {

  size_t scalar_length;
  size_t i = 0;

  for (size_t var_count = 0; var_count < num_variables; var_count++)
  {
    switch (type)
    {
    case T_REAL:
      scalar_length = ((STATIC_REAL_DATA *)variableData)[i].dimension.scalar_length;
      break;
    case T_INTEGER:
      scalar_length = ((STATIC_INTEGER_DATA *)variableData)[i].dimension.scalar_length;
      break;
    case T_BOOLEAN:
      scalar_length = ((STATIC_BOOLEAN_DATA *)variableData)[i].dimension.scalar_length;
      break;
    case T_STRING:
      scalar_length = ((STATIC_STRING_DATA *)variableData)[i].dimension.scalar_length;
      break;
    default:
      throwStreamPrint(NULL, "computeVarsIndex: Illegal variable type case.");
    }

    for (size_t dim = 0; dim < scalar_length; dim++, i++) {
      reverseIndex[i].array_idx = var_count;
      reverseIndex[i].dim_idx = dim;
    }
  }
}
/**
 * @brief Compute all mappings for scalarized variables to array variables.
 *
 * TODO: Add rest
 *
 * @param simulationInfo  Simulation info with index maps to set.
 * @param modelData       Model data with number of variables.
 */
void computeVarReverseIndices(SIMULATION_INFO *simulationInfo,
                              MODEL_DATA *modelData) {

  // Variables
  computeVarsReverseIndex(modelData->realVarsData, T_REAL, modelData->nVariablesReal, simulationInfo->realVarsReverseIndex);
}


modelica_real getNominalFromScalarIdx(const SIMULATION_INFO *simulationInfo,
                                      const MODEL_DATA *modelData,
                                      size_t scalar_idx) {
  array_index_t* revIndex = &simulationInfo->realVarsReverseIndex[scalar_idx];
  return real_get(modelData->realVarsData[revIndex->array_idx].attribute.nominal, revIndex->dim_idx);
}
