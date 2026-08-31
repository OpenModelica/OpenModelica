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

shared_ptr<INonLinSolverSettings> createNewtonSettings();
shared_ptr<INonLinSolverSettings> createKinsolSettings();
shared_ptr<INonLinearAlgLoopSolver> createNewtonSolver(shared_ptr<INonLinSolverSettings> solver_settings,
                                                       shared_ptr<INonLinearAlgLoop> algLoop);
shared_ptr<INonLinearAlgLoopSolver> createKinsolSolver(shared_ptr<INonLinSolverSettings> solver_settings,
                                                       shared_ptr<INonLinearAlgLoop> algLoop);

template <class CreationPolicy>
class StaticNonLinSolverOMCFactory : virtual public ObjectFactory<CreationPolicy>
{
public:
    StaticNonLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    };

    virtual ~StaticNonLinSolverOMCFactory()
    {
    };

    virtual shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string nonlin_solver)
    {
        string nonlin_solver_key;

        if (nonlin_solver.compare("newton") == 0)
        {
            shared_ptr<INonLinSolverSettings> settings = createNewtonSettings();
            return settings;
        }

#ifdef ENABLE_SUNDIALS_STATIC
      if(nonlin_solver.compare("kinsol")==0)
      {
          shared_ptr<INonLinSolverSettings> settings = createKinsolSettings();
          return settings;
      }
#endif //ENABLE_SUNDIALS_STATIC
        throw ModelicaSimulationError(MODEL_FACTORY, "Selected nonlin solver is not available");
        //return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(nonlin_solver);
    }

    virtual shared_ptr<INonLinearAlgLoopSolver> createNonLinSolver(string solver_name,
                                                                   shared_ptr<INonLinSolverSettings> solver_settings,
                                                                   shared_ptr<INonLinearAlgLoop> algLoop = shared_ptr<
                                                                       INonLinearAlgLoop>())
    {
        if (solver_name.compare("newton") == 0)
        {
            shared_ptr<INonLinearAlgLoopSolver> newton = createNewtonSolver(solver_settings, algLoop);
            return newton;
        }

#ifdef ENABLE_SUNDIALS_STATIC
      if(solver_name.compare("kinsol")==0)
      {
        shared_ptr<INonLinearAlgLoopSolver> kinsol = createKinsolSolver(solver_settings,algLoop);
        return kinsol;
      }
#endif //ENABLE_SUNDIALS_STATIC
        throw ModelicaSimulationError(MODEL_FACTORY, "Selected nonlin solver is not available");
    }
};

/** @} */ // end of simcorefactoriesPolicies
