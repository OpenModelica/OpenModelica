#include "stdafx.h"
#include "Factory.h"
#include "GlobalSettings.h"
#include <Solver/ISolverSettings.h>
#include <LibrariesConfig.h>
#define BOOST_NO_WCHAR

SettingsFactory::SettingsFactory(void)
{


}

SettingsFactory::~SettingsFactory(void)
{


}
tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > SettingsFactory::create(fs::path libraries_path,fs::path config_path)
{


  fs::path settingsfile_name("GlobalSettings.xml");
  fs::path settingsfile_path = config_path;
  fs::path settingsfolder_name("config");
  settingsfile_path/=settingsfolder_name;
  settingsfile_path/=settingsfile_name;
    //load global settings or use default settings
    _global_settings =  boost::shared_ptr<IGlobalSettings>(new GlobalSettings());
  _global_settings->load( settingsfile_path.string());
  std::string solver_dll;
  //Load solver dll
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





  string settings = _global_settings->getSelectedSolver().append("Settings");
  string settings_file;
  settings_file.append(
      _global_settings->getSelectedSolver().append("Settings.xml"));

  fs::path solversettingsfile_name(settings_file);
  fs::path solversettingsfile_path = config_path;
  solversettingsfile_path/=settingsfolder_name;
  solversettingsfile_path/=solversettingsfile_name;

  type_map types;

  fs::path solver_name(solver_dll);
  fs::path solver_path = libraries_path;
  solver_path/=solver_name;
   fs::path solver_default_name(SOLVER_LIB);
  fs::path solver_default_path = libraries_path;
  solver_default_path/=solver_default_name;
   if(!load_single_library(types,solver_default_path.string()))
    throw std::invalid_argument(solver_default_path.string()  + " library could not be loaded");

  if(!load_single_library(types,solver_path.string()))
    throw std::invalid_argument(solver_path.string()  + " library could not be loaded");
  //get solver factory
  std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >::iterator iter;
  std::map<std::string, factory<ISolverSettings, IGlobalSettings* > >& factories(types.get());
  iter = factories.find(settings);
  if (iter ==factories.end())
  {
    throw std::invalid_argument("No such Solver "+_global_settings->getSelectedSolver());
  }
  //create with solver factory selected solver settings
  _solver_settings = boost::shared_ptr<ISolverSettings>(iter->second.create(_global_settings.get()));
  //cout<<"Read Settings from "<< solversettingsfile_path << std::endl;

 _solver_settings->load( solversettingsfile_path.string());

  //return global and solver settings
  tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > settings_pair(_global_settings,_solver_settings);
  return settings_pair;

}

using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {

    types.get<std::map<std::string, factory<ISettingsFactory> > >()
    ["SettingsFactory"].set<SettingsFactory>();
}
