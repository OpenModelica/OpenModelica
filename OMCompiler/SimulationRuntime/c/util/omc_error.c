/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */

#include "setjmp.h"
#include <stdio.h>
#include "omc_error.h"
#include "simulation_options.h"
/* For MMC_THROW, so we can end this thing */
#include "../meta/meta_modelica.h"

const FILE_INFO omc_dummyFileInfo = omc_dummyFileInfo_val;

void (*omc_assert)(threadData_t*,FILE_INFO info,const char *msg,...) __attribute__((noreturn)) = omc_assert_function;
void (*omc_assert_warning)(FILE_INFO info,const char *msg,...) = omc_assert_warning_function;
void (*omc_terminate)(FILE_INFO info,const char *msg,...) = omc_terminate_function;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_function;


const int firstOMCErrorStream = 1;

const char *OMC_LOG_STREAM_NAME[OMC_SIM_LOG_MAX] = {
  "LOG_UNKNOWN",
  "LOG_STDOUT",
  "LOG_ASSERT",

  "LOG_DASSL",
  "LOG_DASSL_STATES",
  "LOG_DEBUG",
  "LOG_DELAY",
  "LOG_DIVISION",
  "LOG_DSS",
  "LOG_DSS_JAC",
  "LOG_DT",
  "LOG_DT_CONS",
  "LOG_EVENTS",
  "LOG_EVENTS_V",
  "LOG_GBODE",
  "LOG_GBODE_V",
  "LOG_GBODE_NLS",
  "LOG_GBODE_NLS_V",
  "LOG_GBODE_STATES",
  "LOG_INIT",
  "LOG_INIT_HOMOTOPY",
  "LOG_INIT_V",
  "LOG_IPOPT",
  "LOG_IPOPT_FULL",
  "LOG_IPOPT_JAC",
  "LOG_IPOPT_HESSE",
  "LOG_IPOPT_ERROR",
  "LOG_JAC",
  "LOG_LS",
  "LOG_LS_V",
  "LOG_MIXED",
  "LOG_NLS",
  "LOG_NLS_V",
  "LOG_NLS_HOMOTOPY",
  "LOG_NLS_JAC",
  "LOG_NLS_JAC_TEST",
  "LOG_NLS_NEWTON_DIAGNOSTICS",
  "LOG_NLS_RES",
  "LOG_NLS_EXTRAPOLATE",
  "LOG_RES_INIT",
  "LOG_RT",
  "LOG_SIMULATION",
  "LOG_SOLVER",
  "LOG_SOLVER_V",
  "LOG_SOLVER_CONTEXT",
  "LOG_SOTI",
  "LOG_SPATIALDISTR",
  "LOG_STATS",
  "LOG_STATS_V",
  "LOG_SUCCESS",
  "LOG_SYNCHRONOUS",
#ifdef USE_DEBUG_TRACE
  "LOG_TRACE",
#endif
  "LOG_ZEROCROSSINGS",
};

