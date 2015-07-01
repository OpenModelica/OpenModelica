#pragma once
/** @addtogroup simcorefactoriesPolicies
 *
 *  @{
 */

#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include <SimCoreFactory/Policies/NonLinSolverOMCFactory.h>

template<class T>
struct ObjectFactory;

template <class CreationPolicy>
class StaticNonLinSolverOMCFactory : public NonLinSolverOMCFactory<CreationPolicy>
{

public:
    StaticNonLinSolverOMCFactory(PATH library_path,PATH modelicasystem_path,PATH config_path);
    virtual ~StaticNonLinSolverOMCFactory();

   virtual boost::shared_ptr<INonLinSolverSettings> createNonLinSolverSettings(string nonlin_solver);
   virtual boost::shared_ptr<IAlgLoopSolver> createNonLinSolver(IAlgLoop* algLoop, string solver_name, boost::shared_ptr<INonLinSolverSettings> solver_settings);
};
/** @} */ // end of simcorefactoriesPolicies
