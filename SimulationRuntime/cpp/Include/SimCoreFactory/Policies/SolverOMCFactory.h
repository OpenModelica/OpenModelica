#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

#include <SimCoreFactory/ObjectFactory.h>
#include <Core/Solver/ISolver.h>
#include <Core/SimulationSettings//ISettingsFactory.h>

/* use boost filesystem locally */
#include <boost/filesystem/operations.hpp>
#include <boost/filesystem/path.hpp>

namespace fs = boost::filesystem;

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
        if(solvername.compare("cppdassl")==0)
        {
            fs::path cppdassl_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path cppdassl_name(CPPDASSL_LIB);
            cppdassl_path/=cppdassl_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(cppdassl_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading CppDASSL solver library!");
            }

        }
        else if(solvername.compare("euler")==0)
        {
            fs::path euler_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path euler_name(EULER_LIB);
            euler_path/=euler_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(euler_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Euler solver library!");
            }

        }
        else if(solvername.compare("rk12")==0)
        {
           fs::path rk12_path = ObjectFactory<CreationPolicy>::_library_path;
           fs::path rk12_name(RK12_LIB);
           rk12_path/=rk12_name;
           std::cerr << rk12_path.string() << std::endl;
           LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(rk12_path.string(),*_solver_type_map);
           if (result != LOADER_SUCCESS)
           {
               throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RK12 solver library!");
           }
        }
        else if(solvername.compare("peer")==0)
        {
           fs::path peer_path = ObjectFactory<CreationPolicy>::_library_path;
           fs::path peer_name(PEER_LIB);
           peer_path/=peer_name;
           LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(peer_path.string(),*_solver_type_map);
           if (result != LOADER_SUCCESS)
           {
               throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Peer solver library!");
           }
        }
        else if(solvername.compare("rtrk")==0)
        {
           fs::path rtrk_path = ObjectFactory<CreationPolicy>::_library_path;
           fs::path rtrk_name(RTRK_LIB);
           rtrk_path/=rtrk_name;
           LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(rtrk_path.string(),*_solver_type_map);
           if (result != LOADER_SUCCESS)
           {
               throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RTRK solver library!");
           }
        }
        else if(solvername.compare("RTEuler")==0)
        {
           fs::path RTEuler_path = ObjectFactory<CreationPolicy>::_library_path;
           fs::path RTEuler_name(RTEULER_LIB);
           RTEuler_path/= RTEuler_name;
           LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(RTEuler_path.string(),*_solver_type_map);
           if (result != LOADER_SUCCESS)
           {
               throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RTEuler solver library!");
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
		else if((solvername.compare("arkode")==0))
        {
            fs::path arkode_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path arkode_name(ARKODE_LIB);
            arkode_path /= arkode_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(arkode_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading ARKode solver library!");
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
