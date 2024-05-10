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


#include "integer_array.h"
#include "index_spec.h"
#include "../gc/omc_gc.h"
#include "division.h"
#include "generic_array.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>

#include "omc_error.h"
#include "../meta/meta_modelica.h"

static OMC_INLINE modelica_integer *integer_ptrget(const integer_array *a, size_t i)
{
  return ((modelica_integer *) a->data) + i;
}

static OMC_INLINE void integer_set(integer_array *a, size_t i, modelica_integer r)
{
  ((modelica_integer *) a->data)[i] = r;
}

modelica_integer integer_get(const integer_array a, size_t i)
{
  return ((modelica_integer *) a.data)[i];
}

modelica_integer integer_get_2D(const integer_array a, size_t i, size_t j)
{
  return integer_get(a, getIndex_2D(a.dim_size,i,j));
}

modelica_integer integer_get_3D(const integer_array a, size_t i, size_t j, size_t k)
{
  return integer_get(a, getIndex_3D(a.dim_size,i,j,k));
}

modelica_integer integer_get_4D(const integer_array a, size_t i, size_t j, size_t k, size_t l)
{
  return integer_get(a, getIndex_4D(a.dim_size,i,j,k,l));
}

modelica_integer integer_get_5D(const integer_array a, size_t i, size_t j, size_t k, size_t l, size_t m)
{
  return integer_get(a, getIndex_5D(a.dim_size,i,j,k,l,m));
}

/** function: integer_array_create
 **
 ** sets all fields in a integer_array, i.e. data, ndims and dim_size.
 **/
void integer_array_create(integer_array *dest, modelica_integer *data,
                          int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}


void simple_alloc_1d_integer_array(integer_array* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, n ? integer_alloc(n) : NULL);
}

void simple_alloc_2d_integer_array(integer_array* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, integer_alloc(r * c));
}

void alloc_integer_array(integer_array* dest,int ndims,...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = integer_alloc(elements);
}

void alloc_integer_array_data(integer_array* a)
{
    a->data = integer_alloc(base_array_nr_of_elements(*a));
}

void copy_integer_array_data_mem(const integer_array source,
                                 modelica_integer *dest)
{
    size_t i, nr_of_elements;

    omc_assert_macro(base_array_ok(&source));

    nr_of_elements = base_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = integer_get(source, i);
    }
}

void copy_integer_array(const integer_array source, integer_array *dest)
{
    integer_array_alloc_copy(source,*dest);
}

static modelica_integer integer_le(modelica_integer x, modelica_integer y)
{
    return (x <= y);
}

static modelica_integer integer_ge(modelica_integer x, modelica_integer y)
{
    return (x >= y);
}

/* Creates an integer array from a range with a start, stop and step value.
 * Ex: 1:2:6 => {1,3,5} */
void create_integer_array_from_range(integer_array *dest, modelica_integer start, modelica_integer step, modelica_integer stop)
{
    size_t elements;
    size_t i;
    modelica_integer (*comp_func)(modelica_integer, modelica_integer);

    omc_assert_macro(step != 0);

    comp_func = (step > 0) ? &integer_le : &integer_ge;
    elements = comp_func(start, stop) ? (((stop - start) / step) + 1) : 0;

    simple_alloc_1d_integer_array(dest, elements);

    for(i = 0; i < elements; start += step, ++i) {
        integer_set(dest, i, start);
    }
}

/*
 * Fills an integer array ROW from a range with a start, stop and step value.
 * The last argument is the row/dimension to be filled.
 * e.g: Integer a[10], b[2][10]; a := 1:2:6; b[1] := 1:10;
 *
*/
void fill_integer_array_from_range(integer_array *dest, modelica_integer start, modelica_integer step,
                                   modelica_integer stop/*, size_t dim*/)
{
    size_t elements;
    size_t i;
    modelica_integer value = start;
    modelica_integer (*comp_func)(modelica_integer, modelica_integer);

    omc_assert_macro(step != 0);

    comp_func = (step > 0) ? &integer_le : &integer_ge;
    elements = comp_func(start, stop) ? (((stop - start) / step) + 1) : 0;

    for(i = 0; i < elements; value += step, ++i) {
        integer_set(dest, i, value);
    }
}

/*
 a[1:3] := b;
*/

