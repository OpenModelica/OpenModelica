#include "real_array.h"
#include "index_spec.h"
#include "integer_array.h"
#include "memory_pool.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

int real_array_ok(real_array_t* a)
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


int real_array_shape_eq(real_array_t* a, real_array_t* b)
{
    int i;

    if (a->ndims != b->ndims) return 0;
    
    for (i = 0; i < a->ndims; ++i) 
    {
	if (a->dim_size[i] != b->dim_size[i]) return 0;
    }
    
    return 1;
}

int real_array_one_element_ok(real_array_t* a)
{
  int i;

  for (i = 0; i < a->ndims; ++i)
    {
      if (a->dim_size[i] != 1) return 0;
    }
  return 1;
}

size_t real_array_nr_of_elements(real_array_t* a)
{
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i)
    {
	nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;

}
void simple_alloc_1d_real_array(real_array_t* dest, int n)
{
  dest->ndims = 1;
  dest->dim_size = size_alloc(1);
  dest->dim_size[0] = n;
  dest->data = real_alloc(n);
}

void simple_alloc_2d_real_array(real_array_t* dest, int r, int c)
{
  dest->ndims = 2;
  dest->dim_size = size_alloc(2);
  dest->dim_size[0] = r;
  dest->dim_size[1] = c;
  dest->data = real_alloc(r*c);
}

void alloc_real_array(real_array_t* dest,int ndims,...)
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
  
  dest->data = real_alloc(real_array_nr_of_elements(dest));

}


void alloc_real_array_data(real_array_t* a)
{
  size_t array_size;

  array_size = real_array_nr_of_elements(a) * sizeof(modelica_real);
  a->data = real_alloc(array_size);

  /*  size_t array_size;
  void* ptr;

  assert(real_array_ok(a));
  array_size = real_array_nr_of_elements(a) * sizeof(modelica_real);
  ptr = malloc(array_size);
  assert(ptr);
  a->data = ptr;*/
  
}

void free_real_array_data(real_array_t* a)
{
  size_t array_size;

  assert(real_array_ok(a));

  array_size = real_array_nr_of_elements(a) * sizeof(modelica_real);
  real_free(array_size);
  /*  free(a->data);
      a->data = 0;*/
}

void clone_real_array_spec(real_array_t* source, real_array_t* dest)
{
  int i;
  assert(real_array_ok(source));

  dest->ndims = source->ndims;
  dest->dim_size = size_alloc(dest->ndims*sizeof(int));
  assert(dest->dim_size);
  
  for (i = 0; i < dest->ndims; ++i)
    {
      dest->dim_size[i] = source->dim_size[i];
    }
 /*  int i; */
/*   assert(real_array_ok(source)); */

/*   dest->ndims = source->ndims; */
/*   dest->dim_size = malloc(dest->ndims*sizeof(int)); */
/*   assert(dest->dim_size); */

/*   for (i = 0; i < dest->ndims; ++i) */
/*     { */
/*       dest->dim_size[i] = source->dim_size[i]; */
/*     } */
/*   dest->data = 0; */

}

void copy_real_array_data(real_array_t* source, real_array_t* dest)
{
  size_t i;
  size_t nr_of_elements;

  assert(real_array_ok(source));
  assert(real_array_ok(dest));
  assert(real_array_shape_eq(source, dest));

  nr_of_elements = real_array_nr_of_elements(source);

  for (i = 0; i < nr_of_elements; ++i)
  {
      dest->data[i] = source->data[i];
  }
  
}

/*

 a[1:3] := b;

*/

modelica_real* calc_index_spec(int ndims, size_t* idx_vec, real_array_t* arr, index_spec_t* spec)
{
    int i;
    int d,d2;
    modelica_real* data = arr->data;
    size_t stride = 1;
    for (i = 0; i < ndims; ++i)
    {
	d = idx_vec[i];
	if (spec->index[i])
	{
	    d2 = spec->index[i][d];
	}
	else 
	{
	    d2 = d;
	}
	data += d2*stride;
	stride *= arr->dim_size[i];
	
    }

    return data;
}

