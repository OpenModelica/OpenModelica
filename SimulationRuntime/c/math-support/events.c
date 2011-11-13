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
#include "error.h"
#include "openmodelica.h"		/* for modelica types */
#include "simulation_runtime.h"	/* for globalData */

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

LIST *eventList=NULL;

/* vectors with saved values used by pre(v) */
#define x_saved globalData->states_saved
#define xd_saved globalData->statesDerivatives_saved
#define y_saved globalData->algebraics_saved
#define int_saved globalData->intVariables.algebraics_saved
#define bool_saved globalData->boolVariables.algebraics_saved
#define str_saved globalData->stringVariables.algebraics_saved
#define h_saved globalData->helpVars_saved

double* gout = 0;
double* gout_old = 0;
modelica_boolean* backuprelations = 0;
long* zeroCrossingEnabled = 0;
long inUpdate = 0;
long inSample = 0;
int dideventstep = 0;

/* \brief allocate global data structures for event handling
 *
 * \return zero if successful.
 */
int initializeEventData()
{
  /* re-Initialization is important because the variables are global and used in every solving step */
  eventList = allocList(sizeof(long));
  globalData->helpVars_saved = 0;
  globalData->states_saved = 0;
  globalData->statesDerivatives_saved = 0;
  globalData->algebraics_saved = 0;
  globalData->intVariables.algebraics_saved = 0;
  globalData->boolVariables.algebraics_saved = 0;

  gout = 0;
  gout_old = 0;
  backuprelations = 0;
  zeroCrossingEnabled = 0;
  inUpdate = 0;
  inSample = 0;

  /* load default initial values */
  gout = (double*)calloc(globalData->nZeroCrossing, sizeof(double));
  gout_old = (double*)calloc(globalData->nZeroCrossing, sizeof(double));
  backuprelations = (modelica_boolean*)calloc(globalData->nZeroCrossing, sizeof(modelica_boolean*));
  globalData->helpVars_saved = (double*)calloc(globalData->nHelpVars, sizeof(double));
  globalData->states_saved = (double*)calloc(globalData->nStates, sizeof(double));
  globalData->statesDerivatives_saved = (double*)calloc(globalData->nStates, sizeof(double));
  globalData->algebraics_saved = (double*)calloc(globalData->nAlgebraic, sizeof(double));
  globalData->intVariables.algebraics_saved = (modelica_integer*)calloc(globalData->intVariables.nAlgebraic, sizeof(modelica_integer));
  globalData->boolVariables.algebraics_saved = (modelica_boolean*)calloc(globalData->boolVariables.nAlgebraic, sizeof(modelica_boolean));
  globalData->stringVariables.algebraics_saved = (const char**)calloc(globalData->stringVariables.nAlgebraic, sizeof(const char*));
  zeroCrossingEnabled = (long*)calloc(globalData->nZeroCrossing, sizeof(long));
  if(!globalData->algebraics_saved || !gout || !gout_old || !backuprelations
      || !globalData->helpVars_saved || !globalData->states_saved || !globalData->statesDerivatives_saved || !globalData->intVariables.algebraics_saved
      || !globalData->boolVariables.algebraics_saved || !globalData->stringVariables.algebraics_saved || !zeroCrossingEnabled)
  {
    WARNING("Could not allocate memory for global event data structures");
    return -1;
  }
  return 0;
}

/* \brief deallocate global data for event handling.
 *
 */
void deinitializeEventData()
{
  if(!globalData)
    return;

  free(globalData->helpVars_saved);
  free(globalData->states_saved);
  free(globalData->statesDerivatives_saved);
  free(globalData->algebraics_saved);
  free(globalData->intVariables.algebraics_saved);
  free(globalData->boolVariables.algebraics_saved);
  free(globalData->stringVariables.algebraics_saved);
  free(gout);
  free(gout_old);
  free(backuprelations);
  free(zeroCrossingEnabled);
  freeList(eventList);
}

/* relation functions used in zero crossing detection */
double Less(double a, double b)
{
  return a - b - DBL_EPSILON;
}

double LessEq(double a, double b)
{
  return a - b;
}

double Greater(double a, double b)
{
  return b - a + DBL_EPSILON;
}

double GreaterEq(double a, double b)
{
  return b - a;
}

