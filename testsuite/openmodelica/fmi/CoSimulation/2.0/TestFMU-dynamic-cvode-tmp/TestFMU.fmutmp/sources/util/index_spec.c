/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * GPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium)
 * Public License (OSMC-PL) are obtained from OSMC, either from the above
 * address, from the URLs: http://www.openmodelica.org or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica
 * distribution. GNU version 3 is obtained from:
 * http://www.gnu.org/copyleft/gpl.html. The New BSD License is obtained from:
 * http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied
 * warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS
 * EXPRESSLY SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE
 * CONDITIONS OF OSMC-PL.
 *
 */


#include "index_spec.h"
#include "../gc/omc_gc.h"
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>

int index_spec_ok(const index_spec_t* s)
{
    int i;
    if(s == NULL) {
      fprintf(stderr,"index_spec_ok: the index spec is NULL!\n"); fflush(stderr);
      return 0;
    }
    if(s->ndims < 0) {
      fprintf(stderr,"index_spec_ok: the index spec dimensions are negative: %d!\n", (int)s->ndims); fflush(stderr);
      return 0;
    }
    if(s->dim_size == NULL) {
      fprintf(stderr,"index_spec_ok: the index spec dimensions sizes is NULL!\n"); fflush(stderr);
      return 0;
    }
    if(s->index == NULL) {
      fprintf(stderr,"index_spec_ok: the index spec index array is NULL!\n"); fflush(stderr);
      return 0;
    }
    for(i = 0; i < s->ndims; ++i) {
        if(s->dim_size[i] < 0) {
          fprintf(stderr,"index_spec_ok: the index spec dimension size for dimension %d is negative: %d!\n", i, (int)s->dim_size[i]); fflush(stderr);
          return 0;
        }
        if((s->index[i] == 0) && (s->dim_size[i] != 1 && s->dim_size[i] != 0)) {
            fprintf(stderr,"index_spec_ok: index[%d] == 0, size == %d\n", i, (unsigned int) s->dim_size[i]); fflush(stderr);
            return 0;
        }
    }
    return 1;
}

void alloc_index_spec(index_spec_t* s)
{
    int i;
    s->index = index_alloc(s->ndims);
    for(i = 0; i < s->ndims; ++i) {
        if(s->dim_size[i] > 0) {
            s->index[i] = size_alloc(s->dim_size[i]);
        } else {
            s->index[i] = 0;
        }
    }
}
/*
 * create_index_spec
 *
 * Creates a subscript, i.e. index_spec_t from the arguments.
 * nridx - number of indexes.
 * Each index consist of a size and a pointer to indixes.
 *
 * For instance to create the indexes in a[1,{2,3}] you
 * write:
 * int tmp1[1]={1}; int tmp2[2]={2,3};
 * create_index_spec(&dest,2,1,&tmp1,2,&tmp2);
 */

void create_index_spec(index_spec_t* dest, int nridx, ...)
{
    int i;
    va_list ap;
    va_start(ap,nridx);

    dest->ndims = nridx;
    dest->dim_size = size_alloc(nridx);
    dest->index = index_alloc(nridx);
    dest->index_type = (char*)generic_alloc(nridx+1,sizeof(char));
    for(i = 0; i < nridx; ++i) {
        dest->dim_size[i] = va_arg(ap, _index_t);
        dest->index[i] = va_arg(ap, _index_t*);
        dest->index_type[i] = (char) va_arg(ap,_index_t); /* char is cast to int by va_arg.*/
    }
    va_end(ap);

	assert(index_spec_ok(dest));
}

/* make_index_array
 *
 * Creates an integer array of indices to be used by e.g.
 * create_index_spec above.
 */
_index_t* make_index_array(int nridx, ...)
{
    int i;
    _index_t* res;
    va_list ap;
    va_start(ap,nridx);

    res = size_alloc(nridx);
    for(i = 0; i < nridx; ++i) {
        res[i] = va_arg(ap,_index_t);
    }

    return res;
}

void print_size_array(int size, const size_t* arr)
{
  int i;
  printf("{");
  for(i = 0; i < size-1; ++i) {
    printf("%d,", (int) arr[i]);
  }
  printf("%d}\n", (int) arr[i]);
}

/* Calculates the next index for copying subscripted array.
 * ndims - dimension size of indices.
 * idx - updated with the the next index
 * size - size of each index dimension
 * The function returns 0 if new index is calculated and 1 if no more indices
 * are available (all indices traversed).
  */
int next_index(int ndims, _index_t* idx, const _index_t* size)
{
    int d = ndims - 1;

    idx[d]++;

    while(idx[d] >= size[d]) {
        idx[d] = 0;
        if(d == 0) {
            return 1;
        }
        d--;
        idx[d]++;
    }

    return 0;
}

void print_index_spec(const index_spec_t* spec)
{
    int i,k;
    printf("[");
    for(i = 0; i < spec->ndims; ++i) {
        switch (spec->index_type[i]) {
            case 'S':
                printf("%d", (int) *spec->index[i]);
                break;
            case 'A':
                printf("{");
                for(k = 0; k < spec->dim_size[i]-1; ++k) {
                    printf("%d,", (int) spec->index[i][k]);
                }
                if(0 < spec->dim_size[i]) {
                    printf("%d", (int) spec->index[i][0]);
                }
                printf("}");
                break;
            case 'W':
                printf(":");
                break;
            default:
                printf("INVALID TYPE %c.", spec->index_type[i]);
                break;
        }
        if(i != (spec->ndims - 1)) {
            printf(", ");
        }
    }
    printf("]");
}
