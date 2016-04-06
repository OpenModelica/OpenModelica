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

#include "util/omc_msvc.h"

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


/* ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
 *
 */
#ifndef NO_INTERACTIVE_DEPENDENCY
  #include "socket.h"
  extern Socket sim_communication_port;
#endif

#include "util/omc_error.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "meta/meta_modelica.h"

#include "linearize.h"
#include "options.h"
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "simulation/results/simulation_result_plt.h"
#include "simulation/results/simulation_result_csv.h"
#include "simulation/results/simulation_result_mat.h"
#include "simulation/results/simulation_result_wall.h"
#include "simulation/results/simulation_result_ia.h"
#include "simulation/solver/solver_main.h"
#include "simulation_info_json.h"
#include "modelinfo.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/mixedSystem.h"
#include "simulation/solver/linearSystem.h"
#include "simulation/solver/nonlinearSystem.h"
#include "util/rtclock.h"
#include "omc_config.h"
#include "simulation/solver/initialization/initialization.h"

#ifdef _OMC_QSS_LIB
  #include "solver_qss/solver_qss.h"
#endif

using namespace std;

#ifndef NO_INTERACTIVE_DEPENDENCY
  Socket sim_communication_port;
  static int sim_communication_port_open = 0;
#endif

extern "C" {

int sim_noemit = 0;           /* Flag for not emitting data */

const std::string *init_method = NULL; /* method for  initialization. */

static int callSolver(DATA* simData, threadData_t *threadData, string init_initMethod, string init_file,
      double init_time, int lambda_steps, string outputVariablesAtEnd, int cpuTime, const char *argv_0);

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
    for(i=1; i<SIM_LOG_MAX; ++i)
      useStream[i] = 1;
  }
  else
  {
    string flagList = *flags;
    string flag;
    mmc_uint_t pos;

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

      for(i=firstOMCErrorStream; i<SIM_LOG_MAX; ++i)
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
        for(i=firstOMCErrorStream; i<SIM_LOG_MAX; ++i)
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

  /* print LOG_STATS if LOG_STATS_V if active */
  if(useStream[LOG_STATS_V] == 1)
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

static int getNonlinearSolverMethod()
{
  int i;
  const char *cflags = omc_flagValue[FLAG_NLS];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return NLS_MIXED; /* default method */

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

static int getlinearSolverMethod()
{
  int i;
  const char *cflags = omc_flagValue[FLAG_LS];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return LS_DEFAULT; /* default method */

  for(i=1; i<LS_MAX; ++i)
    if(*method == LS_NAME[i])
      return i;

  warningStreamPrint(LOG_STDOUT, 1, "unrecognized option -ls=%s, current options are:", method->c_str());
  for(i=1; i<LS_MAX; ++i)
    warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", LS_NAME[i], LS_DESC[i]);
  messageClose(LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");

  return LS_NONE;
}

static int getlinearSparseSolverMethod()
{
  int i;
  const char *cflags = omc_flagValue[FLAG_LSS];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return LSS_KLU; /* default method */

  for(i=1; i<LSS_MAX; ++i)
    if(*method == LSS_NAME[i])
      return i;

  warningStreamPrint(LOG_STDOUT, 1, "unrecognized option -lss=%s, current options are:", method->c_str());
  for(i=1; i<LSS_MAX; ++i)
    warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", LSS_NAME[i], LSS_DESC[i]);
  messageClose(LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");

  return LSS_NONE;
}

static int getNewtonStrategy()
{
  int i;
  const char *cflags = omc_flagValue[FLAG_NEWTON_STRATEGY];
  const string *method = cflags ? new string(cflags) : NULL;

  if(!method)
    return NEWTON_DAMPED2; /* default method */

  for(i=1; i<NEWTON_MAX; ++i)
    if(*method == NEWTONSTRATEGY_NAME[i])
      return i;

  warningStreamPrint(LOG_STDOUT, 1, "unrecognized option -nls=%s, current options are:", method->c_str());
  for(i=1; i<NEWTON_MAX; ++i)
    warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", NEWTONSTRATEGY_NAME[i], NEWTONSTRATEGY_DESC[i]);
  messageClose(LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");

  return NEWTON_NONE;
}

static double getFlagReal(enum _FLAG flag, double res)
{
  const char *flagStr = omc_flagValue[flag];
  char *endptr;
  if (flagStr==NULL || *flagStr=='\0') {
    return res;
  }
  res = strtod(flagStr, &endptr);
  if (*endptr) {
    throwStreamPrint(NULL, "Simulation flag %s expects a real number, got: %s", FLAG_NAME[flag], flagStr);
  }
  return res;
}

/**
 * Read the variable filter and mark variables that should not be part of the result file.
 * This phase is skipped for interactive simulations
 */
void initializeOutputFilter(MODEL_DATA *modelData, const char *variableFilter, int resultFormatHasCheapAliasesAndParameters)
{
#ifndef _MSC_VER
  regex_t myregex;
  int flags = REG_EXTENDED;
  int rc;
  string tmp = ("^(" + string(variableFilter) + ")$");
  const char *filter = tmp.c_str(); // C++ strings are horrible to work with...

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

  for(mmc_sint_t i=0; i<modelData->nVariablesReal; i++) if(!modelData->realVarsData[i].filterOutput) {
    modelData->realVarsData[i].filterOutput = regexec(&myregex, modelData->realVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for(mmc_sint_t i=0; i<modelData->nAliasReal; i++) if(!modelData->realAlias[i].filterOutput) {
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
  for (mmc_sint_t i=0; i<modelData->nVariablesInteger; i++) if(!modelData->integerVarsData[i].filterOutput) {
    modelData->integerVarsData[i].filterOutput = regexec(&myregex, modelData->integerVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (mmc_sint_t i=0; i<modelData->nAliasInteger; i++) if(!modelData->integerAlias[i].filterOutput) {
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
  for (mmc_sint_t i=0; i<modelData->nVariablesBoolean; i++) if(!modelData->booleanVarsData[i].filterOutput) {
    modelData->booleanVarsData[i].filterOutput = regexec(&myregex, modelData->booleanVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (mmc_sint_t i=0; i<modelData->nAliasBoolean; i++) if(!modelData->booleanAlias[i].filterOutput) {
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
  for (mmc_sint_t i=0; i<modelData->nVariablesString; i++) if(!modelData->stringVarsData[i].filterOutput) {
    modelData->stringVarsData[i].filterOutput = regexec(&myregex, modelData->stringVarsData[i].info.name, 0, NULL, 0) != 0;
  }
  for (mmc_sint_t i=0; i<modelData->nAliasString; i++) if(!modelData->stringAlias[i].filterOutput) {
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
int startNonInteractiveSimulation(int argc, char**argv, DATA* data, threadData_t *threadData)
{
  TRACE_PUSH

  int retVal = -1;

  /* linear model option is set : <-l lintime> */
  int create_linearmodel = omc_flag[FLAG_L];
  const char* lintime = omc_flagValue[FLAG_L];

  /* activated measure time option with LOG_STATS */
  int measure_time_flag_previous = measure_time_flag;
  if (!measure_time_flag && (ACTIVE_STREAM(LOG_STATS) || omc_flag[FLAG_CPU]))
  {
    measure_time_flag = 1;
  }
  errno = 0;
  if (omc_flag[FLAG_ALARM]) {
    char *endptr;
    mmc_sint_t alarmVal = strtol(omc_flagValue[FLAG_ALARM],&endptr,10);
    if (errno || *endptr != 0) {
      throwStreamPrint(threadData, "-alarm takes an integer argument (got '%s')", omc_flagValue[FLAG_ALARM]);
    }
    alarm(alarmVal);
  }

  /* calc numStep */
  data->simulationInfo->numSteps = static_cast<modelica_integer>(round((data->simulationInfo->stopTime - data->simulationInfo->startTime)/data->simulationInfo->stepSize));
  infoStreamPrint(LOG_SOLVER, 0, "numberOfIntervals = %ld", (long) data->simulationInfo->numSteps);

  { /* Setup the clock */
    enum omc_rt_clock_t clock = OMC_CLOCK_REALTIME;
    const char *clockName;
    if((clockName = omc_flagValue[FLAG_CLOCK]) != NULL) {
      if(0 == strcmp(clockName, "CPU")) {
        clock = OMC_CLOCK_CPUTIME;
      } else if(0 == strcmp(clockName, "RT")) {
        clock = OMC_CLOCK_REALTIME;
      } else if(0 == strcmp(clockName, "CYC")) {
        clock = OMC_CPU_CYCLES;
      } else {
        warningStreamPrint(LOG_STDOUT, 0, "[unknown clock-type] got %s, expected CPU|RT|CYC. Defaulting to RT.", clockName);
      }
    }
    if(rt_set_clock(clock)) {
      warningStreamPrint(LOG_STDOUT, 0, "Chosen clock-type: %s not available for the current platform. Defaulting to real-time.", clockName);
    }
  }

  if(measure_time_flag) {
    rt_tick(SIM_TIMER_INFO_XML);
    modelInfoInit(&data->modelData->modelDataXml);
    rt_accumulate(SIM_TIMER_INFO_XML);
    //std::cerr << "ModelData with " << data->modelData->modelDataXml.nFunctions << " functions and " << data->modelData->modelDataXml.nEquations << " equations and " << data->modelData->modelDataXml.nProfileBlocks << " profileBlocks\n" << std::endl;
    rt_init(SIM_TIMER_FIRST_FUNCTION + data->modelData->modelDataXml.nFunctions + data->modelData->modelDataXml.nEquations + data->modelData->modelDataXml.nProfileBlocks + 4 /* sentinel */);
    rt_measure_overhead(SIM_TIMER_TOTAL);
    rt_clear(SIM_TIMER_TOTAL);
    rt_tick(SIM_TIMER_TOTAL);
    rt_tick(SIM_TIMER_PREINIT);
    rt_clear(SIM_TIMER_OUTPUT);
    rt_clear(SIM_TIMER_EVENT);
    rt_clear(SIM_TIMER_INIT);
  }

  if(create_linearmodel)
  {
    if(lintime == NULL) {
      data->simulationInfo->stopTime = data->simulationInfo->startTime;
    } else {
      data->simulationInfo->stopTime = atof(lintime);
    }
    infoStreamPrint(LOG_STDOUT, 0, "Linearization will performed at point of time: %f", data->simulationInfo->stopTime);
  }

  if(omc_flag[FLAG_S]) {
    if (omc_flagValue[FLAG_S]) {
      data->simulationInfo->solverMethod = GC_strdup(omc_flagValue[FLAG_S]);
      infoStreamPrint(LOG_SOLVER, 0, "overwrite solver method: %s [from command line]", data->simulationInfo->solverMethod);
    }
  }

  // Create a result file
  const char *result_file = omc_flagValue[FLAG_R];
  string result_file_cstr;
  if(!result_file) {
    result_file_cstr = string(data->modelData->modelFilePrefix) + string("_res.") + data->simulationInfo->outputFormat;
    data->modelData->resultFileName = GC_strdup(result_file_cstr.c_str());
  } else {
    data->modelData->resultFileName = GC_strdup(result_file);
  }

  string init_initMethod = "";
  string init_file = "";
  string init_time_string = "";
  double init_time = 0.0;
  string init_lambda_steps_string = "";
  int init_lambda_steps = 1;
  string outputVariablesAtEnd = "";
  int cpuTime = omc_flag[FLAG_CPU];

  if(omc_flag[FLAG_IIM]) {
    init_initMethod = omc_flagValue[FLAG_IIM];
  }
  if(omc_flag[FLAG_IIF]) {
    init_file = omc_flagValue[FLAG_IIF];
  }
  if(omc_flag[FLAG_IIT]) {
    init_time_string = omc_flagValue[FLAG_IIT];
    init_time = atof(init_time_string.c_str());
  }
  if(omc_flag[FLAG_ILS]) {
    init_lambda_steps_string = omc_flagValue[FLAG_ILS];
    init_lambda_steps = atoi(init_lambda_steps_string.c_str());
  }
  if(omc_flag[FLAG_MAX_EVENT_ITERATIONS]) {
    maxEventIterations = atoi(omc_flagValue[FLAG_MAX_EVENT_ITERATIONS]);
    infoStreamPrint(LOG_STDOUT, 0, "Maximum number of event iterations changed to %d", maxEventIterations);
  }
  if(omc_flag[FLAG_OUTPUT]) {
    outputVariablesAtEnd = omc_flagValue[FLAG_OUTPUT];
  }

  retVal = callSolver(data, threadData, init_initMethod, init_file, init_time, init_lambda_steps, outputVariablesAtEnd, cpuTime, argv[0]);

  if (omc_flag[FLAG_ALARM]) {
    alarm(0);
  }

  if(0 == retVal && create_linearmodel) {
    rt_tick(SIM_TIMER_LINEARIZE);
    retVal = linearize(data, threadData);
    rt_accumulate(SIM_TIMER_LINEARIZE);
    infoStreamPrint(LOG_STDOUT, 0, "Linear model is created!");
  }

  /* Use the saved state of measure_time_flag.
   * measure_time_flag is set to active when LOG_STATS is ON.
   * So before doing the profiling reset the measure_time_flag to measure_time_flag_previous state.
   */
  measure_time_flag = measure_time_flag_previous;

  if(0 == retVal && measure_time_flag) {
    const string jsonInfo = string(data->modelData->modelFilePrefix) + "_prof.json";
    const string modelInfo = string(data->modelData->modelFilePrefix) + "_prof.xml";
    const string plotFile = string(data->modelData->modelFilePrefix) + "_prof.plt";
    rt_accumulate(SIM_TIMER_TOTAL);
    const char* plotFormat = omc_flagValue[FLAG_MEASURETIMEPLOTFORMAT];
    retVal = printModelInfo(data, threadData, modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat : "svg",
        data->simulationInfo->solverMethod, data->simulationInfo->outputFormat, data->modelData->resultFileName) && retVal;
    retVal = printModelInfoJSON(data, threadData, jsonInfo.c_str(), data->modelData->resultFileName) && retVal;
  }

  TRACE_POP
  return retVal;
}

/*! \fn initializeResultData(DATA* simData, int cpuTime)
 *
 *  \param [ref] [simData]
 *  \param [int] [cpuTime]
 *
 *  This function initializes result object to emit data.
 */
int initializeResultData(DATA* simData, threadData_t *threadData, int cpuTime)
{
  int resultFormatHasCheapAliasesAndParameters = 0;
  int retVal = 0;
  mmc_sint_t maxSteps = 4 * simData->simulationInfo->numSteps;
  sim_result.filename = strdup(simData->modelData->resultFileName);
  sim_result.numpoints = maxSteps;
  sim_result.cpuTime = cpuTime;
  if (sim_noemit || 0 == strcmp("empty", simData->simulationInfo->outputFormat)) {
    /* Default is set to noemit */
  } else if(0 == strcmp("csv", simData->simulationInfo->outputFormat)) {
    sim_result.init = omc_csv_init;
    sim_result.emit = omc_csv_emit;
    /* sim_result.writeParameterData = omc_csv_writeParameterData; */
    sim_result.free = omc_csv_free;
  } else if(0 == strcmp("mat", simData->simulationInfo->outputFormat)) {
    sim_result.init = mat4_init;
    sim_result.emit = mat4_emit;
    sim_result.writeParameterData = mat4_writeParameterData;
    sim_result.free = mat4_free;
    resultFormatHasCheapAliasesAndParameters = 1;
#if !defined(OMC_MINIMAL_RUNTIME)
  } else if(0 == strcmp("wall", simData->simulationInfo->outputFormat)) {
    sim_result.init = recon_wall_init;
    sim_result.emit = recon_wall_emit;
    sim_result.writeParameterData = recon_wall_writeParameterData;
    sim_result.free = recon_wall_free;
    resultFormatHasCheapAliasesAndParameters = 1;
  } else if(0 == strcmp("plt", simData->simulationInfo->outputFormat)) {
    sim_result.init = plt_init;
    sim_result.emit = plt_emit;
    /* sim_result.writeParameterData = plt_writeParameterData; */
    sim_result.free = plt_free;
  }
  //NEW interactive
  else if(0 == strcmp("ia", simData->simulationInfo->outputFormat)) {
    sim_result.init = ia_init;
    sim_result.emit = ia_emit;
    //sim_result.writeParameterData = ia_writeParameterData;
    sim_result.free = ia_free;
#endif
  } else {
    cerr << "Unknown output format: " << simData->simulationInfo->outputFormat << endl;
    return 1;
  }
  initializeOutputFilter(simData->modelData, simData->simulationInfo->variableFilter, resultFormatHasCheapAliasesAndParameters);
  sim_result.init(&sim_result, simData, threadData);
  infoStreamPrint(LOG_SOLVER, 0, "Allocated simulation result data storage for method '%s' and file='%s'", (char*) simData->simulationInfo->outputFormat, sim_result.filename);
  return 0;
}

/**
 * Calls the solver which is selected in the parameter string "method"
 * This function is used for interactive and non-interactive simulation
 * Parameter method:
 * "" & "dassl" calls a DASSL Solver
 * "euler" calls an Euler solver
 * "rungekutta" calls a fourth-order Runge-Kutta Solver
 */
static int callSolver(DATA* simData, threadData_t *threadData, string init_initMethod, string init_file,
      double init_time, int lambda_steps, string outputVariablesAtEnd, int cpuTime, const char *argv_0)
{
  TRACE_PUSH
  int retVal = -1;
  mmc_sint_t i;
  mmc_sint_t solverID = S_UNKNOWN;
  const char* outVars = (outputVariablesAtEnd.size() == 0) ? NULL : outputVariablesAtEnd.c_str();
  MMC_TRY_INTERNAL(mmc_jumper)
  MMC_TRY_INTERNAL(globalJumpBuffer)

  if (initializeResultData(simData, threadData, cpuTime)) {
    TRACE_POP
    return -1;
  }
  simData->real_time_sync.scaling = getFlagReal(FLAG_RT, 0.0);

  if(std::string("") == simData->simulationInfo->solverMethod) {
#if defined(WITH_DASSL)
    solverID = S_DASSL;
#else
    solverID = S_RUNGEKUTTA;
#endif
  } else {
    for(i=1; i<S_MAX; ++i) {
      if(std::string(SOLVER_METHOD_NAME[i]) == simData->simulationInfo->solverMethod) {
        solverID = i;
      }
    }
  }
  /* if no states are present, then we can
   * use euler method, since it does nothing.
   */
  if (simData->modelData->nStates < 1 && solverID != S_OPTIMIZATION && solverID != S_SYM_EULER) {
    solverID = S_EULER;
  }

  if(S_UNKNOWN == solverID) {
    warningStreamPrint(LOG_STDOUT, 0, "unrecognized option -s %s", (char*) simData->simulationInfo->solverMethod);
    warningStreamPrint(LOG_STDOUT, 0, "current options are:");
    for(i=1; i<S_MAX; ++i) {
      warningStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", SOLVER_METHOD_NAME[i], SOLVER_METHOD_DESC[i]);
    }
    throwStreamPrint(threadData,"see last warning");
    retVal = 1;
  } else {
    infoStreamPrint(LOG_SOLVER, 0, "recognized solver: %s", SOLVER_METHOD_NAME[solverID]);
    /* special solvers */
#ifdef _OMC_QSS_LIB
    if(S_QSS == solverID) {
      retVal = qss_main(argc, argv, simData->simulationInfo->startTime,
                        simData->simulationInfo->stopTime, simData->simulationInfo->stepSize,
                        simData->simulationInfo->numSteps, simData->simulationInfo->tolerance, 3);
    } else /* standard solver interface */
#endif
      retVal = solver_main(simData, threadData, init_initMethod.c_str(), init_file.c_str(), init_time, lambda_steps, solverID, outVars, argv_0);
  }

  MMC_CATCH_INTERNAL(mmc_jumper)
  MMC_CATCH_INTERNAL(globalJumpBuffer)

  sim_result.free(&sim_result, simData, threadData);

  TRACE_POP
  return retVal;
}


/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int initRuntimeAndSimulation(int argc, char**argv, DATA *data, threadData_t *threadData)
{
  int i;
  initDumpSystem();

  if(setLogFormat(argc, argv) || helpFlagSet(argc, argv) || checkCommandLineArguments(argc, argv))
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
          for(j=firstOMCErrorStream; j<SIM_LOG_MAX; ++j)
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", LOG_STREAM_NAME[j], LOG_STREAM_DESC[j]);
          break;

        case FLAG_IIM:
          for(j=1; j<IIM_MAX; ++j)
            infoStreamPrint(LOG_STDOUT, 0, "%-18s [%s]", INIT_METHOD_NAME[j], INIT_METHOD_DESC[j]);
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
  initializeDataStruc(data, threadData);
  if(!data)
  {
    std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
    EXIT(1);
  }

  data->simulationInfo->nlsMethod = getNonlinearSolverMethod();
  data->simulationInfo->lsMethod = getlinearSolverMethod();
  data->simulationInfo->lssMethod = getlinearSparseSolverMethod();
  data->simulationInfo->newtonStrategy = getNewtonStrategy();
  data->simulationInfo->nlsCsvInfomation = omc_flag[FLAG_NLS_INFO];

  if(omc_flag[FLAG_LSS_MAX_DENSITY]) {
    linearSparseSolverMaxDensity = atof(omc_flagValue[FLAG_LSS_MAX_DENSITY]);
    infoStreamPrint(LOG_STDOUT, 0, "Maximum density for using linear sparse solver changed to %f", linearSparseSolverMaxDensity);
  }
  if(omc_flag[FLAG_LSS_MIN_SIZE]) {
    linearSparseSolverMinSize = atoi(omc_flagValue[FLAG_LSS_MIN_SIZE]);
    infoStreamPrint(LOG_STDOUT, 0, "Maximum system size for using linear sparse solver changed to %d", linearSparseSolverMinSize);
  }

  rt_tick(SIM_TIMER_INIT_XML);
  read_input_xml(data->modelData, data->simulationInfo);
  rt_accumulate(SIM_TIMER_INIT_XML);

  /* initialize static data of mixed/linear/non-linear system solvers */
  initializeMixedSystems(data, threadData);
  initializeLinearSystems(data, threadData);
  initializeNonlinearSystems(data, threadData);

  sim_noemit = omc_flag[FLAG_NOEMIT];

  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio

#ifndef NO_INTERACTIVE_DEPENDENCY
  if(omc_flag[FLAG_PORT])
  {
    std::istringstream stream(omc_flagValue[FLAG_PORT]);
    int port;
    stream >> port;
    sim_communication_port_open = 1;
    sim_communication_port_open &= sim_communication_port.create();
    sim_communication_port_open &= sim_communication_port.connect("127.0.0.1", port);

    if(0 != strcmp("ia", data->simulationInfo->outputFormat))
    {
      communicateStatus("Starting", 0.0);
    }
  }
#endif

  return 0;
}

static DATA *SimulationRuntime_printStatus_data = NULL;
void SimulationRuntime_printStatus(int sig)
{
  DATA *data = SimulationRuntime_printStatus_data;
  printf("<status>\n");
  printf("<model>%s</model>\n", data->modelData->modelFilePrefix);
  printf("<phase>UNKNOWN</phase>\n");
  printf("<currentStepSize>%g</currentStepSize>\n", data->simulationInfo->stepSize);
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
  if(sim_communication_port_open)
  {
    std::stringstream s;
    s << (int)(completionPercent*10000) << " " << phase << endl;
    std::string str(s.str());
    sim_communication_port.send(str);
    // cout << str;
  }
#endif
}

void communicateMsg(char id, unsigned int size, const char *data)
{
#ifndef NO_INTERACTIVE_DEPENDENCY
  if(sim_communication_port_open)
  {
    int msgSize = sizeof(char) + sizeof(unsigned int) + size;
    char* msg = new char[msgSize];
    memcpy(msg+0, &id, sizeof(char));
    memcpy(msg+sizeof(char), &size, sizeof(unsigned int));
    memcpy(msg+sizeof(char)+sizeof(unsigned int), data, size);
    sim_communication_port.sendBytes(msg, msgSize);
    delete[] msg;
  }
#endif
}


/* \brief main function for simulator
 *
 * The arguments for the main function are:
 * -v verbose = debug
 * -vf = flags set verbosity flags
 * -f init_file.txt use input data from init file.
 * -r res.plt write result to file.
 */

int _main_SimulationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData)
{
  int retVal = -1;
  MMC_TRY_INTERNAL(globalJumpBuffer)
    if (initRuntimeAndSimulation(argc, argv, data, threadData)) //initRuntimeAndSimulation returns 1 if an error occurs
      return 1;

    /* sighandler_t oldhandler = different type on all platforms... */
#ifdef SIGUSR1
    SimulationRuntime_printStatus_data = data; /* Global, but at least we get something back; doesn't matter which simulation run */
    signal(SIGUSR1, SimulationRuntime_printStatus);
#endif

    retVal = startNonInteractiveSimulation(argc, argv, data, threadData);

    freeMixedSystems(data, threadData);        /* free mixed system data */
    freeLinearSystems(data, threadData);       /* free linear system data */
    freeNonlinearSystems(data, threadData);    /* free nonlinear system data */

    data->callback->callExternalObjectDestructors(data, threadData);
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

#if !defined(OMC_MINIMAL_RUNTIME)
const char* prettyPrintNanoSec(int64_t ns, int *v)
{
  if (ns > 100000000000L || ns < -100000000000L) {
    *v = ns / 1000000000L;
    return "s";
  } if (ns > 100000000L || ns < -100000000L) {
    *v = ns / 1000000L;
    return "ms";
  } else if (ns > 100000L || ns < -100000L) {
    *v = ns / 1000L;
    return "µs";
  } else {
    *v = ns;
    return "ns";
  }
}
#endif

} // extern "C"
