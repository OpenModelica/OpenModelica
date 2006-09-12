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

#include "integer_array.h"
#include "index_spec.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

int integer_array_ok(integer_array_t* a)
{
    int i;
	if (!a) return 0;
    if (a->ndims < 0) return 0;
    if (!a->dim_size) return 0;
    for (i = 0; i < a->ndims; ++i) 
    {
	if (a->dim_size[i] < 0) return 0;
    }  
    return 1;
}


int integer_array_shape_eq(integer_array_t* a, integer_array_t* b)
{
    int i;

    if (a->ndims != b->ndims) 
      {
	fprintf(stderr,"a->ndims != b->ndims, %d != %d\n",a->ndims,b->ndims);
	return 0;
      }
    
    for (i = 0; i < a->ndims; ++i) 
    {
	if (a->dim_size[i] != b->dim_size[i]) 
	  {
	    fprintf(stderr,"a->dim_size[%d] != b->dim_size[%d], %d != %d\n",
		    i,i,a->dim_size[i],b->dim_size[i]);
	    return 0;
	  }
    }
    
    return 1;
}

int integer_array_one_element_ok(integer_array_t* a)
{
  int i;

  for (i = 0; i < a->ndims; ++i)
    {
      if (a->dim_size[i] != 1) return 0;
    }
  return 1;
}

int index_spec_fit_integer_array(index_spec_t* s, integer_array_t* a)
{
  int i,j;

  if (s->ndims != a->ndims) return 0;
  for (i = 0; i < s->ndims; ++i)
    {
      if (s->dim_size[i] == 0) 
	{
	  if ((s->index[i][0] <= 0) || (s->index[i][0] > a->dim_size[i]))
	    {
	      fprintf(stderr,
		      "scalar s->index[%d][0] == %d incorrect, a->dim_size[%d] == %d\n",
		      i,s->index[i][0],i,a->dim_size[i]);
	      return 0;
	    }
	}

      for (j = 0; j < s->dim_size[i]; ++j)
	{	  
	  if (s->index[i] && ((s->index[i][j] <= 0) ||
	      (s->index[i][j] > a->dim_size[i]))) 
	    {
	      fprintf(stderr,
		      "array s->index[%d][%d] == %d incorrect, a->dim_size[%d] == %d\n",
		      i,j,s->index[i][j],i,a->dim_size[i]);
	      return 0;	  
	    }
	}
    }

  return 1;
}

size_t integer_array_nr_of_elements(integer_array_t* a)
{
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i)
    {
	nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;

}
void simple_alloc_1d_integer_array(integer_array_t* dest, int n)
{
  dest->ndims = 1;
  dest->dim_size = size_alloc(1);
  dest->dim_size[0] = n;
  dest->data = integer_alloc(n);
}

void simple_alloc_2d_integer_array(integer_array_t* dest, int r, int c)
{
  dest->ndims = 2;
  dest->dim_size = size_alloc(2);
  dest->dim_size[0] = r;
  dest->dim_size[1] = c;
  dest->data = integer_alloc(r*c);
}

void alloc_integer_array(integer_array_t* dest,int ndims,...)
{
  
  int i;

  va_list ap;
  va_start(ap,ndims);
  
  dest->ndims = ndims;
  dest->dim_size = size_alloc(ndims);
    
  for (i = 0; i < ndims; ++i)
    {
      dest->dim_size[i] = va_arg(ap,int);
    }
  va_end(ap);
  
  dest->data = integer_alloc(integer_array_nr_of_elements(dest));

}


void alloc_integer_array_data(integer_array_t* a)
{
  size_t array_size;

  array_size = integer_array_nr_of_elements(a);
  a->data = integer_alloc(array_size);

  /*  size_t array_size;
  void* ptr;

  assert(integer_array_ok(a));
  array_size = integer_array_nr_of_elements(a) * sizeof(modelica_integer);
  ptr = malloc(array_size);
  assert(ptr);
  a->data = ptr;*/
  
}

void free_integer_array_data(integer_array_t* a)
{
  size_t array_size;

  assert(integer_array_ok(a));

  array_size = integer_array_nr_of_elements(a) * sizeof(modelica_integer);
  integer_free(array_size);
  /*  free(a->data);
      a->data = 0;*/
}

