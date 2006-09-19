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

/* This structure holds indexes when subscripting an array.
 * ndims - number of subscripts, E.g. A[1,{2,3},:] => ndims = 3
 * dim_size - dimension size of each subscript, Eg. A[1,{2,3},:,{3}] => dim_size={1,2,0,1}
 * spec_type - index type for each index, 'S' for scalar, 'A' for array, 'W' for whole dimension (:)
 *     Eg. A[1,{2,3},:,{3}] => spec_type = {'S','A','W','A'}. 
 *     spec_type is required to be able to distinguish between {1} and 1 as an index.
 * index - pointer to all indices (except of type 'W'), eg A[1,{2,3},:,{3}] => index -> {1,2,3,3}
*/
struct index_spec_s
{
  int ndims;  /* number of indices/subscripts */
  int* dim_size; /* size for each subscript */
  char* index_type;  /* type of each subscript, any of 'S','A' or 'W' */
  int** index; /* all indices*/
};

typedef struct index_spec_s index_spec_t;

int index_spec_ok(index_spec_t* s);
void alloc_index_spec(index_spec_t* s);
void create_index_spec(index_spec_t* dest, int nridx, ...);
int* make_index_array(int nridx,...);
int imax(int i,int j);
int next_index(int ndims, size_t* idx, size_t* size);
void print_index_spec(index_spec_t* spec);

#endif
