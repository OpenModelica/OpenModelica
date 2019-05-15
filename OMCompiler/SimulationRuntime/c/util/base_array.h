/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
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

#ifndef BASE_ARRAY_H_
#define BASE_ARRAY_H_

#include "../openmodelica.h"
#include <stdlib.h>
#include <stdarg.h>
#include "omc_msvc.h"

static OMC_INLINE size_t getIndex_2D(_index_t *dim, int i, int j) {return i*dim[1]+j;}
static OMC_INLINE size_t getIndex_3D(_index_t *dim, int i, int j, int k) {return (i*dim[1]+j)*dim[2]+k;}
static OMC_INLINE size_t getIndex_4D(_index_t *dim, int i, int j, int k, int l) {return ((i*dim[1]+j)*dim[2]+k)*dim[3]+l;}
static OMC_INLINE size_t getIndex_5D(_index_t *dim, int i, int j, int k, int l, int m) {return (((i*dim[1]+j)*dim[2]+k)*dim[3]+l)*dim[4]+m;}

/* Settings the fields of a base_array */
void base_array_create(base_array_t *dest, void *data, int ndims, va_list ap);

/* Allocation of a vector */
void simple_alloc_1d_base_array(base_array_t *dest, int n, void *data);

/* Allocation of a matrix */
void simple_alloc_2d_base_array(base_array_t *dest, int r, int c, void *data);

/* Allocate array */
size_t alloc_base_array(base_array_t *dest, int ndims, va_list ap);

/* Number of elements in array. */
static OMC_INLINE size_t base_array_nr_of_elements(const base_array_t a)
{
  int i;
  size_t nr_of_elements = 1;
  for(i = 0; i < a.ndims; ++i) {
     nr_of_elements *= a.dim_size[i];
  }
  return nr_of_elements;
}

/* Clones fields */
void clone_base_array_spec(const base_array_t *source, base_array_t *dest);

void clone_reverse_base_array_spec(const base_array_t* source, base_array_t* dest);

int ndims_base_array(const base_array_t* a);
static OMC_INLINE int size_of_dimension_base_array(const base_array_t a, int i)
{
  /* assert(base_array_ok(&a)); */
  if ((i > 0) && (i <= a.ndims)) {
    return a.dim_size[i-1];
  }
  /* This is a weird work-around to return 0 if the dimension is out of bounds and a dimension is 0
   * The reason is that we lose the dimensions in the DAE.ARRAY after a 0-dimension
   * Note: We return size(arr,2)=0 if arr has dimensions [0,2], and not the expected 2
   */
  for (i=0; i<a.ndims; i++) {
    if (a.dim_size[i] == 0) {
      return 0;
    }
  }
  fprintf(stderr, "size_of_dimension_base_array failed for i=%d, ndims=%d (ndims out of bounds)\n", i, a.ndims);
  abort();
}

/* Helper functions */
int base_array_ok(const base_array_t *a);
void check_base_array_dim_sizes(const base_array_t *elts, int n);
void check_base_array_dim_sizes_except(int k, const base_array_t *elts, int n);
int base_array_shape_eq(const base_array_t *a, const base_array_t *b);
int base_array_one_element_ok(const base_array_t *a);

size_t calc_base_index_spec(int ndims, const _index_t* idx_vec,
                            const base_array_t *arr, const index_spec_t *spec);
size_t calc_base_index(int ndims, const _index_t *idx_vec, const base_array_t *arr);
size_t calc_base_index_va(const base_array_t *source, int ndims, va_list ap);

size_t calc_base_index_dims_subs(int ndims,...);

int index_spec_fit_base_array(const index_spec_t *s, const base_array_t *a);

/* Helper function for index_alloc_TYPE_array; allocates the ndims and dim_size */
void index_alloc_base_array_size(const base_array_t * source, const index_spec_t* source_spec, base_array_t* dest);
/* Helper function for indexed_assign_TYPE_array; allocates the ndims and dim_size */
void indexed_assign_base_array_size_alloc(const base_array_t *source, base_array_t *dest, const index_spec_t *dest_spec, _index_t** _idx_vec1, _index_t** _idx_size);

#endif /* BASE_ARRAY_H_ */
