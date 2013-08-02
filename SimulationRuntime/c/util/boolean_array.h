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

#include "openmodelica.h"
#include "base_array.h"
#include "index_spec.h"
#include <stdarg.h>

/* Indexing 1 dimensions */
extern modelica_boolean boolean_get(const boolean_array_t *a, size_t i);
/* Indexing 2 dimensions */
extern modelica_boolean boolean_get_2D(const boolean_array_t *a, size_t i, size_t j);
/* Indexing 3 dimensions */
extern modelica_boolean boolean_get_3D(const boolean_array_t *a, size_t i, size_t j, size_t k);
/* Indexing 4 dimensions */
extern modelica_boolean boolean_get_4D(const boolean_array_t *a, size_t i, size_t j, size_t k, size_t l);

/* Setting the fields of a boolean_array */
extern void boolean_array_create(boolean_array_t *dest, modelica_boolean *data, int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_boolean_array(boolean_array_t* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_boolean_array(boolean_array_t *dest, int r, int c);

extern void alloc_boolean_array(boolean_array_t *dest, int ndims, ...);

/* Allocation of boolean data */
extern void alloc_boolean_array_data(boolean_array_t* a);

/* Frees memory*/
extern void free_boolean_array_data(boolean_array_t* a);

/* Clones data*/
static inline void clone_boolean_array_spec(const boolean_array_t* src,
                                            boolean_array_t* dst)
{ clone_base_array_spec(src, dst); }

/* Copy boolean data*/
extern void copy_boolean_array_data(const boolean_array_t* source, boolean_array_t* dest);

/* Copy boolean data given memory ptr*/
extern void copy_boolean_array_data_mem(const boolean_array_t* source, modelica_boolean* dest);

/* Copy boolean array*/
extern void copy_boolean_array(const boolean_array_t* source, boolean_array_t* dest);

/* 'and' two boolean arrays*/
void and_boolean_array(const boolean_array_t *source1, const boolean_array_t *source2, boolean_array_t *dest);

/* 'or' two boolean arrays*/
void or_boolean_array(const boolean_array_t *source1, const boolean_array_t *source2, boolean_array_t *dest);

/* 'not' a boolean array*/
void not_boolean_array(const boolean_array_t *source, boolean_array_t *dest);

extern modelica_boolean* calc_boolean_index(int ndims, const _index_t* idx_vec, const boolean_array_t* arr);
extern modelica_boolean* calc_boolean_index_va(const boolean_array_t* source,int ndims,va_list ap);

extern void put_boolean_element(m_boolean value,int i1,boolean_array_t* dest);
extern void put_boolean_matrix_element(m_boolean value, int r, int c, boolean_array_t* dest);

extern void print_boolean_matrix(const boolean_array_t* source);
extern void print_boolean_array(const boolean_array_t* source);
extern char print_boolean(m_boolean value);
/*

 a[1:3] := b;

*/
extern void indexed_assign_boolean_array(const boolean_array_t* source,
                                  boolean_array_t* dest,
                                  const index_spec_t* dest_spec);
extern void simple_indexed_assign_boolean_array1(const boolean_array_t* source,
                                          int i1,
                                          boolean_array_t* dest);
extern void simple_indexed_assign_boolean_array2(const boolean_array_t* source,
                                          int i1, int i2,
                                          boolean_array_t* dest);

/*

 a := b[1:3];

*/
extern void index_boolean_array(const boolean_array_t* source,
                         const index_spec_t* source_spec,
                         boolean_array_t* dest);
extern void index_alloc_boolean_array(const boolean_array_t* source,
                               const index_spec_t* source_spec,
                               boolean_array_t* dest);

extern void simple_index_alloc_boolean_array1(const boolean_array_t* source, int i1,
                                       boolean_array_t* dest);

extern void simple_index_boolean_array1(const boolean_array_t* source,
                                 int i1,
                                 boolean_array_t* dest);
extern void simple_index_boolean_array2(const boolean_array_t* source,
                                 int i1, int i2,
                                 boolean_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_boolean_array(boolean_array_t* dest,int n,
                         boolean_array_t* first,...);
extern void array_alloc_boolean_array(boolean_array_t* dest,int n,
                               boolean_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_boolean_array(boolean_array_t* dest,int n,
                                m_boolean first,...);
extern void array_alloc_scalar_boolean_array(boolean_array_t* dest,int n,...);

extern m_boolean* boolean_array_element_addr(const boolean_array_t* source,int ndims,...);
extern m_boolean* boolean_array_element_addr1(const boolean_array_t* source,int ndims,int dim1);
extern m_boolean* boolean_array_element_addr2(const boolean_array_t* source,int ndims,int dim1,int dim2);

extern void cat_boolean_array(int k,boolean_array_t* dest, int n,
                       boolean_array_t* first,...);
extern void cat_alloc_boolean_array(int k,boolean_array_t* dest, int n,
                             boolean_array_t* first,...);

extern void promote_boolean_array(const boolean_array_t* a, int n,boolean_array_t* dest);
extern void promote_scalar_boolean_array(modelica_boolean s,int n,
                                  boolean_array_t* dest);
extern void promote_alloc_boolean_array(const boolean_array_t* a, int n,
                                 boolean_array_t* dest);

static inline int ndims_boolean_array(const boolean_array_t* a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_boolean_array(boolean_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
static inline modelica_boolean *data_of_boolean_array(const boolean_array_t*a)
{ return (modelica_boolean *) a->data; }

extern void size_boolean_array(const boolean_array_t* a, integer_array_t* dest);
extern m_boolean scalar_boolean_array(const boolean_array_t* a);
extern void vector_boolean_array(const boolean_array_t* a, boolean_array_t* dest);
extern void vector_boolean_scalar(modelica_boolean a,boolean_array_t* dest);
extern void matrix_boolean_array(const boolean_array_t* a, boolean_array_t* dest);
extern void matrix_boolean_scalar(modelica_boolean a,boolean_array_t* dest);
extern void transpose_alloc_boolean_array(const boolean_array_t* a, boolean_array_t* dest);
extern void transpose_boolean_array(const boolean_array_t* a, boolean_array_t* dest);

extern void fill_boolean_array(boolean_array_t* dest,modelica_boolean s);

static inline size_t boolean_array_nr_of_elements(const boolean_array_t*a)
{ return base_array_nr_of_elements(a); }

static inline void clone_reverse_boolean_array_spec(const boolean_array_t*source,
                                                    boolean_array_t *dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_boolean_array_to_f77(const boolean_array_t* a,
                                        boolean_array_t* dest);
extern void convert_alloc_boolean_array_from_f77(const boolean_array_t* a,
                                          boolean_array_t* dest);
extern void fill_alloc_boolean_array(boolean_array_t* dest, modelica_boolean value, int ndims, ...);

#endif
