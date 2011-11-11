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
#include "inline.h"
#include <assert.h>
#include <stdio.h>

/* 16 MB of data ought to be enough */
#define NR_ELEMENTS    4*1024*1024

struct one_state_s {
  int **buffer;
  int nbuffers;
  state current_state;
};

typedef struct one_state_s one_state;

one_state *current_states;

void* push_memory_states(int maxThreads)
{
  int i;
  void *res = current_states;
  current_states = malloc(maxThreads*sizeof(one_state));
  assert(current_states);
  for (i=0; i<maxThreads; i++) {
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
  free(current_states[0].buffer); /* TODO: Free all of them... */
  free(current_states);
  current_states = new_states;
}

state get_memory_state()
{
  return current_states[0].current_state;
}

void print_current_state()
{
  state current_state = current_states[0].current_state;
  printf("=== Current state ===\n");
  printf("  buffer: %d\n",(int)current_state.buffer);
  printf("  offste: %d\n",(int)current_state.offset);
}

void print_state(state s)
{
  printf("=== State ===\n");
  printf("  buffer: %d\n",(int)s.buffer);
  printf("  offste: %d\n",(int)s.offset);
}

void restore_memory_state(state restore_state)
{
  current_states[0].current_state = restore_state;
}

void clear_current_state()
{
  current_states[0].current_state.buffer = 0;
  current_states[0].current_state.offset = 0;
}

void* alloc_elements(int ix, int n, int sz)
{
  _index_t start,nelem;
  assert(n>=0);
  start = current_states[ix].current_state.offset;
  nelem = (n*sz)/sizeof(int) + ((n*sz)%sizeof(int) ? 1 : 0);
  assert(nelem <= NR_ELEMENTS);
  if (start + nelem > NR_ELEMENTS) {
    if (current_states[ix].nbuffers == current_states[ix].current_state.buffer+1) {
      /* We need to allocate another region */
      current_states[ix].buffer=realloc(current_states[ix].buffer,sizeof(int*)*current_states[ix].nbuffers);
      current_states[ix].buffer[current_states[ix].nbuffers]=malloc(sizeof(int)*NR_ELEMENTS);
      assert(current_states[ix].buffer);
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
m_real* real_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(m_real));
}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(m_integer));
}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(m_string));
}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(m_boolean));
}

_index_t* size_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(_index_t));
}

_index_t** index_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(_index_t*));
}

char* char_alloc(int ix, int n)
{
  return alloc_elements(ix,n,sizeof(char));
}
