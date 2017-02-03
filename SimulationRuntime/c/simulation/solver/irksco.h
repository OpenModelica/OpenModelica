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

/*! \file irksco.h
 */

#ifndef _IRKSCO_H_
#define _IRKSCO_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "omc_config.h"
#include "nonlinearSystem.h"

#include <math.h>

typedef struct DATA_IRKSCO{
  DATA* data;
  threadData_t *threadData;
  void* solverData;
  int order, ordersize;
  double *y0, *y05, *y1,*y2, *y3, *der_x0;
  double *A, *c, *d, *Ainv;
  double *m, *n;
  double *radauVarsOld, *radauVars;
  double *zeroCrossingValues;
  double *zeroCrossingValuesOld;
  double radauTime;
  double radauTimeOld;
  double radauStepSize, radauStepSizeOld;
  int firstStep;
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
  unsigned int evalJacobians;
}DATA_IRKSCO;


int allocateIrksco(SOLVER_INFO* solverInfo, int size, int zcSize);
int freeIrksco(SOLVER_INFO* solverInfo);
int irksco_richardson(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);
int irksco_midpoint_rule(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);


#endif /* _IRKSCO_H_ */
