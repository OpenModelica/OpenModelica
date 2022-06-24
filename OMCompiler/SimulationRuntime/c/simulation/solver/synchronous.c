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

#include "synchronous.h"
#include "epsilon.h"
#include "../results/simulation_result.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Function prototypes */
void printClocks(BASECLOCK_DATA* baseClocks, int nBaseCllocks);
void printSyncTimer(void* data, int stream, void* elemPointer);

/**
 * @brief Initialize memory for synchronous functionalities.
 *
 * @param data            Pointer to data.
 * @param threadData      Pointer to thread data.
 * @param startTime       Start time of simulation.
 */
void initSynchronous(DATA* data, threadData_t *threadData, modelica_real startTime)
{
  TRACE_PUSH
  int i,j;
  BASECLOCK_DATA* baseClock;

  /* Initialize clocks */
  data->callback->function_initSynchronous(data, threadData);

  /* Error check */
  for(i=0; i<data->modelData->nBaseClocks; i++) {
    for(j=0; j<data->simulationInfo->baseClocks[i].nSubClocks; j++) {
      assertStreamPrint(threadData, data->simulationInfo->baseClocks[i].subClocks[j].solverMethod != NULL, "Continuous clocked systems aren't supported yet.");
      assertStreamPrint(threadData, floorRat(data->simulationInfo->baseClocks[i].subClocks[j].shift) >= 0, "Shift of sub-clock is negative. Sub-clocks aren't allowed to fire before base-clock.");
    }
    if (data->simulationInfo->baseClocks[i].isEventClock) { /*event clock*/
      for(j=0; j<data->simulationInfo->baseClocks[i].nSubClocks; j++) {
        assertStreamPrint(threadData, data->simulationInfo->baseClocks[i].subClocks[j].factor.den == 1, "Factor of sub-clock of event-clock is not an integer, this is not allowed.");
      }
    }
  }

  for(i=0; i<data->modelData->nBaseClocks; i++)
  {
    baseClock = &data->simulationInfo->baseClocks[i];

    data->callback->function_updateSynchronous(data, threadData, i);
    if (!baseClock->isEventClock) {
      // Add base-clock activation time to data->simulationInfo->intvlTimers
      SYNC_TIMER timer = (SYNC_TIMER){
        .base_idx = i,
        .sub_idx = -1,
        .type = SYNC_BASE_CLOCK,
        .activationTime = startTime
      };
      listPushFront(data->simulationInfo->intvlTimers, &timer);
    }
  }

  /* Debug print */
  printClocks(data->simulationInfo->baseClocks, data->modelData->nBaseClocks);

  TRACE_POP
}

/**
 * @brief Insert given timer into ordered list of timers.
 *
 * Timer with lowest activation time is at the start of the list, last at the end.
 *
 * @param list    List with timers
 * @param timer   Timer to insert into list.
 */
static void insertTimer(LIST* list, SYNC_TIMER* timer)
{
  TRACE_PUSH

  LIST_NODE *it, *prevNode = NULL;
  for(it = listFirstNode(list); it; it = listNextNode(it))
  {
    SYNC_TIMER *tmpTimer = listNodeData(it);
    if(tmpTimer->activationTime > timer->activationTime)
      break;
    prevNode = it;
  }
  if (prevNode) listInsert(list, prevNode, timer);
  else listPushFront(list, timer);

  TRACE_POP
}


/**
 * @brief Check when next clock needs to fire.
 *
 * If next activation time is smaller then time on next step reduce step size
 * to hit activation time of clock exactly.
 *
 * @param data            Pointer to data.
 * @param solverInfo      Solver info, containing next activation time of clocks.
 */
void checkForSynchronous(DATA *data, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  if (data->simulationInfo->intvlTimers != NULL && listLen(data->simulationInfo->intvlTimers) > 0)
  {
    SYNC_TIMER* nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    double nextTimeStep = solverInfo->currentTime + solverInfo->currentStepSize;

    if ((nextTimer->activationTime <= nextTimeStep + SYNC_EPS) && (nextTimer->activationTime >= solverInfo->currentTime))
    {
      solverInfo->currentStepSize = nextTimer->activationTime - solverInfo->currentTime;
    }
  }
  TRACE_POP
}


/**
 * @brief Update base clock and get activation times for all sub-clocks.
 *
 * @param data            Pointer to data.
 * @param threadData      Pointer to thread data.
 * @param idx             Index of timer to handle.
 * @param curTime         Current activation time.
 */
