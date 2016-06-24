/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

/*
 * The original source:
 * https://svn.modelica.org/projects/Modelica/branches/tools/csv-compare/Modelica_ResultCompare/Tubes.cs
 * Comes with the following terms [BSD 3-clause]:
 *
 * Copyright (c) 2013, ITI GmbH Dresden
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * Neither the name of the ITI GmbH nor the names of its contributors may be
 * used to endorse or promote products derived from this software without
 * specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#include <stdlib.h>
#include <math.h>
#include <gc.h>
#include <stdio.h>

typedef struct {
  double *mh,*ml,*xHigh,*xLow,*yHigh,*yLow;
  int *i0h,*i1h,*i0l,*i1l;
  double tStart,tStop,x1,y1,x2,y2,currentSlope,slopeDif,delta,S,xRelEps,xMinStep,min,max;
  size_t countLow,countHigh,length;
} privates;

static inline int intmax(int a, int b) {
  return a>b ? a : b;
}

static void generateHighTube(privates *priv, double *x, double *y)
{
  int index = priv->countHigh - 1;
  double m1 = priv->mh[index];
  double m2 = priv->mh[index - 1];
  priv->slopeDif = fabs(m1 - m2);    // (3.2.6.2)

  if ((priv->slopeDif == 0) || ((priv->slopeDif < 2e-15 * fmax(fabs(m1), fabs(m2))) && (priv->i0h[priv->countHigh - 1] - priv->i1h[priv->countHigh - 2] < 100))) {
    /* new accumulated value of the saved interval is the terminal
     * value of the current interval
     * after that dismiss the current interval (3.2.6.3.2.2.) */
    double x3,y3,x4,y4;

    priv->i0h[index-1] = priv->i0h[index]; /* Remove the second to last element */
    priv->countHigh--; /* Remove the last element for priv->i1h and priv->mh, priv->xHigh and priv->yHigh */


    /* calculation of the new slope (3.2.6.3.3) */
    x3 = x[priv->i0h[index - 1]];  /* = _dX1 */
    y3 = y[priv->i0h[index - 1]];  /* = _dY1 */
    x4 = x[priv->i1h[index - 1]];  /* < X3 */
    y4 = y[priv->i1h[index - 1]];

    /* write slope to the list of slopes */
    priv->mh[index - 1] = (y3 - y4) / (x3 - x4);

  } else { /* If difference is too big:  ( 3.2.6.4) */
    priv->xHigh[index] = priv->x2 - (priv->delta * (m1 + m2) / (sqrt((m2 * m2) + (priv->S * priv->S)) + sqrt((m1 * m1) + (priv->S * priv->S))));
    if (m1 * m2 < 0) {
      priv->yHigh[index] = priv->y2 + (priv->delta * (m1 * sqrt((m2 * m2) + (priv->S * priv->S)) - m2 * sqrt((m1 * m1) + (priv->S * priv->S)))) / (m1 - m2);
    } else {
      priv->yHigh[index] = priv->y2 + (priv->S * priv->S * priv->delta * (m1 + m2) / (m1 * sqrt((m2 * m2) + (priv->S * priv->S)) + m2 * sqrt((m1 * m1) + (priv->S * priv->S))));
    }

    if ((priv->xHigh[index] == priv->xHigh[index - 1]) && (priv->yHigh[index] != priv->yHigh[index - 1])) {
      priv->xHigh[index] = priv->xHigh[index - 1] + priv->xMinStep;
      priv->yHigh[index] = priv->y2 + m1 * (priv->xHigh[index] - priv->x2) + priv->delta * sqrt((m1 * m1) + (priv->S * priv->S));
      priv->mh[index - 1] = (priv->yHigh[index] - priv->yHigh[index - 1]) / priv->xMinStep;
    }

    /* If the juncture of the current interval is before the last saved one (3.2.6.7) */
    while (/* Avoid underflow. Should this generate an error instead? */ index>1 && priv->xHigh[index] <= priv->xHigh[index - 1]) {
      /* consolidating the current and the previous interval (3.2.6.7.3) */
      priv->i0h[index-1] = priv->i0h[index]; /* Remove the second to last element */
      priv->i1h[index-1] = priv->i1h[index];
      priv->mh[index-1] = priv->mh[index];
      index--;
      priv->countHigh--; /* remove also from xHigh,yHigh */

      /* if the saved interval is the 1st interval (3.2.6.7.3.5.1) */
      if (index == 0) {
        double x3 = x[0];
        priv->xHigh[index] = x3 - priv->delta;
        priv->yHigh[index] = priv->y2 + m1 * (priv->xHigh[index] - priv->x2) + priv->delta * sqrt((m1 * m1) + (priv->S * priv->S));
      } else { /* if it is not the first:  (3.2.6.7.3.5.2.) */
        double x3 = priv->xHigh[index - 1];
        double y3 = priv->yHigh[index - 1];
        m2 = priv->mh[index - 1];

        priv->xHigh[index] = (m2 * x3 - m1 * priv->x2 + priv->y2 - y3 + priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) / (m2 - m1);
        priv->yHigh[index] = (m2 * m1 * (x3 - priv->x2) + m2 * (priv->y2 + priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) - m1 * y3) / (m2 - m1);
      }
    }
  }
}

