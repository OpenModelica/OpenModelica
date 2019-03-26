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

/** \file solver_api.c
 *
 * Application interface for OMSI solver.
 */

/** \addtogroup SOLVER OMSI Solver Library
  *  \{ */

#include <solver_api.h>

#include <solver_global.h>

#include <solver_lapack.h>
#include <solver_kinsol.h>


#ifdef __cplusplus
extern "C" {
#endif
/*  set global functions */
solver_callback_logger          solver_logger;
solver_callback_allocate_memory solver_allocateMemory;
solver_callback_free_memory     solver_freeMemory;

/**
 * \brief Set callback functions for memory management and logging.
 *
 * \param allocateMemoryFunction    Pointer to function for memory allocation.
 * \param freeMemoryFunction        Pointer to function for memory deallocation.
 * \param loggerFunction            Pointer to function for logging.
 */
void solver_init_callbacks (solver_callback_allocate_memory allocateMemoryFunction,
                            solver_callback_free_memory     freeMemoryFunction,
                            solver_callback_logger          loggerFunction) {

    /* set global callback functions */
    solver_allocateMemory = allocateMemoryFunction;
    solver_freeMemory = freeMemoryFunction;
    solver_logger = loggerFunction;
}


/*
 * ============================================================================
 * Memory management
 * ============================================================================
 */



/**
 * \brief Allocate memory for solver instance.
 *
 * \param [in]  name    Name of solver to use in this solver instance.
 * \param [in]  dim_n   Dimension `n` of square matrix ´A´.
 * \return              Returns newly allocated `solver_data* solver` instance.
 */
solver_data* solver_allocate(solver_name            name,
                             solver_unsigned_int    dim_n) {

    /* Variables */
    solver_data* solver;
    solver_linear_callbacks* lin_callbacks;
    solver_non_linear_callbacks* non_lin_callbacks;

    /* allocate memory */
    solver = (solver_data*) solver_allocateMemory(1, sizeof(solver_data));

    /* set dimension */
    solver->dim_n = dim_n;

    /* Set solver specific data */
    switch (name) {
        case solver_lapack:
            solver->name = solver_lapack;
            solver_lapack_allocate_data(solver);
        break;
        case solver_kinsol:
            solver->name = solver_kinsol;
            solver_kinsol_allocate_data(solver);
        break;
        default:
            solver_logger(log_solver_error, "In function solver_allocate: No valid solver_name given.");
            solver_freeMemory(solver);
            return NULL;
    }

    /* set callback functions */
    switch (name) {
        case solver_lapack:
            lin_callbacks = (solver_linear_callbacks*) solver_allocateMemory(1, sizeof(solver_linear_callbacks));

            lin_callbacks->get_A_element = &solver_lapack_get_A_element;
            lin_callbacks->set_A_element = &solver_lapack_set_A_element;

            lin_callbacks->get_b_element = &solver_lapack_get_b_element;
            lin_callbacks->set_b_element = &solver_lapack_set_b_element;

            lin_callbacks->get_x_element = &solver_lapack_get_x_element;

            lin_callbacks->solve_eq_system = &solver_lapack_solve;

            solver->solver_callbacks = lin_callbacks;
            break;
        case solver_kinsol:
            non_lin_callbacks = (solver_non_linear_callbacks*) solver_allocateMemory(1, sizeof(solver_non_linear_callbacks));
            non_lin_callbacks->solve_eq_system = solver_kinsol_solve;
            non_lin_callbacks->get_x_element = solver_kinsol_get_x_element;
            non_lin_callbacks->set_jacobian_element = solver_kinsol_set_jacobian_element;
            solver->solver_callbacks = non_lin_callbacks;
            break;
        default:
            solver_logger(log_solver_error, "In function solver_allocate: No valid solver_name given.");
            solver_freeMemory(solver);
            return NULL;
    }

    /* Set solver state */
    solver->state = solver_initializated;
    solver_logger(log_solver_all, "Solver instance allocated.");

    return solver;

}


/** \brief Free memory of struct solver_data.
 *
 * \param [in,out] solver   Pointer to solver instance.
 */
void solver_free(solver_data* solver) {

    /* free solver specific data */
    switch (solver->name) {
        case solver_lapack:
            solver_lapack_free_data(solver);
        break;
        case solver_kinsol:
            solver_kinsol_free_data(solver);
        break;
        default:
            if (solver->specific_data != NULL) {
                solver_logger(log_solver_error, "In function solver_free: No solver"
                        "specified in solver_name, but solver->specific_data is not NULL");
            }
    }

    solver_freeMemory(solver->solver_callbacks);
    solver_freeMemory(solver);
}


/**
 * \brief Prepare specific solver data.
 *
 * E.g. set dimensions for matrices or functions.
 *
 * \param [in]  solver                      Pointer to solver instance.
 * \param [in]  user_wrapper_res_function   Pointer to wrapper function for residual function.<br>
 *                                          Only used for kinsol solver.
 * \param [in]  user_data                   Pointer to user supplied data.<br>
 *                                          Only used by kinsol solver.
 * \return                                  Returns `solver_status` `solver_okay` if solved successful,
 *                                          otherwise `solver_error`.
 */
solver_status solver_prepare_specific_data (solver_data*            solver,
                                            residual_wrapper_func   user_wrapper_res_function,
                                            void*                   user_data) {

    switch (solver->name) {
        case solver_lapack:
            solver->linear = solver_true;
            return solver_lapack_set_dim_data(solver);
        case solver_kinsol:
            solver->linear = solver_false;
            return solver_kinsol_init_data(solver, user_wrapper_res_function, user_data);
        default:
            solver_logger(log_solver_error, "In function prepare_specific_solver_data:"
                    "No solver specified in solver_name.");
            return solver_error;
    }
}


/*
 * ============================================================================
 * Getters and setters
 * ============================================================================
 */

/**
 * \brief Set initial guess for start vector for non-linear solver.
 *
 * \param [in]  solver          Pointer to solver instance.
 * \param [in]  initial_guess   Array of length solver->dim_n containing initial guess.
 * \return                      Returns `solver_status` `solver_okay` if solved successful,
 *                              otherwise `solver_error`.
 */
solver_status solver_set_start_vector (solver_data* solver,
                                       solver_real* initial_guess) {

    switch (solver->name) {
        case solver_lapack:
            solver_logger(log_solver_warning, "In function solver_set_start_vector:"
                    "Linear solver LAPACK does not need a start vector. Ignoring function call.");
            return solver_warning;
        case solver_kinsol:
            solver_kinsol_set_start_vector (solver, initial_guess);
            break;
        default:
            solver_logger(log_solver_error, "In function solver_set_start_vector:"
                    "No solver specified in solver_name.");
            return solver_error;
    }

    return solver_ok;
}


/**
 * \brief Get pointer to initial guess for start vector for non-linear solver.
 *
 * \param [in]  solver          Pointer to solver instance.
 * \return      `solver_real *` Returns pointer to initial_guess if successful,
 *                              otherwise `NULL`.
 */
solver_real* solver_get_start_vector (solver_data* solver)
{
    switch (solver->name) {
        case solver_lapack:
            solver_logger(log_solver_warning, "In function solver_set_start_vector:"
                    "Linear solver LAPACK does not need a start vector. Ignoring function call.");
            return NULL;
        case solver_kinsol:
            return solver_kinsol_get_start_vector(solver);
        default:
            solver_logger(log_solver_error, "In function solver_set_start_vector:"
                    "No solver specified in solver_name.");
            return NULL;
    }
}


/** \brief Set matrix A with values from array value.
 *
 * Sets specified columns and rows of matrix A in solver specific data to
 * values from array value. If no columns and/or rows are specified (set to
 * NULL) all elements in those rows / columns are set to given values.
 *
 *   e.g set_matrix_A(solver, [1,2], 2, [2,3,5], 3, [0.1, 0.2, 0.3, 0.4, 0.5, 0.6]);
 *   will set n-times-n matrix A, for some n>= 5, to something like:<br>
 *         / a_11  a_12  a_13  ... \<br>
 *         | 0.1   0.2   a_23      |<br>
 *         | 0.3   0.4   a_33      |<br>
 *     A = | a_41  a_42  a_43      |<br>
 *         | 0.5   0.6   a_53      |<br>
 *         \ ...               ... /<br>
 *
 * \param [in,out]  solver      Struct with used solver, containing matrix A in
 *                              solver specific format. Has to be a linear solver.
 * \param [in]      column      Array of dimension `n_column` of unsigned integers,
 *                              specifying which columns of matrix A to get. If
 *                              column equals `NULL`, get the first `n_column`
 *                              columns of A.
 * \param [in]      n_column    Size of array `column`. Must be greater then 0
 *                              and less or equal to number of columns of matrix A.
 * \param [in]      row         Array of dimension `n_row` of unsigned integers,
 *                              specifying which rows of matrix A to get. If rows
 *                              equals `NULL`, get the first `n_row` rows of A.
 * \param [in]      n_row       Size of array `row`. Must be greater then 0 and
 *                              less or equal to number of rows of matrix A.
 * \param [in]      value       Pointer to matrix with values, stored as array
 *                              in column-major order of size `n_column*n_row`.
 */
void solver_set_matrix_A(const solver_data*            solver,
                         const solver_unsigned_int*    column,
                         const solver_unsigned_int     n_column,
                         const solver_unsigned_int*    row,
                         const solver_unsigned_int     n_row,
                         solver_real*                  value)
{
    /* Variables */
    solver_unsigned_int i, j;
    solver_linear_callbacks* lin_callbacks;

    if (!solver->linear) {
        /* ToDo: log error, no matrix A in non-linear case */
        return;
    }

    lin_callbacks = solver->solver_callbacks;

    if (column==NULL && row==NULL) {
        /* copy values element wise */
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->set_A_element(solver->specific_data, i, j, &value[i+j*solver->dim_n]);
            }
        }
    }
    else if (column==NULL && row != NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->set_A_element(solver->specific_data, i, row[j], &value[i+j*solver->dim_n]);
            }
        }
    }
    else if (column!=NULL && row == NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->set_A_element(solver->specific_data, column[i], j, &value[i+j*solver->dim_n]);
            }
        }
    }
    else {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->set_A_element(solver->specific_data, column[i], row[j], &value[i+j*solver->dim_n]);
            }
        }
    }
}


