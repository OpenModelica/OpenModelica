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

/** @addtogroup coreSimcontroller
 *
 *  @{
 */
#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/System/FactoryExport.h>
#include <Core/System/SimObjects.h>


SimObjects::SimObjects(PATH library_path, PATH modelicasystem_path, shared_ptr<IGlobalSettings> globalSettings)
    : SimObjectPolicy(library_path, modelicasystem_path, library_path)
      , _globalSettings(globalSettings)
{
    _algloopsolverfactory = createAlgLoopSolverFactory(globalSettings);
}

SimObjects::SimObjects(SimObjects& instance) : SimObjectPolicy(instance)
{
   

    //clone sim_vars
    for (std::map<string, shared_ptr<ISimVars>>::iterator it = instance._sim_vars.begin(); it != instance
                                                                                                 ._sim_vars.end(); it++)
        _sim_vars.insert(pair<string, shared_ptr<ISimVars>>(it->first, shared_ptr<ISimVars>(it->second->clone())));

    _algloopsolverfactory = instance.getAlgLoopSolverFactory();
    _globalSettings = instance.getGlobalSettings();
  
}

SimObjects::~SimObjects()
{
}



weak_ptr<ISimVars> SimObjects::LoadSimVars(string modelKey, size_t dim_real, size_t dim_int, size_t dim_bool,
                                           size_t dim_string, size_t dim_pre_vars, size_t dim_z, size_t z_i)
{
    //if the simdata is already loaded
    std::map<string, shared_ptr<ISimVars>>::iterator iter = _sim_vars.find(modelKey);
    if (iter != _sim_vars.end())
    {
        //destroy system
        _sim_vars.erase(iter);
    }
    //create system
    shared_ptr<ISimVars> sim_vars = createSimVars(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i);
    _sim_vars[modelKey] = sim_vars;
    return sim_vars;
}


shared_ptr<ISimVars> SimObjects::getSimVars(string modelname)
{
    std::map<string, shared_ptr<ISimVars>>::iterator iter = _sim_vars.find(modelname);
    if (iter != _sim_vars.end())
    {
        return iter->second;
    }
    else
    {
        string error = string("Simulation data was not found for model: ") + modelname;
        throw ModelicaSimulationError(SIMMANAGER, error);
    }
}



void SimObjects::eraseSimVars(string modelname)
{
    // destroy simdata
    std::map<string, shared_ptr<ISimVars>>::iterator iter = _sim_vars.find(modelname);
    if (iter != _sim_vars.end())
    {
        _sim_vars.erase(iter);
    }
}

shared_ptr<IAlgLoopSolverFactory> SimObjects::getAlgLoopSolverFactory()
{
    return _algloopsolverfactory;
}



ISimObjects* SimObjects::clone()
{
    return new SimObjects(*this);
}

shared_ptr<IGlobalSettings> SimObjects::getGlobalSettings()
{
    return _globalSettings;
}



/** @} */ // end of coreSimcontroller
