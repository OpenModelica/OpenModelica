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
struct SystemOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    SystemOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _use_modelica_compiler = false;
        _system_type_map = new type_map();
#ifndef RUNTIME_STATIC_LINKING
        initializeLibraries(library_path, modelicasystem_path, config_path);
#endif
    }

    virtual ~SystemOMCFactory()
    {
        delete _system_type_map;
        ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
    }

    virtual shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(shared_ptr<IGlobalSettings> globalSettings)
    {
        std::map<std::string, factory<IAlgLoopSolverFactory, shared_ptr<IGlobalSettings>, PATH, PATH>>::iterator iter;
        std::map<std::string, factory<IAlgLoopSolverFactory, shared_ptr<IGlobalSettings>, PATH, PATH>>&
            algloopsolver_factory(_system_type_map->get());
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


    virtual shared_ptr<IMixedSystem> createOSUSystem(string osu_name, shared_ptr<IGlobalSettings> globalSettings)
    {
        std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>, string>>::iterator system_iter;
        std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>, string>>& factories(
            _system_type_map->get());
        system_iter = factories.find("OMSUSystem");
        if (system_iter == factories.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No omsi system found");
        }

        shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings, osu_name));
        return system;
    }


    virtual shared_ptr<IMixedSystem> createSystem(string modelLib, string modelKey,
                                                  shared_ptr<IGlobalSettings> globalSettings)
    {
        fs::path modelica_path = ObjectFactory<CreationPolicy>::_modelicasystem_path;
        fs::path modelica_name(modelLib);
        modelica_path /= modelica_name;
        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            modelica_path.string(), *_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading System library!" << std::endl << modelica_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }

        std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>>>::iterator system_iter;
        std::map<std::string, factory<IMixedSystem, shared_ptr<IGlobalSettings>>>& factories(_system_type_map->get());
        system_iter = factories.find(modelKey);
        if (system_iter == factories.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No system found");
        }

        shared_ptr<IMixedSystem> system(system_iter->second.create(globalSettings));
        return system;
    }

    shared_ptr<IMixedSystem> createModelicaSystem(PATH modelica_path, string modelKey,
                                                  shared_ptr<IGlobalSettings> globalSettings)
    {
        throw ModelicaSimulationError(MODEL_FACTORY, "Modelica is not supported");
    }

protected:
    virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_path)
    {
        fs::path systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path system_name(SYSTEMBASE_LIB);
        systemfactory_path /= system_name;

        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            systemfactory_path.string(), *_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }

        fs::path extendedystemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path extendedsystem_name(EXTENDEDSYSTEM_LIB);
        extendedystemfactory_path /= extendedsystem_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            extendedystemfactory_path.string(), *_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading extended system library!" << std::endl << extendedystemfactory_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }


        fs::path omsisystemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path omsisystem_name(SYSTEMOMSI_LIB);
        omsisystemfactory_path /= omsisystem_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            omsisystemfactory_path.string(), *_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading omsi system library!" << std::endl << omsisystemfactory_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }

        fs::path dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path dataexchange_name(DATAEXCHANGE_LIB);
        dataexchange_path /= dataexchange_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(), *_system_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading Dataexchange library!");
        }
    }

    bool _use_modelica_compiler;
    type_map* _system_type_map;
};

/** @} */ // end of simcorefactoriesPolicies
