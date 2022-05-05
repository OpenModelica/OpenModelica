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

/*! \file omc_math.c
 */

#include <string.h> /* memcpy */
#include <math.h>

#include "../../util/omc_error.h"
#include "omc_math.h"
#include "../simulation_info_json.h"

/*! \fn _omc_vector* _omc_allocateVectorData(_omc_size size)
 *
 *  allocate _omc_vector and memory of size rows for data
 *
 *  \param [in]  [size] Number of elements
 */
_omc_vector* _omc_allocateVectorData(const _omc_size size) {
  _omc_vector* vec = NULL;
  _omc_scalar* data = NULL;

  assertStreamPrint(NULL, size > 0, "size needs to be greater zero");

  vec = (_omc_vector*) malloc(sizeof(_omc_vector));
  assertStreamPrint(NULL, NULL != vec, "out of memory");

  data = (_omc_scalar*) malloc(size * sizeof(_omc_scalar));
  assertStreamPrint(NULL, NULL != data, "out of memory");

  vec->size = size;
  vec->data = data;

  return vec;
}

/*! \fn void _omc_deallocateVectorData(_omc_vector* vec)
 *
 *  free memory in data
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 */
void _omc_deallocateVectorData(_omc_vector* vec) {
  free(vec->data);
  free(vec);
}

/*! \fn _omc_vector* _omc_createVector(_omc_size size, _omc_scalar* data)
 *
 *  creates a _omc_vector with a data of _omc_vector
 *
 *  \param [in]  [size] size of the vector
 *  \param [ref] [data] !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_createVector(const _omc_size size, _omc_scalar* data) {
  _omc_vector* vec = NULL;
  assertStreamPrint(NULL, size > 0, "size needs to be greater zero");

  vec = (_omc_vector*) malloc(sizeof(_omc_vector));
  assertStreamPrint(NULL, NULL != vec, "out of memory");

  vec->size = size;
  vec->data = data;

  return vec;
}

/*! \fn void _omc_destroyVector(_omc_vector* vec)
 *
 *  free _omc_vector
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 */
void _omc_destroyVector(_omc_vector* vec) {
  free(vec);
}

/*! \fn void _omc_copyVector(_omc_vector* dest, const _omc_vector* src)
 *
 *  creates a new _omc_vector by coping all data
 *
 *  \param [out] [dest] the destination vector, which need already be allocated
 *  \param [in]  [src]  the original vector
 */
void _omc_copyVector(_omc_vector* dest, const _omc_vector* src)
{
  assertStreamPrint(NULL, dest->size == src->size, "sizes of the vector need to be equal");
  memcpy(dest->data, src->data, sizeof(_omc_scalar) * dest->size);
}

/*! \fn _omc_matrix* _omc_allocateMatrixData(_omc_size rows, _omc_size cols)
 *
 *  allocate _omc_matrix and memory of size rows*cols for data
 *
 *  \param [in]  [rows] Number of rows
 *  \param [in]  [cols] Number of cols
 */
_omc_matrix* _omc_allocateMatrixData(const _omc_size rows, const _omc_size cols)
{
  _omc_matrix* mat = NULL;
  _omc_scalar* data = NULL;
  assertStreamPrint(NULL, rows > 0, "size of rows need greater zero");
  assertStreamPrint(NULL, cols > 0, "size of cols need greater zero");

  mat = (_omc_matrix*) malloc(sizeof(_omc_matrix));
  assertStreamPrint(NULL, NULL != mat, "out of memory");

  data = (_omc_scalar*) malloc(rows * cols * sizeof(_omc_scalar));
  assertStreamPrint(NULL, NULL != mat, "data out of memory");

  mat->rows = rows;
  mat->cols = cols;
  mat->data = data;

  return mat;
}

