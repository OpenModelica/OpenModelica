#pragma once

#include "SettingsFactory/Interfaces/IGlobalSettings.h"
#include "Solver/Interfaces/ISolverSettings.h"

class ISettingsFactory
{
public:
	ISettingsFactory() {};
	virtual ~ISettingsFactory(void) {};
  virtual tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > create() =0;
	

};
