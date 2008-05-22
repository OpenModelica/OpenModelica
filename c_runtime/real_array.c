/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
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

#include "real_array.h"
#include "index_spec.h"
#include "memory_pool.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

static inline modelica_real real_get(real_array_t *a, size_t i)
{
    return ((modelica_real *) a->data)[i];
}

static inline modelica_real *real_ptrget(real_array_t *a, size_t i)
{
    return ((modelica_real *) a->data) + i;
}

static inline void real_set(real_array_t *a, size_t i, modelica_real r)
{
    ((modelica_real *) a->data)[i] = r;
}

/** function: real_array_create
 **
 ** sets all fields in a real_array, i.e. data, ndims and dim_size.
 **/

void real_array_create(real_array_t *dest, modelica_real *data, int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}

void simple_alloc_1d_real_array(real_array_t* dest, int n)
{
    simple_alloc_1d_base_array(dest, n, real_alloc(n));
}

void simple_alloc_2d_real_array(real_array_t* dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, real_alloc(r * c));
}

void alloc_real_array(real_array_t *dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = real_alloc(elements);
}

void alloc_real_array_data(real_array_t *a)
{
    a->data = real_alloc(base_array_nr_of_elements(a));
}

void free_real_array_data(real_array_t *a)
{
    size_t array_size;
    assert(base_array_ok(a));
    array_size = base_array_nr_of_elements(a);
    real_free(array_size);
}

void copy_real_array_data(real_array_t *source, real_array_t *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));
    assert(base_array_ok(dest));
    assert(base_array_shape_eq(source, dest));

    nr_of_elements = base_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(source, i));
    }
}

void copy_real_array_data_mem(real_array_t *source, modelica_real *dest)
{
    size_t i, nr_of_elements;

    assert(base_array_ok(source));

    nr_of_elements = base_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i) {
        dest[i] = real_get(source, i);
    }
}

void copy_real_array(real_array_t *source, real_array_t *dest)
{
    clone_base_array_spec(source, dest);
    alloc_real_array_data(dest);
    copy_real_array_data(source,dest);
}

/*
 a[1:3] := b;
*/