/*! \fn void _omc_deallocateMatrixData(_omc_matrix* mat)
 *
 *  free memory in data
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
void _omc_deallocateMatrixData(_omc_matrix* mat)
{
  free(mat->data);
  free(mat);
}

/*! \fn _omc_matrix* _omc_createMatrix(_omc_size rows, _omc_size cols, _omc_scalar* data)
 *
 *  creates a _omc_matrix with a data of _omc_matrix
 *
 *  \param [in]  [rows] Number of rows
 *  \param [in]  [cols] Number of cols
 *  \param [ref] [data] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_createMatrix(const _omc_size rows, const _omc_size cols, _omc_scalar* data)
{
  _omc_matrix* mat = NULL;
  assertStreamPrint(NULL, rows > 0, "size of rows need greater zero");
  assertStreamPrint(NULL, cols > 0, "size of cols need greater zero");

  mat = (_omc_matrix*) malloc(sizeof(_omc_matrix));
  assertStreamPrint(NULL, NULL != mat, "out of memory");

  mat->rows = rows;
  mat->cols = cols;
  mat->data = data;

  return mat;
}

/*! \fn void _omc_destroyMatrix(_omc_matrix* mat)
 *
 *  free _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
void _omc_destroyMatrix(_omc_matrix* mat)
{
  free(mat);
}

/*! \fn _omc_matrix* _omc_copyMatrix(_omc_matrix* mat1)
 *
 *  creates a new _omc_matrix by coping all data
 *
 *  \param [in]  [mat1] the original matrix
 */
_omc_matrix* _omc_copyMatrix(_omc_matrix* mat1)
{
  _omc_matrix* mat = _omc_allocateMatrixData(mat1->rows, mat1->cols);
  memcpy(mat->data, mat1->data, sizeof(_omc_scalar) * _omc_getMatrixSize(mat1));
  return mat;
}

/*! \fn _omc_scalar* _omc_getVectorData(_omc_vector* vec)
 *
 *  get data of _omc_vector
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 */
_omc_scalar* _omc_getVectorData(_omc_vector* vec)
{
  return vec->data;
}

/*! \fn _omc_size _omc_getVectorSize(_omc_vector* vec)
 *
 *  get size of _omc_vector
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 */
_omc_size _omc_getVectorSize(_omc_vector* vec)
{
  return vec->size;
}

/*! \fn _omc_scalar _omc_getVectorElement(_omc_vector* vec, _omc_size i)
 *
 *  get i-th element of _omc_vector
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 *  \param [in]  [i]   element
 */
_omc_scalar _omc_getVectorElement(_omc_vector* vec, const _omc_size i)
{
  assertStreamPrint(NULL, 0 <= i, "index out of bounds: %d", (int)i);
  assertStreamPrint(NULL, i < vec->size, "_omc_vector size %d smaller than %d", (int)vec->size, (int)i);
  return vec->data[i];
}

/*! \fn void _omc_setVectorElement(_omc_vector* vec, _omc_size i, _omc_scalar s)
 *
 *  set i-th element of _omc_vector
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 *  \param [in]  [i]   element
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
void _omc_setVectorElement(_omc_vector* vec, const _omc_size i, const _omc_scalar s)
{
  assertStreamPrint(NULL, 0 <= i, "index out of bounds: %d", (int)i);
  assertStreamPrint(NULL, i < vec->size, "_omc_vector size %d smaller than %d", (int)vec->size, (int)i);
  vec->data[i] = s;
}

/*! \fn _omc_scalar* _omc_setVectorData(_omc_vector* vec, _omc_scalar* data)
 *
 *  replaces data of _omc_vector and return the old one
 *
 *  \param [ref] [vec]   !TODO: DESCRIBE ME!
 *  \param [ref] [data*] !TODO: DESCRIBE ME!
 */
_omc_scalar* _omc_setVectorData(_omc_vector* vec, _omc_scalar* data)
{
  _omc_scalar* output = vec->data;
  vec->data = data;
  return output;
}

