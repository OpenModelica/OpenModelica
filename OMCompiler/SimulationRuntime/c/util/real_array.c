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

#include "real_array.h"
#include "index_spec.h"
#include "../gc/omc_gc.h"
#include "division.h"
#include "integer_array.h"
#include "omc_error.h"
#include "generic_array.h"

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>
#include <float.h>

static inline modelica_real *real_ptrget(const real_array *a, size_t i)
{
    return ((modelica_real *)a->data) + i;
}

static inline void real_set(real_array *a, size_t i, modelica_real r)
{
    ((modelica_real *)a->data)[i] = r;
}

/**
 * @brief Get a single element from a real array by 1D index (row-major order).
 *
 * @param a  The real array to access (0-based indexing in memory).
 * @param i  The flat index of the element to retrieve.
 *
 * @return The value at index i.
 */
modelica_real real_get(const real_array a, size_t i)
{
    return ((modelica_real *)a.data)[i];
}

/**
 * @brief Get a single element from a 2D real array.
 *
 * @param a  The 2D real array (stored in row-major order).
 * @param i  The row index (0-based).
 * @param j  The column index (0-based).
 *
 * @return The value at position (i, j).
 */
modelica_real real_get_2D(const real_array a, size_t i, size_t j)
{
    return real_get(a, getIndex_2D(a.dim_size, i, j));
}

/**
 * @brief Get a single element from a 3D real array.
 *
 * @param a  The 3D real array (stored in row-major order).
 * @param i  The first dimension index (0-based).
 * @param j  The second dimension index (0-based).
 * @param k  The third dimension index (0-based).
 *
 * @return The value at position (i, j, k).
 */
modelica_real real_get_3D(const real_array a, size_t i, size_t j, size_t k)
{
    return real_get(a, getIndex_3D(a.dim_size, i, j, k));
}

/**
 * @brief Get a single element from a 4D real array.
 *
 * @param a  The 4D real array (stored in row-major order).
 * @param i  The first dimension index (0-based).
 * @param j  The second dimension index (0-based).
 * @param k  The third dimension index (0-based).
 * @param l  The fourth dimension index (0-based).
 *
 * @return The value at position (i, j, k, l).
 */
modelica_real real_get_4D(const real_array a, size_t i, size_t j, size_t k, size_t l)
{
    return real_get(a, getIndex_4D(a.dim_size, i, j, k, l));
}

/**
 * @brief Get a single element from a 5D real array.
 *
 * @param a  The 5D real array (stored in row-major order).
 * @param i  The first dimension index (0-based).
 * @param j  The second dimension index (0-based).
 * @param k  The third dimension index (0-based).
 * @param l  The fourth dimension index (0-based).
 * @param m  The fifth dimension index (0-based).
 *
 * @return The value at position (i, j, k, l, m).
 */
modelica_real real_get_5D(const real_array a, size_t i, size_t j, size_t k, size_t l, size_t m)
{
    return real_get(a, getIndex_5D(a.dim_size, i, j, k, l, m));
}

/**
 * @brief Create a real array from existing data and dimension information.
 *
 * This function initializes a real_array structure by setting all its fields:
 * data pointer, number of dimensions (ndims), and dimension sizes. The
 * dimension sizes are passed as variable arguments and must match the ndims
 * parameter.
 *
 * @param[out] dest     Pointer to the real_array structure to be initialized.
 * @param[in]  data     Pointer to the array data (modelica_real values). Must
 *                      be allocated and large enough to hold all elements.
 * @param[in]  ndims    Number of dimensions for the array.
 * @param[in]  ...      Variable arguments specifying the size of each
 *                      dimension. Must provide exactly ndims values, one for
 *                      each dimension.
 *
 * @note The function does not allocate memory for the data; it only wraps
 *       existing data with dimension information. The caller is responsible for
 *       allocating the data buffer and ensuring it has sufficient size.
 *
 * @warning The number and order of dimension size arguments must exactly match
 * ndims.
 *
 * See `alloc_real_array()` for allocation combined with initialization. See
 * `real_array_create()` for alternative creation methods.
 *
 * #### Vector Example (1D array)
 *
 * Create a vector with 5 elements:
 *
 * ```c
 * modelica_real data[5] = {1.0, 2.0, 3.0, 4.0, 5.0};
 * real_array vec;
 * real_array_create(&vec, data, 1, 5);
 * ```
 *
 * #### Matrix Example (2D array)
 *
 * Create a 3x4 matrix in row-major order:
 *
 * ```c
 * modelica_real matrix_data[12] = {
 *     1.0,  2.0,  3.0,  4.0,
 *     5.0,  6.0,  7.0,  8.0,
 *     9.0, 10.0, 11.0, 12.0
 * };
 * real_array mat;
 * real_array_create(&mat, matrix_data, 2, 3, 4);
 * ```
 */
void real_array_create(real_array *dest, modelica_real *data, int ndims, ...)
{
    va_list ap;
    va_start(ap, ndims);
    base_array_create(dest, data, ndims, ap);
    va_end(ap);
}

/**
 * @brief Allocate a 1D real array (vector) of size n with uninitialized values.
 *
 * @param dest  Pointer to the real_array structure to initialize.
 * @param n     Number of elements for the vector.
 *
 * @attention Memory is allocated from the garbage-collected heap; no explicit
 *            free() is needed.
 */
void simple_alloc_1d_real_array(real_array *dest, int n)
{
    simple_alloc_1d_base_array(dest, n, real_alloc(n));
}

/**
 * @brief Allocate a 2D real array (matrix) of size r×c with uninitialized values.
 *
 * @param dest  Pointer to the real_array structure to initialize.
 * @param r     Number of rows in the matrix.
 * @param c     Number of columns in the matrix.
 *
 * @attention Memory is allocated from the garbage-collected heap; no explicit
 *            free() is needed.
 */
void simple_alloc_2d_real_array(real_array *dest, int r, int c)
{
    simple_alloc_2d_base_array(dest, r, c, real_alloc(r * c));
}

/**
 * @brief Allocate a real array with specified dimensions using variable arguments.
 *
 * Allocates memory for a real array with the specified number of dimensions.
 * All dimension sizes must be provided as variable arguments.
 *
 * @param dest    Pointer to the real_array structure to initialize.
 * @param ndims   Number of dimensions.
 * @param ...     Variable arguments specifying the size of each dimension.
 *
 * @attention Memory is allocated from the garbage-collected heap; no explicit
 *            free() is needed.
 */
void alloc_real_array(real_array *dest, int ndims, ...)
{
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = real_alloc(elements);
}

/**
 * @brief Allocate data memory for a real array with pre-configured dimensions.
 *
 * Allocates the data buffer for an array whose dimensions have already been set.
 * Useful when dimension information is already configured in the array structure.
 *
 * @param a  The real_array structure with dimensions already initialized.
 *
 * @pre a->ndims and a->dim_size must be properly initialized.
 * @attention Memory is allocated from the garbage-collected heap; no explicit
 *            free() is needed.
 */
void alloc_real_array_data(real_array *a)
{
    a->data = real_alloc(base_array_nr_of_elements(*a));
}

/**
 * @brief Copy all elements from a real array into a pre-allocated memory buffer.
 *
 * Copies all elements from a real_array structure into a flat memory buffer.
 * The destination buffer must be pre-allocated with sufficient space to hold
 * all array elements (num_elements * sizeof(modelica_real)).
 *
 * @param[in] source  The source real array to copy from.
 * @param[out] dest   Pointer to pre-allocated memory buffer where elements will be copied.
 *
 * @pre source must be a valid real_array structure (checked via base_array_ok).
 * @pre dest must point to valid memory large enough to hold all elements of source.
 * @pre The memory pointed to by dest must not overlap with source.data.
 *
 * @note This function performs element-by-element copying. For large arrays,
 *       consider the performance implications. The function is safe for arrays
 *       of any dimensionality as it copies all elements sequentially.
 *
 * @attention The caller is responsible for allocating and managing the dest buffer.
 *            This function does not allocate or free memory for dest.
 *
 * #### Example: Copy vector elements to buffer
 *
 * ```c
 * real_array vec;
 * simple_alloc_1d_real_array(&vec, 5);
 * // ... populate vec with data ...
 *
 * modelica_real buffer[5];
 * copy_real_array_data_mem(vec, buffer);
 * // buffer now contains all elements from vec
 * ```
 *
 * #### Example: Copy matrix elements to buffer
 *
 * ```c
 * real_array mat;
 * alloc_real_array(&mat, 2, 3, 4);  // 3x4 matrix
 * // ... populate mat with data ...
 *
 * modelica_real *buffer = (modelica_real *)malloc(12 * sizeof(modelica_real));
 * copy_real_array_data_mem(mat, buffer);
 * // buffer now contains all 12 elements from the 3x4 matrix
 * free(buffer);
 * ```
 */