static inline modelica_real *calc_real_index_spec(int ndims, int *idx_vec,
                                                  real_array_t *arr,
                                                  index_spec_t *spec)
{
    return real_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/* Uses zero based indexing */
modelica_real *calc_real_index(int ndims, int *idx_vec, real_array_t *arr)
{
    return real_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/* One based index*/
modelica_real *calc_real_index_va(real_array_t *source, int ndims, va_list ap)
{
    return real_ptrget(source, calc_base_index_va(source, ndims, ap));
}

void print_real_matrix(real_array_t *source)
{
    size_t i,j;
    modelica_real value;

    if (source->ndims == 2) {
        printf("%d X %d matrix:\n", source->dim_size[0], source->dim_size[1]);
        for (i = 0; i < source->dim_size[0]; ++i) {
            for (j = 0; j < source->dim_size[1]; ++j) {
                value = real_get(source, i * source->dim_size[1] + j);
                printf("%e\t", value);
            }
            printf("\n");
        }
    } else {
        printf("array with %d dimensions\n", source->ndims);
    }
}

void print_real_array(real_array_t *source)
{
    size_t i, j, k, n;
    modelica_real *data;
    assert(base_array_ok(source));

    data = (modelica_real *) source->data;
    if (source->ndims == 1) {
        for (i = 0; i < source->dim_size[0]; ++i) {
            printf("%e",*data);
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
                    printf("%e",*data);
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

void put_real_element(m_real value, int i1, real_array_t *dest)
{
    /* Assert that dest has correct dimension */
    /* Assert that i1 is a valid index */
    real_set(dest, i1, value);
}

void put_real_matrix_element(m_real value, int r, int c, real_array_t* dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    real_set(dest, r * dest->dim_size[1] + c, value);
    /* printf("Index %d\n",r*dest->dim_size[1]+c); */
}

/* Zero based index */
void simple_indexed_assign_real_array1(real_array_t* source,
				       int i1,
				       real_array_t* dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    real_set(dest, i1, real_get(source, i1));
}

void simple_indexed_assign_real_array2(real_array_t* source,
				       int i1, int i2,
				       real_array_t* dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = i1 * source->dim_size[1] + i2;
    real_set(dest, index, real_get(source, index));
}

void indexed_assign_real_array(real_array_t* source,
			       real_array_t* dest,
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
        real_set(dest,
                 calc_base_index_spec(dest->ndims, idx_vec1, dest, dest_spec),
                 real_get(source,
                          calc_base_index(source->ndims, idx_vec2, source)));

	quit = next_index(dest_spec->ndims, idx_vec1, idx_size);

	if (quit) break;
    }

    restore_memory_state(mem_state);
}

/*
 * function: index_real_array
 *
 * Returns an subscript of the source array in the destination array.
 * Assumes that both source array and destination array is properly
 * allocated.
 *
 * a := b[1:3];
 *
 */

void index_real_array(real_array_t* source,
                      index_spec_t* source_spec,
		      real_array_t* dest)
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

        real_set(dest, calc_base_index(dest->ndims, idx_vec2, dest),
                 real_get(source,
                          calc_base_index_spec(source->ndims, idx_vec1,
                                               source, source_spec)));

        quit = next_index(source->ndims, idx_vec1, idx_size);
        if (quit) break;
    }

    restore_memory_state(mem_state);
}

/*
 * function: index_alloc_real_array
 *
 * Returns an subscript of the source array in the destination array
 * in the same manner as index_real_array, except that the destination
 * array is allocated.
 *
 *
 * a := b[1:3];
 */

void index_alloc_real_array(real_array_t* source,
                            index_spec_t* source_spec,
                            real_array_t* dest)
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

    alloc_real_array_data(dest);
    index_real_array(source, source_spec, dest);
}

/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_real_array1(real_array_t* source, int i1,
                                    real_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void simple_index_real_array1(real_array_t* source, int i1,
                              real_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void simple_index_real_array2(real_array_t* source,
                              int i1, int i2,
                              real_array_t* dest)
{
    assert(0 && "Not implemented yet");
}

void array_real_array(real_array_t* dest,int n,real_array_t* first,...)
{
    assert(0 && "Not implemented yet");
}

void array_alloc_real_array(real_array_t* dest, int n, real_array_t* first,...)
{
    int i,j,c,m;
    va_list ap;

    real_array_t **elts = malloc(sizeof(real_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap,first);
    elts[0] = first;
    for (i = 1; i < n; ++i) {
        elts[i] = va_arg(ap, real_array_t*);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts,n);

    if (first->ndims == 1) {
        alloc_real_array(dest,2,n,first->dim_size[0]);
    } else if (first->ndims == 2) {
        alloc_real_array(dest,3,n,first->dim_size[0],first->dim_size[1]);
    } else if (first->ndims == 3) {
        alloc_real_array(dest,4,n,first->dim_size[0],first->dim_size[1],
                         first->dim_size[2]);
    } else if (first->ndims == 4) {
        alloc_real_array(dest,5,n,first->dim_size[0],first->dim_size[1],
                         first->dim_size[2],first->dim_size[3]);
    } else {
        assert(0 && "Dimension size > 4 not impl. yet");
    }

    for (i = 0, c = 0; i < n; ++i) {
        m = base_array_nr_of_elements(elts[i]);
        for (j = 0; j < m; ++j) {
            real_set(dest, c++, real_get(elts[i], j));
        }
    }
    free(elts);
}

void array_scalar_real_array(real_array_t* dest, int n, m_real first, ...)
{
    int i;
    va_list ap;
    assert(base_array_ok(dest));
    assert(dest->ndims == 1);
    assert(dest->dim_size[0] == n);
    put_real_element(first, 0, dest);
    va_start(ap,first);
    for (i = 0; i < n; ++i) {
        put_real_element(va_arg(ap,m_real),i,dest);
    }
    va_end(ap);
}

/* array_alloc_scalar_real_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */

void array_alloc_scalar_real_array(real_array_t* dest, int n, m_real first,...)
{
    int i;
    va_list ap;
    simple_alloc_1d_real_array(dest,n);
    va_start(ap,first);
    put_real_element(first,0,dest);
    for (i = 1; i < n; ++i) {
        put_real_element(va_arg(ap,m_real),i,dest);
    }
    va_end(ap);
}

m_real* real_array_element_addr1(real_array_t* source,int ndims,int dim1)
{
    return real_ptrget(source, dim1 - 1);
}

m_real* real_array_element_addr2(real_array_t* source,int ndims,int dim1,int dim2)
{
    return real_ptrget(source, (dim1 - 1) * source->dim_size[1] + dim2-1);
}

m_real* real_array_element_addr(real_array_t* source,int ndims,...)
{
    va_list ap;
    m_real* tmp;

    va_start(ap,ndims);
    tmp = real_ptrget(source, calc_base_index_va(source, ndims, ap));
    va_end(ap);

    return tmp;
}


void cat_real_array(int k, real_array_t* dest, int n, real_array_t* first,...)
{
    assert(0 && "Not implemented yet");
}


/* function: cat_alloc_real_array
 *
 * Concatenates n real arrays along the k:th dimension.
 * Only works for 2 dimensional arrays.
 */
void cat_alloc_real_array(int k, real_array_t* dest, int n,
                          real_array_t* first,...)
{
    va_list ap;
    int i;
    int new_k_dim_size;
    real_array_t **elts = malloc(sizeof(real_array_t *) * n);
    assert(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for (i = 1; i < n; i++) {
        elts[i] = va_arg(ap,real_array_t*);
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
        dest->data = real_alloc(dim_size_2 * new_k_dim_size);
        dest->dim_size = size_alloc(2);
        dest->dim_size[0] = new_k_dim_size;
        dest->dim_size[1] = dim_size_2;
        dest->ndims = 2;

        for(i=0,j=0; i < n ; i++) {
            for(r=0; r < elts[i]->dim_size[0];r++) {
                for(c=0; c < elts[i]->dim_size[1];c++) {
                    real_set(dest, j++,
                             real_get(elts[i], c+r*elts[i]->dim_size[1]));
                }
            }
        }
    } /* concatenation along second dimension */
    /* cat(2,[1,2;3,4],[5,6;7,8]) => [1,2,5,6;3,4,7,8]*/
    else if (k == 2) {
        int r,c,j;
        int dim_size_1 = elts[0]->dim_size[0];
        dest->data = real_alloc(dim_size_1 * new_k_dim_size);
        dest->dim_size = size_alloc(2);
        dest->dim_size[0] = dim_size_1;
        dest->dim_size[1] = new_k_dim_size;
        dest->ndims = 2;

        for(r=0,j=0; r < elts[0]->dim_size[0];r++) {
            for(i=0; i < n ; i++) {
                for(c=0; c < elts[i]->dim_size[1];c++) {
                    real_set(dest, j++,
                             real_get(elts[i], c+r*elts[i]->dim_size[1]));
                }
            }
        }
    } else {
        assert(0&&"Only concatenation dimension 1 and 2 supported");
    }

    free(elts);
}

void range_alloc_real_array(m_real start, m_real stop, m_real inc, real_array_t* dest)
{
    int n;

    n = floor((stop-start)/inc)+1;
    simple_alloc_1d_real_array(dest,n);
    range_real_array(start,stop,inc,dest);
}

void range_real_array(m_real start, m_real stop, m_real inc, real_array_t* dest)
{
    int i;
    /* Assert that dest has correct size */
    for (i = 0; i < dest->dim_size[0]; ++i) {
        real_set(dest, i, start + i*inc);
    }
}

void add_real_array(real_array_t* a, real_array_t* b, real_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(a);
    for (i = 0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(a, i)+real_get(b, i));
    }
}

void add_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest)
{
    clone_real_array_spec(a,dest);
    alloc_real_array_data(dest);
    add_real_array(a,b,dest);
}

void sub_real_array(real_array_t* a, real_array_t* b, real_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(a);
    for (i = 0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(a, i)-real_get(b, i));
    }
}

void sub_real_array_data_mem(real_array_t* a, real_array_t* b,
                             modelica_real* dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(a);
    for (i = 0; i < nr_of_elements; ++i) {
        dest[i] = real_get(a, i) - real_get(b, i);
    }
}

void sub_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest)
{
    clone_real_array_spec(a, dest);
    alloc_real_array_data(dest);
    sub_real_array(a, b, dest);
}

void mul_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    nr_of_elements = base_array_nr_of_elements(b);
    for (i=0; i < nr_of_elements; ++i) {
        real_set(dest, i, a * real_get(b, i));
    }
}

