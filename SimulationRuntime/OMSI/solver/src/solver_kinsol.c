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

/** \file solver_kinsol.c
 *
 * Solver specific functions for kinsol solver.
 */

/** @addtogroup kinsol_SOLVER kinsol solver
 *  \ingroup NONLIN_SOLVER
  *  @{ */

#include <solver_kinsol.h>

#define UNUSED(x) (void)(x)     /* ToDo: delete later */

/*
 * ============================================================================
 * Allocaten, Initialization and freeing of solver_specific_data
 * ============================================================================
 */


/**
 * Allocates memory for kinsol specific solver data and saves it in solver instance.
 *
 * \param [in,out]  general_solver_data     Solver instance.
 * \return          solver_status           solver_ok on success and
 *                                          solver_error on failure.
 */
solver_status solver_kinsol_allocate_data(solver_data* general_solver_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_real* u_scale;
    solver_real* f_scale;

    /* Check for correct solver */
    if (!solver_instance_correct(general_solver_data, solver_kinsol, "allocate_kinsol_data")) {
        return solver_error;
    }

    /* Check if general_solver_data has already specific data */
    if (general_solver_data->specific_data!=NULL) {
        solver_logger(log_solver_error, "In function allocate_kinsol_data: Pointer to solver specific data is not NULL.");
            general_solver_data->state = solver_error_state;
        return solver_error;
    }

    /* Allocate memory */
    kinsol_data = (solver_data_kinsol*) solver_allocateMemory(1, sizeof(solver_data_kinsol));
    if (!kinsol_data) {
        solver_logger(log_solver_error, "In function allocate_kinsol_data: Can't allocate memory for kinsol_data.");
        general_solver_data->specific_data = NULL;
        general_solver_data->state = solver_error_state;
        return solver_error;
    }

    /* Create Kinsol solver object */
    kinsol_data->kinsol_solver_object = KINCreate();
    if (kinsol_data->kinsol_solver_object == NULL) {
        solver_logger(log_solver_error, "In function allocate_kinsol_data: Could not create KINSOL solver object.");
        solver_freeMemory(kinsol_data);
        general_solver_data->specific_data = NULL;
        general_solver_data->state = solver_error_state;
        return solver_error;
    }

    kinsol_data->f_function_eval = NULL;

    kinsol_data->initial_guess = N_VNewEmpty_Serial(general_solver_data->dim_n);

    u_scale = (solver_real*) solver_allocateMemory(general_solver_data->dim_n, sizeof(solver_real));
    kinsol_data->u_scale = N_VMake_Serial(general_solver_data->dim_n, u_scale);

    f_scale = (solver_real*) solver_allocateMemory(general_solver_data->dim_n, sizeof(solver_real));
    kinsol_data->f_scale = N_VMake_Serial(general_solver_data->dim_n, f_scale);

    general_solver_data->specific_data = kinsol_data;
    general_solver_data->state = solver_instantiated;

    return solver_ok;
}


/**
 * \brief Set initial guess for vector `x`.
 *
 * \param [in,out]  general_solver_data     Solver instance.
 * \param [in]      initial_guess           Array with initial guess for vector `x` to start iteration.
 *                                          Has length general_solver_data->dim_n
 * \return          solver_status           solver_ok on success and
 *                                          solver_error on failure.
 */
solver_status solver_kinsol_set_start_vector (solver_data*  general_solver_data,
                                              solver_real*  initial_guess)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;

    /* check for correct solver */
    if (!solver_instance_correct(general_solver_data, solver_kinsol, "solver_kinsol_free_data")) {
        return solver_error;
    }

    kinsol_data = general_solver_data->specific_data;

    /* Set initial_guess vector */
    NV_DATA_S(kinsol_data->initial_guess) = initial_guess;

    return solver_ok;
}


solver_real* solver_kinsol_get_start_vector (solver_data*  general_solver_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;

    kinsol_data = general_solver_data->specific_data;

    return NV_DATA_S(kinsol_data->initial_guess);
}


