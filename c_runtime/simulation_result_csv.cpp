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
#include "simulation_result_csv.h"
#include "simulation_runtime.h"
#include "sendData/sendData.h"
#include <sstream>
#include <time.h>


void simulation_result_csv::emit()
{
  const char* format = "%.16g,";
  storeExtrapolationData();
  fprintf(fout, format, globalData->timeValue);
  for (int i = 0; i < globalData->nStates; i++)
   	fprintf(fout, format, globalData->states[i]);
  for (int i = 0; i < globalData->nStates; i++)
    fprintf(fout, format, globalData->statesDerivatives[i]);
  for (int i = 0; i < globalData->nAlgebraic; i++)
    fprintf(fout, format, globalData->algebraics[i]);
  fprintf(fout, "\n");
}

simulation_result_csv::simulation_result_csv(const char* filename, long numpoints) : simulation_result(filename,numpoints)
{
  const char* format = "\"%s\",";
  fout = fopen(filename, "w");
  if (!fout)
  {
    fprintf(stderr, "Error, couldn't create output file: [%s] because of %s", filename, strerror(errno));
    throw SimulationResultFileOpenException();
  }

  fprintf(fout, format, "time");
  for (int i = 0; i < globalData->nStates; i++)
 	  fprintf(fout, format, globalData->statesNames[i]);
  for (int i = 0; i < globalData->nStates; i++)
 	  fprintf(fout, format, globalData->stateDerivativesNames[i]);
  for (int i = 0; i < globalData->nAlgebraic; i++)
 	  fprintf(fout, format, globalData->algebraicsNames[i]);
  fprintf(fout,"\n");
}

simulation_result_csv::~simulation_result_csv()
{
  fclose(fout);
}
