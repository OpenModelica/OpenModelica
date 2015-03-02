#pragma once

#include "SimManager.h"
#include <SimCoreFactory/Policies/FactoryPolicy.h>
#include <Core/SimController/ISimController.h>

#ifdef RUNTIME_STATIC_LINKING
#include <boost/function.hpp>
#include <Core/SimController/ISimController.h>
#endif

class SimController : public ISimController,
                      public SimControllerPolicy
{
public:
    SimController(PATH library_path,PATH modelicasystem_path);
    virtual ~SimController();

   /*
#if defined(__vxworks) || defined(__TRICORE__)
#else
    virtual std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > LoadSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), string modelKey);
#endif
  */
   virtual boost::weak_ptr<IMixedSystem> LoadSystem(string modelLib,string modelKey);
   virtual boost::weak_ptr<IMixedSystem> LoadModelicaSystem(PATH modelica_path,string modelKey);
   virtual boost::weak_ptr<ISimData> LoadSimData(string modelKey);

   /// Stops the simulation
   virtual void Stop();
   virtual void Start(SimSettings simsettings, string modelKey);
   virtual void StartVxWorks(SimSettings simsettings,string modelKey);
   virtual boost::weak_ptr<ISimData> getSimData(string modelname);
   virtual boost::weak_ptr<IMixedSystem> getSystem(string modelname);
   virtual void calcOneStep();

private:
    void initialize(PATH library_path, PATH modelicasystem_path);
    bool _initialized;
    boost::shared_ptr<Configuration> _config;
    std::map<string, boost::shared_ptr<IMixedSystem> > _systems;
    std::map<string, boost::shared_ptr<ISimData> > _sim_data;
    boost::shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;

    // for real-time usage (VxWorks and BODAS)
    boost::shared_ptr<SimManager> _simMgr;
};
