#pragma once
/** @addtogroup coreSimulationSettings
 *
 *  @{
 */

class ISettingsFactory
{
public:
  ISettingsFactory() {};
  virtual ~ISettingsFactory(void) {};
  virtual shared_ptr<ISolverSettings> createSelectedSolverSettings() = 0;
  virtual shared_ptr<IGlobalSettings> createSolverGlobalSettings() = 0;
};
/** @} */ // end of coreSimulationSettings