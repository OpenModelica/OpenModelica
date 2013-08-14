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
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


#include "integer_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include "division.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>
#include <math.h>

modelica_integer integer_get(const integer_array_t *a, size_t i)
{
    return ((modelica_integer *) a->data)[i];
}

/* Indexing 2 dimensions */
modelica_integer integer_get_2D(const integer_array_t *a, size_t i, size_t j)
{
  modelica_integer value = integer_get(a, (i * a->dim_size[1]) + j);
  return value;
}

/* Indexing 3 dimensions */
modelica_integer integer_get_3D(const integer_array_t *a, size_t i, size_t j, size_t k)
{
  modelica_integer value = integer_get(a, (i * a->dim_size[1] * a->dim_size[2])
                                        + (j * a->dim_size[2]) + k);
  return value;
}

/* Indexing 4 dimensions */
modelica_integer integer_get_4D(const integer_array_t *a, size_t i, size_t j, size_t k, size_t l)
{
  modelica_integer value = integer_get(a, (i * a->dim_size[1] * a->dim_size[2] * a->dim_size[3])
                                        + (j * a->dim_size[2] * a->dim_size[3])
                                        + (k * a->dim_size[3]) + l);
  return value;
}


static inline modelica_integer *integer_ptrget(const integer_array_t *a, size_t i)
{
    return ((modelica_integer *) a->data) + i;
}

static inline void integer_set(integer_array_t *a, size_t i, modelica_integer r)
{
    ((modelica_integer *) a->data)[i] = r;
}

/** function: integer_array_create
 **
 ** sets all fields in a integer_array, i.e. data, ndims and dim_size.
 **/
void integer_array_create(integer_array_t *dest, modelica_integer *data,
                          int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}


void simple_alloc_1d_integer_array(integer_array_t* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, integer_alloc(n));
}

void simple_alloc_2d_integer_array(integer_array_t* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, integer_alloc(r * c));
}

void alloc_integer_array(integer_array_t* dest,int ndims,...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = integer_alloc(elements);
}

void alloc_integer_array_data(integer_array_t* a)
{
    a->data = integer_alloc(base_array_nr_of_elements(a));
}

void copy_integer_array_data(const integer_array_t * source, integer_array_t* dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(base_array_shape_eq(source, dest));

    nr_of_elements = integer_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(source, i));
    }
}

void copy_integer_array_data_mem(const integer_array_t *source,
                                 modelica_integer *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));

    nr_of_elements = base_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = integer_get(source, i);
    }
}

