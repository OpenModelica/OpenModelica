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

#include "events.h"
#include "../../util/omc_error.h"
#include "../options.h"
#include "../../simulation_data.h"
#include "../../openmodelica.h"         /* for modelica types */
#include "../../openmodelica_func.h"    /* for modelica functions */
#include "solver_main.h"
#include "model_help.h"
#include "external_input.h"
#include "epsilon.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

int maxBisectionIterations = 0;
void bisection(DATA* data, threadData_t *threadData, double*, double*, double*, double*, LIST*, LIST*);
void saveZeroCrossingsAfterEvent(DATA *data, threadData_t *threadData);

/*! \fn checkForSampleEvent
 *
 *  \param [ref] [data]
 *  \param [ref] [solverInfo]
 *  \return indicates if a time event is occuered or not.
 *
 *  Function check if a sample expression should be activated
 *  before next step and sets then the next step size to the
 *  time event.
 *
 */
void checkForSampleEvent(DATA *data, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  double nextTimeStep = solverInfo->currentTime + solverInfo->currentStepSize;

  if ((data->simulationInfo->nextSampleEvent <= nextTimeStep + SAMPLE_EPS) && (data->simulationInfo->nextSampleEvent >= solverInfo->currentTime))
  {
    solverInfo->currentStepSize = data->simulationInfo->nextSampleEvent - solverInfo->currentTime;
    data->simulationInfo->sampleActivated = 1;
    infoStreamPrint(OMC_LOG_EVENTS_V, 0, "Adjust step-size to %.15g at time %.15g to get next sample event at %.15g", solverInfo->currentStepSize, solverInfo->currentTime, data->simulationInfo->nextSampleEvent );
  }

  TRACE_POP
}

/*! \fn checkForStateEvent
 *
 *  \param [ref] [data]
 *  \param [ref] [eventList]
 *
 *  This function checks for events in interval=[oldTime, timeValue]
 *  If a zero crossing function cause a sign change, root finding
 *  process will start
 */
int checkForStateEvent(DATA* data, LIST *eventList)
{
  TRACE_PUSH
  long i=0;

  debugStreamPrint(OMC_LOG_EVENTS, 1, "check state-event zerocrossing at time %g", data->localData[0]->timeValue);

  for(i=0; i<data->modelData->nZeroCrossings; i++)
  {
    int *eq_indexes;
    if (OMC_DEBUG_STREAM(OMC_LOG_EVENTS))
    {
      const char *exp_str = data->callback->zeroCrossingDescription(i,&eq_indexes);
      debugStreamPrintWithEquationIndexes(OMC_LOG_EVENTS, omc_dummyFileInfo, 1, eq_indexes, "%s", exp_str);
    }

    if(sign(data->simulationInfo->zeroCrossings[i]) != sign(data->simulationInfo->zeroCrossingsPre[i]))
    {
      debugStreamPrint(OMC_LOG_EVENTS, 0, "changed:   %s", (data->simulationInfo->zeroCrossingsPre[i] > 0) ? "TRUE -> FALSE" : "FALSE -> TRUE");
      listPushFront(eventList, &(data->simulationInfo->zeroCrossingIndex[i]));
    }
    else
    {
      debugStreamPrint(OMC_LOG_EVENTS, 0, "unchanged: %s", (data->simulationInfo->zeroCrossingsPre[i] > 0) ? "TRUE -- TRUE" : "FALSE -- FALSE");
    }

    if (OMC_DEBUG_STREAM(OMC_LOG_EVENTS))
      messageClose(OMC_LOG_EVENTS);
  }
  if (OMC_DEBUG_STREAM(OMC_LOG_EVENTS))
    messageClose(OMC_LOG_EVENTS);

  if(listLen(eventList) > 0)
  {
    TRACE_POP
    return 1;
  }

  TRACE_POP
  return 0;
}

/*! \fn checkEvents
 *
 *  This function check if a time event or a state event should
 *  processed. If sample and state event have the same event-time
 *  then time events are prioritize, since they handle also
 *  state event. It returns 1 if state event is before time event
 *  then it de-activate the time events.
 *
 *  \param [ref] [data]
 *  \param [ref] [threadData]
 *  \param [ref] [eventLst]
 *  \param [in]  [useRootFinding]
 *  \param [out] [eventTime]
 *  \return 0: no event; 1: time event; 2: state event
 */
int checkEvents(DATA* data, threadData_t *threadData, LIST* eventLst, modelica_boolean useRootFinding, double *eventTime)
{
  TRACE_PUSH

  int found = checkForStateEvent(data, eventLst);
  if(found && useRootFinding)
  {
    *eventTime = findRoot(data, threadData, eventLst, data->simulationInfo->timeValueOld, data->simulationInfo->realVarsOld, data->localData[0]->timeValue, data->localData[0]->realVars);
  }

  if(data->simulationInfo->sampleActivated == 1)
  {
    TRACE_POP
    return 1;
  }

  if(listLen(eventLst) > 0)
  {
    TRACE_POP
    return 2;
  }

  TRACE_POP
  return 0;
}

