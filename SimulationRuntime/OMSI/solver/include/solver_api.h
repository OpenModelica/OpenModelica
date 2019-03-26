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

/** \file solver_api.h
 *
 * Application interface for OMSI solver.
 */

/** \addtogroup SOLVER OMSI Solver Library
  *  \{ */

#ifndef _SOLVER_API_H
#define _SOLVER_API_H

#include <stdio.h>

#include <omsi_solver.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Function prototypes */
void solver_init_callbacks (solver_callback_allocate_memory allocateMemoryFunction,
                            solver_callback_free_memory     freeMemoryFunction,
                            solver_callback_logger          loggerFunction);

solver_data* solver_allocate(solver_name            name,
                             solver_unsigned_int    dim_n);

void solver_free(solver_data* solver);

solver_status solver_prepare_specific_data (solver_data*            solver,
                                            residual_wrapper_func   user_wrapper_res_function,
                                            void*                   user_data);

solver_status solver_set_start_vector (solver_data* solver,
                                       solver_real* initial_guess);

solver_real* solver_get_start_vector (solver_data* solver);

void solver_set_matrix_A(const solver_data*            solver,
                         const solver_unsigned_int*    column,
                         const solver_unsigned_int     n_column,
                         const solver_unsigned_int*    row,
                         const solver_unsigned_int     n_row,
                         solver_real*                  value);

void solver_get_matrix_A(solver_data*          solver,
                         solver_unsigned_int*  column,
                         solver_unsigned_int   n_column,
                         solver_unsigned_int*  row,
                         solver_unsigned_int   n_row,
                         solver_real*          value);

void solver_set_vector_b (solver_data*          solver,
                          solver_unsigned_int*  index,
                          solver_unsigned_int   size_of_b,
                          solver_real*          value);

void solver_get_vector_b (solver_data*          solver,
                          solver_unsigned_int*  index,
                          solver_unsigned_int   size_of_b,
                          solver_real*          value);

void solver_get_lin_solution(solver_data*           solver,
                             solver_unsigned_int*   index,
                             solver_unsigned_int    n_index,
                             solver_real*           values);

void solver_get_nonlin_solution(solver_data*           solver,
                                solver_unsigned_int*   index,
                                solver_unsigned_int    n_index,
                                solver_real*           values);

solver_string solver_get_name (solver_data* solver);

void solver_print_data (solver_data*    solver,
                        solver_string   header);

solver_status solver_linear_solve(solver_data* solver);

solver_status solver_non_linear_solve(solver_data* solver);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif

/** \} */
