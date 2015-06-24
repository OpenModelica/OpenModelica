#include <SimCoreFactory/Policies/StaticSolverOMCFactory.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>
#ifdef ENABLE_CVODE_STATIC
#include <Solver/CVode/CVodeSettings.h>
#include <Solver/CVode/CVode.h>
#endif //ENABLE_CVODE_STATIC

template <class CreationPolicy>
StaticSolverOMCFactory<CreationPolicy>::StaticSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        :SolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
{
}

template <class CreationPolicy>
StaticSolverOMCFactory<CreationPolicy>::~StaticSolverOMCFactory()
{
}

template <class CreationPolicy>
boost::shared_ptr<ISettingsFactory> StaticSolverOMCFactory<CreationPolicy>::createSettingsFactory()
{
  return ObjectFactory<CreationPolicy>::_factory->createSettingsFactory();
}

template <class CreationPolicy>
boost::shared_ptr<ISolver> StaticSolverOMCFactory<CreationPolicy>::createSolver(IMixedSystem* system, string solvername, boost::shared_ptr<ISolverSettings> solver_settings)
{
  #ifdef ENABLE_CVODE_STATIC
  if((solvername.compare("cvode")==0)||(solvername.compare("dassl")==0))
  {
    Cvode *cvode = new Cvode(system,solver_settings.get());
    return boost::shared_ptr<ISolver>(cvode);
  }
  #endif //ENABLE_CVODE_STATIC

  throw ModelicaSimulationError(MODEL_FACTORY,"Selected Solver is not available");
}

template <class CreationPolicy>
void StaticSolverOMCFactory<CreationPolicy>::initializeLibraries(PATH library_path,PATH modelicasystem_path,PATH config_pat)
{

}

template class StaticSolverOMCFactory<BaseFactory>;