static inline modelica_integer* calc_integer_index_spec(int ndims, const _index_t* idx_vec,
                                                        const integer_array * arr,
                                                        const index_spec_t* spec)
{
    return integer_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_integer* calc_integer_index(int ndims, const _index_t* idx_vec,
                                     const integer_array * arr)
{
    return integer_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_integer* calc_integer_index_va(const integer_array * source,int ndims,
                                        va_list ap)
{
    return integer_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_integer_matrix(const integer_array * source)
{
    _index_t i,j;
    modelica_integer value;

    if(source->ndims == 2) {
        printf("%d X %d matrix:\n", (int) source->dim_size[0], (int) source->dim_size[1]);
        for(i = 0; i < source->dim_size[0]; ++i) {
            for(j = 0; j < source->dim_size[1]; ++j) {
                value = integer_get(*source, (i * source->dim_size[1]) + j);
                printf("%ld\t", value);
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_integer_array(const integer_array * source)
{
    _index_t i,j;
    modelica_integer *data;
    omc_assert_macro(base_array_ok(source));

    data = (modelica_integer *) source->data;
    if(source->ndims == 1) {
        for(i = 1; i < source->dim_size[0]; ++i) {
            printf("%ld, ",*data);
            ++data;
        }
        if(0 < source->dim_size[0]) {
            printf("%ld",*data);
        }
    } else if(source->ndims > 1) {
        size_t k, n;
        n = base_array_nr_of_elements(*source) /
            (source->dim_size[0] * source->dim_size[1]);
        for(k = 0; k < n; ++k) {
            for(i = 0; i < source->dim_size[1]; ++i) {
                for(j = 0; j < source->dim_size[0]; ++j) {
                    printf("%ld, ",*data);
                    ++data;
                }
                if(0 < source->dim_size[0]) {
                    printf("%ld",*data);
                }
                printf("\n");
            }
            if((k + 1) < n) {
                printf("\n ================= \n");
            }
        }
    }
}

void put_integer_element(modelica_integer value, int i1, integer_array* dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    integer_set(dest, i1, value);
}

void put_integer_matrix_element(modelica_integer value, int r, int c,
                                integer_array* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    integer_set(dest, (r * dest->dim_size[1]) + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_integer_array1(const integer_array * source,
                                          int i1,
                                          integer_array* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    integer_set(dest, i1, integer_get(*source, i1));
}

void simple_indexed_assign_integer_array2(const integer_array * source,
                                          int i1, int i2,
                                          integer_array* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = (i1 * source->dim_size[1]) + i2;
    integer_set(dest, index, integer_get(*source, index));
}

void indexed_assign_integer_array(const integer_array source, integer_array* dest,
                                  const index_spec_t* dest_spec)
{
    _index_t *idx_vec1, *idx_size;
    int j;
    indexed_assign_base_array_size_alloc(&source, dest, dest_spec, &idx_vec1, &idx_size);

    j = 0;
    do {
        integer_set(dest,
                 calc_base_index_spec(dest->ndims, idx_vec1, dest, dest_spec),
                 integer_get(source, j));
        j++;

    } while(0 == next_index(dest_spec->ndims, idx_vec1, idx_size));

    omc_assert_macro(j == base_array_nr_of_elements(source));
}

/*
 function: index_integer_array
 *
 * Returns an subscript of the source array in the destination array.
 * Assumes that both source array and destination array is properly
 * allocated.
 *
 * a := b[1:3];
 *
*/

void index_integer_array(const integer_array * source,
                         const index_spec_t* source_spec,
                         integer_array* dest)
{
    _index_t* idx_vec1;
    _index_t* idx_vec2;
    _index_t* idx_size;
    int j;
    int i;

    omc_assert_macro(base_array_ok(source));
    omc_assert_macro(base_array_ok(dest));
    omc_assert_macro(index_spec_ok(source_spec));
    omc_assert_macro(index_spec_fit_base_array(source_spec,source));
    for(i = 0, j = 0; i < source->ndims; ++i) {
        if((source_spec->index_type[i] == 'W')
            ||
            (source_spec->index_type[i] == 'A')) {
            ++j;
        }
    }
    omc_assert_macro(j == dest->ndims);

    idx_vec1 = size_alloc(source->ndims); /*indices in the source array*/
    idx_vec2 = size_alloc(dest->ndims); /* indices in the destination array*/
    idx_size = size_alloc(source_spec->ndims);

    for(i = 0; i < source->ndims; ++i) {
        idx_vec1[i] = 0;
    }
    for(i = 0; i < source_spec->ndims; ++i) {
        if(source_spec->index[i] != NULL) {
            idx_size[i] = imax(source_spec->dim_size[i],1);
        } else {
            idx_size[i] = source->dim_size[i];
        }
    }

    do {
        for(i = 0, j = 0; i < source->ndims; ++i) {
            if((source_spec->index_type[i] == 'W')
                ||
                (source_spec->index_type[i] == 'A')) {
                idx_vec2[j] = idx_vec1[i];
                ++j;
            }
        }

        integer_set(dest, calc_base_index(dest->ndims, idx_vec2, dest),
                    integer_get(*source,
                                calc_base_index_spec(source->ndims, idx_vec1,
                                                     source, source_spec)));

    } while(0 == next_index(source->ndims, idx_vec1, idx_size));
}

/*
 * function: index_alloc_integer_array
 *
 * Returns an subscript of the source array in the destination array
 * in the same manner as index_integer_array, except that the destination
 * array is allocated.
 *
 *
 * a := b[1:3];
 */

void index_alloc_integer_array(const integer_array * source,
             const index_spec_t* source_spec,
             integer_array* dest)
{
    index_alloc_base_array_size(source, source_spec, dest);
    alloc_integer_array_data(dest);
    index_integer_array(source, source_spec, dest);
}

/* idx(a[i,j,k]) = i * a->dim_size[1] * a->dim_size[2] + j * a->dim_size[2] + k */
/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_integer_array1(const integer_array * source, int i1,
                                       integer_array* dest)
{
    int i;
    omc_assert_macro(base_array_ok(source));

    dest->ndims = source->ndims - 1;
    dest->dim_size = size_alloc(dest->ndims);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[i+1];
    }
    alloc_integer_array_data(dest);

    simple_index_integer_array1(source, i1, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_integer_array1(const integer_array * source,
                                 int i1,
                                 integer_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * i1;

    omc_assert_macro(dest->ndims == (source->ndims - 1));

    for(i = 0 ; i < nr_of_elements ; i++) {
        integer_set(dest, i, integer_get(*source, off + i));
    }
}

/* Returns dest := source[i1,i2,:,:...]*/
void simple_index_integer_array2(const integer_array * source,
                                 int i1, int i2,
                                 integer_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * ((source->dim_size[1] * i1) + i2);

    for(i = 0 ; i < nr_of_elements ; i++) {
        integer_set(dest, i, integer_get(*source, off + i));
    }
}

void array_integer_array(integer_array* dest,int n,integer_array first,...)
{
    int i,j,c;
    va_list ap;

    integer_array *elts=(integer_array*)malloc(sizeof(integer_array) * n);
    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, integer_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            integer_set(dest, c, integer_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

void array_alloc_integer_array(integer_array* dest,int n,
                               integer_array first,...)
{
    int i,j,c;
    va_list ap;

    integer_array *elts=(integer_array*)malloc(sizeof(integer_array) * n);
    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, integer_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    if(first.ndims == 1) {
        alloc_integer_array(dest, 2, n, first.dim_size[0]);
    } else if(first.ndims == 2) {
        alloc_integer_array(dest, 3, n, first.dim_size[0], first.dim_size[1]);
    } else if(first.ndims == 3) {
        alloc_integer_array(dest, 4, n, first.dim_size[0], first.dim_size[1], first.dim_size[2]);
    } else if(first.ndims == 4) {
        alloc_integer_array(dest, 5, n, first.dim_size[0], first.dim_size[1], first.dim_size[2], first.dim_size[3]);
    } else {
        omc_assert_macro(0 && "Dimension size > 4 not impl. yet");
    }

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            integer_set(dest, c, integer_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

/* array_alloc_scalar_integer_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */
void array_alloc_scalar_integer_array(integer_array* dest, int n,
                                      modelica_integer first,...)
{
    int i;
    va_list ap;
    simple_alloc_1d_integer_array(dest,n);
    va_start(ap,first);
    put_integer_element(first,0,dest);
    for(i = 1; i < n; ++i) {
        put_integer_element(va_arg(ap, modelica_integer),i,dest);
    }
    va_end(ap);
}

/* function: cat_integer_array
 *
 * Concatenates n integer arrays along the k:th dimension.
 * k is one based
 */
void cat_integer_array(int k, integer_array* dest, int n,
                    const integer_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const integer_array **elts = (const integer_array**)malloc(sizeof(integer_array *) * n);

    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const integer_array*);
    }
    va_end(ap);

    /* check dim sizes of all inputs and dest */
    omc_assert_macro(elts[0]->ndims >= k);
    for(i = 0; i < n; i++) {
        omc_assert_macro(dest->ndims == elts[i]->ndims);
        for(j = 0; j < (k - 1); j++) {
            omc_assert_macro(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k-1];
        for(j = k; j < elts[0]->ndims; j++) {
            omc_assert_macro(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
    }
    omc_assert_macro(dest->dim_size[k-1] == new_k_dim_size);

    /* calculate size of sub and super structure in 1-dim data representation */
    for(i = 0; i < (k - 1); i++) {
        n_super *= elts[0]->dim_size[i];
    }
    for(i = k; i < elts[0]->ndims; i++) {
        n_sub *= elts[0]->dim_size[i];
    }

    /* concatenation along k-th dimension */
    j = 0;
    for(i = 0; i < n_super; i++) {
        for(c = 0; c < n; c++) {
            int n_sub_k = n_sub * elts[c]->dim_size[k-1];
            for(r = 0; r < n_sub_k; r++) {
                integer_set(dest, j,
                            integer_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/* function: cat_alloc_integer_array
 *
 * Concatenates n integer arrays along the k:th dimension.
 * allocates space in dest array
 * k is one based
 */
void cat_alloc_integer_array(int k, integer_array* dest, int n,
                          const integer_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const integer_array **elts = (const integer_array**)malloc(sizeof(integer_array *) * n);

    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const integer_array*);
    }
    va_end(ap);

    /* check dim sizes of all inputs */
    omc_assert_macro(elts[0]->ndims >= k);
    new_k_dim_size = elts[0]->dim_size[k-1];
    for(i = 1; i < n; i++) {
        omc_assert_macro(elts[0]->ndims == elts[i]->ndims);
        for(j = 0; j < (k - 1); j++) {
            omc_assert_macro(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k-1];
        for(j = k; j < elts[0]->ndims; j++) {
            omc_assert_macro(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
        }
    }

    /* calculate size of sub and super structure in 1-dim data representation */
    for(i = 0; i < (k - 1); i++) {
        n_super *= elts[0]->dim_size[i];
    }
    for(i = k; i < elts[0]->ndims; i++) {
        n_sub *= elts[0]->dim_size[i];
    }
    /* allocate dest structure */
    dest->data = integer_alloc( n_super * new_k_dim_size * n_sub);
    dest->ndims = elts[0]->ndims;
    dest->dim_size = size_alloc(dest->ndims);
    for(j = 0; j < dest->ndims; j++) {
        dest->dim_size[j] = elts[0]->dim_size[j];
    }
    dest->dim_size[k-1] = new_k_dim_size;
    /* concatenation along k-th dimension */
    j = 0;
    for(i = 0; i < n_super; i++) {
        for(c = 0; c < n; c++) {
            int n_sub_k = n_sub * elts[c]->dim_size[k-1];
            for(r = 0; r < n_sub_k; r++) {
                integer_set(dest, j,
                            integer_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

void range_alloc_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array* dest)
{
    int n;

    n = (int)floor((stop-start)/inc)+1;
    simple_alloc_1d_integer_array(dest,n);
    range_integer_array(start,stop,inc,dest);
}

void range_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array* dest)
{
    size_t i;
    /* Assert that dest has correct size */
    for(i = 0; i < dest->dim_size[0]; ++i) {
        integer_set(dest, i, start + (i * inc));
    }
}

void usub_integer_array(integer_array* a)
{
    size_t nr_of_elements, i;

    nr_of_elements = base_array_nr_of_elements(*a);
    for(i = 0; i < nr_of_elements; ++i)
    {
        integer_set(a, i, -integer_get(*a, i));
    }
}

void usub_alloc_integer_array(const integer_array a, integer_array* dest)
{
    size_t nr_of_elements, i;
    clone_integer_array_spec(&a,dest);
    alloc_integer_array_data(dest);

    nr_of_elements = base_array_nr_of_elements(*dest);
    for(i = 0; i < nr_of_elements; ++i)
    {
        integer_set(dest, i, -integer_get(a, i));
    }
}

void add_integer_array(const integer_array * a, const integer_array * b, integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert a and b are of the same size */
    omc_assert_macro(base_array_nr_of_elements(*b) == nr_of_elements);
    /* Assert that dest are of correct size */
    omc_assert_macro(base_array_nr_of_elements(*dest) == nr_of_elements);

    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(*a, i)+integer_get(*b, i));
    }
}

integer_array add_alloc_integer_array(const integer_array a, const integer_array  b)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    add_integer_array(&a,&b,&dest);
    return dest;
}

void sub_integer_array(const integer_array * a, const integer_array * b, integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert a and b are of the same size */
    omc_assert_macro(base_array_nr_of_elements(*b) == nr_of_elements);
    /* Assert that dest are of correct size */
    omc_assert_macro(base_array_nr_of_elements(*dest) == nr_of_elements);

    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(*a, i)-integer_get(*b, i));
    }
}

void sub_integer_array_data_mem(const integer_array * a, const integer_array * b,
                                modelica_integer* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert a and b are of the same size */
    omc_assert_macro(base_array_nr_of_elements(*b) == nr_of_elements);
    /* Assert that dest are of correct size */

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = integer_get(*a, i) - integer_get(*b, i);
    }
}

integer_array sub_alloc_integer_array(const integer_array a, const integer_array b)
{
  integer_array dest;
  clone_integer_array_spec(&a, &dest);
  alloc_integer_array_data(&dest);
  sub_integer_array(&a, &b, &dest);
  return dest;
}

void mul_scalar_integer_array(modelica_integer a,const integer_array * b,integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*b);

    /* Assert that dest has correct size*/
    omc_assert_macro(base_array_nr_of_elements(*dest) == nr_of_elements);

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, a * integer_get(*b, i));
    }
}

integer_array mul_alloc_scalar_integer_array(modelica_integer a, const integer_array b)
{
    integer_array dest;
    clone_integer_array_spec(&b,&dest);
    alloc_integer_array_data(&dest);
    mul_scalar_integer_array(a,&b,&dest);
    return dest;
}

void mul_integer_array_scalar(const integer_array * a,modelica_integer b,integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert that dest has correct size*/
    omc_assert_macro(base_array_nr_of_elements(*dest) == nr_of_elements);

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(*a, i) * b);
    }
}

integer_array mul_alloc_integer_array(const integer_array a, integer_array b)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    mul_integer_array(&a,&b,&dest);
    return dest;
}

void mul_integer_array(const integer_array *a,const integer_array *b,integer_array* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that a,b have same sizes? */
  nr_of_elements = base_array_nr_of_elements(*a);
  for(i=0; i < nr_of_elements; ++i) {
    integer_set(dest, i, integer_get(*a, i) * integer_get(*b, i));
  }
}


integer_array mul_alloc_integer_array_scalar(const integer_array a, modelica_integer b)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    mul_integer_array_scalar(&a,b,&dest);
    return dest;
}


modelica_integer mul_integer_scalar_product(const integer_array a, const integer_array b)
{
    size_t nr_of_elements;
    size_t i;
    modelica_integer res;

    /* Assert that a and b are vectors */
    omc_assert_macro(a.ndims == 1);
    omc_assert_macro(b.ndims == 1);
    /* Assert that vectors are of matching size */
    omc_assert_macro(a.dim_size[0] == b.dim_size[0]);

    nr_of_elements = base_array_nr_of_elements(a);
    res = 0;
    for(i = 0; i < nr_of_elements; ++i) {
        res += integer_get(a, i)*integer_get(b, i);
    }
    return res;
}

void mul_integer_matrix_product(const integer_array * a,const integer_array * b,integer_array* dest)
{
    modelica_integer tmp;
    size_t i_size;
    size_t j_size;
    size_t k_size;
    size_t i;
    size_t j;
    size_t k;

    /* Assert that dest har correct size */
    i_size = dest->dim_size[0];
    j_size = dest->dim_size[1];
    k_size = a->dim_size[1];

    for(i = 0; i < i_size; ++i) {
        for(j = 0; j < j_size; ++j) {
            tmp = 0;
            for(k = 0; k < k_size; ++k) {
                tmp += integer_get(*a, (i * k_size) + k)*integer_get(*b, (k * j_size) + j);
            }
            integer_set(dest, (i * j_size) + j, tmp);
        }
    }
}

void mul_integer_matrix_vector(const integer_array * a, const integer_array * b,integer_array* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_integer tmp;

    /* Assert a matrix */
    omc_assert_macro(a->ndims == 2);
    /* Assert b vector */
    omc_assert_macro(b->ndims == 1);
    /* Assert dest correct size (a vector)*/
    omc_assert_macro(dest->ndims == 1);

    i_size = a->dim_size[0];
    j_size = a->dim_size[1];

    for(i = 0; i < i_size; ++i) {
        tmp = 0;
        for(j = 0; j < j_size; ++j) {
            tmp += integer_get(*a, (i * j_size) + j)*integer_get(*b, j);
        }
        integer_set(dest, i, tmp);
    }
}


void mul_integer_vector_matrix(const integer_array * a, const integer_array * b,integer_array* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_integer tmp;

    /* Assert a vector */
    omc_assert_macro(a->ndims == 1);
    /* Assert b matrix */
    omc_assert_macro(b->ndims == 2);
    /* Assert dest vector of correct size */

    i_size = a->dim_size[0];
    j_size = b->dim_size[1];

    for(i = 0; i < i_size; ++i) {
        tmp = 0;
        for(j = 0; j < j_size; ++j) {
            tmp += integer_get(*a, j) * integer_get(*b, (j * j_size) + i);
        }
        integer_set(dest, i, tmp);
    }
}

integer_array mul_alloc_integer_matrix_product_smart(const integer_array a, const integer_array b)
{
    integer_array dest;
    if((a.ndims == 1) && (b.ndims == 2)) {
        simple_alloc_1d_integer_array(&dest,b.dim_size[1]);
        mul_integer_vector_matrix(&a,&b,&dest);
    } else if((a.ndims == 2) && (b.ndims == 1)) {
        simple_alloc_1d_integer_array(&dest,a.dim_size[0]);
        mul_integer_matrix_vector(&a,&b,&dest);
    } else if((a.ndims == 2) && (b.ndims == 2)) {
        simple_alloc_2d_integer_array(&dest,a.dim_size[0],b.dim_size[1]);
        mul_integer_matrix_product(&a,&b,&dest);
    } else {
        omc_assert_macro(0 == "Invalid size of matrix");
    }
    return dest;
}

void div_integer_array_scalar(const integer_array * a,modelica_integer b,integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert that dest has correct size*/
    omc_assert_macro(nr_of_elements == base_array_nr_of_elements(*dest));

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(*a, i)/b);
    }
}

integer_array div_alloc_integer_array_scalar(const integer_array a,modelica_integer b)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    div_integer_array_scalar(&a,b,&dest);
    return dest;
}

void division_integer_array_scalar(threadData_t *threadData, const integer_array * a,modelica_integer b,integer_array* dest, const char* division_str)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert that dest has correct size*/
    omc_assert_macro(nr_of_elements == base_array_nr_of_elements(*dest));

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, (modelica_integer)DIVISIONNOTIME(integer_get(*a, i),b,division_str));
    }
}

integer_array division_alloc_integer_array_scalar(threadData_t *threadData,const integer_array a,modelica_integer b, const char* division_str)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    division_integer_array_scalar(threadData,&a,b,&dest,division_str);
    return dest;
}

void div_scalar_integer_array(modelica_integer a, const integer_array* b, integer_array* dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(*b);
    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, a / integer_get(*b, i));
    }
}

integer_array div_alloc_scalar_integer_array(modelica_integer a, const integer_array b)
{
    integer_array dest;
    clone_integer_array_spec(&b,&dest);
    alloc_integer_array_data(&dest);
    div_scalar_integer_array(a,&b,&dest);
    return dest;
}

void pow_integer_array_scalar(const integer_array *a, modelica_integer b, integer_array* dest)
{
  size_t nr_of_elements = base_array_nr_of_elements(*a);
  size_t i;

  omc_assert_macro(nr_of_elements == base_array_nr_of_elements(*dest));

  for(i = 0; i < nr_of_elements; ++i) {
    integer_set(dest, i, (modelica_integer)pow(integer_get(*a, i), b));
  }
}

integer_array pow_alloc_integer_array_scalar(const integer_array a, modelica_integer b)
{
  integer_array dest;
  clone_integer_array_spec(&a, &dest);
  alloc_integer_array_data(&dest);
  pow_integer_array_scalar(&a, b, &dest);
  return dest;
}

void exp_integer_array(const integer_array * a, modelica_integer n, integer_array* dest)
{
    /* Assert n>=0 */
    omc_assert_macro(n >= 0);
    /* Assert that a is a two dimensional square array */
    omc_assert_macro((a->ndims == 2) && (a->dim_size[0] == a->dim_size[1]));
    /* Assert that dest is a two dimensional square array with the same size as a */
    omc_assert_macro((dest->ndims == 2) && (dest->dim_size[0] == dest->dim_size[1]) && (a->dim_size[0] == dest->dim_size[0]));

    if(n==0) {
        identity_integer_array(a->dim_size[0],dest);
    } else {
        if(n==1) {
            clone_integer_array_spec(a,dest);
            integer_array_copy_data(*a, *dest);
        } else if (n==2) {
            clone_integer_array_spec(a,dest);
            mul_integer_matrix_product(a,a,dest);
        } else {
            modelica_integer i;

            integer_array tmp;
            integer_array * b;
            integer_array * c;

            /* prepare temporary array */
            clone_integer_array_spec(a,&tmp);
            clone_integer_array_spec(a,dest);

            if ((n&1) != 0) {
              b = &tmp;
              c = dest;
            } else {
              b = dest;
              c = &tmp;
            }
            mul_integer_matrix_product(a,a,b);
            for( i = 2; i < n; ++i) {
                integer_array * x;

                mul_integer_matrix_product(a,b,c);

                /* exchange b and c */
                x = b;
                b = c;
                c = x;
            }
            /* result is already in dest */
        }
    }
}

integer_array exp_alloc_integer_array(const integer_array a,modelica_integer b)
{
    integer_array dest;
    clone_integer_array_spec(&a,&dest);
    alloc_integer_array_data(&dest);
    exp_integer_array(&a,b,&dest);
    return dest;
}

/* function: promote_alloc_integer_array
 *
 * Implementation of promote(A,n) same as promote_integer_array except
 * that the destination array is allocated.
 */
void promote_alloc_integer_array(const integer_array * a, int n, integer_array* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    promote_integer_array(a,n,dest);
}

/* function: promote_integer_array.
 *
 * Implementation of promote(a,n)
 * Adds n onesized array dimensions to the array a to "the right of array dimensions".
 * For instance
 * promote_exp( {1,2},1) => {{1},{2}}
 * promote_exp( {1,2},2) => { {{1}},{{2}} }
*/
void promote_integer_array(const integer_array * a, int n,integer_array* dest)
{
    int i;

    dest->dim_size = size_alloc(n+a->ndims);
    dest->data = a->data;
    /* Assert a->ndims>=n */
    for(i = 0; i < a->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
    for(i = a->ndims; i < (n + a->ndims); ++i) {
        dest->dim_size[i] = 1;
    }
    dest->ndims=n+a->ndims;
}

/* function: promote_scalar_integer_array
 *
 * promotes a scalar value to an n dimensional array.
 */
void promote_scalar_integer_array(modelica_integer s,int n,integer_array* dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = integer_alloc(1);

    dest->ndims = n;
    integer_set(dest, 0, s);

    for(i = 0; i < n; ++i) {
        dest->dim_size[i] = 1;
    }
}

/* return a vector of length ndims(a) containing the dimension sizes of a */
void size_integer_array(const integer_array * a, integer_array* dest)
{
    int i;

    omc_assert_macro(dest->ndims == 1);
    omc_assert_macro(dest->dim_size[0] == a->ndims);

    for(i = 0 ; i < a->ndims ; i++) {
        integer_set(dest, i, a->dim_size[i]);
    }
}

modelica_integer scalar_integer_array(const integer_array * a)
{
    omc_assert_macro(base_array_ok(a));
    omc_assert_macro(base_array_one_element_ok(a));

    return integer_get(*a, 0);
}

void vector_integer_array(const integer_array * a, integer_array* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(*a);
    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(*a, i));
    }
}

