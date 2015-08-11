/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

/* Typedefs and other things used all over the compiler, but does not pull in many other headers */

#ifndef OPENMODELICA_TYPES_H_
#define OPENMODELICA_TYPES_H_

#include <pthread.h>

#if defined(__cplusplus)
extern "C" {
#endif

#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int integer;
typedef unsigned int uinteger;
#else
typedef long int integer;
typedef unsigned long int uinteger;
#endif
typedef double doublereal;
#define maxmacro(X,Y) X > Y ? X : Y
#define minmacro(X,Y) X > Y ? Y : X

typedef void* modelica_complex; /* currently only External objects are represented using modelica_complex.*/
typedef void* modelica_metatype; /* MetaModelica extension, added by sjoelund */
/* MetaModelica extension.
We actually store function-pointers in lists, etc...
So it needs to be void*. If we use a platform with different sizes of function-
pointers, some changes need to be done to code generation */
typedef void* modelica_fnptr;

/* When MetaModelica grammar is enabled, all strings are boxed */
typedef modelica_metatype modelica_string;

typedef double            m_real;
typedef long              m_integer;
typedef modelica_metatype m_string;
typedef signed char       m_boolean;
typedef m_integer         _index_t;

/* This structure holds indexes when subscripting an array.
 * ndims - number of subscripts, E.g. A[1,{2,3},:] => ndims = 3
 * dim_size - dimension size of each subscript, Eg. A[1,{2,3},:,{3}] => dim_size={1,2,0,1}
 * spec_type - index type for each index, 'S' for scalar, 'A' for array, 'W' for whole dimension (:)
 *     Eg. A[1,{2,3},:,{3}] => spec_type = {'S','A','W','A'}.
 *     spec_type is required to be able to distinguish between {1} and 1 as an index.
 * index - pointer to all indices (except of type 'W'), eg A[1,{2,3},:,{3}] => index -> {1,2,3,3}
*/
struct index_spec_s
{
  _index_t ndims;  /* number of indices/subscripts */
  _index_t* dim_size; /* size for each subscript */
  char* index_type;  /* type of each subscript, any of 'S','A' or 'W' */
  _index_t** index; /* all indices*/
};
typedef struct index_spec_s index_spec_t;

struct base_array_s
{
  int ndims;
  _index_t *dim_size;
  void *data;
};

typedef struct base_array_s base_array_t;

typedef base_array_t string_array_t;

typedef signed char modelica_boolean;
typedef base_array_t boolean_array_t;

typedef double modelica_real;
typedef base_array_t real_array_t;

typedef m_integer modelica_integer;
typedef base_array_t integer_array_t;

typedef real_array_t real_array;
typedef integer_array_t integer_array;
typedef boolean_array_t boolean_array;
typedef string_array_t string_array;

/*
 * ERROR_STAGE defines different
 * stages where an assertion can be triggered.
 *
 */
typedef enum {
  ERROR_UNKOWN = 0,
  ERROR_SIMULATION,
  ERROR_INTEGRATOR,
  ERROR_NONLINEARSOLVER,
  ERROR_EVENTSEARCH,
  ERROR_EVENTHANDLING,
  ERROR_OPTIMIZE,
  ERROR_MAX
} errorStage;

#include <setjmp.h>
/* Thread-specific data passed around in most functions.
 * It is also possible to fetch it using pthread_getspecific (mostly for external functions that were not passed the pointer) */
enum {
  LOCAL_ROOT_USER_DEFINED_0,
  LOCAL_ROOT_USER_DEFINED_1,
  LOCAL_ROOT_USER_DEFINED_2,
  LOCAL_ROOT_USER_DEFINED_3,
  LOCAL_ROOT_USER_DEFINED_4,
  LOCAL_ROOT_USER_DEFINED_5,
  LOCAL_ROOT_USER_DEFINED_6,
  LOCAL_ROOT_USER_DEFINED_7,
  LOCAL_ROOT_USER_DEFINED_8,
  LOCAL_ROOT_ERROR_MO,
  LOCAL_ROOT_PRINT_MO,
  LOCAL_ROOT_SYSTEM_MO,
  LOCAL_ROOT_STACK_OVERFLOW,
  MAX_LOCAL_ROOTS
};
#define MAX_LOCAL_ROOTS 16
typedef void (*PlotCallback)(void*, int externalWindow, const char* filename, const char* title, const char* grid, const char* plotType, const char* logX,
    const char* logY, const char* xLabel, const char* yLabel, const char* x1, const char* x2, const char* y1, const char* y2,
    const char* curveWidth, const char* curveStyle, const char* legendPosition, const char* footer, const char* autoScale,
    const char* variables);
typedef struct threadData_s {
  jmp_buf *mmc_jumper;
  jmp_buf *mmc_stack_overflow_jumper;
  jmp_buf *mmc_thread_work_exit;
  void *localRoots[MAX_LOCAL_ROOTS];
/*
 * simulationJumpBufer:
 *  Jump-buffer to handle simulation error
 *  like asserts or divisions by zero.
 *
 * currentJumpStage:
 *   define which simulation jump buffer
 *   is currently used.
 */
  jmp_buf *globalJumpBuffer;
  jmp_buf *simulationJumpBuffer;
  errorStage currentErrorStage;
  struct threadData_s *parent;
  pthread_mutex_t parentMutex; /* Prevent children from all manipulating the parent at the same time */
  void *plotClassPointer;
  PlotCallback plotCB;
  void *stackBottom; /* Actually offset 64 kB from bottom, just to never reach the bottom */
} threadData_t;

#if defined(__cplusplus)
}
#endif

#endif
