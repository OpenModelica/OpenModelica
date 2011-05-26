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

#include <string>
#include <limits>
#include <list>
#include <cmath>
#include <iomanip>
#include <ctime>
#include <cstdio>
#include <cstring>
#include <cassert>
#ifndef _MSC_VER
#include <regex.h>
#endif
#include "simulation_runtime.h"
#include "simulation_input.h"
#include "solver_main.h"

#ifdef _OMC_QSS_LIB
#include "solver_qss/solver_qss.h"
#endif

#include "options.h"
#include "linearize.h"
// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
#include "omi_ServiceInterface.h"
#endif
#include "simulation_result_empty.h"
#include "simulation_result_plt.h"
#include "simulation_result_csv.h"
#include "simulation_result_mat.h"
#include "simulation_modelinfo.h"
#include "rtclock.h"

using namespace std;

int interactiveSimulation = 0; //This variable signals if an simulation session is interactive or non-interactive (by default)

/* Global Data */
/***************/
const char* version = "20110520_1120";
// Becomes non-zero when model terminates simulation.
int modelTermination = 0;
int terminationTerminate = 0;
int terminationAssert = 0;
char* terminateMessage = 0;
int warningLevelAssert = 0;
string TermMsg = string("");
omc_fileInfo TermInfo = omc_dummyFileInfo;

int sim_verbose = 0; // Flag for logging
int sim_verboseLevel = 0; // Flag for logging level
int sim_noemit = 0; // Flag for not emitting data
int jac_flag = 0; // Flag usage of jacobian
int num_jac_flag = 0; // Flag usage of numerical jacobian

int acceptedStep = 0; /* Flag for knowning when step is accepted and when solver searches for solution.
 If solver is only searching for a solution, asserts, etc. should not be triggered, causing faulty error messages to be printed
 */

int modelErrorCode = 0; // set by model calculations. Can be transferred to num. solver.

const std::string *init_method = NULL; // method for  initialization.

// this is the globalData that is used in all the functions
DATA *globalData = 0;

// The simulation result
simulation_result *sim_result = NULL;

/* Flags for controlling logging to stdout */
const int LOG_STATS = 1;
const int LOG_INIT = 2;
const int LOG_RES_INIT = 3;
const int LOG_SOLVER = 4;
const int LOG_NONLIN_SYS = 8;
const int LOG_EVENTS = 16;
const int LOG_ZEROCROSSINGS = 32;
const int LOG_DEBUG = 64;

/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS = -1;
extern const int ERROR_LINSYS = -2;

int
startInteractiveSimulation(int, char**);
int
startNonInteractiveSimulation(int, char**);
int
initRuntimeAndSimulation(int, char**);
/* \brief returns the next simulation time.
 *
 * Returns the next simulation time when an output data is requested.
 * \param t is the current time
 * \param step defines the step size between two consecutive result data.
 * \param stop defines the stop time of the simulation, should not be exceeded.
 */
double
newTime(double t, double step, double stop)
{
  const double maxSolverStep = 0.001;
  double newTime;
  if (step > maxSolverStep)
    { /* Prevent solver from taking larger step than maxSolverStep
     NOTE: DASSL run into problems if the stepsize (TOUT-T) is too large, since it internally keeps track
     of number of iterations and explain if it goes over 500.
     */
      /* Take a max step size forward */
      newTime = t + maxSolverStep;

      /* If output interval point reached, choose that time instead. */
      if (newTime - (globalData->lastEmittedTime + step) >= -1e-10)
        {
          newTime = globalData->lastEmittedTime + step;
          globalData->lastEmittedTime = newTime;
          globalData->forceEmit = 1;
        }
    }
  else
    {
      newTime = (floor((t + 1e-10) / step) + 1.0) * step;
      globalData->lastEmittedTime = newTime;
      globalData->forceEmit = 1;
    }

  // Small gain taking hints from the scheduled sample events. Needs to be done better.
  //while (globalData->curSampleTimeIx < globalData->nSampleTimes && globalData->sampleTimes[globalData->curSampleTimeIx] < t)
  //  globalData->curSampleTimeIx++;
  //if (globalData->curSampleTimeIx && globalData->curSampleTimeIx < globalData->nSampleTimes && newTime > globalData->sampleTimes[globalData->curSampleTimeIx]) {
  //  newTime = globalData->sampleTimes[globalData->curSampleTimeIx++] + 1e-15;
  //}
  // Do not exceed the stop time.
  if (newTime > stop)
    {
      newTime = stop;
    }
  globalData->current_stepsize = newTime - t;
  return newTime;
}

