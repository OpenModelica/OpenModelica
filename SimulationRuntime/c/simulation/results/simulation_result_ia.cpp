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

/*
 * This file contains functions for sending the result of a simulation via TCP/IP.
 *
 * Message: [ID | SIZE | DATA]
 *   ID: 1 byte
 *   SIZE: 4 bytes
 *   DATA: SIZE bytes
 *
 * A message with ID=2 contains the number of Real, Integer, Boolean and String variables together with their names.
 * A message with ID=4 contains all the values (same order as for ID=2: Real, Integer, Boolean, String).
 * A message with ID=6 indicates that the simulation is completed.
 */

#include "util/omc_error.h"
#include "simulation_result_ia.h"
#include "util/rtclock.h"

#include <fstream>
#include <iostream>
#include <map>
#include <string>
#include <utility>
#include <cstring>
#include <cstdlib>
#include <stdint.h>
#include <assert.h>
#include "../simulation_runtime.h"
#include "meta/meta_modelica.h"

typedef struct IA_DATA
{
  unsigned int nReal;
  unsigned int nInteger;
  unsigned int nBoolean;
  unsigned int nString;
} IA_DATA;

void ia_init(simulation_result *self, DATA *data, threadData_t *threadData)
{
  TRACE_PUSH

  IA_DATA *iaData = new IA_DATA;
  self->storage = iaData;

  const MODEL_DATA *mData = &(data->modelData);
  int i;
  unsigned int strLength = 0;
  iaData->nReal = 0;
  iaData->nInteger = 0;
  iaData->nBoolean = 0;
  iaData->nString = 0;

  // count real vars
  { // time
    iaData->nReal++;
    strLength += 5;
  }
  for(i=0; i<mData->nVariablesReal; i++) if(!mData->realVarsData[i].filterOutput)
  {
    iaData->nReal++;
    strLength += strlen(mData->realVarsData[i].info.name) + 1;
  }
  for(i=0; i<mData->nAliasReal; i++) if(!mData->realAlias[i].filterOutput && data->modelData.realAlias[i].aliasType != 1)
  {
    iaData->nReal++;
    strLength += strlen(mData->realAlias[i].info.name) + 1;
  }

  // count integer vars
  for(i=0; i<mData->nVariablesInteger; i++) if(!mData->integerVarsData[i].filterOutput)
  {
    iaData->nInteger++;
    strLength += strlen(mData->integerVarsData[i].info.name) + 1;
  }
  for(i=0; i<mData->nAliasInteger; i++) if(!mData->integerAlias[i].filterOutput && data->modelData.integerAlias[i].aliasType != 1)
  {
    iaData->nInteger++;
    strLength += strlen(mData->integerAlias[i].info.name) + 1;
  }

  // count boolean vars
  for(i=0; i<mData->nVariablesBoolean; i++) if(!mData->booleanVarsData[i].filterOutput)
  {
    iaData->nBoolean++;
    strLength += strlen(mData->booleanVarsData[i].info.name) + 1;
  }
  for(i=0; i<mData->nAliasBoolean; i++) if(!mData->booleanAlias[i].filterOutput && data->modelData.booleanAlias[i].aliasType != 1)
  {
    iaData->nBoolean++;
    strLength += strlen(mData->booleanAlias[i].info.name) + 1;
  }

  // count string vars
  for(i=0; i<mData->nVariablesString; i++) if(!mData->stringVarsData[i].filterOutput)
  {
    iaData->nString++;
    strLength += strlen(mData->stringVarsData[i].info.name) + 1;
  }
  for(i=0; i<mData->nAliasString; i++) if(!mData->stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1)
  {
    iaData->nString++;
    strLength += strlen(mData->stringAlias[i].info.name) + 1;
  }

  unsigned int msgSIZE = 4*sizeof(unsigned int) + strLength;
  char* msgDATA = new char[msgSIZE];
  unsigned int offset = 0;

  memcpy(msgDATA+offset, &iaData->nReal, sizeof(unsigned int)); offset += sizeof(unsigned int);
  memcpy(msgDATA+offset, &iaData->nInteger, sizeof(unsigned int)); offset += sizeof(unsigned int);
  memcpy(msgDATA+offset, &iaData->nBoolean, sizeof(unsigned int)); offset += sizeof(unsigned int);
  memcpy(msgDATA+offset, &iaData->nString, sizeof(unsigned int)); offset += sizeof(unsigned int);

  // real vars
  { // time
    memcpy(msgDATA+offset, "time", 5); offset += 5;
  }
  for(i=0; i<mData->nVariablesReal; i++) if(!mData->realVarsData[i].filterOutput)
  {
    strLength = strlen(mData->realVarsData[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->realVarsData[i].info.name, strLength); offset += strLength;
  }
  for(i=0; i<mData->nAliasReal; i++) if(!mData->realAlias[i].filterOutput && data->modelData.realAlias[i].aliasType != 1)
  {
    strLength = strlen(mData->realAlias[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->realAlias[i].info.name, strLength); offset += strLength;
  }

  // integer vars
  for(i=0; i<mData->nVariablesInteger; i++) if(!mData->integerVarsData[i].filterOutput)
  {
    strLength = strlen(mData->integerVarsData[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->integerVarsData[i].info.name, strLength); offset += strLength;
  }
  for(i=0; i<mData->nAliasInteger; i++) if(!mData->integerAlias[i].filterOutput && data->modelData.integerAlias[i].aliasType != 1)
  {
    strLength = strlen(mData->integerAlias[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->integerAlias[i].info.name, strLength); offset += strLength;
  }

  // boolean vars
  for(i=0; i<mData->nVariablesBoolean; i++) if(!mData->booleanVarsData[i].filterOutput)
  {
    strLength = strlen(mData->booleanVarsData[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->booleanVarsData[i].info.name, strLength); offset += strLength;
  }
  for(i=0; i<mData->nAliasBoolean; i++) if(!mData->booleanAlias[i].filterOutput && data->modelData.booleanAlias[i].aliasType != 1)
  {
    strLength = strlen(mData->booleanAlias[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->booleanAlias[i].info.name, strLength); offset += strLength;
  }

  // string vars
  for(i=0; i<mData->nVariablesString; i++) if(!mData->stringVarsData[i].filterOutput)
  {
    strLength = strlen(mData->stringVarsData[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->stringVarsData[i].info.name, strLength); offset += strLength;
  }
  for(i=0; i<mData->nAliasString; i++) if(!mData->stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1)
  {
    strLength = strlen(mData->stringAlias[i].info.name) + 1;
    memcpy(msgDATA+offset, mData->stringAlias[i].info.name, strLength); offset += strLength;
  }

  communicateMsg(2, msgSIZE, msgDATA);
  delete[] msgDATA;

  TRACE_POP
}

void ia_emit(simulation_result *self, DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  rt_tick(SIM_TIMER_OUTPUT);

  int i;
  const IA_DATA *iaData = (IA_DATA*)self->storage;

  // count string length
  unsigned int strLength = 0;
  for(i=0; i<data->modelData.nVariablesString; i++) if(!data->modelData.stringVarsData[i].filterOutput) {
    strLength += MMC_STRLEN(data->localData[0]->stringVars[i]) + 1;
  }
  for(i=0; i<data->modelData.nAliasString; i++) if(!data->modelData.stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1) {
    strLength += MMC_STRLEN(data->localData[0]->stringVars[data->modelData.stringAlias[i].nameID]) + 1;
  }

  unsigned int msgSIZE = iaData->nReal*sizeof(modelica_real) + iaData->nInteger*sizeof(modelica_integer) + iaData->nBoolean*sizeof(modelica_boolean) + strLength;
  char* msgDATA = new char[msgSIZE];
  unsigned int offset = 0;

  // time
  memcpy(msgDATA+offset, &(data->localData[0]->timeValue), sizeof(modelica_real)); offset += sizeof(modelica_real);
  for(i=0; i<data->modelData.nVariablesReal; i++) if(!data->modelData.realVarsData[i].filterOutput)
  {
    memcpy(msgDATA+offset, &(data->localData[0]->realVars[i]), sizeof(modelica_real)); offset += sizeof(modelica_real);
  }

  modelica_real value = 0;
  for(i=0; i<data->modelData.nAliasReal; i++) if(!data->modelData.realAlias[i].filterOutput && data->modelData.realAlias[i].aliasType != 1)
  {
    if (data->modelData.realAlias[i].aliasType == 2)
      value = (data->localData[0])->timeValue;
    else
      value = (data->localData[0])->realVars[data->modelData.realAlias[i].nameID];

    if (data->modelData.realAlias[i].negate)
      value *= -1.0;

    memcpy(msgDATA+offset, &value, sizeof(modelica_real)); offset += sizeof(modelica_real);
  }


  for(i=0; i<data->modelData.nVariablesInteger; i++) if(!data->modelData.integerVarsData[i].filterOutput)
  {
    memcpy(msgDATA+offset, &(data->localData[0]->integerVars[i]), sizeof(modelica_integer)); offset += sizeof(modelica_integer);
  }

  modelica_integer intValue = 0;
  for(i=0; i<data->modelData.nAliasInteger; i++) if(!data->modelData.integerAlias[i].filterOutput && data->modelData.integerAlias[i].aliasType != 1)
  {
    if (data->modelData.integerAlias[i].negate)
      intValue = -(data->localData[0]->integerVars[data->modelData.integerAlias[i].nameID]);
    else
      intValue = data->localData[0]->integerVars[data->modelData.integerAlias[i].nameID];

    memcpy(msgDATA+offset, &intValue, sizeof(modelica_integer)); offset += sizeof(modelica_integer);
  }


  for(i=0; i<data->modelData.nVariablesBoolean; i++) if(!data->modelData.booleanVarsData[i].filterOutput)
  {
    memcpy(msgDATA+offset, &(data->localData[0]->booleanVars[i]), sizeof(modelica_boolean)); offset += sizeof(modelica_boolean);
  }

  modelica_boolean boolValue;
  for(i=0; i<data->modelData.nAliasBoolean; i++) if(!data->modelData.booleanAlias[i].filterOutput && data->modelData.booleanAlias[i].aliasType != 1)
  {
    if (data->modelData.booleanAlias[i].negate)
      boolValue = (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]==1?0:1;
    else
      boolValue = (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID];

    memcpy(msgDATA+offset, &boolValue, sizeof(modelica_boolean)); offset += sizeof(modelica_boolean);
  }


  for(i=0; i<data->modelData.nVariablesString; i++) if(!data->modelData.stringVarsData[i].filterOutput)
  {
    strLength = MMC_STRLEN((data->localData[0])->stringVars[i]) + 1;
    memcpy(msgDATA+offset, MMC_STRINGDATA((data->localData[0])->stringVars[i]), strLength); offset += strLength;
  }

  for(i=0; i<data->modelData.nAliasString; i++) if(!data->modelData.stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1)
  {
    strLength = MMC_STRLEN((data->localData[0])->stringVars[data->modelData.stringAlias[i].nameID]) + 1;
    memcpy(msgDATA+offset, MMC_STRINGDATA((data->localData[0])->stringVars[data->modelData.stringAlias[i].nameID]), strLength); offset += strLength;
  }

  communicateMsg(4, msgSIZE, msgDATA);
  delete[] msgDATA;

  rt_accumulate(SIM_TIMER_OUTPUT);
  TRACE_POP
}

void ia_free(simulation_result *self, DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  rt_tick(SIM_TIMER_OUTPUT);

  delete (IA_DATA*)self->storage;
  communicateMsg(6, 0, 0);

  rt_accumulate(SIM_TIMER_OUTPUT);
  TRACE_POP
}