modelica_boolean handleBaseClock(DATA* data, threadData_t *threadData, long idx, double curTime)
{
  TRACE_PUSH
  modelica_boolean frstSubClockIsBaseClock = 0 /* false */;

  /* Special case for event-clocks activated at initialization */
  if (data->simulationInfo->initial) {
    SYNC_TIMER nextTimer = (SYNC_TIMER){
      .base_idx =  idx,
      .sub_idx = -1,
      .type = SYNC_BASE_CLOCK,
      .activationTime = data->simulationInfo->startTime};
    insertTimer(data->simulationInfo->intvlTimers, &nextTimer);
    return frstSubClockIsBaseClock;
  }

  BASECLOCK_DATA* baseClock = &(data->simulationInfo->baseClocks[idx]);
  SUBCLOCK_DATA* subClock;
  SYNC_TIMER nextTimer, firstSubTimer;
  SYNC_TIMER* nextSubTimer;
  double nextBaseTime, nextSubTime, absoluteSubTime, activationTime;
  RATIONAL subTimer;
  int i;

  /* Update base clock */
  baseClock->stats.count++;
  // Event clocks can't use baseClock->interval
  if (baseClock->isEventClock) {
    if (baseClock->stats.count > 1) {
      baseClock->stats.previousInterval = curTime - baseClock->stats.lastActivationTime;
    }
  } else {
    baseClock->stats.previousInterval = baseClock->interval;
  }
  baseClock->stats.lastActivationTime = curTime;

  subClock = &baseClock->subClocks[0];
  if (subClock->shift.num == 0 && subClock->factor.num == 1 && subClock->factor.den == 1) {
    frstSubClockIsBaseClock = 1 /* true */;
#if !defined(OMC_MINIMAL_RUNTIME)
    // Save result before clock tick, then evaluate equations
    sim_result.emit(&sim_result, data, threadData);
#endif /* #if !defined(OMC_MINIMAL_RUNTIME) */
    subClock->stats.count++;
    subClock->stats.previousInterval = baseClock->stats.previousInterval;
    subClock->stats.lastActivationTime = baseClock->stats.lastActivationTime;
    data->callback->function_equationsSynchronous(data, threadData, idx, 0);
  }
  if (!baseClock->isEventClock) {
    data->callback->function_updateSynchronous(data, threadData, idx);  /* Update interval */
    nextBaseTime = curTime + baseClock->interval;

    // Next base clock activation
    nextTimer = (SYNC_TIMER){
      .base_idx = idx,
      .sub_idx = -1,
      .type = SYNC_BASE_CLOCK,
      .activationTime = nextBaseTime};
    insertTimer(data->simulationInfo->intvlTimers, &nextTimer);
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated base-clock %li at time %f", idx, curTime);
  } else {
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated event-clock %li at time %f", idx, curTime);
  }

  // Add sub-clocks to timer that will fire during this base-clock interval.
  // s = subClock->shift + subClock->stats.count * subClock->factor - (baseClock->stats.count-1);
  // timer = base.prevTick + s * baseClock->interval

  // Skip first subClock if is equivalent to the baseClock
  i = frstSubClockIsBaseClock ? 1 : 0;
  for (/* init above */; i < baseClock->nSubClocks; ++i) {
    subClock = &baseClock->subClocks[i];
    subTimer = addRat(subRat(subClock->shift, int2Rat(baseClock->stats.count-1)), mulRat(int2Rat(subClock->stats.count), subClock->factor));
    while (floorRat(subTimer) == 0) {
      activationTime = curTime + rat2Real(subTimer)*baseClock->interval;
      nextTimer = (SYNC_TIMER){
        .base_idx = idx,
        .sub_idx = i,
        .type = SYNC_SUB_CLOCK,
        .activationTime = activationTime};
      insertTimer(data->simulationInfo->intvlTimers, &nextTimer);
      subTimer = addRat(subTimer, subClock->factor);
    }
  }

  TRACE_POP
  return frstSubClockIsBaseClock;
}

#if !defined(OMC_MINIMAL_RUNTIME)
/**
 * @brief Handle timer clocks.
 *
 * Loop over all timers and check if a timer fired.
 * If there are no timers return NO_TIMER_FIRED.
 *
 * @param data            Pointer to data.
 * @param threadData      Pointer to thread data.
 * @param solverInfo      Pointer to solver info.
 * @return fire_timer_t   Return NO_TIMER_FIRED, if there are no fired timers;
 *                               TIMER_FIRED, if there is a fired timer;
 *                               TIMER_FIRED_EVENT, if there is a fired timer which triggers an event.
 */
