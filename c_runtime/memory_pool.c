/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

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

real real_buffer[NR_REAL_ELEMENTS];
integer integer_buffer[NR_INTEGER_ELEMENTS];
string string_buffer[NR_STRING_ELEMENTS];
boolean boolean_buffer[NR_BOOLEAN_ELEMENTS];
integer size_buffer[NR_SIZE_ELEMENTS];
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
real* real_alloc(int n)
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
integer* integer_alloc(int n)
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
string* string_alloc(int n)
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
boolean* boolean_alloc(int n)
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
  assert(current_state.real_buffer_ptr-n>=0);
  
  current_state.real_buffer_ptr -= n;
  return current_state.real_buffer_ptr; 
}

_index_t integer_free(int n)
{
  assert(n>=0);
  assert(current_state.integer_buffer_ptr-n>=0);
  
  current_state.integer_buffer_ptr -= n;
  return current_state.integer_buffer_ptr; 
}

_index_t string_free(int n)
{
  assert(n>=0);
  assert(current_state.string_buffer_ptr-n>=0);
  
  current_state.string_buffer_ptr -= n;
  return current_state.string_buffer_ptr; 
}

_index_t boolean_free(int n)
{
  assert(n>=0);
  assert(current_state.boolean_buffer_ptr-n>=0);
  
  current_state.boolean_buffer_ptr -= n;
  return current_state.boolean_buffer_ptr; 
}

_index_t size_free(int n)
{
  assert(n>=0);
  assert(current_state.size_buffer_ptr-n>=0);
  
  current_state.size_buffer_ptr -= n;
  return current_state.size_buffer_ptr; 
}

_index_t index_free(int n)
{
  assert(n>=0);
  assert(current_state.index_buffer_ptr-n>=0);
  
  current_state.index_buffer_ptr -= n;
  return current_state.index_buffer_ptr; 
}

_index_t char_free(int n)
{
  assert(n>=0);
  assert(current_state.char_buffer_ptr-n>=0);
  
  current_state.char_buffer_ptr -= n;
  return current_state.char_buffer_ptr; 
}
