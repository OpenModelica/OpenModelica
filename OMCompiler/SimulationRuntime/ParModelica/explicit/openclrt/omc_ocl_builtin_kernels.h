/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL).
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */


/*

 This file contains functions used to call and execute custom kernels or
 algoritms on OpnCL devices. For example a matrix multiplication or
 transpose can be computed with this kernels if the user has not provided
 the algorithm explicitly.
 e.g. in Modelica
   A := transpose(B);

 The operations are organized by argument type/number and return type.
 All operations that take similar type and number of arguments can be
 handled by one function

 Mahder.Gebremedhin@liu.se  2012-03-31

*/




#ifndef _OMC_OCL_BUILTIN_KERNELS_H
#define _OMC_OCL_BUILTIN_KERNELS_H

#include <time.h>
// Don't need this. Avoid unneccesary header inclusions,
// obey the dependencies.
// #include <omc_ocl_common_header.h>
// This include will bring the omc_ocl_common_header.h
#include "omc_ocl_memory_ops.h"



//binary array operations returning an array
//for now: only pass arrays with the same size.
void modelica_real_arr_arr_arr(const char* op, modelica_real* src_1, modelica_real* src_2, modelica_real* dest, int size_);

//binary array operations returning a scalar
//for now: only pass arrays with the same size
void ocl_real_arr_arr_sca(const char* op, modelica_real* src_1, modelica_real* src_2, modelica_real* dest, int size_);

//operations taking array and a scalar, returning array.
void ocl_real_arr_sca_arr(const char* op, modelica_real* src_1, modelica_real src_2, modelica_real* dest, int size_);

//unary array operations returning arrays.
void ocl_real_arr_arr(const char* op, modelica_real* src_1, modelica_real* dest, int size_);

//unary array operations returning scalars.
void ocl_real_arr_sca(const char* op, modelica_real* src_1, modelica_real* dest, int size_);

//matrix-matrix operations returning a matrix
void ocl_real_matrix_matrix_matrix(const char* op, modelica_real* src_1, int M, modelica_real* src_2, int N, modelica_real* dest, int K);

void ocl_real_matrix_matrix(const char* op, modelica_real* src_1, int M, int N, modelica_real* dest);

//alternate form of matrix multiplications. (Faster but not working right now.)
void ocl_real_matrix_matrix_matrix2(const char* op, modelica_real* src_1, int M, modelica_real* src_2, int N, modelica_real* dest, int K);

#endif
