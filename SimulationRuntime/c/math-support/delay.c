/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköpings University,
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

/*! \file delay.c
 */

#include "delay.h"
#include "ringbuffer.h"
#include "error.h"

#include <stdio.h>
#include <stdlib.h>

double tStart = 0;

typedef struct TIME_AND_VALUE
{
  double time;
  double value;
}TIME_AND_VALUE;

typedef struct EXPRESSION_DELAY_BUFFER
{
  long currentIndex;
  long maxExpressionBuffer;
  TIME_AND_VALUE *expressionDelayBuffer;
}EXPRESSION_DELAY_BUFFER;

/* the delayStructure looks like a matrix (rows = expressionNumber+currentColumnIndex, columns={time, value}) */
static RINGBUFFER **delayStructure;

extern const int numDelayExpressionIndex;

void initDelay(double startTime)
{
  int i;

  /* get the start time of the simulation: time.start. */
  tStart = startTime;

  /* allocate the memory for rows */
  delayStructure = (RINGBUFFER**)calloc(numDelayExpressionIndex, sizeof(RINGBUFFER*));
  ASSERT(delayStructure, "out of memory");

  for(i=0; i<numDelayExpressionIndex; i++)
    delayStructure[i] = allocRingBuffer(1024, sizeof(TIME_AND_VALUE));

  DEBUG_INFO1(LV_SOLVER, "initDelay called with startTime = %f", startTime);
}

void deinitDelay()
{
  int i;

  for(i=0; i<numDelayExpressionIndex; i++)
    freeRingBuffer(delayStructure[i]);

  free(delayStructure);
}

/*
 * Find row with greatest time that is smaller than or equal to 'time'
 * Conditions:
 *  the buffer in 'delayStruct' is not empty
 *  'time' is smaller than the last entry in 'delayStruct'
 */
static int findTime(double time, RINGBUFFER *delayStruct)
{
  int start = 0;
  int end = ringBufferLength(delayStruct);
  double t;

  do
  {
    int i = (start + end) / 2;
    t = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->time;
    if(t > time)
      end = i;
    else
      start = i;
  }while(t != time && end > start + 1);
  return start;
}

void storeDelayedExpression(int exprNumber, double exprValue, double time)
{
  TIME_AND_VALUE tpl;

  /* INFO("storeDelayed[%d] %g:%g", exprNumber, time, exprValue); */

  /* Allocate more space for expressions */
  ASSERT1(exprNumber < numDelayExpressionIndex, "storeDelayedExpression: invalid expression number %d", exprNumber);
  ASSERT1(0 <= exprNumber, "storeDelayedExpression: invalid expression number %d", exprNumber);
  ASSERT(tStart <= time, "storeDelayedExpression: time is smaller than starting time. Value ignored");

  tpl.time = time;
  tpl.value = exprValue;
  appendRingData(delayStructure[exprNumber], &tpl);
}

double delayImpl(int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  RINGBUFFER* delayStruct = delayStructure[exprNumber];
  int length = ringBufferLength(delayStruct);

  /* ERROR("delayImpl: exprNumber = %d, exprValue = %lf, time = %lf, delayTime = %lf", exprNumber, exprValue, time, delayTime); */

  /* Check for errors */
  ASSERT1(0 <= exprNumber, "invalid exprNumber = %d", exprNumber);
  ASSERT1(exprNumber < numDelayExpressionIndex, "invalid exprNumber = %d", exprNumber);

  if(time <= tStart)
  {
    /* ERROR("delayImpl: Entered at time < starting time: %g.", exprValue); */
    return exprValue;
  }

  if(delayTime < 0.0)
  {
    ASSERT1(0.0 < delayTime, "Negative delay requested: delayTime = %g", delayTime);
    THROW("Negative delay requested");
  }

  if(length == 0)
  {
    /*  This occurs in the initialization phase */
    /*  ERROR("delayImpl: Missing initial value, using argument value %g instead.", exprValue); */
    return exprValue;
  }

  /*
   * Returns: expr(time?delayTime) for time>time.start + delayTime and
   *          expr(time.start) for time <= time.start + delayTime.
   * The arguments, i.e., expr, delayTime and delayMax, need to be subtypes of Real.
   * DelayMax needs to be additionally a parameter expression.
   * The following relation shall hold: 0 <= delayTime <= delayMax,
   * otherwise an error occurs. If delayMax is not supplied in the argument list,
   * delayTime need to be a parameter expression. See also Section 3.7.2.1.
   * For non-scalar arguments the function is vectorized according to Section 10.6.12.
   */
  if(time <= tStart + delayTime)
  {
    double res = ((TIME_AND_VALUE*)getRingData(delayStruct, 0))->value;
    /* ERROR("findTime: time <= tStart + delayTime: [%d] = %g",exprNumber, res); */
    return res;
  }
  else
  {
    /* return expr(time-delayTime) */
    double timeStamp = time - delayTime;
    double time0, time1, value0, value1;
    int i;

    ASSERT1(0.0 <= delayTime, "Negative delay requested: delayTime = %g", delayTime);

    /* find the row for the lower limit */
    if(timeStamp > ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->time)
    {
      /* delay between the last accepted time step and the current time */
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->time;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->value;
      time1 = time;
      value1 = exprValue;
    }
    else
    {
      i = findTime(timeStamp, delayStruct);
      ASSERT2(i < length, "%d = i < length = %d", i, length);
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->time;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->value;

      /* was it the last value? */
      if(i+1 == length)
      {
        if(0 < i && delayMax == delayTime)
          dequeueNFirstRingDatas(delayStruct, i-1);
        return value0;
      }
      time1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->time;
      value1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->value;
      if(0 < i && delayMax == delayTime)
        dequeueNFirstRingDatas(delayStruct, i-1);
    }
    /* was it an exact match?*/
    if(time0 == timeStamp)
    {
            /* ERROR("delayImpl: Exact match at %lf", currentTime); */
            return value0;
        }
        else if(time1 == timeStamp)
        {
            return value1;
        }
        else
        {
            /* ERROR("delayImpl: Linear interpolation of %lf between %lf and %lf", timeStamp, time0, time1); */

            /* linear interpolation */
            double timedif = time1 - time0;
            double dt0 = time1 - timeStamp;
            double dt1 = timeStamp - time0;
            return (value0 * dt0 + value1 * dt1) / timedif;
        }
    }
}
