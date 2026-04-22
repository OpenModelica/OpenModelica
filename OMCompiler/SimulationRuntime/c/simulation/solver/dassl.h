/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef DASSL_H
#define DASSL_H

#include "solver_main.h"

#define DDASKR _daskr_ddaskr_

static const unsigned int maxOrder = 5;
static const unsigned int infoLength = 20;

typedef struct DASSL_DATA{

  int dasslSteps;               /* if TRUE then dassl internal steps are used to store results */
  unsigned int dasslStepsFreq;  /* value specifies the output frequency regarding to time steps. Used in dasslSteps mode. */
  double dasslStepsTime;        /* value specifies the time increment when output happens. Used in dasslSteps mode. */
  int dasslRootFinding;         /* if TRUE then the internal root finding is used */
  int dasslJacobian;            /* specifies the method to calculate the jacobian matrix */
  int dasslAvoidEventRestart;   /* if TRUE then no restart after an event is performed */

  long N;
  int* info;

  int idid;
  int* ipar;
  double** rpar;
  /* size of work arrays for DASSL */
  int liw;
  int lrw;
  /* work arrays for DASSL */
  int *iwork;
  double *rwork;
  double *rtol;
  double *atol;

  int ng;
  int *jroot;

  /* variables used in jacobian calculation */
  double *ysave;
  double *delta_hh;
  double *newdelta;
  double *stateDer;
  double *states;

  /* function pointer of provided functions */
  int (*residualFunction)(double *t, double *y, double *yd, double *cj,
                         double *delta, int *ires, double *rpar, int *ipar);
  int (*jacobianFunction)(double *t, double *y, double *yprime, double *deltaD,
                          double *pd, double *cj, double *h, double *wt,
                          double *rpar, int* ipar);
  void* zeroCrossingFunction;

#ifdef USE_PARJAC
  JACOBIAN* jacColumns;         /* thread local analytic jacobians */
#endif
  int allocatedParMem;          /* indicated if parallel memory was allocated, 0=false, 1=true*/
} DASSL_DATA;

/* main dassl function to make a step */
int dassl_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

/* initial main dassl Data */
int dassl_initial(DATA* data, threadData_t *threadData,
                  SOLVER_INFO* solverInfo, DASSL_DATA *dasslData);

/* deinitial main dassl Data */
int dassl_deinitial(DATA* data, DASSL_DATA *dasslData);

int printCurrentStatesVector(int logLevel, double* states, DATA* data, double time);
int printVector(int logLevel, const char* name,  double* vec, int n, double time);

#endif
