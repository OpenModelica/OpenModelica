#include "stdafx.h "
#include "BouncingBall.h "


using boost::extensions::factory;
BOOST_EXTENSION_TYPE_MAP_FUNCTION {
	types.get<std::map<std::string, factory<IDAESystem,IGlobalSettings&> > >()
	["ModelicaSystem"].set<BouncingBall>();
}

BouncingBall::BouncingBall(IGlobalSettings& globalSettings) 
:SystemDefaultImplementation()
,$g(9.81)
,$e(0.7)
{ 
	// Number of equations
	_dimODE1stOrder = 0; // ordinary differential equations of 1st order
	_dimODE2ndOrder = 2; // ordinary differential equations of 2nd order
	//DAE's are not supported yet, Index reduction is enabled
	_dimAE = 0; // algebraic equations
	// Initialize the state vector
	SystemDefaultImplementation::init();
	//Instantiate auxiliary object for event handling functionality
	_event_handling.resetHelpVar =  boost::bind(&BouncingBall::resetHelpVar, this, _1);
	_historyImpl = new HistoryImplType(globalSettings);
	
	
} 

BouncingBall::~BouncingBall() 
{ 
delete _historyImpl;
} 

void BouncingBall::init(double ts,double te)
{
  bool tmp1;
  bool tmp0;
  $t=0.0; // t
  $foo=0.0; // foo
  $v_new=0.0; // v_new
  $impact=0.0; // impact
  $flying=(1); // flying
  _z[1]=0.0; // v
  _z[0]=((modelica_real)1); // h
  _event_handling.init(this,4);
  saveAll();
  tmp1=(_z[1]<=0.0);
  _condition1 = tmp1;//$v <= 0.0
  tmp0=(_z[0]<=0.0);
  _condition0 = tmp0;//$h <= 0.0
  for( int i=0;i<2;++i) { handleEvent(i); }
  vector<unsigned int> var_ouputs_idx;
  
  _historyImpl->setOutputs(var_ouputs_idx);
   _historyImpl->clear();
}

void BouncingBall::resetTimeEvents()
{
}

void BouncingBall::update(const UPDATE command)
{
  bool tmp0;
  bool tmp1;
  bool tmp2;
  double tmp3;
  bool tmp4;
   if(command & CONTINOUS)
  {
    _zDot[0] = _z[1];//der(h)
    $impact = _condition0;
    tmp0 = $flying;
    if (tmp0) {
    }
    else {
    }
    _zDot[1] = ((tmp0)?(-$g):0.0);//der(v)
    tmp1 = $impact;
    if (tmp1) {
    }
    else {
    }
    $foo = ((tmp1)?1:2);
  }
  if (command & DISCRETE)
  {
    if(_event_handling.edge(_event_handling[0],"h0"))
    {
      tmp2 = _event_handling.edge($impact,"$impact");
      if (tmp2) {
        tmp3 = _event_handling.pre(_z[1],"$v");
      }
      else {
      }
      $v_new = ((tmp2)?((-$e) * tmp3):0.0);
      
    }
    if(_event_handling.edge(_event_handling[1],"h1"))
    {
      tmp4=($v_new>0.0);
      $flying = tmp4;
      
    }
    if(_event_handling.edge(_event_handling[2],"h2"))
    {
      $t = $flying;
      
    }
    if(_event_handling.edge(_event_handling[3],"h3"))
    {
          _z[1] = $v_new;
    }
  }
}

void BouncingBall::writeOutput(const OUTPUT command)
{
  	//Write head line
	if (command & HEAD_LINE)
	{
	vector<string> head;
	head+= 	 "t", 	 "foo", 	 "v_new", 	 "impact", 	 "flying", 	 "h", 	 "v", 	"h", 	"v";
	_historyImpl->write(head);
	}
	//Write the current values
	else
	{
	HistoryImplType::value_type_v v(7);
	HistoryImplType::value_type_dv v2(2);
		v(0)= $t; 	v(1)= $foo; 	v(2)= $v_new; 	v(3)= $impact; 	v(4)= $flying; 	v(5)= _z[0]; 	v(6)= _z[1]; 	v2(0)= _zDot[0]; 	v2(1)= _zDot[1];
	_historyImpl->write(v,v2,time);
	}

}

// Release instance
void BouncingBall::destroy()
{
	delete this;
}

// Set current integration time 
void BouncingBall::setTime(const double& t)
{
	SystemDefaultImplementation::setTime(t);
}

// Returns the vector with all time events 
event_times_type BouncingBall::getTimeEvents()
{
	return _event_handling.getTimeEvents();
}

