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

#include <stdarg.h>
#include <stddef.h>
#include "../util/omc_error.h"
#include "../util/utility.h"
#include "../meta/meta_modelica.h"
#include "simulation_runtime.h"

int terminationTerminate = 0; /* Becomes non-zero when user terminates simulation. */
FILE_INFO TermInfo;           /* message for termination. */
char* TermMsg;                /* message for termination. */

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
    termMsgSize = modelica_integer_max(strlen(msg)*2+1,(size_t)2048);
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

static void omc_assert_simulation(threadData_t *threadData, FILE_INFO info, const char *msg, ...) __attribute__ ((noreturn));
static void omc_assert_simulation_withEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *msg, ...) __attribute__ ((noreturn));
static void omc_throw_simulation(threadData_t* threadData) __attribute__ ((noreturn));
static void va_omc_assert_simulation_withEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *msg, va_list args) __attribute__ ((noreturn));

static void va_omc_assert_simulation_withEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *msg, va_list args)
{
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  switch (threadData->currentErrorStage)
  {
  case ERROR_EVENTSEARCH:
  case ERROR_SIMULATION:
    va_errorStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
    longjmp(*threadData->simulationJumpBuffer,1);
    break;
  case ERROR_NONLINEARSOLVER:
    if(ACTIVE_STREAM(LOG_NLS))
    {
      va_errorStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
    }
#ifndef OMC_EMCC
    longjmp(*threadData->simulationJumpBuffer,1);
#endif
    break;
  case ERROR_INTEGRATOR:
    if(ACTIVE_STREAM(LOG_SOLVER))
    {
      va_errorStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
    }
    longjmp(*threadData->simulationJumpBuffer,1);
    break;
  case ERROR_EVENTHANDLING:
    va_errorStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
    longjmp(threadData->globalJumpBuffer ? *threadData->globalJumpBuffer : *threadData->mmc_jumper, 1);
    break;
  case ERROR_OPTIMIZE:
  default:
    va_errorStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
    throwStreamPrint(threadData, "Untreated assertion has been detected.");
  }
}

static void omc_assert_simulation(threadData_t *threadData, FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  va_omc_assert_simulation_withEquationIndexes(threadData, info, NULL, msg, args);
  va_end(args);
}

static void omc_assert_simulation_withEquationIndexes(threadData_t *threadData, FILE_INFO info, const int *indexes, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  va_omc_assert_simulation_withEquationIndexes(threadData, info, indexes, msg, args);
  va_end(args);
}


static void va_omc_assert_warning_simulation(FILE_INFO info, const int *indexes, const char *msg, va_list args)
{
  va_warningStreamPrintWithEquationIndexes(LOG_ASSERT, 0, indexes, msg, args);
}

static void omc_assert_warning_simulation(FILE_INFO info, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  va_omc_assert_warning_simulation(info, NULL, msg, args);
  va_end(args);
}

static void omc_assert_warning_simulation_withEquationIndexes(FILE_INFO info, const int *indexes, const char *msg, ...)
{
  va_list args;
  va_start(args, msg);
  va_omc_assert_warning_simulation(info, indexes, msg, args);
  va_end(args);
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

/*
 * adrpo: workaround function to call setTermMsg with empty va_list!
 *        removes the uninitialized warning for va_list variable.
 */
void setTermMsg_empty_va_list(const char *msg, ...) {
  va_list dummy;
  va_start(dummy, msg);
  setTermMsg(msg, dummy);
  va_end(dummy);
}

static void omc_throw_simulation(threadData_t* threadData)
{
  setTermMsg_empty_va_list("Assertion triggered by external C function");
  set_struct(FILE_INFO, TermInfo, omc_dummyFileInfo);
  threadData = threadData ? threadData : (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  longjmp(*threadData->globalJumpBuffer, 1);
}

void (*omc_assert)(threadData_t*, FILE_INFO info, const char *msg, ...)  __attribute__ ((noreturn)) = omc_assert_simulation;
void (*omc_assert_withEquationIndexes)(threadData_t*, FILE_INFO info, const int *indexes, const char *msg, ...)  __attribute__ ((noreturn)) = omc_assert_simulation_withEquationIndexes;

void (*omc_assert_warning_withEquationIndexes)(FILE_INFO info, const int *indexes, const char *msg, ...) = omc_assert_warning_simulation_withEquationIndexes;
void (*omc_assert_warning)(FILE_INFO info, const char *msg, ...) = omc_assert_warning_simulation;
void (*omc_terminate)(FILE_INFO info, const char *msg, ...) = omc_terminate_simulation;
void (*omc_throw)(threadData_t*) __attribute__ ((noreturn)) = omc_throw_simulation;
