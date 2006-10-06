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

#include "modelica_string.h"
#include "memory_pool.h"
#include <assert.h>
#include <string.h>

int modelica_string_ok(modelica_string_t* a)
{
	/* Since a modelica string is a char* check that it is not null.*/
	
    return (int)a;
}

int modelica_string_length(modelica_string_t* a)
{
  return strlen(*a);
}

void init_modelica_string(modelica_string_t* dest, const char* str)
{
  int i;
  int length = strlen(str);
  alloc_modelica_string(dest, length);
  for (i = 0; i<length; ++i) {
    (*dest)[i] = str[i];
  }
  (*dest)[i]=0;
}

void alloc_modelica_string(modelica_string_t* dest, int n)
{ 
	/* Reserve place for null terminator too.*/
  *dest = char_alloc(n+1);
}


void free_modelica_string(modelica_string_t* a)
{
  int length;

  assert(modelica_string_ok(a));

  length = modelica_string_length(a);
  /* Free also null terminator.*/
  char_free(length+1);
}

void copy_modelica_string(modelica_string_t* source, modelica_string_t* dest)
{ 
	int i;
	alloc_modelica_string(dest,modelica_string_length(source));
	for (i=0; i < modelica_string_length(source)+1; ++i) {
	(*dest)[i]=(*source)[i];
	}
}