void vector_integer_scalar(modelica_integer a,integer_array* dest)
{
    /* Assert that dest is a 1-vector */
    integer_set(dest, 0, a);
}

void matrix_integer_array(const integer_array * a, integer_array* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for(i = 0; i < cnt; ++i) {
        integer_set(dest, i, integer_get(*a, i));
    }
}

void matrix_integer_scalar(modelica_integer a,integer_array* dest)
{
    dest->ndims = 2;
    dest->dim_size[0] = 1;
    dest->dim_size[1] = 1;
    integer_set(dest, 0, a);
}

/* function: transpose_alloc_integer_array
 *
 * Implementation of transpose(A) for matrix A. Same as transpose_integer_array
 * except that destionation array is allocated.
 */

void transpose_alloc_integer_array(const integer_array * a, integer_array* dest)
{
    clone_integer_array_spec(a,dest); /* allocation*/

    /* transpose only valid for matrices.*/

    omc_assert_macro(a->ndims == 2);
    dest->dim_size[0]=a->dim_size[1];
    dest->dim_size[1]=a->dim_size[0];
    dest->ndims = 2;

    alloc_integer_array_data(dest);
    transpose_integer_array(a,dest);
}

/* function: transpose_integer_array
 *
 * Implementation of transpose(A) for matrix A.
 */
