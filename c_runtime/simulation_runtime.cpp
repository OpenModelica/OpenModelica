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

//#include <iostream>
#include <string>
#include <limits>
#include <list>
#include <math.h>
#include "simulation_runtime.h"
#include "simulation_input.h"
#include "solver_dasrt.h"
#include "solver_euler.h"
#include "options.h"

using namespace std;


/* Global Data */
/***************/

// Becomes non-zero when model terminates simulation.
int modelTermination=0;

long numpoints; // the number of points requested by init file

int sim_verbose; // Flag for logging

int modelErrorCode=0; // set by model calculations. Can be transferred to num. solver.

const std::string *init_method; // method for  initialization.

// this is the globalData that is used in all the functions
DATA *globalData = 0;

/* Flags for controlling logging to stdout */
const int LOG_EVENTS =	1;
const int LOG_NONLIN_SYS = 2;
const int LOG_DEBUG = 4;


/* Flags for modelErrorCodes */ 
extern const int ERROR_NONLINSYS=-1;
extern const int ERROR_LINSYS=-2;

/* \brief returns the next simulation time.
 * 
 * Returns the next simulation time when an output data is requested.
 * \param t is the current time
 * \param step defines the step size between two consecutive result data.
 * \param stop defines the stop time of the simulation, should not be exceeded.
*/
double newTime(double t, double step,double stop)
{ 
	double newTime=(floor( (t+1e-10) / step) + 1.0)*step;
	
	// Do not exceed the stop time.
	if (newTime > stop) {
		newTime = stop;
	}
	return newTime; 
}


/** function storeExtrapolationData
 * author: PA
 * 
 * Stores variables (states, derivatives and algebraic) to be used
 * by e.g. numerical solvers to extrapolate values as start values.
 * 
 * The storing is done in two steps, so the two latest values of a variable can 
 * be retrieved. This function is called in emit().
 */ 
void storeExtrapolationData()
{
	if (globalData->timeValue == globalData->oldTime)
	  return;
	  
	int i;
	for(i=0;i<globalData->nStates;i++) {
		globalData->oldStates2[i]=globalData->oldStates[i];
		globalData->oldStatesDerivatives2[i]=globalData->oldStatesDerivatives[i];	
		globalData->oldStates[i]=globalData->states[i];
		globalData->oldStatesDerivatives[i]=globalData->statesDerivatives[i];	
	}
	for(i=0;i<globalData->nAlgebraic;i++) {
		globalData->oldAlgebraics2[i]=globalData->oldAlgebraics[i];
		globalData->oldAlgebraics[i]=globalData->algebraics[i];
	}
	globalData->oldTime2 = globalData->oldTime;
	globalData->oldTime = globalData->timeValue;
}

double old(double* ptr)
{
	int index;
	
	index = (int)(ptr-globalData->states);
	if (index >=0 && index < globalData->nStates) 
		return globalData->oldStates[index];
	index = (int)(ptr-globalData->statesDerivatives);
	if (index >=0 && index < globalData->nStates) 
		return globalData->oldStatesDerivatives[index];
	index = (int)(ptr-globalData->algebraics);
	if (index >=0 && index < globalData->nAlgebraic) 
		return globalData->oldAlgebraics[index];
	return 0.0;
}

double old2(double* ptr)
{
	int index;
	
	index = (int)(ptr-globalData->states);
	if (index >=0 && index < globalData->nStates) 
		return globalData->oldStates2[index];
	index = (int)(ptr-globalData->statesDerivatives);
	if (index >=0 && index < globalData->nStates) 
		return globalData->oldStatesDerivatives2[index];
	index = (int)(ptr-globalData->algebraics);
	if (index >=0 && index < globalData->nAlgebraic) 
		return globalData->oldAlgebraics2[index];
	return 0.0;
}

 /* \brief determine verboselevel by investigating flag -vl=flags 
   * 
   * Flags are or'ed to a returnvalue.
   * Valid flags: LOG_EVENTS, LOG_NONLIN_SYS
   */
int verboseLevel(int argc, char**argv) 
{
	int res = 0;
	const string * flags = getFlagValue("lv",argc,argv);
	
	if (!flags) return res; // no lv flag given.
	
	if (flags->find("LOG_EVENTS",0) != string::npos) {
		res |= LOG_EVENTS; }
	
	if (flags->find("LOG_NONLIN_SYS",0) != string::npos) {
		res |= LOG_NONLIN_SYS; }	
	return res;	
}	  

/* \brief main function for simulator
 * 
 * The arguments for the main function are:
 * -v verbose = debug
 * -vf=flags set verbosity flags
 * -f init_file.txt use input data from init file.
 * -r res.plt write result to file.
 */
 
int main(int argc, char**argv) 
{
   int retVal=-1;
  if (argc == 2 && flagSet("?",argc,argv)) {
    cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler}" << endl;
    exit(0);
  }
  globalData = initializeDataStruc(ALL);
  if( !globalData ){
      std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }
  //this sets the static variable that is in the file with the generated-model functions
  setLocalData(globalData);
  if(globalData->nStates == 0 && globalData->nAlgebraic == 0)
    {
      std::cerr << "No variables in the model." << std::endl;
      return 1;
    }
  /* verbose flag is set : -v */
  sim_verbose = (int)flagSet("v",argc,argv);
  
  int verbose_flags = verboseLevel(argc,argv);
  sim_verbose = verbose_flags ? verbose_flags : sim_verbose;
 
  double start = 0.0;
  double stop = 5.0;
  double stepSize = 0.05;
  long outputSteps = 500;
  double tolerance = 1e-10;
  string method;
  read_input(argc,argv,
             globalData,
             &start,&stop,&stepSize,&outputSteps,&tolerance,&method);
  
  /* the main method identifies which solver to use and then calls 
     respecive solver main function*/
  if (method == "") {
    retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
  } else  if (method == std::string("euler")) {
    retVal = euler_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
  }
  else if (method == std::string("dassl")) {
    retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
  } else {
    cout << "Unrecognized solver: "<< method <<", using dassl." << endl;
    retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);    
  }  
  deInitializeDataStruc(globalData,ALL);
  return retVal;	
}















  