static void generateLowTube(privates *priv, double *x, double *y)
{
  int index = priv->countLow - 1; /* = _li0l.Count - 1 = _li1l.Count - 1 = xLow.Count - 1 = yLow.Count - 1 > 0 */
  double m1 = priv->ml[index];
  double m2 = priv->ml[index - 1];
  priv->slopeDif = fabs(m1 - m2);

  if ((priv->slopeDif == 0) || ((priv->slopeDif < 2e-15 * fmax(fabs(m1), fabs(m2))) && (priv->i0l[priv->countLow - 1] - priv->i1l[priv->countLow - 2] < 100))) {
    double x3,y3,x4,y4;
    priv->i0l[index-1] = priv->i0l[index];
    priv->countLow--;

    x3 = x[priv->i0l[index - 1]];  /* = _dX1 */
    y3 = y[priv->i0l[index - 1]];  /* = _dY1 */
    x4 = x[priv->i1l[index - 1]];  /* < X3 */
    y4 = y[priv->i1l[index - 1]];

    priv->ml[index - 1] = (y3 - y4) / (x3 - x4);
  } else {
    priv->xLow[index] = priv->x2 + (priv->delta * (m1 + m2) / (sqrt((m2 * m2) + (priv->S * priv->S)) + sqrt((m1 * m1) + (priv->S * priv->S))));
    if (m1 * m2 < 0) {
      priv->yLow[index] = priv->y2 - (priv->delta * (m1 * sqrt((m2 * m2) + (priv->S * priv->S)) - m2 * sqrt((m1 * m1) + (priv->S * priv->S)))) / (m1 - m2);
    } else {
      priv->yLow[index] = priv->y2 - (priv->S * priv->S * priv->delta * (m1 + m2) / (m1 * sqrt((m2 * m2) + (priv->S * priv->S)) + m2 * sqrt((m1 * m1) + (priv->S * priv->S))));
    }

    if ((priv->xLow[index] == priv->xLow[index - 1]) && (priv->yLow[index] != priv->yLow[index - 1])) {
      priv->xLow[index] = priv->xLow[index - 1] + priv->xMinStep;
      priv->yLow[index] = priv->y2 + m1 * (priv->xLow[index] - priv->x2) - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S));
      priv->ml[index - 1] = (priv->yLow[index] - priv->yLow[index - 1]) / priv->xMinStep;
    }

    while (index>1 /* Avoid underflow. Should this generate an error instead? */ && priv->xLow[index] <= priv->xLow[index - 1]) {
      priv->i0l[index-1] = priv->i0l[index];
      priv->i1l[index-1] = priv->i1l[index];
      priv->ml[index-1] = priv->ml[index];
      index--;
      priv->countLow--;

      if (index == 0) {
        double x3 = x[0];
        priv->xLow[index] = x3 - priv->delta;
        priv->yLow[index] = priv->y2 + m1 * (priv->xLow[index] - priv->x2) - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S));
      } else {
        double x3 = priv->xLow[index - 1];
        double y3 = priv->yLow[index - 1];
        m2 = priv->ml[index - 1];
        priv->xLow[index] = (m2 * x3 - m1 * priv->x2 + priv->y2 - y3 - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) / (m2 - m1);
        priv->yLow[index] = (m2 * m1 * (x3 - priv->x2) + m2 * (priv->y2 - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) - m1 * y3) / (m2 - m1);
      }
    }
  }
}

static privates* skipCalculateTubes(double *x, double *y, size_t length)
{
  privates *priv = (privates*) omc_alloc_interface.malloc(sizeof(privates));

  /* set tStart and tStop */
  priv->length = length;
  priv->tStart = x[0];
  priv->tStop = x[length - 1];
  priv->xRelEps = 1e-15;
  priv->xMinStep = ((priv->tStop - priv->tStart) + fabs(priv->tStart)) * priv->xRelEps;
  priv->countLow = length;
  priv->countHigh = length;
  priv->yHigh = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->yLow  = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  memcpy(priv->yHigh, y, length * sizeof(double));
  memcpy(priv->yLow, y, length * sizeof(double));
  return priv;
}

/* This method generates tubes around a given curve */
static privates* calculateTubes(double *x, double *y, size_t length, double r)
{
  privates *priv = (privates*) omc_alloc_interface.malloc(sizeof(privates));
  int i;
  /* set tStart and tStop */
  priv->length = length;
  priv->tStart = x[0];
  priv->tStop = x[length - 1];
  priv->xRelEps = 1e-15;
  priv->xMinStep = ((priv->tStop - priv->tStart) + fabs(priv->tStart)) * priv->xRelEps;
  priv->countLow = 0;
  priv->countHigh = 0;

  /* Initialize lists (upper tube) */
  priv->mh  = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->i0h = (int*)omc_alloc_interface.malloc_atomic(sizeof(int)*length);
  priv->i1h = (int*)omc_alloc_interface.malloc_atomic(sizeof(int)*length);
  /* Initialize lists (lower tube) */
  priv->ml  = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->i0l = (int*)omc_alloc_interface.malloc_atomic(sizeof(int)*length);
  priv->i1l = (int*)omc_alloc_interface.malloc_atomic(sizeof(int)*length);

  priv->xHigh = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->xLow  = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->yHigh = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);
  priv->yLow  = (double*)omc_alloc_interface.malloc_atomic(sizeof(double)*length);

  /* calculate the tubes delta */
  priv->delta = r * (priv->tStop - priv->tStart);

  /* calculate S */
  priv->max = y[0];
  priv->min = y[0];

  for (i = 1; i < length; i++) {
    priv->max = fmax(y[i],priv->max);
    priv->min = fmin(y[i],priv->min);
  }
  priv->S = fabs(4 * (priv->max - priv->min) / (fabs(priv->tStop - priv->tStart)));

  if (priv->S < 0.0004 / fabs(priv->tStop - priv->tStart)) {
    priv->S = 0.0004 / fabs(priv->tStop - priv->tStart);
  }

  /* Begin calculation for the tubes */
  for (i = 1; i < length; i++) {
    /* get current value */
    priv->x1 = x[i];
    priv->y1 = y[i];
    /* get previous value */
    priv->x2 = x[i - 1];
    priv->y2 = y[i - 1];
    /* catch jumps */
    if ((priv->x1 <= priv->x2) && (priv->y1 == priv->y2) && (priv->countHigh == 0)) {
      continue;
    }
    if ((priv->x1 <= priv->x2) && (priv->y1 == priv->y2)) {
      priv->x1 = fmax(priv->x1, x[priv->i1l[priv->countLow - 1]] + priv->xMinStep);
      priv->x1 = fmax(priv->x1, x[priv->i1h[priv->countHigh - 1]] + priv->xMinStep);
      x[i] = priv->x1;
      priv->currentSlope = priv->mh[priv->countHigh - 1];
    } else {
      if (priv->x1 <= priv->x2) {
        priv->x1 = priv->x2 + priv->xMinStep;
        x[i] = priv->x1;
      }
      priv->currentSlope = (priv->y1 - priv->y2) / (priv->x1 - priv->x2); /* calculate current slope ( 3.2.6.1) */
    }

    /* fill lists with new values: values upper tube */
    priv->i0h[priv->countHigh] = i;
    priv->i1h[priv->countHigh] = i-1;
    priv->mh[priv->countHigh] = priv->currentSlope;

    /* fill lists with new values: values lower tube */
    priv->i0l[priv->countLow] = i;
    priv->i1l[priv->countLow] = i-1;
    if ((priv->x1 <= priv->x2) && (priv->y1 == priv->y2)) {
      priv->currentSlope = priv->ml[priv->countLow - 1];
    }
    priv->ml[priv->countLow] = priv->currentSlope;

    if (priv->countHigh == 0) { /* 1st interval (3.2.5) */
      /* initial values upper tube */
      priv->xHigh[priv->countHigh] = priv->x2 - priv->delta;
      priv->yHigh[priv->countHigh] = priv->y2 - priv->currentSlope * priv->delta + priv->delta * sqrt((priv->currentSlope * priv->currentSlope) + (priv->S * priv->S));

      /* initial values lower tube */
      priv->xLow[priv->countLow] = priv->x2 - priv->delta;
      priv->yLow[priv->countLow] = priv->y2 - priv->currentSlope * priv->delta - priv->delta * sqrt((priv->currentSlope * priv->currentSlope) + (priv->S * priv->S));

      priv->countHigh++;
      priv->countLow++;
    } else {  // if not 1st interval (3.2.6)
      /* fill lists with new values, set X and Y to arbitrary value (3.2.6.1) */
      priv->xHigh[priv->countHigh] = 1;
      priv->yHigh[priv->countHigh] = 1;
      priv->xLow[priv->countLow] = 1;
      priv->yLow[priv->countLow] = 1;

      priv->countHigh++;
      priv->countLow++;

      /* begin procedure for upper tube */
      generateHighTube(priv, x, y);
      /* begin procedure for lower tube */
      generateLowTube(priv, x, y);
    }

  }

  // calculate terminal value
  // upper tube
  priv->x1 = priv->xHigh[priv->countHigh - 1];
  priv->y1 = priv->yHigh[priv->countHigh - 1];
  priv->x2 = priv->tStop;

  priv->currentSlope = priv->mh[priv->countHigh - 1];

  priv->xHigh[priv->countHigh] = priv->x2 + priv->delta;
  priv->yHigh[priv->countHigh] = priv->y1 + priv->currentSlope * (priv->x2 + priv->delta - priv->x1);
  priv->countHigh++;

  // lower tube
  priv->x1 = priv->xLow[priv->countLow - 1];
  priv->y1 = priv->yLow[priv->countLow - 1];
  priv->x2 = priv->tStop;

  priv->currentSlope = priv->ml[priv->countLow - 1];

  priv->xLow[priv->countLow] = priv->x2 + priv->delta;
  priv->yLow[priv->countLow] = priv->y1 + priv->currentSlope * (priv->x2 + priv->delta - priv->x1);
  priv->countLow++;
  return priv;
}

