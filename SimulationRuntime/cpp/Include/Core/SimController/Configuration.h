#pragma once
/** @defgroup coreSimcontroller Core.SimController
 *  Configuration and control of simulation 
 *  
 *  @{
 */ 

#include <SimCoreFactory/Policies/FactoryPolicy.h>

class Configuration : public ConfigurationPolicy
{
public:
  Configuration(PATH libraries_path,PATH config_path,PATH modelicasystem_path);
  ~Configuration(void);
  boost::shared_ptr<ISolver> createSelectedSolver(IMixedSystem* system);
  IGlobalSettings* getGlobalSettings();
  ISolverSettings* getSolverSettings();
  ISimControllerSettings* getSimControllerSettings();

private:
   boost::shared_ptr<ISettingsFactory> _settings_factory;
   boost::shared_ptr<ISolverSettings> _solver_settings;
   boost::shared_ptr<IGlobalSettings> _global_settings;
   boost::shared_ptr<ISimControllerSettings> _simcontroller_settings;
   boost::shared_ptr<ISolver> _solver;
};
/** @} */ // end of coreSimcontroller