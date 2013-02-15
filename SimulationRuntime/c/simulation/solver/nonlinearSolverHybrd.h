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

#include "blaswrap.h"
#include "f2c.h"
#ifdef VOID
#undef VOID
#endif

extern
void * _omc_hybrj_(void(*) (integer*, double*, double*, double *, int*, int*, void* data),
      integer *n,double*x,double*fvec,double*fjac,int *ldfjac,double*xtol,int* maxfev,
      double* diag,int *mode,double*factor,int *nprint,int*info,int*nfev,int*njev,
      double* r,int *lr,double*qtf,double*wa1,double*wa2,
      double* wa3,double* wa4, void* userdata);

extern
void _omc_hybrd_(void (*) (integer*, double *, double*, int*, void*),
      integer* n, double* x ,double* fvec, double* xtol,
      int* maxfev, int* ml, int* mu, double* epsfcn, double* diag,
      int* mode, double* factor, int* nprint, int* info, int* nfev,
      double* fjac, double* fjacobian, int* ldfjac, double* r__,
      int* lr, double* qtf, double* wa1, double* wa2, double* wa3,
      double* wa4, void* userdata);

#ifdef __cplusplus
}
#endif


extern int allocateHybrdData(int size, void **data);
extern int freeHybrdData(void **data);
extern int solveHybrd(DATA *data, int sysNumber);

#endif