void copy_real_array_data_mem(const real_array source, modelica_real *dest)
{
    size_t i, nr_of_elements;

    omc_assert_macro(base_array_ok(&source));

    nr_of_elements = base_array_nr_of_elements(source);

    for (i = 0; i < nr_of_elements; ++i)
    {
        dest[i] = real_get(source, i);
    }
}

/**
 * @brief Create a deep copy of a real array.
 *
 * Allocates new memory for the destination array and copies all elements
 * from the source array. Both the structure and data are duplicated.
 *
 * @param source  The source real array to copy from.
 * @param dest    Pointer to the destination real_array structure to be initialized.
 *
 * @attention Memory for dest->data is allocated from the garbage-collected heap;
 *            no explicit free() is needed.
 */
void copy_real_array(const real_array source, real_array *dest)
{
    real_array_alloc_copy(source, *dest);
}

static modelica_real real_le(modelica_real x, modelica_real y)
{
    return (x <= y);
}

static modelica_real real_ge(modelica_real x, modelica_real y)
{
    return (x >= y);
}

/**
 * @brief Fill a real array with values from a range with start, step, and stop values.
 *
 * Fills the destination array with evenly-spaced values. If step > 0, values are
 * generated from start to stop (inclusive if step divides evenly). If step < 0,
 * values are generated from start down to stop.
 *
 * @param dest   Pointer to the pre-allocated real_array to fill.
 * @param start  The first value in the range.
 * @param step   The increment between consecutive values (must not be zero).
 * @param stop   The end value of the range (inclusive if reachable with step size).
 *
 * @pre dest must be pre-allocated with sufficient space to hold all generated values.
 * @attention The number of elements generated is calculated from the range;
 *            caller must ensure dest has adequate capacity.
 *
 * #### Example
 *
 * ```c
 * real_array arr;
 * alloc_real_array(&arr, 1, 10);  // Allocate 10 elements
 * fill_real_array_from_range(&arr, 1.0, 0.5, 5.5);
 * // arr now contains: 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 5.5
 * ```
 */
void fill_real_array_from_range(real_array *dest,
                                modelica_real start,
                                modelica_real step,
                                modelica_real stop)
{
    size_t elements;
    size_t i;
    modelica_real value = start;
    modelica_real (*comp_func)(modelica_real, modelica_real);
    omc_assert_macro(step != 0);

    comp_func = (step > 0) ? &real_le : &real_ge;
    elements = comp_func(start, stop) ? (((stop - start) / step) + 1) : 0;

    for (i = 0; i < elements; value += step, ++i)
    {
        real_set(dest, i, value);
    }
}

/**
 * @brief Get pointer to a real array element using an index specification.
 *
 * Internal helper function (static inline) for accessing array elements with
 * index specifications that handle slicing and dimension selection.
 */
static inline modelica_real *calc_real_index_spec(int ndims, const _index_t *idx_vec,
                                                  const real_array *arr,
                                                  const index_spec_t *spec)
{
    return real_ptrget(arr, calc_base_index_spec(ndims, idx_vec, arr, spec));
}

/**
 * @brief Get pointer to a real array element using 0-based multi-dimensional indices.
 *
 * Calculates the flat memory address of an element given its coordinates in
 * a multi-dimensional array using 0-based indexing.
 *
 * @param ndims   Number of dimensions.
 * @param idx_vec Array of 0-based indices, one for each dimension.
 * @param arr     The real array.
 *
 * @return Pointer to the element at the specified indices.
 *
 * @pre ndims must match arr->ndims.
 * @pre idx_vec must contain exactly ndims valid indices.
 */
modelica_real *calc_real_index(int ndims, const _index_t *idx_vec, const real_array *arr)
{
    return real_ptrget(arr, calc_base_index(ndims, idx_vec, arr));
}

/**
 * @brief Get pointer to a real array element using 1-based indices from variable arguments.
 *
 * Calculates the flat memory address of an element given its 1-based coordinates
 * as variable arguments. Provides bounds checking.
 *
 * @param source  The real array.
 * @param ndims   Number of dimensions.
 * @param ap      Variable argument list of 1-based indices.
 *
 * @return Pointer to the element at the specified indices.
 *
 * @pre source must be a valid array with ndims dimensions.
 * @pre ap must contain exactly ndims valid 1-based indices within bounds.
 * @attention Asserts on out-of-bounds indices.
 */
modelica_real *calc_real_index_va(const real_array *source, int ndims, va_list ap)
{
    return real_ptrget(source, calc_base_index_va(source, ndims, ap));
}

/**
 * @brief Print a 2D real array (matrix) to standard output.
 *
 * Prints the matrix in a formatted grid showing all rows and columns.
 * Elements are displayed in scientific notation separated by tabs.
 * For non-2D arrays, prints an informational message.
 *
 * @param source  The real array to print. Should be 2D for proper formatting.
 */
void print_real_matrix(const real_array *source)
{
    _index_t i, j;
    modelica_real value;

    if (source->ndims == 2)
    {
        printf("%d X %d matrix:\n", (int)source->dim_size[0], (int)source->dim_size[1]);
        for (i = 0; i < source->dim_size[0]; ++i)
        {
            for (j = 0; j < source->dim_size[1]; ++j)
            {
                value = real_get(*source, (i * source->dim_size[1]) + j);
                printf("%e\t", value);
            }
            printf("\n");
        }
    }
    else
    {
        printf("array with %d dimensions\n", source->ndims);
    }
}

/**
 * @brief Print a real array to standard output in a formatted manner.
 *
 * For 1D arrays (vectors), prints comma-separated values in a row.
 * For multi-dimensional arrays, prints in a grid format with row breaks.
 *
 * @param source  The real array to print.
 *
 * @pre source must be a valid base_array structure.
 */
void print_real_array(const real_array *source)
{
    _index_t i, j;
    modelica_real *data;
    omc_assert_macro(base_array_ok(source));

    data = (modelica_real *)source->data;
    if (source->ndims == 1)
    {
        for (i = 1; i < source->dim_size[0]; ++i)
        {
            printf("%e, ", *data);
            ++data;
        }
        if (0 < source->dim_size[0])
        {
            printf("%e", *data);
        }
    }
    else if (source->ndims > 1)
    {
        size_t k, n;

        n = base_array_nr_of_elements(*source) /
            (source->dim_size[0] * source->dim_size[1]);
        for (k = 0; k < n; ++k)
        {
            for (i = 0; i < source->dim_size[1]; ++i)
            {
                for (j = 0; j < source->dim_size[0]; ++j)
                {
                    printf("%e, ", *data);
                    ++data;
                }
                if (0 < source->dim_size[0])
                {
                    printf("%e", *data);
                }
                printf("\n");
            }
            if ((k + 1) < n)
            {
                printf("\n =================\n");
            }
        }
    }
}

/**
 * @brief Write real vector into null-terminated string.
 *
 * @param source        Real vector to write to buffer.
 * @param isScalar      Treat vector as scalar.
 * @return const char*  Pointer to static buffer. Not thread-safe!
 */
const char *real_vector_to_string(const real_array *source, modelica_boolean isScalar)
{
    _index_t i;
    modelica_real *data;
    static char buffer[2048];
    size_t pos = 0;

    omc_assert_macro(base_array_ok(source));
    assert(source->ndims == 1);

    data = (modelica_real *)source->data;

    if (isScalar && source->ndims == 1 && source->dim_size[0] == 1)
    {
        pos += snprintf(buffer + pos, sizeof(buffer) - pos,
                        "%g", data[0]);
    }
    else
    {
        pos += snprintf(buffer + pos, sizeof(buffer) - pos, "{");
        for (i = 0; i < source->dim_size[0]; i++)
        {
            pos += snprintf(buffer + pos, sizeof(buffer) - pos,
                            "%g%s", data[i], (i < source->dim_size[0] - 1) ? ", " : "");
            if (pos >= sizeof(buffer))
            {
                break;
            }
        }
        snprintf(buffer + pos, sizeof(buffer) - pos, "}");
    }

    return buffer;
}

/**
 * @brief Set a single element in a real array by flat index (0-based).
 *
 * @param value  Value to store.
 * @param i1     Flat (0-based) index into the array data.
 * @param dest   Destination array where the value will be stored.
 *
 * @pre dest must be a valid real_array and i1 must be in bounds.
 * @attention This function writes directly into the array's data buffer.
 */
void put_real_element(modelica_real value, int i1, real_array *dest)
{
    real_set(dest, i1, value);
}

/**
 * @brief Set a single element in a 2D real matrix by row and column (0-based).
 *
 * @param value  Value to store.
 * @param r      Row index (0-based).
 * @param c      Column index (0-based).
 * @param dest   Destination matrix.
 *
 * @pre dest->ndims must be >= 2 and r,c must be within the matrix bounds.
 */
