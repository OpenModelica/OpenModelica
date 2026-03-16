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

  /* No discrete variables */
  if (modelData->nDiscreteReal == 0 &&
      modelData->nVariablesInteger == 0 &&
      modelData->nVariablesBoolean == 0 &&
      modelData->nVariablesString == 0)
  {
    return FALSE;
  }

  modelica_boolean needToIterate = FALSE;
  if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
  {
    infoStreamPrint(OMC_LOG_EVENTS_V, 1, "check for discrete changes at time=%.12g",
                    data->localData[0]->timeValue);
  }

  /* Real discrete variables */
  for (long i = modelData->nVariablesReal - modelData->nDiscreteReal; i < modelData->nVariablesReal; i++)
  {
    if (strncmp(modelData->realVarsData[i].info.name, "$cse", 4))
    {
      modelica_real v1 = data->simulationInfo->realVarsPre[i];
      modelica_real v2 = data->localData[0]->realVars[i];
      if (v1 != v2)
      {
        needToIterate = TRUE;
        if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
        {
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %g to %g",
                          modelData->realVarsData[i].info.name, v1, v2);
        }
        else
        {
          return needToIterate;
        }
      }
    }
  }

  for (long i = 0; i < modelData->nVariablesInteger; i++)
  {
    if (strncmp(modelData->integerVarsData[i].info.name, "$cse", 4))
    {
      modelica_integer v1 = data->simulationInfo->integerVarsPre[i];
      modelica_integer v2 = data->localData[0]->integerVars[i];
      if (v1 != v2)
      {
        needToIterate = TRUE;
        if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
        {
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %ld to %ld",
                          modelData->integerVarsData[i].info.name, (long)v1, (long)v2);
        }
        else
        {
          return needToIterate;
        }
      }
    }
  }

  for (long i = 0; i < modelData->nVariablesBoolean; i++)
  {
    if (strncmp(modelData->booleanVarsData[i].info.name, "$cse", 4))
    {
      modelica_boolean v1 = data->simulationInfo->booleanVarsPre[i];
      modelica_boolean v2 = data->localData[0]->booleanVars[i];
      if (v1 != v2)
      {
        needToIterate = TRUE;
        if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
        {
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %d to %d",
                          modelData->booleanVarsData[i].info.name, v1, v2);
        }
        else
        {
          return needToIterate;
        }
      }
    }
  }

  for (long i = 0; i < modelData->nVariablesString; i++)
  {
    if (strncmp(modelData->stringVarsData[i].info.name, "$cse", 4))
    {
      modelica_string v1 = data->simulationInfo->stringVarsPre[i];
      modelica_string v2 = data->localData[0]->stringVars[i];
      if (0 != strcmp(MMC_STRINGDATA(v1), MMC_STRINGDATA(v2)))
      {
        needToIterate = TRUE;
        if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
        {
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %s to %s",
                          modelData->stringVarsData[i].info.name, MMC_STRINGDATA(v1), MMC_STRINGDATA(v2));
        }
        else
        {
          return needToIterate;
        }
      }
    }
  }

  if (OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
  {
    messageClose(OMC_LOG_EVENTS_V);
  }

  return needToIterate;
}
