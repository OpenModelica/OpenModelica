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

/** \file omsi_solve_alg_system.c
 *  \brief Contains functions for algebraic system evaluation using OMSISolver library.
 */

/** \defgroup AlgSyst Algebraic system evaluation
 *  \ingroup OMSIBase
 *
 * Functions and wrapper to use OMSISolver library with OMSI structure from
 * generated code functions.
 */

/** \addtogroup AlgSyst
  *  \{ */

#include <omsi_global.h>
#include <omsi_solve_alg_system.h>


/**
 * \brief Solve algebraic system defined in `omsi_algebraic_system_t alg_system`
 *
 * Evaluate jacobian matrix and residual function to get all informations needed
 * for linear or non-linear solver.
 * Gets called from generated code equation evaluation function.
 *
 * \param [in,out]  alg_system                          Pointer to struct containing algebraic system.
 * \param [in]      read_only_model_vars_and_params     Pointer to read only `model_vars_and_params`
 *                                                      to forward to next equation function in generated code.
 * \return                                              Returns `omsi_fatal` on critical error<br>
 *                                                      and returns `omsi_ok` otherwise.
 */
omsi_status omsi_solve_algebraic_system (omsi_algebraic_system_t*   alg_system,
                                         const omsi_values*         read_only_model_vars_and_params) {

    /* Variables */
    omsi_int status;

    /* Check if solver is ready */
    if (alg_system->solver_data == NULL ) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_fatal,
            "fmi2Evaluate: Solver for %s system %u not set.",
            alg_system->isLinear ? "linear":"nonlinear",
            alg_system->id);
        return omsi_fatal;
    }

    /* Log solver call */
    filtered_base_logger(global_logCategories, log_all, omsi_ok,
        "fmi2Evaluate: Solve %s system %u of size %u with solver %s.",
        alg_system->isLinear ? "linear":"nonlinear",
        alg_system->id,
        alg_system->n_iteration_vars,
        solver_get_name(alg_system->solver_data));

    /* Check if it is possible to reuse matrix A or vector b */
    /* ToDo */

    /* Update solver specific data */
    if (alg_system->isLinear) {
        omsi_get_analytical_jacobian(alg_system, read_only_model_vars_and_params);
        omsi_get_right_hand_side(alg_system, read_only_model_vars_and_params);
    } else {
        omsi_update_guess(alg_system->solver_data, alg_system);
    }

    alg_system->solver_data->state = solver_ready;

    /* Call solver */
    if (alg_system->isLinear) {
        status = solver_linear_solve(alg_system->solver_data);
    } else {
        status = solver_non_linear_solve(alg_system->solver_data);
    }

    if (status == solver_error) {
        return omsi_error;
    } else if (status == solver_warning) {
        return omsi_warning;
    }

    /* Save results */
    status = omsi_get_loop_results(alg_system, read_only_model_vars_and_params, alg_system->functions->function_vars);
    /* ToDo: change alg_system->functions->function_vars to next higher function_vars
     * only works because at the moment all function vars are pointer to model_vars_and_params */

    return status;
}


/**
 * \brief Evaluate `omsi_function` jacobian to get the analytical jacobian.
 *
 * Build jacobian row wise with directional derivatives.
 *
 * \param [in,out] alg_system                   Pointer to struct containing algebraic system.
 * \param [in] read_only_model_vars_and_params  Pointer to read only `model_vars_and_params`
 *                                              to forward to next equation function in generated code.
 * \return                                      Returns `omsi_fatal` on critical error<br>
 *                                              and returns `omsi_ok` otherwise.
 */
omsi_status omsi_get_analytical_jacobian (omsi_algebraic_system_t*  alg_system,
                                          const omsi_values*        read_only_model_vars_and_params) {

    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int seed_index;

    /* Set seed vars */
    for (i=0; i<alg_system->jacobian->n_input_vars; i++) {
        seed_index = alg_system->jacobian->input_vars_indices[i].index;
        alg_system->jacobian->local_vars->reals[seed_index] = 0;
    }

    /* Build jacobian row wise with directional derivatives */  /* ToDo: check if realy row wise and not column wise... */
    for (i=0; i<alg_system->jacobian->n_output_vars; i++) {    /* ToDo: Add coloring here */
        /* Activate seed for current row*/
        seed_index = alg_system->jacobian->input_vars_indices[i].index;
        alg_system->jacobian->local_vars->reals[seed_index] = 1;

        /* Evaluate directional derivative */
        alg_system->jacobian->evaluate(alg_system->jacobian, read_only_model_vars_and_params, NULL);

        /* Set i-th row of matrix A */
        solver_set_matrix_A(alg_system->solver_data,
                     NULL, alg_system->jacobian->n_output_vars,
                     &i, 1,
                     &alg_system->jacobian->local_vars->reals[alg_system->jacobian->output_vars_indices[0].index]);

        /* Reset seed vector */
        alg_system->jacobian->local_vars->reals[seed_index] = 0;
    }

    return omsi_ok;
}


