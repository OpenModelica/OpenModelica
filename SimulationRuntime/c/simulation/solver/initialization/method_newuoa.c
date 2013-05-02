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

#include "method_newuoa.h"
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

static DATA *globalData = NULL;
static double* globalInitialResiduals = NULL;

/*! \fn void leastSquare(long *nz, double *z, double *funcValue)
*
*  This function calculates the residual value
*  as the sum of squared residual equations.
*
*  \param nz [in] number of variables
*  \param z [in] vector of variables
*  \param funcValue [out] result
*/
static void leastSquare(long *nz, double *z, double *funcValue)
{
  INIT_DATA initData;

  initData.nVars = *nz;
  initData.nStates = -1;
  initData.nParameters = -1;
  initData.nInitResiduals = 0;
  initData.nStartValueResiduals = 0;

  initData.vars = z;
  initData.start = NULL;
  initData.min = NULL;
  initData.max = NULL;
  initData.nominal = NULL;
  initData.name = NULL;

  initData.initialResiduals = globalInitialResiduals;
  initData.residualScalingCoefficients = NULL;
  initData.startValueResidualScalingCoefficients = NULL;

  initData.simData = globalData;

  *funcValue = leastSquareWithLambda(&initData, 1.0);
}

/*! \fn int newuoa_initialization(INIT_DATA *initData)
 *
 *  This function performs initialization using the newuoa function, which is
 *  a trust region method that forms quadratic models by interpolation.
 */
int newuoa_initialization(INIT_DATA *initData)
{
  long IPRINT = ACTIVE_STREAM(LOG_INIT) ? 1000 : 0;
  long MAXFUN = 1000 * initData->nVars;
  double RHOEND = 1.0e-12;
  double RHOBEG = 10;     /* This should be about one tenth of the greatest
                             expected value of a variable. Perhaps the nominal
                             value can be used for this. */
  long NPT = 2*initData->nVars+1;

  double *W = (double*)calloc((NPT+13)*(NPT+initData->nVars)+3*initData->nVars*(initData->nVars+3)/2, sizeof(double));
  ASSERT(W, "out of memory");

  globalData = initData->simData;
  globalInitialResiduals = initData->initialResiduals;

  NEWUOA(&initData->nVars, &NPT, initData->vars, &RHOBEG, &RHOEND, &IPRINT, &MAXFUN, W, leastSquare);
  free(W);

  globalData = NULL;
  globalInitialResiduals = NULL;

  /* Calculate the residual to verify that equations are consistent. */
  return reportResidualValue(initData);
}