void setTermMsg(const char *msg)
{
  TermMsg = msg;
}

/** function storeExtrapolationData
 * author: PA
 *
 * Stores variables (states, derivatives and algebraic) to be used
 * by e.g. numerical solvers to extrapolate values as start values.
 *
 *
 * The storing is done in two steps, so the two latest values of a variable can
 * be retrieved. This function is called in emit().
 */
void
storeExtrapolationData()
{
  if (globalData->timeValue == globalData->oldTime && globalData->init != 1)
    return;

  int i;
  for (i = 0; i < globalData->nStates; i++)
    {
      globalData->states_old2[i] = globalData->states_old[i];
      globalData->statesDerivatives_old2[i]
                                         = globalData->statesDerivatives_old[i];
      globalData->states_old[i] = globalData->states[i];
      globalData->statesDerivatives_old[i] = globalData->statesDerivatives[i];
    }
  for (i = 0; i < globalData->nAlgebraic; i++)
    {
      globalData->algebraics_old2[i] = globalData->algebraics_old[i];
      globalData->algebraics_old[i] = globalData->algebraics[i];
    }
  for (i = 0; i < globalData->intVariables.nAlgebraic; i++)
    {
      globalData->intVariables.algebraics_old2[i]
                                               = globalData->intVariables.algebraics_old[i];
      globalData->intVariables.algebraics_old[i]
                                              = globalData->intVariables.algebraics[i];
    }
  for (i = 0; i < globalData->boolVariables.nAlgebraic; i++)
    {
      globalData->boolVariables.algebraics_old2[i]
                                                = globalData->boolVariables.algebraics_old[i];
      globalData->boolVariables.algebraics_old[i]
                                               = globalData->boolVariables.algebraics[i];
    }
  globalData->oldTime2 = globalData->oldTime;
  globalData->oldTime = globalData->timeValue;
}

/** function storeExtrapolationDataEvent
 * author: wbraun
 *
 * Stores variables (states, derivatives and algebraic) to be used
 * by e.g. numerical solvers to extrapolate values as start values.
 *
 * This function overwrites all old value with the current.
 * This function is called after events.
 */
void
storeExtrapolationDataEvent()
{
  int i;
  for (i = 0; i < globalData->nStates; i++)
    {
      globalData->states_old2[i] = globalData->states[i];
      globalData->statesDerivatives_old2[i] = globalData->statesDerivatives[i];
      globalData->states_old[i] = globalData->states[i];
      globalData->statesDerivatives_old[i] = globalData->statesDerivatives[i];
    }
  for (i = 0; i < globalData->nAlgebraic; i++)
    {
      globalData->algebraics_old2[i] =  globalData->algebraics[i];
      globalData->algebraics_old[i] = globalData->algebraics[i];
    }
  for (i = 0; i < globalData->intVariables.nAlgebraic; i++)
    {
      globalData->intVariables.algebraics_old2[i] = globalData->intVariables.algebraics[i];
      globalData->intVariables.algebraics_old[i] = globalData->intVariables.algebraics[i];
    }
  for (i = 0; i < globalData->boolVariables.nAlgebraic; i++)
    {
      globalData->boolVariables.algebraics_old2[i] = globalData->boolVariables.algebraics[i];
      globalData->boolVariables.algebraics_old[i] = globalData->boolVariables.algebraics[i];
    }
  globalData->oldTime2 = globalData->timeValue;
  globalData->oldTime = globalData->timeValue;
}

/** function restoreExtrapolationDataOld
 * author: wbraun
 *
 * Restores variables (states, derivatives and algebraic).
 *
 * This function overwrites all variable with old values.
 * This function is called while the initialization to be able
 * initialize all ZeroCrossing relations.
 */
