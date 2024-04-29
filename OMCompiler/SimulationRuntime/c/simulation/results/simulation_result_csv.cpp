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
#include "util/omc_file.h"
#include "simulation_result_csv.h"
#include "util/rtclock.h"

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>

#define MAX_IDENT_LENGTH 4096

extern "C" {

/**
 * @brief Count the occurrences of a substring in a string
 *
 * @param str     String to search.
 * @param substr  Substring to count in `str`.
 * @return int    Number of occurrences.
 */
int countSubstring(const char* str, const char* substr) {
    int count = 0;
    size_t substr_len = strlen(substr);
    const char* ptr = str;
    while ((ptr = strstr(ptr, substr)) != NULL) {
        count++;
        ptr += substr_len;
    }
    return count;
}

/**
 * @brief Escape CSV style.
 *
 * Escape double-quotes with another double-quote to handle quoted identifiers
 * with double-quotes in original. Example: `'a"b'` --> `a""b`
 *
 * @param original      Variable to escape characters into CSV style.
 * @param replaced      Buffer to store escaped version of `original`.
 * @param n             Size of buffer `replaced`.
 */
void csvEscapedString(const char* original, char* replaced, size_t n, threadData_t* threadData)
{
  size_t original_length = strlen(original);

  // Count the occurrences of \"
  int num_occurrences = countSubstring(original, "\\\"");
  size_t replaced_length = original_length + num_occurrences;

  if (replaced == NULL || n < replaced_length + 1) {
    throwStreamPrint(threadData, "Buffer too small. Failed to escape identifier for CSV result file.");
    return;
  }

  size_t j = 0;
  for (size_t i = 0; i < original_length; i++) {
      if (original[i] == '"') {
          replaced[j++] = '"';
          replaced[j++] = '"';
      } else {
          replaced[j++] = original[i];
      }
  }

  // Null-terminate the replaced string
  replaced[j] = '\0';
  return;
}

/**
 * @brief Write CSV data row.
 *
 * @param self        Simulation result.
 * @param data        Simulation data.
 * @param threadData  Thread data for error handling.
 */
void omc_csv_emit(simulation_result *self, DATA *data, threadData_t *threadData)
{
  FILE *fout = (FILE*) self->storage;
  const char* format = ",%.16g";
  const char* formatint = ",%i";
  const char* formatbool = ",%i";
  const char* formatstring = ",\"%s\"";
  int i;
  modelica_real value = 0;
  double cpuTimeValue = 0;
  rt_tick(SIM_TIMER_OUTPUT);

  rt_accumulate(SIM_TIMER_TOTAL);
  cpuTimeValue = rt_accumulated(SIM_TIMER_TOTAL);
  rt_tick(SIM_TIMER_TOTAL);

  fprintf(fout, "%.16g", data->localData[0]->timeValue);
  if(self->cpuTime)
    fprintf(fout, format, cpuTimeValue);
  for(i = 0; i < data->modelData->nVariablesReal; i++) if(!data->modelData->realVarsData[i].filterOutput)
    fprintf(fout, format, (data->localData[0])->realVars[i]);
  for(i = 0; i < data->modelData->nVariablesInteger; i++) if(!data->modelData->integerVarsData[i].filterOutput)
    fprintf(fout, formatint, (data->localData[0])->integerVars[i]);
  for(i = 0; i < data->modelData->nVariablesBoolean; i++) if(!data->modelData->booleanVarsData[i].filterOutput)
    fprintf(fout, formatbool, (data->localData[0])->booleanVars[i]);
  //for(i = 0; i < data->modelData->nVariablesString; i++) if(!data->modelData->stringVarsData[i].filterOutput)
  //  fprintf(fout, formatstring, MMC_STRINGDATA((data->localData[0])->stringVars[i]));

  for(i = 0; i < data->modelData->nAliasReal; i++) if(!data->modelData->realAlias[i].filterOutput && data->modelData->realAlias[i].aliasType != 1) {
    if (data->modelData->realAlias[i].aliasType == 2) {
      value = (data->localData[0])->timeValue;
    } else {
      value = (data->localData[0])->realVars[data->modelData->realAlias[i].nameID];
    }
    if (data->modelData->realAlias[i].negate) {
      fprintf(fout, format, -value);
    } else {
      fprintf(fout, format, value);
    }
  }
  for(i = 0; i < data->modelData->nAliasInteger; i++) if(!data->modelData->integerAlias[i].filterOutput && data->modelData->integerAlias[i].aliasType != 1) {
    if (data->modelData->integerAlias[i].negate) {
      fprintf(fout, formatint, -(data->localData[0])->integerVars[data->modelData->integerAlias[i].nameID]);
    } else {
      fprintf(fout, formatint, (data->localData[0])->integerVars[data->modelData->integerAlias[i].nameID]);
    }
  }
  for(i = 0; i < data->modelData->nAliasBoolean; i++) if(!data->modelData->booleanAlias[i].filterOutput && data->modelData->booleanAlias[i].aliasType != 1) {
    if (data->modelData->booleanAlias[i].negate) {
      fprintf(fout, formatbool, (data->localData[0])->booleanVars[data->modelData->booleanAlias[i].nameID]==1?0:1);
    } else {
      fprintf(fout, formatbool, (data->localData[0])->booleanVars[data->modelData->booleanAlias[i].nameID]);
    }
  }
  //for(i = 0; i < data->modelData->nAliasString; i++) if(!data->modelData->stringAlias[i].filterOutput && data->modelData->stringAlias[i].aliasType != 1) {
  //  /* there would no negation of a string happen */
  //  fprintf(fout, formatstring, MMC_STRINGDATA((data->localData[0])->stringVars[data->modelData->stringAlias[i].nameID]));
  //}
  fprintf(fout, "\n");
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * @brief Write CSV header.
 *
 * @param self        Simulation result.
 * @param data        Simulation data.
 * @param threadData  Thread data for error handling.
 */
void omc_csv_init(simulation_result *self, DATA *data, threadData_t *threadData)
{
  int i;
  const MODEL_DATA *mData = data->modelData;

  const char* format = ",\"%s\"";
  FILE *fout = omc_fopen(self->filename, "w");
  char escapedNameBuffer[MAX_IDENT_LENGTH];

  assertStreamPrint(threadData, 0!=fout, "Error, couldn't create output file: [%s] because of %s", self->filename, strerror(errno));

  fprintf(fout, "\"time\"");
  if(self->cpuTime) {
    fprintf(fout, format, "$cpuTime");
  }
  for(i = 0; i < mData->nVariablesReal; i++) if(!mData->realVarsData[i].filterOutput) {
    csvEscapedString(mData->realVarsData[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
    fprintf(fout, format, escapedNameBuffer);
  }
  for(i = 0; i < mData->nVariablesInteger; i++) {
    if(!mData->integerVarsData[i].filterOutput) {
      csvEscapedString(mData->integerVarsData[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
      fprintf(fout, format, escapedNameBuffer);
    }
  }
  for(i = 0; i < mData->nVariablesBoolean; i++) {
    if(!mData->booleanVarsData[i].filterOutput) {
      csvEscapedString(mData->booleanVarsData[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
      fprintf(fout, format, escapedNameBuffer);
    }
  }

  for(i = 0; i < mData->nAliasReal; i++) {
    if(!mData->realAlias[i].filterOutput && data->modelData->realAlias[i].aliasType != 1) {
      csvEscapedString(mData->realAlias[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
      fprintf(fout, format, escapedNameBuffer);
    }
  }
  for(i = 0; i < mData->nAliasInteger; i++) {
    if(!mData->integerAlias[i].filterOutput && data->modelData->integerAlias[i].aliasType != 1) {
      csvEscapedString(mData->integerAlias[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
      fprintf(fout, format, escapedNameBuffer);
    }
  }
  for(i = 0; i < mData->nAliasBoolean; i++) {
    if(!mData->booleanAlias[i].filterOutput && data->modelData->booleanAlias[i].aliasType != 1) {
      csvEscapedString(mData->booleanAlias[i].info.name, escapedNameBuffer, MAX_IDENT_LENGTH, threadData);
      fprintf(fout, format, escapedNameBuffer);
    }
  }
  fprintf(fout, "\n");
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
