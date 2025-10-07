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

#include <base/block_sparsity.h>

#include "hessian_finite_diff.h"

#include "evaluations.h"

namespace OpenModelica {

void init_eval(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr) {
    init_eval_lfg(info, layout_lfg);
    init_eval_mr(info, layout_mr);
}

/* just enumerate them in order: L -> f -> g. The correct placement will be handled in eval */
void init_eval_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg) {
    int buf_index = 0;

    if (layout_lfg.L) {
        layout_lfg.L->buf_index = buf_index++;
    }

    for (auto& f : layout_lfg.f) {
        f.buf_index = buf_index++;
    }

    for (auto& g : layout_lfg.g) {
        g.buf_index = buf_index++;
    }
}

/* just enumerate them in order: M -> r. The correct placement will be handled in eval */
void init_eval_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr) {
    int buf_index = 0;

    if (layout_mr.M) {
        layout_mr.M->buf_index = buf_index++;
    }

    for (auto& r : layout_mr.r) {
        r.buf_index = buf_index++;
    }
}

void init_jac(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr) {
    init_jac_lfg(info, layout_lfg);
    init_jac_mr(info, layout_mr);
}

// rows are sorted as fLg (as in OpenModelica)
void init_jac_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg) {
    /* full B Jacobian */
    for (int nz = 0; nz < info.exc_jac->B.sparsity.nnz; nz++) {
        int row = info.exc_jac->B.sparsity.row[nz];                       // OpenModelica B matrix row
        int col = info.exc_jac->B.sparsity.col[nz];                       // OpenModelica B matrix col
        int csc_buffer_entry_B = info.exc_jac->B.sparsity.coo_to_csc(nz); // OpenModelica B matrix CSC buffer index
        FunctionLFG& fn = access_fLg_from_row(layout_lfg, row);             // get function corresponding to the OM row
        if (col < info.x_size) {
            fn.jac.dx.push_back(JacobianSparsity{col, csc_buffer_entry_B});
        }
        else if (col < info.xu_size) {
            fn.jac.du.push_back(JacobianSparsity{col - info.x_size, csc_buffer_entry_B});
        }
        else {
            fn.jac.dp.push_back(JacobianSparsity{col - info.xu_size, csc_buffer_entry_B});
        }
    }
}

void init_jac_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr) {
    /* M (first row) in C(COO) Jacobian */
    int nz_C = 0;
    if (info.mayer_exists) {
        assert(layout_mr.M);

        while (info.exc_jac->C.sparsity.row[nz_C] == 0) {
            int col = info.exc_jac->C.sparsity.col[nz_C];

            /* for now only final states: xf! no parameters, no dx0 */
            if (col < info.x_size) {
                /* just point to nz_C, since for 1 row, CSC == COO */
                layout_mr.M->jac.dxf.push_back(JacobianSparsity{col, nz_C});
            }
            else if (col < info.xu_size) {
                /* just point to nz_C, since for 1 row, CSC == COO */
                layout_mr.M->jac.duf.push_back(JacobianSparsity{col - info.x_size, nz_C});
            }

            nz_C++;
        }
    }

    /* r in D Jacobian */
    for (int nz_D = 0; nz_D < info.exc_jac->D.sparsity.nnz; nz_D++) {
        int row = info.exc_jac->D.sparsity.row[nz_D];
        int col = info.exc_jac->D.sparsity.col[nz_D];
        int csc_buffer_entry_D = info.exc_jac->D.sparsity.coo_to_csc(nz_D); // jac_buffer == OpenModelica D CSC buffer!
        auto& fn = layout_mr.r[row];
        if (col < info.x_size) {
            /* add the Mayer offset, since the values f64* is [M, r] */
            // Attention: this offset only works if D contains just r!!
            fn.jac.dxf.push_back(JacobianSparsity{col, info.exc_jac->D.sparsity.nnz_offset + csc_buffer_entry_D});
        }
        else if (col < info.xu_size) {
            fn.jac.duf.push_back(JacobianSparsity{col - info.x_size, info.exc_jac->D.sparsity.nnz_offset + csc_buffer_entry_D});
        }
    }
}

