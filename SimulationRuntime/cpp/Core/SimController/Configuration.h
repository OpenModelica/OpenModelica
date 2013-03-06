#pragma once
#include <boost/filesystem/path.hpp>
#include <SimulationSettings/IGlobalSettings.h>
#include <Solver/ISolverSettings.h>
#include <Solver/IDAESolver.h>
#include <System/IMixedSystem.h>
#include <SimulationSettings/ISettingsFactory.h>
#include <SimulationSettings/ISimControllerSettings.h>
class Configuration
{
public:
    Configuration(fs::path libraries_path, fs::path config_path);
    ~Configuration(void);
    boost::shared_ptr<IDAESolver> createSolver(IMixedSystem* system);
    IGlobalSettings* getGlobalSettings();
    ISolverSettings* getSolverSettings();
    ISimControllerSettings* getSimControllerSettings();
private:

     boost::shared_ptr<ISettingsFactory> _settings_factory;
     boost::shared_ptr<ISolverSettings>  _solver_settings;
     boost::shared_ptr<IGlobalSettings>  _global_settings;
     boost::shared_ptr<ISimControllerSettings>  _simcontroller_settings;
     boost::shared_ptr<IDAESolver> _solver;
   fs::path _libraries_path;
   fs::path _config_path;
};