void clone_integer_array_spec(integer_array_t* source, integer_array_t* dest)
{
  int i;
  assert(integer_array_ok(source));

  dest->ndims = source->ndims;
  dest->dim_size = size_alloc(dest->ndims*sizeof(int));
  assert(dest->dim_size);
  
  for (i = 0; i < dest->ndims; ++i)
    {
      dest->dim_size[i] = source->dim_size[i];
    }
 /*  int i; */
/*   assert(integer_array_ok(source)); */

/*   dest->ndims = source->ndims; */
/*   dest->dim_size = malloc(dest->ndims*sizeof(int)); */
/*   assert(dest->dim_size); */

/*   for (i = 0; i < dest->ndims; ++i) */
/*     { */
/*       dest->dim_size[i] = source->dim_size[i]; */
/*     } */
/*   dest->data = 0; */

}

void copy_integer_array_data(integer_array_t* source, integer_array_t* dest)
{
  size_t i;
  size_t nr_of_elements;

  assert(integer_array_ok(source));
  assert(integer_array_ok(dest));
  assert(integer_array_shape_eq(source, dest));

  nr_of_elements = integer_array_nr_of_elements(source);

  for (i = 0; i < nr_of_elements; ++i)
  {
      dest->data[i] = source->data[i];
  }
  
}

/*

 a[1:3] := b;

*/

modelica_integer* calc_integer_index_spec(int ndims, size_t* idx_vec, integer_array_t* arr, index_spec_t* spec)
{
  /* idx_vec is zero based */
  /* spec is one based */
    int i;
    int d,d2;
    int index = 0;

    assert (integer_array_ok(arr));
    assert (index_spec_ok(spec));
    assert (index_spec_fit_integer_array(spec,arr));
    assert ((ndims == arr->ndims) && (ndims == spec->ndims));

    index = 0;
    for (i = 0; i < ndims; ++i)
    {
	d = idx_vec[i];
	if (spec->index[i])
	{
	    d2 = spec->index[i][d] - 1;
	}
	else 
	{
	    d2 = d;
	}
	index = index*arr->dim_size[i] + d2;
	
    }

    return arr->data + index;
}

/* Uses zero based indexing */
modelica_integer* calc_integer_index(int ndims, size_t* idx_vec, integer_array_t* arr)
{
  int i;
  int index;

  assert(ndims == arr->ndims);
  index = 0;
  for (i = 0; i < ndims; ++i)
    {
      /* Assert that idx_vec[i] is not out of bounds */
      index = index*arr->dim_size[i] + idx_vec[i]; 
    }
  
  return arr->data + index;
}

/* One based index*/
modelica_integer* calc_integer_index_va(integer_array_t* source,int ndims,va_list ap)
{
  int i;
  int index;
  int dim_i;

  index = 0;
  for (i = 0; i < ndims; ++i)
    {
      dim_i = va_arg(ap,int)-1;
      index = index*source->dim_size[i]+dim_i;
    }

  return source->data+index;
}
void print_integer_matrix(integer_array_t* source)
{
  size_t i,j;
  double value;

  if (source->ndims == 2)
    {
      for (i = 0; i < source->dim_size[0];++i)
	{
	  for (j = 0; j < source->dim_size[1];++j)
	    {
	      value = source->data[i*source->dim_size[1]+j];
	      printf("%e\t",value);
	    }
	  printf("\n");
	}
    }
}

void print_integer_array(integer_array_t* source)
			       
{
    size_t i,j,k,n;
    modelica_integer* data;	
    assert(integer_array_ok(source));

    data = source->data;
    if (source->ndims == 1)
    {
	for (i = 0; i < source->dim_size[0]; ++i)
	{
	    printf("%d",*data);
	    ++data;
	    if (i+1 < source->dim_size[0])
	    {
		printf(", ");
	    }
	}
    }
    else if (source->ndims > 1)
    {
	n = integer_array_nr_of_elements(source) / 
	    (source->dim_size[0]*source->dim_size[1]);
	for (k = 0; k < n; ++k)
	{
	    for (i = 0; i < source->dim_size[1]; ++i)
	    {
		for (j = 0; j < source->dim_size[0]; ++j)
		{
		    printf("%d",*data);
		    ++data;
		    if (j+1 < source->dim_size[0])
		    {
			printf(", ");
		    }
		}
		printf("\n");
	    }
	    if (k+1 < n)
	    {
		printf("\n ================= \n");
	    }
	}
    }
    
}