double Sample(double t, double start, double interval)
{
  double pipi = atan(1.0) * 8.0;
  if(t < (start - interval * 0.25))
    return -1.0;
  return sin(pipi * (t - start) / interval);
}

/*
 * Returns true and triggers time events at time instants
 * start + i*interval (i=0, 1, ...).
 * During continuous integration the operator returns always false.
 * The starting time start and the sample interval interval need to
 * be parameter expressions and need to be a subtype of Real or Integer.
 */
double sample(double start, double interval, int hindex)
{
  /* adrpo - 2008-01-15
   * comparison was tmp >= 0 fails sometimes on x86 due to extended precision in registers
   * TODO - fix the simulation runtime so that the sample event is generated at EXACTLY that time.
   * below should be: if (tmp >= -0.0001 && tmp < 0.0001) but needs more testing as some models from
   * testsuite fail.
   */
  static const double eps = 0.0001;

  /* double sloop = 4.0/interval;
   * adrpo: if we test for inSample == 0 no event is generated when start + 0*interval!
   * if (inSample == 0) return 0;
   */
  double tmp = ((globalData->timeValue - start) / interval);
  int tmpindex = globalData->curSampleTimeIx;
  tmp = 1;
  
  if(tmpindex < globalData->nSampleTimes)
  {
    while((globalData->sampleTimes[tmpindex]).activated == 1)
    {
      if((globalData->sampleTimes[tmpindex]).zc_index == hindex)
        tmp = 0;
		
      tmpindex++;
	  
      if(tmpindex == globalData->nSampleTimes)
        break;
    }
  }

  /*
   * sjoelund - do not sample before the start value !
   */
  if(globalData->timeValue >= start - eps && tmp >= -eps && tmp < eps)
  {
    DEBUG_INFO(LV_EVENTS, "Calling sample(%f, %f)", start, interval);
	DEBUG_INFO(LV_EVENTS, "+generating an event at time: %f \t tmp: %f", globalData->timeValue, tmp);
    return 1;
  }
  else
  {
    DEBUG_INFO(LV_EVENTS, "Calling sample(%f, %f)", start, interval);
	DEBUG_INFO(LV_EVENTS, "-NO event at time: %f \t tmp: %f", globalData->timeValue, tmp);
    return 0;
  }
}

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

static int compSample(const void* a, const void* b)
{
  const sample_time *v1 = (const sample_time *) a;
  const sample_time *v2 = (const sample_time *) b;
  const double diff = v1->events - v2->events;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

static int compSampleZC(const void* a, const void* b)
{
  const sample_time *v1 = (const sample_time *) a;
  const sample_time *v2 = (const sample_time *) b;
  const double diff = v1->events - v2->events;
  const int diff2 = v1->zc_index - v2->zc_index;
  const double epsilon = 0.0000000001;

  if(diff < epsilon && diff > -epsilon && diff2 == 0)
    return 0;
  return (v1->events > v2->events) ? 1 : -1;
}

static int unique(void *base, size_t nmemb, size_t size,
                  int (*compar)(const void *, const void *))
{
  size_t nuniq = 0;
  size_t i;
  void *a, *b, *c;
  a = base;
  for(i = 1; i < nmemb; i++)
  {
    b = ((char*) base) + i * size;
    if(0 == compar(a, b))
	  nuniq++;
    else
    {
      a = b;
      c = ((char*) base) + (i - nuniq) * size;
      if(b != c)
        memcpy(c, b, size); /* happens when nuniq==0*/
    }
  }
  return nmemb - nuniq;
}

void initSample(double start, double stop)
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
  sample_time* Samples = NULL;
  int num_samples = 0;
  int max_events = 0;
  int ix = 0;
  int nuniq;

  function_sampleInit();

  num_samples = globalData->nRawSamples;

  for(i = 0; i < num_samples; i++)
  {
    if(stop >= globalData->rawSampleExps[i].start)
	  max_events += (int)(((stop - globalData->rawSampleExps[i].start) / globalData->rawSampleExps[i].interval) + 1);
  }
  
  Samples = (sample_time*)calloc(max_events+1, sizeof(sample_time));
  if(Samples == NULL)
  {
    DEBUG_INFO(LV_EVENTS, "Could not allocate Memory for initSample!");
	THROW("Could not allocate Memory for initSample!");
  }
  for(i = 0; i < num_samples; i++)
  {
    DEBUG_INFO(LV_EVENTS, "Generate times for sample(%f, %f)", globalData->rawSampleExps[i].start, globalData->rawSampleExps[i].interval);
    
	for(d = globalData->rawSampleExps[i].start; ix < max_events && d <= stop; d += globalData->rawSampleExps[i].interval)
    {
	  (Samples[ix]).events = d;
      (Samples[ix++]).zc_index = (globalData->rawSampleExps[i]).zc_index;
	  
	  DEBUG_INFO(LV_EVENTS, "Generate sample(%f, %f, %d)", d, globalData->rawSampleExps[i].interval, (globalData->rawSampleExps[i]).zc_index);
    }
  }
  
  /* Sort, filter out unique values */
  qsort(Samples, max_events, sizeof(sample_time), compSample);
  nuniq = unique(Samples, max_events, sizeof(sample_time), compSampleZC);
  
  DEBUG_INFO(LV_EVENTS, "Number of sorted, unique sample events: %d", nuniq);
  for(i = 0; i < nuniq; i++)
    DEBUG_INFO_AL(LV_EVENTS, "%f\t HelpVar[%d]", (Samples[i]).events, (Samples[i]).zc_index);

  globalData->sampleTimes = Samples;
  globalData->curSampleTimeIx = 0;
  globalData->nSampleTimes = nuniq;
}

