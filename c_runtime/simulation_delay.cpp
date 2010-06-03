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

#include <stdio.h>

#include "modelica.h"
#include "assert.h"
#include "string.h"
#include "simulation_runtime.h"

#include <string>

double tStart = 0;

// we can remember the delay for max 10 expressions by default
// this can be increased using realloc.
long maxExpressions = 10;

typedef struct _TimeAndValue
{
	double time;
	double value;
} t_TimeAndValue;

typedef struct _ExpressionDelayBuffer
{
	long currentIndex;
	long maxExpressionBuffer;
	t_TimeAndValue *expressionDelayBuffer;
} t_ExpressionDelayBuffer;

// the delayStructure looks like a matrix (rows = expressionNumber+currentColumnIndex, columns={time, value})
t_ExpressionDelayBuffer **delayStructure;

void initDelay(double startTime)
{
	// get the start time of the simulation: time.start.
	tStart = startTime;
	// allocate the memory for rows
	delayStructure = (t_ExpressionDelayBuffer**)malloc(maxExpressions
			* sizeof(t_ExpressionDelayBuffer*));
	// zero it out
	for (long i = 0; i < maxExpressions; i++)
		delayStructure[i] = 0;

	//fprintf(stderr, "initDelay called with startTime = %lf\n", startTime);
}

/*
 * Find row with greatest time that is smaller than or equal to 'time'
 * Conditions:
 *  the buffer in 'delayStruct' is not empty
 *  'time' is smaller than the last entry in 'delayStruct'
 */
static int findTime(double time, t_ExpressionDelayBuffer *delayStruct)
{
	int start = 0, end = delayStruct->currentIndex;
	double t;
	do {
		int i = (start + end) / 2;
		t = delayStruct->expressionDelayBuffer[i].time;
		if (t > time)
			end = i;
		else
			start = i;
	} while (t != time && end > start + 1);
	return start;
}

void storeDelayedExpression(int exprNumber, double exprValue)
{
	if (exprNumber < 0) {
		fprintf(stderr, "storeDelayedExpression: Invalid expression number %d.\n", exprNumber);
		return;
	}

	double time = globalData->timeValue;

	if (time < tStart) {
		fprintf(stderr, "storeDelayedExpression: Time is smaller than starting time. Value ignored.\n");
		return;
	}

	// Allocate more space for expressions
	if (exprNumber >= maxExpressions) {
		// increase the rows
		long maxE = maxExpressions;
		maxExpressions = exprNumber + 1;
		delayStructure = (t_ExpressionDelayBuffer**)realloc(delayStructure,
				maxExpressions * sizeof(t_ExpressionDelayBuffer*));
		// zero the new part out
		for (long i = maxE; i < maxExpressions; i++)
			delayStructure[i] = 0;
	}

	t_ExpressionDelayBuffer *delayStruct = delayStructure[exprNumber];

	// is the column allocated?
	if (!delayStruct) {
		// we haven't let's do it...
		// we create memory for 1000 variable values at first, then we increase it using realloc if needed
		assert(time == tStart);

		delayStruct = (t_ExpressionDelayBuffer*)malloc(
				sizeof(t_ExpressionDelayBuffer));
		delayStructure[exprNumber] = delayStruct;
		delayStruct->maxExpressionBuffer = 1000;
		t_TimeAndValue *buffer = (t_TimeAndValue*)malloc(
						delayStruct->maxExpressionBuffer * sizeof(t_TimeAndValue));
		delayStruct->expressionDelayBuffer = buffer;

		// now let's store the time and value!
		buffer[0].time = time;
		buffer[0].value = exprValue;
		delayStruct->currentIndex = 1;
	}
	else {
		assert(delayStruct->currentIndex > 0);

		double lastTime = delayStruct->expressionDelayBuffer[delayStruct->currentIndex-1].time;

		assert(time >= lastTime);

		int index = delayStruct->currentIndex;
    if (index >= delayStruct->maxExpressionBuffer) {
      // it doesn't fit anymore, we need to re-alloc:
      delayStruct->maxExpressionBuffer *= 2;
      delayStruct->expressionDelayBuffer = (t_TimeAndValue*)realloc(
              delayStruct->expressionDelayBuffer,
              delayStruct->maxExpressionBuffer * sizeof(t_TimeAndValue));
    }

		//fprintf(stderr, "storeDelayedExpression: Assigned value for expression %d (index = %d, time = %lf, value = %lf)\n", exprNumber, index, time, exprValue);

		// now let's store the time and value!
		delayStruct->expressionDelayBuffer[index].time = time;
		delayStruct->expressionDelayBuffer[index].value = exprValue;
		delayStruct->currentIndex = index + 1;

		assert(delayStruct->currentIndex <= delayStruct->maxExpressionBuffer);
	}
}

