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