const char *OMC_LOG_STREAM_DESC[OMC_SIM_LOG_MAX] = {
  "unknown",
  "this stream is always active, can be disabled with -lv=-LOG_STDOUT",         /* OMC_LOG_STDOUT */
  "this stream is always active, can be disabled with -lv=-LOG_ASSERT",         /* OMC_LOG_ASSERT */

  "additional information about dassl solver",                                  /* OMC_LOG_DASSL */
  "outputs the states at every dassl call",                                     /* OMC_LOG_DASSL_STATES */
  "additional debug information",                                               /* OMC_LOG_DEBUG */
  "debug information for delay operator",                                       /* OMC_LOG_DELAY */
  "Log division by zero",                                                       /* OMC_LOG_DIVISION */
  "outputs information about dynamic state selection",                          /* OMC_LOG_DSS */
  "outputs jacobian of the dynamic state selection",                            /* OMC_LOG_DSS_JAC */
  "additional information about dynamic tearing",                               /* OMC_LOG_DT */
  "additional information about dynamic tearing (local and global constraints)",/* OMC_LOG_DT_CONS */
  "additional information during event iteration",                              /* OMC_LOG_EVENTS */
  "verbose logging of event system",                                            /* OMC_LOG_EVENTS_V */
  "information about GBODE solver",                                             /* OMC_LOG_GBODE */
  "verbose information about GBODE solver",                                     /* OMC_LOG_GBODE_V */
  "log non-linear solver process of GBODE solver",                              /* OMC_LOG_GBODE_NLS */
  "verbose log non-linear solver process of GBODE solver",                      /* OMC_LOG_GBODE_NLS_V */
  "output states at every GBODE call",                                          /* OMC_LOG_GBODE_STATES */
  "additional information during initialization",                               /* OMC_LOG_INIT */
  "log homotopy initialization",                                                /* OMC_LOG_INIT_HOMOTOPY */
  "verbose information during initialization",                                  /* OMC_LOG_INIT_V */
  "information from Ipopt",                                                     /* OMC_LOG_IPOPT */
  "more information from Ipopt",                                                /* OMC_LOG_IPOPT_FULL*/
  "check jacobian matrix with Ipopt",                                           /* OMC_LOG_IPOPT_JAC*/
  "check hessian matrix with Ipopt",                                            /* OMC_LOG_IPOPT_HESSE*/
  "print max error in the optimization",                                        /* OMC_LOG_IPOPT_ERROR*/
  "outputs the jacobian matrix used by ODE solvers",                            /* OMC_LOG_JAC */
  "logging for linear systems",                                                 /* OMC_LOG_LS */
  "verbose logging of linear systems",                                          /* OMC_LOG_LS_V */
  "logging for mixed systems",                                                  /* OMC_LOG_MIXED */
  "logging for nonlinear systems",                                              /* OMC_LOG_NLS */
  "verbose logging of nonlinear systems",                                       /* OMC_LOG_NLS_V */
  "logging of homotopy solver for nonlinear systems",                           /* OMC_LOG_NLS_HOMOTOPY */
  "outputs the jacobian of nonlinear systems",                                  /* OMC_LOG_NLS_JAC */
  "tests the analytical jacobian of nonlinear systems",                         /* OMC_LOG_NLS_JAC_TEST */
  "newton diagnostics (see: https://doi.org/10.1016/j.amc.2021.125991)",        /* OMC_LOG_NLS_NEWTON_DIAGNOSTICS */
  "outputs every evaluation of the residual function",                          /* OMC_LOG_NLS_RES */
  "outputs debug information about extrapolate process",                        /* OMC_LOG_NLS_EXTRAPOLATE */
  "outputs residuals of the initialization",                                    /* OMC_LOG_RES_INIT */
  "additional information regarding real-time processes",                       /* OMC_LOG_RT */
  "additional information about simulation process",                            /* OMC_LOG_SIMULATION */
  "additional information about solver process",                                /* OMC_LOG_SOLVER */
  "verbose information about the integration process",                          /* OMC_LOG_SOLVER_V */
  "context information during the solver process",                              /* OMC_LOG_SOLVER_CONTEXT" */
  "final solution of the initialization",                                       /* OMC_LOG_SOTI */
  "logging of internal operations for spatialDistribution",                     /* OMC_LOG_SPATIALDISTR */
  "additional statistics about timer/events/solver",                            /* OMC_LOG_STATS */
  "additional statistics for OMC_LOG_STATS",                                    /* OMC_LOG_STATS_V */
  "this stream is always active, unless deactivated with -lv=-LOG_SUCCESS",     /* OMC_LOG_SUCCESS */
  "log clocks and sub-clocks for synchronous features",                         /* OMC_LOG_SYNCHRONOUS */
#ifdef USE_DEBUG_TRACE
  "enables additional output to trace call stack",                              /* OMC_LOG_TRACE */
#endif
  "additional information about the zerocrossings"                              /* OMC_LOG_ZEROCROSSINGS */
};

const char *OMC_LOG_TYPE_DESC[OMC_LOG_TYPE_MAX] = {
  "unknown",
  "info",
  "warning",
  "error",
  "assert",
  "debug"
};

int omc_useStream[OMC_SIM_LOG_MAX];         /* 1 if LOG is enabled, otherwise 0 */
static int backupUseStream[OMC_SIM_LOG_MAX];   /* Backup of omc_useStream */
static int omc_level[OMC_SIM_LOG_MAX];
static int omc_lastType[OMC_SIM_LOG_MAX];
static int omc_lastStream = OMC_LOG_UNKNOWN;
int omc_showAllWarnings = 0;
static int streamsActive = 1;              /* 1 if info streams from omc_useStream are active, 0 if deactivated */

#ifdef USE_DEBUG_TRACE
  int DEBUG_TRACE_PUSH_HELPER(const char* pFnc, const char* pFile, const long ln){if(omc_useStream[OMC_LOG_TRACE]) printf("TRACE: push %s (%s:%d)\n", pFnc, pFile, ln); return 0;}
  int DEBUG_TRACE_POP_HELPER(int traceID){if(omc_useStream[OMC_LOG_TRACE]) printf("TRACE: pop\n"); return 0;}