/* Uses zero based indexing */
modelica_real* calc_index(int ndims, size_t* idx_vec, real_array_t* arr)
{
  int i;
  int index;

  index = 0;
  for (i = 0; i < ndims; ++i)
    {
      /* Assert that idx_vec[i] is not out of bounds */
      index = index*arr->dim_size[i] + idx_vec[i]; 
    }
  
  return arr->data + index;
}

/* One based index*/
real* calc_index_va(real_array_t* source,int ndims,va_list ap)
{
  int i;
  int index;
  int dim_s;

  index = 0;
  for (i = 0; i < ndims; ++i)
    {
      dim_s = va_arg(ap,int);
      index = index*source->dim_size[i]+dim_s;
    }

  return source->data+index;
}
void print_real_matrix(real_array_t* source)
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

void print_real_array(real_array_t* source)
			       
{
    size_t i,j,k,n;
    modelica_real* data;	
    assert(real_array_ok(source));

    data = source->data;
    if (source->ndims == 1)
    {
	for (i = 0; i < source->dim_size[0]; ++i)
	{
	    printf("%e",*data);
	    ++data;
	    if (i+1 < source->dim_size[0])
	    {
		printf(", ");
	    }
	}
    }
    else if (source->ndims > 1)
    {
	n = real_array_nr_of_elements(source) / 
	    (source->dim_size[0]*source->dim_size[1]);
	for (k = 0; k < n; ++k)
	{
	    for (i = 0; i < source->dim_size[1]; ++i)
	    {
		for (j = 0; j < source->dim_size[0]; ++j)
		{
		    printf("%e",*data);
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


void put_real_element(real value,int i1,real_array_t* dest)
{
  /* Assert that dest has correct dimension */
  /* Assert that i1 is a valid index */
  dest->data[i1] = value;
}

void put_matrix_element(real value, int r, int c, real_array_t* dest)
{
  /* Assert that dest hast correct dimension */
  /* Assert that r and c are valid indices */
  dest->data[r*dest->dim_size[1]+c] = value;
  printf("Index %d\n",r*dest->dim_size[1]+c);
}

/* Zero based index */
void simple_indexed_assign_real_array1(real_array_t* source, 
				       int i1,
				       real_array_t* dest)
{
  /* Assert that source has the correct dimension */
  /* Assert that dest has the correct dimension */
  
  dest->data[i1] = source->data[i1]; 
}

void simple_indexed_assign_real_array2(real_array_t* source, 
				       int i1, int i2, 
				       real_array_t* dest)
{
  size_t size_j;
  /* Assert that source has correct dimension */
  /* Assert that dest has correct dimension */
  size_j = source->dim_size[1];

  dest->data[i1*size_j+i2] = source->data[i1*size_j+i2];
}

void indexed_assign_real_array(real_array_t* source, 
			       real_array_t* dest,
			       index_spec_t* spec)
{
  
    size_t* idx_vec;
    size_t d,d2;
    size_t quit;

    assert(real_array_ok(source));
    assert(real_array_ok(dest));

/*    assert(index_spec_ok(spec));
    assert(real_array_index_ok(dest, spec));
    assert(real_array_index_result_ok(source, dest, spec));
*/
    idx_vec = calloc(source->ndims, sizeof(size_t));
    
    d2 = d = source->ndims - 1;

    quit = 0;
    while(1)
    {
/*
	for (i = 0; i < source->ndims; ++i)
	{
	    printf("%d",idx_vec[i]);
	    if (i < source->ndims-1) printf(", ");
	}
	printf("\n");
*/
	*calc_index_spec(source->ndims,idx_vec,dest,spec) =
	    *calc_index(source->ndims,idx_vec, source);

	idx_vec[d]++;
	d2 = d;
	while (idx_vec[d2] >= source->dim_size[d2])
	{
	    idx_vec[d2] = 0;
	    if (!d2) 
	    {
		quit = 1;
		break;
	    }
	    d2--;
	    idx_vec[d2]++;	    
	}
	if (quit) break;
    }
    

    
}

/*

 a := b[1:3];

*/
void index_real_array(real_array_t* source, 
			       index_spec_t* spec, 
			       real_array_t* dest)
{
  
}

void simple_index_real_array1(real_array_t* source, 
				       int i1, 
				       real_array_t* dest)
{
}

void simple_index_real_array2(real_array_t* source, 
				       int i1, int i2, 
				       real_array_t* dest)
{
}

real* real_array_element_addr(real_array_t* source,int ndims,...)
{
  va_list ap;
  real* tmp;

  va_start(ap,ndims);
  tmp = calc_index_va(source,ndims,ap);
  va_end(ap);
  
  return tmp;
}

void modelica_builtin_cat_real_array(int k, real_array_t* A, real_array_t* B)
{

}

void add_real_array(real_array_t* a, real_array_t* b, real_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;

  /* Assert a and b are of the same size */
  /* Assert that dest are of correct size */
  nr_of_elements = real_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]+b->data[i];
    }
}

void add_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest)
{
  clone_real_array_spec(a,dest);
  alloc_real_array_data(dest);
  add_real_array(a,b,dest);
}


void sub_real_array(real_array_t* a, real_array_t* b, real_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;

  /* Assert a and b are of the same size */
  /* Assert that dest are of correct size */
  nr_of_elements = real_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]-b->data[i];
    }
}

