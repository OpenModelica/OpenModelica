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

#include "simulation_events.h"
#include "simulation_runtime.h"
#include "simulation_result.h"
#include <math.h>
#include <string.h> // for memset
#include <stdio.h>
#include <list>
#include <cfloat>

using namespace std;

// vectors with saved values used by pre(v)
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

static list<long> EventQueue;
static list<int> EventList;


/* \brief allocate global data structures for event handling
 *
 * \return zero if successful.
 */
int
initializeEventData()
{
  /*
   * Re-Initialization is important because the variables are global and used in every solving step
   */
  h_saved = 0;
  x_saved = 0;
  xd_saved = 0;
  y_saved = 0;
  int_saved = 0;
  bool_saved = 0;

  gout = 0;
  gout_old = 0;
  backuprelations = 0;
  zeroCrossingEnabled = 0;
  inUpdate = 0;
  inSample = 0;

  // load default initial values.
  gout = new double[globalData->nZeroCrossing];
  gout_old = new double[globalData->nZeroCrossing];
  backuprelations = new modelica_boolean[globalData->nZeroCrossing];
  h_saved = new double[globalData->nHelpVars];
  x_saved = new double[globalData->nStates];
  xd_saved = new double[globalData->nStates];
  y_saved = new double[globalData->nAlgebraic];
  int_saved = new modelica_integer[globalData->intVariables.nAlgebraic];
  bool_saved = new modelica_boolean[globalData->boolVariables.nAlgebraic];
  str_saved = new const char*[globalData->stringVariables.nAlgebraic];
  zeroCrossingEnabled = new long[globalData->nZeroCrossing];
  if (!y_saved || !gout || !gout_old || !backuprelations
      || !h_saved || !x_saved || !xd_saved || !int_saved
      || !bool_saved || !str_saved || !zeroCrossingEnabled)
    {
      cerr << "Could not allocate memory for global event data structures"
          << endl;
      return -1;
    }
  // adrpo 2006-11-30 -> init the damn structures!
  memset(gout, 0, sizeof(double) * globalData->nZeroCrossing);
  memset(gout_old, 0, sizeof(double) * globalData->nZeroCrossing);
  memset(backuprelations, 0, sizeof(modelica_boolean) * globalData->nZeroCrossing);
  memset(h_saved, 0, sizeof(double) * globalData->nHelpVars);
  memset(x_saved, 0, sizeof(double) * globalData->nStates);
  memset(xd_saved, 0, sizeof(double) * globalData->nStates);
  memset(y_saved, 0, sizeof(double) * globalData->nAlgebraic);
  memset(int_saved, 0, sizeof(modelica_integer)
      * globalData->intVariables.nAlgebraic);
  memset(bool_saved, 0, sizeof(modelica_boolean)
      * globalData->boolVariables.nAlgebraic);
  memset(str_saved, 0, sizeof(char*) * globalData->stringVariables.nAlgebraic);
  memset(zeroCrossingEnabled, 0, sizeof(long) * globalData->nZeroCrossing);
  return 0;
}

/* \brief deallocate global data for event handling.
 *
 */
void
deinitializeEventData()
{
  delete[] h_saved;
  delete[] x_saved;
  delete[] xd_saved;
  delete[] y_saved;
  delete[] int_saved;
  delete[] bool_saved;
  delete[] gout;
  delete[] gout_old;
  delete[] backuprelations;
  delete[] zeroCrossingEnabled;
  delete[] str_saved;
}

// relation functions used in zero crossing detection
double
Less(double a, double b)
{
  return a - b;
}

double
LessEq(double a, double b)
{
  return a - b;
}

double
Greater(double a, double b)
{
  return (b+DBL_MIN) - a;
}

double
GreaterEq(double a, double b)
{
  return b - a;
}

double
Sample(double t, double start, double interval)
{
  double pipi = atan(1.0) * 8.0;
  if (t < (start - interval * .25))
    return -1.0;
  return sin(pipi * (t - start) / interval);
}

/*
 * Returns true and triggers time events at time instants
 * start + i*interval (i=0,1,...).
 * During continuous integration the operator returns always false.
 * The starting time start and the sample interval interval need to
 * be parameter expressions and need to be a subtype of Real or Integer.
 */