void transpose_integer_array(const integer_array * a, integer_array* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if(a->ndims == 1) {
        integer_array_copy_data(*a, *dest);
        return;
    }

    omc_assert_macro(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    omc_assert_macro(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for(i = 0; i < n; ++i) {
        for(j = 0; j < m; ++j) {
            integer_set(dest, (j * n) + i, integer_get(*a, (i * m) + j));
        }
    }
}

void outer_product_integer_array(const integer_array * v1,const integer_array * v2, integer_array* dest)
{
  size_t i;
  size_t j;
  size_t number_of_elements_a;
  size_t number_of_elements_b;

  number_of_elements_a = base_array_nr_of_elements(*v1);
  number_of_elements_b = base_array_nr_of_elements(*v2);

  /* Assert a is a vector */
  /* Assert b is a vector */

  for(i = 0; i < number_of_elements_a; ++i) {
    for(j = 0; i < number_of_elements_b; ++j) {
      integer_set(dest, (i * number_of_elements_b) + j, integer_get(*v1, i)*integer_get(*v2, j));
    }
  }
}

void outer_product_alloc_integer_array(const integer_array* v1, const integer_array* v2, integer_array* dest)
{
  size_t dim1,dim2;
  omc_assert_macro(base_array_ok(v1));
  dim1 = base_array_nr_of_elements(*v1);
  dim2 = base_array_nr_of_elements(*v2);
  alloc_integer_array(dest,dim1,dim2);
  outer_product_integer_array(v1,v2,dest);
}

/* Fills an array with a value. */
void fill_alloc_integer_array(integer_array* dest, modelica_integer value, int ndims, ...)
{
    size_t i;
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = integer_alloc(elements);

    for(i = 0; i < elements; ++i) {
        integer_set(dest, i, value);
    }
}

void identity_integer_array(int n, integer_array* dest)
{
    int i;
    int j;

    omc_assert_macro(base_array_ok(dest));

    /* Check that dest size is ok */
    omc_assert_macro(dest->ndims==2);
    omc_assert_macro((dest->dim_size[0]==n) && (dest->dim_size[1]==n));

    for(i = 0; i < (n * n); ++i) {
        integer_set(dest, i, 0);
    }
    j = 0;
    for(i = 0; i < n; ++i) {
        integer_set(dest, j, 1);
        j += n+1;
    }
}

void identity_alloc_integer_array(int n,integer_array* dest)
{
    alloc_integer_array(dest,2,n,n);
    identity_integer_array(n,dest);
}

static void diagonal_integer_array_impl(const integer_array *v, integer_array* dest)
{
    size_t i;
    size_t j;
    size_t n;

    n = v->dim_size[0];

    for(i = 0; i < (n * n); ++i) {
        integer_set(dest, i, 0);
    }
    j = 0;
    for(i = 0; i < n; ++i) {
        integer_set(dest, j, integer_get(*v, i));
        j += n + 1;
    }
}

void diagonal_integer_array(const integer_array * v,integer_array* dest)
{
    size_t n;

    /* Assert that v is a vector */
    omc_assert_macro(v->ndims == 1);

    /* Assert that dest is a nxn matrix */
    n = v->dim_size[0];
    omc_assert_macro(dest->ndims == 2);
    omc_assert_macro((dest->dim_size[0] == n) && (dest->dim_size[1] == n));

    diagonal_integer_array_impl(v, dest);
}

void diagonal_alloc_integer_array(const integer_array* v, integer_array* dest)
{
    size_t n;

    /* Assert that v is a vector */
    omc_assert_macro(v->ndims == 1);

    /* Allocate a n*n matrix and fill it. */
    n = v->dim_size[0];
    alloc_integer_array(dest, 2, n, n);
    diagonal_integer_array_impl(v, dest);
}

void fill_integer_array(integer_array* dest,modelica_integer s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*dest);
    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, s);
    }
}