/*! \fn _omc_scalar* _omc_getMatrixData(_omc_matrix* mat)
 *
 *  get data of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_scalar* _omc_getMatrixData(_omc_matrix* mat)
{
  return mat->data;
}

/*! \fn _omc_size _omc_getMatrixRows(_omc_matrix* mat)
 *
 *  get rows size of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_size _omc_getMatrixRows(_omc_matrix* mat)
{
  return mat->rows;
}

/*! \fn _omc_size _omc_getMatrixCols(_omc_matrix* mat)
 *
 *  get cols size of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_size _omc_getMatrixCols(_omc_matrix* mat)
{
  return mat->cols;
}

/*! \fn _omc_size _omc_getMatrixSize(_omc_matrix* mat)
 *
 *  get size of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_size _omc_getMatrixSize(_omc_matrix* mat)
{
  return mat->rows * mat->cols;
}

/*! \fn _omc_scalar _omc_getMatrixElement(_omc_matrix* mat, _omc_size i, _omc_size j)
 *
 *  get (i,j)-th element of _omc_matrix
 *
 *  \param [ref] [_omc_matrix] !TODO: DESCRIBE ME!
 *  \param [in]  [_omc_size]   rows
 *  \param [in]  [_omc_size]   cols
 */
_omc_scalar _omc_getMatrixElement(_omc_matrix* mat, const _omc_size i, const _omc_size j)
{
  assertStreamPrint(NULL, 0 <= i, "index i out of bounds: %d", (int)i);
  assertStreamPrint(NULL, 0 <= j, "index j out of bounds: %d", (int)j);
  assertStreamPrint(NULL, i < mat->rows, "_omc_matrix rows(%d) too small for %d", (int)mat->rows, (int)i);
  assertStreamPrint(NULL, j < mat->cols, "_omc_matrix cols(%d) too small for %d", (int)mat->cols, (int)j);
  return mat->data[i + j * mat->cols];
}

/*! \fn void _omc_setMatrixElement(_omc_matrix* mat, _omc_size i, _omc_size j, _omc_scalar s)
 *
 *  set i-th element of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 *  \param [in]  [i]   rows
 *  \param [in]  [j]   cols
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
void _omc_setMatrixElement(_omc_matrix* mat, const _omc_size i, const _omc_size j, _omc_scalar s)
{
  assertStreamPrint(NULL, i < mat->rows, "_omc_matrix rows(%d) too small for %d", (int)mat->rows, (int)i);
  assertStreamPrint(NULL, j < mat->cols, "_omc_matrix cols(%d) too small for %d", (int)mat->cols, (int)j);
  mat->data[i + j * mat->cols] = s;
}

/*! \fn _omc_scalar* _omc_setMatrixData(_omc_matrix* mat, _omc_scalar* data)
 *
 *  get data of _omc_matrix
 *
 *  \param [ref] [mat]  !TODO: DESCRIBE ME!
 *  \param [in]  [data] !TODO: DESCRIBE ME!
 */
_omc_scalar* _omc_setMatrixData(_omc_matrix* mat, _omc_scalar* data)
{
  _omc_scalar* output = mat->data;
  mat->data = data;
  return output;
}