/* function: saveall
 *
 * stores all the values for use with the pre-operator
 */
void saveall()
{
    fortran_integer i = 0;
    long l=0;
    for(i=0; i<globalData->nStates; i++)
    {
        x_saved[i] = globalData->states[i];
        xd_saved[i] = globalData->statesDerivatives[i];
    }

    for(i = 0; i < globalData->nAlgebraic; i++)
    {
        y_saved[i] = globalData->algebraics[i];
    }
    for(l = 0; l < globalData->intVariables.nAlgebraic; l++)
    {
        int_saved[l] = globalData->intVariables.algebraics[l];
    }

    for(l = 0; l < globalData->boolVariables.nAlgebraic; l++)
    {
        bool_saved[l] = globalData->boolVariables.algebraics[l];
    }

    for(l = 0; l < globalData->nHelpVars; l++)
    {
        h_saved[l] = globalData->helpVars[l];
    }

    for(l = 0; l < globalData->stringVariables.nAlgebraic; l++)
    {
        str_saved[l] = globalData->stringVariables.algebraics[l];
    }
}

/** function printAllPreValues
 *  author: lochel
 */
void printAllPreValues()
{
    fortran_integer i=0;
    long l=0;
    for(i=0; i<globalData->nStates; i++)
    {
        INFO("x_saved[%ld] = %f)", i, x_saved[i]);
        INFO("xd_saved[%ld] = %f)", i, xd_saved[i]);
    }

    for(i = 0; i < globalData->nAlgebraic; i++)
    {
    	INFO("y_saved[%ld] = %f)", i, y_saved[i]);
    }

    for(l = 0; i < globalData->intVariables.nAlgebraic; l++)
    {
    	INFO("int_saved[%ld] = %d)", l, (int)int_saved[l]);
    }

    for(l = 0; l < globalData->boolVariables.nAlgebraic; l++)
    {
    	INFO("bool_saved[%ld] = %s)", l, (bool_saved[l] ? "true" : "false"));
    }

    for(l = 0; l < globalData->nHelpVars; l++)
    {
    	INFO("h_saved[%ld] = %f)", l, h_saved[l]);
    }

    for(l = 0; l < globalData->stringVariables.nAlgebraic; l++)
    {
    	INFO("h_saved[%ld] = %s)", l, str_saved[l]);
    }
}

/** function restoreHelpVars
 * author: wbraun
 *
 * workaround function to reset all helpvar that are used for when-equations.
 */
void restoreHelpVars()
{
  int i = 0;
  for(i = 0; i < globalData->nHelpVars; i++)
  {
    globalData->helpVars[i] = 0;
  }
}