double
sample(double start, double interval, int hindex)
{
  // double sloop = 4.0/interval;
  // adrpo: if we test for inSample == 0 no event is generated when start + 0*interval!
  // if (inSample == 0) return 0;
  double tmp = ((globalData->timeValue - start) / interval);
  tmp = 1;
  int tmpindex = globalData->curSampleTimeIx;
  if (tmpindex < globalData->nSampleTimes)
	{
	  while ((globalData->sampleTimes[tmpindex]).activated == 1)
		{
		  if ((globalData->sampleTimes[tmpindex]).zc_index == hindex)
			{
			  tmp = 0;
			}
		  tmpindex++;
		  if (tmpindex == globalData->nSampleTimes)
			break;
		}
	}

  /* adrpo - 2008-01-15
   * comparison was tmp >= 0 fails sometimes on x86 due to extended precision in registers
   * TODO - fix the simulation runtime so that the sample event is generated at EXACTLY that time.
   * below should be: if (tmp >= -0.0001 && tmp < 0.0001) but needs more testing as some models from
   * testsuite fail.
   */
  static const double eps = 0.0001;
  /*
   * sjoelund - do not sample before the start value !
   */
  if (globalData->timeValue >= start - eps && tmp >= -eps && tmp < eps)
    {
      if (sim_verbose >= LOG_EVENTS)
        cout << "Calling sample(" << start << ", " << interval << ")\n"
        << "+generating an event at time:" << globalData->timeValue
        << " tmp: " << tmp << endl;
      return 1;
    }
  else
    {
      if (sim_verbose >= LOG_EVENTS)
        cout << "Calling sample(" << start << ", " << interval << ")\n"
        << "-NO an event at time:" << globalData->timeValue << " tmp: "
        << tmp << endl;
      return 0;
    }
}

static int
compdbl(const void* a, const void* b)
{
  const double *v1 = (const double *) a;
  const double *v2 = (const double *) b;
  const double diff = *v1 - *v2;
  const double epsilon = 0.00000000000001;

  if (diff < epsilon && diff > -epsilon)
    return 0;
  return (*v1 > *v2 ? 1 : -1);
}

static int
compSample(const void* a, const void* b)
{
  const sample_time *v1 = (const sample_time *) a;
  const sample_time *v2 = (const sample_time *) b;
  const double diff = v1->events - v2->events;
  const double epsilon = 0.0000000001;

  if (diff < epsilon && diff > -epsilon)
    return 0;
  return (v1->events > v2->events ? 1 : -1);
}

static int
compSampleZC(const void* a, const void* b)
{
  const sample_time *v1 = (const sample_time *) a;
  const sample_time *v2 = (const sample_time *) b;
  const double diff = v1->events - v2->events;
  const int diff2 = v1->zc_index - v2->zc_index;
  const double epsilon = 0.0000000001;

  if (diff < epsilon && diff > -epsilon && diff2 == 0)
    return 0;
  return (v1->events > v2->events ? 1 : -1);
}

static int
unique(void *base, size_t nmemb, size_t size, int
    (*compar)(const void *, const void *))
{
  size_t nuniq = 0;
  size_t i;
  void *a, *b, *c;
  a = base;
  for (i = 1; i < nmemb; i++)
    {
      b = ((char*) base) + i * size;
      if (0 == compar(a, b))
        {
          nuniq++;
        }
      else
        {
          a = b;
          c = ((char*) base) + (i - nuniq) * size;
          if (b != c)
            memcpy(c, b, size); // Happens when nuniq==0
        }
    }
  return nmemb - nuniq;
}

// Array does not need to be sorted
static int
filter_all_lesser(void *base, void *a, size_t nmemb, size_t size, int
    (*compar)(const void *, const void *))
{
  size_t nuniq = 0;
  size_t i;
  void *b, *c;
  for (i = 0; i < nmemb; i++)
    {
      b = ((char*) base) + i * size;
      if (compar(a, b) >= 0)
        {
          nuniq++;
        }
      else
        {
          c = ((char*) base) + (i - nuniq) * size;
          if (b != c)
            memcpy(c, b, size); // Happens when nuniq==0
        }
    }
  return nmemb - nuniq;
}