/** \brief Read matrix A and saves result in array value.
 *
 *  Used for linear solvers, to get values of matrix A stored in its solver
 *  specific data.
 *
 * \param [in]     solver       Struct with used solver, containing matrix A in
 *                              solver specific format. Has to be a linear solver.
 * \param [in]     column       Array of dimension `n_column` of unsigned integers,
 *                              specifying which columns of matrix A to get. If
 *                              column equals `NULL`, get the first `n_column`
 *                              columns of A.
 * \param [in]      n_column    Size of array `column`. Must be greater then 0
 *                              and less or equal to number of columns of matrix A.
 * \param [in]      row         Array of dimension `n_row` of unsigned integers,
 *                              specifying which rows of matrix A to get. If rows
 *                              equals `NULL`, get the first `n_row` rows of A.
 * \param [in]      n_row       Size of array `row`. Must be greater then 0 and
 *                              less or equal to number of rows of matrix A.
 * \param [in,out]  value       On input: Pointer to allocated memory of size
 *                              `sizeof(solver_real)*n_column*n_row`. <br>
 *                              On output: Pointer to array containing specified
 *                              columns and rows of matrix A in row-major-order.
 */
void solver_get_matrix_A(solver_data*          solver,
                         solver_unsigned_int*  column,
                         solver_unsigned_int   n_column,
                         solver_unsigned_int*  row,
                         solver_unsigned_int   n_row,
                         solver_real*          value)
{
    /* Variables */
    solver_unsigned_int i, j;
    solver_linear_callbacks* lin_callbacks;

    lin_callbacks = solver->solver_callbacks;

    if (column==NULL && row==NULL) {
        /* copy values element wise */
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->get_A_element(solver->specific_data, i, j, &value[i*solver->dim_n+j]);
            }
        }
    }
    else if (column==NULL && row != NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->get_A_element(solver->specific_data, i, row[j], &value[i*solver->dim_n+j]);
            }
        }
    }
    else if (column!=NULL && row == NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->get_A_element(solver->specific_data, column[i], j, &value[i*solver->dim_n+j]);
            }
        }
    }
    else {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                lin_callbacks->get_A_element(solver->specific_data, column[i], row[j], &value[i*solver->dim_n+j]);
            }
        }
    }
}