void
restoreExtrapolationDataOld()
{
  int i;
  for (i = 0; i < globalData->nStates; i++)
    {
      globalData->states[i] = globalData->states_old[i];
      globalData->statesDerivatives[i] = globalData->statesDerivatives_old[i];
    }
  for (i = 0; i < globalData->nAlgebraic; i++)
    {
      globalData->algebraics[i] = globalData->algebraics_old[i];
    }
  for (i = 0; i < globalData->intVariables.nAlgebraic; i++)
    {
      globalData->intVariables.algebraics[i] = globalData->intVariables.algebraics_old[i];
    }
  for (i = 0; i < globalData->boolVariables.nAlgebraic; i++)
    {
      globalData->boolVariables.algebraics[i] = globalData->boolVariables.algebraics_old[i];
    }
  globalData->timeValue = globalData->oldTime;
}


/* \brief determine verboselevel by investigating flag -lv=flags
 *
 * Flags are or'ed to a returnvalue.
 * Valid flags: LOG_EVENTS, LOG_NONLIN_SYS
 */
int
verboseLevel(int argc, char**argv)
{
  int res = 0;
  const string * flags = getFlagValue("lv", argc, argv);

  if (!flags)
    return res; // no lv flag given.

  if (flags->find("LOG_STATS", 0) != string::npos)
    {
      res |= LOG_STATS;
    }
  if (flags->find("LOG_INIT", 0) != string::npos)
    {
      res |= LOG_INIT;
    }
  if (flags->find("LOG_RES_INIT", 0) != string::npos)
    {
      res |= LOG_RES_INIT;
    }
  if (flags->find("LOG_SOLVER", 0) != string::npos)
    {
      res |= LOG_SOLVER;
    }
  if (flags->find("LOG_EVENTS", 0) != string::npos)
    {
      res |= LOG_EVENTS;
    }
  if (flags->find("LOG_NONLIN_SYS", 0) != string::npos)
    {
      res |= LOG_NONLIN_SYS;
    }
  if (flags->find("LOG_ZEROCROSSINGS", 0) != string::npos)
    {
      res |= LOG_ZEROCROSSINGS;
    }
  if (flags->find("LOG_DEBUG", 0) != string::npos)
    {
      res |= LOG_DEBUG;
    }
  return res;
}

/**
 * Signals the type of the simulation
 * retuns true for interactive and false for non-interactive
 */
int isInteractiveSimulation()
{
  return interactiveSimulation;
}

/**
 * Starts an Interactive simulation session
 * the runtime waits until a user shuts down the simulation
 */
