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

#include <stdio.h>
#include <errno.h>
#include <string.h>
#include <limits> /* adrpo - for std::numeric_limits in MSVC */
#include "simulation_result_plt.h"
#include "simulation_runtime.h"
#include <sstream>
#include <time.h>
//#include "../Compiler/runtime/config.h"
#include "rtclock.h"

#ifdef CONFIG_WITH_SENDDATA
#include "sendData/sendData.h"
#endif

static const struct omc_varInfo timeValName = {0,"time","Simulation time [s]",{"",-1,-1,-1,-1}};

static int calcDataSize()
{
  int sz = 1; // time
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesDerivativesFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->nAlgebraic; i++) if (!globalData->algebraicsFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->nAlias; i++) if (!globalData->aliasFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) if (!globalData->intVariables.algebraicsFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->intVariables.nAlias; i++) if (!globalData->intVariables.aliasFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) if (!globalData->boolVariables.algebraicsFilterOutput[i]) sz++;
  for (int i = 0; i < globalData->boolVariables.nAlias; i++) if (!globalData->boolVariables.aliasFilterOutput[i]) sz++;
  return sz;
}

static const omc_varInfo** calcDataNames(int dataSize)
{
  const omc_varInfo** names = (const omc_varInfo**) malloc(dataSize*sizeof(struct omc_varInfo*));
  int curVar = 0;
  names[curVar++] = &timeValName;
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesFilterOutput[i])
      names[curVar++] = &globalData->statesNames[i];
  for (int i = 0; i < globalData->nStates; i++) if (!globalData->statesDerivativesFilterOutput[i])
      names[curVar++] = &globalData->stateDerivativesNames[i];
  for (int i = 0; i < globalData->nAlgebraic; i++) if (!globalData->algebraicsFilterOutput[i])
      names[curVar++] = &globalData->algebraicsNames[i];
  for (int i = 0; i < globalData->nAlias; i++) if (!globalData->aliasFilterOutput[i])
      names[curVar++] = &globalData->alias_names[i];
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) if (!globalData->intVariables.algebraicsFilterOutput[i])
      names[curVar++] = &globalData->int_alg_names[i];
  for (int i = 0; i < globalData->intVariables.nAlias; i++) if (!globalData->intVariables.aliasFilterOutput[i])
      names[curVar++] = &globalData->int_alias_names[i];
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) if (!globalData->boolVariables.algebraicsFilterOutput[i])
      names[curVar++] = &globalData->bool_alg_names[i];
  for (int i = 0; i < globalData->boolVariables.nAlias; i++) if (!globalData->boolVariables.aliasFilterOutput[i])
      names[curVar++] = &globalData->bool_alias_names[i];

  return names;
}

void simulation_result_plt::emit()
{
  storeExtrapolationData();
  rt_tick(SIM_TIMER_OUTPUT);
  if (actualPoints < maxPoints) {
    if(!isInteractiveSimulation())add_result(simulationResultData,&actualPoints); //used for non-interactive simulation
  } else {
    maxPoints = (long)(1.4*maxPoints + (maxPoints-actualPoints) + 2000);
    // cerr << "realloc simulationResultData to a size of " << maxPoints * dataSize * sizeof(double) << endl;
    simulationResultData = (double*)realloc(simulationResultData, maxPoints * dataSize * sizeof(double));
    if (!simulationResultData) {
      cerr << "Error allocating simulation result data of size " << maxPoints * dataSize << endl;
      throw SimulationResultReallocException();
    }
    add_result(simulationResultData,&actualPoints);
  }
  rt_accumulate(SIM_TIMER_OUTPUT);
}

 /*
 * add the values of one step for all variables to the data
 * array to be able to later store this on file.
 */
