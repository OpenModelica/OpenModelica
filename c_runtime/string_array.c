/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "string_array.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

modelica_string_t string_get(string_array_t *a, size_t i)
{
    return ((modelica_string_t *) a->data)[i];
}

static inline modelica_string_t *string_ptrget(string_array_t *a, size_t i)
{
    return ((modelica_string_t *) a->data) + i;
}

static inline void string_set(string_array_t *a, size_t i, modelica_string_t r)
{
    ((modelica_string_t *) a->data)[i] = r;
}

/** function: string_array_create
 **
 ** sets all fields in a string_array, i.e. data, ndims and dim_size.
 **/

void string_array_create(string_array_t *dest, modelica_string_t *data,
                         int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}

void simple_alloc_1d_string_array(string_array_t* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, string_alloc(n));
}

void simple_alloc_2d_string_array(string_array_t* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, string_alloc(r * c));
}

void alloc_string_array(string_array_t *dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = string_alloc(elements);
}

void alloc_string_array_data(string_array_t* a)
{
    a->data = string_alloc(base_array_nr_of_elements(a));
}

void free_string_array_data(string_array_t* a)
{
    size_t array_size;
    assert(base_array_ok(a));
    array_size = base_array_nr_of_elements(a);
    string_free(array_size);
}

void copy_string_array_data(string_array_t *source, string_array_t *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(base_array_shape_eq(source, dest));

    nr_of_elements = base_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        string_set(dest, i, string_get(source, i));
    }
}

void copy_string_array_data_mem(string_array_t *source, modelica_string_t *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));

    nr_of_elements = base_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        dest[i] = string_get(source, i);
    }
}

void copy_string_array(string_array_t *source, string_array_t *dest)
{
    clone_base_array_spec(source, dest);
    alloc_string_array_data(dest);
    copy_string_array_data(source,dest);
}

/*
 a[1:3] := b;
*/

