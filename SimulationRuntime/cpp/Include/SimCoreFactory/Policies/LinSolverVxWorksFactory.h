#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

/*
Policy class to create nonlin solver object
*/
template <class CreationPolicy>
struct LinSolverVxWorksFactory : public ObjectFactory<CreationPolicy>
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

    boost::shared_ptr<ILinSolverSettings> createLinSolverSettings(string solver_name)
    {
        boost::shared_ptr<ILinSolverSettings> linsolversetting;
        return linsolversetting;
    }

    boost::shared_ptr<IAlgLoopSolver> createLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<ILinSolverSettings>  solver_settings)
    {
        boost::shared_ptr<IAlgLoopSolver> linsolver;
        return linsolver;
    }

    string _last_selected_solver;
};
/** @} */ // end of simcorefactoriesPolicies