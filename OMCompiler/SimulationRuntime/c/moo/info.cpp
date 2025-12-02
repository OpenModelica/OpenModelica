/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2025, Linköpings University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linköpings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

#include "info.h"

#include <base/log.h>


namespace OpenModelica {

InfoGDOP::InfoGDOP(DATA* data, threadData_t* threadData, int argc, char** argv) :
                   data(data), threadData(threadData), argc(argc), argv(argv)
{
    set_user_solver();
    set_l2bn_options();
}

void InfoGDOP::set_user_solver() {
    const char* flag_solver = (data->simulationInfo->solverMethod ? data->simulationInfo->solverMethod : omc_flagValue[FLAG_S]);
    if (!flag_solver) return;

    for (int solver = 1; solver < S_MAX; solver++) {
        if (std::string(SOLVER_METHOD_NAME[solver]) == flag_solver) {
            user_ode_solver = static_cast<SOLVER_METHOD>(solver);
            return;
        }
    }
}

void InfoGDOP::set_l2bn_options() {
    const char* cflags = omc_flagValue[FLAG_MOO_L2BN_P1_ITERATIONS];
    l2bn_phase_one_iterations = (cflags ? atoi(cflags) : 0);

    cflags = omc_flagValue[FLAG_MOO_L2BN_P2_ITERATIONS];
    l2bn_phase_two_iterations = (cflags ? atoi(cflags) : 0);

    cflags = omc_flagValue[FLAG_MOO_L2BN_P2_LEVEL];
    l2bn_phase_two_level = (cflags ? atof(cflags) : 0.0);
}

void InfoGDOP::set_time_horizon(int steps) {
    model_start_time = data->simulationInfo->startTime;
    model_stop_time = data->simulationInfo->stopTime;
    tf = model_stop_time - model_start_time;
    intervals = static_cast<int>(round(tf/data->simulationInfo->stepSize));
    stages = steps;
}

void InfoGDOP::set_omc_flags(NLP::NLPSolverSettings& nlp_solver_settings) {
    const char* cflags = omc_flagValue[FLAG_OPTIMIZER_NP];
    set_time_horizon(cflags ? atoi(cflags) : 3);

    nlp_solver_settings.set(NLP::Option::Tolerance, data->simulationInfo->tolerance);

    // Linear solver
    cflags = omc_flagValue[FLAG_LS_IPOPT];
    if (cflags) {
        std::string opt(cflags);
        std::string lower;
        std::transform(opt.begin(), opt.end(), std::back_inserter(lower), ::tolower);

        using LS = NLP::LinearSolverOption;
        if (lower == "mumps") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MUMPS);
        } else if (lower == "ma27") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MA27);
        } else if (lower == "ma57") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MA57);
        } else if (lower == "ma77") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MA77);
        } else if (lower == "ma86") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MA86);
        } else if (lower == "ma97") {
            nlp_solver_settings.set(NLP::Option::LinearSolver, LS::MA97);
        } else {
            Log::warning("Unsupported linear solver option: %s", cflags);
        }
    }

    // Maximum iterations
    cflags = omc_flagValue[FLAG_IPOPT_MAX_ITER];
    if (cflags) {
        try {
            nlp_solver_settings.set(NLP::Option::Iterations, std::stoi(cflags));
        } catch (...) {
            Log::warning("Invalid integer for Iterations: %s", cflags);
        }
    }

    // Hessian option
    cflags = omc_flagValue[FLAG_IPOPT_HESSE];
    if (cflags) {
        std::string opt(cflags);
        std::string lower;
        std::transform(opt.begin(), opt.end(), std::back_inserter(lower), ::tolower);

        using H = NLP::HessianOption;
        if (lower == "bfgs" || lower == "lbfgs") {
            nlp_solver_settings.set(NLP::Option::Hessian, H::LBFGS);
        } else if (lower == "const" || lower == "qp") {
            nlp_solver_settings.set(NLP::Option::Hessian, H::Const);
        } else if (lower == "exact") {
            nlp_solver_settings.set(NLP::Option::Hessian, H::Exact);
        } else {
            Log::warning("Unsupported Hessian option: %s (use LBFGS, QP, or Exact)", cflags);
        }
    }
}

ExchangeJacobians::ExchangeJacobians(InfoGDOP& info) :
    /* set OpenModelica Jacobian ptrs, allocate memory, initilization of A, B, C, D */
    A(info,
      info.data->callback->INDEX_JAC_A,
      info.data->callback->initialAnalyticJacobianA),
    B(info,
      info.data->callback->INDEX_JAC_B,
      info.data->callback->initialAnalyticJacobianB),
    C(info,
      info.data->callback->INDEX_JAC_C,
      info.data->callback->initialAnalyticJacobianC,
      info.mayer_exists ? info.x_size + static_cast<int>(info.lagrange_exists) : -1),
    D(info,
      info.data->callback->INDEX_JAC_D,
      info.data->callback->initialAnalyticJacobianD,
      -1,
      info.mayer_exists ? C.sparsity.row_nnz(0) : 0) {}

ExchangeHessians::ExchangeHessians(InfoGDOP& info) :
    A(info, info.exc_jac->A),
    B(info, info.exc_jac->B),
    C(info, info.exc_jac->C),
    D(info, info.exc_jac->D) {}


} // namespace OpenModelica
