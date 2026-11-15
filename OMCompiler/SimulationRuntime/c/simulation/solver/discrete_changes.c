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

#include "discrete_changes.h"
#include "../arrayIndex.h"

/* Whether pre[i] != cur[i] for some i in [i, end). No early exit inside a block
 * of 32, so that the compiler vectorizes the comparisons. */
#define DEFINE_ANY_CHANGE(NAME, TYPE)                                                 \
  static modelica_boolean NAME(const TYPE *pre, const TYPE *cur, size_t i, size_t end) \
  {                                                                                    \
    size_t k;                                                                          \
    for (; i + 32 <= end; i += 32) {                                                   \
      int diff = 0;                                                                    \
      for (k = 0; k < 32; k++)                                                         \
        diff |= pre[i + k] != cur[i + k];                                              \
      if (diff)                                                                        \
        return TRUE;                                                                   \
    }                                                                                  \
    for (; i < end; i++)                                                               \
      if (pre[i] != cur[i])                                                            \
        return TRUE;                                                                   \
    return FALSE;                                                                      \
  }

DEFINE_ANY_CHANGE(anyRealChange, modelica_real)
DEFINE_ANY_CHANGE(anyIntegerChange, modelica_integer)
DEFINE_ANY_CHANGE(anyBooleanChange, modelica_boolean)

/* modelData->discreteChangeRanges gives, for the discrete Real, the Integer, the
 * Boolean and the String variables in turn, the number of ranges and then the
 * ranges [start, end) of array indices (SimCodeCodegenUtil.discreteChangeRanges).
 * The Booleans are compared first: they are cheap, and the when conditions
 * among them often carry the change. */
static modelica_boolean anyDiscreteChange(DATA *data)
{
  const long *reals = data->modelData->discreteChangeRanges;
  const long *integers = reals + 1 + 2 * reals[0];
  const long *booleans = integers + 1 + 2 * integers[0];
  const long *r = booleans + 1 + 2 * booleans[0];
  const SIMULATION_INFO *s = data->simulationInfo;
  const SIMULATION_DATA *d = data->localData[0];
  long k, n;
  size_t i;

  for (n = *booleans++, k = 0; k < n; k++, booleans += 2)
    if (anyBooleanChange(s->booleanVarsPre, d->booleanVars, s->booleanVarsIndex[booleans[0]], s->booleanVarsIndex[booleans[1]]))
      return TRUE;
  for (n = *integers++, k = 0; k < n; k++, integers += 2)
    if (anyIntegerChange(s->integerVarsPre, d->integerVars, s->integerVarsIndex[integers[0]], s->integerVarsIndex[integers[1]]))
      return TRUE;
  for (n = *reals++, k = 0; k < n; k++, reals += 2)
    if (anyRealChange(s->realVarsPre, d->realVars, s->realVarsIndex[reals[0]], s->realVarsIndex[reals[1]]))
      return TRUE;
  for (n = *r++, k = 0; k < n; k++, r += 2)
    for (i = s->stringVarsIndex[r[0]]; i < s->stringVarsIndex[r[1]]; i++)
      if (!stringEqual(s->stringVarsPre[i], d->stringVars[i]))
        return TRUE;
  return FALSE;
}

