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
#include "simulation_result_plt.h"
#include "util/rtclock.h"

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <time.h>

extern "C" {

typedef struct plt_data {
  double* simulationResultData;
  long currentPos;
  long actualPoints; /* the number of actual points saved */
  long maxPoints;
  long dataSize;
  int num_vars;
} plt_data;

static void add_result(simulation_result *self,DATA *data,double *data_, long *actualPoints);
static void deallocResult(plt_data *pltData);
static void printPltLine(FILE* f, double time, double val);

static int calcDataSize(simulation_result *self,const MODEL_DATA *modelData)
{
  int sz = 1, i; /* time */
  if(self->cpuTime)
    sz++; /* $cpuTime */
  for(i = 0; i < modelData->nVariablesReal; i++) if(!modelData->realVarsData[i].filterOutput) sz++;
  for(i = 0; i < modelData->nVariablesInteger; i++) if(!modelData->integerVarsData[i].filterOutput) sz++;
  for(i = 0; i < modelData->nVariablesBoolean; i++) if(!modelData->booleanVarsData[i].filterOutput) sz++;
  /* for(int i = 0; i < modelData->nVariablesString; i++) if(!modelData->stringVarsData[i].filterOutput) sz++; */

  for(i = 0; i < modelData->nAliasReal; i++) if(!modelData->realAlias[i].filterOutput) sz++;
  for(i = 0; i < modelData->nAliasInteger; i++) if(!modelData->integerAlias[i].filterOutput) sz++;
  for(i = 0; i < modelData->nAliasBoolean; i++) if(!modelData->booleanAlias[i].filterOutput) sz++;
  /* for(int i = 0; i < modelData->nAliasString; i++) if(!modelData->stringAlias[i].filterOutput) sz++; */

  return sz;
}

void plt_emit(simulation_result *self,DATA *data, threadData_t *threadData)
{
  plt_data *pltData = (plt_data*) self->storage;
  rt_tick(SIM_TIMER_OUTPUT);
  if(pltData->actualPoints < pltData->maxPoints) {
      add_result(self,data,pltData->simulationResultData,&pltData->actualPoints); /*used for non-interactive simulation */
  } else {
    pltData->maxPoints = (long)(1.4*pltData->maxPoints + (pltData->maxPoints-pltData->actualPoints) + 2000);
    /* cerr << "realloc simulationResultData to a size of " << maxPoints * dataSize * sizeof(double) << endl; */
    pltData->simulationResultData = (double*)realloc(pltData->simulationResultData, pltData->maxPoints * pltData->dataSize * sizeof(double));
    if(!pltData->simulationResultData) {
      throwStreamPrint(threadData, "Error allocating simulation result data of size %ld",pltData->maxPoints * pltData->dataSize);
    }
    add_result(self,data,pltData->simulationResultData,&pltData->actualPoints);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/*
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */
static void add_result(simulation_result *self,DATA *data,double *data_, long *actualPoints)
{
  plt_data *pltData = (plt_data*) self->storage;
  const DATA *simData = data;
  int i;
  double cpuTimeValue = 0;

  rt_accumulate(SIM_TIMER_TOTAL);
  cpuTimeValue = rt_accumulated(SIM_TIMER_TOTAL);
  rt_tick(SIM_TIMER_TOTAL);

  {
    data_[pltData->currentPos++] = simData->localData[0]->timeValue;

    if(self->cpuTime)
      data_[pltData->currentPos++] = cpuTimeValue;

    /* .. reals .. */
    for(i = 0; i < simData->modelData->nVariablesReal; i++) {
      if(!simData->modelData->realVarsData[i].filterOutput) {
        data_[pltData->currentPos++] = simData->localData[0]->realVars[i];
      }
    }
    /* .. integers .. */
    for(i = 0; i < simData->modelData->nVariablesInteger; i++) {
      if(!simData->modelData->integerVarsData[i].filterOutput) {
        data_[pltData->currentPos++] = simData->localData[0]->integerVars[i];
      }
    }
    /* .. booleans .. */
    for(i = 0; i < simData->modelData->nVariablesBoolean; i++) {
      if(!simData->modelData->booleanVarsData[i].filterOutput) {
        data_[pltData->currentPos++] = simData->localData[0]->booleanVars[i];
      }
    }
    /* .. alias reals .. */
    for(i = 0; i < simData->modelData->nAliasReal; i++) {
      if(!simData->modelData->realAlias[i].filterOutput) {
        double value;
        if(simData->modelData->realAlias[i].aliasType == 2)
          value = (simData->localData[0])->timeValue;
        else if(simData->modelData->realAlias[i].aliasType == 1)
          value = simData->simulationInfo->realParameter[simData->modelData->realAlias[i].nameID];
        else
          value = (simData->localData[0])->realVars[simData->modelData->realAlias[i].nameID];
        if(simData->modelData->realAlias[i].negate)
          data_[pltData->currentPos++] = -value;
        else
          data_[pltData->currentPos++] = value;
      }
    }
    /* .. alias integers .. */
    for(i = 0; i < simData->modelData->nAliasInteger; i++) {
      if(!simData->modelData->integerAlias[i].filterOutput) {
        modelica_integer value;
        if(simData->modelData->integerAlias[i].aliasType == 1)
          value = simData->simulationInfo->integerParameter[simData->modelData->realAlias[i].nameID];
        else
          value = (simData->localData[0])->integerVars[simData->modelData->realAlias[i].nameID];
        if(simData->modelData->integerAlias[i].negate)
          data_[pltData->currentPos++] = -value;
        else
          data_[pltData->currentPos++] = value;
      }
    }
    /* .. alias booleans .. */
    for(i = 0; i < simData->modelData->nAliasBoolean; i++) {
      if(!simData->modelData->booleanAlias[i].filterOutput) {
        modelica_boolean value;
        if(simData->modelData->integerAlias[i].aliasType == 1)
          value = simData->simulationInfo->booleanParameter[simData->modelData->realAlias[i].nameID];
        else
          value = (simData->localData[0])->booleanVars[simData->modelData->realAlias[i].nameID];
        if(simData->modelData->booleanAlias[i].negate)
          data_[pltData->currentPos++] = value==1?0:1;
        else
          data_[pltData->currentPos++] = value;
      }
    }
  }

  /*cerr << "  ... done" << endl; */
  (*actualPoints)++;
}

void plt_init(simulation_result *self,DATA *data, threadData_t *threadData)
{
  plt_data *pltData = (plt_data*) malloc(sizeof(plt_data));
  rt_tick(SIM_TIMER_OUTPUT);
  /*
   * Re-Initialization is important because the variables are global and used in every solving step
   */
  pltData->simulationResultData = 0;
  pltData->currentPos = 0;
  pltData->actualPoints = 0; /* the number of actual points saved */
  pltData->dataSize = 0;
  pltData->maxPoints = self->numpoints;

  assertStreamPrint(threadData, self->numpoints >= 0, "Automatic output steps not supported in OpenModelica yet. Set numpoints >= 0.");

  pltData->num_vars = calcDataSize(self,data->modelData);
  pltData->dataSize = calcDataSize(self,data->modelData);
  pltData->simulationResultData = (double*)malloc(self->numpoints * pltData->dataSize * sizeof(double));
  if(!pltData->simulationResultData) {
    throwStreamPrint(threadData, "Error allocating simulation result data of size %ld failed",self->numpoints * pltData->dataSize);
  }
  pltData->currentPos = 0;
  self->storage = pltData;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * Deallocates the simulationResultData
 * This is important for an interactive Simulation because
 * the solvers will be called in a loop and they allocate
 * memory for the simulationResultData all the time
 */
static void deallocResult(plt_data *pltData)
{
  if(pltData->simulationResultData)
  {
    free(pltData->simulationResultData);
    pltData->simulationResultData = 0;
  }
}

static void printPltLine(FILE* f, double time, double val)
{
  /* Double has max 16 digits precision */
  fprintf(f, "%.16g, %.16g\n", time, val);
}

/*
* output the result before destroying the datastructure.
*/
void plt_free(simulation_result *self,DATA *data, threadData_t *threadData)
{
  plt_data *pltData = (plt_data*) self->storage;
  const MODEL_DATA *modelData = data->modelData;
  int varn = 0, i, var;
  FILE* f = NULL;

  rt_tick(SIM_TIMER_OUTPUT);

  f = fopen(self->filename, "w");
  if(!f)
  {
    deallocResult(pltData);
    throwStreamPrint(threadData, "Error, couldn't create output file: [%s] because of %s", self->filename, strerror(errno));
  }

  /* Rather ugly numbers than unneccessary rounding.
     f.precision(std::numeric_limits<double>::digits10 + 1); */
  fprintf(f, "#Ptolemy Plot file, generated by OpenModelica\n");
  fprintf(f, "#NumberofVariables=%d\n", pltData->num_vars);
  fprintf(f, "#IntervalSize=%ld\n", pltData->actualPoints);
  fprintf(f, "TitleText: OpenModelica simulation plot\n");
  fprintf(f, "XLabel: t\n\n");

  /* time variable. */
  fprintf(f, "DataSet: time\n");
  for(i = 0; i < pltData->actualPoints; ++i)
      printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars]);
  fprintf(f, "\n");
  varn++;

  /* $cpuTime variable. */
  if(self->cpuTime)
  {
    fprintf(f, "DataSet: $cpuTime\n");
    for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + 1]);
    fprintf(f, "\n");
    varn++;
  }

  for(var = 0; var < modelData->nVariablesReal; ++var)
  {
    if(!modelData->realVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->realVarsData[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(var = 0; var < modelData->nVariablesInteger; ++var)
  {
    if(!modelData->integerVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->integerVarsData[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(var = 0; var < modelData->nVariablesBoolean; ++var)
  {
    if(!modelData->booleanVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->booleanVarsData[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(var = 0; var < modelData->nAliasReal; ++var)
  {
    if(!modelData->realAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->realAlias[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(var = 0; var < modelData->nAliasInteger; ++var)
  {
    if(!modelData->integerAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->integerAlias[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(var = 0; var < modelData->nAliasBoolean; ++var)
  {
    if(!modelData->booleanAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->booleanAlias[var].info.name);
      for(i = 0; i < pltData->actualPoints; ++i)
        printPltLine(f, pltData->simulationResultData[i*pltData->num_vars], pltData->simulationResultData[i*pltData->num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  deallocResult(pltData);
  if(fclose(f))
  {
    throwStreamPrint(threadData, "Error, couldn't write to output file %s\n", self->filename);
  }
  free(self->storage);
  self->storage = NULL;
  rt_accumulate(SIM_TIMER_OUTPUT);
}

}
