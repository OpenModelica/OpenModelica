
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
#include "stdafx.h"
#include "AlgLoopDefaultImplementation.h"



AlgLoopDefaultImplementation::AlgLoopDefaultImplementation()
:_dim					(NULL)
, _dimInputs			(NULL)
, _dimOutputs			(NULL)
, _xd_init	(NULL)
, _xd		(NULL)
, _doubleOutputs		(NULL)
, _doubleInputs			(NULL)
, _xi_init		(NULL)
, _xi			(NULL)
, _intOutputs			(NULL)
, _intInputs			(NULL)
, _xb_init		(NULL)
, _xb			(NULL)
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

	if(_xd_init)	delete [] _xd_init; 
	if(_xd)		delete [] _xd;

	if(_xi_init)	delete [] _xi_init;
	if(_xi)		delete [] _xi;

	if(_xb_init)	delete [] _xb_init;
	if(_xb)		delete [] _xb; 
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
	_xd_init = new double[_dim[0]];
	_xd = new double[_dim[0]];

	_xi_init = new int[_dim[1]];
	_xi = new int[_dim[1]];

	_xb_init = new bool[_dim[2]];
	_xb = new bool[_dim[2]];

	// initialization: init values = current value
	memset(_xd,0,_dim[0]*sizeof(double));
	memcpy(_xi,0,_dim[1]*sizeof(int));
	memcpy(_xb,0,_dim[2]*sizeof(bool));

	memcpy(_xd_init,_xd,_dim[0]*sizeof(double));
	memcpy(_xi_init,_xi,_dim[1]*sizeof(int));
	memcpy(_xb_init,_xb,_dim[2]*sizeof(bool));
};


/// Provide variables with given index to the system
void AlgLoopDefaultImplementation::giveVars(double* doubleUnknowns, int* intUnknowns, bool* boolUnknowns)
{	
	// return unknowns (current values)
	memcpy(doubleUnknowns,_xd,_dim[0]*sizeof(double));
	memcpy(intUnknowns,_xi,_dim[1]*sizeof(int));
	memcpy(boolUnknowns,_xb,_dim[2]*sizeof(bool));
};


/// Set variables with given index to the system
void AlgLoopDefaultImplementation::setVars(const double* doubleUnknowns, const int* intUnknowns, const bool* boolUnknowns)
{
	// set unknowns (current and initial values)
	memcpy(_xd,doubleUnknowns,_dim[0]*sizeof(double));
	memcpy(_xi,intUnknowns,_dim[1]*sizeof(int));
	memcpy(_xb,boolUnknowns,_dim[2]*sizeof(bool));

	memcpy(_xd_init,_xd,_dim[0]*sizeof(double));
	memcpy(_xi_init,_xi,_dim[1]*sizeof(int));
	memcpy(_xb_init,_xb,_dim[2]*sizeof(bool));
};


/// Provide the right hand side (according to the index)
void AlgLoopDefaultImplementation::giveRHS(double* doubleResiduals, int* intResiduals, bool* boolResiduals)
{
	// return residual: Residuals = initial values (before) - current values (after update of alg loop)
	for(int i=0; i<_dim[0]; ++i)
		doubleResiduals[i] = _xd_init[i] - _xd[i];

	for(int i=0; i<_dim[1]; ++i)
		intResiduals[i] = _xi_init[i] - _xi[i];

	for(int i=0; i<_dim[2]; ++i)
		boolResiduals[i] = !(_xb_init[i] ^ _xb[i]);
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
				*_outputStream << _xd[i];

			for(int i=0; i<_dim[1]; ++i)
				*_outputStream << _xi[i];

			for(int i=0; i<_dim[2]; ++i)
				*_outputStream << _xb[i];
		}
	}
};


/// Set stream for output
void AlgLoopDefaultImplementation::setOutput(ostream* outputStream) 
{
	_outputStream = outputStream;
};