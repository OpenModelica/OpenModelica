#pragma once



class ISettingsFactory
{
public:
  ISettingsFactory() {};
  virtual ~ISettingsFactory(void) {};
  virtual boost::shared_ptr<ISolverSettings>  createSelectedSolverSettings() =0;
  virtual boost::shared_ptr<IGlobalSettings> createSolverGlobalSettings() =0;


};