/** \brief Set values of vector b with values from `value`.
 *
 * Used for right hand side vector `b` of linear systems `A*x=b`.
 *
 * \param [in,out]  solver      Struct with used solver, containing vector `b` in
 *                              solver specific format. Has to be a linear solver.
 * \param [in]      index       Array of indices of `b` to set. If `NULL` for all
 *                              indices up to `n_index` vector b will be returned.
 * \param [in]      n_index     Size of index array `index`.
 * \param [in]      value       Pointer to vector with values, stored as array
 *                              of size `n_index`.
 */
void solver_set_vector_b (solver_data*          solver,
                          solver_unsigned_int*  index,
                          solver_unsigned_int   n_index,
                          solver_real*          value) {

    /* Variables */
    solver_unsigned_int i;
    solver_linear_callbacks* lin_callbacks;

    lin_callbacks = solver->solver_callbacks;

    if (index==NULL) {
        for (i=0; i<n_index; i++) {
            lin_callbacks->set_b_element(solver->specific_data, i, &value[i]);
        }
    }
    else {
        for (i=0; i<n_index; i++) {
            lin_callbacks->set_b_element(solver->specific_data, index[i], &value[i]);
        }
    }
}


/** \brief Get values of vector b with values from `value`.
 *
 * Used for right hand side vector `b` of linear systems `A*x=b`.
 *
 * \param [in]      solver      Struct with used solver, containing vector `b` in
 *                              solver specific format. Has to be a linear solver.
 * \param [in]      index       Array of indices of `b` to set. If `NULL` for all
 *                              indices up to `n_index` vector b will be set.
 * \param [in]      n_index     Size of index array `index`.
 * \param [in,out]  values      On input: Pointer to allocated memory of size
 *                              `n_index`. <br>
 *                              On output: Pointer to array containing specified
 *                              values of vector `b`.
 */