void
initSample(double start, double stop)
{
  /* not used yet
   * long measure_start_time = clock();
   */
  function_sampleInit();
  /* This code will generate an array of time values when sample generates events.
   * The only problem is our backend does not generate this array.
   * Sample() and sample() also need to be changed, but this should be easy to fix. */
  int i;
  //double stop = 1.0;
  double d;
  sample_time* Samples = NULL;
  int num_samples = globalData->nRawSamples;
  int max_events = 0;
  int ix = 0;
  int nuniq;

  for (i = 0; i < num_samples; i++)
    {
      if (stop >= globalData->rawSampleExps[i].start)
        max_events += (int) (((stop - globalData->rawSampleExps[i].start)
            / globalData->rawSampleExps[i].interval) + 1);
    }
  Samples = (sample_time*) calloc(max_events + 1, sizeof(sample_time));
  if (Samples == NULL)
    throw TerminateSimulationException("Could not allocate Memory for initSample!");
  for (i = 0; i < num_samples; i++)
    {
      if (sim_verbose  >= LOG_EVENTS)
        printf("Generate times for sample(%f,%f)\n",
            globalData->rawSampleExps[i].start,
            globalData->rawSampleExps[i].interval);
      for (d = globalData->rawSampleExps[i].start; ix < max_events && d <= stop; d
      += globalData->rawSampleExps[i].interval)
        {
          (Samples[ix]).events = d;
          (Samples[ix++]).zc_index = (globalData->rawSampleExps[i]).zc_index;
          if (sim_verbose >= LOG_EVENTS)
            printf("Generate sample(%f,%f,%d)\n", d,
                globalData->rawSampleExps[i].interval,
                (globalData->rawSampleExps[i]).zc_index);
        }
    }
  // Sort, filter out unique values
  qsort(Samples, max_events, sizeof(sample_time), compSample);
  nuniq = unique(Samples, max_events, sizeof(sample_time), compSampleZC);
  if (sim_verbose  >= LOG_EVENTS)
    {
      printf("Number of sorted, unique sample events: %d\n", nuniq);
      for (i = 0; i < nuniq; i++)
        printf("%f\t HelpVar[%d]\n", (Samples[i]).events, (Samples[i]).zc_index);
    }
  globalData->sampleTimes = Samples;
  globalData->curSampleTimeIx = 0;
  globalData->nSampleTimes = nuniq;

}

void
saveall()
{
  long i;
  for (i = 0; i < globalData->nStates; i++)
    {
      x_saved[i] = globalData->states[i];
      xd_saved[i] = globalData->statesDerivatives[i];
    }
  for (i = 0; i < globalData->nAlgebraic; i++)
    {
      y_saved[i] = globalData->algebraics[i];
    }
  for (i = 0; i < globalData->intVariables.nAlgebraic; i++)
    {
      int_saved[i] = globalData->intVariables.algebraics[i];
    }
  for (i = 0; i < globalData->boolVariables.nAlgebraic; i++)
    {
      bool_saved[i] = globalData->boolVariables.algebraics[i];
    }
  for (i = 0; i < globalData->nHelpVars; i++)
    {
      h_saved[i] = globalData->helpVars[i];
    }
  for (i = 0; i < globalData->stringVariables.nAlgebraic; i++)
    {
      str_saved[i] = globalData->stringVariables.algebraics[i];
    }
}
/** function restoreHelpVars
 * author: wbraun
 *
 * workaround function to reset all helpvar that are used for when-equations.
 */
void
restoreHelpVars()
{
  for (int i = 0; i < globalData->nHelpVars; i++)
    {
      globalData->helpVars[i] = 0;
    }
}



void
checkTermination()
{
  if (terminationAssert || terminationTerminate) {
    printInfo(stdout, TermInfo);
    fputc(' ', stdout);
  }
  if (terminationAssert)
    {
      if (warningLevelAssert)
        { // terminated from assert, etc.
          cout << "Simulation call assert() at time " << globalData->timeValue
              << endl;
          cout << "Level : warning" << endl;
          cout << "Message : " << TermMsg << endl;
        }
      else
        {
          cout << "Simulation call assert() at time " << globalData->timeValue
              << endl;
          cout << "Level : error" << endl;
          cout << "Message : " << TermMsg << endl;
          throw TerminateSimulationException(globalData->timeValue);
        }
    }
  if (terminationTerminate)
    {
      cout << "Simulation call terminate() at time " << globalData->timeValue
          << endl;
      cout << "Message : " << TermMsg << endl;
      throw TerminateSimulationException(globalData->timeValue);
    }
}

