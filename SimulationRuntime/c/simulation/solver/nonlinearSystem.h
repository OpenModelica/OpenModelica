/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
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

#ifdef __cplusplus
}
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

/* nonlinear JumpBuffer */
extern jmp_buf nonlinearJmpbuf;

#endif
