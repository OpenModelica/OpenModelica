/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

//#if !defined(OMC_NDELAY_EXPRESSIONS) || OMC_NDELAY_EXPRESSIONS>0

/*! \file spatialDistribution.c
 */

#include "spatialDistribution.h"
#include "../../util/omc_error.h"
#include "../../util/ringbuffer.h"
#include "../../openmodelica.h"
#include "epsilon.h"

#include <stdio.h>
#include <stdlib.h>


/**
 * @brief Describing value z(x,t).
 *
 * See Modelica specification 3.7.2.2 spatialDistribution for details
 * on transported quantity z(x,t).
 * https://specification.modelica.org/maint/3.4/Ch3.html#spatialdistribution
 */
typedef struct TRANSPORTED_QUANTITY_DATA {
  double position;    /* position x */
  double value;       /* transported quantity at position x */
} TRANSPORTED_QUANTITY_DATA;

/**
 * @brief Saving an event at given position.
 *
 * The zero crossing function will return 0 on this event,
 * zeroCrossValue until next event position
 * and -1*zeroCrossValue before this event.
 */
typedef struct TRANSPORTED_EVENT_DATA {
  double position;              /* position x */
  double zeroCrossValue;        /* Value of zero crossing at position x
                                 * Either +1 or -1 */
} TRANSPORTED_EVENT_DATA;


/* Private function prototypes */
double interpolateTransportedQuantity(const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double interpolationPos);
double extrapolateTransportedQuantity(const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double extrapolationPos);
void addNewNodeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity, double position, double value, int isEvent);
int findOppositeEndSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, double in0, double in1, double posX, int isPositiveVelocity, double* eventPreValue, double* outValue);
int pruneSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity);

// ############################################################################
//
// Section for allocating/ deallocating spatial distribution data
//
// ############################################################################


/**
 * @brief Allocates memory for spatial distribution structs.
 *
 * Returns pointer to array with allocated spatial distribution structs.
 * To free memroy call freeSpatialDistribution.
 *
 * @param nSpatialDistributions           Number of spacial distributions to be allocated.
 * @return SPATIAL_DISTRIBUTION_DATA*     Array with allocated spatial distributions.
 */
SPATIAL_DISTRIBUTION_DATA* allocSpatialDistribution(unsigned int nSpatialDistributions) {
  /* Debug info */
  infoStreamPrint(LOG_SPATIALDISTR, 0, "Allocating memory for %i spatial distribution(s).", nSpatialDistributions);

  /* Variables */
  int i;
  SPATIAL_DISTRIBUTION_DATA* spatialDistributionData;

  if (nSpatialDistributions==0) {
    return NULL;
  }

  spatialDistributionData = (SPATIAL_DISTRIBUTION_DATA*) calloc(nSpatialDistributions, sizeof(SPATIAL_DISTRIBUTION_DATA));

  for(i=0; i<nSpatialDistributions; i++) {
    spatialDistributionData[i].index = i;
    spatialDistributionData[i].isInitialized = 0 /* false */;
    spatialDistributionData[i].transportedQuantity = allocDoubleEndedList(sizeof(TRANSPORTED_QUANTITY_DATA)); /* empty double ended list */
    spatialDistributionData[i].storedEvents = allocDoubleEndedList(sizeof(TRANSPORTED_EVENT_DATA));           /* empty double ended list */
    spatialDistributionData[i].lastStoredEventValue = 0;
  }

  return spatialDistributionData;
}


/**
 * @brief Frees array of spatial distributions.
 *
 * @param spatialDistributionData     Array with spatial distribution of length nSpatialDistributions.
 * @param nSpatialDistributions       Length of spatialDistributionData.
 */
void freeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistributionData, unsigned int nSpatialDistributions) {
  /* Debug info */
  infoStreamPrint(LOG_SPATIALDISTR, 0, "Freeing %i spatial distribution(s).", nSpatialDistributions);

  /* Variables */
  int i;

  for(i=0; i<nSpatialDistributions; i++) {
    freeDoubleEndedList(spatialDistributionData[i].transportedQuantity);
    freeDoubleEndedList(spatialDistributionData[i].storedEvents);
  }
}


/**
 * @brief Initializes transportedQuantity of single spacial distribution.
 *
 * Spatial distribution array data->simulationInfo->spatialDistributionData has
 * to be allocated before using allocSpatialDistribution.
 *
 * @param data              Data
 * @param threadData        threadDate for error handling
 * @param index             Index of spatial distribution, has to match position data->simulationInfo->spatialDistributionData[index].
 * @param initialPoints     Array with initial points.
 *                          Is ordered from 0.0 = initialPoints[0] < initialPoints[i] < initialPoints[length] = 1.0
 * @param initialValues     Array with initial values at initial points.
 * @param length            Length of arrays initialPoints and initialValues.
 */