int
startInteractiveSimulation(int argc, char**argv)
{
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
 * Read the variable filter and mark variables that should not be part of the result file.
 * This phase is skipped for interactive simulations
 */
void initializeOutputFilter(DATA* data, string variableFilter)
{
#ifndef _MSC_VER
  regex_t myregex;
  int flags = REG_EXTENDED;
  int rc;
  string tmp = ("^(" + variableFilter + ")$");
  const char *filter = tmp.c_str(); // C++ strings are horrible to work with...
  if (data->nStates > 0 && 0 == strcmp(data->statesNames[0].name,"$dummy")) {
    data->statesFilterOutput[0] = 1;
    data->statesDerivativesFilterOutput[0] = 1;
  }
  if (0 == strcmp(filter, ".*")) // This matches all variables, so we don't need to do anything
    return;

  rc = regcomp(&myregex, filter, flags);
  if (rc) {
      char err_buf[2048] = {0};
      regerror(rc, &myregex, err_buf, 2048);
      std::cerr << "Failed to compile regular expression: " << filter << " with error: " << err_buf << ". Defaulting to outputting all variables." << std::endl;
      return;
  }
  for (int i = 0; i < data->nStates; i++) if (!data->statesFilterOutput[i])
    data->statesFilterOutput[i] = regexec(&myregex, data->statesNames[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->nStates; i++) if (!data->statesDerivativesFilterOutput[i])
    data->statesDerivativesFilterOutput[i] = regexec(&myregex, data->stateDerivativesNames[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->nAlgebraic; i++) if (!data->algebraicsFilterOutput[i])
    data->algebraicsFilterOutput[i] = regexec(&myregex, data->algebraicsNames[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->nAlias; i++) if (!data->aliasFilterOutput[i])
    data->aliasFilterOutput[i] = regexec(&myregex, data->alias_names[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->intVariables.nAlgebraic; i++) if (!data->intVariables.algebraicsFilterOutput[i])
    data->intVariables.algebraicsFilterOutput[i] = regexec(&myregex, data->int_alg_names[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->intVariables.nAlias; i++) if (!data->intVariables.aliasFilterOutput[i])
    data->intVariables.aliasFilterOutput[i] = regexec(&myregex, data->int_alias_names[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->boolVariables.nAlgebraic; i++) if (!data->boolVariables.algebraicsFilterOutput[i])
    data->boolVariables.algebraicsFilterOutput[i] = regexec(&myregex, data->bool_alg_names[i].name, 0, NULL, 0) != 0;
  for (int i = 0; i < data->boolVariables.nAlias; i++) if (!data->boolVariables.aliasFilterOutput[i])
    data->boolVariables.aliasFilterOutput[i] = regexec(&myregex, data->bool_alias_names[i].name, 0, NULL, 0) != 0;
  regfree(&myregex);
#endif
  return;
}

/**
 * Starts a non-interactive simulation
 */
int
startNonInteractiveSimulation(int argc, char**argv)
{
  int retVal = -1;

  /* linear model option is set : -l <lintime> */
  int create_linearmodel = flagSet("l", argc, argv);
  string* lintime = (string*) getFlagValue("l", argc, argv);

  /* mesure time option is set : -mt */
  if (flagSet("mt", argc, argv)) {
    fprintf(stderr, "Error: The -mt was replaced by the simulate option measureTime, which compiles a simulation more suitable for profiling.\n");
    return 1;
  }

  double start = 0.0;
  double stop = 5.0;
  double stepSize = 0.05;
  long outputSteps = 500;
  double tolerance = 1e-4;
  string method, outputFormat, variableFilter;
  read_input(argc, argv, globalData, &start, &stop, &stepSize, &outputSteps,
      &tolerance, &method, &outputFormat, &variableFilter);
  initializeOutputFilter(globalData,variableFilter);
  callExternalObjectConstructors(globalData);
  globalData->lastEmittedTime = start;
  globalData->forceEmit = 0;

  initSample(start, stop);
  initDelay(start);

  if (measure_time_flag) {
      rt_init(SIM_TIMER_FIRST_FUNCTION + globalData->nFunctions + globalData->nProfileBlocks + 4 /* sentinel */);
      rt_tick( SIM_TIMER_TOTAL );
      rt_tick( SIM_TIMER_PREINIT );
      rt_clear( SIM_TIMER_OUTPUT );
      rt_clear( SIM_TIMER_EVENT );
      rt_clear( SIM_TIMER_INIT );
  }

  if (create_linearmodel) {
      if (lintime == NULL) {
          stop = start;
      } else {
          stop = atof((*lintime).c_str());
      }
      cout << "Linearization will performed at point of time: " << stop << endl;
      method = "dassl";
  }

  int methodflag = flagSet("s", argc, argv);
  if (methodflag) {
    string* solvermethod = (string*) getFlagValue("s", argc, argv);
    if (!(solvermethod == NULL))
      method.assign(*solvermethod);
  }
  
  // Create a result file
  string *result_file = (string*) getFlagValue("r", argc, argv);
  string result_file_cstr;
  if (!result_file) {
      result_file_cstr = string(globalData->modelFilePrefix) + string("_res.") + outputFormat; /* TODO: Fix result file name based on mode */
  } else {
      result_file_cstr = *result_file;
  }

  retVal = callSolver(argc, argv, method, outputFormat, result_file_cstr, start, stop, stepSize,
      outputSteps, tolerance);

  if (retVal == 0 && create_linearmodel) {
      rt_tick(SIM_TIMER_LINEARIZE);
      retVal = linearize();
      rt_accumulate(SIM_TIMER_LINEARIZE);
      cout << "Linear model is created!" << endl;
  }

  if (retVal == 0 && measure_time_flag && ! sim_verbose) {
      const string modelInfo = string(globalData->modelFilePrefix) + "_prof.xml";
      const string plotFile = string(globalData->modelFilePrefix) + "_prof.plt";
      rt_accumulate(SIM_TIMER_TOTAL);
      string* plotFormat = (string*) getFlagValue("measureTimePlotFormat", argc, argv);
      retVal = printModelInfo(globalData, modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat->c_str() : "svg", method.c_str(), outputFormat.c_str(), result_file_cstr.c_str()) && retVal;
  }
  
  deinitDelay();
  deInitializeDataStruc(globalData);

  return retVal;
}

/**
 * Calls the solver which is selected in the parameter string "method"
 * This function is used for interactive and non-interactive simulation
 * Parameter method:
 * "" & "dassl" calls a DASSL Solver
 * "euler" calls an Euler solver
 * "rungekutta" calls a fourth-order Runge-Kutta Solver
 * "dassl" & "dassl2" calls the same DASSL Solver with synchronous event handling
 */
int
callSolver(int argc, char**argv, string method, string outputFormat,
    string result_file_cstr,
    double start, double stop, double stepSize, long outputSteps,
    double tolerance)
{
  int retVal = -1;

  long maxSteps = 2 * outputSteps + 2 * globalData->nSampleTimes;
  if (isInteractiveSimulation() || sim_noemit || 0 == strcmp("empty", outputFormat.c_str())) {
      sim_result = new simulation_result_empty(result_file_cstr.c_str(),maxSteps);
  } else if (0 == strcmp("csv", outputFormat.c_str())) {
      sim_result = new simulation_result_csv(result_file_cstr.c_str(), maxSteps);
  } else if (0 == strcmp("mat", outputFormat.c_str())) {
      sim_result = new simulation_result_mat(result_file_cstr.c_str(), start, stop);
  } else if (0 == strcmp("plt", outputFormat.c_str())) {
      sim_result = new simulation_result_plt(result_file_cstr.c_str(), maxSteps);
  } else {
      cerr << "Unknown output format: " << outputFormat << endl;
      return 1;
  }
  if (sim_verbose >= LOG_SOLVER) {
      cout << "Allocated simulation result data storage for method '"
          << sim_result->result_type() << "' and file='" << result_file_cstr
          << "'" << endl;
  }

  if (method == std::string("")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "No solver is set, using dassl." << endl;
      }
      retVal = solver_main(argc,argv,start,stop,stepSize,outputSteps,tolerance,3);
  } else if (method == std::string("euler")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
      }
      retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 1);
  } else if (method == std::string("rungekutta")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
      }
      retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 2);
  } else if (method == std::string("dassl") || method == std::string("dassl2")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
      }
      retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("dassljac")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
      }
      jac_flag = 1;
      retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("dasslnum")) {
      if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
      }
      num_jac_flag = 1;
      retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("inline-euler")) {
      if (!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-euler")) {
          cout << "Recognized solver: " << method
              << ", but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_EULER."
              << endl;
          retVal = 1;
      } else {
          if (sim_verbose >= LOG_SOLVER) {
              cout << "Recognized solver: " << method << "." << endl;
          }
          retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 4);
      }
  } else if (method == std::string("inline-rungekutta")) {
      if (!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-rungekutta")) {
          cout << "Recognized solver: " << method
              << ", but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_RK."
              << endl;
          retVal = 1;
      } else {
          if (sim_verbose >= LOG_SOLVER) {
              cout << "Recognized solver: " << method << "." << endl;
          }
          retVal = solver_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 4);
      }
