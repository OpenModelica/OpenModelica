/*
    Copyright PELAB, Linkoping University

    This file is part of Open Source Modelica (OSM).

    OSM is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    OSM is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with Foobar; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

*/

#ifndef INTEGER_ARRAY_H_
#define INTEGER_ARRAY_H_

#include "index_spec.h"
#include "memory_pool.h"
#include <stdio.h>
#include <stdarg.h>
#include <math.h>

typedef int modelica_integer;

struct integer_array_s
{
  int ndims;
  int* dim_size;
  modelica_integer* data;
};

typedef struct integer_array_s integer_array_t;

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
void clone_integer_array_spec(integer_array_t* source, integer_array_t* dest);

/* Copy integer data*/
void copy_integer_array_data(integer_array_t* source, integer_array_t* dest);

modelica_integer* calc_integer_index(int ndims,size_t* idx_vec,integer_array_t* arr);
modelica_integer* calc_integer_index_va(integer_array_t* source,int ndims,va_list ap);

void put_integer_element(modelica_integer value,int i1,integer_array_t* dest);
void put_integer_matrix_element(modelica_integer value, int r, int c, integer_array_t* dest);

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

void simple_index_alloc_integer_array1(integer_array_t* source,int i1,integer_array_t* dest);

void simple_index_integer_array1(integer_array_t* source, 
				       int, 
				       integer_array_t* dest);
void simple_index_integer_array2(integer_array_t* source, 
				       int, int, 
				       integer_array_t* dest);

void array_integer_array(integer_array_t* dest,int n,integer_array_t* first,...);
void array_alloc_integer_array(integer_array_t* dest,int n,integer_array_t* first,...);

void array_scalar_integer_array(integer_array_t* dest,int n,modelica_integer first,...);
void array_alloc_scalar_integer_array(integer_array_t* dest,int n,modelica_integer first,...);

modelica_integer* integer_array_element_addr(integer_array_t* source,int ndims,...);
modelica_integer* integer_array_element_addr1(integer_array_t* source,int ndims,int dim1);
m_integer* integer_array_element_addr2(integer_array_t* source,int ndims,int dim1,int dim2);

void cat_integer_array(int k,integer_array_t* dest, int n, integer_array_t* first,...);
void cat_alloc_integer_array(int k,integer_array_t* dest, int n, integer_array_t* first,...);

void range_alloc_integer_array(modelica_integer start,modelica_integer stop,modelica_integer inc,integer_array_t* dest);
void range_integer_array(modelica_integer start,modelica_integer stop, modelica_integer inc,integer_array_t* dest);

void add_alloc_integer_array(integer_array_t* a, integer_array_t* b,integer_array_t* dest);
void add_integer_array(integer_array_t* a, integer_array_t* b, integer_array_t* dest);

void sub_integer_array(integer_array_t* a, integer_array_t* b, integer_array_t* dest);
void sub_alloc_integer_array(integer_array_t* a, integer_array_t* b, integer_array_t* dest);


void mul_scalar_integer_array(modelica_integer a,integer_array_t* b,integer_array_t* dest);
void mul_alloc_scalar_integer_array(modelica_integer a,integer_array_t* b,integer_array_t* dest);

void mul_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest);
void mul_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest);

double mul_integer_scalar_product(integer_array_t* a, integer_array_t* b);

void mul_integer_matrix_product(integer_array_t*a,integer_array_t*b,integer_array_t*dest);
void mul_integer_matrix_vector(integer_array_t* a, integer_array_t* b,integer_array_t* dest);
void mul_integer_vector_matrix(integer_array_t* a, integer_array_t* b,integer_array_t* dest);
void mul_alloc_integer_matrix_product_smart(integer_array_t* a, integer_array_t* b, integer_array_t* dest);

void div_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest);
void div_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest);

void exp_integer_array(integer_array_t* a, modelica_integer b, integer_array_t* dest);
void exp_alloc_integer_array(integer_array_t* a, modelica_integer b, integer_array_t* dest);

void promote_integer_array(integer_array_t* a, int n,integer_array_t* dest);
void promote_scalar_integer_array(double s,int n,integer_array_t* dest);
void promote_alloc_integer_array(integer_array_t* a, int n, integer_array_t* dest);

int ndims_integer_array(integer_array_t* a);
int size_of_dimension_integer_array(integer_array_t a, int i);
typedef modelica_integer size_of_dimension_integer_array_rettype;

void size_integer_array(integer_array_t* a,integer_array_t* dest);
double scalar_integer_array(integer_array_t* a);
void vector_integer_array(integer_array_t* a, integer_array_t* dest);
void vector_integer_scalar(double a,integer_array_t* dest);
void matrix_integer_array(integer_array_t* a, integer_array_t* dest);
void matrix_integer_scalar(double a,integer_array_t* dest);
void transpose_integer_array(integer_array_t* a, integer_array_t* dest);
void transpose_alloc_integer_array(integer_array_t* a, integer_array_t* dest);
void outer_product_integer_array(integer_array_t* v1,integer_array_t* v2,integer_array_t* dest);
void identity_integer_array(int n, integer_array_t* dest);
void diagonal_integer_array(integer_array_t* v,integer_array_t* dest);
void fill_integer_array(integer_array_t* dest,modelica_integer s);
void linspace_integer_array(double x1,double x2,int n,integer_array_t* dest);
double min_integer_array(integer_array_t* a);
double max_integer_array(integer_array_t* a);
double sum_integer_array(integer_array_t* a);
double product_integer_array(integer_array_t* a);
void symmetric_integer_array(integer_array_t* a,integer_array_t* dest);
void cross_integer_array(integer_array_t* x,integer_array_t* y, integer_array_t* dest);
void skew_integer_array(integer_array_t* x,integer_array_t* dest);

size_t integer_array_nr_of_elements(integer_array_t* a);

int* integer_array_make_index_array(integer_array_t *arr);

void clone_reverse_integer_array_spec(integer_array_t* source, integer_array_t* dest);
void convert_alloc_integer_array_to_f77(integer_array_t* a, integer_array_t* dest);
void convert_alloc_integer_array_from_f77(integer_array_t* a, integer_array_t* dest);

#endif
