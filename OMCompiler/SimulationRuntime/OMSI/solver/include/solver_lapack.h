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

/** \file solver_lapack.h
 */

/** \addtogroup LAPACK_SOLVER LAPACK solver
 *  \ingroup LIN_SOLVER
 *
 *  \brief Linear solver using LAPACK routines.
 *
 *  Using DGESV() function from LAPACK to solve `A*x=b` with square matrix `A`.
 *  [DGESV Documentation](http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html#ga5ee879032a8365897c3ba91e3dc8d512)
 *
 *  \{ */


#ifndef _LINEARSOLVERLAPACK_H_
#define _LINEARSOLVERLAPACK_H_

#include <omsi_solver.h>
#include <solver_api.h>
#include <solver_helper.h>

#include <stdio.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Struct for LAPACK solver specific data.
 */
typedef struct solver_data_lapack {
    solver_int      n;      /**< Number of linear equations. */
    solver_int      nrhs;   /**< Number of right hand sides, always `1`. */
    solver_real*    A;      /**< Array of dimension (`lda`,`n`) containing matrix in
                             *   row major order. */
    solver_int      lda;    /**< Leading dimension of array `A`. */
    solver_int*     ipiv;   /**< Array of dimension `n`, stores pivot indices for
                             *   permutation matrix `P`. */
    solver_real*    b;      /**< Array of dimension (`ldb`, `nrhs`), containing right
                             *   hand side of equation system in row major order on entry.
                             *   On exit if `info=0` solution (`n` x `nrhs`) Matrix `X` */
    solver_int      ldb;    /**< Leading dimension of array `B`. */
    solver_int      info;   /**< `=0` if successful, `<0` if for `info=-i` the
                             *   `i`-th diagonal element is singular. */
} solver_data_lapack;


/* extern function prototypes */
extern solver_int dgesv_(solver_int *n, solver_int *nrhs, solver_real *a, solver_int *lda,
                       solver_int *ipiv, solver_real *b, solver_int *ldb, solver_int *info);
extern solver_real ddot_(solver_int* n, solver_real* dx, solver_int* incx, solver_real* dy, solver_int* incy);

/* function prototypes */
solver_status solver_lapack_allocate_data(solver_data* general_solver_data);

solver_status solver_lapack_free_data(solver_data* general_solver_data);

solver_status solver_lapack_set_dim_data(solver_data* general_solver_data);

void solver_lapack_get_A_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    row,
                                 solver_unsigned_int    column,
                                 solver_real*           value);

void solver_lapack_set_A_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    row,
                                 solver_unsigned_int    column,
                                 solver_real*           value);

void solver_lapack_get_b_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    index,
                                 solver_real*           value);

void solver_lapack_set_b_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    index,
                                 solver_real*           value);

void solver_lapack_get_x_element(void*                  specific_data,
                                 solver_unsigned_int    index,
                                 solver_real*           value);

solver_state solver_lapack_solve(void* specific_data);

void solver_lapack_print_data(solver_char*          buffer,
                              solver_unsigned_int   buffer_size,
                              solver_int*           length,
                              solver_data*          general_solver_data);


#ifdef __cplusplus
}   /* end of extern "C" { */
#endif
#endif

/** \} */
