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

#ifndef REAL_ARRAY_H_
#define REAL_ARRAY_H_

#include "base_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include "integer_array.h"
#include <stdarg.h>

typedef double modelica_real;

typedef base_array_t real_array_t;

/* Setting the fields of a real_array */
void real_array_create(real_array_t *dst, modelica_real *data, int ndims, ...);

/* Allocation of a vector */
void simple_alloc_1d_real_array(real_array_t* dest, int n);

/* Allocation of a matrix */
void simple_alloc_2d_real_array(real_array_t*, int r, int c);

void alloc_real_array(real_array_t* dest,int ndims,...);

/* Allocation of real data */
void alloc_real_array_data(real_array_t*);

/* Frees memory*/
void free_real_array_data(real_array_t*);

/* Clones data*/
static inline void clone_real_array_spec(real_array_t *src, real_array_t* dst)
{ clone_base_array_spec(src, dst); }

/* Copy real data*/
void copy_real_array_data(real_array_t* source, real_array_t* dest);

/* Copy real data given memory ptr*/
void copy_real_array_data_mem(real_array_t* source, modelica_real* dest);

/* Copy real array*/
void copy_real_array(real_array_t* source, real_array_t* dest);

m_real* calc_real_index(int ndims, int* idx_vec, real_array_t* arr);
m_real* calc_real_index_va(real_array_t* source,int ndims,va_list ap);

void put_real_element(m_real value,int i1,real_array_t* dest);
void put_real_matrix_element(m_real value, int r, int c, real_array_t* dest);

void print_real_matrix(real_array_t* source);
void print_real_array(real_array_t* source);
/*

 a[1:3] := b;

*/
void indexed_assign_real_array(real_array_t* source,
			       real_array_t* dest,
			       index_spec_t* spec);
void simple_indexed_assign_real_array1(real_array_t* source,
				       int,
				       real_array_t* dest);
void simple_indexed_assign_real_array2(real_array_t* source,
				       int, int,
				       real_array_t* dest);

/*

 a := b[1:3];

*/
void index_real_array(real_array_t* source,
                      index_spec_t* spec,
                      real_array_t* dest);
void index_alloc_real_array(real_array_t* source,
                            index_spec_t* spec,
                            real_array_t* dest);

void simple_index_alloc_real_array1(real_array_t* source, int i1,
                                    real_array_t* dest);

void simple_index_real_array1(real_array_t* source,
                              int,
                              real_array_t* dest);
void simple_index_real_array2(real_array_t* source,
                              int, int,
                              real_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
void array_real_array(real_array_t* dest,int n,real_array_t* first,...);
void array_alloc_real_array(real_array_t* dest,int n,real_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
void array_scalar_real_array(real_array_t* dest,int n,m_real first,...);
void array_alloc_scalar_real_array(real_array_t* dest,int n,m_real first,...);

m_real* real_array_element_addr(real_array_t* source,int ndims,...);
m_real* real_array_element_addr1(real_array_t* source,int ndims,int dim1);
m_real* real_array_element_addr2(real_array_t* source,int ndims,int dim1,int dim2);

void cat_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);
void cat_alloc_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);

void range_alloc_real_array(m_real start,m_real stop,m_real inc,
                            real_array_t* dest);
void range_real_array(m_real start,m_real stop, m_real inc,real_array_t* dest);

void add_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest);
void add_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);

void sub_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);
void sub_alloc_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);

void sub_real_array_data_mem(real_array_t* a, real_array_t* b,
                             modelica_real* dest);

void mul_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest);
void mul_alloc_scalar_real_array(modelica_real a,real_array_t* b,
                                 real_array_t* dest);

void mul_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);
void mul_alloc_real_array_scalar(real_array_t* a,modelica_real b,
                                 real_array_t* dest);

modelica_real mul_real_scalar_product(real_array_t* a, real_array_t* b);

void mul_real_matrix_product(real_array_t*a,real_array_t*b,real_array_t*dest);
void mul_real_matrix_vector(real_array_t* a, real_array_t* b,
                            real_array_t* dest);
void mul_real_vector_matrix(real_array_t* a, real_array_t* b,
                            real_array_t* dest);
void mul_alloc_real_matrix_product_smart(real_array_t* a, real_array_t* b,
                                         real_array_t* dest);

void div_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);
void div_alloc_real_array_scalar(real_array_t* a,modelica_real b,
                                 real_array_t* dest);

void exp_real_array(real_array_t* a, modelica_integer b, real_array_t* dest);
void exp_alloc_real_array(real_array_t* a, modelica_integer b,
                          real_array_t* dest);

void promote_real_array(real_array_t* a, int n,real_array_t* dest);
void promote_scalar_real_array(modelica_real s,int n,real_array_t* dest);
void promote_alloc_real_array(real_array_t* a, int n, real_array_t* dest);

static inline int ndims_real_array(real_array_t* a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_real_array(real_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
typedef modelica_integer size_of_dimension_real_array_rettype;
static inline modelica_real *data_of_real_array(real_array_t *a)
{ return (modelica_real *) a->data; }

void size_real_array(real_array_t* a,real_array_t* dest);
m_real scalar_real_array(real_array_t* a);
void vector_real_array(real_array_t* a, real_array_t* dest);
void vector_real_scalar(modelica_real a,real_array_t* dest);
void matrix_real_array(real_array_t* a, real_array_t* dest);
void matrix_real_scalar(modelica_real a,real_array_t* dest);
void transpose_alloc_real_array(real_array_t* a, real_array_t* dest);
void transpose_real_array(real_array_t* a, real_array_t* dest);
void outer_product_real_array(real_array_t* v1,real_array_t* v2,
                              real_array_t* dest);
void identity_real_array(int n, real_array_t* dest);
void diagonal_real_array(real_array_t* v,real_array_t* dest);
void fill_real_array(real_array_t* dest,modelica_real s);
void linspace_real_array(modelica_real x1,modelica_real x2,int n,
                         real_array_t* dest);
modelica_real min_real_array(real_array_t* a);
modelica_real max_real_array(real_array_t* a);
modelica_real sum_real_array(real_array_t* a);
modelica_real product_real_array(real_array_t* a);
void symmetric_real_array(real_array_t* a,real_array_t* dest);
void cross_real_array(real_array_t* x,real_array_t* y, real_array_t* dest);
void skew_real_array(real_array_t* x,real_array_t* dest);

static inline size_t real_array_nr_of_elements(real_array_t *a)
{ return base_array_nr_of_elements(a); }

static inline void clone_reverse_real_array_spec(real_array_t *source,
                                                 real_array_t *dest)
{ clone_reverse_base_array_spec(source, dest); }
void convert_alloc_real_array_to_f77(real_array_t* a, real_array_t* dest);
void convert_alloc_real_array_from_f77(real_array_t* a, real_array_t* dest);

#endif
