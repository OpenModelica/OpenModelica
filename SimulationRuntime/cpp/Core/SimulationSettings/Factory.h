#pragma once


#include <SimulationSettings/ISettingsFactory.h>

class  SettingsFactory : public ISettingsFactory
{
public:
   SettingsFactory();
    tuple<boost::shared_ptr<IGlobalSettings>,boost::shared_ptr<ISolverSettings> > create(fs::path libraries_path,fs::path config_path);
  ~SettingsFactory(void);
private:
    boost::shared_ptr<IGlobalSettings> _global_settings;
    boost::shared_ptr<ISolverSettings> _solver_settings;

};
