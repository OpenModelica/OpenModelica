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

/*! \file DATA_GENERIC_RK.h
 */

#ifndef _DATA_GENERIC_RK_H_
#define _DATA_GENERIC_RK_H_

#include "simulation_data.h"
#include "solver_main.h"

#include "rk_butcher.h"

/**
 * @brief Function to compute single Runge-Kutta step.
 */
typedef int (*rk_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

typedef struct DATA_GENERIC_RK{
  DATA* data;                   // TODO AHeu: Can we get around having data and threadData inside this struct?
  threadData_t *threadData;     //            I'm afraid not...
  enum RK_SINGLERATE_METHOD RK_method;  /* Runge-Kutta method to use. */
  enum RK_NLS_METHOD nlsSolverMethod;   /* Non-linear solver method uses by generic RK method. */
  void* nlsSolverData;                  /* Nonlinear solver data */
  double *y, *yt, *yOld, *f;
  double *Jf;
  double *k, *res_const;
  double *errest, *errtol;
  double time;
  double stepSize, lastStepSize;
  int act_stage;
  modelica_boolean isExplicit;        /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;
  int nStates;
  int firstStep;
  unsigned int nlSystemSize;          /* Size of non-linear system to solve in a RK step */
  modelica_boolean symJacAvailable;   /* Boolean stating if a symbolic Jacobian is available */
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
  unsigned int errorTestFailures;
  unsigned int convergenceFailures;
  rk_step_function step_fun;
} DATA_GENERIC_RK;

enum RK_SINGLERATE_METHOD getRK_Method();
enum RK_NLS_METHOD getRK_NLS_Method();
int allocateDataGenericRK(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
void freeDataGenericRK(DATA_GENERIC_RK* data);
int genericRK_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#endif /* _DATA_GENERIC_RK_H_ */
