/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include "simulation/simulation_runtime.h"
#include "dopri45.h"
#include <stdlib.h>
#include <math.h>
#include <string.h>


const int dopri5_s = 7;
const int dop5dense_s = 9;


const double dop_bst[9][6] = { { 696.0, -2439.0, 3104.0, -1710.0, 384.0, 384.0 },
                                         { 0.0, 0.0, 0.0, 0.0, 0.0, 1.0 },
                                         { -12000.0, 25500.0, -16000.0, 3000.0, 0.0, 1113.0 },
                                         { -3000.0, 6375.0, -4000.0, 750.0, 0.0, 192.0 },
                                         { 52488.0, -111537.0, 69984.0, -13122.0, 0.0, 6784.0 },
                                         { -264.0, 561.0, -352.0, 66.0, 0.0, 84.0 },
                                         { 32.0, -63.0, 38.0, -7.0, 0.0, 8.0 },
                                         { 0.0, 125.0, -250.0, 125.0, 0.0, 24.0 },
                                         { 48.0, -112.0, 80.0, -16.0, 0.0, 3.0 } };
const double dop_b5[9] = { 5179.0 / 57600.0, 0.0, 7571.0 / 16695.0,
                                     393.0 / 640.0, -92097.0 / 339200.0, 187.0 / 2100.0,
                                     1.0 / 40.0, 0.0, 0.0 }; /* b_i */
const double dop_b4[9] = { 35.0 / 384.0, 0.0, 500.0 / 1113.0,
                                     125.0 / 192.0, -2187.0 / 6784.0, 11.0 / 84.0,
                                     0.0, 0.0, 0.0 }; /* ^b_i */
const double dop_c[9] = { 0.0, 1.0 / 5.0, 3.0 / 10.0, 4.0 / 5.0, 8.0 / 9.0,
                                    1.0, 1.0, 1.0 / 5.0, 1.0 / 2.0 };
const double dop_a[][9] = { { 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 1.0 / 5.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 3.0 / 40.0, 9.0 / 40.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 44.0 / 45.0, -56.0 / 15.0, 32.0 / 9.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 19372.0 / 6561.0, -25360.0 / 2187.0, 64448.0 / 6561.0, -212.0 / 729.0, 0.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 9017.0 / 3168.0, -355.0 / 33.0, 46732.0 / 5247.0, 49.0 / 176.0, -5103.0 / 18656.0, 0.0, 0.0, 0.0, 0.0 },
                                      { 35.0 / 384.0, 0.0, 500.0 / 1113.0, 125.0 / 192.0, -2187.0 / 6784.0, 11.0 / 84.0, 0.0, 0.0, 0.0 },
                                      { 5207.0 / 48000.0, 0.0, 92.0 / 795.0, -79.0 / 960.0, 53217.0 / 848000.0, -11.0 / 300.0, 4.0 / 125.0, 0.0, 0.0 },
                                      { 613.0 / 6144.0, 0.0, 125.0 / 318.0, -125.0 / 3072.0, 8019.0 / 108544.0, -11.0 / 192.0, 1.0 / 32.0, 0.0, 0.0 } };


/*********************variable declaration for DOPRI5(4)***************************************/
int
dopri54(int(*f)(), double* x4, double* x5);


int
init_stepsize(int(*f)(), double tolerence);


double
maxnorm(double* a, double* b) {

  double max_value = 0;
  int i;

  for(i = 0; i < globalData->nStates; i++)
  {
    double c;
    c = fabs(b[i] - a[i]);
    if(c > max_value)
      max_value = c;
  }
  return max_value;
}

double
euklidnorm(double* a) {

  double erg = 0;
  int i;
  for(i = 0; i < globalData->nStates; i++)
  {
    erg = pow(a[i], 2) + erg;
  }
  return sqrt(erg);
}


