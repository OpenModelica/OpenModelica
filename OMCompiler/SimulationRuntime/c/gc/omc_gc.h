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

/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file defines the MetaModelica garbage collector (GC) interface
 * We use Boehm GC mark-and-sweep collector.
 *
 *
 */

#ifndef OMC_GC_H_
#define OMC_GC_H_
#include "../omc_dll.h"

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdlib.h>
#if defined(OM_HAVE_PTHREADS)
#include <pthread.h>
#endif
#include <setjmp.h>

#if defined(_MSC_VER)
#include "omc_dll.h"
#include "omc_inline.h"
#include "util/omc_msvc.h"
#elif !defined(DLLDataDirection)
/* Not omc_dll.h: reaching it needs c/ on the include path. */
#define DLLDataDirection
#endif

typedef struct {
  void (*init)(void);
  void* (*malloc)(size_t);
  void* (*malloc_atomic)(size_t);
  char* (*malloc_string)(size_t);
  char* (*malloc_strdup)(const char*);
  int (*collect_a_little)(void);
  void* (*malloc_uncollectable)(size_t);
  void (*free_uncollectable)(void*);
  void* (*malloc_string_persist)(size_t);
  void (*free_string_persist)(void*);
} omc_alloc_interface_t;

DLLDataDirection extern omc_alloc_interface_t omc_alloc_interface;
extern omc_alloc_interface_t omc_alloc_interface_rc;

/*
 * ERROR_STAGE defines different
 * stages where an assertion can be triggered.
 *
 */
typedef enum {
  ERROR_UNKOWN = 0,
  ERROR_SIMULATION,
  ERROR_INTEGRATOR,
  ERROR_NONLINEARSOLVER,
  ERROR_EVENTSEARCH,
  ERROR_EVENTHANDLING,
  ERROR_OPTIMIZE,
  ERROR_MAX
} errorStage;

typedef void (*PlotCallback)(void*, int externalWindow, const char* filename, const char* title, const char* grid, const char* plotType, const char* logX,
    const char* logY, const char* xLabel, const char* yLabel, const char* x1, const char* x2, const char* y1, const char* y2,
    const char* curveWidth, const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
    const char* variables);

typedef void (*LoadModelCallback)(void*, const char* modelname);

/* Thread-specific data passed around in most functions.
 * It is also possible to fetch it using pthread_getspecific (mostly for external functions that were not passed the pointer) */
enum {
  LOCAL_ROOT_USER_DEFINED_0,
  LOCAL_ROOT_USER_DEFINED_1,
  LOCAL_ROOT_USER_DEFINED_2,
  LOCAL_ROOT_USER_DEFINED_3,
  LOCAL_ROOT_USER_DEFINED_4,
  LOCAL_ROOT_USER_DEFINED_5,
  LOCAL_ROOT_USER_DEFINED_6,
  LOCAL_ROOT_USER_DEFINED_7,
  LOCAL_ROOT_USER_DEFINED_8,
  /* getGlobalRoot cannot access the following special local roots (only custom code can) */
  LOCAL_ROOT_ERROR_MO,
  LOCAL_ROOT_PRINT_MO,
  LOCAL_ROOT_SYSTEM_MO,
  LOCAL_ROOT_STACK_OVERFLOW,
  LOCAL_ROOT_URI_LOOKUP,
  MAX_LOCAL_ROOTS
};
#define LOCAL_ROOT_SIMULATION_DATA LOCAL_ROOT_ERROR_MO
#define LOCAL_ROOT_FMI_DATA LOCAL_ROOT_PRINT_MO
#define MAX_LOCAL_ROOTS 20