void checkTermination()
{
  if(terminationAssert || terminationTerminate)
  {
    printInfo(stdout, TermInfo);
    fputc(' ', stdout);
  }
  
  if(terminationAssert)
  {
    if(warningLevelAssert)
	{
      /* terminated from assert, etc. */
	  WARNING("Simulation call assert() at time %f\nLevel : warning\nMessage : %s", globalData->timeValue, TermMsg);
    }
    else
    {
	  WARNING("Simulation call assert() at time %f\nLevel : error\nMessage : %s", globalData->timeValue, TermMsg);
	  THROW("timeValue = %f", globalData->timeValue);
	}
  }
  
  if(terminationTerminate)
  {
    WARNING("Simulation call terminate() at time %f\nMessage : %s", globalData->timeValue, TermMsg);
	THROW("timeValue = %f", globalData->timeValue);
  }
}

void
debugPrintHelpVars()
{
  long i = 0;
  DEBUG_INFO(LV_EVENTS, "*'*'*'*  HELP VARS  *'*'*'*");

  for (i = 0; i < globalData->nHelpVars; i++)
  {
	  DEBUG_INFO(LV_EVENTS, "HelpVar[%ld] pre: %f, current: %f", i, globalData->helpVars_saved[i], globalData->helpVars[i]); fflush(NULL);
  }
}

/*
 * All event functions from here, are till now only used in Euler
 *
 */

double
getNextSampleTimeFMU()
{
    if (globalData->curSampleTimeIx < globalData->nSampleTimes)
    {
        return((globalData->sampleTimes[globalData->curSampleTimeIx]).events);
    }
    else
    {
        return -1;
    }

}


int
checkForSampleEvent()
{
  double a = globalData->timeValue + globalData->current_stepsize;
  int b = 0;
  int tmpindex = 0;

  DEBUG_INFO(LV_EVENTS, "Check for Sample Events. Current Index: %li", globalData->curSampleTimeIx);

  DEBUG_INFO(LV_EVENTS, "*** Next step : %f", a);
  DEBUG_INFO(LV_EVENTS, "*** Next sample Time : %f", ((globalData->sampleTimes[globalData->curSampleTimeIx]).events));

  tmpindex = globalData->curSampleTimeIx;
  b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));
  if (b >= 0)
    {
      DEBUG_INFO(LV_EVENTS, "** Sample Event **");

      if (!(b == 0))
      {
          if ((globalData->sampleTimes[tmpindex]).events - globalData->timeValue >= 0){
             globalData->current_stepsize = (globalData->sampleTimes[tmpindex]).events - globalData->timeValue;
          }else{
              globalData->current_stepsize = 0;
          }

          DEBUG_INFO(LV_EVENTS, "** Change Stepsize : %f", globalData->current_stepsize);
      }
      return 1;
    }
  else
    {
      return 0;
    }
}

int
activateSampleEvents()
{
    if (globalData->curSampleTimeIx < globalData->nSampleTimes)
    {
        int retVal = 0;
        double a = globalData->timeValue;
        int b = 0;
        long int tmpindex = globalData->curSampleTimeIx;
        DEBUG_INFO(LV_EVENTS, "Activate Sample Events.");
        DEBUG_INFO(LV_EVENTS, "Current Index: %li", globalData->curSampleTimeIx);

        b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));
        while (b >= 0)
        {
            retVal = 1;
            (globalData->sampleTimes[tmpindex]).activated = 1;
            DEBUG_INFO(LV_EVENTS, "Activate Sample Events index: %li", tmpindex);
            tmpindex++;
            if (tmpindex >= globalData->nSampleTimes)
                break;
            b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));
        }
        return retVal;
    }
    else
    {
        return 0;
    }

}

void
deactivateSampleEvents()
{
  int tmpindex = globalData->curSampleTimeIx;

  while ((globalData->sampleTimes[tmpindex]).activated == 1)
    {
      (globalData->sampleTimes[tmpindex++]).activated = 0;
    }
}

void
deactivateSampleEventsandEquations()
{
  while ((globalData->sampleTimes[globalData->curSampleTimeIx]).activated == 1)
    {
      DEBUG_INFO(LV_EVENTS, "Deactivate Sample Events index: %li", globalData->curSampleTimeIx);

      (globalData->sampleTimes[globalData->curSampleTimeIx]).activated = 0;
      globalData->helpVars[((globalData->sampleTimes[globalData->curSampleTimeIx]).zc_index)]
                           = 0;
      globalData->curSampleTimeIx++;
    }
  function_updateSample();
}

