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

/*! \file ESDIRKMR.h
 */

#ifndef _ESDIRKMR_H_
#define _ESDIRKMR_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "omc_config.h"
#include "nonlinearSystem.h"

#include <math.h>

/* Butcher-Tableau ESDIRK2
   Implementation of  multirate  DIRK method  ESDIRK2(1)3L[2]SA
   (section 4.1.1 of the Carpenter & Kennedy NASA review) with
   variable time step. Uses embedded a-stable method of order 1
   for error estimation and Hermite interpolation for output on a fixed step mesh.

   0  | 0
   c2 | gam  gam
   1  | b1   b2   b3
   ---------------------
      | b1   b2   b3
      | bt1  bt2  bt3

   gam=(2-sqrt(2))*0.5;
   c2 = 2*gam;
   b1 = sqrt(2)/4; b2 = b1; b3 = gam;

   bt1 = 7/4-sqrt(2); bt2 = bt1; bt3 = 2*sqrt(2)-5/2;

   for error estimation:
   bh1=b1-bt1; bh2=b2-bt2; bh3=b3-bt3;
*/

typedef struct DATA_ESDIRKMR{
  DATA* data;
  threadData_t *threadData;
  void* solverData;
  double *y, *yt, *yOld, *f;
  double *Jf;
  double *k, *res_const;
  double *errest, *errtol;
  double time;
  double stepSize, lastStepSize;
  int stages, expl, act_stage;
  double *A, *c, *b, *bt;
  int nStates, order_b, order_bt, error_order;
  int firstStep, symJac, nlSystemSize;
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
  unsigned int errorTestFailures;
  unsigned int convergenceFailures;
  int (*step_fun)(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo);

}DATA_ESDIRKMR;


int allocateESDIRKMR(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
int freeESDIRKMR(SOLVER_INFO* solverInfo);
int esdirkmr_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#endif /* _ESDIRKMR_H_ */
