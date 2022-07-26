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

#ifndef REAL_ARRAY_H_
#define REAL_ARRAY_H_


#include "../openmodelica.h"
#include "base_array.h"
#include "generic_array.h"
#include "../gc/omc_gc.h"
#include "index_spec.h"
#include "omc_msvc.h"
#include <stdarg.h>

modelica_real real_get(const real_array a, size_t i);
modelica_real real_get_2D(const real_array a, size_t i, size_t j);
modelica_real real_get_3D(const real_array a, size_t i, size_t j, size_t k);
modelica_real real_get_4D(const real_array a, size_t i, size_t j, size_t k, size_t l);
modelica_real real_get_5D(const real_array a, size_t i, size_t j, size_t k, size_t l, size_t m);

/* Setting the fields of a real_array */
extern void real_array_create(real_array *dest, modelica_real *data, int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_real_array(real_array* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_real_array(real_array* dest, int r, int c);

extern void alloc_real_array(real_array* dest,int ndims,...);

/* Allocation of real data */
extern void alloc_real_array_data(real_array* a);

/* Frees memory*/
extern void free_real_array_data(real_array* a);

/* Clones data*/
static inline void clone_real_array_spec(const real_array *src, real_array* dst)
{ clone_base_array_spec(src, dst); }

/* Copy real data given memory ptr*/
extern void copy_real_array_data_mem(const real_array source, modelica_real* dest);

/* Copy real array*/
extern void copy_real_array(const real_array source, real_array* dest);

extern void create_real_array_from_range(real_array *dest, modelica_real start, modelica_real step, modelica_real stop);

void fill_real_array_from_range(real_array *dest, modelica_real start, modelica_real step,
                                modelica_real stop/*, size_t dim*/);

extern modelica_real* calc_real_index(int ndims, const _index_t* idx_vec, const real_array * arr);
extern modelica_real* calc_real_index_va(const real_array * source,int ndims,va_list ap);

extern void put_real_element(modelica_real value,int i1,real_array* dest);
extern void put_real_matrix_element(modelica_real value, int r, int c, real_array* dest);

extern void print_real_matrix(const real_array * source);
extern void print_real_array(const real_array * source);
/*

 a[1:3] := b;

*/
extern void indexed_assign_real_array(const real_array source,
             real_array* dest,
             const index_spec_t* dest_spec);
extern void simple_indexed_assign_real_array1(const real_array * source,
               int i1,
               real_array* dest);
extern void simple_indexed_assign_real_array2(const real_array * source,
               int i1, int i2,
               real_array* dest);

/*

 a := b[1:3];

*/
extern void index_real_array(const real_array * source,
                      const index_spec_t* source_spec,
                      real_array* dest);
extern void index_alloc_real_array(const real_array * source,
                            const index_spec_t* source_spec,
                            real_array* dest);

extern void simple_index_alloc_real_array1(const real_array * source, int i1,
                                    real_array* dest);

extern void simple_index_real_array1(const real_array * source,
                              int i1,
                              real_array* dest);
extern void simple_index_real_array2(const real_array * source,
                              int i1, int i2,
                              real_array* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_real_array(real_array* dest,int n,real_array first,...);
extern void array_alloc_real_array(real_array* dest,int n,real_array first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_real_array(real_array* dest,int n,modelica_real first,...);
extern void array_alloc_scalar_real_array(real_array* dest,int n,modelica_real first,...);

extern void cat_real_array(int k,real_array* dest, int n, const real_array* first,...);
extern void cat_alloc_real_array(int k,real_array* dest, int n, const real_array* first,...);

extern void range_alloc_real_array(modelica_real start,modelica_real stop,modelica_real inc,
                            real_array* dest);
extern void range_real_array(modelica_real start,modelica_real stop, modelica_real inc,real_array* dest);

extern real_array add_alloc_real_array(const real_array a, const real_array b);
extern void add_real_array(const real_array * a, const real_array * b, real_array* dest);
extern real_array add_alloc_real_array_scalar(const real_array arr, const modelica_real sc);
extern real_array sub_alloc_scalar_real_array(const modelica_real sc, const real_array arr);

/* Unary subtraction */
extern void usub_real_array(real_array* a);
extern void usub_alloc_real_array(const real_array a, real_array* dest);
extern void sub_real_array(const real_array * a, const real_array * b, real_array* dest);
extern real_array sub_alloc_real_array(const real_array a, const real_array b);

extern void sub_real_array_data_mem(const real_array * a, const real_array * b,
                             modelica_real* dest);

extern void mul_scalar_real_array(modelica_real a,const real_array * b,real_array* dest);
extern real_array mul_alloc_scalar_real_array(modelica_real a,const real_array b);

extern void mul_real_array_scalar(const real_array * a,modelica_real b,real_array* dest);
extern real_array mul_alloc_real_array_scalar(const real_array a, const modelica_real b);

extern void mul_real_array(const real_array *a,const real_array *b,real_array* dest);
extern real_array mul_alloc_real_array(const real_array a,const real_array b);

extern modelica_real mul_real_scalar_product(const real_array a, const real_array b);

extern void mul_real_matrix_product(const real_array *a,const real_array *b,real_array*dest);
extern void mul_real_matrix_vector(const real_array * a, const real_array * b,
                            real_array* dest);
extern void mul_real_vector_matrix(const real_array * a, const real_array * b,
                            real_array* dest);
extern real_array mul_alloc_real_matrix_product_smart(const real_array a, const real_array b);

extern void div_real_array(const real_array *a,const real_array *b,real_array* dest);
extern real_array div_alloc_real_array(const real_array a,const real_array b);


extern void div_real_array_scalar(const real_array * a,modelica_real b,real_array* dest);
extern real_array div_alloc_real_array_scalar(const real_array a, const modelica_real b);

extern void division_real_array_scalar(threadData_t*,const real_array * a,modelica_real b,real_array* dest, const char* division_str);
extern real_array division_alloc_real_array_scalar(threadData_t*,const real_array a,modelica_real b, const char* division_str);
extern void div_scalar_real_array(modelica_real a, const real_array* b, real_array* dest);
extern real_array div_alloc_scalar_real_array(modelica_real a, const real_array b);
extern void pow_real_array_scalar(const real_array *a, modelica_real b, real_array* dest);
extern real_array pow_alloc_real_array_scalar(const real_array a, const modelica_real b);

extern void exp_real_array(const real_array * a, modelica_integer n, real_array* dest);
extern real_array exp_alloc_real_array(const real_array a, modelica_integer b);

extern void promote_real_array(const real_array * a, int n,real_array* dest);
extern void promote_scalar_real_array(modelica_real s,int n,real_array* dest);
extern void promote_alloc_real_array(const real_array * a, int n, real_array* dest);

static inline int ndims_real_array(const real_array * a)
{ return ndims_base_array(a); }

extern void size_real_array(const real_array * a,integer_array* dest);
extern modelica_real scalar_real_array(const real_array * a);
extern void vector_real_array(const real_array * a, real_array* dest);
extern void vector_real_scalar(modelica_real a,real_array* dest);
extern void matrix_real_array(const real_array * a, real_array* dest);
extern void matrix_real_scalar(modelica_real a,real_array* dest);
extern void transpose_alloc_real_array(const real_array * a, real_array* dest);
extern void transpose_real_array(const real_array * a, real_array* dest);
extern void outer_product_alloc_real_array(real_array* v1, real_array* v2, real_array* dest);
extern void outer_product_real_array(const real_array * v1,const real_array * v2, real_array* dest);
extern void identity_real_array(int n, real_array* dest);
extern void diagonal_real_array(const real_array * v,real_array* dest);
extern void diagonal_alloc_real_array(const real_array* v, real_array* dest);
extern void fill_real_array(real_array* dest,modelica_real s);
extern void linspace_real_array(modelica_real x1,modelica_real x2,int n,
                         real_array* dest);
extern modelica_real min_real_array(const real_array a);
extern modelica_real max_real_array(const real_array a);
extern modelica_real sum_real_array(const real_array a);
extern modelica_real product_real_array(const real_array a);
extern void symmetric_real_array(const real_array * a,real_array* dest);
extern void cross_real_array(const real_array * x,const real_array * y, real_array* dest);
extern void cross_alloc_real_array(const real_array * x,const real_array * y, real_array* dest);
extern void skew_real_array(const real_array * x,real_array* dest);

#define real_array_nr_of_elements(X) base_array_nr_of_elements(X)

static inline void clone_reverse_real_array_spec(const real_array *source,
                                                 real_array *dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_real_array_to_f77(const real_array * a, real_array* dest);
extern void convert_alloc_real_array_from_f77(const real_array * a, real_array* dest);

extern void cast_integer_array_to_real(const integer_array * a, real_array * dest);
extern void cast_real_array_to_integer(const real_array * a, integer_array * dest);

extern void fill_alloc_real_array(real_array* dest, modelica_real value, int ndims, ...);

extern void identity_alloc_real_array(int n, real_array* dest);

#endif
