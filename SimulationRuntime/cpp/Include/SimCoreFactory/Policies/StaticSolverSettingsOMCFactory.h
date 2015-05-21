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

    virtual boost::shared_ptr<ISolverSettings> createSolverSettings(string solvername,boost::shared_ptr<IGlobalSettings> globalSettings)
    {
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0)||(solvername.compare("ida")==0))
        {
          boost::shared_ptr<ISolverSettings> _solver_settings = boost::shared_ptr<ISolverSettings>(new SolverSettings(globalSettings.get()));
          return _solver_settings;
        }
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");
    }
};
/** @} */ // end of simcorefactoriesPolicies