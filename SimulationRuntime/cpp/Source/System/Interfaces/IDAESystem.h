#pragma once


//#include "API.h"
//#include <ostream>									// Use stream for output
//using std::ostream;

/*****************************************************************************/
/**

Abstract interface class for possibly hybrid (continous and discrete) 
systems of equations in open modelica.

\date     October, 1st, 2008
\author   

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
/// typedef for sparse matrices
typedef double* SparcityPattern;
typedef double* SparseMatrix;
class IDAESystem 
{
public:
	
	/// Enumeration to control the output
	enum OUTPUT
	{
		UNDEF_OUTPUT	=	0x00000000,

		WRITE			=	0x00000001,			///< Store current position of curser and write out current results
		RESET			=	0x00000002,			///< Reset curser position
		OVERWRITE		=	0x00000003,			///< RESET|WRITE

		HEAD_LINE		=	0x00000010,			///< Write out head line
		RESULTS			=	0x00000020,			///< Write out results
		SIMINFO			=	0x00000040			///< Write out simulation info (e.g. number of steps)
	};
    virtual void destroy() = 0;
	virtual ~IDAESystem()	{};
	
	/// Output routine (to be called by the solver after every successful integration step)
	virtual void writeOutput(const OUTPUT command = UNDEF_OUTPUT) = 0;

	/// Provide pattern for Jacobian
	virtual void giveJacobianSparsityPattern(SparcityPattern pattern) = 0;

	/// Provide Jacobian
	virtual void giveJacobian(SparseMatrix matrix) = 0;

	/// Provide pattern for mass matrix
	virtual void giveMassSparsityPattern(SparcityPattern pattern) = 0;

	/// Provide mass matrix
	virtual void giveMassMatrix(SparseMatrix matrix) = 0;

	/// Provide pattern for global constraint jacobian
	virtual void giveConstraintSparsityPattern(SparcityPattern pattern) = 0;

	/// Provide global constraint jacobian
	virtual void giveConstraint(SparseMatrix matrix) = 0;
};
//// Factory function to instantiate the modelica system class
//extern "C" DLL_EXPORT IDAESystem* createModelicaSystem(IGlobalSettings& globalSettings);