void sub_alloc_real_array(real_array_t* a, real_array_t* b,real_array_t* dest)
{
  clone_real_array_spec(a,dest);
  alloc_real_array_data(dest);
  sub_real_array(a,b,dest);
}



void mul_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  nr_of_elements = real_array_nr_of_elements(b);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a*b->data[i];
    }
}

void mul_alloc_scalar_real_array(modelica_real a,real_array_t* b,real_array_t* dest)
{
  clone_real_array_spec(b,dest);
  alloc_real_array_data(dest);
  mul_scalar_real_array(a,b,dest);
}

void mul_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  nr_of_elements = real_array_nr_of_elements(a);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]*b;
    }
}

void mul_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
    clone_real_array_spec(a,dest);
  alloc_real_array_data(dest);
  mul_real_array_scalar(a,b,dest);
}


double mul_real_scalar_product(real_array_t* a, real_array_t* b)
{
  size_t nr_of_elements;
  size_t i;
  double res;
  /* Assert that a and b are vectors */
  /* Assert that vectors are of matching size */
  
  nr_of_elements = real_array_nr_of_elements(a);
  res = 0.0;
  for (i = 0; i < nr_of_elements; ++i)
    {
      res += a->data[i]*b->data[i];
    }
    return res;
}

void mul_real_matrix_product(real_array_t* a,real_array_t* b,real_array_t* dest)
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

void mul_real_matrix_vector(real_array_t* a, real_array_t* b,real_array_t* dest)
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


void mul_real_vector_matrix(real_array_t* a, real_array_t* b,real_array_t* dest)
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

void mul_alloc_real_matrix_product_smart(real_array_t* a, real_array_t* b, real_array_t* dest)
{

  
  if ((a->ndims == 1) && (b->ndims == 2))
    {
      simple_alloc_1d_real_array(dest,b->dim_size[1]);
      mul_real_vector_matrix(a,b,dest);
      
    }
  else if ((a->ndims == 2) && (b->ndims == 1))
    {
      simple_alloc_1d_real_array(dest,a->dim_size[0]);
      mul_real_matrix_vector(a,b,dest);
    }
  else if ((a->ndims == 2) && (b->ndims == 2))
    {
      simple_alloc_2d_real_array(dest,a->dim_size[0],b->dim_size[1]);
      mul_real_matrix_product(a,b,dest);
    }
  else
    {
      printf("Invalid size of matrix\n");
    }
}


