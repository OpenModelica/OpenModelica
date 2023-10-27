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
#if defined(OM_HAVE_PTHREADS)
#include <pthread.h>
#endif
#include "../util/omc_error.h"

#if defined(__cplusplus)
extern "C" {
#endif

#define OMC_MEGABYTE 1024*1024
/// 2MB pool by default
#define OMC_INITIAL_BLOCK_SIZE 2*OMC_MEGABYTE
/// Error out at a 1GB block request. Something is clearly not going
/// as intended. If we continue we will most probably overflow at the
/// 4GB mark anyway so catch it and report it.
#define OMC_ERROR_AT_EXPAND_REQUEST 1024*OMC_MEGABYTE


/// This is the pointer to the current block of memory. The 'memory pool'.
/// It changes when the program requests memory space that does not fit
/// in the current block. In which case a new block will be created and
/// this will be updated. Restoring a saved state (a cleanup operation)
/// will also update this.
OMCMemPoolBlock *memory_pools = NULL;

#if defined(OM_HAVE_PTHREADS)
static pthread_mutex_t memory_pool_mutex = PTHREAD_MUTEX_INITIALIZER;
#endif

static int GC_collect_a_little_or_not(void)
{
  return 0;
}

static void pool_init(void)
{
  memory_pools = (OMCMemPoolBlock*) omc_alloc_interface.malloc_uncollectable(sizeof(OMCMemPoolBlock));
  memory_pools->used = 0;
  memory_pools->size = OMC_INITIAL_BLOCK_SIZE;
  memory_pools->memory = omc_alloc_interface.malloc_uncollectable(memory_pools->size);
  memory_pools->previous = NULL;
}

static inline size_t round_up(size_t num, size_t factor)
{
  return num + factor - 1 - ((num + factor - 1) % factor);
}

static inline void pool_expand(size_t len)
{
  OMCMemPoolBlock *newBlock = NULL;

  // The new block will be 1.5x the current block's size. More if we request a very large array.
  size_t new_size = 3*memory_pools->size / 2;
  // Align the new size to the initial block size (2MB right now) for easier debugging.
  new_size = round_up(new_size, OMC_INITIAL_BLOCK_SIZE);

  // Report an error if the size is too big. This will error out before the size request is
  // able to overflow the the size_t size (at 4GB)
  if (new_size >= OMC_ERROR_AT_EXPAND_REQUEST) {
    omc_assert_macro(0 && "Attempt to allocate an unusually large memory. The memory management does not seem to be working as intended. Please create an issue on https://github.com/OpenModelica/OpenModelica/issues.");
  }

  newBlock = (OMCMemPoolBlock*) omc_alloc_interface.malloc_uncollectable(sizeof(OMCMemPoolBlock));
  newBlock->used = 0;
  newBlock->size = new_size;
  newBlock->memory = omc_alloc_interface.malloc_uncollectable(newBlock->size);
  newBlock->previous = memory_pools;
  memory_pools = newBlock;
}

static void* pool_malloc(size_t requested_size)
{
  void *res;
  requested_size = round_up(requested_size, 8);

#if defined(OM_HAVE_PTHREADS)
  pthread_mutex_lock(&memory_pool_mutex);
#endif

  /// If we forgot to explicitly initialize the pool, initialize it now.
  if (!memory_pools) {
    pool_init();
  }

  /// If the current block does not have enough remaining space, expand the pool
  /// by creating another block. The new block should, at least, be as big as
  /// the requested size. Note that, this will update the global memory_pools pointer.
  if (memory_pools->size - memory_pools->used < requested_size) {
    pool_expand(requested_size);
  }

  res = (void*)((char*)memory_pools->memory + memory_pools->used);
  memory_pools->used += requested_size;

#if defined(OM_HAVE_PTHREADS)
  pthread_mutex_unlock(&memory_pool_mutex);
#endif

  memset(res, 0, requested_size);
  return res;
}

static int pool_collect_a_little()
{
  return 0;
}

static void print_mem_pool(OMCMemPoolBlock* chunk) {
  printf("----------------------------\n");
  printf("%p, %ld, %ld, %p\n", chunk->memory, chunk->used, chunk->size, chunk->previous);
  printf("----------------------------\n");
}

MemPoolState omc_util_get_pool_state() {
  MemPoolState state;
  /// If we forgot to explicitly initialize the pool, initialize it now.
  if (!memory_pools) {
    pool_init();
  }

  state.block = memory_pools;
  state.used = memory_pools->used;

  return state;
}

void omc_util_restore_pool_state(MemPoolState in_state) {
  // printf("original state:\n");
  // print_mem_pool(memory_pools);

  assert(in_state.block);

  OMCMemPoolBlock* currentBlock = memory_pools;
  /// Start from the current block and traverse the chain until we find the block
  /// that was saved in the state.
  /// Clean up the blocks as we go since they will no longer be reachable after updating
  /// to the saved state.
  while (currentBlock != in_state.block) {
    OMCMemPoolBlock* previous = currentBlock->previous;
    omc_alloc_interface.free_uncollectable(currentBlock->memory);
    currentBlock->memory = NULL;
    currentBlock->previous = NULL;
    currentBlock->size = 0;
    currentBlock->used = 0;
    omc_alloc_interface.free_uncollectable(currentBlock);
    currentBlock = previous;
  }
  assert(currentBlock);

  currentBlock->used = in_state.used;
  memory_pools = currentBlock;

  // printf("updated state:\n");
  // print_mem_pool(memory_pools);
}

void free_memory_pool()
{
  OMCMemPoolBlock* currentBlock = memory_pools;

  while (currentBlock) {
    OMCMemPoolBlock* previous = currentBlock->previous;
    omc_alloc_interface.free_uncollectable(currentBlock->memory);
    currentBlock->memory = NULL;
    currentBlock->previous = NULL;
    currentBlock->size = 0;
    currentBlock->used = 0;
    omc_alloc_interface.free_uncollectable(currentBlock);
    currentBlock = previous;
  }

  memory_pools = NULL;
}

static void nofree(void* ptr)
{
}

static void* malloc_zero(size_t sz) {
  // Our runtime system sometimes asks for 0 size allocation.
  // Maybe we should forbid that to avoid masking issues like
  // zero caused by overflow. See #7611.
  if(sz == 0)
    return NULL;

  void* addr = calloc(1, sz);

  if(!addr)
    throwStreamPrint(NULL, "memory_pool.c: Error: Failed to allocate memory (calloc returned NULL.)");

  return addr;
}

omc_alloc_interface_t omc_alloc_interface_pooled = {
  pool_init,
  pool_malloc,
  pool_malloc,
  (char*(*)(size_t)) malloc,
  strdup,
  pool_collect_a_little, /* No OP. Does not do anything. The pool requires explicit state save and restore. */
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
  pool_collect_a_little, /* No OP. Does not do anything. The pool requires explicit state save and restore. */
  malloc_zero /* calloc, but with malloc interface */,
  free,
  malloc,
  free
#endif
};

/* allocates n reals in the real_buffer */
modelica_real* real_alloc(int n)
{
  return (modelica_real*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_real));
}

/* allocates n integers in the integer_buffer */
modelica_integer* integer_alloc(int n)
{
  return (modelica_integer*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_integer));
}

/* allocates n strings in the string_buffer */
modelica_string* string_alloc(int n)
{
  return (modelica_string*) omc_alloc_interface.malloc(n*sizeof(modelica_string));
}

/* allocates n booleans in the boolean_buffer */
modelica_boolean* boolean_alloc(int n)
{
  return (modelica_boolean*) omc_alloc_interface.malloc_atomic(n*sizeof(modelica_boolean));
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