void mul_alloc_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest)
{
    clone_real_array_spec(b,dest);
    alloc_real_array_data(dest);
    mul_scalar_real_array(a,b,dest);
}

void mul_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    nr_of_elements = base_array_nr_of_elements(a);
    for (i=0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(a, i) * b);
    }
}

void mul_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
    clone_real_array_spec(a,dest);
    alloc_real_array_data(dest);
    mul_real_array_scalar(a,b,dest);
}

modelica_real mul_real_scalar_product(real_array_t* a, real_array_t* b)
{
    size_t nr_of_elements;
    size_t i;
    modelica_real res;
    /* Assert that a and b are vectors */
    /* Assert that vectors are of matching size */

    nr_of_elements = real_array_nr_of_elements(a);
    res = 0.0;
    for (i = 0; i < nr_of_elements; ++i) {
        res += real_get(a, i)*real_get(b, i);
    }
    return res;
}

void mul_real_matrix_product(real_array_t* a,real_array_t* b,real_array_t* dest)
{
    modelica_real tmp;
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

    for (i = 0; i < i_size; ++i) {
        for (j = 0; j < j_size; ++j) {
            tmp = 0;
            for (k = 0; k < k_size; ++k) {
                tmp += real_get(a, i*k_size+k)*real_get(b, k*j_size+j);
	    }
            real_set(dest, i*j_size+j, tmp);
	}
    }
}