#endif

void initDumpSystem()
{
  int i;

  for(i=0; i<OMC_SIM_LOG_MAX; ++i)
  {
    omc_useStream[i] = 0;
    omc_level[i] = 0;
    omc_lastType[i] = 0;
  }

  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  omc_useStream[OMC_LOG_SUCCESS] = 1;
}

/* Deactivates streams for logging except for stdout, assert and success. */
void deactivateLogging()
{
  int i;

  if (streamsActive == 0)
  {
    return;   /* Do nothing if already inactive */
  }

  for(i=0; i<OMC_SIM_LOG_MAX; ++i)
  {
    if (i != OMC_LOG_STDOUT && i != OMC_LOG_ASSERT && i != OMC_LOG_SUCCESS)
    {
      backupUseStream[i] = omc_useStream[i];
      /*
      if (omc_useStream[i] != 0) {
        printf("Stream %s deactivated\n",LOG_STREAM_NAME[i]);
      }
      */
      omc_useStream[i] = 0;
      }
  }

  omc_useStream[OMC_LOG_STDOUT] = 1;
  omc_useStream[OMC_LOG_ASSERT] = 1;
  omc_useStream[OMC_LOG_SUCCESS] = 1;

  streamsActive = 0;  /* Deactivate info streams */
  //infoStreamPrint(OMC_LOG_STDOUT,0,"Deactivated logging");
}

/* Resets streams to backup after deactivateLogging() was used. */
void reactivateLogging()
{
  int i;

  if (streamsActive == 1)
  {
    return;   /* Do nothing if already active */
  }

  for(i=0; i<OMC_SIM_LOG_MAX; ++i)
  {
    if (i != OMC_LOG_STDOUT && i != OMC_LOG_ASSERT && i != OMC_LOG_SUCCESS)
    {
      omc_useStream[i] = backupUseStream[i];
      /*
      if (omc_useStream[i] != 0) {
        printf("Stream %s reactivated\n",LOG_STREAM_NAME[i]);
      }
      */
    }
  }

  streamsActive = 1;  /* Activate info streams */
  //infoStreamPrint(OMC_LOG_STDOUT,0,"Reactivated logging");
}

void printInfo(FILE *stream, FILE_INFO info)
{
  fprintf(stream, "[%s:%d:%d-%d:%d:%s]", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

void omc_assert_function(threadData_t* threadData, FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  printInfo(stderr, info);
  fputs("Modelica Assert: ", stderr);
  vfprintf(stderr,msg,ap);
  fputs("!\n", stderr);
  va_end(ap);
  fflush(NULL);
  if (threadData) {
    MMC_THROW_INTERNAL();
  } else {
    MMC_THROW();
  }
}

void omc_assert_warning_function(FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  printInfo(stderr, info);
  fputs("Warning, assertion triggered: ", stderr);
  vfprintf(stderr,msg,ap);
  fputs("!\n", stderr);
  va_end(ap);
  fflush(NULL);
}

void omc_throw_function(threadData_t *threadData)
{
  if (threadData) {
    MMC_THROW_INTERNAL();
  } else {
    MMC_THROW();
  }
}

void omc_terminate_function(FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  printInfo(stderr, info);
  fputs("Modelica Terminate: ", stderr);
  vfprintf(stderr,msg,ap);
  fputs("!\n", stderr);
  va_end(ap);
  fflush(NULL);
  MMC_THROW();
}

void messageText(int type, int stream, FILE_INFO info, int indentNext, char *msg, int subline, const int *indexes)
{
  int i;
  int len;

  printf("%-17s | ", (subline || (omc_lastStream == stream && omc_level[stream] > 0)) ? "|" : OMC_LOG_STREAM_NAME[stream]);
  printf("%-7s | ", (subline || (omc_lastStream == stream && omc_lastType[stream] == type && omc_level[stream] > 0)) ? "|" : OMC_LOG_TYPE_DESC[type]);
  omc_lastType[stream] = type;
  omc_lastStream = stream;

  for(i=0; i<omc_level[stream]; ++i)
      printf("| ");

  if (info.filename && strlen(info.filename) > 0) {
    // Print to stdout because we are using printf down below as well.
    printInfo(stdout, info);
    printf("\n");

    printf("%-17s | ", "|");
    printf("%-7s | ", "|");
  }

  for(i=0; msg[i]; i++)
  {
    if(msg[i] == '\n')
    {
      msg[i] = '\0';
      printf("%s\n", msg);
      if (msg[i+1]) {
        messageText(type, stream, omc_dummyFileInfo, 0, &msg[i+1], 1, indexes);
      }
      return;
    }
  }

  len = strlen(msg);
  if (len>0 && msg[len-1]=='\n') {
    printf("%s", msg);
  } else {
    printf("%s\n", msg);
  }
  fflush(NULL);
  if (indentNext) omc_level[stream]++;
}

/**
 * @brief Close messages.
 *
 * Use for active streams to reduce level of indentation by one.
 *
 * @param stream Log stream.
 */
static void messageCloseText(int stream)
{
  if(OMC_ACTIVE_STREAM(stream)) {
    omc_level[stream]--;
  }
}

/**
 * @brief Close warning messages.
 *
 * Use for warning messages that indented the stream either because the stream is active
 * or showAllWarnings is true.
 *
 * @param stream Log stream.
 */
static void messageCloseTextWarning(int stream)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    omc_level[stream]--;
  }
}