void linspace_integer_array(modelica_integer x1, modelica_integer x2, int n,
                            integer_array* dest)
{
    int i;

    /* Assert n>=2 */

    for(i = 0; i < (n - 1); ++i) {
        integer_set(dest, i, x1 + (((x2-x1)*(i-1))/(n-1)));
    }
}

modelica_integer max_integer_array(const integer_array a)
{
    size_t nr_of_elements;
    modelica_integer max_element = LONG_MIN;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    if(nr_of_elements > 0) {
        size_t i;
        max_element = integer_get(a, 0);
        for(i = 1; i < nr_of_elements; ++i) {
            if(max_element < integer_get(a, i)) {
                max_element = integer_get(a, i);
            }
        }
    }

    return max_element;
}

modelica_integer min_integer_array(const integer_array a)
{
  size_t nr_of_elements;
  modelica_integer min_element = LONG_MAX;

  omc_assert_macro(base_array_ok(&a));

  nr_of_elements = base_array_nr_of_elements(a);

  if(nr_of_elements > 0) {
    size_t i;
    min_element = integer_get(a, 0);
    for(i = 1; i < nr_of_elements; ++i) {
      if(min_element > integer_get(a, i)) {
        min_element = integer_get(a, i);
      }
    }
  }
  return min_element;
}

