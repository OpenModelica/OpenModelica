/*
 * This file belongs to the OpenModelica Run-Time System
 *
 * Copyright (c) 1998-2026, Open Source Modelica Consortium (OSMC), c/o Linköpings
 * universitet, Department of Computer and Information Science, SE-58183 Linköping, Sweden. All rights
 * reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THE BSD NEW LICENSE OR THE
 * AGPL VERSION 3 LICENSE OR THE OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.8. ANY
 * USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S
 * ACCEPTANCE OF THE BSD NEW LICENSE OR THE OSMC PUBLIC LICENSE OR THE AGPL
 * VERSION 3, ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the OSMC (Open Source Modelica Consortium) Public License
 * (OSMC-PL) are obtained from OSMC, either from the above address, from the URLs:
 * http://www.openmodelica.org or https://github.com/OpenModelica/ or
 * http://www.ida.liu.se/projects/OpenModelica, and in the OpenModelica distribution. GNU
 * AGPL version 3 is obtained from: https://www.gnu.org/licenses/licenses.html#GPL. The BSD NEW
 * License is obtained from: http://www.opensource.org/licenses/BSD-3-Clause.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY
 * SET FORTH IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF
 * OSMC-PL.
 *
 */

#ifndef MOO_OM_STRATEGIES_H
#define MOO_OM_STRATEGIES_H

#include "simulation/simulation_runtime.h"

#include <nlp/instances/gdop/gdop.h>

#include "info.h"

namespace OpenModelica {

struct AuxiliaryTrajectory {
    Trajectory& trajectory;
    InfoGDOP& info;
    SOLVER_INFO* solver_info;
};

struct AuxiliaryControls {
    const ControlTrajectory& controls;
    InfoGDOP& info;
    FixedVector<f64> u_interpolation;
};

void initialize_model(InfoGDOP& info);

class ConstantInitialization : public GDOP::Initialization {
public:
    InfoGDOP& info;
    ConstantInitialization(InfoGDOP& info);

    std::unique_ptr<PrimalDualTrajectory> operator()(const GDOP::GDOP& gdop) override;
};

class Simulation : public GDOP::Simulation {
public:
    InfoGDOP& info;
    SOLVER_METHOD solver;

    Simulation(InfoGDOP& info, SOLVER_METHOD solver);

    std::unique_ptr<Trajectory> operator()(const ControlTrajectory& controls, const FixedVector<f64>& parameters,
                                           int num_steps, f64 start_time, f64 stop_time, f64* x_start_values) override;
};

// TODO: OpenModelica::SimulationStep should not hold a simulation, but rather allocate all the structures in activate
//       and deallocate them in reset, so we have minimal overhead (like solver_main())
class SimulationStep : public GDOP::SimulationStep {
public:
    std::shared_ptr<Simulation> simulation;

    SimulationStep(std::shared_ptr<Simulation> simulation);

    void activate(const ControlTrajectory& controls_, const FixedVector<f64>& parameters_) override;
    void reset() override;

    std::unique_ptr<Trajectory> operator()(f64* x_start_values, f64 start_time, f64 stop_time) override;

private:
    const ControlTrajectory* controls;
    const FixedVector<f64>* parameters;
};

class MatEmitter : public GDOP::Emitter {
public:
    InfoGDOP& info;

    MatEmitter(InfoGDOP& info);

    int operator()(const PrimalDualTrajectory& trajectory) override;
};

class NominalScalingFactory : public GDOP::ScalingFactory {
public:
    InfoGDOP& info;

    NominalScalingFactory(InfoGDOP& info) : info{info} {}

    std::shared_ptr<NLP::Scaling> operator()(const GDOP::GDOP& gdop) override;
};

GDOP::Strategies default_strategies(InfoGDOP& info, GDOP::Problem& problem, bool use_moo_simulation);

} // namespace OpenModelica

#endif // MOO_OM_STRATEGIES_H
