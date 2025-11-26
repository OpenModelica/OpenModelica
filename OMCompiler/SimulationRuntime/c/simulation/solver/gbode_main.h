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

/*! \filegbode_main.h
 */

#ifndef _DATA_GBODE_H_
#define _DATA_GBODE_H_

#include <float.h>
#include <math.h>
#include <string.h>

#include "gbode_tableau.h"
#include "gbode_conf.h"

#include "../../simulation_data.h"
#include "../jacobian_util.h"
#include "../../util/omc_error.h"
#include "../../util/omc_file.h"
#include "../../util/simulation_options.h"
#include "../../util/varinfo.h"
#include "../results/simulation_result.h"
#include "epsilon.h"
#include "jacobianSymbolical.h"
#include "model_help.h"
#include "newtonIteration.h"
#include "nonlinearSystem.h"
#include "solver_main.h"

#ifdef __cplusplus
extern "C" {
#endif

/**
 * @brief Function to compute single-rate step.
 */
typedef int (*gm_step_function)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

typedef struct DATA_GBODEF{
  enum GB_METHOD GM_method;                         /* Method to use for integration. */
  enum GM_TYPE type;                                /* Type of GB method */
  enum GB_NLS_METHOD nlsSolverMethod;               /* Non-linear solver method uses by generic RK method. */
  NONLINEAR_SYSTEM_DATA* nlsData;                   /* Non-linear system
                                                     * Something like
                                                     *  0 = yold-x + h*(sum(A[i,j]*k[j], j=1..i-1) + A[i,i]*f(t + c[i]*h, x))
                                                     * */
  JACOBIAN* jacobian;                               /* Jacobian of non-linear system of implicit Runge-Kutta method */
  SPARSE_PATTERN* sparsePattern_DIRK;               /* Sparsity pattern for the DIRK methd, will be reduced based on the fast states selection */

  double *y;                                        /* State vector of the current Runge-Kutta step */
  double *yt, *y1;                                  /* Result vector of the states of embedded RK step */
  double *yLeft, *kLeft, *yRight, *kRight;          /* Needed for interpolation of the slow states and emitting to the result files */
  double *yOld;                                     /* State vector of last Runge-Kutta step */
  double *f;                                        /* State derivatives of ODE for initialization */
  double *k;                                        /* Vector k of derivatives of states with result of intermediate steps of Runge-Kutta method */
  double *x;                                        /* Vector x of states with result of intermediate steps of Runge-Kutta method */
                                                        // k_{i}=f(t_{n}+c_{i}*h, y_{n}+h\sum _{j=1}^{s}a_{ij}*k_{j}),    i=1, ... ,s
  double *yv, *kv, *tv;                             /* Buffer storage of the last values of states (yv) and their derivatives (kv) */
  double *res_const;                                /* Constant parts of residual for non-linear system of implicit RK method. */
  double *errest, *errtol;                          /* absolute error and given error tolerance of each individual states */
  double *err;                                      /* error of each individual state during integration err = errest/errtol*/
  double *errValues;                                /* ring buffer for step size control */
  double *stepSizeValues;                           /* ring buffer for step size control */

  double time, timeLeft, timeRight, eventTime;      /* actual time values and the time values of the current interpolation interval */
  double stepSize, lastStepSize;                    /* actual and last step size of integration */
  int act_stage;                                    /* Current stage of Runge-Kutta method. */
  enum GB_CTRL_METHOD ctrl_method;                  /* Step size control algorithm */
  modelica_boolean isExplicit;                      /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;                         /* Butcher tableau of the Runge-Kutta method */
  int nStates;                                      /* Numbers of fast states */
  int nFastStates, nFastStates_old;                 /* Numbers of fast states, old values for comparison and update of sparsity pattern */
  int nSlowStates;                                  /* Numbers of slow states */
  int *fastStatesIdx, *fastStates_old;              /* Indices of fast states, old values for comparison and update of sparsity pattern */
  int *slowStatesIdx;                               /* Indices of slow states */

  modelica_boolean didEventStep;                    /* Will be used for updating the derivatives */
  int ringBufferSize;                               /* Buffer size for storing the error, stepSize and last values of states (yv) and their derivatives (kv) */
  enum GB_INTERPOL_METHOD interpolation;            /* Interpolation method */
  unsigned int nlSystemSize;                        /* Size of non-linear system to solve in a RK step. */
  modelica_boolean symJacAvailable;                 /* Boolean stating if a symbolic Jacobian is available */
  gm_step_function step_fun;                        /* Step function of the integrator */

  FILE *fastStatesDebugFile;                        /* File pointer for debugging the integration process with respect to slow and fast states */

  /* statistics */
  SOLVERSTATS stats;
} DATA_GBODEF;

typedef struct DATA_GBODE{
  DATA_GBODEF* gbfData;                             /* Data object of the fast states integrator */
  enum GB_METHOD GM_method;                         /* Method to use for integration. */
  enum GM_TYPE type;                                /* Type of GB method */
  enum GB_NLS_METHOD nlsSolverMethod;               /* Non-linear solver method uses by generic RK method. */
  NONLINEAR_SYSTEM_DATA* nlsData;                   /* Non-linear system
                                                     * Something like
                                                     *  0 = yold-x + h*(sum(A[i,j]*k[j], j=1..i-1) + A[i,i]*f(t + c[i]*h, x))
                                                     * */
  JACOBIAN* jacobian;                               /* Jacobian of non-linear system of implicit Runge-Kutta method */
  double *y;                                        /* State vector of the current Runge-Kutta step */
  double *yt, *y1, *y2;                             /* Result vector of the states of embedded RK step */
  double *yLeft, *kLeft, *yRight, *kRight;          /* Needed for interpolation of the slow states and emitting to the result files */
  double *yOld;                                     /* State vector of last Runge-Kutta step */
  double *f;                                        /* State derivatives of ODE for initialization */
  double *yLast;                                    /* Vector y of states at start of previous interval */
  double *kLast;                                    /* Vector k of stage updates for the previous interval */
  double *k;                                        /* Vector k of derivatives of states with result of intermediate steps of Runge-Kutta method */
  double *x;                                        /* Vector x of states with result of intermediate steps of Runge-Kutta method */
                                                        // k_{i}=f(t_{n}+c_{i}*h, y_{n}+h\sum _{j=1}^{s}a_{ij}*k_{j}),    i=1, ... ,s
  double *yv, *kv, *tv;                             /* Buffer storage of the last values of states (yv) and their derivatives (kv) */
  double *yr, *kr, *tr;                             /* Backup storage of the buffers yv, kv, tv for Richardson extrapolation */
  double *res_const;                                /* Constant parts of residual for non-linear system of implicit RK method. */
  double *errest;                                   /* Absolute error estimator of each individual state */
  double *errtol;                                   /* Given error tolerance of each individual state */
  double *err;                                      /* error of each individual state during integration err = errest/errtol*/
  double *errValues;                                /* ring buffer for step size control */
  double *stepSizeValues;                           /* ring buffer for step size control */
  double err_slow, err_fast, err_int;               /* error of the slow, fast states and a preiction of the interpolation error */
  double percentage;                                /* percentage of fast states */
  double time, timeLeft, timeRight, eventTime;      /* actual time values and the time values of the current interpolation interval and for dense output */
  double extrapolationStepSize;                     /* last step size for extrapolation / in sync with yLast and kLast */
  double extrapolationBaseTime;                     /* base time for extrapolation / in sync with yLast and kLast */
  double stepSize, lastStepSize, optStepSize;       /* actual, last, and optimal step size of integration */
  double maxStepSize;                               /* maximal step size of integration */
  double initialStepSize;                           /* initial step size of integration */
  modelica_boolean noRestart;                       /* Flag for omitting re-start after an event occured */
  int act_stage;                                    /* Current stage of Runge-Kutta method. */
  enum GB_CTRL_METHOD ctrl_method;                  /* Step size control algorithm */
  int ringBufferSize;                               /* Buffer size for storing the error, stepSize and last values of states (yv) and their derivatives (kv) */
  modelica_boolean multi_rate;                      /* Flag for the birate mode */
  enum GB_INTERPOL_METHOD interpolation;            /* Interpolation method */
  modelica_boolean isExplicit;                      /* Boolean stating if the RK method is explicit */
  BUTCHER_TABLEAU* tableau;                         /* Butcher tableau of the Runge-Kutta method */
  int initialFailures;                              /* Counts asserts during initialization in order to reduce first tried step size */
  int nStates;                                      /* Numbers of fast states */
  int nFastStates;                                  /* Numbers of fast states */
  int nSlowStates;                                  /* Numbers of slow states */
  int *fastStatesIdx;                               /* Indices of fast states */
  int *slowStatesIdx;                               /* Indices of slow states */
  int *sortedStatesIdx;                             /* Indices of all states sorted for highest error */
  modelica_boolean isFirstStep;                     /* True during first Runge-Kutta integrator step, false otherwise */
  unsigned int nlSystemSize;                        /* Size of non-linear system to solve in a RK step. */
  modelica_boolean symJacAvailable;                 /* Boolean stating if a symbolic Jacobian is available */
  gm_step_function step_fun;                        /* Step function of the integrator */

  /* statistics */
  SOLVERSTATS stats;
} DATA_GBODE;

void gbode_fODE(DATA *data, threadData_t *threadData, unsigned int* counter);
int gbode_allocateData(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
void gbode_freeData(DATA* data, DATA_GBODE *gbData);
int gbode_main(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#ifdef __cplusplus
};
#endif

#endif /* _DATA_GBODE_H_ */
