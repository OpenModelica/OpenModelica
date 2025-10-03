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

#ifndef MOO_OM_EVALUATIONS_H
#define MOO_OM_EVALUATIONS_H

#include "simulation_data.h"
#include "../simulation/jacobian_util.h"

#include <nlp/instances/gdop/problem.h>

#include "info.h"

namespace OpenModelica {

// TODO: try to not call functionDAE that often. Maybe create a workspace buffer where we memcpy the realVars after evaluation
//       main advantage: no need to solve NLS several times!!
// => maybe allocate an additional buffer for the realVars + parameters and memcpy them inside the evaluation again

/* init evaluations */
void init_eval(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr);
void init_eval_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg);
void init_eval_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr);

/* init Jacobians  */
void init_jac(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr);
void init_jac_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg);
void init_jac_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr);

/* init Hessians */
void init_hes(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg, GDOP::BoundarySweepLayout& layout_mr);
void init_hes_lfg(InfoGDOP& info, GDOP::FullSweepLayout& layout_lfg);
void init_hes_mr(InfoGDOP& info, GDOP::BoundarySweepLayout& layout_mr);

/* set values in OM realVars array / time value */
void set_parameters(InfoGDOP& info, const f64* p);
void set_states(InfoGDOP& info, const f64* x_ij);
void set_inputs(InfoGDOP& info, const f64* u_ij);
void set_states_inputs(InfoGDOP& info, const f64* xu_ij);
void set_time(InfoGDOP& info, const f64 t_ij);

// === Simulation Utils (e.g. MOO internal RADAU routine) ===
inline void eval_current_point_ode(InfoGDOP& info) {
    info.data->callback->functionODE(info.data, info.threadData);
}

void eval_ode_write(InfoGDOP& info, f64* eval_ode_buffer);
inline void eval_write_ode_jacobian(InfoGDOP& info, f64* eval_ode_jac_buffer) {
    assert(info.exc_jac->A.jacobian && info.exc_jac->A.jacobian->sparsePattern);
    evalJacobian(info.data, info.threadData, info.exc_jac->A.jacobian, NULL, eval_ode_jac_buffer, FALSE);
}

// === Optimization Utils ===
inline void eval_current_point_dae(InfoGDOP& info) {
    info.data->callback->functionDAE(info.data, info.threadData);
}

/* write previous evaluation to buffer */
void eval_lfg_write(InfoGDOP& info, f64* eval_lfg_buffer);
void eval_mr_write(InfoGDOP& info, f64* eval_mr_buffer);

/* call evalJacobian and write to buffer in *CSC* form; just passes the current buffer with offset to OM Jacobian */
inline void jac_eval_write_as_csc(InfoGDOP& info, JACOBIAN* jacobian, f64* eval_jac_buffer) {
    assert(jacobian != NULL && jacobian->sparsePattern != NULL);
    evalJacobian(info.data, info.threadData, jacobian, NULL, eval_jac_buffer, FALSE);
}

/* eval full jacobian (full_buffer) but only fill eval_jac_buffer with elements of first, *moved* row in Exchange's COO structure
 * (see construction of CscToCoo structures for further info)
 * clearly order doesnt matter for one row; CSC == COO order for this row, but the entries in original CSC are
 * stored in CscToCoo.coo_to_csc(nz). */
void jac_eval_write_first_row_as_csc(InfoGDOP& info, JACOBIAN* jacobian, f64* full_buffer,
                                     f64* eval_jac_buffer, CscToCoo& exc);

} // namespace OpenModelica

#endif // MOO_OM_EVALUATIONS_H
