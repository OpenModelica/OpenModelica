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
#include "openmodelica.h"    /* for modelica types */
#include "openmodelica_func.h"   /* for modelica fucntion */
#include "simulation_runtime.h"
#include "solver_main.h"

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>


double biSection(DATA* data, double*, double*, double*, double*, LIST*, LIST*);
modelica_boolean checkZeroCrossings(DATA *data, LIST *list, LIST*);

void saveZeroCrossingsAfterEvent(DATA *data);
void initializeZeroCrossings(DATA *data);
void correctDirectionZeroCrossings(DATA *data);

/*/*! \fn sample
 *
 *  \param [ref]   [data]
 *  \param [in]    [start]
 *  \param [in]    [interval]
 *  \param [in]    [hindex]
 *  \return boolean value that indicates if sample is activated or not.
 *
 *  Function returns true and triggers smaple events at time instants
 *  start + i*interval (i=0, 1, ...).
 *  During continuous integration the operator returns always false.
 *  The starting time start and the sample interval interval need to
 *  be parameter expressions and need to be a subtype of Real or Integer.
 */
modelica_boolean sample(DATA *data, double start, double interval, int hindex)
{
  static const double eps = 0.0001;
  modelica_boolean retVal;
  double tmp = 1;
  int tmpindex = data->simulationInfo.curSampleTimeIx;

  if(tmpindex < data->simulationInfo.nSampleTimes){
    while((data->simulationInfo.sampleTimes[tmpindex]).activated == 1){
      if((data->simulationInfo.sampleTimes[tmpindex]).zc_index == hindex)
        tmp = 0;

      tmpindex++;

      if(tmpindex == data->simulationInfo.nSampleTimes)
        break;
    }
  }

  /*
   * sjoelund - do not sample before the start value !
   */
  if(data->localData[0]->timeValue >= start - eps && tmp >= -eps && tmp < eps){
    DEBUG_INFO2(LOG_EVENTS,"Calling sample(%f, %f)", start, interval);
    DEBUG_INFO2(LOG_EVENTS,"+generating an event at time: %f \t tmp: %f", data->localData[0]->timeValue, tmp);
    retVal = 1;
  } else {
    DEBUG_INFO2(LOG_EVENTS,"Calling sample(%f, %f)", start, interval);
    DEBUG_INFO2(LOG_EVENTS,"-NO event at time: %f \t tmp: %f", data->localData[0]->timeValue, tmp);
    retVal = 0;
  }
  return retVal;
}

/*! \fn unique
 *
 *  \param [in]   [a]
 *  \param [in]   [b]
 *
 *  Function compares two doubles
 *
 */
static int compdbl(const void* a, const void* b)
{
  const double *v1 = (const double *) a;
  const double *v2 = (const double *) b;
  const double diff = *v1 - *v2;
  const double epsilon = 0.00000000000001;

  if(diff < epsilon && diff > -epsilon)
    return 0;
  return (*v1 > *v2) ? 1 : -1;
}

/*! \fn unique
 *
 *  \param [in]   [a]
 *  \param [in]   [b]
 *
 *  Function compares two SAPLE_TIMES
 *
 */
