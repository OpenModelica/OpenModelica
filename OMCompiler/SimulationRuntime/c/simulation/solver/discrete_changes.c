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

#include "discrete_changes.h"
#include "../arrayIndex.h"

/**
 * @brief Check for changes in discrete variables since the previous step.
 *
 * This routine compares the current values of discrete variables with their
 * previous stored values. Variables whose names begin with "$cse" (common
 * subexpression temporaries) are ignored.
 *
 * When verbose event logging (`OMC_LOG_EVENTS_V`) is enabled the function will
 * print an entry for each changed variable.
 *
 * @param data              Pointer to simulation `DATA` structure containing
 *                          model metadata and current/previous variable values.
 * @param threadData        Thread-local data, unused by this function
 * @return modelica_boolean Returns `TRUE` if any discrete variable changed,
 *                          otherwise `FALSE`.
 */
modelica_boolean checkForDiscreteChanges(DATA *data, threadData_t *threadData)
{
  MODEL_DATA *modelData = data->modelData;
  SIMULATION_INFO *simulationInfo = data->simulationInfo;

  /* No discrete variables */
  if (modelData->nDiscreteRealArray == 0 &&
      modelData->nVariablesIntegerArray == 0 &&
      modelData->nVariablesBooleanArray == 0 &&
      modelData->nVariablesStringArray == 0)
  {
    return FALSE;
  }

  modelica_boolean needToIterate = FALSE;
  char* index_buffer;
  size_t buffer_size = 2000;
  if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
  {
    infoStreamPrint(OMC_LOG_EVENTS_V, 1, "check for discrete changes at time=%.12g",
                    data->localData[0]->timeValue);
    index_buffer = (char*) malloc(buffer_size*sizeof(char));
  }

  /* Real discrete variables */
  for (long arrayIdx = modelData->nVariablesRealArray - modelData->nDiscreteRealArray; arrayIdx < modelData->nVariablesRealArray; arrayIdx++)
  {
    if (strncmp(modelData->realVarsData[arrayIdx].info.name, "$cse", 4))
    {
      for (int i = 0; modelData->realVarsData[arrayIdx].dimension.scalar_length; i++)
      {
        size_t scalarIdx = simulationInfo->realVarsIndex[arrayIdx] + i;
        modelica_real v1 = simulationInfo->realVarsPre[scalarIdx];
        modelica_real v2 = data->localData[0]->realVars[scalarIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
          {
            printMultiDimArrayIndex(&modelData->realVarsData[arrayIdx].dimension, scalarIdx, index_buffer, buffer_size);
            infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %g to %g",
                            modelData->realVarsData[arrayIdx].info.name, index_buffer, v1, v2);
          }
          else
          {
            return needToIterate;
          }
        }
      }
    }
  }

  for (long arrayIdx = 0; arrayIdx < modelData->nVariablesIntegerArray; arrayIdx++)
  {
    if (strncmp(modelData->integerVarsData[arrayIdx].info.name, "$cse", 4))
    {
      for (int i = 0; modelData->integerVarsData[arrayIdx].dimension.scalar_length; i++)
      {
        size_t scalarIdx = simulationInfo->integerVarsIndex[arrayIdx] + i;
        modelica_integer v1 = simulationInfo->integerVarsPre[scalarIdx];
        modelica_integer v2 = data->localData[0]->integerVars[scalarIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
          {
            printMultiDimArrayIndex(&modelData->integerVarsData[arrayIdx].dimension, scalarIdx, index_buffer, buffer_size);
            infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %ld to %ld",
                            modelData->integerVarsData[arrayIdx].info.name, index_buffer, (long)v1, (long)v2);
          }
          else
          {
            return needToIterate;
          }
        }
      }
    }
  }

  for (long arrayIdx = 0; arrayIdx < modelData->nVariablesBooleanArray; arrayIdx++)
  {
    if (strncmp(modelData->booleanVarsData[arrayIdx].info.name, "$cse", 4))
    {
      for (int i = 0; modelData->booleanVarsData[arrayIdx].dimension.scalar_length; i++)
      {
        size_t scalarIdx = simulationInfo->booleanVarsIndex[arrayIdx] + i;
        modelica_boolean v1 = simulationInfo->booleanVarsPre[arrayIdx];
        modelica_boolean v2 = data->localData[0]->booleanVars[arrayIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
          {
            printMultiDimArrayIndex(&modelData->booleanVarsData[arrayIdx].dimension, scalarIdx, index_buffer, buffer_size);
            infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %d to %d",
                            modelData->booleanVarsData[arrayIdx].info.name, index_buffer, v1, v2);
          }
          else
          {
            return needToIterate;
          }
        }
      }
    }
  }

  for (long arrayIdx = 0; arrayIdx < modelData->nVariablesStringArray; arrayIdx++)
  {
    if (strncmp(modelData->stringVarsData[arrayIdx].info.name, "$cse", 4))
    {
      for (int i = 0; modelData->stringVarsData[arrayIdx].dimension.scalar_length; i++)
      {
        size_t scalarIdx = simulationInfo->stringVarsIndex[arrayIdx] + i;
        modelica_string v1 = simulationInfo->stringVarsPre[arrayIdx];
        modelica_string v2 = data->localData[0]->stringVars[arrayIdx];
        if (0 != strcmp(MMC_STRINGDATA(v1), MMC_STRINGDATA(v2)))
        {
          needToIterate = TRUE;
          if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
          {
            printMultiDimArrayIndex(&modelData->stringVarsData[arrayIdx].dimension, scalarIdx, index_buffer, buffer_size);
            infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %s to %s",
                            modelData->stringVarsData[arrayIdx].info.name, MMC_STRINGDATA(v1), MMC_STRINGDATA(v2));
          }
          else
          {
            return needToIterate;
          }
        }
      }
    }
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
  {
    messageClose(OMC_LOG_EVENTS_V);
    free(index_buffer);
  }

  return needToIterate;
}
