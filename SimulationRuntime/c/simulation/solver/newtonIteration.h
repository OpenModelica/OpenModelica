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

/*! \file nonlinearSolverNewton.h
 */

#ifndef _NEWTONITERATION_H_
#define _NEWTONITERATION_H_

#include "simulation_data.h"
#include "nonlinearSolverNewton.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef struct DATA_NEWTON
{
  double* resScaling;
  double* fvecScaled;

  int newtonStrategy;

  int n;
  double* x;
  double* fvec;
  double xtol;
  double ftol;
  int nfev;
  int maxfev;
  int info;
  double epsfcn;
  double* fjac;
  double* rwork;
  int* iwork;
  int calculate_jacobian;
  int factorization;
  int numberOfIterations; /* over the whole simulation time */
  int numberOfFunctionEvaluations; /* over the whole simulation time */

  /* damped newton */
  double* x_new;
  double* x_increment;
  double* f_old;
  double* fvec_minimum;
  double* delta_f;
  double* delta_x_vec;

   rtclock_t timeClock;

} DATA_NEWTON;


int allocateNewtonData(int size, void** data);
int freeNewtonData(void** data);
int _omc_newton(int(*f)(int*, double*, double*, void*, int), DATA_NEWTON* solverData, void* userdata);

#ifdef __cplusplus
}
#endif

#endif
