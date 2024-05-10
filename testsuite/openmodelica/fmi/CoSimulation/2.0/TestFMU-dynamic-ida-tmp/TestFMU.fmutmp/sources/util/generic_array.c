/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
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

#include <string.h>
#include <stdint.h>

#include "generic_array.h"
#include "omc_error.h"

static void* generic_ptrget(const base_array_t *a, size_t sze, size_t i) {
  return ((char*)a->data) + (i*sze);
}

static int generic_array_ndims_eq(const base_array_t* src, const base_array_t* dst) {
    if(src->ndims != dst->ndims) {
        fprintf(stderr, "src->ndims != dst->ndims, %d != %d\n", src->ndims, dst->ndims);
        return 0;
    }
    return 1;
}

#define omc_FORMAT "src->dim_size[%d] != dst->dim_size[%d], %" PRINT_MMC_SINT_T " != %" PRINT_MMC_SINT_T "\n"

static int generic_array_dimsizes_eq(const base_array_t* src, const base_array_t* dst, int print_error)
{
    int i;
    for(i = 0; i < src->ndims; ++i) {
        if(src->dim_size[i] != dst->dim_size[i]) {
            if (print_error) {
                fprintf(stderr, omc_FORMAT,
                        i, i, src->dim_size[i], dst->dim_size[i]);
            }
            return 0;
        }
    }

    return 1;
}


static size_t check_copy_sanity(const base_array_t* src, base_array_t* dst, size_t sze) {
    size_t i;
    // TODO wrap me in debug. No need to do this in release.
    omc_assert_macro(base_array_ok(src));
    omc_assert_macro(generic_array_ndims_eq(src, dst));

    size_t nr_of_elements = base_array_nr_of_elements(*src);

    // Check if shape is equal.
    int shape_eq = generic_array_dimsizes_eq(src, dst, 0 /*do not print error yet*/);

    if(shape_eq) {
        return nr_of_elements;
    }

    // Shape not equal and destination is flexible array.
    // Adjust the dim sizes and realloc the destination
    if(dst->flexible) {
        for(i = 0; i < dst->ndims; ++i) {
          dst->dim_size[i] = src->dim_size[i];
        }
        // let GC collect the old data.
        dst->data = generic_alloc(nr_of_elements, sze);

        return nr_of_elements;
    }

    // Shape not equal and destination is not flexible array.
    generic_array_dimsizes_eq(src, dst, 1 /*print error*/); // Just to print more info.
    throwStreamPrint(NULL, "Failed to copy array. Dimension sizes are not equal and destination array is not flexible.");
    // omc_assert_macro(0 && "Failed to copy array. Dimension sizes are not equal and destination array is not flexible.");

    return -1;
}

void generic_array_create_flexible(base_array_t* dst, int ndims)
{
    dst->ndims = ndims;
    dst->dim_size = size_alloc(ndims);

    dst->flexible = 1;

    size_t i;
    for(i = 0; i < ndims; ++i) {
        dst->dim_size[i] = -1;
    }
}

void generic_array_create(threadData_t* td, base_array_t* dst, constructor_func ctr_func, int ndims, size_t sze, ...)
{
    size_t i, nr_of_elements;

    va_list ap;
    va_start(ap, sze);
    nr_of_elements = alloc_base_array(dst, ndims, ap);
    va_end(ap);
    dst->data = generic_alloc(nr_of_elements, sze);

    // If we get here then the dst array has known dims
    // Which means it is not flexible.
    dst->flexible = 0;

    // Initialize each element of the complex array
    char* d_data = (char*)(dst->data);
    for(i = 0; i < nr_of_elements; ++i) {
        ctr_func(td, d_data + (i*sze));
    }
}