void initSpatialDistribution(DATA* data, threadData_t* threadData, unsigned int index, real_array* initialPoints, real_array* initialValues, unsigned int length) {
  /* Debug info */
  infoStreamPrint(LOG_SPATIALDISTR, 1, "Initializing spatial distributions (index=%i)", index);

  /* Variables */
  int i;
  SPATIAL_DISTRIBUTION_DATA* spatialDistributionData;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  TRANSPORTED_QUANTITY_DATA tmpData;
  TRANSPORTED_EVENT_DATA eventData;
  int numSamePos = 0;
  double lastZeroCrossValue = -1;
  modelica_real* initPnts = (modelica_real *) initialPoints->data;
  modelica_real* initVals = (modelica_real *) initialValues->data;

  /* Error checking */
  if (fabs(initPnts[0]) > SPATIAL_EPS ) {
    errorStreamPrint(LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
    errorStreamPrint(LOG_STDOUT, 0, "initialPoints[0] = %e is not zero.", initPnts[0]);
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }
  else if (fabs(initPnts[length-1] - 1.0) > SPATIAL_EPS) {
    errorStreamPrint(LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
    errorStreamPrint(LOG_STDOUT, 0, "initialPoints[end] = %e is not one.", initPnts[length-1]);
    messageClose(LOG_STDOUT);
    omc_throw_function(threadData);
  }
  for (i=0; i<length-2; i++) {
    if (initPnts[i] > initPnts[i+1]) {
      errorStreamPrint(LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
      errorStreamPrint(LOG_STDOUT, 0, "initialPoints[%i] > initialPoints[%i]", i, i+1);
      errorStreamPrint(LOG_STDOUT, 0, "%f > %f", initVals[i], initPnts[i+1]);
      messageClose(LOG_STDOUT);
      omc_throw_function(threadData);
    }
  }
  spatialDistributionData = &(data->simulationInfo->spatialDistributionData[index]);
  assertStreamPrint(threadData, 1 != spatialDistributionData->isInitialized, "SpatialDistribution was allready allocated!");

  /* Initialize quantity list */
  transportedQuantityList = spatialDistributionData->transportedQuantity;
  for (i=0; i<length-1; i++) {
    tmpData.position = initPnts[i];
    tmpData.value = initVals[i];
    pushBackDoubleEndedList(transportedQuantityList, (const void*) &tmpData);
    if (initPnts[i] == initPnts[i+1]) {
      numSamePos += 1;
      if (numSamePos > 1) {
        errorStreamPrint(LOG_STDOUT, 1, "Initialization of spatial distribution with index %i failed.", index);
        errorStreamPrint(LOG_STDOUT, 0, "initialPoints[%i] = initialPoints[%i] = initialPoints[%i]", i-1, i, i+1);
        errorStreamPrint(LOG_STDOUT, 0, "Only events with one pre-value and one value are allowed.");
        messageClose(LOG_STDOUT);
        omc_throw_function(threadData);
      }
      eventData.position = initPnts[i];
      lastZeroCrossValue = lastZeroCrossValue*(-1);
      eventData.zeroCrossValue = lastZeroCrossValue;
      pushBackDoubleEndedList(spatialDistributionData->storedEvents, (const void*) &eventData);
    } else {
      numSamePos = 0;
    }
  }
  tmpData.position = initPnts[length-1];
  tmpData.value = initVals[length-1];
  pushBackDoubleEndedList(transportedQuantityList, (const void*) &tmpData);

  spatialDistributionData->isInitialized = 1 /* true */;

  /* Debug info */
  doubleEndedListPrint(transportedQuantityList, LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(spatialDistributionData->storedEvents, LOG_SPATIALDISTR, &printTransportedQuantity);
  messageClose(LOG_SPATIALDISTR);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "Finished initializing spatial distribution (index=%i)", index);
}


// ############################################################################
//
// Section for evaluating spatialDistribution operator
//
// ############################################################################


/**
 * @brief Store spatial distribution data for an accepted step.
 *
 * @param data                Data
 * @param threadData          Thread data for error handling
 * @param index               Index of spatial distribution.
 * @param in0                 First input to spatial distribution.
 * @param in1                 Second input to spatial distribution
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Boolean describing if velocity v is positive (>=0).
 *                            Velocity v is `v:=der(x)`.
 */
void storeSpatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  DOUBLE_ENDED_LIST* storedEventsList;
  int walkedOverEvents = 0;
  double deltaX, realDirection;

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  transportedQuantityList = spatialDistribution->transportedQuantity;
  storedEventsList = spatialDistribution->storedEvents;

  /* Debug log */
  infoStreamPrint(LOG_SPATIALDISTR, 1, "Calling storeSpatialDistribution (index=%i, time=%e)", index, data->localData[0]->timeValue);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "spatialDistribution(%f, %f, %f, %s)", in0, in1, posX, isPositiveVelocity?"true":"false");
  doubleEndedListPrint(transportedQuantityList, LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, LOG_SPATIALDISTR, &printTransportedQuantity);

  if (data->simulationInfo->discreteCall) {
    errorStreamPrint(LOG_STDOUT, 0, "Discrete call of storeSpatialDistribution");
    omc_throw_function(threadData);
  }

  /* Get deltaX */
  deltaX = spatialDistribution->oldPosX - posX;
  if (deltaX > 0) {
    realDirection = 1 /* positive */;
  } else if (deltaX < 0) {
    realDirection = -1 /* negative */;
    deltaX = -deltaX;
  } else {
    realDirection = 0 /* standing still */;
  }

  /* If real direction doesn't match isPositiveVelocity just flip isPositiveVelocity. */
  if (deltaX > SPATIAL_ZERO_DELTA_X && isPositiveVelocity*realDirection > 0) {
    // TODO: This is probably still a sign that we didn't handle some event or event search correctly.
    isPositiveVelocity  = !isPositiveVelocity;
  }

  /* Add new node (oldPosX-deltaX, in0) or (oldPosX-deltaX+1, in1) to list
   * Check if it an event and only save it if has a discrete change in in0 or in1.
   */
  if (isPositiveVelocity) {
    TRANSPORTED_QUANTITY_DATA* front = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    if (fabs(-posX - front->position) < SPATIAL_EPS) {
      if (fabs(front->value - in0) > SPATIAL_EPS) {
        addNewNodeSpatialDistribution(spatialDistribution, isPositiveVelocity, -posX, in0, 1 /* true */);
      }
    } else {
      addNewNodeSpatialDistribution(spatialDistribution, isPositiveVelocity, -posX, in0, 0 /* false */);
    }
  } else {
    TRANSPORTED_QUANTITY_DATA* last = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    if (fabs(-posX+1 - last->position) < SPATIAL_EPS) {
      if (fabs(last->value - in1) > SPATIAL_EPS) {
        addNewNodeSpatialDistribution(spatialDistribution, isPositiveVelocity, -posX+1, in1, 1 /* true */);
      }
    } else {
      addNewNodeSpatialDistribution(spatialDistribution, isPositiveVelocity, -posX+1, in1, 0 /* false */);
    }
  }

  /* Remove nodes that droppen of spatial distribution */
  walkedOverEvents = pruneSpatialDistribution(spatialDistribution, isPositiveVelocity);
  if (walkedOverEvents > 1) {
    warningStreamPrint(LOG_STDOUT, 0, "Removed more then one event from spatialDistribution. Step size to big!");
    warningStreamPrint(LOG_STDOUT, 0, "time: %f, spatialDistribution index: %i, number of events: %i", data->localData[0]->timeValue, index, walkedOverEvents);
    messageClose(LOG_STDOUT);
  }

  /* Update oldPosX */
  spatialDistribution->oldPosX = posX;
  messageClose(LOG_SPATIALDISTR);
  return;
}


/**
 * @brief Evaluate spatialDistribution operator.
 *
 * (out0, out1) = spatialDistribution (in0, in1, posX, isPositiveVelocity)
 * If an event was outputted integrator needs to iterate.
 * Doesn't store in0 or in1 because this function doesn't know if the step will be accepted.
 *
 * @param data                Data
 * @param threadData          Thread data for error handling
 * @param index               Index of spatial distribution.
 * @param in0                 First input to spatial distribution.
 * @param in1                 Second input to spatial distribution
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Boolean describing if velocity v is positive (>=0).
 *                            Velocity v is `v:=der(x)`.
 * @param out1                Second output of spatial distribution.
 * @return double             out0, first output of spatial distribution.
 */
double spatialDistribution(DATA* data, threadData_t *threadData, unsigned int index, double in0, double in1, double posX, int isPositiveVelocity, double* out1) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* transportedQuantityList;
  DOUBLE_ENDED_LIST_NODE* firstNode;
  DOUBLE_ENDED_LIST_NODE* lastNode;
  TRANSPORTED_QUANTITY_DATA* firstNodeData;
  TRANSPORTED_QUANTITY_DATA* secondNodeData;
  TRANSPORTED_QUANTITY_DATA* lastNodeData;
  TRANSPORTED_QUANTITY_DATA* forelastNodeData;
  int walkedOverEvents;
  int realDirection;
  int jumped = 0;
  double deltaX;
  double eventPreValue;
  double outValue;
  double out0;    /* Output variable */

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  transportedQuantityList = spatialDistribution->transportedQuantity;

  /* Debug log */
  infoStreamPrint(LOG_SPATIALDISTR, 1, "Calling spatialDistribution (index=%i, time=%e)", index, data->localData[0]->timeValue);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "(out0,out1) = spatialDistribution(%f, %f, %f, %s)", in0, in1, posX, isPositiveVelocity?"true":"false");
  infoStreamPrint(LOG_SPATIALDISTR, 0, "                                     in0        in1        x     isPositiveVelocity");
  doubleEndedListPrint(transportedQuantityList, LOG_SPATIALDISTR, &printTransportedQuantity);

  /* Get deltaX */
  deltaX = spatialDistribution->oldPosX - posX;
  if (deltaX > 0) {
    realDirection = 1 /* positive */;
  } else if (deltaX < 0) {
    realDirection = -1 /* negative */;
    deltaX = -deltaX;
  } else {
    realDirection = 0 /* standing still */;
  }

  /* If real direction doesn't match isPositiveVelocity just flip isPositiveVelocity.
   * This still indicates something wrong, so we don't extrapolate the output */
  if (deltaX > SPATIAL_ZERO_DELTA_X && isPositiveVelocity*realDirection > 0) {
    isPositiveVelocity  = !isPositiveVelocity;
    jumped = 1 /* true */;
  }

  /* Check if x was reinitialized */
  if (deltaX > SPATIAL_ZERO_DELTA_X && data->simulationInfo->discreteCall) {
    errorStreamPrint(LOG_STDOUT, 0, "x got reinitialized during an event at time %f. OpenModelica can't handle that.", data->localData[0]->timeValue);
    omc_throw_function(threadData);
  }

  /* Special case: Zero progress */
  if (deltaX < SPATIAL_EPS) {
    firstNodeData = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    lastNodeData = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    out0 = firstNodeData->value;
    *out1 = lastNodeData->value;
    infoStreamPrint(LOG_SPATIALDISTR, 0, "(out0,out1) = (%f, %f)", out0, *out1);
    messageClose(LOG_SPATIALDISTR);
    return out0;
  }

  /* Get value of ou0/out1 by walkling over list */
  walkedOverEvents = findOppositeEndSpatialDistribution(spatialDistribution, in0, in1, posX, isPositiveVelocity, &eventPreValue, &outValue);

  /* Handle events that would come out of spatialDistribution */
  if (walkedOverEvents > 1) {
    warningStreamPrint(LOG_STDOUT, 1, "Need to output more then one event from spatialDistribution. Step size to big!");
    warningStreamPrint(LOG_STDOUT, 0, "time: %f, spatialDistribution index: %i, number of events: %i", data->localData[0]->timeValue, index, walkedOverEvents);
    messageClose(LOG_STDOUT);
  }
  if (walkedOverEvents>0 && !data->simulationInfo->discreteCall) {
    infoStreamPrint(LOG_SPATIALDISTR, 0, "Found event in spatial distribution at time %f", data->localData[0]->timeValue);
    outValue = eventPreValue;
  }

  /* Extrapolate return values to break up quasi-loop with inputs */
  firstNodeData = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
  secondNodeData = dataDoubleEndedList(getNextNodeDoubleEndedList(getFirstNodeDoubleEndedList(transportedQuantityList)));
  lastNodeData = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
  forelastNodeData = dataDoubleEndedList(getPreviousNodeDoubleEndedList(getLastNodeDoubleEndedList(transportedQuantityList)));
  if (isPositiveVelocity) {
    if (jumped) {
      out0 = in0;
    } else if (deltaX > SPATIAL_EPS && fabs(firstNodeData->position-secondNodeData->position)>SPATIAL_EPS) {
      out0 = extrapolateTransportedQuantity(firstNodeData, secondNodeData, -posX);
    } else {
      out0 = firstNodeData->value;
    }
    *out1 = outValue;
  } else {
    out0 = outValue;
    if (jumped) {
      *out1 = in1;
    } else if (deltaX > SPATIAL_EPS && fabs(forelastNodeData->position-lastNodeData->position)>SPATIAL_EPS) {
      *out1 = extrapolateTransportedQuantity(forelastNodeData, lastNodeData, -posX+1);
    } else {
      *out1 = lastNodeData->value;
    }
  }

  infoStreamPrint(LOG_SPATIALDISTR, 0, "(out0,out1) = (%f, %f)", out0, *out1);
  messageClose(LOG_SPATIALDISTR);
  return out0;
}


