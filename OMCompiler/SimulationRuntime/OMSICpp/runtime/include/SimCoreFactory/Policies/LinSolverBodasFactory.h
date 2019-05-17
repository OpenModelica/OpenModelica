/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */
#pragma once
#include <ObjectFactory.h>
/*
 Policy class to create lin solver object
 */
template<class CreationPolicy>
struct LinSolverBodasFactory : public ObjectFactory<CreationPolicy>
{
public:
    LinSolverBodasFactory(PATH library_path, PATH modelicasystem_path, PATH config_path)
        : ObjectFactory<CreationPolicy>(library_path, modelicasystem_path, config_path)
        , _last_selected_solver("empty")
    {
    }

    virtual ~LinSolverBodasFactory()
    {
    }

    virtual shared_ptr<ILinSolverSettings> createLinSolverSettings(string lin_solver)
    {
        shared_ptr<ILinSolverSettings> linsolversetting;
        return linsolversetting;
    }

    virtual shared_ptr<IAlgLoopSolver> createLinSolver(ILinearAlgLoop* algLoop, string solver_name, shared_ptr<ILinSolverSettings> solver_settings)
    {
        shared_ptr<IAlgLoopSolver> solver;
        return solver;
    }

protected:
    string _last_selected_solver;
};
/** @} */ // end of simcorefactoriesPolicies