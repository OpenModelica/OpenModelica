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
int hybrj_( int(*) (const int*, const double*, double*, double *, const int*, const int*, void*),  const int *n, double *x, double *fvec, double *fjac, const int *ldfjac,
  const double *xtol, const int *axfev, double *diag, const int *mode,
  const double *factor, const int *nprint, int *info, int *nfev, int *njev,
  double *r, int *lr, double *qtf, double *wa1, double *wa2, 
  double *wa3, double *wa4, void* user_data);

#ifdef __cplusplus
}
#endif


extern int allocateHybrdData(int size, void **data);
extern int freeHybrdData(void **data);
extern int solveHybrd(DATA *data, int sysNumber);

#endif