void solver_get_vector_b (solver_data*          solver,
                          solver_unsigned_int*  index,
                          solver_unsigned_int   n_index,
                          solver_real*          values) {

    /* Variables */
    solver_unsigned_int i;
    solver_linear_callbacks* lin_callbacks;

    lin_callbacks = solver->solver_callbacks;

    if (index==NULL) {
        for (i=0; i<n_index; i++) {
            lin_callbacks->get_b_element(solver->specific_data, i, &values[i]);
        }
    }
    else {
        for (i=0; i<n_index; i++) {
            lin_callbacks->get_b_element(solver->specific_data, index[i], &values[i]);
        }
    }
}


/** \brief Set jacobian matrix with values from array value.
 *
 * Sets specified columns and rows of jacobian matrix in solver specific data to
 * values from array value. If no columns and/or rows are specified (set to
 * NULL) all elements in those rows / columns are set to given values.
 *
 * \param [in,out]  solver      Struct with used solver, containing jacobian matrix in
 *                              solver specific format. Has to be a linear solver.
 * \param [in]      column      Array of dimension `n_column` of unsigned integers,
 *                              specifying which columns of jacobian matrix to get. If
 *                              column equals `NULL`, get the first `n_column`
 *                              columns of jacobian.
 * \param [in]      n_column    Size of array `column`. Must be greater then 0
 *                              and less or equal to number of columns of jacobian matrix.
 * \param [in]      row         Array of dimension `n_row` of unsigned integers,
 *                              specifying which rows of jacobian matrix to get. If rows
 *                              equals `NULL`, get the first `n_row` rows of jacobian.
 * \param [in]      n_row       Size of array `row`. Must be greater then 0 and
 *                              less or equal to number of rows of jacobian matrix.
 * \param [in]      value       Pointer to matrix with values, stored as array
 *                              in column-major order of size `n_column*n_row`.
 */