static int compSample(const void* a, const void* b)
{
  const SAMPLE_TIME *v1 = (const SAMPLE_TIME *) a;
  const SAMPLE_TIME *v2 = (const SAMPLE_TIME *) b;
  const double diff = v1->events - v2->events;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

/*! \fn unique
 *
 *  \param [in]   [a]
 *  \param [in]   [b]
 *
 *  Function compares two SAPLE_TIMES with index
 *
 */
static int compSampleZC(const void* a, const void* b)
{
  const SAMPLE_TIME *v1 = (const SAMPLE_TIME *) a;
  const SAMPLE_TIME *v2 = (const SAMPLE_TIME *) b;
  const double diff = v1->events - v2->events;
  const int diff2 = v1->zc_index - v2->zc_index;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon && diff2 == 0)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

/*! \fn unique
 *
 *  \param [ref]  [base]
 *  \param [in]   [nmemb]
 *  \param [in]   [size]
 *  \param [in]   [compar]
 *
 *  Function return for an sorted array just unique elements
 *
 */
static int unique(void *base, size_t nmemb, size_t size,
                  int (*compar)(const void *, const void *))
{
  size_t nuniq = 0;
  size_t i;
  void *a, *b, *c;
  a = base;
  for(i = 1; i < nmemb; i++){
    b = ((char*) base) + i * size;
    if(0 == compar(a, b))
      nuniq++;
    else{
      a = b;
      c = ((char*) base) + (i - nuniq) * size;
      if(b != c)
        memcpy(c, b, size); /* happens when nuniq==0*/
    }
  }
  return nmemb - nuniq;
}

/*! \fn initSample
 *
 *  \param [ref]  [data]
 *  \param [in]   [start]
 *  \param [in]   [stop]
 *  \return indicates if a sample event is occuered or not.
 *
 *  Function initialize data->simulationInfo.sampleTime
 *                      data->simulationInfo.curSampleTimeIx
 *                      data->simulationInfo.nSampleTimes
 *
 */
void initSample(DATA* data, double start, double stop)
{
  /* not used yet
   * long measure_start_time = clock();
   */

  /* This code will generate an array of time values when sample generates events.
   * The only problem is our backend does not generate this array.
   * Sample() and sample() also need to be changed, but this should be easy to fix.
   */

  int i;
  /* double stop = 1.0; */
  double d;
  SAMPLE_TIME* Samples = NULL;
  int num_samples = 0;
  int max_events = 0;
  int ix = 0;
  int nuniq;

  function_sampleInit(data);

  num_samples = data->modelData.nSamples;

  for(i = 0; i < num_samples; i++){
    if(stop >= data->simulationInfo.rawSampleExps[i].start)
    max_events += (int)(((stop - data->simulationInfo.rawSampleExps[i].start) / data->simulationInfo.rawSampleExps[i].interval) + 1);
  }

  Samples = (SAMPLE_TIME*)calloc(max_events+1, sizeof(SAMPLE_TIME));
  if(Samples == NULL){
    DEBUG_INFO(LOG_EVENTS, "Could not allocate Memory for initSample!");
    THROW("Could not allocate Memory for initSample!");
  }

  for(i = 0; i < num_samples; i++){
    DEBUG_INFO2(LOG_EVENTS, "Generate times for sample(%f, %f)", data->simulationInfo.rawSampleExps[i].start, data->simulationInfo.rawSampleExps[i].interval);

    for(d = data->simulationInfo.rawSampleExps[i].start; ix < max_events && d <= stop; d += data->simulationInfo.rawSampleExps[i].interval){
      (Samples[ix]).events = d;
      (Samples[ix++]).zc_index = (data->simulationInfo.rawSampleExps[i]).zc_index;

      DEBUG_INFO3(LOG_EVENTS, "Generate sample(%f, %f, %d)", d, data->simulationInfo.rawSampleExps[i].interval, (data->simulationInfo.rawSampleExps[i]).zc_index);
    }
  }

  /* Sort, filter out unique values */
  qsort(Samples, max_events, sizeof(SAMPLE_TIME), compSample);
  nuniq = unique(Samples, max_events, sizeof(SAMPLE_TIME), compSampleZC);

  DEBUG_INFO1(LOG_INIT, "Number of sorted, unique sample events: %d", nuniq);
  for(i = 0; i < nuniq; i++)
    DEBUG_INFO_AL3(LOG_INIT, "%f\t HelpVar[%d]=activated(%d)", (Samples[i]).events, (Samples[i]).zc_index,(Samples[i]).activated);

  data->simulationInfo.sampleTimes = Samples;
  data->simulationInfo.curSampleTimeIx = 0;
  data->simulationInfo.nSampleTimes = nuniq;
}


/*! \fn checkForSampleEvent
 *
 *  \param [ref]  [data]
 *  \param [ref]  [solverInfo]
 *  \return indicates if a sample event is occuered or not.
 *
 *  Function check if a sample expression should be activated
 *  before next step and sets then the next step size to the
 *  sample event.
 *
 */
modelica_boolean checkForSampleEvent(DATA *data, SOLVER_INFO* solverInfo) {

  modelica_boolean retVal = 0;
  double a = solverInfo->currentTime + solverInfo->currentStepSize;
  int b = 0;
  int tmpindex = 0;

  DEBUG_INFO1(LOG_EVENTS, "Check for Sample Events. Current Index: %li",
      data->simulationInfo.curSampleTimeIx);

  DEBUG_INFO1(LOG_EVENTS, "*** Next step : %f", a);
  DEBUG_INFO1(LOG_EVENTS, "*** Next sample Time : %f",
      ((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).events));

  tmpindex = data->simulationInfo.curSampleTimeIx;
  b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
  if (b >= 0) {
    DEBUG_INFO(LOG_EVENTS, "** Sample Event **");

    if (!(b == 0)) {
      if ((data->simulationInfo.sampleTimes[tmpindex]).events - solverInfo->currentTime >= 0) {
        solverInfo->currentStepSize = (data->simulationInfo.sampleTimes[tmpindex]).events - solverInfo->currentTime;
      } else {
        solverInfo->currentStepSize = 0;
      }
      DEBUG_INFO1(LOG_EVENTS, "** Change Stepsize : %f", solverInfo->currentStepSize);
    }
    retVal = 1;
  }
  return retVal;
}

/*! \fn activateSampleEvents
 *
 *  \param [ref]  [data]
 *  \return indicates if a sample event need to be activated before next output time
 *
 * ! Function activated sample expression
 *
 */
modelica_boolean activateSampleEvents(DATA *data) {
  modelica_boolean retVal = 0;

  if (data->simulationInfo.curSampleTimeIx < data->simulationInfo.nSampleTimes) {
    double a = data->localData[0]->timeValue;
    int b = 0;
    long int tmpindex = data->simulationInfo.curSampleTimeIx;
    DEBUG_INFO(LOG_EVENTS, "Activate Sample Events.");
    DEBUG_INFO1(LOG_EVENTS, "Current Index: %li",
        data->simulationInfo.curSampleTimeIx);

    b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
    while (b >= 0) {
      retVal = 1;
      (data->simulationInfo.sampleTimes[tmpindex]).activated = 1;
      DEBUG_INFO1(LOG_EVENTS, "Activate Sample Events index: %li", tmpindex);
      tmpindex++;
      if (tmpindex >= data->simulationInfo.nSampleTimes)
        break;
      b = compdbl(&a, &((data->simulationInfo.sampleTimes[tmpindex]).events));
    }
  }

  return retVal;
}

/*! \fn activateSampleEvents
 *
 *  \param [ref]  [data]
 *
 * ! Function deactivate, before activated sample expression
 *
 */
void deactivateSampleEvents(DATA *data)
{
  int tmpindex = data->simulationInfo.curSampleTimeIx;

  while ((data->simulationInfo.sampleTimes[tmpindex]).activated == 1)
    {
      (data->simulationInfo.sampleTimes[tmpindex++]).activated = 0;
    }
}

/*! \fn deactivateSampleEventsandEquations
 *
 *  \param [ref]  [data]
 *
 *  Function deactivate, before activated sample expression in equations
 *
 */
void deactivateSampleEventsandEquations(DATA *data)
{
  while ((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).activated == 1)
    {
      DEBUG_INFO1(LOG_EVENTS, "Deactivate Sample Events index: %li", data->simulationInfo.curSampleTimeIx);

      (data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).activated = 0;
      data->simulationInfo.helpVars[((data->simulationInfo.sampleTimes[data->simulationInfo.curSampleTimeIx]).zc_index)]
                           = 0;
      data->simulationInfo.curSampleTimeIx++;
    }
  function_updateSample(data);
}


/* !\fn  checkForNewEvent
 *
 *  \param [ref]  [data]
 *  \param [ref]  [eventList]
 *
 *  This function checks for Events in Interval=[oldTime, timeValue]
 *  If a ZeroCrossing Function cause a sign change, root finding
 *  process will start
 *
 */
modelica_boolean checkForNewEvent(DATA* data, LIST *eventList)
{
  long i = 0;
  modelica_boolean retVal = 0;

  initializeZeroCrossings(data);

  for (i = 0; i < data->modelData.nZeroCrossings; i++){
      DEBUG_INFO4(LOG_ZEROCROSSINGS, "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %d",
                  i, data->simulationInfo.zeroCrossingsPre[i], data->simulationInfo.zeroCrossings[i], data->simulationInfo.zeroCrossingEnabled[i]);

      if (data->simulationInfo.zeroCrossingsPre[i] == 0)
        {
          if (data->simulationInfo.zeroCrossings[i] > 0 && data->simulationInfo.zeroCrossingEnabled[i] <= -1)
            {
              DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, data->localData[0]->timeValue);

              listPushFront(eventList, &(data->simulationInfo.zeroCrossingIndex[i]));
            }
          else if (data->simulationInfo.zeroCrossings[i] < 0 && data->simulationInfo.zeroCrossingEnabled[i] >= 1)
            {
              DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, data->localData[0]->timeValue);

              listPushFront(eventList, &(data->simulationInfo.zeroCrossingIndex[i]));
            }
        }
      if ((data->simulationInfo.zeroCrossings[i] <= 0 && data->simulationInfo.zeroCrossingsPre[i] > 0) ||
          (data->simulationInfo.zeroCrossings[i] >= 0 && data->simulationInfo.zeroCrossingsPre[i] < 0))
        {
          DEBUG_INFO2(LOG_EVENTS, "adding event %ld at time: %f", i, data->localData[0]->timeValue);

          listPushFront(eventList, &(data->simulationInfo.zeroCrossingIndex[i]));
        }
  }

  if (listLen(eventList) > 0){
    /* if an event is pushed to the list sample needs to be activated next time */
    if (data->simulationInfo.sampleActivated == 1){
      data->simulationInfo.sampleActivated = 0;
      deactivateSampleEvents(data);
    }
    retVal = 1;
  }
  return retVal;
}

