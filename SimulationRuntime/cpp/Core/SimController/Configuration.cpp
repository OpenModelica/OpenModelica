#include "stdafx.h"
#include "Configuration.h"
#include <boost/algorithm/string.hpp>
#include "LibrariesConfig.h"
Configuration::Configuration(fs::path libraries_path,fs::path config_path)
:_libraries_path(libraries_path)
{
  type_map types;

  fs::path settings_name(SETTINGSFACTORY_LIB);
  fs::path settings_path = libraries_path;
  settings_path/=settings_name;
  if(!load_single_library(types,settings_path.string()))
    throw std::invalid_argument("Settings factory library could not be loaded");
  std::map<std::string, factory<ISettingsFactory> >::iterator iter;
  std::map<std::string, factory<ISettingsFactory> >& factories(types.get());

  iter = factories.find("SettingsFactory");
  if (iter ==factories.end())
  {
    throw std::invalid_argument("No such settings library");
  }
  _settings_factory = boost::shared_ptr<ISettingsFactory>(iter->second.create());
  tie(_global_settings,_solver_settings) =_settings_factory->create(libraries_path,config_path);
  _simcontroller_settings = boost::shared_ptr<ISimControllerSettings>(new ISimControllerSettings(_global_settings.get()) );

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
Configuration::~Configuration(void)
{

}
boost::shared_ptr<IDAESolver> Configuration::createSolver(IMixedSystem* system)
{
  type_map types;

  string solver_dll;
  string solver = _global_settings->getSelectedSolver().append("Solver");
  if(_global_settings->getSelectedSolver().compare("Euler")==0)
    solver_dll.assign(EULER_LIB);
  else if(_global_settings->getSelectedSolver().compare("Idas")==0)
    solver_dll.assign(IDAS_LIB);
  else if(_global_settings->getSelectedSolver().compare("Ida")==0)
    solver_dll.assign(IDA_LIB);
  else if(_global_settings->getSelectedSolver().compare("CVode")==0)
    solver_dll.assign(CVODE_LIB);
  else
    throw std::invalid_argument("Selected Solver is not available");

  fs::path solver_name(solver_dll);
  fs::path solver_path = _libraries_path;
  solver_path/=solver_name;

  if(!load_single_library(types,solver_path.string()))
    throw std::invalid_argument(solver_path.string()  +  "library could not be loaded");
  std::map<std::string, factory<IDAESolver,IMixedSystem*, ISolverSettings*> >::iterator iter;
  std::map<std::string, factory<IDAESolver,IMixedSystem*, ISolverSettings*> >& factories(types.get());
  iter = factories.find(solver);
  if (iter ==factories.end())
  {
    throw std::invalid_argument("No such Solver");
  }
  _solver= boost::shared_ptr<IDAESolver>(iter->second.create(system,_solver_settings.get()));
  return _solver;


}
