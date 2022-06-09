/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Linköpings University,
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

/*! \file DATA_GBODE.h
 */

#ifndef _DATA_GBODE_H_
#define _DATA_GBODE_H_

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif

#include <float.h>
#include <math.h>
#include <string.h>

#include "gbode_tableau.h"
#include "gbode_util.h"

#include "epsilon.h"
#include "external_input.h"
#include "jacobianSymbolical.h"
#include "kinsolSolver.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "../../simulation_data.h"
#include "../results/simulation_result.h"
#include "solver_main.h"
#include "../../util/jacobian_util.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "../../util/simulation_options.h"
#include "../../util/varinfo.h"

/**
 * @brief Function to compute single-rate step.
 */
typedef int (*gm_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);
typedef double (*gm_stepSize_control_function)(double* err_values, double* stepSize_values, double err_order);

typedef struct DATA_GBODEF{
  enum GB_SINGLERATE_METHOD GM_method;        /* Runge-Kutta method to use. */
  enum GM_TYPE type;                          /* Type of RK method */
  enum GB_NLS_METHOD nlsSolverMethod;         /* Non-linear solver method uses by generic RK method. */

  NONLINEAR_SYSTEM_DATA* nlsData;             /* Non-linear system
                                               * Something like
                                               *  0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
                                               * */
  ANALYTIC_JACOBIAN* jacobian;
  SPARSE_PATTERN* sparesPattern_DIRK;

  void* nlsSolverData;

  double *y, *yt, *yOld, *f;
  double *yStart, *yEnd, *kStart, *kEnd;
  double *yLeft, *kLeft, *yRight, *kRight;
  double *Jf;
  double *k, *res_const;
  double *x;                            /* ring buffer for multistep method */

  double *errest, *errtol, *err;
  double *errValues;                    /* ring buffer for step size control */
  double *stepSizeValues;               /* ring buffer for step size control */
  double time, startTime, endTime;
  double timeLeft, timeRight;
  double stepSize, lastStepSize, stepSize_old;
  int act_stage;
  modelica_boolean isExplicit;        /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;
  int nStates, nFastStates, nSlowStates, *fastStates, *slowStates;
  int nFastStates_old, *fastStates_old;
  modelica_boolean stepRejected;
  modelica_boolean firstStep;
  modelica_boolean didEventStep;                   /* Will be used for updating the derivatives */
  int ringBufferSize;
  int interpolation;
  unsigned int nlSystemSize;          /* Size of non-linear system to solve in a RK step */
  modelica_boolean symJacAvailable;   /* Boolean stating if a symbolic Jacobian is available */
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
  unsigned int errorTestFailures;
  unsigned int convergenceFailures;
  FILE *fastStatesDebugFile;
  gm_step_function step_fun;
  gm_stepSize_control_function stepSize_control;
} DATA_GBODEF;

typedef struct DATA_GBODE{
  DATA_GBODEF* gbfData;
  enum GB_SINGLERATE_METHOD GM_method;  /* method to use for fast states integration. */
  enum GM_TYPE type;                    /* Type of GM method */
  enum GB_NLS_METHOD nlsSolverMethod;   /* Non-linear solver method uses by generic RK method. */
  NONLINEAR_SYSTEM_DATA* nlsData;       /* Non-linear system
                                         * Something like
                                         *  0 = yold-x + h*(sum(A[i,j]*k[j], i=j..i-1) + A[i,i]*f(t + c[i]*h, x))
                                         * */
  ANALYTIC_JACOBIAN* jacobian;
  double *y;                               /* Result vector of RK step */
  double *yt;                              /* Result vector of embedded RK step */
  double *yLeft, *kLeft, *yRight, *kRight; /* Needed for interpolation of the slow states */
  double *nlsxLeft, *nlsxRight;
  double *nlskLeft, *nlskRight;
  double *yOld;                            /* Result vector of last RK step ???? */
  double *f;                               /* State derivatives of ODE */
  double *Jf;
  double *k;                               /* Vector k with result of intermediate steps of Runge-Kutta method */
  double *x;                               /* ring buffer for multistep method */
                                           // k_{i}=f(t_{n}+c_{i}*h, y_{n}+h\sum _{j=1}^{s}a_{ij}*k_{j}),    i=1, ... ,s
  double *res_const;                       /* Constant parts of residual for non-linear system of implicit RK method. */
  double *errest, *errtol;
  double *err;
  double *errValues;                       /* ring buffer for step size control */
  double *stepSizeValues;                  /* ring buffer for step size control */
  double err_slow, err_fast, percentage, err_threshold;
  double time, timeLeft, timeRight;
  double stepSize, lastStepSize;
  double stepSize_old, stepSize_fast;
  int act_stage;                          /* Current stage of Runge-Kutta method. */
  modelica_boolean didEventStep;                       /* will be used for updating the derivatives */
  int ringBufferSize;
  int multi_rate_phase;
  modelica_boolean multi_rate;
  int interpolation;
  modelica_boolean isExplicit;            /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;
  int nStates;
  int nFastStates, nSlowStates;
  int *fastStates;
  int *slowStates;
  int *sortedStates;
  modelica_boolean stepRejected;
  modelica_boolean isFirstStep;       /* True during first Runge-Kutta integrator step, false otherwise */
  unsigned int nlSystemSize;          /* Size of non-linear system to solve in a RK step. */
  modelica_boolean symJacAvailable;   /* Boolean stating if a symbolic Jacobian is available */

  gm_step_function step_fun;
  gm_stepSize_control_function stepSize_control;

  /* statistics */
  // TODO AHeu: Duplicate of SOLVERSTATS
  unsigned int stepsDone;             /* Total number of integrator steps */
  unsigned int evalFunctionODE;       /* Total number of functionODE() calls */
  unsigned int evalJacobians;         /* Total number of Jacobian evaluations */
  unsigned int errorTestFailures;     /* Total number of error test failures */
  unsigned int convergenceFailures;   /* Total number of convergence failures */
} DATA_GBODE;

int gbode_allocateData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
void gbode_freeData(DATA_GBODE* data);
int gbode_main(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#endif /* _DATA_GBODE_H_ */
