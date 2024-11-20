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

/**
 * @brief Determine the error threshold depending on the percentage of fast states
 *        to all states. Use the sorted states with respect to the error.
 *
 * @param gbData        Pointer to generik GBODE data struct.
 * @return * double     Error threshold for the fast state selection
 */
double getErrorThreshold(DATA_GBODE* gbData)
{
  int i, j, temp;

  if (gbData->percentage == 1)
    return -1;

  for (i = 0;  i < gbData->nStates - 1; i++)
  {
    for (j = 0; j < gbData->nStates - i - 1; j++)
    {
      if (gbData->err[gbData->sortedStatesIdx[j]] < gbData->err[gbData->sortedStatesIdx[j+1]])
      {
        temp = gbData->sortedStatesIdx[j];
        gbData->sortedStatesIdx[j] = gbData->sortedStatesIdx[j+1];
        gbData->sortedStatesIdx[j+1] = temp;
      }
    }
  }
  i = fmin(fmax(round(gbData->nStates * gbData->percentage), 1), gbData->nStates - 1);

  return gbData->err[gbData->sortedStatesIdx[i]];
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
  double facmax = 1.2;
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
  double beta1 = 0.7/(err_order+1);
  double beta2 = -0.4/(err_order+1);

  double estimate;

  if (err_values[0] < DBL_EPSILON)
    return facmax;

  if (err_values[1] < DBL_EPSILON)
    estimate = pow(1./err_values[0], beta);
  else
    estimate = pow(1./err_values[0], beta1)*pow(1./err_values[1], beta2);

  return fmin(facmax, fmax(facmin, fac*estimate));
}

/**
 * @brief PID step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param stepSize_values
 * @param err_order
 * @return double
 */
double PIDController(double* err_values, double* stepSize_values, unsigned int err_order)
{
  double fac = 0.9;
  double facmax = 3.5;
  double facmin = 0.5;
  double beta  = 1./(err_order+1);
  double beta1 = 0.7/(err_order+1);
  double beta2 = -0.4/(err_order+1);
  double alpha1 = 1./18/(err_order+1);
  double alpha2 = 1./9/(err_order+1);
  double alpha3 = 1./18/(err_order+1);

  double estimate;

  if (err_values[0] < DBL_EPSILON)
    return facmax;

  if (err_values[1] < DBL_EPSILON)
    estimate = pow(1./err_values[0], beta);
  else
    if (err_values[2] < DBL_EPSILON)
      estimate = pow(1./err_values[0], beta1)*pow(1./err_values[1], beta2);
    else
      estimate = pow(1./err_values[0], alpha1)*pow(1./err_values[1], alpha2)*pow(1./err_values[2], alpha3);

  return fmin(facmax, fmax(facmin, fac*estimate));
}

/**
 * @brief Get step size control function from method.
 *
 * @param ctrl_method     Specifying method.
 * @return void*          Pointer to step size control function.
 */
gm_stepSize_control_function getControllFunc(enum GB_CTRL_METHOD ctrl_method) {
  switch (ctrl_method)
  {
  case GB_CTRL_I:
    return IController;
  case GB_CTRL_PI:
    return PIController;
  case GB_CTRL_PID:
    return PIDController;
  case GB_CTRL_CNST:
    return CController;
  default:
    throwStreamPrint(NULL, "Unknown step size control method.");
  }
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
 * @param gbData        Storing Runge-Kutta solver data.
 */
void getInitStepSize(DATA* data, threadData_t* threadData, DATA_GBODE* gbData)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];
  SIMULATION_DATA *sDataOld = (SIMULATION_DATA*)data->localData[1];
  int nStates = data->modelData->nStates;
  modelica_real* fODE = &sData->realVars[nStates];

  int i;

  double sc;
  double d, d0 = 0.0, d1 = 0.0, d2 = 0.0;
  double h0, h1;
  double absTol = data->simulationInfo->tolerance;
  double relTol = absTol;

  // This flag will be used in order to reduce the step size for the first Euler step below
  // Only used for subsequent calls, if an assert happens during the Euler step
  gbData->initialFailures++;

  /* store values of the states and state derivatives at initial or event time */
  gbData->time = sData->timeValue;
  memcpy(gbData->yOld, sData->realVars, nStates*sizeof(double));
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

  if (gbData->initialStepSize < 0) {
    memcpy(gbData->f, fODE, nStates*sizeof(double));
    for (i=0; i<nStates; i++) {
      sc = absTol + fabs(sDataOld->realVars[i])*relTol;
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
    if (gbData->initialFailures>0)
      h0 /= pow(10,gbData->initialFailures);

    for (i=0; i<nStates; i++) {
      sData->realVars[i] = gbData->yOld[i] + fODE[i] * h0;
    }
    sData->timeValue += h0;

    gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

    for (i=0; i<nStates; i++) {
      sc = absTol + fabs(gbData->yOld[i])*relTol;
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

    gbData->stepSize = 0.5*fmin(100*h0,h1);
    gbData->optStepSize = gbData->stepSize;
    gbData->lastStepSize = 0.0;

    sData->timeValue = gbData->time;
    memcpy(sData->realVars, gbData->yOld, nStates*sizeof(double));
    memcpy(fODE, gbData->f, nStates*sizeof(double));
  } else {
    gbData->stepSize = gbData->initialStepSize;
    gbData->lastStepSize = 0.0;
  }

  infoStreamPrint(OMC_LOG_SOLVER, 0, "Initial step size = %e at time %g", gbData->stepSize, gbData->time);

  // Set number of initialization failures back to -1 (intial step size determination was succesfull)
  gbData->initialFailures = -1;
}
