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
#include <string.h> // adrpo - 2006-12-05 -> for memset
#include <list>
using namespace std;

// vectors with saved values used by pre(v)
double* h_saved = 0;
double* x_saved = 0;
double* xd_saved = 0;
double* y_saved = 0;

double* gout = 0;
long* zeroCrossingEnabled = 0;
long inUpdate = 0;
long inSample = 0;

static list<long> EventQueue;

/* \brief allocate global data structures for event handling
 *
 * \return zero if successful.
 */
int initializeEventData() {
  // load default initial values.
  gout = new double[globalData->nZeroCrossing];
  h_saved = new double[globalData->nHelpVars];
  x_saved = new double[globalData->nStates];
  xd_saved = new double[globalData->nStates];
  y_saved = new double[globalData->nAlgebraic];
  zeroCrossingEnabled = new long[globalData->nZeroCrossing];
  if (!y_saved || !gout || !h_saved || !x_saved || !xd_saved
      || !zeroCrossingEnabled) {
    cerr << "Could not allocate memory for global event data structures"
        << endl;
    return -1;
  }
  // adrpo 2006-11-30 -> init the damn structures!
  memset(gout, 0, sizeof(double) * globalData->nZeroCrossing);
  memset(h_saved, 0, sizeof(double) * globalData->nHelpVars);
  memset(x_saved, 0, sizeof(double) * globalData->nStates);
  memset(xd_saved, 0, sizeof(double) * globalData->nStates);
  memset(y_saved, 0, sizeof(double) * globalData->nAlgebraic);
  memset(zeroCrossingEnabled, 0, sizeof(long) * globalData->nZeroCrossing);
  return 0;
}

/* \brief deallocate global data for event handling.
 *
 */
void deinitializeEventData() {
  delete[] h_saved;
  delete[] x_saved;
  delete[] xd_saved;
  delete[] y_saved;
  delete[] gout;
  delete[] zeroCrossingEnabled;
}

/* \brief
 *
 * Checks for events during initialization.
 *
 * Some solvers(e.g. DASSRT )can not handle events at exaclty the start time.
 * For instance der(x)=1, b = x>0 simulated from 0 .. x will miss the event.
 * The zeroCrossingEnabled vector is used to prevent DASSRT from checking the event above since it occur
 * at start time for the solver.
 *
 * This function checks such initial events and calls the event handling for this. The function is called after the first
 * step is taken by DASSRT (a small tiny step just to check these events)
 * */
void checkForInitialZeroCrossings(fortran_integer* jroot) {
  int i;
  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings" << endl;
  }
  // enable only those that were disabled at init time.
  for (i = 0; i < globalData->nZeroCrossing; i++) {
    if (zeroCrossingEnabled[i] == 0) {
      zeroCrossingEnabled[i] = 1;
    } else {
      zeroCrossingEnabled[i] = 0;
    }
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);

  for (i = 0; i < globalData->nZeroCrossing; i++) {
    if (zeroCrossingEnabled[i] && gout[i]) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
  emit();
  CheckForNewEvents(&globalData->timeValue);
  StartEventIteration(&globalData->timeValue);

  saveall();
  calcEnabledZeroCrossings();
  if (sim_verbose) {
    cout << "checkForIntialZeroCrossings done." << endl;
  }
}

/* This function is similar to CheckForNewEvents except that is called during initialization.
 *
 */

void CheckForInitialEvents(double *t) {
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  if (sim_verbose) {
    cout << "Check for initial events." << endl;
  }
  // if discrete variable not in when equation has changed, saveall and  solve equations again.
  while (checkForDiscreteVarChanges()) {
    saveall();
    function_updateDependents();
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
    if (sim_verbose)
      printf("gout[%ld]=%f\n", i, gout[i]);
    if (gout[i] < 0 || zeroCrossingEnabled[i] == 0) { // check also zero crossings that are on zero.
      if (sim_verbose) {
        cout << "adding event " << i << " at initialization" << endl;
      }
      AddEvent(i);
    }
  }
}

