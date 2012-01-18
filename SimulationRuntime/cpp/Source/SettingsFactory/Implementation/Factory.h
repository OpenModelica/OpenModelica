#pragma once


#include "SettingsFactory/Interfaces/ISettingsFactory.h"

class /*BOOST_EXTENSION_SETTINGSFACTORY_DECL*/ SettingsFactory : public ISettingsFactory
{
public:
	/*DLL_EXPORT*/ SettingsFactory(void);
    /*DLL_EXPORT*/ tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > create();
	/*DLL_EXPORT*/ ~SettingsFactory(void);
private:
	boost::shared_ptr<IGlobalSettings> _global_settings;
	boost::shared_ptr<ISolverSettings> _solver_settings;
	
};
