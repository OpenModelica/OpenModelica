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

/*! \file simplex_initialization.c
 */

#include "initialization.h"
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

#ifndef NELMEAD
#define NELMEAD nelmead_
#endif

void NELMEAD(double *z,
  double *STEP,
  long *nz,
  double *funcValue,
  long *MAXF,
  long *IPRINT,
  double *STOPCR,
  long *NLOOP,
  long *IQUAD,
  double *SIMP,
  double *VAR,
  void (*leastSquare) (long *nz, double *z, double *funcValue),
  long *IFAULT);

/*! \fn reportResidualValue
 *
 *  Returns 1 if residual is non-zero and prints appropriate error message.
 *
 *  \param [ref] [data]
 *  \param [in]  [funcValue] leastSquare-Value
 *  \param [in]  [initialResiduals]
 */
static int reportResidualValue(DATA* data, INIT_DATA* initData, double funcValue)
{
  long i = 0;
  if(funcValue > 1e-5)
  {
    WARNING("reportResidualValue | error in initialization. System of initial equations are not consistent");
    WARNING1("reportResidualValue | (Least Square function value is %g)", funcValue);

    for(i=0; i<initData->nInitResiduals; i++)
      if(fabs(initData->initialResiduals[i]) > 1e-6)
        INFO2("reportResidualValue | residual[%d] = %g", (int) i, initData->initialResiduals[i]);
    return 1;
  }
  return 0;
}

/*! \fn int simplex_initialization(long nz,double *z)
 *
 *  This function performs initialization by using the simplex algorithm.
 *  This does not require a jacobian for the residuals.
 */
int simplex_initialization(DATA* data, INIT_DATA* initData)
{
  int ind = 0;
  double funcValue = 0;
  double *STEP = (double*)malloc(initData->nz * sizeof(double));
  double *VAR = (double*)malloc(initData->nz * sizeof(double));
  double STOPCR = 0, SIMP = 0;
  long IPRINT = 0, NLOOP = 0, IQUAD = 0, IFAULT = 0, MAXF = 0;
  double* nominal;
  ASSERT(STEP, "out of memory");
  ASSERT(VAR, "out of memory");

  /* Start with stepping .5 in each direction. */
  for(ind = 0; ind<initData->nz; ind++)
  {
    /* some kind of scaling */
    STEP[ind] = (initData->z[ind] !=0.0 ? fabs(initData->z[ind])/1000.0 : 1);    /* 1.0 */
    VAR[ind]  = 0.0;
  }

  /* Set max. no. of function evaluations = 5000, print every 100. */

  MAXF = 5000 * initData->nz;
  IPRINT = DEBUG_FLAG(LOG_INIT) ? 1000 : -1;

  /* Set value for stopping criterion.   Stopping occurs when the
  * standard deviation of the values of the objective function at
  * the points of the current simplex < stopcr. */

  STOPCR = 1.e-12;
  NLOOP = initData->nz;

  /* Fit a quadratic surface to be sure a minimum has been found. */

  IQUAD = 0;

  /* As function value is being evaluated in DOUBLE PRECISION, it
  * should be accurate to about 15 decimals.   If we set simp = 1.d-6,
  * we should get about 9 dec. digits accuracy in fitting the surface. */

  SIMP = 1.e-12;

  /* Now call NELMEAD to do the work. */
  nominal = initData->nominal;
  initData->nominal = NULL;
  funcValue = leastSquareWithLambda(data, initData, 1.0);
  initData->nominal = nominal;

  if(fabs(funcValue) != 0)
  {
    globalData = data;
    globalInitialResiduals = initData->initialResiduals;

    NELMEAD(initData->z,STEP, &initData->nz, &funcValue, &MAXF, &IPRINT, &STOPCR, &NLOOP, &IQUAD, &SIMP, VAR, leastSquare, &IFAULT);

    globalData = NULL;
    globalInitialResiduals = NULL;
  }
  else
  {
    DEBUG_INFO1(LOG_INIT, "simplex_initialization | Result of leastSquare method = %g. The initial guess fits to the system", funcValue);
  }

  nominal = initData->nominal;
  initData->nominal = NULL;
  funcValue = leastSquareWithLambda(data, initData, 1.0);
  initData->nominal = nominal;

  DEBUG_INFO1(LOG_INIT, "leastSquare=%g", funcValue);

  if(IFAULT == 1)
  {
    if(funcValue > SIMP)
    {
      WARNING1("Error in initialization. Solver iterated %d times without finding a solution", (int)MAXF);
      return -1;
    }
  }
  else if(IFAULT == 2)
  {
    WARNING("Error in initialization. Inconsistent initial conditions.");
    return -1;
  }
  else if(IFAULT == 3)
  {
    WARNING("Error in initialization. Number of initial values to calculate < 1");
    return -1;
  }
  else if(IFAULT == 4)
  {
    WARNING("Error in initialization. Internal error, NLOOP < 1.");
    return -1;
  }
  return reportResidualValue(data, initData, funcValue);
}
