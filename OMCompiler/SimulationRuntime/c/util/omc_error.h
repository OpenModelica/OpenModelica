/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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


#ifndef OMC_ERROR_H
#define OMC_ERROR_H

#include "../openmodelica.h"
#include "omc_msvc.h"

#include <setjmp.h>
#include <stdio.h>
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct _FILE_INFO
{
  const char* filename;
  int lineStart;
  int colStart;
  int lineEnd;
  int colEnd;
  int readonly;
} FILE_INFO;

#define omc_dummyFileInfo {"",0,0,0,0,0}

DLLExport extern void printInfo(FILE *stream, FILE_INFO info);
DLLExport extern void (*omc_assert)(threadData_t*, FILE_INFO, const char*, ...) __attribute__ ((noreturn));
DLLExport extern void (*omc_assert_warning)(FILE_INFO, const char*, ...);
DLLExport extern void (*omc_terminate)(FILE_INFO, const char*, ...);
DLLExport extern void (*omc_throw)(threadData_t*) __attribute__ ((noreturn));

DLLExport extern void (*omc_assert_withEquationIndexes)(threadData_t*,FILE_INFO, const int*, const char*, ...) __attribute__ ((noreturn));
DLLExport extern void (*omc_assert_warning_withEquationIndexes)(FILE_INFO, const int*, const char*, ...);

void initDumpSystem();
void deactivateLogging();
void reactivateLogging();
void omc_assert_function(threadData_t*,FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
void omc_assert_warning_function(FILE_INFO info,  const char *msg, ...);
void omc_terminate_function(FILE_INFO info, const char *msg, ...);
void omc_throw_function(threadData_t*) __attribute__ ((noreturn));

/* #define USE_DEBUG_OUTPUT */
/* #define USE_DEBUG_TRACE */

enum LOG_STREAM
{
  LOG_UNKNOWN = 0,
  LOG_STDOUT,
  LOG_ASSERT,

  LOG_DASSL,
  LOG_DASSL_STATES,
  LOG_DEBUG,
  LOG_DSS,
  LOG_DSS_JAC,
  LOG_DT,
  LOG_DT_CONS,
  LOG_EVENTS,
  LOG_EVENTS_V,
  LOG_INIT,
  LOG_INIT_HOMOTOPY,
  LOG_INIT_V,
  LOG_IPOPT,
  LOG_IPOPT_FULL,
  LOG_IPOPT_JAC,
  LOG_IPOPT_HESSE,
  LOG_IPOPT_ERROR,
  LOG_JAC,
  LOG_LS,
  LOG_LS_V,
  LOG_NLS,
  LOG_NLS_V,
  LOG_NLS_HOMOTOPY,
  LOG_NLS_JAC,
  LOG_NLS_JAC_TEST,
  LOG_NLS_RES,
  LOG_NLS_EXTRAPOLATE,
  LOG_RES_INIT,
  LOG_RT,
  LOG_SIMULATION,
  LOG_SOLVER,
  LOG_SOLVER_V,
  LOG_SOLVER_CONTEXT,
  LOG_SOTI,
  LOG_STATS,
  LOG_STATS_V,
  LOG_SUCCESS,
#ifdef USE_DEBUG_TRACE
  LOG_TRACE,
#endif
  LOG_UTIL,
  LOG_ZEROCROSSINGS,

  SIM_LOG_MAX
};

enum LOG_TYPE
{
  LOG_TYPE_UNKNOWN = 0,
  LOG_TYPE_INFO,
  LOG_TYPE_WARNING,
  LOG_TYPE_ERROR,
  LOG_TYPE_ASSERT,
  LOG_TYPE_DEBUG,
  LOG_TYPE_MAX
};

extern const int firstOMCErrorStream;
extern const char *LOG_STREAM_NAME[SIM_LOG_MAX];
extern const char *LOG_STREAM_DESC[SIM_LOG_MAX];
extern const char *LOG_STREAM_DETAILED_DESC[SIM_LOG_MAX];
extern const char *LOG_TYPE_DESC[LOG_TYPE_MAX];

extern int useStream[SIM_LOG_MAX];
extern int level[SIM_LOG_MAX];
extern int lastType[SIM_LOG_MAX];
extern int lastStream;
extern int showAllWarnings;
extern char logBuffer[2048];

#define ACTIVE_STREAM(stream)    (useStream[stream])
#define ACTIVE_WARNING_STREAM(stream)    (showAllWarnings || useStream[stream])

#ifdef USE_DEBUG_OUTPUT
  #define DEBUG_STREAM(stream)    (useStream[stream])
#else
  #define DEBUG_STREAM(stream)    (0)
#endif

#ifdef USE_DEBUG_TRACE
  extern int DEBUG_TRACE_PUSH_HELPER(const char* pFnc, const char* pFile, const long ln);
  extern int DEBUG_TRACE_POP_HELPER(int traceID);
  #define TRACE_PUSH int __DEBUG_TRACE_HANDLE = DEBUG_TRACE_PUSH_HELPER(__FUNCTION__, __FILE__, __LINE__);
  #define TRACE_POP DEBUG_TRACE_POP_HELPER(__DEBUG_TRACE_HANDLE);
#else
  #define TRACE_PUSH
  #define TRACE_POP
#endif

extern void (*messageFunction)(int type, int stream, int indentNext, char *msg, int subline, const int *indexes);
extern void (*messageClose)(int stream);
extern void (*messageCloseWarning)(int stream);

#if !defined(OMC_MINIMAL_LOGGING)
extern void va_infoStreamPrint(int stream, int indentNext, const char *format, va_list ap);
extern void infoStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void infoStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 4, 5)));
extern void warningStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void va_warningStreamPrint(int stream, int indentNext, const char *format,va_list ap);
extern void warningStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 4, 5)));
extern void va_warningStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format,va_list ap);
extern void errorStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void va_errorStreamPrint(int stream, int indentNext, const char *format, va_list ap);
extern void va_errorStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format,va_list ap);
#else
static inline void va_infoStreamPrint(int stream, int indentNext, const char *format, va_list ap) {}
static inline void infoStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void infoStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...) {}
static inline void warningStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void va_warningStreamPrint(int stream, int indentNext, const char *format,va_list ap) {}
static inline void warningStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...) {}
static inline void va_warningStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format,va_list ap) {}
static inline void errorStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void va_errorStreamPrint(int stream, int indentNext, const char *format, va_list ap) {}
static inline void va_errorStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format,va_list ap) {}
#endif