// ############################################################################
//
// Section for evaluating spatialDistribution zero-crossing function
//
// ############################################################################


/**
 * @brief Returns value of zero crossing at postion x.
 *
 * zeroCross(x):= -1 if there are no events or before the first event.
 * Otherwise zeroCross(x):=(-1)*zeroCross(x_E), where x_E is the position of the nearest event with bigger position.
 * If there is no event with bigger position zeroCross(x):=zeroCross(x_E) where x_E is the event with the biggest position.
 *
 * @param data                Data
 * @param threadData          threadDate for error handling
 * @param index               Index of spatial distribution, has to match position data->simulationInfo->spatialDistributionData[index].
 * @param posX                Value of position x.
 * @param isPositiveVelocity  Unused
 * @return double             Value of zeroCrossing at position posX.
 */
double spatialDistributionZeroCrossing(DATA* data, threadData_t *threadData, unsigned int index, unsigned int relationIndex, double posX, int isPositiveVelocity) {
  /* Variables */
  SPATIAL_DISTRIBUTION_DATA* spatialDistribution;
  DOUBLE_ENDED_LIST* storedEventsList;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  TRANSPORTED_EVENT_DATA* currentNodeData;
  double zeroCrossingValue;
  double prevPosition, prevValue;

  /* Access spatialDistribution */
  spatialDistribution = &(data->simulationInfo->spatialDistributionData[index]);
  storedEventsList = spatialDistribution->storedEvents;

  if (doubleEndedListLen(storedEventsList) == 0) {
    zeroCrossingValue = data->simulationInfo->zeroCrossingsPre[relationIndex];
    infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events for spatialDistributionZeroCrossing(%e) = %e\n", posX, zeroCrossingValue);
    return zeroCrossingValue;
  }

  if (isPositiveVelocity) {
    currentNode = getLastNodeDoubleEndedList(storedEventsList);
    currentNodeData = dataDoubleEndedList(currentNode);
    // -posX+1 is behind last event
    if (currentNodeData->position < -posX+1 ) {
      zeroCrossingValue = -currentNodeData->zeroCrossValue;
    } else {
      while (currentNode != NULL) {
        // Am I on an event?
        if (fabs(currentNodeData->position+posX-1) <= SPATIAL_EPS) {
          zeroCrossingValue = -currentNodeData->zeroCrossValue;
          break;
        }

        prevPosition = currentNodeData->position;
        prevValue = currentNodeData->zeroCrossValue;
        currentNode = getPreviousNodeDoubleEndedList(currentNode);
        // Did I walk over the first element in the list?
        if (currentNode==NULL) {
          zeroCrossingValue = prevValue;  /* prevValue value of first list element */
          break;
        }
        currentNodeData = dataDoubleEndedList(currentNode);

        // Are we between two events?
        if (currentNodeData->position < -posX+1 && -posX+1 < prevPosition) {
          zeroCrossingValue = prevValue;
          break;
        }
      }
    }
  } else {
    currentNode = getFirstNodeDoubleEndedList(storedEventsList);
    currentNodeData = dataDoubleEndedList(currentNode);
    // -posX is before first event
    if (currentNodeData->position > -posX ) {
      zeroCrossingValue = currentNodeData->zeroCrossValue;
    } else {
      while (currentNode != NULL) {
        // Am I on an event?
        if (fabs(currentNodeData->position+posX) <= SPATIAL_EPS) {
          zeroCrossingValue = -currentNodeData->zeroCrossValue;
          break;
        }

        prevPosition = currentNodeData->position;
        prevValue = currentNodeData->zeroCrossValue;
        currentNode = getNextNodeDoubleEndedList(currentNode);
        // Did I walk over the first element in the list?
        if (currentNode==NULL) {
          zeroCrossingValue = -prevValue;  /* prevValue value of first list element */
          break;
        }
        currentNodeData = dataDoubleEndedList(currentNode);

        // Are we between two events?
        if (currentNodeData->position > -posX && -posX > prevPosition) {
          zeroCrossingValue = -prevValue;
          break;
        }
      }
    }
  }


  infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events for spatialDistributionZeroCrossing(%e) = %e\n", posX, zeroCrossingValue);
  doubleEndedListPrint(storedEventsList, LOG_SPATIALDISTR, &printTransportedQuantity);

  return zeroCrossingValue;
}


