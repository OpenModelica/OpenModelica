
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
#include "stdafx.h"
#include "AlgLoopDefaultImplementation.h"



AlgLoopDefaultImplementation::AlgLoopDefaultImplementation()
:_dim					(NULL)
, _dimInputs			(NULL)
, _dimOutputs			(NULL)
, _doubleUnknownsInit	(NULL)
, _doubleUnknowns		(NULL)
, _doubleOutputs		(NULL)
, _doubleInputs			(NULL)
, _intUnknownsInit		(NULL)
, _intUnknowns			(NULL)
, _intOutputs			(NULL)
, _intInputs			(NULL)
, _boolUnknownsInit		(NULL)
, _boolUnknowns			(NULL)
, _boolOutputs			(NULL)
, _boolInputs			(NULL)
{
	// Allocate memory for dimensions
	_dim		= new int[3];
	_dimInputs	= new int[3];
	_dimOutputs	= new int[3];
}

AlgLoopDefaultImplementation::~AlgLoopDefaultImplementation()
{
	if(_dim)		delete [] _dim;
	if(_dimInputs)	delete [] _dimInputs;
	if(_dimOutputs)	delete [] _dimOutputs; 

	if(_doubleUnknownsInit)	delete [] _doubleUnknownsInit; 
	if(_doubleUnknowns)		delete [] _doubleUnknowns;

	if(_intUnknownsInit)	delete [] _intUnknownsInit;
	if(_intUnknowns)		delete [] _intUnknowns;

	if(_boolUnknownsInit)	delete [] _boolUnknownsInit;
	if(_boolUnknowns)		delete [] _boolUnknowns; 
}
/// Provide number (dimension) of variables according to data type
int AlgLoopDefaultImplementation::getDimVars(const IAlgLoop::DATATYPE type ) const	
{
	int i=0;
	if (type == IAlgLoop::REAL) 
		i+= _dim[0];
	if (type == IAlgLoop::INTEGER) 
		i+= _dim[1];
	if (type == IAlgLoop::BOOLEAN) 
		i+= _dim[2];
	return i;
};


/// Provide number (dimension) of residuals according to data type
int AlgLoopDefaultImplementation::getDimRHS(const IAlgLoop::DATATYPE type) const
{
	int i=0;
	if (type & IAlgLoop::REAL) 
		i+= _dim[0];
	if (type & IAlgLoop::INTEGER) 
		i+= _dim[1];
	if (type & IAlgLoop::BOOLEAN) 
		i+= _dim[2];
	return i;
};


/// Provide number (dimension) of inputs according to data type
int AlgLoopDefaultImplementation::getDimInputs(const IAlgLoop::DATATYPE type ) /*const*/	
{
	int i=0;
	if (type & IAlgLoop::REAL) 
		i+= _dimInputs[0];
	if (type & IAlgLoop::INTEGER) 
		i+= _dimInputs[1];
	if (type & IAlgLoop::BOOLEAN) 
		i+= _dimInputs[2];
	return i;
};


/// Provide number (dimension) of outputs according to data type
int AlgLoopDefaultImplementation::getDimOutputs(const IAlgLoop::DATATYPE type ) /*const*/	
{
	int i=0;
	if (type & IAlgLoop::REAL) 
		i+= _dimOutputs[0];
	if (type & IAlgLoop::INTEGER) 
		i+= _dimOutputs[1];
	if (type & IAlgLoop::BOOLEAN) 
		i+= _dimOutputs[2];
	return i;
};


/// Add inputs of algebraic loop
void AlgLoopDefaultImplementation::addInputs(const double* doubleInputs, const int* intInputs, const bool* boolInputs)
{
	_doubleInputs	= doubleInputs;
	_intInputs		= intInputs;
	_boolInputs		= boolInputs;
}


/// Add outputs of algebraic loop
void AlgLoopDefaultImplementation::addOutputs(double* doubleOutputs, int* intOutputs, bool* boolOutputs)
{
	_doubleOutputs	= doubleOutputs;
	_intOutputs		= intOutputs;
	_boolOutputs	= boolOutputs;
}


