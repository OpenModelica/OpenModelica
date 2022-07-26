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


#include "string_array.h"
#include "../gc/omc_gc.h"
#include "index_spec.h"
#include "modelica_string.h"
#include "omc_error.h"
#include "generic_array.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

static inline modelica_string *string_ptrget(const string_array *a, size_t i)
{
    return ((modelica_string *) a->data) + i;
}

static inline void string_set(string_array *a, size_t i, modelica_string r)
{
    ((modelica_string *) a->data)[i] = r;
}

modelica_string string_get(const string_array a, size_t i)
{
    return ((modelica_string *) a.data)[i];
}

modelica_string string_get_2D(const string_array a, size_t i, size_t j)
{
  return string_get(a, getIndex_2D(a.dim_size,i,j));
}

modelica_string string_get_3D(const string_array a, size_t i, size_t j, size_t k)
{
  return string_get(a, getIndex_3D(a.dim_size,i,j,k));
}

modelica_string string_get_4D(const string_array a, size_t i, size_t j, size_t k, size_t l)
{
  return string_get(a, getIndex_4D(a.dim_size,i,j,k,l));
}

modelica_string string_get_5D(const string_array a, size_t i, size_t j, size_t k, size_t l, size_t m)
{
  return string_get(a, getIndex_5D(a.dim_size,i,j,k,l,m));
}


/** function: string_array_create
 **
 ** sets all fields in a string_array, i.e. data, ndims and dim_size.
 **/

void string_array_create(string_array *dest, modelica_string *data,
                         int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}

void simple_alloc_1d_string_array(string_array* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, string_alloc(n));
}

void simple_alloc_2d_string_array(string_array* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, string_alloc(r * c));
}

void alloc_string_array(string_array *dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = string_alloc(elements);
}

void alloc_string_array_data(string_array* a)
{
    a->data = string_alloc(base_array_nr_of_elements(*a));
}

void copy_string_array_data_mem(const string_array source, modelica_string *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(&source));

    nr_of_elements = base_array_nr_of_elements(source);

    for(i = 0; i < nr_of_elements; ++i) {
        dest[i] = string_get(*&source, i);
    }
}

void copy_string_array(const string_array source, string_array *dest)
{
    string_array_alloc_copy(source,*dest);
}

/*
 a[1:3] := b;
*/