void put_real_matrix_element(modelica_real value, int r, int c, real_array *dest)
{
    /* Assert that dest hast correct dimension */
    /* Assert that r and c are valid indices */
    real_set(dest, (r * dest->dim_size[1]) + c, value);
}

/**
 * @brief Simple indexed assignment for 1D arrays: dest[i1] := source[i1].
 *
 * Copies a single element from the source vector into the destination at
 * the same flat index.
 *
 * @param source  Source real array (vector).
 * @param i1      Index to copy (0-based).
 * @param dest    Destination real array.
 *
 * @pre source and dest must be valid and have compatible dimensions.
 */
void simple_indexed_assign_real_array1(const real_array *source,
                                       int i1,
                                       real_array *dest)
{
    /* Assert that source has the correct dimension */
    /* Assert that dest has the correct dimension */
    real_set(dest, i1, real_get(*source, i1));
}

/**
 * @brief Simple indexed assignment for 2D arrays: dest[i1,i2] := source[i1,i2].
 *
 * Copies a single element from the source 2D array into the destination at
 * the computed flat index.
 *
 * @param source  Source real array (2D).
 * @param i1      First index (0-based).
 * @param i2      Second index (0-based).
 * @param dest    Destination real array.
 *
 * @pre source and dest must be valid and have compatible dimensions.
 */
void simple_indexed_assign_real_array2(const real_array *source,
                                       int i1,
                                       int i2,
                                       real_array *dest)
{
    size_t index;
    /* Assert that source has correct dimension */
    /* Assert that dest has correct dimension */
    index = (i1 * source->dim_size[1]) + i2;
    real_set(dest, index, real_get(*source, index));
}

/**
 * @brief Perform indexed assignment from a source vector into a destination array
 *        according to an index specification.
 *
 * The function iterates over the index specification and assigns elements from
 * the source (flattened) into the positions in dest defined by dest_spec.
 *
 * @param source     Source real array (flattened view expected).
 * @param dest       Destination real array to receive values.
 * @param dest_spec  Index specification describing target positions in dest.
 *
 * @pre dest_spec must be valid and fit the destination array.
 */
void indexed_assign_real_array(const real_array source, real_array *dest,
                               const index_spec_t *dest_spec)
{
    _index_t *idx_vec1, *idx_size;
    int j;
    indexed_assign_base_array_size_alloc(&source, dest, dest_spec, &idx_vec1, &idx_size);

    j = 0;
    do
    {
        real_set(dest,
                 calc_base_index_spec(dest->ndims, idx_vec1, dest, dest_spec),
                 real_get(source, j));
        j++;

    } while (0 == next_index(dest_spec->ndims, idx_vec1, idx_size));

    omc_assert_macro(j == base_array_nr_of_elements(source));
}

/**
 * @brief Extract elements from a source array according to an index specification.
 *
 * Copies elements from `source` into `dest` as defined by `source_spec`.
 * Both arrays must be properly allocated and the index specification must
 * fit the source array.
 *
 * @param source       The source real array.
 * @param source_spec  Index specification describing which elements to extract.
 * @param dest         Destination real array to receive extracted elements.
 *
 * @pre `source_spec` must be valid and fit `source`.
 */
void index_real_array(const real_array *source,
                      const index_spec_t *source_spec,
                      real_array *dest)
{
    _index_t *idx_vec1;
    _index_t *idx_size;
    int j;
    int i;

    omc_assert_macro(base_array_ok(source));
    omc_assert_macro(base_array_ok(dest));
    omc_assert_macro(index_spec_ok(source_spec));
    omc_assert_macro(index_spec_fit_base_array(source_spec, source));

    if (dest->ndims == 1 && dest->dim_size[0] == 0)
        return;

    for (i = 0, j = 0; i < source_spec->ndims; ++i)
    {
        if (source_spec->dim_size[i] != 0)
        {
            ++j;
        }
    }
    omc_assert_macro(imax(j, 1) == dest->ndims);

    idx_vec1 = size_alloc(source->ndims);
    idx_size = size_alloc(source_spec->ndims);

    for (i = 0; i < source->ndims; ++i)
    {
        idx_vec1[i] = 0;
    }
    for (i = 0; i < source_spec->ndims; ++i)
    {
        if (source_spec->index[i] != NULL)
        {                                                    /* is 'S' or 'A' */
            idx_size[i] = imax(source_spec->dim_size[i], 1); /* the imax() is not needed, because there is (idx[d] >= size[d]) in the next_index(), but ... */
        }
        else
        { /* is 'W' */
            idx_size[i] = source->dim_size[i];
        }
    }

    j = 0;
    do
    {
        real_set(dest, j,
                 real_get(*source,
                          calc_base_index_spec(source->ndims, idx_vec1,
                                               source, source_spec)));
        j++;

    } while (0 == next_index(source->ndims, idx_vec1, idx_size));

    omc_assert_macro(j == base_array_nr_of_elements(*dest));
}

/**
 * @brief Allocate destination array and extract a subarray defined by an index spec.
 *
 * Computes the required destination dimensions (using `index_alloc_base_array_size`),
 * allocates the data buffer, and performs the extraction via `index_real_array`.
 *
 * @param source       The source real array.
 * @param source_spec  Index specification describing which elements to extract.
 * @param dest         Destination real array to initialize and fill.
 */
void index_alloc_real_array(const real_array *source,
                            const index_spec_t *source_spec,
                            real_array *dest)
{
    index_alloc_base_array_size(source, source_spec, dest);
    alloc_real_array_data(dest);
    index_real_array(source, source_spec, dest);
}

/**
 * @brief Allocate a (n-1)-dimensional destination array for simple indexing on the first axis.
 *
 * Prepares `dest` to receive `source[i1,:,:...]` by setting its dimension sizes
 * and allocating the data buffer.
 */
void simple_index_alloc_real_array1(const real_array *source, int i1,
                                    real_array *dest)
{
    int i;
    omc_assert_macro(base_array_ok(source));

    dest->ndims = source->ndims - 1;
    dest->dim_size = size_alloc(dest->ndims);
    omc_assert_macro(dest->dim_size);

    for (i = 0; i < dest->ndims; ++i)
    {
        dest->dim_size[i] = source->dim_size[i + 1];
    }
    alloc_real_array_data(dest);

    simple_index_real_array1(source, i1, dest);
}

/**
 * @brief Extract a subarray for a fixed first index: dest := source[i1,:,:...].
 *
 * Copies the contiguous block corresponding to the selected first index.
 */
void simple_index_real_array1(const real_array *source,
                              int i1,
                              real_array *dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * i1;

    for (i = 0; i < nr_of_elements; off++, i++)
    {
        real_set(dest, i, real_get(*source, off));
    }
}

/**
 * @brief Extract a subarray for fixed two first indices: dest := source[i1,i2,:,:...].
 */
void simple_index_real_array2(const real_array *source,
                              int i1, int i2,
                              real_array *dest)
{
    size_t i;
    size_t nr_of_elements = base_array_nr_of_elements(*dest);
    size_t off = nr_of_elements * ((source->dim_size[1] * i1) + i2);

    for (i = 0; i < nr_of_elements; i++, off++)
    {
        real_set(dest, i, real_get(*source, off));
    }
}

/**
 * @brief Concatenate multiple real arrays into a pre-allocated destination.
 *
 * Appends the flattened contents of `n` input arrays (`first`, followed by
 * the variable arguments) into `dest`. The destination must already be
 * allocated with sufficient space.
 *
 * @param dest   Destination array where concatenated elements are stored.
 * @param n      Number of input arrays to concatenate.
 * @param first  First input array; remaining arrays are provided as varargs.
 */