void init_hes(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr) {
    init_hes_lfg(info, layout_lfg);
    init_hes_mr(info, layout_mr);
}

void init_hes_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg) {
    /* TODO: PARAMETERS include hes_lfg_pp and make it threaded (~numberThreads buffers with fancy pooling) */
    auto& hes = layout_lfg.hes;

    HESSIAN_PATTERN* hes_b = info.exc_hes->B.hessian;

    for (int lnz = 0; lnz < hes_b->lnnz; lnz++) {
        int row = hes_b->row[lnz];
        int col = hes_b->col[lnz];

        if (row < info.x_size && col < info.x_size) {
            hes.dx_dx.push_back({row, col, lnz});
        }
        else if (row >= info.x_size && col < info.x_size) {
            hes.du_dx.push_back({row - info.x_size, col, lnz});
        }
        else {
            hes.du_du.push_back({row - info.x_size, col - info.x_size, lnz});
        }
    }
}

void init_hes_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr) {
    auto& hes_mr = layout_mr.hes;

    HESSIAN_PATTERN* hes_c = info.exc_hes->C.hessian;
    HESSIAN_PATTERN* hes_d = info.exc_hes->D.hessian;

    OrderedIndexSet hessian_mr;
    std::vector<HessianSparsity> M_sparsities;
    std::vector<int> M_cols;
    if (info.mayer_exists) {
        assert(layout_mr.M);

        auto& mayer_term = *layout_mr.M;

        // ignore x0 and p for now
        for (auto& M_dxf : mayer_term.jac.dxf) M_cols.push_back(M_dxf.col);
        for (auto& M_duf : mayer_term.jac.duf) M_cols.push_back(info.x_size + M_duf.col);

        // estimate lower triangle sparsity pattern
        for (size_t i = 0; i < M_cols.size(); i++) {
            for (size_t j = 0; j <= i; j++) {
                M_sparsities.push_back({M_cols[i], M_cols[j], 0});
            }
        }
        hessian_mr.insert_sparsity(M_sparsities, 0, 0);
    }

    if (hes_d != nullptr) {
        for (int nz = 0; nz < hes_d->lnnz; nz++) {
            hessian_mr.set.insert({hes_d->row[nz], hes_d->col[nz]});
        }
    }

    // create sparsity pattern struct(H(M) + H(r))
    int lnz = 0;
    std::map<std::pair<int, int>, int> sparsity_to_lnz;
    for (auto pair : hessian_mr.set) {
        auto [row, col] = pair;
        sparsity_to_lnz[pair] = lnz;

        if (row < info.x_size && col < info.x_size) {
            hes_mr.dxf_dxf.push_back({row, col, lnz});
        }
        else if (row >= info.x_size && col < info.x_size) {
            hes_mr.duf_dxf.push_back({row - info.x_size, col, lnz});
        }
        else {
            hes_mr.duf_duf.push_back({row - info.x_size, col - info.x_size, lnz});
        }
        lnz++;
    }

    int c_index = 0;
    info.exc_hes->C_to_Mr_buffer = FixedVector<std::pair<int, int>>(info.mayer_exists ? M_sparsities.size() : 0);

    if (hes_c) {
        int hes_c_index = 0;
        for (const auto& mayer_hess : M_sparsities) {
            while (hes_c_index < hes_c->lnnz && 
                (hes_c->row[hes_c_index] < mayer_hess.row || 
                (hes_c->row[hes_c_index] == mayer_hess.row && hes_c->col[hes_c_index] < mayer_hess.col))) {
                hes_c_index++;
            }
            auto it = sparsity_to_lnz.find({mayer_hess.row, mayer_hess.col});
            if (it != sparsity_to_lnz.end()) {
                info.exc_hes->C_to_Mr_buffer[c_index++] = {hes_c_index, it->second};
                hes_c_index++;
            }
            else {
                Log::error("Hessian entry row = {}, col = {} from hes_d not found in pattern!", mayer_hess.row, mayer_hess.col);
                abort();
            }
        }
    }

    info.exc_hes->D_to_Mr_buffer = FixedVector<std::pair<int, int>>(hes_d ? hes_d->lnnz : 0);
    if (hes_d != nullptr) {
        for (int i = 0; i < hes_d->lnnz; i++) {
            int row = hes_d->row[i];
            int col = hes_d->col[i];
            auto it = sparsity_to_lnz.find({row, col});
            if (it != sparsity_to_lnz.end()) {
                info.exc_hes->D_to_Mr_buffer[i] = {i, it->second};
            } else {
                Log::error("Hessian entry row = {}, col = {} from hes_d not found in pattern!", row, col);
                abort();
            }
        }
    }
}

