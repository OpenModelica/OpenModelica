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

/** \file omsi_solver.h
 * Solver application interface to solve linear and non-linear equation systems
 * in shape of
 *   A*x = b or F(x) = 0,
 * with square Matrix A of dimension n or F:R^n --> R^n.
 *
 */


/** \defgroup SOLVER OMSI Solver Library
 *  \ingroup OMSI
 *
 * \brief Solver library for OpenSimultionInterface.
 *
 *  ... containing linear and non-linear
 * solver to compute algebraic loops within OMSI.
 *
 * Can also be used as stand-alone solver library.
 */

/** \defgroup LIN_SOLVER Linear OMSI Solver
 *  \ingroup SOLVER
 *
 * \brief Linear solver collection.
 *
 * Linear solver to compute algebraic equation systems of form A*x=b.
 * A is an `n` x `n` square matrix, b is vector of dimension `n`.
 */

/** \defgroup NONLIN_SOLVER Non-Linear OMSI Solver
 *  \ingroup SOLVER
 *
 * \brief Non-linear solver collection.
 *
 * Non-linear solver to compute algebraic equation systems of form f(x)=0.
 */


/** \addtogroup SOLVER OMSI Solver Library
  *  \{ */

#ifndef SOLVER_API_H
#define SOLVER_API_H


