/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "simulation_events.h"
#include "simulation_runtime.h"
#include "simulation_result.h"
#include <math.h>
#include <string.h> // adrpo - 2006-12-05 -> for memset
#include <list>
using namespace std;

// vectors with saved values used by pre(v)
double* h_saved  = 0;
double* x_saved  = 0;
double* xd_saved = 0;
double* y_saved  = 0;

double* gout     = 0;
long* zeroCrossingEnabled = 0;
long inUpdate = 0;

static list<long> EventQueue; 

/* \brief allocate global data structures for event handling
 * 
 * \return zero if successful.
 */
int initializeEventData()
{
	 // load default initial values.
  gout = new double[globalData->nZeroCrossing];
  h_saved = new double[globalData->nHelpVars];  
  x_saved = new double[globalData->nStates];
  xd_saved = new double[globalData->nStates];
  y_saved = new double[globalData->nAlgebraic];
  zeroCrossingEnabled = new long[globalData->nZeroCrossing];
  if(!y_saved || !gout || !h_saved || !x_saved || !xd_saved || ! zeroCrossingEnabled){
    cerr << "Could not allocate memory for global event data structures" << endl;
    return -1;
  }
  // adrpo 2006-11-30 -> init the damn structures!
  memset(gout, 0, sizeof(double)*globalData->nZeroCrossing);
  memset(h_saved, 0, sizeof(double)*globalData->nHelpVars);
  memset(x_saved, 0, sizeof(double)*globalData->nStates);
  memset(xd_saved, 0, sizeof(double)*globalData->nStates);
  memset(y_saved, 0, sizeof(double)*globalData->nAlgebraic);
  memset(zeroCrossingEnabled, 0, sizeof(long)*globalData->nZeroCrossing);
  return 0;
}

/* \brief deallocate global data for event handling.
 * 
 */
void deinitializeEventData()
{
  delete [] h_saved;
  delete [] x_saved;
  delete [] xd_saved;
  delete [] y_saved;
  delete [] gout;
  delete [] zeroCrossingEnabled;
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
void checkForInitialZeroCrossings(long*jroot)
{
	int i;
	if (sim_verbose) {
		cout << "checkForIntialZeroCrossings" << endl;
	}
	// enable only those that were disabled at init time.
	for (i=0; i<globalData->nZeroCrossing; i++) {
		if (zeroCrossingEnabled[i]==0) {
			zeroCrossingEnabled[i]=1;
		} else {
			zeroCrossingEnabled[i]=0;
		}
	}
	function_zeroCrossing(&globalData->nStates,&globalData->timeValue,
                        globalData->states,&globalData->nZeroCrossing,gout,0,0);
		
	for(i=0;i<globalData->nZeroCrossing;i++) {
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

void CheckForInitialEvents(double *t)
{
  // Check for changes in discrete variables
  globalData->timeValue = *t;
  if (sim_verbose) { 
  	cout << "Check for initial events." << endl;
  }
  // if discrete variable not in when equation has changed, saveall and  solve equations again.
  while(checkForDiscreteVarChanges()) { 
  	saveall();
  	function_updateDependents(); }
  function_zeroCrossing(&globalData->nStates,
                        &globalData->timeValue,
                        globalData->states,
                        &globalData->nZeroCrossing,gout,0,0);
  for (long i=0;i<globalData->nZeroCrossing;i++) {
  	//printf("gout[%d]=%f\n",i,gout[i]);
    if (gout[i] < 0  || zeroCrossingEnabled[i]==0) { // check also zero crossings that are on zero.
    	if (sim_verbose) {
    		cout << "adding event " << i << " at initialization" << endl;
    		}
       AddEvent(i);
    } 
  }
}


void CheckForNewEvents(double *t)
{
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
  
  function_zeroCrossing(&globalData->nStates,
                        &globalData->timeValue,
                        globalData->states,
                        &globalData->nZeroCrossing,gout,0,0);
  for (long i=0;i<globalData->nZeroCrossing;i++) {
    if (gout[i] < 0) {
       AddEvent(i);
    }
  }
}

void AddEvent(long index)
{
  list<long>::iterator i;
  for (i=EventQueue.begin(); i != EventQueue.end(); i++) {
    if (*i == index)
      return;
  }
  EventQueue.push_back(index);
    //cout << "Adding Event:" << index << " queue length:" << EventQueue.size() << endl;
}
 
bool
ExecuteNextEvent(double *t)
{
  if (EventQueue.begin() != EventQueue.end()) {
    long nextEvent = EventQueue.front();
    if (sim_verbose) { 
		printf("Executing event id:%ld\n",nextEvent);
    }
	if (nextEvent >= globalData->nZeroCrossing) {
      globalData->timeValue = *t;
      function_when(nextEvent-globalData->nZeroCrossing);
    }
    else if (nextEvent >= 0) {
      globalData->timeValue = *t;
      handleZeroCrossing(nextEvent);
      function_updateDependents();
      functionDAE_output();
    }
    function_updateDependents();
    emit();
    EventQueue.pop_front();
    return true;
  }
  return false;
}

void
StartEventIteration(double *t)
{
  while (EventQueue.begin() != EventQueue.end()) {
    calcEnabledZeroCrossings();
    while (ExecuteNextEvent(t)) { }
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

void StateEventHandler(long* jroot, double *t) 
{
  for(int i=0;i<globalData->nZeroCrossing;i++) {
    if (jroot[i] ) {
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
void calcEnabledZeroCrossings()
{
  int i;
  for (i=0;i<globalData->nZeroCrossing;i++) {
    zeroCrossingEnabled[i] = 1;
  }
  function_zeroCrossing(&globalData->nStates,&globalData->timeValue,
                        globalData->states,&globalData->nZeroCrossing,gout,0,0);
  for (i=0;i<globalData->nZeroCrossing;i++) {
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
double Less(double a, double b) 
{
    return a-b;
}

double LessEq(double a, double b) 
{
    return a-b;
}

double Greater(double a, double b) 
{
    return b-a;
}

double GreaterEq(double a, double b) 
{
    return b-a;
}

double Sample(double t, double start ,double interval)
{
  double pipi = atan(1.0)*8.0;
  if (t<(start-interval*.25)) return -1.0;
  return sin(pipi*(t-start)/interval);
}

double sample(double start ,double interval)
{
  //  double sloop = 4.0/interval;
  int count = int((globalData->timeValue - start) / interval);
  if (globalData->timeValue < (start-interval*0.25)) return 0;
  if (( globalData->timeValue-start-count*interval) < 0) return 0;
  if (( globalData->timeValue-start-count*interval) > interval*0.5) return 0;
  return 1;
}

void saveall()
{
  int i;
  for(i=0;i<globalData->nStates; i++) {
    x_saved[i] = globalData->states[i];
    xd_saved[i] = globalData->statesDerivatives[i];
  }
 for(i=0;i<globalData->nAlgebraic; i++) {
    y_saved[i] = globalData->algebraics[i];
  }
  for(i=0;i<globalData->nHelpVars; i++) {
    h_saved[i] = globalData->helpVars[i];
  }
}




/* save(v) saves the previous value of a discrete variable v, which can be accessed 
 * using pre(v) in Modelica.
 */

void save(double & var) 
{
  double* pvar = &var;
  long ind;
  if (sim_verbose) { printf("save %s = %f\n",getName(&var),var);
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

double pre(double & var) 
{
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
bool edge(double& var) 
{
  return var && ! pre(var);
}

bool change(double& var)
{
 return   var && ! pre(var) || !var && pre(var);
}


