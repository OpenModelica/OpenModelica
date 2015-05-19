#pragma once
/*includes removed for static linking not needed any more
#include <SimCoreFactory/Policies/SolverOMCFactory.h>
#include <Core/SimulationSettings//ISettingsFactory.h>
#include <Core/Solver/ISolver.h>
#include <Core/Solver/ISolverSettings.h>
#include <Core/SimulationSettings//ISimControllerSettings.h>
#include <Core/System/IMixedSystem.h>
#include <Core/SimulationSettings/Factory.h>
#include <Solver/CVode/CVode.h>
#include <Solver/IDA/IDA.h>
*/

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
      return ObjectFactory<CreationPolicy>::_factory->createSettingsFactory();
    }

    virtual boost::shared_ptr<ISolver> createSolver(IMixedSystem* system, string solvername, boost::shared_ptr<ISolverSettings> solver_settings)
    {
        if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
        {
          Cvode *cvode = new Cvode(system,solver_settings.get());
          return boost::shared_ptr<ISolver>(cvode);
        }
        else if(solvername.compare("ida")==0)
        {
          Ida *ida = new Ida(system,solver_settings.get());
          return boost::shared_ptr<ISolver>(ida);
        } 
        else
            throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");


        return boost::shared_ptr<ISolver>();
    }
protected:
    virtual void initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_pat)
  {

  }
};
