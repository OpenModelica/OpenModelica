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
#include <stdarg.h>

#ifndef _MSC_VER
  #include <regex.h>
#endif

#include "omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "meta_modelica.h"

#include "linearize.h"
#include "options.h"
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "simulation_result_plt.h"
#include "simulation_result_csv.h"
#include "simulation_result_mat.h"
#include "simulation_result_wall.h"
#include "solver_main.h"
#include "simulation_info_xml.h"
#include "modelinfo.h"
#include "model_help.h"
#include "mixedSystem.h"
#include "linearSystem.h"
#include "nonlinearSystem.h"
#include "rtclock.h"
#include "../../../Compiler/runtime/config.h"
#include "initialization.h"

#ifdef _OMC_QSS_LIB
  #include "solver_qss/solver_qss.h"
#endif

/* ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
 *
 */
#ifndef NO_INTERACTIVE_DEPENDENCY
  #include "../../interactive/omi_ServiceInterface.h"
  #include "../../../interactive/socket.h"
  extern Socket sim_communication_port;
#endif


using namespace std;

#ifndef NO_INTERACTIVE_DEPENDENCY
  Socket sim_communication_port;
  static int sim_communication_port_open = 0;
#endif

extern "C" {

static int interactiveSimulation = 0; /* This variable signals if an simulation session is interactive or non-interactive (by default) */

int terminationTerminate = 0; /* Becomes non-zero when user terminates simulation. */
FILE_INFO TermInfo;           /* message for termination. */

char* TermMsg;                /* message for termination. */

int sim_noemit = 0;           /* Flag for not emitting data */

const std::string *init_method = NULL; /* method for  initialization. */

int isInteractiveSimulation(void);

/*! \fn void setTermMsg(const char* msg)
 *
 *  prints all values as arguments it need data
 *  and which part of the ring should printed.
 */
static void setTermMsg(const char *msg, va_list ap)
{
  size_t i;
  static size_t termMsgSize = 0;
  if(NULL == TermMsg)
  {
    termMsgSize = max(strlen(msg)*2+1,(size_t)2048);
    TermMsg = (char*) malloc(termMsgSize);
  }
  i = vsnprintf(TermMsg,termMsgSize,msg,ap);
  if(i >= termMsgSize)
  {
    free(TermMsg);
    termMsgSize = 2*i+1;
    TermMsg = (char*)malloc(termMsgSize);
    vsnprintf(TermMsg,termMsgSize,msg,ap);
  }
}

/*! \fn void setGlobalVerboseLevel(int argc, char**argv)
 *
 *  \brief determine verboselevel by investigating flag -lv flags
 *
 *  Valid flags: see LOG_STREAM_NAME in omc_error.c
 */
void setGlobalVerboseLevel(int argc, char**argv)
{
  const char *cflags = omc_flagValue[FLAG_LV];
  const string *flags = cflags ? new string(cflags) : NULL;
  int i;

  if(omc_flag[FLAG_W])
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
      int error = 1;
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
        warningStreamPrint(LOG_STDOUT, 1, "current options are:");
        for(i=firstOMCErrorStream; i<LOG_MAX; ++i)
          warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", LOG_STREAM_NAME[i], LOG_STREAM_DESC[i]);
        messageClose(LOG_STDOUT);
        throwStreamPrint(NULL,"unrecognized option -lv %s", flags->c_str());
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

  /* print LOG_NLS if LOG_NLS_RES if active */
  if(useStream[LOG_NLS_RES])
    useStream[LOG_NLS] = 1;

  /* print LOG_EVENTS if LOG_EVENTS_V if active */
  if(useStream[LOG_EVENTS_V]) {
    useStream[LOG_EVENTS] = 1;
  }

  /* print LOG_NLS if LOG_NLS_JAC if active */
  if(useStream[LOG_NLS_JAC])
    useStream[LOG_NLS] = 1;

  /* print LOG_DSS if LOG_DSS_JAC if active */
  if(useStream[LOG_DSS_JAC])
    useStream[LOG_DSS] = 1;

  delete flags;
}

int getNonlinearSolverMethod(int argc, char**argv)
{
  int i;
  const char *cflags = omc_flagValue[FLAG_NLS];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return NLS_HYBRID; /* default method */

  for(i=1; i<NLS_MAX; ++i)
    if(*method == NLS_NAME[i])
      return i;

  warningStreamPrint(LOG_STDOUT, 1, "unrecognized option -nls=%s, current options are:", method->c_str());
  for(i=1; i<NLS_MAX; ++i)
    warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", NLS_NAME[i], NLS_DESC[i]);
  messageClose(LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");

  return NLS_NONE;
}

int getlinearSolverMethod(int argc, char**argv)
{
  const char *cflags = omc_flagValue[FLAG_LS];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return LS_LAPACK; /* default method */

  if(*method == string("lapack"))
    return LS_LAPACK;

  if(*method == string("lis"))
    return LS_LIS;

  warningStreamPrint(LOG_STDOUT, 1, "unrecognized option -ls %s, current options are:", method->c_str());
  warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", "lapack", "default method");
  warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", "lis", "Lis");
  messageClose(LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");
  return LS_NONE;
}

/**
 * Signals the type of the simulation
 * retuns true for interactive and false for non-interactive
 */
int isInteractiveSimulation(void)
{
  return interactiveSimulation;
}

/**
 * Starts an Interactive simulation session
 * the runtime waits until a user shuts down the simulation
 */
int startInteractiveSimulation(int argc, char**argv, void* data)
{
  int retVal = -1;

  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
#ifndef NO_INTERACTIVE_DEPENDENCY
  initServiceInterfaceData(argc, argv, data);

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
void initializeOutputFilter(MODEL_DATA *modelData, modelica_string variableFilter, int resultFormatHasCheapAliasesAndParameters)
{
#ifndef _MSC_VER
  regex_t myregex;
  int flags = REG_EXTENDED;
  int rc;
  std::string varfilter(variableFilter);
  string tmp = ("^(" + varfilter + ")$");
  const char *filter = tmp.c_str(); // C++ strings are horrible to work with...
  if (modelData->nStates > 0 && 0 == strcmp(modelData->realVarsData[0].info.name, "$dummy")) {
    modelData->realVarsData[0].filterOutput = 1;
    modelData->realVarsData[modelData->nStates].filterOutput = 1;
  }

  if(0 == strcmp(filter, ".*")) { // This matches all variables, so we don't need to do anything
    return;
  }

  rc = regcomp(&myregex, filter, flags);
  if(rc) {
    char err_buf[2048] = {0};
    regerror(rc, &myregex, err_buf, 2048);
    std::cerr << "Failed to compile regular expression: " << filter << " with error: " << err_buf << ". Defaulting to outputting all variables." << std::endl;
    return;
  }

  for(long i=0; i<modelData->nVariablesReal; i++) if(!modelData->realVarsData[i].filterOutput) {
    modelData->realVarsData[i].filterOutput = regexec(&myregex, modelData->realVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for(long i=0; i<modelData->nAliasReal; i++) if(!modelData->realAlias[i].filterOutput) {
    if(modelData->realAlias[i].aliasType == 0)  /* variable */ {
      modelData->realAlias[i].filterOutput = regexec(&myregex, modelData->realAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->realAlias[i].filterOutput) {
        modelData->realVarsData[modelData->realAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->realAlias[i].aliasType == 1)  /* parameter */ {
      modelData->realAlias[i].filterOutput = regexec(&myregex, modelData->realAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->realAlias[i].filterOutput && resultFormatHasCheapAliasesAndParameters) {
        modelData->realParameterData[modelData->realAlias[i].nameID].filterOutput = 0;
      }
    }
  }
  for (long i=0; i<modelData->nVariablesInteger; i++) if(!modelData->integerVarsData[i].filterOutput) {
    modelData->integerVarsData[i].filterOutput = regexec(&myregex, modelData->integerVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (long i=0; i<modelData->nAliasInteger; i++) if(!modelData->integerAlias[i].filterOutput) {
    if(modelData->integerAlias[i].aliasType == 0)  /* variable */ {
      modelData->integerAlias[i].filterOutput = regexec(&myregex, modelData->integerAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->integerAlias[i].filterOutput) {
        modelData->integerVarsData[modelData->integerAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->integerAlias[i].aliasType == 1)  /* parameter */ {
      modelData->integerAlias[i].filterOutput = regexec(&myregex, modelData->integerAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->integerAlias[i].filterOutput && resultFormatHasCheapAliasesAndParameters) {
        modelData->integerParameterData[modelData->integerAlias[i].nameID].filterOutput = 0;
      }
    }
  }
  for (long i=0; i<modelData->nVariablesBoolean; i++) if(!modelData->booleanVarsData[i].filterOutput) {
    modelData->booleanVarsData[i].filterOutput = regexec(&myregex, modelData->booleanVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (long i=0; i<modelData->nAliasBoolean; i++) if(!modelData->booleanAlias[i].filterOutput) {
    if(modelData->booleanAlias[i].aliasType == 0)  /* variable */ {
      modelData->booleanAlias[i].filterOutput = regexec(&myregex, modelData->booleanAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->booleanAlias[i].filterOutput) {
        modelData->booleanVarsData[modelData->booleanAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->booleanAlias[i].aliasType == 1)  /* parameter */ {
      modelData->booleanAlias[i].filterOutput = regexec(&myregex, modelData->booleanAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->booleanAlias[i].filterOutput && resultFormatHasCheapAliasesAndParameters) {
        modelData->booleanParameterData[modelData->booleanAlias[i].nameID].filterOutput = 0;
      }
    }
  }
  for (long i=0; i<modelData->nVariablesString; i++) if(!modelData->stringVarsData[i].filterOutput) {
    modelData->stringVarsData[i].filterOutput = regexec(&myregex, modelData->stringVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (long i=0; i<modelData->nAliasString; i++) if(!modelData->stringAlias[i].filterOutput) {
    if(modelData->stringAlias[i].aliasType == 0)  /* variable */ {
      modelData->stringAlias[i].filterOutput = regexec(&myregex, modelData->stringAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->stringAlias[i].filterOutput) {
        modelData->stringVarsData[modelData->stringAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->stringAlias[i].aliasType == 1)  /* parameter */ {
      modelData->stringAlias[i].filterOutput = regexec(&myregex, modelData->stringAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->stringAlias[i].filterOutput && resultFormatHasCheapAliasesAndParameters) {
        modelData->stringParameterData[modelData->stringAlias[i].nameID].filterOutput = 0;
      }
    }
  }
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
  int create_linearmodel = omc_flag[FLAG_L];
  const char* lintime = omc_flagValue[FLAG_L];

  /* activated measure time option with LOG_STATS */
  int measure_time_flag_previous = measure_time_flag;
  if(ACTIVE_STREAM(LOG_STATS) || (omc_flag[FLAG_CPU] && !measure_time_flag))
  {
    measure_time_flag = 1;
    measureSimTime = 1;
  }

  /* calc numStep */
  data->simulationInfo.numSteps = static_cast<modelica_integer>(round((data->simulationInfo.stopTime - data->simulationInfo.startTime)/data->simulationInfo.stepSize));
  infoStreamPrint(LOG_SOLVER, 0, "numberOfIntervals = %ld", (long) data->simulationInfo.numSteps);

  { /* Setup the clock */
    enum omc_rt_clock_t clock = OMC_CLOCK_REALTIME;
    const char *clockName;
    if((clockName = omc_flagValue[FLAG_CLOCK]) != NULL)
    {
      if(0 == strcmp(clockName, "CPU"))
      {
        clock = OMC_CLOCK_CPUTIME;
      }
      else if(0 == strcmp(clockName, "RT"))
      {
        clock = OMC_CLOCK_REALTIME;
      }
      else if(0 == strcmp(clockName, "CYC"))
      {
        clock = OMC_CPU_CYCLES;
      }
      else
      {
        warningStreamPrint(LOG_STDOUT, 0, "[unknown clock-type] got %s, expected CPU|RT|CYC. Defaulting to RT.", clockName);
      }
    }
    if(rt_set_clock(clock))
    {
      warningStreamPrint(LOG_STDOUT, 0, "Chosen clock-type: %s not available for the current platform. Defaulting to real-time.", clockName);
    }
  }

  if(measure_time_flag)
  {
    rt_tick(SIM_TIMER_INFO_XML);
    modelInfoXmlInit(&data->modelData.modelDataXml);
    rt_accumulate(SIM_TIMER_INFO_XML);
    //std::cerr << "ModelData with " << data->modelData.modelDataXml.nFunctions << " functions and " << data->modelData.modelDataXml.nEquations << " equations and " << data->modelData.modelDataXml.nProfileBlocks << " profileBlocks\n" << std::endl;
    rt_init(SIM_TIMER_FIRST_FUNCTION + data->modelData.modelDataXml.nFunctions + data->modelData.modelDataXml.nEquations + data->modelData.modelDataXml.nProfileBlocks + 4 /* sentinel */);
    rt_tick(SIM_TIMER_TOTAL);
    rt_tick(SIM_TIMER_PREINIT);
    rt_clear(SIM_TIMER_OUTPUT);
    rt_clear(SIM_TIMER_EVENT);
    rt_clear(SIM_TIMER_INIT);
  }

  if(create_linearmodel)
  {
    if(lintime == NULL)
      data->simulationInfo.stopTime = data->simulationInfo.startTime;
    else
      data->simulationInfo.stopTime = atof(lintime);
    infoStreamPrint(LOG_STDOUT, 0, "Linearization will performed at point of time: %f", data->simulationInfo.stopTime);
  }

  if(omc_flag[FLAG_S])
  {
    const string *method = new string(omc_flagValue[FLAG_S]);
    if(method)
    {
      data->simulationInfo.solverMethod = method->c_str();
      infoStreamPrint(LOG_SOLVER, 0, "overwrite solver method: %s [from command line]", data->simulationInfo.solverMethod);
    }
  }

  // Create a result file
  const char *result_file = omc_flagValue[FLAG_R];
  string result_file_cstr;
  if(!result_file)
    result_file_cstr = string(data->modelData.modelFilePrefix) + string("_res.") + data->simulationInfo.outputFormat; /* TODO: Fix result file name based on mode */
  else
    result_file_cstr = result_file;

  string init_initMethod = "";
  string init_optiMethod = "";
  string init_file = "";
  string init_time_string = "";
  double init_time = 0.0;
  string init_lambda_steps_string = "";
  int init_lambda_steps = 1;
  string outputVariablesAtEnd = "";
  int cpuTime = omc_flag[FLAG_CPU];

  if(omc_flag[FLAG_IIM])
  {
    init_initMethod = omc_flagValue[FLAG_IIM];
  }

  if(omc_flag[FLAG_IOM])
  {
    init_optiMethod = omc_flagValue[FLAG_IOM];
  }

  if(omc_flag[FLAG_IIF])
  {
    init_file = omc_flagValue[FLAG_IIF];
  }

  if(omc_flag[FLAG_IIT])
  {
    init_time_string = omc_flagValue[FLAG_IIT];
    init_time = atof(init_time_string.c_str());
  }

  if(omc_flag[FLAG_ILS])
  {
    init_lambda_steps_string = omc_flagValue[FLAG_ILS];
    init_lambda_steps = atoi(init_lambda_steps_string.c_str());
  }

  if(omc_flag[FLAG_OUTPUT])
  {
    outputVariablesAtEnd = omc_flagValue[FLAG_OUTPUT];
  }

  retVal = callSolver(data, result_file_cstr, init_initMethod, init_optiMethod, init_file, init_time, init_lambda_steps, outputVariablesAtEnd, cpuTime);

  if(0 == retVal && create_linearmodel)
  {
    rt_tick(SIM_TIMER_LINEARIZE);
    retVal = linearize(data);
    rt_accumulate(SIM_TIMER_LINEARIZE);
    infoStreamPrint(LOG_STDOUT, 0, "Linear model is created!");
  }

  /* Use the saved state of measure_time_flag.
   * measure_time_flag is set to active when LOG_STATS is ON.
   * So before doing the profiling reset the measure_time_flag to measure_time_flag_previous state.
   */
  measure_time_flag = measure_time_flag_previous;

  if(0 == retVal && measure_time_flag)
  {
    const string modelInfo = string(data->modelData.modelFilePrefix) + "_prof.xml";
    const string plotFile = string(data->modelData.modelFilePrefix) + "_prof.plt";
    rt_accumulate(SIM_TIMER_TOTAL);
    const char* plotFormat = omc_flagValue[FLAG_MEASURETIMEPLOTFORMAT];
    retVal = printModelInfo(data, modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat : "svg",
        data->simulationInfo.solverMethod, data->simulationInfo.outputFormat, result_file_cstr.c_str()) && retVal;
  }

  return retVal;
}

/*! \fn initializeResultData(DATA* simData, int cpuTime)
 *
 *  \param [ref] [simData]
 *  \param [int] [cpuTime]
 *
 *  This function initializes result object to emit data.
 */
int initializeResultData(DATA* simData, string result_file_cstr, int cpuTime)
{
  int resultFormatHasCheapAliasesAndParameters = 0;
  int retVal = 0;
  long maxSteps = 4 * simData->simulationInfo.numSteps;
  sim_result.filename = strdup(result_file_cstr.c_str());
  sim_result.numpoints = maxSteps;
  sim_result.cpuTime = cpuTime;
  if(isInteractiveSimulation() || sim_noemit || 0 == strcmp("empty", simData->simulationInfo.outputFormat)) {
    /* Default is set to noemit */
  } else if(0 == strcmp("csv", simData->simulationInfo.outputFormat)) {
    sim_result.init = omc_csv_init;
    sim_result.emit = omc_csv_emit;
    /* sim_result.writeParameterData = omc_csv_writeParameterData; */
    sim_result.free = omc_csv_free;
  } else if(0 == strcmp("mat", simData->simulationInfo.outputFormat)) {
    sim_result.init = mat4_init;
    sim_result.emit = mat4_emit;
    sim_result.writeParameterData = mat4_writeParameterData;
    sim_result.free = mat4_free;
    resultFormatHasCheapAliasesAndParameters = 1;
  } else if(0 == strcmp("wall", simData->simulationInfo.outputFormat)) {
    sim_result.init = recon_wall_init;
    sim_result.emit = recon_wall_emit;
    sim_result.writeParameterData = recon_wall_writeParameterData;
    sim_result.free = recon_wall_free;
    resultFormatHasCheapAliasesAndParameters = 1;
  } else if(0 == strcmp("plt", simData->simulationInfo.outputFormat)) {
    sim_result.init = plt_init;
    sim_result.emit = plt_emit;
    /* sim_result.writeParameterData = plt_writeParameterData; */
    sim_result.free = plt_free;
  } else {
    cerr << "Unknown output format: " << simData->simulationInfo.outputFormat << endl;
    return 1;
  }
  initializeOutputFilter(&(simData->modelData), simData->simulationInfo.variableFilter, resultFormatHasCheapAliasesAndParameters);
  sim_result.init(&sim_result, simData);
  infoStreamPrint(LOG_SOLVER, 0, "Allocated simulation result data storage for method '%s' and file='%s'", simData->simulationInfo.outputFormat, sim_result.filename);
  return 0;
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
    string init_optiMethod, string init_file, double init_time, int lambda_steps, string outputVariablesAtEnd, int cpuTime)
{
  int retVal = -1;
  long i;
  long solverID = S_UNKNOWN;
  const char* outVars = (outputVariablesAtEnd.size() == 0) ? NULL : outputVariablesAtEnd.c_str();

  if(initializeResultData(simData, result_file_cstr, cpuTime))
    return -1;

  if(std::string("") == simData->simulationInfo.solverMethod)
    solverID = S_DASSL;
  else
  {
    for(i=1; i<S_MAX; ++i)
    {
      if(std::string(SOLVER_METHOD_NAME[i]) == simData->simulationInfo.solverMethod)
        solverID = i;
    }
  }

  if(S_UNKNOWN == solverID)
  {
    warningStreamPrint(LOG_STDOUT, 0, "unrecognized option -s %s", simData->simulationInfo.solverMethod);
    warningStreamPrint(LOG_STDOUT, 0, "current options are:");
    for(i=1; i<S_MAX; ++i) {
      warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", SOLVER_METHOD_NAME[i], SOLVER_METHOD_DESC[i]);
    }
    throwStreamPrint(simData->threadData,"see last warning");
    retVal = 1;
  }
  else
  {
    infoStreamPrint(LOG_SOLVER, 0, "recognized solver: %s", SOLVER_METHOD_NAME[solverID]);
    /* special solvers */
#ifdef _OMC_QSS_LIB
    if(S_QSS == solverID)
    {
      retVal = qss_main(argc, argv, simData->simulationInfo.startTime,
                        simData->simulationInfo.stopTime, simData->simulationInfo.stepSize,
                        simData->simulationInfo.numSteps, simData->simulationInfo.tolerance, 3);
    }
    else /* standard solver interface */
#endif
      retVal = solver_main(simData, init_initMethod.c_str(), init_optiMethod.c_str(), init_file.c_str(), init_time, lambda_steps, solverID, outVars);
  }

  sim_result.free(&sim_result, simData);

  return retVal;
}


/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int initRuntimeAndSimulation(int argc, char**argv, DATA *data)
{
  int i;
  initDumpSystem();

  if(helpFlagSet(argc, argv) || checkCommandLineArguments(argc, argv))
  {
    infoStreamPrint(LOG_STDOUT, 1, "usage: %s", argv[0]);

    for(i=1; i<FLAG_MAX; ++i)
    {
      if(FLAG_TYPE[i] == FLAG_TYPE_FLAG) {
        infoStreamPrint(LOG_STDOUT, 0, "<-%s>\n  %s", FLAG_NAME[i], FLAG_DESC[i]);
      } else if(FLAG_TYPE[i] == FLAG_TYPE_OPTION) {
        infoStreamPrint(LOG_STDOUT, 0, "<-%s=value> or <-%s value>\n  %s", FLAG_NAME[i], FLAG_NAME[i], FLAG_DESC[i]);
      } else {
        warningStreamPrint(LOG_STDOUT, 0, "[unknown flag-type] <-%s>", FLAG_NAME[i]);
      }
    }

    messageClose(LOG_STDOUT);
    EXIT(0);
  }
  if (omc_flag[FLAG_LOG_FORMAT]) {
    if (0==strcmp(omc_flagValue[FLAG_LOG_FORMAT],"xml")) {
      setStreamPrintXML(1);
    } else if (0==strcmp(omc_flagValue[FLAG_LOG_FORMAT],"text")) {
      setStreamPrintXML(0);
    } else {
      warningStreamPrint(LOG_STDOUT, 0, "invalid command line option: -logFormat=%s, expected text or xml", omc_flagValue[FLAG_LOG_FORMAT]);
      EXIT(0);
    }
  }

  if(omc_flag[FLAG_HELP]) {
    std::string option = omc_flagValue[FLAG_HELP];

    for(i=1; i<FLAG_MAX; ++i)
    {
      if(option == std::string(FLAG_NAME[i]))
      {
        int j;

        if(FLAG_TYPE[i] == FLAG_TYPE_FLAG)
          infoStreamPrint(LOG_STDOUT, 1, "detailed flag-description for: <-%s>\n%s", FLAG_NAME[i], FLAG_DETAILED_DESC[i]);
        else if(FLAG_TYPE[i] == FLAG_TYPE_OPTION)
          infoStreamPrint(LOG_STDOUT, 1, "detailed flag-description for: <-%s=value> or <-%s value>\n%s", FLAG_NAME[i], FLAG_NAME[i], FLAG_DETAILED_DESC[i]);
        else
          warningStreamPrint(LOG_STDOUT, 1, "[unknown flag-type] <-%s>", FLAG_NAME[i]);

        /* detailed information for some flags */
        switch(i)
        {
        case FLAG_LV:
          for(j=firstOMCErrorStream; j<LOG_MAX; ++j)
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", LOG_STREAM_NAME[j], LOG_STREAM_DESC[j]);
          break;

        case FLAG_IIM:
          for(j=1; j<IIM_MAX; ++j)
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", INIT_METHOD_NAME[j], INIT_METHOD_DESC[j]);
          break;

        case FLAG_IOM:
          for(j=1; j<IOM_MAX; ++j)
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", OPTI_METHOD_NAME[j], OPTI_METHOD_DESC[j]);
          break;

        case FLAG_S:
          for(j=1; j<S_MAX; ++j) {
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", SOLVER_METHOD_NAME[j], SOLVER_METHOD_DESC[j]);
          }
          break;
        }
        messageClose(LOG_STDOUT);

        EXIT(0);
      }
    }

    warningStreamPrint(LOG_STDOUT, 0, "invalid command line option: -help=%s", option.c_str());
    warningStreamPrint(LOG_STDOUT, 0, "use %s -help for a list of all command-line flags", argv[0]);
    EXIT(0);
  }

  setGlobalVerboseLevel(argc, argv);
  initializeDataStruc(data);
  if(!data)
  {
    std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
  }

  data->simulationInfo.nlsMethod = getNonlinearSolverMethod(argc, argv);
  data->simulationInfo.lsMethod = getlinearSolverMethod(argc, argv);

  rt_tick(SIM_TIMER_INIT_XML);
  read_input_xml(&(data->modelData), &(data->simulationInfo));
  rt_accumulate(SIM_TIMER_INIT_XML);

  /* allocate memory for mixed system solvers */
  allocatemixedSystem(data);

  /* allocate memory for linear system solvers */
  allocatelinearSystem(data);

  /* allocate memory for non-linear system solvers */
  allocateNonlinearSystem(data);

  // this sets the static variable that is in the file with the generated-model functions
  if(data->modelData.nVariablesReal == 0 && data->modelData.nVariablesInteger && data->modelData.nVariablesBoolean)
  {
    std::cerr << "No variables in the model." << std::endl;
    return 1;
  }

  sim_noemit = omc_flag[FLAG_NOEMIT];

  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio

#ifndef NO_INTERACTIVE_DEPENDENCY
  interactiveSimulation = omc_flag[FLAG_INTERACTIVE];
  if(interactiveSimulation && omc_flag[FLAG_PORT])
  {
    cout << "userPort" << endl;
    std::istringstream stream(omc_flagValue[FLAG_PORT]);
    int userPort;
    stream >> userPort;
    setPortOfControlServer(userPort);
  }
  else if(!interactiveSimulation && omc_flag[FLAG_PORT])
  {
    std::istringstream stream(omc_flagValue[FLAG_PORT]);
    int port;
    stream >> port;
    sim_communication_port_open = 1;
    sim_communication_port_open &= sim_communication_port.create();
    sim_communication_port_open &= sim_communication_port.connect("127.0.0.1", port);
    communicateStatus("Starting", 0.0);
  }
#endif

  return 0;
}

static DATA *SimulationRuntime_printStatus_data = NULL;
void SimulationRuntime_printStatus(int sig)
{
  DATA *data = SimulationRuntime_printStatus_data;
  printf("<status>\n");
  printf("<model>%s</model>\n", data->modelData.modelFilePrefix);
  printf("<phase>UNKNOWN</phase>\n");
  printf("<currentStepSize>%g</currentStepSize>\n", data->simulationInfo.stepSize);
  printf("<oldTime>%.12g</oldTime>\n", data->localData[1]->timeValue);
  printf("<oldTime2>%.12g</oldTime2>\n", data->localData[2]->timeValue);
  printf("<diffOldTime>%g</diffOldTime>\n", data->localData[1]->timeValue-data->localData[2]->timeValue);
  printf("<currentTime>%g</currentTime>\n", data->localData[0]->timeValue);
  printf("<diffCurrentTime>%g</diffCurrentTime>\n", data->localData[0]->timeValue-data->localData[1]->timeValue);
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
  threadData_t *threadData = data->threadData;
  MMC_TRY_INTERNAL(globalJumpBuffer)
    if (initRuntimeAndSimulation(argc, argv, data)) //initRuntimeAndSimulation returns 1 if an error occurs
      return 1;

    /* sighandler_t oldhandler = different type on all platforms... */
#ifdef SIGUSR1
    SimulationRuntime_printStatus_data = data; /* Global, but at least we get something back; doesn't matter which simulation run */
    signal(SIGUSR1, SimulationRuntime_printStatus);
#endif

    if(interactiveSimulation)
    {
      cout << "startInteractiveSimulation: " << endl;
      retVal = startInteractiveSimulation(argc, argv, data);
    }
    else
    {
      retVal = startNonInteractiveSimulation(argc, argv, data);
    }

    freemixedSystem(data);        /* free mixed system data */
    freelinearSystem(data);       /* free linear system data */
    freeNonlinearSystem(data);    /* free nonlinear system data */

    data->callback->callExternalObjectDestructors(data);
    deInitializeDataStruc(data);
    fflush(NULL);
  MMC_CATCH_INTERNAL(globalJumpBuffer)

#ifndef NO_INTERACTIVE_DEPENDENCY
  if(sim_communication_port_open)
  {
    sim_communication_port.close();
  }
#endif

  return retVal;
}

static void omc_assert_simulation(threadData_t *threadData, FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
static void omc_throw_simulation(threadData_t* threadData) __attribute__ ((noreturn));

static void omc_assert_simulation(threadData_t *threadData, FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  switch (threadData->currentErrorStage)
  {
  case ERROR_EVENTSEARCH:
  case ERROR_OPTIMIZE:
  case ERROR_SIMULATION:
    va_start(ap,msg);
    fputs("Error: ",stderr);
    vfprintf(stderr,msg,ap);
    fputs("\n",stderr);
    va_end(ap);
    fflush(NULL);
    longjmp(*threadData->simulationJumpBuffer,1);
    break;
  case ERROR_NONLINEARSOLVER:
    if(ACTIVE_STREAM(LOG_NLS))
    {
      va_start(ap,msg);
      fputs("Error: ",stderr);
      vfprintf(stderr,msg,ap);
      fputs("\n",stderr);
      fflush(NULL);
      va_end(ap);
    }
#ifndef OMC_EMCC
    longjmp(*threadData->simulationJumpBuffer,1);
#endif
    break;
  case ERROR_INTEGRATOR:
    if(ACTIVE_STREAM(LOG_SOLVER))
    {
      va_start(ap,msg);
      fputs("Error: ",stderr);
      vfprintf(stderr,msg,ap);
      fputs("\n",stderr);
      fflush(NULL);
      va_end(ap);
    }
    longjmp(*threadData->simulationJumpBuffer,1);
    break;
  default:
    throwStreamPrint(threadData,"Unhandled Assertion-Error");
  }
}

static void omc_assert_warning_simulation(FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  fputs("Warning: ",stderr);
  vfprintf(stderr,msg,ap);
  fputs("\n",stderr);
  fflush(NULL);
  va_end(ap);
}

static void omc_terminate_simulation(FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  terminationTerminate = 1;
  setTermMsg(msg,ap);
  va_end(ap);
  TermInfo = info;
}

static void omc_throw_simulation(threadData_t* threadData)
{
  va_list ap;
  setTermMsg("Assertion triggered by external C function", ap);
  set_struct(FILE_INFO, TermInfo, omc_dummyFileInfo);
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  longjmp(*threadData->globalJumpBuffer, 1);
}

void (*omc_assert)(threadData_t*,FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn)) = omc_assert_simulation;
void (*omc_assert_warning)(FILE_INFO info, const char *msg, ...) = omc_assert_warning_simulation;
void (*omc_terminate)(FILE_INFO info, const char *msg, ...) = omc_terminate_simulation;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_simulation;

} // extern "C"
