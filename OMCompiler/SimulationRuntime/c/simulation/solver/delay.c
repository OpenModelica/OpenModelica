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

/* Private prototypes */
void printDelayBuffer(void* data, int stream, void* elemPointer);


/**
 * @brief Find row with greatest time that is greater than or equal to 'time'
 *
 * So all buffer elements before returned row index need to be removed from buffer.
 *
 * @param[in] time          Time value to search for.
 * @param[in] delayStruct   Ringbuffer with stored delay values.
 *                          Looks like a matrix with columns of type TIME_AND_VALUE.
 * @param[out] foundEvent   Boolean indicating if an event was found while searching for time.
 * @return int              Row with maximum time value smaller equal to time.
 */
static int findTime(double time, RINGBUFFER *delayStruct, int* foundEvent)
{
  int end = ringBufferLength(delayStruct);
  int pos = 0;
  double curTime, prevTime;
  TIME_AND_VALUE* bufferElem;

  infoStreamPrint(LOG_DELAY, 0, "findTime %e", time);
  *foundEvent = 0 /* false */;

  /* Check if ring buffer is valid */
  assertStreamPrint(NULL, ringBufferLength(delayStruct) > 0, "delay: In function findTime\nEmpty ring buffer.");
  bufferElem = getRingData(delayStruct, pos);
  curTime = bufferElem->t;

  /* If searched time is smaller then first element return first position */
  if(time < curTime) {
    return pos;
  }

  /* Search for time starting at begin of ring buffer */
  while(pos < end-1) {
    pos++;
    bufferElem = getRingData(delayStruct, pos);
    prevTime = curTime;
    curTime = bufferElem->t;
    /* Check for an event */
    if (fabs(prevTime-curTime)< 1e-12) {
      *foundEvent = 1 /* true */;
      infoStreamPrint(LOG_EVENTS, 0, "Found event stored at time %f while searching for %f", curTime, time);
      plotRingBuffer(delayStruct, LOG_UTIL, printDelayBuffer);
    }
    if (curTime > time) {
      pos--;
      // Found time in previous step
      break;
    }
  }
  assertStreamPrint(NULL, pos < end, "delay: In function findTime\nCould not find time");

  infoStreamPrint(LOG_DELAY, 0, "return time[%d, %d] = %e", pos, end, curTime);
  return pos;
}


/**
 * @brief Store expression value in delay.
 *
 * @param data          Storing all simulation/model data.
 * @param threadData    Used for error handling.
 * @param exprNumber    Index of delay.
 * @param exprValue     Value to store in delay ringbuffer.
 * @param delayTime     Time to delay expValue.
 * @param delayMax      Maximum allowed delay time, defaults to delayTime.
 */
void storeDelayedExpression(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double delayTime, double delayMax)
{
  int row;
  int foundEvent;
  int length = ringBufferLength(data->simulationInfo->delayStructure[exprNumber]);
  double time = data->localData[0]->timeValue;
  TIME_AND_VALUE tpl;
  TIME_AND_VALUE* lastElem;

  assertStreamPrint(threadData, exprNumber < data->modelData->nDelayExpressions, "storeDelayedExpression: invalid expression number %d", exprNumber);
  assertStreamPrint(threadData, 0 <= exprNumber, "storeDelayedExpression: invalid expression number %d", exprNumber);
  assertStreamPrint(threadData, data->simulationInfo->startTime <= time, "storeDelayedExpression: time is smaller than starting time.");

  /* Check if time is greater equal then last stored time in delay structure */
  if (length > 0) {
    lastElem = getRingData(data->simulationInfo->delayStructure[exprNumber], length-1);
    while (time < lastElem->t) {
      removeLastRingData(data->simulationInfo->delayStructure[exprNumber],1);
      length = ringBufferLength(data->simulationInfo->delayStructure[exprNumber]);
      lastElem = getRingData(data->simulationInfo->delayStructure[exprNumber], length-1);
    }
  }

  /* Check if (time,value) pair is already saved
   * This should happen after an event was found and the event iteration finished */
  if (length > 0) {
    if (fabs(lastElem->t-time) < 1e-12 && fabs(lastElem->value-exprValue) < DBL_EPSILON) {
      /* Remove stuff that is not needed any more */
      row = findTime(time-delayTime+DBL_EPSILON, data->simulationInfo->delayStructure[exprNumber], &foundEvent);
      if(row > 0){
        dequeueNFirstRingDatas(data->simulationInfo->delayStructure[exprNumber], row);
      }
      return;
    }
  }

  /* Append expression value to delay ring buffer */
  tpl.t = time;
  tpl.value = exprValue;
  appendRingData(data->simulationInfo->delayStructure[exprNumber], &tpl);

  /* Dequeue not longer needed values from ring buffer */
  row = findTime(time-delayTime+DBL_EPSILON, data->simulationInfo->delayStructure[exprNumber], &foundEvent);
  if(foundEvent) {
    infoStreamPrint(LOG_EVENTS, 0, "Current time: %f.", data->localData[0]->timeValue);
  }
  if(row > 0 && !foundEvent){
    dequeueNFirstRingDatas(data->simulationInfo->delayStructure[exprNumber], row);
  }

  /* Debug print */
  infoStreamPrint(LOG_DELAY, 0, "storeDelayed[%d] (%g,%g) position=%d", exprNumber, time, exprValue, ringBufferLength(data->simulationInfo->delayStructure[exprNumber]));
  plotRingBuffer(data->simulationInfo->delayStructure[exprNumber], LOG_DELAY, printDelayBuffer);
}


