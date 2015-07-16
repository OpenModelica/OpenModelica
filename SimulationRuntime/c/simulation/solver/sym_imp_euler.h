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

/*! \file sym_imp_euler.h
 */

#ifndef _SYM_IMP_EULER_H_
#define _SYM_IMP_EULER_H_

#include "simulation_data.h"
#include "solver_main.h"
#include "omc_config.h"

#include <math.h>

typedef struct DATA_SYM_IMP_EULER{
  void* data;
  void* solverData;
  double *y05, *y1,*y2;
  double *radauVarsOld, *radauVars;
  double radauTime;
  double radauTimeOld;
  double radauStepSize, radauStepSizeOld;
  int firstStep;
  unsigned int stepsDone;
  unsigned int evalFunctionODE;
}DATA_SYM_IMP_EULER;


int allocateSymEulerImp(SOLVER_INFO* solverInfo, int size);
int freeSymEulerImp(SOLVER_INFO* solverInfo);
int sym_euler_im_with_step_size_control_step(DATA* data, SOLVER_INFO* solverInfo);


#endif /* _SYM_IMP_EULER_H_ */
