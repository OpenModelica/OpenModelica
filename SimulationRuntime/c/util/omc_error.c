/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "setjmp.h"
#include <stdio.h>
#include "omc_error.h"
/* For MMC_THROW, so we can end this thing */
#include "meta_modelica.h"

/* Global JumpBuffer */
jmp_buf globalJmpbuf;

const int firstOMCErrorStream = 3;

const char *LOG_STREAM_NAME[LOG_MAX] = {
  "LOG_UNKNOWN",
  "stdout",
  "assert",

  "LOG_DDASRT",
  "LOG_DEBUG",
  "LOG_DSS",
  "LOG_DSS_JAC",
  "LOG_EVENTS",
  "LOG_EVENTS_V",
  "LOG_INIT",
  "LOG_IPOPT",
  "LOG_JAC",
  "LOG_LS",
  "LOG_LS_V",
  "LOG_NLS",
  "LOG_NLS_V",
  "LOG_NLS_JAC",
  "LOG_NLS_RES",
  "LOG_RES_INIT",
  "LOG_SIMULATION",
  "LOG_SOLVER",
  "LOG_SOTI",
  "LOG_STATS",
  "LOG_UTIL",
  "LOG_ZEROCROSSINGS",
};

const char *LOG_STREAM_DESC[LOG_MAX] = {
  "unknown",
  "this stream is always active",                       /* LOG_STDOUT */
  "this stream is always active",                       /* LOG_ASSERT */

  "additional information about dassl solver",          /* LOG_DDASRT */
  "additional debug information",                       /* LOG_DEBUG */
  "outputs information about dynamic state selection",  /* LOG_DSS */
  "outputs jacobian of the dynamic state selection",    /* LOG_DSS_JAC */
  "additional information during event iteration",      /* LOG_EVENTS */
  "verbose logging of event system",                    /* LOG_EVENTS_V */
  "additional information during initialization",       /* LOG_INIT */
  "more information from Ipopt",                        /* LOG_IPOPT */
  "outputs the jacobian matrix used by dassl",          /* LOG_JAC */
  "logging for linear systems",                         /* LOG_LS */
  "verbose logging of linear systems",                  /* LOG_LS_V */
  "logging for nonlinear systems",                      /* LOG_NLS */
  "verbose logging of nonlinear systems",               /* LOG_NLS_V */
  "outputs the jacobian of nonlinear systems",          /* LOG_NLS_JAC */
  "outputs every evaluation of the residual function",  /* LOG_NLS_RES */
  "outputs residuals of the initialization",            /* LOG_RES_INIT */
  "additional information about simulation process",    /* LOG_SIMULATION */
  "additional information about solver process",        /* LOG_SOLVER */
  "final solution of the initialization",               /* LOG_SOTI */
  "additional statistics about timer/events/solver",    /* LOG_STATS */
  "???",                                                /* LOG_UTIL*/
  "additional information about the zerocrossings"      /* LOG_ZEROCROSSINGS */
};

static const char *LOG_TYPE_DESC[LOG_TYPE_MAX] = {
  "unknown",
  "info",
  "warning",
  "error",
  "assert",
  "debug"
};

int useStream[LOG_MAX];
int level[LOG_MAX];
int lastType[LOG_MAX];
int lastStream = LOG_UNKNOWN;
int showAllWarnings = 0;

void initDumpSystem()
{
  int i;

  for(i=0; i<LOG_MAX; ++i)
  {
    useStream[i] = 0;
    level[i] = 0;
    lastType[i] = 0;
  }

  useStream[LOG_STDOUT] = 1;
  useStream[LOG_ASSERT] = 1;
}

void printInfo(FILE *stream, FILE_INFO info)
{
  fprintf(stream, "[%s:%d:%d-%d:%d:%s]", info.filename, info.lineStart, info.colStart, info.lineEnd, info.colEnd, info.readonly ? "readonly" : "writable");
}

