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

/* Stack overflow handling */

#if (defined(__linux__) || defined(__FreeBSD__)) && !defined(_GNU_SOURCE)
#define _GNU_SOURCE 1
/* for pthread_getattr_np */
#endif

#if defined(__FreeBSD__)
#include <pthread_np.h>
#endif

#include "../gc/omc_gc.h"
#include "omc_init.h"

void mmc_clearStacktraceMessages(threadData_t *threadData)
{
  threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW] = 0;
}

int mmc_hasStacktraceMessages(threadData_t *threadData)
{
  return threadData->localRoots[LOCAL_ROOT_STACK_OVERFLOW] != 0;
}

#if (defined(__linux__) && defined(__GLIBC__)) || defined(__APPLE__) || defined(__FreeBSD__)
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

/* If we find a SIGSEGV near the end of the stack, it is probably due to a stack overflow. 64kB for a function frame seems reasonable. */
#define LIMIT_FOR_STACK_OVERFLOW 65536

static void *trace[MMC_SEGV_TRACE_NFRAMES];
static int trace_size;
static int trace_size_skip=0; /* First index we should use; that is skip handler, etc */
static struct sigaction default_segv_action;

void printStacktraceMessages(void) {
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
  if (trace_size==MMC_SEGV_TRACE_NFRAMES) {
    fprintf(stderr,"[bt] [...]\n");
  }
  free(messages);
}

void mmc_setStacktraceMessages(int numSkip, int numFrames) {
  trace_size = 0;
  trace_size = backtrace(trace, numFrames == 0 ? MMC_SEGV_TRACE_NFRAMES : numFrames > MMC_SEGV_TRACE_NFRAMES ? MMC_SEGV_TRACE_NFRAMES : numFrames);
  trace_size_skip = numSkip;
}


static sigset_t segvset;

static void handler(int signo, siginfo_t *si, void *ptr)
{
  int unused __attribute__((unused)), isStackOverflow;
  threadData_t *threadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key);
  isStackOverflow = si->si_addr < threadData->stackBottom
                 && (char*)si->si_addr > (char*)threadData->stackBottom - LIMIT_FOR_STACK_OVERFLOW;
  if (isStackOverflow) {
    mmc_setStacktraceMessages(1,0);
    sigprocmask(SIG_UNBLOCK, &segvset, NULL);
    longjmp(*threadData->mmc_stack_overflow_jumper,1);
  }
  /* This backtrace uses very little stack-space, and segmentation faults we always want to print... */
  mmc_setStacktraceMessages(1,16);
  unused=write(2, "\nLimited backtrace at point of segmentation fault\n", 50);
  backtrace_symbols_fd(trace+trace_size_skip, trace_size-trace_size_skip, 2);
  sigaction(SIGSEGV, &default_segv_action, 0);
}

#if defined(__APPLE__)
#include <AvailabilityMacros.h>
#include <sys/sysctl.h>
#endif

static void* getStackBase(void) {
  /* Warning: These functions are highly non-portable and are recommended to not be used.
   * We only tested them on Linux and OSX.
   * On OSX we get the top of the stack and the size
   * On Linux we get the bottom, so we don't need the size... YMMV
   */
  void* stackBottom;
  pthread_t self = pthread_self();
#if !defined(__APPLE__)
  size_t size = 0;
  pthread_attr_t sattr;
  pthread_attr_init(&sattr);
#if defined(__FreeBSD__)
  assert(0==pthread_attr_get_np(self, &sattr));
#else // normal Linux
  assert(0==pthread_getattr_np(self, &sattr));
#endif
  assert(0==pthread_attr_getstack(&sattr, &stackBottom, &size));
#if defined(__FreeBSD__)
  // if we get a 0 stackBottom, try a different strategy
  if (!stackBottom) {
    void* stack_addr = NULL;
    assert(0==pthread_attr_getstackaddr(&sattr, &stack_addr));
    // if we get a 0 as stack address, all bets are off
    assert(stack_addr);
    assert(0==pthread_attr_getstacksize(&sattr, &size));
    stackBottom = (void*) (((long)stack_addr) - size);
  }
#endif
  assert(stackBottom);
  pthread_attr_destroy(&sattr);
#else
  void* stack_addr = pthread_get_stackaddr_np(self);
  size_t size = pthread_get_stacksize_np(self);
  stackBottom = (void*) (((long)stack_addr) - size);
  /* This workaround is only built if compiling for/on legacy OS X 10.9 (Mavericks) or older */
#if defined(MAC_OS_X_VERSION_MAX_ALLOWED) && MAC_OS_X_VERSION_MAX_ALLOWED <= 1090
  if (pthread_main_np()) {
    char str[256];
    size_t size_str = sizeof(str);
    int ret = sysctlbyname("kern.osrelease", str, &size_str, NULL, 0);
    if (0==ret && str[0]=='1' && str[1]=='3' && str[2]=='.') {
      /* OSX Mavericks returns a wrong stack size... Assume default 8MB */
      stackBottom = (void*) (((long)stack_addr) - 8 * 1024 * 1024);
    }
  }
#endif
#endif
  assert(size > 128*1024);
  return (char*)stackBottom + 64*1024;
}

/* The alternate signal stack has to outlive every frame that could fault on it,
   so it is allocated once and never freed; the handle keeps it reachable. */
static char *segv_altstack = NULL;

void init_metamodelica_segv_handler(void)
{
  stack_t ss;
  struct sigaction sa = {
      .sa_sigaction = handler,
      .sa_flags = SA_ONSTACK | SA_SIGINFO
  };

  segv_altstack = (char*) malloc(SIGSTKSZ);
  ss.ss_size = SIGSTKSZ;
  ss.ss_sp = segv_altstack;
  ss.ss_flags = 0;
  sigaltstack(&ss, 0);
  sigfillset(&sa.sa_mask);
  sigaction(SIGSEGV, &sa, &default_segv_action);
  sigfillset(&segvset);
}

void mmc_init_stackoverflow(threadData_t *threadData)
{
  /* Keep a known bottom: a library omc dlopens with RTLD_DEEPBIND has its own
     mmc_thread_data_key, so its in_<fn> wrapper lands here with omc's
     threadData, and a bottom taken from this deep frame trips the next MMC_SO(). */
  if (threadData->stackBottom) {
    return;
  }
  threadData->stackBottom = getStackBase();
}

#else

void printStacktraceMessages()
{
}

void init_metamodelica_segv_handler(void)
{
}

void mmc_init_stackoverflow(threadData_t *threadData)
{
  threadData->stackBottom = (void *)0x1; /* Dummy until Windows detects the stack bottom */
}
#endif

/* omc records the trace as a MetaModelica list, through a hook meta/ installs
   (meta_modelica_segv.c); a simulation leaves it unset. */
static void (*stacktrace_capture)(threadData_t*, int, int) = NULL;

void omc_set_stacktrace_capture(void (*fn)(threadData_t*, int, int))
{
  stacktrace_capture = fn;
}

void mmc_do_stackoverflow(threadData_t *threadData)
{
  if (stacktrace_capture) {
    stacktrace_capture(threadData, 1, MMC_SEGV_TRACE_NFRAMES);
  }
  longjmp(*threadData->mmc_stack_overflow_jumper, 1);
}
