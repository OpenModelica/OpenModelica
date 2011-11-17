/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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

#include "error.h"

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <limits> /* adrpo - for std::numeric_limits in MSVC */
#include "simulation_result_csv.h"
#include "simulation_runtime.h"
#include <sstream>
#include <time.h>
#include "rtclock.h"

void simulation_result_csv::emit(_X_DATA *data)
{
  const char* format = "%.16g,";
  const char* formatint = "%i,";
  const char* formatbool = "%i,";
  const char* formatstring = "\"%s\",";
  rt_tick(SIM_TIMER_OUTPUT);
  fprintf(fout, format, data->localData[0]->time);

  for (int i = 0; i < data->modelData.nVariablesReal; i++) if (!data->modelData.realData[i].filterOutput)
    fprintf(fout, format, (data->localData[0])->realVars[i]);
  for (int i = 0; i < data->modelData.nVariablesInteger; i++) if (!data->modelData.integerData[i].filterOutput)
    fprintf(fout, formatint, (data->localData[0])->integerVars[i]);
  for (int i = 0; i < data->modelData.nVariablesBoolean; i++) if (!data->modelData.booleanData[i].filterOutput)
    fprintf(fout, formatbool, (data->localData[0])->booleanVars[i]);
  for (int i = 0; i < data->modelData.nVariablesString; i++) if (!data->modelData.stringData[i].filterOutput)
    fprintf(fout, formatstring, (data->localData[0])->stringVars[i]);

  for (int i = 0; i < data->modelData.nAliasReal; i++) if (!data->modelData.realAlias[i].filterOutput)
    if (data->modelData.realAlias[i].negate)
      fprintf(fout, format, -(data->localData[0])->realVars[data->modelData.realAlias[i].nameID]);
    else
      fprintf(fout, format, (data->localData[0])->realVars[data->modelData.realAlias[i].nameID]);
  for (int i = 0; i < data->modelData.nAliasInteger; i++) if (!data->modelData.integerAlias[i].filterOutput)
    if (data->modelData.integerAlias[i].negate)
      fprintf(fout, formatint, -(data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
    else
      fprintf(fout, formatint, (data->localData[0])->integerVars[data->modelData.integerAlias[i].nameID]);
  for (int i = 0; i < data->modelData.nAliasBoolean; i++) if (!data->modelData.booleanAlias[i].filterOutput)
    if (data->modelData.booleanAlias[i].negate)
      fprintf(fout, formatbool, -(data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]);
    else
      fprintf(fout, formatbool, (data->localData[0])->booleanVars[data->modelData.booleanAlias[i].nameID]);
  for (int i = 0; i < data->modelData.nAliasString; i++) if (!data->modelData.stringAlias[i].filterOutput)
    /* there would no negation of a string happen */
    fprintf(fout, formatstring, (data->localData[0])->stringVars[data->modelData.stringAlias[i].nameID]);
  fprintf(fout, "\n");
  rt_accumulate(SIM_TIMER_OUTPUT);
}

simulation_result_csv::simulation_result_csv(const char* filename, long numpoints, MODEL_DATA *modelData) : simulation_result(filename,numpoints)
{
  const char* format = "\"%s\",";
  fout = fopen(filename, "w");
  if (!fout)
  {
    THROW2("Error, couldn't create output file: [%s] because of %s", filename, strerror(errno));
  }

  fprintf(fout, format, "time");
  for (int i = 0; i < modelData->nVariablesReal; i++) if (!modelData->realData[i].filterOutput)
    fprintf(fout, format, modelData->realData[i].info.name);
  for (int i = 0; i < modelData->nVariablesInteger; i++) if (!modelData->integerData[i].filterOutput)
    fprintf(fout, format, modelData->integerData[i].info.name);
  for (int i = 0; i < modelData->nVariablesBoolean; i++) if (!modelData->booleanData[i].filterOutput)
    fprintf(fout, format, modelData->booleanData[i].info.name);
  for (int i = 0; i < modelData->nVariablesString; i++) if (!modelData->stringData[i].filterOutput)
    fprintf(fout, format, modelData->stringData[i].info.name);

  for (int i = 0; i < modelData->nAliasReal; i++) if (!modelData->realAlias[i].filterOutput)
    fprintf(fout, format, modelData->realAlias[i].info.name);
  for (int i = 0; i < modelData->nAliasInteger; i++) if (!modelData->integerAlias[i].filterOutput)
    fprintf(fout, format, modelData->integerAlias[i].info.name);
  for (int i = 0; i < modelData->nAliasBoolean; i++) if (!modelData->booleanAlias[i].filterOutput)
    fprintf(fout, format, modelData->booleanAlias[i].info.name);
  for (int i = 0; i < modelData->nAliasString; i++) if (!modelData->stringAlias[i].filterOutput)
    fprintf(fout, format, modelData->stringAlias[i].info.name);
  fprintf(fout,"\n");
}

simulation_result_csv::~simulation_result_csv()
{
  rt_tick(SIM_TIMER_OUTPUT);
  fclose(fout);
  rt_accumulate(SIM_TIMER_OUTPUT);
}
