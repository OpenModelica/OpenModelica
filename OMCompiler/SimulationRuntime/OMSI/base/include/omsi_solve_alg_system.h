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


#ifndef OMSI_SOLVE_ALG_SYSTEM__H_
#define OMSI_SOLVE_ALG_SYSTEM__H_

#ifdef __cplusplus
extern "C" {
#endif
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <math.h>

/* Public OMSI headers */
#include <omsi.h>
#include <omsi_callbacks.h>
#include <omsi_utils.h>

/* OMSI Solver header */
#include <solver_api.h>
#include <omsi_solver.h>


/* Function prototypes */
omsi_status omsi_solve_algebraic_system (omsi_algebraic_system_t*   alg_system,
                                         const omsi_values*         read_only_model_vars_and_params);

omsi_status omsi_get_analytical_jacobian (omsi_algebraic_system_t*  alg_system,
                                          const omsi_values*        read_only_model_vars_and_params);

omsi_status omsi_get_right_hand_side (omsi_algebraic_system_t*  alg_system,
                                      const omsi_values*        read_only_model_vars_and_params);

omsi_status omsi_get_loop_results (omsi_algebraic_system_t* alg_system,
                                   const omsi_values*       read_only_model_vars_and_params,
                                   omsi_values*             vars);

omsi_status omsi_set_up_solver (omsi_algebraic_system_t* alg_system);

omsi_int omsi_residual_wrapper (omsi_real*   x_data,
                                   omsi_real*   fval_data,
                                   void*        data);

omsi_int omsi_update_guess (solver_data*                solver,
                            omsi_algebraic_system_t*    alg_system_data);

#ifdef __cplusplus
}
#endif
#endif
