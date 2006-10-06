/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
