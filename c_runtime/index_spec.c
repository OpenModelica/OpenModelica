#include "index_spec.h"
#include <stdlib.h>

void alloc_index_spec(index_spec_t* s)
{
    int i;
    s->index = malloc(s->ndims*sizeof(int*));
    for (i = 0; i < s->ndims; ++i)
    {
	if (s->dim_size[i] > 0)
	{
	    s->index[i] = malloc(s->dim_size[i]*sizeof(int));
	}
	else
	{
	    s->index[i] = 0;
	}
    }
}