/**
 * \brief Get right hand side `b` of linear equation system `A*x=b`.
 *
 * Evaluate residual function with loop iteration variables set to zero to get `-b`.
 *
 * \param [in,out] alg_system                   Pointer to struct containing algebraic system.
 * \param [in] read_only_model_vars_and_params  Pointer to read only `model_vars_and_params`
 *                                              to forward to next equation function in generated code.
 * \return                                      Returns `omsi_fatal` on critical error<br>
 *                                              and returns `omsi_ok` otherwise.
 */
omsi_status omsi_get_right_hand_side (omsi_algebraic_system_t*  alg_system,
                                      const omsi_values*        read_only_model_vars_and_params) {

    /* Variables */
    omsi_real* residual;
    omsi_unsigned_int i, n_loop_iteration_vars;
    omsi_unsigned_int loop_iter_var_index;

    n_loop_iteration_vars = alg_system->jacobian->n_output_vars;

    /* Allocate memory */
    residual = global_callback->allocateMemory(alg_system->jacobian->n_input_vars, sizeof(omsi_real));

    /* Set loop iteration variables zero. */
    for (i=0; i<n_loop_iteration_vars; i++) {
        loop_iter_var_index = alg_system->functions->output_vars_indices[i].index;
        alg_system->functions->function_vars->reals[loop_iter_var_index] = 0;
    }

    /* Evaluate residuum function */
    alg_system->functions->evaluate(alg_system->functions, read_only_model_vars_and_params, residual);

    /* Flip signs of residual to get b*/
    for (i=0; i<alg_system->jacobian->n_input_vars;i++) {
        residual[i] = - residual[i];
    }
    solver_set_vector_b(alg_system->solver_data, NULL, alg_system->jacobian->n_input_vars, residual);


    /* Free memory */
    global_callback->freeMemory(residual);

    return omsi_ok;
}


/**
 *
 * \param [in,out] alg_system                   Pointer to struct containing algebraic system.
 * \param [in] read_only_model_vars_and_params  Pointer to read only `model_vars_and_params`
 *                                              to forward to next equation function in generated code.
 * \param [in, out] vars                        On input pointer to `omsi_values`. <br>
 *                                              Contains result of algebraic system evaluation on exit.
 *                                              Overwrites information in `vars` with indices saved in
 *                                              `alg_system->functions->output_vars_indices`.
 * \return                                      Returns `omsi_fatal` on critical error,<br>
 *                                              `omsi_warning` if the solution is not within error tolerance<br>
 *                                              and returns `omsi_ok` otherwise.
 */
omsi_status omsi_get_loop_results (omsi_algebraic_system_t* alg_system,
                                   const omsi_values*       read_only_model_vars_and_params,
                                   omsi_values*             vars) {

    /* Variables */
    omsi_unsigned_int i;
    omsi_unsigned_int n_loop_iteration_vars;
    omsi_real *res;
    omsi_status status;

    status = omsi_ok;

    /* Allocate memory */
    n_loop_iteration_vars = alg_system->jacobian->n_output_vars;
    res = (omsi_real*) global_callback->allocateMemory(n_loop_iteration_vars ,sizeof(omsi_real));
    if (res == NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                        "fmi2Evaluate: Could not allocate memory.");
        return omsi_fatal;
    }

    if (alg_system->isLinear) {
        for (i=0; i<alg_system->jacobian->n_output_vars; i++) {
            solver_get_lin_solution(alg_system->solver_data,
                &i,
                1,
                &vars->reals[alg_system->functions->output_vars_indices[i].index]);
        }
    } else {
        for (i=0; i<alg_system->jacobian->n_output_vars; i++) {
            solver_get_nonlin_solution(alg_system->solver_data,
                &i,
                1,
                &vars->reals[alg_system->functions->output_vars_indices[i].index]);
        }
    }

    /* evaluate residuum function to get LOOP_SOLVED variables */
    alg_system->functions->evaluate(alg_system->functions, read_only_model_vars_and_params, res);

    /* Check result */
    for (i=0; i<n_loop_iteration_vars; i++) {
        if (fabs(res[i]) > 1e-8) {
            filtered_base_logger(global_logCategories, log_statusdiscard, omsi_warning,
                    "fmi2Evaluate: Solution of %s system %u is not within accepted error tollerance 1e-8.",
                    alg_system->isLinear? "linear":"non-linear",
                    alg_system->id);
            break;
            status = omsi_error;
        }
    }

    /* Free memory */
    global_callback->freeMemory(res);

    return status;
}

