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

    void loadGlobalSettings( boost::shared_ptr<IGlobalSettings> global_settings)
    {

    }

  virtual ~SolverSettingsOMCFactory()
    {
       delete _solver_type_map;
       ObjectFactory<CreationPolicy>::_factory->UnloadAllLibs();

    }

  virtual boost::shared_ptr<ISolverSettings> createSolverSettings(string solvername,boost::shared_ptr<IGlobalSettings> globalSettings)
    {

        string solver_settings_key;
        if(solvername.compare("euler")==0)
        {
             PATH euler_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH euler_name(EULER_LIB);
            euler_path/=euler_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(euler_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading Euler solver library!");
            }
            solver_settings_key.assign("createEulerSettings");
        }
        else if(solvername.compare("peer")==0)
        {
            PATH peer_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH peer_name(PEER_LIB);
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
            PATH rtrk_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH rtrk_name(RTRK_LIB);
            rtrk_path/=rtrk_name;
            LOADERRESULT result = ObjectFactory<CreationPolicy>::_factory->LoadLibrary(rtrk_path.string(),*_solver_type_map);
            if (result != LOADER_SUCCESS)
            {
                throw ModelicaSimulationError(MODEL_FACTORY,"Failed loading RTRK solver library!");
            }
            solver_settings_key.assign("createRTRKSettings");
        }
        else if(solvername.compare("idas")==0)
        {
            solver_settings_key.assign("extension_export_idas");
        }
        else if(solvername.compare("ida")==0)
        {
            PATH ida_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH ida_name(IDA_LIB);
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
      PATH cvode_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH cvode_name(CVODE_LIB);
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
            PATH arkode_path = ObjectFactory<CreationPolicy>::_library_path;
            PATH arkode_name(ARKODE_LIB);
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
        boost::shared_ptr<ISolverSettings> solver_settings  = boost::shared_ptr<ISolverSettings>(iter->second.create(globalSettings.get()));


        return solver_settings;

    }
 private:
    type_map* _solver_type_map;

};
/** @} */ // end of simcorefactoriesPolicies