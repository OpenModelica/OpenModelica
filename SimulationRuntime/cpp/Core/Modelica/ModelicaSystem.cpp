#include "Modelica.h"
#include "ModelicaSystem.h"


using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IMixedSystem,IGlobalSettings&> > >()
  ["ModelicaSystem"].set<Modelica>();
}

Modelica::Modelica(IGlobalSettings& globalSettings)
:SystemDefaultImplementation(globalSettings)

{
  _dimVars =0;
  _dimFunc = 0;
   //DAE's are not supported yet, Index reduction is enabled
  _dimAE = 0; // algebraic equations
  // Initialize the state vector
  SystemDefaultImplementation::init();
  //Instantiate auxiliary object for event handling functionality
  _event_handling.resetHelpVar =  boost::bind(&Modelica::resetHelpVar, this, _1);
  _historyImpl = new HistoryImplType(globalSettings);


}

Modelica::~Modelica()
{
delete _historyImpl;
}

void Modelica::init(double ts,double te)
{

}

void Modelica::resetTimeEvents()
{
}

void Modelica::update(const UPDATE command)
{

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

// Returns the vector with all time events
event_times_type Modelica::getTimeEvents()
{
  return _event_handling.getTimeEvents();
}

// Provide number (dimension) of variables according to the index
int Modelica::getDimVars() const
{
  return(SystemDefaultImplementation::getDimVars());
}
  void Modelica::giveConditions(bool* c)
   {
     memcpy(c,_conditions,_dimZeroFunc*sizeof(bool));
   }

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int Modelica::getDimRHS() const
{
   return(SystemDefaultImplementation::getDimRHS());
}

// Provide variables with given index to the system
void Modelica::giveVars(double* z)
{
  SystemDefaultImplementation::giveVars(z);
}

// Set variables with given index to the system
void Modelica::setVars(const double* z)
{
  SystemDefaultImplementation::setVars(z);
}
 IHistory*  Modelica::getHistory()
 {
   return _historyImpl;
 }
// Provide the right hand side (according to the index)
void Modelica::giveRHS(double* f)
{
  SystemDefaultImplementation::giveRHS(f);
}

void Modelica::giveZeroFunc(double* f)
{

}

void Modelica::handleEvent(const bool* events)
{

}

 void Modelica::handleSystemEvents( bool* events)
{

}

bool Modelica::checkForDiscreteEvents()
{
    bool restart = false;

  return restart;
}

 void Modelica::checkConditions(const bool* events, bool all)
 {
 }

void Modelica::giveJacobianSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveJacobianSparsityPattern is not yet implemented");
}

void Modelica::giveJacobian(SparseMatrix& matrix)
{
  throw std::runtime_error("giveJacobian is not yet implemented");
}

void Modelica::giveMassSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveMassSparsityPattern is not yet implemented");
}

void Modelica::giveMassMatrix(SparseMatrix& matrix)
{
  throw std::runtime_error("giveMassMatrix is not yet implemented");
}

void Modelica::giveConstraintSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveConstraintSparsityPattern is not yet implemented");
}

void Modelica::giveConstraint(SparseMatrix matrix)
{
  throw std::runtime_error("giveConstraint is not yet implemented");
}

bool Modelica::isAutonomous()
{
  throw std::runtime_error("isAutonomous is not yet implemented");
}

bool Modelica::isTimeInvariant()
{
  throw std::runtime_error("isTimeInvariant is not yet implemented");
}

bool Modelica::isODE()
{
  return false;
}

bool Modelica::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

bool Modelica::isExplicit()
{
  return false; // At the moment only explicit form is supported
}

bool Modelica::hasConstantMass()
{
  throw std::runtime_error("hasConstantMass is not yet implemented");
}

bool Modelica::hasStateDependentMass()
{
  throw std::runtime_error("hasStateDependentMass is not yet implemented");
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

