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

#ifndef GENERIC_ARRAY_H_
#define GENERIC_ARRAY_H_

#include "base_array.h"

typedef void (*constructor_func)(threadData_t* td,  void* dst);
typedef void (*copy_func)(void* dst, void* src);

void generic_array_create_flexible(base_array_t* dst, int ndims);


void generic_array_create(threadData_t* td, base_array_t* dst, constructor_func ctor, int ndims, size_t sze, ...);
void simple_array_create(threadData_t* td, base_array_t* dst, int ndims, size_t sze, ...);

void generic_array_copy_data(const base_array_t src, base_array_t* dst, copy_func cper, size_t sze);
void simple_array_copy_data(const base_array_t src, base_array_t* dst, size_t sze);

#define real_array_copy_data(src,dst)               simple_array_copy_data(src, &dst, sizeof(modelica_real));
#define integer_array_copy_data(src,dst)            simple_array_copy_data(src, &dst, sizeof(modelica_integer));
#define string_array_copy_data(src,dst)             simple_array_copy_data(src, &dst, sizeof(modelica_string));
#define boolean_array_copy_data(src,dst)            simple_array_copy_data(src, &dst, sizeof(modelica_boolean));

void generic_array_alloc_copy(const base_array_t src, base_array_t* dst, copy_func cper, size_t sze);
void simple_array_alloc_copy(const base_array_t src, base_array_t* dst, size_t sze);

#define real_array_alloc_copy(src,dst)              simple_array_alloc_copy(src, &dst, sizeof(modelica_real));
#define integer_array_alloc_copy(src,dst)           simple_array_alloc_copy(src, &dst, sizeof(modelica_integer));
#define string_array_alloc_copy(src,dst)            simple_array_alloc_copy(src, &dst, sizeof(modelica_string));
#define boolean_array_alloc_copy(src,dst)           simple_array_alloc_copy(src, &dst, sizeof(modelica_boolean));


void* generic_array_get(const base_array_t* source, size_t sze,...);
// Versions with no variadic args for common dimensions 1 and 2
void* generic_array_get1(const base_array_t* source, size_t sze, int dim1);
void* generic_array_get2(const base_array_t* source, size_t sze, int dim1, int dim2);

#define real_array_get(src,ndims,...)               (*(modelica_real*)(generic_array_get(&src, sizeof(modelica_real), __VA_ARGS__)))
#define real_array_get1(src,ndims,dim1)             (*(modelica_real*)(generic_array_get1(&src, sizeof(modelica_real), dim1)))
#define real_array_get2(src,ndims,dim1,dim2)        (*(modelica_real*)(generic_array_get2(&src, sizeof(modelica_real), dim1, dim2)))

#define integer_array_get(src,ndims,...)            (*(modelica_integer*)(generic_array_get(&src, sizeof(modelica_integer), __VA_ARGS__)))
#define integer_array_get1(src,ndims,dim1)          (*(modelica_integer*)(generic_array_get1(&src, sizeof(modelica_integer), dim1)))
#define integer_array_get2(src,ndims,dim1,dim2)     (*(modelica_integer*)(generic_array_get2(&src, sizeof(modelica_integer), dim1, dim2)))

#define string_array_get(src,ndims,...)             (*(modelica_string*)(generic_array_get(&src, sizeof(modelica_string), __VA_ARGS__)))
#define string_array_get1(src,ndims,dim1)           (*(modelica_string*)(generic_array_get1(&src, sizeof(modelica_string), dim1)))
#define string_array_get2(src,ndims,dim1,dim2)      (*(modelica_string*)(generic_array_get2(&src, sizeof(modelica_string), dim1, dim2)))

#define boolean_array_get(src,ndims,...)            (*(modelica_boolean*)(generic_array_get(&src, sizeof(modelica_boolean), __VA_ARGS__)))
#define boolean_array_get1(src,ndims,dim1)          (*(modelica_boolean*)(generic_array_get1(&src, sizeof(modelica_boolean), dim1)))
#define boolean_array_get2(src,ndims,dim1,dim2)     (*(modelica_boolean*)(generic_array_get2(&src, sizeof(modelica_boolean), dim1, dim2)))


void generic_array_set(base_array_t* dst, void* val, copy_func cp_func, size_t sze, ...);




/// Get data functions. They return the raw data without the dim and size specifications.

#define data_of_real_array(arr)                     (modelica_real*) ((arr).data)
#define data_of_real_f77_array(arr)                 (modelica_real*) ((arr).data)
#define data_of_real_c89_array(arr)                 (modelica_real*) ((arr).data)

#define data_of_integer_array(arr)                  (int*) ((arr).data)
/// Integer arrays are packed to int when converted to fortran arrays
#define data_of_integer_f77_array(arr)              (int*) ((arr).data)
#define data_of_integer_c89_array(arr)              (int*) ((arr).data)

#define data_of_boolean_array(arr)                  (modelica_boolean*) ((arr).data)
#define data_of_boolean_f77_array(arr)              (modelica_boolean*) ((arr).data)
#define data_of_boolean_c89_array(arr)              (modelica_boolean*) ((arr).data)

#define data_of_string_array(arr)                  (modelica_string*) ((arr).data)
// This one needs some manual processing. It is implemented in string_array.c/h
// const char** data_of_string_c89_array(const string_array *a);




#endif
