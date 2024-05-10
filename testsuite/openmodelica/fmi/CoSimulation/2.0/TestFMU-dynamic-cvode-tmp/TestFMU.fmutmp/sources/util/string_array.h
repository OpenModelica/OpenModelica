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

#ifndef STRING_ARRAY_H_
#define STRING_ARRAY_H_

#include <stdarg.h>
#include "../openmodelica.h"
#include "base_array.h"
#include "generic_array.h"

/* Indexing */
modelica_string string_get(const string_array a, size_t i);
modelica_string string_get_2D(const string_array a, size_t i, size_t j);
modelica_string string_get_3D(const string_array a, size_t i, size_t j, size_t k);
modelica_string string_get_4D(const string_array a, size_t i, size_t j, size_t k, size_t l);
modelica_string string_get_5D(const string_array a, size_t i, size_t j, size_t k, size_t l, size_t m);

/* Setting the fields of a string_array */
extern void string_array_create(string_array *dest, modelica_string *data, int ndims, ...);

/* Allocation of a vector */
extern void simple_alloc_1d_string_array(string_array* dest, int n);

/* Allocation of a matrix */
extern void simple_alloc_2d_string_array(string_array *dest, int r, int c);

extern void alloc_string_array(string_array *dest, int ndims, ...);
extern void fill_alloc_string_array(string_array* dest, modelica_string value, int ndims, ...);

/* Allocation of string data */
extern void alloc_string_array_data(string_array* a);

/* Frees memory*/
extern void free_string_array_data(string_array* a);

/* Clones data*/
static inline void clone_string_array_spec(const string_array * src,
                                           string_array* dst)
{ clone_base_array_spec(src, dst); }

/* Copy string data given memory ptr*/
extern void copy_string_array_data_mem(const string_array source,modelica_string* dest);

/* Copy string array*/
extern void copy_string_array(const string_array source, string_array* dest);

extern modelica_string* calc_string_index(int ndims, const _index_t* idx_vec, const string_array * arr);
extern modelica_string* calc_string_index_va(const string_array * source,int ndims,
                                               va_list ap);

extern void put_string_element(modelica_string value,int i1,string_array* dest);
extern void put_string_matrix_element(modelica_string value, int r, int c,
                                      string_array* dest);

extern void print_string_matrix(const string_array * source);
extern void print_string_array(const string_array * source);
/*

 a[1:3] := b;

*/
extern void indexed_assign_string_array(const string_array source,
                                        string_array* dest,
                                        const index_spec_t* dest_spec);
extern void simple_indexed_assign_string_array1(const string_array * source,
                                                int i1,
                                                string_array* dest);
extern void simple_indexed_assign_string_array2(const string_array * source,
                                                int i1, int i2,
                                                string_array* dest);

/*

 a := b[1:3];

*/
extern void index_string_array(const string_array * source,
                               const index_spec_t* source_spec,
                               string_array* dest);
extern void index_alloc_string_array(const string_array * source,
                                     const index_spec_t* source_spec,
                                     string_array* dest);

extern void simple_index_alloc_string_array1(const string_array * source, int i1,
                                      string_array* dest);

extern void simple_index_string_array1(const string_array * source,
                                       int i1,
                                       string_array* dest);
extern void simple_index_string_array2(const string_array * source,
                                       int i1, int i2,
                                       string_array* dest);

/* array(A,B,C) for arrays A,B,C */
extern void array_string_array(string_array* dest,int n,
                               string_array first,...);
extern void array_alloc_string_array(string_array* dest,int n,
                                     string_array first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
extern void array_scalar_string_array(string_array* dest,int n,
                                      modelica_string first,...);
extern void array_alloc_scalar_string_array(string_array* dest,int n,
                                            modelica_string first,...);

extern void cat_string_array(int k,string_array* dest, int n,
                             const string_array* first,...);
extern void cat_alloc_string_array(int k,string_array* dest, int n,
                                   const string_array* first,...);

extern void promote_string_array(const string_array * a, int n,string_array* dest);
extern void promote_scalar_string_array(modelica_string s,int n,
                                        string_array* dest);
extern void promote_alloc_string_array(const string_array * a, int n,
                                       string_array* dest);

static inline int ndims_string_array(const string_array * a)
{ return ndims_base_array(a); }

extern const char** data_of_string_c89_array(const string_array a);

extern void size_string_array(const string_array * a, integer_array* dest);
extern modelica_string scalar_string_array(const string_array * a);
extern void vector_string_array(const string_array * a, string_array* dest);
extern void vector_string_scalar(modelica_string a,string_array* dest);
extern void matrix_string_array(const string_array * a, string_array* dest);
extern void matrix_string_scalar(modelica_string a,string_array* dest);
extern void transpose_alloc_string_array(const string_array * a, string_array* dest);
extern void transpose_string_array(const string_array * a, string_array* dest);

extern void fill_string_array(string_array* dest,modelica_string s);

static inline void clone_reverse_string_array_spec(const string_array *source,
                                                   string_array *dest)
{ clone_reverse_base_array_spec(source, dest); }
extern void convert_alloc_string_array_to_f77(const string_array * a,
                                              string_array* dest);
extern void convert_alloc_string_array_from_f77(const string_array * a,
                                                string_array* dest);

extern void fill_alloc_real_array(real_array* dest, modelica_real value, int ndims, ...);

extern void unpack_string_array(const string_array *a, const char **data);

#endif
