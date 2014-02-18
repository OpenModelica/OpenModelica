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

/*! \file openmodelica.h
 * Description: This is the C header file for the C code generated from
 * Modelica. It includes e.g. the C object representation of the builtin types
 * and arrays, etc.
 */

#ifndef OPENMODELICA_H_
#define OPENMODELICA_H_

#if defined(__cplusplus)
extern "C" {
#endif

#include <stdlib.h>
#include <stdio.h>
#include <limits.h>
#include <assert.h>
#include <float.h>
#include <setjmp.h>

/* adrpo: extreme windows crap! */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define DLLImport   __declspec( dllimport )
#define DLLExport   __declspec( dllexport )
#else
#define DLLImport extern
#define DLLExport /* nothing */
#endif

#if defined(IMPORT_INTO)
#define DLLDirection DLLImport
#else /* we export from the dll */
#define DLLDirection DLLExport
#endif

typedef void* modelica_complex; /* currently only External objects are represented using modelica_complex.*/
typedef void* modelica_metatype; /* MetaModelica extension, added by sjoelund */
/* MetaModelica extension.
We actually store function-pointers in lists, etc...
So it needs to be void*. If we use a platform with different sizes of function-
pointers, some changes need to be done to code generation */
typedef void* modelica_fnptr;

#if defined(__MINGW32__) || defined(_MSC_VER)
 #define WIN32_LEAN_AND_MEAN
#if !defined(NOMINMAX)
 #define NOMINMAX
#endif
#endif

/* BEFORE: compat.h */
#if defined(__MINGW32__) || defined(_MSC_VER)
#define EXIT(code) exit(code)
#else
/* We need to patch exit() on Unix systems
 * It does not change the exit code of simulations for some reason! */
#include <unistd.h>
#define EXIT(code) {fflush(NULL); _exit(code);}
#endif

#include "omc_inline.h"


/* BEFORE: modelica_string.h */
#ifdef __OPENMODELICA__METAMODELICA
/* When MetaModelica grammar is enabled, all strings are boxed */
typedef modelica_metatype modelica_string_t;
typedef const modelica_metatype modelica_string_const;
typedef modelica_string_t modelica_string;
#else
typedef char* modelica_string_t;
typedef const char* modelica_string_const;
typedef modelica_string_const modelica_string;
#endif


/* BEFORE: #include "memory_pool.h" */
typedef double      m_real;
typedef long        m_integer;
typedef const char* m_string;
typedef signed char m_boolean;
typedef m_integer   _index_t;

/* BEFORE: #include "index_spec.h" */
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


/* BEFORE: #include "base_array.h" */
struct base_array_s
{
  int ndims;
  _index_t *dim_size;
  void *data;
};

typedef struct base_array_s base_array_t;


/* BEFORE: #include "string_array.h" */
typedef base_array_t string_array_t;

/* BEFORE: #include "boolean_array.h" */
typedef signed char modelica_boolean;
typedef base_array_t boolean_array_t;


/* BEFORE: #include "real_array.h" */
typedef double modelica_real;
typedef base_array_t real_array_t;

/* BEFORE: #include "integer_array.h" */
typedef m_integer modelica_integer;
typedef base_array_t integer_array_t;


/* BEFORE: #include "modelica.h" */
typedef real_array_t real_array;
typedef integer_array_t integer_array;
typedef boolean_array_t boolean_array;
typedef string_array_t string_array;


/* BEFORE: fortran_types */
#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int fortran_integer;
typedef unsigned int fortran_uinteger;
#else
typedef long int fortran_integer;
typedef unsigned long int fortran_uinteger;
#endif


/* BEFORE: read_write */
typedef struct type_desc_s type_description;

enum type_desc_e {
  TYPE_DESC_NONE,
  TYPE_DESC_REAL,
  TYPE_DESC_REAL_ARRAY,
  TYPE_DESC_INT,
  TYPE_DESC_INT_ARRAY,
  TYPE_DESC_BOOL,
  TYPE_DESC_BOOL_ARRAY,
  TYPE_DESC_STRING,
  TYPE_DESC_STRING_ARRAY,
  TYPE_DESC_TUPLE,
  TYPE_DESC_COMPLEX,
  TYPE_DESC_RECORD,
  /* function pointer - added by stefan */
  TYPE_DESC_FUNCTION,
  TYPE_DESC_MMC,
  TYPE_DESC_NORETCALL
};

struct type_desc_s {
  enum type_desc_e type;
  int retval : 1;
  union _data {
    modelica_real real;
    real_array_t real_array;
    modelica_integer integer;
    integer_array_t int_array;
    modelica_boolean boolean;
    boolean_array_t bool_array;
    modelica_string_const string;
    string_array_t string_array;
    struct _tuple {
      size_t elements;
      struct type_desc_s *element;
    } tuple;
    modelica_complex complex;
    struct _record {
      const char *record_name;
      size_t elements;
      char **name;
      struct type_desc_s *element;
    } record;
    /* function pointer - stefan */
    modelica_fnptr function;
    void* mmc;
  } data;
};

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
  MAX_LOCAL_ROOTS
};
#define MAX_LOCAL_ROOTS 16
typedef struct threadData_s {
  jmp_buf *mmc_jumper;
  jmp_buf *mmc_stack_overflow_jumper;
  jmp_buf *mmc_thread_work_exit;
  void *localRoots[MAX_LOCAL_ROOTS];
} threadData_t;


