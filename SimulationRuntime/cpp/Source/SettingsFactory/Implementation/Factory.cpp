#include "StdAfx.h"
//#define BOOST_EXTENSION_SETTINGSFACTORY_DECL BOOST_EXTENSION_EXPORT_DECL
//#define BOOST_EXTENSION_GLOBALSETTINGS_DECL BOOST_EXTENSION_EXPORT_DECL
#include "Factory.h"
#include "GlobalSettings.h"
#include "Solver/Interfaces/ISolverSettings.h"
#include "LibrariesConfig.h"

SettingsFactory::SettingsFactory(void)
{
	
	
}

SettingsFactory::~SettingsFactory(void)
{

 
}
tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > SettingsFactory::create()
{
	cout<<"Read Settings..."<<std::endl;
	
	//load global settings or use default settings
	_global_settings =  boost::shared_ptr<IGlobalSettings>(new GlobalSettings());
	_global_settings->load("config//GlobalSettings.xml");
	std::string solver_dll;
	//Load solver dll
	if(_global_settings->getSelectedSolver().compare("Euler")==0)
		solver_dll.assign(EULER_LIB);
	else
		throw std::invalid_argument("Selected Solver is not available");
	
	//solver_dll.assign("Idas.dll");
	//solver_dll.assign("CVODE.dll");

	string settings = _global_settings->getSelectedSolver().append("Settings");
	string settings_file ="config//";
	settings_file.append(
			_global_settings->getSelectedSolver().append("Settings.xml"));
	type_map types;
	
	if(!load_single_library(types,solver_dll))
		throw std::invalid_argument(solver_dll + " library could not be loaded");
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
	_solver_settings->load(settings_file);
	
	//return global and solver settings	
	tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > settings_pair(_global_settings,_solver_settings);
	return settings_pair;

}

using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {

	types.get<std::map<std::string, factory<ISettingsFactory> > >()
    ["SettingsFactory"].set<SettingsFactory>();
}











//
//extern "C" 
//void BOOST_EXTENSION_EXPORT_DECL 
//extension_export_settings(boost::extensions::factory_map & fm)
//{
//	cout<<"in settingsfactory "<<std::endl;
//  fm.get<ISettingsFactory, int>()[1].set<SettingsFactory>();
//  
//}



	 /*types.get<std::map<std::string, factory<ISettingsFactory > > >()
    ["SettingsFactory"].set<SettingsFactory>();
   types.get<std::map<std::string, factory<IGlobalSettings > > >()
    ["GlobalSettings"].set<GlobalSettings>();*/
