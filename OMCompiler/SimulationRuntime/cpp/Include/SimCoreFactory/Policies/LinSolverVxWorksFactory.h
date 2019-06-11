#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

/*
Policy class to create nonlin solver object
*/
template <class CreationPolicy>
struct LinSolverVxWorksFactory : virtual public ObjectFactory<CreationPolicy>
{
public:
    LinSolverVxWorksFactory(PATH library_path,PATH modelicasystem_path,PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path,modelicasystem_path,config_path)
        , _last_selected_solver("empty")
    {
    }

    ~LinSolverVxWorksFactory()
    {
    }

    shared_ptr<ILinSolverSettings> createLinSolverSettings(string solver_name)
    {
        shared_ptr<ILinSolverSettings> linsolversetting;
        return linsolversetting;
    }

    shared_ptr<IAlgLoopSolver> createLinSolver(ILinearAlgLoop* algLoop, string solver_name, shared_ptr<ILinSolverSettings>  solver_settings)
    {
        shared_ptr<IAlgLoopSolver> linsolver;
        return linsolver;
    }

    string _last_selected_solver;
};
/** @} */ // end of simcorefactoriesPolicies
