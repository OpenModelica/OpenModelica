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

#ifndef OMCMATH_H_
#define OMCMATH_H_

#include "../simulation_info_json.h"

typedef double _omc_scalar;

#if defined(__alpha__) || defined(__sparc64__) || defined(__x86_64__) || defined(__ia64__)
typedef int _omc_integer;
typedef unsigned int _omc_size;
#else
typedef long int _omc_integer;
typedef unsigned long int _omc_size;
#endif

typedef struct
{
  _omc_size size;
  _omc_scalar *data;
} _omc_vector;

typedef struct
{
  _omc_size rows;
  _omc_size cols;
  _omc_scalar *data;
} _omc_matrix;

/* memory management vector */
_omc_vector* _omc_allocateVectorData(const _omc_size size);
void _omc_deallocateVectorData(_omc_vector* vec);
_omc_vector* _omc_createVector(const _omc_size size, _omc_scalar* data);
static inline void _omc_initVector(_omc_vector* vec, const _omc_size size, _omc_scalar* data) {
  vec->size = size;
  vec->data = data;
}
void _omc_destroyVector(_omc_vector* vec);
void _omc_copyVector(_omc_vector* dest, const _omc_vector* src);

/* memory management matrix */
_omc_matrix* _omc_allocateMatrixData(const _omc_size rows, const _omc_size cols);
void _omc_deallocateMatrixData(_omc_matrix* mat);
_omc_matrix* _omc_createMatrix(const _omc_size rows, const _omc_size cols, _omc_scalar* data);
void _omc_destroyMatrix(_omc_matrix* mat);
_omc_matrix* _omc_copyMatrix(_omc_matrix* mat);

/* get and set vector */
_omc_scalar* _omc_getVectorData(_omc_vector* vec);
_omc_size _omc_getVectorSize(_omc_vector* vec);
_omc_scalar _omc_getVectorElement(_omc_vector* vec, const _omc_size i);
void _omc_setVectorElement(_omc_vector* vec, const _omc_size i, _omc_scalar s);
_omc_scalar* _omc_setVectorData(_omc_vector* vec, _omc_scalar* data);

/* get and set matrix */
_omc_scalar* _omc_getMatrixData(_omc_matrix* mat);
_omc_size _omc_getMatrixRows(_omc_matrix* mat);
_omc_size _omc_getMatrixCols(_omc_matrix* mat);
_omc_size _omc_getMatrixSize(_omc_matrix* mat);
_omc_scalar _omc_getMatrixElement(_omc_matrix* mat, const _omc_size i, const _omc_size j);
void _omc_setMatrixElement(_omc_matrix* mat, const _omc_size i, const _omc_size j, _omc_scalar s);
_omc_scalar* _omc_setMatrixData(_omc_matrix* mat, _omc_scalar* data);

/* vector operations */
_omc_vector* _omc_fillVector(_omc_vector* vec, _omc_scalar s);
_omc_vector* _omc_negateVector(_omc_vector* vec);

_omc_vector* _omc_multiplyScalarVector(_omc_vector* vec, _omc_scalar s);
_omc_vector* _omc_addVector(_omc_vector* vec1, const _omc_vector* vec2);
_omc_vector* _omc_subVector(_omc_vector* vec1, const _omc_vector* vec2);
_omc_vector* _omc_addVectorVector(_omc_vector* dest, const _omc_vector* vec1, const _omc_vector* vec2);
_omc_vector* _omc_subVectorVector(_omc_vector* dest, const _omc_vector* vec1, const _omc_vector* vec2);
_omc_scalar _omc_scalarProduct(const _omc_vector* vec1, const _omc_vector* vec2);
_omc_scalar _omc_sumVector(const _omc_vector* vec);

/* matrix operations */
_omc_matrix* _omc_fillMatrix(_omc_matrix* mat, _omc_scalar s);
_omc_matrix* _omc_fillIndentityMatrix(_omc_matrix* mat);
_omc_matrix* _omc_negateMatrix(_omc_matrix* mat);

_omc_matrix* _omc_multiplyScalarMatrix(_omc_matrix* mat, _omc_scalar s);
_omc_matrix* _omc_addMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2);
_omc_matrix* _omc_subtractMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2);
_omc_matrix* _omc_multiplyMatrixMatrix(_omc_matrix* mat1, _omc_matrix* mat2);

/* print functions */
void _omc_printVectorWithEquationInfo(_omc_vector* vec, const char* name, const enum LOG_STREAM stream, EQUATION_INFO eqnInfo);
void _omc_printVector(_omc_vector* vec, const char* name, const enum LOG_STREAM stream);
void _omc_printMatrix(_omc_matrix* mat, const char* name, const enum LOG_STREAM stream);

/* norm functions */
_omc_scalar _omc_euclideanVectorNorm(const _omc_vector* vec);
_omc_scalar _omc_gen_euclideanVectorNorm(const _omc_scalar* vec_data, const _omc_size vec_size);
_omc_scalar _omc_maximumVectorNorm(const _omc_vector* vec);

#endif