void mul_real_matrix_vector(real_array_t* a, real_array_t* b,real_array_t* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_real tmp;

    /* Assert a matrix */
    /* Assert b vector */
    /* Assert dest correct size (a vector)*/

    i_size = a->dim_size[0];
    j_size = a->dim_size[1];

    for (i = 0; i < i_size; ++i) {
        tmp = 0;
        for (j = 0; j < j_size; ++j) {
            tmp += real_get(a, i*j_size+j)*real_get(b, j);
	}
        real_set(dest, i, tmp);
    }
}


void mul_real_vector_matrix(real_array_t* a, real_array_t* b,real_array_t* dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_real tmp;

    /* Assert a vector */
    /* Assert b matrix */
    /* Assert dest vector of correct size */

    i_size = a->dim_size[0];
    j_size = b->dim_size[1];

    for (i = 0; i < i_size; ++i) {
        tmp = 0;
        for (j = 0; j < j_size; ++j) {
            tmp += real_get(a, j)*real_get(b, j*j_size+i);
	}
        real_set(dest, i, tmp);
    }
}

void mul_alloc_real_matrix_product_smart(real_array_t* a, real_array_t* b, real_array_t* dest)
{
    if ((a->ndims == 1) && (b->ndims == 2)) {
        simple_alloc_1d_real_array(dest,b->dim_size[1]);
        mul_real_vector_matrix(a,b,dest);
    } else if ((a->ndims == 2) && (b->ndims == 1)) {
        simple_alloc_1d_real_array(dest,a->dim_size[0]);
        mul_real_matrix_vector(a,b,dest);
    } else if ((a->ndims == 2) && (b->ndims == 2)) {
        simple_alloc_2d_real_array(dest,a->dim_size[0],b->dim_size[1]);
        mul_real_matrix_product(a,b,dest);
    } else {
        printf("Invalid size of matrix\n");
    }
}

void div_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(a);
    for (i=0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(a, i)/b);
    }
}

void div_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
    clone_real_array_spec(a,dest);
    alloc_real_array_data(dest);
    div_real_array_scalar(a,b,dest);
}

void exp_real_array(real_array_t* a, modelica_integer n, real_array_t* dest)
{
    size_t i;

    /* Assert n>=0 */
    /* Assert a matrix */
    /* Assert square matrix */

    if (n==0) {
        identity_real_array(a->dim_size[0],dest);
    } else {
        if (n==1) {
            clone_real_array_spec(a,dest);
            copy_real_array_data(a,dest);
	} else {
            real_array_t* tmp = 0;
            clone_real_array_spec(a,tmp);
            copy_real_array_data(a,tmp);
            for (i = 1; i < n; ++i) {
                mul_real_matrix_product(a,tmp,dest);
                copy_real_array_data(dest,tmp);
	    }
            free_real_array_data(tmp);
	}
    }
}

void exp_alloc_real_array(real_array_t* a,modelica_integer b,real_array_t* dest)
{
    clone_real_array_spec(a,dest);
    alloc_real_array_data(dest);
    exp_real_array(a,b,dest);
}

/* function: promote_alloc_real_array
 *
 * Implementation of promote(A,n) same as promote_real_array except
 * that the destination array is allocated.
 */