/*! \fn _omc_vector* _omc_fillVector(_omc_vector* vec, _omc_scalar s)
 *
 *  fill all elements of _omc_vector by s
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_fillVector(_omc_vector* vec, _omc_scalar s)
{
  _omc_size i;

  assertStreamPrint(NULL, NULL != vec->data, "_omc_vector data is NULL pointer");
  for (i = 0; i < vec->size; ++i)
  {
    vec->data[i] = s;
  }

  return vec;
}

/*! \fn _omc_vector* _omc_negateVector(_omc_vector* vec)
 *
 *  negate all elements of _omc_vector
 *
 *  \param [ref] [_omc_vector] !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_negateVector(_omc_vector* vec)
{
  _omc_size i;

  assertStreamPrint(NULL, NULL != vec->data, "_omc_vector data is NULL pointer");
  for (i = 0; i < vec->size; ++i)
  {
    vec->data[i] = -vec->data[i];
  }

  return vec;
}

/*! \fn _omc_vector* _omc_multiplyScalarVector(_omc_vector* vec, _omc_scalar s)
 *
 *  multiply all elements of _omc_vector by s
 *
 *  \param [ref] [vec] !TODO: DESCRIBE ME!
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_multiplyScalarVector(_omc_vector* vec, _omc_scalar s)
{
  _omc_size i;

  assertStreamPrint(NULL, NULL != vec->data, "_omc_vector data is NULL pointer");
  for (i = 0; i < vec->size; ++i)
  {
    vec->data[i] *= s;
  }

  return vec;
}

/*! \fn _omc_vector* _omc_addVector(_omc_vector* dest, _omc_vector* src)
 *
 *  addition of two vectors to the first one
 *
 *  \param [ref] [dest] !TODO: DESCRIBE ME!
 *  \param [ref] [src]  !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_addVector(_omc_vector* dest, const _omc_vector* src)
{
  _omc_size i;
  assertStreamPrint(NULL, dest->size == src->size,
      "Vectors have not the same size %d != %d", (int)dest->size, (int)src->size);
  assertStreamPrint(NULL, NULL != dest->data, "vector1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != src->data, "vector2 data is NULL pointer");
  for (i = 0; i < dest->size; ++i) {
    dest->data[i] += src->data[i];
  }

  return dest;
}

/*! \fn _omc_vector* _omc_subVector(_omc_vector* dest, const _omc_vector* src)
 *
 *  subtraction of two vectors to the first one
 *
 *  \param [ref] [dest] !TODO: DESCRIBE ME!
 *  \param [ref] [src]  !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_subVector(_omc_vector* dest, const _omc_vector* src)
{
  _omc_size i;
  assertStreamPrint(NULL, src->size == dest->size, "Vectors have not the same size %d != %d", (int)src->size, (int)dest->size);
  assertStreamPrint(NULL, NULL != dest->data, "vector1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != src->data, "vector2 data is NULL pointer");
  for (i = 0; i < dest->size; ++i)
  {
    dest->data[i] -= src->data[i];
  }

  return dest;
}

/*! \fn _omc_vector* _omc_addVectorVector(_omc_vector dest, const _omc_vector* vec1, const _omc_vector* vec2)
 *
 *  addition of two vectors in a third one
 *
 *  \param [ref] [dest] !TODO: DESCRIBE ME!
 *  \param [ref] [vec1] !TODO: DESCRIBE ME!
 *  \param [ref] [vec2] !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_addVectorVector(_omc_vector* dest, const _omc_vector* vec1, const _omc_vector* vec2)
{
  _omc_size i;
  assertStreamPrint(NULL, vec1->size == vec2->size && dest->size == vec1->size,
      "Vectors have not the same size %d != %d != %d", (int)dest->size, (int)vec1->size, (int)vec2->size);
  assertStreamPrint(NULL, NULL != vec1->data, "vector1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != vec2->data, "vector2 data is NULL pointer");
  assertStreamPrint(NULL, NULL != dest->data, "destination data is NULL pointer");
  for (i = 0; i < vec1->size; ++i) {
    dest->data[i] = vec1->data[i] + vec2->data[i];
  }

  return dest;
}

/*! \fn _omc_vector* _omc_subVectorVector(_omc_vector* dest, const _omc_vector* vec1, const _omc_vector* vec2)
 *
 *  subtraction of vec2 from vec1 in a third one
 *
 *  \param [ref] [dest] !TODO: DESCRIBE ME!
 *  \param [ref] [vec1] !TODO: DESCRIBE ME!
 *  \param [ref] [vec2] !TODO: DESCRIBE ME!
 */
