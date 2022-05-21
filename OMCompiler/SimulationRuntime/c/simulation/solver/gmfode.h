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

/*! \file DATA_GMF.h
 */

#ifndef _DATA_GMF_H_
#define _DATA_GMF_H_

#include "simulation_data.h"
#include "solver_main.h"

#include "gm_tableau.h"
#include "gmode.h"

/**
 * @brief Function to compute single Runge-Kutta step.
 */
typedef int (*rk_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
typedef double (*rk_stepSize_control_function)(double* err_values, double* stepSize_values, double err_order);

typedef struct DATA_GMF{
  DATA* data;                   // TODO AHeu: Can we get around having data and threadData inside this struct?
  threadData_t *threadData;     //            I'm afraid not...
  enum GM_SINGLERATE_METHOD GM_method;  /* Runge-Kutta method to use. */
  enum GM_type type;                    /* Type of RK method */
  enum GM_NLS_METHOD nlsSolverMethod;   /* Non-linear solver method uses by generic RK method. */
  NONLINEAR_SYSTEM_DATA* nlsData;       /* Non-linear system
                                         * Something like
                                         *  0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
                                         * */
  ANALYTIC_JACOBIAN* jacobian;

  void* nlsSolverData;

  double *y, *yt, *yOld, *f, *yStart, *yEnd;
  double *Jf;
  double *k, *res_const;
  double *x;                            /* ring buffer for multistep method */

  double *errest, *errtol, *err;
  double *errValues;                    /* ring buffer for step size control */
  double *stepSizeValues;               /* ring buffer for step size control */
  double time, startTime, endTime;
  double stepSize, lastStepSize, stepSize_old;
  int act_stage;
  modelica_boolean isExplicit;        /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;
  int nStates, nFastStates, nSlowStates, *fastStates, *slowStates;
  int nFastStates_old, *fastStates_old;
  int firstStep;
  int didEventStep;                   /* Will be used for updating the derivatives */
  int ringBufferSize;
  unsigned int nlSystemSize;          /* Size of non-linear system to solve in a RK step */
  modelica_boolean symJacAvailable;   /* Boolean stating if a symbolic Jacobian is available */
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
  unsigned int errorTestFailures;
  unsigned int convergenceFailures;
  rk_step_function step_fun;
  rk_stepSize_control_function stepSize_control;
} DATA_GMF;

void freeDatagmf(DATA_GMF* data);
int gmf_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, double targetTime);
//auxiliary vector functions
void linear_interpolation(double a, double* fa, double b, double* fb, double t, double *f, int n);
void linear_interpolation_MR(double a, double* fa, double b, double* fb, double t, double *f, int nIdx, int* indx);
void printVector_gmf(char name[], double* a, int n, double time, int nIndx, int* indx);
void printMatrix_gmf(char name[], double* a, int n, double time);
void copyVector_gmf(double* a, double* b, int nIndx, int* indx);



#endif /* _DATA_GMF_H_ */
