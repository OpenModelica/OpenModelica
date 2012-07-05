#include "Modelica.h"
#include "ModelicaSystem.h"


using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
  types.get<std::map<std::string, factory<IDAESystem,IGlobalSettings&> > >()
  ["ModelicaSystem"].set<Modelica>();
}

Modelica::Modelica(IGlobalSettings& globalSettings) 
:SystemDefaultImplementation()

{ 
  // Number of equations
  _dimODE1stOrder = 0; // ordinary differential equations of 1st order
  _dimODE2ndOrder = 0; // ordinary differential equations of 2nd order
  _dimResidues = 0;
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
int Modelica::getDimVars(const INDEX index) const
{
  return(SystemDefaultImplementation::getDimVars(index));
}
  void Modelica::giveConditions(bool* c)
   {
     memcpy(c,_conditions0,_dimZeroFunc*sizeof(bool));
   }
  void Modelica::setConditions(bool* c)
   {
     memcpy(_conditions0,c,_dimZeroFunc*sizeof(bool));
   }
// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int Modelica::getDimRHS(const INDEX index ) const
{
   return(SystemDefaultImplementation::getDimRHS(index));
}

// Provide variables with given index to the system
void Modelica::giveVars(double* z, const INDEX index)
{ 
  SystemDefaultImplementation::giveVars(z,index);
}

// Set variables with given index to the system
void Modelica::setVars(const double* z, const INDEX index)
{
  SystemDefaultImplementation::setVars(z,index);
}
 
// Provide the right hand side (according to the index)
void Modelica::giveRHS(double* f, const INDEX index)
{
  SystemDefaultImplementation::giveRHS(f,index);
}

void Modelica::giveZeroFunc(double* f)
{
  
}

void Modelica::handleEvent(unsigned long index)
{
  
}

void Modelica::handleSystemEvents(const bool* events)
{
 
}

bool Modelica::checkForDiscreteEvents()
{
    bool restart = false;
  
  return restart;
}
void Modelica::saveConditions()
{
  
  
}
 void Modelica::checkConditions(unsigned int, bool all) 
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

void Modelica::resetHelpVar(const int index)
{
}

