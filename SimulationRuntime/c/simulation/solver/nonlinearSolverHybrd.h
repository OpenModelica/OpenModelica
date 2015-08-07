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

/*! \file nonlinearSolverHybrd.h
 */

#ifndef _NONLINEARSOLVERHYBRD_H_
#define _NONLINEARSOLVERHYBRD_H_

#include "simulation_data.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef VOID
#undef VOID
#endif

extern
int hybrj_( int(*) (const integer*, const double*, double*, double *, const integer*, const integer*, void*),  const integer *n, double *x, double *fvec, double *fjac, const integer *ldfjac,
  const double *xtol, const integer *axfev, double *diag, const integer *mode,
  const double *factor, const integer *nprint, integer *info, integer *nfev, integer *njev,
  double *r, integer *lr, double *qtf, double *wa1, double *wa2,
  double *wa3, double *wa4, void* user_data);

extern int allocateHybrdData(int size, void **data);
extern int freeHybrdData(void **data);
extern int solveHybrd(DATA *data, threadData_t *threadData, int sysNumber);


typedef struct DATA_HYBRD
{
  int initialized; /* 1 = initialized, else = 0*/
  double* resScaling;
  int useXScaling;
  double* xScalefactors;
  double* fvecScaled;

  integer n;
  double* x;
  double* xSave;
  double* xScaled;
  double* fvec;
  double* fvecSave;
  double xtol;
  integer maxfev;
  int ml;
  int mu;
  double epsfcn;
  double* diag;
  double* diagres;
  integer mode;
  double factor;
  integer nprint;
  integer info;
  integer nfev;
  integer njev;
  double* fjac;
  double* fjacobian;
  integer ldfjac;
  double* r__;
  integer lr;
  double* qtf;
  double* wa1;
  double* wa2;
  double* wa3;
  double* wa4;

  unsigned int numberOfIterations; /* over the whole simulation time */
  unsigned int numberOfFunctionEvaluations; /* over the whole simulation time */

} DATA_HYBRD;

#ifdef __cplusplus
}
#endif

#endif