/*
 * ERROR_STAGE defines different
 * stages where an assertion can be triggered.
 *
 */
typedef enum
{
  ERROR_UNKOWN = 0,
  ERROR_SIMULATION,
  ERROR_INTEGRATOR,
  ERROR_NONLINEARSOLVER,
  ERROR_EVENTSEARCH,
  ERROR_OPTIMIZE,

  ERROR_MAX
} ERROR_STAGE;

/* ERROR_HANDLE
 *
 * Used to handle errors via setjmp and longjmp.
 *
 * simulationJumpBufer:
 *  Jump-buffer to handle simulation error
 *  like asserts or divisions by zero.
 *
 * currentJumpStage:
 *   define which simulation jump buffer
 *   is currently used.
 */
typedef struct ERROR_HANDLE
{
  jmp_buf globalJumpBuffer;
  jmp_buf simulationJumpBuffer;
  int currentErrorStage;
} ERROR_HANDLE;

/* math functions (-lm)*/

/* Special Modelica builtin functions*/
#define smooth(P,EXP)    (EXP)
#define semiLinear(x,positiveSlope,negativeSlope) (x>=0?positiveSlope*x:negativeSlope*x)

/* sign function */
#define sign(v) (v>0?1:(v<0?-1:0))

#if defined(_MSC_VER)
#define fmax(x, y) ((x>y)?x:y)
#define fmin(x, y) ((x<y)?x:y)
#define snprintf sprintf_s
#define trunc(a) ((double)((int)(a)))
#endif

/* initial and terminal function calls */
#define initial() data->simulationInfo.initial
#define terminal() data->simulationInfo.terminal

#define homotopy(actual, simplified) (actual)
#define homotopyParameter() data->simulationInfo.lambda

typedef struct {
  void (*init)(void);
  void* (*malloc)(size_t);
  void* (*malloc_atomic)(size_t);
  char* (*malloc_string)(size_t);
  char* (*malloc_strdup)(const char*);
  int (*collect_a_little)(void);
} omc_alloc_interface_t;

extern omc_alloc_interface_t omc_alloc_interface;
extern omc_alloc_interface_t omc_alloc_interface_pooled;
typedef threadData_t* OpenModelica_threadData_ThreadData;

/* g++ does not allow putting attributes next to labels
 * clang++ does allow it however...
 */
#if defined(__cplusplus) && defined(__GNUC__)
#define OMC_LABEL_UNUSED
#else
#define OMC_LABEL_UNUSED __attribute__((unused))
#endif

#if defined(__cplusplus)
} /* end extern "C" */
#endif

#endif
