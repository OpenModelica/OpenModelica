/** @addtogroup simcorefactoryBodas
 *
 *  @{
 */
#include <Core/SimController/ISimController.h>
#include <SimCoreFactory/BodasFactory/BodasFactory.h>

extern "C" ISimController* createSimController(PATH library_path, PATH modelicasystem_path);
extern "C" IAlgLoopSolverFactory* createAlgLoopSolverFactory(IGlobalSettings* globalSettings, PATH library_path, PATH modelicasystem_path);
extern "C" ISettingsFactory* createSettingsFactory(PATH library_path, PATH modelicasystem_path);
extern "C" ISimData* createSimData();
extern "C" ISolver* createRTRK(IMixedSystem* system, ISolverSettings* settings);
extern "C" ISolverSettings* createRTEulerSettings(IGlobalSettings* globalSettings);
extern "C" ISolver* createRTEuler(IMixedSystem* system, ISolverSettings* settings);
extern "C" ISolverSettings* createRTRKSettings(IGlobalSettings* globalSettings);
extern "C" INonLinSolverSettings* createKinsolSettings();
extern "C" IAlgLoopSolver* createKinsol(INonLinearAlgLoop* algloop, INonLinSolverSettings* solver_settings);
extern "C" IMixedSystem* createModelicaSystem(IGlobalSettings* globalSettings, shared_ptr<IAlgLoopSolverFactory> nonlinsolver, shared_ptr<ISimData> simdata);

BodasFactory::BodasFactory(string library_path, string modelicasystem_path)
    : _library_path(library_path)
    , _modelicasystem_path(modelicasystem_path)
{
}

shared_ptr<ISimController> BodasFactory::LoadSimController()
{
    ISimController* simController = createSimController(_library_path, _modelicasystem_path);
    return shared_ptr<ISimController>(simController);
}

shared_ptr<ISettingsFactory> BodasFactory::LoadSettingsFactory()
{
    ISettingsFactory* settingsFactory = createSettingsFactory(_library_path, _modelicasystem_path);
    return shared_ptr<ISettingsFactory>(settingsFactory);
}

shared_ptr<IAlgLoopSolverFactory> BodasFactory::LoadAlgLoopSolverFactory(IGlobalSettings* globalSettings)
{
    IAlgLoopSolverFactory* algloopsolverFactory = createAlgLoopSolverFactory(globalSettings, _library_path, _modelicasystem_path);
    return shared_ptr<IAlgLoopSolverFactory>(algloopsolverFactory);
}

shared_ptr<IMixedSystem> BodasFactory::LoadSystem(IGlobalSettings* globalSettings, shared_ptr<IAlgLoopSolverFactory> nonlinsolver, shared_ptr<ISimData> simData)
{
    IMixedSystem* system = createModelicaSystem(globalSettings, nonlinsolver, simData);
    return shared_ptr<IMixedSystem>(system);
}

shared_ptr<ISimData> BodasFactory::LoadSimData()
{
    ISimData* simData = createSimData();
    return shared_ptr<ISimData>(simData);
}

shared_ptr<ISolver> BodasFactory::LoadSolver(IMixedSystem* system, string solver_name, shared_ptr<ISolverSettings> solver_settings)
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

shared_ptr<ISolverSettings> BodasFactory::LoadSolverSettings(string solver_name, shared_ptr<IGlobalSettings> global_settings)
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

shared_ptr<IAlgLoopSolver> BodasFactory::LoadAlgLoopSolver(INonLinearAlgLoop* algLoop, string solver_name, shared_ptr<INonLinSolverSettings> solver_settings)
{
    IAlgLoopSolver* algloopsolver;
    if (solver_name.compare("createNewton") == 0)
    {
        //algloopsolver = createNewton(algLoop, solver_settings.get());
    }
    else if (solver_name.compare("createKinsol") == 0)
    {
        algloopsolver = createKinsol(algLoop, solver_settings.get());
    }
    else
    {
    }
    return shared_ptr<IAlgLoopSolver>(algloopsolver);
}

shared_ptr<INonLinSolverSettings> BodasFactory::LoadAlgLoopSolverSettings(string solver_name)
{
    INonLinSolverSettings* solver_settings;
    if (solver_name.compare("createNewtonSettings") == 0)
    {
        //solver_settings = createNewtonSettings();
    }
    else if (solver_name.compare("createKinsolSettings") == 0)
    {
        solver_settings = createKinsolSettings();
    }
    else
    {
    }
    return shared_ptr<INonLinSolverSettings>(solver_settings);
}
/** @} */ // end of simcorefactoryBodas