static inline modelica_string_t *calc_string_index_spec(int ndims, int *idx_vec,
                                                        string_array_t *arr,
                                                        index_spec_t *spec)
{
    return string_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_string_t *calc_string_index(int ndims, int *idx_vec,
                                     string_array_t *arr)
{
    return string_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_string_t *calc_string_index_va(string_array_t *source, int ndims,
                                        va_list ap)
{
    return string_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_string_matrix(string_array_t *source)
{
    size_t i,j;
    modelica_string_t value;

    if (source->ndims == 2) {
        printf("%d X %d matrix:\n", source->dim_size[0], source->dim_size[1]);
        for (i = 0; i < source->dim_size[0]; ++i) {
            for (j = 0; j < source->dim_size[1]; ++j) {
                value = string_get(source, i * source->dim_size[1] + j);
                printf("%s\t", value);
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_string_array(string_array_t *source)
{
    size_t i, j, k, n;
    modelica_string_t *data;
    assert(base_array_ok(source));

    data = (modelica_string_t *) source->data;
    if (source->ndims == 1) {
        for (i = 0; i < source->dim_size[0]; ++i) {
            printf("%s", (*data));
            ++data;
            if ((i + 1) < source->dim_size[0]) {
                printf(", ");
            }
        }
    } else if (source->ndims > 1) {
        n = base_array_nr_of_elements(source) /
            (source->dim_size[0] * source->dim_size[1]);
        for (k = 0; k < n; ++k) {
            for (i = 0; i < source->dim_size[1]; ++i) {
                for (j = 0; j < source->dim_size[0]; ++j) {
                    printf("%s", (*data));
                    ++data;
                    if ((j + 1) < source->dim_size[0]) {
                        printf(", ");
                    }
                }
                printf("\n");
            }
            if ((k + 1) < n) {
                printf("\n ================= \n");
            }
        }
    }
}

void put_string_element(modelica_string_t value, int i1, string_array_t *dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    string_set(dest, i1, value);
}

void put_string_matrix_element(modelica_string_t value, int r, int c,
                               string_array_t* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    string_set(dest, r * dest->dim_size[1] + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_string_array1(string_array_t* source,
                                         int i1,
                                         string_array_t* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    string_set(dest, i1, string_get(source, i1));
}

void simple_indexed_assign_string_array2(string_array_t* source,
                                         int i1, int i2,
                                         string_array_t* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = i1 * source->dim_size[1] + i2;
    string_set(dest, index, string_get(source, index));
}

void indexed_assign_string_array(string_array_t* source,
                                 string_array_t* dest,
                                 index_spec_t* dest_spec)
{
    int* idx_vec1;
    int* idx_vec2;
    int* idx_size;
    int quit;
    int i,j;
    state mem_state;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(index_spec_ok(dest_spec));
    assert(index_spec_fit_base_array(dest_spec, dest));
    for (i = 0,j = 0; i < dest_spec->ndims; ++i)
        if (dest_spec->dim_size[i] != 0) ++j;
    assert(j == source->ndims);

    mem_state = get_memory_state();
    idx_vec1 = size_alloc(dest->ndims);
    idx_vec2 = size_alloc(source->ndims);
    idx_size = size_alloc(dest_spec->ndims);

    for (i = 0; i < dest_spec->ndims; ++i) {
	idx_vec1[i] = 0;

	if (dest_spec->index[i])
            idx_size[i] = imax(dest_spec->dim_size[i],1);
	else
            idx_size[i] = dest->dim_size[i];
    }

    quit = 0;
    while (1) {
        for (i = 0, j = 0; i < dest_spec->ndims; ++i) {
            if (dest_spec->dim_size[i] != 0) {
                idx_vec2[j] = idx_vec1[i];
                ++j;
            }
        }
        string_set(dest, calc_base_index_spec(dest->ndims, idx_vec1,
                                              dest, dest_spec),
                   string_get(source, calc_base_index(source->ndims,
                                                      idx_vec2, source)));

        quit = next_index(dest_spec->ndims, idx_vec1, idx_size);

        if (quit) break;
    }

    restore_memory_state(mem_state);
}

/*
 * function: index_string_array
 *
 * Returns an subscript of the source array in the destination array.
 * Assumes that both source array and destination array is properly
 * allocated.
 *
 * a := b[1:3];
 *
 */

void index_string_array(string_array_t* source,
                        index_spec_t* source_spec,
                        string_array_t* dest)
{
    int* idx_vec1;
    int* idx_vec2;
    int* idx_size;
    int quit;
    int j;
    int i;
    state mem_state;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(index_spec_ok(source_spec));
    assert(index_spec_fit_base_array(source_spec,source));
    for (i = 0, j = 0; i < source->ndims; ++i)
        if ((source_spec->index_type[i] == 'W')
            ||
            (source_spec->index_type[i] == 'A'))
            ++j;
    assert(j == dest->ndims);

    mem_state = get_memory_state();
    idx_vec1 = size_alloc(source->ndims);  /*indices in the source array*/
    idx_vec2 = size_alloc(dest->ndims); /* indices in the destination array*/
    idx_size = size_alloc(source_spec->ndims);

    for (i = 0; i < source->ndims; ++i) idx_vec1[i] = 0;
    for (i = 0; i < source_spec->ndims; ++i) {
        if (source_spec->index[i])
            idx_size[i] = imax(source_spec->dim_size[i],1);
        else
            idx_size[i] = source->dim_size[i];
    }

    quit = 0;
    while (1) {
        for (i = 0, j = 0; i < source->ndims; ++i) {
            if ((source_spec->index_type[i] == 'W')
                ||
                (source_spec->index_type[i] == 'A')) {
                idx_vec2[j] = idx_vec1[i];
                j++;
            }
        }

        string_set(dest, calc_base_index(dest->ndims, idx_vec2, dest),
                   string_get(source,
                              calc_base_index_spec(source->ndims, idx_vec1,
                                                   source, source_spec)));

        quit = next_index(source->ndims, idx_vec1, idx_size);
        if (quit) break;
    }

    restore_memory_state(mem_state);
}

/*
 * function: index_alloc_string_array
 *
 * Returns an subscript of the source array in the destination array
 * in the same manner as index_string_array, except that the destination
 * array is allocated.
 *
 *
 * a := b[1:3];
 */

void index_alloc_string_array(string_array_t* source,
                              index_spec_t* source_spec,
                              string_array_t* dest)
{
    int i;
    int j;
    int ndimsdiff;

    assert(base_array_ok(source));
    assert(index_spec_ok(source_spec));
    assert(index_spec_fit_base_array(source_spec, source));

    ndimsdiff = 0;
    for (i = 0; i < source_spec->ndims; ++i) {
        if ((source_spec->index_type[i] == 'W')
            ||
            (source_spec->index_type[i] == 'A'))
            ndimsdiff--;
    }

    dest->ndims = source->ndims + ndimsdiff;
    dest->dim_size = size_alloc(dest->ndims);

    for (i = 0,j = 0; i < dest->ndims; ++i) {
        while (source_spec->index_type[i+j] == 'S') ++j; /* Skip scalars */
        if (source_spec->index_type[i+j] == 'W') { /*take whole dimension from source*/
            dest->dim_size[i]=source->dim_size[i+j];
        } else if (source_spec->index_type[i+j] == 'A') { /* Take dimension size from splice*/
            dest->dim_size[i]=source_spec->dim_size[i+j];
        }
    }

    alloc_string_array_data(dest);
    index_string_array(source, source_spec, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_string_array1(string_array_t* source, int i1,
                                      string_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void simple_index_string_array1(string_array_t* source, int i1,
                                string_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void simple_index_string_array2(string_array_t* source,
                                int i1, int i2,
                                string_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void array_string_array(string_array_t* dest,int n,string_array_t* first,...)
{
    assert(0 && "Not implemented yet");
}

void array_alloc_string_array(string_array_t* dest, int n,
                              string_array_t* first,...)
{
    int i,j,c,m;
    va_list ap;

    string_array_t **elts = malloc(sizeof(string_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for (i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, string_array_t*);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    if (first->ndims == 1) {
        alloc_string_array(dest,2,n,first->dim_size[0]);
    } else if (first->ndims == 2) {
        alloc_string_array(dest,3,n,first->dim_size[0],first->dim_size[1]);
    } else if (first->ndims == 3) {
        alloc_string_array(dest,4,n,first->dim_size[0],first->dim_size[1],
                           first->dim_size[2]);
    } else if (first->ndims == 4) {
        alloc_string_array(dest,5,n,first->dim_size[0],first->dim_size[1],
                           first->dim_size[2],first->dim_size[3]);
    } else {
        assert(0 && "Dimension size > 4 not impl. yet");
    }

    for (i = 0, c = 0; i < n; ++i) {
        m = base_array_nr_of_elements(elts[i]);
        for (j = 0; j < m; ++j) {
            string_set(dest, c++, string_get(elts[i], j));
        }
    }
    free(elts);
}

void array_scalar_string_array(string_array_t* dest, int n,
                               modelica_string_t first, ...)
{
    int i;
    va_list ap;
    assert(base_array_ok(dest));
    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == n);
    put_string_element(first, 0, dest);
    va_start(ap,first);
    for (i = 0; i < n; ++i) {
        put_string_element(va_arg(ap, modelica_string_t),i,dest);
    }
    va_end(ap);
}

/* array_alloc_scalar_string_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */

void array_alloc_scalar_string_array(string_array_t* dest, int n,
                                     modelica_string_t first,...)
{
    int i;
    va_list ap;
    simple_alloc_1d_string_array(dest,n);
    va_start(ap,first);
    put_string_element(first,0,dest);
    for (i = 1; i < n; ++i) {
        put_string_element(va_arg(ap, modelica_string_t),i,dest);
    }
    va_end(ap);
}

modelica_string_t* string_array_element_addr1(string_array_t* source,int ndims,
                                              int dim1)
{
    return string_ptrget(source, dim1 - 1);
}

modelica_string_t* string_array_element_addr2(string_array_t* source,int ndims,
                                              int dim1,int dim2)
{
    return string_ptrget(source, (dim1 - 1) * source->dim_size[1] + dim2-1);
}

modelica_string_t* string_array_element_addr(string_array_t* source,
                                             int ndims,...)
{
    va_list ap;
    modelica_string_t* tmp;

    va_start(ap,ndims);
    tmp = string_ptrget(source, calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}


void cat_string_array(int k, string_array_t* dest, int n,
                      string_array_t* first,...)
{
    assert(0 && "Not implemented yet");
}

/* function: cat_alloc_string_array
 *
 * Concatenates n string arrays along the k:th dimension.
 * Only works for 2 dimensional arrays.
 */
void cat_alloc_string_array(int k, string_array_t* dest, int n,
                            string_array_t* first,...)
{
    va_list ap;
    int i;
    int new_k_dim_size;
    string_array_t **elts = malloc(sizeof(string_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for (i = 1; i < n; i++) {
        elts[i] = va_arg(ap,string_array_t*);
    }
    va_end(ap);

    /* calculate new k:th dim size.*/
    new_k_dim_size = 0;
    for(i=0;i < n; i++) {
        assert(elts[i]->ndims >= k);
        new_k_dim_size += elts[i]->dim_size[k-1];
    }
    check_base_array_dim_sizes_except(k,elts,n);

    /* concatenation along first dimension */
    /* cat(1,[1,2;3,4],[5,6;7,8]) => [1,2;3,4;5,6;7,8]*/
    if (k == 1) {
        int r,c,j;
        int dim_size_2 = elts[0]->dim_size[1];
        dest->data = string_alloc(dim_size_2 * new_k_dim_size);
        dest->dim_size = size_alloc(2);
        dest->dim_size[0] = new_k_dim_size;
        dest->dim_size[1] = dim_size_2;
        dest->ndims = 2;

        for(i=0,j=0; i < n ; i++) {
            for(r=0; r < elts[i]->dim_size[0];r++) {
                for(c=0; c < elts[i]->dim_size[1];c++) {
                    string_set(dest, j++,
                               string_get(elts[i], c+r*elts[i]->dim_size[1]));
                }
            }
        }
    } /* concatenation along second dimension */
    /* cat(2,[1,2;3,4],[5,6;7,8]) => [1,2,5,6;3,4,7,8]*/
    else if (k == 2) {
        int r,c,j;
        int dim_size_1 = elts[0]->dim_size[0];
        dest->data = string_alloc(dim_size_1 * new_k_dim_size);
        dest->dim_size = size_alloc(2);
        dest->dim_size[0] = dim_size_1;
        dest->dim_size[1] = new_k_dim_size;
        dest->ndims = 2;

        for(r=0,j=0; r < elts[0]->dim_size[0];r++) {
            for(i=0; i < n ; i++) {
                for(c=0; c < elts[i]->dim_size[1];c++) {
                    string_set(dest, j++,
                               string_get(elts[i], c+r*elts[i]->dim_size[1]));
                }
            }
        }
    } else {
        assert(0&&"Only concatenation dimension 1 and 2 supported");
    }

    free(elts);
}

/* function: promote_alloc_string_array
 *
 * Implementation of promote(A,n) same as promote_string_array except
 * that the destination array is allocated.
 */
void promote_alloc_string_array(string_array_t* a, int n,
                                string_array_t* dest)
{
    clone_string_array_spec(a,dest);
    alloc_string_array_data(dest);
    promote_string_array(a,n,dest);
}

/* function: promote_string_array.
 *
 * Implementation of promote(a,n)
 * Adds n onesized array dimensions to the array a to "the right of array dimensions".
 * For instance
 * promote_exp( {1,2},1) => {{1},{2}}
 * promote_exp( {1,2},2) => { {{1}},{{2}} }
*/
void promote_string_array(string_array_t* a, int n,string_array_t* dest)
{
    int i;

    dest->dim_size = size_alloc(n+a->ndims);
    dest->data = a->data;
    /* Assert a->ndims>=n */
    for (i = 0; i < a->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
    for (i = a->ndims; i < n+a->ndims; ++i) {
        dest->dim_size[i] = 1;
    }

    dest->ndims=n+a->ndims;
}

/* function: promote_scalar_string_array
 *
 * promotes a scalar value to an n dimensional array.
 */

void promote_scalar_string_array(modelica_string_t s,int n,
                                 string_array_t* dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = string_alloc(1);

    dest->ndims = n;
    string_set(dest, 0, s);

    for (i = 0; i < n; ++i) {
        dest->dim_size[i] = 1;
    }
}

void size_string_array(string_array_t* a, string_array_t* dest)
{
    /* This should be an integer data instead */
    /*copy_integer_array_data(a->dim_size,dest); */
    /* Code below can't possibly do what it was supposed to do - x08joekl */
    /* dest = a; */
    assert(0&&"Not implemented.");
}

modelica_string_t scalar_string_array(string_array_t* a)
{
    assert(base_array_ok(a));
    assert(base_array_one_element_ok(a));

    return string_get(a, 0);
}

void vector_string_array(string_array_t* a, string_array_t* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(a);
    for (i = 0; i < nr_of_elements; ++i) {
        string_set(dest, i, string_get(a, i));
    }
}

void vector_string_scalar(modelica_string_t a,string_array_t* dest)
{
    /* Assert that dest is a 1-vector */
    string_set(dest, 0, a);
}

void matrix_string_array(string_array_t* a, string_array_t* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for (i = 0; i < cnt; ++i) {
        string_set(dest, i, string_get(a, i));
    }
}

void matrix_string_scalar(modelica_string_t a, string_array_t* dest)
{
    dest->ndims = 2;
    dest->dim_size[0] = 1;
    dest->dim_size[1] = 1;
    string_set(dest, 0, a);
}

/* function: transpose_alloc_string_array
 *
 * Implementation of transpose(A) for matrix A. Same as transpose_string_array
 * except that destionation array is allocated.
 */

void transpose_alloc_string_array(string_array_t* a, string_array_t* dest)
{
    clone_string_array_spec(a,dest); /* allocation*/

    /* transpose only valid for matrices.*/

    assert(a->ndims == 2);
    dest->dim_size[0]=a->dim_size[1];
    dest->dim_size[1]=a->dim_size[0];
    dest->ndims = 2;

    alloc_string_array_data(dest);
    transpose_string_array(a,dest);
}

/* function: transpose_string_array
 *
 * Implementation of transpose(A) for matrix A.
 */
void transpose_string_array(string_array_t* a, string_array_t* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if (a->ndims == 1) {
        copy_string_array_data(a,dest);
        return;
    }

    assert(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    assert(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for (i = 0; i < n; ++i) {
        for (j = 0; j < m; ++j) {
            string_set(dest, j*n+i, string_get(a, i*m+j));
        }
    }
}

void fill_string_array(string_array_t* dest,modelica_string_t s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(dest);
    for (i = 0; i < nr_of_elements; ++i) {
        string_set(dest, i, s);
    }
}

void convert_alloc_string_array_to_f77(string_array_t* a,
                                       string_array_t* dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_string_array_data(dest);
    transpose_string_array(a, dest);
    for (i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
}

void convert_alloc_string_array_from_f77(string_array_t* a,
                                         string_array_t* dest)
{
    int i;
    clone_reverse_base_array_spec(a,dest);
    alloc_string_array_data(dest);
    for (i = 0; i < dest->ndims; ++i) {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_string_array(a, dest);
}