void CheckForNewEvents(double *t) {
  //	int discVarChange=0;
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  // if discrete variable not in when equation has changed, saveall and solve equations again.
  /*
   while(checkForDiscreteVarChanges()) {
   discVarChange=1;
   saveall();
   function_updateDependents();
   }

   if(!discVarChange) function_updateDependents();
   */

  if (checkForDiscreteVarChanges()) {
    AddEvent(-1);
  }

  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
    if (gout[i] < 0) {
      AddEvent(i);
    }
  }
}

void AddEvent(long index) {
  list<long>::iterator i;
  for (i = EventQueue.begin(); i != EventQueue.end(); i++) {
    if (*i == index)
      return;
  }
  EventQueue.push_back(index);
  //cout << "Adding Event:" << index << " queue length:" << EventQueue.size() << endl;
}

bool ExecuteNextEvent(double *t) {
  if (sim_verbose) {
    cout << "Events in the queue:";
    for (list<long>::const_iterator it = EventQueue.begin(); it
        != EventQueue.end(); ++it) {
      cout << *it << ", ";
    }
    cout << endl;
  }
  if (EventQueue.begin() != EventQueue.end()) {
    long nextEvent = EventQueue.front();
    if (sim_verbose) {
      printf("Executing event id:%ld\n", nextEvent);
    }
    if (nextEvent >= globalData->nZeroCrossing) {
      globalData->timeValue = *t;
      function_when(nextEvent - globalData->nZeroCrossing);
    } else if (nextEvent >= 0) {
      globalData->timeValue = *t;
      handleZeroCrossing(nextEvent);
      function_updateDependents();
      functionDAE_output();
    }
    function_updateDependents();
    //emit();
    EventQueue.pop_front();
    return true;
  }
  return false;
}

void StartEventIteration(double *t) {
  while (EventQueue.begin() != EventQueue.end()) {
    calcEnabledZeroCrossings();
    while (ExecuteNextEvent(t)) {
    }
    inSample = 0;
    //    for (long i = 0; i < globalData->nHelpVars; i++) save(globalData->helpVars[i]);
    saveall();
    globalData->timeValue = *t;
    function_updateDependents();
    CheckForNewEvents(t);
  }
  for (long i = 0; i < globalData->nHelpVars; i++) {
    //  	globalData->helpVars[i] = 0;
    //  	save(globalData->helpVars[i]);
  }
  //  cout << "EventIteration done" << endl;
}

void StateEventHandler(fortran_integer* jroot, double *t) {
  inSample = 1;
  for (int i = 0; i < globalData->nZeroCrossing; i++) {
    if (jroot[i]) {
      handleZeroCrossing(i);
      function_updateDependents();
      functionDAE_output();
    }
  }
  //  emit();
}

#if defined(__GNUC__) // for GNUC
// adrpo - 2006-12-05
// for GNUC the inline is a bit more involved
// read here:
// http://gcc.gnu.org/onlinedocs/gcc-3.2.3/gcc/Inline.html
#else /* for other compilers */
inline
#endif
void calcEnabledZeroCrossings() {
  int i;
  for (i = 0; i < globalData->nZeroCrossing; i++) {
    zeroCrossingEnabled[i] = 1;
  }
  function_zeroCrossing(&globalData->nStates, &globalData->timeValue,
      globalData->states, &globalData->nZeroCrossing, gout, 0, 0);
  for (i = 0; i < globalData->nZeroCrossing; i++) {
    if (gout[i] > 0)
      zeroCrossingEnabled[i] = 1;
    else if (gout[i] < 0)
      zeroCrossingEnabled[i] = -1;
    else
      zeroCrossingEnabled[i] = 0;
    // cout << "e[" << i << "]=" << zeroCrossingEnabled[i] << " gout[" << i << "]="<< gout[i]
    //  << " init =" << globalData->init << endl;
  }
}

// relation functions used in zero crossing detection
double Less(double a, double b) {
  return a - b;
}

double LessEq(double a, double b) {
  return a - b;
}

double Greater(double a, double b) {
  return b - a;
}

double GreaterEq(double a, double b) {
  return b - a;
}