void
debugPrintHelpVars()
{
  if (sim_verbose >= LOG_EVENTS)
    cout << " *'*'*'*  HELP VARS  *'*'*'*" << endl;
  for (int i = 0; i < globalData->nHelpVars; i++)
    {
      if (sim_verbose >= LOG_EVENTS)
        cout << "HelpVar[" << i << "] pre: " << globalData->helpVars_saved[i]
        << ",  HelpVar[" << i << "] : " << globalData->helpVars[i] << endl;
    }
}

/*
 * All event functions from here, are till now only used in Euler
 *
 */

int
checkForSampleEvent()
{
  if (sim_verbose >= LOG_EVENTS)
    {
      cout << "Check for Sample Events" << endl;
      cout << "Current Index: " << globalData->curSampleTimeIx << endl;
    }
  double a = globalData->timeValue + globalData->current_stepsize;
  if (sim_verbose >= LOG_EVENTS)
    {
      cout << "*** Next step : " << a << endl;
      cout << "*** Next sample Time : "
          << ((globalData->sampleTimes[globalData->curSampleTimeIx]).events)
          << endl;
    }
  int b = 0;
  int tmpindex = globalData->curSampleTimeIx;
  b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));

  if (b >= 0)
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << " ** Sample Event ** " << endl;
        }
      if (!(b == 0))
        {
          globalData->current_stepsize
          = (globalData->sampleTimes[tmpindex]).events
          - globalData->timeValue;
          if (sim_verbose >= LOG_EVENTS)
            {
              cout << " ** Change Stepsize :  " << globalData->current_stepsize
                  << endl;
            }
        }
      return 1;
    }
  else
    {
      return 0;
    }
}

void
activateSampleEvents()
{
  if (sim_verbose >= LOG_EVENTS)
    {
      cout << "Activate Sample Events" << endl;
      cout << "Current Index: " << globalData->curSampleTimeIx << endl;
    }
  double a = globalData->timeValue;
  int b = 0;
  int tmpindex = globalData->curSampleTimeIx;
  b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));
  while (b >= 0)
    {
      (globalData->sampleTimes[tmpindex]).activated = 1;
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Activate Sample Events index: " << tmpindex << endl;
        }
      tmpindex++;
      if (tmpindex >= globalData->nSampleTimes)
        break;
      b = compdbl(&a, &((globalData->sampleTimes[tmpindex]).events));
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
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Deactivate Sample Events index: "
              << globalData->curSampleTimeIx << endl;
        }
      (globalData->sampleTimes[globalData->curSampleTimeIx]).activated = 0;
      globalData->helpVars[((globalData->sampleTimes[globalData->curSampleTimeIx]).zc_index)]
                           = 0;
      globalData->curSampleTimeIx++;
    }
  function_updateSample();
}

