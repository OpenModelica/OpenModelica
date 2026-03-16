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


#include "base_array.h"
#include "index_spec.h"
#include "../gc/omc_gc.h"
#include "omc_error.h"

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <stdarg.h>


/**
 * @brief Calculate flat index for 2D array element access.
 *
 * Converts 2D subscripts (i, j) to a flat 1D index using row-major order.
 *
 * @param dim  Pointer to dimension sizes array (at least 2 elements).
 * @param i    Row index (0-based).
 * @param j    Column index (0-based).
 *
 * @return Flat 1D index for row-major storage.
 *
 * @note Uses row-major (C-style) array layout: index = i * dim[1] + j
 */
_index_t getIndex_2D(_index_t * dim, int i, int j) {
  return i * dim[1] + j;
}

/**
 * @brief Calculate flat index for 3D array element access.
 *
 * Converts 3D subscripts (i, j, k) to a flat 1D index using row-major order.
 *
 * @param dim  Pointer to dimension sizes array (at least 3 elements).
 * @param i    First dimension index (0-based).
 * @param j    Second dimension index (0-based).
 * @param k    Third dimension index (0-based).
 *
 * @return Flat 1D index for row-major storage.
 *
 * @note Uses row-major array layout: index = (i * dim[1] + j) * dim[2] + k
 */
_index_t getIndex_3D(_index_t * dim, int i, int j, int k) {
  return (i * dim[1] + j) * dim[2] + k;
}

/**
 * @brief Calculate flat index for 4D array element access.
 *
 * Converts 4D subscripts (i, j, k, l) to a flat 1D index using row-major order.
 *
 * @param dim  Pointer to dimension sizes array (at least 4 elements).
 * @param i    First dimension index (0-based).
 * @param j    Second dimension index (0-based).
 * @param k    Third dimension index (0-based).
 * @param l    Fourth dimension index (0-based).
 *
 * @return Flat 1D index for row-major storage.
 */
_index_t getIndex_4D(_index_t * dim, int i, int j, int k, int l) {
  return ((i * dim[1] + j) * dim[2] + k) * dim[3] + l;
}

/**
 * @brief Calculate flat index for 5D array element access.
 *
 * Converts 5D subscripts (i, j, k, l, m) to a flat 1D index using row-major
 * order.
 *
 * @param dim  Pointer to dimension sizes array (at least 5 elements).
 * @param i    First dimension index (0-based).
 * @param j    Second dimension index (0-based).
 * @param k    Third dimension index (0-based).
 * @param l    Fourth dimension index (0-based).
 * @param m    Fifth dimension index (0-based).
 *
 * @return Flat 1D index for row-major storage.
 */
_index_t getIndex_5D(_index_t * dim, int i, int j, int k, int l, int m) {
  return (((i * dim[1] + j) * dim[2] + k) * dim[3] + l) * dim[4] + m;
}

/**
 * @brief Calculate total number of elements in an array.
 *
 * Computes the product of all dimension sizes to get the total element count.
 *
 * @param a  The base array structure.
 *
 * @return Total number of elements in the array.
 */
_index_t base_array_nr_of_elements(const base_array_t a)
{
  int i;
  _index_t nr_of_elements = 1;
  for(i = 0; i < a.ndims; ++i) {
     nr_of_elements *= a.dim_size[i];
  }
  return nr_of_elements;
}

/**
 * @brief Get the size of a specific dimension in an array.
 *
 * Returns the size of the i-th dimension (1-based indexing).
 *
 * @param a  The base array structure.
 * @param i  Dimension index (1-based: 1 to ndims).
 *
 * @return Size of the specified dimension, or 0 if dimension index is out of bounds
 *         or any prior dimension has size 0.
 *
 * @attention Uses 1-based indexing for dimensions (Modelica convention).
 */
_index_t size_of_dimension_base_array(const base_array_t a, int i)
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

/**
 * @brief Initialize a base array structure with existing data and dimension information.
 *
 * Sets all fields in a base_array structure: data pointer, number of dimensions
 * (ndims), and dimension sizes. The dimension sizes are extracted from a variable
 * argument list passed as a va_list.
 *
 * @param dest   Pointer to the base_array structure to initialize.
 * @param data   Pointer to the pre-allocated data buffer for array elements.
 * @param ndims  Number of dimensions.
 * @param ap     Variable argument list containing ndims dimension size values
 *               (each of type _index_t).
 *
 * @pre data pointer should be valid (typically allocated via malloc or gc).
 * @pre ap must contain exactly ndims dimension size arguments of type _index_t.
 *
 * @note This is the low-level initialization function. Type-specific wrappers
 *       like real_array_create() typically call this function internally.
 *
 * @attention Sets dest->flexible to 0. The caller is responsible for ensuring
 *            the data buffer is large enough to hold all array elements.
 */
