/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */


/* The stack-overflow trace as a MetaModelica list. The handling itself is in
   util/omc_stackoverflow.c, shared with the simulation runtime. */

#include "meta_modelica.h"
#include "meta_modelica_string.h"
#include "meta_modelica_segv.h"
#include "../util/omc_stackoverflow.h"
#include <assert.h>
#include <stdlib.h>

#if (defined(__linux__) && defined(__GLIBC__)) || defined(__APPLE__) || defined(__FreeBSD__)
#include <execinfo.h>

#define _OMC_LIT_OOM_data "Out of memory! Printed backtrace to stderr."
static const MMC_DEFSTRINGLIT(_OMC_LIT_STRUCT_OOM,45,_OMC_LIT_OOM_data);
static const MMC_DEFSTRUCTLIT(_OMC_LIT_STRUCT_OOM_LST,2,1) {MMC_REFSTRINGLIT(_OMC_LIT_STRUCT_OOM),MMC_REFSTRUCTLIT(mmc_nil)}};

void mmc_setStacktraceMessages_threadData(threadData_t *threadData, int numSkip, int numFrames)
{
  void **trace;
  char **messages;
  void *res;
  int i;
  int trace_size;

  assert(numFrames > 0);

  trace = (void**) malloc(numFrames*sizeof(void*));
  if (trace==0) {
    mmc_setStacktraceMessages(numSkip, numFrames);
    printStacktraceMessages();
    threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW] = MMC_REFSTRINGLIT(_OMC_LIT_STRUCT_OOM_LST);
    return;
  }
  trace_size = backtrace(trace, numFrames);

  res = mmc_mk_nil();
  messages = backtrace_symbols(trace, trace_size);

  if (trace_size==numFrames) {
    res = mmc_mk_cons(mmc_mk_scon("[...]"), res);
  }
  for (i=trace_size-1; i>=numSkip; --i) {
    res = mmc_mk_cons(mmc_mk_scon(messages[i]), res);
  }
  free(trace);
  free(messages);
  threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW] = res;
}

#else

void mmc_setStacktraceMessages_threadData(threadData_t *threadData, int numSkip, int numFrames)
{
  threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW] = mmc_mk_cons(mmc_mk_scon("[... unsupported platform for backtraces]"), mmc_mk_nil());
}

#endif

void* mmc_getStacktraceMessages_threadData(threadData_t *threadData)
{
  if (!threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW]) {
    MMC_THROW_INTERNAL();
  }
  return threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW];
}

/* omc captures the trace; a simulation leaves the hook unset. */
static void __attribute__((constructor)) install_stacktrace_capture(void)
{
  omc_set_stacktrace_capture(mmc_setStacktraceMessages_threadData);
}
