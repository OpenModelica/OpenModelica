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

#define omc_dummyFileInfo_val {"",0,0,0,0,0}
extern const FILE_INFO omc_dummyFileInfo;

DLLExport extern void printInfo(FILE *stream, FILE_INFO info);
// Defined in omc_error.c
DLLExport extern void (*omc_assert)(threadData_t*, FILE_INFO, const char*, ...) __attribute__ ((noreturn));
DLLExport extern void (*omc_assert_warning)(FILE_INFO, const char*, ...);
DLLExport extern void (*omc_terminate)(FILE_INFO, const char*, ...);
DLLExport extern void (*omc_throw)(threadData_t*) __attribute__ ((noreturn));

// Defined in simulation_omc_assert.c
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

enum OMC_LOG_STREAM
{
  OMC_LOG_UNKNOWN = 0,
  OMC_LOG_STDOUT,
  OMC_LOG_ASSERT,

  OMC_LOG_DASSL,
  OMC_LOG_DASSL_STATES,
  OMC_LOG_DEBUG,
  OMC_LOG_DELAY,
  OMC_LOG_DIVISION,
  OMC_LOG_DSS,
  OMC_LOG_DSS_JAC,
  OMC_LOG_DT,
  OMC_LOG_DT_CONS,
  OMC_LOG_EVENTS,
  OMC_LOG_EVENTS_V,
  OMC_LOG_GBODE,
  OMC_LOG_GBODE_V,
  OMC_LOG_GBODE_NLS,
  OMC_LOG_GBODE_NLS_V,
  OMC_LOG_GBODE_STATES,
  OMC_LOG_INIT,
  OMC_LOG_INIT_HOMOTOPY,
  OMC_LOG_INIT_V,
  OMC_LOG_IPOPT,
  OMC_LOG_IPOPT_FULL,
  OMC_LOG_IPOPT_JAC,
  OMC_LOG_IPOPT_HESSE,
  OMC_LOG_IPOPT_ERROR,
  OMC_LOG_JAC,
  OMC_LOG_LS,
  OMC_LOG_LS_V,
  OMC_LOG_MIXED,
  OMC_LOG_NLS,
  OMC_LOG_NLS_V,
  OMC_LOG_NLS_HOMOTOPY,
  OMC_LOG_NLS_JAC,
  OMC_LOG_NLS_JAC_TEST,
  OMC_LOG_NLS_NEWTON_DIAG,
  OMC_LOG_NLS_RES,
  OMC_LOG_NLS_EXTRAPOLATE,
  OMC_LOG_RES_INIT,
  OMC_LOG_RT,
  OMC_LOG_SIMULATION,
  OMC_LOG_SOLVER,
  OMC_LOG_SOLVER_V,
  OMC_LOG_SOLVER_CONTEXT,
  OMC_LOG_SOTI,
  OMC_LOG_SPATIALDISTR,
  OMC_LOG_STATS,
  OMC_LOG_STATS_V,
  OMC_LOG_SUCCESS,
  OMC_LOG_SYNCHRONOUS,
#ifdef USE_DEBUG_TRACE
  OMC_LOG_TRACE,
#endif
  OMC_LOG_ZEROCROSSINGS,

  OMC_SIM_LOG_MAX
};

enum OMC_LOG_TYPE
{
  OMC_LOG_TYPE_UNKNOWN = 0,
  OMC_LOG_TYPE_INFO,
  OMC_LOG_TYPE_WARNING,
  OMC_LOG_TYPE_ERROR,
  OMC_LOG_TYPE_ASSERT,
  OMC_LOG_TYPE_DEBUG,
  OMC_LOG_TYPE_MAX
};

extern const int firstOMCErrorStream;
extern const char *OMC_LOG_STREAM_NAME[OMC_SIM_LOG_MAX];
extern const char *OMC_LOG_STREAM_DESC[OMC_SIM_LOG_MAX];
extern const char *OMC_LOG_STREAM_DETAILED_DESC[OMC_SIM_LOG_MAX];
extern const char *OMC_LOG_TYPE_DESC[OMC_LOG_TYPE_MAX];