void put_integer_element(modelica_integer value,int i1,integer_array_t* dest)
{
  /* Assert that dest has correct dimension */
  /* Assert that i1 is a valid index */
  dest->data[i1] = value;
}

void put_integer_matrix_element(modelica_integer value, int r, int c, integer_array_t* dest)
{
  /* Assert that dest hast correct dimension */
  /* Assert that r and c are valid indices */
  dest->data[r*dest->dim_size[1]+c] = value;
  printf("Index %d\n",r*dest->dim_size[1]+c);
}

/* Zero based index */
void simple_indexed_assign_integer_array1(integer_array_t* source, 
				       int i1,
				       integer_array_t* dest)
{
  /* Assert that source has the correct dimension */
  /* Assert that dest has the correct dimension */
  
  dest->data[i1] = source->data[i1]; 
}

void simple_indexed_assign_integer_array2(integer_array_t* source, 
				       int i1, int i2, 
				       integer_array_t* dest)
{
  size_t size_j;
  /* Assert that source has correct dimension */
  /* Assert that dest has correct dimension */
  size_j = source->dim_size[1];

  dest->data[i1*size_j+i2] = source->data[i1*size_j+i2];
}

void indexed_assign_integer_array(integer_array_t* source, 
			       integer_array_t* dest,
			       index_spec_t* dest_spec)
{
  
    size_t* idx_vec1;
    size_t* idx_vec2;
    size_t* idx_size;
    int quit;
    int i,j;
    state mem_state;

    assert(integer_array_ok(source));
    assert(integer_array_ok(dest));
    assert(index_spec_ok(dest_spec));
    assert(index_spec_fit_integer_array(dest_spec, dest));
    for (i = 0,j = 0; i < dest_spec->ndims; ++i) 
      if (dest_spec->dim_size[i] != 0) ++j;
    assert(j == source->ndims);

    mem_state = get_memory_state();
    idx_vec1 = (size_t *)size_alloc(dest->ndims);
    idx_vec2 = (size_t *)size_alloc(source->ndims);
    idx_size = (size_t *)size_alloc(dest_spec->ndims);

    for (i = 0; i < dest_spec->ndims; ++i)
      {
	idx_vec1[i] = 0;

	if (dest_spec->index[i])
	  idx_size[i] = imax(dest_spec->dim_size[i],1);
	else
	  idx_size[i] = dest->dim_size[i];
      }
    
    quit = 0;
    while(1)
      {
	for (i = 0,j=0; i < dest_spec->ndims; ++i) 
	  {
	    if (dest_spec->dim_size[i] != 0) 
	      {
		idx_vec2[j] = idx_vec1[i];
		++j;
	      }
	  }

	*calc_integer_index_spec(dest->ndims,idx_vec1,dest,dest_spec) =
	  *calc_integer_index(source->ndims,idx_vec2, source);

	quit = next_index(dest_spec->ndims,idx_vec1,idx_size);

	if (quit) break;
    }
    
    restore_memory_state(mem_state);
    
}

/*

 a := b[1:3];

*/


void index_integer_array(integer_array_t* source, 
		      index_spec_t* source_spec, 
		      integer_array_t* dest)
{
    size_t* idx_vec1;
    size_t* idx_vec2;
    size_t* idx_size;
    int quit;
    int j;
    int i;
    state mem_state;


    assert(integer_array_ok(source));
    assert(integer_array_ok(dest));
    assert(index_spec_ok(source_spec));
    assert(index_spec_fit_integer_array(source_spec,source));
    for (i = 0,j=0; i < source->ndims; ++i) 
      if (source_spec->dim_size[i] != 0) ++j;
    assert(j == dest->ndims);

    mem_state = get_memory_state();
    idx_vec1 = (size_t *)size_alloc(source->ndims);
    idx_vec2 = (size_t *)size_alloc(dest->ndims);
    idx_size = (size_t *)size_alloc(source_spec->ndims);

    for (i = 0; i < source->ndims; ++i) idx_vec1[i] = 0;
    for (i = 0; i < source_spec->ndims; ++i)
      {
	if (source_spec->index[i])
	  idx_size[i] = imax(source_spec->dim_size[i],1);
	else
	  idx_size[i] = source->dim_size[i];
      }

    quit = 0;
    while(1)
      {
	for (i = 0,j=0; i < source->ndims; ++i) {
	  if (source_spec->dim_size[i] != 0) {
	    idx_vec2[j] = idx_vec1[i];
	    ++j;
	  }
	}
		
	*calc_integer_index(dest->ndims,idx_vec2, dest) 
	  = *calc_integer_index_spec(source->ndims,idx_vec1, source,source_spec);

	quit = next_index(source->ndims,idx_vec1,idx_size);
	if (quit) break;
    }

    restore_memory_state(mem_state);
  
}

