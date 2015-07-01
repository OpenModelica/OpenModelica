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

/*! \file solver_main.h
 *
 *  Description: This file is a C header file for the main solver function.
 *  It contains integration method for simulation.
 */

#ifndef OMC_SOLVER_MAIN_H
#define OMC_SOLVER_MAIN_H

#include "openmodelica.h"
#include "simulation_data.h"
#include "util/list.h"
#include "util/simulation_options.h"

typedef struct SOLVER_INFO
{
  double currentTime;
  double currentStepSize;
  double laststep;
  int solverMethod;

  /* set by solver if an internal root finding method is activated  */
  modelica_boolean solverRootFinding;

  /* events */
  LIST* eventLst;
  int didEventStep;

  /* stats */
  unsigned long stateEvents;
  unsigned long sampleEvents;

  void* solverData;
}SOLVER_INFO;

#ifdef __cplusplus
  extern "C" {
#endif

extern int solver_main(DATA* data, const char* init_initMethod,
    const char* init_file, double init_time, int lambda_steps,
    int solverID, const char* outputVariablesAtEnd);

/* Provide solver interface to interactive stuff */
extern int initializeSolverData(DATA* data, SOLVER_INFO* solverInfo);
extern int freeSolverData(DATA* data, SOLVER_INFO* solverInfo);

extern int freeSolverData(DATA* data, SOLVER_INFO* solverInfo);

extern int initializeModel(DATA* data, const char* init_initMethod,
    const char* init_file, double init_time, int lambda_steps);

extern int finishSimulation(DATA* data, SOLVER_INFO* solverInfo, const char* outputVariablesAtEnd);

extern int solver_main_step(DATA* data, SOLVER_INFO* solverInfo);

void checkTermination(DATA* data);

extern int stateSelection(DATA *data, char reportError, int switchStates);

#ifdef __cplusplus
  }
#endif

#endif
