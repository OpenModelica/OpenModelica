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

#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <cstring>
#include <cstdlib>
#include <stdint.h>
#include <assert.h>

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
  size_t maxLengthName;    /* Lenght of longest variable name */
  size_t maxLengthDesc;   /* Length of longest variable description */
  size_t nSignals;        /* Number of signals */
};

enum channel_t: int32_t {
  CHANNEL_TIME = 0,
  CHANNEL_TIME_INVARIANT = 1,
  CHANNEL_TIME_VARIANT = 2
};

enum interpolation_t: int32_t {
  INTERPOLATION_LINEAR = 0
};

enum extrapolation_t: int32_t {
  EXTRAPOLATION_NOT_ALLOWED = -1,
  EXTRAPOLATION_CONSTANT = 0,
  EXTRAPOLATION_LINEAR = 1
};

/**
 * @brief DataInfo
 *
 * Information for each variable. See
 * doc/UsersGuide/source/technical_details.rst for details.
 */
typedef struct DataInfo {
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
  extrapolation_t extraplotation;
} DataInfo;

static const char timeName[] = "time";
static const char timeDesc[] = "Simulation time [s]";
static const char cpuTimeName[] = "$cpuTime";
static const char cpuTimeDesc[] = "cpu time [s]";
static const char solverStepsName[] = "$solverSteps";
static const char solverStepsDesc[] = "number of steps taken by the integrator";

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
  size_t len;
  struct variableCount count = {
    .maxLengthName = strlen(timeName) + 1,
    .maxLengthDesc = strlen(timeDesc) + 1,
    .nSignals = 1};

  if (cpuTime)
  {
    len = strlen(cpuTimeName) + 1;
    if (len > count.maxLengthName)
      count.maxLengthName = len;
    len = strlen(cpuTimeDesc) + 1;
    if (len > count.maxLengthDesc)
      count.maxLengthDesc = len;
    count.nSignals++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    len = strlen(solverStepsName) + 1;
    if (len > count.maxLengthName)
      count.maxLengthName = len;
    len = strlen(solverStepsDesc) + 1;
    if (len > count.maxLengthDesc)
      count.maxLengthDesc = len;
    count.nSignals++;
  }

  for (int i = 0; i < mData->nVariablesReal; i++)
  {
    if (!mData->realVarsData[i].filterOutput)
    {
      const char *unitStr = MMC_STRINGDATA(mData->realVarsData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) + 3 : 0;

      len = strlen(mData->realVarsData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->realVarsData[i].info.comment) + 1 + unitLength;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  if (omc_flag[FLAG_IDAS])
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      len = strlen(mData->realSensitivityData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->realSensitivityData[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }

  for (int i = 0; i < mData->nVariablesInteger; i++)
  {
    if (!mData->integerVarsData[i].filterOutput)
    {
      len = strlen(mData->integerVarsData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->integerVarsData[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nVariablesBoolean; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput)
    {
      len = strlen(mData->booleanVarsData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->booleanVarsData[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nParametersReal; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      const char *unitStr = MMC_STRINGDATA(mData->realParameterData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) + 3 : 0;

      len = strlen(mData->realParameterData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->realParameterData[i].info.comment) + 1 + unitLength;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nParametersInteger; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      len = strlen(mData->integerParameterData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->integerParameterData[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nParametersBoolean; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      len = strlen(mData->booleanParameterData[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->booleanParameterData[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nAliasReal; i++)
  {
    if (!mData->realAlias[i].filterOutput)
    {
      const char *unitStr = NULL;
      size_t unitLength = 0;

      if (mData->realAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      { /* variable */
        unitStr = MMC_STRINGDATA(mData->realVarsData[mData->realAlias[i].nameID].attribute.unit);
        unitLength = unitStr ? strlen(unitStr) + 3 : 0;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_PARAMETER)
      { /* parameter */
        unitStr = MMC_STRINGDATA(mData->realParameterData[mData->realAlias[i].nameID].attribute.unit);
        unitLength = unitStr ? strlen(unitStr) + 3 : 0;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_TIME)
      { /* time */
        unitStr = "s";
        unitLength = 4;
      }

      len = strlen(mData->realAlias[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->realAlias[i].info.comment) + 1 + unitLength;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nAliasInteger; i++)
  {
    if (!mData->integerAlias[i].filterOutput)
    {
      len = strlen(mData->integerAlias[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->integerAlias[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  for (int i = 0; i < mData->nAliasBoolean; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      len = strlen(mData->booleanAlias[i].info.name) + 1;
      if (len > count.maxLengthName)
        count.maxLengthName = len;
      len = strlen(mData->booleanAlias[i].info.comment) + 1;
      if (len > count.maxLengthDesc)
        count.maxLengthDesc = len;
      count.nSignals++;
    }
  }

  return count;
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
  void *name = calloc(sizeof(char), maxLengthName * matData->nSignals);
  void *description = calloc(sizeof(char), maxLengthDesc * matData->nSignals);
  size_t cur = 0;
  memcpy(name, timeName, strlen(timeName));
  memcpy(description, timeDesc, strlen(timeDesc));
  cur++;

  if (self->cpuTime)
  {
    memcpy((uint8_t *)name + maxLengthName * cur, cpuTimeName, strlen(cpuTimeName));
    memcpy((uint8_t *)description + maxLengthDesc * cur, cpuTimeDesc, strlen(cpuTimeDesc));
    cur++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    memcpy((uint8_t *)name + maxLengthName * cur, solverStepsName, strlen(solverStepsName));
    memcpy((uint8_t *)description + maxLengthDesc * cur, solverStepsDesc, strlen(solverStepsDesc));
    cur++;
  }

  for (int i = 0; i < mData->nVariablesReal; i++)
  {
    if (!mData->realVarsData[i].filterOutput)
    {
      const char *unitStr = MMC_STRINGDATA(mData->realVarsData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) : 0;

      memcpy((uint8_t *)name + maxLengthName * cur, mData->realVarsData[i].info.name, strlen(mData->realVarsData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->realVarsData[i].info.comment, strlen(mData->realVarsData[i].info.comment));
      // unit information
      if (unitLength > 0)
      {
        memcpy((uint8_t *)description + maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 2, unitStr, unitLength);
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 0] = ' ';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 1] = '[';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 2 + unitLength] = ']';
      }
      cur++;
    }
  }

  if (omc_flag[FLAG_IDAS])
  {
    for (int i = mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->realSensitivityData[i].info.name, strlen(mData->realSensitivityData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->realSensitivityData[i].info.comment, strlen(mData->realSensitivityData[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesInteger; i++)
  {
    if (!mData->integerVarsData[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->integerVarsData[i].info.name, strlen(mData->integerVarsData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->integerVarsData[i].info.comment, strlen(mData->integerVarsData[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nVariablesBoolean; i++)
  {
    if (!mData->booleanVarsData[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->booleanVarsData[i].info.name, strlen(mData->booleanVarsData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->booleanVarsData[i].info.comment, strlen(mData->booleanVarsData[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersReal; i++)
  {
    if (!mData->realParameterData[i].filterOutput)
    {
      const char *unitStr = MMC_STRINGDATA(mData->realParameterData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) : 0;

      memcpy((uint8_t *)name + maxLengthName * cur, mData->realParameterData[i].info.name, strlen(mData->realParameterData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->realParameterData[i].info.comment, strlen(mData->realParameterData[i].info.comment));
      // unit information
      if (unitLength > 0)
      {
        memcpy((uint8_t *)description + maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 2, unitStr, unitLength);
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 0] = ' ';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 1] = '[';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 2 + unitLength] = ']';
      }
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersInteger; i++)
  {
    if (!mData->integerParameterData[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->integerParameterData[i].info.name, strlen(mData->integerParameterData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->integerParameterData[i].info.comment, strlen(mData->integerParameterData[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nParametersBoolean; i++)
  {
    if (!mData->booleanParameterData[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->booleanParameterData[i].info.name, strlen(mData->booleanParameterData[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->booleanParameterData[i].info.comment, strlen(mData->booleanParameterData[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nAliasReal; i++)
  {
    if (!mData->realAlias[i].filterOutput)
    {
      const char *unitStr = NULL;
      size_t unitLength = 0;

      if (mData->realAlias[i].aliasType == ALIAS_TYPE_VARIABLE)
      { /* variable */
        unitStr = MMC_STRINGDATA(mData->realVarsData[mData->realAlias[i].nameID].attribute.unit);
        unitLength = unitStr ? strlen(unitStr) : 0;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_PARAMETER)
      { /* parameter */
        unitStr = MMC_STRINGDATA(mData->realParameterData[mData->realAlias[i].nameID].attribute.unit);
        unitLength = unitStr ? strlen(unitStr) : 0;
      }
      else if (mData->realAlias[i].aliasType == ALIAS_TYPE_TIME)
      { /* time */
        unitStr = "s";
        unitLength = 1;
      }

      memcpy((uint8_t *)name + maxLengthName * cur, mData->realAlias[i].info.name, strlen(mData->realAlias[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->realAlias[i].info.comment, strlen(mData->realAlias[i].info.comment));
      // unit information
      if (unitLength > 0)
      {
        memcpy((uint8_t *)description + maxLengthDesc * cur + strlen(mData->realAlias[i].info.comment) + 2, unitStr, unitLength);
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realAlias[i].info.comment) + 0] = ' ';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realAlias[i].info.comment) + 1] = '[';
        ((uint8_t *)description)[maxLengthDesc * cur + strlen(mData->realAlias[i].info.comment) + 2 + unitLength] = ']';
      }
      cur++;
    }
  }

  for (int i = 0; i < mData->nAliasInteger; i++)
  {
    if (!mData->integerAlias[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->integerAlias[i].info.name, strlen(mData->integerAlias[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->integerAlias[i].info.comment, strlen(mData->integerAlias[i].info.comment));
      cur++;
    }
  }

  for (int i = 0; i < mData->nAliasBoolean; i++)
  {
    if (!mData->booleanAlias[i].filterOutput)
    {
      memcpy((uint8_t *)name + maxLengthName * cur, mData->booleanAlias[i].info.name, strlen(mData->booleanAlias[i].info.name));
      memcpy((uint8_t *)description + maxLengthDesc * cur, mData->booleanAlias[i].info.comment, strlen(mData->booleanAlias[i].info.comment));
      cur++;
    }
  }

  //       Name: name
  //       Rank: 2
  // Dimensions: maxLength x nVars
  // Class Type: Character Array
  //  Data Type: 8-bit, unsigned integer
  writeMatrix_matVer4(matData->pFile, "name", maxLengthName, matData->nSignals, name, MatVer4Type_CHAR);
  free(name);
  name = NULL;

  //       Name: description
  //       Rank: 2
  // Dimensions: maxLength x nVars
  // Class Type: Character Array
  //  Data Type: 8-bit, unsigned integer
  writeMatrix_matVer4(matData->pFile, "description", maxLengthDesc, matData->nSignals, description, MatVer4Type_CHAR);
  free(description);
  description = NULL;
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
void writeDataInfo(simulation_result *self, mat_data *matData, const MODEL_DATA *mData) {
  static_assert(sizeof(DataInfo) == 4 * sizeof(int32_t), "DataInfo must be 4x32-bit");

  DataInfo *dataInfo = (DataInfo *)malloc(sizeof(DataInfo) * matData->nSignals);
  size_t index_time_invariant = 1;  // Count time-invariant series, stored in data_1
  size_t index_time_variant = 0;    // Count time-variant series, stored in data_2
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
  dataInfo[0].extraplotation = EXTRAPOLATION_NOT_ALLOWED;

  if (self->cpuTime)
  {
    dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
    dataInfo[cur].index = ++index_time_variant;
    dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
    dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
    cur++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS])
  {
    dataInfo[cur].channel = CHANNEL_TIME_VARIANT;
    dataInfo[cur].index = ++index_time_variant;
    dataInfo[cur].interpolation = INTERPOLATION_LINEAR;
    dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
      dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
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
        dataInfo[cur].extraplotation = dataInfo[realLookup[mData->realAlias[i].nameID]].extraplotation;

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
        dataInfo[cur].extraplotation = dataInfo[realParameterLookup[mData->realAlias[i].nameID]].extraplotation;

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
        dataInfo[cur].extraplotation = EXTRAPOLATION_NOT_ALLOWED;

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
        dataInfo[cur].extraplotation = dataInfo[integerLookup[mData->integerAlias[i].nameID]].extraplotation;

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
        dataInfo[cur].extraplotation = dataInfo[integerParameterLookup[mData->integerAlias[i].nameID]].extraplotation;

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
          dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
          cur++;
        }
        else
        {
          dataInfo[cur].channel = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].channel;
          dataInfo[cur].index = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].index;
          dataInfo[cur].interpolation = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].interpolation;
          dataInfo[cur].extraplotation = dataInfo[boolLookup[mData->booleanAlias[i].nameID]].extraplotation;
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
          dataInfo[cur].extraplotation = EXTRAPOLATION_CONSTANT;
          cur++;
        }
        else
        {
          dataInfo[cur].channel = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].channel;
          dataInfo[cur].index = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].index;
          dataInfo[cur].interpolation = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].interpolation;
          dataInfo[cur].extraplotation = dataInfo[boolParameterLookup[mData->booleanAlias[i].nameID]].extraplotation;
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

#define WRITE_REAL_VALUE(data, offset, value)                                    \
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
