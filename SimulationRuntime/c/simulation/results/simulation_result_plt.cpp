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
#include "simulation_result_plt.h"
#include "simulation_runtime.h"
#include <sstream>
#include <time.h>

#include "rtclock.h"

#ifdef CONFIG_WITH_SENDDATA
#include "sendData/sendData.h"
#endif

static const char * timeName = "time";

static int calcDataSize(MODEL_DATA *modelData)
{
  int sz = 1; // time
  for (int i = 0; i < modelData->nVariablesReal; i++) if (!modelData->realVarsData[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nVariablesInteger; i++) if (!modelData->integerVarsData[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nVariablesBoolean; i++) if (!modelData->booleanVarsData[i].filterOutput) sz++;
  /* for (int i = 0; i < modelData->nVariablesString; i++) if (!modelData->stringVarsData[i].filterOutput) sz++; */

  for (int i = 0; i < modelData->nAliasReal; i++) if (!modelData->realAlias[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nAliasInteger; i++) if (!modelData->integerAlias[i].filterOutput) sz++;
  for (int i = 0; i < modelData->nAliasBoolean; i++) if (!modelData->booleanAlias[i].filterOutput) sz++;
  /* for (int i = 0; i < modelData->nAliasString; i++) if (!modelData->stringAlias[i].filterOutput) sz++; */

  return sz;
}

static const char** calcDataNames(MODEL_DATA *modelData, int dataSize)
{
  const char** names = (const char**)calloc(dataSize,sizeof(char*));
  ASSERT(names,"Not enough memory!");
  int curVar = 0;
  names[curVar++] = timeName;
  for (int i = 0; i < modelData->nVariablesReal; i++) if (!modelData->realVarsData[i].filterOutput)
    names[curVar++] = modelData->realVarsData[i].info.name;
  for (int i = 0; i < modelData->nVariablesInteger; i++) if (!modelData->integerVarsData[i].filterOutput)
    names[curVar++] = modelData->integerVarsData[i].info.name;
  for (int i = 0; i < modelData->nVariablesBoolean; i++) if (!modelData->booleanVarsData[i].filterOutput)
    names[curVar++] = modelData->booleanVarsData[i].info.name;
/*  for (int i = 0; i < modelData->nVariablesString; i++) if (!modelData->stringVarsData[i].filterOutput)
    names[curVar++] = modelData->stringVarsData[i].info.name; */
  for (int i = 0; i < modelData->nAliasReal; i++) if (!modelData->realAlias[i].filterOutput)
    names[curVar++] = modelData->realAlias[i].info.name;
  for (int i = 0; i < modelData->nAliasInteger; i++) if (!modelData->integerAlias[i].filterOutput)
    names[curVar++] = modelData->integerAlias[i].info.name;
  for (int i = 0; i < modelData->nAliasBoolean; i++) if (!modelData->booleanAlias[i].filterOutput)
    names[curVar++] = modelData->booleanAlias[i].info.name;
/*  for (int i = 0; i < modelData->nAliasString; i++) if (!modelData->stringAlias[i].filterOutput)
    names[curVar++] = modelData->stringAlias[i].info.name; */
  return names;
}

void simulation_result_plt::emit(_X_DATA *data)
{
  rt_tick(SIM_TIMER_OUTPUT);
  if (actualPoints < maxPoints) 
  {
    if(!isInteractiveSimulation())
      add_result(simulationResultData,&actualPoints,data); /*used for non-interactive simulation */
  } else 
  {
    maxPoints = (long)(1.4*maxPoints + (maxPoints-actualPoints) + 2000);
    /* cerr << "realloc simulationResultData to a size of " << maxPoints * dataSize * sizeof(double) << endl; */
    simulationResultData = (double*)realloc(simulationResultData, maxPoints * dataSize * sizeof(double));
    if (!simulationResultData) 
      THROW1("Error allocating simulation result data of size %ld",maxPoints * dataSize);
    add_result(simulationResultData,&actualPoints,data);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

 /*
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */
void simulation_result_plt::add_result(double *data, long *actualPoints, _X_DATA *simData)
{
  /* save time first */
  /* cerr << "adding result for time: " << time; */
  /* cerr.flush(); */
#ifdef CONFIG_WITH_SENDDATA
  if(Static::enabled())
  {
  std::ostringstream ss;
  ss << "time" << "\n";
  ss << (data[currentPos++] = simData->localData[0]->timeValue) << "\n";
  /* .. reals .. */
  for (int i = 0; i < simData->modelData.nVariablesReal; i++) {
    if (!simData->modelData.realVarsData[i].filterOutput) {
      ss << simData->modelData.realVarsData[i].info.name << "\n";
      ss << (data[currentPos++] = simData->localData[0]->realVars[i]) << "\n";
    }
  }
  /* .. integers .. */
  for (int i = 0; i < simData->modelData.nVariablesInteger; i++) {
    if (!simData->modelData.integerVarsData[i].filterOutput) {
      ss << simData->modelData.integerVarsData[i].info.name << "\n";
      ss << (data[currentPos++] = simData->localData[0]->integerVars[i]) << "\n";
    }
  }
  /* .. booleans .. */
  for (int i = 0; i < simData->modelData.nVariablesBoolean; i++) {
    if (!simData->modelData.booleanVarsData[i].filterOutput) {
      ss << simData->modelData.booleanVarsData[i].info.name << "\n";
      ss << (data[currentPos++] = simData->localData[0]->booleanVars[i]) << "\n";
    }
  }
  /* .. alias reals .. */
  for (int i = 0; i < simData->modelData.nAliasReal; i++) {
    if (!simData->modelData.realAlias[i].filterOutput) {
      ss << simData->modelData.realAlias[i].info.name << "\n";
      if (simData->modelData.realAlias[i].negate)
        ss << (data[currentPos++] = -simData->localData[0]->realVars[simData->modelData.realAlias[i].nameID]) << "\n";
      else
        ss << (data[currentPos++] = simData->localData[0]->realVars[simData->modelData.realAlias[i].nameID]) << "\n";
    }
  }
  /* .. alias integers .. */
  for (int i = 0; i < simData->modelData.nAliasInteger; i++) {
    if (!simData->modelData.integerAlias[i].filterOutput) {
      ss << simData->modelData.integerAlias[i].info.name << "\n";
      if (simData->modelData.integerAlias[i].negate)
        ss << (data[currentPos++] = -simData->localData[0]->integerVars[simData->modelData.integerAlias[i].nameID]) << "\n";
      else
        ss << (data[currentPos++] = simData->localData[0]->integerVars[simData->modelData.integerAlias[i].nameID]) << "\n";
    }
  }
  /* .. alias booleans .. */
  for (int i = 0; i < simData->modelData.nAliasBoolean; i++) {
    if (!simData->modelData.booleanAlias[i].filterOutput) {
      ss << simData->modelData.booleanAlias[i].info.name << "\n";
      if (simData->modelData.booleanAlias[i].negate)
        ss << (data[currentPos++] = -simData->localData[0]->booleanVars[simData->modelData.booleanAlias[i].nameID]) << "\n";
      else
        ss << (data[currentPos++] = simData->localData[0]->booleanVars[simData->modelData.booleanAlias[i].nameID]) << "\n";
    }
  }
  sendPacket(ss.str().c_str());
  }
  else
#endif /* CONFIG_WITH_SENDDATA */
  {
    data[currentPos++] = simData->localData[0]->timeValue;

    /* .. reals .. */
    for (int i = 0; i < simData->modelData.nVariablesReal; i++) {
      if (!simData->modelData.realVarsData[i].filterOutput) {
        data[currentPos++] = simData->localData[0]->realVars[i];
      }
    }
    /* .. integers .. */
    for (int i = 0; i < simData->modelData.nVariablesInteger; i++) {
      if (!simData->modelData.integerVarsData[i].filterOutput) {
        data[currentPos++] = simData->localData[0]->integerVars[i];
      }
    }
    /* .. booleans .. */
    for (int i = 0; i < simData->modelData.nVariablesBoolean; i++) {
      if (!simData->modelData.booleanVarsData[i].filterOutput) {
        data[currentPos++] = simData->localData[0]->booleanVars[i];
      }
    }
    /* .. alias reals .. */
    for (int i = 0; i < simData->modelData.nAliasReal; i++) {
      if (!simData->modelData.realAlias[i].filterOutput) {
        if (simData->modelData.realAlias[i].negate)
          data[currentPos++] = -simData->localData[0]->realVars[simData->modelData.realAlias[i].nameID];
        else
          data[currentPos++] = simData->localData[0]->realVars[simData->modelData.realAlias[i].nameID];
      }
    }
    /* .. alias integers .. */
    for (int i = 0; i < simData->modelData.nAliasInteger; i++) {
      if (!simData->modelData.integerAlias[i].filterOutput) {
        if (simData->modelData.integerAlias[i].negate)
          data[currentPos++] = -simData->localData[0]->integerVars[simData->modelData.integerAlias[i].nameID];
        else
          data[currentPos++] = simData->localData[0]->integerVars[simData->modelData.integerAlias[i].nameID];
      }
    }
    /* .. alias booleans .. */
    for (int i = 0; i < simData->modelData.nAliasBoolean; i++) {
      if (!simData->modelData.booleanAlias[i].filterOutput) {
        if (simData->modelData.booleanAlias[i].negate)
          data[currentPos++] = -simData->localData[0]->booleanVars[simData->modelData.booleanAlias[i].nameID];
        else
          data[currentPos++] = simData->localData[0]->booleanVars[simData->modelData.booleanAlias[i].nameID];
      }
    }
  } 

  /*cerr << "  ... done" << endl; */
  (*actualPoints)++;
}

simulation_result_plt::simulation_result_plt(const char* filename, long numpoints, MODEL_DATA *modeldata) :
simulation_result(filename,numpoints), modelData(modeldata)
{
  rt_tick(SIM_TIMER_OUTPUT);
  /*
   * Re-Initialization is important because the variables are global and used in every solving step
   */
  simulationResultData = 0;
  currentPos = 0;
  actualPoints = 0; /* the number of actual points saved */
  dataSize = 0;
  maxPoints = numpoints;

  if (numpoints < 0 ) { /* Automatic number of output steps */
    cerr << "Warning automatic output steps not supported in OpenModelica yet." << endl;
    cerr << "Attempt to solve this by allocating large amount of result data." << endl;
    numpoints = abs(numpoints);
    maxPoints = abs(numpoints);
  }
  num_vars = calcDataSize(modelData);
  dataSize = calcDataSize(modelData);
  simulationResultData = (double*)malloc(numpoints * dataSize * sizeof(double));
  if (!simulationResultData) {
    THROW1("Error allocating simulation result data of size %ld failed",numpoints * dataSize);
  }
  currentPos = 0;
#ifdef CONFIG_WITH_SENDDATA
  char* enabled = getenv("enableSendData");
  if(enabled != NULL) {
    Static::enabled_ = !strcmp(enabled, "1");
  }
  if(Static::enabled()) {
    const char** names = calcDataNames(modelData,num_vars);
    initSendData(num_vars,names);
    free(names);
  }
#endif /* CONFIG_WITH_SENDDATA */
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * Deallocates the simulationResultData
 * This is important for an interactive Simulation because
 * the solvers will be called in a loop and they allocate
 * memory for the simulationResultData all the time
 */
void simulation_result_plt::deallocResult()
{
  if (simulationResultData)
    free(simulationResultData);
}

void simulation_result_plt::printPltLine(FILE* f, double time, double val) {
#if 0
  fwrite(&time, sizeof(double), 1, f);
  fputs(", ", f);
  fwrite(&val, sizeof(double), 1, f);
  fputs("\n", f);
#else
  /* Double has max 16 digits precision */
  fprintf(f, "%.16g, %.16g\n", time, val);
#endif
}

/*
* output the result before destroying the datastructure.
*/
simulation_result_plt::~simulation_result_plt()
{
#ifdef CONFIG_WITH_SENDDATA
  if(Static::enabled())
    closeSendData();
#endif
  rt_tick(SIM_TIMER_OUTPUT);

  FILE* f = fopen(filename, "w");
  if (!f)
  {
    deallocResult();
    THROW2("Error, couldn't create output file: [%s] because of %s", filename, strerror(errno));
  }

  /* Rather ugly numbers than unneccessary rounding.
     f.precision(std::numeric_limits<double>::digits10 + 1); */
  fprintf(f, "#Ptolemy Plot file, generated by OpenModelica\n");
  fprintf(f, "#NumberofVariables=%d\n", num_vars);
  fprintf(f, "#IntervalSize=%ld\n", actualPoints);
  fprintf(f, "TitleText: OpenModelica simulation plot\n");
  fprintf(f, "XLabel: t\n\n");

  int varn = 0;

  /* time variable. */
  fprintf(f, "DataSet: time\n");
  for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars]);
  fprintf(f, "\n");
  varn++;

  for(int var = 0; var < modelData->nVariablesReal; ++var)
  {
    if (!modelData->realVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->realVarsData[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < modelData->nVariablesInteger; ++var)
  {
    if (!modelData->integerVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->integerVarsData[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < modelData->nVariablesBoolean; ++var)
  {
    if (!modelData->booleanVarsData[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->booleanVarsData[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < modelData->nAliasReal; ++var)
  {
    if (!modelData->realAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->realAlias[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < modelData->nAliasInteger; ++var)
  {
    if (!modelData->integerAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->integerAlias[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < modelData->nAliasBoolean; ++var)
  {
    if (!modelData->booleanAlias[var].filterOutput) {
      fprintf(f, "DataSet: %s\n", modelData->booleanAlias[var].info.name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  deallocResult();
  if (fclose(f))
  {
    THROW1("Error, couldn't write to output file %s\n", filename);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}