void index_alloc_integer_array(integer_array_t* source, 
			       index_spec_t* source_spec, 
			       integer_array_t* dest)
{
  int i;
  int j;
  int ndimsdiff;

  assert(integer_array_ok(source));
  assert(index_spec_ok(source_spec));
  assert(index_spec_fit_integer_array(source_spec,source));

  ndimsdiff = 0;
  for (i = 0; i < source_spec->ndims; ++i)
    {
      if (source_spec->dim_size[i] == 0) ndimsdiff--;
    }

  dest->ndims = source->ndims + ndimsdiff;
  dest->dim_size = size_alloc(dest->ndims);

  for (i = 0,j = 0; i < dest->ndims; ++i)
    {
      while (source_spec->dim_size[i+j] == 0) ++j;
      if (source_spec->index[i+j] == 0)
	{
	  dest->dim_size[i] = source->dim_size[i+j];
	}
      else
	{
	  dest->dim_size[i] = source_spec->dim_size[i+j];
	}
    }

  alloc_integer_array_data(dest);

  index_integer_array(source,source_spec,dest);

}


/* Returns dest := source[i1,:,:...]*/
void simple_index_alloc_integer_array1(integer_array_t* source,int i1,integer_array_t* dest)
{
  

}

void simple_index_integer_array1(integer_array_t* source, 
				       int i1, 
				       integer_array_t* dest)
{
  

}

void simple_index_integer_array2(integer_array_t* source, 
				       int i1, int i2, 
				       integer_array_t* dest)
{
}

void array_integer_array(integer_array_t* dest,int n,integer_array_t* first,...)
{

}

void array_alloc_integer_array(integer_array_t* dest,int n,integer_array_t* first,...)
{

}

void array_scalar_integer_array(integer_array_t* dest,int n,modelica_integer first,...)
{
  int i;
  va_list ap;

  va_start(ap,first);
  
  dest->ndims = 1;
  dest->dim_size = integer_alloc(1);
  dest->dim_size[0]=n;
  dest->data = integer_alloc(n);
  
  dest->data[0] = first;
  for (i = 1; i < n; ++i)
    {
      dest->data[i] = va_arg(ap,int);
    }
  va_end(ap);

}

/* Allocate space for array of arrays
 * Author: KN
 * 
 */
void array_alloc_scalar_integer_array(integer_array_t* dest,int n,modelica_integer first,...)
{
  int i;
  va_list ap;
  simple_alloc_1d_integer_array(dest,n);
  va_start(ap,first);      
  put_integer_element(first,0,dest);
  for (i = 1; i < n; ++i)
    {
      put_integer_element(va_arg(ap,m_integer),i,dest);
    }
  va_end(ap);
}

modelica_integer* integer_array_element_addr1(integer_array_t* source,int ndims,int dim1)
{
  return source->data+dim1-1;
}

modelica_integer* integer_array_element_addr2(integer_array_t* source,int ndims,int dim1,int dim2)
{
  return source->data+(dim1-1)*source->dim_size[1]+dim2-1;
}

m_integer* integer_array_element_addr(integer_array_t* source,int ndims,...)
{
  va_list ap;
  m_integer* tmp;

  va_start(ap,ndims);
  tmp = calc_integer_index_va(source,ndims,ap);
  va_end(ap);
  
  return tmp;
}


