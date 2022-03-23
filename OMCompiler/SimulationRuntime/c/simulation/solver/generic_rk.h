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
#include "omc_config.h"
#include "nonlinearSystem.h"

#include <math.h>

typedef struct DATA_GENERIC_RK{
  DATA* data;
  threadData_t *threadData;
  void* solverData;
  double *y, *yt, *yOld, *f;
  double *Jf;
  double *k, *res_const;
  double *errest, *errtol, fac;
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

}DATA_GENERIC_RK;


int allocateDataGenericRK(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
int freeDataGenericRK(SOLVER_INFO* solverInfo);
int genericRK_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);

#endif /* _DATA_GENERIC_RK_H_ */