fire_timer_t handleTimers(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  int base_idx, sub_idx;
  double activationTime;
  modelica_boolean frstSubClockIsBaseClock = 0 /* false */;
  SYNC_TIMER_TYPE type;
  SYNC_TIMER* nextTimer;
  fire_timer_t ret = NO_TIMER_FIRED;
  SUBCLOCK_DATA* subClock;

  if (data->simulationInfo->intvlTimers == NULL || listLen(data->simulationInfo->intvlTimers) <= 0) {
    TRACE_POP
    return ret;
  }

  /* Fire all timers at current time step */
  nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
  while(nextTimer->activationTime <= solverInfo->currentTime + SYNC_EPS)
  {
    base_idx = nextTimer->base_idx;
    sub_idx = nextTimer->sub_idx;
    type = nextTimer->type;
    activationTime = nextTimer->activationTime;
    listRemoveFront(data->simulationInfo->intvlTimers);
    switch(type)
    {
      case SYNC_BASE_CLOCK:
        frstSubClockIsBaseClock = handleBaseClock(data, threadData, base_idx, activationTime);
        if (frstSubClockIsBaseClock && data->simulationInfo->baseClocks[base_idx].subClocks[0].holdEvents) {
          ret = TIMER_FIRED_EVENT;
        } else {
          ret = TIMER_FIRED;
        }
        break;
      case SYNC_SUB_CLOCK:
        // Save result before clock tick, then evaluate equations
        sim_result.emit(&sim_result, data, threadData);
        subClock = &data->simulationInfo->baseClocks[base_idx].subClocks[sub_idx];
        subClock->stats.count++;
        subClock->stats.previousInterval = solverInfo->currentTime - subClock->stats.lastActivationTime;
        subClock->stats.lastActivationTime = solverInfo->currentTime;
        data->callback->function_equationsSynchronous(data, threadData, base_idx, sub_idx);  /* TODO: Fix indices. Now indices for base and sub-clocks */
        if (subClock->holdEvents) {
          ret = TIMER_FIRED_EVENT;
          infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated sub-clock (%i,%i) which triggered event at time %f",
                          base_idx, sub_idx, solverInfo->currentTime);
        } else {
          ret = TIMER_FIRED;
          infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated sub-clock (%i,%i) at time %f",
                          base_idx, sub_idx, solverInfo->currentTime);
        }
        break;
    }
    if (listLen(data->simulationInfo->intvlTimers) == 0){
      break;
    }
    nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
  }

  TRACE_POP
  return ret;
}
#endif /* #if !defined(OMC_MINIMAL_RUNTIME) */


/**
 * @brief Handle timer clocks and return next time a timer will fire
 *
 * Update timers and output when the next timer will fire.
 * Used for Synchronous features in FMUs.
 *
 * @param data                            data
 * @param threadData                      thread data, for errro handling
 * @param currentTime                     Current solver timer.
 * @param nextTimerDefined                0 (false) if no next timer is defined.
 *                                        1 (true) if a next timer is defined. Then the time is outputted in nextTimerActivationTime.
 * @param nextTimerActivationTime         If nextTimerDefined is true it will contain the next time a timer will fire.
 * @return int                            Return 0, if there is no fired timers;
 *                                               1, if there is a fired timer;
 *                                               2, if there is a fired timer which trigger event;
 */
int handleTimersFMI(DATA* data, threadData_t *threadData, double currentTime, int *nextTimerDefined, double *nextTimerActivationTime)
{
  int base_idx, sub_idx;
  double activationTime;
  modelica_boolean frstSubClockIsBaseClock = 0 /* false */;
  SYNC_TIMER_TYPE type;
  SYNC_TIMER* nextTimer;
  fire_timer_t ret = NO_TIMER_FIRED;
  SUBCLOCK_DATA* subClock;

  *nextTimerDefined = 0;

  if (data->simulationInfo->intvlTimers == NULL || listLen(data->simulationInfo->intvlTimers) <= 0) {
    TRACE_POP
    return (int) ret;
  }

  /* Fire all timers at current time step */
  nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
  while(nextTimer->activationTime <= currentTime + SYNC_EPS)
  {
    base_idx = nextTimer->base_idx;
    sub_idx = nextTimer->sub_idx;
    type = nextTimer->type;
    activationTime = nextTimer->activationTime;
    listRemoveFront(data->simulationInfo->intvlTimers);
    switch(type)
    {
      case SYNC_BASE_CLOCK:
        frstSubClockIsBaseClock = handleBaseClock(data, threadData, base_idx, activationTime);
        if (frstSubClockIsBaseClock && data->simulationInfo->baseClocks[base_idx].subClocks[0].holdEvents) {
          ret = TIMER_FIRED_EVENT;
        } else {
          ret = TIMER_FIRED;
        }
        break;
      case SYNC_SUB_CLOCK:
        subClock = &data->simulationInfo->baseClocks[base_idx].subClocks[sub_idx];
        subClock->stats.count++;
        subClock->stats.previousInterval = currentTime - subClock->stats.lastActivationTime;
        subClock->stats.lastActivationTime = currentTime;
        data->callback->function_equationsSynchronous(data, threadData, base_idx, sub_idx);  /* TODO: Fix indices. Now indices for base and sub-clocks */
        if (subClock->holdEvents) {
          ret = TIMER_FIRED_EVENT;
          infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated sub-clock (%i,%i) which triggered event at time %f",
                          base_idx, sub_idx, currentTime);
        } else {
          ret = TIMER_FIRED;
          infoStreamPrint(LOG_SYNCHRONOUS, 0, "Activated sub-clock (%i,%i) at time %f",
                          base_idx, sub_idx, currentTime);
        }
        break;
    }
    if (listLen(data->simulationInfo->intvlTimers) == 0){
      break;
    }
    nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    /* Next time a timer will activate: */
    *nextTimerActivationTime = nextTimer->activationTime;
    *nextTimerDefined = 1;
  }

  TRACE_POP
  return (int) ret;
}

