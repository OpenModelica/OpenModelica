/** @addtogroup coreSimcontroller
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <Core/SimController/Configuration.h>
#if defined(OMC_BUILD) || defined(SIMSTER_BUILD)
#include "LibrariesConfig.h"
#endif

Configuration::Configuration(PATH libraries_path, PATH config_path, PATH modelicasystem_path)
    : ConfigurationPolicy(libraries_path, modelicasystem_path, config_path)
{
  _settings_factory = createSettingsFactory();
  _global_settings = _settings_factory->createSolverGlobalSettings();
}

Configuration::~Configuration(void)
{
}

shared_ptr<IGlobalSettings> Configuration::getGlobalSettings()
{
  return _global_settings;
}

ISimControllerSettings* Configuration::getSimControllerSettings()
{
  return _simcontroller_settings.get();
}

ISolverSettings* Configuration::getSolverSettings()
{
  return _solver_settings.get();
}

shared_ptr<ISolver> Configuration::createSelectedSolver(IMixedSystem* system)
{
  string solver_name = _global_settings->getSelectedSolver();
  _solver_settings =_settings_factory->createSelectedSolverSettings();
  _simcontroller_settings = shared_ptr<ISimControllerSettings>(new ISimControllerSettings(_global_settings.get()) );
  _solver = createSolver(system, solver_name, _solver_settings);
  return _solver;
}
/** @} */ // end of coreSimcontroller