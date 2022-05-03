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

/*! \file DATA_GENERIC_RK_MR.h
 */

#ifndef _DATA_GENERIC_RK_MR_H_
#define _DATA_GENERIC_RK_MR_H_

#include "simulation_data.h"
#include "solver_main.h"

#include "rk_butcher.h"
#include "generic_rk.h"

/**
 * @brief Function to compute single Runge-Kutta step.
 */
typedef int (*rk_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
typedef double (*rk_stepSize_control_function)(double* err_values, double err_order);

typedef struct DATA_GENERIC_RK_MR{
  DATA* data;                   // TODO AHeu: Can we get around having data and threadData inside this struct?
  threadData_t *threadData;     //            I'm afraid not...
  enum RK_SINGLERATE_METHOD RK_method;  /* Runge-Kutta method to use. */
  enum RK_type type;                    /* Type of RK method */
  enum RK_NLS_METHOD nlsSolverMethod;   /* Non-linear solver method uses by generic RK method. */
  void* nlsSolverData;                  /* Nonlinear solver data */
  double *y, *yt, *yOld, *f, *yStart, *yEnd;
  double *Jf;
  double *k, *res_const;
  double *errest, *errtol, *err, err_new, err_old;
  double time, startTime, endTime;
  double stepSize, lastStepSize, stepSize_old;
  int act_stage;
  modelica_boolean isExplicit;        /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;
  int nStates, nFastStates, nSlowStates, *fastStates, *slowStates;
  int firstStep;
  unsigned int nlSystemSize;          /* Size of non-linear system to solve in a RK step */
  modelica_boolean symJacAvailable;   /* Boolean stating if a symbolic Jacobian is available */
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
  unsigned int errorTestFailures;
  unsigned int convergenceFailures;
  rk_step_function step_fun;
  rk_stepSize_control_function stepSize_control;
} DATA_GENERIC_RK_MR;

void freeDataGenericRK_MR(DATA_GENERIC_RK_MR* data);
int genericRK_MR_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, double targetTime);
//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void linear_interpolation_MR(double a, double* fa, double b, double* fb, double t, double *f, int nIdx, int* indx);
void printVector_genericRK_MR(char name[], double* a, int n, double time, int nIndx, int* indx);
void printMatrix_genericRK_MR(char name[], double* a, int n, double time);
void copyVector_genericRK_MR(double* a, double* b, int nIndx, int* indx);



#endif /* _DATA_GENERIC_RK_MR_H_ */
