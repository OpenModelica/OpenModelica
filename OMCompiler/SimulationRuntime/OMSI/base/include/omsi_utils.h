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

/*
 * This file defines functions for the FMI used via the OpenModelica Simulation
 * Interface (OMSI). These are helper functions used for the other omsu functions.
 */

#ifndef OMSU_UTILS__H_
#define OMSU_UTILS__H_


#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include <omsi.h>

#include <omsi_global.h>

#include <solver_api.h>

#include <omsi_input_model_variables.h>


#ifdef __cplusplus
extern "C" {
#endif

#if _MSC_VER
#define __attribute__(x)
#endif


/* function prototypes */
void filtered_base_logger(omsi_bool*            logCategories,      /* Array of categories, that should be logged, can be NULL */
                          log_categories        category,           /* Category of this log call */
                          omsi_status           status,             /* Status for logger */
                          omsi_string           message,            /* Message for logger */
                          ...);                                      /* Optional arguments in message */

void wrapper_alg_system_logger (solver_log_level    log_level,
                                omsi_string         message, ...);

omsi_bool isCategoryLogged(omsi_bool*       logCategories,
                           log_categories   categoryIndex);

void omsu_free_osu_data(omsi_t* omsi_data);

void omsu_free_model_data (model_data_t* model_data);

void omsu_free_model_variable_info(model_variable_info_t*   model_vars_info,
                                   omsi_unsigned_int        size);

void omsu_free_modelica_attributes(void*            modelica_attribute,
                                   omsi_data_type  type);

void omsu_free_equation_info(equation_info_t*   eq_info,
                             omsi_unsigned_int  n_equations );

void omsu_free_sim_data (sim_data_t* sim_data);

void omsu_free_omsi_function(omsi_function_t*   omsi_function,
                             omsi_bool          shared_vars);

void omsu_free_alg_system (omsi_algebraic_system_t* algebraic_system,
                           omsi_bool                shared_vars);

void omsu_free_omsi_values(omsi_values* values);

omsi_bool omsi_vr_out_of_range(omsi_t*               omsu,
                               omsi_string          function_name,
                               omsi_unsigned_int    vr,
                               omsi_int             end);

omsi_int omsi_get_negated_index (model_variable_info_t* model_var_info,
                                 omsi_unsigned_int      value_reference);

void omsu_print_omsi_t (omsi_t*     omsi,
                        omsi_string indent);

void omsu_print_model_data(model_data_t*    model_data,
                           omsi_string      indent);

omsi_status omsu_print_model_variable_info(model_data_t*  model_data,
                                           omsi_string    indent);

omsi_status omsu_print_modelica_attributes (void*               modelica_attribute,
                                            omsi_index_type*    type_index,
                                            omsi_string         indent);

void omsu_print_real_var_attribute (real_var_attribute_t*   real_var_attribute,
                                    omsi_string             indent);

void omsu_printf_int_var_attribute(int_var_attribute_t* int_var_attribute,
                                   omsi_string          indent);

omsi_status omsu_print_equation_info(model_data_t*  model_data,
                                     omsi_string    indent);

void omsu_print_experiment (omsi_experiment_t*  experiment,
                            omsi_string         indent);

omsi_status omsu_print_sim_data (sim_data_t* sim_data,
                                 omsi_string indent);

omsi_status omsu_print_omsi_function_rec (omsi_function_t* omsi_function,
                                          omsi_string      omsi_function_name,
                                          omsi_string      indent);

omsi_status omsu_print_this_omsi_function (omsi_function_t* omsi_function,
                                           omsi_string      omsi_function_name,
                                           omsi_string      indent);

omsi_status omsu_print_omsi_values (omsi_values*        omsi_values,
                                    omsi_string         omsi_values_name,
                                    omsi_string         indent);

omsi_status omsu_print_algebraic_system(omsi_algebraic_system_t*    algebraic_system_t,
                                        omsi_string                 indent);

omsi_status omsu_print_index_type (omsi_index_type*     vars_indices,
                                   omsi_unsigned_int    size,
                                   omsi_string          indent);

omsi_status omsu_print_externs(void*                externs,
                               omsi_unsigned_int    n_externs);

omsi_status omsu_print_solver_data(omsi_string  solver_name,
                                   void*        solver_data,
                                   omsi_string  indent);
#ifdef __cplusplus
}
#endif
#endif