static inline double linearInterpolation(double x, double x0, double x1, double y0, double y1, double xabstol)
{
  if (almostEqualRelativeAndAbs(x0,x,0,xabstol)) { //prevent NaN -> division by zero
    return y0;
  } else if (almostEqualRelativeAndAbs(x1,x,0,xabstol)) { //prevent NaN -> division by zero
    return y1;
  } else if (almostEqualRelativeAndAbs(x1,x0,0,xabstol)) { //prevent NaN -> division by zero
    return y0;
  } else {
    return y0 + (((y1 - y0) / (x1 - x0)) * (x - x0)); // linear interpolation of the source value at the target moment in time
  }
}

/* Calibrate the target time+value pair onto the source timeline */
static double* calibrateValues(double* sourceTimeLine, double* targetTimeLine, double* targetValues, size_t *nsource, size_t ntarget, double xabstol)
{
  double* interpolatedValues;
  int j, i;
  double x0, x1, y0, y1;
  size_t n;

  if (0 == nsource) {
    return NULL;
  }

  n = *nsource;
  interpolatedValues = (double*) omc_alloc_interface.malloc_atomic(sizeof(double)*n);

  j = 1;
  for (i = 0; i < n; i++) {
    double x = sourceTimeLine[i];

    if (targetTimeLine[j] > sourceTimeLine[n - 1] && targetTimeLine[j-1] > sourceTimeLine[n - 1]) { // Avoid extrapolation by cutting the sequence
      interpolatedValues[i] = linearInterpolation(x,x0,x1,y0,y1,xabstol);
      *nsource = i+1;
      break;
    }

    x1 = targetTimeLine[j];
    y1 = targetValues[j];

    while ((x1 <= x) && ((j + 1) < ntarget)) { // step source timline to the current moment
      j++;
      x1 = targetTimeLine[j];
      y1 = targetValues[j];
      if (almostEqualRelativeAndAbs(x1,x,0,xabstol)) {
        break;
      }
    }
    x0 = targetTimeLine[j - 1];
    y0 = targetValues[j - 1];
    if (i && almostEqualRelativeAndAbs(sourceTimeLine[i-1],x0,0,xabstol) && almostEqualRelativeAndAbs(x0,x1,0,xabstol)) {
      /* Previous value was the left limit of the event; use the right limit! */
      interpolatedValues[i] = y1;
    } else {
      interpolatedValues[i] = linearInterpolation(x,x0,x1,y0,y1,xabstol);
    }
  }

  return interpolatedValues;
}

typedef struct {
  double *time;
  double *values;
  size_t size;
} addTargetEventTimesRes;

static size_t findNextEvent(size_t i, double *time, size_t n, double xabstol)
{
  for (; i < n; i++) {
    if (almostEqualRelativeAndAbs(time[i-1],time[i],0,xabstol) || (i<n-1 && almostEqualRelativeAndAbs(time[i],time[i+1],0,xabstol))) return i;
  }
  return 0; /* Not found */
}