modelica_integer sum_integer_array(const integer_array a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_integer sum = 0;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    for(i = 0;i < nr_of_elements; ++i) {
        sum += integer_get(a, i);
    }

    return sum;
}

modelica_integer product_integer_array(const integer_array a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_integer product = 1;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    for(i = 0;i < nr_of_elements; ++i) {
        product *= integer_get(a, i);
    }

    return product;
}

void symmetric_integer_array(const integer_array * a,integer_array* dest)
{
    size_t i;
    size_t j;
    size_t nr_of_elements;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert that a is a two dimensional square array */
    omc_assert_macro((a->ndims == 2) && (a->dim_size[0] == a->dim_size[1]));
    /* Assert that dest is a two dimensional square array with the same size as a */
    omc_assert_macro((dest->ndims == 2) && (dest->dim_size[0] == dest->dim_size[1]) && (a->dim_size[0] == dest->dim_size[0]));

    for(i = 0; i < nr_of_elements; ++i) {
        for(j = 0; j < i; ++j) {
            integer_set(dest, (i * nr_of_elements) + j,
                        integer_get(*a, (j * nr_of_elements) + i));
        }
        for( ; j < nr_of_elements; ++j) {
            integer_set(dest, (i * nr_of_elements) + j,
                        integer_get(*a, (i * nr_of_elements) + j));
        }
    }
}