void array_real_array(real_array *dest, int n, real_array first, ...)
{
    int i, j, c;
    va_list ap;

    real_array *elts = (real_array *)malloc(sizeof(real_array) * n);
    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;
    for (i = 1; i < n; ++i)
    {
        elts[i] = va_arg(ap, real_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts, n);

    for (i = 0, c = 0; i < n; ++i)
    {
        int m = base_array_nr_of_elements(elts[i]);
        for (j = 0; j < m; ++j)
        {
            real_set(dest, c, real_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

/**
 * @brief Allocate and concatenate multiple real arrays into `dest`.
 *
 * Computes the required destination dimensions, allocates `dest->data`, and
 * fills `dest` with the flattened contents of the provided arrays.
 *
 * @param dest   Destination array to allocate and initialize.
 * @param n      Number of input arrays.
 * @param first  First input array; remaining arrays provided as varargs.
 */
void array_alloc_real_array(real_array *dest, int n, real_array first, ...)
{
    int i, j, c;
    va_list ap;

    real_array *elts = (real_array *)malloc(sizeof(real_array) * n);
    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;
    for (i = 1; i < n; ++i)
    {
        elts[i] = va_arg(ap, real_array);
    }
    va_end(ap);

    check_base_array_dim_sizes(elts, n);

    if (first.ndims == 1)
    {
        alloc_real_array(dest, 2, n, first.dim_size[0]);
    }
    else if (first.ndims == 2)
    {
        alloc_real_array(dest, 3, n, first.dim_size[0], first.dim_size[1]);
    }
    else if (first.ndims == 3)
    {
        alloc_real_array(dest, 4, n, first.dim_size[0], first.dim_size[1], first.dim_size[2]);
    }
    else if (first.ndims == 4)
    {
        alloc_real_array(dest, 5, n, first.dim_size[0], first.dim_size[1], first.dim_size[2], first.dim_size[3]);
    }
    else
    {
        omc_assert_macro(0 && "Dimension size > 4 not impl. yet");
    }

    for (i = 0, c = 0; i < n; ++i)
    {
        int m = base_array_nr_of_elements(elts[i]);
        for (j = 0; j < m; ++j)
        {
            real_set(dest, c, real_get(elts[i], j));
            c++;
        }
    }
    free(elts);
}

/**
 * @brief Create (allocate) a 1D real array from scalar arguments.
 *
 * Allocates a vector of length `n` and fills it with the scalar arguments
 * provided (first followed by varargs).
 *
 * @param dest   Destination vector to allocate and fill.
 * @param n      Number of scalar elements.
 * @param first  First scalar element; remaining elements provided as varargs.
 */
void array_alloc_scalar_real_array(real_array *dest, int n, modelica_real first, ...)
{
    int i;
    va_list ap;
    simple_alloc_1d_real_array(dest, n);
    va_start(ap, first);
    put_real_element(first, 0, dest);
    for (i = 1; i < n; ++i)
    {
        put_real_element(va_arg(ap, modelica_real), i, dest);
    }
    va_end(ap);
}

/**
 * @brief Concatenate multiple real arrays along the k-th dimension (k is 1-based).
 *
 * Appends the input arrays along the specified dimension into a pre-allocated
 * destination array `dest`.
 *
 * @param k      Dimension index (1-based) along which to concatenate.
 * @param dest   Pre-allocated destination array.
 * @param n      Number of input arrays.
 * @param first  First input array; remaining arrays provided as varargs.
 */
void cat_real_array(int k, real_array *dest, int n,
                    const real_array *first, ...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const real_array **elts = (const real_array **)malloc(sizeof(real_array *) * n);

    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for (i = 1; i < n; i++)
    {
        elts[i] = va_arg(ap, const real_array *);
    }
    va_end(ap);

    /* check dim sizes of all inputs and dest */
    omc_assert_macro(elts[0]->ndims >= k);
    for (i = 0; i < n; i++)
    {
        omc_assert_macro(dest->ndims == elts[i]->ndims);
        for (j = 0; j < (k - 1); j++)
        {
            omc_assert_macro(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k - 1];
        for (j = k; j < elts[0]->ndims; j++)
        {
            omc_assert_macro(dest->dim_size[j] == elts[i]->dim_size[j]);
        }
    }
    omc_assert_macro(dest->dim_size[k - 1] == new_k_dim_size);

    /* calculate size of sub and super structure in 1-dim data representation */
    for (i = 0; i < (k - 1); i++)
    {
        n_super *= elts[0]->dim_size[i];
    }
    for (i = k; i < elts[0]->ndims; i++)
    {
        n_sub *= elts[0]->dim_size[i];
    }

    /* concatenation along k-th dimension */
    j = 0;
    for (i = 0; i < n_super; i++)
    {
        for (c = 0; c < n; c++)
        {
            int n_sub_k = n_sub * elts[c]->dim_size[k - 1];
            for (r = 0; r < n_sub_k; r++)
            {
                real_set(dest, j,
                         real_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/**
 * @brief Allocate and concatenate multiple real arrays along the k-th dimension.
 *
 * Computes the required `dest` dimensions and fills the allocated destination
 * with concatenated inputs.
 *
 * @param k      Dimension index (1-based) along which to concatenate.
 * @param dest   Destination array to allocate and fill.
 * @param n      Number of input arrays.
 * @param first  First input array; remaining arrays provided as varargs.
 */
void cat_alloc_real_array(int k,
                          real_array *dest,
                          int n,
                          const real_array *first, ...)
{
    va_list ap;
    int i, j, r, c;
    int n_sub = 1, n_super = 1;
    int new_k_dim_size = 0;
    const real_array **elts = (const real_array **)malloc(sizeof(real_array *) * n);

    omc_assert_macro(elts);
    /* collect all array ptrs to simplify traversal.*/
    va_start(ap, first);
    elts[0] = first;

    for (i = 1; i < n; i++)
    {
        elts[i] = va_arg(ap, const real_array *);
    }
    va_end(ap);

    /* check dim sizes of all inputs */
    omc_assert_macro(elts[0]->ndims >= k);
    new_k_dim_size = elts[0]->dim_size[k - 1];
    for (i = 1; i < n; i++)
    {
        omc_assert_macro(elts[0]->ndims == elts[i]->ndims);
        for (j = 0; j < (k - 1); j++)
        {
            omc_assert_macro(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
        }
        new_k_dim_size += elts[i]->dim_size[k - 1];
        for (j = k; j < elts[0]->ndims; j++)
        {
            omc_assert_macro(elts[0]->dim_size[j] == elts[i]->dim_size[j]);
        }
    }

    /* calculate size of sub and super structure in 1-dim data representation */
    for (i = 0; i < (k - 1); i++)
    {
        n_super *= elts[0]->dim_size[i];
    }
    for (i = k; i < elts[0]->ndims; i++)
    {
        n_sub *= elts[0]->dim_size[i];
    }
    /* allocate dest structure */
    dest->data = real_alloc(n_super * new_k_dim_size * n_sub);
    dest->ndims = elts[0]->ndims;
    dest->dim_size = size_alloc(dest->ndims);
    for (j = 0; j < dest->ndims; j++)
    {
        dest->dim_size[j] = elts[0]->dim_size[j];
    }
    dest->dim_size[k - 1] = new_k_dim_size;
    /* concatenation along k-th dimension */
    j = 0;
    for (i = 0; i < n_super; i++)
    {
        for (c = 0; c < n; c++)
        {
            int n_sub_k = n_sub * elts[c]->dim_size[k - 1];
            for (r = 0; r < n_sub_k; r++)
            {
                real_set(dest, j,
                         real_get(*elts[c], r + (i * n_sub_k)));
                j++;
            }
        }
    }
    free(elts);
}

/**
 * @brief Allocate a 1D real array and fill it with a numeric range.
 *
 * Allocates a vector of values starting at `start`, incrementing by `inc`,
 * and ending at or before `stop` (depending on step alignment).
 *
 * @param start  Start value.
 * @param stop   Stop value.
 * @param inc    Increment (step).
 * @param dest   Destination vector to allocate and fill.
 */
void range_alloc_real_array(modelica_real start, modelica_real stop, modelica_real inc, real_array *dest)
{
    int n;

    n = (int)floor((stop - start) / inc) + 1;
    simple_alloc_1d_real_array(dest, n);
    range_real_array(start, stop, inc, dest);
}

/**
 * @brief Fill an existing 1D array with a numeric range.
 *
 * Populates `dest` with values starting at `start` and incremented by `inc`.
 * `dest` must already be allocated with sufficient length.
 *
 * @param start  Start value.
 * @param stop   Stop value (unused by this function; kept for API symmetry).
 * @param inc    Increment (step).
 * @param dest   Destination vector to fill.
 */
void range_real_array(modelica_real start, modelica_real stop, modelica_real inc, real_array *dest)
{
    int i;
    modelica_real v = start;
    /* Assert that dest has correct size */
    for (i = 0; i < dest->dim_size[0]; ++i, v += inc)
    {
        real_set(dest, i, v);
    }
}

/**
 * @brief Element-wise addition of two real arrays: dest := a + b.
 *
 * Adds corresponding elements of `a` and `b` and stores the result in `dest`.
 * Arrays must have the same shape.
 */
void add_real_array(const real_array *a, const real_array *b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) + real_get(*b, i));
    }
}

/**
 * @brief Allocate and return the element-wise sum of two real arrays.
 *
 * Clones the shape of `a`, allocates storage for the result, and returns
 * a new array containing `a + b`.
 */
real_array add_alloc_real_array(const real_array a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    add_real_array(&a, &b, &dest);
    return dest;
}

/**
 * @brief Allocate and return array resulting from adding a scalar to each element.
 *
 * Returns `sc + arr` with the same shape as `arr`.
 */
real_array add_alloc_real_array_scalar(const real_array arr, const modelica_real sc)
{
    size_t nr_of_elements, i;
    real_array dest;
    clone_real_array_spec(&arr, &dest);
    alloc_real_array_data(&dest);
    nr_of_elements = base_array_nr_of_elements(arr);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(&dest, i, sc + real_get(arr, i));
    }
    return dest;
}

real_array sub_alloc_scalar_real_array(modelica_real sc, const real_array arr)
{
    size_t nr_of_elements, i;
    real_array dest;
    clone_real_array_spec(&arr, &dest);
    alloc_real_array_data(&dest);
    nr_of_elements = base_array_nr_of_elements(arr);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(&dest, i, sc - real_get(arr, i));
    }
    return dest;
}

/**
 * @brief In-place unary negation of a real array (a := -a).
 */
void usub_real_array(real_array *a)
{
    size_t nr_of_elements, i;

    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(a, i, -real_get(*a, i));
    }
}

/**
 * @brief Allocate and return the unary negation of a real array.
 */
void usub_alloc_real_array(const real_array a, real_array *dest)
{
    size_t nr_of_elements, i;
    clone_real_array_spec(&a, dest);
    alloc_real_array_data(dest);

    nr_of_elements = base_array_nr_of_elements(*dest);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, -real_get(a, i));
    }
}

/**
 * @brief Element-wise subtraction: dest := a - b.
 */
void sub_real_array(const real_array *a, const real_array *b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) - real_get(*b, i));
    }
}

/**
 * @brief Element-wise subtraction writing into a pre-allocated C buffer.
 *
 * Writes (a - b) into `dest` (C array of modelica_real).
 */
void sub_real_array_data_mem(const real_array *a,
                             const real_array *b,
                             modelica_real *dest)
{
    size_t nr_of_elements;
    size_t i;

    /* Assert a and b are of the same size */
    /* Assert that dest are of correct size */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        dest[i] = real_get(*a, i) - real_get(*b, i);
    }
}

