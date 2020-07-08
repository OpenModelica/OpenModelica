#pragma once
/** @defgroup coreSimulationSettings Core.SimulationSettings
 *  Module for simulation settings
 *  @{
 */
#include <SimCoreFactory/Policies/FactoryPolicy.h>
class  SettingsFactory : public ISettingsFactory
                       , public SolverSettingsPolicy
{
public:
  SettingsFactory(PATH libraries_path, PATH config_path, PATH modelicasystem_path);
  virtual shared_ptr<ISolverSettings> createSelectedSolverSettings();
  virtual shared_ptr<IGlobalSettings> createSolverGlobalSettings();
  ~SettingsFactory(void);

private:
  shared_ptr<IGlobalSettings> _global_settings;
  shared_ptr<ISolverSettings> _solver_settings;
};
/** @} */ // end of coreSimulationSettings