static addTargetEventTimesRes addTargetEventTimes(double* sourceTimeLine, double* targetTimeLine, double *sourceValues, size_t nsource, size_t ntarget, double xabstol)
{
  addTargetEventTimesRes res;
  size_t i=0,j,count=0;
  int iter=0;
  while ((i=findNextEvent(i+1,targetTimeLine,ntarget,xabstol))) {
    if (targetTimeLine[i] >= sourceTimeLine[nsource-1]) {
      break;
    }
    count++; /* The number of found time events in the target file */
  }
  if (count == 0) {
    res.size = nsource;
    res.time = sourceTimeLine;
    res.values = sourceValues;
    return res;
  }
  res.size = nsource+count;
  res.values = omc_alloc_interface.malloc_atomic(sizeof(double)*res.size);
  res.time = omc_alloc_interface.malloc_atomic(sizeof(double)*res.size);
  i=0;
  count=0;
  j=findNextEvent(1,targetTimeLine,ntarget,xabstol);
  while (j) {
    if (targetTimeLine[j] >= sourceTimeLine[nsource-1]) {
      break;
    }
    while (sourceTimeLine[i] < targetTimeLine[j] && i<nsource) {
      res.values[count] = sourceValues[i];
      res.time[count++] = sourceTimeLine[i++];
    }
    if (sourceTimeLine[i] == targetTimeLine[j]) {
      res.size--; /* Filter events at identical times in both files */
    } else {
      double x0 = sourceTimeLine[intmax(0,i-1)];
      double y0 = sourceValues[intmax(0,i-1)];
      double x1 = sourceTimeLine[i];
      double y1 = sourceValues[i];
      double x = targetTimeLine[j];
      double y = linearInterpolation(x,x0,x1,y0,y1,xabstol);
      res.values[count] = y;
      res.time[count++] = x;
    }
    assert(count < res.size);
    j=findNextEvent(j+1,targetTimeLine,ntarget,xabstol);
    iter++;
  }
  while (i < nsource) {
    res.values[count] = sourceValues[i];
    res.time[count++] = sourceTimeLine[i++];
  }
  assert(res.size == count);
  return res;
}

static addTargetEventTimesRes mergeTimelines(addTargetEventTimesRes ref, addTargetEventTimesRes actual, double xabstol)
{
  int i=0,j=0,count=0;
  addTargetEventTimesRes res;
  res.size = ref.size + actual.size;
  res.values = omc_alloc_interface.malloc_atomic(sizeof(double)*res.size);
  res.time = omc_alloc_interface.malloc_atomic(sizeof(double)*res.size);
  res.values[count] = ref.values[0];
  res.time[count++] = ref.time[0];
  for (i=1; i<ref.size; i++) {
    double x0 = ref.time[i-1];
    double y0 = ref.values[i-1];
    double x1 = ref.time[i];
    double y1 = ref.values[i];
    while (j<actual.size && actual.time[j] <= x1) {
      double x = actual.time[j];
      int isEventInRef = almostEqualRelativeAndAbs(x0,x1,0,xabstol);
      int isEventInActual = j<actual.size-1 && almostEqualRelativeAndAbs(x,actual.time[j+1],0,xabstol);
      int isEvent = isEventInRef || isEventInActual;
      if ((almostEqualRelativeAndAbs(x,x0,0,xabstol) || almostEqualRelativeAndAbs(x,x1,0,xabstol)) && !isEvent) {
        /* Not an event but we got the same time stamp; skip! */
        j++;
        continue;
      }
      res.time[count] = x;
      res.values[count++] = linearInterpolation(x,x0,x1,y0,y1,xabstol);
      j++;
    }
    res.time[count] = x1;
    res.values[count++] = y1;
    assert(count <= res.size);
  }
  res.size = count;
  return res;
}

