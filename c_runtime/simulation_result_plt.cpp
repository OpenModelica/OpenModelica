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
#include "sendData/sendData.h"
#include <sstream>
#include <time.h>


void simulation_result_plt::emit()
{
  storeExtrapolationData();
  if (actualPoints < maxPoints) {
	  if(!isInteractiveSimulation())add_result(simulationResultData,&actualPoints); //used for non-interactive simulation
    return;
  }
  else {
    maxPoints = 1.4*maxPoints + (maxPoints-actualPoints) + 2000;
    // cerr << "realloc simulationResultData to a size of " << maxPoints * dataSize * sizeof(double) << endl;
    simulationResultData = (double*)realloc(simulationResultData, maxPoints * dataSize * sizeof(double));
    if (!simulationResultData) {
      cerr << "Error allocating simulation result data of size " << maxPoints * dataSize << endl;
      throw SimulationResultReallocException();
    }
    add_result(simulationResultData,&actualPoints);
  }
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
  if(Static::enabled())
  {
  std::ostringstream ss;
  ss << "time" << "\n";
  ss << (data[currentPos++] = globalData->timeValue) << "\n";
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
 	ss << globalData->statesNames[i] << "\n";
    ss << (data[currentPos] = globalData->states[i]) << "\n";
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
  	ss << globalData->stateDerivativesNames[i] << "\n";
    ss << (data[currentPos] = globalData->statesDerivatives[i]) << "\n";
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++, currentPos++) {
  	ss << globalData->algebraicsNames[i] << "\n";
    ss << (data[currentPos] = globalData->algebraics[i]) << "\n";
  }
  // .. and int alg. vars.
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++, currentPos++) {
  	ss << globalData->int_alg_names[i] << "\n";
    ss << (data[currentPos] = (double) globalData->intVariables.algebraics[i]) << "\n";
  }
  // .. and bool alg. vars.
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++, currentPos++) {
  	ss << globalData->bool_alg_names[i] << "\n";
    ss << (data[currentPos] = (double) globalData->boolVariables.algebraics[i]) << "\n";
  }

  sendPacket(ss.str().c_str());
  }
  else
  {

  (data[currentPos++] = globalData->timeValue);
  // .. then states..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
 	(data[currentPos] = globalData->states[i]);
  }
  // ..followed by derivatives..
  for (int i = 0; i < globalData->nStates; i++, currentPos++) {
    (data[currentPos] = globalData->statesDerivatives[i]);
  }
  // .. and last alg. vars.
  for (int i = 0; i < globalData->nAlgebraic; i++, currentPos++) {
    (data[currentPos] = globalData->algebraics[i]);
  }
  // .. and int alg. vars.
  for (int i = 0; i < globalData->intVariables.nAlgebraic; i++, currentPos++) {
	(data[currentPos] = (double) globalData->intVariables.algebraics[i]);
  }
  // .. and bool alg. vars.
  for (int i = 0; i < globalData->boolVariables.nAlgebraic; i++, currentPos++) {
	(data[currentPos] = (double) globalData->boolVariables.algebraics[i]);
  }


  }

  //cerr << "  ... done" << endl;
  (*actualPoints)++;
}

simulation_result_plt::simulation_result_plt(const char* filename, long numpoints) : simulation_result(filename,numpoints)
{
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
  dataSize = (globalData->nStates*2+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic+1);
  simulationResultData = (double*)malloc(numpoints * dataSize * sizeof(double));
  if (!simulationResultData) {
    cerr << "Error allocating simulation result data of size " << numpoints * dataSize << endl;
    throw SimulationResultMallocException();
  }
  currentPos = 0;
  char* enabled = getenv("enableSendData");
  if(enabled != NULL)
  {
  	Static::enabled_ = !strcmp(enabled, "1");
  }
  if(Static::enabled())
  	initSendData(	globalData->nStates,
					globalData->nAlgebraic,
					globalData->intVariables.nAlgebraic,
					globalData->boolVariables.nAlgebraic,
					globalData->statesNames,
					globalData->stateDerivativesNames,
					globalData->algebraicsNames,
					globalData->int_alg_names,
					globalData->bool_alg_names);
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
  if(Static::enabled())
  	closeSendData();

  FILE* f = fopen(filename, "w");
  if (!f)
  {
    fprintf(stderr, "Error, couldn't create output file: [%s] because of %s", filename, strerror(errno));
    deallocResult();
    throw SimulationResultFileOpenException();
  }

  clock_t  t0, t1;
  t0 = clock();

  // Rather ugly numbers than unneccessary rounding.
  //f.precision(std::numeric_limits<double>::digits10 + 1);
  fprintf(f, "#Ptolemy Plot file, generated by OpenModelica\n");
  fprintf(f, "#IntervalSize=%ld\n", actualPoints);
  fprintf(f, "TitleText: OpenModelica simulation plot\n");
  fprintf(f, "XLabel: t\n\n");

  int num_vars = 1+globalData->nStates*2+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+globalData->boolVariables.nAlgebraic;

  // time variable.
  fprintf(f, "DataSet: time\n");
  for(int i = 0; i < actualPoints; ++i)
    printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars]);
  fprintf(f, "\n");

  for(int var = 0; var < globalData->nStates; ++var)
  {
    fprintf(f, "DataSet: %s\n", globalData->statesNames[var]);
    for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + 1+var]);
    fprintf(f, "\n");
  }

  for(int var = 0; var < globalData->nStates; ++var)
  {
    fprintf(f, "DataSet: %s\n", globalData->stateDerivativesNames[var]);
    for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + 1+globalData->nStates+var]);
    fprintf(f, "\n");
  }

  for(int var = 0; var < globalData->nAlgebraic; ++var)
  {
    fprintf(f, "DataSet: %s\n", globalData->algebraicsNames[var]);
    for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + 1+2*globalData->nStates+var]);
    fprintf(f, "\n");
  }

  for(int var = 0; var < globalData->intVariables.nAlgebraic; ++var)
  {
    fprintf(f, "DataSet: %s\n", globalData->int_alg_names[var]);
    for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + 1+2*globalData->nStates+globalData->nAlgebraic+var]);
    fprintf(f, "\n");
  }

  for(int var = 0; var < globalData->boolVariables.nAlgebraic; ++var)
  {
    fprintf(f, "DataSet: %s\n", globalData->bool_alg_names[var]);
    for(int i = 0; i < actualPoints; ++i)
      printPltLine(f, simulationResultData[i*num_vars], simulationResultData[i*num_vars + 1+2*globalData->nStates+globalData->nAlgebraic+globalData->intVariables.nAlgebraic+var]);
    fprintf(f, "\n");
  }

  deallocResult();
  if (fclose(f))
  {
    fprintf(stderr, "Error, couldn't write to output file %s\n", filename);
    throw SimulationResultFileCloseException();
  }

  t1 = clock();
  // printf ("\telapsed wall clock time for printing simulation results: %g\n", ((double) (t1 - t0))/CLOCKS_PER_SEC);
}
