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


#include "memory_pool.h"
#include <assert.h>
#include <stdio.h>

/* 16 MB of data ought to be enough */
#define NR_ELEMENTS    (4*1024*1024)

static one_state *current_states = NULL;

int get_thread_index_default(void)
{
  return 0;
}
int (*get_thread_index)(void) = get_thread_index_default;

void* push_memory_states(int maxThreads)
{
  int i;
  void *res = current_states;
  current_states = malloc(maxThreads*sizeof(one_state));
  assert(current_states);
  for(i=0; i<maxThreads; i++) {
    current_states[i].buffer = (int**) malloc(sizeof(int*));
    current_states[i].buffer[0] = malloc(sizeof(int)*NR_ELEMENTS);
    current_states[i].nbuffers = 1;
    current_states[i].current_state.buffer = 0;
    current_states[i].current_state.offset = 0;
  }
  return res;
}

void pop_memory_states(void* new_states)
{
  if(current_states != NULL)
  {
    free(current_states[0].buffer[0]); /* TODO: Free all of them... */
    free(current_states[0].buffer);
    free(current_states);
  }
  current_states = new_states;
}

state get_memory_state(void)
{
  if (current_states == NULL) {
    push_memory_states(1);
  }
  return current_states[get_thread_index()].current_state;
}

void print_current_state(void)
{
  state current_state = current_states[0].current_state;
  printf("=== Current state ===\n");
  printf("  buffer: %d\n",(int)current_state.buffer);
  printf("  offset: %d\n",(int)current_state.offset);
}

void print_state(state s)
{
  printf("=== State ===\n");
  printf("  buffer: %d\n",(int)s.buffer);
  printf("  offset: %d\n",(int)s.offset);
}

void restore_memory_state(state restore_state)
{
  assert(restore_state.buffer == 0);
  current_states[get_thread_index()].current_state = restore_state;
}

void clear_current_state(void)
{
  int ix = get_thread_index();
  current_states[ix].current_state.buffer = 0;
  current_states[ix].current_state.offset = 0;
}

void* alloc_elements(int n, int sz)
{
  _index_t start,nelem;
  int ix = get_thread_index();
  assert(n>=0);
  start = current_states[ix].current_state.offset;
  nelem = (((n * sz)+(sizeof(int)-1))/sizeof(int));
  assert(nelem <= NR_ELEMENTS);
  if((start + nelem) > NR_ELEMENTS) {
    if(current_states[ix].nbuffers == (current_states[ix].current_state.buffer + 1)) {
      /* We need to allocate another region */
      current_states[ix].buffer=realloc(current_states[ix].buffer,sizeof(int*)*current_states[ix].nbuffers);
      assert(current_states[ix].buffer);
      current_states[ix].buffer[current_states[ix].nbuffers]=malloc(sizeof(int)*NR_ELEMENTS);
      assert(current_states[ix].buffer[current_states[ix].nbuffers]);
    }
    current_states[ix].current_state.buffer = current_states[ix].nbuffers++;
    current_states[ix].current_state.offset = 0;
    start = 0;
    /* fprintf(stderr,"realloc %d %d %d\n", current_states[ix].nbuffers, current_states[ix].current_state.buffer, current_states[ix].current_state.offset); */
  }
  current_states[ix].current_state.offset += nelem;
  /* fprintf(stderr,"return data buffer:%d offset:%d\n", current_states[ix].current_state.buffer, start); */
  return current_states[ix].buffer[current_states[ix].current_state.buffer] + start;
}

/* allocates n reals in the real_buffer */
m_real* real_alloc(int n)
{
  return alloc_elements(n,sizeof(m_real));
}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int n)
{
  return alloc_elements(n,sizeof(m_integer));
}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int n)
{
  return alloc_elements(n,sizeof(m_string));
}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int n)
{
  return alloc_elements(n,sizeof(m_boolean));
}

_index_t* size_alloc(int n)
{
  return alloc_elements(n,sizeof(_index_t));
}

_index_t** index_alloc(int n)
{
  return alloc_elements(n,sizeof(_index_t*));
}

/* allocates n elements of size sze */
void* generic_alloc(int n, size_t sze)
{
  return alloc_elements(n,sze);
}
