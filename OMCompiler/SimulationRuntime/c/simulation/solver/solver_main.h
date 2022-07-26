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

#include "../../openmodelica.h"
#include "../../simulation_data.h"
#include "../../util/list.h"
#include "../../util/simulation_options.h"

static const unsigned int numStatistics = 5;

/**
 * @brief Solver statistics.
 */
typedef struct SOLVERSTATS {
  unsigned int nStepsTaken;                 /* Number of steps taken by the solver */
  unsigned int nCallsODE;                   /* Number of calls on functionODE */
  unsigned int nCallsJacobian;              /* Number of evaluations of Jacobian */
  unsigned int nErrorTestFailures;          /* Number of error test failures */
  unsigned int nConvergenveTestFailures;    /* Number of convergence test failures */
} SOLVERSTATS;

/**
 * @brief Information and data needed by the ODE/DAE solver.
 */
typedef struct SOLVER_INFO
{
  double currentTime;
  double currentStepSize;
  double laststep;
  enum SOLVER_METHOD solverMethod;            /* ODE/DAE solver method */
  double solverStepSize;                      /* used by implicit radau solver */
                                              // TODO: This should be in radau solverData

  modelica_boolean solverRootFinding;         /* Set by solver if an internal root finding method is activated  */
  modelica_boolean solverNoEquidistantGrid;   /* Set by solver if output points are set by step size control */
  double lastdesiredStep;

  /* events */
  LIST* eventLst;
  int didEventStep;       /* Boolean stating if during the last step an event was encountered,
                           * Used to reinitialize ODE/DAE solver after event iteration */

  /* stats */
  unsigned long stateEvents;
  unsigned long sampleEvents;
  /* integrator stats */
  /* TODO: Change to SOLVERSTATS!!!! */
  unsigned int* solverStats;          /* Statistic for integrator */
  unsigned int* solverStatsTmp;       /* tmp solver stats to update solverStats with */

  /* further options */
  int integratorSteps;              /* 1 => stepSizeControl; 0 => equidistant grid */
                                    // TODO: This is a duplicate of solverNoEquidistantGrid set in DASSL/IDA/...

  void* solverData;     /* ODE/DAE solver data */
}SOLVER_INFO;

#ifdef __cplusplus
  extern "C" {
#endif

extern int solver_main(DATA* data, threadData_t *threadData, const char* init_initMethod,
    const char* init_file, double init_time,
    int solverID, const char* outputVariablesAtEnd, const char *argv_0);

/* Provide solver interface to interactive stuff */
extern int initializeSolverData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
extern int freeSolverData(DATA* data, SOLVER_INFO* solverInfo);

extern int initializeModel(DATA* data, threadData_t *threadData, const char* init_initMethod,
    const char* init_file, double init_time);

extern int finishSimulation(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, const char* outputVariablesAtEnd);

extern int solver_main_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

void checkTermination(DATA* data);

extern int stateSelection(DATA *data, threadData_t *threadData, char reportError, int switchStates);

#ifdef __cplusplus
  }
#endif

#endif
