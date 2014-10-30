#pragma once

#include "SimManager.h"
#include <SimCoreFactory/Policies/FactoryPolicy.h>
#include <Core/SimController/ISimController.h>

#ifdef ANALYZATION_MODE
#include <boost/function.hpp>
#include <Core/SimController/ISimController.h>
#endif

class SimController : public ISimController,
                      public SimControllerPolicy
{
public:
    SimController(PATH library_path,PATH modelicasystem_path);
    virtual ~SimController();

    ///Load and translates a Modelica modell to IMixedSystem dll
    virtual std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > LoadSystem(string modelLib, string modelKey);
#if defined(__vxworks) || defined(__TRICORE__)
#else
    virtual std::pair<boost::shared_ptr<IMixedSystem>,boost::shared_ptr<ISimData> > LoadSystem(boost::shared_ptr<ISimData> (*createSimDataCallback)(), boost::shared_ptr<IMixedSystem> (*createSystemCallback)(IGlobalSettings*, boost::shared_ptr<IAlgLoopSolverFactory>, boost::shared_ptr<ISimData>), string modelKey);
#endif
    virtual std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > LoadModelicaSystem(PATH modelica_path, string modelKey);
    /// Starts the simulation
    virtual void Start(boost::shared_ptr<IMixedSystem> mixedsystem, SimSettings simsettings, string modelKey);
    /// Stops the simulation
    virtual void Stop();

    // for real-time usage (VxWorks and BODAS)
    virtual boost::shared_ptr<ISimData> getSimData(string modelname);
    virtual void StartVxWorks(boost::shared_ptr<IMixedSystem> mixedsystem, SimSettings simsettings);
    virtual void calcOneStep(double cycletime);

private:
    void initialize(PATH library_path, PATH modelicasystem_path);
    bool _initialized;
    boost::shared_ptr<Configuration> _config;
    std::map<string, std::pair<boost::shared_ptr<IMixedSystem>, boost::shared_ptr<ISimData> > > _systems;
    boost::shared_ptr<IAlgLoopSolverFactory> _algloopsolverfactory;

    // for real-time usage (VxWorks and BODAS)
    boost::shared_ptr<SimManager> _simMgr;
};
