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

// TODO: maybe think about how we provide these configurations to the Strategy?
// Do we want to pass a grant SimulationInfo { num_steps, start_time, stop_time } ?
class Simulation : public GDOP::Simulation {
public:
    InfoGDOP& info;
    SOLVER_METHOD solver;

    Simulation(InfoGDOP& info, SOLVER_METHOD solver);

    std::unique_ptr<Trajectory> operator()(const ControlTrajectory& controls, int num_steps,
                                           f64 start_time, f64 stop_time, f64* x_start_values) override;
};

class SimulationStep : public GDOP::SimulationStep {
public:
    std::shared_ptr<Simulation> simulation;

    SimulationStep(std::shared_ptr<Simulation> simulation);

    std::unique_ptr<Trajectory> operator()(const ControlTrajectory& controls,
                                           f64 start_time, f64 stop_time, f64* x_start_values) override;
};

class MatEmitter : public GDOP::Emitter {
public:
    InfoGDOP& info;

    MatEmitter(InfoGDOP& info);

    int operator()(const Trajectory& trajectory) override;
};

class NominalScalingFactory : public GDOP::ScalingFactory {
public:
    InfoGDOP& info;

    NominalScalingFactory(InfoGDOP& info) : info{info} {}

    std::shared_ptr<NLP::Scaling> operator()(const GDOP::GDOP& gdop) override;
};

GDOP::Strategies default_strategies(InfoGDOP& info);

} // namespace OpenModelica

#endif // MOO_OM_STRATEGIES_H