/**
 * \brief Set up solver instance for one algebraic system.
 *
 * Allocate memory and set constant data like dimensions.
 *
 * \param [in, out]  alg_system     Algebraic system instance.
 * \return                          Returns `omsi_ok` on success, otherwise `omsi_error`.
 */
omsi_status omsi_set_up_solver (omsi_algebraic_system_t* alg_system) {

    /* Allocate memory */
    alg_system->solver_data = solver_allocate(solver_lapack, alg_system->n_iteration_vars);
    if (alg_system->solver_data == NULL) {
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
            "fmi2Something: Can not allocate memory for solver instance.");
        return omsi_error;
    }

    /* Prepare specific solver data */
    if(solver_prepare_specific_data(alg_system->solver_data, omsi_residual_wrapper, alg_system) != solver_ok) {
        solver_free(alg_system->solver_data);
        filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
            "fmi2Something: Could not prepare specific solver data for solver instance.");
        return omsi_error;
    }

    return omsi_ok;
}


/**
 * \brief Callback function for OMSISolver of function type `evaluate_res_func`.
 *
 * Map input vector `x_data` to `alg_system->residual->function_vars` and vice
 * versa residual to `fval_data`.
 *
 * \param [in,out]  x_data      Gets mapped to`alg_system->residual->function_vars`.
 *                              Input for residuum function.
 * \param [out]     fval_data   Contains result of residuum evaluation.
 * \param [in,out]  data        Contains `omsi_algebraic_system_t* alg_system_data`.
 * \return                      Return `omsi_ok` on success and `omsi_error` otherwise,
 *                              returning as `omsi_int`.
 */
omsi_int omsi_residual_wrapper (omsi_real*   x_data,
                                omsi_real*   fval_data,
                                void*        data) {

    /* Variables */
    omsi_unsigned_int i, index;
    omsi_algebraic_system_t* alg_system_data;
    omsi_function_t* residual;

    alg_system_data = (omsi_algebraic_system_t*) data;
    residual = alg_system_data->functions;

    /* Copy x_data to residuum->function_vars */
    for (i=0; i<alg_system_data->jacobian->n_input_vars; i++) {      /* ToDo: Count number of loop_iteration_vars of residuum function */

        switch (residual->output_vars_indices[i].type) {
            case OMSI_TYPE_REAL:
                index = residual->output_vars_indices[i].index;
                residual->function_vars->reals[index] = x_data[i];
            break;
            default:
                filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                    "fmi2Evaluate: Could not copy data for residual evaluation."
                    "Data type was not a real.");
                return omsi_error;
        }
    }

    /* Evaluate residum */
    residual->evaluate(residual, residual->function_vars, fval_data);

    return omsi_ok;
}


/**
 * \brief Update initial guess for iterative solvers to last solution.
 *
 * \param [in,out]  solver          Solver initial guess should be updated for.
 * \param [in]      alg_system_data Containing solution of last time step.
 * \return                          Return `0` on success and `-1` on failure.
 */
omsi_int omsi_update_guess (solver_data*                solver,
                            omsi_algebraic_system_t*    alg_system_data) {

    /* Variables */
    omsi_unsigned_int i, index, n_loop_iteration_vars;
    omsi_real* initial_guess;

    /* Get pointer to initial_guess */
    initial_guess = solver_get_start_vector(solver);

    n_loop_iteration_vars = alg_system_data->jacobian->n_output_vars;

    for (i=0; i<n_loop_iteration_vars; i++) {
        switch (alg_system_data->functions->output_vars_indices[i].type) {
            case OMSI_TYPE_REAL:
                index = alg_system_data->functions->output_vars_indices[i].index;
            break;
        default:
            filtered_base_logger(global_logCategories, log_statuserror, omsi_error,
                "fmi2Evaluate: Could not copy data for initial guess."
                "Data type was not a real.");
            return -1;
        }
        initial_guess[i] = alg_system_data->functions->function_vars->reals[index];
    }

    solver_set_start_vector(solver, initial_guess);

    return 0;
}

/** \} */
