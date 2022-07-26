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


#include "boolean_array.h"
#include "../gc/omc_gc.h"
#include "omc_error.h"
#include "generic_array.h"


#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>


modelica_boolean boolean_get(const boolean_array a, size_t i)
{
    return ((modelica_boolean *) a.data)[i];
}

modelica_boolean boolean_get_2D(const boolean_array a, size_t i, size_t j)
{
    return boolean_get(a, getIndex_2D(a.dim_size,i,j));
}

modelica_boolean boolean_get_3D(const boolean_array a, size_t i, size_t j, size_t k)
{
    return boolean_get(a, getIndex_3D(a.dim_size,i,j,k));
}

modelica_boolean boolean_get_4D(const boolean_array a, size_t i, size_t j, size_t k, size_t l)
{
    return boolean_get(a, getIndex_4D(a.dim_size,i,j,k,l));
}

modelica_boolean boolean_get_5D(const boolean_array a, size_t i, size_t j, size_t k, size_t l, size_t m)
{
    return boolean_get(a, getIndex_5D(a.dim_size,i,j,k,l,m));
}


static inline modelica_boolean *boolean_ptrget(const boolean_array *a, size_t i)
{
    return ((modelica_boolean *) a->data) + i;
}

static inline void boolean_set(boolean_array *a, size_t i, modelica_boolean r)
{
    ((modelica_boolean *) a->data)[i] = r;
}

/** function: boolean_array_create
 **
 ** sets all fields in a boolean_array, i.e. data, ndims and dim_size.
 **/

void boolean_array_create(boolean_array *dest, modelica_boolean *data,
                          int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}

void simple_alloc_1d_boolean_array(boolean_array* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, boolean_alloc(n));
}

void simple_alloc_2d_boolean_array(boolean_array* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, boolean_alloc(r * c));
}

void alloc_boolean_array(boolean_array *dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = boolean_alloc(elements);
}

void alloc_boolean_array_data(boolean_array* a)
{
    a->data = boolean_alloc(base_array_nr_of_elements(*a));
}

void and_boolean_array(const boolean_array *source1, const boolean_array *source2, boolean_array *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source1));
    assert(base_array_ok(source2));
    assert(base_array_shape_eq(source1, source2));

    clone_base_array_spec(source1, dest);
    // assert(base_array_ok(dest));
    // assert(base_array_shape_eq(source1, dest));
    alloc_boolean_array_data(dest);


    nr_of_elements = base_array_nr_of_elements(*source1);

    for(i = 0; i < nr_of_elements; ++i) {
        boolean_set(dest, i, boolean_get(*source1, i) && boolean_get(*source2, i));
    }
}

void or_boolean_array(const boolean_array *source1, const boolean_array *source2, boolean_array *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source1));
    assert(base_array_ok(source2));
    assert(base_array_shape_eq(source1, source2));

    clone_base_array_spec(source1, dest);
    // assert(base_array_ok(dest));
    // assert(base_array_shape_eq(source1, dest));
    alloc_boolean_array_data(dest);


    nr_of_elements = base_array_nr_of_elements(*source1);

    for(i = 0; i < nr_of_elements; ++i) {
        boolean_set(dest, i, boolean_get(*source1, i) || boolean_get(*source2, i));
    }
}

void not_boolean_array(const boolean_array source, boolean_array *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(&source));

    clone_base_array_spec(&source, dest);
    alloc_boolean_array_data(dest);


    nr_of_elements = base_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        boolean_set(dest, i, !boolean_get(source, i));
    }
}

void copy_boolean_array_data_mem(const boolean_array source, modelica_boolean *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(&source));

    nr_of_elements = base_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = boolean_get(source, i);
    }
}

void copy_boolean_array(const boolean_array source, boolean_array *dest)
{
    boolean_array_alloc_copy(source,*dest);
}

/*
 a[1:3] := b;
*/