/***************************************    STEPSIZE  ***********************************/
int
init_stepsize(int(*f)(), double tolerence) {
  double p = 4.0, d0norm = 0.0, d1norm = 0.0, d2norm = 0.0, h0 = 0.0, h1 = 0.0,
         d, backupTime;
  double* sc = (double*) malloc(globalData->nStates * sizeof(double*));
  double* d0 = (double*) malloc(globalData->nStates * sizeof(double*));
  double* d1 = (double*) malloc(globalData->nStates * sizeof(double*));
  double* temp = (double*) malloc(globalData->nStates * sizeof(double*));
  double* x0 = (double*) malloc(globalData->nStates * sizeof(double*));
  double* y = (double*) malloc(globalData->nStates * sizeof(double*));
  int i;
  if(sim_verbose >= LOG_SOLVER)
  {
     fprintf(stdout, "Initializing stepsize...\n"); fflush(NULL);
  }

  if(tolerence <= 1e-6) {
  tolerence = 1e-5;
    fprintf(stdout, "| warning | DOPRI5: error tolerance too stringent *setting tolerance to 1e-5*\n"); fflush(NULL);
  }

  backupTime = globalData->timeValue;

  for(i = 0; i < globalData->nStates; i++)
  {
    x0[i] = globalData->states[i]; /* initial values for solver (used as backup too) */
    y[i] = globalData->statesDerivatives[i]; /* initial values for solver (used as backup too) */
    /* if(sim_verbose >= LOG_SOLVER){ cout << "x0[" << i << "]: " << x0[i] << endl;  fflush(NULL); } for debugging */

    sc[i] = tolerence + fabs(globalData->states[i]) * tolerence;
    d0[i] = globalData->states[i] / sc[i];
    d1[i] = globalData->statesDerivatives[i];
  }

  d0norm = euklidnorm(d0) / sqrt((double)globalData->nStates);
  d1norm = euklidnorm(d1) / sqrt((double)globalData->nStates);

  free(d0);
  free(d1);

  if(d0norm < 1e-5 || d1norm < 1e-5)
  {
    h0 = 1e-6;
  } else {
    h0 = 0.01 * d0norm / d1norm;
  }

  for(i = 0; i < globalData->nStates; i++)
  {
    globalData->states[i] = x0[i] + h0 * y[i]; /* give new states */
  }
  globalData->timeValue = globalData->timeValue + h0; /* set time */
  f(); /* get new statesDerivatives */

  for(i = 0; i < globalData->nStates; i++)
  {
    temp[i] = globalData->statesDerivatives[i] - y[i];
  }

  d2norm = (euklidnorm(temp) / sqrt((double)globalData->nStates)) / h0;

  d = fmax(d1norm, d2norm);

  if(d <= 1e-15)
  {
    h1 = fmax(1e-6, h0 * 1e-3);
  } else {
    h1 = pow((0.01 / d), (1.0 / (p + 1.0)));
  }

  globalData->current_stepsize = fmin(tolerence * 100 * h0, tolerence * h1);

  if(sim_verbose >= LOG_SOLVER)
  {
      fprintf(stdout, "stepsize initialized: step = %g\n",
            globalData->current_stepsize); fflush(NULL);
  }

  for(i = 0; i < globalData->nStates; i++)
  {
    globalData->states[i] = x0[i]; /* reset states */
    globalData->statesDerivatives[i] = y[i]; /* reset statesDerivatives */
  }
  globalData->timeValue = backupTime; /* reset time */

  free(sc);
  free(temp);
  free(x0);
  free(y);

  return 0;
}

