/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2022, Open Source Modelica Consortium (OSMC),
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

/*! \file gbode_events.c
 */

#include "../../simulation/options.h"
#include "epsilon.h"
#include "events.h"
#include "external_input.h"
#include "gbode_main.h"
#include "gbode_util.h"
#include "model_help.h"

/*! \fn bisection_gb
 *
 *  \param [ref] [data]
 *  \param [ref] [a]
 *  \param [ref] [b]
 *  \param [ref] [states_a]
 *  \param [ref] [states_b]
 *  \param [ref] [eventListTmp]
 *  \param [in]  [eventList]
 *
 *  Method to find root in interval [oldTime, timeValue]
 */
void bisection_gb(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo, double* a, double* b, double* states_a, double* states_b, LIST *tmpEventList, LIST *eventList, modelica_boolean isInnerIntegration)
{
  TRACE_PUSH

  DATA_GBODE *gbData = (DATA_GBODE *)solverInfo->solverData;
  DATA_GBODEF *gbfData;

  int gb_step_info;
  double timeValue, *y;

  double TTOL = GB_MINIMAL_STEP_SIZE + GB_MINIMAL_STEP_SIZE*fabs(*b-*a); /* absTol + relTol*abs(b-a) */
  double c;
  long i=0;
  /* n >= log(2)/log(2) + log(|b-a|/TOL)/log(2)*/
  unsigned int n = maxBisectionIterations > 0 ? maxBisectionIterations : 1 + ceil(log(fabs(*b - *a)/TTOL)/log(2));

  memcpy(data->simulationInfo->zeroCrossingsBackup, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));

  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "bisection method starts in interval [%e, %e]", *a, *b);
  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "TTOL is set to %e and maximum number of intersections %d.", TTOL, n);

  while(fabs(*b - *a) > GB_MINIMAL_STEP_SIZE && n-- > 0)
  {
    c = 0.5 * (*a + *b);
    data->localData[0]->timeValue = c;

    /*calculates states at time c using interpolation */
    if (isInnerIntegration) {
      gbfData = gbData->gbfData;
      gb_interpolation(gbfData->interpolation,
                  gbfData->timeLeft,  gbfData->yLeft,  gbfData->kLeft,
                  gbfData->timeRight, gbfData->yRight, gbfData->kRight,
                  c, data->localData[0]->realVars,
                  gbData->nStates, NULL,  gbData->nStates, gbfData->tableau, gbfData->x, gbfData->k);
    } else {
      gb_interpolation(gbData->interpolation,
                  gbData->timeLeft,  gbData->yLeft,  gbData->kLeft,
                  gbData->timeRight, gbData->yRight, gbData->kRight,
                  c, data->localData[0]->realVars,
                  gbData->nStates, NULL,  gbData->nStates, gbData->tableau, gbData->x, gbData->k);
    }

    /*calculates Values dependents on new states*/
    /* read input vars */
    externalInputUpdate(data);
    data->callback->input_function(data, threadData);
    /* eval needed equations*/
    data->callback->function_ZeroCrossingsEquations(data, threadData);

    data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);

    if(checkZeroCrossings(data, tmpEventList, eventList))  /* If Zerocrossing in left Section */
    {
      memcpy(states_b, data->localData[0]->realVars, data->modelData->nStates * sizeof(modelica_real));
      *b = c;
      memcpy(data->simulationInfo->zeroCrossingsBackup, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));
    }
    else  /*else Zerocrossing in right Section */
    {
      memcpy(states_a, data->localData[0]->realVars, data->modelData->nStates * sizeof(modelica_real));
      *a = c;
      memcpy(data->simulationInfo->zeroCrossingsPre, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));
      memcpy(data->simulationInfo->zeroCrossings, data->simulationInfo->zeroCrossingsBackup, data->modelData->nZeroCrossings * sizeof(modelica_real));
    }
  }

  TRACE_POP
}

/*! \fn findRoot
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [ref] [eventList]
 *  \param [in]  [time_left]
 *  \param [in]  [values_left]
 *  \param [in]  [time_right]
 *  \param [in]  [values_right]
 *  \return: first event of interval [time_left, time_right]
 */
