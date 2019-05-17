#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
/*
Policy class to create solver settings object
*/
template <class CreationPolicy>
struct SolverSettingsVxWorksFactory : public  ObjectFactory<CreationPolicy>
{

public:
    SolverSettingsVxWorksFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }

    void loadGlobalSettings( shared_ptr<IGlobalSettings> global_settings)
    {

    }
    ~SolverSettingsVxWorksFactory()
    {
    }
    shared_ptr<ISolverSettings> createSolverSettings(string solvername,shared_ptr<IGlobalSettings> globalSettings)
    {

        string solver_settings_key;
        if(solvername.compare("Euler")==0)
        {
            solver_settings_key.assign("createEulerSettings");
        }
      else if(solvername.compare("RTEuler")==0)
        {
            solver_settings_key.assign("createRTEulerSettings");
        }
        else if(solvername.compare("RTRK")==0)
        {
            solver_settings_key.assign("createRTRKSettings");
        }
        else if(solvername.compare("Idas")==0)
        {
            solver_settings_key.assign("extension_export_idas");
        }
        else if(solvername.compare("Ida")==0)
        {
            solver_settings_key.assign("extension_export_ida");
        }
        else if(solvername.compare("CVode")==0)
        {
            solver_settings_key.assign("extension_export_cvode");
        }
        else
            throw std::invalid_argument("Selected Solver is not available");


        shared_ptr<ISolverSettings> solver_settings  = ObjectFactory<CreationPolicy>::_factory->LoadSolverSettings(solver_settings_key, globalSettings) ;


        return solver_settings;
    }
};
/** @} */ // end of simcorefactoriesPolicies
