/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#pragma once
/** @addtogroup math
 *   @{
*/

/*************************
    copies a vector, x, to a vector, y.
    uses unrolled loops for increments equal to one.
    jack dongarra, linpack, 3/11/78.
    modified 12/3/93, array(1) declarations changed to array(*)
*************************/

extern "C" void DCOPY(long int* n, double* dx, long int* incx, double* dy, long int* incy);
extern "C" void daxpy_(long int* N, double* DA, double* DX, long int* INCX, double* DY, long int* INCY);
// Matrix vector multiplication
extern "C" void dcopy_(long int* n, double* DX, long int* INCX, double* DY, long int* INCY);
// y := alpha*A*x + beta*y
extern "C" void dgemv_(char* trans, long int* m, long int* n, double* alpha, double* a, long int* lda, double* x,
                       long int* incx, double* beta, double* y, long int* incy);
extern "C" void dscal_(long int* n, double* da, double* dx, long int* incx);
extern "C" void dger_(long int* m, long int* n, double* alpha, double* x, long int* incx, double* y, long int* incy,
                      double* a, long int* lda);
//A := alpha*x*y' + A,
extern "C" double ddot_(long int* n, double* dx, long int* incx, double* dy, long int* incy);
// dot product
extern "C" double dnrm2_(long int* n, double* x, long int* incx);
//Euclidean norm

/** @} */ // end of math