void base_array_create(base_array_t *dest, void *data, int ndims, va_list ap)
{
    int i;

    dest->data = data;
    dest->ndims = ndims;

    dest->dim_size = size_alloc(ndims);

    for(i = 0; i < ndims; ++i) {
        dest->dim_size[i] = va_arg(ap, _index_t);
    }

    dest->flexible = 0;
}

/**
 * @brief Validate that a base_array structure is well-formed.
 *
 * Performs comprehensive validity checks on all fields of the base_array structure.
 *
 * @param a  Pointer to the base_array to validate.
 *
 * @return 1 if array is valid, 0 otherwise. Prints error messages to stderr for each
 *         validation failure.
 *
 * @attention This function performs diagnostic output to stderr. Failures indicate
 *            critical structural problems with the array.
 */
int base_array_ok(const base_array_t *a)
{
    int i;
    if(a == NULL) {
      fprintf(stderr, "base_array.c: array is NULL!\n"); fflush(stderr);
      return 0;
    }
    if(a->ndims < 0) {
      fprintf(stderr, "base_array.c: the number of array dimensions are < 0!\n"); fflush(stderr);
      return 0;
    }
    if(a->dim_size == NULL) {
      fprintf(stderr, "base_array.c: array dimensions sizes are NULL!\n"); fflush(stderr);
      return 0;
    }
    for(i = 0; i < a->ndims; ++i) {
        if(a->dim_size[i] < 0) {
          fprintf(stderr, "base_array.c: array dimension size for dimension %d is %d < 0!\n", i, (int) a->dim_size[i]); fflush(stderr);
          return 0;
        }
    }
    return 1;
}

/**
 * @brief Verify that multiple arrays have identical dimensions.
 *
 * Helper function for operations like concatenation. Asserts that all provided
 * arrays have the same number of dimensions and matching dimension sizes.
 *
 * @param elts  Array of base_array pointers to check.
 * @param n     Number of arrays in the elts array.
 *
 * @pre All pointers in elts must be valid and non-NULL.
 *
 * @note This function uses assertions and will abort if validation fails.
 *
 * @attention Used internally by array allocation and concatenation functions.
 */
void check_base_array_dim_sizes(const base_array_t *elts, int n)
{
    int i, curdim;
    int ndims = elts[0].ndims;
    for(i = 1; i < n; ++i) {
        assert(elts[i].ndims == ndims && "Not same number of dimensions");
    }
    for(curdim = 0; curdim < ndims; ++curdim) {
        int dimsize = elts[0].dim_size[curdim];
        for(i = 1; i < n; ++i) {
            assert(dimsize == elts[i].dim_size[curdim]
                   && "Dimensions size not same");
        }
    }
}

/**
 * @brief Verify that multiple arrays have identical dimensions except one.
 *
 * Helper function for concatenation operations. Asserts that all provided arrays
 * have the same number of dimensions and matching dimension sizes for all dimensions
 * except dimension k (1-based).
 *
 * @param k     Dimension to exclude from comparison (1-based indexing).
 * @param elts  Array of base_array pointers to check.
 * @param n     Number of arrays in the elts array.
 *
 * @pre All pointers in elts must be valid and non-NULL.
 *
 * @note This function uses assertions and will abort if validation fails.
 * @note Dimension k is allowed to differ in size across arrays.
 *
 * @attention Used internally by array concatenation functions like cat_alloc_real_array().
 */
void check_base_array_dim_sizes_except(int k, const base_array_t *elts, int n)
{
    int i, curdim, dimsize;
    int k_loc = k - 1;
    int ndims = elts[0].ndims;
    for(i = 1; i < n; ++i) {
        assert(elts[i].ndims == ndims && "Not same number of dimensions");
    }
    for(curdim = 0; curdim < ndims; ++curdim) {
        if(curdim != k_loc) {
            assert(elts);
            assert(elts[0].dim_size[curdim]);
            dimsize = elts[0].dim_size[curdim];

            for(i = 1; i < n; ++i) {
                assert(dimsize == elts[i].dim_size[curdim]
                       && "Dimensions size not same");
            }
        }
    }
}