/*
   This function checks for Events in Interval=[oldTime, timeValue]
   If a ZeroCrossing Function cause a sign change, root finding
   process will start
*/
int
CheckForNewEvent(int* sampleactived)
{
  long i = 0;
  initializeZeroCrossings();
  if (sim_verbose >= LOG_EVENTS)
    {
      DEBUG_INFO(LV_EVENTS, "Check for events ...");
    }
  for (i = 0; i < globalData->nZeroCrossing; i++)
    {
      DEBUG_INFO(LV_ZEROCROSSINGS, "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %li",
                  i, gout_old[i], gout[i], zeroCrossingEnabled[i]);

      if (gout_old[i] == 0)
        {
          if (gout[i] > 0 && zeroCrossingEnabled[i] <= -1)
            {
              DEBUG_INFO(LV_EVENTS, "adding event %ld at time: %f", i, globalData->timeValue);

              listPushFront(eventList, &i);
            }
          else if (gout[i] < 0 && zeroCrossingEnabled[i] >= 1)
            {
              DEBUG_INFO(LV_EVENTS, "adding event %ld at time: %f", i, globalData->timeValue);

              listPushFront(eventList, &i);
            }
        }
      if ((gout[i] <= 0 && gout_old[i] > 0) ||
          (gout[i] >= 0 && gout_old[i] < 0))
        {
          DEBUG_INFO(LV_EVENTS, "adding event %ld at time: %f", i, globalData->timeValue);

          listPushFront(eventList, &i);
        }
    }
  if (listLength(eventList) > 0)
    {
      double EventTime = 0;

      if (*sampleactived == 1)
        {
          *sampleactived = 0;
          deactivateSampleEvents();
        }

      FindRoot(&EventTime);
      /*Handle event as state event*/
      EventHandle(0);

      DEBUG_INFO(LV_EVENTS, "Event Handling at EventTime: %f done!", EventTime);

      return 1;
    }
  return 0;
}

/*
  This function handle events and change all
  needed variables for an event
  parameter flag - Indicate the kind of event
     = 0 state event
     = 1 sample event
*/
int
EventHandle(int flag)
{

  if (flag == 0)
    {
      int event_id;
      int needToIterate = 0;
      int IterationNum = 0;

      if (sim_verbose >= LOG_EVENTS)
      {
        DEBUG_INFO(LV_EVENTS, "Handle Event caused by ZeroCrossings: ");  fflush(NULL);
      }
      while (listLength(eventList) > 0)
        {
          event_id = *((long*)listFirstData(eventList));
          listPopFront(eventList);
          if (sim_verbose >= LOG_EVENTS)
          {
            fprintf(stdout, "%d", event_id);
            if (listLength(eventList) > 0)
            {
              fprintf(stdout, ", ");
            }
            fflush(NULL);
          }
          if (zeroCrossingEnabled[event_id] == -1)
            {
              zeroCrossingEnabled[event_id] = 1;
            }
          else if (zeroCrossingEnabled[event_id] == 1)
            {
              zeroCrossingEnabled[event_id] = -1;
            }
        }
      if (sim_verbose >= LOG_EVENTS)
      {
          fprintf(stdout, "\n"); fflush(NULL);
      }

      /*debugPrintHelpVars(); */
      /*determined complete system */
      needToIterate = 0;
      IterationNum = 0;
      functionDAE(&needToIterate);
      functionAliasEquations();
      if (sim_verbose >= LOG_EVENTS)
        {
           sim_result_emit();
        }
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "reinit call. Iteration needed!");  fflush(NULL);
              }
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "discrete Var changed. Iteration needed!");
              }
            }
          saveall();
          functionDAE(&needToIterate);
          functionAliasEquations();
          if (sim_verbose >= LOG_EVENTS)
            {
              sim_result_emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
              /*break; */
              fprintf(stdout, "ERROR: Too many Iteration. System is not consistent!");  fflush(NULL);
              EXIT(1);
              /*throw TerminateSimulationException(
                  globalData->timeValue, 
                  string(
                      "ERROR: Too many Iteration. System is not consistent!\n"));*/
            }

        }
    }
  /* sample event handling */
  else if (flag == 1)
    {
      int needToIterate = 0;
      int IterationNum = 0;
      if (sim_verbose >= LOG_EVENTS)
        {
          DEBUG_INFO(LV_EVENTS, "Event Handling for Sample : %f!", globalData->timeValue); fflush(NULL);
        }
      sim_result_emit();
      /*evaluate and emit results before sample events are activated */
      functionDAE(&needToIterate);
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "reinit call. Iteration needed!");
              }
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "discrete Var changed. Iteration needed!");
              }
            }
          saveall();
          functionDAE(&needToIterate);
          if (sim_verbose >= LOG_EVENTS)
            {
              sim_result_emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
              fprintf(stdout, "ERROR: Too many Iteration. System is not consistent!");  fflush(NULL);
              EXIT(1);
              /*throw TerminateSimulationException(globalData->timeValue, string(
                  "ERROR: Too many Iteration. System is not consistent!\n"));*/
            }

        }
      saveall();
      sim_result_emit();

      /*Activate sample and evaluate again */
      activateSampleEvents();

      functionDAE(&needToIterate);
      if (sim_verbose >= LOG_EVENTS)
        {
          sim_result_emit();
        }
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "reinit call. Iteration needed!");
              }
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
              {
                DEBUG_INFO(LV_EVENTS, "discrete Var changed. Iteration needed!");
              }
            }
          saveall();
          functionDAE(&needToIterate);
          if (sim_verbose >= LOG_EVENTS)
            {
              sim_result_emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
                fprintf(stdout, "ERROR: Too many Iteration. System is not consistent!\n");  fflush(NULL);
                EXIT(1);
             /* throw TerminateSimulationException(globalData->timeValue, string(
                  "ERROR: Too many Iteration. System is not consistent!\n"));*/
            }

        }
      deactivateSampleEventsandEquations();
      if (sim_verbose >= LOG_EVENTS)
        {
          DEBUG_INFO(LV_EVENTS, "Event Handling for Sample : %f done!", globalData->timeValue);
        }
    }
  SaveZeroCrossingsAfterEvent();
  correctDirectionZeroCrossings();
  return 0;
}

