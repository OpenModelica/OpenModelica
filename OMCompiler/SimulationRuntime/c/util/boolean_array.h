/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#ifndef BOOLEAN_ARRAY_H_
#define BOOLEAN_ARRAY_H_

#include "../openmodelica.h"
#include "base_array.h"
#include "generic_array.h"
#include "index_spec.h"
#include "omc_msvc.h"
#include <stdarg.h>

modelica_boolean boolean_get(const boolean_array a, size_t i);
modelica_boolean boolean_get_2D(const boolean_array a, size_t i, size_t j);
modelica_boolean boolean_get_3D(const boolean_array a, size_t i, size_t j, size_t k);
modelica_boolean boolean_get_4D(const boolean_array a, size_t i, size_t j, size_t k, size_t l);
modelica_boolean boolean_get_5D(const boolean_array a, size_t i, size_t j, size_t k, size_t l, size_t m);

/* Setting the fields of a boolean_array */
extern void boolean_array_create(boolean_array *dest, modelica_boolean *data, int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_boolean_array(boolean_array* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_boolean_array(boolean_array *dest, int r, int c);

extern void alloc_boolean_array(boolean_array *dest, int ndims, ...);

/* Allocation of boolean data */
extern void alloc_boolean_array_data(boolean_array* a);

/* Frees memory*/
extern void free_boolean_array_data(boolean_array* a);

/* Clones data*/
static inline void clone_boolean_array_spec(const boolean_array* src,
                                            boolean_array* dst)
{ clone_base_array_spec(src, dst); }

/* Copy boolean data given memory ptr*/
extern void copy_boolean_array_data_mem(const boolean_array source, modelica_boolean* dest);

/* Copy boolean array*/
extern void copy_boolean_array(const boolean_array source, boolean_array* dest);

/* 'and' two boolean arrays*/
void and_boolean_array(const boolean_array *source1, const boolean_array *source2, boolean_array *dest);

/* 'or' two boolean arrays*/
void or_boolean_array(const boolean_array *source1, const boolean_array *source2, boolean_array *dest);

/* 'not' a boolean array*/
void not_boolean_array(const boolean_array source, boolean_array *dest);

extern modelica_boolean* calc_boolean_index(int ndims, const _index_t* idx_vec, const boolean_array* arr);
extern modelica_boolean* calc_boolean_index_va(const boolean_array* source,int ndims,va_list ap);

extern void put_boolean_element(modelica_boolean value,int i1,boolean_array* dest);
extern void put_boolean_matrix_element(modelica_boolean value, int r, int c, boolean_array* dest);

extern void print_boolean_matrix(const boolean_array* source);
extern void print_boolean_array(const boolean_array* source);
extern char print_boolean(modelica_boolean value);
/*

 a[1:3] := b;

*/
extern void indexed_assign_boolean_array(const boolean_array source,
                                  boolean_array* dest,
                                  const index_spec_t* dest_spec);
extern void simple_indexed_assign_boolean_array1(const boolean_array* source,
                                          int i1,
                                          boolean_array* dest);
extern void simple_indexed_assign_boolean_array2(const boolean_array* source,
                                          int i1, int i2,
                                          boolean_array* dest);

/*

 a := b[1:3];

*/
extern void index_boolean_array(const boolean_array* source,
                         const index_spec_t* source_spec,
                         boolean_array* dest);
extern void index_alloc_boolean_array(const boolean_array* source,
                               const index_spec_t* source_spec,
                               boolean_array* dest);

extern void simple_index_alloc_boolean_array1(const boolean_array* source, int i1,
                                       boolean_array* dest);

extern void simple_index_boolean_array1(const boolean_array* source,
                                 int i1,
                                 boolean_array* dest);
extern void simple_index_boolean_array2(const boolean_array* source,
                                 int i1, int i2,
                                 boolean_array* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_boolean_array(boolean_array* dest,int n,
                         boolean_array first,...);
extern void array_alloc_boolean_array(boolean_array* dest,int n,
                               boolean_array first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_boolean_array(boolean_array* dest,int n,...);
extern void array_alloc_scalar_boolean_array(boolean_array* dest,int n,...);

extern void cat_boolean_array(int k,boolean_array* dest, int n,
                       const boolean_array* first,...);
extern void cat_alloc_boolean_array(int k,boolean_array* dest, int n,
                             const boolean_array* first,...);

extern void promote_boolean_array(const boolean_array* a, int n,boolean_array* dest);
extern void promote_scalar_boolean_array(modelica_boolean s,int n,
                                  boolean_array* dest);
extern void promote_alloc_boolean_array(const boolean_array* a, int n,
                                 boolean_array* dest);

static inline int ndims_boolean_array(const boolean_array* a)
{ return ndims_base_array(a); }

extern void size_boolean_array(const boolean_array* a, integer_array* dest);
extern modelica_boolean scalar_boolean_array(const boolean_array* a);
extern void vector_boolean_array(const boolean_array* a, boolean_array* dest);
extern void vector_boolean_scalar(modelica_boolean a,boolean_array* dest);
extern void matrix_boolean_array(const boolean_array* a, boolean_array* dest);
extern void matrix_boolean_scalar(modelica_boolean a,boolean_array* dest);
extern void transpose_alloc_boolean_array(const boolean_array* a, boolean_array* dest);
extern void transpose_boolean_array(const boolean_array* a, boolean_array* dest);

extern void fill_boolean_array(boolean_array* dest,modelica_boolean s);

static inline void clone_reverse_boolean_array_spec(const boolean_array*source,
                                                    boolean_array *dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_boolean_array_to_f77(const boolean_array* a,
                                        boolean_array* dest);
extern void convert_alloc_boolean_array_from_f77(const boolean_array* a,
                                          boolean_array* dest);
extern void fill_alloc_boolean_array(boolean_array* dest, modelica_boolean value, int ndims, ...);

/* Returns the smallest value in the given array, or true if the array is empty. */
extern modelica_boolean min_boolean_array(const boolean_array a);
/* Returns the largest value in the given array, or false if the array is empty. */
extern modelica_boolean max_boolean_array(const boolean_array a);

#endif
