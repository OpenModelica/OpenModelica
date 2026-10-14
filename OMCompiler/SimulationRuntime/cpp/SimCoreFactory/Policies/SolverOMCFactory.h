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
#include <Core/Solver/ISolver.h>
#include <Core/SimulationSettings//ISettingsFactory.h>

#include <filesystem>

namespace fs = std::filesystem;

/*
Policy class to create solver object
*/
template <class CreationPolicy>
struct SolverOMCFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
         _solver_type_map = new type_map();
         _settings_type_map = new type_map();
#ifndef RUNTIME_STATIC_LINKING
         initializeLibraries(library_path,modelicasystem_path,config_path);
#endif
    }

    virtual ~SolverOMCFactory()
    {
       delete _solver_type_map;
       delete _settings_type_map;
       ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();

    }

    virtual shared_ptr<ISettingsFactory> createSettingsFactory()
    {
          std::map<std::string, factory<ISettingsFactory,PATH,PATH,PATH> >::iterator iter;
          std::map<std::string, factory<ISettingsFactory,PATH,PATH,PATH> >& factories(_settings_type_map->get());
          iter = factories.find("SettingsFactory");
          if (iter ==factories.end())
          {
                throw ModelicaSimulationError(MODEL_FACTORY,"No such settings library");
            }
         shared_ptr<ISettingsFactory>  settings_factory = shared_ptr<ISettingsFactory>(iter->second.create(ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path,ObjectFactory<CreationPolicy>::_config_path));

         return settings_factory;
    }

    virtual shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername, shared_ptr<ISolverSettings> solver_settings)
    {
        if (solvername.compare("dassl") == 0)
        {
            fs::path dassl_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path dassl_name(DASSL_LIB);
            dassl_path /= dassl_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dassl_path.string(), *_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading DASSL solver library!");
            }
        }
        else if(solvername.compare("idas")==0)
        {

        }
        else if(solvername.compare("ida")==0)
        {
            solvername = "ida"; //workound for dassl, using cvode instead
            fs::path ida_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path ida_name(IDA_LIB);
            ida_path/=ida_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(ida_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw std::runtime_error("Failed loading IDA solver library!");
            }
        }
        else if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
            solvername = "cvode"; //workound for dassl, using cvode instead
            fs::path cvode_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path cvode_name(CVODE_LIB);
            cvode_path/=cvode_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(cvode_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading CVode solver library!");
            }
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");

        std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> >::iterator iter;
        std::map<std::string, factory<ISolver,IMixedSystem*, ISolverSettings*> >& factories(_solver_type_map->get());
        string solver_key = solvername.append("Solver");
       iter = factories.find(solver_key);
        if (iter ==factories.end())
        {
                throw ModelicaSimulationError(MODEL_FACTORY,"No such Solver " + solver_key);
        }

        shared_ptr<ISolver> solver = shared_ptr<ISolver>(iter->second.create(system,solver_settings.get()));

        return solver;
    }
protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_path)
    {

        LOADERRESULT result;

        fs::path math_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path math_name(MATH_LIB);
        math_path/=math_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(math_path.string(),*_settings_type_map);

        if (result != LOADER_SUCCESS)
        {

            throw ModelicaSimulationError(MODEL_FACTORY,string("Failed loading Math library: ") + math_path.string());
        }



        fs::path settingsfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path settingsfactory_name(SETTINGSFACTORY_LIB);
        settingsfactory_path/=settingsfactory_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(settingsfactory_path.string(),*_settings_type_map);

        if (result != LOADER_SUCCESS)
        {

            throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading SimulationSettings library!");
        }

        fs::path solver_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path solver_name(SOLVER_LIB);
        solver_path/=solver_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(solver_path.string(),*_solver_type_map);

        if (result != LOADER_SUCCESS)
        {
            throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Solver default implementation library!");
        }
    }

    type_map* _solver_type_map;
    type_map* _settings_type_map;
};
/** @} */ // end of simcorefactoriesPolicies
