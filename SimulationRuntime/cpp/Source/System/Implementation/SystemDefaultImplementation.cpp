#include "stdafx.h"
#define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
#include "SystemDefaultImplementation.h"
#include "AlgLoopSolverFactory.h"
#include "Eventhandling.h"
#include "Algloopdefaultimplementation.h"

SystemDefaultImplementation::SystemDefaultImplementation()
: time				(0.0)
, _z				(NULL)
, _zDot				(NULL)
, _dimODE			(0)
{
}

SystemDefaultImplementation::~SystemDefaultImplementation()
{
	if(_z) delete [] _z;
	if(_zDot) delete [] _zDot;
}
void SystemDefaultImplementation::Assert(bool cond,string msg)
{
	if(!cond)
		throw std::runtime_error(msg);
}

void SystemDefaultImplementation::Terminate(string msg)
{
	throw std::runtime_error(msg);
}

int SystemDefaultImplementation::getDimVars(const IContinous::INDEX index) const	
{
	int i=0;
	if (index & IContinous::VAR_INDEX0) 
		i+= _dimODE1stOrder;
	if (index & IContinous::VAR_INDEX1) 
		i+= _dimODE2ndOrder/2;
	if (index & IContinous::VAR_INDEX2) 
		i+= _dimODE2ndOrder/2;
	if (index & IContinous::VAR_INDEX3) 
		i+= _dimAE;
	return i;
};


/// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int SystemDefaultImplementation::getDimRHS(const IContinous::INDEX index) const
{
	int i=0;
	if (index & IContinous::VAR_INDEX0) 
		i+= _dimODE1stOrder;
	if (index & IContinous::VAR_INDEX1) 
		i+= _dimODE2ndOrder/2;
	if (index & IContinous::VAR_INDEX2) 
		i+= _dimODE2ndOrder/2;

	if (index & IContinous::DIFF_INDEX3) 
		i+= _dimAE;
	else if (index & IContinous::DIFF_INDEX2) 
		i+= _dimAE;
	else if (index & IContinous::DIFF_INDEX1) 
		i+= _dimAE;

	return i;
};


/// (Re-) initialize the system of equations
 void SystemDefaultImplementation::init()
{
	_dimODE	= _dimODE1stOrder + _dimODE2ndOrder;

	if((_dimODE + _dimAE) > 0)
	{
		// Initialize "extended state vector"
		if(_z) delete [] _z ; 
		if(_zDot) delete [] _zDot;

		_z = new double[_dimODE + _dimAE];
		_zDot = new double[_dimODE + _dimAE];

		memset(_z,0,(_dimODE + _dimAE)*sizeof(double));
		memset(_zDot,0,(_dimODE + _dimAE)*sizeof(double));
	}
};


/// Set current integration time
void SystemDefaultImplementation::setTime(const double& t)
{
	time = t;
};


/// Provide variables with given index to the system
void SystemDefaultImplementation::giveVars(double* z, const IContinous::INDEX index)
{	
	int j = 0;
	if (index & IContinous::VAR_INDEX0)
	{
		for(int i=0; i<_dimODE1stOrder; ++i)
		{
			z[i] = _z[i];
		}

		j += _dimODE1stOrder;

	}

	if (index & IContinous::VAR_INDEX1)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
		{
			z[i + j] = _z[_dimODE1stOrder + i];
		}

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX2)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
		{
			z[i + j] = _z[_dimODE1stOrder + _dimODE2ndOrder/2 + i];
		}

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX3)
	{
		for(int i=0; i<_dimAE; ++i)
		{
			z[i + j] = _z[_dimODE + i];
		}
	}			
};


/// Set variables with given index to the system
void SystemDefaultImplementation::setVars(const double* z, const IContinous::INDEX index)
{
	int j = 0;
	if (index & IContinous::VAR_INDEX0)
	{
		for(int i=0; i<_dimODE1stOrder; ++i)
		{
			_z[i] = z[i];
		}

		j += _dimODE1stOrder;

	}

	if (index & IContinous::VAR_INDEX1)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
		{
			_z[_dimODE1stOrder + i] = z[i + j];
		}

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX2)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
		{
			_z[_dimODE1stOrder + _dimODE2ndOrder/2 + i] = z[i + j];
		}

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX3)
	{
		for(int i=0; i<_dimAE; ++i)
		{
			_z[_dimODE + i] = z[i + j];
		}
	}

};


/// Provide the right hand side (according to the index)
void SystemDefaultImplementation::giveRHS(double* f, const IContinous::INDEX index)
{
	int j = 0;
	if (index & IContinous::VAR_INDEX0)
	{
		for(int i=0; i<_dimODE1stOrder; ++i)
			f[i] = _zDot[i];

		j += _dimODE1stOrder;
	}

	if (index & IContinous::VAR_INDEX1)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
			f[i + j] = _zDot[_dimODE1stOrder + i];

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX2)
	{
		for(int i=0; i<_dimODE2ndOrder/2; ++i)
			f[i + j] = _zDot[_dimODE1stOrder + _dimODE2ndOrder/2 + i];

		j += _dimODE2ndOrder/2;
	}

	if (index & IContinous::VAR_INDEX3)
	{
		for(int i=0; i<_dimAE; ++i)
			f[i + j] = _zDot[_dimODE + i];
	}

	// Here one can distinguish between the residuals of the algeraic constraints according to the differentiation 
	// index. Therefor check for condition DIFF_INDEX3, DIFF_INDEX2, DIFF_INDEX1. If one needs more than one contraint
	// at once, make sure the size of th state vector is enhanced.
};

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  /*types.get<std::map<std::string, factory<SystemDefaultImplementation> > >()
    ["SystemDefaultImplementation"].set<SystemDefaultImplementation>();*/
  types.get<std::map<std::string, factory<AlgLoopDefaultImplementation> > >()
    ["AlgLoopDefaultImplementation"].set<AlgLoopDefaultImplementation>();
  types.get<std::map<std::string, factory<AlgLoopSolverFactory> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();
  /* types.get<std::map<std::string, factory<EventHandling> > >()
    ["EventHandling"].set<EventHandling>();*/

}