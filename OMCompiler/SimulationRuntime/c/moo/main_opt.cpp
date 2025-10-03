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

#include <base/fLGR.h>
#include <base/log.h>
#include <base/mesh.h>

#include <nlp/solvers/ipopt/solver.h>
#include <nlp/instances/gdop/orchestrator.h>

#include "problem.h"
#include "strategies.h"
#include "streamlog.h"

using namespace OpenModelica;

/* entry point to the optimization runtime from OpenModelica generated code
 * this contains the glue code between MOO and the simulation runtime */
extern "C"
int _main_OptimizationRuntime(int argc, char** argv, DATA* data, threadData_t* threadData) {
    create_set_logger();
    auto info = InfoGDOP(data, threadData, argc, argv);
    auto nlp_solver_settings = NLP::NLPSolverSettings(argc, argv);
    info.set_omc_flags(nlp_solver_settings);
    nlp_solver_settings.print();

    auto mesh = Mesh::create_equidistant_fixed_stages(info.tf, info.intervals, info.stages);
    auto problem = create_gdop(info, *mesh);
    auto strategies = std::make_unique<GDOP::Strategies>(default_strategies(info, problem, false));
    auto gdop = GDOP::GDOP(problem);

    IpoptSolver::IpoptSolver ipopt_solver(gdop, nlp_solver_settings);

    auto orchestrator = GDOP::MeshRefinementOrchestrator(gdop, std::move(strategies), ipopt_solver);

    orchestrator.optimize();

    communicateStatus("Finished", 1, info.tf, 0.0);

    return 0;
}
