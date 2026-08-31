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
/*
Policy class to create nonlin solver object
*/
template <class CreationPolicy>
struct NonLinSolverVxWorksFactory : virtual public ObjectFactory<CreationPolicy>
{
public:
    NonLinSolverVxWorksFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
          , _last_selected_solver("empty")
    {
    }

    ~NonLinSolverVxWorksFactory()
    {
    }

    shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string solver_name)
    {
        string nonlin_solver_key;
        string nonlin_solver;
        if (solver_name.compare("newton") == 0)
            nonlin_solver_key.assign("createNewtonSettings");
        else if (solver_name.compare("broyden") == 0)
            nonlin_solver_key.assign("createBroydenSettings");
        else if (solver_name.compare("kinsol") == 0)
            nonlin_solver_key.assign("createKinsolSettings");
        else if (solver_name.compare("Hybrj") == 0)
            nonlin_solver_key.assign("extension_export_hybrj");
        else
            throw std::invalid_argument("Selected nonlinear solver is not available");
        _last_selected_solver = solver_name;
        shared_ptr<INonLinSolverSettings> nonlinsolversetting = ObjectFactory<CreationPolicy>::_factory->
            LoadAlgLoopSolverSettings(nonlin_solver_key);
        return nonlinsolversetting;
    }

    shared_ptr<IAlgLoopSolver> createNonLinSolver(INonLinearAlgLoop* algLoop, string solver_name,
                                                  shared_ptr<INonLinSolverSettings> solver_settings)
    {
        if (_last_selected_solver.compare(solver_name) == 0)
        {
            string nonlin_solver_key;
            if (solver_name.compare("newton") == 0)
                nonlin_solver_key.assign("createNewton");
            if (solver_name.compare("broyden") == 0)
                nonlin_solver_key.assign("createBroyden");
            else if (solver_name.compare("kinsol") == 0)
                nonlin_solver_key.assign("createKinsol");
            else if (solver_name.compare("Hybrj") == 0)
                nonlin_solver_key.assign("extension_export_hybrj");
            else
                throw std::invalid_argument("Selected nonlinear solver is not available");
            shared_ptr<IAlgLoopSolver> nonlinsolver = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolver(
                algLoop, nonlin_solver_key, solver_settings);
            return nonlinsolver;
        }
        else
            throw std::invalid_argument("Selected nonlinear solver is not available");
    }

    string _last_selected_solver;
};

/** @} */ // end of simcorefactoriesPolicies