void simple_array_create(threadData_t* td, base_array_t* dst, int ndims, size_t sze, ...)
{
    size_t i, nr_of_elements;

    va_list ap;
    va_start(ap, sze);
    nr_of_elements = alloc_base_array(dst, ndims, ap);
    va_end(ap);
    dst->data = generic_alloc(nr_of_elements, sze);

    // If we get here then the dst array has known dims
    // Which means it is not flexible.
    dst->flexible = 0;

    // Init to 0. IDK if this is what Modelica expects
    // I guess it is better than garbage values.
    memset(dst->data, 0, nr_of_elements*sze);
}


void generic_array_alloc_copy(const base_array_t src_cp, base_array_t* dst, copy_func cp_func, size_t sze)
{
    const base_array_t* src = &src_cp;

    clone_base_array_spec(src, dst);

    // If we get here then it means the dst array had a default value (i.e., binding to src array)
    // Which means even if it was unknown size, it is not flexible anymore and is
    // same shape as the src array.
    dst->flexible = 0;

    size_t nr_of_elements = base_array_nr_of_elements(*dst);
    dst->data = generic_alloc(nr_of_elements, sze);

    size_t i;
    char* d_data = (char*)(dst->data);
    char* s_data = (char*)(src->data);
    for(i = 0; i < nr_of_elements; ++i) {
        cp_func(s_data + (i*sze), d_data + (i*sze));
    }
}

void simple_array_alloc_copy(const base_array_t src_cp, base_array_t* dst, size_t sze)
{
    const base_array_t* src = &src_cp;

    clone_base_array_spec(src, dst);

    // If we get here then it means the dst array had a default value (i.e., binding to src array)
    // Which means even if it was unknown size, it is not flexible anymore and is
    // same shape as the src array.
    dst->flexible = 0;

    size_t nr_of_elements = base_array_nr_of_elements(*dst);
    dst->data = generic_alloc(nr_of_elements, sze);

    memcpy(dst->data, src->data, sze*nr_of_elements);
}


void generic_array_copy_data(const base_array_t src_cp, base_array_t* dst, copy_func cp_func, size_t sze)
{
    const base_array_t* src = &src_cp;

    size_t nr_of_elements = check_copy_sanity(src, dst, sze);

    size_t i;
    char* d_data = (char*)(dst->data);
    char* s_data = (char*)(src->data);
    for(i = 0; i < nr_of_elements; ++i) {
        cp_func(s_data + (i*sze), d_data + (i*sze));
    }
}

void simple_array_copy_data(const base_array_t src_cp, base_array_t* dst, size_t sze)
{
    const base_array_t* src = &src_cp;

    size_t nr_of_elements = check_copy_sanity(src, dst, sze);
    memcpy(dst->data, src->data, sze*nr_of_elements);
}



void* generic_array_get(const base_array_t* src, size_t sze, ...) {
  va_list ap;
  va_start(ap,sze);
  // TODO assert va_list is as long as ndims. Otherwise we have slicing
  void* trgt = generic_ptrget(src, calc_base_index_va(src, src->ndims, ap), sze);
  va_end(ap);
  return trgt;
}

void* generic_array_get1(const base_array_t* src, size_t sze, int sub1) {
    omc_assert_macro(sub1 > 0 && sub1 <= src->dim_size[0]);

    return generic_ptrget(src, sub1 - 1, sze);
}

void* generic_array_get2(const base_array_t* src, size_t sze, int sub1, int sub2) {
    omc_assert_macro(sub1 > 0 && sub1 <= src->dim_size[0]);
    omc_assert_macro(sub2 > 0 && sub2 <= src->dim_size[1]);

    return generic_ptrget(src, ((sub1 - 1) * src->dim_size[1]) + (sub2 - 1), sze);
}

void generic_array_set(base_array_t* dst, void* val, copy_func cp_func, size_t sze, ...) {
  va_list ap;
  va_start(ap,sze);
  // TODO assert va_list is as long as ndims. Otherwise we have slicing
  void* trgt = generic_ptrget(dst, calc_base_index_va(dst, dst->ndims, ap), sze);
  cp_func(val,trgt);
  va_end(ap);
}