void cat_integer_array(int k, integer_array_t* dest,  int n, integer_array_t* first,...)
{
  assert(0 && "Not implemented yet");
}
void cat_alloc_integer_array(int k, integer_array_t* dest, int n, integer_array_t* first,...)
{
  assert(0 && "Not implemented yet");
}


void range_alloc_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array_t* dest)
{
  int n;

  n = floor((stop-start)/inc)+1;
  simple_alloc_1d_integer_array(dest,n);
  range_integer_array(start,stop,inc,dest);
}

void range_integer_array(modelica_integer start, modelica_integer stop, modelica_integer inc, integer_array_t* dest)
{
  int i;
  /* Assert that dest has correct size */
  for (i = 0; i < dest->dim_size[0]; ++i)
    {
      dest->data[i] = start + i*inc; 
    } 
}

void add_integer_array(integer_array_t* a, integer_array_t* b, integer_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;

  /* Assert a and b are of the same size */
  /* Assert that dest are of correct size */
  nr_of_elements = integer_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]+b->data[i];
    }
}

void add_alloc_integer_array(integer_array_t* a, integer_array_t* b,integer_array_t* dest)
{
  clone_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  add_integer_array(a,b,dest);
}


void sub_integer_array(integer_array_t* a, integer_array_t* b, integer_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;

  /* Assert a and b are of the same size */
  /* Assert that dest are of correct size */
  nr_of_elements = integer_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]-b->data[i];
    }
}

void sub_alloc_integer_array(integer_array_t* a, integer_array_t* b,integer_array_t* dest)
{
  clone_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  sub_integer_array(a,b,dest);
}



void mul_scalar_integer_array(modelica_integer a,integer_array_t* b,integer_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  nr_of_elements = integer_array_nr_of_elements(b);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a*b->data[i];
    }
}

void mul_alloc_scalar_integer_array(modelica_integer a,integer_array_t* b,integer_array_t* dest)
{
  clone_integer_array_spec(b,dest);
  alloc_integer_array_data(dest);
  mul_scalar_integer_array(a,b,dest);
}

void mul_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  nr_of_elements = integer_array_nr_of_elements(a);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]*b;
    }
}

void mul_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest)
{
    clone_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  mul_integer_array_scalar(a,b,dest);
}


double mul_integer_scalar_product(integer_array_t* a, integer_array_t* b)
{
  size_t nr_of_elements;
  size_t i;
  double res;
  /* Assert that a and b are vectors */
  /* Assert that vectors are of matching size */
  
  nr_of_elements = integer_array_nr_of_elements(a);
  res = 0.0;
  for (i = 0; i < nr_of_elements; ++i)
    {
      res += a->data[i]*b->data[i];
    }
    return res;
}

void mul_integer_matrix_product(integer_array_t* a,integer_array_t* b,integer_array_t* dest)
{
  double tmp;
  size_t i_size;
  size_t j_size;
  size_t k_size;
  size_t i;
  size_t j;
  size_t k;


  /* Assert that dest har correct size */
  i_size = dest->dim_size[0];
  j_size = dest->dim_size[1];
  k_size = a->dim_size[1];

  for (i = 0; i < i_size; ++i)
    {
      for (j = 0; j < j_size; ++j)
	{
	  tmp = 0;
          for (k = 0; k < k_size; ++k)
	    {
	      tmp += a->data[i*k_size+k]*b->data[k*j_size+j]; 
	    }
	  dest->data[i*j_size+j] = tmp;
	}
    }
}

void mul_integer_matrix_vector(integer_array_t* a, integer_array_t* b,integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t i_size;
  size_t j_size;
  double tmp;

  /* Assert a matrix */
  /* Assert b vector */
  /* Assert dest correct size (a vector)*/

  i_size = a->dim_size[0];
  j_size = a->dim_size[1];

  for (i = 0; i < i_size; ++i)
    {
      tmp = 0;
      for (j = 0; j < j_size; ++j)
	{
	  tmp += a->data[i*j_size+j]*b->data[j];
	}
      dest->data[i] = tmp;
    }
}


