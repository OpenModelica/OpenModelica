#pragma once

#include <SimCoreFactory/Policies/SolverSettingsOMCFactory.h>
#include <Solver/SolverSettings.h>
#include <boost/shared_ptr.hpp>
#include <SimulationSettings/IGlobalSettings.h>

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
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
          boost::shared_ptr<ISolverSettings> _solver_settings = boost::shared_ptr<ISolverSettings>(new SolverSettings(globalSettings.get()));
          return _solver_settings;
        }
        else
            throw std::invalid_argument("Selected Solver is not available");
    }
};
