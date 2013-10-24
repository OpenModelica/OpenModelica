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

    priv->i0h[index-1] = priv->i0h[index]; /* Remove the second to last element */
    priv->countHigh--; /* Remove the last element for priv->i1h and priv->mh, priv->xHigh and priv->yHigh */


    /* calculation of the new slope (3.2.6.3.3) */
    double x3 = x[priv->i0h[index - 1]];  /* = _dX1 */
    double y3 = y[priv->i0h[index - 1]];  /* = _dY1 */
    double x4 = x[priv->i1h[index - 1]];  /* < X3 */
    double y4 = y[priv->i1h[index - 1]];

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
    while (/* Avoid underflow. Should this generate an error instead? */ index && priv->xHigh[index] <= priv->xHigh[index - 1]) {
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
        m2 = priv->mh[index - 1];
        double x3 = priv->xHigh[index - 1];
        double y3 = priv->yHigh[index - 1];

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
    priv->i0l[index-1] = priv->i0l[index];
    priv->countLow--;

    double x3 = x[priv->i0l[index - 1]];  /* = _dX1 */
    double y3 = y[priv->i0l[index - 1]];  /* = _dY1 */
    double x4 = x[priv->i1l[index - 1]];  /* < X3 */
    double y4 = y[priv->i1l[index - 1]];

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

    while (index /* Avoid underflow. Should this generate an error instead? */ && priv->xLow[index] <= priv->xLow[index - 1]) {
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
        m2 = priv->ml[index - 1];
        double x3 = priv->xLow[index - 1];
        double y3 = priv->yLow[index - 1];
        priv->xLow[index] = (m2 * x3 - m1 * priv->x2 + priv->y2 - y3 - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) / (m2 - m1);
        priv->yLow[index] = (m2 * m1 * (x3 - priv->x2) + m2 * (priv->y2 - priv->delta * sqrt((m1 * m1) + (priv->S * priv->S))) - m1 * y3) / (m2 - m1);
      }
    }
  }
}

/* This method generates tubes around a given curve */
static privates* calculateTubes(double *x, double *y, size_t length, double r)
{
  privates *priv = (privates*) GC_malloc(sizeof(privates));
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
  priv->mh  = (double*)GC_malloc_atomic(sizeof(double)*length);
  priv->i0h = (int*)GC_malloc_atomic(sizeof(int)*length);
  priv->i1h = (int*)GC_malloc_atomic(sizeof(int)*length);
  /* Initialize lists (lower tube) */
  priv->ml  = (double*)GC_malloc_atomic(sizeof(double)*length);
  priv->i0l = (int*)GC_malloc_atomic(sizeof(int)*length);
  priv->i1l = (int*)GC_malloc_atomic(sizeof(int)*length);

  priv->xHigh = (double*)GC_malloc_atomic(sizeof(double)*length);
  priv->xLow  = (double*)GC_malloc_atomic(sizeof(double)*length);
  priv->yHigh = (double*)GC_malloc_atomic(sizeof(double)*length);
  priv->yLow  = (double*)GC_malloc_atomic(sizeof(double)*length);

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

/* Count the number of errors */
static int validate(int n, double *low, double *high, double *val)
{
  int iErrors = 0, i;
  for (i = 0; i < n; i++) {
    if (val[i] < low[i] || val[i] > high[i]) {
      iErrors++; //Count as error if current value is bigger than value of high tube and smaller than value of lowtube
    }
  }
  return iErrors;
}

/* Calibrate the target time+value pair onto the source timeline */
static double* calibrateValues(double* sourceTimeLine, double* targetTimeLine, double* targetValues, size_t *nsource, size_t ntarget)
{
  if (0 == nsource) {
    return NULL;
  }

  double* interpolatedValues = (double*) GC_malloc_atomic(sizeof(double)**nsource);

  int j = 1, i;
  double x, x0, x1, y0, y1;
  size_t n = *nsource;

  for (i = 0; i < n; i++) {
    x = sourceTimeLine[i];

    if (targetTimeLine[j] > sourceTimeLine[n - 1]) { // Avoid extrapolation by cutting the sequence
      *nsource = i;
      break;
    }

    x1 = targetTimeLine[j];
    y1 = targetValues[j];

    while (x1 <= x && j + 1 < ntarget) { // step source timline to the current moment
      j++;
      x1 = targetTimeLine[j];
      y1 = targetValues[j];
      if (x1 == x) {
        break; /* Consume at most one if equal */
      }
    }

    x0 = targetTimeLine[j - 1];
    y0 = targetValues[j - 1];

    if (((x1 - x0) * (x - x0)) != 0) { //prevent NaN -> division by zero
      interpolatedValues[i] = y0 + (((y1 - y0) / (x1 - x0)) * (x - x0)); // linear interpolation of the source value at the target moment in time
    } else {
      interpolatedValues[i] = y0;
    }
  }

  return interpolatedValues;
}

typedef struct {
  double *time;
  double *values;
  size_t size;
} addTargetEventTimesRes;

static inline size_t findNextEvent(size_t i, double *time, size_t n)
{
  for (i; i < n; i++) {
    if (AlmostEqualRelativeAndAbs(time[i-1],time[i])) return i;
  }
  return 0; /* Not found */
}

static addTargetEventTimesRes addTargetEventTimes(double* sourceTimeLine, double* targetTimeLine, double *sourceValues, size_t nsource, size_t ntarget)
{
  addTargetEventTimesRes res;
  size_t i=0,j,count=0;
  while (i=findNextEvent(i+1,targetTimeLine,ntarget)) {
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
  res.values = GC_malloc_atomic(sizeof(double)*res.size);
  res.time = GC_malloc_atomic(sizeof(double)*res.size);
  i=0;
  count=0;
  int iter=0;
  j=findNextEvent(1,targetTimeLine,ntarget);
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
      res.values[count] = sourceValues[intmax(0,i-1)];
      res.time[count++] = targetTimeLine[j];
    }
    assert(count < res.size);
    j=findNextEvent(j+1,targetTimeLine,ntarget);
    iter++;
  }
  while (i < nsource) {
    res.values[count] = sourceValues[i];
    res.time[count++] = sourceTimeLine[i++];
  }
  assert(res.size == count);
  return res;
}

