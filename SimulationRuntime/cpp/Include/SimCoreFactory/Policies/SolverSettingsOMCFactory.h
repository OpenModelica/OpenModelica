#pragma once

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
                throw std::runtime_error("Failed loading Euler solver library!");
            }
            solver_settings_key.assign("createEulerSettings");
        }
        else if(solvername.compare("idas")==0)
        {
            solver_settings_key.assign("extension_export_idas");
        }
        else if(solvername.compare("ida")==0)
        {
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
                throw std::runtime_error("Failed loading CVode solver library!");
            }
            solver_settings_key.assign("extension_export_cvode");
        }
        else
            throw std::invalid_argument("Selected Solver is not available");

      
        string settings = solvername.append("Settings");
        std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >::iterator iter;
        std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >& factories(_solver_type_map->get());
        iter = factories.find(settings);
        if (iter ==factories.end())
        {

            throw std::invalid_argument("No such Solver "+ solvername );
        }
        boost::shared_ptr<ISolverSettings> solver_settings  = boost::shared_ptr<ISolverSettings>(iter->second.create(globalSettings.get()));
    
     
        return solver_settings;

    }
 private:
    type_map* _solver_type_map;

};
