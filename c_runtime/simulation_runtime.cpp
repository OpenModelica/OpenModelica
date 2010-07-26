/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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
 * from Link�pings University, either from the above address,
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

#include <string>
#include <limits>
#include <list>
#include <cmath>
#include <iomanip>
#include <ctime>
#include <cstdio>
#include <cstring>
#include "simulation_runtime.h"
#include "simulation_input.h"
#include "solver_dasrt.h"
#include "solver_main.h"
#include "options.h"
// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
#include "omi_ServiceInterface.h"
#endif
#include "simulation_result_bin.h"
#include "simulation_result_empty.h"
#include "simulation_result_plt.h"
#include "simulation_result_csv.h"
#include "simulation_result_mat.h"

using namespace std;

bool interactiveSimuation = false; //This variable signals if an simulation session is interactive or non-interactive (by default)

/* Global Data */
/***************/
const char* version = "20100629";
// Becomes non-zero when model terminates simulation.
int modelTermination=0;

int sim_verbose; // Flag for logging
int sim_noemit; // Flag for not emitting data

int acceptedStep=0; /* Flag for knowning when step is accepted and when solver searches for solution.
If solver is only searching for a solution, asserts, etc. should not be triggered, causing faulty error messages to be printed
*/

int modelErrorCode=0; // set by model calculations. Can be transferred to num. solver.

const std::string *init_method; // method for  initialization.

// this is the globalData that is used in all the functions
DATA *globalData = 0;

// The simulation result
simulation_result *sim_result;

/* Flags for controlling logging to stdout */
const int LOG_EVENTS =  1;
const int LOG_NONLIN_SYS = 2;
const int LOG_DEBUG = 4;


/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS=-1;
extern const int ERROR_LINSYS=-2;

