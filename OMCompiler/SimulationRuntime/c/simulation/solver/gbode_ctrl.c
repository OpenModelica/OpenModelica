/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_ctrl.c
 */

#include "gbode_main.h"

int gbode_fODE(DATA* data, threadData_t *threadData, void* evalFunctionODE, modelica_real* fODE);

double getErrorThreshold(DATA_GBODE* gbData)
{
  int i, j, temp;

  if (gbData->percentage == 1)
    return -1;

  for (i = 0;  i < gbData->nStates - 1; i++)
  {
    for (j = 0; j < gbData->nStates - i - 1; j++)
    {
      if (gbData->err[gbData->sortedStates[j]] < gbData->err[gbData->sortedStates[j+1]])
      {
        temp = gbData->sortedStates[j];
        gbData->sortedStates[j] = gbData->sortedStates[j+1];
        gbData->sortedStates[j+1] = temp;
      }
    }
  }
  i = MIN(MAX(round(gbData->nStates * gbData->percentage), 1), gbData->nStates - 1);

  return gbData->err[gbData->sortedStates[i]];
}


/**
 * @brief constant step size (given by solver main)
 *
 * @param err_values
 * @param stepSize_values
 * @param err_order
 * @return double
 */
double CController(double* err_values, double* stepSize_values, unsigned int err_order)
{
  return 1.0;
}

/**
 * @brief simple step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param stepSize_values
 * @param err_order
 * @return double
 */
double IController(double* err_values, double* stepSize_values, unsigned int err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta = 1./(err_order+1);

  if (err_values[0]>0) {
    return fmin(facmax, fmax(facmin, fac*pow(1./err_values[0], beta)));
  } else {
    return facmax;
  }
}

/**
 * @brief PI step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param stepSize_values
 * @param err_order
 * @return double
 */
double PIController(double* err_values, double* stepSize_values, unsigned int err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta  = 1./(err_order+1);
  double beta1 = 1./(err_order+1);
  double beta2 = 1./(err_order+1);

  double estimate;

  if (err_values[0] < DBL_EPSILON)
    return facmax;

  if (err_values[1] < DBL_EPSILON)
    estimate = pow(1./err_values[0], beta);
  else
    estimate = stepSize_values[0]/stepSize_values[1]*pow(.5/err_values[0], beta1)*pow(err_values[1]/err_values[0], beta2);

  return fmin(facmax, fmax(facmin, fac*estimate));

}


/**
 * @brief Calculate initial step size.
 *
 * Called at the beginning of simulation or after an event occurred.
 *
 * Book Reference:
 * E. Hairer, S. P. Nørsett, G. Wanner
 * Solving Ordinary Differential Equations I, Nonstiff Problems, page 169
 *
 * @param data              Runtime data struct.
 * @param threadData        Thread data for error handling.
 * @param solverInfo        Storing Runge-Kutta solver data.
 */
void gb_first_step(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  DATA_GBODE* gbData = (DATA_GBODE*)solverInfo->solverData;
  int nStates = data->modelData->nStates;
  modelica_real* fODE = &sData->realVars[nStates];

  int i;

  double sc, d, d0 = 0.0, d1 = 0.0, d2 = 0.0, h0, h1, delta_ti, infNorm, sum = 0;
  double Atol = data->simulationInfo->tolerance;
  double Rtol = Atol;

  /* store values of the states and state derivatives at initial or event time */
  gbData->time = sData->timeValue;
  memcpy(gbData->yOld, sData->realVars, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);
  memcpy(gbData->f, fODE, nStates*sizeof(double));

  for (i=0; i<nStates; i++) {
    sc = Atol + fabs(sDataOld->realVars[i])*Rtol;
    d0 += ((sDataOld->realVars[i] * sDataOld->realVars[i])/(sc*sc));
    d1 += ((fODE[i] * fODE[i]) / (sc*sc));
  }
  d0 /= nStates;
  d1 /= nStates;

  d0 = sqrt(d0);
  d1 = sqrt(d1);

  /* calculate first guess of the initial step size */
  if (d0 < 1e-5 || d1 < 1e-5) {
    h0 = 1e-6;
  } else {
    h0 = 0.01 * d0/d1;
  }

  for (i=0; i<nStates; i++) {
    sData->realVars[i] = gbData->yOld[i] + fODE[i] * h0;
  }
  sData->timeValue += h0;

  gbode_fODE(data, threadData, &(gbData->evalFunctionODE), fODE);

  for (i=0; i<nStates; i++) {
    sc = Atol + fabs(gbData->yOld[i])*Rtol;
    d2 += ((fODE[i]-gbData->f[i])*(fODE[i]-gbData->f[i])/(sc*sc));
  }

  d2 /= h0;
  d2 = sqrt(d2);


  d = fmax(d1,d2);

  if (d > 1e-15) {
    h1 = sqrt(0.01/d);
  } else {
    h1 = fmax(1e-6, h0*1e-3);
  }

  gbData->stepSize = 0.5*fmin(100*h0,h1)*50;
  gbData->lastStepSize = 0.0;

  infoStreamPrint(LOG_SOLVER, 0, "Initial step size = %e at time %g", gbData->stepSize, gbData->time);
}
