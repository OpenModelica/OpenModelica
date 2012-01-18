#pragma once

#include "IDAESystem.h"
#include "IContinous.h"

/*****************************************************************************/
/**

Abstract interface class for algebraic loop in equations in open modelica.

\date     October, 1st, 2008
\author   

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IAlgLoop 
{
public:
	/// Enumeration with modelica data types
	enum DATATYPE
	{
		UNDEF	=	0x00000000,
		REAL	=	0x00000001,
		INTEGER	=	0x00000002,
		BOOLEAN	=	0x00000004,
		ALL		=	0x00000007,
	};

	virtual ~IAlgLoop()	{};

	/// Provide number (dimension) of variables according to the data type
	virtual int getDimVars(const DATATYPE type = ALL) const = 0;

	/// Provide number (dimension) of right hand sides (residuals) according to the data type
	virtual int getDimRHS(const DATATYPE type = ALL) const = 0;

	/// Provide number (dimension) of inputs according to data type
	virtual int getDimInputs(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) /*const*/ = 0;

	/// Provide number (dimension) of outputs according to data type
	virtual int getDimOutputs(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) /*const*/ = 0;

	/// Add inputs of algebraic loop
	virtual void addInputs(const double* doubleInputs, const int* intInputs, const bool* boolInputs) = 0;

	/// Add outputs of algebraic loop
	virtual void addOutputs(double* doubleOutputs, int* intOutputs, bool* boolOutputs) = 0;

	/// (Re-) initialize the system of equations
	virtual void init() = 0;

	/// Provide variables of given data type 
	virtual void giveVars(double* doubleVars, int* intVars, bool* boolVars) = 0;

	/// Set variables with given data type
	virtual void setVars(const double* doubleVars, const int* intVars, const bool* boolVars) = 0;

	/// Update transfer behavior of the system of equations according to command given by solver
	virtual void update(const IContinous::UPDATE command = IContinous::UNDEF_UPDATE) = 0;

	/// Provide the right hand side (according to the index)
	virtual void giveRHS(double* doubleFuncs, int* intFuncs, bool* boolFuncs) = 0;
	virtual void giveAMatrix(double* A_matrix) = 0;
	virtual bool isLinear() = 0;
};