/* TODO: PARAMETERS add me */
void set_parameters(InfoGDOP& info, const f64* p) {
    return;
}

void set_states(InfoGDOP& info, const f64* x_ij) {
    std::memcpy(
        info.data->localData[0]->realVars + info.index_x_real_vars,
        x_ij,
        info.x_size * sizeof(f64)
    );
}

void set_inputs(InfoGDOP& info, const f64* u_ij) {
    for (int u = 0; u < info.u_size; u++) {
        info.data->localData[0]->realVars[info.u_indices_real_vars[u]] = u_ij[u];
    }
}

void set_states_inputs(InfoGDOP& info, const f64* xu_ij) {
    set_states(info, xu_ij);
    set_inputs(info, xu_ij + info.x_size);
}

void set_time(InfoGDOP& info, const f64 t_ij) {
    /* move time horizon to Modelica model time */
    info.data->localData[0]->timeValue = t_ij + info.model_start_time;
}

void eval_ode_write(InfoGDOP& info, f64* eval_ode_buffer) {
    /* f */
    for (int der_x = 0; der_x < info.f_size; der_x++) {
        eval_ode_buffer[der_x] = info.data->localData[0]->realVars[info.index_der_x_real_vars + der_x];
    }
}

void eval_lfg_write(InfoGDOP& info, f64* eval_lfg_buffer) {
    int nz = 0;
    /* L */
    if (info.lagrange_exists) {
        eval_lfg_buffer[nz++] = info.data->localData[0]->realVars[info.index_lagrange_real_vars];
    }
    /* f */
    for (int der_x = 0; der_x < info.f_size; der_x++) {
        eval_lfg_buffer[nz++] = info.data->localData[0]->realVars[info.index_der_x_real_vars + der_x];
    }
    /* g */
    for (int g = 0; g < info.g_size; g++) {
        eval_lfg_buffer[nz++] = info.data->localData[0]->realVars[info.index_g_real_vars + g];
    }
}

void eval_mr_write(InfoGDOP& info, f64* eval_mr_buffer) {
    int nz = 0;
    /* M */
    if (info.mayer_exists) {
        eval_mr_buffer[nz++] = info.data->localData[0]->realVars[info.index_mayer_real_vars];
    }
    /* r */
    for (int r = 0; r < info.r_size; r++) {
        eval_mr_buffer[nz++] = info.data->localData[0]->realVars[info.index_r_real_vars + r];
    }
}

void jac_eval_write_first_row_as_csc(InfoGDOP& info, JACOBIAN* jacobian, f64* full_buffer,
                                     f64* eval_jac_buffer, CscToCoo& exc) {
    assert(jacobian && jacobian->sparsePattern);
    evalJacobian(info.data, info.threadData, jacobian, NULL, full_buffer, FALSE);

    for (int nz = 0; nz < exc.nnz_moved_row; nz++) {
        eval_jac_buffer[nz] = full_buffer[exc.coo_to_csc(nz)];
    }
}

} // namespace OpenModelica