static inline modelica_string *calc_string_index_spec(int ndims, const _index_t *idx_vec,
                                                        const string_array *arr,
                                                        const index_spec_t *spec)
{
    return string_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_string *calc_string_index(int ndims, const _index_t *idx_vec,
                                     const string_array *arr)
{
    return string_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_string *calc_string_index_va(const string_array *source, int ndims,
                                        va_list ap)
{
    return string_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_string_matrix(const string_array *source)
{
    if(source->ndims == 2) {
        _index_t i,j;
        modelica_string value;

        printf("%d X %d matrix:\n", (int) source->dim_size[0], (int) source->dim_size[1]);
        for(i = 0; i < source->dim_size[0]; ++i) {
            for(j = 0; j < source->dim_size[1]; ++j) {
                value = string_get(*source, (i * source->dim_size[1]) + j);
                printf("%s\t", MMC_STRINGDATA(value));
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_string_array(const string_array *source)
{
    _index_t i;
    modelica_string *data;
    assert(base_array_ok(source));

    data = (modelica_string *) source->data;
    if(source->ndims == 1) {
        for(i = 1; i < source->dim_size[0]; ++i) {
            printf("%s, ", MMC_STRINGDATA(*data));
            ++data;
        }
        if(0 < source->dim_size[0]) {
            printf("%s", MMC_STRINGDATA(*data));
        }
    } else if(source->ndims > 1) {
        size_t k, n;
        _index_t j;

        n = base_array_nr_of_elements(*source) /
            (source->dim_size[0] * source->dim_size[1]);
        for(k = 0; k < n; ++k) {
            for(i = 0; i < source->dim_size[1]; ++i) {
                for(j = 0; j < source->dim_size[0]; ++j) {
                    printf("%s, ", MMC_STRINGDATA(*data));
                    ++data;
                }
                if(0 < source->dim_size[0]) {
                    printf("%s", MMC_STRINGDATA(*data));
                }
                printf("\n");
            }
            if((k + 1) < n) {
                printf("\n ================= \n");
            }
        }
    }
}

void put_string_element(modelica_string value, int i1, string_array *dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    string_set(dest, i1, value);
}

void put_string_matrix_element(modelica_string value, int r, int c,
                               string_array* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    string_set(dest, (r * dest->dim_size[1]) + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_string_array1(const string_array * source,
                                         int i1,
                                         string_array* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    string_set(dest, i1, string_get(*source, i1));
}

void simple_indexed_assign_string_array2(const string_array * source,
                                         int i1, int i2,
                                         string_array* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = (i1 * source->dim_size[1]) + i2;
    string_set(dest, index, string_get(*source, index));
}

void indexed_assign_string_array(const string_array source,
                                 string_array* dest,
                                 const index_spec_t* dest_spec)
{
    _index_t *idx_vec1, *idx_size;
    int j;
    indexed_assign_base_array_size_alloc(&source, dest, dest_spec, &idx_vec1, &idx_size);

    j = 0;
    do {
        string_set(dest,
                 calc_base_index_spec(dest->ndims, idx_vec1, dest, dest_spec),
                 string_get(source, j));
        j++;

    } while(0 == next_index(dest_spec->ndims, idx_vec1, idx_size));

    omc_assert_macro(j == base_array_nr_of_elements(source));
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

void index_string_array(const string_array * source,
                        const index_spec_t* source_spec,
                        string_array* dest)
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
                j++;
            }
        }

        string_set(dest, calc_base_index(dest->ndims, idx_vec2, dest),
                   string_get(*source,
                              calc_base_index_spec(source->ndims, idx_vec1,
                                                   source, source_spec)));

    } while(0 == next_index(source->ndims, idx_vec1, idx_size));
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

void index_alloc_string_array(const string_array * source,
                              const index_spec_t* source_spec,
                              string_array* dest)
{
    index_alloc_base_array_size(source, source_spec, dest);
    alloc_string_array_data(dest);
    index_string_array(source, source_spec, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_string_array1(const string_array * source, int i1,
                                      string_array* dest)
{
    int i;
    assert(base_array_ok(source));

    dest->ndims = source->ndims - 1;
    dest->dim_size = size_alloc(dest->ndims);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[i+1];
    }
    alloc_string_array_data(dest);

    simple_index_string_array1(source, i1, dest);
}

void simple_index_string_array1(const string_array * source, int i1,
                                string_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * i1;

    assert(dest->ndims == (source->ndims - 1));

    for(i = 0 ; i < nr_of_elements ; i++) {
        string_set(dest, i, string_get(*source, off + i));
    }
}

void simple_index_string_array2(const string_array * source,
                                int i1, int i2,
                                string_array* dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * ((source->dim_size[1] * i1) + i2);

    for(i = 0 ; i < nr_of_elements ; i++) {
        string_set(dest, i, string_get(*source, off + i));
    }
}

void array_string_array(string_array* dest,int n,string_array first,...)
{
    int i,j,c;
    va_list ap;

    string_array *elts=(string_array*)malloc(sizeof(string_array) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, string_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            string_set(dest, c, string_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

void array_alloc_string_array(string_array* dest, int n,
                              string_array first,...)
{
    int i,j,c;
    va_list ap;

    string_array *elts = (string_array*)malloc(sizeof(string_array) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for(i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, string_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts, n);

    if(first.ndims == 1) {
        alloc_string_array(dest, 2, n, first.dim_size[0]);
    } else if(first.ndims == 2) {
        alloc_string_array(dest, 3, n, first.dim_size[0], first.dim_size[1]);
    } else if(first.ndims == 3) {
        alloc_string_array(dest, 4, n, first.dim_size[0], first.dim_size[1], first.dim_size[2]);
    } else if(first.ndims == 4) {
        alloc_string_array(dest, 5, n, first.dim_size[0], first.dim_size[1], first.dim_size[2], first.dim_size[3]);
    } else {
        assert(0 && "Dimension size > 4 not impl. yet");
    }

    for(i = 0, c = 0; i < n; ++i) {
        int m = base_array_nr_of_elements(elts[i]);
        for(j = 0; j < m; ++j) {
            string_set(dest, c, string_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

/* array_alloc_scalar_string_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */

void array_alloc_scalar_string_array(string_array* dest, int n,
                                     modelica_string first,...)
{
    int i;
    va_list ap;
    simple_alloc_1d_string_array(dest,n);
    va_start(ap,first);
    put_string_element(first,0,dest);
    for(i = 1; i < n; ++i) {
        put_string_element(va_arg(ap, modelica_string),i,dest);
    }
    va_end(ap);
}


/* function: cat_string_array
 *
 * Concatenates n string arrays along the k:th dimension.
 * k is one based
 */
void cat_string_array(int k, string_array* dest, int n,
                    const string_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const string_array **elts = (const string_array**)malloc(sizeof(string_array *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const string_array*);
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
                string_set(dest, j,
                            string_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/* function: cat_alloc_string_array
 *
 * Concatenates n string arrays along the k:th dimension.
 * allocates space in dest array
 * k is one based
 */
void cat_alloc_string_array(int k, string_array* dest, int n,
                          const string_array* first,...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const string_array **elts = (const string_array**)malloc(sizeof(string_array *) * n);

    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for(i = 1; i < n; i++) {
        elts[i] = va_arg(ap,const string_array*);
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
    dest->data = string_alloc( n_super * new_k_dim_size * n_sub);
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
                string_set(dest, j,
                            string_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/* function: promote_alloc_string_array
 *
 * Implementation of promote(A,n) same as promote_string_array except
 * that the destination array is allocated.
 */
void promote_alloc_string_array(const string_array * a, int n,
                                string_array* dest)
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
void promote_string_array(const string_array * a, int n,string_array* dest)
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

/* function: promote_scalar_string_array
 *
 * promotes a scalar value to an n dimensional array.
 */

void promote_scalar_string_array(modelica_string s,int n,
                                 string_array* dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = string_alloc(1);

    dest->ndims = n;
    string_set(dest, 0, s);

    for(i = 0; i < n; ++i) {
        dest->dim_size[i] = 1;
    }
}

/* return a vector of length ndims(a) containing the dimension sizes of a */
void size_string_array(const string_array * a, integer_array* dest)
{
    int i;

    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == a->ndims);

    for(i = 0 ; i < a->ndims ; i++) {
        ((modelica_integer *) dest->data)[i] = a->dim_size[i];
    }
}

modelica_string scalar_string_array(const string_array * a)
{
    assert(base_array_ok(a));
    assert(base_array_one_element_ok(a));

    return string_get(*a, 0);
}

void vector_string_array(const string_array * a, string_array* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(*a);
    for(i = 0; i < nr_of_elements; ++i) {
        string_set(dest, i, string_get(*a, i));
    }
}

void vector_string_scalar(modelica_string a,string_array* dest)
{
    /* Assert that dest is a 1-vector */
    string_set(dest, 0, a);
}

void matrix_string_array(const string_array * a, string_array* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for(i = 0; i < cnt; ++i) {
        string_set(dest, i, string_get(*a, i));
    }
}

void matrix_string_scalar(modelica_string a, string_array* dest)
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

void transpose_alloc_string_array(const string_array * a, string_array* dest)
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
void transpose_string_array(const string_array * a, string_array* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if(a->ndims == 1) {
        string_array_copy_data(*a, *dest);
        return;
    }

    assert(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    assert(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for(i = 0; i < n; ++i) {
        for(j = 0; j < m; ++j) {
            string_set(dest, (j * n) + i, string_get(*a, (i * m) + j));
        }
    }
}

void fill_string_array(string_array* dest,modelica_string s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*dest);
    for(i = 0; i < nr_of_elements; ++i) {
        string_set(dest, i, s);
    }
}

void convert_alloc_string_array_to_f77(const string_array * a,
                                       string_array* dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_string_array_data(dest);
    transpose_string_array(a, dest);
    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
}

void convert_alloc_string_array_from_f77(const string_array * a,
                                         string_array* dest)
{
    int i;
    clone_reverse_base_array_spec(a,dest);
    alloc_string_array_data(dest);
    for(i = 0; i < dest->ndims; ++i) {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_string_array(a, dest);
}

void fill_alloc_string_array(string_array* dest, modelica_string value, int ndims, ...)
{
  size_t i;
  size_t elements = 0;
  va_list ap;
  va_start(ap, ndims);
  elements = alloc_base_array(dest, ndims, ap);
  va_end(ap);
  dest->data = string_alloc(elements);

  for(i = 0; i < elements; ++i) {
      string_set(dest, i, value);
  }
}

const char** data_of_string_c89_array(const string_array a)
{
  long i;
  size_t sz = base_array_nr_of_elements(a);
  const char **res = (const char**) omc_alloc_interface.malloc(sz*sizeof(const char*));
  for (i=0; i<sz; i++) {
    res[i] = MMC_STRINGDATA(((void**)a.data)[i]);
  }
  return res;
}

void unpack_string_array(const string_array *a, const char **data)
{
  size_t sz = base_array_nr_of_elements(*a);
  long i;
  for (i=0; i<sz; i++) {
    ((void**)a->data)[i] = mmc_mk_scon(data[i]);
  }
}
