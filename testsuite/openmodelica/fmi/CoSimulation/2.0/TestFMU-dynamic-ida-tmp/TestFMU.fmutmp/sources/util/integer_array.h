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

#ifndef INTEGER_ARRAY_H_
#define INTEGER_ARRAY_H_

#include "../openmodelica.h"
#include "base_array.h"
#include "generic_array.h"
#include "../gc/omc_gc.h"
#include "omc_msvc.h"
#include "index_spec.h"
#include <stdarg.h>

modelica_integer integer_get(const integer_array a, size_t i);
modelica_integer integer_get_2D(const integer_array a, size_t i, size_t j);
modelica_integer integer_get_3D(const integer_array a, size_t i, size_t j, size_t k);
modelica_integer integer_get_4D(const integer_array a, size_t i, size_t j, size_t k, size_t l);
modelica_integer integer_get_5D(const integer_array a, size_t i, size_t j, size_t k, size_t l, size_t m);

/* Settings the fields of a integer_array */
extern void integer_array_create(integer_array *dest, modelica_integer *data,
                                 int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_integer_array(integer_array* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_integer_array(integer_array* dest, int r, int c);

extern void alloc_integer_array(integer_array *dest,int ndims,...);

/* Allocation of integer data */
extern void alloc_integer_array_data(integer_array *a);

/* Frees memory*/
extern void free_integer_array_data(integer_array* a);

/* Clones data*/
static inline void clone_integer_array_spec(const integer_array * source,
                                            integer_array* dest)
{ clone_base_array_spec(source, dest); }

/* Copy integer data given memory ptr*/
extern void copy_integer_array_data_mem(const integer_array source,
                                        modelica_integer *dest);

/* Copy integer array*/
extern void copy_integer_array(const integer_array source, integer_array* dest);

extern void create_integer_array_from_range(integer_array *dest, modelica_integer start, modelica_integer step, modelica_integer stop);

void fill_integer_array_from_range(integer_array *dest, modelica_integer start,
                                   modelica_integer step, modelica_integer stop/*, size_t dim*/);

extern modelica_integer* calc_integer_index(int ndims, const _index_t* idx_vec,
                                            const integer_array * arr);
extern modelica_integer* calc_integer_index_va(const integer_array * source,int ndims,
                                               va_list ap);

extern void put_integer_element(modelica_integer value,int i1,integer_array* dest);
extern void put_integer_matrix_element(modelica_integer value, int r, int c,
                                       integer_array* dest);

extern void print_integer_matrix(const integer_array * source);
extern void print_integer_array(const integer_array * source);
/*

 a[1:3] := b;

*/
extern void indexed_assign_integer_array(const integer_array source,
                                         integer_array* dest,
                                         const index_spec_t* dest_spec);
extern void simple_indexed_assign_integer_array1(const integer_array * source,
                                                 int i1,
                                                 integer_array* dest);
extern void simple_indexed_assign_integer_array2(const integer_array * source,
                                                 int i1, int i2,
                                                 integer_array* dest);

/*

 a := b[1:3];

*/
extern void index_integer_array(const integer_array * source,
                                const index_spec_t* source_spec,
                                integer_array* dest);
extern void index_alloc_integer_array(const integer_array * source,
                    const index_spec_t* source_spec,
                    integer_array* dest);

extern void simple_index_alloc_integer_array1(const integer_array * source,int i1,
                                              integer_array* dest);

extern void simple_index_integer_array1(const integer_array * source,
                                        int i1,
                                        integer_array* dest);
extern void simple_index_integer_array2(const integer_array * source,
                                        int i1, int i2,
                                        integer_array* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_integer_array(integer_array* dest,int n,
                                integer_array first,...);
extern void array_alloc_integer_array(integer_array* dest,int n,
                                      integer_array first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_integer_array(integer_array* dest,int n,
                                       modelica_integer first,...);
extern void array_alloc_scalar_integer_array(integer_array* dest,int n,
                                             modelica_integer first,...);

extern void cat_integer_array(int k,integer_array* dest, int n,
                              const integer_array* first,...);
extern void cat_alloc_integer_array(int k,integer_array* dest, int n,
                                    const integer_array* first,...);

extern void range_alloc_integer_array(modelica_integer start, modelica_integer stop,
                                      modelica_integer inc,integer_array* dest);
extern void range_integer_array(modelica_integer start,modelica_integer stop,
                                modelica_integer inc,integer_array* dest);

extern integer_array add_alloc_integer_array(const integer_array a, const integer_array b);
extern void add_integer_array(const integer_array * a, const integer_array * b,
                              integer_array* dest);

/* Unary subtraction */
extern void usub_integer_array(integer_array* a);
extern void usub_alloc_integer_array(const integer_array a, integer_array* dest);
extern void sub_integer_array(const integer_array * a, const integer_array * b,
                              integer_array* dest);
extern integer_array sub_alloc_integer_array(const integer_array a, const integer_array b);
extern void sub_integer_array_data_mem(const integer_array * a, const integer_array * b,
                                       modelica_integer* dest);

extern void mul_scalar_integer_array(modelica_integer a,const integer_array * b,
                                     integer_array* dest);
extern integer_array mul_alloc_scalar_integer_array(modelica_integer a,const integer_array b);

extern void mul_integer_array_scalar(const integer_array * a,modelica_integer b,
                                     integer_array* dest);
extern void mul_integer_array(const integer_array *a,const integer_array *b,integer_array* dest);
extern integer_array mul_alloc_integer_array(const integer_array a, integer_array b);
extern integer_array mul_alloc_integer_array_scalar(const integer_array a,modelica_integer b);

extern modelica_integer mul_integer_scalar_product(const integer_array a,
                                                   const integer_array b);

extern void mul_integer_matrix_product(const integer_array *a,const integer_array *b,
                                       integer_array*dest);
extern void mul_integer_matrix_vector(const integer_array * a, const integer_array * b,
                                      integer_array* dest);
extern void mul_integer_vector_matrix(const integer_array * a, const integer_array * b,
                                      integer_array* dest);
extern integer_array mul_alloc_integer_matrix_product_smart(const integer_array a, const integer_array b);

extern void div_integer_array_scalar(const integer_array * a,modelica_integer b,
                                     integer_array* dest);
extern integer_array div_alloc_integer_array_scalar(const integer_array a,modelica_integer b);

extern void division_integer_array_scalar(threadData_t*,const integer_array * a,modelica_integer b,
                                          integer_array* dest, const char* division_str);
extern integer_array division_alloc_integer_array_scalar(threadData_t *threadData,const integer_array a,modelica_integer b, const char* division_str);
extern void div_scalar_integer_array(modelica_integer a, const integer_array* b, integer_array* dest);
extern integer_array div_alloc_scalar_integer_array(modelica_integer a, const integer_array b);
extern void pow_integer_array_scalar(const integer_array *a, modelica_integer b, integer_array* dest);
extern integer_array pow_alloc_integer_array_scalar(const integer_array a, modelica_integer b);

extern void exp_integer_array(const integer_array * a, modelica_integer n,
                              integer_array* dest);
extern integer_array exp_alloc_integer_array(const integer_array a, modelica_integer b);

extern void promote_integer_array(const integer_array * a, int n,integer_array* dest);
extern void promote_scalar_integer_array(modelica_integer s,int n,
                                         integer_array* dest);
extern void promote_alloc_integer_array(const integer_array * a, int n,
                                        integer_array* dest);

static inline int ndims_integer_array(const integer_array * a)
{ return ndims_base_array(a); }
/* This is defined in integer_array since we return an integer array */
extern void sizes_of_dimensions_base_array(const base_array_t *a, integer_array *dest);

extern void size_integer_array(const integer_array * a,integer_array* dest);
extern modelica_integer scalar_integer_array(const integer_array * a);
extern void vector_integer_array(const integer_array * a, integer_array* dest);
extern void vector_integer_scalar(modelica_integer a,integer_array* dest);
extern void matrix_integer_array(const integer_array * a, integer_array* dest);
extern void matrix_integer_scalar(modelica_integer a,integer_array* dest);
extern void transpose_integer_array(const integer_array * a, integer_array* dest);
extern void transpose_alloc_integer_array(const integer_array * a, integer_array* dest);
extern void outer_product_alloc_integer_array(const integer_array * v1,const integer_array * v2, integer_array* dest);
extern void outer_product_integer_array(const integer_array * v1,const integer_array * v2, integer_array* dest);
extern void fill_alloc_integer_array(integer_array* dest, modelica_integer value, int ndims, ...);
extern void identity_integer_array(int n, integer_array* dest);
extern void identity_alloc_integer_array(int n, integer_array* dest);

extern void diagonal_integer_array(const integer_array * v,integer_array* dest);
extern void diagonal_alloc_integer_array(const integer_array *v, integer_array* dest);
extern void fill_integer_array(integer_array* dest,modelica_integer s);
extern void linspace_integer_array(modelica_integer x1,modelica_integer x2,int n,
                                   integer_array* dest);
extern modelica_integer min_integer_array(const integer_array a);
extern modelica_integer max_integer_array(const integer_array a);
extern modelica_integer sum_integer_array(const integer_array a);
extern modelica_integer product_integer_array(const integer_array a);
extern void symmetric_integer_array(const integer_array * a,integer_array* dest);
extern void cross_integer_array(const integer_array * x,const integer_array * y,integer_array* dest);
extern void cross_alloc_integer_array(const integer_array * x,const integer_array * y,integer_array* dest);
extern void skew_integer_array(const integer_array * x,integer_array* dest);

extern _index_t* integer_array_make_index_array(const integer_array arr);

static inline void clone_reverse_integer_array_spec(const integer_array * source,
                                                    integer_array* dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_integer_array_to_f77(const integer_array * a,
                                               integer_array* dest);
extern void convert_alloc_integer_array_from_f77(const integer_array * a,
                                                 integer_array* dest);

void pack_integer_array(integer_array *a);
void unpack_integer_array(integer_array *a);
void pack_alloc_integer_array(integer_array *a, integer_array *dest);
void unpack_copy_integer_array(const integer_array *a, integer_array *dest);

#endif
