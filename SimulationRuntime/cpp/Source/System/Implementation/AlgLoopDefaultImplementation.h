#pragma once

#include "System/Interfaces/IAlgLoop.h"					// Interface for algebraic loop

#include "Math/Implementation/Functions.h"	// Include for use of abs



#include <ostream>									// Use stream for output
using std::ostream;

/*****************************************************************************/
/**

Services for the implementation of an algebraic loop in open modelica. 

\date     October, 1st, 2008
\author

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL AlgLoopDefaultImplementation
{
public:
	AlgLoopDefaultImplementation();

	~AlgLoopDefaultImplementation();


	/// Provide number (dimension) of variables according to data type
	int getDimVars(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) const;


	/// Provide number (dimension) of residuals according to data type
	int getDimRHS(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) const;


	/// Provide number (dimension) of inputs according to data type
	int getDimInputs(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) ;


	/// Provide number (dimension) of outputs according to data type
	int getDimOutputs(const IAlgLoop::DATATYPE type = IAlgLoop::ALL) ;


	/// Add inputs of algebraic loop
	void addInputs(const double* doubleInputs, const int* intInputs, const bool* boolInputs);


	/// Add outputs of algebraic loop
	void addOutputs(double* doubleOutputs, int* intOutputs, bool* boolOutputs);
	

	
	/// (Re-) initialize the system of equations
	void init()	;


	/// Provide variables with given index to the system
	void giveVars(double* doubleUnknowns, int* intUnknowns, bool* boolUnknowns);


	/// Set variables with given index to the system
	void setVars(const double* doubleUnknowns, const int* intUnknowns, const bool* boolUnknowns);


	/// Provide the right hand side (according to the index)
	void giveRHS(double* doubleResiduals, int* intResiduals, bool* boolResiduals);


	/// Output routine (to be called by the solver after every successful integration step)
	void writeOutput(const IDAESystem::OUTPUT command = IDAESystem::UNDEF_OUTPUT);


	/// Set stream for output
	void setOutput(ostream* outputStream) ;


	// Member variables
	//---------------------------------------------------------------
protected:
	int
		*_dim,						///< Number (dimension) of unknown/equations (the index denotes the data type; 0: double, 1: int, 2: bool)
		*_dimInputs,				///< Number (dimension) of inputs
		*_dimOutputs;				///< Number (dimension) of outputs

	double 
		*_doubleUnknownsInit,		///< Double values before update of loop
		*_doubleUnknowns,			///< Double values after update of loop
		*_doubleOutputs;			///< Double outputs of loop 

	const double
		*_doubleInputs;				///< Double inputs of loop 

	int 
		*_intUnknownsInit,			///< Integer values before update of loop
		*_intUnknowns,				///< Integer values after update of loop
		*_intOutputs;				///< Integer outputs of loop 
									
	const int						
		*_intInputs;				///< Integer inputs of loop 

	bool 
		*_boolUnknownsInit,			///< Boolean values before update of loop
		*_boolUnknowns,				///< Boolean values after update of loop
		*_boolOutputs;				///< Boolean outputs of loop 
									
	const bool						
		*_boolInputs;				///< Boolean inputs of loop 

	ostream
		*_outputStream;				///< Output stream for results
};