// ############################################################################
//
// Section for "small" helper functions
//
// ############################################################################


/**
 * @brief Linear interpolation between left and right (position,value) pair at given position.
 *
 * leftData->position < interpolationPos < rightData->position must hold.
 *
 * @param leftData                Left (position,value) pair
 * @param rightData               Right (position,value) pair
 * @param interpolationPos        Position where to interpolate.
 * @return double                 Interpolated value
 */
double interpolateTransportedQuantity(const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double interpolationPos) {
  double leftPosition, rightPosition;
  double leftValue, rightValue;
  double distPos;
  double interpolatedValue;

  leftPosition = leftData->position;
  leftValue = leftData->value;
  rightPosition = rightData->position;
  rightValue = rightData->value;
  distPos = rightPosition - leftPosition;

  assertStreamPrint(NULL, distPos > 0, "interpolateTransportedQuantity: wrong order or same position!");

  interpolatedValue = leftValue  * ((rightPosition-interpolationPos)/distPos)
                    + rightValue * ((interpolationPos-leftPosition)/distPos);

  return interpolatedValue;
}


/**
 * @brief Linear extrapolation at given position.
 *
 * @param leftData              Left (position,value) pair
 * @param rightData             Right (position,value) pair
 * @param extrapolationPos      Position where to interpolate.
 * @return double               Extrapolated value.
 */