//
// This function checks for Events in Interval=[oldTime,timeValue]
// If a ZeroCrossing Function cause a sign change, root finding
// process will start
//
int
CheckForNewEvent(int* sampleactived)
{
  initializeZeroCrossings();
  if (sim_verbose >= LOG_EVENTS)
    {
      cout << "Check for events ..." << endl;
    }
  for (int i = 0; i < globalData->nZeroCrossing; i++)
    {
      if (sim_verbose >= LOG_ZEROCROSSINGS)
        {
          cout << "ZeroCrossing ID: " << i << "\t old = " << gout_old[i]
                                                                      << "\t" << "current = " << gout[i] << "\t" << "Direction: "
                                                                      << zeroCrossingEnabled[i] << endl;
        }
      if (gout_old[i] == 0)
        {
          if (gout[i] > 0 && zeroCrossingEnabled[i] <= -1)
            {
              if (sim_verbose >= LOG_EVENTS)
                {
                  cout << "adding event " << i << " at time: "
                      << globalData->timeValue << endl;
                }
              EventList.push_front(i);
            }
          else if (gout[i] < 0 && zeroCrossingEnabled[i] >= 1)
            {
              if (sim_verbose >= LOG_EVENTS)
                {
                  cout << "adding event " << i << " at time: "
                      << globalData->timeValue << endl;
                }
              EventList.push_front(i);
            }
        }
      if ((gout[i] < 0 && gout_old[i] > 0) ||
          (gout[i] > 0 && gout_old[i] < 0))
        {
          if (sim_verbose >= LOG_EVENTS)
            {
              cout << "adding event " << i << " at time: "
                  << globalData->timeValue << endl;
            }
          EventList.push_front(i);
        }
    }
  if (!EventList.empty())
    {

      if (*sampleactived == 1)
        {
          *sampleactived = 0;
          deactivateSampleEvents();
        }

      double EventTime = 0;
      FindRoot(&EventTime);
      //Handle event as state event
      EventHandle(0);

      // save the ZeroCrossings
      //SaveZeroCrossings();
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Event Handling at EventTime: " << globalData->timeValue
              << " done!" << endl;
        }

      return 1;
    }
  return 0;
}

//
// This function handle events and change all
// needed variables for an event
// parameter flag - Indicate the kind of event
//    = 0 state event
//    = 1 sample event
int
EventHandle(int flag)
{

  if (flag == 0)
    {
      int event_id;

      while (!EventList.empty())
        {
          if (sim_verbose >= LOG_EVENTS)
            {
              cout << "Handle Event caused by ZeroCrossing: ";
            }
          event_id = EventList.front();
          EventList.pop_front();
          if (sim_verbose >= LOG_EVENTS)
            {
              cout << event_id << endl;
              if (!EventList.empty())
                {
                  cout << ", ";
                }
            }
          if (zeroCrossingEnabled[event_id] == -1 || gout[event_id] > 0)
            {
              zeroCrossingEnabled[event_id] = 1;
            }
          else if (zeroCrossingEnabled[event_id] == 1 || gout[event_id] < 0)
            {
              zeroCrossingEnabled[event_id] = -1;
            }
        }
      //debugPrintHelpVars();
      //determined complete system
      int needToIterate = 0;
      int IterationNum = 0;
      functionDAE(&needToIterate);
      functionAliasEquations();
      if (sim_verbose >= LOG_EVENTS)
        {
          if (sim_result) sim_result->emit();
        }
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "reinit call. Iteration needed!" << endl;
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "discrete Var changed. Iteration needed!" << endl;
            }
          saveall();
          functionDAE(&needToIterate);
          functionAliasEquations();
          if (sim_verbose >= LOG_EVENTS)
            {
              if (sim_result) sim_result->emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
              //break;
              throw TerminateSimulationException(
                  globalData->timeValue,
                  string(
                      "ERROR: Too many Iteration. System is not consistent!\n"));
            }

        }
      // sample event handling
    }
  else if (flag == 1)
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Event Handling for Sample : " << globalData->timeValue
              << endl;
        }
      //evaluate and emit results before sample events are activated
      int needToIterate = 0;
      int IterationNum = 0;
      functionDAE(&needToIterate);
      if (sim_verbose >= LOG_EVENTS)
        {
          if (sim_result) sim_result->emit();
        }
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "reinit call. Iteration needed!" << endl;
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "discrete Var changed. Iteration needed!" << endl;
            }
          saveall();
          functionDAE(&needToIterate);
          if (sim_verbose >= LOG_EVENTS)
            {
              if (sim_result) sim_result->emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
              throw TerminateSimulationException(globalData->timeValue, string(
                  "ERROR: Too many Iteration. System is not consistent!\n"));
            }

        }
      saveall();
      if (sim_result) sim_result->emit();

      //Activate sample and evaluate again
      activateSampleEvents();

      functionDAE(&needToIterate);
      if (sim_verbose >= LOG_EVENTS)
        {
          if (sim_result) sim_result->emit();
        }
      while (needToIterate || checkForDiscreteChanges())
        {
          if (needToIterate)
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "reinit call. Iteration needed!" << endl;
            }
          else
            {
              if (sim_verbose >= LOG_EVENTS)
                cout << "discrete Var changed. Iteration needed!" << endl;
            }
          saveall();
          functionDAE(&needToIterate);
          if (sim_verbose >= LOG_EVENTS)
            {
              if (sim_result) sim_result->emit();
            }
          IterationNum++;
          if (IterationNum > IterationMax)
            {
              throw TerminateSimulationException(globalData->timeValue, string(
                  "ERROR: Too many Iteration. System is not consistent!\n"));
            }

        }
      deactivateSampleEventsandEquations();
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Event Handling for Sample : " << globalData->timeValue
              << " DONE!" << endl;
        }
    }
  return 0;
}

