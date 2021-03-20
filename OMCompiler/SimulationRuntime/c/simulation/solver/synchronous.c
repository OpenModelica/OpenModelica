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
  long idx;                   /**< Index of clock */
  SYNC_TIMER_TYPE type;       /**< Type of clock */
  double activationTime;      /**< Next activation time of clock */
} SYNC_TIMER;


/* Function prototypes */
void printClocks(CLOCK_INFO* clocksInfo, CLOCK_DATA* clocksData, SUBCLOCK_INFO* subClocksInfo, int nClocks);


/**
 * @brief Initialize memory for synchronus functionalities.
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
  long i;

  /* Free in case initSynchronous is called multiple times */
  freeSynchronous(data);

  /* Initialize clocks */
  data->callback->function_initSynchronous(data, threadData);
  data->simulationInfo->intvlTimers = allocList(sizeof(SYNC_TIMER));

  /* Error check */
  for(i=0; i<data->modelData->nSubClocks; i++) {
    assertStreamPrint(threadData, NULL != data->modelData->subClocksInfo[i].solverMethod, "Continuous clocked systems aren't supported yet");
  }

  for(i=0; i<data->modelData->nClocks; i++)
  {
    data->callback->function_updateSynchronous(data, threadData, i);
    if (!data->modelData->clocksInfo[i].isBoolClock) {
      SYNC_TIMER timer;
      timer.idx = i;
      timer.type = SYNC_BASE_CLOCK;
      timer.activationTime = startTime;
      listPushFront(data->simulationInfo->intvlTimers, &timer);
    }
  }

  /* Debug print */
  printClocks(data->modelData->clocksInfo , data->simulationInfo->clocksData, data->modelData->subClocksInfo, data->modelData->nClocks);

  TRACE_POP
}


/**
 * @brief Frees memories allocated with initSynchronous.
 *
 * @param data            Pointer to data.
 */
void freeSynchronous(DATA* data)
{
  freeList(data->simulationInfo->intvlTimers);
  data->simulationInfo->intvlTimers = NULL;
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
void fireClock(DATA* data, threadData_t *threadData, long idx, double curTime)
{
  TRACE_PUSH
  CLOCK_INFO* clk = &(data->modelData->clocksInfo[idx]);
  CLOCK_DATA* clkData = &(data->simulationInfo->clocksData[idx]);
  SUBCLOCK_INFO* subClk;
  double nextBaseTime;
  long off;
  long i;

  /* Update base clock */
  data->callback->function_updateSynchronous(data, threadData, idx);
  nextBaseTime = curTime + clkData->interval;
  off = clk->subClocks - data->modelData->subClocksInfo;

  /* Add timers for all sub-clocks until next base clock fires */
  for(i=0; i<clk->nSubClocks; i++)
  {
    subClk = &(clk->subClocks[i]);
    long i0 = ceilRat(divRat2Rat(subInt2Rat(clkData->cnt, subClk->shift), subClk->factor));
    long i1 = floorRatStrict(divRat2Rat(subInt2Rat(clkData->cnt + 1, subClk->shift), subClk->factor));
    for (; i0<=i1; i0++)
    {
      // Skip negative i0, because those timePoints are shifted
      //if(i0 < 0) {
      //  continue;
      //}
      // TODO for AnHeuermann: This computes wrong times!
      double next_time = clkData->interval * (rat2Real(subClk->shift) + (i0 * rat2Real(subClk->factor)));
      if (next_time >= nextBaseTime)
      {
        next_time = nextBaseTime - SYNC_EPS;
      }
      else if (next_time < curTime)
      {
        next_time = curTime;
      }
      SYNC_TIMER nextTimer;
      nextTimer.idx = i + off;
      nextTimer.type = SYNC_SUB_CLOCK;
      nextTimer.activationTime = next_time;
      insertTimer(data->simulationInfo->intvlTimers, &nextTimer);
    }
  }
  TRACE_POP
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
  CLOCK_DATA* clkData = &(data->simulationInfo->clocksData[idx]);
  SYNC_TIMER timer;

  /* Fire timer */
  fireClock(data, threadData, idx, activationTime);

  /* Save next activation time */
  timer.idx = idx;
  timer.type = SYNC_BASE_CLOCK;
  timer.activationTime = activationTime + clkData->interval;
  insertTimer(data->simulationInfo->intvlTimers, &timer);

  clkData->timepoint = activationTime;
  clkData->cnt++;

  TRACE_POP
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
 * @return int            Return 0, if there are no fired timers;
 *                               1, if there is a fired timer;
 *                               2, if there is a fired timer which triggers an event.
 */
int handleTimers(DATA* data, threadData_t *threadData, SOLVER_INFO* solverInfo)
{
  TRACE_PUSH
  int ret = 0;

  if (listLen(data->simulationInfo->intvlTimers) > 0)
  {
    SYNC_TIMER* nextTimer = (SYNC_TIMER*)listNodeData(listFirstNode(data->simulationInfo->intvlTimers));
    while(nextTimer->activationTime <= solverInfo->currentTime + SYNC_EPS)
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
          sim_result.emit(&sim_result, data, threadData);
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
  }

  /* Debug log */
  if (ret == 1)
  {
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Fired timer at time %f", data->localData[0]->timeValue);
  }
  else if( ret == 2) {
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Fired timer which trigger event at time %f", data->localData[0]->timeValue);
  }

  TRACE_POP
  return ret;
}
#endif /* #if !defined(OMC_MINIMAL_RUNTIME) */


/**
 * @brief Handle timer clocks and return next time a timer will fire
 *
 * Update timers and output when the next timer will fire.
 * Used for Synchronus features in FMUs.
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


/**
 * @brief Print informations about all clocks and sub-clocks.
 *
 * @param clocksInfo        Pointer to array of size nClocks with base clock static information.
 * @param clocksData        Pointer to array of size nClocks with base clock data.
 * @param subClocksInfo     Pointer to array of all sub-clocks.
 * @param nClocks           Number of base clocks.
 */
void printClocks(CLOCK_INFO* clocksInfo, CLOCK_DATA* clocksData, SUBCLOCK_INFO* subClocksInfo, int nClocks) {
  /* Variables */
  int i,j;
  int subClockCounter = 0;

  if(useStream[LOG_SYNCHRONOUS]) {
    infoStreamPrint(LOG_SYNCHRONOUS, 1, "Initialized synchronous timers.");
    infoStreamPrint(LOG_SYNCHRONOUS, 0, "Number of base clocks: %i", nClocks);
    for(i=0; i<nClocks; i++) {
      infoStreamPrint(LOG_SYNCHRONOUS, 1, "Base clock %i", i+1);
      infoStreamPrint(LOG_SYNCHRONOUS, 0, "Interval: %e", clocksData[i].interval);
      infoStreamPrint(LOG_SYNCHRONOUS, 0, "Number of sub-clocks: %i", clocksInfo[i].nSubClocks);
      for(j=0; j<clocksInfo[i].nSubClocks; j++,subClockCounter++) {
        infoStreamPrint(LOG_SYNCHRONOUS, 1, "Sub-clock %i of base clock %i", j+1, i+1);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "shift: %i/%i", subClocksInfo[subClockCounter].shift.m, subClocksInfo[subClockCounter].shift.n);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "factor: %i/%i", subClocksInfo[subClockCounter].factor.m, subClocksInfo[subClockCounter].factor.n);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "solverMethod: %s", subClocksInfo[subClockCounter].solverMethod);
        infoStreamPrint(LOG_SYNCHRONOUS, 0, "holdEvents: %s", subClocksInfo[subClockCounter].holdEvents?"true":"false");
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
