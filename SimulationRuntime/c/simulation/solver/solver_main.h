/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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
#include "list.h"

typedef struct SOLVER_INFO
{
  double currentTime;
  double currentStepSize;
  double laststep;
  double offset;
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

  enum SOLVER_METHOD
  {
    S_UNKNOWN = 0,
    
    S_EULER,         /*  1 */
    S_RUNGEKUTTA,    /*  2 */
    S_DASSL,         /*  3 */
    S_INLINE_EULER,  /*  4 */
    S_OPTIMIZATION,  /*  5 */
    S_RADAU5,        /*  6 */
    S_RADAU3,        /*  7 */
    S_RADAU1,        /*  8 */
    S_LOBATTO2,      /*  9 */
    S_LOBATTO4,      /* 10 */
    S_LOBATTO6,      /* 11 */
    S_DASSLWORT,
    S_DASSLTEST,
    S_DASSLSYMJAC,
    S_DASSLNUMJAC,
    S_DASSLCOLORSYMJAC,
    S_DASSLINTERNALNUMJAC,
    S_INLINE_RUNGEKUTTA,
    S_QSS,
    
    S_MAX
  };

  static const char *SOLVER_METHOD_NAME[S_MAX] = {
    "unknown",
    "euler",
    "rungekutta",
    "dassl",
    "inline-euler",
    "optimization",
    "radau5",
    "radau3",
    "radau1",
    "lobatto2",
    "lobatto4",
    "lobatto6",
    "dasslwort",
    "dassltest",
    "dasslSymJac",
    "dasslNumJac",
    "dasslColorSymJac",
    "dasslInternalNumJac",
    "inline-rungekutta",
    "qss"
  };
  static const char *SOLVER_METHOD_DESC[S_MAX] = {
    "unknown",
    "euler",
    "rungekutta",
    "dassl with colored numerical jacobian, with interval root finding - default",
    "inline-euler",
    "optimization",
    "radau5 [sundial/kinsol needed]",
    "radau3 [sundial/kinsol needed]",
    "radau1 [sundial/kinsol needed]",
    "lobatto2 [sundial/kinsol needed]",
    "lobatto4 [sundial/kinsol needed]",
    "lobatto6 [sundial/kinsol needed]",
    "dassl without internal root finding",
    "dassl for debug propose",
    "dassl with symbolic jacobian",
    "dassl with numerical jacobian",
    "dassl with colored symbolic jacobian",
    "dassl with internal numerical jacobian",
    "inline-rungekutta",
    "qss"
  };

extern int solver_main(DATA* data, const char* init_initMethod,
    const char* init_optiMethod, const char* init_file, double init_time,
    int lambda_steps, int solverID, const char* outputVariablesAtEnd);

/* Provide solver interface to interactive stuff */
extern int initializeSolverData(DATA* data, SOLVER_INFO* solverInfo);
extern int freeSolverData(DATA* data, SOLVER_INFO* solverInfo);

extern int freeSolverData(DATA* data, SOLVER_INFO* solverInfo);

extern int initializeModel(DATA* data, const char* init_initMethod,
    const char* init_optiMethod, const char* init_file, double init_time,
    int lambda_steps);

/* Defined in perform_simulation.c and omp_perform_simulation.c */
extern int performSimulation(DATA* data, SOLVER_INFO* solverInfo);

extern int finishSimulation(DATA* data, SOLVER_INFO* solverInfo, const char* outputVariablesAtEnd);

extern int solver_main_step(DATA* data, SOLVER_INFO* solverInfo);

void checkTermination(DATA* data);

extern int stateSelection(DATA *data, char reportError, int switchStates);

#ifdef __cplusplus
  }
#endif

#endif
