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

state current_state = {
  0,/*real buffer*/
  0,/*integer buffer*/
  0,/*string buffer*/
  0,/*boolean buffer*/
  0,/* size buffer */
  0,/* index buffer */
  0 /* char buffer */
};

m_real real_buffer[NR_REAL_ELEMENTS];
m_integer integer_buffer[NR_INTEGER_ELEMENTS];
m_string string_buffer[NR_STRING_ELEMENTS];
m_boolean boolean_buffer[NR_BOOLEAN_ELEMENTS];
m_integer size_buffer[NR_SIZE_ELEMENTS];
int* index_buffer[NR_INDEX_ELEMENTS];
char char_buffer[NR_CHAR_ELEMENTS];


state get_memory_state()
{
  return current_state;
}

void print_current_state()
{
  printf("=== Current state ===\n");
  printf("real index: %d\n",current_state.real_buffer_ptr);
  printf("integer index: %d\n",current_state.integer_buffer_ptr);
  printf("string index: %d\n",current_state.string_buffer_ptr);
  printf("boolean: %d\n",current_state.boolean_buffer_ptr);
  printf("char: %d\n",current_state.char_buffer_ptr);
}

void print_state(state s)
{
  printf("=== State ===\n");
  printf("real index: %d\n",s.real_buffer_ptr);
  printf("integer index: %d\n",s.integer_buffer_ptr);
  printf("string index: %d\n",s.string_buffer_ptr);
  printf("boolean: %d\n",s.boolean_buffer_ptr);
  printf("char: %d\n",s.char_buffer_ptr);
}

void restore_memory_state(state restore_state)
{
  current_state = restore_state;
}

void clear_current_state()
{
  current_state.real_buffer_ptr = 0;
  current_state.integer_buffer_ptr = 0;
  current_state.string_buffer_ptr = 0;
  current_state.boolean_buffer_ptr = 0;
  current_state.char_buffer_ptr = 0;
}

/* allocates n reals in the real_buffer */
m_real* real_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_state.real_buffer_ptr +n < NR_REAL_ELEMENTS);

  start = current_state.real_buffer_ptr;
  current_state.real_buffer_ptr += n;
  return real_buffer+start;
  /*return start;*/

}

/* allocates n integers in the integer_buffer */
m_integer* integer_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_state.integer_buffer_ptr +n < NR_INTEGER_ELEMENTS);

  start = current_state.integer_buffer_ptr;
  current_state.integer_buffer_ptr += n;

  return integer_buffer+start;
  /*  return start;*/

}

/* allocates n strings in the string_buffer */
m_string* string_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_state.string_buffer_ptr +n < NR_STRING_ELEMENTS);

  start = current_state.string_buffer_ptr;
  current_state.string_buffer_ptr += n;

  return string_buffer+start;
  /*return start;*/

}

/* allocates n booleans in the boolean_buffer */
m_boolean* boolean_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(current_state.boolean_buffer_ptr +n < NR_BOOLEAN_ELEMENTS);

  start = current_state.boolean_buffer_ptr;
  current_state.boolean_buffer_ptr += n;

  return boolean_buffer+start;
  /*  return start;*/

}

int* size_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_state.size_buffer_ptr < NR_SIZE_ELEMENTS);

  start = current_state.size_buffer_ptr;
  current_state.size_buffer_ptr += n;
  return size_buffer+start;

  /*  return start;*/
}

int** index_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_state.index_buffer_ptr < NR_SIZE_ELEMENTS);

  start = current_state.index_buffer_ptr;
  current_state.index_buffer_ptr += n;
  return index_buffer+start;

  /*  return start;*/
}

char* char_alloc(int n)
{
  _index_t start;

  assert(n>=0);
  assert(n + current_state.char_buffer_ptr < NR_CHAR_ELEMENTS);

  start = current_state.char_buffer_ptr;
  current_state.char_buffer_ptr += n;
  return char_buffer+start;

  /*  return start;*/
}

_index_t real_free(int n)
{
  assert(n>=0);
  assert(current_state.real_buffer_ptr>=n);

  current_state.real_buffer_ptr -= n;
  return current_state.real_buffer_ptr;
}

_index_t integer_free(int n)
{
  assert(n>=0);
  assert(current_state.integer_buffer_ptr>=n);

  current_state.integer_buffer_ptr -= n;
  return current_state.integer_buffer_ptr;
}

_index_t string_free(int n)
{
  assert(n>=0);
  assert(current_state.string_buffer_ptr>=n);

  current_state.string_buffer_ptr -= n;
  return current_state.string_buffer_ptr;
}

_index_t boolean_free(int n)
{
  assert(n>=0);
  assert(current_state.boolean_buffer_ptr>=n);

  current_state.boolean_buffer_ptr -= n;
  return current_state.boolean_buffer_ptr;
}

_index_t size_free(int n)
{
  assert(n>=0);
  assert(current_state.size_buffer_ptr>=n);

  current_state.size_buffer_ptr -= n;
  return current_state.size_buffer_ptr;
}

_index_t index_free(int n)
{
  assert(n>=0);
  assert(current_state.index_buffer_ptr>=n);

  current_state.index_buffer_ptr -= n;
  return current_state.index_buffer_ptr;
}

_index_t char_free(int n)
{
  assert(n>=0);
  assert(current_state.char_buffer_ptr>=n);

  current_state.char_buffer_ptr -= n;
  return current_state.char_buffer_ptr;
}