double findRoot_gb(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, LIST* eventList, double time_left, double* values_left, double time_right, double* values_right, modelica_boolean isInnerIntegration)
{
  TRACE_PUSH

  LIST_NODE* it;
  fortran_integer i=0;
  LIST *tmpEventList = allocList(eventListAlloc, eventListFree, eventListCopy);

  /* static work arrays */
  double *states_left = data->simulationInfo->states_left;
  double *states_right = data->simulationInfo->states_right;

  /* write states to work arrays */
  memcpy(states_left,  values_left,  data->modelData->nStates * sizeof(double));
  memcpy(states_right, values_right, data->modelData->nStates * sizeof(double));

  for(it=listFirstNode(eventList); it; it=listNextNode(it))
  {
    infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "search for current event. Events in list: %ld", *((long*)listNodeData(it)));
  }

  /* Search for event time and event_id with bisection method */
  bisection_gb(data, threadData, solverInfo, &time_left, &time_right, states_left, states_right, tmpEventList, eventList, isInnerIntegration);

  /* what happens here? */
  if(listLen(tmpEventList) == 0)
  {
    double value = fabs(data->simulationInfo->zeroCrossings[*((long*) listFirstData(eventList))]);
    for(it = listFirstNode(eventList); it; it = listNextNode(it))
    {
      double fvalue = fabs(data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))]);
      if(value > fvalue)
      {
        value = fvalue;
      }
    }
    infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "Minimum value: %e", value);
    for(it = listFirstNode(eventList); it; it = listNextNode(it))
    {
      if(value == fabs(data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))]))
      {
        listPushBack(tmpEventList, listNodeData(it));
        infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "added tmp event : %ld", *((long*) listNodeData(it)));
      }
    }
  }

  listClear(eventList);

  debugStreamPrint(OMC_LOG_EVENTS, 0, (listLen(tmpEventList) == 1) ? "found event: " : "found events: ");
  while(listLen(tmpEventList) > 0)
  {
    long event_id = *((long*)listFirstData(tmpEventList));
    listPushFrontNodeNoCopy(eventList, listPopFrontNode(tmpEventList));
    infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "Event id: %ld", event_id);
  }

  debugStreamPrint(OMC_LOG_EVENTS, 0, "time: %.10e", time_right);

  data->localData[0]->timeValue = time_left;
  memcpy(data->localData[0]->realVars, states_left, data->modelData->nStates * sizeof(double));

  /* determined continuous system */
  data->callback->updateContinuousSystem(data, threadData);
  updateRelationsPre(data);
  /*sim_result_emit(data);*/

  data->localData[0]->timeValue = time_right;
  memcpy(data->localData[0]->realVars, states_right, data->modelData->nStates * sizeof(double));

  freeList(tmpEventList);

  TRACE_POP
  return time_right;
}

/**
 * @brief Check if an event has happend between timeLeft and timeRight by comparing the
 *        values of the zero crossing functions with the pre values
 *
 * @param data                    Runtime data struct.
 * @param threadData              Thread data for error handling.
 * @param solverInfo              Information about main solver.
 * @param timeLeft                Time value at the left hand side of the interval
 * @param leftValues              State values at the left hand side of the time interval
 * @param timeRight               Time value at the right hand side of the interval
 * @param rightValues             State values at the right hand side of the time interval
 * @param isInnerIntegration      Specifying if inner or outer step function should be used.
 * @param foundEvent              On return is set to true if an event was found, otherwise false.
 *                                Returned event time must be ignored if foundEvent=false.
 * @return double                 Event time if an event was found, NAN otherwise.
 */
double checkForEvents(DATA* data, threadData_t* threadData, SOLVER_INFO* solverInfo, double timeLeft, double* leftValues, double timeRight, double* rightValues, modelica_boolean isInnerIntegration, modelica_boolean* foundEvent)
{
  SIMULATION_DATA *sData = (SIMULATION_DATA*)data->localData[0];

  double eventTime = DBL_MAX;

  static LIST *tmpEventList = NULL;

  // store the pre values of the zeroCrossings for comparison
  memcpy(data->simulationInfo->zeroCrossingsPre, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));

  // set simulation data to the current time
  sData->timeValue = timeRight;
  memcpy(sData->realVars, rightValues, data->modelData->nStates*sizeof(double));
  /*calculates Values dependents on new states*/
  /* read input vars */
  externalInputUpdate(data);
  data->callback->input_function(data, threadData);
  /* eval needed equations*/
  data->callback->function_ZeroCrossingsEquations(data, threadData);
  data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);

  *foundEvent = checkForStateEvent(data, solverInfo->eventLst);

  if (*foundEvent) {
     if (omc_flag[FLAG_NO_ROOTFINDING]) {
       eventTime = timeRight;
       infoStreamPrint(OMC_LOG_SOLVER, 0, "gbode detected an event at time: %20.16g (rootfinding is disabled)", eventTime);
     } else {
       eventTime = findRoot_gb(data, threadData, solverInfo, solverInfo->eventLst, timeLeft, leftValues, timeRight, rightValues, isInnerIntegration);
       infoStreamPrint(OMC_LOG_SOLVER, 0, "gbode detected an event at time: %20.16g", eventTime);
    }
  }
  // re-store the pre values of the zeroCrossings for comparison
  memcpy(data->simulationInfo->zeroCrossings, data->simulationInfo->zeroCrossingsPre, data->modelData->nZeroCrossings * sizeof(modelica_real));

  return eventTime;
}
