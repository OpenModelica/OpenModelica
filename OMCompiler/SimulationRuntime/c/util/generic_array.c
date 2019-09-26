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

#pragma GCC diagnostic error "-Werror"


static size_t subs_to_offset(const base_array_t *src, va_list ap)
{
    int i;
    size_t offset;

    offset = 0;
    for(i = 0; i < src->ndims; ++i) {
        int sub_i = va_arg(ap, _index_t) - 1;
        if (sub_i < 0 || sub_i >= src->dim_size[i]) {
          throwStreamPrint(NULL, "Dimension %d has bounds 1..%ld, got array subscript %d", i+1, src->dim_size[i], sub_i+1);
        }
        offset = (offset * src->dim_size[i]) + sub_i;
    }

    return offset;
}

static void* array_get(const base_array_t *src, size_t i) {
  return ((char*)src->data) + (i * src->elem_size);
}

static void* array_get_ap(const base_array_t *src, va_list ap) {
  return array_get(src, subs_to_offset(src, ap));
}

static size_t array_nr_of_elems(const base_array_t* src) {
    int i;
    size_t nr_elems = 1;
    for(i = 0; i < src->ndims; ++i) {
        nr_elems *= src->dim_size[i];
    }
    return nr_elems;
}


static int generic_array_ndims_eq(const base_array_t* src, const base_array_t* dst) {
    if(src->ndims != dst->ndims) {
        fprintf(stderr, "src->ndims != dst->ndims, %d != %d\n", src->ndims, dst->ndims);
        return 0;
    }
    return 1;
}

static int generic_array_dimsizes_eq(const base_array_t* src, const base_array_t* dst, int print_error)
{
    int i;
    for(i = 0; i < src->ndims; ++i) {
        if(src->dim_size[i] != dst->dim_size[i]) {
            if (print_error) {
                fprintf(stderr, "src->dim_size[%d] != dst->dim_size[%d], %ld != %ld\n",
                        i, i, src->dim_size[i], dst->dim_size[i]);
            }
            return 0;
        }
    }

    return 1;
}


static size_t check_copy_sanity(const base_array_t* src, base_array_t* dst) {
    size_t i;
    // TODO wrap me in debug. No need to do this in release.
    omc_assert_macro(base_array_ok(src));
    omc_assert_macro(generic_array_ndims_eq(src, dst));

    if(src->elem_size != dst->elem_size) {
        throwStreamPrint(NULL, "src->elem_size != dst->dim_size, %ld != %ld\n", src->elem_size, dst->elem_size);
    }

    size_t nr_elems = array_nr_of_elems(src);

    // Check if shape is equal.
    int shape_eq = generic_array_dimsizes_eq(src, dst, 0 /*do not print error yet*/);

    if(shape_eq) {
        return nr_elems;
    }

    // Shape not equal and destination is flexible array.
    // Adjust the dim sizes and realloc the destination
    if(dst->flexible) {
        for(i = 0; i < dst->ndims; ++i) {
          dst->dim_size[i] = src->dim_size[i];
        }
        // let GC collect the old data.
        dst->data = generic_alloc(nr_elems, dst->elem_size);

        return nr_elems;
    }

    // Shape not equal and destination is not flexible array.
    generic_array_dimsizes_eq(src, dst, 1 /*print error*/); // Just to print more info.
    throwStreamPrint(NULL, "Failed to copy array. Dimension sizes are not equal and destination array is not flexible.");
    // omc_assert_macro(0 && "Failed to copy array. Dimension sizes are not equal and destination array is not flexible.");

    return -1;
}

static void array_clone_spec(const base_array_t *src, base_array_t *dst)
{
    int i;
    assert(base_array_ok(src));

    dst->ndims = src->ndims;
    dst->elem_size = src->elem_size;

    dst->dim_size = size_alloc(dst->ndims);
    for(i = 0; i < dst->ndims; ++i) {
        dst->dim_size[i] = src->dim_size[i];
    }
}




void generic_array_create_flexible(base_array_t* dst, int ndims, size_t sze)
{
    dst->ndims = ndims;
    dst->dim_size = size_alloc(ndims);
    dst->elem_size = sze;

    dst->flexible = 1;

    size_t i;
    for(i = 0; i < ndims; ++i) {
        dst->dim_size[i] = -1;
    }
}