/*
  This function perform a root finding for
  Intervall=[oldTime, timeValue]
*/
void FindRoot(double *EventTime)
{
  int event_id;
  LIST_NODE* it;
  fortran_integer i=0;
  static LIST *tmpEventList = 0;
  
  double *states_right = (double*)calloc(globalData->nStates, sizeof(double));
  double *states_left = (double*)calloc(globalData->nStates, sizeof(double));

  double time_left = globalData->oldTime;
  double time_right = globalData->timeValue;

  if(!tmpEventList)
      tmpEventList = allocList(sizeof(long));

  assert(states_right);
  assert(states_left);

  for(it=listFirstNode(eventList); it; it=listNextNode(it))
    {
	  	  DEBUG_INFO(LV_ZEROCROSSINGS, "Search for current event. Events in list: %ld", *((long*)listNodeData(it)));
    }


  /*write states to work arrays*/
  for (i = 0; i < globalData->nStates; i++)
    {
      states_left[i] = globalData->states_old[i];
      states_right[i] = globalData->states[i];
    }

  /* Search for event time and event_id with Bisection method */
  *EventTime = BiSection(&time_left, &time_right, states_left, states_right, 
      tmpEventList);

  if (listLength(tmpEventList) == 0)
    {
        double value = fabs(gout[*((long*)listFirstData(eventList))]);
        for(it=listFirstNode(eventList); it; it=listNextNode(it))
        {
            if(value > fabs(gout[*((long*)listNodeData(it))]))
            {
                value = fabs(gout[*((long*)listNodeData(it))]);
            }
        }
      if (sim_verbose >= LOG_ZEROCROSSINGS)
        {
          DEBUG_INFO(LV_ZEROCROSSINGS, "Minimum value: %g", value);
        }
      for (it=listFirstNode(eventList); it; it=listNextNode(it))
        {
            if (value == fabs(gout[*((long*)listNodeData(it))]))
            {
              listPushBack(tmpEventList, listNodeData(it));
              DEBUG_INFO(LV_ZEROCROSSINGS, "added tmp event : %ld", *((long*)listNodeData(it)));
            }
        }
    }

  listClear(eventList);

  if (listLength(tmpEventList) > 0)
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          DEBUG_INFO(LV_EVENTS, "Found events: "); fflush(NULL);
        }
    }
  else
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          DEBUG_INFO(LV_EVENTS, "Found event: "); fflush(NULL);
        }
    }
  while (listLength(tmpEventList) > 0)
    {
      event_id = *((long*)listFirstData(tmpEventList));
      listPopFront(tmpEventList);
      if (sim_verbose >= LOG_EVENTS)
        {
          fprintf(stdout, "%d ", event_id); fflush(NULL);
        }
      if (listLength(tmpEventList) > 0)
        {
          if (sim_verbose >= LOG_EVENTS)
            {
              fprintf(stdout, ", "); fflush(NULL);
            }
        }
      listPushFront(eventList, &event_id);
    }
  if (sim_verbose >= LOG_EVENTS)
  {
      fprintf(stdout, "\n"); fflush(NULL);
  }

 DEBUG_INFO(LV_EVENTS, "at time: %g \nTime at Point left: %g\nTime at Point right: %g", *EventTime, time_left, time_right);

  /*determined system at t_e - epsilon */
  globalData->timeValue = time_left;
  for (i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = states_left[i];
    }
  /*determined continuous system */
  functionODE();
  functionAlgebraics();
  function_storeDelayed();
  saveall();
  sim_result_emit();

  /*determined system at t_e + epsilon */
  globalData->timeValue = time_right;
  for (i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = states_right[i];
    }

  free(states_left);
  free(states_right);

}

