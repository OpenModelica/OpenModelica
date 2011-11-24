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

#include "error.h"
#include "simulation_data.h"

#include <setjmp.h>
#include <string>
#include <limits>
#include <list>
#include <cmath>
#include <iomanip>
#include <ctime>
#include <cstdio>
#include <cstring>
#include <cassert>
#include <signal.h>
#ifndef _MSC_VER
#include <regex.h>
#endif
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "solver_main.h"

#ifdef _OMC_QSS_LIB
#include "solver_qss/solver_qss.h"
#endif

#include "options.h"
#include "linearize.h"
// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
#include "../../interactive/omi_ServiceInterface.h"
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
char* TermMsg = 0;
omc_fileInfo TermInfo = omc_dummyFileInfo;

#ifndef NO_INTERACTIVE_DEPENDENCY
Socket sim_communication_port;
static int sim_communication_port_open = 0;
#endif

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


/* this is the globalData that is used in all the functions */
DATA *globalData = 0;

// The simulation result
simulation_result *sim_result = NULL;

/* Flags for controlling logging to stdout */
/*
const int LOG_STATS         = (1<<0);
const int LOG_INIT          = (1<<1);
const int LOG_SOLVER        = (1<<2);
const int LOG_JAC           = (1<<3);
const int LOG_ENDJAC        = (1<<4);
const int LOG_NONLIN_SYS    = (1<<5);
const int LOG_EVENTS        = (1<<6);
const int LOG_ZEROCROSSINGS = (1<<7);
const int LOG_DEBUG         = (1<<8);
const int LOG_RES_INIT      = LOG_STATS|LOG_INIT;
*/

/* Flags for modelErrorCodes */
extern const int ERROR_NONLINSYS = -1;
extern const int ERROR_LINSYS = -2;


int
startInteractiveSimulation(int, char**);
int
startNonInteractiveSimulation(int, char**);
int
initRuntimeAndSimulation(int, char**);


void setTermMsg(const char *msg)
{
  size_t length = strlen(msg);
  if (length > 0) {
      if (TermMsg == NULL) {
        TermMsg = (char*)calloc(length+1,sizeof(char));
      } else {
          if (strlen(msg) > strlen(TermMsg)) {
            if (TermMsg != NULL) {
                  free(TermMsg);
            }
            TermMsg = (char*)calloc(length+1,sizeof(char));
          }
      }
      for (size_t i=0;i<length;i++)
        TermMsg[i] = msg[i];
  }
}