void generic_array_create(threadData_t* td, base_array_t* dst, constructor_func ctr_func, int ndims, size_t sze, ...)
{
    size_t i, nr_elems;

    dst->ndims = ndims;
    dst->dim_size = size_alloc(ndims);
    dst->elem_size = sze;
    // If we get here then the dst array has known dims
    // Whcih means it is not flexible.
    dst->flexible = 0;

    va_list ap;
    va_start(ap, sze);
    for(i = 0; i < ndims; ++i) {
        dst->dim_size[i] = va_arg(ap, _index_t);
        nr_elems *= dst->dim_size[i];
    }
    va_end(ap);

    size_t data_size = nr_elems * dst->elem_size;
    dst->data = omc_alloc_interface.malloc(data_size);

    // Initialize each element of the complex array
    char* d_data = (char*)(dst->data);
    for(i = 0; i < nr_elems; ++i) {
        ctr_func(td, array_get(dst, i));
    }
}

void simple_array_create(threadData_t* td, base_array_t* dst, int ndims, size_t sze, ...)
{
    size_t i, nr_elems;

    dst->ndims = ndims;
    dst->dim_size = size_alloc(ndims);
    dst->elem_size = sze;
    // If we get here then the dst array has known dims
    // Whcih means it is not flexible.
    dst->flexible = 0;

    va_list ap;
    va_start(ap, sze);
    for(i = 0; i < ndims; ++i) {
        dst->dim_size[i] = va_arg(ap, _index_t);
        nr_elems *= dst->dim_size[i];
    }
    va_end(ap);

    size_t data_size = nr_elems * dst->elem_size;
    dst->data = omc_alloc_interface.malloc(data_size);

    // Init to 0. IDK if this is what Modelica expects
    // I guess it is better than garbage values.
    memset(dst->data, 0, data_size);
}


void generic_array_alloc_copy(const base_array_t src_cp, base_array_t* dst, copy_func cp_func)
{
    const base_array_t* src = &src_cp;

    array_clone_spec(src, dst);

    // If we get here then it means the dst array had a default value (i.e., binding to src array)
    // Whcih means even if it was unknown size, it is not flexible anymore and is
    // same shape as the src array.
    dst->flexible = 0;

    size_t nr_elems = array_nr_of_elems(dst);
    size_t data_size = nr_elems * dst->elem_size;
    dst->data = omc_alloc_interface.malloc(data_size);

    size_t i;
    for(i = 0; i < nr_elems; ++i) {
        cp_func(array_get(src, i), array_get(dst, i));
    }
}

void simple_array_alloc_copy(const base_array_t src_cp, base_array_t* dst)
{
    const base_array_t* src = &src_cp;

    array_clone_spec(src, dst);

    // If we get here then it means the dst array had a default value (i.e., binding to src array)
    // Whcih means even if it was unknown size, it is not flexible anymore and is
    // same shape as the src array.
    dst->flexible = 0;

    size_t nr_elems = array_nr_of_elems(dst);
    size_t data_size = nr_elems * dst->elem_size;
    dst->data = generic_alloc(nr_elems, data_size);

    memcpy(dst->data, src->data, data_size);
}


void generic_array_copy_data(const base_array_t src_cp, base_array_t* dst, copy_func cp_func)
{
    const base_array_t* src = &src_cp;

    size_t nr_elems = check_copy_sanity(src, dst);

    size_t i;
    for(i = 0; i < nr_elems; ++i) {
        cp_func(array_get(src, i), array_get(dst, i));
    }
}

void simple_array_copy_data(const base_array_t src_cp, base_array_t* dst)
{
    const base_array_t* src = &src_cp;

    size_t nr_elems = check_copy_sanity(src, dst);
    memcpy(dst->data, src->data, dst->elem_size*nr_elems);
}



void* generic_array_get(const base_array_t* src, ...) {
  va_list ap;
  va_start(ap,src);
  // TODO assert va_list is as long as ndims. Otherwise we have slicing
  void* trgt = array_get_ap(src, ap);
  va_end(ap);

  return trgt;
}

void generic_array_set(base_array_t* dst, void* val, copy_func cp_func, ...) {
  va_list ap;
  va_start(ap,cp_func);
  // TODO assert va_list is as long as ndims. Otherwise we have slicing
  void* trgt = array_get_ap(dst, ap);
  va_end(ap);

  cp_func(val,trgt);
}



// TODO remove me. not needed anymore. superseded by generic_array_get
// TODO: ndims is not needed to be passed here.
void* generic_array_element_addr(const base_array_t* src, size_t sze, int ndims, ...) {
  va_list ap;
  va_start(ap,ndims);
  void* trgt = array_get_ap(src, ap);
  va_end(ap);

  return trgt;
}

void* generic_array_element_addr1(const base_array_t* source, size_t sze, int sub1) {
  return array_get(source, sub1-1);
}