/*
  Method to find root in Intervall[oldTime, timeValue]
*/
double
BiSection(double* a, double* b, double* states_a, double* states_b, 
    LIST *tmpEventList)
{

  /*double TTOL =  DBL_EPSILON*fabs((*b - *a))*100; */
  double TTOL = 1e-9;
  double c;
  int right = 0;
  long i = 0;

  double *backup_gout = (double*)calloc(globalData->nZeroCrossing, sizeof(double));
  assert(backup_gout);

  for (i = 0; i < globalData->nZeroCrossing; i++)
    {
      backup_gout[i] = gout[i];
    }

  DEBUG_INFO(LV_ZEROCROSSINGS, "Check interval [%g, %g]", *a, *b);
  DEBUG_INFO(LV_ZEROCROSSINGS, "TTOL is set to: %g", TTOL);

  while (fabs(*b - *a) > TTOL)
    {

      c = (*a + *b) / 2.0;
      globalData->timeValue = c;

      /*if (sim_verbose >= LOG_ZEROCROSSINGS){
        cout << "Split interval at point : " << c << endl;
      } */

      /*calculates states at time c */
      for (i = 0; i < globalData->nStates; i++)
        {
          globalData->states[i] = (states_a[i] + states_b[i]) / 2.0;
        }

      /*calculates Values dependents on new states*/
      functionODE();
      functionAlgebraics();

      function_onlyZeroCrossings(gout, &globalData->timeValue);
      if (CheckZeroCrossings(tmpEventList))
        { /*If Zerocrossing in left Section */

          for (i = 0; i < globalData->nStates; i++)
            {
              states_b[i] = globalData->states[i];
            }
          *b = c;
          /*if (sim_verbose >= LOG_ZEROCROSSINGS){
               cout << "Found ZeroCrossing in the left section. " << endl;
                  for(int i=0;i<globalData->nStates;i++){
                      cout << "states at b : " << states_b[i]  << endl;
                  }
           }*/
          /*for(int i=0;i<globalData->nZeroCrossing;i++){
             backup_gout[i] = gout_old[i];
          } */
          right = 0;

        }
      else
        { /*else Zerocrossing in right Section */

          for (i = 0; i < globalData->nStates; i++)
            {
              states_a[i] = globalData->states[i];
            }
          *a = c;
          /*if (sim_verbose >= LOG_ZEROCROSSINGS){
             cout << "ZeroCrossing is in the right section. " << endl;
             for(int i=0;i<globalData->nStates;i++){
                 cout << "states at a : " << states_a[i]  << endl;
             }
          }*/
          right = 1;
        }
      if (right)
        {
          for(i=0;i<globalData->nZeroCrossing;i++){
            gout_old[i] = gout[i];
            gout[i] = backup_gout[i];
          }
          /*std::copy(gout, gout + globalData->nZeroCrossing, gout_old);*/
          /*std::copy(backup_gout, backup_gout + globalData->nZeroCrossing, gout);*/
        }
      else
        {

          /* std::copy(gout, gout + globalData->nZeroCrossing, backup_gout);
          std::copy(backup_gout, backup_gout + globalData->nZeroCrossing, gout); */
          for(i=0;i<globalData->nZeroCrossing;i++){
            gout_old[i] = gout[i];
            gout[i] = backup_gout[i];
          } 
        }
    }

  /*
  if (sim_verbose >= LOG_ZEROCROSSINGS){
      for (long i = 0; i < globalData->nZeroCrossing; i++) {
          cout << "check gout_old[" << i << "] = " << gout_old[i] << "\t" <<
                  "check gout[" << i << "] = " << gout[i] <<
                  "check gout_backup[" << i << "] = " << backup_gout[i] << endl;
      }
  }
  */
  free(backup_gout);
  c = (*a + *b) / 2.0;
  return c;
}

