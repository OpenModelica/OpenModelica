
#include "stdafx.h"
#include "FactoryExport.h"
#include <System/SystemDefaultImplementation.h>
#include <System/AlgLoopSolverFactory.h>


SystemDefaultImplementation::SystemDefaultImplementation(IGlobalSettings& globalSettings)
: _simTime        (0.0)
, __z        (NULL)
, __zDot       (NULL)
,_conditions(NULL)
,_time_conditions(NULL)
,_time_event_counter(NULL)

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
        throw std::runtime_error(msg);
}

void SystemDefaultImplementation::Terminate(string msg)
{
    throw std::runtime_error(msg);
}

int SystemDefaultImplementation::getDimBoolean() const
{
    return _dimBoolean;
}

int SystemDefaultImplementation::getDimContinuousStates() const
{
    return _dimContinuousStates;
}

int SystemDefaultImplementation::getDimInteger() const
{
    return _dimInteger;
}

int SystemDefaultImplementation::getDimReal() const
{
    return _dimReal;
}

int SystemDefaultImplementation::getDimString() const
{
    return _dimString;
}

/// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int SystemDefaultImplementation::getDimRHS() const
{

    return _dimRHS;
};


/// (Re-) initialize the system of equations
void SystemDefaultImplementation::initialize()
{
    _callType = IContinuous::CONTINUOUS;
    if((_dimContinuousStates) > 0)
    {
        // Initialize "extended state vector"
    if(__z) delete [] __z ; 
    if(__zDot) delete [] __zDot;

    __z = new double[_dimContinuousStates];
    __zDot = new double[_dimContinuousStates];

    memset(__z,0,(_dimContinuousStates)*sizeof(double));
    memset(__zDot,0,(_dimContinuousStates)*sizeof(double));
  }
  if(_dimZeroFunc > 0)
  {
    if(_conditions) delete [] _conditions ; 
   
    _conditions = new bool[_dimZeroFunc];
  
    memset(_conditions,false,(_dimZeroFunc)*sizeof(bool));
  
  }
  if(_dimTimeEvent > 0)
  {
    if(_time_conditions) delete [] _time_conditions ; 
    if(_time_event_counter) delete [] _time_event_counter;
    _time_conditions = new bool[_dimTimeEvent];
   
   
   _time_event_counter = new int[_dimTimeEvent];
   
   memset(_time_conditions,false,(_dimTimeEvent)*sizeof(bool));
    memset(_time_event_counter,0,(_dimTimeEvent)*sizeof(int));
  }
  
};


/// Set current integration time
void SystemDefaultImplementation::setTime(const double& t)
{
    _simTime = t;
};


/// getter for variables of different types
void SystemDefaultImplementation::getBoolean(bool* z)
{ 
    for(int i=0; i< _dimBoolean; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::getReal(double* z)
{ 
    for(int i=0; i< _dimReal; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::getInteger(int* z)
{ 
    for(int i=0; i< _dimInteger; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::getString(string* z)
{ 
    for(int i=0; i< _dimString; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::getContinuousStates(double* z)
{ 
    for(int i=0; i< _dimContinuousStates; ++i)
    {
        z[i] = __z[i];
    }

};





/// setter for variables of different types

void SystemDefaultImplementation::setBoolean(const bool* z)
{ 
    for(int i=0; i< _dimBoolean; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::setInteger(const int* z)
{ 
    for(int i=0; i< _dimInteger; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::setString(const string* z)
{ 
    for(int i=0; i< _dimString; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::setReal(const double* z)
{ 
    for(int i=0; i< _dimReal; ++i)
    {
      //z[i] = __z[i];
    // TODO: insert Code here
    }

};

void SystemDefaultImplementation::setContinuousStates(const double* z)
{
    for(int i=0; i<_dimContinuousStates; ++i)
    {
      __z[i] = z[i];
    }

};

void SystemDefaultImplementation::setRHS(const double* f)
{
    for(int i=0; i<_dimRHS; ++i)
    {
      __zDot[i] = f[i];
    }

};


/// Provide the right hand side (according to the index)
void SystemDefaultImplementation::getRHS(double* f)
{
 
     for(int i=0; i<_dimRHS; ++i)
      f[i] = __zDot[i];

};

