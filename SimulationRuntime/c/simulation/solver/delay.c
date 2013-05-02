/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2008, Linköping University,
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
 * from Linköping University, either from the above address,
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
#include "omc_error.h"
#include "simulation_data.h"
#include "ringbuffer.h"
#include "openmodelica.h"

#include <stdio.h>
#include <stdlib.h>


/* the delayStructure looks like a matrix (rows = expressionNumber+currentColumnIndex, columns={time, value}) */


void initDelay(DATA* data, double startTime)
{
  /* get the start time of the simulation: time.start. */
  data->simulationInfo.tStart = startTime;
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


  INFO1(LOG_EVENTS, "findTime %e", time);
  do
  {
    int i = (start + end) / 2;
    t = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->time;
    INFO4(LOG_EVENTS, "time(%d, %d)[%d] = %e", start, end, i, t);
    if(t > time)
      end = i;
    else
      start = i;
  }while(t != time && end > start + 1);
  INFO3(LOG_EVENTS, "return time[%d, %d] = %e", start, end, t);
  return (start);
}

void storeDelayedExpression(DATA* data, int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  int i;
  TIME_AND_VALUE tpl;

  /* Allocate more space for expressions */
  ASSERT1(exprNumber < data->modelData.nDelayExpressions, "storeDelayedExpression: invalid expression number %d", exprNumber);
  ASSERT1(0 <= exprNumber, "storeDelayedExpression: invalid expression number %d", exprNumber);
  ASSERT(data->simulationInfo.tStart <= time, "storeDelayedExpression: time is smaller than starting time. Value ignored");

  tpl.time = time;
  tpl.value = exprValue;
  appendRingData(data->simulationInfo.delayStructure[exprNumber], &tpl);
  INFO4(LOG_EVENTS, "storeDelayed[%d] %g:%g position=%d", exprNumber, time, exprValue,ringBufferLength(data->simulationInfo.delayStructure[exprNumber]));

  /* dequeue not longer needed values */
  i = findTime(time-delayMax+DBL_EPSILON,data->simulationInfo.delayStructure[exprNumber]);
  if(i > 0){
    dequeueNFirstRingDatas(data->simulationInfo.delayStructure[exprNumber], i-1);
    INFO3(LOG_EVENTS, "delayImpl: dequeueNFirstRingDatas[%d] %g = %g", i, time-delayMax+DBL_EPSILON, delayTime);
  }
}


double delayImpl(DATA* data, int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  RINGBUFFER* delayStruct = data->simulationInfo.delayStructure[exprNumber];
  int length = ringBufferLength(delayStruct);

  INFO4(LOG_EVENTS, "delayImpl: exprNumber = %d, exprValue = %g, time = %g, delayTime = %g", exprNumber, exprValue, time, delayTime);

  /* Check for errors */

  ASSERT1(0 <= exprNumber, "invalid exprNumber = %d", exprNumber);
  ASSERT1(exprNumber < data->modelData.nDelayExpressions, "invalid exprNumber = %d", exprNumber);

  if(time <= data->simulationInfo.tStart)
  {
    INFO1(LOG_EVENTS, "delayImpl: Entered at time < starting time: %g.", exprValue);
    return (exprValue);
  }

  if(delayTime < 0.0)
  {
    ASSERT1(0.0 < delayTime, "Negative delay requested: delayTime = %g", delayTime);
    THROW("Negative delay requested");
  }

  if(length == 0)
  {
    /*  This occurs in the initialization phase */
    INFO1(LOG_EVENTS, "delayImpl: Missing initial value, using argument value %g instead.", exprValue);
    return (exprValue);
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
  if(time <= data->simulationInfo.tStart + delayTime)
  {
    double res = ((TIME_AND_VALUE*)getRingData(delayStruct, 0))->value;
    INFO2(LOG_EVENTS, "findTime: time <= tStart + delayTime: [%d] = %g",exprNumber, res);
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
      INFO2(LOG_EVENTS, "delayImpl: find the row  %g = %g", timeStamp, ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->time);
      /* delay between the last accepted time step and the current time */
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->time;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->value;
      time1 = time;
      value1 = exprValue;
      INFO2(LOG_EVENTS, "delayImpl: times %g and %g", time0, time1);
      INFO2(LOG_EVENTS, "delayImpl: values %g and  %g", value0, value1);
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
        return value0;
      }
      time1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->time;
      value1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->value;
    }
    /* was it an exact match?*/
    if(time0 == timeStamp){
      INFO2(LOG_EVENTS, "delayImpl: Exact match at %g = %g", timeStamp, value0);

      return value0;
    } else if(time1 == timeStamp) {
      INFO2(LOG_EVENTS, "delayImpl: Exact match at %g = %g", timeStamp, value1);

      return value1;
    } else {
      /* linear interpolation */
      double timedif = time1 - time0;
      double dt0 = time1 - timeStamp;
      double dt1 = timeStamp - time0;
      double retVal = (value0 * dt0 + value1 * dt1) / timedif;
      INFO3(LOG_EVENTS, "delayImpl: Linear interpolation of %g between %g and %g", timeStamp, time0, time1);
      INFO4(LOG_EVENTS, "delayImpl: Linear interpolation of %g value: %g and %g = %g", timeStamp, value0, value1, retVal);
      return retVal;
    }
  }

}

