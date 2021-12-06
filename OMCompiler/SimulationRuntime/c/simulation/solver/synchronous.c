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

/* Private type definitions */
/**
 * @brief Type of synchronous timer.
 */
typedef enum SYNC_TIMER_TYPE {
  SYNC_BASE_CLOCK,    /**< Base clock */
  SYNC_SUB_CLOCK      /**< Sub-clock */
} SYNC_TIMER_TYPE;

/**
 * @brief Data elements of list data->simulationInfo->intvlTimers.
 * Stores next activation time of synchronous clock idx.
 */
typedef struct SYNC_TIMER {
  int base_idx;               /**< Index of base clock */
  int sub_idx;                /**< Index of sub clock */
  SYNC_TIMER_TYPE type;       /**< Type of clock */
  double activationTime;      /**< Next activation time of clock */
} SYNC_TIMER;


/* Function prototypes */
void printClocks(BASECLOCK_DATA* baseClocks, int nBaseCllocks);


/**
 * @brief Initialize memory for synchronous fonctionnalities.
 *
 * Use freeSynchronous to free data again.
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

  /* Free in case initSynchronous is called multiple times */
  freeSynchronous(data);

  /* Initialize clocks */
  data->callback->function_initSynchronous(data, threadData);
  data->simulationInfo->intvlTimers = allocList(sizeof(SYNC_TIMER));  // TODO: Free me!

  /* Error check */
  for(i=0; i<data->modelData->nBaseClocks; i++) {
    for(j=0; j<data->simulationInfo->baseClocks[i].nSubClocks; j++)
    assertStreamPrint(threadData, data->simulationInfo->baseClocks[i].subClocks[j].solverMethod != NULL, "Continuous clocked systems aren't supported yet.");
    assertStreamPrint(threadData, rat2Real(data->simulationInfo->baseClocks[i].subClocks[j].shift) >= 0, "Shift of sub-clock is negative. Sub-clocks aren't allowed to fire before base-clock.");
  }

  for(i=0; i<data->modelData->nBaseClocks; i++)
  {
    baseClock = &data->simulationInfo->baseClocks[i];
    baseClock->fireList = allocList(sizeof(SYNC_TIMER));  // TODO: Free me!

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
 * @brief Frees memories allocated with initSynchronous.
 *
 * @param data            Pointer to data.
 */
void freeSynchronous(DATA* data)
{
  int i;
  BASECLOCK_DATA* baseClock;

  freeList(data->simulationInfo->intvlTimers);
  data->simulationInfo->intvlTimers = NULL;

  for(i=0; i<data->modelData->nBaseClocks; i++) {
    baseClock = &data->simulationInfo->baseClocks[i];
    freeList(baseClock->fireList);
    baseClock->fireList = NULL;
  }
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

  LIST_NODE* prevNode = NULL;
  if(listLen(list) > 0)
  {
    LIST_NODE* tmpNode = listFirstNode(list);
    SYNC_TIMER* tmpTimer = listNodeData(tmpNode);
    assertStreamPrint(NULL, 0 != tmpTimer, "invalid timerList node");

    while(tmpTimer->activationTime <= timer->activationTime)
    {
      prevNode = tmpNode;
      tmpNode = listNextNode(tmpNode);
      if(tmpNode)
      {
        tmpTimer = listNodeData(tmpNode);
        assertStreamPrint(NULL, 0 != tmpTimer, "invalid timerList node");
      }
      else break;
    }
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
  if (listLen(data->simulationInfo->intvlTimers) > 0)
  {
    SYNC_TIMER* nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    double nextTimeStep = solverInfo->currentTime + solverInfo->currentStepSize;

    // TODO: Check list of sub-clocks as well
    if ((nextTimer->activationTime <= nextTimeStep + SYNC_EPS) && (nextTimer->activationTime >= solverInfo->currentTime))
    {
      solverInfo->currentStepSize = nextTimer->activationTime - solverInfo->currentTime;
      infoStreamPrint( LOG_EVENTS_V, 0, "Adjust step-size to %.15g at time %.15g to get next timer at %.15g",
                       solverInfo->currentStepSize, solverInfo->currentTime, nextTimer->activationTime );
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
void fireBaseClock(DATA* data, threadData_t *threadData, long idx, double curTime)
{
  TRACE_PUSH
  BASECLOCK_DATA* baseClock = &(data->simulationInfo->baseClocks[idx]);
  SUBCLOCK_DATA* subClock;
  SYNC_TIMER nextTimer, firstSubTimer;
  SYNC_TIMER* nextSubTimer;
  double nextBaseTime, nextSubTime, absoluteSubTime;
  double subTimer, activationTime;
  int i, k;

  /* Update base clock */
  baseClock->stats.count++;
  baseClock->stats.previousInterval = baseClock->interval;
  //TODO: Update subClocks previousInterval
  data->callback->function_updateSynchronous(data, threadData, idx);  /* Update interval */
  nextBaseTime = curTime + baseClock->interval;

  // Next base clock activation
  nextTimer = (SYNC_TIMER){
    .base_idx = idx,
    .sub_idx = -1,
    .type = SYNC_BASE_CLOCK,
    .activationTime = nextBaseTime};
  insertTimer(data->simulationInfo->intvlTimers, &nextTimer);

  // Add sub-clocks to timer that will fire during this base-clock interval.
  // k = subClock->stats.count
  // s = subClock->shift + k*subClock->factor;
  // timer = base.prevTick + (s-baseClock->stats.count-1) * baserClock->interval
  for (i=0; i<baseClock->nSubClocks; i++) {
    subClock = &baseClock->subClocks[i];
    k = subClock->stats.count;
    subTimer = rat2Real(addRat2Rat(subClock->shift, multInt2Rat(k, subClock->factor)));
    while (subTimer < baseClock->stats.count) {
      activationTime = baseClock->previousBaseFireTime + (subTimer-baseClock->stats.count-1)*baseClock->interval;
      nextTimer = (SYNC_TIMER){
        .base_idx = idx,
        .sub_idx = i,
        .type = SYNC_SUB_CLOCK,
        .activationTime = activationTime};
      insertTimer(data->simulationInfo->intvlTimers, &nextTimer);
      k++;
      subTimer = rat2Real(addRat2Rat(subClock->shift, multInt2Rat(k, subClock->factor)));
    }
  }

  TRACE_POP
  return;
}

void fireSubClock(DATA* data, threadData_t *threadData, int base_idx, int sub_idx,  double curTime)
{
  TRACE_PUSH
  BASECLOCK_DATA* baseClock = &(data->simulationInfo->baseClocks[base_idx]);
  SUBCLOCK_DATA* subClock = &(baseClock->subClocks[sub_idx]);
  SYNC_TIMER nextTimer;
  double nextSubTime;

  /* Update base-clock fire list */
  subClock->stats.count++;

  TRACE_POP
  return;
}


/**
 * @brief Handle base clock timer.
 *
 * Fire clock and save next time this timer needs to fire.
 * The timer had to fire at activationTime which should be smaller or equal than the current time.
 *
 * @param data            Pointer to data.
 * @param threadData      Pointer to thread data.
 * @param idx             Index of timer to handle.
 * @param activationTime  Time timer had to fire.
 */
static void handleBaseClock(DATA* data, threadData_t *threadData, long idx, double activationTime)
{
  TRACE_PUSH
  /* Variables */
  BASECLOCK_DATA* baseClock = &(data->simulationInfo->baseClocks[idx]);
  SYNC_TIMER timer;

  baseClock->previousBaseFireTime = activationTime;
  /* Fire timer */
  fireClock(data, threadData, idx, activationTime);

  /* Save next activation time */
  timer.base_idx = idx;
  timer.type = SYNC_BASE_CLOCK;
  timer.activationTime = activationTime + baseClock->interval;
  insertTimer(data->simulationInfo->intvlTimers, &timer);

  TRACE_POP
  return;
}

#if !defined(OMC_MINIMAL_RUNTIME)
/**
 * @brief Handle timer clocks.
 *
 * Loop over all timers and check if a timer fired.
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
  SYNC_TIMER_TYPE type;
  fire_timer_t ret = NO_TIMER_FIRED;

  if (listLen(data->simulationInfo->intvlTimers) <= 0) {
    TRACE_POP
    return ret;
  }

  /* Fire all timers at current time step */
  SYNC_TIMER* nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
  while(nextTimer->activationTime <= solverInfo->currentTime + SYNC_EPS)
  {
    base_idx =  nextTimer->base_idx;
    sub_idx = nextTimer->sub_idx;
    type = nextTimer->type;
    activationTime = nextTimer->activationTime;
    listPopFront(data->simulationInfo->intvlTimers);
    switch(type)
    {
      case SYNC_BASE_CLOCK:
        handleBaseClock(data, threadData, base_idx, activationTime);
        break;
      case SYNC_SUB_CLOCK:
        sim_result.emit(&sim_result, data, threadData);
        data->callback->function_equationsSynchronous(data, threadData, base_idx);
        if (data->simulationInfo->baseClocks[base_idx].subClocks[sub_idx].holdEvents) {
          ret = TIMER_FIRED_EVENT;
        } else {
          ret = TIMER_FIRED;
        }
        break;
    }
    if (listLen(data->simulationInfo->intvlTimers) == 0) break;
    nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
  }

  /* Debug log */
  if (ret == TIMER_FIRED)
  {
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Fired timer at time %f", data->localData[0]->timeValue);
  }
  else if( ret == TIMER_FIRED_EVENT) {
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Fired timer which triggered event at time %f", data->localData[0]->timeValue);
  }

  TRACE_POP
  return ret;
}
#endif /* #if !defined(OMC_MINIMAL_RUNTIME) */


#if 0

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
int handleTimersFMI(DATA* data, threadData_t *threadData, double currentTime, int *nextTimerDefined ,double *nextTimerActivationTime)
{
  TRACE_PUSH
  int ret = 0;
  int i=0;

  *nextTimerDefined = 0;

  /* Loop over all timers that need to fire and evaluate synchronized equations */
  if (listLen(data->simulationInfo->intvlTimers) > 0)
  {
    SYNC_TIMER* nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    while(nextTimer->activationTime <= currentTime + SYNC_EPS)
    {
      long idx =  nextTimer->idx;
      double activationTime = nextTimer->activationTime;
      SYNC_TIMER_TYPE type = nextTimer->type;
      listPopFront(data->simulationInfo->intvlTimers);
      switch(type)
      {
        case SYNC_BASE_CLOCK:
          handleBaseClock(data, threadData, idx, activationTime);
          break;
        case SYNC_SUB_CLOCK:
          data->callback->function_equationsSynchronous(data, threadData, idx);
          if (data->modelData->subClocksInfo[idx].holdEvents)
            ret = 2;
          else
            ret = ret == 2 ? ret : 1;
          break;
      }
      if (listLen(data->simulationInfo->intvlTimers) == 0) break;
      nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    }

    /* Next time a timer will activate: */
    *nextTimerActivationTime = nextTimer->activationTime;
    *nextTimerDefined = 1;
  }

  TRACE_POP
  return ret;
}
#endif

/**
 * @brief
 *
 * @param baseClocks    Pointer to array of size nClocks with base clock data.
 * @param nBaseClocks  Number of base clocks.
 */
void printClocks(BASECLOCK_DATA* baseClocks, int nBaseClocks) {
  /* Variables */
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
      } else {
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "intervalCounter/resolution = : %i/%i", baseClock->intervalCounter, baseClock->resolution);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "interval: %e", baseClock->interval);
      }
      infoStreamPrint(LOG_SYNCHRONOUS, 0, "Number of sub-clocks: %i", baseClock->nSubClocks);
      for(j=0; j<baseClock->nSubClocks; j++) {
        subClock = &baseClock->subClocks[j];
        infoStreamPrint(LOG_SYNCHRONOUS, 1, "Sub-clock %i of base clock %i", j+1, i+1);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "shift: %li/%li", subClock->shift.m, subClock->shift.n);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "factor: %li/%li", subClock->factor.m, subClock->factor.n);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "solverMethod: %s", subClock->solverMethod);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "holdEvents: %s", subClock->holdEvents?"true":"false");
        messageClose(LOG_SYNCHRONOUS);
      }
      messageClose(LOG_SYNCHRONOUS);
    }
    messageClose(LOG_SYNCHRONOUS);
  }
}

#ifdef __cplusplus
}
#endif
