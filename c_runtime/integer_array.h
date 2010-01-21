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

#ifndef INTEGER_ARRAY_H_
#define INTEGER_ARRAY_H_

#include "base_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include <stdarg.h>

typedef int modelica_integer;

typedef base_array_t integer_array_t;

/* Indexing 1 dimensions */
modelica_integer integer_get(integer_array_t *a, size_t i);
/* Indexing 2 dimensions */
modelica_integer integer_get_2D(integer_array_t *a, size_t i, size_t j);
/* Indexing 3 dimensions */
modelica_integer integer_get_3D(integer_array_t *a, size_t i, size_t j, size_t k);
/* Indexing 4 dimensions */
modelica_integer integer_get_4D(integer_array_t *a, size_t i, size_t j, size_t k, size_t l);

/* Settings the fields of a integer_array */
void integer_array_create(integer_array_t *dst, modelica_integer *data,
                          int ndims, ...);

/* Allocation of a vector */
void simple_alloc_1d_integer_array(integer_array_t* dest, int n);

/* Allocation of a matrix */
void simple_alloc_2d_integer_array(integer_array_t*, int r, int c);

void alloc_integer_array(integer_array_t* dest,int ndims,...);

/* Allocation of integer data */
void alloc_integer_array_data(integer_array_t*);

/* Frees memory*/
void free_integer_array_data(integer_array_t*);

/* Clones data*/
static inline void clone_integer_array_spec(integer_array_t* source,
                                            integer_array_t* dest)
{ clone_base_array_spec(source, dest); }

/* Copy integer data*/
void copy_integer_array_data(integer_array_t* source, integer_array_t* dest);

/* Copy integer data given memory ptr*/
void copy_integer_array_data_mem(integer_array_t* source,
                                 modelica_integer *dest);

/* Copy integer array*/
void copy_integer_array(integer_array_t* source, integer_array_t* dest);

modelica_integer* calc_integer_index(int ndims,int* idx_vec,
                                     integer_array_t* arr);
modelica_integer* calc_integer_index_va(integer_array_t* source,int ndims,
                                        va_list ap);

void put_integer_element(modelica_integer value,int i1,integer_array_t* dest);
void put_integer_matrix_element(modelica_integer value, int r, int c,
                                integer_array_t* dest);

void print_integer_matrix(integer_array_t* source);
void print_integer_array(integer_array_t* source);
/*

 a[1:3] := b;

*/
void indexed_assign_integer_array(integer_array_t* source,
                                  integer_array_t* dest,
                                  index_spec_t* spec);
void simple_indexed_assign_integer_array1(integer_array_t* source,
                                          int,
                                          integer_array_t* dest);
void simple_indexed_assign_integer_array2(integer_array_t* source,
                                          int, int,
                                          integer_array_t* dest);

/*

 a := b[1:3];

*/
void index_integer_array(integer_array_t* source,
                         index_spec_t* spec,
                         integer_array_t* dest);
void index_alloc_integer_array(integer_array_t* source,
			       index_spec_t* spec,
			       integer_array_t* dest);

void simple_index_alloc_integer_array1(integer_array_t* source,int i1,
                                       integer_array_t* dest);

void simple_index_integer_array1(integer_array_t* source,
                                 int,
                                 integer_array_t* dest);