/**
 * @brief Compare the shapes (dimensions) of two arrays for equality.
 *
 * Checks if two arrays have the same number of dimensions and all matching
 * dimension sizes.
 *
 * @param a  First array to compare.
 * @param b  Second array to compare.
 *
 * @return 1 if arrays have identical shapes, 0 otherwise. Prints diagnostic
 *         messages to stderr if shapes differ.
 */
int base_array_shape_eq(const base_array_t *a, const base_array_t *b)
{
    int i;

    if(a->ndims != b->ndims) {
        fprintf(stderr, "a->ndims != b->ndims, %d != %d\n", a->ndims, b->ndims);
        return 0;
    }

    for(i = 0; i < a->ndims; ++i) {
        if(a->dim_size[i] != b->dim_size[i]) {
            fprintf(stderr, "a->dim_size[%d] != b->dim_size[%d], %d != %d\n",
                    i, i, (int) a->dim_size[i], (int) b->dim_size[i]);
            return 0;
        }
    }

    return 1;
}

/**
 * @brief Check if an array contains exactly one element.
 *
 * Verifies that all dimensions have size 1, indicating a single-element array
 * (equivalent to a scalar in array form).
 *
 * @param a  The array to check.
 *
 * @return 1 if array has exactly one element (all dims = 1), 0 otherwise.
 */
int base_array_one_element_ok(const base_array_t *a)
{
    int i;

    for(i = 0; i < a->ndims; ++i) {
        if(a->dim_size[i] != 1) {
            return 0;
        }
    }
    return 1;
}

/**
 * @brief Validate that an index specification fits a base array.
 *
 * Checks that an index_spec_t structure is compatible with a base_array structure,
 * verifying that dimensions agree and all indices are within valid bounds.
 *
 * @param s  Index specification to validate.
 * @param a  Base array to validate against.
 *
 * @return 1 if index spec fits the array, 0 otherwise. Prints diagnostic error
 *         messages to stderr if validation fails.
 *
 * @attention Used to validate array indexing operations before execution.
 */
int index_spec_fit_base_array(const index_spec_t *s, const base_array_t *a)
{
    int i, j;

    if(s->ndims != a->ndims) {
        fprintf(stderr, "index spec dimensions and array dimensions do not agree %d != %d\n",
                (int)s->ndims, (int)a->ndims); fflush(stderr);
        return 0;
    }
    for(i = 0; i < s->ndims; ++i) {
        if(s->dim_size[i] == 0) {
            if (s->index[i] != NULL)
            {
              if((s->index[i][0] < 0) || (s->index[i][0] > a->dim_size[i])) {
                  fprintf(stderr,
                          "scalar s->index[%d][0] == %d incorrect, a->dim_size[%d] == %d\n",
                          i, (int) s->index[i][0], i, (int) a->dim_size[i]); fflush(stderr);
                  return 0;
              }
            }
        }

        if(s->index[i] != NULL)
        {
            for(j = 0; j < s->dim_size[i]; ++j) {
                if((s->index[i][j] <= 0) || (s->index[i][j] > a->dim_size[i])) {
                    fprintf(stderr,
                            "array s->index[%d][%d] == %d incorrect, a->dim_size[%d] == %d\n",
                            i, j, (int) s->index[i][j], i, (int) a->dim_size[i]); fflush(stderr);
                    return 0;
                }
            }
        }
    }

    return 1;
}

/**
 * @brief Initialize a 1D base array with existing data.
 *
 * Convenience function for creating a simple 1D array structure with pre-allocated data.
 *
 * @param dest  Pointer to the base_array structure to initialize.
 * @param n     Size of the 1D array (number of elements).
 * @param data  Pointer to the pre-allocated data buffer.
 */
void simple_alloc_1d_base_array(base_array_t *dest, int n, void *data)
{
    dest->ndims = 1;
    dest->dim_size = size_alloc(1);
    dest->dim_size[0] = n;
    dest->data = data;
    dest->flexible = 0;
}

/**
 * @brief Initialize a 2D base array with existing data.
 *
 * Convenience function for creating a simple 2D array structure with pre-allocated data.
 *
 * @param dest  Pointer to the base_array structure to initialize.
 * @param r     Number of rows.
 * @param c     Number of columns.
 * @param data  Pointer to the pre-allocated data buffer.
 */