static void callExternalObjectDestructors2(_X_DATA *data)
{
  if(!data)
    return;
  callExternalObjectDestructors(data) /* external objects */;
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

/*! \fn void overwriteOldSimulationData(_X_DATA *data)
 *
 * Stores variables (states, derivatives and algebraic) to be used
 * by e.g. numerical solvers to extrapolate values as start values.
 *
 * This function overwrites all old value with the current.
 * This function is called after events.
 *
 *  author: lochel
 */
void overwriteOldSimulationData(_X_DATA *data)
{
  long i;

  for(i=1; i<ringBufferLength(data->simulationData); ++i){
    data->localData[i]->timeValue = data->localData[i-1]->timeValue;
    memcpy(data->localData[i]->realVars, data->localData[i-1]->realVars, sizeof(modelica_real)*data->modelData.nVariablesReal);
    memcpy(data->localData[i]->integerVars, data->localData[i-1]->integerVars, sizeof(modelica_integer)*data->modelData.nVariablesInteger);
    memcpy(data->localData[i]->booleanVars, data->localData[i-1]->booleanVars, sizeof(modelica_boolean)*data->modelData.nVariablesBoolean);
    memcpy(data->localData[i]->stringVars, data->localData[i-1]->stringVars, sizeof(modelica_string)*data->modelData.nVariablesString);
  }
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
int verboseLevel(int argc, char**argv) {
  int res = 0;
  const string * flags = getFlagValue("lv", argc, argv);

  if (!flags)
    return res; // no lv flag given.

  if (flags->find("LOG_STATS", 0) != string::npos) {
    res |= LOG_STATS;
    globalDebugFlags |= LOG_STATS;
  }
  if (flags->find("LOG_JAC", 0) != string::npos) {
    res |= LOG_JAC;
    globalDebugFlags |= LOG_JAC;
  }
  if (flags->find("LOG_ENDJAC", 0) != string::npos) {
    res |= LOG_ENDJAC;
    globalDebugFlags |= LOG_ENDJAC;
  }
  if (flags->find("LOG_INIT", 0) != string::npos) {
    res |= LOG_INIT;
    globalDebugFlags |= LOG_INIT;
  }
  if (flags->find("LOG_RES_INIT", 0) != string::npos) {
    res |= LOG_RES_INIT;
    globalDebugFlags |= LOG_RES_INIT;
  }
  if (flags->find("LOG_SOLVER", 0) != string::npos) {
    res |= LOG_SOLVER;
    globalDebugFlags |= LOG_SOLVER;
  }
  if (flags->find("LOG_EVENTS", 0) != string::npos) {
    res |= LOG_EVENTS;
    globalDebugFlags |= LOG_EVENTS;
  }
  if (flags->find("LOG_NONLIN_SYS", 0) != string::npos) {
    res |= LOG_NONLIN_SYS;
    globalDebugFlags |= LOG_NONLIN_SYS;
  }
  if (flags->find("LOG_ZEROCROSSINGS", 0) != string::npos) {
    res |= LOG_ZEROCROSSINGS;
    globalDebugFlags |= LOG_ZEROCROSSINGS;
  }
  if (flags->find("LOG_DEBUG", 0) != string::npos) {
    res |= LOG_DEBUG;
    globalDebugFlags |= LOG_DEBUG;
  }
  if (flags->find("LOG_ALL", 0) != string::npos) {
    res = INT_MAX;
    globalDebugFlags = UINT_MAX;
  }
  return res;
}

int useVerboseOutput(int level)
{
  return (sim_verbose >= level);
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
void initializeOutputFilter(MODEL_DATA *modelData, modelica_string variableFilter)
{
#ifndef _MSC_VER
  std::string varfilter(variableFilter);
  regex_t myregex;
  int flags = REG_EXTENDED;
  int rc;
  string tmp = ("^(" + varfilter + ")$");
  const char *filter = tmp.c_str(); // C++ strings are horrible to work with...
  if (modelData->nStates > 0 && 0 == strcmp(modelData->realData[0].info.name,"$dummy")) {
    modelData->realData[0].filterOutput = 1;
    modelData->realData[1].filterOutput = 1;
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
  /* new imple */
  for (int i = 0; i < modelData->nVariablesReal; i++) if (!modelData->realData[i].filterOutput)
    modelData->realData[i].filterOutput = regexec(&myregex, modelData->realData[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nAliasReal; i++) if (!modelData->realAlias[i].filterOutput)
    modelData->realAlias[i].filterOutput = regexec(&myregex, modelData->realAlias[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nVariablesInteger; i++) if (!modelData->integerData[i].filterOutput)
    modelData->integerData[i].filterOutput = regexec(&myregex, modelData->integerData[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nAliasInteger; i++) if (!modelData->integerAlias[i].filterOutput)
    modelData->integerAlias[i].filterOutput = regexec(&myregex, modelData->integerAlias[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nVariablesBoolean; i++) if (!modelData->booleanData[i].filterOutput)
    modelData->booleanData[i].filterOutput = regexec(&myregex, modelData->booleanData[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nAliasBoolean; i++) if (!modelData->booleanAlias[i].filterOutput)
    modelData->booleanAlias[i].filterOutput = regexec(&myregex, modelData->booleanAlias[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nVariablesString; i++) if (!modelData->stringData[i].filterOutput)
    modelData->stringData[i].filterOutput = regexec(&myregex, modelData->stringData[i].info.name, 0, NULL, 0) != 0;
  for (int i = 0; i < modelData->nAliasString; i++) if (!modelData->stringAlias[i].filterOutput)
    modelData->stringAlias[i].filterOutput = regexec(&myregex, modelData->stringAlias[i].info.name, 0, NULL, 0) != 0;
  regfree(&myregex);
#endif
  return;
}

/**
 * Starts a non-interactive simulation
 */
int
startNonInteractiveSimulation(int argc, char**argv,_X_DATA *data)
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
  function_initMemoryState();
  read_input_xml(argc, argv, globalData, &(data->modelData), &(data->simulationInfo), &start, &stop, &stepSize, &outputSteps,
      &tolerance, &method, &outputFormat, &variableFilter);
  initializeOutputFilter(&(data->modelData),data->simulationInfo.variableFilter);
  callExternalObjectConstructors(data);

  if (measure_time_flag) {
    rt_init(SIM_TIMER_FIRST_FUNCTION + data->modelData.nFunctions + data->modelData.nProfileBlocks + 4 /* sentinel */);
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
    result_file_cstr = string(data->modelData.modelFilePrefix) + string("_res.") + outputFormat; /* TODO: Fix result file name based on mode */
  } else {
    result_file_cstr = *result_file;
  }

  retVal = callSolver(data, method, outputFormat, result_file_cstr, start, stop, stepSize,
      outputSteps, tolerance);

  if (retVal == 0 && create_linearmodel) {
    rt_tick(SIM_TIMER_LINEARIZE);
    retVal = linearize(data->modelData.nStates, data->modelData.nInputVars, data->modelData.nOutputVars);
    rt_accumulate(SIM_TIMER_LINEARIZE);
    cout << "Linear model is created!" << endl;
  }

  if (retVal == 0 && measure_time_flag && ! sim_verbose) {
    const string modelInfo = string(data->modelData.modelFilePrefix) + "_prof.xml";
    const string plotFile = string(data->modelData.modelFilePrefix) + "_prof.plt";
    rt_accumulate(SIM_TIMER_TOTAL);
    string* plotFormat = (string*) getFlagValue("measureTimePlotFormat", argc, argv);
    retVal = printModelInfo(globalData, modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat->c_str() : "svg", method.c_str(), outputFormat.c_str(), result_file_cstr.c_str()) && retVal;
  }

  deinitDelay();

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
 * "dopri5" calls an embedded DOPRI5(4)-solver with stepsize control
 */
int
callSolver(_X_DATA* simData, string method, string outputFormat,
    string result_file_cstr,
    double start, double stop, double stepSize, long outputSteps,
    double tolerance)
{
  int retVal = -1;

  long maxSteps = 2 * outputSteps + 2 * simData->simulationInfo.nSampleTimes;
  if (isInteractiveSimulation() || sim_noemit || 0 == strcmp("empty", outputFormat.c_str())) {
    sim_result = new simulation_result_empty(result_file_cstr.c_str(),maxSteps);
  } else if (0 == strcmp("csv", outputFormat.c_str())) {
    sim_result = new simulation_result_csv(result_file_cstr.c_str(), maxSteps,&(simData->modelData));
  } else if (0 == strcmp("mat", outputFormat.c_str())) {
    sim_result = new simulation_result_mat(result_file_cstr.c_str(), simData->simulationInfo.startTime, simData->simulationInfo.stopTime,&(simData->modelData));
  } else if (0 == strcmp("plt", outputFormat.c_str())) {
    sim_result = new simulation_result_plt(result_file_cstr.c_str(), maxSteps,&(simData->modelData));
  } else {
    cerr << "Unknown output format: " << outputFormat << endl;
    return 1;
  }
  if (DEBUG_FLAG(LOG_SOLVER)) {
    cout << "Allocated simulation result data storage for method '"
        << sim_result->result_type() << "' and file='" << result_file_cstr
        << "'" << endl; fflush(NULL);
  }

  if (method == std::string("")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "No solver is set, using dassl." << endl; fflush(NULL);
    }
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("euler")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 1);
  } else if (method == std::string("rungekutta")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 2);
  } else if (method == std::string("dassl") || method == std::string("dassl2")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("dassljac")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    jac_flag = 1;
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("dasslnum")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    num_jac_flag = 1;
    retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 3);
  } else if (method == std::string("dopri5")) {
       if (DEBUG_FLAG(LOG_SOLVER)) {
       cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
       }
       retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 6);
  } else if (method == std::string("inline-euler")) {
    if (!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-euler")) {
      cout << "Recognized solver: " << method
          << ", but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_EULER."
          << endl; fflush(NULL);
      retVal = 1;
    } else {
      if (DEBUG_FLAG(LOG_SOLVER)) {
        cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
      }
      retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 4);
    }
  } else if (method == std::string("inline-rungekutta")) {
    if (!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-rungekutta")) {
      cout << "Recognized solver: " << method
          << ", but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_RK."
          << endl; fflush(NULL);
      retVal = 1;
    } else {
      if (DEBUG_FLAG(LOG_SOLVER)) {
        cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
      }
      retVal = solver_main(simData, start, stop, stepSize, outputSteps, tolerance, 4);
    }
#ifdef _OMC_QSS_LIB
  } else if (method == std::string("qss")) {
    if (DEBUG_FLAG(LOG_SOLVER)) {
      cout << "Recognized solver: " << method << "." << endl; fflush(NULL);
    }
    retVal = qss_main(argc, argv, start, stop, stepSize, outputSteps, tolerance, 3);
#endif
  } else {
    cout << "Unrecognized solver: " << method
        << "; valid solvers are dassl,euler,rungekutta,dopri5,inline-euler or inline-rungekutta."
        << endl; fflush(NULL);
    retVal = 1;
  }

  delete sim_result;

  return retVal;
}


/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int
initRuntimeAndSimulation(int argc, char**argv, _X_DATA *data)
{
  if (flagSet("?", argc, argv) || flagSet("help", argc, argv)) {
    cout << "usage: " << argv[0]
                              << " <-f initfile> <-r result file> -m solver:{dassl,euler,rungekutta,dopri5,inline-euler or inline-rungekutta} <-interactive> <-port value> "
                              << "-lv [LOG_STATS] [LOG_INIT] [LOG_RES_INIT] [LOG_SOLVER] [LOG_EVENTS] [LOG_NONLIN_SYS] [LOG_ZEROCROSSINGS] [LOG_DEBUG]"
                              << endl;
    EXIT(0);
  }
  initializeXDataStruc(data);
  callExternalObjectConstructors(data);

  if (!data) {
    std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }
  //this sets the static variable that is in the file with the generated-model functions
  if (data->modelData.nVariablesReal == 0 && data->modelData.nVariablesInteger && data->modelData.nVariablesBoolean) {
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
  } else if (!interactiveSimulation && flagSet("port", argc, argv)) {
    string *portvalue = (string*) getFlagValue("port", argc, argv);
    std::istringstream stream(*portvalue);
    int port;
    stream >> port;
    sim_communication_port_open = 1;
    sim_communication_port_open &= sim_communication_port.create();
    sim_communication_port_open &= sim_communication_port.connect("127.0.0.1",port);
    communicateStatus("Starting",0.0);
  }
#endif
  int verbose_flags = verboseLevel(argc, argv);
  sim_verbose = verbose_flags ? verbose_flags : sim_verbose;
  if (sim_verbose)
    measure_time_flag = 1;

  return 0;
}

void SimulationRuntime_printStatus(int sig) {
  printf("<status>\n");
  printf("<model>%s</model>\n", globalData->modelFilePrefix);
  printf("<phase>UNKNOWN</phase>\n");
  printf("<currentStepSize>%g</currentStepSize>\n",globalData->current_stepsize);
  printf("<oldTime>%.12g</oldTime>\n",globalData->oldTime);
  printf("<oldTime2>%.12g</oldTime2>\n",globalData->oldTime2);
  printf("<diffOldTime>%g</diffOldTime>\n",globalData->oldTime-globalData->oldTime2);
  printf("<currentTime>%g</currentTime>\n",globalData->timeValue);
  printf("<diffCurrentTime>%g</diffCurrentTime>\n",globalData->timeValue-globalData->oldTime);
  printf("</status>\n");
}

void communicateStatus(const char *phase, double completionPercent /*0.0 to 1.0*/)
{
#ifndef NO_INTERACTIVE_DEPENDENCY
  if (sim_communication_port_open) {
    std::stringstream s;
    s << (int)(completionPercent*10000) << " " << phase << endl;
    std::string str(s.str());
    sim_communication_port.send(str);
    // cout << str;
  }
#endif
}

/* \brief main function for simulator
 *
 * The arguments for the main function are:
 * -v verbose = debug
 * -vf=flags set verbosity flags
 * -f init_file.txt use input data from init file.
 * -r res.plt write result to file.
 */

int _main_SimulationRuntime(int argc, char**argv, _X_DATA *data)
{
  int retVal = -1;
  if(!setjmp(globalJmpbuf) ) 
  {
      if (initRuntimeAndSimulation(argc, argv, data)) //initRuntimeAndSimulation returns 1 if an error occurs
        return 1;
      /* sighandler_t oldhandler = different type on all platforms... */
#ifdef SIGUSR1
      signal(SIGUSR1, SimulationRuntime_printStatus);
#endif

      if (interactiveSimulation) {
        cout << "startInteractiveSimulation: " << version << endl;
        retVal = startInteractiveSimulation(argc, argv);
      } else {
        /* cout << "startNonInteractiveSimulation: " << version << endl; */
        retVal = startNonInteractiveSimulation(argc, argv, data);
      }
  }
  else
  {
    /* THROW was executed */
  }

  /* deinitializeEventData();
   * callExternalObjectDestructors2(globalData);
   * free(globalData);
   */
  callExternalObjectDestructors(data);
  DeinitializeXDataStruc(data);
  fflush(NULL);
#ifndef NO_INTERACTIVE_DEPENDENCY
  if (sim_communication_port_open) {
    sim_communication_port.close();
  }
#endif
  EXIT(retVal);
}

/* C-Interface for sim_result->emit(); */
void sim_result_emit(_X_DATA *data)
{
   if (sim_result) sim_result->emit(data);
}

/* C-Interface for sim_result->writeParameterData(); */
void sim_result_writeParameterData(MODEL_DATA *modelData)
{
   if (sim_result) sim_result->writeParameterData(modelData);
}