/*! \fn handleEvents
 *
 *  \param [ref] [data]
 *  \param [ref] [eventList]
 *  \param [in]  [eventTime]
 *
 *  This handles all zero crossing events from event list at event time
 */
void handleEvents(DATA* data, threadData_t *threadData, LIST* eventLst, double *eventTime, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  double time = data->localData[0]->timeValue;
  long i;
  LIST_NODE* it;

  /* time event */
  if(data->simulationInfo->sampleActivated)
  {
    storePreValues(data);

    /* activate time event */
    for(i=0; i<data->modelData->nSamples; ++i)
      if(data->simulationInfo->nextSampleTimes[i] <= time + SAMPLE_EPS)
      {
        data->simulationInfo->samples[i] = 1;
        infoStreamPrint(OMC_LOG_EVENTS, 0, "[%ld] sample(%g, %g)", data->modelData->samplesInfo[i].index, data->modelData->samplesInfo[i].start, data->modelData->samplesInfo[i].interval);
      }
  }
  data->simulationInfo->chatteringInfo.lastStepsNumStateEvents-=data->simulationInfo->chatteringInfo.lastSteps[data->simulationInfo->chatteringInfo.currentIndex];
  /* state event */
  if(listLen(eventLst)>0)
  {
    data->localData[0]->timeValue = *eventTime;
    /* time = data->localData[0]->timeValue; */

    if (omc_useStream[OMC_LOG_EVENTS])
    {
      for(it = listFirstNode(eventLst); it; it = listNextNode(it))
      {
        long ix = *((long*) listNodeData(it));
        int *eq_indexes;
        const char *exp_str = data->callback->zeroCrossingDescription(ix,&eq_indexes);
        infoStreamPrintWithEquationIndexes(OMC_LOG_EVENTS, omc_dummyFileInfo, 0, eq_indexes, "[%ld] %s", ix+1, exp_str);
      }
    }

    solverInfo->stateEvents++;
    data->simulationInfo->chatteringInfo.lastStepsNumStateEvents++;
    data->simulationInfo->chatteringInfo.lastSteps[data->simulationInfo->chatteringInfo.currentIndex]=1;
    data->simulationInfo->chatteringInfo.lastTimes[data->simulationInfo->chatteringInfo.currentIndex]=time;

    if (!data->simulationInfo->chatteringInfo.messageEmitted && data->simulationInfo->chatteringInfo.lastStepsNumStateEvents == data->simulationInfo->chatteringInfo.numEventLimit)
    {
      int numEventLimit = data->simulationInfo->chatteringInfo.numEventLimit;
      int currentIndex = data->simulationInfo->chatteringInfo.currentIndex;
      double t0 = data->simulationInfo->chatteringInfo.lastTimes[(currentIndex+1) % numEventLimit];
      if (time - t0 < data->simulationInfo->stepSize)
      {
        long ix = *((long*) listNodeData(listFirstNode(eventLst)));
        int *eq_indexes;
        const char *exp_str = data->callback->zeroCrossingDescription(ix,&eq_indexes);
        infoStreamPrintWithEquationIndexes(OMC_LOG_STDOUT, omc_dummyFileInfo, 0, eq_indexes, "Chattering detected around time %.12g..%.12g (%d state events in a row with a total time delta less than the step size %.12g). This can be a performance bottleneck. Use -lv LOG_EVENTS for more information. The zero-crossing was: %s", t0, time, numEventLimit, data->simulationInfo->stepSize, exp_str);
        data->simulationInfo->chatteringInfo.messageEmitted = 1;
        if (omc_flag[FLAG_ABORT_SLOW])
        {
          throwStreamPrintWithEquationIndexes(threadData, omc_dummyFileInfo, eq_indexes, "Aborting simulation due to chattering being detected and the simulation flags requesting we do not continue further.");
        }
      }
    }

    listClear(eventLst);
  } else {
    data->simulationInfo->chatteringInfo.lastSteps[data->simulationInfo->chatteringInfo.currentIndex]=0;
    /* Setting time does not matter */
  }
  data->simulationInfo->chatteringInfo.currentIndex = (data->simulationInfo->chatteringInfo.currentIndex+1) % data->simulationInfo->chatteringInfo.numEventLimit;

  /* update the whole system */
  updateDiscreteSystem(data, threadData);
  saveZeroCrossingsAfterEvent(data, threadData);
  /*sim_result_emit(data);*/

  /* time event */
  if(data->simulationInfo->sampleActivated)
  {
    /* deactivate time events */
    for(i=0; i<data->modelData->nSamples; ++i)
    {
      if(data->simulationInfo->samples[i])
      {
        data->simulationInfo->samples[i] = 0;
        data->simulationInfo->nextSampleTimes[i] += data->modelData->samplesInfo[i].interval;
      }
    }

    for(i=0; i<data->modelData->nSamples; ++i)
      if((i == 0) || (data->simulationInfo->nextSampleTimes[i] < data->simulationInfo->nextSampleEvent))
        data->simulationInfo->nextSampleEvent = data->simulationInfo->nextSampleTimes[i];

    data->simulationInfo->sampleActivated = 0;

    debugStreamPrint(OMC_LOG_EVENTS, 0, "next sample-event at t = %g", data->simulationInfo->nextSampleEvent);

    solverInfo->sampleEvents++;
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
double findRoot(DATA* data, threadData_t* threadData, LIST* eventList, double time_left, double* values_left, double time_right, double* values_right)
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
  bisection(data, threadData, &time_left, &time_right, states_left, states_right, tmpEventList, eventList);

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

/*! \fn bisection
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
void bisection(DATA* data, threadData_t *threadData, double* a, double* b, double* states_a, double* states_b, LIST *tmpEventList, LIST *eventList)
{
  TRACE_PUSH

  double TTOL = MINIMAL_STEP_SIZE + MINIMAL_STEP_SIZE*fabs(*b-*a); /* absTol + relTol*abs(b-a) */
  double c;
  long i=0;
  /* n >= log(2)/log(2) + log(|b-a|/TOL)/log(2)*/
  unsigned int n = maxBisectionIterations > 0 ? maxBisectionIterations : 1 + ceil(log(fabs(*b - *a)/TTOL)/log(2));

  memcpy(data->simulationInfo->zeroCrossingsBackup, data->simulationInfo->zeroCrossings, data->modelData->nZeroCrossings * sizeof(modelica_real));

  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "bisection method starts in interval [%e, %e]", *a, *b);
  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "TTOL is set to %e and maximum number of intersections %d.", TTOL, n);

  while(fabs(*b - *a) > MINIMAL_STEP_SIZE && n-- > 0)
  {
    c = 0.5 * (*a + *b);
    data->localData[0]->timeValue = c;

    /*calculates states at time c */
    for(i=0; i < data->modelData->nStates; i++)
    {
      data->localData[0]->realVars[i] = 0.5*(states_a[i] + states_b[i]);
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

/*! \fn checkZeroCrossings
 *
 *  Function checks for an event list on events
 *
 *  \param [ref] [data]
 *  \param [ref] [eventListTmp]
 *  \param [in]  [eventList]
 *  \return boolean value
 */
int checkZeroCrossings(DATA *data, LIST *tmpEventList, LIST *eventList)
{
  TRACE_PUSH
  LIST_NODE *it;

  listClear(tmpEventList);
  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "bisection checks for condition changes");

  for(it=listFirstNode(eventList); it; it=listNextNode(it))
  {
    /* found event in left section */
    if((data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))] == -1 &&
        data->simulationInfo->zeroCrossingsPre[*((long*) listNodeData(it))] == 1) ||
       (data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))] == 1 &&
        data->simulationInfo->zeroCrossingsPre[*((long*) listNodeData(it))] == -1))
    {
      infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "%ld changed from %s to current %s",
            *((long*) listNodeData(it)),
            (data->simulationInfo->zeroCrossingsPre[*((long*) listNodeData(it))] > 0) ? "TRUE" : "FALSE",
            (data->simulationInfo->zeroCrossings[*((long*) listNodeData(it))] > 0) ? "TRUE" : "FALSE");
      listPushFront(tmpEventList, listNodeData(it));
    }
  }

  if(listLen(tmpEventList) > 0)
  {
    TRACE_POP
    return 1;   /* event in left section */
  }

  TRACE_POP
  return 0;     /* event in right section */
}

