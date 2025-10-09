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

/* For CommandLineToArgvW. */
#if defined(__MINGW32__) || defined(_MSC_VER)
#include <windows.h>
#include <shellapi.h>
#endif

/* ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio
 *
 */
#ifndef NO_INTERACTIVE_DEPENDENCY
  #include "socket.h"
  extern Socket sim_communication_port;
#endif

#include "util/omc_error.h"
#include "util/omc_file.h"
#include "util/omc_numbers.h"
#include "simulation_data.h"
#include "openmodelica_func.h"
#include "meta/meta_modelica.h"

#include "linearization/linearize.h"
#include "options.h"
#include "simulation_runtime.h"
#include "simulation_input_xml.h"
#include "simulation/results/simulation_result_plt.h"
#include "simulation/results/simulation_result_csv.h"
#include "simulation/results/simulation_result_mat4.h"
#include "simulation/results/simulation_result_wall.h"
#include "simulation/results/simulation_result_ia.h"
#include "simulation/solver/solver_main.h"
#include "simulation/solver/gbode_util.h"
#include "simulation_info_json.h"
#include "modelinfo.h"
#include "simulation/solver/events.h"
#include "simulation/solver/model_help.h"
#include "simulation/solver/mixedSystem.h"
#include "simulation/solver/linearSystem.h"
#include "simulation/solver/nonlinearSystem.h"
#include "util/rtclock.h"
#include "omc_config.h"
#include "simulation/solver/initialization/initialization.h"
#include "simulation/solver/dae_mode.h"
#include "dataReconciliation/dataReconciliation.h"
#include "util/parallel_helper.h"

#ifdef _OMC_QSS_LIB
  #include "solver_qss/solver_qss.h"
#endif

using namespace std;

#ifndef NO_INTERACTIVE_DEPENDENCY
  Socket sim_communication_port;
  static int sim_communication_port_open = 0;
  static int isXMLTCP=0;
#endif

extern "C" {

int sim_noemit = 0;           /* Flag for not emitting data */

const std::string *init_method = NULL; /* method for  initialization. */

static int callSolver(DATA* simData, threadData_t *threadData, string init_initMethod, string init_file,
      double init_time, string outputVariablesAtEnd, int cpuTime, const char *argv_0);

/*! \fn void setGlobalVerboseLevel(int argc, char**argv)
 *
 *  \brief determine verboselevel by investigating flag -lv flags
 *
 *  Valid flags: see OMC_LOG_STREAM_NAME in omc_error.c
 */
void setGlobalVerboseLevel(int argc, char**argv)
{
  const char *cflags = omc_flagValue[FLAG_LV];
  const string *flags = cflags ? new string(cflags) : NULL;
  int i;

  if(omc_flag[FLAG_W])
    omc_showAllWarnings = 1;

  if(!flags)
  {
    /* default activated */
    omc_useStream[OMC_LOG_STDOUT] = 1;
    omc_useStream[OMC_LOG_ASSERT] = 1;
    omc_useStream[OMC_LOG_SUCCESS] = 1;
    return; // no lv flag given.
  }

  /* default activated, but it can be disabled with -LOG_STDOUT or -LOG_ASSERT */
  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;

  if(flags->find("LOG_ALL", 0) != string::npos)
  {
    for(i=1; i<OMC_SIM_LOG_MAX; ++i)
      omc_useStream[i] = 1;
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

      for(i=firstOMCErrorStream; i<OMC_SIM_LOG_MAX; ++i)
      {
        if(flag == string(OMC_LOG_STREAM_NAME[i]))
        {
          omc_useStream[i] = 1;
          error = 0;
          break;
        }
        else if(flag == string("-") + string(OMC_LOG_STREAM_NAME[i]))
        {
          omc_useStream[i] = 0;
          error = 0;
          break;
        }
      }

      if(error)
      {
        warningStreamPrint(OMC_LOG_STDOUT, 1, "current options are:");
        for(i=firstOMCErrorStream; i<OMC_SIM_LOG_MAX; ++i)
          warningStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", OMC_LOG_STREAM_NAME[i], OMC_LOG_STREAM_DESC[i]);
        messageClose(OMC_LOG_STDOUT);
        throwStreamPrint(NULL,"unrecognized option -lv %s", flags->c_str());
      }
    }while(pos != string::npos);
  }

  /* print OMC_LOG_GBODE if OMC_LOG_GBODE_V if active */
  if(omc_useStream[OMC_LOG_GBODE_V] == 1)
    omc_useStream[OMC_LOG_GBODE] = 1;

  /* print OMC_LOG_GBODE_NLS if OMC_LOG_GBODE_NLS_V if active */
  if(omc_useStream[OMC_LOG_GBODE_NLS_V] == 1)
    omc_useStream[OMC_LOG_GBODE_NLS] = 1;

  /* print OMC_LOG_INIT and OMC_LOG_SOTI if OMC_LOG_INIT_V is active */
  if(omc_useStream[OMC_LOG_INIT_V] == 1)
  {
    omc_useStream[OMC_LOG_INIT] = 1;
    omc_useStream[OMC_LOG_SOTI] = 1;
  }

  /* print OMC_LOG_INIT_HOMOTOPY if OMC_LOG_INIT is active */
  if(omc_useStream[OMC_LOG_INIT] == 1)
    omc_useStream[OMC_LOG_INIT_HOMOTOPY] = 1;

  /* print OMC_LOG_STATS if OMC_LOG_SOLVER if active */
  if(omc_useStream[OMC_LOG_SOLVER_V] == 1)
    omc_useStream[OMC_LOG_SOLVER] = 1;

  /* print OMC_LOG_STATS if OMC_LOG_SOLVER if active */
  if(omc_useStream[OMC_LOG_SOLVER] == 1)
    omc_useStream[OMC_LOG_STATS] = 1;

  /* print OMC_LOG_STATS if OMC_LOG_STATS_V if active */
  if(omc_useStream[OMC_LOG_STATS_V] == 1)
    omc_useStream[OMC_LOG_STATS] = 1;

  /* print OMC_LOG_NLS if OMC_LOG_NLS_V if active */
  if(omc_useStream[OMC_LOG_NLS_V])
    omc_useStream[OMC_LOG_NLS] = 1;

  /* print OMC_LOG_NLS if OMC_LOG_NLS_RES if active */
  if(omc_useStream[OMC_LOG_NLS_RES])
    omc_useStream[OMC_LOG_NLS] = 1;

  /* print OMC_LOG_EVENTS if OMC_LOG_EVENTS_V if active */
  if(omc_useStream[OMC_LOG_EVENTS_V]) {
    omc_useStream[OMC_LOG_EVENTS] = 1;
  }

  /* print OMC_LOG_NLS if OMC_LOG_NLS_JAC if active */
  if(omc_useStream[OMC_LOG_NLS_JAC])
    omc_useStream[OMC_LOG_NLS] = 1;

  /* print OMC_LOG_DSS if OMC_LOG_DSS_JAC if active */
  if(omc_useStream[OMC_LOG_DSS_JAC])
    omc_useStream[OMC_LOG_DSS] = 1;

  delete flags;
}