typedef struct threadData_s {
  jmp_buf *mmc_jumper;
  jmp_buf *mmc_stack_overflow_jumper;
  jmp_buf *mmc_thread_work_exit;
  void *localRoots[MAX_LOCAL_ROOTS];
/*
 * simulationJumpBufer:
 *  Jump-buffer to handle simulation error
 *  like asserts or divisions by zero.
 *
 * currentJumpStage:
 *   define which simulation jump buffer
 *   is currently used.
 */
  jmp_buf *globalJumpBuffer;
  jmp_buf *simulationJumpBuffer;
  errorStage currentErrorStage;
  struct threadData_s *parent;
#if defined(OM_HAVE_PTHREADS)
  pthread_mutex_t parentMutex; /* Prevent children from all manipulating the parent at the same time */
#endif
  void *plotClassPointer;
  PlotCallback plotCB;
  void *loadModelClassPointer;
  LoadModelCallback loadModelCB;
  int lastEquationSolved;
  void *stackBottom; /* Actually offset 64 kB from bottom, just to never reach the bottom */
  int errorState; /* A raised error, waiting to be returned; see OMC_ERROR_RAISE */
  /* Set only while an external function runs: its ModelicaError must land at
     the wrapper, not the solver. */
  jmp_buf *externalJumpBuffer;
} threadData_t;

typedef threadData_t OpenModelica_threadData_ThreadData;

/* Both runtimes jump for throwStreamPrint and stack overflow; a simulation
   also returns raised errors, so a solver recovering has to handle both. */
#define OMC_TRY_INTERNAL(X) { jmp_buf new_mmc_jumper, *old_jumper __attribute__((unused)) = threadData->X; threadData->X = &new_mmc_jumper; if (setjmp(new_mmc_jumper) == 0) {
#define OMC_CATCH_INTERNAL(X) } threadData->X = old_jumper;}
/* A block: generated code emits this without a terminating semicolon. */
#define OMC_THROW_INTERNAL() {longjmp(*threadData->mmc_jumper,1);}
#define OMC_INIT(X) pthread_once(&mmc_init_once, mmc_init)
#define OMC_TRY_TOP() { threadData_t threadDataOnStack = {0}, *oldThreadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key), *threadData = &threadDataOnStack; pthread_setspecific(mmc_thread_data_key,threadData); pthread_mutex_init(&threadData->parentMutex,NULL); mmc_init_stackoverflow_fast(threadData, oldThreadData); OMC_TRY_INTERNAL(mmc_jumper) threadData->mmc_stack_overflow_jumper = threadData->mmc_jumper;
#define OMC_TRY_TOP_INTERNAL() { threadData_t *oldThreadData = (threadData_t*)pthread_getspecific(mmc_thread_data_key); pthread_setspecific(mmc_thread_data_key,threadData); pthread_mutex_init(&threadData->parentMutex,NULL); mmc_init_stackoverflow_fast(threadData, oldThreadData); OMC_TRY_INTERNAL(mmc_jumper) threadData->mmc_stack_overflow_jumper = threadData->mmc_jumper;
#define OMC_RESTORE_INTERNAL(X) threadData->X = old_jumper;
#define OMC_SO() mmc_check_stackoverflow(threadData)

/* A simulation returns a raised error so that no frame is skipped and every
   release still runs; MetaModelica throws, and emits no check to catch one. */
#if defined(OMC_METAMODELICA_RUNTIME)
#define OMC_ERROR_RAISE()   OMC_THROW_INTERNAL()
#else
#define OMC_ERROR_RAISE()   ((void) (threadData->errorState = 1))
#endif
#define OMC_ERROR_RAISED()  (threadData->errorState != 0)
#define OMC_ERROR_CLEAR()   ((void) (threadData->errorState = 0))
/* Needs a _return: label in scope. */
#define OMC_ERROR_CHECK()   do { if (OMC_ERROR_RAISED()) { goto _return; } } while (0)
/* The runtime's own call sites, which have nothing to release. Never inside an
   OMC_TRY_INTERNAL block: leaving one without its catch strands the jumper. */
#define OMC_ERROR_CHECK_RETURN(X) do { if (OMC_ERROR_RAISED()) { return (X); } } while (0)
/* An external function's ModelicaError, once the wrapper caught the jump and
   gave back what the call allocated. */
