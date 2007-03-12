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

/* Convert a modelica_integer to a modelica_string, used in String(i) */

void modelica_integer_to_modelica_string(modelica_string_t* dest,modelica_integer i,
	modelica_integer minLen,modelica_boolean leftJustified,modelica_integer signDigits)
{
	char formatStr[40];
	char buf[400];
	formatStr[0]='%';	
	if (leftJustified) {	
		sprintf(&formatStr[1],"-%dd",minLen);
	} else {
		sprintf(&formatStr[1],"%dd",minLen);
	}
	sprintf(buf,formatStr,i);
	init_modelica_string(dest,buf);
}

/* Convert a modelica_real to a modelica_string, used in String(r) */

void modelica_real_to_modelica_string(modelica_string_t* dest,modelica_real r,modelica_integer minLen,
	modelica_boolean leftJustified,modelica_integer signDigits)
{
	char formatStr[40];
	char buf[400];
	formatStr[0]='%';	
	if (leftJustified) {	
		sprintf(&formatStr[1],"-%d.%dg",minLen,signDigits);
	} else {
		sprintf(&formatStr[1],"%d.%dg",minLen,signDigits);
	}
	sprintf(buf,formatStr,r);
	init_modelica_string(dest,buf);
}

/* Convert a modelica_boolean to a modelica_string, used in String(b) */

void modelica_boolean_to_modelica_string(modelica_string_t* dest,modelica_boolean b,
modelica_integer minLen, modelica_boolean leftJustified, modelica_integer signDigits)
{
	if (b) { 
		init_modelica_string(dest,"true");
	} else {
		init_modelica_string(dest,"false");
	}	
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

void cat_modelica_string(modelica_string_t* dest, modelica_string_t *s1, modelica_string_t *s2)
{
	int len = modelica_string_length(s1)+modelica_string_length(s2);
	alloc_modelica_string(dest,len); 
	sprintf(*dest,"%s%s",*s1,*s2);
}

