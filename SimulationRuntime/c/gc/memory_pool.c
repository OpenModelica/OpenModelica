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

#include "../omc_simulation_settings.h"
#if defined(OMC_MINIMAL_RUNTIME) || defined(OMC_FMI_RUNTIME)
#define OMC_NO_GC_MAPPING
#endif
#include "omc_gc.h"
#include <string.h>
#if !defined(OMC_NO_THREADS)
#include <pthread.h>
#endif

#if defined(__cplusplus)
extern "C" {
#endif

static int GC_collect_a_little_or_not(void)
{
  return 0;
}

typedef struct list_s {
  void *memory;
  size_t used;
  size_t size;
  struct list_s *next;
} list;

#if !defined(OMC_NO_THREADS)
static pthread_mutex_t memory_pool_mutex = PTHREAD_MUTEX_INITIALIZER;
#endif
static list *memory_pools = NULL;

static void pool_init(void)
{
  memory_pools = (list*) malloc(sizeof(list));
  memory_pools->used = 0;
  memory_pools->size = 2*1024*1024; /* 2MB pool by default */
  memory_pools->memory = malloc(memory_pools->size);
  memory_pools->next = NULL;
}

static unsigned long upper_power_of_two(unsigned long v)
{
  v--;
  v |= v >> 1;
  v |= v >> 2;
  v |= v >> 4;
  v |= v >> 8;
  v |= v >> 16;
  v++;
  return v;
}

static inline size_t round_up(size_t num, size_t factor)
{
  return num + factor - 1 - (num - 1) % factor;
}

static inline void pool_expand(size_t len)
{
  list *newlist = NULL;
  if (0==memory_pools) {
    pool_init();
  }
  /* Check if we have enough memory already */
  if (memory_pools->size - memory_pools->used >= len) {
    return;
  }
  newlist = (list*) malloc(sizeof(list));
  newlist->next = memory_pools;
  memory_pools = newlist;
  memory_pools->used = 0;
  memory_pools->size = upper_power_of_two(3*memory_pools->next->size/2 + len); /* expand by 1.5x the old memory pool. More if we request a very large array. */
  memory_pools->memory = malloc(memory_pools->size);
}

static void* pool_malloc(size_t sz)
{
  void *res;
  sz = round_up(sz,8);
#if !defined(OMC_NO_THREADS)
  pthread_mutex_lock(&memory_pool_mutex);
#endif
  pool_expand(sz);
  res = (void*)((char*)memory_pools->memory + memory_pools->used);
  memory_pools->used += sz;
#if !defined(OMC_NO_THREADS)
  pthread_mutex_unlock(&memory_pool_mutex);
#endif
  memset(res,0,sz);
  return res;
}

static int pool_free(void)
{
  list *freelist = memory_pools->next;
  while (freelist) {
    list *next = freelist->next;
    free(freelist->memory);
    free(freelist);
    freelist = next;
  }
  memory_pools->used = 0;
  memory_pools->next = 0;
  return 0;
}

static void nofree(void* ptr)
{
}

static void* malloc_zero(size_t sz) {
  return calloc(1, sz);
}

omc_alloc_interface_t omc_alloc_interface_pooled = {
  pool_init,
  pool_malloc,
  pool_malloc,
  (char*(*)(size_t)) malloc,
  strdup,
  pool_free,
  malloc_zero,
  free,
  malloc,
  free
};

#if defined(OMC_RECORD_ALLOC_WORDS)
#include "gc/omc_gc.h"

static void* OMC_record_malloc(size_t sz)
{
  mmc_record_alloc_words(sz);
  return GC_malloc(sz);
}

static void* OMC_record_malloc_uncollectable(size_t sz)
{
  mmc_record_alloc_words(sz);
  return GC_malloc_uncollectable(sz);
}

static void* OMC_record_malloc_atomic(size_t sz)
{
  mmc_record_alloc_words(sz);
  return GC_malloc_atomic(sz);
}

static void* OMC_record_strdup(const char *str)
{
  mmc_record_alloc_words(strlen(str)+1);
  return GC_strdup(str);
}

#endif

omc_alloc_interface_t omc_alloc_interface = {
#if !defined(OMC_MINIMAL_RUNTIME)
#if !defined(OMC_RECORD_ALLOC_WORDS)
  GC_init,
  GC_malloc,
  GC_malloc_atomic,
  (char*(*)(size_t)) GC_malloc_atomic,
  GC_strdup,
  GC_collect_a_little_or_not,
  GC_malloc_uncollectable,
  GC_free,
  GC_malloc_atomic,
  nofree
#else
  GC_init,
  OMC_record_malloc,
  OMC_record_malloc_atomic,
  (char*(*)(size_t)) OMC_record_malloc_atomic,
  OMC_record_strdup,
  GC_collect_a_little_or_not,
  OMC_record_malloc_uncollectable,
  GC_free,
  OMC_record_malloc_atomic,
  nofree
#endif
#else
  pool_init,
  pool_malloc,
  pool_malloc,
  (char*(*)(size_t)) malloc,
  strdup,
  pool_free,
  malloc_zero /* calloc, but with malloc interface */,
  free,
  malloc,
  free
#endif
};

/* allocates n reals in the real_buffer */
m_real* real_alloc(int n)
{
  return (m_real*) omc_alloc_interface.malloc_atomic(n*sizeof(m_real));
}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int n)
{
  return (m_integer*) omc_alloc_interface.malloc_atomic(n*sizeof(m_integer));
}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int n)
{
  return (m_string*) omc_alloc_interface.malloc(n*sizeof(m_string));
}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int n)
{
  return (m_boolean*) omc_alloc_interface.malloc_atomic(n*sizeof(m_boolean));
}

_index_t* size_alloc(int n)
{
  return (_index_t*) omc_alloc_interface.malloc(n*sizeof(_index_t));
}

_index_t** index_alloc(int n)
{
  return (_index_t**) omc_alloc_interface.malloc(n*sizeof(_index_t*));
}

/* allocates n elements of size sze */
void* generic_alloc(int n, size_t sze)
{
  return (void*) omc_alloc_interface.malloc(n*sze);
}


#if defined(__cplusplus)
} /* end extern "C" */
#endif

