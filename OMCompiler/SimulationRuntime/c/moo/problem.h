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

#ifndef MOO_OM_GDOP_PROBLEM_H
#define MOO_OM_GDOP_PROBLEM_H

#include <nlp/instances/gdop/problem.h>

#include "info.h"

namespace OpenModelica {

class FullSweep : public GDOP::FullSweep {
public:
    InfoGDOP& info;

    FullSweep(GDOP::FullSweepLayout&& lfg_in,
              const GDOP::ProblemConstants& pc,
              InfoGDOP& info);

    void callback_eval(const f64* xu_nlp, const f64* p) override;
    void callback_jac(const f64* xu_nlp, const f64* p) override;
    void callback_hes(const f64* xu_nlp, const f64* p, const FixedField<f64, 2>& lagrange_factors, const f64* lambda) override;
};

class BoundarySweep : public GDOP::BoundarySweep {
public:
    InfoGDOP& info;

    BoundarySweep(GDOP::BoundarySweepLayout&& mr_in,
                  const GDOP::ProblemConstants& pc,
                  InfoGDOP& info);

    void callback_eval(const f64* x0_nlp, const f64* xuf_nlp, const f64* p) override;
    void callback_jac(const f64* x0_nlp, const f64* xuf_nlp, const f64* p) override;
    void callback_hes(const f64* x0_nlp, const f64* xuf_nlp, const f64* p, const f64 mayer_factor, const f64* lambda) override;
};

class Dynamics : public GDOP::Dynamics {
public:
    InfoGDOP& info;

    Dynamics(const GDOP::ProblemConstants& pc_in, InfoGDOP& info);

    void allocate() override;
    void free() override;

    void eval(const f64* x, const f64* u, const f64* p, f64 t, f64* f, void* user_data) override;
    void jac(const f64* x, const f64* u, const f64* p, f64 t, f64* dfdx, void* user_data) override;

private:
    bool allocated_ode_matrix = false;
};

GDOP::Problem create_gdop(InfoGDOP& info, const Mesh& mesh);

} // namespace OpenModelica

#endif // MOO_OM_GDOP_PROBLEM_H
