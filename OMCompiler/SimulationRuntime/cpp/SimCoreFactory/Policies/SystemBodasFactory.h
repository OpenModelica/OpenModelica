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
Policy class to create a Simster-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SystemBodasFactory : public ObjectFactory<CreationPolicy>
{
public:
    SystemBodasFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _use_modelica_compiler = false;
    }

    ~SystemBodasFactory()
    {
    }

    shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings)
    {
        shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverFactory(globalSettings);
        return algloopsolverfactory;
    }

    shared_ptr<ISimData> createSimData()
    {
        shared_ptr<ISimData> simData = ObjectFactory<CreationPolicy>::_factory->LoadSimData();
        return simData;
    }

    shared_ptr<IMixedSystem> createSystem(string modelLib, string modelKey, IGlobalSettings* globalSettings,shared_ptr<ISimObjects> simObjects)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings,simObjects);
        return system;
    }

    shared_ptr<IMixedSystem> createModelicaSystem(string modelLib, string modelKey, IGlobalSettings* globalSettings,shared_ptr<ISimObjects> simObjects)
    {
        shared_ptr<IMixedSystem> system = ObjectFactory<CreationPolicy>::_factory->LoadSystem(globalSettings, simObjects);
        return system;
    }

    bool _use_modelica_compiler;
};
/** @} */ // end of simcorefactoriesPolicies