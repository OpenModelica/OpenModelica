/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

/*! \file nonlinearSystem.h
 */


#ifndef _NONLINEARSYSTEM_H_
#define _NONLINEARSYSTEM_H_

#include "simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef VOID
#undef VOID
#endif

enum NONLINEAR_SOLVER
{
  NLS_NONE = 0,
  
  NLS_HYBRID,
  NLS_KINSOL,
  NLS_NEWTON,
  
  NLS_MAX
};


extern const char *NLS_NAME[NLS_MAX+1];
extern const char *NLS_DESC[NLS_MAX+1];

typedef void* NLS_SOLVER_DATA;

int allocateNonlinearSystem(DATA *data);
int freeNonlinearSystem(DATA *data);
int solve_nonlinear_system(DATA *data, int sysNumber);
int check_nonlinear_solutions(DATA *data, int printFailingSystems);
double extraPolate(DATA *data, double old1, double old2);

#ifdef __cplusplus
}
#endif

#endif
