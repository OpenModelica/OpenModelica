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

/** \file solver_helper.c
 *
 * Helper functions for OMSI solver.
 */

/** @addtogroup SOLVER OMSI Solver Library
  *  @{ */

#include <solver_helper.h>

solver_bool solver_instance_correct(solver_data*    general_solver_data,
                                    solver_name     given_name,
                                    solver_string   function_name) {

    if (general_solver_data->name != given_name) {
        solver_logger(log_solver_error, "In function %s:"
                "Solver instance is not %s.",
                function_name,
                solver_name2string(given_name));
        general_solver_data->state = solver_error_state;
        return solver_false;
    }

    return solver_true;
}


solver_string solver_name2string(solver_name name) {

    switch (name) {
    case solver_lapack:
        return "LAPACK";
    case solver_newton:
        return "Newton";
    case solver_kinsol:
        return "SUNDIALS KINSOL";
    case solver_extern:
        return "Extern solver";
    case solver_unregistered:
        return "No solver name set";
    default:
        return "Unknown solver name";
    }
}


solver_bool solver_func_call_allowed (solver_data*      general_solver_data,
                                      solver_state      expected_state,
                                      solver_string     function_name) {

    if (general_solver_data->state != expected_state) {
        solver_logger(log_solver_error, "In function %s: "
                "Function call was not allowed for current state %s. "
                "Expected state %s.",
                function_name,
                solver_state2string(general_solver_data->state),
                solver_state2string(expected_state));
        general_solver_data->state = solver_error_state;
        return solver_false;
    }

    return solver_true;
}


solver_string solver_state2string(solver_state state) {

    switch (state) {
    case solver_uninitialized:
        return "solver_uninitialized";
    case solver_instantiated:
        return "solver_instantiated";
    case solver_initializated:
        return "solver_initializated";
    case solver_ready:
        return "solver_ready";
    case solver_finished_ok:
            return "solver_finished_ok";
    case solver_finished_error:
            return "solver_finished_error";
    case solver_error_state:
            return "solver_error_state";
    default:
        return "Unknown solver state";
    }
}

/** @} */