/**
 * Set dimension `dim_n` of function `f` in kinsol specific solver data.
 *
 * \param [in,out]  general_solver_data         Solver instance.
 * \param [in]      user_wrapper_res_function   User provided residual wrapper function.
 * \param [in]      user_data                   Pointer to `user_data` needed in user provided
 *                                              residual wrapper function. Can be `NULL`.
 * \return          solver_status               `solver_ok` on success and
 *                                              `solver_error` on failure.
 */
solver_status solver_kinsol_init_data(solver_data*              general_solver_data,
                                      residual_wrapper_func     user_wrapper_res_function,
                                      void*                     user_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_int flag;

    /* check for correct solver */
    if (!solver_instance_correct(general_solver_data, solver_kinsol, "solver_kinsol_free_data")) {
        return solver_error;
    }

    /* Access data */
    kinsol_data = general_solver_data->specific_data;

    if (kinsol_data->initial_guess == NULL) {
        solver_logger(log_solver_error, "In function kinsol_init_data: Initial guess not set. "
                "Use API function solver_set_start_vector to set initial guess..");
        general_solver_data->state = solver_error_state;
        return solver_error;
    }

    /* Set Kinsol print level */
    flag = KINSetPrintLevel(kinsol_data->kinsol_solver_object, 0);
    if (flag != KIN_SUCCESS) {
        return solver_kinsol_error_handler(general_solver_data, flag,
                "kinsol_init_data",
                "Could not set print level.");
    }

    /* Set KINSOL user data */
    kinsol_data->kin_user_data = (kinsol_user_data*) solver_allocateMemory(1, sizeof(kinsol_user_data));
    kinsol_data->kin_user_data->user_data = user_data;
    kinsol_data->kin_user_data->kinsol_data = kinsol_data;
    flag = KINSetUserData(kinsol_data->kinsol_solver_object, kinsol_data->kin_user_data);
    if (flag != KIN_SUCCESS) {
        return solver_kinsol_error_handler(general_solver_data, flag,
                "kinsol_init_data",
                "Could not set KINSOL user data.");
    }

    /* Set user supplied wrapper function */
    kinsol_data->f_function_eval = user_wrapper_res_function;

    /* Set problem-defining function and initialize KINSOL*/
    flag = KINInit(kinsol_data->kinsol_solver_object,
                   solver_kinsol_residual_wrapper,
                   kinsol_data->initial_guess);
    if (flag != KIN_SUCCESS) {
        return solver_kinsol_error_handler(general_solver_data, flag,
                "kinsol_init_data",
                "Could not initialize KINSOL solver object.");
    }

    /* Set KINSOL strategy */
    kinsol_data->strategy = KIN_LINESEARCH;

    /* Create Jacobian matrix object */



    /* Create linear solver object */



    /* Attach linear solver module */
    flag = KINDense(kinsol_data->kinsol_solver_object, general_solver_data->dim_n);
    if (flag != KIN_SUCCESS) {
        return solver_kinsol_error_handler(general_solver_data, flag,
                "kinsol_init_data",
                "Could not initialize KINSOL solver object.");
    }

    /* Set scaling vectors */
    solver_kinsol_scaling(general_solver_data);

    /* Set state and exit*/
    general_solver_data->state = solver_initializated;
    return solver_ok;
}


/**
 *  \brief Frees kinsol specific solver data.
 *
 * \param [in,out]  general_solver_data     Solver instance.
 * \return          solver_status           solver_ok on success and
 *                                          solver_error on failure.
 */