void promote_alloc_real_array(real_array_t* a, int n, real_array_t* dest)
{
    clone_real_array_spec(a,dest);
    alloc_real_array_data(dest);
    promote_real_array(a,n,dest);
}

/* function: promote_real_array.
 *
 * Implementation of promote(a,n)
 * Adds n onesized array dimensions to the array a to "the right of array dimensions".
 * For instance
 * promote_exp( {1,2},1) => {{1},{2}}
 * promote_exp( {1,2},2) => { {{1}},{{2}} }
*/
void promote_real_array(real_array_t* a, int n,real_array_t* dest)
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

/* function: promote_scalar_real_array
 *
 * promotes a scalar value to an n dimensional array.
 */

void promote_scalar_real_array(modelica_real s,int n,real_array_t* dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = real_alloc(1);

    dest->ndims = n;
    real_set(dest, 0, s);

    for (i = 0; i < n; ++i) {
        dest->dim_size[i] = 1;
    }
}

void size_real_array(real_array_t* a, real_array_t* dest)
{
    /* This should be an integer data instead */
    /*copy_integer_array_data(a->dim_size,dest); */
    /* Code below can't possibly do what it was supposed to do - x08joekl */
    /* dest = a; */
    assert(0&&"Not implemented.");
}

m_real scalar_real_array(real_array_t* a)
{
    assert(base_array_ok(a));
    assert(base_array_one_element_ok(a));

    return real_get(a, 0);
}

void vector_real_array(real_array_t* a, real_array_t* dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(a);
    for (i = 0; i < nr_of_elements; ++i) {
        real_set(dest, i, real_get(a, i));
    }
}

void vector_real_scalar(m_real a,real_array_t* dest)
{
    /* Assert that dest is a 1-vector */
    real_set(dest, 0, a);
}

void matrix_real_array(real_array_t* a, real_array_t* dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for (i = 0; i < cnt; ++i) {
        real_set(dest, i, real_get(a, i));
    }
}

void matrix_real_scalar(modelica_real a, real_array_t* dest)
{
    dest->ndims = 2;
    dest->dim_size[0] = 1;
    dest->dim_size[1] = 1;
    real_set(dest, 0, a);
}

/* function: transpose_alloc_real_array
 *
 * Implementation of transpose(A) for matrix A. Same as transpose_real_array
 * except that destionation array is allocated.
 */

void transpose_alloc_real_array(real_array_t* a, real_array_t* dest)
{
    clone_real_array_spec(a,dest); /* allocation*/

    /* transpose only valid for matrices.*/

    assert(a->ndims == 2);
    dest->dim_size[0]=a->dim_size[1];
    dest->dim_size[1]=a->dim_size[0];
    dest->ndims = 2;

    alloc_real_array_data(dest);
    transpose_real_array(a,dest);
}

/* function: transpose_real_array
 *
 * Implementation of transpose(A) for matrix A.
 */