/**
 * @brief Allocate and return dest := a - b.
 */
real_array sub_alloc_real_array(const real_array a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    sub_real_array(&a, &b, &dest);
    return dest;
}

/**
 * @brief Multiply every element of `b` by scalar `a` and store in `dest`.
 */
void mul_scalar_real_array(modelica_real a,
                           const real_array *b,
                           real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    nr_of_elements = base_array_nr_of_elements(*b);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, a * real_get(*b, i));
    }
}

/**
 * @brief Allocate and return the result of scalar * array.
 *
 * TODO: Remove me
 */
real_array mul_alloc_scalar_real_array(modelica_real a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&b, &dest);
    alloc_real_array_data(&dest);
    mul_scalar_real_array(a, &b, &dest);
    return dest;
}

/**
 * @brief Multiply every element of `a` by scalar `b` and store in `dest`.
 */
void mul_real_array_scalar(const real_array *a,
                           modelica_real b,
                           real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) * b);
    }
}

/**
 * @brief Allocate and return the result of array * scalar.
 */
real_array mul_alloc_real_array_scalar(const real_array a,
                                       const modelica_real b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    mul_real_array_scalar(&a, b, &dest);
    return dest;
}

/**
 * @brief Element-wise multiplication of two real arrays: dest := a * b.
 */
void mul_real_array(const real_array *a, const real_array *b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that a,b have same sizes? */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) * real_get(*b, i));
    }
}

/**
 * @brief Allocate and return the element-wise product of two arrays.
 */
real_array mul_alloc_real_array(const real_array a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    mul_real_array(&a, &b, &dest);
    return dest;
}

/**
 * @brief Compute the scalar (dot) product of two vectors.
 */
modelica_real mul_real_scalar_product(const real_array a, const real_array b)
{
    size_t nr_of_elements;
    size_t i;
    modelica_real res;
    /* Assert that a and b are vectors */
    /* Assert that vectors are of matching size */

    nr_of_elements = real_array_nr_of_elements(a);
    res = 0.0;
    for (i = 0; i < nr_of_elements; ++i)
    {
        res += real_get(a, i) * real_get(b, i);
    }
    return res;
}

/**
 * @brief Matrix-matrix multiplication: dest := a * b.
 *
 * Computes the matrix product of `a` and `b` storing the result in `dest`.
 * All arrays are in row-major order.
 */
void mul_real_matrix_product(const real_array *a, const real_array *b, real_array *dest)
{
    modelica_real tmp;
    size_t i_size;
    size_t j_size;
    size_t k_size;
    size_t i;
    size_t j;
    size_t k;

    /* Assert that dest has correct size */
    i_size = dest->dim_size[0];
    j_size = dest->dim_size[1];
    k_size = a->dim_size[1];

    for (i = 0; i < i_size; ++i)
    {
        for (j = 0; j < j_size; ++j)
        {
            tmp = 0;
            for (k = 0; k < k_size; ++k)
            {
                tmp += real_get(*a, (i * k_size) + k) * real_get(*b, (k * j_size) + j);
            }
            real_set(dest, (i * j_size) + j, tmp);
        }
    }
}

/**
 * @brief Matrix-vector multiplication: dest := a * b (b is a vector).
 */
void mul_real_matrix_vector(const real_array *a, const real_array *b, real_array *dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_real tmp;

    /* Assert a matrix */
    /* Assert b vector */
    /* Assert dest correct size (a vector)*/

    i_size = a->dim_size[0];
    j_size = a->dim_size[1];

    for (i = 0; i < i_size; ++i)
    {
        tmp = 0;
        for (j = 0; j < j_size; ++j)
        {
            tmp += real_get(*a, (i * j_size) + j) * real_get(*b, j);
        }
        real_set(dest, i, tmp);
    }
}

/**
 * @brief Vector-matrix multiplication: dest := a * b (a is a vector).
 */
void mul_real_vector_matrix(const real_array *a, const real_array *b, real_array *dest)
{
    size_t i;
    size_t j;
    size_t i_size;
    size_t j_size;
    modelica_real tmp;

    /* Assert a vector */
    /* Assert b matrix */
    /* Assert dest vector of correct size */

    i_size = a->dim_size[0];
    j_size = b->dim_size[1];

    for (i = 0; i < i_size; ++i)
    {
        tmp = 0;
        for (j = 0; j < j_size; ++j)
        {
            tmp += real_get(*a, j) * real_get(*b, (j * j_size) + i);
        }
        real_set(dest, i, tmp);
    }
}

/**
 * @brief Smart allocator for matrix/vector multiplication.
 *
 * Chooses the appropriate result shape for combinations of vector/matrix
 * and performs the multiplication, allocating the result.
 */
real_array mul_alloc_real_matrix_product_smart(const real_array a, const real_array b)
{
    real_array dest;
    if ((a.ndims == 1) && (b.ndims == 2))
    {
        simple_alloc_1d_real_array(&dest, b.dim_size[1]);
        mul_real_vector_matrix(&a, &b, &dest);
    }
    else if ((a.ndims == 2) && (b.ndims == 1))
    {
        simple_alloc_1d_real_array(&dest, a.dim_size[0]);
        mul_real_matrix_vector(&a, &b, &dest);
    }
    else if ((a.ndims == 2) && (b.ndims == 2))
    {
        simple_alloc_2d_real_array(&dest, a.dim_size[0], b.dim_size[1]);
        mul_real_matrix_product(&a, &b, &dest);
    }
    else
    {
        omc_assert_macro(0 == "Invalid size of matrix");
    }
    return dest;
}

/**
 * @brief Divide every element of array `a` by scalar `b` and store in `dest`.
 */
void div_real_array_scalar(const real_array *a, modelica_real b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) / b);
    }
}

/**
 * @brief Allocate and return array := a / b (scalar division).
 */
real_array div_alloc_real_array_scalar(const real_array a, const modelica_real b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    div_real_array_scalar(&a, b, &dest);
    return dest;
}

/**
 * @brief Division with runtime check wrapper; uses DIVISIONNOTIME macro.
 */
void division_real_array_scalar(threadData_t *threadData, const real_array *a, modelica_real b, real_array *dest, const char *division_str)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, DIVISIONNOTIME(real_get(*a, i), b, division_str));
    }
}

/**
 * @brief Allocate and perform division with runtime checks.
 */
real_array division_alloc_real_array_scalar(threadData_t *threadData, const real_array a, modelica_real b, const char *division_str)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    division_real_array_scalar(threadData, &a, b, &dest, division_str);
    return dest;
}

/**
 * @brief Divide scalar `a` by every element of array `b` and store in `dest`.
 */
void div_scalar_real_array(modelica_real a, const real_array *b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that dest has correct size*/
    /* Do we need to check for b=0? */
    nr_of_elements = base_array_nr_of_elements(*b);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, a / real_get(*b, i));
    }
}

/**
 * @brief Allocate and return scalar / array.
 */
real_array div_alloc_scalar_real_array(modelica_real a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&b, &dest);
    alloc_real_array_data(&dest);
    div_scalar_real_array(a, &b, &dest);
    return dest;
}

/**
 * @brief Element-wise division of two arrays: dest := a / b.
 */
