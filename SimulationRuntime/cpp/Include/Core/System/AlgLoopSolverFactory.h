#pragma once


#include <System/IAlgLoopSolverFactory.h>
#include <Solver/INonLinSolverSettings.h>
#include <SimulationSettings/IGlobalSettings.h>

/*****************************************************************************/
/**
Factory used by the system to create a solver for the solution of a (possibly
non-linear) system of the Form F(x)=0.
*/
#ifdef ANALYZATION_MODE
#include <SimCoreFactory/Policies/StaticNonLinSolverOMCFactory.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public StaticNonLinSolverOMCFactory<OMCFactory>
#else
#include <Policies/FactoryPolicy.h>
class AlgLoopSolverFactory : public IAlgLoopSolverFactory, public NonLinSolverPolicy
#endif
{
public:
    AlgLoopSolverFactory(IGlobalSettings*  gloabl_settings,PATH library_path,PATH modelicasystem_path);

    virtual ~AlgLoopSolverFactory();

    /// Creates a solver according to given system of equations of type algebraic loop
    virtual boost::shared_ptr<IAlgLoopSolver> createAlgLoopSolver(IAlgLoop* algLoop);

private:
  //std::vector<boost::shared_ptr<IKinsolSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<INonLinSolverSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<IAlgLoopSolver> > _algsolvers;
  IGlobalSettings*  _global_settings;
};
