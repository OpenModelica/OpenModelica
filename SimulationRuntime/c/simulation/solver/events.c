/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
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

#include "events.h"
#include "omc_error.h"
#include "simulation_data.h"
#include "simulation_result.h"
#include "openmodelica.h"         /* for modelica types */
#include "openmodelica_func.h"    /* for modelica fucntion */
#include "simulation_runtime.h"
#include "solver_main.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

double bisection(DATA* data, double*, double*, double*, double*, LIST*, LIST*);
int checkZeroCrossings(DATA *data, LIST *list, LIST*);
void saveZeroCrossingsAfterEvent(DATA *data);

int checkForStateEvent(DATA* data, LIST *eventList);

const double eps = 1e-14;

/*! \fn initSample
 *
 *  \param [ref] [data]
 *  \param [in]  [startTime]
 *  \param [in]  [stopTime]
 *
 *  This function initializes sample-events.
 */
void initSample(DATA* data, double startTime, double stopTime)
{
  long i;

  function_initSample(data);                              /* set-up sample */
  data->simulationInfo.nextSampleEvent = stopTime + 1.0;  /* should never be reached */
  for(i=0; i<data->modelData.nSamples; ++i)
  {
    if(startTime < data->modelData.samplesInfo[i].start) {
      data->simulationInfo.nextSampleTimes[i] = data->modelData.samplesInfo[i].start;
    } else {
      data->simulationInfo.nextSampleTimes[i] = data->modelData.samplesInfo[i].start + ceil((startTime-data->modelData.samplesInfo[i].start) / data->modelData.samplesInfo[i].interval) * data->modelData.samplesInfo[i].interval;
    }

    if((i == 0) || (data->simulationInfo.nextSampleTimes[i] < data->simulationInfo.nextSampleEvent)) {
      data->simulationInfo.nextSampleEvent = data->simulationInfo.nextSampleTimes[i];
    }
  }

  if(stopTime < data->simulationInfo.nextSampleEvent) {
    DEBUG(LOG_EVENTS, "there are no sample-events");
  } else {
    DEBUG1(LOG_EVENTS, "first sample-event at t = %g", data->simulationInfo.nextSampleEvent);
  }
}


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
  double time = solverInfo->currentTime + solverInfo->currentStepSize;

  if(data->simulationInfo.nextSampleEvent <= time + eps)
  {
    solverInfo->currentStepSize = data->simulationInfo.nextSampleEvent - solverInfo->currentTime;
    data->simulationInfo.sampleActivated = 1;
  }
}

/*! \fn checkForStateEvent
 *
 *  \param [ref] [data]
 *  \param [ref] [eventList]
 *
 *  This function checks for Events in Interval=[oldTime, timeValue]
 *  If a ZeroCrossing Function cause a sign change, root finding
 *  process will start
 */
