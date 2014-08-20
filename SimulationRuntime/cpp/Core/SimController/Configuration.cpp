#include "Modelica.h"
#include <SimCoreFactory/Policies/FactoryConfig.h>
#include <SimCoreFactory/OMCFactory/OMCFactory.h>
#include "Configuration.h"
#include "LibrariesConfig.h"


Configuration::Configuration( PATH libraries_path,PATH config_path,PATH modelicasystem_path)
 :ConfigurationPolicy(libraries_path,modelicasystem_path,config_path)
{

     _settings_factory = createSettingsFactory();

     _global_settings = _settings_factory->createSolverGlobalSettings();

}

Configuration::~Configuration(void)
{
}

IGlobalSettings* Configuration::getGlobalSettings()
{
    return _global_settings.get();


}

ISimControllerSettings* Configuration::getSimControllerSettings()
{
    return _simcontroller_settings.get();
}

ISolverSettings* Configuration::getSolverSettings()
{
    return _solver_settings.get();
}

boost::shared_ptr<ISolver> Configuration::createSelectedSolver(IMixedSystem* system)
{
  string solver_name = _global_settings->getSelectedSolver();
  _solver_settings =_settings_factory->createSelectedSolverSettings();
  _simcontroller_settings = boost::shared_ptr<ISimControllerSettings>(new ISimControllerSettings(_global_settings.get()) );
   _solver = createSolver(system, solver_name, _solver_settings);
  return _solver;


}
