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

#include <limits.h>

#if defined(__cplusplus)
extern "C" {
#endif

#if defined(_LP64) /* linux 64bit*/

#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 8
#define MMC_LOG2_SIZE_INT 3
#define PRINT_MMC_SINT_T "ld"
#define PRINT_MMC_UINT_T "lu"
typedef unsigned long mmc_uint_t;
typedef long mmc_sint_t;
#define MODELICA_INT_MIN LONG_MIN;
#define MODELICA_INT_MAX LONG_MAX;

#elif defined(_LLP64) || defined(_WIN64) || defined(__MINGW64__) /* windows 64bit */

#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 8
#define MMC_LOG2_SIZE_INT 3
#ifndef PRIu64
#define PRIu64 "I64u"
#endif
#ifndef PRId64
#define PRId64 "I64d"
#endif
#define PRINT_MMC_SINT_T PRId64
#define PRINT_MMC_UINT_T PRIu64
typedef unsigned long long mmc_uint_t;
typedef long long mmc_sint_t;
#define MODELICA_INT_MIN LONG_MIN;
#define MODELICA_INT_MAX LONG_MAX;

#else /* 32bit platforms */

#define MMC_SIZE_DBL 8
#define MMC_SIZE_INT 4
#define MMC_LOG2_SIZE_INT 2
#define PRINT_MMC_SINT_T "d"
#define PRINT_MMC_UINT_T "u"
typedef unsigned int mmc_uint_t;
typedef int mmc_sint_t;
#define MODELICA_INT_MIN INT_MIN;
#define MODELICA_INT_MAX INT_MAX;

#endif

/* helpers for mmc_sint_t: printing / div */
#if defined(_WIN64) || defined(__MINGW64__)
#define modelica_div_integer lldiv
#define OMC_INT_FORMAT_LEFT_JUSTIFIED "%-*lld"
#define OMC_INT_FORMAT "%*lld"
#else
#define modelica_div_integer ldiv
#define OMC_INT_FORMAT_LEFT_JUSTIFIED "%-*ld"
#define OMC_INT_FORMAT "%*ld"
#endif

typedef void* modelica_complex; /* currently only External objects are represented using modelica_complex.*/
typedef void* modelica_metatype; /* MetaModelica extension, added by sjoelund */
/* MetaModelica extension.
We actually store function-pointers in lists, etc...
So it needs to be void*. If we use a platform with different sizes of function-
pointers, some changes need to be done to code generation */
typedef void* modelica_fnptr;

typedef double modelica_real;
typedef mmc_sint_t modelica_integer;
typedef signed char modelica_boolean;
/* When MetaModelica grammar is enabled, all strings are boxed */
typedef modelica_metatype modelica_string;
typedef mmc_sint_t         _index_t;

#ifndef FALSE
#define FALSE 0
#endif

#ifndef TRUE
#define TRUE 1
#endif


struct base_array_s
{
  int ndims;
  _index_t *dim_size;
  void *data;
  modelica_boolean flexible;
};
typedef struct base_array_s base_array_t;

typedef base_array_t boolean_array;
typedef base_array_t real_array;
typedef base_array_t integer_array;
typedef base_array_t string_array;


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




// This typedfes should be removed and their uses replaced by the corresponding data types.
typedef int integer;
typedef unsigned int uinteger;
typedef double doublereal;

#include "gc/omc_gc.h" /* for threadData_t */

#if defined(__cplusplus)
}
#endif

#endif