void omc_assert_function(FILE_INFO info, const char *msg, ...)
{
  va_list ap;
  va_start(ap,msg);
  printInfo(stderr, info);
  fputs("Modelica Assert: ", stderr);
  vfprintf(stderr,msg,ap);
  fputs("!\n", stderr);
  va_end(ap);
  fflush(NULL);
  MMC_THROW();
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

void omc_throw_function()
{
  MMC_THROW();
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

static void printEscapedXML(const char *msg)
{
  while (*msg) {
    if (*msg == '&') fputs("&amp;", stdout);
    else if (*msg == '<') fputs("&lt;", stdout);
    else if (*msg == '>') fputs("&gt;", stdout);
    else fputc(*msg, stdout);
    msg++;
  }
}

void messageText(int type, int stream, int indentNext, char *msg, int subline, const int *indexes)
{
  int i;

  printf("%-17s | ", (subline || (lastStream == stream && level[stream] > 0)) ? "|" : LOG_STREAM_NAME[stream]);
  printf("%-7s | ", (subline || (lastStream == stream && lastType[stream] == type && level[stream] > 0)) ? "|" : LOG_TYPE_DESC[type]);
  lastType[stream] = type;
  lastStream = stream;

  for(i=0; i<level[stream]; ++i)
      printf("| ");

  for(i=0; msg[i]; i++)
  {
    if(msg[i] == '\n')
    {
      msg[i] = '\0';
      printf("%s\n", msg);
      messageText(type, stream, 0, &msg[i+1], 1, indexes);
      return;
    }
  }

  printf("%s\n", msg);
  fflush(NULL);
  if (indentNext) level[stream]++;
}

void messageXML(int type, int stream, int indentNext, char *msg, int subline, const int *indexes)
{
  int i;

  printf("<message stream=\"%s\" type=\"%s\" text=\"", LOG_STREAM_NAME[stream], LOG_TYPE_DESC[type]);
  printEscapedXML(msg);
  if (indexes) {
    printf("\">");
    for (i=1; i<=*indexes; i++) {
      printf("<used index=\"%d\" />", indexes[i]);
    }
    printf("</message>\n");
  } else {
    fputs(indentNext ? "\">\n" : "\" />\n", stdout);
  }
  fflush(stdout);
}

static void messageCloseText(int stream)
{
  level[stream]--;
}

static void messageCloseXML(int stream)
{
  fputs("</message>\n", stdout);
  fflush(stdout);
}

static void (*messageFunction)(int type, int stream, int indentNext, char *msg, int subline, const int *indexes) = messageText;
void (*messageClose)(int stream) = messageCloseText;

void setStreamPrintXML(int isXML)
{
  if (isXML) {
    messageFunction = messageXML;
    messageClose = messageCloseXML;
  } else {
    messageFunction = messageText;
    messageClose = messageCloseText;
  }
}

#define SIZE_LOG_BUFFER 2048
void infoStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...)
{
  if (useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(LOG_TYPE_INFO, stream, indentNext, logBuffer, 0, indexes);
  }
}

void infoStreamPrint(int stream, int indentNext, const char *format, ...)
{
  if (useStream[stream]) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(LOG_TYPE_INFO, stream, indentNext, logBuffer, 0, NULL);
  }
}

void warningStreamPrint(int stream, int indentNext, const char *format, ...)
{
  if (ACTIVE_WARNING_STREAM(stream)) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(LOG_TYPE_WARNING, stream, indentNext, logBuffer, 0, NULL);
  }
}

void errorStreamPrint(int stream, int indentNext, const char *format, ...)
{
  char logBuffer[SIZE_LOG_BUFFER];
  va_list args;
  va_start(args, format);
  vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
  messageFunction(LOG_TYPE_ERROR, stream, indentNext, logBuffer, 0, NULL);
}

void assertStreamPrint(int cond, const char *format, ...)
{
  if (!cond) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(LOG_TYPE_ASSERT, LOG_ASSERT, 0, logBuffer, 0, NULL);
  }
}

#ifdef USE_DEBUG_OUTPUT
void debugStreamPrint(int cond, int indentNext, const char *format, ...)
{
  if (!cond) {
    char logBuffer[SIZE_LOG_BUFFER];
    va_list args;
    va_start(args, format);
    vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
    messageFunction(LOG_TYPE_DEBUG, LOG_ASSERT, indentNext, logBuffer, 0, NULL);
    longjmp(globalJmpbuf, 1);
  }
}
#endif

void throwStreamPrint(const char *format, ...)
{
  char logBuffer[SIZE_LOG_BUFFER];
  va_list args;
  va_start(args, format);
  vsnprintf(logBuffer, SIZE_LOG_BUFFER, format, args);
  messageFunction(LOG_TYPE_DEBUG, LOG_ASSERT, 0, logBuffer, 0, NULL);
  longjmp(globalJmpbuf, 1);
}