int
stepsize_control(double start, double stop, double fixStep, int(*f)(),
                 int reinit_step, int useInterpolation, double tolerance, int* reject) {

  double maxVal = 0, alpha, delta, TTOL, erg;
  double backupTime;
  int retVal;
  int retry = 0;
  int i,l;

  double* x4 = (double*) malloc(globalData->nStates * sizeof(double));

  double* x5 = (double*) malloc(globalData->nStates * sizeof(double));
  double** k = work_states;

  backupTime = globalData->timeValue;

  TTOL = tolerance * 0.6; /* tolerance * sf */

  if(reinit_step)
  {
    init_stepsize(functionODE, tolerance);
    reinit_step = 0;
  }

  do {
    retVal = dopri54(functionODE, x4, x5);

    for(i = 0; i < globalData->nStates; i++)
    {
      for(l = 0; l < dopri5_s; l++)
      {
        erg = fabs((dop_b5[l] - dop_b4[l]) * k[l][i]);
        if(erg > maxVal)
          maxVal = erg;
      }
    }

    delta = globalData->current_stepsize * maxVal; /* error estimate */
    alpha = pow((delta / TTOL), (1.0 / 5.0)); /* step ratio */

    if(sim_verbose >= LOG_SOLVER)
    {
      fprintf(stdout, "delta: %g\n", delta);
      fprintf(stdout, "alpha: %g\n", alpha);
      fflush(NULL);
    }

    if(delta < tolerance)
    {
      for(i = 0; i < globalData->nStates; i++)
      {
        globalData->states[i] += globalData->current_stepsize * x4[i]; /* give new states */
      }
      f(); /* get new statesDerivatives */
      retry = 0;
      globalData->current_stepsize = globalData->current_stepsize / fmax(alpha, 0.1);
    } else {
      reject = reject + 1;
      retry = 1; /* do another step with new stepsize until step is valid */
      globalData->current_stepsize = globalData->current_stepsize / fmin(alpha, 10.0);

      if(sim_verbose >= LOG_SOLVER)
      {
        fprintf(stdout, "| info | DOPRI5: ***!! step rejected !!***\n"); fflush(NULL);
      }

      globalData->timeValue = backupTime; /* reset time */

      if((*reject > (int)10e+4) || (globalData->current_stepsize < 1e-10)) /* to avoid infinite loops */
      {
        fprintf(stdout, "| error | DOPRI5: Too many steps rejected (>10e+4) or desired stepsize too small (< 1e-10)!.\n"); fflush(NULL);
        free(x4);
        free(x5);

        return 1;
      }
    }

    /* do not advance past t_stop */
    if((globalData->timeValue + globalData->current_stepsize) > stop)
    {
      globalData->current_stepsize = stop - globalData->timeValue;
      useInterpolation = 0;
    }

    if(sim_verbose >= LOG_SOLVER)
    {
      fprintf(stdout, "| info | DOPRI5: stepsize on next step: %g\n",
              globalData->current_stepsize); fflush(NULL);
    }
  } while (retry);

  free(x4);
  free(x5);

  return 0;
}


/***************************************    DOPRI54    ***********************************/
int
dopri54(int(*f)(), double* x4, double* x5) {
  double** k = work_states;
  double sum;
  int i, j, l;

  double* backupstats = (double*) malloc(globalData->nStates * sizeof(double));
  double* backupderivatives = (double*) malloc(globalData->nStates * sizeof(double));

  memcpy(backupstats, globalData->states, globalData->nStates * sizeof(double));
  memcpy(backupderivatives, globalData->statesDerivatives, globalData->nStates * sizeof(double));

  for(i = 1; i < dop5dense_s; i++)
  {
    for(j = 0; j < globalData->nStates; j++)
    {
      k[i][j] = 0;
    }
  }

  for(j = 0; j < globalData->nStates; j++)
  {
    k[0][j] = globalData->statesDerivatives[j];
  }

  /* calculation of extra f's used by dense output included per step */
  for(j = 1; j < dop5dense_s; j++)
  {
    /* set proper time to get derivatives */
    globalData->timeValue = globalData->oldTime + dop_c[j] * globalData->current_stepsize;
    for(i = 0; i < globalData->nStates; i++)
    {
      sum = 0;
      for(l = 0; l < dop5dense_s; l++)
      {
        sum = sum + dop_a[j][l] * k[l][i];
      }
      globalData->states[i] = backupstats[i] + globalData->current_stepsize * sum;
    }
    f();
    for(i = 0; i < globalData->nStates; i++)
    {
      k[j][i] = globalData->statesDerivatives[i];
    }
  }

  globalData->timeValue = globalData->oldTime + globalData->current_stepsize; /* next solver step */

  for(i = 0; i < globalData->nStates; i++)
  {
    sum = 0;
    for(l = 0; l < dopri5_s; l++)
    {
      sum = sum + dop_b5[l] * k[l][i];
    }
    x5[i] = sum;
    /* if(sim_verbose >= LOG_SOLVER){ cout << "dx5[" << i << "]: " << x5[i] << endl; fflush(NULL); }; for debugging */
  }

  for(i = 0; i < globalData->nStates; i++)
  {
    sum = 0;
    for(l = 0; l < dopri5_s; l++)
    {
      sum = sum + dop_b4[l] * k[l][i];
    }
    x4[i] = sum;
    /* if(sim_verbose >= LOG_SOLVER){ cout << "dx4[" << i << "]: " << x4[i] << endl; fflush(NULL); }; for debugging */
  }

  memcpy(globalData->states, backupstats, globalData->nStates * sizeof(double));
  memcpy(globalData->statesDerivatives, backupderivatives, globalData->nStates * sizeof(double));

  free(backupstats);
  free(backupderivatives);

  return 0;
}

