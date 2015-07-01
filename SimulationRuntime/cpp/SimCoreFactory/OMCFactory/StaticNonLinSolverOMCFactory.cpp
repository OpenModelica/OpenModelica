#include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>
#include <Solver/Newton/NewtonSettings.h>
#include <Solver/Newton/Newton.h>
#ifdef ENABLE_KINSOL_STATIC
#include <Solver/Kinsol/KinsolSettings.h>
#include <Solver/Kinsol/Kinsol.h>
#endif //ENABLE_KINSOL_STATIC

template <class CreationPolicy>
StaticNonLinSolverOMCFactory<CreationPolicy>::StaticNonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path),
    NonLinSolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
{
}

template <class CreationPolicy>
StaticNonLinSolverOMCFactory<CreationPolicy>::~StaticNonLinSolverOMCFactory()
{
}

template <class CreationPolicy>
boost::shared_ptr<INonLinSolverSettings> StaticNonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(string nonlin_solver)
{
  string nonlin_solver_key;

  if(nonlin_solver.compare("newton")==0)
  {
    boost::shared_ptr<INonLinSolverSettings> settings = boost::shared_ptr<INonLinSolverSettings>(new NewtonSettings());
    return settings;
  }

  #ifdef ENABLE_KINSOL_STATIC
  if(nonlin_solver.compare("kinsol")==0)
  {
      boost::shared_ptr<INonLinSolverSettings> settings = boost::shared_ptr<INonLinSolverSettings>(new KinsolSettings());
      return settings;
  }
  #endif //ENABLE_KINSOL_STATIC

  return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolverSettings(nonlin_solver);
}

template <class CreationPolicy>
boost::shared_ptr<IAlgLoopSolver> StaticNonLinSolverOMCFactory<CreationPolicy>::createNonLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings> solver_settings)
{
  if(solver_name.compare("newton")==0)
  {
    boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new Newton(algLoop,solver_settings.get()));
    return solver;
  }

  #ifdef ENABLE_KINSOL_STATIC
  if(solver_name.compare("kinsol")==0)
  {
    boost::shared_ptr<IAlgLoopSolver> settings = boost::shared_ptr<IAlgLoopSolver>(new Kinsol(algLoop,solver_settings.get()));
    return settings;
  }
  #endif //ENABLE_KINSOL_STATIC

  return NonLinSolverOMCFactory<CreationPolicy>::createNonLinSolver(algLoop, solver_name, solver_settings);
}

template class StaticNonLinSolverOMCFactory<BaseFactory>;