void div_real_array(const real_array *a, const real_array *b, real_array *dest)
{
    size_t nr_of_elements;
    size_t i;
    /* Assert that a,b have same sizes? */
    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i) / real_get(*b, i));
    }
}

/**
 * @brief Allocate and return element-wise division of two arrays.
 */
real_array div_alloc_real_array(const real_array a, const real_array b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    div_real_array(&a, &b, &dest);
    return dest;
}

/**
 * @brief Raise each element of array `a` to the power `b` and store in `dest`.
 */
void pow_real_array_scalar(const real_array *a, modelica_real b, real_array *dest)
{
    size_t nr_of_elements = base_array_nr_of_elements(*a);
    size_t i;

    omc_assert_macro(nr_of_elements == base_array_nr_of_elements(*dest));

    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, pow(real_get(*a, i), b));
    }
}

/**
 * @brief Allocate and return array where each element is `a[i]^b`.
 */
real_array pow_alloc_real_array_scalar(const real_array a, const modelica_real b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    pow_real_array_scalar(&a, b, &dest);
    return dest;
}

/**
 * @brief Compute integer power of a square matrix: dest := a^n.
 *
 * Supports n >= 0. The operation requires `a` (and `dest`) to be square 2D arrays.
 */
void exp_real_array(const real_array *a, modelica_integer n, real_array *dest)
{
    /* Assert n>=0 */
    omc_assert_macro(n >= 0);
    /* Assert that a is a two dimensional square array */
    omc_assert_macro((a->ndims == 2) && (a->dim_size[0] == a->dim_size[1]));
    /* Assert that dest is a two dimensional square array with the same size as a */
    omc_assert_macro((dest->ndims == 2) && (dest->dim_size[0] == dest->dim_size[1]) && (a->dim_size[0] == dest->dim_size[0]));

    if (n == 0)
    {
        identity_real_array(a->dim_size[0], dest);
    }
    else
    {
        if (n == 1)
        {
            clone_real_array_spec(a, dest);
            real_array_copy_data(*a, *dest);
        }
        else if (n == 2)
        {
            clone_real_array_spec(a, dest);
            mul_real_matrix_product(a, a, dest);
        }
        else
        {
            modelica_integer i;

            real_array tmp;
            real_array *b;
            real_array *c;

            /* prepare temporary array */
            clone_real_array_spec(a, &tmp);
            clone_real_array_spec(a, dest);

            if ((n & 1) != 0)
            {
                b = &tmp;
                c = dest;
            }
            else
            {
                b = dest;
                c = &tmp;
            }
            mul_real_matrix_product(a, a, b);
            for (i = 2; i < n; ++i)
            {
                real_array *x;

                mul_real_matrix_product(a, b, c);

                /* exchange b and c */
                x = b;
                b = c;
                c = x;
            }
            /* result is already in dest */
        }
    }
}

/**
 * @brief Allocate and return matrix power result a^b.
 */
real_array exp_alloc_real_array(const real_array a, modelica_integer b)
{
    real_array dest;
    clone_real_array_spec(&a, &dest);
    alloc_real_array_data(&dest);
    exp_real_array(&a, b, &dest);
    return dest;
}

/**
 * @brief Allocate and promote array by adding `n` singleton dimensions.
 *
 * Equivalent to `promote_real_array` but also allocates the destination
 * array data buffer.
 */
void promote_alloc_real_array(const real_array *a, int n, real_array *dest)
{
    clone_real_array_spec(a, dest);
    alloc_real_array_data(dest);
    promote_real_array(a, n, dest);
}

/**
 * @brief Promote an array by adding `n` trailing singleton dimensions.
 *
 * For example, promoting a vector `{1,2}` by 1 yields `{{1},{2}}`.
 * For example, promoting a vector `{1,2}` by 2 yields `{{{1},{2}}}`.
 */
void promote_real_array(const real_array *a, int n, real_array *dest)
{
    int i;

    dest->dim_size = size_alloc(n + a->ndims);
    dest->data = a->data;
    /* Assert a->ndims>=n */
    for (i = 0; i < a->ndims; ++i)
    {
        dest->dim_size[i] = a->dim_size[i];
    }
    for (i = a->ndims; i < (n + a->ndims); ++i)
    {
        dest->dim_size[i] = 1;
    }

    dest->ndims = n + a->ndims;
}

/**
 * @brief Promote a scalar value `s` to an `n`-dimensional array of ones.
 *
 * The resulting array has shape [1,1,...] (n times) with the single element `s`.
 */
void promote_scalar_real_array(modelica_real s, int n, real_array *dest)
{
    int i;

    /* Assert that dest is of correct dimension */

    /* Alloc size */
    dest->dim_size = size_alloc(n);

    /* Alloc data */
    dest->data = real_alloc(1);

    dest->ndims = n;
    real_set(dest, 0, s);

    for (i = 0; i < n; ++i)
    {
        dest->dim_size[i] = 1;
    }
}

/**
 * @brief Write the dimension sizes of a real array into an integer array.
 *
 * Copies the length of each dimension from `a` into `dest->data` as
 * integers. `dest` must be a 1-D integer array with length equal to
 * `ndims(a)`.
 *
 * @param a Source real array whose sizes are read.
 * @param dest Destination integer array to receive the sizes (must be 1-D).
 * @pre `dest->ndims == 1` and `dest->dim_size[0] == a->ndims`.
 */
void size_real_array(const real_array *a, integer_array *dest)
{
    /* This should be an integer array dest instead */
    int i;

    omc_assert_macro(dest->ndims == 1);
    omc_assert_macro(dest->dim_size[0] == a->ndims);

    for (i = 0; i < a->ndims; i++)
    {
        ((modelica_integer *)dest->data)[i] = a->dim_size[i];
    }
}

/**
 * @brief Return the single scalar value of a one-element real array.
 *
 * This function asserts that `a` contains exactly one element and
 * returns that element as a scalar `modelica_real`.
 *
 * @param a Source real array (must contain one element).
 * @return The scalar element value from `a`.
 */
modelica_real scalar_real_array(const real_array *a)
{
    omc_assert_macro(base_array_ok(a));
    omc_assert_macro(base_array_one_element_ok(a));

    return real_get(*a, 0);
}

/**
 * @brief Flatten or copy `a` into a 1-D real vector `dest`.
 *
 * Copies the elements of `a` into `dest` in row-major order. Useful when
 * converting a higher-dimensional array into a vector view.
 *
 * @param a Source real array to be flattened.
 * @param dest Destination 1-D real array (vector) to receive elements.
 */
void vector_real_array(const real_array *a, real_array *dest)
{
    size_t i, nr_of_elements;

    /* Assert that a has at most one dimension with dim_size>1*/

    nr_of_elements = base_array_nr_of_elements(*a);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, real_get(*a, i));
    }
}

/**
 * @brief Place a scalar into a 1-D real vector at index 0.
 *
 * Writes the scalar `a` into `dest[0]`. `dest` is expected to be a
 * 1-element vector.
 *
 * @param a Scalar value to write.
 * @param dest Destination real array (1-vector).
 */
void vector_real_scalar(modelica_real a, real_array *dest)
{
    /* Assert that dest is a 1-vector */
    real_set(dest, 0, a);
}

/**
 * @brief Convert `a` to a 2-D matrix stored in `dest`.
 *
 * Sets `dest` to be a 2-D array with the first two dimensions taken from
 * `a`. Higher dimensions of `a` are asserted to be 1. Elements are copied
 * in row-major order.
 *
 * @param a Source real array.
 * @param dest Destination real array (2-D matrix) to receive elements.
 */
void matrix_real_array(const real_array *a, real_array *dest)
{
    size_t i, cnt;
    /* Assert that size(A,i)=1 for 2 <i<=ndims(A)*/
    dest->dim_size[0] = a->dim_size[0];
    dest->dim_size[1] = (a->ndims < 2) ? 1 : a->dim_size[1];

    cnt = dest->dim_size[0] * dest->dim_size[1];

    for (i = 0; i < cnt; ++i)
    {
        real_set(dest, i, real_get(*a, i));
    }
}

/**
 * @brief Place scalar `a` into a 1x1 matrix `dest`.
 *
 * Sets `dest` to a 2-D array of size 1x1 and stores `a` as its single
 * element.
 *
 * @param a Scalar value to write.
 * @param dest Destination real array (1x1 matrix).
 */
void matrix_real_scalar(modelica_real a, real_array *dest)
{
    dest->ndims = 2;
    dest->dim_size[0] = 1;
    dest->dim_size[1] = 1;
    real_set(dest, 0, a);
}

/**
 * @brief Allocate and produce the transpose of matrix `a` into `dest`.
 *
 * Allocates `dest` with the transposed shape and copies the transposed
 * elements. Only valid for 2-D arrays (matrices).
 *
 * @param a Source matrix to transpose (must be 2-D).
 * @param dest Destination real array; will be allocated to the transposed shape.
 * @pre `a->ndims == 2`.
 */
