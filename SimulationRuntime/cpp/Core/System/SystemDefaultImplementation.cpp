
#include "stdafx.h"
#define BOOST_EXTENSION_SYSTEM_DECL BOOST_EXTENSION_EXPORT_DECL
#define BOOST_EXTENSION_ALGLOOPDEFAULTIMPL_DECL BOOST_EXTENSION_EXPORT_DECL
 
#include <System/SystemDefaultImplementation.h>
#include "AlgLoopSolverFactory.h"
#include <System/EventHandling.h>
#include <System/AlgLoopDefaultImplementation.h>
#include <LibrariesConfig.h>
SystemDefaultImplementation::SystemDefaultImplementation(IGlobalSettings& globalSettings)
: time  (0.0)
, __z  (NULL)
, __zDot       (NULL)
, _dimODE     (0)
,_conditions(NULL)

{

 /* fs::path newton_name(NEWTON_LIB);
  fs::path newton_path = globalSettings.getRuntimeLibrarypath();
  newton_path/=newton_name;

  newton_path.make_preferred();
  type_map types;
  if(!load_single_library(types,  newton_path.string()))
     throw std::invalid_argument("Newton library could not be loaded");*/

}

SystemDefaultImplementation::~SystemDefaultImplementation()
{
  if(__z) delete [] __z;
  if(__zDot) delete [] __zDot;
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

int SystemDefaultImplementation::getDimVars() const    
{
  return _dimVars;
};


/// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int SystemDefaultImplementation::getDimRHS() const
{

    return _dimFunc;
};


/// (Re-) initialize the system of equations
 void SystemDefaultImplementation::init()
{
   
    
    if((_dimVars) > 0)
    {
  // Initialize "extended state vector"
    if(__z) delete [] __z ; 
    if(__zDot) delete [] __zDot;

    __z = new double[_dimVars];
    __zDot = new double[_dimFunc];

    memset(__z,0,(_dimVars)*sizeof(double));
    memset(__zDot,0,(_dimFunc)*sizeof(double));
  }
  if(_dimZeroFunc > 0)
  {
    if(_conditions) delete [] _conditions ; 
   
    _conditions = new bool[_dimZeroFunc];
  
    memset(_conditions,false,(_dimZeroFunc)*sizeof(bool));
  
  }
};


/// Set current integration time
void SystemDefaultImplementation::setTime(const double& t)
{
    time = t;
};


/// Provide variables with given index to the system
void SystemDefaultImplementation::giveVars(double* z)
{ 
  
 
    for(int i=0; i< _dimVars; ++i)
    {
      z[i] = __z[i];
    }

};


/// Set variables with given index to the system
void SystemDefaultImplementation::setVars(const double* z)
{
  
 
    for(int i=0; i<_dimVars; ++i)
    {
      __z[i] = z[i];
    }

};


/// Provide the right hand side (according to the index)
void SystemDefaultImplementation::giveRHS(double* f)
{
 
     for(int i=0; i<_dimFunc; ++i)
      f[i] = __zDot[i];

};


using boost::extensions::factory;


