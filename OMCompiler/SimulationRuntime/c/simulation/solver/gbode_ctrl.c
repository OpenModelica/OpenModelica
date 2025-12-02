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
#include "gbode_conf.h"

unsigned int use_fhr = FALSE;
double use_filter = 1.0;

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

  for (i = 0;  i < gbData->nStates - 1; i++) {
    for (j = 0; j < gbData->nStates - i - 1; j++) {
      if (gbData->err[gbData->sortedStatesIdx[j]] < gbData->err[gbData->sortedStatesIdx[j+1]]) {
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
 * @brief PI step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param step_values
 * @param err_order
 * @return double
 */
double PIController(double* err_values, double* step_values, unsigned int err_order, enum GB_CTRL_METHOD ctrl_method)
{
  unsigned int k = err_order+1;
  double beta1, beta2;
  double err_n     = err_values[0];
  double err_n1    = err_values[1];

  // Fallback for incomplete history
  if (err_n1 < DBL_EPSILON) {
      return pow(1. / err_n, 1. / k);
  }

  switch (ctrl_method) {
      case GB_CTRL_PI_34:
          beta1 = 0.7 / k;            // current error (P)
          beta2 = -0.4 / k;           // previous error (I)
          break;
      case GB_CTRL_PI_33:
          beta1 = (2.0 / 3.0) / k;    // current error (P)
          beta2 = (-1.0 / 3.0) / k;   // previous error (I)
          break;
      case GB_CTRL_PI_42:
          beta1 = 0.6 / k;            // current error (P)
          beta2 = -0.2 / k;           // previous error (I)
          break;
      default:
        throwStreamPrint(NULL, "Unknown step size control method.");
  }

  return pow(1.0 / err_n, beta1) * pow(1.0 / err_n1, beta2);
}

/**
 * @brief PID step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param step_values
 * @param err_order
 * @return double
 */
double PIDController(double* err_values, double* step_values, unsigned int err_order, enum GB_CTRL_METHOD ctrl_method)
{
  unsigned int k = err_order + 1;
  double beta1, beta2, beta3;

  double err_n     = err_values[0];
  double err_n1    = err_values[1];
  double err_n2    = err_values[2];

  // Fallback for incomplete history
  if (err_n1 < DBL_EPSILON || err_n2 < DBL_EPSILON) {
      return pow(1.0 / err_n, 1.0 / k);
  }

  switch (ctrl_method) {
      case GB_CTRL_PID_H312:
          beta1 = 1./18/k;  // current error (P)
          beta2 = 1./9/k;   // previous error (I)
          beta3 = 1./18/k;  // second previous error (D)
          break;
      case GB_CTRL_PID_SOEDERLIND:
          beta1 = 0.1 / k;  // current error (P)
          beta2 = 0.2 / k;  // previous error (I)
          beta3 = 0.1 / k;  // second previous error (D)
          break;
      case GB_CTRL_PID_STIFF:
          beta1 = 0.58 / k;  // current error (P)
          beta2 = 0.21 / k;  // previous error (I)
          beta3 = 0.21 / k;  // second previous error (D)
          break;
      default:
        throwStreamPrint(NULL, "Unknown step size control method.");
  }

  return pow(1.0 / err_n,  beta1) * pow(1.0 / err_n1, beta2) * pow(1.0 / err_n2, beta3);
}

/**
 * @brief Compute adaptive gamma for FHR controller
 *
 * @param err_now   Current error estimate
 * @param err_prev  Previous error estimate
 * @param h_now     Current step size
 * @param h_prev    Previous step size
 * @param eta       Scaling factor (e.g. 0.1)
 * @return double   Adaptive gamma value
 */
double computeGamma(double err_now, double err_prev, double h_now, double h_prev, double eta)
{
    double log_h_ratio = log(h_now / h_prev);
    double log_e_ratio = log((err_now + DBL_EPSILON) / (err_prev + DBL_EPSILON));  // avoid division by zero

    return eta * log_h_ratio / (log_e_ratio + DBL_EPSILON);
}

/**
 * @brief PID step size control (see Hairer, etc.)
 *
 * @param err_values
 * @param step_values
 * @param err_order
 * @return double
 */
double GenericController(double* err_values, double* step_values, unsigned int err_order, enum GB_CTRL_METHOD ctrl_method)
{
  double fac    = 0.85;
  double facmax = 2.5;
  double facmin = 0.2;

  unsigned int k = err_order + 1;

  double err_n     = err_values[0];
  double err_n1    = err_values[1];

  double h_n       = step_values[0];
  double h_n1      = step_values[1];

  double h_fac;

  // Handle pathological zero error
  if (err_n < DBL_EPSILON)
      return facmax;

  switch (ctrl_method) {
      case GB_CTRL_CNST:
          h_fac = 1.0; // Constant step size
          break;
      case GB_CTRL_I:
          h_fac = pow(1./err_n, 1./k);
          break;
      case GB_CTRL_PI_33:
      case GB_CTRL_PI_34:
      case GB_CTRL_PI_42:
          h_fac = PIController(err_values, step_values, err_order, ctrl_method);
          break;
      case GB_CTRL_PID_H312:
      case GB_CTRL_PID_SOEDERLIND:
      case GB_CTRL_PID_STIFF:
          h_fac = PIDController(err_values, step_values, err_order, ctrl_method);
          break;
      default:
        throwStreamPrint(NULL, "Unknown step size control method.");
  }

  // Applies Fuehrer-style adaptive damping to the step size factor:
  // If the last step was rejected, gamma > 0 increases conservatism by reducing h_fac.
  // If accepted, gamma = 0 has little effect. The formula h_fac *= (h_n / h_n1)^gamma
  // discourages oscillatory step behavior by penalizing instability in recent steps.
  if (use_fhr && h_n1 > DBL_EPSILON) {
      // Compute gamma adaptively (Needs to be looked up in the literature), not suitable for PID Controller?!
      double eta = 0.1;
      double gamma = computeGamma(err_n, err_n1, h_n, h_n1, eta);
      h_fac = h_fac * pow(h_n / h_n1, gamma);
  }

  // Applies exponential smoothing to the step size factor:
  // use_filter = 0 -> constant step size,
  // use_filter = 1 -> full adaptation without smoothing.
  if (use_filter>0) {
     h_fac = use_filter * h_fac + (1.0 - use_filter);
  }

  // Keep step size constant, if there are only small changes
  if ((0.95 < h_fac) && (h_fac < 1.05)) {
    return 1.0;
  } else
    return fmin(facmax, fmax(facmin, fac*h_fac));
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
  double sc, safety = 0.01;
  double d0 = 0.0;  // norm of y0 weighted
  double d1 = 0.0;  // norm of f0 weighted
  double d2 = 0.0;  // norm of slope difference weighted

  double h0, h1;
  double absTol = data->simulationInfo->tolerance;
  double relTol = absTol;

  // Increase initialFailures counter on repeated failures (for adaptive reduction)
  gbData->initialFailures++;

  // Store current time and state
  gbData->time = sData->timeValue;
  memcpy(gbData->yOld, sData->realVars, nStates * sizeof(double));

  // Compute f(t0, y0)
  gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

  if (gbData->initialStepSize < 0) {
    memcpy(gbData->f, fODE, nStates * sizeof(double));

    // Compute weighted norms of y0 and f0
    for (i = 0; i < nStates; i++) {
      sc = absTol + fabs(gbData->yOld[i]) * relTol;
      d0 += (gbData->yOld[i] * gbData->yOld[i]) / (sc * sc);
      d1 += (fODE[i] * fODE[i]) / (sc * sc);
    }
    d0 = sqrt(d0 / nStates);
    d1 = sqrt(d1 / nStates);

    // Initial guess for h0 based on ratio
    if (d0 < 1e-5 || d1 < 1e-5) {
      h0 = 1e-6;
    } else {
      h0 = safety * d0 / d1;
    }

    // If repeated failures happened, reduce h0 accordingly
    if (gbData->initialFailures > 0) {
          h0 /= pow(10, gbData->initialFailures);
    }
    // Security condition, if h0 is nonsense
    h0 = fmin(h0, 0.1*data->simulationInfo->stepSize);

    // Trial explicit Euler step: y1 = y0 + h0 * f0
    for (i = 0; i < nStates; i++) {
      sData->realVars[i] = gbData->yOld[i] + fODE[i] * h0;
    }
    sData->timeValue = gbData->time + h0;

    // Compute f(t0+h0, y1)
    gbode_fODE(data, threadData, &(gbData->stats.nCallsODE));

    // Compute weighted norm of slope difference
    for (i = 0; i < nStates; i++) {
      sc = absTol + fabs(gbData->yOld[i]) * relTol;
      double diff = fODE[i] - gbData->f[i];
      d2 += (diff * diff) / (sc * sc);
    }
    d2 = sqrt(d2 / nStates) / h0;

    // Combine the slopes to refine step size estimate
    double d = fmax(d1, d2);

    if (d > 1e-15) {
      h1 = sqrt(safety / d);
    } else {
      h1 = fmax(1e-6, h0 * 1e-3);
    }

    // Final step size: blend h0 and h1 with some limits
    gbData->stepSize = fmin(100.0 * h0, h1);
    gbData->optStepSize = gbData->stepSize;
    gbData->lastStepSize = 0.0;

    // Restore original state and time
    sData->timeValue = gbData->time;
    memcpy(sData->realVars, gbData->yOld, nStates * sizeof(double));
    memcpy(fODE, gbData->f, nStates * sizeof(double));
  } else {
    gbData->stepSize = gbData->initialStepSize;
    gbData->lastStepSize = 0.0;
  }

  infoStreamPrint(OMC_LOG_SOLVER, 0, "Initial step size = %e at time %g", gbData->stepSize, gbData->time);

  // Reset failure count on success
  gbData->initialFailures = -1;
}