int checkForStateEvent(DATA* data, LIST *eventList)
{
  long i=0;

  DEBUG1(LOG_EVENTS, "check state-event zerocrossing at time %g",  data->localData[0]->timeValue);
  INDENT(LOG_EVENTS);

  for(i=0; i<data->modelData.nZeroCrossings; i++)
  {
    DEBUG1(LOG_EVENTS, "%s", zeroCrossingDescription[i]);
    INDENT(LOG_EVENTS);
    if((data->simulationInfo.zeroCrossings[i] == 1 && data->simulationInfo.zeroCrossingsPre[i] == -1) ||
       (data->simulationInfo.zeroCrossings[i] == -1 && data->simulationInfo.zeroCrossingsPre[i] == 1))
    {
      DEBUG2(LOG_EVENTS, "changed:   %s -> %s", (data->simulationInfo.zeroCrossingsPre[i]>0) ? "TRUE" : "FALSE", (data->simulationInfo.zeroCrossings[i]>0) ? "TRUE" : "FALSE");
      listPushFront(eventList, &(data->simulationInfo.zeroCrossingIndex[i]));
    }
    else
    {
      DEBUG2(LOG_EVENTS, "unchanged: %s -> %s", (data->simulationInfo.zeroCrossingsPre[i]>0) ? "TRUE" : "FALSE", (data->simulationInfo.zeroCrossings[i]>0) ? "TRUE" : "FALSE");
    }
    RELEASE(LOG_EVENTS);
  }
  RELEASE(LOG_EVENTS);

  if(listLen(eventList) > 0)
    return 1;
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
 *  \param [ref] [eventList]
 *  \param [in]  [eventTime]
 *  \param [ref] [solverInfo]
 *  \return 0: no event; 1: time event; 2: state event
 */
int checkEvents(DATA* data, LIST* eventLst, double *eventTime, SOLVER_INFO* solverInfo)
{
  if(checkForStateEvent(data, solverInfo->eventLst))
    if(!solverInfo->solverRootFinding)
      findRoot(data, solverInfo->eventLst, &(solverInfo->currentTime));

  if(data->simulationInfo.sampleActivated == 1)
    return 1;
  if(listLen(eventLst)>0)
    return 2;

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
void handleEvents(DATA* data, LIST* eventLst, double *eventTime, SOLVER_INFO* solverInfo)
{
  double time = data->localData[0]->timeValue;
  long i;
  LIST_NODE* it;

  sim_result.emit(&sim_result,data);

  /* time event */
  if(data->simulationInfo.sampleActivated)
  {
    storePreValues(data);

    /* activate time event */
    for(i=0; i<data->modelData.nSamples; ++i)
      if(data->simulationInfo.nextSampleTimes[i] <= time + eps)
      {
        data->simulationInfo.samples[i] = 1;
        INFO3(LOG_EVENTS, "[%ld] sample(%g, %g)", data->modelData.samplesInfo[i].index, data->modelData.samplesInfo[i].start, data->modelData.samplesInfo[i].interval);
      }
  }

  /* state event */
  if(listLen(eventLst)>0)
  {
    data->localData[0]->timeValue = *eventTime;
    /* time = data->localData[0]->timeValue; */

    for(it = listFirstNode(eventLst); it; it = listNextNode(it))
      INFO2(LOG_EVENTS, "[%ld] %s", *((long*) listNodeData(it)), zeroCrossingDescription[*((long*) listNodeData(it))]);

    listClear(eventLst);
    solverInfo->stateEvents++;
  }

  /* update the whole system */
  updateDiscreteSystem(data);
  saveZeroCrossingsAfterEvent(data);
  /*sim_result_emit(data);*/

  /* time event */
  if(data->simulationInfo.sampleActivated)
  {
    /* deactivate time events */
    for(i=0; i<data->modelData.nSamples; ++i)
    {
      if(data->simulationInfo.samples[i])
      {
        data->simulationInfo.samples[i] = 0;
        data->simulationInfo.nextSampleTimes[i] += data->modelData.samplesInfo[i].interval;
      }
    }

    for(i=0; i<data->modelData.nSamples; ++i)
      if((i == 0) || (data->simulationInfo.nextSampleTimes[i] < data->simulationInfo.nextSampleEvent))
        data->simulationInfo.nextSampleEvent = data->simulationInfo.nextSampleTimes[i];

    data->simulationInfo.sampleActivated = 0;

    INDENT(LOG_EVENTS);
    DEBUG1(LOG_EVENTS, "next sample-event at t = %g", data->simulationInfo.nextSampleEvent);
    RELEASE(LOG_EVENTS);

    solverInfo->sampleEvents++;
  }
}

/*! \fn findRoot
 *
 *  \param [ref] [data]
 *  \param [ref] [eventLst]
 *  \param [in]  [eventTime]
 *
 *  This function perform a root finding for Intervall = [oldTime, timeValue]
 */
void findRoot(DATA* data, LIST *eventList, double *eventTime)
{
  long event_id;
  LIST_NODE* it;
  fortran_integer i=0;
  static LIST *tmpEventList = NULL;

  double *states_right = (double*) malloc(data->modelData.nStates * sizeof(double));
  double *states_left = (double*) malloc(data->modelData.nStates * sizeof(double));

  double time_left = data->simulationInfo.timeValueOld;
  double time_right = data->localData[0]->timeValue;

  tmpEventList = allocList(sizeof(long));

  assert(states_right);
  assert(states_left);

  INDENT(LOG_ZEROCROSSINGS);
  for(it=listFirstNode(eventList); it; it=listNextNode(it))
  {
    INFO1(LOG_ZEROCROSSINGS, "search for current event. Events in list: %ld", *((long*)listNodeData(it)));
  }
  RELEASE(LOG_ZEROCROSSINGS);

  /* write states to work arrays */
  for(i=0; i < data->modelData.nStates; i++)
  {
    states_left[i] = data->simulationInfo.realVarsOld[i];
    states_right[i] = data->localData[0]->realVars[i];
  }

  /* Search for event time and event_id with bisection method */
  *eventTime = bisection(data, &time_left, &time_right, states_left, states_right, tmpEventList, eventList);

  if(listLen(tmpEventList) == 0)
  {
    double value = fabs(data->simulationInfo.zeroCrossings[*((long*) listFirstData(eventList))]);
    for(it = listFirstNode(eventList); it; it = listNextNode(it)) {
      double fvalue = fabs(data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))]);
      if(value > fvalue)
      {
        value = fvalue;
      }
    }
    INFO1(LOG_ZEROCROSSINGS, "Minimum value: %e", value);
    for(it = listFirstNode(eventList); it; it = listNextNode(it))
    {
      if(value == fabs(data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))]))
      {
        listPushBack(tmpEventList, listNodeData(it));
        INFO1(LOG_ZEROCROSSINGS, "added tmp event : %ld", *((long*) listNodeData(it)));
      }
    }
  }

  listClear(eventList);

  if(ACTIVE_STREAM(LOG_EVENTS))
  {
    if(listLen(tmpEventList) > 0)
    {
      DEBUG(LOG_EVENTS, "found events: ");
    }
    else
    {
      DEBUG(LOG_EVENTS, "found event: ");
    }
  }
  while(listLen(tmpEventList) > 0)
  {
    event_id = *((long*)listFirstData(tmpEventList));
    listPopFront(tmpEventList);

    INFO1(LOG_EVENTS, "%ld ", event_id);

    if(listLen(tmpEventList) > 0)
      DEBUG(LOG_EVENTS, ", ");

    listPushFront(eventList, &event_id);
  }
  DEBUG(LOG_EVENTS, "\n");

  *eventTime = time_right;
  DEBUG1(LOG_EVENTS, "time: %.10e", *eventTime);

  data->localData[0]->timeValue = time_left;
  for(i=0; i < data->modelData.nStates; i++)
  {
    data->localData[0]->realVars[i] = states_left[i];
  }

  /* determined continuous system */
  updateContinuousSystem(data);
  storeRelations(data);
  /*sim_result_emit(data);*/

  data->localData[0]->timeValue = *eventTime;
  for(i=0; i < data->modelData.nStates; i++)
  {
    data->localData[0]->realVars[i] = states_right[i];
  }

  free(states_left);
  free(states_right);
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
 *  \return Founded event time
 *
 *  Method to find root in Intervall [oldTime, timeValue]
 */
