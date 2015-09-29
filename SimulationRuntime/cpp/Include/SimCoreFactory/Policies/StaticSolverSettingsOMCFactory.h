#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
/*includes removed for static linking not needed any more
#include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
#include <Core/Solver/SolverSettings.h>
#include <boost/shared_ptr.hpp>
#include <Core/SimulationSettings/IGlobalSettings.h>
*/
/*
Policy class to create solver settings object
*/
shared_ptr<ISolverSettings> createIdaSettings(shared_ptr<IGlobalSettings> globalSettings);
shared_ptr<ISolverSettings> createCVodeSettings(shared_ptr<IGlobalSettings> globalSettings);
template <class CreationPolicy>
struct StaticSolverSettingsOMCFactory : public  SolverSettingsOMCFactory<CreationPolicy>
{

public:
    StaticSolverSettingsOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :SolverSettingsOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }

    virtual ~StaticSolverSettingsOMCFactory()
    {
    }

    virtual shared_ptr<ISolverSettings> createSolverSettings(string solvername,shared_ptr<IGlobalSettings> globalSettings)
    {
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
          shared_ptr<ISolverSettings> _solver_settings = createCVodeSettings(globalSettings);
          return _solver_settings;
        }
        else if((solvername.compare("ida")==0))
        {
           shared_ptr<ISolverSettings> _solver_settings = createIdaSettings(globalSettings);
           return _solver_settings;
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");
    }
};
/** @} */ // end of simcorefactoriesPolicies