void transpose_alloc_real_array(const real_array *a, real_array *dest)
{
    clone_real_array_spec(a, dest); /* allocation*/

    /* transpose only valid for matrices.*/

    omc_assert_macro(a->ndims == 2);
    dest->dim_size[0] = a->dim_size[1];
    dest->dim_size[1] = a->dim_size[0];
    dest->ndims = 2;

    alloc_real_array_data(dest);
    transpose_real_array(a, dest);
}

/**
 * @brief Compute the transpose of matrix `a` into pre-allocated `dest`.
 *
 * If `a` is a 1-D vector it is copied into `dest`. For 2-D inputs both
 * `a` and `dest` must be 2-D and have matched transposed dimensions.
 *
 * @param a Source array to transpose.
 * @param dest Destination array (pre-allocated) to receive the transpose.
 */
void transpose_real_array(const real_array *a, real_array *dest)
{
    size_t i;
    size_t j;
    /*  size_t k;*/
    size_t n, m;

    if (a->ndims == 1)
    {
        real_array_copy_data(*a, *dest);
        return;
    }

    omc_assert_macro(a->ndims == 2 && dest->ndims == 2);

    n = a->dim_size[0];
    m = a->dim_size[1];

    omc_assert_macro(dest->dim_size[0] == m && dest->dim_size[1] == n);

    for (i = 0; i < n; ++i)
    {
        for (j = 0; j < m; ++j)
        {
            real_set(dest, (j * n) + i, real_get(*a, (i * m) + j));
        }
    }
}

/**
 * @brief Compute the outer product of two vectors `v1` and `v2` into `dest`.
 *
 * The result is a matrix with shape `(len(v1), len(v2))` where
 * `dest[i,j] = v1[i] * v2[j]`.
 *
 * @param v1 Left vector operand.
 * @param v2 Right vector operand.
 * @param dest Destination matrix to receive the outer product.
 */
void outer_product_real_array(const real_array *v1, const real_array *v2,
                              real_array *dest)
{
    size_t i;
    size_t j;
    size_t number_of_elements_a;
    size_t number_of_elements_b;

    number_of_elements_a = base_array_nr_of_elements(*v1);
    number_of_elements_b = base_array_nr_of_elements(*v2);

    /* Assert a is a vector */
    /* Assert b is a vector */

    for (i = 0; i < number_of_elements_a; ++i)
    {
        for (j = 0; j < number_of_elements_b; ++j)
        {
            real_set(dest, (i * number_of_elements_b) + j,
                     real_get(*v1, i) * real_get(*v2, j));
        }
    }
}

void outer_product_alloc_real_array(real_array *v1, real_array *v2, real_array *dest)
{
    size_t dim1, dim2;
    omc_assert_macro(base_array_ok(v1));
    dim1 = base_array_nr_of_elements(*v1);
    dim2 = base_array_nr_of_elements(*v2);
    alloc_real_array(dest, dim1, dim2);
    outer_product_real_array(v1, v2, dest);
}

/**
 * @brief Allocate and compute the outer product of two vectors.
 *
 * Allocates `dest` with shape `(len(v1), len(v2))` and fills it with
 * the outer product of `v1` and `v2`.
 *
 * @param v1 Left vector operand.
 * @param v2 Right vector operand.
 * @param dest Destination matrix (will be allocated).
 */

void identity_real_array(int n, real_array *dest)
{
    int i;
    int j;

    omc_assert_macro(base_array_ok(dest));

    /* Check that dest size is ok */
    omc_assert_macro(dest->ndims == 2);
    omc_assert_macro((dest->dim_size[0] == n) && (dest->dim_size[1] == n));

    for (i = 0; i < (n * n); ++i)
    {
        real_set(dest, i, 0);
    }
    j = 0;
    for (i = 0; i < n; ++i)
    {
        real_set(dest, j, 1);
        j += n + 1;
    }
}

/**
 * @brief Fill `dest` with the identity matrix of size `n`.
 *
 * Sets `dest` to an `n x n` matrix with ones on the diagonal and zeros
 * elsewhere. `dest` must be pre-allocated with the correct shape.
 *
 * @param n Size of the identity matrix.
 * @param dest Destination real array (n x n).
 */

static void diagonal_real_array_impl(const real_array *v, real_array *dest)
{
    size_t i;
    size_t j;
    size_t n;

    n = v->dim_size[0];

    for (i = 0; i < (n * n); ++i)
    {
        real_set(dest, i, 0);
    }
    j = 0;
    for (i = 0; i < n; ++i)
    {
        real_set(dest, j, real_get(*v, i));
        j += n + 1;
    }
}

void diagonal_real_array(const real_array *v, real_array *dest)
{
    size_t i;
    size_t j;
    size_t n;

    /* Assert that v is a vector */
    omc_assert_macro(v->ndims == 1);

    /* Assert that dest is a nxn matrix */
    n = v->dim_size[0];
    omc_assert_macro(dest->ndims == 2);
    omc_assert_macro((dest->dim_size[0] == n) && (dest->dim_size[1] == n));

    diagonal_real_array_impl(v, dest);
}

/**
 * @brief Create a diagonal matrix from vector `v` into `dest`.
 *
 * `dest` must be an `n x n` matrix where `n = len(v)`. The diagonal
 * entries are taken from `v` and off-diagonal entries set to zero.
 *
 * @param v Source vector.
 * @param dest Destination square matrix (pre-allocated).
 */

void diagonal_alloc_real_array(const real_array *v, real_array *dest)
{
    size_t n;

    /* Assert that v is a vector */
    omc_assert_macro(v->ndims == 1);

    /* Allocate a n*n matrix and fill it. */
    n = v->dim_size[0];
    alloc_real_array(dest, 2, n, n);
    diagonal_real_array_impl(v, dest);
}

/**
 * @brief Allocate and fill a diagonal matrix from vector `v`.
 *
 * Allocates `dest` as `n x n` and fills it with the diagonal entries from
 * `v`.
 *
 * @param v Source vector.
 * @param dest Destination real array (will be allocated to n x n).
 */

void fill_real_array(real_array *dest, modelica_real s)
{
    size_t nr_of_elements;
    size_t i;

    nr_of_elements = base_array_nr_of_elements(*dest);
    for (i = 0; i < nr_of_elements; ++i)
    {
        real_set(dest, i, s);
    }
}

/**
 * @brief Fill every element of `dest` with scalar `s`.
 *
 * @param dest Destination real array to be filled.
 * @param s Scalar value to set for every element.
 */

void linspace_real_array(modelica_real x1, modelica_real x2, int n,
                         real_array *dest)
{
    int i;

    /* Assert n>=2 */

    for (i = 0; i < (n - 1); ++i)
    {
        real_set(dest, i, x1 + (((x2 - x1) * (i - 1)) / (n - 1)));
    }
}

/**
 * @brief Fill `dest` with `n` linearly spaced values from `x1` to `x2`.
 *
 * Writes `n` values into `dest`, forming a linearly spaced vector.
 *
 * @param x1 Start value.
 * @param x2 End value.
 * @param n Number of points (must be >= 2).
 * @param dest Destination real array (length `n`).
 */

/**
 * @brief Return the maximum element of `a`.
 *
 * Scans all elements of `a` and returns the largest value. If `a` is
 * empty, returns DBL_MIN.
 *
 * @param a Source real array.
 * @return Maximum element or DBL_MIN if empty.
 */
modelica_real max_real_array(const real_array a)
{
    size_t nr_of_elements;
    modelica_real max_element = DBL_MIN;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    if (nr_of_elements > 0)
    {
        size_t i;
        max_element = real_get(a, 0);
        for (i = 1; i < nr_of_elements; ++i)
        {
            if (max_element < real_get(a, i))
            {
                max_element = real_get(a, i);
            }
        }
    }

    return max_element;
}

/**
 * @brief Return the minimum element of `a`.
 *
 * Scans all elements of `a` and returns the smallest value. If `a` is
 * empty, returns DBL_MAX.
 *
 * @param a Source real array.
 * @return Minimum element or DBL_MAX if empty.
 */
modelica_real min_real_array(const real_array a)
{
    size_t nr_of_elements;
    modelica_real min_element = DBL_MAX;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    if (nr_of_elements > 0)
    {
        size_t i;
        min_element = real_get(a, 0);
        for (i = 1; i < nr_of_elements; ++i)
        {
            if (min_element > real_get(a, i))
            {
                min_element = real_get(a, i);
            }
        }
    }

    return min_element;
}

/**
 * @brief Compute the sum of all elements in `a`.
 *
 * @param a Source real array.
 * @return Sum of all elements (0 for empty array).
 */
modelica_real sum_real_array(const real_array a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real sum = 0;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    for (i = 0; i < nr_of_elements; ++i)
    {
        sum += real_get(a, i);
    }

    return sum;
}

