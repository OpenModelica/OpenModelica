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
int _omc_hybrj_(int(*) (integer*, double*, double*, double *, integer*, integer*, void* data, int),
      integer *n,double*x,double*fvec,double*fjac,integer *ldfjac,double*xtol,integer* maxfev,
      double* diag,integer *mode,double*factor, integer *nprint,integer* info, integer* nfev, integer* njev,
      double* r, integer *lr,double*qtf,double*wa1,double*wa2,
      double* wa3,double* wa4, void* userdata, int sysNumber);

extern
int _omc_hybrd_(int (*) (integer*, double *, double*, integer*, void*),
      integer* n, double* x ,double* fvec, double* xtol,
      integer* maxfev, integer* ml, integer* mu, double* epsfcn, double* diag,
      integer* mode, double* factor, integer* nprint, integer* info, integer* nfev,
      double* fjac, double* fjacobian, integer* ldfjac, double* r__,
      integer* lr, double* qtf, double* wa1, double* wa2, double* wa3,
      double* wa4, void* userdata);

#ifdef __cplusplus
}
#endif


extern int allocateHybrdData(int size, void **data);
extern int freeHybrdData(void **data);
extern int solveHybrd(DATA *data, int sysNumber);

#endif