// Provide number (dimension) of variables according to the index
int BouncingBall::getDimVars(const INDEX index) const
{
	return(SystemDefaultImplementation::getDimVars(index));
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int BouncingBall::getDimRHS(const INDEX index ) const
{
	 return(SystemDefaultImplementation::getDimRHS(index));
}

// Provide variables with given index to the system
void BouncingBall::giveVars(double* z, const INDEX index)
{	
	SystemDefaultImplementation::giveVars(z,index);
}

// Set variables with given index to the system
void BouncingBall::setVars(const double* z, const INDEX index)
{
	SystemDefaultImplementation::setVars(z,index);
}
 
// Provide the right hand side (according to the index)
void BouncingBall::giveRHS(double* f, const INDEX index)
{
	SystemDefaultImplementation::giveRHS(f,index);
}

void BouncingBall::giveZeroFunc(double* f,const double& eps)
{
  f[1]=0.0-_z[1];
  f[0]=0.0-_z[0];
}

void BouncingBall::handleEvent(unsigned long index)
{
  switch(index)	
{
    	
     case 0:
	{
      
      $impact = _condition0;
      
      break;
      	
    }
    	
     case 1:
	{
      
      break;
      	
    }
  }
}

void BouncingBall::handleSystemEvents(const bool* events,update_events_type update_event)
{
  bool tmp0;
  bool tmp1;
  bool restart =true;
  int iter = 0;
  while(restart && !(iter++ > 10))
  {
    	//save all variables for pre and edge operators
	saveAll();

    	//root 0 was found
    if(events[0])
	{
		//set the condition for root 0
      tmp0=(_z[0]<=0.0);
      _condition0=tmp0;
      //add the event to the eventqueue $h <= 0.0
      _event_handling.addEvent(0);
      handleEvent(0);
    }
    	//root 0 was found
    if(events[1])
	{
		//set the condition for root 1
      tmp1=(_z[1]<=0.0);
      _condition1=tmp1;
      //add the event to the eventqueue $v <= 0.0
      _event_handling.addEvent(1);
      handleEvent(1);
    }
    	//sets discrete vars of while 
	double h[4];
    	h[0]=(_condition0 && _condition1);
    	h[1]=(_condition0 && _condition1);
    	h[2]=(_condition0 && _condition1);
    	h[3]=(_condition0 && _condition1);
    _event_handling.setHelpVars(h);
    //iterate and handle all events inside the eventqueue
    restart=_event_handling.IterateEventQueue(events,update_event);
  }
  resetTimeEvents();
  if(iter>10){
    throw std::runtime_error("Number of event iteration steps exceeded. ");}
}

bool BouncingBall::checkForDiscreteEvents()
{
  	bool restart = false;
  
  if (_event_handling.change($foo,"$foo")) {  restart=true; }
  
  if (_event_handling.change($impact,"$impact")) {  restart=true; }
  
  return restart;
}

void BouncingBall::giveJacobianSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveJacobianSparsityPattern is not yet implemented");	
}

void BouncingBall::giveJacobian(SparseMatrix matrix)
{
  throw std::runtime_error("giveJacobian is not yet implemented");	
}

void BouncingBall::giveMassSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveMassSparsityPattern is not yet implemented");	
}

void BouncingBall::giveMassMatrix(SparseMatrix matrix)
{
  throw std::runtime_error("giveMassMatrix is not yet implemented");	
}

void BouncingBall::giveConstraintSparsityPattern(SparcityPattern pattern)
{
  throw std::runtime_error("giveConstraintSparsityPattern is not yet implemented");	
}

void BouncingBall::giveConstraint(SparseMatrix matrix)
{
  throw std::runtime_error("giveConstraint is not yet implemented");	
}

bool BouncingBall::isAutonomous()
{
  throw std::runtime_error("isAutonomous is not yet implemented");	
}

bool BouncingBall::isTimeInvariant()
{
  throw std::runtime_error("isTimeInvariant is not yet implemented");	
}

bool BouncingBall::isODE()
{
  return true;
}

bool BouncingBall::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

bool BouncingBall::isExplicit()
{
  return true; // At the moment only explicit form is supported
}

bool BouncingBall::hasConstantMass()
{
  throw std::runtime_error("hasConstantMass is not yet implemented");	
}

bool BouncingBall::hasStateDependentMass()
{
  throw std::runtime_error("hasStateDependentMass is not yet implemented");	
}

int BouncingBall::getDimZeroFunc()
{
  return 2;
}

bool BouncingBall::provideSymbolicJacobian()
{
  throw std::runtime_error("provideSymbolicJacobian is not yet implemented");	
}

void BouncingBall::saveAll()
{
  _event_handling.save($flying,"$flying");
  _event_handling.save($impact,"$impact");
  _event_handling.save($v_new,"$v_new");
  _event_handling.save($foo,"$foo");
  _event_handling.save($t,"$t");
  _event_handling.save(_z[1],"$v");
  _event_handling.save(_z[0],"$h");
  _event_handling.saveH();
}

void BouncingBall::resetHelpVar(const int index)
{
  switch(index)
  {
    case 0:
    {
      _event_handling.setHelpVar(0,(_condition0 && _condition1));
      break;
    }
    case 1:
    {
      _event_handling.setHelpVar(1,(_condition0 && _condition1));
      break;
    }
    case 2:
    {
      _event_handling.setHelpVar(2,(_condition0 && _condition1));
      break;
    }
    case 3:
    {
      _event_handling.setHelpVar(3,(_condition0 && _condition1));
      break;
    }
  }
}