/* Adds a relative tolerance compared to the reference signal. Overwrites the target values vector. */
static inline void addRelativeTolerance(double *targetValues, double *sourceValues, double length, double reltol, int direction)
{
  int i;
  if (direction > 0) {
    for (i=0; i<length; i++) {
      targetValues[i] = fmax(sourceValues[i] + fabs(sourceValues[i]*reltol), targetValues[i]);
    }
  } else {
    for (i=0; i<length; i++) {
      targetValues[i] = fmin(sourceValues[i] - fabs(sourceValues[i]*reltol), targetValues[i]);
    }
  }
}

static unsigned int cmpDataTubes(int isResultCmp, char* varname, DataField *time, DataField *reftime, DataField *data, DataField *refdata, double reltol, double rangeDelta, DiffDataField *ddf, char **cmpdiffvars, unsigned int vardiffindx, int keepEqualResults, void **diffLst, const char *prefix)
{
  int i, isdifferent = 0;
  FILE *fout = NULL;
  char *fname = NULL;
  addTargetEventTimesRes ref = addTargetEventTimes(reftime->data, time->data, refdata->data, reftime->n, time->n);
  size_t n = ref.size;
  // calibrateValuesConsiderEventsResult calibrated = calibrateValuesConsiderEvents(ref->time,time->data,data->data,&n,time->n);
  double *calibrated_values = calibrateValues(ref.time,time->data,data->data,&n,time->n);
  privates *priv = calculateTubes(ref.time,ref.values,ref.size,rangeDelta);
  double *high = calibrateValues(ref.time,priv->xHigh,priv->yHigh,&n,priv->countHigh);
  double *low  = calibrateValues(ref.time,priv->xLow,priv->yLow,&n,priv->countLow);
  addRelativeTolerance(high,ref.values,n,reltol,1);
  addRelativeTolerance(low ,ref.values,n,reltol,-1);
  if (!isResultCmp) {
    fname = (char*) GC_malloc_atomic(25 + strlen(prefix) + strlen(varname));
    sprintf(fname, "%s.%s.csv", prefix, varname);
    fout = fopen(fname,"w");
    if (fout) {
       /*            1             2         3      4    5   6     7          8         9        10      11      12     13                  14  15  16        17   */
      fprintf(fout, "timereference,reference,actual,high,low,error,timeactual,rawactual,timehigh,rawhigh,timelow,rawlow,actual_interpolated,min,max,startTime,stopTime\n");
    }
  }
  size_t maxn = intmax(intmax(intmax(ref.size,time->n),priv->countHigh),priv->countLow);
  if (fout) {
    for (i=0; i<maxn; i++) {
      if (i < ref.size) {
       fprintf(fout, "%.15g,%.15g,",ref.time[i],ref.values[i]);
      } else {
       fprintf(fout, ",,");
      }
      if (i < n) { /* actual,high,low,error */
        fprintf(fout, "%.15g,", calibrated_values[i]);
        fprintf(fout, "%.15g,%.15g,",high[i],low[i]);
        if ((i && AlmostEqualRelativeAndAbs(ref.time[i],ref.time[i-1])) || (i+1<n && AlmostEqualRelativeAndAbs(ref.time[i],ref.time[i+1]))) {
          /* Skip calculating errors at events */
          fprintf(fout, "0,");
        } else if (calibrated_values[i] < low[i]) {
          fprintf(fout, "%.15g,", low[i]-calibrated_values[i]);
          isdifferent++;
        } else if (calibrated_values[i] > high[i]) {
          fprintf(fout, "%.15g,", calibrated_values[i]-high[i]);
          isdifferent++;
        } else {
          fprintf(fout, "0,");
        }
      } else {
        fprintf(fout, ",,,,");
      }
      if (i < time->n) {
       fprintf(fout, "%.15g,%.15g,",time->data[i],data->data[i]);
      } else {
       fprintf(fout, ",,");
      }
      if (i < priv->countHigh) {
       fprintf(fout, "%.15g,%.15g,",priv->xHigh[i],priv->yHigh[i]);
      } else {
       fprintf(fout, ",,");
      }
      if (i < priv->countLow) {
       fprintf(fout, "%.15g,%.15g,",priv->xLow[i],priv->yLow[i]);
      } else {
       fprintf(fout, ",,");
      }
      if (i==0) {
        fprintf(fout, "%.15g,%.15g,%.15g,%.15g", priv->min, priv->max, ref.time[0], ref.time[ref.size-1]);
      } else {
        fprintf(fout, ",,,");
      }
      fprintf(fout, "\n");
    }
  } else {
    isdifferent = validate(n,low,high,calibrated_values);
  }
  if (isdifferent) {
    cmpdiffvars[vardiffindx] = varname;
    vardiffindx++;
    if (!isResultCmp) {
      *diffLst = mk_cons(mk_scon(varname),*diffLst);
    }
  }
  if (fout) {
    fclose(fout);
  }
  if (!isdifferent && 0==keepEqualResults && 0==isResultCmp) {
    SystemImpl__removeFile(fname);
  }
  return vardiffindx;
}
