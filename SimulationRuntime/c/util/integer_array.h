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

#ifndef INTEGER_ARRAY_H_
#define INTEGER_ARRAY_H_

#include "openmodelica.h"
#include "base_array.h"
#include "memory_pool.h"
#include "index_spec.h"
#include <stdarg.h>

/* Indexing 1 dimensions */
extern modelica_integer integer_get(const integer_array_t *a, size_t i);
/* Indexing 2 dimensions */
extern modelica_integer integer_get_2D(const integer_array_t *a, size_t i, size_t j);
/* Indexing 3 dimensions */
extern modelica_integer integer_get_3D(const integer_array_t *a, size_t i, size_t j, size_t k);
/* Indexing 4 dimensions */
extern modelica_integer integer_get_4D(const integer_array_t *a, size_t i, size_t j, size_t k, size_t l);

/* Settings the fields of a integer_array */
extern void integer_array_create(integer_array_t *dest, modelica_integer *data,
                                 int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_integer_array(integer_array_t* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_integer_array(integer_array_t* dest, int r, int c);

extern void alloc_integer_array(integer_array_t *dest,int ndims,...);

/* Allocation of integer data */
extern void alloc_integer_array_data(integer_array_t *a);

/* Frees memory*/
extern void free_integer_array_data(integer_array_t* a);

/* Clones data*/
static inline void clone_integer_array_spec(const integer_array_t * source,
                                            integer_array_t* dest)
{ clone_base_array_spec(source, dest); }

/* Copy integer data*/
extern void copy_integer_array_data(const integer_array_t * source, integer_array_t* dest);

/* Copy integer data given memory ptr*/
extern void copy_integer_array_data_mem(const integer_array_t * source,
                                        modelica_integer *dest);

/* Copy integer array*/
extern void copy_integer_array(const integer_array_t * source, integer_array_t* dest);

extern void create_integer_array_from_range(integer_array_t *dest, modelica_integer start, modelica_integer step, modelica_integer stop);

void fill_integer_array_from_range(integer_array_t *dest, modelica_integer start,
                                   modelica_integer step, modelica_integer stop/*, size_t dim*/);

extern modelica_integer* calc_integer_index(int ndims, const _index_t* idx_vec,
                                            const integer_array_t * arr);
extern modelica_integer* calc_integer_index_va(const integer_array_t * source,int ndims,
                                               va_list ap);

extern void put_integer_element(modelica_integer value,int i1,integer_array_t* dest);
extern void put_integer_matrix_element(modelica_integer value, int r, int c,
                                       integer_array_t* dest);

extern void print_integer_matrix(const integer_array_t * source);
extern void print_integer_array(const integer_array_t * source);
/*

 a[1:3] := b;

*/
extern void indexed_assign_integer_array(const integer_array_t * source,
                                         integer_array_t* dest,
                                         const index_spec_t* dest_spec);
extern void simple_indexed_assign_integer_array1(const integer_array_t * source,
                                                 int i1,
                                                 integer_array_t* dest);
extern void simple_indexed_assign_integer_array2(const integer_array_t * source,
                                                 int i1, int i2,
                                                 integer_array_t* dest);

/*

 a := b[1:3];

*/
extern void index_integer_array(const integer_array_t * source,
                                const index_spec_t* source_spec,
                                integer_array_t* dest);
extern void index_alloc_integer_array(const integer_array_t * source,
                    const index_spec_t* source_spec,
                    integer_array_t* dest);

extern void simple_index_alloc_integer_array1(const integer_array_t * source,int i1,
                                              integer_array_t* dest);

extern void simple_index_integer_array1(const integer_array_t * source,
                                        int i1,
                                        integer_array_t* dest);
extern void simple_index_integer_array2(const integer_array_t * source,
                                        int i1, int i2,
                                        integer_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_integer_array(integer_array_t* dest,int n,
                                integer_array_t* first,...);
extern void array_alloc_integer_array(integer_array_t* dest,int n,
                                      integer_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_integer_array(integer_array_t* dest,int n,
                                       modelica_integer first,...);
extern void array_alloc_scalar_integer_array(integer_array_t* dest,int n,
                                             modelica_integer first,...);

extern modelica_integer* integer_array_element_addr(const integer_array_t * source,
                                                    int ndims,...);
extern modelica_integer* integer_array_element_addr1(const integer_array_t * source,
                                                     int ndims,int dim1);
extern modelica_integer* integer_array_element_addr2(const integer_array_t * source,int ndims,
                                                     int dim1,int dim2);

extern void cat_integer_array(int k,integer_array_t* dest, int n,
                              integer_array_t* first,...);
extern void cat_alloc_integer_array(int k,integer_array_t* dest, int n,
                                    integer_array_t* first,...);

extern void range_alloc_integer_array(modelica_integer start, modelica_integer stop,
                                      modelica_integer inc,integer_array_t* dest);
extern void range_integer_array(modelica_integer start,modelica_integer stop,
                                modelica_integer inc,integer_array_t* dest);

extern void add_alloc_integer_array(const integer_array_t * a, const integer_array_t * b,
                                    integer_array_t* dest);
extern void add_integer_array(const integer_array_t * a, const integer_array_t * b,
                              integer_array_t* dest);

extern void sub_integer_array(const integer_array_t * a, const integer_array_t * b,
                              integer_array_t* dest);
extern void sub_alloc_integer_array(const integer_array_t * a, const integer_array_t * b,
                                    integer_array_t* dest);
extern void sub_integer_array_data_mem(const integer_array_t * a, const integer_array_t * b,
                                       modelica_integer* dest);

extern void mul_scalar_integer_array(modelica_integer a,const integer_array_t * b,
                                     integer_array_t* dest);
extern void mul_alloc_scalar_integer_array(modelica_integer a,const integer_array_t * b,
                                           integer_array_t* dest);

extern void mul_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                     integer_array_t* dest);
extern void mul_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                           integer_array_t* dest);

extern modelica_integer mul_integer_scalar_product(const integer_array_t * a,
                                                   const integer_array_t * b);

extern void mul_integer_matrix_product(const integer_array_t *a,const integer_array_t *b,
                                       integer_array_t*dest);
extern void mul_integer_matrix_vector(const integer_array_t * a, const integer_array_t * b,
                                      integer_array_t* dest);
extern void mul_integer_vector_matrix(const integer_array_t * a, const integer_array_t * b,
                                      integer_array_t* dest);
extern void mul_alloc_integer_matrix_product_smart(const integer_array_t * a,
                                                   const integer_array_t * b,
                                                   integer_array_t* dest);

extern void div_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                     integer_array_t* dest);
extern void div_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                           integer_array_t* dest);