void (*messageFunction)(int type, int stream, FILE_INFO info, int indentNext, char *msg, int subline, const int *indexes) = messageText;
/**
 * @brief Close messages.
 * See messageCloseText() for more info.
 */
void (*messageClose)(int stream) = messageCloseText;
/**
 * @brief Close warning messages.
 * See messageCloseTextWarning() for more info.
 */
void (*messageCloseWarning)(int stream) = messageCloseTextWarning;

#define SIZE_LOG_BUFFER 2048

#if !defined(OMC_MINIMAL_LOGGING)
void va_infoStreamPrint(int stream, int indentNext, const char *format, va_list args)
{
  if (omc_useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(OMC_LOG_TYPE_INFO, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
  }
}

void infoStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...)
{
  if (omc_useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_INFO, stream, info, indentNext, logBuffer, 0, indexes);
  }
}

void infoStreamPrint(int stream, int indentNext, const char *format, ...)
{
  if (omc_useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_INFO, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
  }
}

void warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_WARNING, stream, info, indentNext, logBuffer, 0, indexes);
  }
}

/**
 * @brief Print warning to stream until limit is reached.
 *
 * If `nDisplayed` is larger than user specified display limit for warnings
 * a info is displayed and no warning will be printed.
 *
 * @param stream          Stream to print to.
 * @param indentNext      Will increase indentation level by one if true.
 * @param nDisplayed      Number of times this warning was displayed.
 * @param maxWarnDisplays Maximum allowed warning displays.
 * @param format          Format string with message to print.
 * @param ...             Arguments for format string.
 */
void warningStreamPrintWithLimit(int stream, int indentNext, unsigned long nDisplayed, unsigned long maxWarnDisplays, const char *format, ...) {

  if (!OMC_ACTIVE_WARNING_STREAM(stream)) {
    return;
  }

  va_list args;

  /* Display warning */
  if (nDisplayed <= maxWarnDisplays) {
    va_start(args, format);
    va_warningStreamPrint(stream, indentNext, format, args);
  }
  if (nDisplayed == maxWarnDisplays) {
    infoStreamPrint(stream, indentNext, "Too many warnings, reached display limit of %lu. "
                                        "Suppressing further warning messages of the same type.", maxWarnDisplays);
    infoStreamPrint(stream, indentNext, "Change limit with simulation flag -%s=<newLimit>", FLAG_NAME[FLAG_LV_MAX_WARN]);
    messageClose(stream);
  }
}

/**
 * @brief Print warning to stream.
 *
 * Prints message only if stream is active or global variable showAllWarnings is true.
 *
 * Use messageCloseWarning to close message, if indentNext is true.
 *
 * @param stream      Stream to print to.
 * @param indentNext  Will increase indentation level by one if true.
 * @param format      Format string with message to print.
 * @param ...         Arguments for format string.
 */
void warningStreamPrint(int stream, int indentNext, const char *format, ...)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_WARNING, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
  }
}

void va_warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, va_list args)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    char logBuffer[SIZE_LOG_BUFFER];
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(OMC_LOG_TYPE_WARNING, stream, info, indentNext, logBuffer, 0, indexes);
  }
}

