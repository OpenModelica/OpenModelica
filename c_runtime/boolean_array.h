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

#ifndef BOOLEAN_ARRAY_H_
#define BOOLEAN_ARRAT_H_

#include "index_spec.h"
#include "memory_pool.h"
#include <stdio.h>
#include <stdarg.h>
#include <math.h>

typedef double modelica_boolean;

struct boolean_array_s
{
  int ndims;
  int* dim_size;
  modelica_boolean* data;
};

typedef struct boolean_array_s boolean_array_t;

size_t boolean_array_nr_of_elements(boolean_array_t* a);

void alloc_boolean_array_data(boolean_array_t* a);

void clone_boolean_array_spec(boolean_array_t* source, boolean_array_t* dest);

#endif
