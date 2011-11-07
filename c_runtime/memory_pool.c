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

struct one_state_s {
  m_real real_buffer[NR_REAL_ELEMENTS];
  m_integer integer_buffer[NR_INTEGER_ELEMENTS];
  m_string string_buffer[NR_STRING_ELEMENTS];
  m_boolean boolean_buffer[NR_BOOLEAN_ELEMENTS];
  m_integer size_buffer[NR_SIZE_ELEMENTS];
  _index_t* index_buffer[NR_INDEX_ELEMENTS];
  char char_buffer[NR_CHAR_ELEMENTS];
  state current_state;
};

typedef struct one_state_s one_state;

one_state *current_states;

void* push_memory_states(int maxThreads)
{
  void *res = current_states;
  current_states = calloc(maxThreads,sizeof(one_state));
  return res;
}

void pop_memory_states(void* new_states)
{
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
  printf("real index: %d\n",(int)current_state.real_buffer_ptr);
  printf("integer index: %d\n",(int)current_state.integer_buffer_ptr);
  printf("string index: %d\n",(int)current_state.string_buffer_ptr);
  printf("boolean: %d\n",(int)current_state.boolean_buffer_ptr);
  printf("char: %d\n",(int)current_state.char_buffer_ptr);
}

void print_state(state s)
{
  printf("=== State ===\n");
  printf("real index: %d\n",(int)s.real_buffer_ptr);
  printf("integer index: %d\n",(int)s.integer_buffer_ptr);
  printf("string index: %d\n",(int)s.string_buffer_ptr);
  printf("boolean: %d\n",(int)s.boolean_buffer_ptr);
  printf("char: %d\n",(int)s.char_buffer_ptr);
}

void restore_memory_state(state restore_state)
{
  current_states[0].current_state = restore_state;
}

void clear_current_state()
{
  current_states[0].current_state.real_buffer_ptr = 0;
  current_states[0].current_state.integer_buffer_ptr = 0;
  current_states[0].current_state.string_buffer_ptr = 0;
  current_states[0].current_state.boolean_buffer_ptr = 0;
  current_states[0].current_state.char_buffer_ptr = 0;
}

/* allocates n reals in the real_buffer */
m_real* real_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_states[ix].current_state.real_buffer_ptr + n < NR_REAL_ELEMENTS);

  start = current_states[ix].current_state.real_buffer_ptr;
  current_states[ix].current_state.real_buffer_ptr += n;
  return current_states[ix].real_buffer+start;
  /*return start;*/
}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_states[ix].current_state.integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);

  start = current_states[ix].current_state.integer_buffer_ptr;
  current_states[ix].current_state.integer_buffer_ptr += n;

  return current_states[ix].integer_buffer+start;
  /*  return start;*/

}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_states[ix].current_state.string_buffer_ptr +n < NR_STRING_ELEMENTS);

  start = current_states[ix].current_state.string_buffer_ptr;
  current_states[ix].current_state.string_buffer_ptr += n;

  return current_states[ix].string_buffer+start;
  /*return start;*/

}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_states[ix].current_state.boolean_buffer_ptr +n < NR_BOOLEAN_ELEMENTS);

  start = current_states[ix].current_state.boolean_buffer_ptr;
  current_states[ix].current_state.boolean_buffer_ptr += n;

  return current_states[ix].boolean_buffer+start;
  /*  return start;*/

}

_index_t* size_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_states[ix].current_state.size_buffer_ptr < NR_SIZE_ELEMENTS);

  start = current_states[ix].current_state.size_buffer_ptr;
  current_states[ix].current_state.size_buffer_ptr += n;
  return current_states[ix].size_buffer+start;

  /*  return start;*/
}

_index_t** index_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_states[ix].current_state.index_buffer_ptr < NR_INDEX_ELEMENTS);

  start = current_states[ix].current_state.index_buffer_ptr;
  current_states[ix].current_state.index_buffer_ptr += n;
  return current_states[ix].index_buffer+start;

  /*  return start;*/
}

char* char_alloc(int ix, int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_states[ix].current_state.char_buffer_ptr < NR_CHAR_ELEMENTS);

  start = current_states[ix].current_state.char_buffer_ptr;
  current_states[ix].current_state.char_buffer_ptr += n;
  return current_states[ix].char_buffer+start;

  /*  return start;*/
}