void va_warningStreamPrint(int stream, int indentNext, const char *format, va_list args)
{
  if (OMC_ACTIVE_WARNING_STREAM(stream)) {
    char logBuffer[SIZE_LOG_BUFFER];
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(OMC_LOG_TYPE_WARNING, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
  }
}

void errorStreamPrint(int stream, int indentNext, const char *format, ...)
{
  char logBuffer[SIZE_LOG_BUFFER];
  va_list args;
  va_start(args, format);
  vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
  va_end(args);
  messageFunction(OMC_LOG_TYPE_ERROR, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
}

void va_errorStreamPrint(int stream, int indentNext, const char *format, va_list args)
{
  char logBuffer[SIZE_LOG_BUFFER];
  vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
  messageFunction(OMC_LOG_TYPE_ERROR, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
}

void va_errorStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, va_list args)
{

  char logBuffer[SIZE_LOG_BUFFER];
  vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
  messageFunction(OMC_LOG_TYPE_ERROR, stream, info, indentNext, logBuffer, 0, indexes);
}
#endif

#ifdef USE_DEBUG_OUTPUT
void debugStreamPrint(int stream, int indentNext, const char *format, ...)
{
  if (omc_useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_DEBUG, stream, omc_dummyFileInfo, indentNext, logBuffer, 0, NULL);
  }
}

void debugStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...)
{
  if (omc_useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_DEBUG, stream, info, indentNext, logBuffer, 0, indexes);
  }
}
#endif

static inline jmp_buf* getBestJumpBuffer(threadData_t *threadData)
{
  switch (threadData->currentErrorStage) {
  case ERROR_EVENTSEARCH:
  case ERROR_SIMULATION:
  case ERROR_NONLINEARSOLVER:
  case ERROR_INTEGRATOR:
  case ERROR_OPTIMIZE:
#ifndef OMC_EMCC
    if (threadData->simulationJumpBuffer) {
      return threadData->simulationJumpBuffer;
    }
    fprintf(stderr, "getBestJumpBuffer got simulationJumpBuffer=%p\n", threadData->simulationJumpBuffer);
    abort();
#endif
  case ERROR_EVENTHANDLING:
  default:
    if (threadData->globalJumpBuffer) {
      return threadData->globalJumpBuffer;
    }
    if (threadData->mmc_jumper) {
      return threadData->mmc_jumper;
    }
    fprintf(stderr, "getBestJumpBuffer got mmc_jumper=%p, globalJumpBuffer=%p\n", threadData->globalJumpBuffer, threadData->mmc_jumper);
    abort();
  }
}

/**
 * @brief Variadic stream print and throw.
 *
 * Print message to OMC_LOG_ASSERT.
 *
 * @param threadData  Thread data for throwing.
 * @param format      Format string.
 * @param args        Variadic argument list for format string
 */
void va_throwStreamPrint(threadData_t *threadData, const char *format, va_list args)
{
#if !defined(OMC_MINIMAL_LOGGING)
  if (omc_useStream[OMC_LOG_ASSERT]) {
    char logBuffer[SIZE_LOG_BUFFER];
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(OMC_LOG_TYPE_DEBUG, OMC_LOG_ASSERT, omc_dummyFileInfo, 0, logBuffer, 0, NULL);
  }
#endif
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  longjmp(*getBestJumpBuffer(threadData), 1);
}

/**
 * @brief Print message to OMC_LOG_ASSERT and throw.
 *
 * @param threadData  Thread data for throwing.
 * @param format      Format string.
 * @param ...         Additional arguments for format string.
 */
void throwStreamPrint(threadData_t *threadData, const char *format, ...)
{
#if !defined(OMC_MINIMAL_LOGGING)
  va_list args;
  va_start(args, format);
  va_throwStreamPrint(threadData, format, args);
  va_end(args);
#else
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  longjmp(*getBestJumpBuffer(threadData), 1);
#endif
}

/**
 * @brief Print message with equation indices to OMC_LOG_ASSERT stream and throw.
 *
 * @param threadData    Thread data for throwing.
 * @param info          File info, can be omc_dummyFileInfo.
 * @param indexes       Equation indices.
 * @param format        Format string.
 * @param ...           Additional arguments for format string.
 */
void throwStreamPrintWithEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *format, ...)
{
#if !defined(OMC_MINIMAL_LOGGING)
  if (omc_useStream[OMC_LOG_ASSERT]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    va_end(args);
    messageFunction(OMC_LOG_TYPE_DEBUG, OMC_LOG_ASSERT, info, 0, logBuffer, 0, indexes);
  }
#endif
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  longjmp(*getBestJumpBuffer(threadData), 1);
}
