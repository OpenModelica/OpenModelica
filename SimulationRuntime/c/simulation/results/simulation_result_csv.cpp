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
 * This file contains functions for storing the result of a simulation to a file.
 *
 * The solver should call three functions in this file.
 * 1. Call initializeResult before starting simulation, telling maximum number of data points.
 * 2. Call emit() to store data points at given time (taken from globalData structure)
 * 3. Call deinitializeResult with actual number of points produced to store data to file.
 *
 */

#include "util/omc_error.h"
#include "simulation_result_csv.h"
#include "util/rtclock.h"

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>

extern "C" {

void omc_csv_emit(simulation_result *self, DATA *data, threadData_t *threadData)
{
  FILE *fout = (FILE*) self->storage;
  const char* format = "%.16g,";
  const char* formatint = "%i,";
  const char* formatbool = "%i,";
  const char* formatstring = "\"%s\",";
  int i;
  modelica_real value = 0;
  double cpuTimeValue = 0;
  rt_tick(SIM_TIMER_OUTPUT);

  rt_accumulate(SIM_TIMER_TOTAL);
  cpuTimeValue = rt_accumulated(SIM_TIMER_TOTAL);
  rt_tick(SIM_TIMER_TOTAL);

  fprintf(fout, format, data->localData[0]->timeValue);
  if(self->cpuTime)
    fprintf(fout, format, cpuTimeValue);
  for(i = 0; i < data->modelData.nVariablesReal; i++) if(!data->modelData.realVarsData[i].filterOutput)
    fprintf(fout, format, (data->localData[0])->realVars[i]);
  for(i = 0; i < data->modelData.nVariablesInteger; i++) if(!data->modelData.integerVarsData[i].filterOutput)
    fprintf(fout, formatint, (data->localData[0])->integerVars[i]);
  for(i = 0; i < data->modelData.nVariablesBoolean; i++) if(!data->modelData.booleanVarsData[i].filterOutput)
    fprintf(fout, formatbool, (data->localData[0])->booleanVars[i]);
  for(i = 0; i < data->modelData.nVariablesString; i++) if(!data->modelData.stringVarsData[i].filterOutput)
    fprintf(fout, formatstring, (data->localData[0])->stringVars[i]);

  for(i = 0; i < data->modelData.nAliasReal; i++) if(!data->modelData.realAlias[i].filterOutput && data->modelData.realAlias[i].aliasType != 1) {
    if (data->modelData.realAlias[i].aliasType == 2) {
      value = (data->localData[0])->timeValue;
    } else {
      value = (data->localData[0])->realVars[data->modelData.realAlias[i].nameID];
    }
    if (data->modelData.realAlias[i].negate) {
      fprintf(fout, format, -value);
    } else {
      fprintf(fout, format, value);
    }
  }
  for(i = 0; i < data->modelData.nAliasInteger; i++) if(!data->modelData.integerAlias[i].filterOutput && data->modelData.integerAlias[i].aliasType != 1) {
    if (data->modelData.integerAlias[i].negate) {
      fprintf(fout, formatint, -(data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
    } else {
      fprintf(fout, formatint, (data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
    }
  }
  for(i = 0; i < data->modelData.nAliasBoolean; i++) if(!data->modelData.booleanAlias[i].filterOutput && data->modelData.booleanAlias[i].aliasType != 1) {
    if (data->modelData.booleanAlias[i].negate) {
      fprintf(fout, formatbool, (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]==1?0:1);
    } else {
      fprintf(fout, formatbool, (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]);
    }
  }
  for(i = 0; i < data->modelData.nAliasString; i++) if(!data->modelData.stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1) {
    /* there would no negation of a string happen */
    fprintf(fout, formatstring, (data->localData[0])->stringVars[data->modelData.stringAlias[i].nameID]);
  }
  fseek(fout, -1, SEEK_CUR); // removes the eol comma separator
  fprintf(fout, "\n");
  rt_accumulate(SIM_TIMER_OUTPUT);
}

void omc_csv_init(simulation_result *self, DATA *data, threadData_t *threadData)
{
  int i;
  const MODEL_DATA *mData = &(data->modelData);

  const char* format = "\"%s\",";
  FILE *fout = fopen(self->filename, "w");

  assertStreamPrint(threadData, 0!=fout, "Error, couldn't create output file: [%s] because of %s", self->filename, strerror(errno));

  fprintf(fout, format, "time");
  if(self->cpuTime)
    fprintf(fout, format, "$cpuTime");
  for(i = 0; i < mData->nVariablesReal; i++) if(!mData->realVarsData[i].filterOutput)
    fprintf(fout, format, mData->realVarsData[i].info.name);
  for(i = 0; i < mData->nVariablesInteger; i++) if(!mData->integerVarsData[i].filterOutput)
    fprintf(fout, format, mData->integerVarsData[i].info.name);
  for(i = 0; i < mData->nVariablesBoolean; i++) if(!mData->booleanVarsData[i].filterOutput)
    fprintf(fout, format, mData->booleanVarsData[i].info.name);
  for(i = 0; i < mData->nVariablesString; i++) if(!mData->stringVarsData[i].filterOutput)
    fprintf(fout, format, mData->stringVarsData[i].info.name);

  for(i = 0; i < mData->nAliasReal; i++) if(!mData->realAlias[i].filterOutput && data->modelData.realAlias[i].aliasType != 1)
    fprintf(fout, format, mData->realAlias[i].info.name);
  for(i = 0; i < mData->nAliasInteger; i++) if(!mData->integerAlias[i].filterOutput && data->modelData.integerAlias[i].aliasType != 1)
    fprintf(fout, format, mData->integerAlias[i].info.name);
  for(i = 0; i < mData->nAliasBoolean; i++) if(!mData->booleanAlias[i].filterOutput && data->modelData.booleanAlias[i].aliasType != 1)
    fprintf(fout, format, mData->booleanAlias[i].info.name);
  for(i = 0; i < mData->nAliasString; i++) if(!mData->stringAlias[i].filterOutput && data->modelData.stringAlias[i].aliasType != 1)
    fprintf(fout, format, mData->stringAlias[i].info.name);
  fseek(fout, -1, SEEK_CUR); // removes the eol comma separator
  fprintf(fout,"\n");
  self->storage = fout;
}

void omc_csv_free(simulation_result *self, DATA *data, threadData_t *threadData)
{
  FILE *fout = (FILE*) self->storage;
  rt_tick(SIM_TIMER_OUTPUT);
  fclose(fout);
  rt_accumulate(SIM_TIMER_OUTPUT);
}

}
