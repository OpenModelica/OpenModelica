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
Policy class to create solver object
*/
template <class CreationPolicy>
struct SolverVxWorksFactory : public ObjectFactory<CreationPolicy>
{
public:
    SolverVxWorksFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    ~SolverVxWorksFactory()
    {
    }

    shared_ptr<ISettingsFactory> createSettingsFactory()
    {
        shared_ptr<ISettingsFactory> settings_factory = ObjectFactory<CreationPolicy>::_factory->LoadSettingsFactory();
        return settings_factory;
    }

    shared_ptr<ISolver> createSolver(IMixedSystem* system, string solver_name,
                                     shared_ptr<ISolverSettings> solver_settings)
    {
        string solver_key;
        if (solver_name.compare("Euler") == 0)
        {
            solver_key.assign("createEuler");
        }
        else if (solver_name.compare("RTEuler") == 0)
        {
            solver_key.assign("createRTEuler");
        }
        else if (solver_name.compare("RTRK") == 0)
        {
            solver_key.assign("createRTRK");
        }
        else if (solver_name.compare("Idas") == 0)
        {
            solver_key.assign("extension_export_idas");
        }
        else if (solver_name.compare("Ida") == 0)
        {
            solver_key.assign("extension_export_ida");
        }
        else if (solver_name.compare("CVode") == 0)
        {
            solver_key.assign("extension_export_cvode");
        }
        else
            throw std::invalid_argument("Selected Solver is not available");

        shared_ptr<ISolver> solver = ObjectFactory<CreationPolicy>::_factory->LoadSolver(
            system, solver_key, solver_settings);
        return solver;
    }
};

/** @} */ // end of simcorefactoriesPolicies
