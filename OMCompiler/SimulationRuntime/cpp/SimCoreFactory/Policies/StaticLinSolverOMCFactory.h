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

#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>
shared_ptr<ILinSolverSettings> createLinearSolverSettings();
shared_ptr<ILinearAlgLoopSolver> createLinearSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>());
shared_ptr<ILinSolverSettings> createDgesvSolverSettings();
shared_ptr<ILinearAlgLoopSolver> createDgesvSolver(shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>());
template<class CreationPolicy>
struct StaticLinSolverOMCFactory : virtual public ObjectFactory<CreationPolicy>{

public:
  StaticLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path,PATH config_path)
    : ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
  {
  }

  virtual ~StaticLinSolverOMCFactory() {}

  virtual shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
  {
     if (lin_solver.compare("linearSolver") == 0)
     {
       throw ModelicaSimulationError(MODEL_FACTORY, "Selected lin solver is not supported for static Linking. Use dgesvSolver instead.");
     }
     else if (lin_solver.compare("dgesvSolver") == 0)
     {
       shared_ptr<ILinSolverSettings> settings = createDgesvSolverSettings();
       return settings;
     }
     else
       throw ModelicaSimulationError(MODEL_FACTORY, "Selected lin solver is not available");
  }

  virtual shared_ptr<ILinearAlgLoopSolver> createLinSolver(string solver_name, shared_ptr<ILinSolverSettings> solver_settings,shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>())
  {
    if (solver_name.compare("linearSolver") == 0)
    {
      throw ModelicaSimulationError(MODEL_FACTORY, "Selected lin solver is not supported for static Linking. Use dgesvSolver instead.");
    }
    else if (solver_name.compare("dgesvSolver") == 0)
    {
      shared_ptr<ILinearAlgLoopSolver> solver = createDgesvSolver(solver_settings, algLoop);
      return solver;
    }
    else
      throw ModelicaSimulationError(MODEL_FACTORY, "Selected lin solver is not available");
  }
};

/** @} */ // end of simcorefactoriesPolicies
