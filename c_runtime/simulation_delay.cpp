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
#include "ringbuffer.h"

double tStart = 0;

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
typedef ringbuffer<t_TimeAndValue> t_buffer;
t_buffer **delayStructure;
extern const int numDelayExpressionIndex;

void initDelay(double startTime)
{
	// get the start time of the simulation: time.start.
	tStart = startTime;
	// allocate the memory for rows
	delayStructure = new t_buffer*[numDelayExpressionIndex];
  for (int i=0; i<numDelayExpressionIndex; i++)
    delayStructure[i] = new t_buffer(1024);

	if (sim_verbose)
    fprintf(stderr, "initDelay called with startTime = %f\n", startTime);
}

void deinitDelay()
{
  delete[] delayStructure;
}

/*
 * Find row with greatest time that is smaller than or equal to 'time'
 * Conditions:
 *  the buffer in 'delayStruct' is not empty
 *  'time' is smaller than the last entry in 'delayStruct'
 */
static int findTime(double time, t_buffer delayStruct)
{
	int start = 0, end = delayStruct.length();
	double t;
	do {
		int i = (start + end) / 2;
		t = delayStruct[i].time;
		if (t > time)
			end = i;
		else
			start = i;
	} while (t != time && end > start + 1);
	return start;
}

void storeDelayedExpression(int exprNumber, double exprValue)
{
	double time = globalData->timeValue;

  //fprintf(stderr, "storeDelayed %g:%g\n", time, exprValue);
	if (exprNumber < 0) {
		fprintf(stderr, "storeDelayedExpression: Invalid expression number %d.\n", exprNumber);
		return;
	}


	if (time < tStart) {
		fprintf(stderr, "storeDelayedExpression: Time is smaller than starting time. Value ignored.\n");
		return;
	}

	// Allocate more space for expressions
  assert(exprNumber < numDelayExpressionIndex);

	t_buffer* delayStruct = delayStructure[exprNumber];
  t_TimeAndValue tpl;
  tpl.time = time;
	tpl.value = exprValue;
  delayStruct->append(tpl);
}

double delayImpl(int exprNumber, double exprValue, double time, double delayTime, double delayMax /* Unused */)
{
	//fprintf(stderr, "delayImpl: exprNumber = %d, exprValue = %lf, time = %lf, delayTime = %lf\n", exprNumber, exprValue, time, delayTime);

	// Check for errors
	assert(exprNumber >= 0);
  assert(exprNumber < numDelayExpressionIndex);

	if (time < tStart) {
		fprintf(stderr, "delayImpl: Entered at time < starting time.\n");
		return exprValue;
	}

	if (delayTime < 0.0) {
    throw TerminateSimulationException(globalData->timeValue,
      std::string("Negative delay requested.\n"));
	}

	t_buffer* delayStruct = delayStructure[exprNumber];
  int length = delayStruct->length();

	if (length == 0) {
	  // This occurs in the initialization phase
	  // fprintf(stderr, "delayImpl: Missing initial value, using argument value instead.\n");
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
		return (*delayStruct)[0].value;
	}
	else {
		// return expr(time-delayTime)
		assert(delayTime >= 0.0);
    double skipToTimeStamp = time - delayMax;
		double timeStamp = time - delayTime;
		double time0, time1, value0, value1;
    
    int i;

		// find the row for the lower limit
    if (timeStamp > (*delayStruct)[length - 1].time) {
      // delay between the last accepted time step and the current time
      time0 = (*delayStruct)[length - 1].time;
      value0 = (*delayStruct)[length - 1].value;
      time1 = time;
      value1 = exprValue;
    }
    else {
      i = findTime(timeStamp, *delayStruct);
      assert(i < length);
      time0 = (*delayStruct)[i].time;
      value0 = (*delayStruct)[i].value;
      // Was it the last value?
      if (i+1 == length) {
        if (i>0 && delayMax == delayTime) (*delayStruct).dequeue_n_first(i-1);
        return value0;
      }
      time1 = (*delayStruct)[i+1].time;
      value1 = (*delayStruct)[i+1].value;
      if (i>0 && delayMax == delayTime) (*delayStruct).dequeue_n_first(i-1);
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