#ifdef _OMC_QSS_LIB
      } else if (method == std::string("qss")) {
        if (sim_verbose >= LOG_SOLVER) {
          cout << "Recognized solver: " << method << "." << endl;
        }
        retVal = qss_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 3);
#endif
    } else {
      cout << "Unrecognized solver: " << method
          << "; valid solvers are dassl,euler,rungekutta,dassl2,inline-euler or inline-rungekutta."
          << endl;
      retVal = 1;
  }

  delete sim_result;

  return retVal;
}


static DATA *initializeDataStruc2(DATA *returnData)
{
  if (returnData->nStates) {
    returnData->states = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nStates);
    returnData->states_old = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->states_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->states&&returnData->states_old&&returnData->states_old2);
    memset(returnData->states,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesFilterOutput,0,sizeof(modelica_boolean)*returnData->nStates);
    memset(returnData->states_old,0,sizeof(double)*returnData->nStates);
    memset(returnData->states_old2,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->states = 0;
    returnData->statesFilterOutput = 0;
    returnData->states_old = 0;
    returnData->states_old2 = 0;
  }

  if (returnData->nStates) {
    returnData->statesDerivatives = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivativesFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nStates);
    returnData->statesDerivatives_old = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivatives_old2 = (double*) malloc(sizeof(double)*returnData->nStates);
    returnData->statesDerivativesBackup = (double*) malloc(sizeof(double)*returnData->nStates);
    assert(returnData->statesDerivatives&&returnData->statesDerivatives_old&&returnData->statesDerivatives_old2&&returnData->statesDerivativesBackup);
    memset(returnData->statesDerivatives,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivativesFilterOutput,0,sizeof(modelica_boolean)*returnData->nStates);
    memset(returnData->statesDerivatives_old,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivatives_old2,0,sizeof(double)*returnData->nStates);
    memset(returnData->statesDerivativesBackup,0,sizeof(double)*returnData->nStates);
  } else {
    returnData->statesDerivatives = 0;
    returnData->statesDerivativesFilterOutput = 0;
    returnData->statesDerivatives_old = 0;
    returnData->statesDerivatives_old2 = 0;
    returnData->statesDerivativesBackup = 0;
  }

  if (returnData->nHelpVars) {
    returnData->helpVars = (double*) malloc(sizeof(double)*returnData->nHelpVars);
    assert(returnData->helpVars);
    memset(returnData->helpVars,0,sizeof(double)*returnData->nHelpVars);
  } else {
    returnData->helpVars = 0;
  }

  if (returnData->nAlgebraic) {
    returnData->algebraics = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nAlgebraic);
    returnData->algebraics_old = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    returnData->algebraics_old2 = (double*) malloc(sizeof(double)*returnData->nAlgebraic);
    assert(returnData->algebraics&&returnData->algebraics_old&&returnData->algebraics_old2);
    memset(returnData->algebraics,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->nAlgebraic);
    memset(returnData->algebraics_old,0,sizeof(double)*returnData->nAlgebraic);
    memset(returnData->algebraics_old2,0,sizeof(double)*returnData->nAlgebraic);
  } else {
    returnData->algebraics = 0;
    returnData->algebraicsFilterOutput = 0;
    returnData->algebraics_old = 0;
    returnData->algebraics_old2 = 0;
  }

  if (returnData->stringVariables.nAlgebraic) {
    returnData->stringVariables.algebraics = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nAlgebraic);
    assert(returnData->stringVariables.algebraics);
    memset(returnData->stringVariables.algebraics,0,sizeof(char*)*returnData->stringVariables.nAlgebraic);
  } else {
    returnData->stringVariables.algebraics=0;
  }
  
  if (returnData->intVariables.nAlgebraic) {
    returnData->intVariables.algebraics = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraics_old = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    returnData->intVariables.algebraics_old2 = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    assert(returnData->intVariables.algebraics&&returnData->intVariables.algebraics_old&&returnData->intVariables.algebraics_old2);
    memset(returnData->intVariables.algebraics,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraics_old,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
    memset(returnData->intVariables.algebraics_old2,0,sizeof(modelica_integer)*returnData->intVariables.nAlgebraic);
  } else {
    returnData->intVariables.algebraics=0;
    returnData->intVariables.algebraicsFilterOutput=0;
    returnData->intVariables.algebraics_old = 0;
    returnData->intVariables.algebraics_old2 = 0;
  }

  if (returnData->boolVariables.nAlgebraic) {
    returnData->boolVariables.algebraics = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraicsFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraics_old = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    returnData->boolVariables.algebraics_old2 = (signed char*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    assert(returnData->boolVariables.algebraics&&returnData->boolVariables.algebraics_old&&returnData->boolVariables.algebraics_old2);
    memset(returnData->boolVariables.algebraics,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraicsFilterOutput,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraics_old,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
    memset(returnData->boolVariables.algebraics_old2,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlgebraic);
  } else {
    returnData->boolVariables.algebraics=0;
    returnData->boolVariables.algebraicsFilterOutput=0;
    returnData->boolVariables.algebraics_old = 0;
    returnData->boolVariables.algebraics_old2 = 0;
  }
  
  if (returnData->nParameters) {
    returnData->parameters = (double*) malloc(sizeof(double)*returnData->nParameters);
    assert(returnData->parameters);
    memset(returnData->parameters,0,sizeof(double)*returnData->nParameters);
  } else {
    returnData->parameters = 0;
  }

  if (returnData->stringVariables.nParameters) {
    returnData->stringVariables.parameters = (const char**)malloc(sizeof(char*)*returnData->stringVariables.nParameters);
      assert(returnData->stringVariables.parameters);
      memset(returnData->stringVariables.parameters,0,sizeof(char*)*returnData->stringVariables.nParameters);
  } else {
      returnData->stringVariables.parameters=0;
  }
  
  if (returnData->intVariables.nParameters) {
    returnData->intVariables.parameters = (modelica_integer*)malloc(sizeof(modelica_integer)*returnData->intVariables.nParameters);
      assert(returnData->intVariables.parameters);
      memset(returnData->intVariables.parameters,0,sizeof(modelica_integer)*returnData->intVariables.nParameters);
  } else {
      returnData->intVariables.parameters=0;
  }
  
  if (returnData->boolVariables.nParameters) {
    returnData->boolVariables.parameters = (modelica_boolean*)malloc(sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
      assert(returnData->boolVariables.parameters);
      memset(returnData->boolVariables.parameters,0,sizeof(modelica_boolean)*returnData->boolVariables.nParameters);
  } else {
      returnData->boolVariables.parameters=0;
  }
  
  if (returnData->nOutputVars) {
    returnData->outputVars = (double*) malloc(sizeof(double)*returnData->nOutputVars);
    assert(returnData->outputVars);
    memset(returnData->outputVars,0,sizeof(double)*returnData->nOutputVars);
  } else {
    returnData->outputVars = 0;
  }

  if (returnData->nInputVars) {
    returnData->inputVars = (double*) malloc(sizeof(double)*returnData->nInputVars);
    assert(returnData->inputVars);
    memset(returnData->inputVars,0,sizeof(double)*returnData->nInputVars);
  } else {
    returnData->inputVars = 0;
  }

  if (returnData->nAlias) {
    returnData->realAlias = (DATA_REAL_ALIAS*) malloc(sizeof(DATA_REAL_ALIAS)*returnData->nAlias);
    assert(returnData->realAlias);
    returnData->aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->nAlias);
    assert(returnData->aliasFilterOutput);
    memset(returnData->realAlias,0,sizeof(DATA_REAL_ALIAS)*returnData->nAlias);
    memset(returnData->aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->nAlias);
  } else {
    returnData->realAlias = 0;
    returnData->aliasFilterOutput = 0;
  }

  if (returnData->intVariables.nAlias) {
    returnData->intVariables.alias = (DATA_INT_ALIAS*) malloc(sizeof(DATA_INT_ALIAS)*returnData->intVariables.nAlias);
    assert(returnData->intVariables.alias);
    returnData->intVariables.aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->intVariables.nAlias);
    assert(returnData->intVariables.aliasFilterOutput);
    memset(returnData->intVariables.alias,0,sizeof(DATA_INT_ALIAS)*returnData->intVariables.nAlias);
    memset(returnData->intVariables.aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->intVariables.nAlias);
  } else {
    returnData->intVariables.alias = 0;
    returnData->intVariables.aliasFilterOutput=0;
  }

  if (returnData->boolVariables.nAlias) {
    returnData->boolVariables.alias = (DATA_BOOL_ALIAS*) malloc(sizeof(DATA_BOOL_ALIAS)*returnData->boolVariables.nAlias);
    assert(returnData->boolVariables.alias);
    returnData->boolVariables.aliasFilterOutput = (modelica_boolean*) malloc(sizeof(modelica_boolean)*returnData->boolVariables.nAlias);
    assert(returnData->boolVariables.aliasFilterOutput);
    memset(returnData->boolVariables.alias,0,sizeof(DATA_BOOL_ALIAS)*returnData->boolVariables.nAlias);
    memset(returnData->boolVariables.aliasFilterOutput,0,sizeof(modelica_boolean)*returnData->boolVariables.nAlias);
  } else {
    returnData->boolVariables.alias = 0;
    returnData->boolVariables.aliasFilterOutput=0;
  }

  if (returnData->stringVariables.nAlias) {
    returnData->stringVariables.alias = (DATA_STRING_ALIAS*) malloc(sizeof(DATA_STRING_ALIAS)*returnData->stringVariables.nAlias);
    assert(returnData->stringVariables.alias);
    memset(returnData->stringVariables.alias,0,sizeof(DATA_STRING_ALIAS)*returnData->stringVariables.nAlias);
  } else {
    returnData->stringVariables.alias = 0;
  }
    
  if (returnData->nJacobianvars) {
    returnData->jacobianVars = (double*) malloc(sizeof(double)*returnData->nJacobianvars);
    assert(returnData->jacobianVars);
    memset(returnData->jacobianVars,0,sizeof(double)*returnData->nJacobianvars);
  } else {
    returnData->jacobianVars = 0;
  }

  if (returnData->nInitialResiduals) {
    returnData->initialResiduals = (double*) malloc(sizeof(double)*returnData->nInitialResiduals);
    assert(returnData->initialResiduals);
    memset(returnData->initialResiduals,0,sizeof(double)*returnData->nInitialResiduals);
  } else {
    returnData->initialResiduals = 0;
  }

  if (returnData->nRawSamples) {
    returnData->rawSampleExps = (sample_raw_time*) malloc(sizeof(sample_raw_time)*returnData->nRawSamples);
    assert(returnData->rawSampleExps);
    memset(returnData->rawSampleExps,0,sizeof(sample_raw_time)*returnData->nRawSamples);
  } else {
    returnData->rawSampleExps = 0;
  }
  return returnData;
}

/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int
initRuntimeAndSimulation(int argc, char**argv)
{
  if (flagSet("?", argc, argv) || flagSet("help", argc, argv)) {
      cout << "usage: " << argv[0]
           << " <-f initfile> <-r result file> -m solver:{dassl, dassl2, rungekutta, euler} <-interactive> <-port value> "
           << "-lv [LOG_STATS] [LOG_INIT] [LOG_RES_INIT] [LOG_SOLVER] [LOG_EVENTS] [LOG_NONLIN_SYS] [LOG_ZEROCROSSINGS] [LOG_DEBUG]"
           << endl;
      EXIT(0);
  }
  globalData = initializeDataStruc2(initializeDataStruc());
 
  if (!globalData) {
      std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }
  //this sets the static variable that is in the file with the generated-model functions
  setLocalData(globalData);
  if (globalData->nStates == 0 && globalData->nAlgebraic == 0) {
      std::cerr << "No variables in the model." << std::endl;
      return 1;
  }
  /* verbose flag is set : -v */
  sim_verbose = flagSet("v", argc, argv);
  sim_noemit = flagSet("noemit", argc, argv);
  jac_flag = flagSet("jac", argc, argv);
  num_jac_flag = flagSet("numjac", argc, argv);


  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
  interactiveSimulation = flagSet("interactive", argc, argv);

  if (interactiveSimulation && flagSet("port", argc, argv)) {
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
  if (sim_verbose)
    measure_time_flag = 1;

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

#ifndef _OMC_QSS_LIB
int
main(int argc, char**argv)
{
  int retVal = -1;
  
  if (initRuntimeAndSimulation(argc, argv)) //initRuntimeAndSimulation returns 1 if an error occurs
    return 1;

  if (interactiveSimulation) {
    cout << "startInteractiveSimulation: " << version << endl;
    retVal = startInteractiveSimulation(argc, argv);
  } else {
    // cout << "startNonInteractiveSimulation: " << version << endl;
    retVal = startNonInteractiveSimulation(argc, argv);
  }

  deInitializeDataStruc(globalData);
  free(globalData);
  fflush(NULL);
  EXIT(retVal);
}
#endif 