void mul_integer_vector_matrix(integer_array_t* a, integer_array_t* b,integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t i_size;
  size_t j_size;
  double tmp;

  /* Assert a vector */
  /* Assert b matrix */
  /* Assert dest vector of correct size */
  
  i_size = a->dim_size[0];
  j_size = b->dim_size[1];
  
  for (i = 0; i < i_size; ++i)
    {
      tmp = 0;
      for (j = 0; j < j_size; ++j)
	{
	  tmp += a->data[j]*b->data[j*j_size+i];
	}
      dest->data[i] = tmp;
    }
}

void mul_alloc_integer_matrix_product_smart(integer_array_t* a, integer_array_t* b, integer_array_t* dest)
{

  
  if ((a->ndims == 1) && (b->ndims == 2))
    {
      simple_alloc_1d_integer_array(dest,b->dim_size[1]);
      mul_integer_vector_matrix(a,b,dest);
      
    }
  else if ((a->ndims == 2) && (b->ndims == 1))
    {
      simple_alloc_1d_integer_array(dest,a->dim_size[0]);
      mul_integer_matrix_vector(a,b,dest);
    }
  else if ((a->ndims == 2) && (b->ndims == 2))
    {
      simple_alloc_2d_integer_array(dest,a->dim_size[0],b->dim_size[1]);
      mul_integer_matrix_product(a,b,dest);
    }
  else
    {
      printf("Invalid size of matrix\n");
    }
}


void div_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  /* Do we need to check for b=0? */
  nr_of_elements = integer_array_nr_of_elements(a);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]/b;
    }
}

void div_alloc_integer_array_scalar(integer_array_t* a,modelica_integer b,integer_array_t* dest)
{
  clone_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  div_integer_array_scalar(a,b,dest);
}


void exp_integer_array(integer_array_t* a, modelica_integer n, integer_array_t* dest)
{
  size_t i;

  /* Assert n>=0 */
  /* Assert a matrix */
  /* Assert square matrix */

  if (n==0) 
    {
      identity_integer_array(a->dim_size[0],dest);
    }
  else
    { 
      if (n==1)
	{
	  clone_integer_array_spec(a,dest);
	  copy_integer_array_data(a,dest);
	}
      else
	{
	  integer_array_t* tmp = 0;
	  clone_integer_array_spec(a,tmp);
	  copy_integer_array_data(a,tmp);
	  for ( i = 1; i < n; ++i)
	    {
	      mul_integer_matrix_product(a,tmp,dest);
	      copy_integer_array_data(dest,tmp);
	    }
	  free_integer_array_data(tmp);
	}
    }
}

void exp_alloc_integer_array(integer_array_t* a,modelica_integer b,integer_array_t* dest)
{
  clone_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  exp_integer_array(a,b,dest);
}

void promote_integer_array(integer_array_t* a, int n,integer_array_t* dest)
{
  size_t i;
  
  dest->dim_size = size_alloc(n);
  dest->data = a->data;
  /*Assert a->ndims>=n */
  for (i = 0; i < a->ndims; ++i)
    {
      dest->dim_size[i] = a->dim_size[i];
    }
  for (i = a->ndims; i < n; ++i)
    {
      dest->dim_size[i] = 1;
    }
  dest->ndims=n;
}

/* function: promote_scalar_integer_array
 *
 * promotes a scalar value to an n dimensional array.
 */
 void promote_scalar_integer_array(double s,int n,integer_array_t* dest)
{
  size_t i;
  
  /* Assert that dest is of correct dimension */
  
  /* Alloc size */
  dest->dim_size = size_alloc(n);
  /*Alloc data */
  dest->data = integer_alloc(1);

  dest->data[0] = s;
  for (i = 0; i < n; ++i)
    {
      dest->dim_size[i] = 1;
    }
}

int ndims_integer_array(integer_array_t* a)
{
  assert(integer_array_ok(a));

  return a->ndims;
}

int size_of_dimension_integer_array(integer_array_t a, int i)
{

  assert(integer_array_ok(&a));
  assert((i > 0) && (i <= a.ndims));

  return a.dim_size[i-1];
}


void size_integer_array(integer_array_t* a, integer_array_t* dest)
{
  /* This should be an integer data instead */
  /*copy_integer_array_data(a->dim_size,dest); */
  dest = a;
}

double scalar_integer_array(integer_array_t* a)
{
  assert(integer_array_ok(a));
  assert(integer_array_one_element_ok(a));

  return a->data[0];
}