static addTargetEventTimesRes removeUneventfulPoints(addTargetEventTimesRes in, double reltol, double xabstol)
{
  int i;
  addTargetEventTimesRes res;
  res.values = (double*) omc_alloc_interface.malloc_atomic(in.size * sizeof(double));
  res.time = (double*) omc_alloc_interface.malloc_atomic(in.size * sizeof(double));

  do {
    int iter = 0;
    /* Don't remove first point */
    res.values[0] = in.values[0];
    res.time[0] = in.time[0];
    res.size = 1;
    for (i=1; i<in.size-1; i++) {
      double x0 = res.time[res.size-1];
      double y0 = res.values[res.size-1];
      double x = in.time[i];
      double y = in.values[i];
      double x1 = in.time[i+1];
      double y1 = in.values[i+1];
      if (y0 == y1 && y == y0) {
        res.time[res.size] = x1;
        res.values[res.size] = y1;
        res.size++;
        i++;
        if (i < in.size-2) {
          iter=1;
        }
        continue;
      }
      res.time[res.size] = x;
      res.values[res.size] = y;
      res.size++;
    }
    if (in.size > 1) {
      /* Don't remove last point */
      res.values[res.size] = in.values[in.size-1];
      res.time[res.size] = in.time[in.size-1];
      res.size++;
    }
    if (iter) {
      /* This is ok, because we only remove the current element we iterate over; we could do this in-place but we avoid copying the initial array (which we want to remain as is) */
      in = res;
      reltol = 0;
    } else {
      /* no more recursion */
      break;
    }
  } while (1);
  return res;
}

/* Adds a relative tolerance compared to the reference signal. Overwrites the target values vector. */
static void addRelativeTolerance(double *targetValues, double *sourceValues, size_t length, double reltol, double abstol, int direction)
{
  int i;
  if (direction > 0) {
    for (i=0; i<length; i++) {
      targetValues[i] = fmax(sourceValues[i] + fmax(fabs(sourceValues[i]*reltol),abstol), targetValues[i]);
    }
  } else {
    for (i=0; i<length; i++) {
      targetValues[i] = fmin(sourceValues[i] - fmax(fabs(sourceValues[i]*reltol),abstol), targetValues[i]);
    }
  }
}

static void assertMonotonic(addTargetEventTimesRes series)
{
  int i;
  for (i=1; i<series.size; i++) {
    if (series.time[i] < series.time[i-1]) {
      printf("assertion failed, size %ld: %.15g < %.15g\n", series.size, series.time[i], series.time[i-1]);
      abort();
    }
  }
}

/* Return NULL if there were no errors */
static double* validate(int n, addTargetEventTimesRes ref, double *low, double *high, double *calibrated_values, double reltol, double abstol, double xabstol)
{
  double *error = omc_alloc_interface.malloc_atomic(n * sizeof(double));
  int isdifferent = 0;
  int i,lastStepError = 1;
  for (i=0; i<n; i++) {
    int thisStepError = 0;
    int isEvent = (i && almostEqualRelativeAndAbs(ref.time[i],ref.time[i-1],0,xabstol)) || (i+1<n && almostEqualRelativeAndAbs(ref.time[i],ref.time[i+1],0,xabstol));
    if (isEvent) {
      double refv = ref.values[i];
      double val = calibrated_values[i];
      double tol = fmax(abstol*10,fmax(fabs(refv),fabs(val))*reltol*10);
      /* If there was no error in the last step before the event, give a nice tight curve around both values */
      high[i] = (lastStepError ? refv : fmax(refv,val)) + tol;
      low[i] = (lastStepError ? refv : fmin(refv,val)) - tol;
      error[i] = NAN;
    } else {
      error[i] = 0;
      thisStepError=lastStepError;
      if (calibrated_values[i] < low[i]) {
        error[i] = low[i]-calibrated_values[i];
        isdifferent++;
        thisStepError=1;
      } else if (calibrated_values[i] > high[i]) {
        error[i] = calibrated_values[i]-high[i];
        isdifferent++;
        thisStepError=1;
      }
    }
    lastStepError = thisStepError;
  }
  if (isdifferent) {
    return error;
  }
  return NULL;
}

