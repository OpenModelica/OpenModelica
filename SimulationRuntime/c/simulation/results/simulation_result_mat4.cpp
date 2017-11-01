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

extern "C" {

typedef struct mat_data {
  FILE *pFile;
  long data2HdrPos; /* position of data_2 matrix's header in a file */

  size_t nData1;
  size_t nData2;
  size_t nSignals;
  size_t nEmits;
  void* data_2;
  MatVer4Type_t type;
} mat_data;

static const char timeName[] = "time";
static const char timeDesc[] = "Simulation time [s]";
static const char cpuTimeName[] = "$cpuTime";
static const char cpuTimeDesc[] = "cpu time [s]";
static const char solverStepsName[] = "$solverSteps";
static const char solverStepsDesc[] = "number of steps taken by the integrator";

void mat4_init4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  const MODEL_DATA *mData = data->modelData;
  mat_data *matData = new mat_data();
  self->storage = matData;

  assert(sizeof(char) == 1);

  rt_tick(SIM_TIMER_OUTPUT);

  matData->type = omc_flag[FLAG_SINGLE_PRECISION] ? MatVer4Type_SINGLE : MatVer4Type_DOUBLE;

  matData->pFile = fopen(self->filename, "wb+");
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
  size_t maxLengthName = strlen(timeName) + 1;
  size_t maxLengthDesc = strlen(timeDesc) + 1;
  size_t len;
  matData->nSignals=1;

  if (self->cpuTime) {
    len = strlen(cpuTimeName) + 1;
    if (len > maxLengthName) maxLengthName = len;
    len = strlen(cpuTimeDesc) + 1;
    if (len > maxLengthDesc) maxLengthDesc = len;
    matData->nSignals++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS]) {
    len = strlen(solverStepsName) + 1;
    if (len > maxLengthName) maxLengthName = len;
    len = strlen(solverStepsDesc) + 1;
    if (len > maxLengthDesc) maxLengthDesc = len;
    matData->nSignals++;
  }

  for (int i=0; i < mData->nVariablesReal; i++)
    if (!mData->realVarsData[i].filterOutput) {
      const char *unitStr = MMC_STRINGDATA(mData->realVarsData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) + 3 : 0;

      len = strlen(mData->realVarsData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->realVarsData[i].info.comment) + 1 + unitLength;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  if (omc_flag[FLAG_IDAS])
    for (int i=mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++) {
      len = strlen(mData->realSensitivityData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->realSensitivityData[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nVariablesInteger; i++)
    if (!mData->integerVarsData[i].filterOutput) {
      len = strlen(mData->integerVarsData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->integerVarsData[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nVariablesBoolean; i++)
    if (!mData->booleanVarsData[i].filterOutput) {
      len = strlen(mData->booleanVarsData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->booleanVarsData[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nParametersReal; i++)
    if (!mData->realParameterData[i].filterOutput) {
      const char *unitStr = MMC_STRINGDATA(mData->realParameterData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) + 3 : 0;

      len = strlen(mData->realParameterData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->realParameterData[i].info.comment) + 1 + unitLength;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nParametersInteger; i++)
    if (!mData->integerParameterData[i].filterOutput) {
      len = strlen(mData->integerParameterData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->integerParameterData[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nParametersBoolean; i++)
    if (!mData->booleanParameterData[i].filterOutput) {
      len = strlen(mData->booleanParameterData[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->booleanParameterData[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nAliasReal; i++)
    if (!mData->realAlias[i].filterOutput) {
      len = strlen(mData->realAlias[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->realAlias[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nAliasInteger; i++)
    if (!mData->integerAlias[i].filterOutput) {
      len = strlen(mData->integerAlias[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->integerAlias[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  for (int i=0; i < mData->nAliasBoolean; i++)
    if (!mData->booleanAlias[i].filterOutput) {
      len = strlen(mData->booleanAlias[i].info.name) + 1;
      if (len > maxLengthName) maxLengthName = len;
      len = strlen(mData->booleanAlias[i].info.comment) + 1;
      if (len > maxLengthDesc) maxLengthDesc = len;
      matData->nSignals++;
    }

  /* Copy all the var names and descriptions to "name" and "description". */
  void* name = calloc(sizeof(char), maxLengthName * matData->nSignals);
  void* description = calloc(sizeof(char), maxLengthDesc * matData->nSignals);
  size_t cur=0;
  memcpy(name, timeName, strlen(timeName));
  memcpy(description, timeDesc, strlen(timeDesc));
  cur++;

  if (self->cpuTime) {
    memcpy((uint8_t*)name + maxLengthName * cur, cpuTimeName, strlen(cpuTimeName));
    memcpy((uint8_t*)description + maxLengthDesc * cur, cpuTimeDesc, strlen(cpuTimeDesc));
    cur++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS]) {
    memcpy((uint8_t*)name + maxLengthName * cur, solverStepsName, strlen(solverStepsName));
    memcpy((uint8_t*)description + maxLengthDesc * cur, solverStepsDesc, strlen(solverStepsDesc));
    cur++;
  }

  for (int i=0; i < mData->nVariablesReal; i++)
    if (!mData->realVarsData[i].filterOutput) {
      const char *unitStr = MMC_STRINGDATA(mData->realVarsData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) : 0;

      memcpy((uint8_t*)name + maxLengthName * cur, mData->realVarsData[i].info.name, strlen(mData->realVarsData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->realVarsData[i].info.comment, strlen(mData->realVarsData[i].info.comment));
      // unit information
      if (unitLength > 0)
      {
        memcpy((uint8_t*)description + maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 2, unitStr, unitLength);
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 0] = ' ';
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 1] = '[';
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realVarsData[i].info.comment) + 2 + unitLength] = ']';
      }
      cur++;
    }

  if (omc_flag[FLAG_IDAS])
    for (int i=mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->realSensitivityData[i].info.name, strlen(mData->realSensitivityData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->realSensitivityData[i].info.comment, strlen(mData->realSensitivityData[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nVariablesInteger; i++)
    if (!mData->integerVarsData[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->integerVarsData[i].info.name, strlen(mData->integerVarsData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->integerVarsData[i].info.comment, strlen(mData->integerVarsData[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nVariablesBoolean; i++)
    if (!mData->booleanVarsData[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->booleanVarsData[i].info.name, strlen(mData->booleanVarsData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->booleanVarsData[i].info.comment, strlen(mData->booleanVarsData[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nParametersReal; i++)
    if (!mData->realParameterData[i].filterOutput) {
      const char *unitStr = MMC_STRINGDATA(mData->realParameterData[i].attribute.unit);
      size_t unitLength = unitStr ? strlen(unitStr) : 0;

      memcpy((uint8_t*)name + maxLengthName * cur, mData->realParameterData[i].info.name, strlen(mData->realParameterData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->realParameterData[i].info.comment, strlen(mData->realParameterData[i].info.comment));
      // unit information
      if (unitLength > 0)
      {
        memcpy((uint8_t*)description + maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 2, unitStr, unitLength);
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 0] = ' ';
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 1] = '[';
        ((uint8_t*)description)[maxLengthDesc * cur + strlen(mData->realParameterData[i].info.comment) + 2 + unitLength] = ']';
      }
      cur++;
    }

  for (int i=0; i < mData->nParametersInteger; i++)
    if (!mData->integerParameterData[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->integerParameterData[i].info.name, strlen(mData->integerParameterData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->integerParameterData[i].info.comment, strlen(mData->integerParameterData[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nParametersBoolean; i++)
    if (!mData->booleanParameterData[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->booleanParameterData[i].info.name, strlen(mData->booleanParameterData[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->booleanParameterData[i].info.comment, strlen(mData->booleanParameterData[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nAliasReal; i++)
    if (!mData->realAlias[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->realAlias[i].info.name, strlen(mData->realAlias[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->realAlias[i].info.comment, strlen(mData->realAlias[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nAliasInteger; i++)
    if (!mData->integerAlias[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->integerAlias[i].info.name, strlen(mData->integerAlias[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->integerAlias[i].info.comment, strlen(mData->integerAlias[i].info.comment));
      cur++;
    }

  for (int i=0; i < mData->nAliasBoolean; i++)
    if (!mData->booleanAlias[i].filterOutput) {
      memcpy((uint8_t*)name + maxLengthName * cur, mData->booleanAlias[i].info.name, strlen(mData->booleanAlias[i].info.name));
      memcpy((uint8_t*)description + maxLengthDesc * cur, mData->booleanAlias[i].info.comment, strlen(mData->booleanAlias[i].info.comment));
      cur++;
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

#define WRITE_REAL_VALUE(data, offset, value) {if (omc_flag[FLAG_SINGLE_PRECISION]) {float f=(value); memcpy(((uint8_t*)(data)) + (offset)*sizeof(float), &f, sizeof(float));} else {double d=(value); memcpy(((uint8_t*)(data)) + (offset)*sizeof(double), &d, sizeof(double));}}

/* write the parameter data after updateBoundParameters is called */
void mat4_writeParameterData4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const MODEL_DATA      *mData = data->modelData;

  if (!matData->pFile)
    return;

  rt_tick(SIM_TIMER_OUTPUT);

  int32_t* dataInfo = (int32_t*) malloc(sizeof(int32_t) * 4 * matData->nSignals);
  size_t index1 = 1;
  size_t index2 = 0;
  size_t cur = 1;

  /* alias lookups */
  size_t *realLookup = (size_t*) malloc(sizeof(size_t) * mData->nVariablesReal);
  size_t *integerLookup = (size_t*) malloc(sizeof(size_t) * mData->nVariablesInteger);
  size_t *boolLookup = (size_t*) malloc(sizeof(size_t) * mData->nVariablesBoolean);

  size_t *realParameterLookup = (size_t*) malloc(sizeof(size_t) * mData->nParametersReal);
  size_t *integerParameterLookup = (size_t*) malloc(sizeof(size_t) * mData->nParametersInteger);
  size_t *boolParameterLookup = (size_t*) malloc(sizeof(size_t) * mData->nParametersBoolean);

  /* time */
  dataInfo[0] = 0;
  dataInfo[1] = ++index2;
  dataInfo[2] = 0;
  dataInfo[3] = -1;

  if (self->cpuTime) {
    dataInfo[4 * cur + 0] = 2;
    dataInfo[4 * cur + 1] = ++index2;
    dataInfo[4 * cur + 2] = 0;
    dataInfo[4 * cur + 3] = 0;
    cur++;
  }

  if (omc_flag[FLAG_SOLVER_STEPS]) {
    dataInfo[4 * cur + 0] = 2;
    dataInfo[4 * cur + 1] = ++index2;
    dataInfo[4 * cur + 2] = 0;
    dataInfo[4 * cur + 3] = 0;
    cur++;
  }

  for (int i=0; i < mData->nVariablesReal; i++)
    if (!mData->realVarsData[i].filterOutput) {
      realLookup[i] = cur;
      dataInfo[4 * cur + 0] = mData->realVarsData[i].time_unvarying ? 1 : 2;
      dataInfo[4 * cur + 1] = mData->realVarsData[i].time_unvarying ? ++index1 : ++index2;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  if (omc_flag[FLAG_IDAS])
    for (int i=mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++) {
      dataInfo[4 * cur + 0] = 2;
      dataInfo[4 * cur + 1] = ++index2;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nVariablesInteger; i++)
    if (!mData->integerVarsData[i].filterOutput) {
      integerLookup[i] = cur;
      dataInfo[4 * cur + 0] = mData->integerVarsData[i].time_unvarying ? 1 : 2;
      dataInfo[4 * cur + 1] = mData->integerVarsData[i].time_unvarying ? ++index1 : ++index2;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nVariablesBoolean; i++)
    if (!mData->booleanVarsData[i].filterOutput) {
      boolLookup[i] = cur;
      dataInfo[4 * cur + 0] = mData->booleanVarsData[i].time_unvarying ? 1 : 2;
      dataInfo[4 * cur + 1] = mData->booleanVarsData[i].time_unvarying ? ++index1 : ++index2;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nParametersReal; i++)
    if (!mData->realParameterData[i].filterOutput) {
      realParameterLookup[i] = cur;
      dataInfo[4 * cur + 0] = 1;
      dataInfo[4 * cur + 1] = ++index1;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nParametersInteger; i++)
    if (!mData->integerParameterData[i].filterOutput) {
      integerParameterLookup[i] = cur;
      dataInfo[4 * cur + 0] = 1;
      dataInfo[4 * cur + 1] = ++index1;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nParametersBoolean; i++)
    if (!mData->booleanParameterData[i].filterOutput) {
      boolParameterLookup[i] = cur;
      dataInfo[4 * cur + 0] = 1;
      dataInfo[4 * cur + 1] = ++index1;
      dataInfo[4 * cur + 2] = 0;
      dataInfo[4 * cur + 3] = 0;
      cur++;
    }

  for (int i=0; i < mData->nAliasReal; i++)
    if (!mData->realAlias[i].filterOutput) {
      if (mData->realAlias[i].aliasType == 0)
      { /* variable */
        dataInfo[4 * cur + 0] = dataInfo[4 * realLookup[mData->realAlias[i].nameID] + 0];
        dataInfo[4 * cur + 1] = dataInfo[4 * realLookup[mData->realAlias[i].nameID] + 1];
        dataInfo[4 * cur + 2] = dataInfo[4 * realLookup[mData->realAlias[i].nameID] + 2];
        dataInfo[4 * cur + 3] = dataInfo[4 * realLookup[mData->realAlias[i].nameID] + 3];

        if (mData->realAlias[i].negate)
          dataInfo[4 * cur + 1] = -dataInfo[4 * cur + 1];
        cur++;
      }
      else if (mData->realAlias[i].aliasType == 1)
      { /* parameter */
        dataInfo[4 * cur + 0] = dataInfo[4 * realParameterLookup[mData->realAlias[i].nameID] + 0];
        dataInfo[4 * cur + 1] = dataInfo[4 * realParameterLookup[mData->realAlias[i].nameID] + 1];
        dataInfo[4 * cur + 2] = dataInfo[4 * realParameterLookup[mData->realAlias[i].nameID] + 2];
        dataInfo[4 * cur + 3] = dataInfo[4 * realParameterLookup[mData->realAlias[i].nameID] + 3];

        if (mData->realAlias[i].negate)
          dataInfo[4 * cur + 1] = -dataInfo[4 * cur + 1];
        cur++;
      }
      else if (mData->realAlias[i].aliasType == 2)
      { /* time */
        dataInfo[4 * cur + 0] = 2;
        dataInfo[4 * cur + 1] = 1;
        dataInfo[4 * cur + 2] = 0;
        dataInfo[4 * cur + 3] = -1;

        if (mData->realAlias[i].negate)
          dataInfo[4 * cur + 1] = -dataInfo[4 * cur + 1];
        cur++;
      }
    }

  for (int i=0; i < mData->nAliasInteger; i++)
    if (!mData->integerAlias[i].filterOutput) {
      if (mData->integerAlias[i].aliasType == 0)
      { /* variable */
        dataInfo[4 * cur + 0] = dataInfo[4 * integerLookup[mData->integerAlias[i].nameID] + 0];
        dataInfo[4 * cur + 1] = dataInfo[4 * integerLookup[mData->integerAlias[i].nameID] + 1];
        dataInfo[4 * cur + 2] = dataInfo[4 * integerLookup[mData->integerAlias[i].nameID] + 2];
        dataInfo[4 * cur + 3] = dataInfo[4 * integerLookup[mData->integerAlias[i].nameID] + 3];

        if (mData->integerAlias[i].negate)
          dataInfo[4 * cur + 1] = -dataInfo[4 * cur + 1];
        cur++;
      }
      else if (mData->integerAlias[i].aliasType == 1)
      { /* parameter */
        dataInfo[4 * cur + 0] = dataInfo[4 * integerParameterLookup[mData->integerAlias[i].nameID] + 0];
        dataInfo[4 * cur + 1] = dataInfo[4 * integerParameterLookup[mData->integerAlias[i].nameID] + 1];
        dataInfo[4 * cur + 2] = dataInfo[4 * integerParameterLookup[mData->integerAlias[i].nameID] + 2];
        dataInfo[4 * cur + 3] = dataInfo[4 * integerParameterLookup[mData->integerAlias[i].nameID] + 3];

        if (mData->integerAlias[i].negate)
          dataInfo[4 * cur + 1] = -dataInfo[4 * cur + 1];
        cur++;
      }
    }

  for (int i=0; i < mData->nAliasBoolean; i++)
    if (!mData->booleanAlias[i].filterOutput) {
      if (mData->booleanAlias[i].aliasType == 0)
      { /* variable */
        if (mData->booleanAlias[i].negate)
        {
          dataInfo[4 * cur + 0] = 2;
          dataInfo[4 * cur + 1] = ++index2;
          dataInfo[4 * cur + 2] = 0;
          dataInfo[4 * cur + 3] = 0;
          cur++;
        }
        else
        {
          dataInfo[4 * cur + 0] = dataInfo[4 * boolLookup[mData->booleanAlias[i].nameID] + 0];
          dataInfo[4 * cur + 1] = dataInfo[4 * boolLookup[mData->booleanAlias[i].nameID] + 1];
          dataInfo[4 * cur + 2] = dataInfo[4 * boolLookup[mData->booleanAlias[i].nameID] + 2];
          dataInfo[4 * cur + 3] = dataInfo[4 * boolLookup[mData->booleanAlias[i].nameID] + 3];
          cur++;
        }
      }
      else if (mData->booleanAlias[i].aliasType == 1)
      { /* parameter */
        if (mData->booleanAlias[i].negate)
        {
          dataInfo[4 * cur + 0] = 1;
          dataInfo[4 * cur + 1] = ++index1;
          dataInfo[4 * cur + 2] = 0;
          dataInfo[4 * cur + 3] = 0;
          cur++;
        }
        else
        {
          dataInfo[4 * cur + 0] = dataInfo[4 * boolParameterLookup[mData->booleanAlias[i].nameID] + 0];
          dataInfo[4 * cur + 1] = dataInfo[4 * boolParameterLookup[mData->booleanAlias[i].nameID] + 1];
          dataInfo[4 * cur + 2] = dataInfo[4 * boolParameterLookup[mData->booleanAlias[i].nameID] + 2];
          dataInfo[4 * cur + 3] = dataInfo[4 * boolParameterLookup[mData->booleanAlias[i].nameID] + 3];
          cur++;
        }
      }
    }

  free(realLookup);
  free(integerLookup);
  free(boolLookup);

  free(realParameterLookup);
  free(integerParameterLookup);
  free(boolParameterLookup);

  matData->nData1 = index1;
  matData->nData2 = index2;
  matData->nEmits = 0;

  //       Name: dataInfo
  //       Rank: 2
  // Dimensions: 4 x nVars
  // Class Type: 32-bit, signed integer array
  //  Data Type: 32-bit, signed integer
  writeMatrix_matVer4(matData->pFile, "dataInfo", 4, matData->nSignals, dataInfo, MatVer4Type_INT32);
  free(dataInfo);
  dataInfo = NULL;

  size_t size = sizeofMatVer4Type(matData->type);
  cur = 0;
  void* data_1 = malloc(size * matData->nData1 * 2);

  WRITE_REAL_VALUE(data_1, cur, data->simulationInfo->startTime);
  WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->simulationInfo->stopTime);
  cur++;

  for (int i=0; i < mData->nVariablesReal; i++)
    if (!mData->realVarsData[i].filterOutput && mData->realVarsData[i].time_unvarying) {
        WRITE_REAL_VALUE(data_1, cur, data->localData[0]->realVars[i]);
        WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->realVars[i]);
        cur++;
      }

  for (int i=0; i < mData->nVariablesInteger; i++)
    if (!mData->integerVarsData[i].filterOutput && mData->integerVarsData[i].time_unvarying) {
      WRITE_REAL_VALUE(data_1, cur, data->localData[0]->integerVars[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->integerVars[i]);
      cur++;
    }

  for (int i=0; i < mData->nVariablesBoolean; i++)
    if (!mData->booleanVarsData[i].filterOutput && mData->booleanVarsData[i].time_unvarying) {
      WRITE_REAL_VALUE(data_1, cur, data->localData[0]->booleanVars[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, data->localData[0]->booleanVars[i]);
      cur++;
    }

  for (int i=0; i < mData->nParametersReal; i++)
    if (!mData->realParameterData[i].filterOutput) {
      WRITE_REAL_VALUE(data_1, cur, sInfo->realParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->realParameter[i]);
      cur++;
    }

  for (int i=0; i < mData->nParametersInteger; i++)
    if (!mData->integerParameterData[i].filterOutput) {
      WRITE_REAL_VALUE(data_1, cur, sInfo->integerParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->integerParameter[i]);
      cur++;
    }

  for (int i=0; i < mData->nParametersBoolean; i++)
    if (!mData->booleanParameterData[i].filterOutput) {
      WRITE_REAL_VALUE(data_1, cur, sInfo->booleanParameter[i]);
      WRITE_REAL_VALUE(data_1, cur + matData->nData1, sInfo->booleanParameter[i]);
      cur++;
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

void mat4_emit4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;
  const SIMULATION_INFO *sInfo = data->simulationInfo;
  const MODEL_DATA      *mData = data->modelData;

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
    WRITE_REAL_VALUE(matData->data_2, cur++, cpuTimeValue);

  if (omc_flag[FLAG_SOLVER_STEPS])
    WRITE_REAL_VALUE(matData->data_2, cur++, data->simulationInfo->solverSteps);

  for (int i=0; i < mData->nVariablesReal; i++)
    if (!mData->realVarsData[i].filterOutput && !mData->realVarsData[i].time_unvarying)
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->realVars[i]);

  if (omc_flag[FLAG_IDAS])
    for (int i=mData->nSensitivityParamVars; i < mData->nSensitivityVars; i++)
      WRITE_REAL_VALUE(matData->data_2, cur++, data->simulationInfo->sensitivityMatrix[i]);

  for (int i=0; i < mData->nVariablesInteger; i++)
    if (!mData->integerVarsData[i].filterOutput && !mData->integerVarsData[i].time_unvarying)
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->integerVars[i]);

  for (int i=0; i < mData->nVariablesBoolean; i++)
    if (!mData->booleanVarsData[i].filterOutput && !mData->booleanVarsData[i].time_unvarying)
      WRITE_REAL_VALUE(matData->data_2, cur++, data->localData[0]->booleanVars[i]);

  for (int i=0; i < mData->nAliasBoolean; i++)
    if (!mData->booleanAlias[i].filterOutput)
      if (mData->booleanAlias[i].aliasType == 0)
        if (mData->booleanAlias[i].negate)
          WRITE_REAL_VALUE(matData->data_2, cur++, (1-data->localData[0]->booleanVars[mData->booleanAlias[i].nameID]));

  //appendMatVer4Matrix_4(matData->pFile, matData->data2HdrPos, "data_2", matData->nData2, 1, matData->data_2, matData->type);
  fwrite(matData->data_2, sizeofMatVer4Type(matData->type), matData->nData2, matData->pFile);
  matData->nEmits++;

  rt_accumulate(SIM_TIMER_OUTPUT);
}

void mat4_free4(simulation_result *self, DATA *data, threadData_t *threadData)
{
  mat_data *matData = (mat_data*) self->storage;

  rt_tick(SIM_TIMER_OUTPUT);

  if (!matData->pFile) {
    rt_accumulate(SIM_TIMER_OUTPUT);
    return;
  }

  updateHeader_matVer4(matData->pFile, matData->data2HdrPos, "data_2", matData->nData2, matData->nEmits, matData->type);

  if (matData->data_2) {
    free(matData->data_2);
    matData->data_2 = NULL;
  }

  fclose(matData->pFile);
  matData->pFile = NULL;

  rt_accumulate(SIM_TIMER_OUTPUT);
}

}