/**
 * @brief Print all base-clocks and sub-clocks.
 *
 * @param baseClocks   Pointer to array of size nClocks with base clock data.
 * @param nBaseClocks  Number of base clocks.
 */
void printClocks(BASECLOCK_DATA* baseClocks, int nBaseClocks)
{
  int i,j;
  BASECLOCK_DATA* baseClock;
  SUBCLOCK_DATA* subClock;

  if(useStream[LOG_SYNCHRONOUS]) {
    infoStreamPrint(LOG_SYNCHRONOUS, 1, "Initialized synchronous timers.");
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Number of base clocks: %i", nBaseClocks);
    for(i=0; i<nBaseClocks; i++) {
      baseClock = &baseClocks[i];
      infoStreamPrint(LOG_SYNCHRONOUS, 1, "Base clock %i", i+1);
      if (baseClock->isEventClock) {
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "is event clock");
      } else if (baseClock->intervalCounter==-1) {
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "interval: %e", baseClock->interval);
      } else {
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "intervalCounter/resolution = : %i/%i", baseClock->intervalCounter, baseClock->resolution);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "interval: %e", baseClock->interval);
      }
      infoStreamPrint(LOG_SYNCHRONOUS, 0, "Number of sub-clocks: %i", baseClock->nSubClocks);
      for(j=0; j<baseClock->nSubClocks; j++) {
        subClock = &baseClock->subClocks[j];
        infoStreamPrint(LOG_SYNCHRONOUS, 1, "Sub-clock %i of base clock %i", j+1, i+1);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "shift: "RAT_FMT"/"RAT_FMT, subClock->shift.num, subClock->shift.den);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "factor: "RAT_FMT"/"RAT_FMT, subClock->factor.num, subClock->factor.den);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "solverMethod: %s", strlen(subClock->solverMethod)>0?subClock->solverMethod:"none");
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "holdEvents: %s", subClock->holdEvents?"true":"false");
        messageClose(LOG_SYNCHRONOUS);
      }
      messageClose(LOG_SYNCHRONOUS);
    }
    messageClose(LOG_SYNCHRONOUS);
  }
}

/**
 * @brief Print synchronous timer.
 *
 * Prints tuple (base_idx, sub_idx, type, activationTime).
 *
 * @param data          Void pointer to sync timer element.
 *                      Will be casted to SYNC_TIMER*.
 * @param stream        Stream of LOG_STREAM type.
 * @param elemPointer   Address of element storing this data.
 */
void printSyncTimer(void* data, int stream, void* elemPointer)
{
  SYNC_TIMER* syncTimerElem = (SYNC_TIMER*) data;
  switch (syncTimerElem->type)
  {
  case SYNC_BASE_CLOCK:
    infoStreamPrint(stream, 0, "%p: (base_idx :%i, type: %s, activationTime: %e)", elemPointer, syncTimerElem->base_idx, "base-clock", syncTimerElem->activationTime);
    break;
  case SYNC_SUB_CLOCK:
    infoStreamPrint(stream, 0, "%p: (base_idx: %i, sub_idx: %i, type: %s, activationTime: %e)", elemPointer, syncTimerElem->base_idx, syncTimerElem->sub_idx, "sub-clock", syncTimerElem->activationTime);
    break;

  default:
    infoStreamPrint(stream, 0, "%p: ERROR: Unknown type", elemPointer);
    break;
  }
}

#ifdef __cplusplus
}
#endif