double extrapolateTransportedQuantity(const TRANSPORTED_QUANTITY_DATA* leftData, const TRANSPORTED_QUANTITY_DATA* rightData, const double extrapolationPos) {
  double leftPosition, rightPosition;
  double leftValue, rightValue;
  double distPos;
  double extrapolatedValue;

  leftPosition = leftData->position;
  leftValue = leftData->value;
  rightPosition = rightData->position;
  rightValue = rightData->value;
  distPos = rightPosition - leftPosition;

  assertStreamPrint(NULL, distPos > 0, "interpolateTransportedQuantity: wrong order or same position!");

  extrapolatedValue = leftValue + (rightValue-leftValue)/(distPos) * (extrapolationPos - leftPosition);
  return extrapolatedValue;
}


/**
 * @brief Adding new pair (position, value) to front or back of spatial distribution.
 *
 * For positive velocity add at frond, else at back.
 * If this node is an event node add an event to stored events list as well.
 *
 * @param transportedQuantityList     Double ended list representing spatial distribution.
 * @param front                       Boolean value if node should be added at the front (true) or the end (false).
 * @param position                    Position of new node.
 * @param value                       Value of new node.
 * @param isEvent                     Boolean value if new node is an event node.
 */
void addNewNodeSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int front, double position, double value, int isEvent) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  TRANSPORTED_QUANTITY_DATA newNodeData;
  TRANSPORTED_EVENT_DATA newEventNodeData;

  /* New node */
  newNodeData.position = position;
  newNodeData.value = value;
  newEventNodeData.position = position;

  /* Add node to transported quantity list */
  infoStreamPrint(LOG_SPATIALDISTR, 0, "Adding (%e,%e) at %s.", newNodeData.position, newNodeData.value, front?"front":"back");
  if (front) {
    // Make sure new first node is smaller then previous first node
    TRANSPORTED_QUANTITY_DATA* oldFront = (TRANSPORTED_QUANTITY_DATA*) firstDataDoubleEndedList(transportedQuantityList);
    assertStreamPrint(NULL, position<=oldFront->position, "New front position is not smaller then previous first node.");
    pushFrontDoubleEndedList(transportedQuantityList, (const void*) &newNodeData);
  } else {
    // Make sure new first node is smaller then previous first node
    TRANSPORTED_QUANTITY_DATA* oldEnd = (TRANSPORTED_QUANTITY_DATA*) lastDataDoubleEndedList(transportedQuantityList);
    assertStreamPrint(NULL, position>=oldEnd->position, "New end position is not bigger then previous last node.");
    pushBackDoubleEndedList(transportedQuantityList, (const void*) &newNodeData);
  }

  /* Add event to stored event list */
  if (isEvent == 1) {
    if (front) {
      if (doubleEndedListLen(storedEventsList) == 0) {
        if (spatialDistribution->lastStoredEventValue==0) {
          newEventNodeData.zeroCrossValue = 1;
        } else {
          newEventNodeData.zeroCrossValue = -spatialDistribution->lastStoredEventValue;
        }
      } else {
        // Make sure new first node is smaller then previous first node
        TRANSPORTED_EVENT_DATA* oldEventFront = (TRANSPORTED_EVENT_DATA*) firstDataDoubleEndedList(storedEventsList);
        assertStreamPrint(NULL, position<=oldEventFront->position, "New front position is not smaller then previous first event node.");
        newEventNodeData.zeroCrossValue = oldEventFront->zeroCrossValue*(-1);
      }
      pushFrontDoubleEndedList(storedEventsList, (const void*) &newEventNodeData);
    } else {
      if (doubleEndedListLen(storedEventsList) == 0) {
        newEventNodeData.zeroCrossValue = 1;
      } else {
        // Make sure new first node is smaller then previous first node
        TRANSPORTED_EVENT_DATA* oldEventEnd = (TRANSPORTED_EVENT_DATA*) lastDataDoubleEndedList(storedEventsList);
        assertStreamPrint(NULL, position>=oldEventEnd->position, "New end position is not bigger then previous last event node.");
        newEventNodeData.zeroCrossValue = oldEventEnd->zeroCrossValue*(-1);
      }
      pushBackDoubleEndedList(storedEventsList, (const void*) &newEventNodeData);
    }
    infoStreamPrint(LOG_SPATIALDISTR, 0, "Adding event (%e,%e) at %s.", newEventNodeData.position, newEventNodeData.zeroCrossValue, front?"front":"back");
  }

  /* Debug prints */
  doubleEndedListPrint(transportedQuantityList, LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, LOG_SPATIALDISTR, &printTransportedQuantity);
}