void simple_alloc_2d_base_array(base_array_t *dest, int r, int c, void *data)
{
    dest->ndims = 2;
    dest->dim_size = size_alloc(2);
    dest->dim_size[0] = r;
    dest->dim_size[1] = c;
    dest->data = data;
    dest->flexible = 0;
}

/**
 * @brief Allocate and initialize a base array structure with variable dimensions.
 *
 * Initializes a base_array structure by setting the number of dimensions and
 * allocating space for dimension sizes. The dimension sizes are extracted from
 * a variable argument list. Computes the total number of elements needed.
 *
 * @param dest   Pointer to the base_array structure to initialize.
 * @param ndims  Number of dimensions.
 * @param ap     Variable argument list containing ndims dimension size values
 *               (each of type _index_t).
 *
 * @return Total number of elements in the array (product of all dimension sizes).
 *
 * @pre ap must contain exactly ndims dimension size arguments of type _index_t.
 *
 * @note The caller is responsible for allocating the actual data buffer separately
 *       and assigning it to dest->data. This function only allocates the metadata
 *       (dimension information).
 *
 * @attention Sets dest->flexible to 0. Used internally by type-specific allocation
 *            functions like alloc_real_array().
 */
size_t alloc_base_array(base_array_t *dest, int ndims, va_list ap)
{
    int i;
    size_t nr_of_elements = 1;

    dest->ndims = ndims;
    dest->dim_size = size_alloc(ndims);

    for(i = 0; i < ndims; ++i) {
        dest->dim_size[i] = va_arg(ap, _index_t);
        nr_of_elements *= dest->dim_size[i];
    }

    dest->flexible = 0;

    return nr_of_elements;
}

/**
 * @brief Copy dimension specification from one array to another.
 *
 * Creates a copy of the dimension metadata (number of dimensions and dimension sizes)
 * from source array to destination array. Does not copy the data pointer.
 *
 * @param source  Source array to copy specification from.
 * @param dest    Destination array to copy specification to.
 *
 * @pre source must be a valid base_array structure.
 *
 * @note The destination array should have an uninitialized dim_size pointer,
 *       as new memory will be allocated for it.
 */
void clone_base_array_spec(const base_array_t *source, base_array_t *dest)
{
    int i;
    assert(base_array_ok(source));

    dest->ndims = source->ndims;
    dest->dim_size = size_alloc(dest->ndims);
    assert(dest->dim_size);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[i];
    }

    dest->flexible = source->flexible;
}

/**
 * @brief Calculate flat index using index specification.
 *
 * Converts multi-dimensional indices with an index specification into a flat 1D index.
 * Handles both scalar indexing and array slicing specifications.
 *
 * @param ndims    Number of dimensions.
 * @param idx_vec  Array of indices (0-based).
 * @param arr      Base array containing dimension information.
 * @param spec     Index specification defining how to map indices.
 *
 * @return Flat 1D index for array element access.
 *
 * @pre idx_vec must have exactly ndims elements.
 * @pre spec and arr dimensions must be compatible.
 * @pre All indices and specifications must be valid and within bounds.
 *
 * @note idx_vec uses 0-based indexing while spec uses 1-based indexing.
 */
size_t calc_base_index_spec(int ndims, const _index_t *idx_vec,
                            const base_array_t *arr, const index_spec_t *spec)
{
    int i;
    int d2;
    size_t index = 0;

    assert(base_array_ok(arr));
    assert(index_spec_ok(spec));
    assert(index_spec_fit_base_array(spec, arr));
    assert((ndims == arr->ndims) && (ndims == spec->ndims));

    index = 0;
    for(i = 0; i < ndims; ++i) {
        int d = idx_vec[i];
        if(spec->index[i] != NULL) {
            d2 = spec->index[i][d] - 1;
        } else {
            d2 = d;
        }
        index = (index * arr->dim_size[i]) + d2;
    }

    return index;
}

/**
 * @brief Calculate flat index from 0-based multi-dimensional indices.
 *
 * Converts multi-dimensional indices (0-based) into a flat 1D index using row-major order.
 *
 * @param ndims    Number of dimensions.
 * @param idx_vec  Array of 0-based indices.
 * @param arr      Base array containing dimension information.
 *
 * @return Flat 1D index for array element access.
 *
 * @pre idx_vec must have exactly ndims elements.
 * @pre All indices must be within valid bounds.
 */
