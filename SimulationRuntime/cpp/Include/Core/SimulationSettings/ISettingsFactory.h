#pragma once

#include <SimulationSettings/IGlobalSettings.h>
#include <Solver/ISolverSettings.h>

class ISettingsFactory
{
public:
    ISettingsFactory() {};
    virtual ~ISettingsFactory(void) {};
  virtual tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > create(fs::path libraries_path,fs::path config_path) =0;


};
