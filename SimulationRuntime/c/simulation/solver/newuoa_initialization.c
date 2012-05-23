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

/*! \file newuoa_initialization.c
 */

#include "newuoa_initialization.h"
#include "simulation_data.h"
#include "omc_error.h"
#include "openmodelica.h"
#include "openmodelica_func.h"
#include "model_help.h"
#include "read_matlab4.h"
#include "events.h"

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

#ifndef NEWUOA
#define NEWUOA newuoa_
#endif

void NEWUOA(long *nz,
  long *NPT,
  double *z,
  double *RHOBEG,
  double *RHOEND,
  long *IPRINT,
  long *MAXFUN,
  double *W,
  void (*leastSquare) (long *nz, double *z, double *funcValue));

/*! \fn int newuoa_initialization(long nz, double *z)
 *
 *  This function performs initialization using the newuoa function, which is
 *  a trust region method that forms quadratic models by interpolation.
 */
int newuoa_initialization(DATA* data, INIT_DATA* initData)
{
  long IPRINT = DEBUG_FLAG(LOG_INIT) ? 1000 : 0;
  long MAXFUN = 50000;
  double RHOEND = 1.0e-6;
  double RHOBEG = 10;     /* This should be about one tenth of the greatest
                             expected value of a variable. Perhaps the nominal
                             value can be used for this. */
  long NPT = 2*initData->nz+1;
  double funcValue = 0;
  double* nominal;

  double *W = (double*)calloc((NPT+13)*(NPT+initData->nz)+3*initData->nz*(initData->nz+3)/2, sizeof(double));

  globalData = data;
  globalInitialResiduals = initData->initialResiduals;

  ASSERT(W, "out of memory");
  NEWUOA(&initData->nz, &NPT, initData->z, &RHOBEG, &RHOEND, &IPRINT, &MAXFUN, W, leastSquare);
  free(W);

  globalData = NULL;
  globalInitialResiduals = NULL;

  /* Calculate the residual to verify that equations are consistent. */
  nominal = initData->nominal;
  initData->nominal = NULL;
  funcValue = leastSquareWithLambda(data, initData, 1.0);
  initData->nominal = nominal;
  return reportResidualValue(data, initData, funcValue);
}