#if defined(OMC_METAMODELICA_RUNTIME)
#define OMC_EXTERNAL_ERROR() OMC_ERROR_RAISE()
#else
void omc_external_error(threadData_t *threadData);
#define OMC_EXTERNAL_ERROR() omc_external_error(threadData)
#endif
#define OMC_TRY_STACK() { jmp_buf *oldMMCJumper = threadData->mmc_jumper; { OMC_TRY_INTERNAL(mmc_stack_overflow_jumper) threadData->mmc_stack_overflow_jumper = &new_mmc_jumper;
#define OMC_CATCH_STACK() OMC_CATCH_INTERNAL(mmc_stack_overflow_jumper) } threadData->mmc_jumper = oldMMCJumper; }
#define OMC_ELSE() } else { threadData->mmc_jumper = old_jumper;
#define OMC_ELSE_STACK() } else { threadData->mmc_jumper = oldMMCJumper; threadData->mmc_stack_overflow_jumper = old_jumper;
#define OMC_CATCH_TOP(X) pthread_setspecific(mmc_thread_data_key,oldThreadData); } else {pthread_setspecific(mmc_thread_data_key,oldThreadData);X;}}}
#define OMC_THROW() {threadData_t *td_ = (threadData_t*)pthread_getspecific(mmc_thread_data_key); longjmp(*td_->mmc_jumper,1);} /* needs util/omc_init.h at the use site */

#include "../util/omc_stackoverflow.h"
#include "../util/omc_init.h"
void mmc_do_out_of_memory(void) __attribute__ ((noreturn));
#define GC_RETURN_REPORT_ALLOC_FAILED(X) { void *res = (X); \
  if (0==res) { \
    mmc_do_out_of_memory(); \
  } \
  return res; }
static inline void* mmc_check_out_of_memory(void *ptr)
{
  if (0==ptr) {
    mmc_do_out_of_memory();
  }
  return ptr;
}

/* Only MetaModelica collects; a simulation counts (omc_rc.h). */
#if !defined(OMC_METAMODELICA_RUNTIME)
#define OMC_NO_BOEHM_GC 1
#endif

#if defined(OMC_NO_BOEHM_GC)

#define OMC_STATIC_ALLOC_IFACE omc_alloc_interface_rc

#if !defined(OMC_NO_GC_MAPPING)
#define GC_init                           OMC_STATIC_ALLOC_IFACE.init
#define GC_malloc                         OMC_STATIC_ALLOC_IFACE.malloc
#define GC_malloc_atomic                  OMC_STATIC_ALLOC_IFACE.malloc_atomic
#define GC_strdup                         OMC_STATIC_ALLOC_IFACE.malloc_strdup
#define GC_collect_a_little_or_not        OMC_STATIC_ALLOC_IFACE.collect_a_little
#define GC_malloc_uncollectable           OMC_STATIC_ALLOC_IFACE.malloc_uncollectable
/* GC_free means "dead now", not "free an uncollectable block". */
#define GC_free                           omc_rc_release
#define nofree                            OMC_STATIC_ALLOC_IFACE.free_string_persist
#define GC_malloc_atomic_ignore_off_page  OMC_STATIC_ALLOC_IFACE.malloc_atomic
#define GC_register_displacement(X)       /* nothing */
#define GC_set_force_unmap_on_gcollect(X) /* nothing */
#define omc_GC_set_max_heap_size(X)       /* nothing */
#define omc_GC_get_max_heap_size()        0
#endif

#else /* #if defined(OMC_NO_BOEHM_GC) */

#include <gc.h>
// No need for this I think. If you define GC_THREADS (linux) or GC_WIN32_PTHREADS (on Win/MinGW) before
// including gc.h these will be picked up.
// Make sure to define GC_THREADS (linux) or GC_WIN32_PTHREADS (on Win/MinGW) on the makefiles or
// compiler command line so that everything is picked up consistently by all headers.

