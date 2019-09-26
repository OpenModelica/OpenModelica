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

#define real_array_get(src,ndims,...)               (*(modelica_real*)(real_array_element_addr(&src, ndims, __VA_ARGS__)))
#define integer_array_get(src,ndims,...)            (*(modelica_integer*)(integer_array_element_addr(&src, ndims, __VA_ARGS__)))
#define string_array_get(src,ndims,...)             (*(modelica_string*)(string_array_element_addr(&src, ndims, __VA_ARGS__)))
#define boolean_array_get(src,ndims,...)            (*(modelica_boolean*)(boolean_array_element_addr(&src, ndims, __VA_ARGS__)))

void generic_array_set(base_array_t* dst, void* val, copy_func cp_func, size_t sze, ...);




void* generic_array_element_addr(const base_array_t* source, size_t sze, int ndims,...);
void* generic_array_element_addr1(const base_array_t* source, size_t sze, int dim1);


#endif