void div_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
  size_t nr_of_elements;
  size_t i;
  /* Assert that dest has correct size*/
  /* Do we need to check for b=0? */
  nr_of_elements = real_array_nr_of_elements(a);
  for (i=0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i]/b;
    }
}

void div_alloc_real_array_scalar(real_array_t* a,modelica_real b,real_array_t* dest)
{
  clone_real_array_spec(a,dest);
  alloc_real_array_data(dest);
  div_real_array_scalar(a,b,dest);
}


void exp_real_array(real_array_t* a, modelica_integer n, real_array_t* dest)
{
  size_t i;

  /* Assert n>=0 */
  /* Assert a matrix */
  /* Assert square matrix */

  if (n==0) 
    {
      identity_real_array(a->dim_size[0],dest);
    }
  else
    { 
      if (n==1)
	{
	  clone_real_array_spec(a,dest);
	  copy_real_array_data(a,dest);
	}
      else
	{
	  real_array_t* tmp;
	  clone_real_array_spec(a,tmp);
	  copy_real_array_data(a,tmp);
	  for ( i = 1; i < n; ++i)
	    {
	      mul_real_matrix_product(a,tmp,dest);
	      copy_real_array_data(dest,tmp);
	    }
	  free_real_array_data(tmp);
	}
    }
}

void exp_alloc_real_array(real_array_t* a,modelica_integer b,real_array_t* dest)
{
  clone_real_array_spec(a,dest);
  alloc_real_array_data(dest);
  exp_real_array(a,b,dest);
}

void promote_real_array(real_array_t* a, int n,real_array_t* dest)
{
  size_t i;
  
  /*Assert a->ndims>=n */
  for (i = 0; i < a->ndims; ++i)
    {
      dest->dim_size[i] = a->dim_size[i];
    }
  for (i = a->ndims; i < n; ++i)
    {
      dest->dim_size[i] = 1;
    }
}

void promote_real_scalar(double s,int n,real_array_t* dest)
{
  size_t i;
  
  /* Assert that dest is of correct dimension */

  dest->data[0] = s;
  for (i = 0; i < n; ++i)
    {
      dest->dim_size[i] = 1;
    }
}

int ndims_real_array(real_array_t* a)
{
  assert(real_array_ok(a));

  return a->ndims;
}

int size_of_dimension_real_array(real_array_t* a, int i)
{
  assert(real_array_ok(a));
  assert((i > 0) && (i <= a->ndims));

  return a->dim_size[i];
}

void size_real_array(real_array_t* a, real_array_t* dest)
{
  /* This should be an integer data instead */
  /*copy_integer_array_data(a->dim_size,dest); */
  dest = a;
}

double scalar_real_array(real_array_t* a)
{
  assert(real_array_ok(a));
  assert(real_array_one_element_ok(a));

  return a->data[0];
}

void vector_real_array(real_array_t* a,real_array_t* dest)
{
  size_t i;
  size_t nr_of_elements;

  /* Assert that a has at most one dimension with dim_size>1*/

  nr_of_elements = real_array_nr_of_elements(a);
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = a->data[i];
    } 
}

void vector_real_scalar(double a,real_array_t* dest)
{
  /* Assert that dest is a 1-vector */
  dest->data[0] = a;
}

void matrix_real_array(real_array_t* a, real_array_t* dest)
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

void matrix_real_scalar(double a,real_array_t* dest)
{
  dest->ndims = 2;
  dest->dim_size[0] = 1;
  dest->dim_size[1] = 1;
  dest->data[0] = a;
}

