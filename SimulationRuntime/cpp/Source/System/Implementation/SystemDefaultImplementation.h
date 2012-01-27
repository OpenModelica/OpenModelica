#pragma once

#include "System/Interfaces/IDAESystem.h"				// System interface
#include "System/Interfaces/IContinous.h"				// System interface
#include "System/Interfaces/IEvent.h"				// System interface
#include "System/Interfaces/ISystemProperties.h"				// System interface
#include "Math/Implementation/Functions.h"	// Include for use of abs





/*****************************************************************************/
/**

Services, which can be used by systems. 
Implementation of standart functions (e.g. giveRHS(...), etc.). 
Provision of member variables used by all systems.

Note: 
The order of variables in the extended state vector perserved (see: "Sorting 
variables by using the index" in "Design proposal for a general solver interface 
for Open Modelica", September, 10 th, 2008


\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/


class BOOST_EXTENSION_SYSTEM_DECL SystemDefaultImplementation
{
public:
	SystemDefaultImplementation();

	~SystemDefaultImplementation();
	
	/// Provide number (dimension) of variables according to the index
	 int getDimVars(const IContinous::INDEX index = IContinous::ALL_VARS) const	;


	/// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
	 int getDimRHS(const IContinous::INDEX index = IContinous::ALL_VARS) const;


	/// (Re-) initialize the system of equations
	 void init();
	/// Set current integration time
	 void setTime(const double& t);


	/// Provide variables with given index to the system
	void giveVars(double* z, const IContinous::INDEX index = IContinous::ALL_VARS);

	/// Set variables with given index to the system
	void setVars(const double* z, const IContinous::INDEX index = IContinous::ALL_VARS);
	


	/// Provide the right hand side (according to the index)
	void giveRHS(double* f, const IContinous::INDEX index = IContinous::ALL_VARS);
	
	// Member variables
	//---------------------------------------------------------------
protected:
     void Assert(bool cond,string msg);
	 void Terminate(string msg); 
	 bool initial();
	double
		time;				///< current simulation time (given by the solver) 

	double
		*_z,				///< "Extended state vector", containing all states and algebraic variables of all types
		*_zDot;				///< "Extended vector of derivatives", containing all right hand sides of differential and algebraic equations

	ostream
		*_outputStream;		///< Output stream for results

	int		
		_dimODE1stOrder,	///< Number (dimension) of first order ordinary differential equations 
		_dimODE2ndOrder,	///< Number (dimension) of second order ordinary differential equations (RHS of a mechanical system)
		_dimResidues,       ///< Number of residues
		_dimAE;				///< Number (dimension) of algebraic equations (e.g. constraints from an algebraic loop)
	bool _initial;		

private:
	int
		_dimODE;			///< Total number (dimension) of all order ordinary differential equations (first and second order)

};