void simple_index_integer_array2(integer_array_t* source,
                                 int, int,
                                 integer_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
void array_integer_array(integer_array_t* dest,int n,
                         integer_array_t* first,...);
void array_alloc_integer_array(integer_array_t* dest,int n,
                               integer_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
void array_scalar_integer_array(integer_array_t* dest,int n,
                                modelica_integer first,...);
void array_alloc_scalar_integer_array(integer_array_t* dest,int n,
                                      modelica_integer first,...);

modelica_integer* integer_array_element_addr(integer_array_t* source,
                                             int ndims,...);
modelica_integer* integer_array_element_addr1(integer_array_t* source,
                                              int ndims,int dim1);
m_integer* integer_array_element_addr2(integer_array_t* source,int ndims,
                                       int dim1,int dim2);

void cat_integer_array(int k,integer_array_t* dest, int n,
                       integer_array_t* first,...);
void cat_alloc_integer_array(int k,integer_array_t* dest, int n,
                             integer_array_t* first,...);

void range_alloc_integer_array(modelica_integer start, modelica_integer stop,
                               modelica_integer inc,integer_array_t* dest);
void range_integer_array(modelica_integer start,modelica_integer stop,
                         modelica_integer inc,integer_array_t* dest);

void add_alloc_integer_array(integer_array_t* a, integer_array_t* b,
                             integer_array_t* dest);
void add_integer_array(integer_array_t* a, integer_array_t* b,
                       integer_array_t* dest);

void sub_integer_array(integer_array_t* a, integer_array_t* b,
                       integer_array_t* dest);
void sub_alloc_integer_array(integer_array_t* a, integer_array_t* b,
                             integer_array_t* dest);
void sub_integer_array_data_mem(integer_array_t* a, integer_array_t* b,
                                modelica_integer* dest);

void mul_scalar_integer_array(modelica_integer a,integer_array_t* b,
                              integer_array_t* dest);
void mul_alloc_scalar_integer_array(modelica_integer a,integer_array_t* b,
                                    integer_array_t* dest);

void mul_integer_array_scalar(integer_array_t* a,modelica_integer b,
                              integer_array_t* dest);
void mul_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,
                                    integer_array_t* dest);

modelica_integer mul_integer_scalar_product(integer_array_t* a,
                                            integer_array_t* b);

void mul_integer_matrix_product(integer_array_t*a,integer_array_t*b,
                                integer_array_t*dest);
void mul_integer_matrix_vector(integer_array_t* a, integer_array_t* b,
                               integer_array_t* dest);
void mul_integer_vector_matrix(integer_array_t* a, integer_array_t* b,
                               integer_array_t* dest);
void mul_alloc_integer_matrix_product_smart(integer_array_t* a,
                                            integer_array_t* b,
                                            integer_array_t* dest);

void div_integer_array_scalar(integer_array_t* a,modelica_integer b,
                              integer_array_t* dest);
void div_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,
                                    integer_array_t* dest);

void exp_integer_array(integer_array_t* a, modelica_integer b,
                       integer_array_t* dest);
void exp_alloc_integer_array(integer_array_t* a, modelica_integer b,
                             integer_array_t* dest);

void promote_integer_array(integer_array_t* a, int n,integer_array_t* dest);
void promote_scalar_integer_array(modelica_integer s,int n,
                                  integer_array_t* dest);
void promote_alloc_integer_array(integer_array_t* a, int n,
                                 integer_array_t* dest);

static inline int ndims_integer_array(integer_array_t* a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_integer_array(integer_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
typedef modelica_integer size_of_dimension_integer_array_rettype;
static inline modelica_integer *data_of_integer_array(integer_array_t *a)
{ return (modelica_integer *) a->data; }

void size_integer_array(integer_array_t* a,integer_array_t* dest);
modelica_integer scalar_integer_array(integer_array_t* a);
void vector_integer_array(integer_array_t* a, integer_array_t* dest);
void vector_integer_scalar(modelica_integer a,integer_array_t* dest);
void matrix_integer_array(integer_array_t* a, integer_array_t* dest);
void matrix_integer_scalar(modelica_integer a,integer_array_t* dest);
void transpose_integer_array(integer_array_t* a, integer_array_t* dest);
void transpose_alloc_integer_array(integer_array_t* a, integer_array_t* dest);
void outer_product_integer_array(integer_array_t* v1,integer_array_t* v2,
                                 integer_array_t* dest);
void identity_integer_array(int n, integer_array_t* dest);
void identity_alloc_integer_array(int n, integer_array_t* dest);

void diagonal_integer_array(integer_array_t* v,integer_array_t* dest);
void fill_integer_array(integer_array_t* dest,modelica_integer s);
void linspace_integer_array(modelica_integer x1,modelica_integer x2,int n,
                            integer_array_t* dest);
modelica_integer min_integer_array(integer_array_t* a);
modelica_integer max_integer_array(integer_array_t* a);
modelica_integer sum_integer_array(integer_array_t* a);
modelica_integer product_integer_array(integer_array_t* a);
void symmetric_integer_array(integer_array_t* a,integer_array_t* dest);
void cross_integer_array(integer_array_t* x,integer_array_t* y,integer_array_t* dest);
void cross_alloc_integer_array(integer_array_t* x,integer_array_t* y,integer_array_t* dest);
void skew_integer_array(integer_array_t* x,integer_array_t* dest);

static inline size_t integer_array_nr_of_elements(integer_array_t* a)
{ return base_array_nr_of_elements(a); }

modelica_integer* integer_array_make_index_array(integer_array_t *arr);

static inline void clone_reverse_integer_array_spec(integer_array_t* source,
                                                    integer_array_t* dest)
{ clone_reverse_base_array_spec(source, dest); }
void convert_alloc_integer_array_to_f77(integer_array_t* a,
                                        integer_array_t* dest);
void convert_alloc_integer_array_from_f77(integer_array_t* a,
                                          integer_array_t* dest);

#endif
