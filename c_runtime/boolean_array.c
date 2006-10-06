/*
Copyright (c) 1998-2006, Linköpings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

* Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

* Neither the name of Linköpings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
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
