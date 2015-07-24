#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
/*
Policy class to create nonlin solver object
*/
template <class CreationPolicy>
struct NonLinSolverVxWorksFactory : virtual public  ObjectFactory<CreationPolicy>
{
public:
    NonLinSolverVxWorksFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
        , _last_selected_solver("empty")
    {
    }

    ~NonLinSolverVxWorksFactory()
    {
    }

    boost::shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string solver_name)
    {
        string nonlin_solver_key;
        string nonlin_solver;
        if(solver_name.compare("Newton")==0)
            nonlin_solver_key.assign("createNewtonSettings");
        else if(solver_name.compare("Kinsol")==0)
            nonlin_solver_key.assign("createKinsolSettings");
        else if(solver_name.compare("Hybrj")==0)
            nonlin_solver_key.assign("extension_export_hybrj");
        else
            throw std::invalid_argument("Selected nonlinear solver is not available");
        _last_selected_solver = solver_name;
        boost::shared_ptr<INonLinSolverSettings> nonlinsolversetting = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolverSettings(nonlin_solver_key);
        return nonlinsolversetting;
    }

    boost::shared_ptr<IAlgLoopSolver> createNonLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings>  solver_settings)
    {
        if(_last_selected_solver.compare(solver_name)==0)
        {
            string nonlin_solver_key;
            if(solver_name.compare("Newton")==0)
                nonlin_solver_key.assign("createNewton");
            else if(solver_name.compare("Kinsol")==0)
                nonlin_solver_key.assign("createKinsol");
            else if(solver_name.compare("Hybrj")==0)
                nonlin_solver_key.assign("extension_export_hybrj");
            else
                throw std::invalid_argument("Selected nonlinear solver is not available");
            boost::shared_ptr<IAlgLoopSolver> nonlinsolver = ObjectFactory<CreationPolicy>::_factory->LoadAlgLoopSolver(algLoop, nonlin_solver_key, solver_settings);
            return nonlinsolver;
        }
        else
            throw std::invalid_argument("Selected nonlinear solver is not available");
    }

    string _last_selected_solver;
};
/** @} */ // end of simcorefactoriesPolicies