/*
   Check if at least one zerocrossing has change sign
   is used in BiSection
*/
int
CheckZeroCrossings(LIST *tmpEventList)
{

  LIST_NODE *it;
  
  listClear(tmpEventList);
  for(it=listFirstNode(eventList); it; it=listNextNode(it))
    {
      DEBUG_INFO(LV_ZEROCROSSINGS, "ZeroCrossing ID: %ld \t old = %g \t current = %g \t Direction = %li",
              *((long*)listNodeData(it)), gout_old[*((long*)listNodeData(it))], gout[*((long*)listNodeData(it))], zeroCrossingEnabled[*((long*)listNodeData(it))]); fflush(NULL);

      /*Found event in left section*/
      if ((gout[*((long*)listNodeData(it))] <= 0 && gout_old[*((long*)listNodeData(it))] > 0) || (gout[*((long*)listNodeData(it))] >= 0 && gout_old[*((long*)listNodeData(it))] < 0)
          || (gout[*((long*)listNodeData(it))] > 0 && zeroCrossingEnabled[*((long*)listNodeData(it))] <= -1) || (gout[*((long*)listNodeData(it))] < 0
              && zeroCrossingEnabled[*((long*)listNodeData(it))] >= 1))
        {
           listPushFront(tmpEventList, listNodeData(it));
        }
    }
  /*Found event in left section*/
  if (listLength(tmpEventList) > 0)
    {
      return 1;
    }
  /* Else event in right section */
  else
    {
      return 0;
    }
}

void
SaveZeroCrossings()
{
  long i = 0;

  DEBUG_INFO(LV_ZEROCROSSINGS, "Save ZeroCrossings!");

  for(i=0;i<globalData->nZeroCrossing;i++){
      gout_old[i] = gout[i];
  } 
  function_onlyZeroCrossings(gout, &globalData->timeValue);
}

void
SaveZeroCrossingsAfterEvent()
{
  long i = 0;

  DEBUG_INFO(LV_ZEROCROSSINGS, "Save ZeroCrossings after an Event!");

  function_onlyZeroCrossings(gout, &globalData->timeValue);
  for(i=0;i<globalData->nZeroCrossing;i++){
      gout_old[i] = gout[i];
  }
}


void
initializeZeroCrossings()
{
  long i = 0;
  for (i = 0; i < globalData->nZeroCrossing; i++)
    {
      if (zeroCrossingEnabled[i] == 0){
          if (gout[i] > 0)
            zeroCrossingEnabled[i] = 1;
          else if (gout[i] < 0)
            zeroCrossingEnabled[i] = -1;
          else
            zeroCrossingEnabled[i] = 0;
      }
    }
}

void
correctDirectionZeroCrossings()
{
  long i = 0;
  for (i = 0; i < globalData->nZeroCrossing; i++)
    {
      if (zeroCrossingEnabled[i] == -1 && gout[i] > 0){
          zeroCrossingEnabled[i] = 1;
      }else if (zeroCrossingEnabled[i] == 1 && gout[i] < 0){
            zeroCrossingEnabled[i] = -1;
      }
    }
}