void solver_set_Jacobian(const solver_data*            solver,
                         const solver_unsigned_int*    column,
                         const solver_unsigned_int     n_column,
                         const solver_unsigned_int*    row,
                         const solver_unsigned_int     n_row,
                         solver_real*                  value)
{
    /* Variables */
    solver_unsigned_int i, j;
    solver_non_linear_callbacks* non_lin_callbacks;

    if (solver->linear) {
        /* ToDo: log error, no jacobian in linear case */
        return;
    }

    non_lin_callbacks = solver->solver_callbacks;

    if (column==NULL && row==NULL) {
        /* copy values element wise */
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                non_lin_callbacks->set_jacobian_element(solver->specific_data, i, j, &value[i+j*solver->dim_n]);
            }
        }
    }
    else if (column==NULL && row != NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                non_lin_callbacks->set_jacobian_element(solver->specific_data, i, row[j], &value[i+j*solver->dim_n]);
            }
        }
    }
    else if (column!=NULL && row == NULL) {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                non_lin_callbacks->set_jacobian_element(solver->specific_data, column[i], j, &value[i+j*solver->dim_n]);
            }
        }
    }
    else {
        for (i=0; i<n_column; i++) {
            for (j=0; j<n_row; j++) {
                non_lin_callbacks->set_jacobian_element(solver->specific_data, column[i], row[j], &value[i+j*solver->dim_n]);
            }
        }
    }
}



/**
 * \brief Get solution `x` of linear problem `A*x=b`.
 *
 * \param [in]      solver      Struct containing solution in solver specific
 *                              format. Has to be a linear solver.
 * \param [in]      index       Array of indices of `x` to get. If `NULL` get
 *                              solution for all indices up to `n_index`.
 * \param [in]      n_index     Size of index array `index`.
 * \param [in,out]  values      On input: Pointer to allocated memory of size
 *                              `n_index`. <br>
 *                              On output: Pointer to array containing specified
 *                              values of vector `x`.
 */
void solver_get_lin_solution(solver_data*           solver,
                             solver_unsigned_int*   index,
                             solver_unsigned_int    n_index,
                             solver_real*           values) {

    /* Variables */
    solver_unsigned_int i;
    solver_linear_callbacks* lin_callbacks;

    lin_callbacks = solver->solver_callbacks;

    if (index==NULL) {
        for (i=0; i<n_index; i++) {
            lin_callbacks->get_x_element(solver->specific_data, i, &values[i]);
        }
    }
    else {
        for (i=0; i<n_index; i++) {
            lin_callbacks->get_x_element(solver->specific_data, index[i], &values[i]);
        }
    }
}



/**
 * \brief Get solution `x` of non-linear problem `f(x)=0`.
 *
 * \param [in]      solver      Struct with used solver, containing solution in
 *                              solver specific format. Has to be a non-linear solver.
 * \param [in]      index       Array of indices of `x` to get. If `NULL` get
 *                              solution for all indices up to `n_index`.
 * \param [in]      n_index     Size of index array `index`.
 * \param [in,out]  values      On input: Pointer to allocated memory of size
 *                              `n_index`. <br>
 *                              On output: Pointer to array containing specified
 *                              values of vector `x`.
 */
void solver_get_nonlin_solution(solver_data*           solver,
                                solver_unsigned_int*   index,
                                solver_unsigned_int    n_index,
                                solver_real*           values) {

   /* Variables */
    solver_unsigned_int i;
   solver_non_linear_callbacks* callbacks;

   callbacks = solver->solver_callbacks;

   if (index==NULL) {
       for (i=0; i<n_index; i++) {
           callbacks->get_x_element(solver->specific_data, i, &values[i]);
       }
   }
   else {
       for (i=0; i<n_index; i++) {
           callbacks->get_x_element(solver->specific_data, index[i], &values[i]);
       }
   }
}



/**
 * \brief Return solver name as string.
 *
 * \param [in] solver   Pointer to solver instance.
 * \return              String with solver name.
 */
solver_string solver_get_name (solver_data* solver) {

    return solver_name2string(solver->name);
}


/*
 * ============================================================================
 * Print and debug functions
 * ============================================================================
 */

/**
 * Print all data in solver_instance.
 *
 * \param [in] solver       Solver instance.
 * \param [in] header       String for header of printed output. Can be NULL.
 */