solver_status solver_kinsol_free_data(solver_data* general_solver_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;

    /* check for correct solver */
    if (!solver_instance_correct(general_solver_data, solver_kinsol, "kinsol_free_data")) {
        return solver_error;
    }

    kinsol_data = general_solver_data->specific_data;

    /* Free data */
    KINFree((void*)kinsol_data);
    solver_freeMemory(kinsol_data->kin_user_data);

    solver_freeMemory(NV_DATA_S(kinsol_data->initial_guess));       /* ToDo: Is it smart to free a user supplied aray???
                                                                       Well the free Function is also provided by user, so it should work any way...
                                                                       Maybe... */
    N_VDestroy_Serial(kinsol_data->initial_guess);

    solver_freeMemory(NV_DATA_S(kinsol_data->u_scale));
    N_VDestroy_Serial(kinsol_data->u_scale);

    solver_freeMemory(NV_DATA_S(kinsol_data->f_scale));
    N_VDestroy_Serial(kinsol_data->f_scale);

    solver_freeMemory(kinsol_data);

    /* Set solver state */
    general_solver_data->state = solver_uninitialized;
    return solver_ok;
}


/*
 * ============================================================================
 * Kinsol wrapper functions
 * ============================================================================
 */

/**
 * \brief Computes system function `f` of non-linear problem.
 *
 * This function is of type `KINSysFn` and will be used by Kinsol solver
 * to evaluate `f(x)`
 *
 * \param [in]      x               Dependent variable vector `x`
 * \param [out]     fval            Set fval to `f(x)`.
 * \param [in,out]  user_data_in
 * \return          solver_int  Return value is ignored from Kinsol.
 */
solver_int solver_kinsol_residual_wrapper(N_Vector  x,
                                          N_Vector  fval,
                                          void*     user_data_in)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_real* x_data;
    solver_real* fval_data;
    kinsol_user_data* user_data;

    /* Access input data */
    user_data = (kinsol_user_data*) user_data_in;
    kinsol_data = user_data->kinsol_data;
    x_data = NV_DATA_S(x);
    fval_data = NV_DATA_S(fval);

    /* Call residual function */
    kinsol_data->f_function_eval(x_data, fval_data, user_data->user_data);

    /* Log function call */


    return 0;
}


/**
 * \brief Wrapper function for KINSOL to compute dense Jacobian
 *
 * Computes dense Jacobian `J(u)` using `omsi_function`
 * `algebraic_system_t->jacobian`.
 *
 * @param N
 * @param u
 * @param fu
 * @param J
 * @param user_data
 * @param tmp1
 * @param tmp2
 * @return
 */
solver_int solver_kinsol_jacobian_wrapper(long int N,
                                          N_Vector u,
                                          N_Vector fu,
                                          DlsMat J,
                                          void* user_data,
                                          N_Vector tmp1,
                                          N_Vector tmp2)
{

    /* ToDo: Insert smart stuff here */
    UNUSED(N);
    UNUSED(u);
    UNUSED(fu);
    UNUSED(J);
    UNUSED(user_data);
    UNUSED(tmp1);
    UNUSED(tmp2);

    return -1;
}








/*
 * ============================================================================
 * Solve call
 * ============================================================================
 */

solver_state solver_kinsol_solve(void* specific_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_int flag;

    kinsol_data = specific_data;

    /* ToDo: Scale f and x */

    /* Solver call */
    flag = KINSol(kinsol_data->kinsol_solver_object,
                  kinsol_data->initial_guess,
                  kinsol_data->strategy,
                  kinsol_data->u_scale,
                  kinsol_data->f_scale);

    if (flag != KIN_SUCCESS) {
        return solver_kinsol_error_handler(NULL, flag,
                "solver_kinsol_solve",
                "Error while solving equation system.");
    }

    return solver_ok;
}



/*
 * ============================================================================
 * Getters and setters
 * ============================================================================
 */

void solver_kinsol_get_x_element(void*                  solver_specififc_data,
                                 solver_unsigned_int    index,
                                 solver_real*           value)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_real* x_vector;

    kinsol_data = solver_specififc_data;

    /* Access initial_guess(index) */
    x_vector = N_VGetArrayPointer(kinsol_data->initial_guess);
    value[0]=x_vector[index];
}


