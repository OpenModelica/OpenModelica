#pragma once

#include <SimCoreFactory/Policies/SolverOMCFactory.h>
#include <SimulationSettings/ISettingsFactory.h>
#include <Solver/ISolver.h>
#include <Solver/ISolverSettings.h>
#include <SimulationSettings/ISimControllerSettings.h>
#include <System/IMixedSystem.h>
#include <Core/SimulationSettings/Factory.h>
#include <Solver/CVode/CVode.h>

/*
Policy class to create solver object
*/
template <class CreationPolicy>
struct StaticSolverOMCFactory : public SolverOMCFactory<CreationPolicy>
{

public:
    StaticSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :SolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
    {
    }
    
    virtual ~StaticSolverOMCFactory()
    {
    }

    virtual boost::shared_ptr<ISettingsFactory> createSettingsFactory()
    {
      SettingsFactory *setFac = new SettingsFactory(ObjectFactory<CreationPolicy>::_library_path,ObjectFactory<CreationPolicy>::_modelicasystem_path,ObjectFactory<CreationPolicy>::_config_path);
      boost::shared_ptr<ISettingsFactory>  settings_factory = boost::shared_ptr<ISettingsFactory>(setFac);
        return settings_factory;
    }

    virtual boost::shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername, boost::shared_ptr<ISolverSettings> solver_settings)
    {
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
          Cvode *cvode = new Cvode(system,solver_settings.get());
          return boost::shared_ptr<ISolver>(cvode);
        }
        else
            throw std::invalid_argument("Selected Solver is not available");

        return boost::shared_ptr<ISolver>();
    }
protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_pat)
  {

  }
};