/* integer_array_make_index_array
 *
 * Creates an integer array of indices to be used by e.g.
 ** create_index_spec defined in index_spec.c
 */

_index_t* integer_array_make_index_array(const integer_array arr)
{
    return arr.data;
}

/* Converts the elements of an integer_array to int and packs them. I.e. if the
 * array element type is 64 bits and int is 32 bits then the data will be packed
 * in the first half of the array. */
void pack_integer_array(integer_array *a)
{
  if(sizeof(int) != sizeof(modelica_integer)) {
    long i;
    int * int_data = (int*)a->data;
    size_t n = base_array_nr_of_elements(*a);

    for(i = 0; i < n; ++i) {
      int_data[i] = (int)integer_get(*a, i);
    }
  }
}

/* Unpacks an integer_array that was packed with pack_integer_array */
void unpack_integer_array(integer_array *a)
{
  if(sizeof(int) != sizeof(modelica_integer)) {
    long i;
    int * int_data = (int*)a->data;
    long n = (long)base_array_nr_of_elements(*a);

    for(i = n - 1; i >= 0; --i) {
      integer_set(a, i, int_data[i]);
    }
  }
}

/* Returns a modelica_integer array that can be treated as an int array. If the
 * size of int and modelica_integer is the same this means simply returning the
 * given array, but if int is smaller than modelica_integer a new array is
 * allocated and filled with the data from given array as if it was an int array.
 *
 * I.e. if int is 32 bit and modelica_integer is 64 bit then the data will be
 * packed into the first half of the new array.
 *
 * The case where int is larger than modelica_integer is not implemented. */
