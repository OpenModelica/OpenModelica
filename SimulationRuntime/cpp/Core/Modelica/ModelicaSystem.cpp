#include <Core/ModelicaDefine.h>
 #include <Core/Modelica.h>

#include <Core/Modelica/FactoryExport.h>
#include <Core/System/EventHandling.h>
#include <Core/HistoryImpl.h>
#include <Core/System/SystemDefaultImplementation.h>
#include <Core/DataExchange/Policies/TextfileWriter.h>
#include <Core/Modelica/ModelicaSystem.h>

Modelica::Modelica(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : SystemDefaultImplementation(globalSettings,sim_data,sim_vars)
{
  _dimBoolean = 0;
  _dimInteger = 0;
  _dimString = 0;
  _dimReal = 0;
  _dimContinuousStates = 0;
  _dimRHS = 0;
  //DAE's are not supported yet, Index reduction is enabled
  _dimAE = 0; // algebraic equations
  // Initialize the state vector
  SystemDefaultImplementation::initialize();
  //Instantiate auxiliary object for event handling functionality
}

Modelica::~Modelica()
{
}

void Modelica::resetTimeEvents()
{
}

bool Modelica::evaluateAll(const UPDATETYPE command)
{
  return false;
}

void Modelica::evaluateODE(const UPDATETYPE command)
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

void Modelica::evaluateZeroFuncs(const UPDATETYPE command)
{
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

bool Modelica::stepCompleted(double time)
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"stepCompleted is not yet implemented");
}

bool Modelica::checkConditions()
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"checkConditions is not yet implemented");
}

void Modelica::getJacobian(SparseMatrix& matrix)
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"giveJacobian is not yet implemented");
}

void Modelica::getStateSetJacobian(SparseMatrix& matrix)
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"giveStateJacobian is not yet implemented");
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
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"provideSymbolicJacobian is not yet implemented");
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
