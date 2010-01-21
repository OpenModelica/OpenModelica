/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#ifndef MEMORY_POOL_H_
#define MEMORY_POOL_H_

#include <stdlib.h>

#define NR_REAL_ELEMENTS 1000000
#define NR_INTEGER_ELEMENTS 1000000
#define NR_STRING_ELEMENTS 10000
#define NR_BOOLEAN_ELEMENTS 10000
#define NR_SIZE_ELEMENTS 1000000
#define NR_INDEX_ELEMENTS 10000
#define NR_CHAR_ELEMENTS 10000

typedef double m_real;
typedef int m_integer;
typedef const char* m_string;
typedef signed char m_boolean;
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