/// (Re-) initialize the system of equations
void AlgLoopDefaultImplementation::init()
{
	// Allocation of memory
	_doubleUnknownsInit = new double[_dim[0]];
	_doubleUnknowns = new double[_dim[0]];

	_intUnknownsInit = new int[_dim[1]];
	_intUnknowns = new int[_dim[1]];

	_boolUnknownsInit = new bool[_dim[2]];
	_boolUnknowns = new bool[_dim[2]];

	// initialization: init values = current value
	memset(_doubleUnknowns,0,_dim[0]*sizeof(double));
	memcpy(_intUnknowns,0,_dim[1]*sizeof(int));
	memcpy(_boolUnknowns,0,_dim[2]*sizeof(bool));

	memcpy(_doubleUnknownsInit,_doubleUnknowns,_dim[0]*sizeof(double));
	memcpy(_intUnknownsInit,_intUnknowns,_dim[1]*sizeof(int));
	memcpy(_boolUnknownsInit,_boolUnknowns,_dim[2]*sizeof(bool));
};


/// Provide variables with given index to the system
void AlgLoopDefaultImplementation::giveVars(double* doubleUnknowns, int* intUnknowns, bool* boolUnknowns)
{	
	// return unknowns (current values)
	memcpy(doubleUnknowns,_doubleUnknowns,_dim[0]*sizeof(double));
	memcpy(intUnknowns,_intUnknowns,_dim[1]*sizeof(int));
	memcpy(boolUnknowns,_boolUnknowns,_dim[2]*sizeof(bool));
};


/// Set variables with given index to the system
void AlgLoopDefaultImplementation::setVars(const double* doubleUnknowns, const int* intUnknowns, const bool* boolUnknowns)
{
	// set unknowns (current and initial values)
	memcpy(_doubleUnknowns,doubleUnknowns,_dim[0]*sizeof(double));
	memcpy(_intUnknowns,intUnknowns,_dim[1]*sizeof(int));
	memcpy(_boolUnknowns,boolUnknowns,_dim[2]*sizeof(bool));

	memcpy(_doubleUnknownsInit,_doubleUnknowns,_dim[0]*sizeof(double));
	memcpy(_intUnknownsInit,_intUnknowns,_dim[1]*sizeof(int));
	memcpy(_boolUnknownsInit,_boolUnknowns,_dim[2]*sizeof(bool));
};


/// Provide the right hand side (according to the index)
void AlgLoopDefaultImplementation::giveRHS(double* doubleResiduals, int* intResiduals, bool* boolResiduals)
{
	// return residual: Residuals = initial values (before) - current values (after update of alg loop)
	for(int i=0; i<_dim[0]; ++i)
		doubleResiduals[i] = _doubleUnknownsInit[i] - _doubleUnknowns[i];

	for(int i=0; i<_dim[1]; ++i)
		intResiduals[i] = _intUnknownsInit[i] - _intUnknowns[i];

	for(int i=0; i<_dim[2]; ++i)
		boolResiduals[i] = !(_boolUnknownsInit[i] ^ _boolUnknowns[i]);
};


/// Output routine (to be called by the solver after every successful integration step)
void AlgLoopDefaultImplementation::writeOutput(const IDAESystem::OUTPUT command )
{
	if (_outputStream)
	{
		// Write head line
		if (command & IDAESystem::HEAD_LINE)
		{
			for(int i=0; i<_dim[0]; ++i)
				*_outputStream << "\tdoubleUnknowns[" << i << "]"; 
			for(int i=0; i<_dim[1]; ++i)
				*_outputStream << "\tintUnknowns[" << i << "]"; 
			for(int i=0; i<_dim[2]; ++i)
				*_outputStream << "\tboolUnknowns[" << i << "]";
		}

		// Write the current values
		else
		{
			for(int i=0; i<_dim[0]; ++i)
				*_outputStream << _doubleUnknowns[i];

			for(int i=0; i<_dim[1]; ++i)
				*_outputStream << _intUnknowns[i];

			for(int i=0; i<_dim[2]; ++i)
				*_outputStream << _boolUnknowns[i];
		}
	}
};


/// Set stream for output
void AlgLoopDefaultImplementation::setOutput(ostream* outputStream) 
{
	_outputStream = outputStream;
};