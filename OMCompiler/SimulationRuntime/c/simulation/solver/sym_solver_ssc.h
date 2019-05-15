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

/*! \file sym_solver_ssc.h
 */

#ifndef _SYM_SOLVER_SSC_H_
#define _SYM_SOLVER_SSC_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "omc_config.h"

#include <math.h>

typedef struct DATA_SYM_SOLVER_SSC{
  void* data;
  void* solverData;
  double *y05, *y1,*y2;
  double *radauVarsOld, *radauVars, *der_x0;
  double radauTime;
  double radauTimeOld;
  double radauStepSize, radauStepSizeOld;
  int firstStep;
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
}DATA_SYM_SOLVER_SSC;


int allocateSymSolverSsc(SOLVER_INFO* solverInfo, int size);
int freeSymSolverSsc(SOLVER_INFO* solverInfo);
int sym_solver_ssc_step(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo);


#endif /* _SYM_SOLVER_SSC_H_ */
