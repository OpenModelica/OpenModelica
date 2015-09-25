#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

/*
Policy class to create solver object
*/
template <class CreationPolicy>
struct SolverBodasFactory : public ObjectFactory<CreationPolicy>
{
public:
    SolverBodasFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
    {
    }

    ~SolverBodasFactory()
    {
    }

    shared_ptr<ISettingsFactory> createSettingsFactory()
    {
        shared_ptr<ISettingsFactory> settings_factory = ObjectFactory<CreationPolicy>::_factory->LoadSettingsFactory();
        return settings_factory;
    }

    shared_ptr<ISolver> createSolver(IMixedSystem* system, string solver_name, shared_ptr<ISolverSettings> solver_settings)
    {
        string solver_key;
        if(solver_name.compare("Euler") == 0)
        {
            solver_key.assign("createEuler");
        }
        else if(solver_name.compare("RTEuler") == 0)
        {
            solver_key.assign("createRTEuler");
        }
        else if(solver_name.compare("RTRK")==0)
        {
            solver_key.assign("createRTRK");
        }
        else if(solver_name.compare("Idas") == 0)
        {
            solver_key.assign("extension_export_idas");
        }
        else if(solver_name.compare("Ida") == 0)
        {
            solver_key.assign("extension_export_ida");
        }
        else if(solver_name.compare("CVode") == 0)
        {
            solver_key.assign("extension_export_cvode");
        }
        else
            throw std::invalid_argument("Selected Solver is not available");

        shared_ptr<ISolver> solver = ObjectFactory<CreationPolicy>::_factory->LoadSolver(system, solver_key, solver_settings);
        return solver;
    }
};
/** @} */ // end of simcorefactoriesPolicies