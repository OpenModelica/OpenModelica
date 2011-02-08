#include "StdAfx.h"
#include "Configuration.h"
#include <boost/algorithm/string.hpp>

Configuration::Configuration(void)
{
	type_map types;
	if(!load_single_library(types, "SettingsFactory.dll"))
		throw std::invalid_argument("Settings factory library could not be loaded");
	std::map<std::string, factory<ISettingsFactory> >::iterator iter;
	std::map<std::string, factory<ISettingsFactory> >& factories(types.get());

	iter = factories.find("SettingsFactory");
	if (iter ==factories.end()) 
	{
		throw std::invalid_argument("No such Solver");
	}
	_settings_factory = boost::shared_ptr<ISettingsFactory>(iter->second.create());
	tie(_global_settings,_solver_settings) =_settings_factory->create();


}
IGlobalSettings* Configuration::getGlobalSettings()
{
	return _global_settings.get();


}
ISolverSettings* Configuration::getSolverSettings()
{
	return _solver_settings.get();
}
Configuration::~Configuration(void)
{

}
IDAESolver* Configuration::createSolver(IDAESystem* system)
{
	type_map types;
	string solver_dll = _global_settings->getSelectedSolver().append(".dll");
	string solver = _global_settings->getSelectedSolver().append("Solver");
	if(!load_single_library(types, solver_dll))
		throw std::invalid_argument(solver_dll + "library could not be loaded");
	std::map<std::string, factory<IDAESolver,IDAESystem*, ISolverSettings*> >::iterator iter;
	std::map<std::string, factory<IDAESolver,IDAESystem*, ISolverSettings*> >& factories(types.get());
	iter = factories.find(solver);
	if (iter ==factories.end()) 
	{
		throw std::invalid_argument("No such Solver");
	}
	_solver= boost::shared_ptr<IDAESolver>(iter->second.create(system,_solver_settings.get()));
	return _solver.get();


}

//
//// Create global and solver specific settings
//	GlobalSettings globalSettings;
//	globalSettings._endTime =  5;
//	globalSettings._hOutput = 0.001;
//	
//	EulerSettings solverSettings(&globalSettings);
//	solverSettings._denseOutput = true;
//	solverSettings._zeroSearchMethod = EulerSettings::BISECTION;
//	solverSettings._hInit = 1e-4;
//	solverSettings._zeroTimeTol = 1e-10;
//	solverSettings._method =EulerSettings::LINEAREULER;
//	//solverSettings._zeroTol = 1e-8;
//	
//	if(argc==2)
//	{
//		globalSettings._output_path = string(argv[1]);
//	}

//factory_map fm;
//// load the shared library with 
//load_single_library(fm, "SettingsFactory.dll", 
//                    "extension_export_settings");
////  Get a reference to the list of constructors for words.
//std::map<int, factory<ISettingsFactory> > & factory_list = fm.get<ISettingsFactory, int>();
//if (factory_list.size() < 1)
//{
//   throw std::invalid_argument("Error - the classes were not found.");
//}
//for (std::map<int, factory<ISettingsFactory> >::iterator current_word = 
//       factory_list.begin(); current_word != factory_list.end(); 
//     ++current_word)
//{
//  //  Using auto_ptr to avoid needing delete. Using smart_ptrs is 
//  // recommended.
//  //  Note that this has a zero argument constructor - currently constructors
//  //  with up to six arguments can be used.
//  std::auto_ptr<ISettingsFactory> word_ptr(current_word->second.create());
//
//}