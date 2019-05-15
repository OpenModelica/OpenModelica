#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#include <SimCoreFactory/ObjectFactory.h>
#include <Core/Solver/ISolver.h>

/*
Policy class to create solver settings object
*/
template <class CreationPolicy>
struct SolverSettingsOMCFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SolverSettingsOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {

        _solver_type_map = new type_map();
    }

    void loadGlobalSettings( shared_ptr<IGlobalSettings> global_settings)
    {

    }

  virtual ~SolverSettingsOMCFactory()
    {
       delete _solver_type_map;
       ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();

    }

  virtual shared_ptr<ISolverSettings> createSolverSettings(string solvername,shared_ptr<IGlobalSettings> globalSettings)
    {

        string solver_settings_key;
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
            solver_settings_key.assign("createCppDASSLSettings");
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
            solver_settings_key.assign("createEulerSettings");
        }
        else if(solvername.compare("rk12")==0)
        {
            fs::path rk12_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path rk12_name(RK12_LIB);
            rk12_path/=rk12_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(rk12_name.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RK12 solver library!");
            }
            solver_settings_key.assign("createRK12Settings");
        }
        else if(solvername.compare("peer")==0)
        {
            fs::path peer_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path peer_name(PEER_LIB);
            peer_path/=peer_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(peer_name.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Peer solver library!");
            }
            solver_settings_key.assign("createPeerSettings");
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
            solver_settings_key.assign("createRTRKSettings");
        }
        else if(solvername.compare("RTEuler")==0)
        {
            fs::path RTEuler_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path RTEuler_name(RTEULER_LIB);
            RTEuler_path/=RTEuler_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(RTEuler_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RTEuler solver library!");
            }
            solver_settings_key.assign("createRTEulerSettings");
        }

        else if(solvername.compare("idas")==0)
        {
            solver_settings_key.assign("extension_export_idas");
        }
        else if(solvername.compare("ida")==0)
        {
            fs::path ida_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path ida_name(IDA_LIB);
            ida_path/=ida_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(ida_name.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw std::runtime_error("Failed loading IDA solver library!");
            }
            solver_settings_key.assign("extension_export_ida");
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
            solver_settings_key.assign("extension_export_cvode");
        }
		else if((solvername.compare("arkode")==0))
        {
            fs::path arkode_path = ObjectFactory<CreationPolicy>::_library_path;
            fs::path arkode_name(ARKODE_LIB);
            arkode_path/=arkode_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(arkode_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading ARKode solver library!");
            }
            solver_settings_key.assign("extension_export_arkode");
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");


        string settings = solvername.append("Settings");
        std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >::iterator iter;
        std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >& factories(_solver_type_map->get());
        iter = factories.find(settings);
        if (iter ==factories.end())
        {
            std::string factoryStr = ""; std::cerr << "Available solverfactories:" << std::endl;
            for(std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >::iterator iter = factories.begin(); iter != factories.end(); iter++)
            {
                factoryStr += iter->first + " ";
            }

            throw ModelicaSimulationError(MODEL_FACTORY,"No such Solver " + solvername + ". Available solver factories:" + factoryStr );
        }
        shared_ptr<ISolverSettings> solver_settings  = shared_ptr<ISolverSettings>(iter->second.create(globalSettings.get()));


        return solver_settings;

    }
 private:
    type_map* _solver_type_map;

};
/** @} */ // end of simcorefactoriesPolicies