extern void va_throwStreamPrint(threadData_t *threadData, const char *format, va_list ap) __attribute__ ((noreturn));
extern void throwStreamPrint(threadData_t *threadData, const char *format, ...) __attribute__ ((format (printf, 2, 3), noreturn));
extern void throwStreamPrintWithEquationIndexes(threadData_t *threadData, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 3, 4), noreturn));
#ifdef HAVE_VA_MACROS
#define assertStreamPrint(threadData, cond, ...) if (!(cond)) {throwStreamPrint((threadData), __VA_ARGS__); assert(0);}
#else
static void OMC_INLINE assertStreamPrint(threadData_t *threadData, int cond, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
static void OMC_INLINE assertStreamPrint(threadData_t *threadData, int cond, const char *format, ...)
{
  va_list args;
  if (cond) return;
  va_start(args, format);
  va_throwStreamPrint(threadData,format,args);
  va_end(args);
}
#endif

#if defined __STDC_VERSION__ && __STDC_VERSION__ >= 199901L
#define OMC_FUNCTION __func__
#elif __STDC_VERSION__ < 199901L && __GNUC__ >= 2
#define OMC_FUNCTION __FUNCTION__
#else
#define OMC_FUNCTION "(null)"
#endif

#define omc_assert_macro(expr) \
  if (!(expr)) {                \
    abort(); \
    throwStreamPrint(NULL, "%s:%d: %s: Assertion `%s` failed.\n",  __FILE__, __LINE__, OMC_FUNCTION, #expr); \
  }

#ifdef USE_DEBUG_OUTPUT
void debugStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
void debugStreamPrintWithEquationIndexes(int stream, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 4, 5)));
#else
static OMC_INLINE void debugStreamPrint(int stream __attribute__((unused)), int indentNext __attribute__((unused)), const char *format __attribute__((unused)), ...) __attribute__ ((format (printf, 3, 4)));
static OMC_INLINE void debugStreamPrint(int stream __attribute__((unused)), int indentNext __attribute__((unused)), const char *format __attribute__((unused)), ...) {/* Do nothing */}
static OMC_INLINE void debugStreamPrintWithEquationIndexes(int stream __attribute__((unused)), int indentNext __attribute__((unused)), const int *indexes __attribute__((unused)), const char *format __attribute__((unused)), ...) __attribute__ ((format (printf, 4, 5)));
static OMC_INLINE void debugStreamPrintWithEquationIndexes(int stream  __attribute__((unused)), int indentNext __attribute__((unused)), const int *indexes __attribute__((unused)), const char *format __attribute__((unused)), ...)  {/* Do nothing */}
#endif

#ifdef __cplusplus
}
#endif

#endif
