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
