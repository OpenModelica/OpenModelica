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

/** @addtogroup solverKinsol
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <Solver/Kinsol/Kinsol.h>
#include <Solver/Kinsol/KinsolSettings.h>

using boost::extensions::factory;

#if defined(OMC_BUILD) && !defined(RUNTIME_STATIC_LINKING)
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<INonLinearAlgLoopSolver, INonLinSolverSettings*,shared_ptr<INonLinearAlgLoop> > > >()
    ["kinsol"].set<Kinsol>();
  types.get<std::map<std::string, factory<INonLinSolverSettings> > >()
    ["kinsolSettings"].set<KinsolSettings>();
}
#elif defined(OMC_BUILD) && defined(RUNTIME_STATIC_LINKING)
  // Nothing
#else
error "operating system not supported"
#endif

#if defined(OMC_BUILD)  && defined(RUNTIME_STATIC_LINKING)
  #if defined(ENABLE_SUNDIALS_STATIC)
   shared_ptr<INonLinSolverSettings> createKinsolSettings()
   {
       shared_ptr<INonLinSolverSettings> settings = shared_ptr<INonLinSolverSettings>(new KinsolSettings());
        return settings;
   }
    shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
   {
       shared_ptr<INonLinearAlgLoopSolver> solver = shared_ptr<INonLinearAlgLoopSolver>(new Kinsol(solver_settings.get(),algLoop));
          return solver;
   }
  #else
   shared_ptr<INonLinSolverSettings> createKinsolSettings()
   {
     throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
   }
   shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,shared_ptr<INonLinearAlgLoop> algLoop)
   {
     throw ModelicaSimulationError(ALGLOOP_SOLVER,"Kinsol was disabled during build");
   }
  #endif //ENABLE_SUNDIALS_STATIC
#endif
/** @} */ // end of solverKinsol
