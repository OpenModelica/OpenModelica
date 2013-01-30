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


#ifdef _MSC_VER
#include <windows.h>
#endif

#include <setjmp.h>
#include <string>
#include <iostream>
#include <sstream>
#include <limits>
#include <list>
#include <cmath>
#include <iomanip>
#include <ctime>
#include <cstdio>
#include <cstring>
#include <cassert>
#include <signal.h>
#include <fstream>
#include <string>

#ifndef _MSC_VER
#include <regex.h>
#endif

#include "omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"

#include "linearize.h"
#include "options.h"
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "simulation_result_empty.h"
#include "simulation_result_plt.h"
#include "simulation_result_csv.h"
#include "simulation_result_mat.h"
#include "solver_main.h"
#include "modelinfo.h"
#include "model_help.h"
#include "nonlinearSystem.h"
#include "rtclock.h"

#ifdef _OMC_QSS_LIB
#include "solver_qss/solver_qss.h"
#endif

// ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
/* #include "../../interactive/omi_ServiceInterface.h" */
#endif

using namespace std;

int interactiveSimulation = 0; //This variable signals if an simulation session is interactive or non-interactive (by default)

const char* version = "20110520_1120";

#ifndef NO_INTERACTIVE_DEPENDENCY
Socket sim_communication_port;
static int sim_communication_port_open = 0;
#endif


int modelTermination = 0; /* Becomes non-zero when simulation terminates. */
int terminationTerminate = 0; /* Becomes non-zero when user terminates simulation. */
int terminationAssert = 0; /* Becomes non-zero when model call assert simulation. */
int warningLevelAssert = 0; /* Becomes non-zero when model call assert with warning level. */
FILE_INFO TermInfo; /* message for termination. */

char* TermMsg; /* message for termination. */

int sim_noemit = 0; // Flag for not emitting data

const std::string *init_method = NULL; // method for  initialization.


// The simulation result
simulation_result *sim_result = NULL;


/* function for start simulation */
int callSolver(DATA*, string, string, string, string, double, string);

int isInteractiveSimulation();

/*! \fn void setTermMsg(DATA* simData, const char* msg )
 *
 *  prints all values as arguments it need data
 *  and which part of the ring should printed.
 *
 */
void setTermMsg(const char *msg)
{
  size_t i;
  size_t length = strlen(msg);
  if(length > 0)
  {
    if(TermMsg == NULL)
    {
      TermMsg = (char*)malloc((length+1)*sizeof(char));
    }
    else
    {
      if(strlen(msg) > strlen(TermMsg))
      {
        if(TermMsg != NULL)
        {
          free(TermMsg);
        }
        TermMsg = (char*)malloc((length+1)*sizeof(char));
      }
    }
    for(i=0;i<length;i++)
      TermMsg[i] = msg[i];
    /* set the terminating 0 */
    TermMsg[i] = '\0';
  }
}

/* \brief determine verboselevel by investigating flag -lv flags
 *
 * Valid flags: see LOG_STREAM_NAME in omc_error.c
 */
