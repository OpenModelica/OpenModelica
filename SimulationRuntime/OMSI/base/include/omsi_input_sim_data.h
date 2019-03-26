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

#ifndef OMSU_INPUT_SIM_DATA_H
#define OMSU_INPUT_SIM_DATA_H

#include <omsi.h>
#include <omsi_callbacks.h>
#include <omsi_global.h>
#include <omsi_utils.h>

#include <omsi_solver.h>
#include <solver_api.h>
#include <omsi_solve_alg_system.h>

#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>


#ifdef __cplusplus
extern "C" {
#endif


/* function prototypes */

omsi_status omsu_setup_sim_data(omsi_t*                             omsi_data,
                                omsi_template_callback_functions_t* template_function,
                                const omsi_callback_functions*      callback_functions);

omsi_status omsu_setup_sim_data_omsi_function(sim_data_t*                   sim_data,
                                              omsi_string                   function_name,
                                              omsu_initialize_omsi_function template_instantiate_function);

omsi_status omsu_allocate_sim_data(omsi_t* omsi_data, const omsi_callback_functions*      callback_functions, omsi_string                     instanceName);

omsi_status omsu_instantiate_omsi_function_func_vars (omsi_function_t*    omsi_function,
                                                      omsi_values*        function_vars,
                                                      omsi_values*        pre_vars) ;

omsi_status omsu_set_zerocrossings_omsi_functions (omsi_function_t* omsi_function,
                                                   omsi_real*       pointer_to_zerocrossings_vars,
                                                   omsi_real*       pointer_to_pre_zerocrossings_vars,
                                                   omsi_sample*     sample_events);

omsi_function_t* omsu_instantiate_omsi_function (omsi_values*   function_vars,
                                                 omsi_values*   pre_vars);

omsi_algebraic_system_t* omsu_instantiate_alg_system_array (omsi_unsigned_int n_algebraic_system);

omsi_status omsu_set_model_vars_and_params_start (omsi_values*     model_vars_and_params,
                                                  model_data_t*    model_data);

omsi_values* instantiate_omsi_values (omsi_unsigned_int   n_reals,
                                      omsi_unsigned_int   n_ints,
                                      omsi_unsigned_int   n_bools,
                                      omsi_unsigned_int   n_externs);

omsi_status omsu_set_template_functions (omsi_template_callback_functions_t*  template_callback);

omsi_status instantiate_input_inner_output_indices (omsi_function_t*    omsi_function,
                                                    omsi_unsigned_int   n_input_vars,
                                                    omsi_unsigned_int   n_output_vars);

omsi_status omsu_set_default_solvers (omsi_function_t*  omsi_function,
                                      omsi_string       omsi_function_name);

void omsu_set_initial_guess (omsi_algebraic_system_t* algebraic_system);

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif
