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

/*! \file sym_solver_ssc.h
 */

#ifndef _SYM_SOLVER_SSC_H_
#define _SYM_SOLVER_SSC_H_

#include "../../simulation_data.h"
#include "solver_main.h"

#include <math.h>

typedef struct DATA_SYM_SOLVER_SSC{
  void* data;
  void* solverData;
  double *y05, *y1,*y2;
  double *radauVarsOld, *radauVars, *der_x0;
  double radauTime;
  double radauTimeOld;
  double radauStepSize, radauStepSizeOld;
  double solverStepSize;
  int firstStep;
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
} DATA_SYM_SOLVER_SSC;


int allocateSymSolverSsc(SOLVER_INFO* solverInfo, int size);
int freeSymSolverSsc(SOLVER_INFO* solverInfo);
int sym_solver_ssc_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);


#endif /* _SYM_SOLVER_SSC_H_ */