extern int omc_useStream[OMC_SIM_LOG_MAX];
extern int omc_logLevel[OMC_SIM_LOG_MAX];
extern int omc_logLastType[OMC_SIM_LOG_MAX];
extern int omc_logLastStream;
extern int omc_showAllWarnings;
extern char omc_logBuffer[2048];

#define OMC_ACTIVE_STREAM(stream)    (omc_useStream[stream])
#define OMC_ACTIVE_WARNING_STREAM(stream)    (omc_showAllWarnings || omc_useStream[stream])

#ifdef USE_DEBUG_OUTPUT
  #define OMC_DEBUG_STREAM(stream)    (omc_useStream[stream])
#else
  #define OMC_DEBUG_STREAM(stream)    (0)
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

extern void (*messageFunction)(int type, int stream, FILE_INFO info, int indentNext, char *msg, int subline, const int *indexes);
extern void (*messageClose)(int stream);
extern void (*messageCloseWarning)(int stream);

#if !defined(OMC_MINIMAL_LOGGING)
extern void infoStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void va_infoStreamPrint(int stream, int indentNext, const char *format, va_list ap);
extern void infoStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
extern void warningStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void va_warningStreamPrint(int stream, int indentNext, const char *format,va_list ap);
extern void warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
extern void va_warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format,va_list ap);
extern void warningStreamPrintWithLimit(int stream, int indentNext, unsigned long nDisplayed, unsigned long maxWarnDisplays, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
extern void errorStreamPrint(int stream, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
extern void va_errorStreamPrint(int stream, int indentNext, const char *format, va_list ap);
extern void va_errorStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format,va_list ap);
#else
static inline void infoStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void va_infoStreamPrint(int stream, int indentNext, const char *format, va_list ap) {}
static inline void infoStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...) {}
static inline void warningStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void va_warningStreamPrint(int stream, int indentNext, const char *format,va_list ap) {}
static inline void warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...) {}
static inline void va_warningStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format,va_list ap) {}
static inline void warningStreamPrintWithLimit(int stream, int indentNext, unsigned long nDisplayed, unsigned long maxWarnDisplays, const char *format, ...) {}
static inline void errorStreamPrint(int stream, int indentNext, const char *format, ...) {}
static inline void va_errorStreamPrint(int stream, int indentNext, const char *format, va_list ap) {}
static inline void va_errorStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format,va_list ap) {}
#endif

extern void va_throwStreamPrint(threadData_t *threadData, const char *format, va_list ap) __attribute__ ((noreturn));
extern void throwStreamPrint(threadData_t *threadData, const char *format, ...) __attribute__ ((format (printf, 2, 3), noreturn));
extern void throwStreamPrintWithEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 4, 5), noreturn));
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
    throwStreamPrint(NULL, "%s:%d: %s: Assertion `%s` failed.\n",  __FILE__, __LINE__, OMC_FUNCTION, #expr); \
    exit(1); \
  }

#ifdef USE_DEBUG_OUTPUT
void debugStreamPrint(int stream, FILE_INFO info, int indentNext, const char *format, ...) __attribute__ ((format (printf, 3, 4)));
void debugStreamPrintWithEquationIndexes(int stream, FILE_INFO info, int indentNext, const int *indexes, const char *format, ...) __attribute__ ((format (printf, 5, 6)));
#else
static OMC_INLINE void debugStreamPrint(int stream __attribute__((unused)), int indentNext __attribute__((unused)), const char *format __attribute__((unused)), ...) __attribute__ ((format (printf, 3, 4)));
static OMC_INLINE void debugStreamPrint(int stream __attribute__((unused)), int indentNext __attribute__((unused)), const char *format __attribute__((unused)), ...) {/* Do nothing */}
static OMC_INLINE void debugStreamPrintWithEquationIndexes(int stream __attribute__((unused)), FILE_INFO info, int indentNext __attribute__((unused)), const int *indexes __attribute__((unused)), const char *format __attribute__((unused)), ...) __attribute__ ((format (printf, 5, 6)));
static OMC_INLINE void debugStreamPrintWithEquationIndexes(int stream  __attribute__((unused)), FILE_INFO info __attribute__((unused)), int indentNext __attribute__((unused)), const int *indexes __attribute__((unused)), const char *format __attribute__((unused)), ...)  {/* Do nothing */}
#endif

#ifdef __cplusplus
}
#endif

#endif
