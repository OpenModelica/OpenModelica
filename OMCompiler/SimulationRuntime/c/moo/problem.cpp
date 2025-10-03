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

#include "simulation_data.h"
#include "simulation/simulation_runtime.h"
#include "simulation/solver/gbode_main.h"
#include "simulation/solver/external_input.h"

#include <nlp/instances/gdop/gdop.h>

#include "evaluations.h"
#include "strategies.h"

#include "problem.h"

#define NUM_HES_FD_STEP 1e-6      // base step size for numerical Hessian perturbation
#define NUM_HES_DF_EXTR_STEPS 1   // number of extrapolation steps
#define NUM_HES_EXTR_DIV 2        // divisor for new step size in extrapolation


namespace OpenModelica {

FullSweep::FullSweep(GDOP::FullSweepLayout&& layout_lfg,
                           const GDOP::ProblemConstants& pc,
                           InfoGDOP& info)
    : GDOP::FullSweep(std::move(layout_lfg), pc), info(info) {
}

void FullSweep::callback_eval(const f64* xu_nlp, const f64* p) {
    set_parameters(info, p);
    for (int i = 0; i < pc.mesh->intervals; i++) {
        for (int j = 0; j < pc.mesh->nodes[i]; j++) {
            const f64* xu_ij = get_xu_ij(xu_nlp, i, j);
            f64* eval_buf_ij = get_eval_buffer(i, j);

            set_states_inputs(info, xu_ij);
            set_time(info, pc.mesh->t[i][j]);
            eval_current_point_dae(info);
            eval_lfg_write(info, eval_buf_ij);
        }
    }
}

void FullSweep::callback_jac(const f64* xu_nlp, const f64* p) {
    set_parameters(info, p);
    for (int i = 0; i < pc.mesh->intervals; i++) {
        for (int j = 0; j < pc.mesh->nodes[i]; j++) {
            const f64* xu_ij = get_xu_ij(xu_nlp, i, j);
            f64* jac_buf_ij  = get_jac_buffer(i, j);

            set_states_inputs(info, xu_ij);
            set_time(info, pc.mesh->t[i][j]);
            eval_current_point_dae(info);
            /* TODO: check if B matrix does hold additional ders */
            jac_eval_write_as_csc(info, info.exc_jac->B.jacobian, jac_buf_ij);
        }
    }
}

void FullSweep::callback_hes(const f64* xu_nlp, const f64* p, const FixedField<f64, 2>& lagrange_factors, const f64* lambda) {
    set_parameters(info, p);
    for (int i = 0; i < pc.mesh->intervals; i++) {
        for (int j = 0; j < pc.mesh->nodes[i]; j++) {
            const f64* xu_ij     = get_xu_ij(xu_nlp, i, j);
            const f64* lambda_ij = get_lambda_ij(lambda, i, j);
            f64* jac_buf_ij      = get_jac_buffer(i, j);
            f64* hes_buf_ij  = get_hes_buffer(i, j);

            set_states_inputs(info, xu_ij);
            set_time(info, pc.mesh->t[i][j]);

            /* TODO: check if B matrix does hold additional ders */

            if (pc.has_lagrange) {
                /* OpenModelica sorts the Functions as fLg, we have to
                 * use the workspace buffer from info.exc_hes and split the old lambda
                 * (lmbd_f_1, ..., lmbd_f_n,             lmbd_g_1, ..., lmbd_g_m) in the middle as
                 * (lmbd_f_1, ..., lmbd_f_n, *L_factor*, lmbd_g_1, ..., lmbd_g_m) */
                info.exc_hes->B.lambda[pc.x_size] = lagrange_factors[i][j];
                for (int f = 0; f < pc.f_size; f++) {
                    info.exc_hes->B.lambda[f] = lambda_ij[f];
                }
                for (int g = 0; g < pc.g_size; g++) {
                    /* Lagrange offset */
                    info.exc_hes->B.lambda[pc.f_size + 1 + g] = lambda_ij[pc.f_size + g];
                }
                /* set wrapper lambda */
                info.exc_hes->B.args.lambda = info.exc_hes->B.lambda.raw();
            }
            else {
                /* set wrapper lambda, as Lagrange term isnt set and OM and MOO sortings are the same (f, g) */
                info.exc_hes->B.args.lambda = lambda_ij;
            }

            /* set previous Jacobian *CSC* OpenModelica buffer */
            info.exc_hes->B.args.jac_csc = jac_buf_ij;

            /* call Hessian */
            richardson_extrapolation(info.exc_hes->B.extr, hessian_fwd_differences_wrapper, &info.exc_hes->B.args,
                                    NUM_HES_FD_STEP, NUM_HES_DF_EXTR_STEPS, NUM_HES_EXTR_DIV, 1, hes_buf_ij);
        }
    }
}

BoundarySweep::BoundarySweep(GDOP::BoundarySweepLayout&& layout_mr,
                                   const GDOP::ProblemConstants& pc,
                                   InfoGDOP& info)
    : GDOP::BoundarySweep(std::move(layout_mr), pc), info(info) {}

void BoundarySweep::callback_eval(const f64* x0_nlp, const f64* xuf_nlp, const f64* p) {
    set_parameters(info, p);
    set_states_inputs(info, xuf_nlp);
    set_time(info, pc.mesh->tf);
    eval_current_point_dae(info);
    eval_mr_write(info, get_eval_buffer());
}

void BoundarySweep::callback_jac(const f64* x0_nlp, const f64* xuf_nlp, const f64* p) {
    f64* jac_buf = get_jac_buffer();
    set_parameters(info, p);
    set_states_inputs(info, xuf_nlp);
    set_time(info, pc.mesh->tf);
    eval_current_point_dae(info);
    /* TODO: check if C matrix does hold additional ders */

    /* derivative of mayer to jacbuffer[0] ... jac_buffer[exc_jac.D_coo.nnz_offset - 1] */
    if (pc.has_mayer) {
        jac_eval_write_first_row_as_csc(info, info.exc_jac->C.jacobian, info.exc_jac->C.buffer.raw(),
                                        jac_buf, info.exc_jac->C.sparsity);
    }

    if (info.exc_jac->D.exists) {
        /* TODO: check if D matrix does hold additional ders */
        jac_eval_write_as_csc(info, info.exc_jac->D.jacobian, jac_buf + info.exc_jac->D.sparsity.nnz_offset);
    }
}

void BoundarySweep::callback_hes(const f64* x0_nlp, const f64* xuf_nlp, const f64* p, const f64 mayer_factor, const f64* lambda) {
    set_parameters(info, p);
    set_states_inputs(info, xuf_nlp);
    set_time(info, pc.mesh->tf);
    fill_zero_hes_buffer();

    f64* jac_buf = get_jac_buffer();
    f64* hes_buffer = get_hes_buffer();

    if (pc.has_mayer) {
        // set all lambdas to 0, except mayer lambda
        int index_mayer = pc.x_size + static_cast<int>(info.lagrange_exists);
        info.exc_hes->C.lambda[index_mayer] = mayer_factor;
        info.exc_hes->C.args.lambda = info.exc_hes->C.lambda.raw();

        richardson_extrapolation(info.exc_hes->C.extr, hessian_fwd_differences_wrapper, &info.exc_hes->C.args,
                                NUM_HES_FD_STEP, NUM_HES_DF_EXTR_STEPS, NUM_HES_EXTR_DIV, 1, info.exc_hes->C.buffer.raw());
        for (auto& [index_C, index_buffer] : info.exc_hes->C_to_Mr_buffer) {
            hes_buffer[index_buffer] += info.exc_hes->C.buffer[index_C];
        }
    }

    if (pc.r_size != 0) {
        /* set duals and precomputed Jacobian D */
        info.exc_hes->C.args.lambda = lambda;
        info.exc_hes->C.args.jac_csc = jac_buf + info.exc_jac->D.sparsity.nnz_offset;

        richardson_extrapolation(info.exc_hes->C.extr, hessian_fwd_differences_wrapper, &info.exc_hes->C.args,
                                NUM_HES_FD_STEP, NUM_HES_DF_EXTR_STEPS, NUM_HES_EXTR_DIV, 1, info.exc_hes->C.buffer.raw());
        for (auto& [index_D, index_buffer] : info.exc_hes->C_to_Mr_buffer) {
            hes_buffer[index_buffer] += info.exc_hes->C.buffer[index_D];
        }
    }
}

Dynamics::Dynamics(const GDOP::ProblemConstants& pc, InfoGDOP& info)
    : GDOP::Dynamics(pc), info(info) {}

void Dynamics::allocate() {
    // TODO: its unclear if other allocations are missing here. for now its working
    JACOBIAN* jacobian = info.exc_jac->A.jacobian;
    if (!jacobian->sparsePattern) {
        info.data->callback->initialAnalyticJacobianA(info.data, info.threadData, jacobian);
        allocated_ode_matrix = true;
    }

    SPARSE_PATTERN* sparsePattern = jacobian->sparsePattern;

    jac_pattern = ::Simulation::Jacobian::sparse(
                    ::Simulation::JacobianFormat::CSC,
                    reinterpret_cast<int*>(sparsePattern->index)     /* row indices */,
                    reinterpret_cast<int*>(sparsePattern->leadindex) /* col pointers */,
                    sparsePattern->numberOfNonZeros);
}

void Dynamics::free() {
    if (allocated_ode_matrix) {
        freeJacobian(info.exc_jac->A.jacobian);
        allocated_ode_matrix = false;
    }
}

void Dynamics::eval(const f64* x, const f64* u, const f64* p, f64 t, f64* f, void* user_data) {
    set_parameters(info, p);
    set_states(info, x);
    set_inputs(info, u);
    set_time(info, t);
    eval_current_point_ode(info);
    eval_ode_write(info, f);
}

void Dynamics::jac(const f64* x, const f64* u, const f64* p, f64 t, f64* dfdx, void* user_data) {
    set_parameters(info, p);
    set_states(info, x);
    set_inputs(info, u);
    set_time(info, t);
    eval_write_ode_jacobian(info, dfdx);
}

GDOP::Problem create_gdop(InfoGDOP& info, const Mesh& mesh) {
    DATA* data = info.data;

    // at first call init for all start values
    initialize_model(info);

    /* variable sizes */
    info.x_size = data->modelData->nStates;
    info.u_size = data->modelData->nInputVars;
    info.xu_size = info.x_size + info.u_size;
    info.p_size = 0; // TODO: PARAMETERS

    /* variable bounds */
    FixedVector<Bounds> x_bounds(info.x_size);
    FixedVector<Bounds> u_bounds(info.u_size);
    FixedVector<Bounds> p_bounds(info.p_size);

    for (int x = 0; x < info.x_size; x++) {
        x_bounds[x].lb = data->modelData->realVarsData[x].attribute.min;
        x_bounds[x].ub = data->modelData->realVarsData[x].attribute.max;
    }

    /* new generated function getInputVarIndices, just fills the index list of all optimizable inputs */
    info.u_indices_real_vars = FixedVector<int>(info.u_size);
    data->callback->getInputVarIndicesInOptimization(data, info.u_indices_real_vars.raw());
    for (int u = 0; u < info.u_size; u++) {
        int u_index = info.u_indices_real_vars[u];
        u_bounds[u].lb = data->modelData->realVarsData[u_index].attribute.min;
        u_bounds[u].ub = data->modelData->realVarsData[u_index].attribute.max;
    }

    /* constraint sizes */
    info.f_size = info.x_size;
    info.index_der_x_real_vars = info.x_size;
    info.g_size = data->modelData->nOptimizeConstraints;
    info.r_size = data->modelData->nOptimizeFinalConstraints; // TODO: add *generic boundary* constraints later also at t=t0

    short der_index_mayer_realVars = -1;
    short der_indices_lagrange_realVars[2] = {-1, -1};

    /* this is really ugly IMO, fix this when ready for master! */
    info.mayer_exists = (data->callback->mayer(data, &info.address_mayer_real_vars, &der_index_mayer_realVars) >= 0);
    if (info.mayer_exists) {
        info.index_mayer_real_vars = static_cast<int>(info.address_mayer_real_vars - data->localData[0]->realVars);
    }

    info.lagrange_exists = (data->callback->lagrange(data, &info.address_lagrange_real_vars, &der_indices_lagrange_realVars[0], &der_indices_lagrange_realVars[1]) >= 0);
    if (info.lagrange_exists) {
        info.index_lagrange_real_vars = static_cast<int>(info.address_lagrange_real_vars - data->localData[0]->realVars);
    }

    /* constraint bounds */
    FixedVector<Bounds> g_bounds(info.g_size);
    FixedVector<Bounds> r_bounds(info.r_size);

    info.index_g_real_vars = data->modelData->nVariablesReal - (info.g_size + info.r_size);
    info.index_r_real_vars = data->modelData->nVariablesReal - info.r_size;
    for (int g = 0; g < info.g_size; g++) {
        g_bounds[g].lb = data->modelData->realVarsData[info.index_g_real_vars + g].attribute.min;
        g_bounds[g].ub = data->modelData->realVarsData[info.index_g_real_vars + g].attribute.max;
    }

    for (int r = 0; r < info.r_size; r++) {
        r_bounds[r].lb = data->modelData->realVarsData[info.index_r_real_vars + r].attribute.min;
        r_bounds[r].ub = data->modelData->realVarsData[info.index_r_real_vars + r].attribute.max;
    }

    /* for now we ignore xf fixed (need some steps in Backend to detect)
     * and also ignore x0 non fixed, since too complicated
     * => assume x(t_0) = x0 fixed, x(t_f) free to r constraint / maybe the old BE can do that already?!
     * option: generate fixed final states individually */
    FixedVector<std::optional<f64>> x0_fixed(info.x_size);
    FixedVector<std::optional<f64>> xf_fixed(info.x_size);

    /* set *fixed* initial, final states */
    for (int x = 0; x < info.x_size; x++) {
        x0_fixed[x] = data->modelData->realVarsData[x].attribute.start;
    }

    /* create CSC <-> COO exchange, init jacobians */
    info.exc_jac = std::make_unique<ExchangeJacobians>(info);

    /* create HESSIAN_PATTERNs and allocate buffers for extrapolation / evaluation */
    info.exc_hes = std::make_unique<ExchangeHessians>(info);

    /* create blocks (contains sparse patterns and mapping to buffer indices) */
    GDOP::BoundarySweepLayout layout_mr(info.mayer_exists, info.r_size);
    GDOP::FullSweepLayout layout_lfg(info.lagrange_exists, info.f_size, info.g_size);

    /* fill layout_lfg and layout_mr objects with COO sparsity patterns */
    init_eval(info, layout_lfg, layout_mr);
    init_jac(info, layout_lfg, layout_mr);
    init_hes(info, layout_lfg, layout_mr);

    auto pc = std::make_unique<GDOP::ProblemConstants>(
        info.mayer_exists,
        info.lagrange_exists,
        std::move(x_bounds),
        std::move(u_bounds),
        std::move(p_bounds),
        std::move(x0_fixed),
        std::move(xf_fixed),
        std::move(r_bounds),
        std::move(g_bounds),
        mesh
    );

    auto fs  = std::make_unique<FullSweep>(std::move(layout_lfg), *pc, info);
    auto bs  = std::make_unique<BoundarySweep>(std::move(layout_mr), *pc, info);
    auto dyn = std::make_unique<Dynamics>(*pc, info);

    return GDOP::Problem(std::move(fs), std::move(bs), std::move(pc), std::move(dyn));
}

} // namespace OpenModelica