double delayImpl(DATA* data, threadData_t *threadData, int exprNumber, double exprValue, double time, double delayTime, double delayMax)
{
  RINGBUFFER* delayStruct = data->simulationInfo->delayStructure[exprNumber];
  int length = ringBufferLength(delayStruct);
  int foundEvent;

  infoStreamPrint(LOG_DELAY, 0, "delayImpl: exprNumber = %d, exprValue = %g, time = %g, delayTime = %g", exprNumber, exprValue, time, delayTime);

  /* Check for errors */

  assertStreamPrint(threadData, 0 <= exprNumber, "invalid exprNumber = %d", exprNumber);
  assertStreamPrint(threadData, exprNumber < data->modelData->nDelayExpressions, "invalid exprNumber = %d", exprNumber);

  if(time <= data->simulationInfo->startTime)
  {
    infoStreamPrint(LOG_DELAY, 0, "delayImpl: Entered at time < starting time: %g.", exprValue);
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
  if(time <= data->simulationInfo->startTime + delayTime)
  {
    double res = ((TIME_AND_VALUE*)getRingData(delayStruct, 0))->value;
    infoStreamPrint(LOG_DELAY, 0, "findTime: time <= tStart + delayTime: [%d] = %g",exprNumber, res);
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
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: find the row  %g = %g", timeStamp, ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->t);
      /* delay between the last accepted time step and the current time */
      time0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->t;
      value0 = ((TIME_AND_VALUE*)getRingData(delayStruct, length - 1))->value;
      time1 = time;
      value1 = exprValue;
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: times %g and %g", time0, time1);
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: values %g and  %g", value0, value1);
    }
    else
    {
      i = findTime(timeStamp, delayStruct, &foundEvent);
      if (foundEvent) {
        // TODO: Do something if an event was found!
      }

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
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: Exact match at %g = %g", timeStamp, value0);

      return value0;
    } else if(time1 == timeStamp) {
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: Exact match at %g = %g", timeStamp, value1);

      return value1;
    } else {
      /* linear interpolation */
      double timedif = time1 - time0;
      double dt0 = time1 - timeStamp;
      double dt1 = timeStamp - time0;
      double retVal = (value0 * dt0 + value1 * dt1) / timedif;
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: Linear interpolation of %g between %g and %g", timeStamp, time0, time1);
      infoStreamPrint(LOG_DELAY, 0, "delayImpl: Linear interpolation of %g value: %g and %g = %g", timeStamp, value0, value1, retVal);
      return retVal;
    }
  }
}


/**
 * @brief Returns value of zero crossing at current simulation time.
 *
 *
 * @param data            Storing all simulation/model data.
 * @param threadData      Used for error handling.
 * @param exprNumber      Index of delay.
 * @param relationIndex   Index of relation used for zero crossing.
 * @param delayValue      Value to store in delay ringbuffer.
 * @param delayTime       Time to delay expValue.
 * @param delayMax        Maximum allowed delay time, defaults to delayTime.
 * @return double         Value of zeroCrossing at current simulation time.
 */
double delayZeroCrossing(DATA* data, threadData_t *threadData, unsigned int exprNumber, unsigned int relationIndex, double delayValue, double delayTime, double delayMax)
{
  int foundEvent;
  int eventPos;
  double zeroCrossingValue;
  double time = data->localData[0]->timeValue;

  RINGBUFFER* delayStruct = data->simulationInfo->delayStructure[exprNumber];
  zeroCrossingValue = data->simulationInfo->zeroCrossingsPre[relationIndex];

  if (ringBufferLength(delayStruct) == 0)
  {
    return zeroCrossingValue;
  }

  /* Find first event on ring buffer */
  findTime(time - delayTime, delayStruct, &foundEvent);

  /* Case 0: No event to output */
  if (!foundEvent)
  {
    return zeroCrossingValue;
  }
  else /* Case 2: There is an event to output */
  {
    return -zeroCrossingValue;
  }
}



/**
 * @brief Print transported quantity data to stream.
 *
 * Prints tuple (time, value).
 *
 * @param data          Void pointer to bufferElemData.
 *                      Will be casted to TIME_AND_VALUE*.
 * @param stream        Stream of LOG_STREAM type.
 * @param elemPointer   Address of element storing this data.
 */
void printDelayBuffer(void* data, int stream, void* elemPointer)
{
  TIME_AND_VALUE* bufferElemData = (TIME_AND_VALUE*) data;
  infoStreamPrint(stream, 0, "%p: (%e,%e)", elemPointer, bufferElemData->t, bufferElemData->value);
}

#endif