double delayImpl(int exprNumber, double exprValue, double time, double delayTime)
{
	//fprintf(stderr, "delayImpl: exprNumber = %d, exprValue = %lf, time = %lf, delayTime = %lf\n", exprNumber, exprValue, time, delayTime);

	// Check for errors
	if (exprNumber < 0) {
		fprintf(stderr, "delayImpl: Invalid expression number %d.\n", exprNumber);
		return exprValue;
	}

	if (time < tStart) {
		fprintf(stderr, "delayImpl: Entered at time < starting time.\n");
		return exprValue;
	}

	if (delayTime < 0.0) {
    throw TerminateSimulationException(globalData->timeValue,
      std::string("Negative delay requested.\n"));
	}

	t_ExpressionDelayBuffer *delayStruct = delayStructure[exprNumber];

	if (!delayStruct || delayStruct->currentIndex == 0) {
	  // This occurs in the initialization phase
	  //fprintf(stderr, "delayImpl: Missing initial value, using argument value instead.\n");
	  return exprValue;
	}

	// Returns: expr(time?delayTime) for time>time.start + delayTime and
	//          expr(time.start) for time <= time.start + delayTime.
	// The arguments, i.e., expr, delayTime and delayMax, need to be subtypes of Real.
	// DelayMax needs to be additionally a parameter expression.
	// The following relation shall hold: 0 <= delayTime <= delayMax,
	// otherwise an error occurs. If delayMax is not supplied in the argument list,
	// delayTime need to be a parameter expression. See also Section 3.7.2.1.
	// For non-scalar arguments the function is vectorized according to Section 10.6.12.

	if (time <= tStart + delayTime) {
		//fprintf(stderr, "findTime: time <= tStart + delayTime\n");
		return delayStruct->expressionDelayBuffer[0].value;
	}
	else {
		// return expr(time-delayTime)
		assert(delayTime >= 0.0);
		double timeStamp = time - delayTime;
		double time0, time1, value0, value1;

		// find the row for the lower limit
		int i;
    if (timeStamp > delayStruct->expressionDelayBuffer[delayStruct->currentIndex - 1].time) {
      // delay between the last accepted time step and the current time
      time0 = delayStruct->expressionDelayBuffer[delayStruct->currentIndex - 1].time;
      value0 = delayStruct->expressionDelayBuffer[delayStruct->currentIndex - 1].value;
      time1 = time;
      value1 = exprValue;
    }
    else {
      i = findTime(timeStamp, delayStruct);
      assert(i < delayStruct->currentIndex);
      // Was it the last value?
      if (i+1 == delayStruct->currentIndex) {
        return value0;
      }
      t_TimeAndValue *nearest = delayStruct->expressionDelayBuffer + i;
      time0 = nearest[0].time;
      value0 = nearest[0].value;
      time1 = nearest[1].time;
      value1 = nearest[1].value;
    }

		// was it an exact match?
		if (time0 == timeStamp) {
			//fprintf(stderr, "delayImpl: Exact match at %lf\n", currentTime);
			return value0;
		}
		else if (time1 == timeStamp) {
		  return value1;
		}
		else {
			//fprintf(stderr, "delayImpl: Linear interpolation of %lf between %lf and %lf\n", timeStamp, time0, time1);

			// linear interpolation
			double timedif = time1 - time0;
			double dt0 = time1 - timeStamp;
			double dt1 = timeStamp - time0;
			return (value0 * dt0 + value1 * dt1) / timedif;
		}
	}
}