int startInteractiveSimulation(int , char**);
int startNonInteractiveSimulation(int , char**);
int initRuntimeAndSimulation(int , char**);
/* \brief returns the next simulation time.
 *
 * Returns the next simulation time when an output data is requested.
 * \param t is the current time
 * \param step defines the step size between two consecutive result data.
 * \param stop defines the stop time of the simulation, should not be exceeded.
*/
double newTime(double t, double step, double stop)
{
  const double maxSolverStep=0.001;
  double newTime;
  if (step > maxSolverStep) { /* Prevent solver from taking larger step than maxSolverStep
  NOTE: DASSL run into problems if the stepsize (TOUT-T) is too large, since it internally keeps track
  of number of iterations and explain if it goes over 500.
   */
    /* Take a max step size forward */
    newTime=t+maxSolverStep;

    /* If output interval point reached, choose that time instead. */
    if (newTime - (globalData->lastEmittedTime+step) >= -1e-10) {
      newTime = globalData->lastEmittedTime+step;
      globalData->lastEmittedTime = newTime;
      globalData->forceEmit = 1;
    }
  } else {
   newTime=(floor( (t+1e-10) / step) + 1.0)*step;
     globalData->lastEmittedTime = newTime;
   globalData->forceEmit = 1;
  }

  // Small gain taking hints from the scheduled sample events. Needs to be done better.
  while (globalData->curSampleTimeIx < globalData->nSampleTimes && globalData->sampleTimes[globalData->curSampleTimeIx] < t)
    globalData->curSampleTimeIx++;
  if (globalData->curSampleTimeIx && globalData->curSampleTimeIx < globalData->nSampleTimes && newTime > globalData->sampleTimes[globalData->curSampleTimeIx]) {
    newTime = globalData->sampleTimes[globalData->curSampleTimeIx++] + 1e-15;
  } 
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
  if (globalData->timeValue == globalData->oldTime && globalData->init!=1)
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

 /* \brief determine verboselevel by investigating flag -lv=flags
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

/**
 * Signals the type of the simulation
 * retuns true for interactive and false for non-interactive
 */
bool isInteractiveSimulation(){
  return interactiveSimuation;
}

/**
 * Starts an Interactive simulation session
 * the runtime waits until a user shuts down the simulation
 */
int startInteractiveSimulation(int argc, char**argv) {
  int retVal = -1;

// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY 
  initServiceInterfaceData(argc, argv);

  //Create the Control Server Thread
  Thread *threadSimulationControl = createControlThread();
  threadSimulationControl->Join();
  delete threadSimulationControl;

  std::cout << "simulation finished!" << std::endl;
#else
	std::cout << "Interactive Simulation not supported when LEAST_DEPENDENCY is defined!!!" << std::endl;
#endif
  return retVal; //TODO 20100211 pv return value implementation / error handling
}

/**
 * Starts a non-interactive simulation
 */
int startNonInteractiveSimulation(int argc, char**argv){
  int retVal = -1;

      /* mesure time option is set : -mt */
  int measure_time_flag = (int)flagSet("mt",argc,argv);
  double measure_start_time = 0;

  double start = 0.0;
  double stop = 5.0;
  double stepSize = 0.05;
  long outputSteps = 500;
  double tolerance = 1e-4;
  string method,outputFormat;
  read_input(argc,argv,
             globalData,
             &start,&stop,&stepSize,&outputSteps,&tolerance,&method,&outputFormat);
  callExternalObjectConstructors(globalData);
  globalData->lastEmittedTime = start;
  globalData->forceEmit=0;

  initSample(start);
  initDelay(start);

  if (measure_time_flag)
    measure_start_time = clock();

  retVal = callSolver(argc, argv, method, outputFormat, start, stop, stepSize, outputSteps, tolerance);

  deinitDelay();

  if (measure_time_flag)
     cout << "Time to calculate simulation: "<< (clock()-measure_start_time)/CLOCKS_PER_SEC <<" sec." << endl;
  deInitializeDataStruc(globalData,ALL);

  return retVal;
}

/**
 * Calls the solver which is selected in the parameter string "method"
 * This function is used for interactive and non-interactive simulation
 * Parameter method:
 * "" & "dassl" calls a DASSL Solver
 * "euler" calls an Euler solver
 * "rungekutta" calls a fourth-order Runge-Kutta Solver
 * "dassl2" calls a DASSL Solver with synchronous event handling
 */
int callSolver(int argc, char**argv, string method, string outputFormat, double start, double stop, double stepSize, long outputSteps, double tolerance) {
  int retVal = -1;

  // Create a result file
  string *result_file =(string*)getFlagValue("r",argc,argv);
  string result_file_cstr;
  if (!result_file) {
    result_file_cstr = string(globalData->modelName)+string("_res.")+outputFormat; /* TODO: Fix result file name based on mode */
  } else {
    result_file_cstr = *result_file;
  }
  long maxSteps = 2*outputSteps+2*globalData->nSampleTimes;
  if (isInteractiveSimulation() || sim_noemit || 0 == strcmp("empty",outputFormat.c_str())) {
    sim_result = new simulation_result_empty(result_file_cstr.c_str(),maxSteps);
  } else if (0 == strcmp("csv",outputFormat.c_str())) {
    sim_result = new simulation_result_csv(result_file_cstr.c_str(),maxSteps);
  } else if (0 == strcmp("bin",outputFormat.c_str())) {
    sim_result = new simulation_result_bin(result_file_cstr.c_str(),maxSteps);
  } else if (0 == strcmp("mat",outputFormat.c_str())) {
    sim_result = new simulation_result_mat(result_file_cstr.c_str(),start,stop);
  } else { /* Default to plt */
    sim_result = new simulation_result_plt(result_file_cstr.c_str(),maxSteps);
  }
  if (sim_verbose) { cout << "Allocated simulation result data storage for method '" << sim_result->result_type() << "' and file='" << result_file_cstr << "'" << endl; }

  if (method == "") {
    if (sim_verbose) { cout << "No Recognized solver, using dassl." << endl; }
    retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
  } else  if (method == std::string("euler")) {
    if (sim_verbose) { cout << "Recognized solver: "<< method <<"." << endl; }
    retVal = solver_main(argc,argv,start,stop,stepSize,outputSteps,tolerance,1);
  } else  if (method == std::string("rungekutta")) {
    if (sim_verbose) { cout << "Recognized solver: "<< method <<"." << endl; }
    retVal = solver_main(argc,argv,start,stop,stepSize,outputSteps,tolerance,2);
  } else  if (method == std::string("dassl2")) {
    if (sim_verbose) { cout << "Recognized solver: "<< method <<"." << endl; }
    retVal = solver_main(argc,argv,start,stop,stepSize,outputSteps,tolerance,3);
  } else if (method == std::string("dassl")) {
    if (sim_verbose) { cout << "Recognized solver: "<< method <<"." << endl; }
    retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
 } else {
   if (sim_verbose) {  cout << "Unrecognized solver: "<< method <<", using dassl." << endl; }
   retVal = dassl_main(argc,argv,start,stop,stepSize,outputSteps,tolerance);
  }

  delete sim_result;
  
  return retVal;
}

/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int initRuntimeAndSimulation(int argc, char**argv) {

  if (argc == 2 && flagSet("?", argc, argv)) {
        //cout << "usage: " << argv[0]  << " <-f initfile> <-r result file> -m solver:{dassl, euler} -v" << endl;
    cout << "usage: " << argv[0]
        << " <-f initfile> <-r result file> -m solver:{dassl, dassl2, rungekutta, euler} -v <-interactive> <-port value>"
        << endl;
    EXIT(0);
  }
  globalData = initializeDataStruc(ALL);
  if (!globalData) {
    std::cerr
        << "Error: Could not initialize the global data structure file"
        << std::endl;
  }
  //this sets the static variable that is in the file with the generated-model functions
  setLocalData(globalData);
  if (globalData->nStates == 0 && globalData->nAlgebraic == 0) {
    std::cerr << "No variables in the model." << std::endl;
    return 1;
  }
  /* verbose flag is set : -v */
  sim_verbose = (int) flagSet("v", argc, argv);
  sim_noemit = (int) flagSet("noemit", argc, argv);

// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
  interactiveSimuation = flagSet("interactive", argc, argv);

  if (interactiveSimuation && flagSet("port", argc, argv)) {
    cout << "userPort" << endl;
    string *portvalue = (string*) getFlagValue("port", argc, argv);
    std::istringstream stream(*portvalue);
    int userPort;
    stream >> userPort;
    setPortOfControlServer(userPort);
  }
#endif
  int verbose_flags = verboseLevel(argc, argv);
  sim_verbose = verbose_flags ? verbose_flags : sim_verbose;
  //sim_verbose = 1;

  return 0;
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
  int retVal = -1;

  if(initRuntimeAndSimulation(argc, argv)) //initRuntimeAndSimulation returns 1 if an error occurs
    return 1;

  if(interactiveSimuation){
    //cout << "startInteractiveSimulation: " << version << endl;
    retVal = startInteractiveSimulation(argc, argv);
  } else{
    //cout << "startNonInteractiveSimulation: " << version << endl;
    retVal = startNonInteractiveSimulation(argc, argv);
  }

  deInitializeDataStruc(globalData, ALL);
  free(globalData);
  fflush(NULL);
  EXIT(retVal);
}
