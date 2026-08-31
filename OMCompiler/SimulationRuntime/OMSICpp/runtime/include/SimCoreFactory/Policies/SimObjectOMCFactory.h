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
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct SimObjectOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    SimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _simobject_type_map = new type_map();
#ifndef RUNTIME_STATIC_LINKING
        initializeLibraries(library_path, modelicasystem_path, config_path);
#endif
    }

    virtual ~SimObjectOMCFactory()
    {
        delete _simobject_type_map;
        ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
    }

    virtual shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
    {
        std::map<std::string, factory<IAlgLoopSolverFactory, shared_ptr<IGlobalSettings>, PATH, PATH>>::iterator iter;
        std::map<std::string, factory<IAlgLoopSolverFactory, shared_ptr<IGlobalSettings>, PATH, PATH>>&
            algloopsolver_factory(_simobject_type_map->get());
        iter = algloopsolver_factory.find("AlgLoopSolverFactory");
        if (iter == algloopsolver_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No AlgLoopSolverFactory  found");
        }
        shared_ptr<IAlgLoopSolverFactory> algloopsolverfactory = shared_ptr<IAlgLoopSolverFactory>(
            iter->second.create(globalSettings, ObjectFactory<CreationPolicy>::_library_path,
                                ObjectFactory<CreationPolicy>::_modelicasystem_path));

        return algloopsolverfactory;
    }

    virtual shared_ptr<ISimData> createSimData()
    {
        std::map<std::string, factory<ISimData>>::iterator simdata_iter;
        std::map<std::string, factory<ISimData>>& simdata_factory(_simobject_type_map->get());
        simdata_iter = simdata_factory.find("SimData");
        if (simdata_iter == simdata_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No simdata found");
        }
        shared_ptr<ISimData> simData(simdata_iter->second.create());
        return simData;
    }

    virtual shared_ptr<ISimVars> createSimVars(size_t dim_real, size_t dim_int, size_t dim_bool, size_t dim_string,
                                               size_t dim_pre_vars, size_t dim_z, size_t z_i)
    {
        std::map<std::string, factory<ISimVars, size_t, size_t, size_t, size_t, size_t, size_t, size_t>>::iterator
            simvars_iter;
        std::map<std::string, factory<ISimVars, size_t, size_t, size_t, size_t, size_t, size_t, size_t>>&
            simvars_factory(_simobject_type_map->get());
        simvars_iter = simvars_factory.find("SimVars");
        if (simvars_iter == simvars_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No simvars found");
        }
        shared_ptr<ISimVars> simVars(
            simvars_iter->second.create(dim_real, dim_int, dim_bool, dim_string, dim_pre_vars, dim_z, z_i));
        return simVars;
    }
    
       



protected:
    virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_path)
    {
        fs::path systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path system_name(SYSTEMBASE_LIB);
        systemfactory_path /= system_name;

        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            systemfactory_path.string(), *_simobject_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }


        fs::path dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path dataexchange_name(DATAEXCHANGE_LIB);
        dataexchange_path /= dataexchange_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(), *_simobject_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading Dataexchange library!");
        }
    }


    type_map* _simobject_type_map;
};

/** @} */ // end of simcorefactoriesPolicies
