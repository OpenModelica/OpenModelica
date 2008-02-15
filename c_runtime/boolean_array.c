/* 
 * This file is part of OpenModelica.
 * 
 * Copyright (c) 1998-2008, Linköpings University,
 * Department of Computer and Information Science, 
 * SE-58183 Linköping, Sweden. 
 * 
 * All rights reserved.
 * 
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC 
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF 
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC 
 * PUBLIC LICENSE. 
 * 
 * The OpenModelica software and the Open Source Modelica 
 * Consortium (OSMC) Public License (OSMC-PL) are obtained 
 * from Linköpings University, either from the above address, 
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 * 
 * This program is distributed  WITHOUT ANY WARRANTY; without 
 * even the implied warranty of  MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH 
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS 
 * OF OSMC-PL. 
 * 
 * See the full OSMC Public License conditions for more details.
 * 
 */

#include "boolean_array.h"

#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include <stdarg.h>

int boolean_array_ok(boolean_array_t* a)
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

size_t boolean_array_nr_of_elements(boolean_array_t* a)
{
    int i;
    size_t nr_of_elements = 1;
    for (i = 0; i < a->ndims; ++i)
    {
	nr_of_elements *= a->dim_size[i];
    }
    return nr_of_elements;

}

void alloc_boolean_array_data(boolean_array_t* a)
{
  size_t array_size;

  array_size = boolean_array_nr_of_elements(a);
  a->data = boolean_alloc(array_size);
}

void clone_boolean_array_spec(boolean_array_t* source, boolean_array_t* dest)
{
  int i;
  assert(boolean_array_ok(source));

  dest->ndims = source->ndims;
  dest->dim_size = size_alloc(dest->ndims*sizeof(int));
  assert(dest->dim_size);
  
  for (i = 0; i < dest->ndims; ++i)
    {
      dest->dim_size[i] = source->dim_size[i];
    }
}

/* array_alloc_scalar_boolean_array
 *
 * Creates(incl allocation) an array from scalar elements.
 */

void array_alloc_scalar_boolean_array(boolean_array_t* dest,int n,modelica_boolean first,...)
{
  int i;
  va_list ap;
  simple_alloc_1d_boolean_array(dest,n);
  va_start(ap,first);      
  put_boolean_element(first,0,dest);
  for (i = 1; i < n; ++i)
    {
      put_boolean_element(va_arg(ap,int),i,dest);
    }
  va_end(ap);
}
void simple_alloc_1d_boolean_array(boolean_array_t* dest, int n)
{
  dest->ndims = 1;
  dest->dim_size = size_alloc(1);
  dest->dim_size[0] = n;
  dest->data = boolean_alloc(n);
}

void put_boolean_element(modelica_boolean value,int i1,boolean_array_t* dest)
{
  /* Assert that dest has correct dimension */
  /* Assert that i1 is a valid index */
  dest->data[i1] = value;
}

void free_boolean_array_data(boolean_array_t* a)
{
  size_t array_size;

  assert(boolean_array_ok(a));

  array_size = boolean_array_nr_of_elements(a);
  boolean_free(array_size);
}

/* One based index*/
m_boolean* calc_boolean_index_va(boolean_array_t* source,int ndims,va_list ap)
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

m_boolean* boolean_array_element_addr(boolean_array_t* source,int ndims,...)
{
  va_list ap;
  m_boolean* tmp;

  va_start(ap,ndims);
  tmp = calc_boolean_index_va(source,ndims,ap);
  va_end(ap);
  
  return tmp;
}

m_boolean* boolean_array_element_addr1(boolean_array_t* source,int ndims,int dim1)
{
  return source->data+dim1-1;
}

m_boolean* boolean_array_element_addr2(boolean_array_t* source,int ndims,int dim1,int dim2)
{
  return source->data+(dim1-1)*source->dim_size[1]+dim2-1;
}

int size_of_dimension_boolean_array(boolean_array_t a, int i)
{
  assert(boolean_array_ok(&a));
  assert((i > 0) && (i <= a.ndims));

  return a.dim_size[i-1];
}