static unsigned int cmpDataTubes(int isResultCmp, char* varname, DataField *time, DataField *reftime, DataField *data, DataField *refdata, double reltol, double rangeDelta, double reltolDiffMaxMin, DiffDataField *ddf, char **cmpdiffvars, unsigned int vardiffindx, int keepEqualResults, void **diffLst, const char *prefix, int isHtml, char **htmlOut)
{
  int withTubes = 0 == rangeDelta;
  FILE *fout = NULL;
  char *fname = NULL;
  char *html;
  /* The tolerance for detecting events is proportional to the number of output points in the file */
  double xabstol = (reftime->data[reftime->n-1]-reftime->data[0])*(withTubes ? rangeDelta : 1e-3) / fmax(time->n,reftime->n);
  /* Calculate the tubes without additional events added */
  addTargetEventTimesRes ref,actual,actualoriginal;
  privates *priv=NULL;
  size_t n,maxn,html_size=0;
  double *calibrated_values=NULL, *high=NULL, *low=NULL, *error=NULL,maxPlusTol,minMinusTol,abstol;

  ref.values = refdata->data;
  ref.time = reftime->data;
  ref.size = reftime->n;
  actualoriginal.values = data->data;
  actualoriginal.time = time->data;
  actualoriginal.size = time->n;
  actual = actualoriginal;
  /* assertMonotonic(ref); */
  /* assertMonotonic(actual); */
  /* ref = removeUneventfulPoints(ref, reltol*reltol, xabstol); */
  /* actual = removeUneventfulPoints(actual, reltol*reltol, xabstol); */
  /* assertMonotonic(ref); */
  /* assertMonotonic(actual); */
  priv = withTubes ? skipCalculateTubes(ref.time,ref.values,ref.size) : calculateTubes(ref.time,ref.values,ref.size,rangeDelta);
  /* ref = mergeTimelines(ref,actual,xabstol); */
  /* assertMonotonic(ref); */
  n = ref.size;
  calibrated_values = calibrateValues(ref.time,actual.time,actual.values,&n,actual.size,xabstol);
  maxPlusTol = priv->max + fabs(priv->max) * reltol;
  minMinusTol = priv->min - fabs(priv->min) * reltol;
  high = calibrateValues(ref.time,priv->xHigh,priv->yHigh,&n,priv->countHigh,xabstol);
  low  = calibrateValues(ref.time,priv->xLow,priv->yLow,&n,priv->countLow,xabstol);
  /* If all values in the reference are ~0 (and the same)... Allow reltolDiffMaxMin^2 as tolerance
   * Maybe we should just treat it differently though
   * Like not creating a tubes and simply check that the other file also has only identical points close to this
   */
  abstol = (priv->max-priv->min == 0 && priv->max < reltolDiffMaxMin*reltolDiffMaxMin) ? reltolDiffMaxMin*reltolDiffMaxMin : fabs((priv->max-priv->min)*reltolDiffMaxMin);
  addRelativeTolerance(high,ref.values,n,reltol,abstol,1);
  addRelativeTolerance(low ,ref.values,n,reltol,abstol,-1);
  error = validate(n,ref,low,high,calibrated_values,reltol,abstol,xabstol);
  if ( isHtml ) {

#if _XOPEN_SOURCE >= 700 || _POSIX_C_SOURCE >= 200809L
    html_size=0;
    fout = open_memstream(&html, &html_size);
#else
    fname = (char*) omc_alloc_interface.malloc_atomic(25 + strlen(varname));
    sprintf(fname, "tmp.%s.html.tmp", varname);
    fout = fopen(fname, "wb+");
    if (!fout)
    {
      perror("Error opening temp file"); fflush(stderr);
    }
#endif

    fprintf(fout, "<html>\n"
"<head>\n"
"<script type=\"text/javascript\" src=\"dygraph-combined.js\"></script>\n"
"    <style type=\"text/css\">\n"
"    #graphdiv {\n"
"      position: absolute;\n"
"      left: 10px;\n"
"      right: 10px;\n"
"      top: 40px;\n"
"      bottom: 10px;\n"
"    }\n"
"    </style>\n"
"</head>\n"
"<body>\n"
"<div id=\"graphdiv\"></div>\n"
"<p>"
"<input type=checkbox id=\"0\" checked onClick=\"change(this)\">\n"
"<label for=\"0\">reference</label>\n"
"<input type=checkbox id=\"1\" checked onClick=\"change(this)\">\n"
"<label for=\"1\">actual</label>\n"
"<input type=checkbox id=\"2\" checked onClick=\"change(this)\">\n"
"<label for=\"2\">high</label>\n"
"<input type=checkbox id=\"3\" checked onClick=\"change(this)\">\n"
"<label for=\"3\">low</label>\n"
"<input type=checkbox id=\"4\" checked onClick=\"change(this)\">\n"
"<label for=\"4\">error</label>\n"
"<input type=checkbox id=\"5\" onClick=\"change(this)\">\n"
"<label for=\"5\">actual (original)</label>\n"
"Reference time: %.15g to %.15g, actual time: %.15g to %.15g. Parameters used for the comparison: Relative tolerance %.2g. Absolute tolerance %.2g (%.2g relative). Range delta %.2g."
"</p>\n"
"<script type=\"text/javascript\">\n"
"g = new Dygraph(document.getElementById(\"graphdiv\"),\n"
"[\n",
  reftime->data[0],
  reftime->data[reftime->n-1],
  time->data[0],
  time->data[time->n-1],
  reltol,
  abstol,
  reltolDiffMaxMin,
  rangeDelta
);
  } else if (!isResultCmp && (error || keepEqualResults)) {
    fname = (char*) omc_alloc_interface.malloc_atomic(25 + strlen(prefix) + strlen(varname));
    sprintf(fname, "%s.%s.csv", prefix, varname);
    fout = fopen(fname,"w");
  }
  maxn = intmax(intmax(intmax(ref.size,actual.size),priv->countHigh),priv->countLow);
  if (fout) {
    int i;
    const char *empty = isHtml ? "null" : "";
    const char *lbracket = isHtml ? "[" : "";
    const char *rbracket = isHtml ? "]," : "";
    int j=0;
    int lastStepError = 1;
    if (!isHtml) {
      fputs("time,reference,actual,high,low,error,actual (raw)\n", fout);
    }
    for (i=0; i<ref.size; i++) {
      int thisStepError = 0;
      fprintf(fout, "%s%.15g,%.15g,",lbracket,ref.time[i],ref.values[i]);
      if (i < n) {
        if (!error || isnan(error[i])) {
          fprintf(fout, "%.15g,%.15g,%.15g,%s",calibrated_values[i],high[i],low[i],empty);
        } else {
          fprintf(fout, "%.15g,%.15g,%.15g,%.15g",calibrated_values[i],high[i],low[i],error[i]);
        }
        if (j < actualoriginal.size && ref.time[i] == actualoriginal.time[j]) {
          fprintf(fout, ",%.15g%s\n",actualoriginal.values[j++],rbracket);
        } else {
          fprintf(fout, ",%s%s\n",empty,rbracket);
        }
      } else {
        fputs(isHtml ? "null,null,null,null,null],\n" : ",,,,\n", fout);
      }
      while (j < actualoriginal.size && ref.time[i] > actualoriginal.time[j]) {
        fprintf(fout, "%s%.15g,%s,%s,%s,%s,%s,%.15g%s\n",lbracket,actualoriginal.time[j],empty,empty,empty,empty,empty,actualoriginal.values[j],rbracket);
        j++;
      }
      lastStepError = thisStepError;
    }
    fputs(isHtml ? "],\n" : "\n", fout);
  }
  if (error) {
    cmpdiffvars[vardiffindx] = varname;
    vardiffindx++;
    if (!isResultCmp) {
      *diffLst = mmc_mk_cons(mmc_mk_scon(varname),*diffLst);
    }
  }
  if (fout) {
    if (isHtml) {
fprintf(fout, "{title: '%s',\n"
"legend: 'always',\n"
"xlabel: ['time'],\n"
"connectSeparatedPoints: true,\n"
"labels: ['time','reference','actual','high','low','error','actual (original)'],\n"
"y2label: ['error'],\n"
"series : { 'error': { axis: 'y2' } },\n"
"colors: ['blue','red','teal','lightblue','orange','black'],\n"
"visibility: [true,true,true,true,true,false]\n"
"});\n"
"function change(el) {\n"
"  g.setVisibility(parseInt(el.id), el.checked);\n"
"}\n"
"</script>\n"
"</body>\n"
"</html>\n", varname);
    }

    if (isHtml) {
#if !(_XOPEN_SOURCE >= 700 || _POSIX_C_SOURCE >= 200809L)
      size_t r;
      if (fseek(fout, 0, SEEK_END))
      {
        perror("Error on fseek end!");
      }
      html_size = ftell(fout);
      if (fseek(fout, 0, SEEK_SET))
      {
        perror("Error on fseek set!");
      }
      html = (char*)malloc((html_size + 1) * sizeof(char));
      r = fread(html, sizeof(char), html_size, fout);
      if (r != html_size)
      {
        perror("Error on fread!");
      }
      html[html_size] = '\0';
      fclose(fout);
      unlink(fname);
#else
      fclose(fout);
#endif
      *htmlOut = omc_alloc_interface.malloc_strdup(html);
      free(html);
    }
    else
    {
      fclose(fout);
    }
  }
  /* Tell the GC some variables have been free'd */
  if (error) GC_free(error);
  if (fname) GC_free(fname);
  GC_free(low);
  GC_free(high);
  if (withTubes) {
    GC_free(priv->mh);
    GC_free(priv->i0h);
    GC_free(priv->i1h);
    GC_free(priv->ml);
    GC_free(priv->i0l);
    GC_free(priv->i1l);
    GC_free(priv->xHigh);
    GC_free(priv->xLow);
  }
  GC_free(priv->yHigh);
  GC_free(priv->yLow);
  GC_free(priv);
  GC_free(calibrated_values);
  return vardiffindx;
}
