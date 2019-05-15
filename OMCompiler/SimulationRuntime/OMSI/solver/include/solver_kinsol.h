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

/** \file solver_kinsol.h
 */

/** \addtogroup kinsol_SOLVER kinsol solver
 *  \ingroup NONLIN_SOLVER
 *  \{ */


#ifndef _NONLINEARSOLVERKINSOL_H_
#define _NONLINEARSOLVERKINSOL_H_

#include <omsi_solver.h>
#include <solver_api.h>
#include <solver_helper.h>

#include <stdio.h>
#include <stddef.h>

/* Headers for sundials kinsol */
#include <kinsol/kinsol.h>
#include <nvector/nvector_serial.h>
#include <kinsol/kinsol_dense.h>

#ifdef __cplusplus
extern "C" {
#endif



struct solver_data_kinsol;

/**
 * User data used in kinsol functions.
 */
typedef struct kinsol_user_data {
    void*                           user_data;
    struct solver_data_kinsol*      kinsol_data;
}kinsol_user_data;


/**
 * Solver data for kinsol solver.
 */
typedef struct solver_data_kinsol {
    void* kinsol_solver_object;             /**< KINSOL memory block */
    kinsol_user_data* kin_user_data;        /**< Pointer to user_data given to all kinsol functions */

    residual_wrapper_func f_function_eval;  /**< Pointer to function to evaluate residual of `f` */

    N_Vector initial_guess;                 /**< Initial guess for first solver call, containing solution after solver call. */
    N_Vector u_scale;
    N_Vector f_scale;

    DlsMat Jacobian;                        /**< Optional Jacobian matrix used by Kinsol. */

    solver_int strategy;                    /**< Strategy used by KINSOL solver. Possible values:
                                                 `KIN_NONE`, `KIN_LINESEARCH`, `KIN_FP` or `KIN_PICARD` */
}solver_data_kinsol;


/* Function prototypes */
solver_status solver_kinsol_allocate_data(solver_data* general_solver_data);

solver_status solver_kinsol_free_data(solver_data* general_solver_data);

solver_status solver_kinsol_init_data(solver_data*              general_solver_data,
                                      residual_wrapper_func     user_wrapper_res_function,
                                      void*                     user_data);

solver_status solver_kinsol_set_start_vector (solver_data*  general_solver_data,
                                              solver_real*  initial_guess);

solver_real* solver_kinsol_get_start_vector (solver_data*  general_solver_data);

solver_int solver_kinsol_residual_wrapper(N_Vector  x,
                                          N_Vector  fval,
                                          void*     user_data_in);

solver_state solver_kinsol_solve(void* specific_data);

void solver_kinsol_get_x_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    index,
                                 solver_real*           value);

void solver_kinsol_set_jacobian_element(void*                  solver_specififc_data,
                                        solver_unsigned_int    row,
                                        solver_unsigned_int    column,
                                        solver_real*           value);

solver_status solver_kinsol_scaling (solver_data* general_solver_data);

solver_status solver_kinsol_error_handler(solver_data*  solver,
                                          solver_int    flag,
                                          solver_string function_name,
                                          solver_string message);

#ifdef __cplusplus
}   /* end of extern "C" { */
#endif

#endif

/** \} */