/**
 * @brief Gets value from opposite end of list.
 *
 * @param transportedQuantityList     Double ended list containing spatial distribution.
 * @param isPositiveVelocity          Boolean describing if velocity v is positive (>=0).
 *                                    Velocity v is `v:=der(x)`.
 * @param eventPreValue               On output containing value of first/last node before event.
 *                                    This value is only written when function returned 1 or greater.
 * @return int                        Return number of events that were encountered.
 */
int findOppositeEndSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, double in0, double in1, double posX, int isPositiveVelocity, double* eventPreValue, double* outValue) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  DOUBLE_ENDED_LIST_NODE* firstNode;
  DOUBLE_ENDED_LIST_NODE* lastNode;
  DOUBLE_ENDED_LIST_NODE* prevVisitedNode;
  TRANSPORTED_QUANTITY_DATA* currentNodeData;
  TRANSPORTED_QUANTITY_DATA* prevVisitedNodeData;
  TRANSPORTED_QUANTITY_DATA* firstNodeData;
  TRANSPORTED_QUANTITY_DATA* lastNodeData;
  TRANSPORTED_QUANTITY_DATA tempData;
  double edgeNodePosition;
  double currentDistance;
  int walkedOverEvents = 0;

  /* Step 0
   * Check if we are still in spatialDistribution intervall or if deltaX > 1
   */
  firstNode = getFirstNodeDoubleEndedList(transportedQuantityList);
  firstNodeData = firstDataDoubleEndedList(transportedQuantityList);
  lastNode = getLastNodeDoubleEndedList(transportedQuantityList);
  lastNodeData = lastDataDoubleEndedList(transportedQuantityList);
  if (isPositiveVelocity) {
    if (-posX+1 < firstNodeData->position) {
      // We need to interpolate (-posX,in0) <-> (-posX+1,out1) <-> (firstNodeData->position, firstNodeData->value)
      //                                                  ^
      //                                                  |
      tempData.position = -posX;
      tempData.value = in0;
      *outValue = interpolateTransportedQuantity(&tempData, firstNodeData, -posX + 1);
      return doubleEndedListLen(storedEventsList);
    }
  } else {
    if (-posX > lastNodeData->position) {
      // We need to interpolate (lastNodeData->position,lastNodeData->value) <-> (-posX, out0) <-> (-posX+1,in1)
      //                                                                                  ^
      //                                                                                  |
      tempData.position = -posX+1;
      tempData.value = in1;
      *outValue = interpolateTransportedQuantity(lastNodeData, &tempData, -posX);
      return doubleEndedListLen(storedEventsList);
    }
  }

  /* Step 1
   * Walk over list, starting from opposite side of edgeNode,
   * until distance between currentNode and edgeNode < 1.
   */
  if (isPositiveVelocity) {
    edgeNodePosition = firstNodeData->position;
    currentNode = lastNode;
  } else {
    edgeNodePosition = lastNodeData->position;
    currentNode = firstNode;
  }
  currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

  currentDistance = fabs(currentNodeData->position - edgeNodePosition);
  if (currentDistance + SPATIAL_EPS < 1) {
    errorStreamPrint(LOG_STDOUT, 0, "Error for spatialDistribution in function findOppositeEndSpatialDistribution.\nThis case should not be possible. Please open a bug reoprt about it.");
    omc_throw_function(NULL);
    return walkedOverEvents;
  }

  /* Move to neighbor */
  prevVisitedNode = currentNode;
  prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);

  while (currentNode != NULL) {
    if (isPositiveVelocity) {
      currentNode = getPreviousNodeDoubleEndedList(currentNode);
    } else {
      currentNode = getNextNodeDoubleEndedList(currentNode);
    }
    if(currentNode == NULL) {
      break;
    }
    currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

    /* Check for event:
     * Current node position equal to previous visited node position
     */
    if (fabs(prevVisitedNodeData->position - currentNodeData->position) < SPATIAL_EPS) {
      *eventPreValue = prevVisitedNodeData->value;
      walkedOverEvents += 1;
    }

    /* Check if distance between currentNode and edgeNode is < 1 */
    currentDistance = fabs(currentNodeData->position - edgeNodePosition);
    if (currentDistance + SPATIAL_EPS < 1) {
      break;
    } else {
      prevVisitedNode = currentNode;
      prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);
    }
  }

  /* Step 2
   * Interpolate at edgeNodePosition +/- 1.
   */
  if (currentNode == NULL) {
    /* Walked over all elements of list */
    if (isPositiveVelocity) {
      *outValue = lastNodeData->value;
    } else {
      *outValue = firstNodeData->value;
    }
  } else {
    if (isPositiveVelocity) {
      *outValue = interpolateTransportedQuantity(currentNodeData, prevVisitedNodeData, edgeNodePosition + 1);
    } else {
      *outValue = interpolateTransportedQuantity(prevVisitedNodeData, currentNodeData, edgeNodePosition - 1);
    }
  }

  return walkedOverEvents;
}



