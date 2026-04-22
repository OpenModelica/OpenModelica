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

/** @addtogroup solverNewton
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)

#include <Solver/Dgesv/DgesvSolver.h>
#include <Solver/Dgesv/DgesvSolverSettings.h>

/* OMC factory */
using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
types.get<std::map<std::string, factory<ILinearAlgLoopSolver,ILinSolverSettings*,shared_ptr<ILinearAlgLoop> > > >()
    ["dgesvSolver"].set<DgesvSolver>();
types.get<std::map<std::string, factory<ILinSolverSettings> > >()
    ["dgesvSolverSettings"].set<DgesvSolverSettings>();
}

#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
#include <Solver/Dgesv/DgesvSolver.h>
#include <Solver/Dgesv/DgesvSolverSettings.h>
shared_ptr<ILinSolverSettings> createDgesvSolverSettings()
   {
       shared_ptr<ILinSolverSettings> settings = shared_ptr<ILinSolverSettings>(new DgesvSolverSettings());
        return settings;
   }
shared_ptr<ILinearAlgLoopSolver> createDgesvSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop)
{
  shared_ptr<ILinearAlgLoopSolver> solver = shared_ptr<ILinearAlgLoopSolver>(new DgesvSolver(solver_settings.get(),algLoop));
  return solver;
}

#else
  error "operating system not supported"
#endif
