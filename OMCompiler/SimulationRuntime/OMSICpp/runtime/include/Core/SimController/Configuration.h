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
  shared_ptr<ISolver> createSelectedSolver(IMixedSystem* system);
  shared_ptr<IGlobalSettings> getGlobalSettings();
  ISolverSettings* getSolverSettings();
  ISimControllerSettings* getSimControllerSettings();

private:
   shared_ptr<ISettingsFactory> _settings_factory;
   shared_ptr<ISolverSettings> _solver_settings;
   shared_ptr<IGlobalSettings> _global_settings;
   shared_ptr<ISimControllerSettings> _simcontroller_settings;
   shared_ptr<ISolver> _solver;
};
/** @} */ // end of coreSimcontroller