/**
 * @brief Compute the product of all elements in `a`.
 *
 * @param a Source real array.
 * @return Product of all elements (1 for empty array).
 */
modelica_real product_real_array(const real_array a)
{
    size_t i;
    size_t nr_of_elements;
    modelica_real product = 1;

    omc_assert_macro(base_array_ok(&a));

    nr_of_elements = base_array_nr_of_elements(a);

    for (i = 0; i < nr_of_elements; ++i)
    {
        product *= real_get(a, i);
    }

    return product;
}

void symmetric_real_array(const real_array *a, real_array *dest)
{
    size_t i;
    size_t j;
    size_t nr_of_elements;

    nr_of_elements = base_array_nr_of_elements(*a);

    /* Assert that a is a two dimensional square array */
    /* Assert that dest is a two dimensional square array */
    for (i = 0; i < nr_of_elements; ++i)
    {
        for (j = 0; j < i; ++j)
        {
            real_set(dest, (i * nr_of_elements) + j,
                     real_get(*a, (j * nr_of_elements) + i));
        }
        for (; j < nr_of_elements; ++j)
        {
            real_set(dest, (i * nr_of_elements) + j,
                     real_get(*a, (i * nr_of_elements) + j));
        }
    }
}

/**
 * @brief Produce a symmetric version of square matrix `a` into `dest`.
 *
 * Copies elements so that `dest[i,j] = a[i,j]` for `j>=i` and
 * `dest[i,j] = a[j,i]` for `j<i`.
 *
 * @param a Source square matrix.
 * @param dest Destination square matrix (pre-allocated).
 */

void cross_real_array(const real_array *x, const real_array *y, real_array *dest)
{
    /* Assert x and y are vectors */
    omc_assert_macro((x->ndims == 1) && (x->dim_size[0] == 3));
    /* Assert y is vector of size 3 */
    omc_assert_macro((y->ndims == 1) && (y->dim_size[0] == 3));
    /* Assert dest is vector of size 3 */
    omc_assert_macro((dest->ndims == 1) && (dest->dim_size[0] == 3));

    real_set(dest, 0, (real_get(*x, 1) * real_get(*y, 2)) - (real_get(*x, 2) * real_get(*y, 1)));
    real_set(dest, 1, (real_get(*x, 2) * real_get(*y, 0)) - (real_get(*x, 0) * real_get(*y, 2)));
    real_set(dest, 2, (real_get(*x, 0) * real_get(*y, 1)) - (real_get(*x, 1) * real_get(*y, 0)));
}

/**
 * @brief Compute the 3D cross product of vectors `x` and `y`.
 *
 * Both `x` and `y` must be length-3 vectors. The result is written into
 * `dest` (also a length-3 vector).
 *
 * @param x Left vector (length 3).
 * @param y Right vector (length 3).
 * @param dest Destination vector (length 3).
 */

void cross_alloc_real_array(const real_array *x, const real_array *y, real_array *dest)
{
    alloc_real_array(dest, 1, 3);
    cross_real_array(x, y, dest);
}

/**
 * @brief Allocate and compute the cross product of two 3-vectors.
 *
 * Allocates `dest` as a length-3 vector and computes `dest = cross(x, y)`.
 *
 * @param x Left vector (length 3).
 * @param y Right vector (length 3).
 * @param dest Destination vector (will be allocated).
 */

void skew_real_array(const real_array *x, real_array *dest)
{
    /* Assert x vector*/
    /* Assert x has size 3*/
    /* Assert dest is 3x3*/
    real_set(dest, 0, 0);
    real_set(dest, 1, -real_get(*x, 2));
    real_set(dest, 2, real_get(*x, 1));
    real_set(dest, 3, real_get(*x, 2));
    real_set(dest, 4, 0);
    real_set(dest, 5, -real_get(*x, 0));
    real_set(dest, 6, -real_get(*x, 1));
    real_set(dest, 7, real_get(*x, 0));
    real_set(dest, 8, 0);
}

/**
 * @brief Build the skew-symmetric matrix of a length-3 vector `x`.
 *
 * Fills `dest` (3x3) with the skew symmetric matrix such that
 * `skew(x)*y = cross(x,y)`.
 *
 * @param x Source length-3 vector.
 * @param dest Destination 3x3 matrix (pre-allocated).
 */

void convert_alloc_real_array_to_f77(const real_array *a, real_array *dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_real_array_data(dest);
    transpose_real_array(a, dest);
    for (i = 0; i < dest->ndims; ++i)
    {
        dest->dim_size[i] = a->dim_size[i];
    }
}

/**
 * @brief Convert `a` to Fortran (column-major) layout into an allocated `dest`.
 *
 * Allocates `dest` with reversed base-array spec, transposes the data and
 * adjusts dimension sizes so that the result is suitable for Fortran-style
 * libraries expecting column-major order.
 *
 * @param a Source array in C row-major layout.
 * @param dest Destination array that will be allocated in F77 layout.
 */

void convert_alloc_real_array_from_f77(const real_array *a, real_array *dest)
{
    int i;
    clone_reverse_base_array_spec(a, dest);
    alloc_real_array_data(dest);
    for (i = 0; i < dest->ndims; ++i)
    {
        int tmp = dest->dim_size[i];
        dest->dim_size[i] = a->dim_size[i];
        a->dim_size[i] = tmp;
    }
    transpose_real_array(a, dest);
}

/**
 * @brief Convert from Fortran (column-major) layout into an allocated C array.
 *
 * Allocates `dest` and transposes the Fortran-ordered data into C row-major
 * layout.
 *
 * @param a Source array in F77 layout.
 * @param dest Destination array that will be allocated in C layout.
 */

void cast_integer_array_to_real(const integer_array *a, real_array *dest)
{
    int els = base_array_nr_of_elements(*a);
    int i;
    clone_base_array_spec(a, dest);
    alloc_real_array_data(dest);
    for (i = 0; i < els; i++)
    {
        real_set(dest, i, (modelica_real)integer_get(*a, i));
    }
}

/**
 * @brief Cast an integer array to a real array element-wise.
 *
 * Allocates `dest` data and converts each integer element to `modelica_real`.
 *
 * @param a Source integer array.
 * @param dest Destination real array (shape cloned from `a`).
 */

void cast_real_array_to_integer(const real_array *a, integer_array *dest)
{
    int els = base_array_nr_of_elements(*a);
    int i;
    clone_base_array_spec(a, dest);
    alloc_integer_array_data(dest);
    for (i = 0; i < els; i++)
    {
        put_integer_element((modelica_integer)real_get(*a, i), i, dest);
    }
}

/**
 * @brief Cast a real array to an integer array element-wise.
 *
 * Allocates `dest` data and converts each real element to `modelica_integer`.
 *
 * @param a Source real array.
 * @param dest Destination integer array (shape cloned from `a`).
 */

/* Fills an array with a value. */
void fill_alloc_real_array(real_array *dest, modelica_real value, int ndims, ...)
{
    size_t i;
    size_t elements = 0;
    va_list ap;
    va_start(ap, ndims);
    elements = alloc_base_array(dest, ndims, ap);
    va_end(ap);
    dest->data = real_alloc(elements);

    for (i = 0; i < elements; ++i)
    {
        real_set(dest, i, value);
    }
}

/**
 * @brief Allocate an array with given dimensions and fill it with `value`.
 *
 * The function takes a variable argument list of dimension sizes after
 * `ndims`, allocates `dest` and fills every element with `value`.
 *
 * @param dest Destination real array (will be allocated).
 * @param value Value to fill the array with.
 * @param ndims Number of dimensions to allocate, followed by their sizes.
 */

void identity_alloc_real_array(int n, real_array *dest)
{
    alloc_real_array(dest, 2, n, n);
    identity_real_array(n, dest);
}

/**
 * @brief Create a 1-D real array from a range `start:step:stop`.
 *
 * Example: `1.0:2.0:6.0` => `{1.0, 3.0, 5.0}`. The function computes the
 * number of elements and allocates a 1-D array containing the arithmetic
 * progression.
 *
 * @param dest Destination 1-D real array (will be allocated).
 * @param start Range start value.
 * @param step Range step value (must be non-zero).
 * @param stop Range end value.
 * @pre `step != 0`.
 */
void create_real_array_from_range(real_array *dest, modelica_real start, modelica_real step, modelica_real stop)
{
    size_t elements;
    size_t i;
    modelica_real (*comp_func)(modelica_real, modelica_real);

    omc_assert_macro(step != 0);

    comp_func = (step > 0) ? &real_le : &real_ge;
    elements = comp_func(start, stop) ? (((stop - start) / step) + 1) : 0;
    /* fprintf(stderr, "start %g step %g stop %g elements %d\n", start, step, stop, elements); */

    simple_alloc_1d_real_array(dest, elements);

    for (i = 0; i < elements; start += step, ++i)
    {
        real_set(dest, i, start);
    }
}