/******************************* interpolation module ************************************************/
int
interpolation_control(const int dideventstep, double interpolationStep,
                      double fixStep, double stop) {

  int i,l;
  if(sim_verbose >= LOG_SOLVER)
  {
    fprintf(stdout, "| info | dense output: $$$$$\t interpolate data at %g\n", interpolationStep); fflush(NULL);
  }
  /* if(sim_verbose >= LOG_SOLVER)
   * {
   *   cout << "oldTime,Time,interpolate data at " << globalData->oldTime << ", "
   *     << globalData->timeValue << ", " << interpolationStep << endl; fflush(NULL);
   * } /* for debugging */

  if(dideventstep == 1)
  {
    /* Emit data after an event */
    sim_result.emit(&sim_result,data);
  }

  if(((interpolationStep > globalData->oldTime) && (interpolationStep < globalData->timeValue)) ||
      ((dideventstep == 1) && (interpolationStep < globalData->timeValue)))
  {
    double** k = work_states;
    double backupTime = globalData->timeValue;
    double backupTime_old = globalData->oldTime;
    double* backupstats = (double*) malloc(globalData->nStates * sizeof(double));
    double* backupderivatives = (double*) malloc(globalData->nStates * sizeof(double));
    double* backupstats_old = (double*) malloc(globalData->nStates * sizeof(double));
    double bstar[9];
    double numerator = 0, sigma, sh, sum;

    /* save states and derivatives as they're altered by linear interpolation method */
    for(i = 0; i < globalData->nStates; i++)
    {
      backupstats[i] = globalData->states[i];
      backupderivatives[i] = globalData->statesDerivatives[i];
      backupstats_old[i] = globalData->states_old[i];
    }

    do
    {
      if(!(backupTime == backupTime_old)) /* don't interpolate during an event */
      {
        /* calculate dense output interpolation parameter sigma */
        sh = interpolationStep - globalData->timeValue;
        sigma = sh / globalData->current_stepsize;

        for(i = 0; i < dop5dense_s; i++)
        {
          /* compute bstar vector components using Horner's scheme */
          numerator = dop_bst[i][4] +
                      sigma * (dop_bst[i][3] +
                      sigma * (dop_bst[i][2] +
                      sigma * (dop_bst[i][1] +
                      sigma * dop_bst[i][0])));
          bstar[i] = numerator / dop_bst[i][5];
        }

        for(i = 0; i < globalData->nStates; i++)
        {
          sum = 0;
          for(l = 0; l < dop5dense_s; l++)
          {
            sum = sum + bstar[l] * k[l][i];
          }
          globalData->states[i] = globalData->states[i] + sh * sum;
        }

        /* set global time value to interpolated time */
        globalData->timeValue = interpolationStep;

        /* update all dependent variables */
        functionODE(NULL);
        functionAlgebraics(NULL);
        saveZeroCrossings();

        /* Emit interpolated data at the current time step */
        sim_result.emit(&sim_result,data);
      }

      interpolationStep = interpolationStep + fixStep;

    } while ((interpolationStep <= stop + fixStep) && (interpolationStep < backupTime));

    /* update old data */
    globalData->oldTime = backupTime;

    /* reset data for next solver step */
    globalData->timeValue = backupTime;
    for(i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = backupstats[i];
      globalData->statesDerivatives[i] = backupderivatives[i];
    }

    free(backupstats);
    free(backupderivatives);
    free(backupstats_old);
  } else {
    globalData->oldTime = globalData->timeValue;
  }
  return 0;
}
