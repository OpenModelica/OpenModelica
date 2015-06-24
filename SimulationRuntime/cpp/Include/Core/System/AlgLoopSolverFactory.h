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
/*includes removed for static linking not needed any more
#ifdef RUNTIME_STATIC_LINKING
#include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
#include <SimCoreFactory/Policies/StaticLinSolverOMCFactory.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public StaticNonLinSolverOMCFactory<OMCFactory>, public StaticLinSolverOMCFactory<OMCFactory>
includes removed for static linking not needed any more
#else
*/
#include <SimCoreFactory/Policies/FactoryPolicy.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public NonLinSolverPolicy, public LinSolverPolicy
/*#endif*/
{
public:
  AlgLoopSolverFactory(IGlobalSettings* gloabl_settings, PATH library_path, PATH modelicasystem_path);
  virtual ~AlgLoopSolverFactory();

  /// Creates a solver according to given system of equations of type algebraic loop
  virtual boost::shared_ptr<IAlgLoopSolver> createAlgLoopSolver(IAlgLoop* algLoop);

private:
  //std::vector<boost::shared_ptr<IKinsolSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<INonLinSolverSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<ILinSolverSettings> > _linalgsolversettings;
  std::vector<boost::shared_ptr<IAlgLoopSolver> > _algsolvers;
  IGlobalSettings* _global_settings;
};
/** @} */ // end of coreSystem
