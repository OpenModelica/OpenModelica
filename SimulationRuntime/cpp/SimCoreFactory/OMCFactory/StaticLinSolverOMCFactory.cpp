#include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
#include <SimCoreFactory/Policies/FactoryPolicy.h>

template <class CreationPolicy>
StaticLinSolverOMCFactory<CreationPolicy>::StaticLinSolverOMCFactory(PATH library_path, PATH modelicasystem_path,PATH config_path)
    :ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
     ,LinSolverOMCFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
     ,_last_selected_solver("empty")
{
}

template <class CreationPolicy>
StaticLinSolverOMCFactory<CreationPolicy>::~StaticLinSolverOMCFactory()
{
}

template <class CreationPolicy>
boost::shared_ptr<ILinSolverSettings> StaticLinSolverOMCFactory<CreationPolicy>::createLinSolverSettings(string lin_solver)
{
/*
        if(lin_solver.compare("umfpack")==0)
        {
     boost::shared_ptr<ILinSolverSettings> settings = boost::shared_ptr<ILinSolverSettings>(new UmfPackSettings());
     return settings;
        }
        else */
           return LinSolverOMCFactory<CreationPolicy>::createLinSolverSettings(lin_solver);
}

template <class CreationPolicy>
boost::shared_ptr<IAlgLoopSolver> StaticLinSolverOMCFactory<CreationPolicy>::createLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<ILinSolverSettings> solver_settings)
{
/*
       if(solver_name.compare("umfpack")==0)
       {
           boost::shared_ptr<IAlgLoopSolver> solver = boost::shared_ptr<IAlgLoopSolver>(new UmfPack(algLoop,solver_settings.get()));
           return solver;
       }
       else */
           return LinSolverOMCFactory<CreationPolicy>::createLinSolver(algLoop, solver_name, solver_settings);
}

template class StaticLinSolverOMCFactory<BaseFactory>;
