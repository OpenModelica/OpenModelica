/** @addtogroup simcorefactoryVxworks
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>

#include <SimCoreFactory/VxWorksFactory/VxWorksFactory.h>

extern "C" ISimController* createSimController(PATH library_path, PATH modelicasystem_path);
extern "C" ISettingsFactory* createSettingsFactory(PATH library_path,PATH modelicasystem_path);

extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactoryFunction(IGlobalSettings* globalSettings,PATH library_path,PATH modelicasystem_path);

  //shared_ptr<IAlgLoopSolverFactory> createAlgLoopSolverFactory(IGlobalSettings* globalSettings);



extern "C" ISimData* createSimData();
extern "C" ISimVars* createSimVars(size_t dim_real,size_t dim_int,size_t dim_bool, size_t dim_string,size_t dim_pre_vars,size_t dim_z,size_t z_i);
extern "C" ISolver* createRTEuler(IMixedSystem* system, ISolverSettings* settings);
extern "C" ISolver* createRTRK(IMixedSystem* system, ISolverSettings* settings);
extern "C" ISolverSettings* createRTEulerSettings(IGlobalSettings* globalSettings);
extern "C" ISolverSettings* createRTRKSettings(IGlobalSettings* globalSettings);
extern "C" IAlgLoopSolver* createKinsol(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings);
extern "C" INonLinSolverSettings* createKinsolSettings();
extern "C" IAlgLoopSolver* createNewton(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings);
extern "C" INonLinSolverSettings* createNewtonSettings();
extern "C" IAlgLoopSolver* createBroyden(INonLinearAlgLoop* algLoop, INonLinSolverSettings* settings);
extern "C" INonLinSolverSettings* createBroydenSettings();
extern "C" IMixedSystem* createModelicaSystem(IGlobalSettings* globalSettings);

VxWorksFactory::VxWorksFactory(string library_path, string modelicasystem_path)
    : _library_path(library_path)
    , _modelicasystem_path(modelicasystem_path)
{
}

VxWorksFactory::~VxWorksFactory()
{
}

shared_ptr<ISimController> VxWorksFactory::LoadSimController()
{
    ISimController* simController = createSimController(_library_path, _modelicasystem_path);
    return shared_ptr<ISimController>(simController);
}

shared_ptr<ISettingsFactory>  VxWorksFactory::LoadSettingsFactory()
{
    ISettingsFactory* settingsFactory = createSettingsFactory(_library_path, _modelicasystem_path);
    return shared_ptr<ISettingsFactory>(settingsFactory);

}

shared_ptr<IAlgLoopSolverFactory>  VxWorksFactory::LoadAlgLoopSolverFactory(IGlobalSettings* globalSettings)
{
    IAlgLoopSolverFactory* algloopsolverFactory = createAlgLoopSolverFactoryFunction(globalSettings, _library_path, _modelicasystem_path);
    return shared_ptr<IAlgLoopSolverFactory>(algloopsolverFactory);

}

/*
shared_ptr<IAlgLoopSolverFactory>  VxWorksFactory::LoadAlgLoopSolverFactory(IGlobalSettings* globalSettings)
{
	return createAlgLoopSolverFactory(globalSettings);
}
*/

shared_ptr<IMixedSystem> VxWorksFactory::LoadSystem(IGlobalSettings* globalSettings,shared_ptr<ISimObjects> simObjects)
{
    IMixedSystem* system = createModelicaSystem(globalSettings, simObjects);
    return shared_ptr<IMixedSystem>(system);
}

shared_ptr<ISimData> VxWorksFactory::LoadSimData()
{
    ISimData* simData = createSimData();
    return shared_ptr<ISimData>(simData);
}

shared_ptr<ISolver> VxWorksFactory::LoadSolver(IMixedSystem* system, string solver_name,shared_ptr<ISolverSettings>  solver_settings)
{
  ISolver* solver;
  if (solver_name.compare("createRTEuler") == 0)
  {
    solver = createRTEuler(system, solver_settings.get());
  }
  else if (solver_name.compare("createRTRK") == 0)
  {
    solver = createRTRK(system, solver_settings.get());
  }
  else
  {
  }

  return shared_ptr<ISolver>(solver);
}

shared_ptr<ISolverSettings> VxWorksFactory::LoadSolverSettings(string solver_name,shared_ptr<IGlobalSettings> global_settings)
{
  ISolverSettings* solver_settings;
  if (solver_name.compare("createRTEulerSettings") == 0)
  {
    solver_settings = createRTEulerSettings(global_settings.get());
  }
  else if (solver_name.compare("createRTRKSettings") == 0)
  {
    solver_settings = createRTRKSettings(global_settings.get());
  }
  else
  {

  }
    return shared_ptr<ISolverSettings>(solver_settings);
}

shared_ptr<IAlgLoopSolver> VxWorksFactory::LoadAlgLoopSolver(INonLinearAlgLoop* algLoop, string solver_name, shared_ptr<INonLinSolverSettings> solver_settings)
{
  IAlgLoopSolver* algloopsolver;
  if (solver_name.compare("createNewton") == 0)
  {
    algloopsolver = createNewton(algLoop, solver_settings.get());
  }
  else if (solver_name.compare("createKinsol") == 0)
  {
    algloopsolver = createKinsol(algLoop, solver_settings.get());
  }
  else if (solver_name.compare("createBroyden") == 0)
  {
    algloopsolver = createBroyden(algLoop, solver_settings.get());
  }
  else
  {
  }

  return shared_ptr<IAlgLoopSolver>(algloopsolver);
}

shared_ptr<INonLinSolverSettings> VxWorksFactory::LoadAlgLoopSolverSettings(string solver_name)
{
  INonLinSolverSettings* solver_settings;
  if (solver_name.compare("createNewtonSettings") == 0)
  {
  solver_settings = createNewtonSettings();
  }
  else if (solver_name.compare("createKinsolSettings") == 0)
  {
    solver_settings = createKinsolSettings();
  }
  else if (solver_name.compare("createBroydenSettings") == 0)
  {
    solver_settings = createBroydenSettings();
  }
  else
  {

  }
    return shared_ptr<INonLinSolverSettings>(solver_settings);
}
shared_ptr<ISimVars> VxWorksFactory::LoadSimVars(size_t dim_real,size_t dim_int,size_t dim_bool, size_t dim_string, size_t dim_pre_vars,size_t dim_z,size_t z_i)
{
    ISimVars* simVars = createSimVars(dim_real,dim_int,dim_bool, dim_string, dim_pre_vars,dim_z,z_i);
    return shared_ptr<ISimVars>(simVars);
}
/** @} */ // end of simcorefactoryVxworks
