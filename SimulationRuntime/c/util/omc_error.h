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


#ifndef OMC_ERROR_H
#define OMC_ERROR_H

#include <setjmp.h>
#include <stdio.h>

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

extern void printInfo(FILE *stream, FILE_INFO info);
extern void (*omc_assert)(FILE_INFO,const char*, ...);
extern void (*omc_assert_warning)(FILE_INFO,const char*, ...);
extern void (*omc_terminate)(FILE_INFO,const char*, ...);
extern void (*omc_throw)();
void initDumpSystem();
void omc_assert_function(FILE_INFO info, const char *msg, ...);
void omc_assert_warning_function(FILE_INFO info, const char *msg, ...);
void omc_terminate_function(FILE_INFO info, const char *msg, ...);
void omc_throw_function();

/* global JumpBuffer */
extern jmp_buf globalJmpbuf;

enum ERROR_HANDLE
{
  ERROR_UNKOWN = 0,
  ERROR_SIMULATION,
  ERROR_INTEGRATOR,
  ERROR_NONLINEARSOLVER,
  ERROR_EVENTSEARCH,
  ERROR_OPTIMIZE,

  ERROR_MAX
};

/* #define USE_DEBUG_OUTPUT */

enum LOG_STREAM
{
  LOG_UNKNOWN = 0,
  LOG_STDOUT,
  LOG_ASSERT,

  LOG_DDASRT,
  LOG_DEBUG,
  LOG_DSS,
  LOG_DSS_JAC,
  LOG_EVENTS,
  LOG_EVENTS_V,
  LOG_INIT,
  LOG_IPOPT,
  LOG_JAC,
  LOG_LS,
  LOG_LS_V,
  LOG_NLS,
  LOG_NLS_V,
  LOG_NLS_JAC,
  LOG_RES_INIT,
  LOG_SIMULATION,
  LOG_SOLVER,
  LOG_SOTI,
  LOG_STATS,
  LOG_UTIL,
  LOG_ZEROCROSSINGS,


  LOG_MAX
};

extern const int firstOMCErrorStream;
extern const char *LOG_STREAM_NAME[LOG_MAX];
extern const char *LOG_STREAM_DESC[LOG_MAX];
extern const char *LOG_STREAM_DETAILED_DESC[LOG_MAX];

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

extern int useStream[LOG_MAX];
extern int level[LOG_MAX];
extern int lastType[LOG_MAX];
extern int lastStream;
extern int showAllWarnings;
extern char logBuffer[2048];

void Message(int type, int stream, char *msg, int subline);

#define INDENT(stream)           do{level[stream]++;}while(0)
#define RELEASE(stream)          do{level[stream]--; if(level[stream] < 0) level[stream] = 0;}while(0)
#define RESET_INDENTION(stream)  do{level[stream] = 0;}while(0)
#define ACTIVE_STREAM(stream)    (useStream[stream])

#ifdef USE_DEBUG_OUTPUT
  #define DEBUG_STREAM(stream)    (useStream[stream])
#else
  #define DEBUG_STREAM(stream)    (0)
#endif

#define   INFO(stream, msg)                                  do{if(useStream[stream]){sprintf(logBuffer, msg);                               Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO1(stream, msg, a)                               do{if(useStream[stream]){sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO2(stream, msg, a, b)                            do{if(useStream[stream]){sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO3(stream, msg, a, b, c)                         do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO4(stream, msg, a, b, c, d)                      do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO5(stream, msg, a, b, c, d, e)                   do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO6(stream, msg, a, b, c, d, e, f)                do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO7(stream, msg, a, b, c, d, e, f, g)             do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO8(stream, msg, a, b, c, d, e, f, g, h)          do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define  INFO9(stream, msg, a, b, c, d, e, f, g, h, i)       do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)
#define INFO10(stream, msg, a, b, c, d, e, f, g, h, i, j)    do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_INFO, stream, logBuffer, 0);}}while(0)

#define   WARNING(stream, msg)                               do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg);                               Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING1(stream, msg, a)                            do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING2(stream, msg, a, b)                         do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING3(stream, msg, a, b, c)                      do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING4(stream, msg, a, b, c, d)                   do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING5(stream, msg, a, b, c, d, e)                do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING6(stream, msg, a, b, c, d, e, f)             do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING7(stream, msg, a, b, c, d, e, f, g)          do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING8(stream, msg, a, b, c, d, e, f, g, h)       do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define  WARNING9(stream, msg, a, b, c, d, e, f, g, h, i)    do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)
#define WARNING10(stream, msg, a, b, c, d, e, f, g, h, i, j) do{if(showAllWarnings || useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_WARNING, stream, logBuffer, 0);}}while(0)