/* !\fn handleStateEvent
 *
 *  \param [ref]  [data]
 *  \param [ref]  [eventList]
 *  \param [in]   [eventTime]
 *
 *  This handles all zero crossing events from event list at event time
 */
int handleStateEvent(DATA* data, LIST* eventLst, double *eventTime){

  long event_id = 0;
  LIST_NODE* it;

  DEBUG_INFO1(LOG_EVENTS, "Event Handling : %f!", *eventTime);

  data->localData[0]->timeValue = *eventTime;

  DEBUG_INFO_NEL(LOG_EVENTS, "Handle Event caused by ZeroCrossings: ");
  for (it = listFirstNode(eventLst); it; it = listNextNode(it)) {
    event_id = *((long*) listNodeData(it));
    DEBUG_INFO_NELA1(LOG_EVENTS, "%ld", event_id);
    if (listLen(eventLst) > 0) {
      DEBUG_INFO_NELA(LOG_EVENTS, ", ");
    }

    /* switch the direction of ZeroCrossing */
    if (data->simulationInfo.zeroCrossingEnabled[event_id] == -1) {
      data->simulationInfo.zeroCrossingEnabled[event_id] = 1;
    } else if (data->simulationInfo.zeroCrossingEnabled[event_id] == 1) {
      data->simulationInfo.zeroCrossingEnabled[event_id] = -1;
    }
  }
  listClear(eventLst);
  DEBUG_INFO_NELA(LOG_EVENTS, "\n");

  /* update the whole system */
  updateDiscreteSystem(data);

  saveZeroCrossingsAfterEvent(data);
  correctDirectionZeroCrossings(data);

  return 0;
}

