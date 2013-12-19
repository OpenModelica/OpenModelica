#pragma once

#include "SimManager.h"
#include <Policies/FactoryPolicy.h>


class SimController : public ISimController, 
                      public SimControllerPolicy
{
public:
    
    SimController(PATH library_path,PATH modelicasystem_path);
    virtual ~SimController();
   
  
  ///Load and translates a Modelica modell to IMixedSystem dll
    virtual std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > LoadSystem(string modelLib,string modelKey);
    virtual std::pair<boost::weak_ptr<IMixedSystem>,boost::weak_ptr<ISimData> > LoadModelicaSystem(PATH modelica_path,string modelKey);
    /// Starts the simulation
    virtual void Start(boost::weak_ptr<IMixedSystem> mixedsystem,SimSettings simsettings/*,ISimData* simData*/);
    /// Stops the simulation
    virtual void Stop();
private:
    void initialize(PATH library_path, PATH modelicasystem_path);
    bool _initialized;
       boost::shared_ptr<Configuration> _config;
     std::map<string, std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > > _systems;
    boost::shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;
};