/**
 * @brief Check for changes in discrete variables since the previous step.
 *
 * This routine compares the current values of the discrete variables with
 * their previous stored values. The compiler leaves out the common
 * subexpression temporaries ($cse), see modelData->discreteChangeRanges.
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
  const long *r = modelData->discreteChangeRanges;
  modelica_boolean needToIterate = FALSE;
  size_t buffer_size = 2000;
  char *index_buffer;
  long k, n, arrayIdx;
  size_t scalarIdx;

  if (!OMC_ACTIVE_STREAM(OMC_LOG_EVENTS_V))
  {
    return anyDiscreteChange(data);
  }

  index_buffer = (char*) malloc(buffer_size*sizeof(char));
  infoStreamPrint(OMC_LOG_EVENTS_V, 1, "check for discrete changes at time=%.12g",
                  data->localData[0]->timeValue);

  for (n = *r++, k = 0; k < n; k++, r += 2)
  {
    for (arrayIdx = r[0]; arrayIdx < r[1]; arrayIdx++)
    {
      for (scalarIdx = simulationInfo->realVarsIndex[arrayIdx]; scalarIdx < simulationInfo->realVarsIndex[arrayIdx + 1]; scalarIdx++)
      {
        modelica_real v1 = simulationInfo->realVarsPre[scalarIdx];
        modelica_real v2 = data->localData[0]->realVars[scalarIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          printMultiDimArrayIndex(&modelData->realVarsData[arrayIdx].dimension, scalarIdx - simulationInfo->realVarsIndex[arrayIdx], index_buffer, buffer_size);
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %g to %g",
                          modelData->realVarsData[arrayIdx].info.name, index_buffer, v1, v2);
        }
      }
    }
  }

  for (n = *r++, k = 0; k < n; k++, r += 2)
  {
    for (arrayIdx = r[0]; arrayIdx < r[1]; arrayIdx++)
    {
      for (scalarIdx = simulationInfo->integerVarsIndex[arrayIdx]; scalarIdx < simulationInfo->integerVarsIndex[arrayIdx + 1]; scalarIdx++)
      {
        modelica_integer v1 = simulationInfo->integerVarsPre[scalarIdx];
        modelica_integer v2 = data->localData[0]->integerVars[scalarIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          printMultiDimArrayIndex(&modelData->integerVarsData[arrayIdx].dimension, scalarIdx - simulationInfo->integerVarsIndex[arrayIdx], index_buffer, buffer_size);
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %ld to %ld",
                          modelData->integerVarsData[arrayIdx].info.name, index_buffer, (long)v1, (long)v2);
        }
      }
    }
  }

  for (n = *r++, k = 0; k < n; k++, r += 2)
  {
    for (arrayIdx = r[0]; arrayIdx < r[1]; arrayIdx++)
    {
      for (scalarIdx = simulationInfo->booleanVarsIndex[arrayIdx]; scalarIdx < simulationInfo->booleanVarsIndex[arrayIdx + 1]; scalarIdx++)
      {
        modelica_boolean v1 = simulationInfo->booleanVarsPre[scalarIdx];
        modelica_boolean v2 = data->localData[0]->booleanVars[scalarIdx];
        if (v1 != v2)
        {
          needToIterate = TRUE;
          printMultiDimArrayIndex(&modelData->booleanVarsData[arrayIdx].dimension, scalarIdx - simulationInfo->booleanVarsIndex[arrayIdx], index_buffer, buffer_size);
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s%s from %s to %s",
                          modelData->booleanVarsData[arrayIdx].info.name, index_buffer, v1 ? "true" : "false", v2 ? "true" : "false");
        }
      }
    }
  }

  for (n = *r++, k = 0; k < n; k++, r += 2)
  {
    for (arrayIdx = r[0]; arrayIdx < r[1]; arrayIdx++)
    {
      for (scalarIdx = simulationInfo->stringVarsIndex[arrayIdx]; scalarIdx < simulationInfo->stringVarsIndex[arrayIdx + 1]; scalarIdx++)
      {
        modelica_string v1 = simulationInfo->stringVarsPre[scalarIdx];
        modelica_string v2 = data->localData[0]->stringVars[scalarIdx];
        if (!stringEqual(v1, v2))
        {
          needToIterate = TRUE;
          infoStreamPrint(OMC_LOG_EVENTS_V, 0, "discrete var changed: %s from %s to %s",
                          modelData->stringVarsData[arrayIdx].info.name, omc_string_data(v1), omc_string_data(v2));
        }
      }
    }
  }

  messageClose(OMC_LOG_EVENTS_V);
  free(index_buffer);

  return needToIterate;
}