double Sample(double t, double start, double interval) {
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
double sample(double start, double interval) {
  // double sloop = 4.0/interval;
  // adrpo: if we test for inSample == 0 no event is generated when start + 0*interval!
  // if (inSample == 0) return 0;
  double tmp = ((globalData->timeValue - start) / interval);
  tmp -= floor(tmp);
  /* adrpo - 2008-01-15
   * comparison was tmp >= 0 fails sometimes on x86 due to extended precision in registers
   * TODO - fix the simulation runtime so that the sample event is generated at EXACTLY that time.
   * below should be: if (tmp >= -0.0001 && tmp < 0.0001) but needs more testing as some models from
   * testsuite fail.
   */
  if (tmp >= -0.0001 && tmp < 0.0001) {
    if (sim_verbose)
      cout << "Calling sample(" << start << ", " << interval << ")\n"
          << "+generating an event at time:" << globalData->timeValue
          << " tmp: " << tmp << endl;
    return 1;
  } else {
    if (sim_verbose)
      cout << "Calling sample(" << start << ", " << interval << ")\n"
          << "-NO an event at time:" << globalData->timeValue << " tmp: "
          << tmp << endl;
    return 0;
  }
}

void saveall() {
  int i;
    for (i = 0; i < globalData->nStates; i++) {
    x_saved[i] = globalData->states[i];
    xd_saved[i] = globalData->statesDerivatives[i];
  }
  for (i = 0; i < globalData->nAlgebraic; i++) {
    y_saved[i] = globalData->algebraics[i];
  }
  for (i = 0; i < globalData->nHelpVars; i++) {
    h_saved[i] = globalData->helpVars[i];
  }
}

/* save(v) saves the previous value of a discrete variable v, which can be accessed
 * using pre(v) in Modelica.
 */

void save(double & var) {
  double* pvar = &var;
  long ind;
  if (sim_verbose) {
    printf("save %s = %f\n", getName(&var), var);
  }
  ind = long(pvar - globalData->helpVars);
  if (ind >= 0 && ind < globalData->nHelpVars) {
    h_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->states);
  if (ind >= 0 && ind < globalData->nStates) {
    x_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->statesDerivatives);
  if (ind >= 0 && ind < globalData->nStates) {
    xd_saved[ind] = var;
    return;
  }
  ind = long(pvar - globalData->algebraics);
  if (ind >= 0 && ind < globalData->nAlgebraic) {
    y_saved[ind] = var;
    return;
  }
  return;
}

double pre(double & var) {
  double* pvar = &var;
  long ind;

  ind = long(pvar - globalData->states);
  if (ind >= 0 && ind < globalData->nStates) {
    return x_saved[ind];
  }
  ind = long(pvar - globalData->statesDerivatives);
  if (ind >= 0 && ind < globalData->nStates) {
    return xd_saved[ind];
  }
  ind = long(pvar - globalData->algebraics);
  if (ind >= 0 && ind < globalData->nAlgebraic) {
    return y_saved[ind];
  }
  ind = long(pvar - globalData->helpVars);
  if (ind >= 0 && ind < globalData->nHelpVars) {
    return h_saved[ind];
  }
  return var;
}
bool edge(double& var) {
  return var && !pre(var);
}

bool change(double& var) {
  return (var && !pre(var)) || (!var && pre(var));
}

/*
 * All event functions from here, are till now only used in Euler  
 * 
*/

//
// This function checks for Events in Intervall=[oldTime,timeValue]
// If a zerocrossing Function cause a sign chage, root finding  
// process will start
//
int CheckForNewEvent(int flag) {
	
	//if (flag != INTERVAL){
	//   while(checkForDiscreteVarChanges()) {
	//	   saveall();
	//	   function_updateDepend();
	//	   if (sim_verbose) cout << "Discrete Var Changed!" << endl;
	//   }
	//}
	
	function_onlyZeroCrossings(gout,&globalData->timeValue);

	for (long i = 0; i < globalData->nZeroCrossing; i++) {
		//if (sim_verbose) cout << "gout[" << i << "] = " << gout[i] << endl;
		if (gout[i] < 0) { // check also zero crossings that are on zero.
			
			if (sim_verbose) {
				cout << "adding event " << i << " at time: "
				<< globalData->timeValue << endl;
			}
			AddEvent(i);
		}
	}
	if (!EventQueue.empty() && flag == INTERVAL){
		FindRoot();
		EventHandle();
		return 2;
	}else if(!EventQueue.empty()){
		EventHandle();
		return 1;
	}	
	return 0;
}

//
// This function handle events and change all 
// needed variables for an event
//
void EventHandle(){
	
	while(!EventQueue.empty()){
		long event_id;
		
		event_id = EventQueue.front(); 
	
		if (sim_verbose) cout << "Handle Event ID: " << event_id << endl;
		if (zeroCrossingEnabled[event_id] == 1){
			zeroCrossingEnabled[event_id] = -1;}
		else if (zeroCrossingEnabled[event_id] == -1){
			zeroCrossingEnabled[event_id] = 1;}
		else{
			zeroCrossingEnabled[event_id] = -1;}
		
		saveall();
		function_updateDepend();
	    saveall();
	    
		EventQueue.pop_front();
	}
	CheckForNewEvent(NOINTERVAL);
}

//
// This function perform a root finding for 
// Intervall=[oldTime,timeValue]
//
void FindRoot(){
	double EventTime = 0;
	
	long int event_id =0;
	
	double *states_right = new double[globalData->nStates];
	double *states_left = new double[globalData->nStates];
	
	double time_left = globalData->oldTime;
	double time_right = globalData->timeValue;

	//write states to work and backup Array
	for(int i=0;i<globalData->nStates;i++){
		states_left[i] = globalData->oldStates[i];
		states_right[i] = globalData->states[i];
	}

	// Search for event time with Bisection method
	EventTime = BiSection(&time_left,&time_right, states_left, states_right, &event_id);
	
	
	if (sim_verbose) {
		cout << "Found event " << event_id << " at time: "<< EventTime << endl;
		cout << "Time at Point left: " << time_left << endl;
		cout << "Time at Point right: " << time_right << endl;
	}
	AddEvent(event_id);
	globalData->timeValue = time_left;
	for(int i=0;i<globalData->nStates;i++){
		globalData->states[i] = states_left[i];
	}
	functionODE();
	functionDAE_output();
	emit();

	globalData->timeValue = time_right;
	for(int i=0;i<globalData->nStates;i++){
		globalData->states[i] = states_right[i];
	}
	
	delete[] states_left;
	delete[] states_right;
	
	EventHandle();
}

// 
// Method to find root in Intervall[oldTime,timeValue]
//
double BiSection(double* a, double* b, double* states_a, double* states_b,long int* event_id )	
{
	
	//double TTOL =  DBL_EPSILON;//*fabs(2*b-a)*100;
	double TTOL = 1e-06;
	if(TOL!=0) TTOL = TOL;
	double c;

	if (sim_verbose){
			cout << "Check Intervall [" << *a << "," << *b << "]" << endl; 
			cout << "TTOL is set to: " << TTOL << endl;
	}
	
	while ( fabs(*b-*a) > TTOL){
		
		c = (*a+*b)/2.0;
		globalData->timeValue = c;
		
		//calculates states at time c 
		for(int i=0;i<globalData->nStates;i++){
			globalData->states[i] = (states_a[i] + states_b[i]) / 2.0; 
		}
		
		//calculates Values dependents on new states 
		functionODE();
		functionDAE_output();
	
		if ( CheckZeroCrossings(event_id)){ //If Zerocrossing in left Section
			
			//if (sim_verbose) cout << "  Search in the left section" << endl;
			for(int i=0;i<globalData->nStates;i++){
				states_b[i] = globalData->states[i];
			}
			*b = c;
		}else{   //If Zerocrossing in right Section
			
			//if (sim_verbose) cout << "\t\tSearch in the right section" << endl;
			for(int i=0;i<globalData->nStates;i++){
				states_a[i] = globalData->states[i];
			}
			*a = c;
		} 
	}
	
	c = (*a+*b)/2.0;
	return c;
}


//
// Check if at least one zerocrossing has change sign
// is used in BiSection
//
int CheckZeroCrossings(long int *eventid) {
  function_onlyZeroCrossings(gout,&globalData->timeValue);
  for (long i = 0; i < globalData->nZeroCrossing; i++) {
	  //if (sim_verbose) cout << "check gout[" << i << "] = " << gout[i] << endl;
	  if (gout[i] < 0) {
		  *eventid = i;
		  return 1;
	  }
  }
  return 0;
}
