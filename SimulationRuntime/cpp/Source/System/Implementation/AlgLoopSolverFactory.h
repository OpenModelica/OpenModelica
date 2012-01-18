#pragma once

#include "System/Interfaces/IAlgLoop.h"				// Interface for algebraic loops
#include "System/Interfaces/IAlgLoopSolver.h"		// Interface for algebraic loops
#include "System/Newton/Interfaces/INewtonSettings.h"
#include "System/Interfaces/IAlgLoopSolverFactory.h"	
/*****************************************************************************/
/**

Factory used by the system to create a solver for the solution of a (possibly 
non-linear) system of the Form F(x)=0. 

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class AlgLoopSolverFactory : public IAlgLoopSolverFactory
{
public:
	AlgLoopSolverFactory();

	 ~AlgLoopSolverFactory();

	/// Creates a solver according to given system of equations of type algebraic loop
	virtual boost::shared_ptr<IAlgLoopSolver> createAlgLoopSolver(IAlgLoop* algLoop);

private:
	boost::shared_ptr<INewtonSettings>_algsolversettings;
	boost::shared_ptr<IAlgLoopSolver> _algsolver;
};