void vector_integer_array(integer_array_t* a,integer_array_t* dest)
{
  size_t i;
  size_t nr_of_elements;

  /* Assert that a has at most one dimension with dim_size>1*/

  nr_of_elements = integer_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i];
    } 
}

void vector_integer_scalar(double a,integer_array_t* dest)
{
  /* Assert that dest is a 1-vector */
  dest->data[0] = a;
}

void matrix_integer_array(integer_array_t* a, integer_array_t* dest)
{
  size_t i;
  /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
  dest->dim_size[0] = a->dim_size[0];
  dest->dim_size[1] = (a->ndims < 2)? 1 : a->dim_size[1];
  
  for (i = 0; i < dest->dim_size[0]*dest->dim_size[1]; ++i)
    {
      dest->data[i] = a->data[i];
    }
}

void matrix_integer_scalar(double a,integer_array_t* dest)
{
  dest->ndims = 2;
  dest->dim_size[0] = 1;
  dest->dim_size[1] = 1;
  dest->data[0] = a;
}

void transpose_integer_array(integer_array_t* a, integer_array_t* dest)
{
  size_t i;
  size_t j;
  /*  size_t k;*/
  size_t n,m;

  if (a->ndims == 1) {
    copy_integer_array_data(a,dest);
    return;
  }

  assert(a->ndims==2 && dest->ndims==2);

  n = a->dim_size[0];
  m = a->dim_size[1];

  assert(dest->dim_size[0] == m && dest->dim_size[1] == n);
  
  for (i = 0; i < n; ++i) {
    for (j = 0; j < m; ++j) {
      dest->data[j*n+i] = a->data[i*m+j];
    }
  }
}

void outer_product_integer_array(integer_array_t* v1,integer_array_t* v2,integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t number_of_elements_a;
  size_t number_of_elements_b;
  
  number_of_elements_a = integer_array_nr_of_elements(v1);
  number_of_elements_b = integer_array_nr_of_elements(v2);

  /* Assert a is a vector */
  /* Assert b is a vector */

  for (i = 0; i < number_of_elements_a; ++i)
    {
      for (j = 0; i < number_of_elements_b; ++j)
	{
	  dest->data[i*number_of_elements_b + j] = v1->data[i]*v2->data[j];
	}
    }
}

void identity_integer_array(int n, integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;
  
  assert(integer_array_ok(dest));
  
  /* Check that dest size is ok */
  if (dest->ndims!=2) 
    exit(0);

  if ((dest->dim_size[0]!=n) || (dest->dim_size[1]!=n))
    exit(0);

  nr_of_elements = integer_array_nr_of_elements(dest);
  
  for (i=0;i < nr_of_elements;++i)
    {
      for ( j = 0;j <= nr_of_elements; ++j)
	{
	  dest->data[i*n+j] = i==j? 1:0;
	}
    }
}

void diagonal_integer_array(integer_array_t* v,integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;

  /* Assert that v is a vector */
  nr_of_elements = integer_array_nr_of_elements(v);

  for (i = 0; i < nr_of_elements; ++i)
    {
      for (j = 0; j < nr_of_elements;++j)
      {
	dest->data[i*nr_of_elements+j] = (i==j)?v->data[i]:0;
      }
    }
}

void fill_integer_array(integer_array_t* dest,modelica_integer s)
{
  size_t nr_of_elements;
  size_t i;

  nr_of_elements = integer_array_nr_of_elements(dest);  
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = s;
    }
}

void linspace_integer_array(double x1, double x2, int n,integer_array_t* dest)
{
  size_t i;

  /* Assert n>=2 */

  for (i = 0; i < n-1; ++i)
    {
      dest->data[i] = x1 + (x2-x1)*(i-1)/(n-1);
    }
}

double max_integer_array(integer_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double max_element;
  
  assert(integer_array_ok(a));

  nr_of_elements = integer_array_nr_of_elements(a);

  if (nr_of_elements > 0)
    {
      max_element = a->data[0];
      for (i = 1; i < nr_of_elements; ++i)
	{
	  if (max_element < a->data[i])
	    {
	      max_element = a->data[i];
	    }
	}
    }
  
  return max_element;
}