void solver_print_data (solver_data*    solver,
                        solver_string   header) {

    /* Variables */
    solver_char buffer[MAX_BUFFER_SIZE] = "";
    solver_int length;
    solver_linear_callbacks* lin_callbacks;

    length = 0;
    if (header) {
        length += snprintf(buffer, MAX_BUFFER_SIZE-length, header);
        length += snprintf(buffer+length, MAX_BUFFER_SIZE-length, "\n");
    }
    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "Solver data print:\n");
    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "\t name: \t %s\n", solver_name2string(solver->name));
    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "\t linear: %s\n", solver->linear ? "solver_true":"solver_false");
    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "\t info: \t %d\n", solver->info);
    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "\t dim_n:\t %u\n", solver->dim_n);

    switch (solver->name) {
        case solver_lapack:
            solver_lapack_print_data(buffer, MAX_BUFFER_SIZE, &length, solver);
            break;
        default:
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "No solver specific data.\n");
            break;
    }

    if (length >= MAX_BUFFER_SIZE*0.5) {
        solver_logger(log_solver_all, buffer);
        length = 0;
        length += snprintf(buffer+length, MAX_BUFFER_SIZE-length, "Solver data print continue:\n");
    }

    length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
            "\t solver_callbacks set: \t\t %s \t ( Address: %x )\n", solver->solver_callbacks?"yes":"no", solver->solver_callbacks);
    switch (solver->linear) {
        case solver_true:
            lin_callbacks = solver->solver_callbacks;
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "\t\t get_A_element set: \t %s \t ( Address: %x )\n", lin_callbacks->get_A_element?"yes":"no", lin_callbacks->get_A_element);
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "\t\t set_A_element set: \t %s \t ( Address: %x )\n", lin_callbacks->set_A_element?"yes":"no", lin_callbacks->set_A_element);
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "\t\t get_b_element set: \t %s \t ( Address: %x )\n", lin_callbacks->get_b_element?"yes":"no", lin_callbacks->get_b_element);
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "\t\t set_b_element set: \t %s \t ( Address: %x )\n", lin_callbacks->set_b_element?"yes":"no", lin_callbacks->set_b_element);
            length += snprintf(buffer+length, MAX_BUFFER_SIZE-length,
                    "\t\t solve_eq_system set: \t %s \t ( Address: %x )\n", lin_callbacks->solve_eq_system?"yes":"no", lin_callbacks->solve_eq_system);
            break;
        default:

            break;
    }

    /* print buffer */
    solver_logger(log_solver_all, buffer);
}


/*
 * ============================================================================
 * Solve call
 * ============================================================================
 */

/**
 * \brief Call solve function for registered linear solver.
 *
 * Checks if all necessary data is already set and solves linear equation system
 * with registered linear solver.
 *
 * \param solver    Solver instance.
 * \return          Returns `solver_status` `solver_okay` if solved successful,
 *                  otherwise `solver_error`.
 */
solver_status solver_linear_solve(solver_data* solver) {

    /* Variables */
    solver_linear_callbacks* lin_callbacks;


    /* Check if solver is ready */
    if (!solver_func_call_allowed (solver, solver_ready, "solver_linear_solver")) {
        return solver_error;
    }

    lin_callbacks = solver->solver_callbacks;

    /* Call solve function */
    return lin_callbacks->solve_eq_system(solver->specific_data);
}


/**
 * \brief Call solve function for registered non-linear solver.
 *
 * Checks if all necessary data is already set and solves linear or non-linear
 * equation system with the registered non-linear solver.
 *
 * \param solver    Solver instance.
 * \return          Returns `solver_status` `solver_okay` if solved successful,
 *                  otherwise `solver_error`.
 */
solver_status solver_non_linear_solve(solver_data* solver) {

    /* Variables */
    solver_non_linear_callbacks* non_lin_callbacks;


    /* Check if solver is ready */
    if (!solver_func_call_allowed (solver, solver_ready, "solver_non_linear_solver")) {
        return solver_error;
    }

    non_lin_callbacks = solver->solver_callbacks;

    /* Call solve function */
    return non_lin_callbacks->solve_eq_system(solver->specific_data);
}

#ifdef __cplusplus
}  /* end of extern "C" { */
#endif


/** \} */
