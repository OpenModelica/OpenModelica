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

#ifndef MEMORY_POOL_H_
#define MEMORY_POOL_H_

#define NR_REAL_ELEMENTS 10000
#define NR_INTEGER_ELEMENTS 10000
#define NR_STRING_ELEMENTS 10000
#define NR_BOOLEAN_ELEMENTS 10000
#define NR_SIZE_ELEMENTS 10000
#define NR_INDEX_ELEMENTS 10000
#define NR_CHAR_ELEMENTS 10000

typedef double m_real;
typedef int m_integer;
typedef const char* m_string;
typedef double m_boolean;
typedef int _index_t; 

extern m_real real_buffer[NR_REAL_ELEMENTS];
extern m_integer integer_buffer[NR_INTEGER_ELEMENTS];
extern m_string string_buffer[NR_STRING_ELEMENTS];
extern m_boolean boolean_buffer[NR_BOOLEAN_ELEMENTS];
extern m_integer size_buffer[NR_SIZE_ELEMENTS];
extern int* index_buffer[NR_INDEX_ELEMENTS];
extern char char_buffer[NR_CHAR_ELEMENTS];

struct state_s {
  _index_t real_buffer_ptr;
  _index_t integer_buffer_ptr;
  _index_t string_buffer_ptr;
  _index_t boolean_buffer_ptr;
  _index_t size_buffer_ptr;
  _index_t index_buffer_ptr;
  _index_t char_buffer_ptr;
};

typedef struct state_s state;

state get_memory_state();
void restore_memory_state(state restore_state);
void clear_memory_state();

/*Help functions*/
void print_current_state();

/*state start_state;*/
/*state current_state;*/
/*size_mem current_size;*/

/* Allocation functions */
m_real* real_alloc(int n);
m_integer* integer_alloc(int n);
m_string* string_alloc(int n);
m_boolean* boolean_alloc(int n);
int* size_alloc(int n);
int** index_alloc(int n);
char* char_alloc(int n);

_index_t real_free(int n);
_index_t integer_free(int n);
_index_t string_free(int n);
_index_t boolean_free(int n);
_index_t size_free(int n);
_index_t index_free(int n);
_index_t char_free(int n);
#endif