double min_integer_array(integer_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double min_element;
  
  assert(integer_array_ok(a));

  nr_of_elements = integer_array_nr_of_elements(a);

  if (nr_of_elements > 0)
    {
      min_element = a->data[0];
      for (i = 1; i < nr_of_elements; ++i)
	{
	  if (min_element > a->data[i])
	    {
	      min_element = a->data[i];
	    }
	}
    }
  
  return min_element;
}

double sum_integer_array(integer_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double sum = 0;

  assert(integer_array_ok(a));

  nr_of_elements = integer_array_nr_of_elements(a);
  
  for (i=0;i < nr_of_elements;++i)
    {
      sum += a->data[i];
    }

  return sum;
}

double product_integer_array(integer_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double product = 0;
  
  assert(integer_array_ok(a));

  nr_of_elements = integer_array_nr_of_elements(a);
  
  for (i=0;i < nr_of_elements;++i)
    {
      product *= a->data[i];
    }

  return product;
  
}

void symmetric_integer_array(integer_array_t* a,integer_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;

  nr_of_elements = integer_array_nr_of_elements(a);
 
  /* Assert that a is a two dimensional square array */
  /* Assert that dest is a two dimensional square array */
  for (i = 0; i < nr_of_elements; ++i)
    {
      for (j = 0; j < nr_of_elements; ++j)
	{
	  if ( i <= j)
	    {
	      dest->data[i*nr_of_elements + j] = a->data[i*nr_of_elements + j];
	    }
	  else
	    {
	      dest->data[i*nr_of_elements + j] = a->data[j*nr_of_elements+i];
	    }
	}
    }
}

void cross_integer_array(integer_array_t* x,integer_array_t* y, integer_array_t* dest)
{
  /* Assert x and y are vectors */
  /* Assert x and y have size 3 */
  /* Assert dest is a vector */
  /* Assert that dest have size 3*/
  
  dest->data[0] = x->data[1]*y->data[2]-x->data[2]*y->data[1];
  dest->data[1] = x->data[2]*y->data[0]-x->data[0]*y->data[2];
  dest->data[2] = x->data[0]*y->data[1]-x->data[1]*y->data[0];
}

void skew_integer_array(integer_array_t* x,integer_array_t* dest)
{
  /* Assert x vector*/
  /* Assert x has size 3*/
  /* Assert dest is 3x3*/
  dest->data[0] = 0;
  dest->data[1] = -x->data[2];
  dest->data[2] = x->data[1];
  dest->data[3] = x->data[2];
  dest->data[4] = 0;
  dest->data[5] = -x->data[0];
  dest->data[6] = x->data[1];
  dest->data[7] = x->data[0];
  dest->data[6] = 0;
}

/* integer_array_make_index_array
 *
 * Creates an integer array if indices to be used by e.g.
 ** create_index_spec defined in index_spec.c
 */

int* integer_array_make_index_array(integer_array_t *arr)
{ 
  return arr->data;
}


void clone_reverse_integer_array_spec(integer_array_t* source, integer_array_t* dest)
{
  int i;
  assert(integer_array_ok(source));

  dest->ndims = source->ndims;
  dest->dim_size = size_alloc(dest->ndims*sizeof(int));
  assert(dest->dim_size);
  
  for (i = 0; i < dest->ndims; ++i)
  {
    dest->dim_size[i] = source->dim_size[dest->ndims - 1 - i];
  }
}

void convert_alloc_integer_array_to_f77(integer_array_t* a, integer_array_t* dest) 
{
  int i;
  clone_reverse_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  transpose_integer_array (a,dest);
  for (i = 0; i < dest->ndims; ++i)
  {
    dest->dim_size[i] = a->dim_size[i];
  }
}

void convert_alloc_integer_array_from_f77(integer_array_t* a, integer_array_t* dest)
{
  int i;
  clone_reverse_integer_array_spec(a,dest);
  alloc_integer_array_data(dest);
  for (i = 0; i < dest->ndims; ++i)
  {
    size_t tmp = dest->dim_size[i];
    dest->dim_size[i] = a->dim_size[i];
    a->dim_size[i] = tmp;
  }
  transpose_integer_array (a,dest);
 }