//
// This function perform a root finding for
// Intervall=[oldTime,timeValue]
//
void
FindRoot(double *EventTime)
{

  int event_id;
  list<int>::iterator it;
  static list<int> tmpEventList;
  for ( it=EventList.begin() ; it != EventList.end(); it++ )
    {
      if (sim_verbose >= LOG_ZEROCROSSINGS)
        {
          //cout << "--------------------------------------------" << endl;
          cout << "Search for current event. Events in list:  "
              << *it << endl;

        }
    }

  double *states_right = new double[globalData->nStates];
  double *states_left = new double[globalData->nStates];

  double time_left = globalData->oldTime;
  double time_right = globalData->timeValue;

  //write states to work arrays
  for (int i = 0; i < globalData->nStates; i++)
    {
      states_left[i] = globalData->states_old[i];
      states_right[i] = globalData->states[i];
    }

  // Search for event time and event_id with Bisection method
  *EventTime = BiSection(&time_left, &time_right, states_left, states_right,
      &tmpEventList);

  if (tmpEventList.empty())
    {
      double value = fabs(gout[*(EventList.begin())]);;
      for ( it=EventList.begin() ; it != EventList.end(); it++ )
        {
          if (value > fabs(gout[*it]))
            {
              value = fabs(gout[*it]);
            }
        }
      if (sim_verbose >= LOG_ZEROCROSSINGS)
        {
          cout << "Minimum value: " << value << endl;
        }
      for ( it=EventList.begin() ; it != EventList.end(); it++ )
        {
          if (value == fabs(gout[*it]))
            {
              tmpEventList.push_back(*it);
              if (sim_verbose >= LOG_ZEROCROSSINGS)
                {
                  cout << "added tmp event : " << *it << endl;
                }
            }
        }
    }

  EventList.clear();

  if (tmpEventList.size() > 1)
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Found events: ";
        }
    }
  else
    {
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << "Found event: ";
        }
    }
  while (!tmpEventList.empty())
    {
      event_id = tmpEventList.front();
      tmpEventList.pop_front();
      if (sim_verbose >= LOG_EVENTS)
        {
          cout << event_id;
        }
      if (!tmpEventList.empty())
        {
          if (sim_verbose >= LOG_EVENTS)
            {
              cout << ", ";
            }
        }
      EventList.push_front(event_id);
    }
  if (sim_verbose >= LOG_EVENTS)
    {
      cout.precision(10);
      cout << " at time: " << *EventTime << endl;
      cout << "Time at Point left: " << time_left << endl;
      cout << "Time at Point right: " << time_right << endl;
    }

  //determined system at t_e - epsilon
  globalData->timeValue = time_left;
  for (int i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = states_left[i];
    }
  //determined continuous system
  functionODE();
  functionAlgebraics();
  saveall();
  if (sim_result) sim_result->emit();

  //determined system at t_e + epsilon
  globalData->timeValue = time_right;
  for (int i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = states_right[i];
    }

  delete[] states_left;
  delete[] states_right;

}

