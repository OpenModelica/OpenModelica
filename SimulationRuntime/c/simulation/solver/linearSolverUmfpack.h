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

/*! \file linearSolverUmfpack.h
 */

#include "omc_config.h"

#ifdef WITH_UMFPACK
#ifndef _LINEARSOLVERUMFPACK_H_
#define _LINEARSOLVERUMFPACK_H_

#include "simulation_data.h"

#include "suitesparse/Include/umfpack.h"
#include "suitesparse/Include/umfpack_get_numeric.h"

typedef struct DATA_UMFPACK
{
  int *Ap;
  int *Ai;
  double *Ax;
  int n_col;
  int n_row;
  int nnz;
  void *symbolic, *numeric;
  double control[UMFPACK_CONTROL], info[UMFPACK_INFO];

  int col_akt;
  int akt;

  double* work;

  int* Wi;
  double* W;

  rtclock_t timeClock;             /* time clock */
  int numberSolving;

} DATA_UMFPACK;

int allocateUmfPackData(int n_row, int n_col, int nz, void **data);
int freeUmfPackData(void **data);
int solveUmfPack(DATA *data, threadData_t *threadData, int sysNumber);

#endif
#endif