double bisection(DATA* data, double* a, double* b, double* states_a, double* states_b, LIST *tmpEventList, LIST *eventList)
{
  double TTOL = 1e-9;
  double c;
  int right = 0;
  long i=0;

  double *backup_gout = (double*) malloc(
      data->modelData.nZeroCrossings * sizeof(double));
  assert(backup_gout);

  for(i=0; i < data->modelData.nZeroCrossings; i++)
  {
    backup_gout[i] = data->simulationInfo.zeroCrossings[i];
  }

  INFO2(LOG_ZEROCROSSINGS, "bisection method starts in interval [%e, %e]", *a, *b);
  INFO1(LOG_ZEROCROSSINGS, "TTOL is set to: %e", TTOL);

  while(fabs(*b - *a) > TTOL)
  {
    c = (*a + *b) / 2.0;
    data->localData[0]->timeValue = c;

    /*calculates states at time c */
    for(i=0; i < data->modelData.nStates; i++)
    {
      data->localData[0]->realVars[i] = (states_a[i] + states_b[i]) / 2.0;
    }

    /*calculates Values dependents on new states*/
    functionODE(data);
    functionAlgebraics(data);

    function_ZeroCrossings(data, data->simulationInfo.zeroCrossings, &(data->localData[0]->timeValue));

    if(checkZeroCrossings(data, tmpEventList, eventList))  /* If Zerocrossing in left Section */
    {
      for(i=0; i < data->modelData.nStates; i++)
      {
        states_b[i] = data->localData[0]->realVars[i];
      }
      *b = c;
      right = 0;
    }
    else  /*else Zerocrossing in right Section */
    {
      for(i=0; i < data->modelData.nStates; i++)
      {
        states_a[i] = data->localData[0]->realVars[i];
      }
      *a = c;
      right = 1;
    }
    if(right)
    {
      for(i=0; i < data->modelData.nZeroCrossings; i++)
      {
        data->simulationInfo.zeroCrossingsPre[i] = data->simulationInfo.zeroCrossings[i];
        data->simulationInfo.zeroCrossings[i] = backup_gout[i];
      }
    }
    else
    {
      for(i=0; i < data->modelData.nZeroCrossings; i++)
      {
        backup_gout[i] = data->simulationInfo.zeroCrossings[i];
      }
    }
  }
  free(backup_gout);
  c = (*a + *b) / 2.0;
  return c;
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
  LIST_NODE *it;

  listClear(tmpEventList);
  INFO(LOG_ZEROCROSSINGS, "bisection checks for condition changes");

  for(it = listFirstNode(eventList); it; it = listNextNode(it))
  {
    /* found event in left section */
    if((data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] == -1 &&
        data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))] == 1) ||
       (data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] == 1 &&
        data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))] == -1))
    {
      INFO3(LOG_ZEROCROSSINGS, "%ld changed from %s to current %s",
            *((long*) listNodeData(it)),
            (data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))]>0) ? "TRUE" : "FALSE",
            (data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))]>0) ? "TRUE" : "FALSE");
      listPushFront(tmpEventList, listNodeData(it));
    }
  }

  if(listLen(tmpEventList) > 0)
    return 1;   /* event in left section */
  return 0;     /* event in right section */
}

/*! \fn saveZeroCrossingsAfterEvent
 *
 *  Function saves all zero-crossing values as pre(zero-crossing)
 *
 *  \param [ref] [data]
 */
void saveZeroCrossingsAfterEvent(DATA *data)
{
  long i=0;

  INFO(LOG_ZEROCROSSINGS, "save all zerocrossings after an event"); /* ??? */

  function_ZeroCrossings(data, data->simulationInfo.zeroCrossings, &(data->localData[0]->timeValue));
  for(i=0; i<data->modelData.nZeroCrossings; i++)
    data->simulationInfo.zeroCrossingsPre[i] = data->simulationInfo.zeroCrossings[i];
}

#ifdef __cplusplus
}
#endif