_omc_vector* _omc_subVectorVector(_omc_vector* dest, const _omc_vector* vec1, const _omc_vector* vec2)
{
  _omc_size i;
  assertStreamPrint(NULL, vec1->size == vec2->size && dest->size == vec1->size,
      "Vectors have not the same size %d != %d", (int)vec1->size, (int)vec2->size);
  assertStreamPrint(NULL, NULL != vec1->data, "vector1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != vec2->data, "vector2 data is NULL pointer");
  assertStreamPrint(NULL, NULL != dest->data, "destination data is NULL pointer");
  for (i = 0; i < vec1->size; ++i)
  {
    dest->data[i] = vec1->data[i] - vec2->data[i];
  }

  return dest;
}

/*! \fn _omc_scalar _omc_scalarProduct(_omc_vector* vec1, _omc_vector* vec2)
 *
 *  _omc_vector multiplication of two vectors
 *
 *  \param [ref] [vec1] !TODO: DESCRIBE ME!
 *  \param [ref] [vec2] !TODO: DESCRIBE ME!
 */
_omc_scalar _omc_scalarProduct(const _omc_vector* vec1, const _omc_vector* vec2)
{
  _omc_size i;
  _omc_size m = vec1->size, n = vec2->size;
  _omc_scalar result = 0;
  assertStreamPrint(NULL, m == n, "Vectors size doesn't match to multiply %d != %d ", (int)m, (int)n);
  assertStreamPrint(NULL, NULL != vec1->data, "vector1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != vec2->data, "vector2 data is NULL pointer");
  for (i = 0; i < n; ++i)
  {
    result += vec1->data[i] * vec2->data[i];
  }

  return result;
}

/*! \fn _omc_scalar _omc_sumVector(_omc_vector* vec)
 *
 *  calculates the sum of all elements of the vector
 *
 *  \param [ref] [_omc_vector] !TODO: DESCRIBE ME!
 */
_omc_scalar _omc_sumVector(const _omc_vector* vec) {
  _omc_size i;
  _omc_scalar sum = 0;
  assertStreamPrint(NULL, NULL != vec->data, "vector data is NULL pointer");
  for (i = 0; i < vec->size; ++i)
  {
    sum += vec->data[i];
  }

  return sum;
}

/*! \fn _omc_matrix* _omc_fillMatrix(_omc_matrix* mat, _omc_scalar s)
 *
 *  fill all elements of _omc_matrix by s
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_fillMatrix(_omc_matrix* mat, _omc_scalar s) {
  _omc_size i;
  _omc_size size = mat->rows * mat->cols;
  assertStreamPrint(NULL, NULL != mat->data, "_omc_matrix data is NULL pointer");
  for (i = 0; i < size; ++i) {
    mat->data[i] = s;
  }

  return mat;
}

/*! \fn _omc_matrix* _omc_fillIndentityMatrix(_omc_matrix* mat)
 *
 *  fill identity _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_fillIndentityMatrix(_omc_matrix* mat)
{
  _omc_size i, min;
  assertStreamPrint(NULL, NULL != mat->data, "_omc_matrix data is NULL pointer");
  mat = _omc_fillMatrix(mat, 0);
  min = mat->rows <= mat->cols ? mat->rows : mat->cols;
  for (i = 0; i < min; ++i)
  {
    _omc_setMatrixElement(mat, i, i, 1.0);
  }

  return mat;
}

/*! \fn _omc_matrix* _omc_negateMatrix(_omc_matrix* mat)
 *
 *  negate all elements of _omc_matrix
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_negateMatrix(_omc_matrix* mat)
{
  _omc_size i, size = mat->rows * mat->cols;
  assertStreamPrint(NULL, NULL != mat->data, "_omc_matrix data is NULL pointer");
  for (i = 0; i < size; ++i) {
    mat->data[i] = -mat->data[i];
  }

  return mat;
}

/*! \fn _omc_matrix* _omc_multiplyScalarMatrix(_omc_matrix* mat, _omc_scalar s)
 *
 *  multiply all elements of _omc_matrix by s
 *
 *  \param [ref] [mat] !TODO: DESCRIBE ME!
 *  \param [in]  [s]   !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_multiplyScalarMatrix(_omc_matrix* mat, _omc_scalar s)
{
  _omc_size i, size = mat->rows * mat->cols;
  assertStreamPrint(NULL, NULL != mat->data, "_omc_matrix data is NULL pointer");
  for (i = 0; i < size; ++i)
  {
    mat->data[i] *= s;
  }

  return mat;
}

/*! \fn _omc_matrix* _omc_addMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
 *
 *  addition of two matrixs to the first one
 *
 *  \param [ref] [mat1] !TODO: DESCRIBE ME!
 *  \param [ref] [mat2] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_addMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
{
  _omc_size i, j;
  assertStreamPrint(NULL, mat1->rows == mat2->rows && mat1->cols == mat2->cols,
      "matrixes have not the same size ((%d,%d)!=(%d,%d))",
      (int)mat1->rows, (int)mat1->cols, (int)mat2->rows, (int)mat2->cols);
  assertStreamPrint(NULL, NULL != mat1->data, "matrix1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != mat2->data, "matrix2 data is NULL pointer");
  for (i = 0; i < mat1->rows; ++i) {
    for (j = 0; j < mat1->cols; ++j) {
      _omc_setMatrixElement(mat1, i, j,
          _omc_getMatrixElement(mat1, i, j)
              + _omc_getMatrixElement(mat2, i, j));
    }
  }

  return mat1;
}

/*! \fn _omc_matrix* _omc_subtractMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
 *
 *  subtraction of two matrixs to the first one
 *
 *  \param [ref] [mat1] !TODO: DESCRIBE ME!
 *  \param [ref] [mat2] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_subtractMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
{
  _omc_size i, j;
  assertStreamPrint(NULL, mat1->rows == mat2->rows && mat1->cols == mat2->cols,
      "matrixes have not the same size ((%d,%d)!=(%d,%d))",
      (int)mat1->rows, (int)mat1->cols, (int)mat2->rows, (int)mat2->cols);
  assertStreamPrint(NULL, NULL != mat1->data, "matrix1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != mat2->data, "matrix2 data is NULL pointer");
  for (i = 0; i < mat1->rows; ++i) {
    for (j = 0; j < mat1->cols; ++j) {
      _omc_setMatrixElement(mat1, i, j,
          _omc_getMatrixElement(mat1, i, j)
              - _omc_getMatrixElement(mat2, i, j));
    }
  }

  return mat1;
}

/*! \fn _omc_matrix* _omc_multiplyMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
 *
 *  _omc_matrix multiplication of two matrixes into matrix one
 *
 *  \param [ref] [mat1] !TODO: DESCRIBE ME!
 *  \param [ref] [mat2] !TODO: DESCRIBE ME!
 */
_omc_matrix* _omc_multiplyMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2)
{
  _omc_size i, j, k;
  _omc_size l = mat1->rows, m = mat1->cols, n = mat2->cols;
  assertStreamPrint(NULL, mat1->cols == mat2->rows,
      "matrixes size doesn't match to multiply"
          "(%d!=%d)", (int)mat1->cols, (int)mat2->rows);
  assertStreamPrint(NULL, NULL != mat1->data, "matrix1 data is NULL pointer");
  assertStreamPrint(NULL, NULL != mat2->data, "matrix2 data is NULL pointer");
  for (i = 0; i < l; ++i) {
    for (j = 0; j < n; ++j) {
      for (k = 0; j < m; ++k) {
        _omc_setMatrixElement(mat1, i, j,
            _omc_getMatrixElement(mat1, i, k)
                * _omc_getMatrixElement(mat2, k, j));
      }
    }
  }

  return mat1;
}

/**
 * @brief Print vector and equation info to stream.
 *
 * @param vec       Vector.
 * @param name      Name of vector.
 * @param stream    Log stream.
 * @param eqnInfo   Information about equation
 */
void _omc_printVectorWithEquationInfo(_omc_vector* vec, const char* name, const enum LOG_STREAM stream, EQUATION_INFO eqnInfo)
{
  _omc_size i;

  if (!ACTIVE_STREAM(stream))
    return;

  assertStreamPrint(NULL, NULL != vec->data, "Vector data is NULL pointer");

  infoStreamPrint(stream, 1, "%s", name);
  for (i = 0; i < vec->size; ++i)
  {
 //   infoStreamPrint(stream, 0, "[%3d] %-40s = %20.12g",   (int)i+1, eqnInfo.vars[i], vec->data[i]);
  }
  messageClose(stream);
}

/**
 * @brief Print vector to stream.
 *
 * @param vec       Vector.
 * @param name      Name of vector.
 * @param stream    Log stream.
 */
void _omc_printVector(_omc_vector* vec, const char* name, const enum LOG_STREAM stream)
{
  _omc_size i;

  if (!ACTIVE_STREAM(stream))
    return;

  assertStreamPrint(NULL, NULL != vec->data, "Vector data is NULL pointer");

  infoStreamPrint(stream, 1, "%s", name);
  for (i = 0; i < vec->size; ++i)
  {
    infoStreamPrint(stream, 0, "[%2d] %20.12g", (int)i+1, vec->data[i]);
  }
  messageClose(stream);
}

/**
 * @brief Print matrix to stream.
 *
 * @param mat       Matrix.
 * @param name      Name of matrix.
 * @param stream    Log stream.
 */
void _omc_printMatrix(_omc_matrix* mat, const char* name, const enum LOG_STREAM stream) {
  if (ACTIVE_STREAM(stream))
  {
    _omc_size i, j;
    char *buffer = (char*)malloc(sizeof(char)*mat->cols*20);

    assertStreamPrint(NULL, NULL != mat->data, "matrix data is NULL pointer");

    infoStreamPrint(stream, 1, "%s", name);
    for (i = 0; i < mat->rows; ++i)
    {
      buffer[0] = 0;
      for (j = 0; j < mat->cols; ++j)
      {
        sprintf(buffer, "%s%10g ", buffer, _omc_getMatrixElement(mat, i, j));
      }
      infoStreamPrint(stream, 0, "%s", buffer);
    }
    messageClose(stream);
    free(buffer);
  }
}

/*! \fn _omc_scalar _omc_euclideanVectorNorm(_omc_vector* vec)
 *
 *  calculates the euclidean vector norm
 *
 *  \param [in]  [vec] !TODO: DESCRIBE ME!
 */
_omc_scalar _omc_euclideanVectorNorm(const _omc_vector* vec)
{
  _omc_size i;
  _omc_scalar result = 0;
  assertStreamPrint(NULL, vec->size > 0, "Vector size is greater than zero");
  assertStreamPrint(NULL, NULL != vec->data, "Vector data is NULL pointer");
  for (i = 0; i < vec->size; ++i) {
    result += pow(fabs(vec->data[i]),2.0);
  }

  return sqrt(result);
}

/*! \fn _omc_scalar _omc_gen_euclideanVectorNorm(_omc_vector* vec)
 *
 *  calculates the euclidean vector norm
 *
 *  \param [in]  [vec] !TODO: DESCRIBE ME!
 */
_omc_scalar _omc_gen_euclideanVectorNorm(const _omc_scalar* vec_data, const _omc_size vec_size)
{
  _omc_size i;
  _omc_scalar result = 0;
  assertStreamPrint(NULL, vec_size > 0, "Vector size is greater than zero");
  assertStreamPrint(NULL, NULL != vec_data, "Vector data is NULL pointer");
  for (i = 0; i < vec_size; ++i) {
    result += pow(fabs(vec_data[i]),2.0);
  }

  return sqrt(result);
}

/*! \fn _omc_scalar _omc_maximumVectorNorm(_omc_vector* vec)
 *
 *  calculates the maximum vector norm
 */
_omc_scalar _omc_maximumVectorNorm(const _omc_vector* vec)
{
  _omc_size i;
  _omc_scalar result, tmp;
  assertStreamPrint(NULL, vec->size > 0, "Vector size is greater the zero");
  assertStreamPrint(NULL, NULL != vec->data, "Vector data is NULL pointer");
  result = fabs(vec->data[0]);
  for (i = 1; i < vec->size; ++i)
  {
    tmp = fabs(vec->data[i]);
    if (result < tmp)
    {
      result = tmp;
    }
  }

  return result;
}
