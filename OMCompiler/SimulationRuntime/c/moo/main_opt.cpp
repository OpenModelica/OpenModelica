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

#include <base/fLGR.h>
#include <base/log.h>
#include <base/timing.h>
#include <base/mesh.h>

#include <nlp/solvers/ipopt/solver.h>
#include <nlp/instances/gdop/orchestrator.h>

#include "../simulation/options.h"
#include "problem.h"
#include "strategies.h"
#include "streamlog.h"

#ifndef NO_INTERACTIVE_DEPENDENCY
    #include "simulation/socket.h"
    extern Socket sim_communication_port;
#endif

using namespace OpenModelica;

/* entry point to the optimization runtime from OpenModelica generated code
 * this contains the glue code between MOO and the simulation runtime */
extern "C"
int _main_OptimizationRuntime(int argc, char** argv, DATA* data, threadData_t* threadData) {
{
    ScopedTimer timer("Optimization Runtime");
    create_set_logger();
    auto info = InfoGDOP(data, threadData, argc, argv);
    auto nlp_solver_settings = NLP::NLPSolverSettings(argc, argv);
    info.set_omc_flags(nlp_solver_settings);
    nlp_solver_settings.print();

    auto mesh = Mesh::create_equidistant_fixed_stages(info.t0, info.tf, info.intervals, info.stages, MeshType::Physical);
    auto problem = create_gdop(info, *mesh);
    auto strategies = std::make_unique<GDOP::Strategies>(default_strategies(info, problem, false));
    auto gdop = GDOP::GDOP(problem);

    IpoptSolver::IpoptSolver ipopt_solver(gdop, nlp_solver_settings);

    auto orchestrator = GDOP::MeshRefinementOrchestrator(gdop, std::move(strategies), ipopt_solver);

    orchestrator.optimize();

    communicateStatus("Finished", 1, info.tf, 0.0);
}
    // TODO: if MOO VERBOSE
    // TimingTree::instance().print_tree_table();

#ifndef NO_INTERACTIVE_DEPENDENCY
    if(omc_flag[FLAG_PORT] /* should be the same as static sim_communication_port_open */)
    {
        sim_communication_port.close();
    }
#endif

    return 0;
}