void simulation_result_plt::add_result(double *data, long *actualPoints)
{
  //save time first
  //cerr << "adding result for time: " << time;
  //cerr.flush();
#ifdef CONFIG_WITH_SENDDATA
  if(Static::enabled())
  {
  std::ostringstream ss;
  ss << "time" << "\n";
  ss << (data[currentPos++] = globalData->timeValue) << "\n";
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++) {
    if (!globalData->statesFilterOutput[i]) {
      ss << globalData->statesNames[i].name << "\n";
      ss << (data[currentPos++] = globalData->states[i]) << "\n";
    }
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++) {
    if (!globalData->statesDerivativesFilterOutput[i]) {
      ss << globalData->stateDerivativesNames[i].name << "\n";
      ss << (data[currentPos++] = globalData->statesDerivatives[i]) << "\n";
    }
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++) {
    if (!globalData->algebraicsFilterOutput[i]) {
      ss << globalData->algebraicsNames[i].name << "\n";
      ss << (data[currentPos++] = globalData->algebraics[i]) << "\n";
    }
  }
  // .. and last alg. vars. alias
  for (int i = 0; i < globalData->nAlias; i++) {
    if (!globalData->aliasFilterOutput[i]) {
      ss << globalData->alias_names[i].name << "\n";
      if (((globalData->realAlias)[i]).negate){
        ss << (data[currentPos++] = - *(((globalData->realAlias)[i].alias))) << "\n";
  }else{
        ss << (data[currentPos++] = *(((globalData->realAlias)[i].alias))) << "\n";
      }
    }
  }
 // .. and int alg. vars.
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) {
    if (!globalData->intVariables.algebraicsFilterOutput[i]) {
      ss << globalData->int_alg_names[i].name << "\n";
      ss << (data[currentPos++] = (double) globalData->intVariables.algebraics[i]) << "\n";
    }
  }
   // .. and int alg. vars. alias
  for (int i = 0; i < globalData->intVariables.nAlias; i++) {
    if (!globalData->intVariables.aliasFilterOutput[i]) {
      ss << globalData->int_alias_names[i].name << "\n";
      if (((globalData->intVariables.alias)[i]).negate){
        ss << (data[currentPos++] = -(double) *(((globalData->intVariables.alias)[i].alias))) << "\n";
        }else{
        ss << (data[currentPos++] = (double) *(((globalData->intVariables.alias)[i].alias))) << "\n";
      }
    }
  } // .. and bool alg. vars.
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) {
    if (!globalData->boolVariables.algebraicsFilterOutput[i]) {
      ss << globalData->bool_alg_names[i].name << "\n";
      ss << (data[currentPos++] = (double) globalData->boolVariables.algebraics[i]) << "\n";
    }
  }
  // .. and bool alg. vars. alias
  for (int i = 0; i < globalData->boolVariables.nAlias; i++) {
    if (!globalData->boolVariables.aliasFilterOutput[i]) {
      ss << globalData->bool_alias_names[i].name << "\n";
      if (((globalData->boolVariables.alias)[i]).negate){
        ss << (data[currentPos++] = -(double) *(((globalData->boolVariables.alias)[i].alias))) << "\n";
        }else{
        ss << (data[currentPos++] = (double) *(((globalData->boolVariables.alias)[i].alias))) << "\n";
      }
    }
  } // .. and bool alg. vars.
  sendPacket(ss.str().c_str());
  }
  else
#endif // CONFIG_WITH_SENDDATA
  {
  data[currentPos++] = globalData->timeValue;

  // .. then states..
  for (int i = 0; i < globalData->nStates; i++) {
    if (!globalData->statesFilterOutput[i]) {
      data[currentPos++] = globalData->states[i];
    }
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++) {
    if (!globalData->statesDerivativesFilterOutput[i]) {
      data[currentPos++] = globalData->statesDerivatives[i];
    }
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++) {
    if (!globalData->algebraicsFilterOutput[i]) {
      data[currentPos++] = globalData->algebraics[i];
    }
  }
  // .. and alg. vars. alias
  for (int i = 0; i < globalData->nAlias; i++) {
    if (!globalData->aliasFilterOutput[i]) {
      if (((globalData->realAlias)[i]).negate){
        data[currentPos++] = (-1.0) * *(((globalData->realAlias)[i].alias));
      }else{
        data[currentPos++] = *(((globalData->realAlias)[i].alias));
      }
    }
  }
  // .. and int alg. vars.
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++) {
    if (!globalData->intVariables.algebraicsFilterOutput[i]) {
      data[currentPos++] = (double) globalData->intVariables.algebraics[i];
    }
  }
  // .. and int alg. vars. alias
  for (int i = 0; i < globalData->intVariables.nAlias; i++) {
    if (!globalData->intVariables.aliasFilterOutput[i]) {
      if (((globalData->intVariables.alias)[i]).negate){
        data[currentPos++] = (double) (-1.0) * *(((globalData->intVariables.alias)[i].alias));
      }else{
        data[currentPos++] = (double)*(((globalData->intVariables.alias)[i].alias));
      }
    }
  } 
  // .. and bool alg. vars.
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++) {
    if (!globalData->boolVariables.algebraicsFilterOutput[i]) {
      data[currentPos++] = (double) globalData->boolVariables.algebraics[i];
    }
  }
  // .. and bool alg. vars. alias
  for (int i = 0; i < globalData->boolVariables.nAlias; i++) {
    if (!globalData->boolVariables.aliasFilterOutput[i]) {
      if (((globalData->boolVariables.alias)[i]).negate){
        data[currentPos++] = (double) (-1.0) * *(((globalData->boolVariables.alias)[i].alias));
      }else{
        data[currentPos++] = (double) *((globalData->boolVariables.alias[i]).alias);
      }
    }
  }
  } 

  //cerr << "  ... done" << endl;
  (*actualPoints)++;
}