#ifdef __cplusplus
extern "C" {
#endif

/*
 * Type definitions of variables
 */
#ifdef OMSI_TYPES_DEFINED

typedef omsi_unsigned_int   solver_unsigned_int;
typedef omsi_real           solver_real;
typedef omsi_int            solver_int;
typedef omsi_long           solver_long;
typedef omsi_bool           solver_bool;
#define solver_true         omsi_true
#define solver_false        omsi_false
#ifndef true
#define true omsi_true
#endif
#ifndef false
#define false omsi_false
#endif
typedef omsi_char           solver_char;
typedef omsi_string         solver_string;
#else
typedef unsigned int        solver_unsigned_int;
typedef double              solver_real;
typedef int                 solver_int;
typedef long                solver_long;
typedef int                 solver_bool;
#define solver_true  1
#define solver_false 0
typedef char                solver_char;
typedef const solver_char*  solver_string;
#endif

/* Maximum buffer size for print functions. */
#define MAX_BUFFER_SIZE BUFSIZ


/**
 * Solver name to specify used solver in solver_data
 */
typedef enum {
    solver_unregistered, /**< No solver selected. */
    solver_lapack,       /**< LAPACK solver using DGESV routine for generale matrices. <br>
                              [DGESV Documentation](http://www.netlib.org/lapack/explore-html/d7/d3b/group__double_g_esolve_ga5ee879032a8365897c3ba91e3dc8d512.html#ga5ee879032a8365897c3ba91e3dc8d512) */
    solver_newton,       /**< solver_newton */
    solver_kinsol,       /**< SUNDIALS KINSOL solver */
    solver_extern        /**< solver_extern */
}solver_name;


/**
 * Current state of solver instance.
 */
typedef enum {
    solver_uninitialized = 0,   /**< Solver is not initialized yet. */
    solver_instantiated,        /**< Memory for `solver_data` is allocated. */
    solver_initializated,       /**< Solver is initialized for selected `solver_name`
                                     and memory was allocated. */
    solver_ready,               /**< Solver is ready to compute solution of algebraic system. */
    solver_finished_ok,         /**< Solver computed solution successfully. */
    solver_finished_error,      /**< Solver could not solve algebraic system successfully. */
    solver_error_state          /**< Solver is in critical error state. */
}solver_state;


/**
 * Status for error handling.
 */
typedef enum {
    solver_ok,      /**< Everything is just fine. */
    solver_warning, /**< Something is not totally correct, but carrying on. */
    solver_error    /**< Encountered a serious problem, need to abort. */
}solver_status;


#define NUMBER_OF_SOLVER_CATEGORIES 5
typedef enum {
    log_solver_error,
    log_solver_warning,
    log_solver_nonlinear,
    log_solver_linear,
    log_solver_all
}solver_log_level;

/** Information about solution and its quality.
 *
 * Multiple values are possible.
 */
typedef enum {
    solver_successful_exit       = 1<<0,    /**< Solver solved algebraic system successful. */

    /* linear informations */
    solver_singular              = 1<<1,    /**< Solver encountered singularity, e.g. in LU decomposition. */

    /* non-linear informations */
    solver_max_iteration_reached = 1<<2,    /**< Solver reached maximum number of iterations (only for non-linear solvers). */
    solver_min_step_size_reached = 1<<3,    /**< Solver step size has fallen below minimum step size (only for non-linear solvers). */
    solver_got_assert            = 1<<4     /**< Got an assert, e.g. while evaluating function f. */
}solver_info;


/* callback functions */
/** \fn void (*solver_callback_logger) (solver_string format, ...)
 * \brief Logger function.
 *
 * Used to report messages and prints.
 * Must accept format tags in `format` in form of
 * `%[flags][width][.precision][length]specifier` as specified for `printf` of
 * the C standard library..
 * E.g. use `printf` from the C standard library.
 *
 * \param [in] log_level    Log level of current message to filter logs.
 * \param [in] format       Text to be written. Can optionally contain embedded
 *                          format tags similar to `printf`.
 */
typedef void    (*solver_callback_logger)   (solver_log_level,
                                             solver_string, ...);


/** \fn void* (*solver_callback_allocate_memory) (solver_unsigned_int n_objects, solver_unsigned_int size)
 * \brief Callback function to allocate memory.
 *
 * The space is initialized to zero bytes. E.g. use `calloc` from the C standard
 * library.
 *
 * \param   [in]    n_objects   Number of objects to allocate memory for.
 * \param   [in]    size        Size of each object.
 *
 * \return          Returns pointer to allocated memory for a vector of
 *                  `n_objects` objects, each of size `size`, or `NULL` on failure.
 */
typedef void*   (*solver_callback_allocate_memory)  (solver_unsigned_int, solver_unsigned_int);


/** \fn void (*solver_callback_free_memory) (void* pointer)
 * \brief Callback function to free memory allocated with `solver_allocate_memory`
 * function.
 *
 * If a null pointer is provided as input no action is performed.
 *
 * \param [in] pointer  Pointer to memory allocated previously with
 *                      `solver_allocate_memory` function or `NULL`.
 */
typedef void    (*solver_callback_free_memory)      (void*);

typedef void    (*solver_interact_matrix_element)   (void*,
                                                     solver_unsigned_int,
                                                     solver_unsigned_int,
                                                     solver_real*);

typedef void    (*solver_interact_vector_element)   (void*,
                                                     solver_unsigned_int,
                                                     solver_real*);

typedef void    (*solver_get_set_F_func)            (void);


typedef solver_state (*solver_solve_func)           (void*);


/** \fn solver_status (*evaluate_res_func) (void* data);
 * \brief Evaluate residuum function `f(x)` for non-linear equation systems.
 *
 * \param [in]  x_vector    Vector x
 * \param [out] fval        Function value `f(x)`
 */
typedef void (*evaluate_res_func)                   (solver_real*   x_vector,
                                                     solver_real*   fval,
                                                     void*          data);

typedef solver_int (*residual_wrapper_func)         (solver_real*,
                                                     solver_real*,
                                                     void*);

/**
 * Struct for callback functions for linear solvers.
 */
typedef struct solver_linear_callbacks {
    solver_interact_matrix_element get_A_element;   /**< Callback function to get element(s) of `A`. */
    solver_interact_matrix_element set_A_element;   /**< Callback function to set element(s) of `A`. */

    solver_interact_vector_element get_b_element;   /**< Callback function to get element(s) of `b`. */
    solver_interact_vector_element set_b_element;   /**< Callback function to set element(s) of `b`. */

    solver_interact_vector_element get_x_element;   /**< Callback function to get element(s) of solution vector `x`. */

    solver_solve_func solve_eq_system;              /**< Callback function to solve equation system `A*x=b`. */
} solver_linear_callbacks;


/**
 * Struct for callback functions for non-linear solvers.
 */
typedef struct solver_non_linear_callbacks {
    solver_solve_func solve_eq_system;

    solver_interact_vector_element get_x_element;           /**< Callback function to get element(s) of solution vector `x`. */

    solver_interact_matrix_element set_jacobian_element;    /**< Callback function to set element of Jacobian matrix*/
} solver_non_linear_callbacks;


/** \brief General solver structure.
 *
 * Containing informations and function callbacks for a general solver instance.
 * Solver specific data is stored in `specific_data` in it's own data formats.
 *
 *
 */
typedef struct solver_data {
    solver_name         name;           /**< Name of solver instance. */
    solver_bool         linear;         /**< `solver_true` if solver can only solve linear problems,
                                         *   `solver_false` if non-linear. */

    solver_state        state;          /**< Current state of solver instance, e.g if already initialized or finished. */
    solver_info         info;           /**< Informations about solution quality. */

    solver_unsigned_int dim_n;          /**< Dimension of algebraic loop. In linear
                                             case dimension `n` of square matrix `A`.
                                             For non-linear loops dimension `n` of function `f`. */
    void*               specific_data;  /**< Solver specific data, depending on named solver.
                                             Contains it's own data formats to save variables, settings and so on. */

    void*               solver_callbacks;   /**< Linear case: Pointer to `solver_linear_callbacks`<br>
                                             *   Non-linear case: Pointer to `solver_non_linear_callbacks`. */
} solver_data;




#ifdef __cplusplus
}  /* end of extern "C" { */
#endif

#endif

/** \} */