/*
 * !\fn handleStateEvent
 *
 * \param [ref]  [data]
 *
 * This function handle sample events
 */
int handleSampleEvent(DATA* data) {

  DEBUG_INFO1(LOG_EVENTS, "Event Handling for Sample : %f!",
      data->localData[0]->timeValue);
  sim_result_emit(data);
  /*evaluate and emit results before sample events are activated */
  /* update the whole system */
  updateDiscreteSystem(data);

  storePreValues(data);
  sim_result_emit(data);

  /*Activate sample and evaluate again */
  activateSampleEvents(data);

  /* update the whole system */
  updateDiscreteSystem(data);

  deactivateSampleEventsandEquations(data);
  DEBUG_INFO1(LOG_EVENTS, "Event Handling for Sample : %f done!",
      data->localData[0]->timeValue);

  saveZeroCrossingsAfterEvent(data);
  correctDirectionZeroCrossings(data);

  return 0;
}

/*
 * !\fn findRoot
 *
 * \param [ref] [data]
 *        [ref] [eventLst]
 *        [in] [eventTime]
 *
 * This function perform a root finding for
 * Intervall = [oldTime, timeValue]
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

  for(it=listFirstNode(eventList); it; it=listNextNode(it)){
    DEBUG_INFO1(LOG_ZEROCROSSINGS, "Search for current event. Events in list: %ld", *((long*)listNodeData(it)));
  }

  /*write states to work arrays*/
  for (i = 0; i < data->modelData.nStates; i++){
    states_left[i] = data->simulationInfo.realVarsOld[i];
    states_right[i] = data->localData[0]->realVars[i];
  }

  /* Search for event time and event_id with Bisection method */
  *eventTime = biSection(data, &time_left, &time_right, states_left, states_right,
      tmpEventList, eventList);

  if (listLen(tmpEventList) == 0) {
    double value = fabs(data->simulationInfo.zeroCrossings[*((long*) listFirstData(eventList))]);
    for (it = listFirstNode(eventList); it; it = listNextNode(it)) {
      double fvalue = fabs(data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))]);
      if (value > fvalue) {
        value = fvalue;
      }
    }
    DEBUG_INFO1(LOG_ZEROCROSSINGS, "Minimum value: %e", value);
    for (it = listFirstNode(eventList); it; it = listNextNode(it)) {
      if (value == fabs(data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))])) {
        listPushBack(tmpEventList, listNodeData(it));
        DEBUG_INFO1(LOG_ZEROCROSSINGS, "added tmp event : %ld", *((long*) listNodeData(it)));
      }
    }
  }

  listClear(eventList);

  if (DEBUG_FLAG(LOG_EVENTS)){
    if (listLen(tmpEventList) > 0){
      DEBUG_INFO_NEL(LOG_EVENTS, "Found events: ");
    }else{
      DEBUG_INFO_NEL(LOG_EVENTS, "Found event: ");
    }
  }
  while (listLen(tmpEventList) > 0){
      event_id = *((long*)listFirstData(tmpEventList));
      listPopFront(tmpEventList);
      if (DEBUG_FLAG(LOG_EVENTS)){
        DEBUG_INFO_NELA1(LOG_EVENTS, "%ld ", event_id);
      }
      if (listLen(tmpEventList) > 0){
        DEBUG_INFO_NELA(LOG_EVENTS, ", ");
      }
      listPushFront(eventList, &event_id);
  }
  DEBUG_INFO_NELA(LOG_EVENTS, "\n");

 DEBUG_INFO1(LOG_EVENTS, "at time: %.10e", *eventTime);
 DEBUG_INFO1(LOG_EVENTS, "Time at Point left: %.10e", time_left);
 DEBUG_INFO1(LOG_EVENTS, "Time at Point right: %.10e", time_right);

  /*determined system at t_e - epsilon */
  data->localData[0]->timeValue = time_left;
  for (i = 0; i < data->modelData.nStates; i++){
    data->localData[0]->realVars[i] = states_left[i];
  }
  /*determined continuous system */
  updateContinuousSystem(data);
  sim_result_emit(data);

  /*determined system at t_e + epsilon */
  data->localData[0]->timeValue = time_right;
  for (i = 0; i < data->modelData.nStates; i++){
    data->localData[0]->realVars[i] = states_right[i];
  }
  *eventTime = time_right;
  free(states_left);
  free(states_right);
}