void solver_kinsol_set_jacobian_element(void*                  solver_specififc_data,
                                        solver_unsigned_int    row,
                                        solver_unsigned_int    column,
                                        solver_real*           value)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;

    kinsol_data = solver_specififc_data;

    /* Set element Jacobian(row,column) to value */
    DENSE_ELEM(kinsol_data->Jacobian, row, column)=*value;
}


/*
 * ============================================================================
 * Helper functions
 * ============================================================================
 */

solver_status solver_kinsol_scaling(solver_data* general_solver_data)
{
    /* Variables */
    solver_data_kinsol* kinsol_data;
    solver_real* u_scale_data;
    solver_real* f_scale_data;

    solver_unsigned_int i;

    kinsol_data = general_solver_data->specific_data;

    f_scale_data = NV_DATA_S(kinsol_data->f_scale);
    u_scale_data = NV_DATA_S(kinsol_data->u_scale);

    for (i=0; i<general_solver_data->dim_n; i++) {
        u_scale_data[i] = 1;                 /* ToDo: Do smarter stuff here */
        f_scale_data[i] = 1;
    }

    return solver_ok;
}








solver_status solver_kinsol_error_handler(solver_data*  solver,
                                          solver_int    flag,
                                          solver_string function_name,
                                          solver_string message) {

    /* Set error state */
    if (solver != NULL) {
        if (flag < 0) {
                solver->state = solver_error_state;
        }
    }

    /* Log error message */
    switch (flag) {
        case KIN_SUCCESS:
            return solver_ok;

        case KIN_INITIAL_GUESS_OK:
            return solver_ok;

        case KIN_STEP_LT_STPTOL:
            solver_logger(log_solver_warning,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_STEP_LT_STPTOL",
                    function_name, message);
            return solver_warning;

        case KIN_MEM_NULL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_MEM_NULL",
                    function_name, message);
            return solver_error;

        case KIN_ILL_INPUT:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_ILL_INPUT",
                    function_name, message);
            return solver_error;

        case KIN_NO_MALLOC:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_NO_MALLOC",
                    function_name, message);
            return solver_error;

        case KIN_MEM_FAIL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_MEM_FAIL",
                    function_name, message);
            return solver_error;

        case KIN_LINESEARCH_NONCONV:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LINESEARCH_NONCONV",
                    function_name, message);
            return solver_error;

        case KIN_MAXITER_REACHED:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_MAXITER_REACHED",
                    function_name, message);
            return solver_error;

        case KIN_MXNEWT_5X_EXCEEDED:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_MXNEWT_5X_EXCEEDED",
                    function_name, message);
            return solver_error;

        case KIN_LINESEARCH_BCFAIL:
            solver_logger(log_solver_warning,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LINESEARCH_BCFAIL",
                    function_name, message);
            return solver_warning;

        case KIN_LINSOLV_NO_RECOVERY:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LINSOLV_NO_RECOVERY",
                    function_name, message);
            return solver_error;

        case KIN_LINIT_FAIL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LINIT_FAIL",
                    function_name, message);
            return solver_error;

        case KIN_LSETUP_FAIL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LSETUP_FAIL",
                    function_name, message);
            return solver_error;

        case KIN_LSOLVE_FAIL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_LSOLVE_FAIL",
                    function_name, message);
            return solver_error;

        case KIN_SYSFUNC_FAIL:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_SYSFUNC_FAIL",
                    function_name, message);
            return solver_error;

        case KIN_FIRST_SYSFUNC_ERR:
            solver_logger(log_solver_warning,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_FIRST_SYSFUNC_ERR",
                    function_name, message);
            return solver_warning;

        case KIN_REPTD_SYSFUNC_ERR:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: KIN_REPTD_SYSFUNC_ERR",
                    function_name, message);
            return solver_error;

        default:
            solver_logger(log_solver_error,
                    "Warning in function %s: %s\n"
                    "\tKINSOL_ERROR: unknown ERROR",
                    function_name, message);
            return solver_error;

        /* ToDo: Add more error cases */
    }
}


/** @} */
