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


#ifndef INDEX_SPEC_H_
#define INDEX_SPEC_H_
#include <stdio.h>

struct index_spec_s
{
  int ndims;
  int* dim_size;
  int** index;
};

typedef struct index_spec_s index_spec_t;

int index_spec_ok(index_spec_t* s);
void alloc_index_spec(index_spec_t* s);
void create_index_spec(index_spec_t* dest, int nridx, ...);
int* make_index_array(int nridx,...);
int imax(int i,int j);
int next_index(int ndims, size_t* idx, size_t* size);

#endif