extern void division_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                          integer_array_t* dest, const char* division_str);
extern void division_alloc_integer_array_scalar(const integer_array_t * a,modelica_integer b,
                                                integer_array_t* dest, const char* division_str);
extern void div_scalar_integer_array(modelica_integer a, const integer_array_t* b, integer_array_t* dest);
extern void div_alloc_scalar_integer_array(modelica_integer a, const integer_array_t* b, integer_array_t* dest);
extern void pow_integer_array_scalar(const integer_array_t *a, modelica_integer b, integer_array_t* dest);
extern void pow_alloc_integer_array_scalar(const integer_array* a, modelica_integer b, integer_array_t* dest);

extern void exp_integer_array(const integer_array_t * a, modelica_integer n,
                              integer_array_t* dest);
extern void exp_alloc_integer_array(const integer_array_t * a, modelica_integer b,
                                    integer_array_t* dest);

extern void promote_integer_array(const integer_array_t * a, int n,integer_array_t* dest);
extern void promote_scalar_integer_array(modelica_integer s,int n,
                                         integer_array_t* dest);
extern void promote_alloc_integer_array(const integer_array_t * a, int n,
                                        integer_array_t* dest);

static inline int ndims_integer_array(const integer_array_t * a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_integer_array(integer_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
/* This is defined in integer_array since we return an integer array */
extern void sizes_of_dimensions_base_array(const base_array_t *a, integer_array_t *dest);

extern void size_integer_array(const integer_array_t * a,integer_array_t* dest);
extern modelica_integer scalar_integer_array(const integer_array_t * a);
extern void vector_integer_array(const integer_array_t * a, integer_array_t* dest);
extern void vector_integer_scalar(modelica_integer a,integer_array_t* dest);
extern void matrix_integer_array(const integer_array_t * a, integer_array_t* dest);
extern void matrix_integer_scalar(modelica_integer a,integer_array_t* dest);
extern void transpose_integer_array(const integer_array_t * a, integer_array_t* dest);
extern void transpose_alloc_integer_array(const integer_array_t * a, integer_array_t* dest);
extern void outer_product_alloc_integer_array(const integer_array_t * v1,const integer_array_t * v2, integer_array_t* dest);
extern void outer_product_integer_array(const integer_array_t * v1,const integer_array_t * v2, integer_array_t* dest);
extern void fill_alloc_integer_array(integer_array_t* dest, modelica_integer value, int ndims, ...);
extern void identity_integer_array(int n, integer_array_t* dest);
extern void identity_alloc_integer_array(int n, integer_array_t* dest);

extern void diagonal_integer_array(const integer_array_t * v,integer_array_t* dest);
extern void fill_integer_array(integer_array_t* dest,modelica_integer s);
extern void linspace_integer_array(modelica_integer x1,modelica_integer x2,int n,
                                   integer_array_t* dest);
extern modelica_integer min_integer_array(const integer_array_t * a);
extern modelica_integer max_integer_array(const integer_array_t * a);
extern modelica_integer sum_integer_array(const integer_array_t * a);
extern modelica_integer product_integer_array(const integer_array_t * a);
extern void symmetric_integer_array(const integer_array_t * a,integer_array_t* dest);
extern void cross_integer_array(const integer_array_t * x,const integer_array_t * y,integer_array_t* dest);
extern void cross_alloc_integer_array(const integer_array_t * x,const integer_array_t * y,integer_array_t* dest);
extern void skew_integer_array(const integer_array_t * x,integer_array_t* dest);

static inline size_t integer_array_nr_of_elements(const integer_array_t * a)
{ return base_array_nr_of_elements(a); }

extern _index_t* integer_array_make_index_array(const integer_array_t *arr);

static inline void clone_reverse_integer_array_spec(const integer_array_t * source,
                                                    integer_array_t* dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_integer_array_to_f77(const integer_array_t * a,
                                               integer_array_t* dest);
extern void convert_alloc_integer_array_from_f77(const integer_array_t * a,
                                                 integer_array_t* dest);

void pack_integer_array(integer_array_t *a);
void unpack_integer_array(integer_array_t *a);

/* Note: data_of_integer_array converts from integer_array to int*, for external functions only */
static inline int* data_of_integer_array(const integer_array_t *a)
{ return (int *) a->data; }

static inline int* data_of_integer_f77_array(const integer_array_t *a)
{ return (int *) a->data; }

#endif