void copy_integer_array(const integer_array_t *source, integer_array_t *dest)
{
    clone_base_array_spec(source, dest);
    alloc_integer_array_data(dest);
    copy_integer_array_data(source, dest);
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
void create_integer_array_from_range(integer_array_t *dest, modelica_integer start, modelica_integer step, modelica_integer stop)
{
    size_t elements;
    size_t i;
    modelica_integer (*comp_func)(modelica_integer, modelica_integer);

    assert(step != 0);

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
void fill_integer_array_from_range(integer_array_t *dest, modelica_integer start, modelica_integer step,
                                   modelica_integer stop/*, size_t dim*/)
{
    size_t elements;
    size_t i;
    modelica_integer value = start;
    modelica_integer (*comp_func)(modelica_integer, modelica_integer);

    assert(step != 0);

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
                                                        const integer_array_t * arr,
                                                        const index_spec_t* spec)
{
    return integer_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_integer* calc_integer_index(int ndims, const _index_t* idx_vec,
                                     const integer_array_t * arr)
{
    return integer_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_integer* calc_integer_index_va(const integer_array_t * source,int ndims,
                                        va_list ap)
{
    return integer_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_integer_matrix(const integer_array_t * source)
{
    _index_t i,j;
    modelica_integer value;

    if(source->ndims == 2) {
        printf("%d X %d matrix:\n", (int) source->dim_size[0], (int) source->dim_size[1]);
        for(i = 0; i < source->dim_size[0]; ++i) {
            for(j = 0; j < source->dim_size[1]; ++j) {
                value = integer_get(source, (i * source->dim_size[1]) + j);
                printf("%ld\t", value);
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_integer_array(const integer_array_t * source)
{
    size_t k, n;
    _index_t i,j;
    modelica_integer *data;
    assert(base_array_ok(source));

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
        n = base_array_nr_of_elements(source) /
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

void put_integer_element(modelica_integer value, int i1, integer_array_t* dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    integer_set(dest, i1, value);
}

void put_integer_matrix_element(modelica_integer value, int r, int c,
                                integer_array_t* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    integer_set(dest, (r * dest->dim_size[1]) + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_integer_array1(const integer_array_t * source,
                                          int i1,
                                          integer_array_t* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    integer_set(dest, i1, integer_get(source, i1));
}

void simple_indexed_assign_integer_array2(const integer_array_t * source,
                                          int i1, int i2,
                                          integer_array_t* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = (i1 * source->dim_size[1]) + i2;
    integer_set(dest, index, integer_get(source, index));
}

void indexed_assign_integer_array(const integer_array_t * source,
                                  integer_array_t* dest,
                                  const index_spec_t* dest_spec)
{
    _index_t* idx_vec1;
    _index_t* idx_vec2;
    _index_t* idx_size;
    int i,j;
    state mem_state;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(index_spec_ok(dest_spec));
    assert(index_spec_fit_base_array(dest_spec, dest));
    for(i = 0,j = 0; i < dest_spec->ndims; ++i) {
        if(dest_spec->dim_size[i] != 0) {
            ++j;
        }
    }
    assert(j == source->ndims);

    mem_state = get_memory_state();
    idx_vec1 = size_alloc(dest->ndims);
    idx_vec2 = size_alloc(source->ndims);
    idx_size = size_alloc(dest_spec->ndims);

    for(i = 0; i < dest_spec->ndims; ++i) {
        idx_vec1[i] = 0;

        if(dest_spec->index[i] != NULL) {
            idx_size[i] = imax(dest_spec->dim_size[i],1);
        } else {
            idx_size[i] = dest->dim_size[i];
        }
    }

    do {
        for(i = 0,j=0; i < dest_spec->ndims; ++i) {
            if(dest_spec->dim_size[i] != 0) {
                idx_vec2[j] = idx_vec1[i];
                ++j;
            }
        }

        integer_set(dest, calc_base_index_spec(dest->ndims, idx_vec1, dest,
                                               dest_spec),
                    integer_get(source, calc_base_index(source->ndims, idx_vec2,
                                                        source)));

    } while(0 == next_index(dest_spec->ndims, idx_vec1, idx_size));

    restore_memory_state(mem_state);
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

void index_integer_array(const integer_array_t * source,
                         const index_spec_t* source_spec,
                         integer_array_t* dest)
{
    _index_t* idx_vec1;
    _index_t* idx_vec2;
    _index_t* idx_size;
    int j;
    int i;
    state mem_state;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(index_spec_ok(source_spec));
    assert(index_spec_fit_base_array(source_spec,source));
    for(i = 0, j = 0; i < source->ndims; ++i) {
        if((source_spec->index_type[i] == 'W')
            ||
            (source_spec->index_type[i] == 'A')) {
            ++j;
        }
    }
    assert(j == dest->ndims);

    mem_state = get_memory_state();
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
                    integer_get(source,
                                calc_base_index_spec(source->ndims, idx_vec1,
                                                     source, source_spec)));

    } while(0 == next_index(source->ndims, idx_vec1, idx_size));

    restore_memory_state(mem_state);
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

void index_alloc_integer_array(const integer_array_t * source,
             const index_spec_t* source_spec,
             integer_array_t* dest)
{
    int i;
    int j;
    int ndimsdiff;

    assert(base_array_ok(source));
    assert(index_spec_ok(source_spec));
    assert(index_spec_fit_base_array(source_spec,source));

    ndimsdiff = 0;
    for(i = 0; i < source_spec->ndims; ++i) {
        if((source_spec->index_type[i] == 'W')
            ||
            (source_spec->index_type[i]== 'A')) {
            ndimsdiff--;
        }
    }

    dest->ndims = source->ndims + ndimsdiff;
    dest->dim_size = size_alloc(dest->ndims);

    for(i = 0,j = 0; i < dest->ndims; ++i) {
        while(source_spec->index_type[i+j] == 'S') { /* Skip scalars */
            j++;
        }
        if(source_spec->index_type[i+j] == 'W') { /*take whole dimension from source*/
            dest->dim_size[i]=source->dim_size[i+j];
        } else if(source_spec->index_type[i+j] == 'A') { /* Take dimension size from splice*/
            dest->dim_size[i]=source_spec->dim_size[i+j];
        }
    }

    alloc_integer_array_data(dest);
    index_integer_array(source, source_spec, dest);
}

/* idx(a[i,j,k]) = i * a->dim_size[1] * a->dim_size[2] + j * a->dim_size[2] + k */
/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_integer_array1(const integer_array_t * source, int i1,
                                       integer_array_t* dest)
{
    int i;
    assert(base_array_ok(source));

    dest->ndims = source->ndims - 1;
    dest->dim_size = size_alloc(dest->ndims);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[i+1];
    }
    alloc_integer_array_data(dest);

    simple_index_integer_array1(source, i1, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_integer_array1(const integer_array_t * source,
                                 int i1,
                                 integer_array_t* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(dest);
    size_t off = nr_of_elements * i1;

    assert(dest->ndims == (source->ndims - 1));

    for(i = 0 ; i < nr_of_elements ; i++) {
        integer_set(dest, i, integer_get(source, off + i));
    }
}

/* Returns dest := source[i1,i2,:,:...]*/
void simple_index_integer_array2(const integer_array_t * source,
                                 int i1, int i2,
                                 integer_array_t* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(dest);
    size_t off = nr_of_elements * ((source->dim_size[1] * i1) + i2);

    for(i = 0 ; i < nr_of_elements ; i++) {
        integer_set(dest, i, integer_get(source, off + i));
    }
}

void array_integer_array(integer_array_t* dest,int n,integer_array_t* first,...)
{
    int i,j,c,m;
    va_list ap;

    integer_array_t **elts=(integer_array_t**)malloc(sizeof(integer_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, integer_array_t*);
    }
    va_end(ap);

    check_base_array_dim_sizes((const base_array_t **)elts,n);

    for(i = 0, c = 0; i < n; ++i) {
        m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            integer_set(dest, c, integer_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

void array_alloc_integer_array(integer_array_t* dest,int n,
                               integer_array_t* first,...)
{
    int i,j,c,m;
    va_list ap;

    integer_array_t **elts=(integer_array_t**)malloc(sizeof(integer_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, integer_array_t*);
    }
    va_end(ap);

    check_base_array_dim_sizes((const base_array_t **)elts,n);

    if(first->ndims == 1) {
        alloc_integer_array(dest,2,n,first->dim_size[0]);
    } else if(first->ndims == 2) {
        alloc_integer_array(dest,3,n,first->dim_size[0],first->dim_size[1]);
    } else if(first->ndims == 3) {
        alloc_integer_array(dest,4,n,first->dim_size[0],first->dim_size[1],
                            first->dim_size[2]);
    } else if(first->ndims == 4) {
        alloc_integer_array(dest,5,n,first->dim_size[0],first->dim_size[1],
                            first->dim_size[2],first->dim_size[3]);
    } else {
        assert(0 && "Dimension size > 4 not impl. yet");
    }

    for(i = 0, c = 0; i < n; ++i) {
        m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            integer_set(dest, c, integer_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

void array_scalar_integer_array(integer_array_t* dest,int n,
                                modelica_integer first,...)
{
    int i;
    va_list ap;
    assert(base_array_ok(dest));
    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == n);
    put_integer_element(first, 0, dest);
    va_start(ap,first);
    for(i = 0; i < n; ++i) {
        put_integer_element(va_arg(ap, modelica_integer),i,dest);
    }
    va_end(ap);
}

/* array_alloc_scalar_integer_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */
void array_alloc_scalar_integer_array(integer_array_t* dest, int n,
                                      modelica_integer first,...)
{
    int i;
    va_list ap;
    simple_alloc_1d_integer_array(dest,n);
    va_start(ap,first);
    put_integer_element(first,0,dest);
    for(i = 1; i < n; ++i) {
        put_integer_element(va_arg(ap, m_integer),i,dest);
    }
    va_end(ap);
}

modelica_integer* integer_array_element_addr1(const integer_array_t * source,
                                              int ndims,int dim1)
{
    return integer_ptrget(source, dim1 - 1);
}

modelica_integer* integer_array_element_addr2(const integer_array_t * source,int ndims,int dim1,int dim2)
{
    return integer_ptrget(source, ((dim1 - 1) * source->dim_size[1]) + (dim2 - 1));
}

modelica_integer* integer_array_element_addr(const integer_array_t * source,int ndims,...)
{
    va_list ap;
    m_integer* tmp;

    va_start(ap,ndims);
    tmp = integer_ptrget(source, calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}

/* function: cat_integer_array
 *
 * Concatenates n integer arrays along the k:th dimension.
 * k is one based
 */
void cat_integer_array(int k, integer_array_t* dest, int n,
                    integer_array_t* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    integer_array_t **elts = (integer_array_t**)malloc(sizeof(integer_array_t *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,integer_array_t*);
    }
    va_end(ap);

    /* check dim sizes of all inputs and dest */
    assert(elts[0]->ndims >= k);
    for(i = 0; i < n; i++) {
        assert(dest->ndims == elts[i]->ndims);
        for(j = 0; j < (k - 1); j++) {
            assert(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k-1];
        for(j = k; j < elts[0]->ndims; j++) {
            assert(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
    }
    assert(dest->dim_size[k-1] == new_k_dim_size);

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
                            integer_get(elts[c], r + (i * n_sub_k)));
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
void cat_alloc_integer_array(int k, integer_array_t* dest, int n,
                          integer_array_t* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    integer_array_t **elts = (integer_array_t**)malloc(sizeof(integer_array_t *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,integer_array_t*);
    }
    va_end(ap);

    /* check dim sizes of all inputs */
    assert(elts[0]->ndims >= k);
    new_k_dim_size = elts[0]->dim_size[k-1];
    for(i = 1; i < n; i++) {
        assert(elts[0]->ndims == elts[i]->ndims);
        for(j = 0; j < (k - 1); j++) {
            assert(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k-1];
        for(j = k; j < elts[0]->ndims; j++) {
            assert(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
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
                            integer_get(elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

void range_alloc_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array_t* dest)
{
    int n;

    n = (int)floor((stop-start)/inc)+1;
    simple_alloc_1d_integer_array(dest,n);
    range_integer_array(start,stop,inc,dest);
}

void range_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array_t* dest)
{
    size_t i;
    /* Assert that dest has correct size */
    for(i = 0; i < dest->dim_size[0]; ++i) {
        integer_set(dest, i, start + (i * inc));
    }
}

void add_integer_array(const integer_array_t * a, const integer_array_t * b, integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert a and b are of the same size */
    assert(integer_array_nr_of_elements(b) == nr_of_elements);
    /* Assert that dest are of correct size */
    assert(integer_array_nr_of_elements(dest) == nr_of_elements);

    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(a, i)+integer_get(b, i));
    }
}

void add_alloc_integer_array(const integer_array_t * a, const integer_array_t * b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    add_integer_array(a,b,dest);
}

void sub_integer_array(const integer_array_t * a, const integer_array_t * b, integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert a and b are of the same size */
    assert(integer_array_nr_of_elements(b) == nr_of_elements);
    /* Assert that dest are of correct size */
    assert(integer_array_nr_of_elements(dest) == nr_of_elements);

    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(a, i)-integer_get(b, i));
    }
}

void sub_integer_array_data_mem(const integer_array_t * a, const integer_array_t * b,
                                modelica_integer* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert a and b are of the same size */
    assert(integer_array_nr_of_elements(b) == nr_of_elements);
    /* Assert that dest are of correct size */

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = integer_get(a, i) - integer_get(b, i);
    }
}

void sub_alloc_integer_array(const integer_array_t * a, const integer_array_t * b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    sub_integer_array(a,b,dest);
}

void mul_scalar_integer_array(modelica_integer a,const integer_array_t * b,integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(b);

    /* Assert that dest has correct size*/
    assert(integer_array_nr_of_elements(dest) == nr_of_elements);

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, a * integer_get(b, i));
    }
}

void mul_alloc_scalar_integer_array(modelica_integer a, const integer_array_t * b, integer_array_t* dest)
{
    clone_integer_array_spec(b,dest);
    alloc_integer_array_data(dest);
    mul_scalar_integer_array(a,b,dest);
}

void mul_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert that dest has correct size*/
    assert(integer_array_nr_of_elements(dest) == nr_of_elements);

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(a, i) * b);
    }
}

void mul_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    mul_integer_array_scalar(a,b,dest);
}


modelica_integer mul_integer_scalar_product(const integer_array_t * a, const integer_array_t * b)
{
    size_t nr_of_elements;
    size_t i;
    modelica_integer res;

    /* Assert that a and b are vectors */
    assert(a->ndims == 1);
    assert(b->ndims == 1);
    /* Assert that vectors are of matching size */
    assert(a->dim_size[0] == b->dim_size[0]);

    nr_of_elements = integer_array_nr_of_elements(a);
    res = 0;
    for(i = 0; i < nr_of_elements; ++i) {
        res += integer_get(a, i)*integer_get(b, i);
    }
    return res;
}

void mul_integer_matrix_product(const integer_array_t * a,const integer_array_t * b,integer_array_t* dest)
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
                tmp += integer_get(a, (i * k_size) + k)*integer_get(b, (k * j_size) + j);
            }
            integer_set(dest, (i * j_size) + j, tmp);
        }
    }
}

void mul_integer_matrix_vector(const integer_array_t * a, const integer_array_t * b,integer_array_t* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_integer tmp;

    /* Assert a matrix */
    assert(a->ndims == 2);
    /* Assert b vector */
    assert(b->ndims == 1);
    /* Assert dest correct size (a vector)*/
    assert(dest->ndims == 1);

    i_size = a->dim_size[0];
    j_size = a->dim_size[1];

    for(i = 0; i < i_size; ++i) {
        tmp = 0;
        for(j = 0; j < j_size; ++j) {
            tmp += integer_get(a, (i * j_size) + j)*integer_get(b, j);
        }
        integer_set(dest, i, tmp);
    }
}


void mul_integer_vector_matrix(const integer_array_t * a, const integer_array_t * b,integer_array_t* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_integer tmp;

    /* Assert a vector */
    assert(a->ndims == 1);
    /* Assert b matrix */
    assert(b->ndims == 2);
    /* Assert dest vector of correct size */

    i_size = a->dim_size[0];
    j_size = b->dim_size[1];

    for(i = 0; i < i_size; ++i) {
        tmp = 0;
        for(j = 0; j < j_size; ++j) {
            tmp += integer_get(a, j) * integer_get(b, (j * j_size) + i);
        }
        integer_set(dest, i, tmp);
    }
}

void mul_alloc_integer_matrix_product_smart(const integer_array_t * a, const integer_array_t * b, integer_array_t* dest)
{
    if((a->ndims == 1) && (b->ndims == 2)) {
        simple_alloc_1d_integer_array(dest,b->dim_size[1]);
        mul_integer_vector_matrix(a,b,dest);
    } else if((a->ndims == 2) && (b->ndims == 1)) {
        simple_alloc_1d_integer_array(dest,a->dim_size[0]);
        mul_integer_matrix_vector(a,b,dest);
    } else if((a->ndims == 2) && (b->ndims == 2)) {
        simple_alloc_2d_integer_array(dest,a->dim_size[0],b->dim_size[1]);
        mul_integer_matrix_product(a,b,dest);
    } else {
        printf("Invalid size of matrix\n");
    }
}

void div_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert that dest has correct size*/
    assert(nr_of_elements == base_array_nr_of_elements(dest));

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(a, i)/b);
    }
}

void div_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    div_integer_array_scalar(a,b,dest);
}

void division_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest, const char* division_str)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert that dest has correct size*/
    assert(nr_of_elements == base_array_nr_of_elements(dest));

    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, (modelica_integer)DIVISIONNOTIME(integer_get(a, i),b,division_str));
    }
}

void division_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,integer_array_t* dest, const char* division_str)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    division_integer_array_scalar(a,b,dest,division_str);
}

void div_scalar_integer_array(modelica_integer a, const integer_array_t* b, integer_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(b);
    for(i=0; i < nr_of_elements; ++i) {
        integer_set(dest, i, a / integer_get(b, i));
    }
}

void div_alloc_scalar_integer_array(modelica_integer a, const integer_array_t* b, integer_array_t* dest)
{
    clone_integer_array_spec(b,dest);
    alloc_integer_array_data(dest);
    div_scalar_integer_array(a,b,dest);
}

void pow_integer_array_scalar(const integer_array_t *a, modelica_integer b, integer_array_t* dest)
{
  size_t nr_of_elements = base_array_nr_of_elements(a);
  size_t i;

  assert(nr_of_elements == base_array_nr_of_elements(dest));

  for(i = 0; i < nr_of_elements; ++i) {
    integer_set(dest, i, (modelica_integer)pow(integer_get(a, i), b));
  }
}

void pow_alloc_integer_array_scalar(const integer_array* a, modelica_integer b, integer_array_t* dest)
{
  clone_integer_array_spec(a, dest);
  alloc_integer_array_data(dest);
  pow_integer_array_scalar(a, b, dest);
}

void exp_integer_array(const integer_array_t * a, modelica_integer n, integer_array_t* dest)
{
    modelica_integer i;

    /* Assert n>=0 */
    assert(n >= 0);
    /* Assert that a is a two dimensional square array */
    assert((a->ndims == 2) && (a->dim_size[0] == a->dim_size[1]));
    /* Assert that dest is a two dimensional square array with the same size as a */
    assert((dest->ndims == 2) && (dest->dim_size[0] == dest->dim_size[1]) && (a->dim_size[0] == dest->dim_size[0]));

    if(n==0) {
        identity_integer_array(a->dim_size[0],dest);
    } else {
        if(n==1) {
            clone_integer_array_spec(a,dest);
            copy_integer_array_data(a,dest);
  } else {
            integer_array_t* tmp = 0;
            clone_integer_array_spec(a,tmp);
            copy_integer_array_data(a,tmp);
            for( i = 1; i < n; ++i) {
                mul_integer_matrix_product(a,tmp,dest);
                copy_integer_array_data(dest,tmp);
      }
  }
    }
}

void exp_alloc_integer_array(const integer_array_t * a,modelica_integer b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
    alloc_integer_array_data(dest);
    exp_integer_array(a,b,dest);
}

/* function: promote_alloc_integer_array
 *
 * Implementation of promote(A,n) same as promote_integer_array except
 * that the destination array is allocated.
 */
void promote_alloc_integer_array(const integer_array_t * a, int n, integer_array_t* dest)
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
void promote_integer_array(const integer_array_t * a, int n,integer_array_t* dest)
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
void promote_scalar_integer_array(modelica_integer s,int n,integer_array_t* dest)
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
void size_integer_array(const integer_array_t * a, integer_array_t* dest)
{
    int i;

    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == a->ndims);

    for(i = 0 ; i < a->ndims ; i++) {
        integer_set(dest, i, a->dim_size[i]);
    }
}