size_t calc_base_index(int ndims, const _index_t *idx_vec, const base_array_t *arr)
{
    int i;
    size_t index = 0;
    assert(ndims == arr->ndims);

    for(i = 0; i < ndims; ++i) {
        /* Assert that idx_vec[i] is not out of bounds */
        index = (index * arr->dim_size[i]) + idx_vec[i];
    }

    return index;
}

/**
 * @brief Calculate flat index from dimension sizes and 1-based subscripts.
 *
 * Calculates a flat 1D index from variable argument lists containing dimension
 * sizes followed by 1-based subscripts. Includes bounds checking with assertions.
 *
 * @param ndims  Number of dimensions.
 * @param ...    Variable arguments: first ndims values are dimension sizes,
 *               next ndims values are 1-based subscripts.
 *
 * @return Flat 1D index for array element access.
 *
 * @attention Asserts on any out-of-bounds subscript.
 * @attention Subscripts are converted from 1-based to 0-based internally.
 */
size_t calc_base_index_dims_subs(int ndims,...)
{

    int i;
    size_t index;

    _index_t *dims = (_index_t*)omc_alloc_interface.malloc(sizeof(_index_t)*ndims);
    _index_t *subs = (_index_t*)omc_alloc_interface.malloc(sizeof(_index_t)*ndims);

    va_list ap;
    va_start(ap,ndims);
    for(i = 0; i < ndims; ++i) {
        dims[i] = va_arg(ap, _index_t);
    }
    for(i = 0; i < ndims; ++i) {
        subs[i] = va_arg(ap, _index_t) - 1;
    }
    va_end(ap);

    index = 0;
    for(i = 0; i < ndims; ++i) {
        if (subs[i] < 0 || subs[i] >= dims[i]) {
          omc_assert(NULL, omc_dummyFileInfo, "Dimension %d has bounds 1..%d, got array subscript %d", i+1, dims[i], subs[i]+1);
        }
        index = (index * dims[i]) + subs[i];
    }


    return index;
}

/**
 * @brief Calculate flat index from 1-based subscripts in a variable argument list.
 *
 * Converts 1-based subscripts from a va_list into a flat 0-based index.
 * Includes bounds checking with assertions.
 *
 * @param source  Base array containing dimension information.
 * @param ndims   Number of dimensions.
 * @param ap      Variable argument list containing ndims 1-based subscripts.
 *
 * @return Flat 1D (0-based) index for array element access.
 *
 * @pre ap must contain exactly ndims subscript values (1-based).
 *
 * @attention Asserts on any out-of-bounds subscript.
 * @attention Input subscripts are 1-based; output index is 0-based.
 */
size_t calc_base_index_va(const base_array_t *source, int ndims, va_list ap)
{
    int i;
    size_t index;

    index = 0;
    for(i = 0; i < ndims; ++i) {
        int sub_i = va_arg(ap, _index_t) - 1;
        if (sub_i < 0 || sub_i >= source->dim_size[i]) {
          omc_assert(NULL, omc_dummyFileInfo, "Dimension %d has bounds 1..%d, got array subscript %d", i+1, source->dim_size[i], sub_i+1);
        }
        index = (index * source->dim_size[i]) + sub_i;
    }

    return index;
}

/**
 * @brief Get the number of dimensions in an array.
 *
 * @param[in] a  The base array structure.
 *
 * @return Number of dimensions (ndims).
 *
 * @pre a must be a valid base_array structure.
 */
int ndims_base_array(const base_array_t* a)
{
    assert(base_array_ok(a));
    return a->ndims;
}

/**
 * @brief Clone array dimensions in reversed order.
 *
 * Creates a copy of the source array's dimension specification but with
 * dimensions in reverse order. For example, a 2x3x4 array becomes 4x3x2.
 *
 * @param source  The source array with dimensions to reverse.
 * @param dest    The destination array where reversed dimensions are stored.
 *
 * @pre source must be a valid base_array structure.
 * @pre dest must not be NULL.
 * @attention Allocates new memory for dest->dim_size; caller is responsible
 *            for cleanup.
 */
void clone_reverse_base_array_spec(const base_array_t* source, base_array_t* dest)
{
    int i;
    assert(base_array_ok(source));

    dest->ndims = source->ndims;
    dest->dim_size = size_alloc(dest->ndims);
    assert(dest->dim_size);

    for(i = 0; i < dest->ndims; ++i) {
        dest->dim_size[i] = source->dim_size[dest->ndims - 1 - i];
    }
}

