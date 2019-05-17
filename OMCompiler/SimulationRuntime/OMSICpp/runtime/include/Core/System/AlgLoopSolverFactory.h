#pragma once
/** @addtogroup coreSystem
 *
 *  @{
 */
/*****************************************************************************/
/**
Factory used by the system to create a solver for the solution of a (possibly
non-linear) system of the Form F(x)=0.
*/

#include <SimCoreFactory/Policies/FactoryPolicy.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public NonLinSolverPolicy, public LinSolverPolicy
{
public:
  AlgLoopSolverFactory(shared_ptr<IGlobalSettings> gloabl_settings, PATH library_path, PATH modelicasystem_path);
  virtual ~AlgLoopSolverFactory();

  /// Creates a solver according to given system of equations of type algebraic loop
  virtual shared_ptr<ILinearAlgLoopSolver> createLinearAlgLoopSolver(shared_ptr<ILinearAlgLoop> algLoop = shared_ptr<ILinearAlgLoop>());
  virtual shared_ptr<INonLinearAlgLoopSolver> createNonLinearAlgLoopSolver(shared_ptr<INonLinearAlgLoop> algLoop = shared_ptr<INonLinearAlgLoop>());
private:
  //std::vector<shared_ptr<IKinsolSettings> > _algsolversettings;
  std::vector<shared_ptr<INonLinSolverSettings> > _algsolversettings;
  std::vector<shared_ptr<ILinSolverSettings> > _linalgsolversettings;
  std::vector<shared_ptr<ILinearAlgLoopSolver> > _linear_algsolvers;
  std::vector<shared_ptr<INonLinearAlgLoopSolver> > _non_linear_algsolvers;
  shared_ptr<IGlobalSettings> _global_settings;
};
/** @} */ // end of coreSystem
