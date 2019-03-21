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

#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0

/*! \file delay.c
 */

#include "delay.h"
#include "../../util/omc_error.h"
#include "../../util/ringbuffer.h"
#include "../../openmodelica.h"

#include <stdio.h>
#include <stdlib.h>


/* the delayStructure looks like a matrix (rows = expressionNumber+currentColumnIndex, columns={time, value}) */


void initDelay(DATA* data, double startTime)
{
  /* get the start time of the simulation: time.start. */
  data->simulationInfo->tStart = startTime;
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


  infoStreamPrint(LOG_EVENTS_V, 0, "findTime %e", time);
  do
  {
    int i = (start + end) / 2;
    t = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->t;
    infoStreamPrint(LOG_EVENTS_V, 0, "time(%d, %d)[%d] = %e", start, end, i, t);
    if(t > time)
      end = i;
    else
      start = i;
  }while(t != time && end > start + 1);
  infoStreamPrint(LOG_EVENTS_V, 0, "return time[%d, %d] = %e", start, end, t);
  return (start);
}

void storeDelayedExpression(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  int i;
  TIME_AND_VALUE tpl;

  /* Allocate more space for expressions */
  assertStreamPrint(threadData, exprNumber < data->modelData->nDelayExpressions, "storeDelayedExpression: invalid expression number %d", exprNumber);
  assertStreamPrint(threadData, 0 <= exprNumber, "storeDelayedExpression: invalid expression number %d", exprNumber);
  assertStreamPrint(threadData, data->simulationInfo->tStart <= time, "storeDelayedExpression: time is smaller than starting time. Value ignored");

  tpl.t = time;
  tpl.value = exprValue;
  appendRingData(data->simulationInfo->delayStructure[exprNumber], &tpl);
  infoStreamPrint(LOG_EVENTS_V, 0, "storeDelayed[%d] %g:%g position=%d", exprNumber, time, exprValue,ringBufferLength(data->simulationInfo->delayStructure[exprNumber]));

  /* dequeue not longer needed values */
  i = findTime(time-delayMax+DBL_EPSILON,data->simulationInfo->delayStructure[exprNumber]);
  if(i > 0){
    dequeueNFirstRingDatas(data->simulationInfo->delayStructure[exprNumber], i-1);
    infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: dequeueNFirstRingDatas[%d] %g = %g", i, time-delayMax+DBL_EPSILON, delayTime);
  }
}


double delayImpl(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  RINGBUFFER* delayStruct = data->simulationInfo->delayStructure[exprNumber];
  int length = ringBufferLength(delayStruct);

  infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: exprNumber = %d, exprValue = %g, time = %g, delayTime = %g", exprNumber, exprValue, time, delayTime);

  /* Check for errors */

  assertStreamPrint(threadData, 0 <= exprNumber, "invalid exprNumber = %d", exprNumber);
  assertStreamPrint(threadData, exprNumber < data->modelData->nDelayExpressions, "invalid exprNumber = %d", exprNumber);

  if(time <= data->simulationInfo->tStart)
  {
    infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: Entered at time < starting time: %g.", exprValue);
    return (exprValue);
  }

  if(delayTime < 0.0)
  {
    throwStreamPrint(threadData, "Negative delay requested %g", delayTime);
  }

  if(length == 0)
  {
    /*  This occurs in the initialization phase */
    infoStreamPrint(LOG_EVENTS, 0, "delayImpl: Missing initial value, using argument value %g instead.", exprValue);
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
  if(time <= data->simulationInfo->tStart + delayTime)
  {
    double res = ((TIME_AND_VALUE*)getRingData(delayStruct, 0))->value;
    infoStreamPrint(LOG_EVENTS_V, 0, "findTime: time <= tStart + delayTime: [%d] = %g",exprNumber, res);
    return res;
  }
  else
  {
    /* return expr(time-delayTime) */
    double timeStamp = time - delayTime;
    double time0, time1, value0, value1;
    int i;

    assertStreamPrint(threadData, 0.0 <= delayTime, "Negative delay requested: delayTime = %g", delayTime);

    /* find the row for the lower limit */
    if(timeStamp > ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->t)
    {
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: find the row  %g = %g", timeStamp, ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->t);
      /* delay between the last accepted time step and the current time */
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->t;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->value;
      time1 = time;
      value1 = exprValue;
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: times %g and %g", time0, time1);
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: values %g and  %g", value0, value1);
    }
    else
    {
      i = findTime(timeStamp, delayStruct);
      assertStreamPrint(threadData, i < length, "%d = i < length = %d", i, length);
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->t;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, i))->value;

      /* was it the last value? */
      if(i+1 == length)
      {
        return value0;
      }
      time1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->t;
      value1 = ((TIME_AND_VALUE*)getRingData(delayStruct, i+1))->value;
    }
    /* was it an exact match?*/
    if(time0 == timeStamp){
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: Exact match at %g = %g", timeStamp, value0);

      return value0;
    } else if(time1 == timeStamp) {
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: Exact match at %g = %g", timeStamp, value1);

      return value1;
    } else {
      /* linear interpolation */
      double timedif = time1 - time0;
      double dt0 = time1 - timeStamp;
      double dt1 = timeStamp - time0;
      double retVal = (value0 * dt0 + value1 * dt1) / timedif;
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: Linear interpolation of %g between %g and %g", timeStamp, time0, time1);
      infoStreamPrint(LOG_EVENTS_V, 0, "delayImpl: Linear interpolation of %g value: %g and %g = %g", timeStamp, value0, value1, retVal);
      return retVal;
    }
  }

}

#endif
