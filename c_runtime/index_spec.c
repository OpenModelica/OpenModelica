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


#include "index_spec.h"
#include "memory_pool.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int index_spec_ok(index_spec_t* s)
{
    int i;
    if (!s) return 0;
    if (s->ndims < 0) return 0;
    if (!s->dim_size) return 0;
    if (!s->index) return 0;
    for (i = 0; i < s->ndims; ++i) 
    {
      
	if (s->dim_size[i] < 0) return 0;
	if ((s->index[i] == 0) && (s->dim_size[i] != 1)) 
	  {
	    fprintf(stderr,"index[%d] == 0, size == %d\n",i,(unsigned int)s->dim_size[i]);
	    return 0;	  
	  }
	
    }  
    return 1;
}



void alloc_index_spec(index_spec_t* s)
{
    int i;
    s->index = index_alloc(s->ndims);
    for (i = 0; i < s->ndims; ++i)
    {
	if (s->dim_size[i] > 0)
	{
	    s->index[i] = size_alloc(s->dim_size[i]);
	}
	else
	{
	    s->index[i] = 0;
	}
    }
}

void create_index_spec(index_spec_t* dest, int nridx, ...)
{ 
  int i;
  va_list ap;
  va_start(ap,nridx);
  
  dest->ndims = nridx;
  dest->dim_size = size_alloc(nridx);
  dest->index = index_alloc(nridx);   
  for (i = 0; i < nridx; ++i)
    {
      dest->dim_size[i] = va_arg(ap,int);      
      dest->index[i] = va_arg(ap,int*);
    }
  va_end(ap);
  
  
}

int* make_index_array(int nridx,...)
{
  int i;
  int* res;
  va_list ap;
  va_start(ap,nridx);
  
  res = size_alloc(nridx);
  for (i = 0; i < nridx; ++i)
    {
      res[i] = va_arg(ap,int);
    }

  return res;

}

int imax(int i,int j)
{
  return i < j ? j : i;
}

int next_index(int ndims, size_t* idx, size_t* size) 
{
  int d = ndims - 1;

  idx[d]++;
  while (idx[d] >= size[d])
    {
      idx[d] = 0;
      if (!d) { return 1; }
      d--;
      idx[d]++;	    
    }
  return 0;
}