static inline modelica_boolean *calc_boolean_index_spec(int ndims, const _index_t* idx_vec,
                                                        const boolean_array *arr,
                                                        const index_spec_t *spec)
{
    return boolean_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_boolean *calc_boolean_index(int ndims, const _index_t *idx_vec,
                                     const boolean_array *arr)
{
    return boolean_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_boolean *calc_boolean_index_va(const boolean_array *source, int ndims,
                                        va_list ap)
{
    return boolean_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_boolean_matrix(const boolean_array *source)
{
    _index_t i,j;
    modelica_boolean value;

    if(source->ndims == 2) {
        printf("%d X %d matrix:\n", (int) source->dim_size[0], (int) source->dim_size[1]);
        for(i = 0; i < source->dim_size[0]; ++i) {
            for(j = 0; j < source->dim_size[1]; ++j) {
                value = boolean_get(*source, (i * source->dim_size[1]) + j);
                printf("%c\t", value ? 'T' : 'F');
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_boolean_array(const boolean_array *source)
{
    _index_t i,j;
    modelica_boolean *data;
    assert(base_array_ok(source));

    data = (modelica_boolean *) source->data;
    if(source->ndims == 1) {
        for(i = 1; i < source->dim_size[0]; ++i) {
            printf("%c, ", (*data) ? 'T' : 'F');
            ++data;
        }
        if(0 < source->dim_size[0]) {
            printf("%c", (*data) ? 'T' : 'F');
        }
    } else if(source->ndims > 1) {
        size_t k, n;
        n = base_array_nr_of_elements(*source) /
            (source->dim_size[0] * source->dim_size[1]);
        for(k = 0; k < n; ++k) {
            for(i = 0; i < source->dim_size[1]; ++i) {
                for(j = 0; j < source->dim_size[0]; ++j) {
                    printf("%c, ",(*data) ? 'T' : 'F');
                    ++data;
                }
                if(0 < source->dim_size[0]) {
                    printf("%c",(*data) ? 'T' : 'F');
                }
                printf("\n");
            }
            if((k + 1) < n) {
                printf("\n ================= \n");
            }
        }
    }
}

char print_boolean(modelica_boolean value)
{
    return value ? 'T' : 'F';
}

void put_boolean_element(modelica_boolean value, int i1, boolean_array *dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    boolean_set(dest, i1, value);
}

void put_boolean_matrix_element(modelica_boolean value, int r, int c,
                                boolean_array* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    boolean_set(dest, (r * dest->dim_size[1]) + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_boolean_array1(const boolean_array* source,
                                          int i1,
                                          boolean_array* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    boolean_set(dest, i1, boolean_get(*source, i1));
}

void simple_indexed_assign_boolean_array2(const boolean_array* source,
                                          int i1, int i2,
                                          boolean_array* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = (i1 * source->dim_size[1]) + i2;
    boolean_set(dest, index, boolean_get(*source, index));
}

void indexed_assign_boolean_array(const boolean_array source, boolean_array* dest,
                                  const index_spec_t* dest_spec)
{
    _index_t *idx_vec1, *idx_size;
    int j;
    indexed_assign_base_array_size_alloc(&source, dest, dest_spec, &idx_vec1, &idx_size);

    j = 0;
    do {
        boolean_set(dest,
                 calc_base_index_spec(dest->ndims, idx_vec1, dest, dest_spec),
                 boolean_get(source, j));
        j++;

    } while(0 == next_index(dest_spec->ndims, idx_vec1, idx_size));

    omc_assert_macro(j == base_array_nr_of_elements(source));
}

/*
 * function: index_boolean_array
 *
 * Returns an subscript of the source array in the destination array.
 * Assumes that both source array and destination array is properly
 * allocated.
 *
 * a := b[1:3];
 *
 */

void index_boolean_array(const boolean_array* source,
                         const index_spec_t* source_spec,
                         boolean_array* dest)
{
    _index_t* idx_vec1;
    _index_t* idx_vec2;
    _index_t* idx_size;
    int j;
    int i;

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

    idx_vec1 = size_alloc(source->ndims);  /*indices in the source array*/
    idx_vec2 = size_alloc(dest->ndims); /* indices in the destination array*/
    idx_size = size_alloc(source_spec->ndims);

    for(i = 0; i < source->ndims; ++i) {
        idx_vec1[i] = 0;
    }
    for(i = 0; i < source_spec->ndims; ++i) {
        if(source_spec->index[i]) {
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
                j++;
            }
        }

        boolean_set(dest, calc_base_index(dest->ndims, idx_vec2, dest),
                    boolean_get(*source,
                                calc_base_index_spec(source->ndims, idx_vec1,
                                                     source, source_spec)));

    } while(0 == next_index(source->ndims, idx_vec1, idx_size));
}

/*
 * function: index_alloc_boolean_array
 *
 * Returns an subscript of the source array in the destination array
 * in the same manner as index_boolean_array, except that the destination
 * array is allocated.
 *
 *
 * a := b[1:3];
 */

void index_alloc_boolean_array(const boolean_array* source,
                               const index_spec_t* source_spec,
                               boolean_array* dest)
{
    index_alloc_base_array_size(source, source_spec, dest);
    alloc_boolean_array_data(dest);
    index_boolean_array(source, source_spec, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_boolean_array1(const boolean_array* source, int i1,
                                       boolean_array* dest)
{
    int i;
    assert(base_array_ok(source));

    dest->ndims = source->ndims - 1;
    dest->dim_size = size_alloc(dest->ndims);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[i+1];
    }
    alloc_boolean_array_data(dest);

    simple_index_boolean_array1(source, i1, dest);
}

void simple_index_boolean_array1(const boolean_array* source, int i1,
                                 boolean_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * i1;

    assert(dest->ndims == (source->ndims - 1));

    for(i = 0 ; i < nr_of_elements ; i++) {
        boolean_set(dest, i, boolean_get(*source, off + i));
    }
}

void simple_index_boolean_array2(const boolean_array* source,
                                 int i1, int i2,
                                 boolean_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * ((source->dim_size[1] * i1) + i2);

    for(i = 0 ; i < nr_of_elements ; i++) {
        boolean_set(dest, i, boolean_get(*source, off + i));
    }
}

void array_boolean_array(boolean_array* dest,int n,boolean_array first,...)
{
    int i,j,c;
    va_list ap;

    boolean_array *elts=(boolean_array*)malloc(sizeof(boolean_array) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, boolean_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            boolean_set(dest, c, boolean_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

void array_alloc_boolean_array(boolean_array* dest, int n,
                               boolean_array first,...)
{
    int i,j,c;
    va_list ap;

    boolean_array *elts = (boolean_array*)malloc(sizeof(boolean_array) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, boolean_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    if(first.ndims == 1) {
        alloc_boolean_array(dest, 2, n, first.dim_size[0]);
    } else if(first.ndims == 2) {
        alloc_boolean_array(dest, 3, n, first.dim_size[0], first.dim_size[1]);
    } else if(first.ndims == 3) {
        alloc_boolean_array(dest, 4, n, first.dim_size[0],first.dim_size[1], first.dim_size[2]);
    } else if(first.ndims == 4) {
        alloc_boolean_array(dest, 5, n, first.dim_size[0], first.dim_size[1], first.dim_size[2], first.dim_size[3]);
    } else {
        assert(0 && "Dimension size > 4 not impl. yet");
    }

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            boolean_set(dest, c, boolean_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

/* array_alloc_scalar_boolean_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */

void array_alloc_scalar_boolean_array(boolean_array* dest, int n, ...)
{
    int i;
    va_list ap;
    simple_alloc_1d_boolean_array(dest,n);
    va_start(ap,n);
    for(i = 0; i < n; ++i) {
        put_boolean_element((modelica_boolean) va_arg(ap, int),i,dest);
    }
    va_end(ap);
}


/* function: cat_boolean_array
 *
 * Concatenates n boolean arrays along the k:th dimension.
 * k is one based
 */
void cat_boolean_array(int k, boolean_array* dest, int n,
                    const boolean_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const boolean_array **elts = (const boolean_array**)malloc(sizeof(boolean_array *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const boolean_array*);
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
                boolean_set(dest, j,
                            boolean_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/* function: cat_alloc_boolean_array
 *
 * Concatenates n boolean arrays along the k:th dimension.
 * allocates space in dest array
 * k is one based
 */
void cat_alloc_boolean_array(int k, boolean_array* dest, int n,
                          const boolean_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const boolean_array **elts = (const boolean_array**)malloc(sizeof(boolean_array *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const boolean_array*);
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
    dest->data = boolean_alloc( n_super * new_k_dim_size * n_sub);
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
                boolean_set(dest, j,
                            boolean_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/* function: promote_alloc_boolean_array
 *
 * Implementation of promote(A,n) same as promote_boolean_array except
 * that the destination array is allocated.
 */
void promote_alloc_boolean_array(const boolean_array* a, int n,
                                 boolean_array* dest)
{
    clone_boolean_array_spec(a,dest);
    alloc_boolean_array_data(dest);
    promote_boolean_array(a,n,dest);
}

/* function: promote_boolean_array.
 *
 * Implementation of promote(a,n)
 * Adds n onesized array dimensions to the array a to "the right of array dimensions".
 * For instance
 * promote_exp( {1,2},1) => {{1},{2}}
 * promote_exp( {1,2},2) => { {{1}},{{2}} }
*/
void promote_boolean_array(const boolean_array* a, int n,boolean_array* dest)
{
    int i;

    dest->dim_size = size_alloc(n+a->ndims);
    dest->data = a->data;
    /* Assert a->ndims>=n */
    for(i = 0; i < a->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
    for(i = a->ndims; i < (n+a->ndims); ++i) {
        dest->dim_size[i] = 1;
    }

    dest->ndims=n+a->ndims;
}

/* function: promote_scalar_boolean_array
 *
 * promotes a scalar value to an n dimensional array.
 */

void promote_scalar_boolean_array(modelica_boolean s,int n,
                                  boolean_array* dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = boolean_alloc(1);

    dest->ndims = n;
    boolean_set(dest, 0, s);

    for(i = 0; i < n; ++i) {
        dest->dim_size[i] = 1;
    }
}

void size_boolean_array(const boolean_array* a, integer_array* dest)
{
    /* This should be an integer array dest instead */
    int i;

    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == a->ndims);

    for(i = 0 ; i < a->ndims ; i++) {
        ((modelica_integer *) dest->data)[i] = a->dim_size[i];
    }
}

modelica_boolean scalar_boolean_array(const boolean_array* a)
{
    assert(base_array_ok(a));
    assert(base_array_one_element_ok(a));

    return boolean_get(*a, 0);
}

void vector_boolean_array(const boolean_array* a, boolean_array* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(*a);
    for(i = 0; i < nr_of_elements; ++i) {
        boolean_set(dest, i, boolean_get(*a, i));
    }
}

void vector_boolean_scalar(modelica_boolean a,boolean_array* dest)
{
    /* Assert that dest is a 1-vector */
    boolean_set(dest, 0, a);
}

void matrix_boolean_array(const boolean_array* a, boolean_array* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for(i = 0; i < cnt; ++i) {
        boolean_set(dest, i, boolean_get(*a, i));
    }
}

void matrix_boolean_scalar(modelica_boolean a, boolean_array* dest)
{
    dest->ndims = 2;
    dest->dim_size[0] = 1;
    dest->dim_size[1] = 1;
    boolean_set(dest, 0, a);
}

/* function: transpose_alloc_boolean_array
 *
 * Implementation of transpose(A) for matrix A. Same as transpose_boolean_array
 * except that destionation array is allocated.
 */

void transpose_alloc_boolean_array(const boolean_array* a, boolean_array* dest)
{
    clone_boolean_array_spec(a,dest); /* allocation*/

    /* transpose only valid for matrices.*/

    assert(a->ndims == 2);
    dest->dim_size[0]=a->dim_size[1];
    dest->dim_size[1]=a->dim_size[0];
    dest->ndims = 2;

    alloc_boolean_array_data(dest);
    transpose_boolean_array(a,dest);
}

/* function: transpose_boolean_array
 *
 * Implementation of transpose(A) for matrix A.
 */
void transpose_boolean_array(const boolean_array* a, boolean_array* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if(a->ndims == 1) {
        boolean_array_copy_data(*a, *dest);
        return;
    }

    assert(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    assert(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for(i = 0; i < n; ++i) {
        for(j = 0; j < m; ++j) {
            boolean_set(dest, (j*n)+i, boolean_get(*a, (i*m)+j));
        }
    }
}

void fill_boolean_array(boolean_array* dest,modelica_boolean s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*dest);
    for(i = 0; i < nr_of_elements; ++i) {
        boolean_set(dest, i, s);
    }
}

void convert_alloc_boolean_array_to_f77(const boolean_array* a,
                                        boolean_array* dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_boolean_array_data(dest);
    transpose_boolean_array(a, dest);
    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
}

void convert_alloc_boolean_array_from_f77(const boolean_array* a,
                                          boolean_array* dest)
{
    int i;
    clone_reverse_base_array_spec(a,dest);
    alloc_boolean_array_data(dest);
    for(i = 0; i < dest->ndims; ++i) {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_boolean_array(a, dest);
}

/* Fills an array with a value. */
void fill_alloc_boolean_array(boolean_array* dest, modelica_boolean value, int ndims, ...)
{
    size_t i;
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = boolean_alloc(elements);

    for(i = 0; i < elements; ++i) {
        boolean_set(dest, i, value);
    }
}

modelica_boolean min_boolean_array(const boolean_array a)
{
  size_t nr_of_elements;

  omc_assert_macro(base_array_ok(&a));
  nr_of_elements = base_array_nr_of_elements(a);

  size_t i;
  for (i = 0; i < nr_of_elements; ++i) {
    if (!boolean_get(a, i)) return 0;
  }

  return 1;
}

modelica_boolean max_boolean_array(const boolean_array a)
{
  size_t nr_of_elements;

  omc_assert_macro(base_array_ok(&a));
  nr_of_elements = base_array_nr_of_elements(a);

  size_t i;
  for (i = 0; i < nr_of_elements; ++i) {
    if (boolean_get(a, i)) return 1;
  }

  return 0;
}
