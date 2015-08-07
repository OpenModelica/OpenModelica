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

/* Stack overflow handling */

#if defined(linux) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE 1
/* for pthread_getattr_np */
#endif
#include "meta_modelica.h"

pthread_key_t mmc_stack_overflow_jumper;

#if defined(linux) || defined(__APPLE_CC__)
#include <stdlib.h>
#include <stdio.h>
#include <signal.h>
#include <stdio.h>
#include <signal.h>
#include <execinfo.h>
#include <sys/time.h>
#include <sys/resource.h>
#include <assert.h>
#include <pthread.h>
#include <setjmp.h>
#include <unistd.h>

/* Really 64kB memory for this? Oh well... */
#define TRACE_NFRAMES 65536
/* If we find a SIGSEGV near the end of the stack, it is probably due to a stack overflow. 64kB for a function frame seems reasonable. */
#define LIMIT_FOR_STACK_OVERFLOW 65536

static void *trace[TRACE_NFRAMES];
static int trace_size;
static int trace_size_skip=0; /* First index we should use; that is skip handler, etc */
static void *stackBottom;
static struct sigaction default_segv_action;

void printStacktraceMessages() {
  int i,j=-1,k;
  char **messages = backtrace_symbols(trace, trace_size);
  fprintf(stderr,"[bt] Execution path:\n");
  for (i=trace_size_skip; i<trace_size; ++i)
  {
    if (i<trace_size-1 && trace[i] == trace[i+1]) {
      j=j==-1?i:j;
    } else if (j>=0) {
      k=19-fprintf(stderr,"[bt] #%d..%d", j-trace_size_skip, i-trace_size_skip);
      while (k-->0) fprintf(stderr, " ");
      fprintf(stderr,"%s\n", messages[i]);
      j=-1;
    } else {
      k=19-fprintf(stderr,"[bt] #%d   ", i-trace_size_skip);
      while (k-->0) fprintf(stderr, " ");
      fprintf(stderr,"%s\n", messages[i]);
    }
  }
  if (trace_size==TRACE_NFRAMES) {
    fprintf(stderr,"[bt] [...]\n");
  }
  free(messages);
}

static inline void setTrace(int numSkip, int numFrames) {
  trace_size = 0;
  trace_size = backtrace(trace, numFrames == 0 ? TRACE_NFRAMES : numFrames > TRACE_NFRAMES ? TRACE_NFRAMES : numFrames);
  trace_size_skip = numSkip;
}

static sigset_t segvset;

static void handler(int signo, siginfo_t *si, void *ptr)
{
  int unused __attribute__((unused)), isStackOverflow;
  isStackOverflow = si->si_addr < stackBottom && (si->si_addr > stackBottom - LIMIT_FOR_STACK_OVERFLOW);
  if (isStackOverflow) {
    setTrace(1,0);
    sigprocmask(SIG_UNBLOCK, &segvset, NULL);
    longjmp(*((threadData_t*)pthread_getspecific(mmc_thread_data_key))->mmc_stack_overflow_jumper,1);
  }
  /* This backtrace uses very little stack-space, and segmentation faults we always want to print... */
  setTrace(1,16);
  unused=write(2, "\nLimited backtrace at point of segmentation fault\n", 50);
  backtrace_symbols_fd(trace+trace_size_skip, trace_size-trace_size_skip, 2);
  sigaction(SIGSEGV, &default_segv_action, 0);
}

static void getStackBase() {
  /* Warning: These functions are highly non-portable and are recommended to not be used.
   * We only tested them on Linux and OSX.
   * On OSX we get the top of the stack and the size
   * On Linux we get the bottom, so we don't need the size... YMMV
   */
  pthread_t self = pthread_self();
#if !defined(__APPLE_CC__)
  size_t size = 0;
  pthread_attr_t sattr;
  pthread_attr_init(&sattr);
  pthread_getattr_np(self, &sattr);
  assert(0==pthread_attr_getstack(&sattr, &stackBottom, &size));
  assert(stackBottom);
  pthread_attr_destroy(&sattr);
#else
  void* addr = pthread_get_stackaddr_np(self);
  size_t size = pthread_get_stacksize_np(self);
  stackBottom = ((long)addr) - size;
#endif
}

void init_metamodelica_segv_handler()
{
  char *stack = (char*)malloc(SIGSTKSZ);
  stack_t ss = {
      .ss_size = SIGSTKSZ,
      .ss_sp = stack,
  };
  struct sigaction sa = {
      .sa_sigaction = handler,
      .sa_flags = SA_ONSTACK | SA_SIGINFO
  };
  getStackBase();
  sigaltstack(&ss, 0);
  sigfillset(&sa.sa_mask);
  sigaction(SIGSEGV, &sa, &default_segv_action);
  sigfillset(&segvset);
}

#else
void printStacktraceMessages()
{
}
void init_metamodelica_segv_handler()
{
}
#endif
