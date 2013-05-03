#pragma once

#include <System/IAlgLoop.h>        // Interface for algebraic loops
#include <System/IAlgLoopSolverFactory.h>
#include <Solver/IAlgLoopSolver.h>        // Interface for algebraic loops
#include <Solver/INonLinSolverSettings.h>
#include <SimulationSettings/IGlobalSettings.h>
#include <boost/filesystem/path.hpp>
/*****************************************************************************/
/**
Factory used by the system to create a solver for the solution of a (possibly
non-linear) system of the Form F(x)=0.
*/
class AlgLoopSolverFactory : public IAlgLoopSolverFactory
{
public:
    AlgLoopSolverFactory(IGlobalSettings&  gloabl_settings);

     ~AlgLoopSolverFactory();

    /// Creates a solver according to given system of equations of type algebraic loop
    virtual boost::shared_ptr<IAlgLoopSolver> createAlgLoopSolver(IAlgLoop* algLoop);

private:
  //std::vector<boost::shared_ptr<IKinsolSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<INonLinSolverSettings> > _algsolversettings;
  std::vector<boost::shared_ptr<IAlgLoopSolver> > _algsolvers;
   boost::filesystem::path _libraries_path;
   IGlobalSettings&  _global_settings;
};
