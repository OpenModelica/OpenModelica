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

#ifndef STRING_ARRAY_H_
#define STRING_ARRAY_H_

#include "modelica_string.h"
#include "base_array.h"
#include "integer_array.h"
#include "memory_pool.h"
#include <stdarg.h>

typedef base_array_t string_array_t;

/* Indexing */
modelica_string_t string_get(string_array_t *a, size_t i);

/* Setting the fields of a string_array */
void string_array_create(string_array_t *dst, modelica_string_t *data, int ndims, ...);

/* Allocation of a vector */
void simple_alloc_1d_string_array(string_array_t* dest, int n);

/* Allocation of a matrix */
void simple_alloc_2d_string_array(string_array_t *dest, int r, int c);

void alloc_string_array(string_array_t *dest, int ndims, ...);

/* Allocation of string data */
void alloc_string_array_data(string_array_t* a);

/* Frees memory*/
void free_string_array_data(string_array_t*);

/* Clones data*/
static inline void clone_string_array_spec(string_array_t* src,
                                           string_array_t* dst)
{ clone_base_array_spec(src, dst); }

/* Copy string data*/
void copy_string_array_data(string_array_t* source, string_array_t* dest);

/* Copy string data given memory ptr*/
void copy_string_array_data_mem(string_array_t* source,modelica_string_t* dest);

/* Copy string array*/
void copy_string_array(string_array_t* source, string_array_t* dest);

modelica_string_t* calc_string_index(int ndims, int* idx_vec,
                                     string_array_t* arr);
modelica_string_t* calc_string_index_va(string_array_t* source,int ndims,
                                        va_list ap);

void put_string_element(modelica_string_t value,int i1,string_array_t* dest);
void put_string_matrix_element(modelica_string_t value, int r, int c,
                               string_array_t* dest);

void print_string_matrix(string_array_t* source);
void print_string_array(string_array_t* source);
/*

 a[1:3] := b;

*/
void indexed_assign_string_array(string_array_t* source,
                                 string_array_t* dest,
                                 index_spec_t* spec);
void simple_indexed_assign_string_array1(string_array_t* source,
                                         int,
                                         string_array_t* dest);
void simple_indexed_assign_string_array2(string_array_t* source,
                                         int, int,
                                         string_array_t* dest);

/*

 a := b[1:3];

*/
void index_string_array(string_array_t* source,
                        index_spec_t* spec,
                        string_array_t* dest);
void index_alloc_string_array(string_array_t* source,
                              index_spec_t* spec,
                              string_array_t* dest);

void simple_index_alloc_string_array1(string_array_t* source, int i1,
                                      string_array_t* dest);

void simple_index_string_array1(string_array_t* source,
                                int,
                                string_array_t* dest);
void simple_index_string_array2(string_array_t* source,
                                int, int,
                                string_array_t* dest);

/* array(A,B,C) for arrays A,B,C */
void array_string_array(string_array_t* dest,int n,
                        string_array_t* first,...);
void array_alloc_string_array(string_array_t* dest,int n,
                              string_array_t* first,...);

/* array(s1,s2,s3)  for scalars s1,s2,s3 */
void array_scalar_string_array(string_array_t* dest,int n,
                               modelica_string_t first,...);
void array_alloc_scalar_string_array(string_array_t* dest,int n,
                                     modelica_string_t first,...);

modelica_string_t* string_array_element_addr(string_array_t* source,int ndims,
                                             ...);
modelica_string_t* string_array_element_addr1(string_array_t* source,int ndims,
                                              int dim1);
modelica_string_t* string_array_element_addr2(string_array_t* source,int ndims,
                                              int dim1,int dim2);

void cat_string_array(int k,string_array_t* dest, int n,
                      string_array_t* first,...);
void cat_alloc_string_array(int k,string_array_t* dest, int n,
                            string_array_t* first,...);

void promote_string_array(string_array_t* a, int n,string_array_t* dest);
void promote_scalar_string_array(modelica_string_t s,int n,
                                 string_array_t* dest);
void promote_alloc_string_array(string_array_t* a, int n,
                                string_array_t* dest);

static inline int ndims_string_array(string_array_t* a)
{ return ndims_base_array(a); }
static inline int size_of_dimension_string_array(string_array_t a, int i)
{ return size_of_dimension_base_array(a, i); }
typedef modelica_integer size_of_dimension_string_array_rettype;
static inline modelica_string_t *data_of_string_array(string_array_t *a)
{ return (modelica_string_t *) a->data; }

void size_string_array(string_array_t* a, string_array_t* dest);
modelica_string_t scalar_string_array(string_array_t* a);
void vector_string_array(string_array_t* a, string_array_t* dest);
void vector_string_scalar(modelica_string_t a,string_array_t* dest);
void matrix_string_array(string_array_t* a, string_array_t* dest);
void matrix_string_scalar(modelica_string_t a,string_array_t* dest);
void transpose_alloc_string_array(string_array_t* a, string_array_t* dest);
void transpose_string_array(string_array_t* a, string_array_t* dest);

void fill_string_array(string_array_t* dest,modelica_string_t s);

static inline size_t string_array_nr_of_elements(string_array_t *a)
{ return base_array_nr_of_elements(a); }

static inline void clone_reverse_string_array_spec(string_array_t *source,
                                                   string_array_t *dest)
{ clone_reverse_base_array_spec(source, dest); }
void convert_alloc_string_array_to_f77(string_array_t* a,
                                       string_array_t* dest);
void convert_alloc_string_array_from_f77(string_array_t* a,
                                         string_array_t* dest);

#endif
