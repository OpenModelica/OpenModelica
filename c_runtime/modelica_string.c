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

int modelica_string_ok(modelica_string_t* a)
{
    if (!a) return 0;
    if (a->length < 0) return 0;
    return 1;
}

int modelica_string_length(modelica_string_t* a)
{
  return a->length;
}

void init_modelica_string(modelica_string_t* dest, const char* str)
{
  int i;
  int length = strlen(str);
  alloc_modelica_string(dest, length);
  alloc_modelica_string_data(dest);
  for (i = 0; i<length; ++i) {
    dest->data[i] = str[i];
  }
}

void alloc_modelica_string(modelica_string_t* dest, int n)
{ 
  dest->length = n;
  dest->data = char_alloc(n);

}

void alloc_modelica_string_data(modelica_string_t* a)
{
  int length = modelica_string_length(a);

  a->data = char_alloc(length);
}

void free_modelica_string_data(modelica_string_t* a)
{
  int length;

  assert(modelica_string_ok(a));

  length = modelica_string_length(a);
  char_free(length);
}

void clone_modelica_string_spec(modelica_string_t* source, modelica_string_t* dest)
{
  assert(modelica_string_ok(source));
  dest->length = source->length;
}

void copy_modelica_string_data(modelica_string_t* source, modelica_string_t* dest)
{
  int length;
  int i;
  assert(modelica_string_ok(source));
  assert(modelica_string_ok(dest));
  length = source->length;
  for (i = 0; i<length; ++i) {
    dest->data[i] = source->data[i];
  }
}

void copy_modelica_string(modelica_string_t* source, modelica_string_t* dest)
{
  clone_modelica_string_spec (source, dest);
  alloc_modelica_string_data(dest);
  copy_modelica_string_data(source,dest);
}