void setGlobalVerboseLevel(int argc, char**argv)
{
  const string *flags = getFlagValue("lv", argc, argv);
  int i;
  int error;
  
  if(flagSet("w", argc, argv))
    showAllWarnings = 1;

  if(!flags)
  {
    /* default activated */
    useStream[LOG_STDOUT] = 1;
    useStream[LOG_ASSERT] = 1;
    return; // no lv flag given.
  }

  if(flags->find("LOG_ALL", 0) != string::npos)
  {
    for(i=1; i<LOG_MAX; ++i)
      useStream[i] = 1;
  }
  else
  {
    string flagList = *flags;
    string flag;
    unsigned long pos;

    do
    {
      error = 1;
      pos = flagList.find(",", 0);
      if(pos != string::npos)
      {
        flag = flagList.substr(0, pos);
        flagList = flagList.substr(pos+1);
      }
      else
      {
        flag = flagList;
      }

      for(i=firstOMCErrorStream; i<LOG_MAX; ++i)
      {
        if(flag == string(LOG_STREAM_NAME[i]))
        {
          useStream[i] = 1;
          error = 0;
        }
      }

      if(error)
      {
        WARNING(LOG_STDOUT, "current options are:");
        INDENT(LOG_STDOUT);
        for(i=firstOMCErrorStream; i<LOG_MAX; ++i)
          WARNING2(LOG_STDOUT, "%-18s [%s]", LOG_STREAM_NAME[i], LOG_STREAM_DESC[i]);
        RELEASE(LOG_STDOUT);
        THROW1("unrecognized option -lv %s", flags->c_str());
      }
    }while(pos != string::npos);
  }

  /* default activated */
  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;

  /* print LOG_SOTI if LOG_INIT is enabled */
  if(useStream[LOG_INIT])
    useStream[LOG_SOTI] = 1;

  /* print LOG_STATS if LOG_SOLVER if active */
  if(useStream[LOG_SOLVER] == 1)
    useStream[LOG_STATS] = 1;

  /* print LOG_NLS if LOG_NLS_V if active */
  if(useStream[LOG_NLS_V])
    useStream[LOG_NLS] = 1;
    
  /* print LOG_EVENTS if LOG_EVENTS_V if active */
  if(useStream[LOG_EVENTS_V])
    useStream[LOG_EVENTS] = 1;

  if(useStream[LOG_NLS_JAC])
    useStream[LOG_NLS] = 1;

  delete flags;
}

