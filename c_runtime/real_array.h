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


#ifndef REAL_ARRAY_H_
#define REAL_ARRAY_H_

#include "integer_array.h"
#include "index_spec.h"
#include "memory_pool.h"
#include <stdio.h>
#include <stdarg.h>
#include <math.h>

typedef double modelica_real;

struct real_array_s
{
  int ndims;
  int* dim_size;
  modelica_real* data;
};

typedef struct real_array_s real_array_t;


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
void clone_real_array_spec(real_array_t* source, real_array_t* dest);

/* Copy real data*/
void copy_real_array_data(real_array_t* source, real_array_t* dest);

/* Copy real array*/
void copy_real_array(real_array_t* source, real_array_t* dest);

real* calc_real_index(int ndims,size_t* idx_vec,real_array_t* arr);
real* calc_real_index_va(real_array_t* source,int ndims,va_list ap);

void put_real_element(real value,int i1,real_array_t* dest);
void put_real_matrix_element(real value, int r, int c, real_array_t* dest);

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

void simple_index_alloc_real_array1(real_array_t* source,int i1,real_array_t* dest);

void simple_index_real_array1(real_array_t* source, 
				       int, 
				       real_array_t* dest);
void simple_index_real_array2(real_array_t* source, 
				       int, int, 
				       real_array_t* dest);

void array_real_array(real_array_t* dest,int n,real_array_t* first,...);
void array_alloc_real_array(real_array_t* dest,int n,real_array_t* first,...);

void array_scalar_real_array(real_array_t* dest,int n,real first,...);
void array_alloc_scalar_real_array(real_array_t* dest,int n,real first,...);

real* real_array_element_addr(real_array_t* source,int ndims,...);
real* real_array_element_addr1(real_array_t* source,int ndims,int dim1);
real* real_array_element_addr2(real_array_t* source,int ndims,int dim1,int dim2);

void cat_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);
void cat_alloc_real_array(int k,real_array_t* dest, int n, real_array_t* first,...);

void range_alloc_real_array(real start,real stop,real inc,real_array_t* dest);
void range_real_array(real start,real stop, real inc,real_array_t* dest);

void add_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest);
void add_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);

void sub_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);
void sub_alloc_real_array(real_array_t* a, real_array_t* b, real_array_t* dest);


void mul_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest);
void mul_alloc_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest);

void mul_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);
void mul_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);

double mul_real_scalar_product(real_array_t* a, real_array_t* b);

void mul_real_matrix_product(real_array_t*a,real_array_t*b,real_array_t*dest);
void mul_real_matrix_vector(real_array_t* a, real_array_t* b,real_array_t* dest);
void mul_real_vector_matrix(real_array_t* a, real_array_t* b,real_array_t* dest);
void mul_alloc_real_matrix_product_smart(real_array_t* a, real_array_t* b, real_array_t* dest);

void div_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);
void div_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest);

void exp_real_array(real_array_t* a, modelica_integer b, real_array_t* dest);
void exp_alloc_real_array(real_array_t* a, modelica_integer b, real_array_t* dest);

void promote_real_array(real_array_t* a, int n,real_array_t* dest);
void promote_scalar_real_array(double s,int n,real_array_t* dest);

int ndims_real_array(real_array_t* a);
int size_of_dimension_real_array(real_array_t a, int i);
typedef modelica_integer size_of_dimension_real_array_rettype;

void size_real_array(real_array_t* a,real_array_t* dest);
double scalar_real_array(real_array_t* a);
void vector_real_array(real_array_t* a, real_array_t* dest);
void vector_real_scalar(double a,real_array_t* dest);
void matrix_real_array(real_array_t* a, real_array_t* dest);
void matrix_real_scalar(double a,real_array_t* dest);
void transpose_real_array(real_array_t* a, real_array_t* dest);
void outer_product_real_array(real_array_t* v1,real_array_t* v2,real_array_t* dest);
void identity_real_array(int n, real_array_t* dest);
void diagonal_real_array(real_array_t* v,real_array_t* dest);
void fill_real_array(real_array_t* dest,modelica_real s);
void linspace_real_array(double x1,double x2,int n,real_array_t* dest);
double min_real_array(real_array_t* a);
double max_real_array(real_array_t* a);
double sum_real_array(real_array_t* a);
double product_real_array(real_array_t* a);
void symmetric_real_array(real_array_t* a,real_array_t* dest);
void cross_real_array(real_array_t* x,real_array_t* y, real_array_t* dest);
void skew_real_array(real_array_t* x,real_array_t* dest);

size_t real_array_nr_of_elements(real_array_t* a);

void clone_reverse_real_array_spec(real_array_t* source, real_array_t* dest);
void convert_alloc_real_array_to_f77(real_array_t* a, real_array_t* dest);
void convert_alloc_real_array_from_f77(real_array_t* a, real_array_t* dest);

#endif