#define  ERROR0(stream, msg)                                 do{sprintf(logBuffer, msg);                               Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR1(stream, msg, a)                              do{sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR2(stream, msg, a, b)                           do{sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR3(stream, msg, a, b, c)                        do{sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR4(stream, msg, a, b, c, d)                     do{sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR5(stream, msg, a, b, c, d, e)                  do{sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR6(stream, msg, a, b, c, d, e, f)               do{sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR7(stream, msg, a, b, c, d, e, f, g)            do{sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR8(stream, msg, a, b, c, d, e, f, g, h)         do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define  ERROR9(stream, msg, a, b, c, d, e, f, g, h, i)      do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)
#define ERROR10(stream, msg, a, b, c, d, e, f, g, h, i, j)   do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_ERROR, stream, logBuffer, 0);}while(0)

#define   ASSERT(exp, msg)                                   do{if(!(exp)){sprintf(logBuffer, msg);                               Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT1(exp, msg, a)                                do{if(!(exp)){sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT2(exp, msg, a, b)                             do{if(!(exp)){sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT3(exp, msg, a, b, c)                          do{if(!(exp)){sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT4(exp, msg, a, b, c, d)                       do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT5(exp, msg, a, b, c, d, e)                    do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT6(exp, msg, a, b, c, d, e, f)                 do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT7(exp, msg, a, b, c, d, e, f, g)              do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT8(exp, msg, a, b, c, d, e, f, g, h)           do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define  ASSERT9(exp, msg, a, b, c, d, e, f, g, h, i)        do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)
#define ASSERT10(exp, msg, a, b, c, d, e, f, g, h, i, j)     do{if(!(exp)){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}}while(0)

#define   THROW(msg)                                         do{sprintf(logBuffer, msg);                               Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW1(msg, a)                                      do{sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW2(msg, a, b)                                   do{sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW3(msg, a, b, c)                                do{sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW4(msg, a, b, c, d)                             do{sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW5(msg, a, b, c, d, e)                          do{sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW6(msg, a, b, c, d, e, f)                       do{sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW7(msg, a, b, c, d, e, f, g)                    do{sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW8(msg, a, b, c, d, e, f, g, h)                 do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define  THROW9(msg, a, b, c, d, e, f, g, h, i)              do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)
#define THROW10(msg, a, b, c, d, e, f, g, h, i, j)           do{sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_ASSERT, LOG_ASSERT, logBuffer, 0); longjmp(globalJmpbuf, 1);}while(0)

#ifdef USE_DEBUG_OUTPUT
  #define   DEBUG(stream, msg)                               do{if(useStream[stream]){sprintf(logBuffer, msg);                               Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG1(stream, msg, a)                            do{if(useStream[stream]){sprintf(logBuffer, msg, a);                            Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG2(stream, msg, a, b)                         do{if(useStream[stream]){sprintf(logBuffer, msg, a, b);                         Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG3(stream, msg, a, b, c)                      do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c);                      Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG4(stream, msg, a, b, c, d)                   do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d);                   Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG5(stream, msg, a, b, c, d, e)                do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e);                Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG6(stream, msg, a, b, c, d, e, f)             do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f);             Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG7(stream, msg, a, b, c, d, e, f, g)          do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g);          Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG8(stream, msg, a, b, c, d, e, f, g, h)       do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h);       Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define  DEBUG9(stream, msg, a, b, c, d, e, f, g, h, i)    do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i);    Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
  #define DEBUG10(stream, msg, a, b, c, d, e, f, g, h, i, j) do{if(useStream[stream]){sprintf(logBuffer, msg, a, b, c, d, e, f, g, h, i, j); Message(LOG_TYPE_DEBUG, stream, logBuffer, 0);}}while(0)
#else
  #define   DEBUG(stream, msg)                               /* do nothing */
  #define  DEBUG1(stream, msg, a)                            /* do nothing */
  #define  DEBUG2(stream, msg, a, b)                         /* do nothing */
  #define  DEBUG3(stream, msg, a, b, c)                      /* do nothing */
  #define  DEBUG4(stream, msg, a, b, c, d)                   /* do nothing */
  #define  DEBUG5(stream, msg, a, b, c, d, e)                /* do nothing */
  #define  DEBUG6(stream, msg, a, b, c, d, e, f)             /* do nothing */
  #define  DEBUG7(stream, msg, a, b, c, d, e, f, g)          /* do nothing */
  #define  DEBUG8(stream, msg, a, b, c, d, e, f, g, h)       /* do nothing */
  #define  DEBUG9(stream, msg, a, b, c, d, e, f, g, h, i)    /* do nothing */
  #define DEBUG10(stream, msg, a, b, c, d, e, f, g, h, i, j) /* do nothing */
#endif

#ifdef __cplusplus
}
#endif

#endif
