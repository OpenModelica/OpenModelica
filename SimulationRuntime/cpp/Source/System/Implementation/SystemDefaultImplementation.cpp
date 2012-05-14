#include "stdafx.h"
#define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_EVENTHANDLING_DECL BOOST_EXTENSION_EXPORT_DECL
#include "SystemDefaultImplementation.h"
#include "AlgLoopSolverFactory.h"
#include "Eventhandling.h"
#include "Algloopdefaultimplementation.h"

SystemDefaultImplementation::SystemDefaultImplementation()
: time        (0.0)
, __z        (NULL)
, __zDot       (NULL)
, _dimODE     (0)
,_conditions0(NULL)
,_conditions1(NULL)
{
}

SystemDefaultImplementation::~SystemDefaultImplementation()
{
  if(__z) delete [] __z;
  if(__zDot) delete [] __zDot;
}
void SystemDefaultImplementation::Assert(bool cond,string msg)
{
  if(!cond)
    //throw std::runtime_error(msg);
    //cout << msg << std::endl;
    cout << "";
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
    
  if (index & IContinous::ALL_RESIDUES)
    i+= _dimResidues;

  return i;
};


/// (Re-) initialize the system of equations
 void SystemDefaultImplementation::init()
{
  _dimODE = _dimODE1stOrder + _dimODE2ndOrder;

  if((_dimODE + _dimAE) > 0)
  {
    // Initialize "extended state vector"
    if(__z) delete [] __z ; 
    if(__zDot) delete [] __zDot;

    __z = new double[_dimODE + _dimAE];
    __zDot = new double[_dimODE + _dimAE];

    memset(__z,0,(_dimODE + _dimAE)*sizeof(double));
    memset(__zDot,0,(_dimODE + _dimAE)*sizeof(double));
  }
  if(_dimZeroFunc > 0)
  {
    if(_conditions0) delete [] _conditions0 ; 
    if(_conditions1) delete [] _conditions1;
    _conditions0 = new bool[_dimZeroFunc];
    _conditions1 = new bool[_dimZeroFunc];
    memset(_conditions0,false,(_dimZeroFunc)*sizeof(bool));
    memset(_conditions1,false,(_dimZeroFunc)*sizeof(bool));
  }
};
 void SystemDefaultImplementation::saveConditions()
 {
  memcpy(_conditions0,_conditions1,_dimZeroFunc*sizeof(bool));
 }

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
      z[i] = __z[i];
    }

    j += _dimODE1stOrder;

  }

  if (index & IContinous::VAR_INDEX1)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
    {
      z[i + j] = __z[_dimODE1stOrder + i];
    }

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX2)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
    {
      z[i + j] = __z[_dimODE1stOrder + _dimODE2ndOrder/2 + i];
    }

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX3)
  {
    for(int i=0; i<_dimAE; ++i)
    {
      z[i + j] = __z[_dimODE + i];
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
      __z[i] = z[i];
    }

    j += _dimODE1stOrder;

  }

  if (index & IContinous::VAR_INDEX1)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
    {
      __z[_dimODE1stOrder + i] = z[i + j];
    }

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX2)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
    {
      __z[_dimODE1stOrder + _dimODE2ndOrder/2 + i] = z[i + j];
    }

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX3)
  {
    for(int i=0; i<_dimAE; ++i)
    {
      __z[_dimODE + i] = z[i + j];
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
      f[i] = __zDot[i];

    j += _dimODE1stOrder;
  }

  if (index & IContinous::VAR_INDEX1)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
      f[i + j] = __zDot[_dimODE1stOrder + i];

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX2)
  {
    for(int i=0; i<_dimODE2ndOrder/2; ++i)
      f[i + j] = __zDot[_dimODE1stOrder + _dimODE2ndOrder/2 + i];

    j += _dimODE2ndOrder/2;
  }

  if (index & IContinous::VAR_INDEX3)
  {
    for(int i=0; i<_dimAE; ++i)
      f[i + j] = __zDot[_dimODE + i];
  }

  // Here one can distinguish between the residuals of the algeraic constraints according to the differentiation 
  // index. Therefor check for condition DIFF_INDEX3, DIFF_INDEX2, DIFF_INDEX1. If one needs more than one contraint
  // at once, make sure the size of th state vector is enhanced.
};

using boost::extensions::factory;

BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  /*types.get<std::map<std::string, factory<SystemDefaultImplementation> > >()
    ["SystemDefaultImplementation"].set<SystemDefaultImplementation>();
  types.get<std::map<std::string, factory<AlgLoopDefaultImplementation> > >()
    ["AlgLoopDefaultImplementation"].set<AlgLoopDefaultImplementation>();
*/
   types.get<std::map<std::string, factory<IAlgLoopSolverFactory> > >()
    ["AlgLoopSolverFactory"].set<AlgLoopSolverFactory>();   /* 
 types.get<std::map<std::string, factory<EventHandling> > >()
    ["EventHandling"].set<EventHandling>();*/

}