modelica_integer scalar_integer_array(const integer_array_t * a)
{
    assert(base_array_ok(a));
    assert(base_array_one_element_ok(a));

    return integer_get(a, 0);
}

void vector_integer_array(const integer_array_t * a, integer_array_t* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = integer_array_nr_of_elements(a);
    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, integer_get(a, i));
    }
}

void vector_integer_scalar(modelica_integer a,integer_array_t* dest)
{
    /* Assert that dest is a 1-vector */
    integer_set(dest, 0, a);
}

void matrix_integer_array(const integer_array_t * a, integer_array_t* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for(i = 0; i < cnt; ++i) {
        integer_set(dest, i, integer_get(a, i));
    }
}

void matrix_integer_scalar(modelica_integer a,integer_array_t* dest)
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

void transpose_alloc_integer_array(const integer_array_t * a, integer_array_t* dest)
{
    clone_integer_array_spec(a,dest); /* allocation*/

    /* transpose only valid for matrices.*/

    assert(a->ndims == 2);
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
void transpose_integer_array(const integer_array_t * a, integer_array_t* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if(a->ndims == 1) {
        copy_integer_array_data(a,dest);
        return;
    }

    assert(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    assert(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for(i = 0; i < n; ++i) {
        for(j = 0; j < m; ++j) {
            integer_set(dest, (j * n) + i, integer_get(a, (i * m) + j));
        }
    }
}

void outer_product_integer_array(const integer_array_t * v1,const integer_array_t * v2, integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t number_of_elements_a;
  size_t number_of_elements_b;

  number_of_elements_a = base_array_nr_of_elements(v1);
  number_of_elements_b = base_array_nr_of_elements(v2);

  /* Assert a is a vector */
  /* Assert b is a vector */

  for(i = 0; i < number_of_elements_a; ++i) {
    for(j = 0; i < number_of_elements_b; ++j) {
      integer_set(dest, (i * number_of_elements_b) + j, integer_get(v1, i)*integer_get(v2, j));
    }
  }
}

void outer_product_alloc_integer_array(const integer_array_t* v1, const integer_array_t* v2, integer_array_t* dest)
{
  size_t dim1,dim2;
  assert(base_array_ok(v1));
  dim1 = base_array_nr_of_elements(v1);
  dim2 = base_array_nr_of_elements(v2);
  alloc_integer_array(dest,dim1,dim2);
  outer_product_integer_array(v1,v2,dest);
}

/* Fills an array with a value. */
void fill_alloc_integer_array(integer_array_t* dest, modelica_integer value, int ndims, ...)
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

void identity_integer_array(int n, integer_array_t* dest)
{
    int i;
    int j;

    assert(base_array_ok(dest));

    /* Check that dest size is ok */
    assert(dest->ndims==2);
    assert((dest->dim_size[0]==n) && (dest->dim_size[1]==n));

    for(i = 0; i < (n * n); ++i) {
        integer_set(dest, i, 0);
    }
    j = 0;
    for(i = 0; i < n; ++i) {
        integer_set(dest, j, 1);
        j += n+1;
    }
}

void identity_alloc_integer_array(int n,integer_array_t* dest)
{
    alloc_integer_array(dest,2,n,n);
    identity_integer_array(n,dest);
}

void diagonal_integer_array(const integer_array_t * v,integer_array_t* dest)
{
    size_t i;
    size_t j;
    size_t n;

    /* Assert that v is a vector */
    assert(v->ndims == 1);

    /* Assert that dest is a nxn matrix */
    n = v->dim_size[0];
    assert(dest->ndims == 2);
    assert((dest->dim_size[0] == n) && (dest->dim_size[1] == n));

    for(i = 0; i < (n * n); ++i) {
        integer_set(dest, i, 0);
    }
    j = 0;
    for(i = 0; i < n; ++i) {
        integer_set(dest, j, integer_get(v, i));
        j += n+1;
    }
}

void fill_integer_array(integer_array_t* dest,modelica_integer s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(dest);
    for(i = 0; i < nr_of_elements; ++i) {
        integer_set(dest, i, s);
    }
}

void linspace_integer_array(modelica_integer x1, modelica_integer x2, int n,
                            integer_array_t* dest)
{
    int i;

    /* Assert n>=2 */

    for(i = 0; i < (n - 1); ++i) {
        integer_set(dest, i, x1 + (((x2-x1)*(i-1))/(n-1)));
    }
}

modelica_integer max_integer_array(const integer_array_t * a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_integer max_element = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    if(nr_of_elements > 0) {
        max_element = integer_get(a, 0);
        for(i = 1; i < nr_of_elements; ++i) {
            if(max_element < integer_get(a, i)) {
                max_element = integer_get(a, i);
            }
        }
    }

    return max_element;
}

modelica_integer min_integer_array(const integer_array_t * a)
{
  size_t i;
  size_t nr_of_elements;
  modelica_integer min_element = -LONG_MAX;

  assert(base_array_ok(a));

  nr_of_elements = base_array_nr_of_elements(a);

  if(nr_of_elements > 0) {
    min_element = integer_get(a, 0);
    for(i = 1; i < nr_of_elements; ++i) {
      if(min_element > integer_get(a, i)) {
        min_element = integer_get(a, i);
      }
    }
  }
  return min_element;
}

modelica_integer sum_integer_array(const integer_array_t * a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_integer sum = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    for(i = 0;i < nr_of_elements; ++i) {
        sum += integer_get(a, i);
    }

    return sum;
}

modelica_integer product_integer_array(const integer_array_t * a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_integer product = 1;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    for(i = 0;i < nr_of_elements; ++i) {
        product *= integer_get(a, i);
    }

    return product;
}

void symmetric_integer_array(const integer_array_t * a,integer_array_t* dest)
{
    size_t i;
    size_t j;
    size_t nr_of_elements;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert that a is a two dimensional square array */
    assert((a->ndims == 2) && (a->dim_size[0] == a->dim_size[1]));
    /* Assert that dest is a two dimensional square array with the same size as a */
    assert((dest->ndims == 2) && (dest->dim_size[0] == dest->dim_size[1]) && (a->dim_size[0] == dest->dim_size[0]));

    for(i = 0; i < nr_of_elements; ++i) {
        for(j = 0; j < i; ++j) {
            integer_set(dest, (i * nr_of_elements) + j,
                        integer_get(a, (j * nr_of_elements) + i));
        }
        for( ; j < nr_of_elements; ++j) {
            integer_set(dest, (i * nr_of_elements) + j,
                        integer_get(a, (i * nr_of_elements) + j));
        }
    }
}

void cross_integer_array(const integer_array_t * x,const integer_array_t * y, integer_array_t* dest)
{
    /* Assert x is vector of size 3 */
    assert((x->ndims == 1) && (x->dim_size[0] == 3));
    /* Assert y is vector of size 3 */
    assert((y->ndims == 1) && (y->dim_size[0] == 3));
    /* Assert dest is vector of size 3 */
    assert((dest->ndims == 1) && (dest->dim_size[0] == 3));

    integer_set(dest, 0, (integer_get(x,1) * integer_get(y,2))
                - (integer_get(x,2) * integer_get(y,1)));
    integer_set(dest, 1, (integer_get(x,2) * integer_get(y,0))
                - (integer_get(x,0) * integer_get(y,2)));
    integer_set(dest, 2, (integer_get(x,0) * integer_get(y,1))
                - (integer_get(x,1) * integer_get(y,0)));
}

void cross_alloc_integer_array(const integer_array_t * x,const integer_array_t * y,integer_array_t* dest)
{
    alloc_integer_array(dest,1,3);
    cross_integer_array(x,y,dest);
}

void skew_integer_array(const integer_array_t * x,integer_array_t* dest)
{
    /* Assert x is vector of size 3 */
    assert((x->ndims == 1) && (x->dim_size[0] == 3));
    /* Assert dest is 3x3 matrix */
    assert((dest->ndims == 2) && (dest->dim_size[0] == 3) && (dest->dim_size[1] == 3));

    integer_set(dest, 0, 0);
    integer_set(dest, 1, -integer_get(x, 2));
    integer_set(dest, 2, integer_get(x, 1));
    integer_set(dest, 3, integer_get(x, 2));
    integer_set(dest, 4, 0);
    integer_set(dest, 5, -integer_get(x, 0));
    integer_set(dest, 6, -integer_get(x, 1));
    integer_set(dest, 7, integer_get(x, 0));
    integer_set(dest, 8, 0);
}

/* integer_array_make_index_array
 *
 * Creates an integer array if indices to be used by e.g.
 ** create_index_spec defined in index_spec.c
 */

_index_t* integer_array_make_index_array(const integer_array_t *arr)
{
    return arr->data;
}

/* Converts the elements of an integer_array to int and packs them. I.e. if the
 * array element type is 64 bits and int is 32 bits then the data will be packed
 * in the first half of the array. */
void pack_integer_array(integer_array_t *a)
{
  size_t i, n;
  int *int_data;

  if(sizeof(int) != sizeof(modelica_integer)) {
    int_data = (int*)a->data;
    n = integer_array_nr_of_elements(a);

    for(i = 0; i < n; ++i) {
      int_data[i] = (int)integer_get(a, i);
    }
  }
}

/* Unpacks an integer_array that was packed with pack_integer_array */
void unpack_integer_array(integer_array_t *a)
{
  size_t n;
  long i;
  int *int_data;

  if(sizeof(int) != sizeof(modelica_integer)) {
    int_data = (int*)a->data;
    n = integer_array_nr_of_elements(a);

    for(i = n - 1; i >= 0; --i) {
      integer_set(a, i, int_data[i]);
    }
  }
}

void convert_alloc_integer_array_to_f77(const integer_array_t * a,
                                        integer_array_t* dest)
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

void convert_alloc_integer_array_from_f77(const integer_array_t * a,
                                          integer_array_t* dest)
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

void sizes_of_dimensions_base_array(const base_array_t *a, integer_array_t *dest)
{
  int i = ndims_base_array(a);
  simple_alloc_1d_integer_array(dest, i);
  while(i--) {
    integer_set(dest, i, a->dim_size[i]);
  }
}