int getNonlinearSolverMethod(int argc, char**argv)
{
  const string *method = getOption("nls", argc, argv);

  if(!method)
    return NS_HYBRID; /* default method */

  if(*method == string("hybrid"))
    return NS_HYBRID;
  else if(*method == string("kinsol"))
    return NS_KINSOL;
  else if(*method == string("newton"))
    return NS_NEWTON;

  WARNING1(LOG_STDOUT, "unrecognized option -nls %s", method->c_str());
  WARNING(LOG_STDOUT, "current options are:");
  INDENT(LOG_STDOUT);
  WARNING2(LOG_STDOUT, "%-18s [%s]", "hybrid", "default method");
  WARNING2(LOG_STDOUT, "%-18s [%s]", "kinsol", "sundials/kinsol");
  WARNING2(LOG_STDOUT, "%-18s [%s]", "newton", "newton Raphson");
  THROW("see last warning");
  return NS_NONE;
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
/*
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
*/
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
  if(modelData->nStates > 0 && 0 == strcmp(modelData->realVarsData[0].info.name,"$dummy")) {
    modelData->realVarsData[0].filterOutput = 1;
    modelData->realVarsData[modelData->nStates].filterOutput = 1;
  }
  if(0 == strcmp(filter, ".*")) // This matches all variables, so we don't need to do anything
    return;

  rc = regcomp(&myregex, filter, flags);
  if(rc) {
    char err_buf[2048] = {0};
    regerror(rc, &myregex, err_buf, 2048);
    std::cerr << "Failed to compile regular expression: " << filter << " with error: " << err_buf << ". Defaulting to outputting all variables." << std::endl;
    return;
  }
  /* new imple */
  for(int i = 0; i < modelData->nVariablesReal; i++) if(!modelData->realVarsData[i].filterOutput)
    modelData->realVarsData[i].filterOutput = regexec(&myregex, modelData->realVarsData[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nAliasReal; i++) if(!modelData->realAlias[i].filterOutput)
    modelData->realAlias[i].filterOutput = regexec(&myregex, modelData->realAlias[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nVariablesInteger; i++) if(!modelData->integerVarsData[i].filterOutput)
    modelData->integerVarsData[i].filterOutput = regexec(&myregex, modelData->integerVarsData[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nAliasInteger; i++) if(!modelData->integerAlias[i].filterOutput)
    modelData->integerAlias[i].filterOutput = regexec(&myregex, modelData->integerAlias[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nVariablesBoolean; i++) if(!modelData->booleanVarsData[i].filterOutput)
    modelData->booleanVarsData[i].filterOutput = regexec(&myregex, modelData->booleanVarsData[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nAliasBoolean; i++) if(!modelData->booleanAlias[i].filterOutput)
    modelData->booleanAlias[i].filterOutput = regexec(&myregex, modelData->booleanAlias[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nVariablesString; i++) if(!modelData->stringVarsData[i].filterOutput)
    modelData->stringVarsData[i].filterOutput = regexec(&myregex, modelData->stringVarsData[i].info.name, 0, NULL, 0) != 0;
  for(int i = 0; i < modelData->nAliasString; i++) if(!modelData->stringAlias[i].filterOutput)
    modelData->stringAlias[i].filterOutput = regexec(&myregex, modelData->stringAlias[i].info.name, 0, NULL, 0) != 0;
  regfree(&myregex);
#endif
  return;
}

/**
 * Starts a non-interactive simulation
 */
int startNonInteractiveSimulation(int argc, char**argv, DATA* data)
{
  int retVal = -1;
  int measureSimTime = 0;

  /* linear model option is set : <-l lintime> */
  int create_linearmodel = flagSet("l", argc, argv);
  string* lintime = (string*) getFlagValue("l", argc, argv);

  /* activated measure time option with LOG_STATS */
  if(DEBUG_STREAM(LOG_STATS) && !measure_time_flag)
  {
    measure_time_flag = 1;
    measureSimTime = 1;
  }

  function_initMemoryState();
  read_input_xml(argc, argv, &(data->modelData), &(data->simulationInfo));
  initializeOutputFilter(&(data->modelData),data->simulationInfo.variableFilter);
  setupDataStruc2(data);

  /* calc numStep */
  data->simulationInfo.numSteps = static_cast<modelica_integer>((data->simulationInfo.stopTime - data->simulationInfo.startTime)/data->simulationInfo.stepSize);

  if(measure_time_flag)
  {
    rt_init(SIM_TIMER_FIRST_FUNCTION + data->modelData.nFunctions + data->modelData.nProfileBlocks + 4 /*sentinel */);
    rt_tick( SIM_TIMER_TOTAL );
    rt_tick( SIM_TIMER_PREINIT );
    rt_clear( SIM_TIMER_OUTPUT );
    rt_clear( SIM_TIMER_EVENT );
    rt_clear( SIM_TIMER_INIT );
  }

  if(create_linearmodel)
  {
    if(lintime == NULL)
      data->simulationInfo.stopTime = data->simulationInfo.startTime;
    else
      data->simulationInfo.stopTime = atof(lintime->c_str());
    cout << "Linearization will performed at point of time: " << data->simulationInfo.stopTime << endl;
    data->simulationInfo.solverMethod = "dassl";
  }

  int methodflag = flagSet("s", argc, argv);
  if(methodflag)
  {
    string* method = (string*) getFlagValue("s", argc, argv);
    if(!(method == NULL)){
      data->simulationInfo.solverMethod = method->c_str();
      INFO1(LOG_SOLVER, " | overwrite solver method: %s [from command line]", data->simulationInfo.solverMethod);
    }
  }

  // Create a result file
  string *result_file = (string*) getFlagValue("r", argc, argv);
  string result_file_cstr;
  if(!result_file)
    result_file_cstr = string(data->modelData.modelFilePrefix) + string("_res.") + data->simulationInfo.outputFormat; /* TODO: Fix result file name based on mode */
  else
    result_file_cstr = *result_file;

  string init_initMethod = "";
  string init_optiMethod = "";
  string init_file = "";
  string init_time_string = "";
  double init_time = 0;
  string outputVariablesAtEnd = "";

  if(flagSet("iim", argc, argv))
    init_initMethod = *getFlagValue("iim", argc, argv);
  if(flagSet("iom", argc, argv))
    init_optiMethod = *getFlagValue("iom", argc, argv);
  if(flagSet("iif", argc, argv))
    init_file = *getFlagValue("iif", argc, argv);
  if(flagSet("iit", argc, argv))
  {
    init_time_string = *getFlagValue("iit", argc, argv);
    init_time = atof(init_time_string.c_str());
  }

  if(flagSet("output", argc, argv))
  {
    outputVariablesAtEnd = *getFlagValue("output", argc, argv);
  }

  retVal = callSolver(data, result_file_cstr, init_initMethod, init_optiMethod,
      init_file, init_time, outputVariablesAtEnd);

  if(retVal == 0 && create_linearmodel)
  {
    rt_tick(SIM_TIMER_LINEARIZE);
    retVal = linearize(data);
    rt_accumulate(SIM_TIMER_LINEARIZE);
    cout << "Linear model is created!" << endl;
  }
  /* disable measure_time_flag to prevent producing
   * all profiling files, since measure_time_flag
   * was not activated while compiling, it was
   * just used for measure simulation time for LOG_STATS.
   */
  if(measureSimTime){
    measure_time_flag = 0;
  }


  if(retVal == 0 && measure_time_flag)
  {
    const string modelInfo = string(data->modelData.modelFilePrefix) + "_prof.xml";
    const string plotFile = string(data->modelData.modelFilePrefix) + "_prof.plt";
    rt_accumulate(SIM_TIMER_TOTAL);
    string* plotFormat = (string*) getFlagValue("measureTimePlotFormat", argc, argv);
    retVal = printModelInfo(data, modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat->c_str() : "svg",
        data->simulationInfo.solverMethod, data->simulationInfo.outputFormat, result_file_cstr.c_str()) && retVal;
  }

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
int callSolver(DATA* simData, string result_file_cstr, string init_initMethod,
    string init_optiMethod, string init_file, double init_time, string outputVariablesAtEnd)
{
  int retVal = -1;
  const char* outVars = (outputVariablesAtEnd.size() == 0) ? NULL : outputVariablesAtEnd.c_str();

  long maxSteps = 4 * simData->simulationInfo.numSteps;
  if(isInteractiveSimulation() || sim_noemit || 0 == strcmp("empty", simData->simulationInfo.outputFormat)) {
    sim_result = new simulation_result_empty(result_file_cstr.c_str(), maxSteps, simData);
  } else if(0 == strcmp("csv", simData->simulationInfo.outputFormat)) {
    sim_result = new simulation_result_csv(result_file_cstr.c_str(), maxSteps, simData);
  } else if(0 == strcmp("mat", simData->simulationInfo.outputFormat)) {
    sim_result = new simulation_result_mat(result_file_cstr.c_str(), simData->simulationInfo.startTime, simData->simulationInfo.stopTime, simData);
  } else if(0 == strcmp("plt", simData->simulationInfo.outputFormat)) {
    sim_result = new simulation_result_plt(result_file_cstr.c_str(), maxSteps, simData);
  } else {
    cerr << "Unknown output format: " << simData->simulationInfo.outputFormat << endl;
    return 1;
  }
  INFO2(LOG_SOLVER,"Allocated simulation result data storage for method '%s' and file='%s'", sim_result->result_type(), result_file_cstr.c_str());

  if(simData->simulationInfo.solverMethod == std::string("")) {
    INFO(LOG_SOLVER, " | No solver is set, using dassl.");
    retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 3, outVars);
  } else if(simData->simulationInfo.solverMethod == std::string("euler")) {
    INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
    retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 1, outVars);
  } else if(simData->simulationInfo.solverMethod == std::string("rungekutta")) {
    INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
    retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 2, outVars);
  } else if(simData->simulationInfo.solverMethod == std::string("dassl") ||
              simData->simulationInfo.solverMethod == std::string("dasslwort")  ||
              simData->simulationInfo.solverMethod == std::string("dassltest")  ||
              simData->simulationInfo.solverMethod == std::string("dasslSymJac") ||
              simData->simulationInfo.solverMethod == std::string("dasslNumJac") ||
              simData->simulationInfo.solverMethod == std::string("dasslColorSymJac") ||
              simData->simulationInfo.solverMethod == std::string("dasslInternalNumJac")) {

    INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
    retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 3, outVars);
  } else if(simData->simulationInfo.solverMethod == std::string("inline-euler")) {
    if(!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-euler")) {
      INFO1(LOG_SOLVER, " | Recognized solver: %s, but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_EULER.", simData->simulationInfo.solverMethod);
      retVal = 1;
    } else {
      INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
      retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 4, outVars);
    }
  } else if(simData->simulationInfo.solverMethod == std::string("inline-rungekutta")) {
    if(!_omc_force_solver || std::string(_omc_force_solver) != std::string("inline-rungekutta")) {
      INFO1(LOG_SOLVER, " | Recognized solver: %s, but the executable was not compiled with support for it. Compile with -D_OMC_INLINE_RK.", simData->simulationInfo.solverMethod);
      retVal = 1;
    } else {
      INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
      retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, 4, outVars);
    }
#ifdef _OMC_QSS_LIB
  } else if(simData->simulationInfo.solverMethod == std::string("qss")) {
    INFO1(LOG_SOLVER, " | Recognized solver: %s.", simData->simulationInfo.solverMethod);
    retVal = qss_main(argc, argv, simData->simulationInfo.startTime,
                      simData->simulationInfo.stopTime, simData->simulationInfo.stepSize,
                      simData->simulationInfo.numSteps, simData->simulationInfo.tolerance, 3);
#endif
  } else {
    INFO1(LOG_STDOUT, " | Unrecognized solver: %s.", simData->simulationInfo.solverMethod);
    INFO(LOG_STDOUT, " | valid solvers are: dassl, euler, rungekutta, inline-euler, inline-rungekutta, dasslwort, dasslSymJac, dasslNumJac, dasslColorSymJac, dasslInternalNumJac, qss.");
    retVal = 1;
  }

  delete sim_result;

  return retVal;
}


/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int initRuntimeAndSimulation(int argc, char**argv, DATA *data)
{
  int i;
  initDumpSystem();

  if(flagSet("?", argc, argv) || flagSet("help", argc, argv))
  {
    INFO1(LOG_STDOUT, "usage: %s", argv[0]);
    INDENT(LOG_STDOUT);
    INFO(LOG_STDOUT, "<-f setup file>");
    INFO(LOG_STDOUT, "\tspecify a new setup XML file to the generated simulation code");
    INFO(LOG_STDOUT, "<-r result file>");
    INFO(LOG_STDOUT, "\tspecify a new result file than the default Model_res.mat");
    INFO(LOG_STDOUT, "<-m|s solver:{dassl,euler,rungekutta,inline-euler,inline-rungekutta,qss}>");
    INFO(LOG_STDOUT, "\tspecify the solver");
    INFO(LOG_STDOUT, "<-nls={hybrid|kinsol}>");
    INFO(LOG_STDOUT, "\tspecify the nonlinear solver");
    INFO(LOG_STDOUT, "<-interactive> <-port value>");
    INFO(LOG_STDOUT, "\tspecify interactive simulation and port");
    INFO(LOG_STDOUT, "<-iim initialization method:{none,numeric,symbolic}>");
    INFO(LOG_STDOUT, "\tspecify the initialization method");
    INFO(LOG_STDOUT, "<-iom optimization method:{nelder_mead_ex,nelder_mead_ex2,simplex,newuoa}>");
    INFO(LOG_STDOUT, "\tspecify the initialization optimization method");
    INFO(LOG_STDOUT, "<-iif initialization file>");
    INFO(LOG_STDOUT, "\tspecify an external file for the initialization of the model");
    INFO(LOG_STDOUT, "<-iit initialization time>");
    INFO(LOG_STDOUT, "\tspecify a time for the initialization of the model");
    INFO(LOG_STDOUT, "<-override var1=start1,var2=start2,par3=start3,");
    INFO(LOG_STDOUT, " startTime=val1,stopTime=val2,stepSize=val3,tolerance=val4,");
    INFO(LOG_STDOUT, " solver=\"see -m\",outputFormat=\"mat|plt|csv|empty\",variableFilter=\"filter\">");
    INFO(LOG_STDOUT, "\toverride the variables or the simulation settings in the XML setup file");
    INFO(LOG_STDOUT, "<-overrideFile overrideFileName>");
    INFO(LOG_STDOUT, "\tnote that: -overrideFile CANNOT be used with -override");
    INFO(LOG_STDOUT, "\tuse when variables for -override are too many and do not fit in command line size");
    INFO(LOG_STDOUT, "\toverrideFileName contains lines of the form: var1=start1");
    INFO(LOG_STDOUT, "\twill override the variables or the simulation settings in the XML setup file with the values from the file");
    INFO(LOG_STDOUT, "<-output a,b,c>");
    INFO(LOG_STDOUT, "\toutput the variables a, b and c at the end of the simulation to the standard output as time = value, a = value, b = value, c = value");
    INFO(LOG_STDOUT, "<-noemit>");
    INFO(LOG_STDOUT, "\tdo not emit any results to the result file");
    INFO(LOG_STDOUT, "<-jac> ");
    INFO(LOG_STDOUT, "\tspecify jacobian");
    INFO(LOG_STDOUT, "<-numjac> ");
    INFO(LOG_STDOUT, "\tspecify numerical jacobian");
    INFO(LOG_STDOUT, "<-l linear time> ");
    INFO(LOG_STDOUT, "\tspecify a time where the linearization of the model should be performed");
    INFO(LOG_STDOUT, "<-mt> ");
    INFO(LOG_STDOUT, "\tthis command line parameter is DEPRECATED!");
    INFO(LOG_STDOUT, "<-measureTimePlotFormat svg|jpg|ps|gif|...> ");
    INFO(LOG_STDOUT, "\tspecify the output format of the measure time functionality");
    INFO(LOG_STDOUT, "<-lv [flag1][,flags2][,...]>");
    INFO(LOG_STDOUT, "\tspecify the logging level");
    for(i=firstOMCErrorStream; i<LOG_MAX; ++i)
      INFO2(LOG_STDOUT, "\t%-18s [%s]", LOG_STREAM_NAME[i], LOG_STREAM_DESC[i]);
    INFO(LOG_STDOUT, "<-w>");
    INFO(LOG_STDOUT, "\tshow all warnings");
      
    RELEASE(LOG_STDOUT);
    EXIT(0);
  }

  setGlobalVerboseLevel(argc, argv);
  initializeDataStruc(data);
  if(!data)
  {
    std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }

  // this sets the static variable that is in the file with the generated-model functions
  if(data->modelData.nVariablesReal == 0 && data->modelData.nVariablesInteger && data->modelData.nVariablesBoolean)
  {
    std::cerr << "No variables in the model." << std::endl;
    return 1;
  }

  /* verbose flag is set : -v */
  if(flagSet("v", argc, argv))
    useStream[LOG_STATS] = 1;
  sim_noemit = flagSet("noemit", argc, argv);


  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio

#ifndef NO_INTERACTIVE_DEPENDENCY
  interactiveSimulation = flagSet("interactive", argc, argv);
  /*
  if(interactiveSimulation && flagSet("port", argc, argv)) {
    cout << "userPort" << endl;
    string *portvalue = (string*) getFlagValue("port", argc, argv);
    std::istringstream stream(*portvalue);
    int userPort;
    stream >> userPort;
    setPortOfControlServer(userPort);
  } else if(!interactiveSimulation && flagSet("port", argc, argv)) {
  */
  if(!interactiveSimulation && flagSet("port", argc, argv))
  {
    string *portvalue = (string*) getFlagValue("port", argc, argv);
    std::istringstream stream(*portvalue);
    int port;
    stream >> port;
    sim_communication_port_open = 1;
    sim_communication_port_open &= sim_communication_port.create();
    sim_communication_port_open &= sim_communication_port.connect("127.0.0.1", port);
    communicateStatus("Starting", 0.0);
  }
#endif

  data->simulationInfo.nlsMethod = getNonlinearSolverMethod(argc, argv);

  return 0;
}

void SimulationRuntime_printStatus(int sig)
{
  printf("<status>\n");
  printf("<phase>UNKNOWN</phase>\n");
  /*
   * FIXME: Variables needed here are no longer global.
   *        and (int sig) is too small for pointer to data.
   */
  /*
  printf("<model>%s</model>\n", data->modelData.modelFilePrefix);
  printf("<phase>UNKNOWN</phase>\n");
  printf("<currentStepSize>%g</currentStepSize>\n", data->simulationInfo.stepSize);
  printf("<oldTime>%.12g</oldTime>\n",data->localData[1]->timeValue);
  printf("<oldTime2>%.12g</oldTime2>\n",data->localData[2]->timeValue);
  printf("<diffOldTime>%g</diffOldTime>\n",data->localData[1]->timeValue-data->localData[2]->timeValue);
  printf("<currentTime>%g</currentTime>\n",data->localData[0]->timeValue);
  printf("<diffCurrentTime>%g</diffCurrentTime>\n",data->localData[0]->timeValue-data->localData[1]->timeValue);
  */
  printf("</status>\n");
}

void communicateStatus(const char *phase, double completionPercent /*0.0 to 1.0*/)
{
#ifndef NO_INTERACTIVE_DEPENDENCY
  if(sim_communication_port_open) {
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

int _main_SimulationRuntime(int argc, char**argv, DATA *data)
{
  int retVal = -1;

  if(!setjmp(globalJmpbuf))
  {
    if(initRuntimeAndSimulation(argc, argv, data)) //initRuntimeAndSimulation returns 1 if an error occurs
      return 1;

    /* sighandler_t oldhandler = different type on all platforms... */
#ifdef SIGUSR1
    signal(SIGUSR1, SimulationRuntime_printStatus);
#endif

    /*
     * if(interactiveSimulation)
     * {
     *   cout << "startInteractiveSimulation: " << version << endl;
     *   retVal = startInteractiveSimulation(argc, argv);
     * }
     * else
     * {
     *   cout << "startNonInteractiveSimulation: " << version << endl;
     *   retVal = startNonInteractiveSimulation(argc, argv, data);
     * }
     */
    retVal = startNonInteractiveSimulation(argc, argv, data);

    callExternalObjectDestructors(data);
    deInitializeDataStruc(data);
    fflush(NULL);
  }
  else
  {
    /* THROW was executed */
  }

#ifndef NO_INTERACTIVE_DEPENDENCY
  if(sim_communication_port_open) {
    sim_communication_port.close();
  }
#endif
  EXIT(retVal);
}

/* C-Interface for sim_result->emit(); */
void sim_result_emit()
{
   if(sim_result)
     sim_result->emit();
}

/* C-Interface for sim_result->writeParameterData(); */
void sim_result_writeParameterData()
{
   if(sim_result)
     sim_result->writeParameterData();
}

static void omc_assert_simulation(const char *msg, FILE_INFO info)
{
  terminationAssert = 1;
  setTermMsg(msg);
  TermInfo = info;
}

static void omc_assert_warning_simulation(const char *msg, FILE_INFO info)
{
  fprintf(stderr, "Warning: %s\n", msg);
}

static void omc_terminate_simulation(const char *msg, FILE_INFO info)
{
  modelTermination=1;
  terminationTerminate = 1;
  setTermMsg(msg);
  TermInfo = info;
}

static void omc_throw_simulation()
{
  terminationAssert = 1;
  setTermMsg("Assertion triggered by external C function");
  set_struct(FILE_INFO, TermInfo, omc_dummyFileInfo);
}

void (*omc_assert)(const char *msg, FILE_INFO info) = omc_assert_simulation;
void (*omc_assert_warning)(const char *msg, FILE_INFO info) = omc_assert_warning_simulation;
void (*omc_terminate)(const char *msg, FILE_INFO info) = omc_terminate_simulation;
void (*omc_throw)() = omc_throw_simulation;