/* gc.h doesn't include this by default; and the actual header redirects dlopen, which does not have an implementation */
// #if defined(OM_HAVE_PTHREADS)
// int GC_pthread_create(pthread_t *,const pthread_attr_t *,void *(*)(void *), void *);
// int GC_pthread_join(pthread_t, void **);
// #endif

void omc_GC_set_max_heap_size(size_t);
size_t omc_GC_get_max_heap_size(void);

#endif /* #if defined(OMC_NO_BOEHM_GC) */

/* A thread the collector has to know about, where there is one. Generated HPCOM
   code starts its ODE threads with this. */
#if defined(OM_HAVE_PTHREADS)
#if defined(OMC_NO_BOEHM_GC)
#define omc_pthread_create pthread_create
#define omc_pthread_join   pthread_join
#else
#define omc_pthread_create GC_pthread_create
#define omc_pthread_join   GC_pthread_join
#endif
#endif

#include "../openmodelica_types.h"

/* global roots size */
#define MMC_GC_GLOBAL_ROOTS_SIZE 1024

struct mmc_GC_state_type /* the structure of GC state */
{
  modelica_metatype       global_roots[MMC_GC_GLOBAL_ROOTS_SIZE]; /* the global roots ! */
};
typedef struct mmc_GC_state_type mmc_GC_state_type;
DLLDataDirection extern mmc_GC_state_type* mmc_GC_state;

/* tag the free reqion as a free object with 250 ctor*/
#define MMC_FREE_OBJECT_CTOR           200
#define MMC_TAG_AS_FREE_OBJECT(p, sz)  (((struct mmc_header*)p)->header = MMC_STRUCTHDR(sz, MMC_FREE_OBJECT_CTOR))

#if !defined(OMC_NO_GC_MAPPING)
static inline void mmc_GC_init(void)
{
  GC_init();
  GC_register_displacement(0);
#ifdef RML_STYLE_TAGPTR
  GC_register_displacement(3);
#endif
  GC_set_force_unmap_on_gcollect(1);
}

static inline void mmc_GC_init_default(void)
{
  mmc_GC_init();
}

#define mmc_GC_clear(void)
#define mmc_GC_collect(local_GC_state)

#if defined(OMC_RECORD_ALLOC_WORDS)
void mmc_record_alloc_words(size_t n);
void mmc_set_current_pos(const char *str);
#endif

static inline void* mmc_alloc_words_atomic(unsigned int nwords) {
#if defined(OMC_RECORD_ALLOC_WORDS)
  mmc_record_alloc_words((nwords) * sizeof(void*));
#endif
  GC_RETURN_REPORT_ALLOC_FAILED(GC_malloc_atomic((nwords) * sizeof(void*)));
}

static inline void* mmc_alloc_words(unsigned int nwords) {
#if defined(OMC_RECORD_ALLOC_WORDS)
  mmc_record_alloc_words((nwords) * sizeof(void*));
#endif
  GC_RETURN_REPORT_ALLOC_FAILED(GC_malloc((nwords) * sizeof(void*)));
}

/* for arrays only */
static inline void* mmc_alloc_words_atomic_ignore_off_page(unsigned int nwords) {
#if defined(OMC_RECORD_ALLOC_WORDS)
  mmc_record_alloc_words((nwords) * sizeof(void*));
#endif
  GC_RETURN_REPORT_ALLOC_FAILED(GC_malloc_atomic_ignore_off_page((nwords) * sizeof(void*)));
}

/* for arrays only */
static inline void* mmc_alloc_words_ignore_off_page(unsigned int nwords) {
#if defined(OMC_RECORD_ALLOC_WORDS)
  mmc_record_alloc_words((nwords) * sizeof(void*));
#endif
  GC_RETURN_REPORT_ALLOC_FAILED(GC_malloc_atomic_ignore_off_page((nwords) * sizeof(void*)));
}
#endif


#include "omc_rc.h"
#include "omc_alloc.h"


#if defined(__cplusplus)
}
#endif

#endif /* #define OMC_GC_H_ */
