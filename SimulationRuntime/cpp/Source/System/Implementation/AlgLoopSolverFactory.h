#pragma once

#include "../Interfaces/IAlgLoop.h"				// Interface for algebraic loops
#include "../Interfaces/IAlgLoopSolver.h"		// Interface for algebraic loops



#include "../Newton/Interfaces/INewtonSettings.h"

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
class AlgLoopSolverFactory
{
public:
	AlgLoopSolverFactory();

	 ~AlgLoopSolverFactory();

	/// Creates a solver according to given system of equations of type algebraic loop
	 IAlgLoopSolver* createAlgLoopSolver(IAlgLoop* algLoop);

private:
	boost::shared_ptr<INewtonSettings>_algsolversettings;
	boost::shared_ptr<IAlgLoopSolver> _algsolver;
};
