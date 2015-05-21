#pragma once
/** @addtogroup coreSimulationSettings
 *  
 *  @{
 */
#include <Core/SimulationSettings/IGlobalSettings.h>
#include <Core/Solver/ISolverSettings.h>

class ISettingsFactory
{
public:
  ISettingsFactory() {};
  virtual ~ISettingsFactory(void) {};
  virtual boost::shared_ptr<ISolverSettings> createSelectedSolverSettings() = 0;
  virtual boost::shared_ptr<IGlobalSettings> createSolverGlobalSettings() = 0;
};
/** @} */ // end of coreSimulationSettings