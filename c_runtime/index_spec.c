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