/*! \fn saveZeroCrossingsAfterEvent
 *
 *  Function saves all zero-crossing values as pre(zero-crossing)
 *
 *  \param [ref] [data]
 */
void saveZeroCrossingsAfterEvent(DATA *data, threadData_t *threadData)
{
  TRACE_PUSH
  long i=0;

  infoStreamPrint(OMC_LOG_ZEROCROSSINGS, 0, "save all zerocrossings after an event at time=%g", data->localData[0]->timeValue); /* ??? */

  data->callback->function_ZeroCrossings(data, threadData, data->simulationInfo->zeroCrossings);
  for(i=0; i<data->modelData->nZeroCrossings; i++)
    data->simulationInfo->zeroCrossingsPre[i] = data->simulationInfo->zeroCrossings[i];

  TRACE_POP
}

/**
 * @brief Allocate memory for eventList elements.
 *
 * @param data      Unused.
 * @return void*    Allocated memory for LIST_NODE data.
 */
void* eventListAlloc(const void* data) {
  void* newElem = malloc(sizeof(long));
  assertStreamPrint(NULL, newElem != NULL, "eventListAlloc: Out of memory");
  return newElem;
}

/**
 * @brief Free memory allocated with eventListAlloc.
 *
 * @param data      Void pointer, representing index for new list element.
 */
void eventListFree(void* data) {
  free(data);
}

/**
 * @brief Copy data of eventList elements.
 *
 * @param dest    Void pointer of destination data, representing long index.
 * @param src     Void pointer of source data, representing long index.
 */
void eventListCopy(void* dest, const void* src) {
  long* dest_event = (long*) dest;
  *dest_event = *((long*) src);
}

#ifdef __cplusplus
}
#endif
