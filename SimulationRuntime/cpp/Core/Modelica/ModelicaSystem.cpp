#include "stdafx.h"

#include "ModelicaSystem.h"



Modelica::Modelica(IGlobalSettings* globalSettings,boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory,boost::shared_ptr<ISimData> ) 
:SystemDefaultImplementation(*globalSettings)

{ 
    _dimBoolean =0;
    _dimInteger =0;
    _dimString =0;
    _dimReal =0;
    _dimContinuousStates =0;
    _dimRHS = 0;
    //DAE's are not supported yet, Index reduction is enabled
    _dimAE = 0; // algebraic equations
    // Initialize the state vector
    SystemDefaultImplementation::initialize();
    //Instantiate auxiliary object for event handling functionality
    //vxworkstodo linker fehler: _event_handling.resetHelpVar =  boost::bind(&Modelica::resetHelpVar, this, _1);
    _historyImpl = new HistoryImplType(*globalSettings);
} 

Modelica::~Modelica()
{
delete _historyImpl;
}

void Modelica::initialize(double ts,double te)
{

}

void Modelica::resetTimeEvents()
{
}


bool Modelica::evaluate(const UPDATETYPE command)
{
  return false;
}

void Modelica::writeOutput(const OUTPUT command)
{


}

// Release instance
void Modelica::destroy()
{
  delete this;
}

// Set current integration time
void Modelica::setTime(const double& t)
{
  SystemDefaultImplementation::setTime(t);
}



// Provide number (dimension) of variables
int Modelica::getDimBoolean() const
{
  return(SystemDefaultImplementation::getDimBoolean());
}

int Modelica::getDimInteger() const
{
  return(SystemDefaultImplementation::getDimInteger());
}

int Modelica::getDimString() const
{
  return(SystemDefaultImplementation::getDimString());
}

int Modelica::getDimReal() const
{
  return(SystemDefaultImplementation::getDimReal());
}

int Modelica::getDimContinuousStates() const
{
  return(SystemDefaultImplementation::getDimContinuousStates());
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int Modelica::getDimRHS() const
{
   return(SystemDefaultImplementation::getDimRHS());
}

// Provide variables to the system
void Modelica::getBoolean(bool* z)
{ 
  SystemDefaultImplementation::getBoolean(z);
}

void Modelica::getInteger(int* z)
{ 
  SystemDefaultImplementation::getInteger(z);
}

void Modelica::getString(string* z)
{ 
  SystemDefaultImplementation::getString(z);
}


void Modelica::getReal(double* z)
{ 
  SystemDefaultImplementation::getReal(z);
}



void Modelica::getContinuousStates(double* z)
{ 
  SystemDefaultImplementation::getContinuousStates(z);
}

// Provide the right hand side (according to the index)
void Modelica::getRHS(double* z)
{ 
  SystemDefaultImplementation::getRHS(z);
}

// Set variables to the system
void Modelica::setBoolean(const bool* z)
{ 
  SystemDefaultImplementation::setBoolean(z);
}

void Modelica::setInteger(const int* z)
{ 
  SystemDefaultImplementation::setInteger(z);
}

void Modelica::setString(const string* z)
{ 
  SystemDefaultImplementation::setString(z);
}

void Modelica::setReal(const double* z)
{ 
  SystemDefaultImplementation::setReal(z);
}

void Modelica::setContinuousStates(const double* z)
{ 
  SystemDefaultImplementation::setContinuousStates(z);
}

void Modelica::setRHS(const double* f)
{ 
  SystemDefaultImplementation::setRHS(f);
}


// History
 IHistory*  Modelica::getHistory()
 {
   return _historyImpl;
 }


void Modelica::getZeroFunc(double* f)
{
  
}

void Modelica::handleEvent(const bool* events)
{
  
}

bool Modelica::handleSystemEvents( bool* events)
{
 return false;
 
}

bool Modelica::checkForDiscreteEvents()
{
    bool restart = false;
  
  return restart;
}
void Modelica::stepCompleted(double time)
{
}
 bool Modelica::checkConditions()
 {
     throw std::runtime_error("checkConditions is not yet implemented"); 
 }

void Modelica::getJacobianSparsityPattern(SparsityPattern pattern)
{
  throw std::runtime_error("giveJacobianSparsityPattern is not yet implemented"); 
}

void Modelica::getJacobian(SparseMatrix& matrix)
{
  throw std::runtime_error("giveJacobian is not yet implemented");  
}

bool Modelica::isODE()
{
  return false;
}

bool Modelica::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

int Modelica::getDimZeroFunc()
{
  return 0;
}

bool Modelica::provideSymbolicJacobian()
{
  throw std::runtime_error("provideSymbolicJacobian is not yet implemented");
}

void Modelica::saveAll()
{

}
void Modelica::saveDiscreteVars()
   {

   }
void Modelica::resetHelpVar(const int index)
{
}

void Modelica::getConditions(bool* c)
{
     memcpy(c,_conditions,_dimZeroFunc*sizeof(bool));
}

