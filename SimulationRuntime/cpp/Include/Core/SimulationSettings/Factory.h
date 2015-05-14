#pragma once

#ifdef RUNTIME_STATIC_LINKING
/*includes removed for static linking not needed any more
#include <Core/SimulationSettings//ISettingsFactory.h>*/
#include <SimCoreFactory/Policies/StaticSolverSettingsOMCFactory.h>
class  SettingsFactory : public ISettingsFactory
                       , public StaticSolverSettingsOMCFactory<OMCFactory>
#else

#include <SimCoreFactory/Policies/FactoryPolicy.h>
class  SettingsFactory : public ISettingsFactory
                       , public SolverSettingsPolicy

#endif

{
public:
  SettingsFactory(PATH libraries_path, PATH config_path, PATH modelicasystem_path);
  virtual boost::shared_ptr<ISolverSettings> createSelectedSolverSettings();
  virtual boost::shared_ptr<IGlobalSettings> createSolverGlobalSettings();
  ~SettingsFactory(void);

private:
  boost::shared_ptr<IGlobalSettings> _global_settings;
  boost::shared_ptr<ISolverSettings> _solver_settings;
};