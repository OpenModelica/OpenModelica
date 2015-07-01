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
#include "util/simulation_options.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef VOID
#undef VOID
#endif

typedef void* NLS_SOLVER_DATA;

int initializeNonlinearSystems(DATA *data);
int updateStaticDataOfNonlinearSystems(DATA *data);
int freeNonlinearSystems(DATA *data);
void printNonLinearSystemSolvingStatistics(DATA *data, int sysNumber, int logLevel);
int solve_nonlinear_system(DATA *data, int sysNumber);
int check_nonlinear_solutions(DATA *data, int printFailingSystems);
double extraPolate(DATA *data, const double old1, const double old2, const double minValue, const double maxValue);

#ifdef __cplusplus
}
#endif

#endif