simulation_result_plt::simulation_result_plt(const char* filename, long numpoints) : simulation_result(filename,numpoints)
{
  rt_tick(SIM_TIMER_OUTPUT);
  /*
   * Re-Initialization is important because the variables are global and used in every solving step
   */
  simulationResultData = 0;
  currentPos = 0;
  actualPoints = 0; // the number of actual points saved
  dataSize = 0;
  maxPoints = numpoints;

  if (numpoints < 0 ) { // Automatic number of output steps
    cerr << "Warning automatic output steps not supported in OpenModelica yet." << endl;
    cerr << "Attempt to solve this by allocating large amount of result data." << endl;
    numpoints = abs(numpoints);
    maxPoints = abs(numpoints);
  }
  dataSize = calcDataSize();
  simulationResultData = (double*)malloc(numpoints * dataSize * sizeof(double));
  if (!simulationResultData) {
    cerr << "Error allocating simulation result data of size " << numpoints * dataSize << endl;
    throw SimulationResultMallocException();
  }
  currentPos = 0;
#ifdef CONFIG_WITH_SENDDATA
  char* enabled = getenv("enableSendData");
  if(enabled != NULL) {
    Static::enabled_ = !strcmp(enabled, "1");
  }
  if(Static::enabled()) {
    const omc_varInfo** names = calcDataNames(dataSize);
    initSendData(dataSize,names);
    free(names);
  }
#endif // CONFIG_WITH_SENDDATA
  rt_accumulate(SIM_TIMER_OUTPUT);
}

/**
 * Deallocates the simulationResultData
 * This is important for an interactive Simulation because
 * the solvers will be called in a loop and they allocate
 * memory for the simulationResultData all the time
 */
void simulation_result_plt::deallocResult(){
  free(simulationResultData);
}

void simulation_result_plt::printPltLine(FILE* f, double time, double val) {
#if 0
  fwrite(&time, sizeof(double), 1, f);
  fputs(", ", f);
  fwrite(&val, sizeof(double), 1, f);
  fputs("\n", f);
#else
  // Double has max 16 digits precision
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
    fprintf(stderr, "Error, couldn't create output file: [%s] because of %s", filename, strerror(errno));
    deallocResult();
    throw SimulationResultFileOpenException();
  }

  int num_vars = calcDataSize();
  // Rather ugly numbers than unneccessary rounding.
  //f.precision(std::numeric_limits<double>::digits10 + 1);
  fprintf(f, "#Ptolemy Plot file, generated by OpenModelica\n");
  fprintf(f, "#NumberofVariables=%d\n", num_vars);
  fprintf(f, "#IntervalSize=%ld\n", actualPoints);
  fprintf(f, "TitleText: OpenModelica simulation plot\n");
  fprintf(f, "XLabel: t\n\n");

  int varn = 0;

  // time variable.
  fprintf(f, "DataSet: time\n");
  for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars]);
  fprintf(f, "\n");
  varn++;

  for(int var = 0; var < globalData->nStates; ++var)
  {
    if (!globalData->statesFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->statesNames[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < globalData->nStates; ++var)
  {
    if (!globalData->statesDerivativesFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->stateDerivativesNames[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < globalData->nAlgebraic; ++var)
  {
    if (!globalData->algebraicsFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->algebraicsNames[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }
  for(int var = 0; var < globalData->nAlias; ++var)
  {
    if (!globalData->aliasFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->alias_names[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }
  for(int var = 0; var < globalData->intVariables.nAlgebraic; ++var)
  {
    if (!globalData->intVariables.algebraicsFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->int_alg_names[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }
  for(int var = 0; var < globalData->intVariables.nAlias; ++var)
  {
    if (!globalData->intVariables.aliasFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->int_alias_names[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }

  for(int var = 0; var < globalData->boolVariables.nAlgebraic; ++var)
  {
    if (!globalData->boolVariables.algebraicsFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->bool_alg_names[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }
  for(int var = 0; var < globalData->boolVariables.nAlias; ++var)
  {
    if (!globalData->boolVariables.aliasFilterOutput[var]) {
      fprintf(f, "DataSet: %s\n", globalData->bool_alias_names[var].name);
      for(int i = 0; i < actualPoints; ++i)
        printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + varn]);
      fprintf(f, "\n");
      varn++;
    }
  }


  deallocResult();
  if (fclose(f))
  {
    fprintf(stderr, "Error, couldn't write to output file %s\n", filename);
    throw SimulationResultFileCloseException();
  }

  rt_accumulate(SIM_TIMER_OUTPUT);
}
