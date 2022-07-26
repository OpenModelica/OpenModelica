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

/*
 * Adrian Pop [Adrian.Pop@liu.se]
 * This file defines the MetaModelica garbage collector (GC) interface
 * We use Boehm GC mark-and-sweep collector.
 *
 *
 */

#ifndef OMC_GC_H_
#define OMC_GC_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdlib.h>
#if !defined(OMC_NO_THREADS)
#include <pthread.h>
#endif
#include <setjmp.h>

#if defined(_MSC_VER)
#include "omc_inline.h"
#include "util/omc_msvc.h"
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

extern omc_alloc_interface_t omc_alloc_interface;
extern omc_alloc_interface_t omc_alloc_interface_pooled;

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
#if !defined(OMC_NO_THREADS)
  pthread_mutex_t parentMutex; /* Prevent children from all manipulating the parent at the same time */
#endif
  void *plotClassPointer;
  PlotCallback plotCB;
  void *loadModelClassPointer;
  LoadModelCallback loadModelCB;
  int lastEquationSolved;
  void *stackBottom; /* Actually offset 64 kB from bottom, just to never reach the bottom */
} threadData_t;

typedef threadData_t OpenModelica_threadData_ThreadData;

#include "../meta/meta_modelica_segv.h"
void mmc_do_out_of_memory() __attribute__ ((noreturn));
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

#if (defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME))

#if !defined(OMC_NO_GC_MAPPING)
#define GC_init                           omc_alloc_interface_pooled.init
#define GC_malloc                         omc_alloc_interface_pooled.malloc
#define GC_malloc_atomic                  omc_alloc_interface_pooled.malloc_atomic
#define GC_strdup                         omc_alloc_interface_pooled.malloc_strdup
#define GC_collect_a_little_or_not        omc_alloc_interface_pooled.collect_a_little
#define GC_malloc_uncollectable           omc_alloc_interface_pooled.malloc_uncollectable
#define GC_free                           omc_alloc_interface_pooled.free_uncollectable
#define nofree                            omc_alloc_interface_pooled.free_string_persist
#define GC_malloc_atomic_ignore_off_page  omc_alloc_interface_pooled.malloc_atomic
#define GC_register_displacement          /* nothing */
#define GC_set_force_unmap_on_gcollect    /* nothing */
#define omc_GC_set_max_heap_size(X)       /* nothing */
#define omc_GC_get_max_heap_size()        0
#endif

#else /* #if (defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)) */

#include <gc.h>
// No need for this I think. If you define GC_THREADS (linux) or GC_WIN32_PTHREADS (on Win/MinGW) before
// including gc.h these will be picked up.
// Make sure to define GC_THREADS (linux) or GC_WIN32_PTHREADS (on Win/MinGW) on the makefiles or
// compiler command line so that everything is picked up consistently by all headers.

/* gc.h doesn't include this by default; and the actual header redirects dlopen, which does not have an implementation */
// #if !defined(OMC_NO_THREADS)
// int GC_pthread_create(pthread_t *,const pthread_attr_t *,void *(*)(void *), void *);
// int GC_pthread_join(pthread_t, void **);
// #endif

void omc_GC_set_max_heap_size(size_t);
size_t omc_GC_get_max_heap_size();

#endif /* #if (defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)) */

#include "../openmodelica_types.h"

/* global roots size */
#define MMC_GC_GLOBAL_ROOTS_SIZE 1024

struct mmc_GC_state_type /* the structure of GC state */
{
  modelica_metatype       global_roots[MMC_GC_GLOBAL_ROOTS_SIZE]; /* the global roots ! */
};
typedef struct mmc_GC_state_type mmc_GC_state_type;
extern mmc_GC_state_type* mmc_GC_state;

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


#include "memory_pool.h"


#if defined(__cplusplus)
}
#endif

#endif /* #define OMC_GC_H_ */