/*
 * !\fn biSection
 *
 * \param [ref] [data]
 * \param [ref] [a]
 * \param [ref] [b]
 * \param [ref] [states_a]
 * \param [ref] [states_b]
 * \param [list] [eventListTmp]
 * \param [list] [eventList]
 * \return Founded event time
 *
 * Method to find root in Intervall[oldTime, timeValue]
 */
double biSection(DATA* data, double* a, double* b, double* states_a,
    double* states_b, LIST *tmpEventList, LIST *eventList) {

  double TTOL = 1e-9;
  double c;
  int right = 0;
  long i = 0;

  double *backup_gout = (double*) malloc(
      data->modelData.nZeroCrossings * sizeof(double));
  assert(backup_gout);

  for (i = 0; i < data->modelData.nZeroCrossings; i++) {
    backup_gout[i] = data->simulationInfo.zeroCrossings[i];
  }

  DEBUG_INFO2(LOG_ZEROCROSSINGS, "Check interval [%e, %e]", *a, *b);
  DEBUG_INFO1(LOG_ZEROCROSSINGS, "TTOL is set to: %e", TTOL);

  while (fabs(*b - *a) > TTOL) {

    c = (*a + *b) / 2.0;
    data->localData[0]->timeValue = c;

    /*calculates states at time c */
    for (i = 0; i < data->modelData.nStates; i++) {
      data->localData[0]->realVars[i] = (states_a[i] + states_b[i]) / 2.0;
    }

    /*calculates Values dependents on new states*/
    functionODE(data);
    functionAlgebraics(data);

    function_ZeroCrossings(data, data->simulationInfo.zeroCrossings,
        &(data->localData[0]->timeValue));
    if (checkZeroCrossings(data, tmpEventList, eventList)) { /*If Zerocrossing in left Section */

      for (i = 0; i < data->modelData.nStates; i++) {
        states_b[i] = data->localData[0]->realVars[i];
      }
      *b = c;
      right = 0;

    } else { /*else Zerocrossing in right Section */

      for (i = 0; i < data->modelData.nStates; i++) {
        states_a[i] = data->localData[0]->realVars[i];
      }
      *a = c;
      right = 1;
    }
    if (right) {
      for (i = 0; i < data->modelData.nZeroCrossings; i++) {
        data->simulationInfo.zeroCrossingsPre[i] =
            data->simulationInfo.zeroCrossings[i];
        data->simulationInfo.zeroCrossings[i] = backup_gout[i];
      }
    } else {
      for (i = 0; i < data->modelData.nZeroCrossings; i++) {
        backup_gout[i] = data->simulationInfo.zeroCrossings[i];
      }
    }
  }
  free(backup_gout);
  c = (*a + *b) / 2.0;
  return c;
}