//
// Method to find root in Intervall[oldTime,timeValue]
//
double
BiSection(double* a, double* b, double* states_a, double* states_b,
    list<int> *tmpEventList)
{

  //double TTOL =  DBL_EPSILON*fabs(2*b-a)*100;
  double TTOL = 1e-6;
  double c;
  int right = 0;

  double *backup_gout = new double[globalData->nZeroCrossing];
  for (int i = 0; i < globalData->nZeroCrossing; i++)
    {
      backup_gout[i] = gout[i];
    }
  if (sim_verbose >= LOG_ZEROCROSSINGS)
    {
      cout << "Check interval [" << *a << "," << *b << "]" << endl;
      cout << "TTOL is set to: " << TTOL << endl;
    }

  while (fabs(*b - *a) > TTOL)
    {

      c = (*a + *b) / 2.0;
      globalData->timeValue = c;

      //if (sim_verbose >= LOG_ZEROCROSSINGS){
      //  cout << "Split interval at point : " << c << endl;
      //}

      //calculates states at time c
      for (int i = 0; i < globalData->nStates; i++)
        {
          globalData->states[i] = (states_a[i] + states_b[i]) / 2.0;
        }

      //calculates Values dependents on new states
      functionODE();
      functionAlgebraics();

      function_onlyZeroCrossings(gout, &globalData->timeValue);
      if (CheckZeroCrossings(tmpEventList))
        { //If Zerocrossing in left Section

          for (int i = 0; i < globalData->nStates; i++)
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
          //for(int i=0;i<globalData->nZeroCrossing;i++){
          //  backup_gout[i] = gout_old[i];
          //}
          right = 0;

        }
      else
        { //else Zerocrossing in right Section

          for (int i = 0; i < globalData->nStates; i++)
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
          //for(int i=0;i<globalData->nZeroCrossing;i++){
          //  gout_old[i] = gout[i];
          //}
          std::copy(gout, gout + globalData->nZeroCrossing, gout_old);
          std::copy(backup_gout, backup_gout + globalData->nZeroCrossing, gout);
        }
      else
        {

          std::copy(gout, gout + globalData->nZeroCrossing, backup_gout);
          //std::copy(backup_gout, backup_gout + globalData->nZeroCrossing, gout);
          //for(int i=0;i<globalData->nZeroCrossing;i++){
          //  gout_old[i] = gout[i];
          //  gout[i] = backup_gout[i];
          //}
        }
    }

  //  for (long i = 0; i < globalData->nZeroCrossing; i++) {
  //  if (sim_verbose >= LOG_ZEROCROSSINGS){ cout << "check gout_old[" << i << "] = " << gout_old[i] << "\t" <<
  //  "check gout[" << i << "] = " << gout[i] <<
  //  "check gout_backup[" << i << "] = " << backup_gout[i] << endl;
  //  }
  //  }
  delete[] backup_gout;
  c = (*a + *b) / 2.0;
  return c;
}

//
// Check if at least one zerocrossing has change sign
// is used in BiSection
//
int
CheckZeroCrossings(list<int> *tmpEventList)
{

  list<int>::iterator it;
  tmpEventList->clear();
  for ( it=EventList.begin() ; it != EventList.end(); it++ )
    {
      if (sim_verbose >= LOG_ZEROCROSSINGS)
        {
          cout << "ZeroCrossing ID: " << *it << "\t old = " << gout_old[*it]
                                                                        << "\t" << "current = " << gout[(*it)] << "\t" << "Direction: "
                                                                        << zeroCrossingEnabled[(*it)] << endl;
        }
      //Found event in left section
      if ((gout[(*it)] < 0 && gout_old[(*it)] > 0) || (gout[(*it)] > 0 && gout_old[(*it)] < 0)
          || (gout[(*it)] > 0 && zeroCrossingEnabled[(*it)] <= -1) || (gout[(*it)] < 0
              && zeroCrossingEnabled[(*it)] >= 1))
        {
          (*tmpEventList).push_front(*it);
        }
    }
  //Found event in left section
  if (!(*tmpEventList).empty())
    {
      return 1;
    }
  // Else event in right section
  else
    {
      return 0;
    }
}

void
SaveZeroCrossings()
{

  if (sim_verbose >= LOG_ZEROCROSSINGS)
    {
      cout << "Save ZeroCrossings" << endl;
    }
  std::copy(gout, gout + globalData->nZeroCrossing, gout_old);
  function_onlyZeroCrossings(gout, &globalData->timeValue);
}


void
initializeZeroCrossings()
{
  function_onlyZeroCrossings(gout, &globalData->timeValue);
  for (int i = 0; i < globalData->nZeroCrossing; i++)
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