/**
 * @brief Read value of flag lv_time to set time interval in which logging is active.
 *
 * @param simulationInfo    Simulation info struct
 */
void setGlobalLoggingTime(SIMULATION_INFO *simulationInfo)
{
  const char *flagStr = omc_flagValue[FLAG_LV_TIME];
  const string *flags = flagStr ? new string(flagStr) : NULL;
  char *endptr;
  const char *secondPart;
  double loggingStartTime, loggingStopTime;

  /* Check if lv_time flag is given */
  if (flagStr==NULL || *flagStr=='\0')
  {
    /* default activated --> Log everything */
    simulationInfo->useLoggingTime = 0;
    return;
  }

  /* Parse flagStr */
  loggingStartTime = om_strtod(flagStr, &endptr);
  endptr = endptr+1;
  secondPart = endptr;
  loggingStopTime = om_strtod(secondPart, &endptr);
  if (*endptr)
  {
    throwStreamPrint(NULL, "Simulation flag %s expects two real numbers, separated by a commas. Got: %s", FLAG_NAME[FLAG_LV_TIME], flagStr);
  }

  /* Check flag input */
  if (loggingStartTime > loggingStopTime)
  {
    throwStreamPrint(NULL, "Simulation flag %s expects first number to be smaller then second number. Got: %s", FLAG_NAME[FLAG_LV_TIME], flagStr);
  }

  /* Save logging time */
  simulationInfo->useLoggingTime = 1;
  simulationInfo->loggingTimeRecord[0] = loggingStartTime;
  simulationInfo->loggingTimeRecord[1] = loggingStopTime;
  infoStreamPrint(OMC_LOG_STDOUT, 0, "Time dependent logging enabled. Activate logging in interval [%f, %f]", simulationInfo->loggingTimeRecord[0], simulationInfo->loggingTimeRecord[1]);

  /* Deactivate Logging */
  deactivateLogging();
}


static void readFlag(int *flag, int max, const char *value, const char *flagName, const char **names, const char **desc)
{
  int i;
  if (!value) {
    return; /* keep the default value */
  }

  for (i=1; i<max; ++i) {
    if (0 == strcmp(value, names[i])) {
      *flag = i;
      return;
    }
  }

  warningStreamPrint(OMC_LOG_STDOUT, 1, "unrecognized option %s=%s, current options are:", flagName, value);
  for (i=1; i<max; ++i) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", names[i], desc[i]);
  }
  messageClose(OMC_LOG_STDOUT);
  throwStreamPrint(NULL,"see last warning");
}

