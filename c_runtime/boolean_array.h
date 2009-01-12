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

#ifndef BOOLEAN_ARRAY_H_
#define BOOLEAN_ARRAY_H_

#include "base_array.h"
#include "integer_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include <stdarg.h>

typedef signed char modelica_boolean;

typedef base_array_t boolean_array_t;

/* Indexing */
modelica_boolean boolean_get(boolean_array_t *a, size_t i);

/* Setting the fields of a boolean_array */
void boolean_array_create(boolean_array_t *dst, modelica_boolean *data, int ndims, ...);

/* Allocation of a vector */
void simple_alloc_1d_boolean_array(boolean_array_t* dest, int n);

/* Allocation of a matrix */
void simple_alloc_2d_boolean_array(boolean_array_t *dest, int r, int c);

void alloc_bool_array(boolean_array_t *dest, int ndims, ...);

/* Allocation of boolean data */
void alloc_boolean_array_data(boolean_array_t* a);

/* Frees memory*/
void free_boolean_array_data(boolean_array_t*);

/* Clones data*/
static inline void clone_boolean_array_spec(boolean_array_t* src,
                                            boolean_array_t* dst)
{ clone_base_array_spec(src, dst); }

/* Copy boolean data*/
void copy_boolean_array_data(boolean_array_t* source, boolean_array_t* dest);

/* Copy boolean data given memory ptr*/
void copy_boolean_array_data_mem(boolean_array_t* source, modelica_boolean* dest);

/* Copy boolean array*/
void copy_boolean_array(boolean_array_t* source, boolean_array_t* dest);

m_boolean* calc_boolean_index(int ndims, int* idx_vec, boolean_array_t* arr);
m_boolean* calc_boolean_index_va(boolean_array_t* source,int ndims,va_list ap);

void put_boolean_element(m_boolean value,int i1,boolean_array_t* dest);
void put_boolean_matrix_element(m_boolean value, int r, int c, boolean_array_t* dest);

void print_boolean_matrix(boolean_array_t* source);
void print_boolean_array(boolean_array_t* source);
/*

 a[1:3] := b;

*/
void indexed_assign_boolean_array(boolean_array_t* source,
                                  boolean_array_t* dest,
                                  index_spec_t* spec);
void simple_indexed_assign_boolean_array1(boolean_array_t* source,
                                          int,
                                          boolean_array_t* dest);
void simple_indexed_assign_boolean_array2(boolean_array_t* source,
                                          int, int,
                                          boolean_array_t* dest);

/*

 a := b[1:3];

*/
void index_boolean_array(boolean_array_t* source,
                         index_spec_t* spec,
                         boolean_array_t* dest);
void index_alloc_boolean_array(boolean_array_t* source,
                               index_spec_t* spec,
                               boolean_array_t* dest);

void simple_index_alloc_boolean_array1(boolean_array_t* source, int i1,
                                       boolean_array_t* dest);

void simple_index_boolean_array1(boolean_array_t* source,
                                 int,
                                 boolean_array_t* dest);
void simple_index_boolean_array2(boolean_array_t* source,
                                 int, int,
                                 boolean_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
void array_boolean_array(boolean_array_t* dest,int n,
                         boolean_array_t* first,...);
void array_alloc_boolean_array(boolean_array_t* dest,int n,
                               boolean_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
void array_scalar_boolean_array(boolean_array_t* dest,int n,
                                m_boolean first,...);
void array_alloc_scalar_boolean_array(boolean_array_t* dest,int n,
                                      m_boolean first,...);

m_boolean* boolean_array_element_addr(boolean_array_t* source,int ndims,...);
m_boolean* boolean_array_element_addr1(boolean_array_t* source,int ndims,int dim1);
m_boolean* boolean_array_element_addr2(boolean_array_t* source,int ndims,int dim1,int dim2);

void cat_boolean_array(int k,boolean_array_t* dest, int n,
                       boolean_array_t* first,...);
void cat_alloc_boolean_array(int k,boolean_array_t* dest, int n,
                             boolean_array_t* first,...);

void promote_boolean_array(boolean_array_t* a, int n,boolean_array_t* dest);
void promote_scalar_boolean_array(modelica_boolean s,int n,
                                  boolean_array_t* dest);
void promote_alloc_boolean_array(boolean_array_t* a, int n,
                                 boolean_array_t* dest);

static inline int ndims_boolean_array(boolean_array_t* a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_boolean_array(boolean_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
typedef modelica_integer size_of_dimension_boolean_array_rettype;
static inline modelica_boolean *data_of_boolean_array(boolean_array_t *a)
{ return (modelica_boolean *) a->data; }

void size_boolean_array(boolean_array_t* a, boolean_array_t* dest);
m_boolean scalar_boolean_array(boolean_array_t* a);
void vector_boolean_array(boolean_array_t* a, boolean_array_t* dest);
void vector_boolean_scalar(modelica_boolean a,boolean_array_t* dest);
void matrix_boolean_array(boolean_array_t* a, boolean_array_t* dest);
void matrix_boolean_scalar(modelica_boolean a,boolean_array_t* dest);
void transpose_alloc_boolean_array(boolean_array_t* a, boolean_array_t* dest);
void transpose_boolean_array(boolean_array_t* a, boolean_array_t* dest);

void fill_boolean_array(boolean_array_t* dest,modelica_boolean s);

static inline size_t boolean_array_nr_of_elements(boolean_array_t *a)
{ return base_array_nr_of_elements(a); }

static inline void clone_reverse_boolean_array_spec(boolean_array_t *source,
                                                    boolean_array_t *dest)
{ clone_reverse_base_array_spec(source, dest); }
void convert_alloc_boolean_array_to_f77(boolean_array_t* a,
                                        boolean_array_t* dest);
void convert_alloc_boolean_array_from_f77(boolean_array_t* a,
                                          boolean_array_t* dest);

#endif