/**
 * @brief Allocate and compute destination array dimensions from indexed access.
 *
 * Determines the resulting array dimensions when an index_spec is applied to
 * a source array, handling 'A' (all) and 'W' (wildcard) index dimensions.
 * Only counts non-zero dimension sizes.
 *
 * #### Example
 * For a 3x4x5 source array with index spec that selects [2, :, :],
 * the destination array will have dimensions 4x5 (skipping the indexed dimension).
 *
 * @param source       The source array to index into.
 * @param source_spec  The index specification defining which dimensions/indices to access.
 * @param dest         The destination array where computed dimensions are stored.
 *
 * @pre source must be a valid base_array structure.
 * @pre source_spec must be valid and fit the source array.
 * @pre dest must not be NULL.
 */
void index_alloc_base_array_size(const real_array * source,
                                 const index_spec_t* source_spec,
                                 base_array_t* dest)
{
    int i;
    int j;

    omc_assert_macro(base_array_ok(source));
    omc_assert_macro(index_spec_ok(source_spec));
    omc_assert_macro(index_spec_fit_base_array(source_spec, source));

    for(i = 0, j = 0; i < source_spec->ndims; ++i) {
         if(source_spec->dim_size[i] != 0) { /* is 'W' or 'A' */
           ++j;
         }
    }

    dest->ndims = imax(j,1);
    dest->dim_size = size_alloc(dest->ndims);
    for(i = 0; i < dest->ndims; ++i) {
      dest->dim_size[i] = 0;
    }

    for(i = 0, j = 0; i < source_spec->ndims; ++i) {
        if(source_spec->dim_size[i] != 0) { /* is 'W' or 'A' */
            if(source_spec->index[i] != NULL) { /* is 'A' */
                dest->dim_size[j] = source_spec->dim_size[i];
            } else { /* is 'W' */
                dest->dim_size[j] = source->dim_size[i];
            }

            ++j;
        }
    }
}

/**
 * @brief Allocate and initialize index vectors for indexed assignment.
 *
 * Prepares index iteration structures for assigning elements to a destination
 * array via an index specification. Allocates vectors for tracking current
 * indices and dimension sizes in the indexed assignment operation.
 *
 * #### Example
 * For assigning a 4x5 source array to elements dest[2, :, :] of a 3x4x5 array,
 * this initializes the iteration indices and size boundaries.
 *
 * @param source      The source array being assigned.
 * @param dest        The destination array being assigned to.
 * @param dest_spec   The index specification defining target locations in dest.
 * @param _idx_vec1   Output: current iteration indices for destination.
 * @param _idx_size   Output: dimension size boundaries for destination iteration.
 *
 * @pre source must be a valid base_array with dimensions matching indexed dest.
 * @pre dest must be a valid base_array structure.
 * @pre dest_spec must be valid and fit the dest array.
 * @pre _idx_vec1 and _idx_size must be valid pointers to _index_t*.
 */
void indexed_assign_base_array_size_alloc(const base_array_t *source, base_array_t *dest, const index_spec_t *dest_spec, _index_t** _idx_vec1, _index_t** _idx_size)
{
    _index_t* idx_vec1;
    _index_t* idx_size;
    int i, j;
    omc_assert_macro(base_array_ok(source));
    omc_assert_macro(base_array_ok(dest));
    omc_assert_macro(index_spec_ok(dest_spec));
    omc_assert_macro(index_spec_fit_base_array(dest_spec, dest));
    for(i = 0,j = 0; i < dest_spec->ndims; ++i) {
        if(dest_spec->dim_size[i] != 0) {
            ++j;
        }
    }
    omc_assert_macro(j == source->ndims);

    idx_vec1 = size_alloc(dest->ndims);
    idx_size = size_alloc(dest_spec->ndims);

    for(i = 0; i < dest_spec->ndims; ++i) {
        idx_vec1[i] = 0;

        if(dest_spec->index[i] != NULL) { /* is 'S' or 'A' */
            idx_size[i] = imax(dest_spec->dim_size[i],1);
        } else { /* is 'W' */
            idx_size[i] = dest->dim_size[i];
        }
    }
    *_idx_vec1 = idx_vec1;
    *_idx_size = idx_size;
}