void transpose_real_array(real_array_t* a, real_array_t* dest)
{
  size_t i;
  size_t j;
  /*  size_t k;*/

  for (i = 0; i < a->dim_size[0]; ++i)
    {
      for (j = 0; j < a->dim_size[1]; ++i)
	{
	  /*for (k = 0; k < k_size; ++k)
	    {
	        dest->data[j*dest->dim_size[1]+i] = a->data[i*a->dim_size[1]+j];
	    }
	  */
	}
    }
}

void outer_product_real_array(real_array_t* v1,real_array_t* v2,real_array_t* dest)
{
  size_t i;
  size_t j;
  size_t number_of_elements_a;
  size_t number_of_elements_b;
  
  number_of_elements_a = real_array_nr_of_elements(v1);
  number_of_elements_b = real_array_nr_of_elements(v2);

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

void identity_real_array(int n, real_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;
  
  assert(real_array_ok(dest));
  
  /* Check that dest size is ok */
  if (dest->ndims!=2) 
    exit(0);

  if ((dest->dim_size[0]!=n) || (dest->dim_size[1]!=n))
    exit(0);

  nr_of_elements = real_array_nr_of_elements(dest);
  
  for (i=0;i < nr_of_elements;++i)
    {
      for ( j = 0;j <= nr_of_elements; ++j)
	{
	  dest->data[i*n+j] = i==j? 1:0;
	}
    }
}

void diagonal_real_array(real_array_t* v,real_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;

  /* Assert that v is a vector */
  nr_of_elements = real_array_nr_of_elements(v);

  for (i = 0; i < nr_of_elements; ++i)
    {
      for (i = 0; j < nr_of_elements;++j)
      {
	dest->data[i*nr_of_elements+j] = (i==j)?v->data[i]:0;
      }
    }
}

void fill_real_array(real_array_t* dest,modelica_real s)
{
  size_t nr_of_elements;
  size_t i;

  nr_of_elements = real_array_nr_of_elements(dest);  
  for (i = 0; i < nr_of_elements; ++i)
    {
      dest->data[i] = s;
    }
}

void linspace_real_array(double x1, double x2, int n,real_array_t* dest)
{
  size_t i;

  /* Assert n>=2 */

  for (i = 0; i < n-1; ++i)
    {
      dest->data[i] = x1 + (x2-x1)*(i-1)/(n-1);
    }
}

double max_real_array(real_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double max_element;
  
  assert(real_array_ok(a));

  nr_of_elements = real_array_nr_of_elements(a);

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

double min_real_array(real_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double min_element;
  
  assert(real_array_ok(a));

  nr_of_elements = real_array_nr_of_elements(a);

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

double sum_real_array(real_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double sum = 0;

  assert(real_array_ok(a));

  nr_of_elements = real_array_nr_of_elements(a);
  
  for (i=0;i < nr_of_elements;++i)
    {
      sum += a->data[i];
    }

  return sum;
}

double product_real_array(real_array_t* a)
{
  size_t i;
  size_t nr_of_elements;
  double product = 0;
  
  assert(real_array_ok(a));

  nr_of_elements = real_array_nr_of_elements(a);
  
  for (i=0;i < nr_of_elements;++i)
    {
      product *= a->data[i];
    }

  return product;
  
}

void symmetric_real_array(real_array_t* a,real_array_t* dest)
{
  size_t i;
  size_t j;
  size_t nr_of_elements;

  nr_of_elements = real_array_nr_of_elements(a);
 
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

void cross_real_array(real_array_t* x,real_array_t* y, real_array_t* dest)
{
  /* Assert x and y are vectors */
  /* Assert x and y have size 3 */
  /* Assert dest is a vector */
  /* Assert that dest have size 3*/
  
  dest->data[0] = x->data[1]*y->data[2]-x->data[2]*y->data[1];
  dest->data[1] = x->data[2]*y->data[0]-x->data[0]*y->data[2];
  dest->data[2] = x->data[0]*y->data[1]-x->data[1]*y->data[0];
}

void skew_real_array(real_array_t* x,real_array_t* dest)
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