static double getFlagReal(enum _FLAG flag, double res)
{
  const char *flagStr = omc_flagValue[flag];
  char *endptr;
  if (flagStr==NULL || *flagStr=='\0') {
    return res;
  }
  res = om_strtod(flagStr, &endptr);
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
    if(modelData->realAlias[i].aliasType == ALIAS_TYPE_VARIABLE) {
      modelData->realAlias[i].filterOutput = regexec(&myregex, modelData->realAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->realAlias[i].filterOutput) {
        modelData->realVarsData[modelData->realAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->realAlias[i].aliasType == ALIAS_TYPE_PARAMETER) {
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
    if(modelData->integerAlias[i].aliasType == ALIAS_TYPE_VARIABLE) {
      modelData->integerAlias[i].filterOutput = regexec(&myregex, modelData->integerAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->integerAlias[i].filterOutput) {
        modelData->integerVarsData[modelData->integerAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->integerAlias[i].aliasType == ALIAS_TYPE_PARAMETER) {
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
    if(modelData->booleanAlias[i].aliasType == ALIAS_TYPE_VARIABLE) {
      modelData->booleanAlias[i].filterOutput = regexec(&myregex, modelData->booleanAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->booleanAlias[i].filterOutput) {
        modelData->booleanVarsData[modelData->booleanAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->booleanAlias[i].aliasType == ALIAS_TYPE_PARAMETER) {
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
    if(modelData->stringAlias[i].aliasType == ALIAS_TYPE_VARIABLE) {
      modelData->stringAlias[i].filterOutput = regexec(&myregex, modelData->stringAlias[i].info.name, 0, NULL, 0) != 0;
      if (0 == modelData->stringAlias[i].filterOutput) {
        modelData->stringVarsData[modelData->stringAlias[i].nameID].filterOutput = 0;
      }
    } else if(modelData->stringAlias[i].aliasType == ALIAS_TYPE_PARAMETER) {
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
  data->modelData->create_linearmodel = create_linearmodel;
  const char* lintime = omc_flagValue[FLAG_L];

  /* activated measure time option with OMC_LOG_STATS */
  int measure_time_flag_previous = measure_time_flag;
  if (!measure_time_flag && (OMC_ACTIVE_STREAM(OMC_LOG_STATS) || omc_flag[FLAG_CPU]))
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
  infoStreamPrint(OMC_LOG_SOLVER, 0, "numberOfIntervals = %ld", (long) data->simulationInfo->numSteps);

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
        warningStreamPrint(OMC_LOG_STDOUT, 0, "[unknown clock-type] got %s, expected CPU|RT|CYC. Defaulting to RT.", clockName);
      }
    }
    if(rt_set_clock(clock)) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Chosen clock-type: %s not available for the current platform. Defaulting to real-time.", clockName);
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
    rt_clear(SIM_TIMER_PREINIT);
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
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Linearization will be performed at point of time: %f", data->simulationInfo->stopTime);
  }

  /* set delta x for linearization */
  if(omc_flag[FLAG_DELTA_X_LINEARIZE]) {
    numericalDifferentiationDeltaXlinearize = atof(omc_flagValue[FLAG_DELTA_X_LINEARIZE]);
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Set delta x for numerical differentiation of the linearization to %f", numericalDifferentiationDeltaXlinearize);
  }else{
    numericalDifferentiationDeltaXlinearize = sqrt(DBL_EPSILON*2e1);
  }

  /* set delta x for integration methods dassl, ida */
  if(omc_flag[FLAG_DELTA_X_SOLVER]) {
    numericalDifferentiationDeltaXsolver = atof(omc_flagValue[FLAG_DELTA_X_SOLVER]);
    infoStreamPrint(OMC_LOG_SOLVER, 0, "Set delta x for numerical differentiation of the integrator to %f", numericalDifferentiationDeltaXsolver);
  }else{
    numericalDifferentiationDeltaXsolver = sqrt(DBL_EPSILON);
  }

  if(omc_flag[FLAG_S]) {
    if (omc_flagValue[FLAG_S]) {
      data->simulationInfo->solverMethod = GC_strdup(omc_flagValue[FLAG_S]);
      infoStreamPrint(OMC_LOG_SOLVER, 0, "overwrite solver method: %s [from command line]", data->simulationInfo->solverMethod);
    }
  }
  /* if the model is compiled in daeMode then we have to use ida solver */
  if (compiledInDAEMode && std::string("ida") != data->simulationInfo->solverMethod) {
    data->simulationInfo->solverMethod = GC_strdup(std::string("ida").c_str());
    infoStreamPrint(OMC_LOG_SIMULATION, 0, "overwrite solver method: %s [DAEmode works only with IDA solver]", data->simulationInfo->solverMethod);
  }

  // Create a result file
  const char *result_file = omc_flagValue[FLAG_R];
  string result_file_cstr;
  if (result_file) {
    data->modelData->resultFileName = GC_strdup(result_file);
  } else if (omc_flag[FLAG_OUTPUT_PATH]) { /* read the output path from the command line (if any) */
    if (0 > GC_asprintf(&result_file, "%s/%s_res.%s", omc_flagValue[FLAG_OUTPUT_PATH], data->modelData->modelFilePrefix, data->simulationInfo->outputFormat)) {
      throwStreamPrint(NULL, "simulation_runtime.c: Error: can not allocate memory.");
    }
    data->modelData->resultFileName = GC_strdup(result_file);
  } else {
    result_file_cstr = string(data->modelData->modelFilePrefix) + string("_res.") + data->simulationInfo->outputFormat;
    data->modelData->resultFileName = GC_strdup(result_file_cstr.c_str());
  }

  data->modelData->resourcesDir = NULL;

  string init_initMethod = "";
  string init_file = "";
  string init_time_string = "";
  double init_time = 0.0;
  string outputVariablesAtEnd = "";
  int cpuTime = omc_flag[FLAG_CPU];

  if(omc_flag[FLAG_IIM]) {
    init_initMethod = omc_flagValue[FLAG_IIM];
  }
  if(omc_flag[FLAG_IIF]) {
    if (omc_flag[FLAG_INPUT_PATH]) {
      const char *tmp_filename;

      if (omc_file_exists(omc_flagValue[FLAG_IIF])) {
        if (0 > GC_asprintf(&tmp_filename, "%s", omc_flagValue[FLAG_IIF] )) {
          throwStreamPrint(NULL, "simulation_runtime.cpp: Error: can not allocate memory.");
        }
      }
      else {
        if (0 > GC_asprintf(&tmp_filename, "%s/%s", omc_flagValue[FLAG_INPUT_PATH], omc_flagValue[FLAG_IIF])) {
          throwStreamPrint(NULL, "simulation_runtime.cpp: Error: can not allocate memory.");
        }
      }
      init_file = tmp_filename;
    }
    else {
      init_file = omc_flagValue[FLAG_IIF];
    }
    if (!omc_file_exists(init_file.c_str())) {
      throwStreamPrint(NULL, "Initialization file \"%s\" doesn't exist.", init_file.c_str());
    }
  }
  if(omc_flag[FLAG_IIT]) {
    init_time_string = omc_flagValue[FLAG_IIT];
    init_time = atof(init_time_string.c_str());
  }
  if(omc_flag[FLAG_ILS]) {
    init_lambda_steps = atoi(omc_flagValue[FLAG_ILS]);
    if(init_lambda_steps <= 0) {
      init_lambda_steps = 0;
      infoStreamPrint(OMC_LOG_STDOUT, 0, "Number of lambda steps set to 0. Homotopy is disabled.");
    }
    else {
      infoStreamPrint(OMC_LOG_STDOUT, 0, "Number of lambda steps for homotopy approach changed to %d", init_lambda_steps);
    }
  }
  if(omc_flag[FLAG_MAX_BISECTION_ITERATIONS]) {
    maxBisectionIterations = atoi(omc_flagValue[FLAG_MAX_BISECTION_ITERATIONS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum number of bisection iterations changed to %d", maxBisectionIterations);
  }
  if(omc_flag[FLAG_MAX_EVENT_ITERATIONS]) {
    maxEventIterations = atoi(omc_flagValue[FLAG_MAX_EVENT_ITERATIONS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum number of event iterations changed to %d", maxEventIterations);
  }
  if(omc_flag[FLAG_OUTPUT]) {
    outputVariablesAtEnd = omc_flagValue[FLAG_OUTPUT];
  }

  /* Check if logging should be enabled */
  if ((data->simulationInfo->useLoggingTime == 1) && (data->simulationInfo->startTime >= data->simulationInfo->loggingTimeRecord[0])) {
    reactivateLogging();
  }

  retVal = callSolver(data, threadData, init_initMethod, init_file, init_time, outputVariablesAtEnd, cpuTime, argv[0]);

  /* Check if logging should be disabled */
  if (data->simulationInfo->useLoggingTime == 1) {
    deactivateLogging();
  }

  if (omc_flag[FLAG_ALARM]) {
    alarm(0);
  }

  if (omc_flag[FLAG_DATA_RECONCILE])
  {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "DataReconciliation Starting!");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "%s", data->modelData->modelName);
    retVal = dataReconciliation(data, threadData, retVal);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "DataReconciliation Completed!");
  }

  if (omc_flag[FLAG_DATA_RECONCILE_BOUNDARY])
  {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Reconcile Boundary Conditions Starting!");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "%s", data->modelData->modelName);
    retVal = boundaryConditions(data, threadData, retVal);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Reconcile Boundary Conditions Completed!");
  }

  if (omc_flag[FLAG_DATA_RECONCILE_STATE])
  {
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Reconcile State Estimation Starting!");
    infoStreamPrint(OMC_LOG_STDOUT, 0, "%s", data->modelData->modelName);
    retVal = dataReconciliation(data, threadData, retVal);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Reconcile State Estimation Completed!");
  }

  if(0 == retVal && create_linearmodel) {
    rt_tick(SIM_TIMER_JACOBIAN);
    retVal = linearize(data, threadData);
    rt_accumulate(SIM_TIMER_JACOBIAN);
  }

  /* Use the saved state of measure_time_flag.
   * measure_time_flag is set to active when OMC_LOG_STATS is ON.
   * So before doing the profiling reset the measure_time_flag to measure_time_flag_previous state.
   */
  measure_time_flag = measure_time_flag_previous;
  string output_path = "";
  if (0 == retVal && measure_time_flag) {
    if (omc_flag[FLAG_OUTPUT_PATH]) { /* read the output path from the command line (if any) */
      output_path = string(omc_flagValue[FLAG_INPUT_PATH]) + string("/");
    }
    const string jsonInfo = string(data->modelData->modelFilePrefix) + "_prof.json";
    const string modelInfo = string(data->modelData->modelFilePrefix) + "_prof.xml";
    const string plotFile = string(data->modelData->modelFilePrefix) + "_prof.plt";
    rt_accumulate(SIM_TIMER_TOTAL);
    const char* plotFormat = omc_flagValue[FLAG_MEASURETIMEPLOTFORMAT];
    retVal = printModelInfo(data, threadData, output_path.c_str(), modelInfo.c_str(), plotFile.c_str(), plotFormat ? plotFormat : "svg",
        data->simulationInfo->solverMethod, data->simulationInfo->outputFormat, data->modelData->resultFileName) && retVal;
    retVal = printModelInfoJSON(data, threadData, output_path.c_str(), jsonInfo.c_str(), data->modelData->resultFileName) && retVal;
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
    sim_result.init = mat4_init4;
    sim_result.emit = mat4_emit4;
    sim_result.writeParameterData = mat4_writeParameterData4;
    sim_result.free = mat4_free4;
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
  infoStreamPrint(OMC_LOG_SOLVER, 0, "Allocated simulation result data storage for method '%s' and file='%s'", (char*) simData->simulationInfo->outputFormat, sim_result.filename);
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
      double init_time, string outputVariablesAtEnd, int cpuTime, const char *argv_0)
{
  TRACE_PUSH
  int retVal = -1;
  mmc_sint_t i;
  enum SOLVER_METHOD solverID = S_UNKNOWN;
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
        solverID = (enum SOLVER_METHOD) i;
      }
    }
  }

  /* Deprecation warnings */
   deprecationWarningGBODE(solverID);
  switch (solverID)
  {
    case S_SYM_SOLVER:
    case S_SYM_SOLVER_SSC:
    case S_QSS:
    warningStreamPrint(OMC_LOG_STDOUT, 0, "Integration method '%s' is deprecated and will be removed in a future version of OpenModelica.",
      SOLVER_METHOD_NAME[solverID]);
    break;
    default:
    break;
  }

  /* if no states are present, then we can
   * use euler method, since it does nothing.
   */
  if ( (simData->modelData->nStates < 1 &&
        solverID != S_OPTIMIZATION &&
        solverID != S_SYM_SOLVER &&
        !compiledInDAEMode) ||
       (compiledInDAEMode && (simData->simulationInfo->daeModeData->nResidualVars +
                             simData->simulationInfo->daeModeData->nAlgebraicDAEVars < 1))
      )
  {
    solverID = S_EULER;
    infoStreamPrint(OMC_LOG_SOLVER, 0, "No states present, continuing without ODE solver.");
    if (compiledInDAEMode)
    {
      simData->callback->functionDAE = evaluateDAEResiduals_wrapperEventUpdate;
      simData->callback->function_ZeroCrossingsEquations = evaluateDAEResiduals_wrapperZeroCrossingsEquations;
    }
  }

  if(S_UNKNOWN == solverID) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "unrecognized option -s %s", (char*) simData->simulationInfo->solverMethod);
    warningStreamPrint(OMC_LOG_STDOUT, 0, "current options are:");
    for(i=1; i<S_MAX; ++i) {
      warningStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", SOLVER_METHOD_NAME[i], SOLVER_METHOD_DESC[i]);
    }
    throwStreamPrint(threadData,"see last warning");
    retVal = 1;
  } else {
    infoStreamPrint(OMC_LOG_SOLVER, 0, "recognized solver: %s", SOLVER_METHOD_NAME[solverID]);
    /* special solvers */
#ifdef _OMC_QSS_LIB
    if(S_QSS == solverID) {
      retVal = qss_main(argc, argv, simData->simulationInfo->startTime,
                        simData->simulationInfo->stopTime, simData->simulationInfo->stepSize,
                        simData->simulationInfo->numSteps, simData->simulationInfo->tolerance, 3);
    } else /* standard solver interface */
#endif
      retVal = solver_main(simData, threadData, init_initMethod.c_str(), init_file.c_str(), init_time, solverID, outVars, argv_0);
  }

  MMC_CATCH_INTERNAL(mmc_jumper)
  MMC_CATCH_INTERNAL(globalJumpBuffer)

  sim_result.free(&sim_result, simData, threadData);

  TRACE_POP
  return retVal;
}

/**
 * @brief Set log activation from equationIndex and list from lv_system.
 *
 * Requires `nonlinsys[i].equationIndex` to be set already!
 *
 * @param data  Data object
 */
static void setLVSystems(DATA *data, threadData_t *threadData)
{
  int i;
  int N = 0; /* largest equationIndex */
  modelica_boolean* isSystemActive = NULL;
  const char* p;
  char* endptr;

  MIXED_SYSTEM_DATA *mixedsys = data->simulationInfo->mixedSystemData;
  LINEAR_SYSTEM_DATA *linsys = data->simulationInfo->linearSystemData;
  NONLINEAR_SYSTEM_DATA *nonlinsys = data->simulationInfo->nonlinearSystemData;

  if (omc_flag[FLAG_LV_SYSTEM]) {
    /* get largest equationIndex */
    for (i = 0; i < data->modelData->nMixedSystems; ++i)
      if (mixedsys[i].equationIndex > N)
        N = mixedsys[i].equationIndex;
    for (i = 0; i < data->modelData->nLinearSystems; ++i)
      if (linsys[i].equationIndex > N)
        N = linsys[i].equationIndex;
    for (i = 0; i < data->modelData->nNonLinearSystems; ++i)
      if (nonlinsys[i].equationIndex > N)
        N = nonlinsys[i].equationIndex;

    /* initialize isSystemActive with FALSE */
    isSystemActive = (modelica_boolean*) calloc(N+1, sizeof(modelica_boolean));
    assertStreamPrint(threadData, NULL != isSystemActive, "setLVSystems: Out of memory.");

    /* set isSystemActive[i] to true for all i in lv_system */
    p = omc_flagValue[FLAG_LV_SYSTEM];
    do {
      errno = 0;
      i = strtol(p, &endptr, 10);
      if (errno == ERANGE) {
        throwStreamPrint(threadData,
          "setLVSystems: %s takes equation indices (got '%s')",
          endptr, omc_flagValue[FLAG_LV_SYSTEM]);
      }
      if (i > N) {
        throwStreamPrint(threadData,
          "setLVSystems: %d is not a valid equation index", i);
      }
      isSystemActive[i] = TRUE;
      p = endptr;
    } while(*(p++) == ',');

    /* activate corresponding system */
    for (i = 0; i < data->modelData->nMixedSystems; ++i) {
      mixedsys[i].logActive = isSystemActive[mixedsys[i].equationIndex];
      isSystemActive[mixedsys[i].equationIndex] = FALSE;
    }
    for (i = 0; i < data->modelData->nLinearSystems; ++i) {
      linsys[i].logActive = isSystemActive[linsys[i].equationIndex];
      isSystemActive[linsys[i].equationIndex] = FALSE;
    }
    for (i = 0; i < data->modelData->nNonLinearSystems; ++i) {
      nonlinsys[i].logActive = isSystemActive[nonlinsys[i].equationIndex];
      isSystemActive[nonlinsys[i].equationIndex] = FALSE;
    }

    for (i = 0; i <= N; ++i){
      if (isSystemActive[i]) {
        throwStreamPrint(threadData,
          "setLVSystems: %d is not a valid equation index.", i);
      }
    }
    /* done */
    free(isSystemActive);
  } else {
    /* if no list is given then all systems are active */
    for (i = 0; i < data->modelData->nMixedSystems; ++i)
      mixedsys[i].logActive = TRUE;
    for (i = 0; i < data->modelData->nLinearSystems; ++i)
      linsys[i].logActive = TRUE;
    for (i = 0; i < data->modelData->nNonLinearSystems; ++i)
      nonlinsys[i].logActive = TRUE;
  }
}

/**
 * Initialization is the same for interactive or non-interactive simulation
 */
int initRuntimeAndSimulation(int argc, char**argv, DATA *data, threadData_t *threadData)
{
  int i;
  initDumpSystem();

  int checkArgumentsRes = checkCommandLineArguments(argc, argv);

#ifndef NO_INTERACTIVE_DEPENDENCY
  if(omc_flag[FLAG_PORT]) {
    std::istringstream stream(omc_flagValue[FLAG_PORT]);
    int port;
    stream >> port;
    sim_communication_port_open = 1;
    sim_communication_port_open &= sim_communication_port.create();
    sim_communication_port_open &= sim_communication_port.connect("127.0.0.1", port);
  }
#endif

  int logFormatResult = setLogFormat(argc, argv);

#ifndef NO_INTERACTIVE_DEPENDENCY
  if (isXMLTCP && !sim_communication_port_open) {
    errorStreamPrint(OMC_LOG_STDOUT, 0, "xmltcp log format requires a TCP-port to be passed (and successfully open)");
    EXIT(1);
  }
#endif

  if(logFormatResult || helpFlagSet(argc, argv) || checkArgumentsRes)
  {
    infoStreamPrint(OMC_LOG_STDOUT, 1, "usage: %s", argv[0]);

    for(i=1; i<FLAG_MAX; ++i)
    {
      if(FLAG_TYPE[i] == FLAG_TYPE_FLAG) {
        infoStreamPrint(OMC_LOG_STDOUT, 0, "<-%s>\n  %s", FLAG_NAME[i], FLAG_DESC[i]);
      } else if(FLAG_TYPE[i] == FLAG_TYPE_OPTION) {
        infoStreamPrint(OMC_LOG_STDOUT, 0, "<-%s=value> or <-%s value>\n  %s", FLAG_NAME[i], FLAG_NAME[i], FLAG_DESC[i]);
      } else {
        warningStreamPrint(OMC_LOG_STDOUT, 0, "[unknown flag-type] <-%s>", FLAG_NAME[i]);
      }
    }

    messageClose(OMC_LOG_STDOUT);
    EXIT(1);
  }

  if(omc_flag[FLAG_HELP])
  {
    std::string option = omc_flagValue[FLAG_HELP];
    for(i=1; i<FLAG_MAX; ++i)
    {
      if(option == std::string(FLAG_NAME[i]))
      {
        int j;

        if(FLAG_TYPE[i] == FLAG_TYPE_FLAG)
          infoStreamPrint(OMC_LOG_STDOUT, 1, "detailed flag-description for: <-%s>\n%s", FLAG_NAME[i], FLAG_DETAILED_DESC[i]);
        else if(FLAG_TYPE[i] == FLAG_TYPE_OPTION)
          infoStreamPrint(OMC_LOG_STDOUT, 1, "detailed flag-description for: <-%s=value> or <-%s value>\n%s", FLAG_NAME[i], FLAG_NAME[i], FLAG_DETAILED_DESC[i]);
        else
          warningStreamPrint(OMC_LOG_STDOUT, 1, "[unknown flag-type] <-%s>", FLAG_NAME[i]);

        /* detailed information for some flags */
        switch(i)
        {
          case FLAG_IDA_LS:
            for(j=1; j<IDA_LS_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", IDA_LS_METHOD_NAME[j], IDA_LS_METHOD_DESC[j]);
            }
            break;

          case FLAG_IIM:
            for(j=1; j<IIM_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", INIT_METHOD_NAME[j], INIT_METHOD_DESC[j]);
            }
            break;

          case FLAG_JACOBIAN:
            for(j=1; j<JAC_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", JACOBIAN_METHOD_NAME[j], JACOBIAN_METHOD_DESC[j]);
            }
            break;

          case FLAG_LS:
            for(j=1; j<LS_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", LS_NAME[j], LS_DESC[j]);
            }
            break;

          case FLAG_LSS:
            for(j=1; j<LSS_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", LSS_NAME[j], LSS_DESC[j]);
            }
            break;

          case FLAG_LV:
            for(j=firstOMCErrorStream; j<OMC_SIM_LOG_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", OMC_LOG_STREAM_NAME[j], OMC_LOG_STREAM_DESC[j]);
            }
            break;

          case FLAG_NEWTON_STRATEGY:
            for(j=firstOMCErrorStream; j<NEWTON_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", NEWTONSTRATEGY_NAME[j], NEWTONSTRATEGY_DESC[j]);
            }
            break;

          case FLAG_NLS:
            for(j=firstOMCErrorStream; j<NLS_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", NLS_NAME[j], NLS_DESC[j]);
            }
            break;

          case FLAG_NLS_LS:
            for(j=firstOMCErrorStream; j<NLS_LS_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", NLS_LS_METHOD_NAME[j], NLS_LS_METHOD_DESC[j]);
            }
            break;

          case FLAG_S:
            for(j=1; j<S_MAX; ++j) {
              infoStreamPrint(OMC_LOG_STDOUT, 0, "%-18s [%s]", SOLVER_METHOD_NAME[j], SOLVER_METHOD_DESC[j]);
            }
            break;
        }
        messageClose(OMC_LOG_STDOUT);

        EXIT(0);
      }
    }

    warningStreamPrint(OMC_LOG_STDOUT, 0, "invalid command line option: -help=%s", option.c_str());
    warningStreamPrint(OMC_LOG_STDOUT, 0, "use %s -help for a list of all command-line flags", argv[0]);
    EXIT(1);
  }

  setGlobalVerboseLevel(argc, argv);
  setGlobalLoggingTime(data->simulationInfo);
  if(omc_flag[FLAG_LV_MAX_WARN]) {
    data->simulationInfo->maxWarnDisplays = atoi(omc_flagValue[FLAG_LV_MAX_WARN]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Display limit for repeating warnings changed to %lu.", data->simulationInfo->maxWarnDisplays);
  } else {
    data->simulationInfo->maxWarnDisplays = DEFAULT_FLAG_LV_MAX_WARN;
  }

  rt_tick(SIM_TIMER_INIT_XML);
  read_input_xml(data->modelData, data->simulationInfo, threadData);
  rt_accumulate(SIM_TIMER_INIT_XML);
  data->simulationInfo->minStepSize = 4.0 * DBL_EPSILON * fmax(fabs(data->simulationInfo->startTime),fabs(data->simulationInfo->stopTime));


  initializeDataStruc(data, threadData);
  if(!data)
  {
    std::cerr << "Error: Could not initialize the global data structure file" << std::endl;
    EXIT(1);
  }

  readFlag((int*)&data->simulationInfo->nlsMethod, NLS_MAX, omc_flagValue[FLAG_NLS], "-nls", NLS_NAME, NLS_DESC);
  readFlag((int*)&data->simulationInfo-> lsMethod,  LS_MAX, omc_flagValue[FLAG_LS ],  "-ls",  LS_NAME,  LS_DESC);
  readFlag((int*)&data->simulationInfo->lssMethod, LSS_MAX, omc_flagValue[FLAG_LSS], "-lss", LSS_NAME, LSS_DESC);
  readFlag((int*)&homBacktraceStrategy, HOM_BACK_STRAT_MAX, omc_flagValue[FLAG_HOMOTOPY_BACKTRACE_STRATEGY], "-homBacktraceStrategy", HOM_BACK_STRAT_NAME, HOM_BACK_STRAT_DESC);
  readFlag((int*)&data->simulationInfo->newtonStrategy, NEWTON_MAX, omc_flagValue[FLAG_NEWTON_STRATEGY], "-newton", NEWTONSTRATEGY_NAME, NEWTONSTRATEGY_DESC);
  data->simulationInfo->nlsCsvInfomation = omc_flag[FLAG_NLS_INFO];
  readFlag((int*)&data->simulationInfo->nlsLinearSolver, NLS_LS_MAX, omc_flagValue[FLAG_NLS_LS], "-nlsLS", NLS_LS_METHOD_NAME, NLS_LS_METHOD_DESC);

  if(omc_flag[FLAG_HOMOTOPY_ADAPT_BEND]) {
    homAdaptBend = atof(omc_flagValue[FLAG_HOMOTOPY_ADAPT_BEND]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homAdaptBend changed to %f", homAdaptBend);
  }

  if(omc_flag[FLAG_HOMOTOPY_H_EPS]) {
    homHEps = atof(omc_flagValue[FLAG_HOMOTOPY_H_EPS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homHEps changed to %f", homHEps);
  }

  if(omc_flag[FLAG_HOMOTOPY_MAX_LAMBDA_STEPS]) {
    homMaxLambdaSteps = atoi(omc_flagValue[FLAG_HOMOTOPY_MAX_LAMBDA_STEPS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homMaxLambdaSteps changed to %d", homMaxLambdaSteps);
  }

  if(omc_flag[FLAG_HOMOTOPY_MAX_NEWTON_STEPS]) {
    homMaxNewtonSteps = atoi(omc_flagValue[FLAG_HOMOTOPY_MAX_NEWTON_STEPS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homMaxNewtonSteps changed to %d", homMaxNewtonSteps);
  }

  if(omc_flag[FLAG_HOMOTOPY_MAX_TRIES]) {
    homMaxTries = atoi(omc_flagValue[FLAG_HOMOTOPY_MAX_TRIES]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homMaxTries changed to %d", homMaxTries);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_DEC_FACTOR]) {
    homTauDecreasingFactor = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_DEC_FACTOR]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauDecreasingFactor changed to %f", homTauDecreasingFactor);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED]) {
    homTauDecreasingFactorPredictor = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_DEC_FACTOR_PRED]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauDecreasingFactorPredictor changed to %f", homTauDecreasingFactorPredictor);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_INC_FACTOR]) {
    homTauIncreasingFactor = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_INC_FACTOR]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauIncreasingFactor changed to %f", homTauIncreasingFactor);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_INC_THRESHOLD]) {
    homTauIncreasingThreshold = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_INC_THRESHOLD]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauIncreasingThreshold changed to %f", homTauIncreasingThreshold);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_MAX]) {
    homTauMax = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_MAX]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauMax changed to %f", homTauMax);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_MIN]) {
    homTauMin = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_MIN]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauMin changed to %f", homTauMin);
  }

  if(omc_flag[FLAG_HOMOTOPY_TAU_START]) {
    homTauStart = atof(omc_flagValue[FLAG_HOMOTOPY_TAU_START]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "homotopy parameter homTauStart changed to %f", homTauStart);
  }

  if(omc_flag[FLAG_LSS_MAX_DENSITY]) {
    linearSparseSolverMaxDensity = atof(omc_flagValue[FLAG_LSS_MAX_DENSITY]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum density for using linear sparse solver changed to %f", linearSparseSolverMaxDensity);
  }
  if(omc_flag[FLAG_LSS_MIN_SIZE]) {
    linearSparseSolverMinSize = atoi(omc_flagValue[FLAG_LSS_MIN_SIZE]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Minimum system size for using linear sparse solver changed to %d", linearSparseSolverMinSize);
  }
  if(omc_flag[FLAG_NLSS_MAX_DENSITY]) {
    nonlinearSparseSolverMaxDensity = atof(omc_flagValue[FLAG_NLSS_MAX_DENSITY]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum density for using non-linear sparse solver changed to %f", nonlinearSparseSolverMaxDensity);
  }
  if(omc_flag[FLAG_NLSS_MIN_SIZE]) {
    nonlinearSparseSolverMinSize = atoi(omc_flagValue[FLAG_NLSS_MIN_SIZE]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Minimum system size for using non-linear sparse solver changed to %d", nonlinearSparseSolverMinSize);
  }
  if(omc_flag[FLAG_NEWTON_XTOL]) {
    newtonXTol = atof(omc_flagValue[FLAG_NEWTON_XTOL]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Tolerance for updating solution vector in Newton solver changed to %g", newtonXTol);
  }

  if(omc_flag[FLAG_NEWTON_FTOL]) {
    newtonFTol = atof(omc_flagValue[FLAG_NEWTON_FTOL]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Tolerance for accepting accuracy in Newton solver changed to %g", newtonFTol);
  }

  if(omc_flag[FLAG_NEWTON_MAX_STEPS]) {
    newtonMaxSteps = atoi(omc_flagValue[FLAG_NEWTON_MAX_STEPS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum number of Newton steps for GBODE changed to %d", newtonMaxSteps);
  }

  if(omc_flag[FLAG_NEWTON_MAX_STEP_FACTOR]) {
    maxStepFactor = atof(omc_flagValue[FLAG_NEWTON_MAX_STEP_FACTOR]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Maximum step size factor for a Newton step changed to %g", newtonFTol);
  }

  if(omc_flag[FLAG_NEWTON_JAC_UPDATES]) {
    int j = 0;
    const char* p = omc_flagValue[FLAG_NEWTON_JAC_UPDATES];
    char* endptr;
    do {
      errno = 0;
      int i = strtol(p, &endptr, 10);
      if (errno == ERANGE) {
        throwStreamPrint(threadData,
          "newtonJacUpdates: takes non-negative integers (got '%s')", omc_flagValue[FLAG_NEWTON_JAC_UPDATES]);
      }
      assertStreamPrint(threadData, i >= 0, "jac update must be non-negative, got %d", i);
      maxJacUpdate[j++] = i;
      p = endptr;
    } while(*(p++) == ',' && i < 4);
  }

  if(omc_flag[FLAG_STEADY_STATE_TOL]) {
    steadyStateTol = atof(omc_flagValue[FLAG_STEADY_STATE_TOL]);
    infoStreamPrint(OMC_LOG_STDOUT, 0, "Tolerance for steady state detection changed to %g", steadyStateTol);
  }

  if(omc_flag[FLAG_DAE_MODE]) {
    warningStreamPrint(OMC_LOG_STDOUT, 0, "The daeMode flag is *deprecated*, because it is not needed any more.\n"
      "If a model is compiled in \"DAEmode\" with compiler flag --daeMode, then it simulates automatically in DAE mode.");
  }

  /* Set the maximum number of threads prior to any allocation w.r.t.
   * linear systems and Jacobians in order to avoid memory leaks.
   */
#ifdef USE_PARJAC
  int num_threads = omc_get_max_threads();
  if (omc_flag[FLAG_JACOBIAN_THREADS]) {
    int num_threads_tmp = atoi(omc_flagValue[FLAG_JACOBIAN_THREADS]);
    infoStreamPrint(OMC_LOG_STDOUT, 0,
         "Number of threads passed via -jacobianThreads: %d",
         num_threads_tmp);
    if (0 >= num_threads_tmp) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
          "Number of desired OpenMP threads for parallel Jacobian evaluation is <= 0.");
      warningStreamPrint(OMC_LOG_STDOUT, 0, "Use omp_get_max_threads().");
    } else {
      num_threads = num_threads_tmp;
    }
  }
  omp_set_num_threads(num_threads);

  infoStreamPrint(OMC_LOG_STDOUT, 0,
      "Number of OpenMP threads for parallel Jacobian evaluation: %d",
      omc_get_max_threads());
#else
  if (omc_flag[FLAG_JACOBIAN_THREADS]) {
      warningStreamPrint(OMC_LOG_STDOUT, 0,
          "Simulation flag jacobianThreads not available. Make sure you have configured omc with \"--enable-parjac\" and build with a compiler supporting OpenMP.");
  }
#endif

  /* set log activation from equationIndex and lv_system */
  setLVSystems(data, threadData);

  /* initialize static data of mixed/linear/non-linear system solvers */
  initializeMixedSystems(data, threadData);
  initializeLinearSystems(data, threadData);
  initializeNonlinearSystems(data, threadData);

  sim_noemit = omc_flag[FLAG_NOEMIT];

#ifndef NO_INTERACTIVE_DEPENDENCY
  if(omc_flag[FLAG_PORT]) {
    if(0 != strcmp("ia", data->simulationInfo->outputFormat)) {
      communicateStatus("Starting", 0.0, data->simulationInfo->startTime, 0);
    }
  }
#endif
  // ppriv - NO_INTERACTIVE_DEPENDENCY - for simpler debugging in Visual Studio

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

/**
 * @brief Parses the commandline (program options) and sets some
 * values. See initRuntimeAndSimulation for more info.
 * This allows generated simulation code to check-on/read options and flags before
 * it calls the main _main_SimulationRuntime function to do the simulation.
 *
 * @param argc
 * @param argv  This gets overwritten on Windows!!
 * @param data
 * @param threadData
 * @return int    Returns 0 on success. Returns 1 otherwise.
 *
 * Note: The function will overwrite argv to its wide character representation. Not sure
 * if this is a good idea. However, I am leaving it as it was for now.
 */
int _main_initRuntimeAndSimulation(int argc, char**argv, DATA *data, threadData_t *threadData) {

  // FIXME this looks like it's just a wrapper!

  if (initRuntimeAndSimulation(argc, argv, data, threadData)) //initRuntimeAndSimulation returns 1 if an error occurs
    return 1;

  return 0;
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

#ifndef OMC_HAVE_MOO

int _main_OptimizationRuntime(int argc, char**argv, DATA *data, threadData_t *threadData) {
  errorStreamPrint(OMC_LOG_STDOUT, 0, "MOO has not been built and can not be called: Set -DOM_OMC_ENABLE_MOO=ON to build MOO.");
  return -1;
}

#endif // OMC_HAVE_MOO

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

#ifndef NO_INTERACTIVE_DEPENDENCY
static std::stringstream xmlTcpStream;
static int numOpenTags=0;

static void printEscapedXMLTCP(std::stringstream *s, const char *msg)
{
  while (*msg) {
    if (*msg == '&') {
      *s << "&amp;";
    } else if (*msg == '<') {
      *s << "&lt;";
    } else if (*msg == '>') {
      *s << "&gt;";
    } else if (*msg == '"') {
      *s << "&quot;";
    } else {
      *s << *msg;
    }
    msg++;
  }
}

static inline void sendXMLTCPIfClosed()
{
  if (numOpenTags==0) {
    sim_communication_port.send(xmlTcpStream.str());
    xmlTcpStream.str("");
  }
}

static void messageXMLTCP(int type, int stream, FILE_INFO info, int indentNext, char *msg, int subline, const int *indexes)
{
  numOpenTags++;
  xmlTcpStream << "<message stream=\"" << OMC_LOG_STREAM_NAME[stream] << "\" type=\"" << OMC_LOG_TYPE_DESC[type] << "\" text=\"";
  printEscapedXMLTCP(&xmlTcpStream, msg);
  if (indexes) {
    int i;
    xmlTcpStream << "\">\n";
    for (i=1; i<=*indexes; i++) {
      xmlTcpStream << "<used index=\"" << indexes[i] << "\" />\n";
    }
    if (!indentNext) {
      numOpenTags--;
      xmlTcpStream << "</message>\n";
    }
  } else {
    if (indentNext) {
      xmlTcpStream << "\">\n";
    } else {
      numOpenTags--;
      xmlTcpStream << "\" />\n";
    }
  }
  sendXMLTCPIfClosed();
}

static void messageCloseXMLTCP(int stream)
{
  if (OMC_ACTIVE_STREAM(stream)) {
    numOpenTags--;
    xmlTcpStream << "</message>\n";
    sendXMLTCPIfClosed();
  }
}

static void messageCloseXMLTCPWarning(int stream)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    numOpenTags--;
    xmlTcpStream << "</message>\n";
    sendXMLTCPIfClosed();
  }
}
#endif

static void printEscapedXML(const char *msg)
{
  while (*msg) {
    if (*msg == '&') fputs("&amp;", stdout);
    else if (*msg == '<') fputs("&lt;", stdout);
    else if (*msg == '>') fputs("&gt;", stdout);
    else if (*msg == '"') fputs("&quot;", stdout);
    else fputc(*msg, stdout);
    msg++;
  }
}

static void messageXML(int type, int stream, FILE_INFO info, int indentNext, char *msg, int subline, const int *indexes)
{
  printf("<message stream=\"%s\" type=\"%s\" text=\"", OMC_LOG_STREAM_NAME[stream], OMC_LOG_TYPE_DESC[type]);
  printEscapedXML(msg);
  if (indexes) {
    int i;
    printf("\">\n");
    for (i=1; i<=*indexes; i++) {
      printf("<used index=\"%d\" />\n", indexes[i]);
    }
    if (!indentNext) {
      fputs("</message>\n",stdout);
    }
  } else {
    fputs(indentNext ? "\">\n" : "\" />\n", stdout);
  }
  fflush(stdout);
}

static void messageCloseXML(int stream)
{
  if (OMC_ACTIVE_STREAM(stream)) {
    fputs("</message>\n", stdout);
    fflush(stdout);
  }
}

static void messageCloseXMLWarning(int stream)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    fputs("</message>\n", stdout);
    fflush(stdout);
  }
}

void setStreamPrintXML(int isXML)
{
  if (isXML==1) {
    messageFunction = messageXML;
    messageClose = messageCloseXML;
    messageCloseWarning = messageCloseXMLWarning;
#ifndef NO_INTERACTIVE_DEPENDENCY
  } else if (isXML==2) {
    messageFunction = messageXMLTCP;
    messageClose = messageCloseXMLTCP;
    messageCloseWarning = messageCloseXMLTCPWarning;
    isXMLTCP = 1;
#endif
  } else {
    /* Already set... */
  }
}

/**
 * @brief Send status via XMLTCP or TCP.
 *
 * @param phase               Simulation phase.
 * @param completionPercent   Percentage of simulation progress: 0.0 to 1.0
 * @param currentTime         Current simulation time.
 * @param currentStepSize     Current solver step size.
 */
void communicateStatus(const char *phase, double completionPercent, double currentTime, double currentStepSize)
{
#ifndef NO_INTERACTIVE_DEPENDENCY
  if (sim_communication_port_open && isXMLTCP) {
    std::stringstream s;
    s << "<status phase=\"" << phase << "\" currentStepSize=\"" << currentStepSize << "\" time=\"" << currentTime << "\" progress=\"" << (int)(completionPercent*10000) << "\" />" << std::endl;
    std::string str(s.str());
    sim_communication_port.send(str);
  } else if (sim_communication_port_open) {
    std::stringstream s;
    s << (int)(completionPercent*10000) << " " << phase << endl;
    std::string str(s.str());
    sim_communication_port.send(str);
  }
#endif
}

} // extern "C"
