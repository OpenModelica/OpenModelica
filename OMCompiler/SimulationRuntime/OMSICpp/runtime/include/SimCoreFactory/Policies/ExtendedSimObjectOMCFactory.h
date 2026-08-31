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

#include <omsi.h>

/*
Policy class to create a OMC-,  Modelica- system or AlgLoopSolver
*/
template <class CreationPolicy>
struct ExtendedSimObjectOMCFactory : public ObjectFactory<CreationPolicy>
{
public:
    ExtendedSimObjectOMCFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
        _extended_simobject_type_map = new type_map();
#ifndef RUNTIME_STATIC_LINKING
        initializeLibraries(library_path, modelicasystem_path, config_path);
#endif
    }

    virtual ~ExtendedSimObjectOMCFactory()
    {
        delete _extended_simobject_type_map;
        ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();
    }

    virtual shared_ptr<ISimVars> createExtendedSimVars(omsi_t* omsu)
    {
        std::map<std::string, factory<ISimVars, omsi_t*>>::iterator simvars_iter;
        std::map<std::string, factory<ISimVars, omsi_t*>>& simvars_factory(_extended_simobject_type_map->get());
        simvars_iter = simvars_factory.find("ExtendedSimVars");
        if (simvars_iter == simvars_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No simvars found");
        }
        shared_ptr<ISimVars> simVars(simvars_iter->second.create(omsu));
        return simVars;
    }
   
   
    shared_ptr<IHistory> createMatFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>::iterator writer_iter;
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>& writer_factory(
            _extended_simobject_type_map->get());
        writer_iter = writer_factory.find("MatFileWriter");
        if (writer_iter == writer_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No MatfileWriter found");
        }
        shared_ptr<IHistory> writer(writer_iter->second.create(settings, dim));
        return writer;
    }

    shared_ptr<IHistory> createTextFileWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>::iterator writer_iter;
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>& writer_factory(
            _extended_simobject_type_map->get());
        writer_iter = writer_factory.find("TextFileWriter");
        if (writer_iter == writer_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No MatfileWriter found");
        }
        shared_ptr<IHistory> writer(writer_iter->second.create(settings, dim));
        return writer;
    }

    shared_ptr<IHistory> createBufferReaderWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>::iterator writer_iter;
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>& writer_factory(
            _extended_simobject_type_map->get());
        writer_iter = writer_factory.find("BufferReaderWriter");
        if (writer_iter == writer_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No MatfileWriter found");
        }
        shared_ptr<IHistory> writer(writer_iter->second.create(settings, dim));
        return writer;
    }

    shared_ptr<IHistory> createDefaultWriter(shared_ptr<IGlobalSettings> settings, size_t dim)
    {
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>::iterator writer_iter;
        std::map<std::string, factory<IHistory, shared_ptr<IGlobalSettings>, size_t>>& writer_factory(
            _extended_simobject_type_map->get());
        writer_iter = writer_factory.find("DefaultWriter");
        if (writer_iter == writer_factory.end())
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "No MatfileWriter found");
        }
        shared_ptr<IHistory> writer(writer_iter->second.create(settings, dim));
        return writer;
    }
    

protected:
    virtual void initializeLibraries(PATH library_path, PATH modelicasystem_path, PATH config_path)
    {
        fs::path systemfactory_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path system_name(SYSTEMBASE_LIB);
        systemfactory_path /= system_name;

        LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(
            systemfactory_path.string(), *_extended_simobject_type_map);
        if (result != LOADER_SUCCESS)
        {
            std::stringstream tmp;
            tmp << "Failed loading System library!" << std::endl << systemfactory_path.string();
            throw ModelicaSimulationError(MODEL_FACTORY, tmp.str());
        }


        fs::path dataexchange_path = ObjectFactory<CreationPolicy>::_library_path;
        fs::path dataexchange_name(DATAEXCHANGE_LIB);
        dataexchange_path /= dataexchange_name;

        result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(dataexchange_path.string(), *_extended_simobject_type_map);
        if (result != LOADER_SUCCESS)
        {
            throw ModelicaSimulationError(MODEL_FACTORY, "Failed loading Dataexchange library!");
        }
    }


    type_map* _extended_simobject_type_map;
};

/** @} */ // end of simcorefactoriesPolicies
