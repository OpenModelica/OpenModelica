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


#ifndef MEMORY_POOL_H_
#define MEMORY_POOL_H_

#define NR_REAL_ELEMENTS 10000
#define NR_INTEGER_ELEMENTS 10000
#define NR_STRING_ELEMENTS 10000
#define NR_BOOLEAN_ELEMENTS 10000
#define NR_SIZE_ELEMENTS 10000
#define NR_INDEX_ELEMENTS 10000

typedef double real;
typedef int integer;
typedef const char* string;
typedef int boolean;
typedef int _index_t; 

extern real real_buffer[NR_REAL_ELEMENTS];
extern integer integer_buffer[NR_INTEGER_ELEMENTS];
extern string string_buffer[NR_STRING_ELEMENTS];
extern boolean boolean_buffer[NR_BOOLEAN_ELEMENTS];
extern integer size_buffer[NR_SIZE_ELEMENTS];
extern int* index_buffer[NR_INDEX_ELEMENTS];

struct state_s {
  _index_t real_buffer_ptr;
  _index_t integer_buffer_ptr;
  _index_t string_buffer_ptr;
  _index_t boolean_buffer_ptr;
  _index_t size_buffer_ptr;
  _index_t index_buffer_ptr;
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
real* real_alloc(int n);
integer* integer_alloc(int n);
string* string_alloc(int n);
boolean* boolean_alloc(int n);
int* size_alloc(int n);
int** index_alloc(int n);

_index_t real_free(int n);
_index_t integer_free(int n);
_index_t string_free(int n);
_index_t boolean_free(int n);
_index_t size_free(int n);
_index_t index_free(int n);
#endif
