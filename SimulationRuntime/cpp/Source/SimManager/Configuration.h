#pragma once
#include <boost/filesystem/path.hpp>
#include "SettingsFactory/Interfaces/IGlobalSettings.h"
#include "Solver/Interfaces/ISolverSettings.h"
#include "Solver/Interfaces/IDAESolver.h"
#include "System/Interfaces/IDAESystem.h"
#include "SettingsFactory/Interfaces/ISettingsFactory.h"

class Configuration
{
public:
  Configuration(fs::path libraries_path);
  ~Configuration(void);
  IDAESolver* createSolver(IDAESystem* system);
  IGlobalSettings* getGlobalSettings();
  ISolverSettings* getSolverSettings();
private:
  
   boost::shared_ptr<ISettingsFactory> _settings_factory;
   boost::shared_ptr<ISolverSettings>  _solver_settings;
   boost::shared_ptr<IGlobalSettings>  _global_settings;
   boost::shared_ptr<IDAESolver> _solver;
   fs::path _libraries_path;
};