/**
 * @brief Remove nodes until distance between first and last element is 1.
 *
 * @param transportedQuantityList     Double ended list containing spatial distribution.
 * @param isPositiveVelocity          Boolean describing if velocity v is positive (>=0).
 *                                    Velocity v is `v:=der(x)`.
 * @param eventPreValue               On output containing value of first/last node before event.
 *                                    This value is only written when function returned 1 or greater.
 * @return int                        Return number of events that were encountered.
 */
int pruneSpatialDistribution(SPATIAL_DISTRIBUTION_DATA* spatialDistribution, int isPositiveVelocity) {
  /* Variables */
  DOUBLE_ENDED_LIST* transportedQuantityList = spatialDistribution->transportedQuantity;
  DOUBLE_ENDED_LIST* storedEventsList = spatialDistribution->storedEvents;
  DOUBLE_ENDED_LIST_NODE* edgeNode;
  DOUBLE_ENDED_LIST_NODE* currentNode;
  DOUBLE_ENDED_LIST_NODE* prevVisitedNode;
  TRANSPORTED_QUANTITY_DATA* edgeNodeData;
  TRANSPORTED_QUANTITY_DATA* currentNodeData;
  TRANSPORTED_QUANTITY_DATA* prevVisitedNodeData;
  TRANSPORTED_EVENT_DATA* eventData;
  int walkedOverEvents = 0;
  int i;
  double currentDistance;

  /* Step 1
   * Walk over list, starting from opposite side of edgeNode,
   * until distance between currentNode and edgeNode < 1.
   */
  if (isPositiveVelocity) {
    edgeNode = getFirstNodeDoubleEndedList(transportedQuantityList);
    currentNode = getLastNodeDoubleEndedList(transportedQuantityList);
  } else {
    edgeNode = getLastNodeDoubleEndedList(transportedQuantityList);
    currentNode = getFirstNodeDoubleEndedList(transportedQuantityList);
  }
  edgeNodeData  = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(edgeNode);
  currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

  currentDistance = fabs(currentNodeData->position - edgeNodeData->position);
  if (currentDistance + SPATIAL_EPS < 1) {
    errorStreamPrint(LOG_STDOUT, 0, "Error for spatialDistribution in function pruneSpatialDistribution.\nThis case should not be possible. Please open a bug reoprt about it.");
    omc_throw_function(NULL);
  }

  /* Move to neighbor */
  prevVisitedNode = currentNode;
  prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);

  while (currentNode != edgeNode) {
    if (isPositiveVelocity) {
      currentNode = getPreviousNodeDoubleEndedList(currentNode);
    } else {
      currentNode = getNextNodeDoubleEndedList(currentNode);
    }
    currentNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(currentNode);

    /* Check for event:
     * Current node position equal to previous visited node position
     */
    if (fabs(prevVisitedNodeData->position - currentNodeData->position) < SPATIAL_EPS) {
      walkedOverEvents += 1;
    }

    /* Check if distance between currentNode and edgeNode is < 1 */
    currentDistance = fabs(currentNodeData->position - edgeNodeData->position);
    if (currentDistance + SPATIAL_EPS < 1) {
      break;
    } else {
      prevVisitedNode = currentNode;
      prevVisitedNodeData = (TRANSPORTED_QUANTITY_DATA*) dataDoubleEndedList(prevVisitedNode);
    }
  }

  /* Step 2
   * Interpolate at edgeNode->position +/- 1.
   */
  if (currentDistance + SPATIAL_EPS < 1) {
    if (isPositiveVelocity) {
      prevVisitedNodeData->value = interpolateTransportedQuantity(currentNodeData, prevVisitedNodeData, edgeNodeData->position + 1);
      prevVisitedNodeData->position = edgeNodeData->position + 1;
    } else {
      prevVisitedNodeData->value = interpolateTransportedQuantity(prevVisitedNodeData, currentNodeData, edgeNodeData->position - 1);
      prevVisitedNodeData->position = edgeNodeData->position - 1;
    }
    infoStreamPrint(LOG_SPATIALDISTR, 0, "Interpolate at %s", isPositiveVelocity?"end":"front");
  }

  /* Step 3
   * Remove all nodes that have a distance to edge > 1.
   */
  infoStreamPrint(LOG_SPATIALDISTR, 0, "Removing nodes %s node %p", isPositiveVelocity?"after":"before", prevVisitedNode);
  if (isPositiveVelocity) {
    clearAfterNodeDoubleEndedList(transportedQuantityList, prevVisitedNode);
  } else {
    clearBeforeNodeDoubleEndedList(transportedQuantityList, prevVisitedNode);
  }

  /* Step 4
   * Remove all events that are outside spatial distribution [leftEdge-SPATIAL_ZERO_DELTA_X, rightEdge+SPATIAL_ZERO_DELTA_X]
   */
  if (doubleEndedListLen(storedEventsList) > 0) {
    if (isPositiveVelocity) {
      eventData = lastDataDoubleEndedList(storedEventsList);
      while (edgeNodeData->position+1 + SPATIAL_ZERO_DELTA_X < eventData->position) {
        spatialDistribution->lastStoredEventValue = eventData->zeroCrossValue;
        removeLastDoubleEndedList(storedEventsList);
        if (doubleEndedListLen(storedEventsList) == 0) {
          break;
        } else {
          eventData = lastDataDoubleEndedList(storedEventsList);
        }
      }
    } else {
      eventData = firstDataDoubleEndedList(storedEventsList);
      while (edgeNodeData->position-1 - SPATIAL_ZERO_DELTA_X > eventData->position) {
        spatialDistribution->lastStoredEventValue = eventData->zeroCrossValue;
        removeFirstDoubleEndedList(storedEventsList);
        if (doubleEndedListLen(storedEventsList) == 0) {
          break;
        } else {
          eventData = firstDataDoubleEndedList(storedEventsList);
        }
      }
    }
  }

  /* Debug prints */
  doubleEndedListPrint(transportedQuantityList, LOG_SPATIALDISTR, &printTransportedQuantity);
  infoStreamPrint(LOG_SPATIALDISTR, 0, "List of events");
  doubleEndedListPrint(storedEventsList, LOG_SPATIALDISTR, &printTransportedQuantity);

  return walkedOverEvents;
}


/**
 * @brief Print transported quantity data to stream.
 *
 * Prints tuple (position, value).
 *
 * @param data          Void pointer to transportedQuantityData.
 *                      Will be casted to TRANSPORTED_QUANTITY_DATA*.
 * @param stream        Stream of LOG_STREAM type.
 * @param nodePointer   Address of node storing this data.
 */
void printTransportedQuantity(void* data, int stream, void* nodePointer) {
  TRANSPORTED_QUANTITY_DATA* transportedQuantityData = (TRANSPORTED_QUANTITY_DATA*) data;
  infoStreamPrint(stream, 0, "%p: (%e,%e)", nodePointer, transportedQuantityData->position, transportedQuantityData->value);
}


//#endif