void pack_alloc_integer_array(integer_array *a, integer_array *dest)
{
  if (sizeof(int) == sizeof(modelica_integer)) {
    *dest = *a;
  } else {
    /* We only handle the case where int is smaller than modelica_integer. */
    omc_assert_macro(sizeof(int) < sizeof(modelica_integer));

    /* Allocate a new array. */
    clone_integer_array_spec(a, dest);
    alloc_integer_array_data(dest);

    /* Pretend that the new array is an int array and fill it with the values
     * from the given array. */
    int *int_data = (int*)dest->data;
    long i;
    size_t n = base_array_nr_of_elements(*a);

    for (i = 0; i < n; ++i) {
      int_data[i] = (int)integer_get(*a, i);
    }
  }
}

/* Unpacks an integer_array that was packed with pack_integer_array into the
 * destination array. If packing hasn't been done, i.e. if the size of int and
 * modelica_integer is the same, then the function does nothing since both the
 * source and destination is assumed to be the same array. */
void unpack_copy_integer_array(const integer_array *a, integer_array *dest)
{
  if(sizeof(int) != sizeof(modelica_integer)) {
    long i;
    const int * int_data = (const int*)a->data;
    long n = (long)base_array_nr_of_elements(*a);

    for(i = n - 1; i >= 0; --i) {
      integer_set(dest, i, int_data[i]);
    }
  }
}

void convert_alloc_integer_array_to_f77(const integer_array * a,
                                        integer_array* dest)
{
    int i;
    clone_reverse_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    transpose_integer_array (a,dest);

    /* Assume that external fortran functions use int, and pack the array if
     * needed. */
    pack_integer_array(dest);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
}

void convert_alloc_integer_array_from_f77(const integer_array * a,
                                          integer_array* dest)
{
    int i;
    clone_reverse_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    for(i = 0; i < dest->ndims; ++i) {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_integer_array (a,dest);

    /* Unpack the array if needed */
    unpack_integer_array(dest);
}

void sizes_of_dimensions_base_array(const base_array_t *a, integer_array *dest)
{
  int i = ndims_base_array(a);
  simple_alloc_1d_integer_array(dest, i);
  while(i--) {
    integer_set(dest, i, a->dim_size[i]);
  }
}