/*
 * !\fn checkZeroCrossings
 *
 * \param [ref] [data]
 * \param [list] [eventListTmp]
 * \param [list] [eventList]
 * \return boolean value
 *
 * Function checks for an eventlst on events
 */
modelica_boolean checkZeroCrossings(DATA *data, LIST *tmpEventList, LIST *eventList) {
  modelica_boolean retVal;
  LIST_NODE *it;

  listClear(tmpEventList);
  for (it = listFirstNode(eventList); it; it = listNextNode(it)) {
    DEBUG_INFO4(
        LOG_ZEROCROSSINGS,
        "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %d",
        *((long*) listNodeData(it)),
        data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))],
        data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))],
        data->simulationInfo.zeroCrossingEnabled[*((long*) listNodeData(it))]);

    /*Found event in left section*/
    if ((data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] <= 0
        && data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))] > 0)

        || (data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] >= 0
        && data->simulationInfo.zeroCrossingsPre[*((long*) listNodeData(it))] < 0)

        || (data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] > 0
        && data->simulationInfo.zeroCrossingEnabled[*((long*) listNodeData(it))] <= -1)

        || (data->simulationInfo.zeroCrossings[*((long*) listNodeData(it))] < 0
        && data->simulationInfo.zeroCrossingEnabled[*((long*) listNodeData(it))] >= 1))
    {
      listPushFront(tmpEventList, listNodeData(it));
    }
  }
  /*Found event in left section*/
  if (listLen(tmpEventList) > 0) {
    retVal = 1;
  }
  /* Else event in right section */
  else {
    retVal = 0;
  }
  return retVal;
}

/*
 * !\fn saveZeroCrossingsAfterEvent
 *
 * \param [ref] [data]
 *
 * Function save all zero-crossing values as pre(zero-crossing)
 */
void saveZeroCrossingsAfterEvent(DATA* data)
{
  long i = 0;

  DEBUG_INFO(LOG_ZEROCROSSINGS, "Save ZeroCrossings after an Event!");

  function_ZeroCrossings(data, data->simulationInfo.zeroCrossings, &(data->localData[0]->timeValue));
  for(i=0;i<data->modelData.nZeroCrossings;i++){
      data->simulationInfo.zeroCrossingsPre[i] = data->simulationInfo.zeroCrossings[i];
  }
}


/*
 * !\fn initializeZeroCrossings
 *
 * \param [ref] [data]
 *
 * TODO: Obsolete. Remove if zero-crossings are conditions and not anymore functions
 */
void initializeZeroCrossings(DATA* data) {
  long i = 0;
  for (i = 0; i < data->modelData.nZeroCrossings; i++) {
    if (data->simulationInfo.zeroCrossingEnabled[i] == 0) {
      if (data->simulationInfo.zeroCrossings[i] > 0)
        data->simulationInfo.zeroCrossingEnabled[i] = 1;
      else if (data->simulationInfo.zeroCrossings[i] < 0)
        data->simulationInfo.zeroCrossingEnabled[i] = -1;
      else
        data->simulationInfo.zeroCrossingEnabled[i] = 0;
    }
  }
}


/*
 * !\fn correctDirectionZeroCrossings
 *
 * \param [ref] [data]
 *
 * TODO: Obsolete. Remove if zero-crossings are conditions and not anymore functions
 */
void correctDirectionZeroCrossings(DATA* data) {
  long i = 0;
  for (i = 0; i < data->modelData.nZeroCrossings; i++) {
    if (data->simulationInfo.zeroCrossingEnabled[i] == -1
        && data->simulationInfo.zeroCrossings[i] > 0) {
      data->simulationInfo.zeroCrossingEnabled[i] = 1;
    } else if (data->simulationInfo.zeroCrossingEnabled[i] == 1
        && data->simulationInfo.zeroCrossings[i] < 0) {
      data->simulationInfo.zeroCrossingEnabled[i] = -1;
    }
  }
}