void transpose_real_array(real_array_t* a, real_array_t* dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n,m;

    if (a->ndims == 1) {
        copy_real_array_data(a,dest);
        return;
    }

    assert(a->ndims==2 && dest->ndims==2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    assert(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for (i = 0; i < n; ++i) {
        for (j = 0; j < m; ++j) {
            real_set(dest, j*n+i, real_get(a, i*m+j));
        }
    }
}

void outer_product_real_array(real_array_t* v1, real_array_t* v2,
                              real_array_t* dest)
{
    size_t i;
    size_t j;
    size_t number_of_elements_a;
    size_t number_of_elements_b;

    number_of_elements_a = base_array_nr_of_elements(v1);
    number_of_elements_b = base_array_nr_of_elements(v2);

    /* Assert a is a vector */
    /* Assert b is a vector */

    for (i = 0; i < number_of_elements_a; ++i) {
        for (j = 0; i < number_of_elements_b; ++j) {
            real_set(dest, i*number_of_elements_b + j,
                     real_get(v1, i)*real_get(v2, j));
	}
    }
}

void identity_real_array(int n, real_array_t* dest)
{
    size_t i;
    size_t j;

    assert(base_array_ok(dest));

    /* Check that dest size is ok */
    assert(dest->ndims==2);
    assert((dest->dim_size[0]==n) && (dest->dim_size[1]==n));

    for (i = 0; i < n; ++i) {
        for (j = 0; j < n; ++j) {
            real_set(dest, i*n+j, i == j ? 1 : 0);
        }
    }
}

void diagonal_real_array(real_array_t* v,real_array_t* dest)
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

    for (i = 0; i < n; ++i) {
        for (j = 0; j < n; ++j) {
            real_set(dest, i*n+j, (i == j) ? real_get(v, i) : 0);
        }
    }
}

void fill_real_array(real_array_t* dest,modelica_real s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(dest);
    for (i = 0; i < nr_of_elements; ++i) {
        real_set(dest, i, s);
    }
}

void linspace_real_array(modelica_real x1, modelica_real x2, int n,
                         real_array_t* dest)
{
    size_t i;

    /* Assert n>=2 */

    for (i = 0; i < n-1; ++i) {
        real_set(dest, i, x1 + (x2-x1)*(i-1)/(n-1));
    }
}

modelica_real max_real_array(real_array_t* a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real max_element = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    if (nr_of_elements > 0) {
        max_element = real_get(a, 0);
        for (i = 1; i < nr_of_elements; ++i) {
            if (max_element < real_get(a, i)) {
                max_element = real_get(a, i);
	    }
	}
    }

    return max_element;
}

modelica_real min_real_array(real_array_t* a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real min_element = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    if (nr_of_elements > 0) {
        min_element = real_get(a, 0);
        for (i = 1; i < nr_of_elements; ++i) {
            if (min_element > real_get(a, i)) {
                min_element = real_get(a, i);
	    }
	}
    }

    return min_element;
}

modelica_real sum_real_array(real_array_t* a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real sum = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    for (i = 0; i < nr_of_elements; ++i) {
        sum += real_get(a, i);
    }

    return sum;
}

modelica_real product_real_array(real_array_t* a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real product = 0;

    assert(base_array_ok(a));

    nr_of_elements = base_array_nr_of_elements(a);

    for (i = 0; i < nr_of_elements; ++i) {
        product *= real_get(a, i);
    }

    return product;
}

void symmetric_real_array(real_array_t* a,real_array_t* dest)
{
    size_t i;
    size_t j;
    size_t nr_of_elements;

    nr_of_elements = base_array_nr_of_elements(a);

    /* Assert that a is a two dimensional square array */
    /* Assert that dest is a two dimensional square array */
    for (i = 0; i < nr_of_elements; ++i) {
        for (j = 0; j < nr_of_elements; ++j) {
            if (i <= j) {
                real_set(dest, i*nr_of_elements + j,
                         real_get(a, i*nr_of_elements + j));
	    } else {
                real_set(dest, i*nr_of_elements + j,
                         real_get(a, j*nr_of_elements + i));
	    }
	}
    }
}

void cross_real_array(real_array_t* x,real_array_t* y, real_array_t* dest)
{
    /* Assert x and y are vectors */
    /* Assert x and y have size 3 */
    /* Assert dest is a vector */
    /* Assert that dest have size 3*/

    real_set(dest, 0, real_get(x,1)*real_get(y,2)-real_get(x,2)*real_get(y,1));
    real_set(dest, 1, real_get(x,2)*real_get(y,0)-real_get(x,0)*real_get(y,2));
    real_set(dest, 2, real_get(x,0)*real_get(y,1)-real_get(x,1)*real_get(y,0));
}

void skew_real_array(real_array_t* x,real_array_t* dest)
{
    /* Assert x vector*/
    /* Assert x has size 3*/
    /* Assert dest is 3x3*/
    real_set(dest, 0, 0);
    real_set(dest, 1, -real_get(x, 2));
    real_set(dest, 2, real_get(x, 1));
    real_set(dest, 3, real_get(x, 2));
    real_set(dest, 4, 0);
    real_set(dest, 5, -real_get(x, 0));
    real_set(dest, 6, real_get(x, 1));
    real_set(dest, 7, real_get(x, 0));
    real_set(dest, 6, 0);
}

void convert_alloc_real_array_to_f77(real_array_t* a, real_array_t* dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_real_array_data(dest);
    transpose_real_array(a, dest);
    for (i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = a->dim_size[i];
    }
}

void convert_alloc_real_array_from_f77(real_array_t* a, real_array_t* dest)
{
    int i;
    clone_reverse_base_array_spec(a,dest);
    alloc_real_array_data(dest);
    for (i = 0; i < dest->ndims; ++i) {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_real_array(a, dest);
}
