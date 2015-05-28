#if defined(__TRICORE__) || defined(__vxworks)
  #include <DataExchange/SimDouble.h>
#endif

/* Constructor */
BouncingBall::BouncingBall(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : SystemDefaultImplementation(globalSettings,sim_data,sim_vars)
    , _algLoopSolverFactory(nonlinsolverfactory)
    , _pointerToRealVars(sim_vars->getRealVarsVector())
    , _pointerToIntVars(sim_vars->getIntVarsVector())
    , _pointerToBoolVars(sim_vars->getBoolVarsVector())
    
{
    defineConstVals();
    defineAlgVars();
    defineDiscreteAlgVars();
    defineIntAlgVars();
    defineBoolAlgVars();
    defineParameterRealVars();
    defineParameterIntVars();
    defineParameterBoolVars();
    defineMixedArrayVars();
    defineAliasRealVars();
    defineAliasIntVars();
    defineAliasBoolVars();
    
    //Number of equations
    _dimContinuousStates = 2;
    _dimRHS = 2;
    _dimBoolean = 6;
    _dimInteger = 2;
    _dimString = 0 + 0;
    _dimReal = 8;
    _dimZeroFunc = 2;
    _dimTimeEvent = 0;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&BouncingBall::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    
}

BouncingBall::BouncingBall(BouncingBall &instance) : SystemDefaultImplementation(instance.getGlobalSettings(),instance._sim_data,instance._sim_vars)
    , _algLoopSolverFactory(instance.getAlgLoopSolverFactory())
    
{
    defineConstVals();
    defineAlgVars();
    defineDiscreteAlgVars();
    defineIntAlgVars();
    defineBoolAlgVars();
    defineParameterRealVars();
    defineParameterIntVars();
    defineParameterBoolVars();
    defineMixedArrayVars();
    defineAliasRealVars();
    defineAliasIntVars();
    defineAliasBoolVars();
    
    //Number of equations
    _dimContinuousStates = 2;
    _dimRHS = 2;
    _dimBoolean = 6;
    _dimInteger = 2;
    _dimString = 0 + 0;
    _dimReal = 8;
    _dimZeroFunc = 2;
    _dimTimeEvent = 0;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&BouncingBall::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    double* realVars = new double[3 + _dimContinuousStates + _dimContinuousStates];
    int* integerVars = new int[1];
    bool* booleanVars = new bool[5];
    string* stringVars = new string[0];
    instance.getReal(realVars);
    instance.getInteger(integerVars);
    instance.getBoolean(booleanVars);
    instance.getString(stringVars);
    setReal(realVars);
    setInteger(integerVars);
    setBoolean(booleanVars);
    setString(stringVars);
    delete[] realVars;
    delete[] integerVars;
    delete[] booleanVars;
    delete[] stringVars;
     
}

/* Destructor */
BouncingBall::~BouncingBall()
{
  deleteObjects();
  
}

void BouncingBall::deleteObjects()
{

  if(_functions != NULL)
    delete _functions;

  deleteAlgloopSolverVariables();
}

boost::shared_ptr<IAlgLoopSolverFactory> BouncingBall::getAlgLoopSolverFactory()
{
    return _algLoopSolverFactory;
}

boost::shared_ptr<ISimData> BouncingBall::getSimData()
{
    return _sim_data;
}

void BouncingBall::initializeAlgloopSolverVariables_0()
{
}


void BouncingBall::initializeAlgloopSolverVariables()
{
  initializeAlgloopSolverVariables_0();
  initializeJacAlgloopSolverVariables();
}


void BouncingBall::initializeJacAlgloopSolverVariables()
{
}

void BouncingBall::deleteAlgloopSolverVariables_0()
{

}


void BouncingBall::deleteAlgloopSolverVariables()
{
  deleteAlgloopSolverVariables_0();
  deleteJacAlgloopSolverVariables();
}
void BouncingBall::deleteJacAlgloopSolverVariables()
{
}

/*
equation index: 15
type: SIMPLE_ASSIGN
der(h) = v
*/
void BouncingBall::evaluate_15()
{
   __zDot[0]  = __z[1];
}
/*
equation index: 16
type: SIMPLE_ASSIGN
impact = h <= 0.0
*/
void BouncingBall::evaluate_16()
{
  _impact = getCondition(0);
}
/*
equation index: 17
type: SIMPLE_ASSIGN
$whenCondition1 = impact and v <= 0.0
*/
void BouncingBall::evaluate_17()
{
  _$whenCondition1 = (_impact && getCondition(1));
}
/*
equation index: 18
type: SIMPLE_ASSIGN
$whenCondition2 = impact
*/
void BouncingBall::evaluate_18()
{
  _$whenCondition2 = _impact;
}
/*
equation index: 19
type: WHEN

when {$whenCondition2, $whenCondition1} then
  v_new = if impact and not pre(impact) then (-e) * pre(v) else 0.0;
end when;
*/
void BouncingBall::evaluate_19()
{
  double tmp0;
  if(_initial)
  {
     _v_new = _discrete_events->pre(_v_new);
  }
  else if (0 || (_$whenCondition2 && !_discrete_events->pre(_$whenCondition2)) || (_$whenCondition1 && !_discrete_events->pre(_$whenCondition1)))
  {
    if (_impact && (!_discrete_events->pre(_impact))) {
      tmp0 = ((-_e) * _discrete_events->pre(__z[1]));
    } else {
      tmp0 = 0.0;
    }
    _v_new = tmp0;;
  }
  else
  {
         _v_new = _discrete_events->pre(_v_new);
   }
}
/*
equation index: 20
type: WHEN

when {$whenCondition2, $whenCondition1} then
  flying = v_new > 0.0;
end when;
*/
void BouncingBall::evaluate_20()
{
  if(_initial)
  {
     _flying = _discrete_events->pre(_flying);
  }
  else if (0 || (_$whenCondition2 && !_discrete_events->pre(_$whenCondition2)) || (_$whenCondition1 && !_discrete_events->pre(_$whenCondition1)))
  {
    _flying = (_v_new > 0.0);;
  }
  else
  {
         _flying = _discrete_events->pre(_flying);
   }
}
/*
equation index: 21
type: SIMPLE_ASSIGN
der(v) = if flying then -g else 0.0
*/
void BouncingBall::evaluate_21()
{
  double tmp1;
  if (_flying) {
    tmp1 = (-_g);
  } else {
    tmp1 = 0.0;
  }
   __zDot[1]  = tmp1;
}
/*
equation index: 22
type: WHEN

when {$whenCondition2, $whenCondition1} then
  n_bounce = 1 + pre(n_bounce);
end when;
*/
void BouncingBall::evaluate_22()
{
  if(_initial)
  {
     _n_bounce = _discrete_events->pre(_n_bounce);
  }
  else if (0 || (_$whenCondition2 && !_discrete_events->pre(_$whenCondition2)) || (_$whenCondition1 && !_discrete_events->pre(_$whenCondition1)))
  {
    _n_bounce = (1 + _discrete_events->pre(_n_bounce));;
  }
  else
  {
         _n_bounce = _discrete_events->pre(_n_bounce);
   }
}
/*
equation index: 23
type: SIMPLE_ASSIGN
$whenCondition3 = h <= 0.0 and v <= 0.0
*/
void BouncingBall::evaluate_23()
{
  _$whenCondition3 = (getCondition(0) && getCondition(1));
}

bool BouncingBall::evaluateAll(const UPDATETYPE command)
{
  bool state_var_reinitialized = false;
  
  /* Evaluate Equations*/
  evaluate_15();
  evaluate_16();
  evaluate_17();
  evaluate_18();
  evaluate_19();
  evaluate_20();
  evaluate_21();
  evaluate_22();
  evaluate_23();
  
  /* evaluateODE(command);
  
  evaluate_19();
  evaluate_20();
  evaluate_22();
  evaluate_23();
  */
  // Reinits
  
  
  
  //For whenclause index: 3
  if(_initial)
  {
    ; // nothing to do
  }
  else if (0 || (_$whenCondition2 && !_discrete_events->pre(_$whenCondition2)) || (_$whenCondition3 && !_discrete_events->pre(_$whenCondition3))) {
    state_var_reinitialized = true;
      __z[1]   = _v_new;
  }

  return state_var_reinitialized;
}

void BouncingBall::evaluateODE(const UPDATETYPE command)
{
  /* Evaluate Equations*/
  evaluate_15();
  evaluate_16();
  evaluate_17();
  evaluate_18();
  evaluate_21();
}

void BouncingBall::evaluateZeroFuncs(const UPDATETYPE command)
{
  /* Evaluate Equations*/
  evaluate_15();
  evaluate_16();
  evaluate_17();
  evaluate_18();
  evaluate_21();
}

bool BouncingBall::evaluateConditions(const UPDATETYPE command)
{
  return evaluateAll(command);
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

// Provide number (dimension) of variables according to the index
int BouncingBall::getDimContinuousStates() const
{
  return(SystemDefaultImplementation::getDimContinuousStates());
}


// Provide number (dimension) of variables according to the index
int BouncingBall::getDimBoolean() const
{
  return(SystemDefaultImplementation::getDimBoolean());
}

// Provide number (dimension) of variables according to the index
int BouncingBall::getDimInteger() const
{
  return(SystemDefaultImplementation::getDimInteger());
}
// Provide number (dimension) of variables according to the index
int BouncingBall::getDimReal() const
{
  return(SystemDefaultImplementation::getDimReal());
}

// Provide number (dimension) of variables according to the index
int BouncingBall::getDimString() const
{
  return(SystemDefaultImplementation::getDimString());
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int BouncingBall::getDimRHS() const
{
  return(SystemDefaultImplementation::getDimRHS());
}

void BouncingBall::getContinuousStates(double* z)
{
  SystemDefaultImplementation::getContinuousStates(z);
}
void BouncingBall::getNominalStates(double* z)
{
   z[0] = 1.0;
   z[1] = 1.0;
}

// Set variables with given index to the system
void BouncingBall::setContinuousStates(const double* z)
{
  SystemDefaultImplementation::setContinuousStates(z);
}

// Provide the right hand side (according to the index)
void BouncingBall::getRHS(double* f)
{
  SystemDefaultImplementation::getRHS(f);
}

void BouncingBall::setRHS(const double* f)
{
  SystemDefaultImplementation::setRHS(f);
}

bool BouncingBall::isStepEvent()
{
 throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"isStepEvent is not yet implemented");

}

void BouncingBall::setTerminal(bool terminal)
{
  _terminal=terminal;
}

bool BouncingBall::terminal()
{
  return _terminal;
}

bool BouncingBall::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

bool BouncingBall::provideSymbolicJacobian()
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"provideSymbolicJacobian is not yet implemented");
}

void BouncingBall::handleEvent(const bool* events)
{
}
bool BouncingBall::checkForDiscreteEvents()
{
  if (_discrete_events->changeDiscreteVar(_$whenCondition3)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition2)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition1)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_flying)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_impact)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_v_new)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_n_bounce)) {  return true; }
  return false;
}
void BouncingBall::getZeroFunc(double* f)
{
  if(_conditions[0])
      f[0] = (__z[0] - 1e-9 - 0.0);
  else
      f[0] = (0.0 - __z[0] - 1e-9);
  if(_conditions[1])
      f[1] = (__z[1] - 1e-9 - 0.0);
  else
      f[1] = (0.0 - __z[1] - 1e-9);
}

void BouncingBall::setConditions(bool* c)
{
  SystemDefaultImplementation::setConditions(c);
}
void BouncingBall::getConditions(bool* c)
{
    SystemDefaultImplementation::getConditions(c);
}
bool BouncingBall::isConsistent()
{
  return SystemDefaultImplementation::isConsistent();
}

bool BouncingBall::stepCompleted(double time)
{

  storeTime(time);

#if defined(__TRICORE__) || defined(__vxworks)
#endif

saveAll();
return _terminate;
}

bool BouncingBall::stepStarted(double time)
{
#if defined(__TRICORE__) || defined(__vxworks)
#endif

return true;
}

void BouncingBall::handleTimeEvent(int* time_events)
{
  for(int i=0; i<_dimTimeEvent; i++)
  {
    if(time_events[i] != _time_event_counter[i])
      _time_conditions[i] = true;
    else
      _time_conditions[i] = false;
  }
  memcpy(_time_event_counter, time_events, (int)_dimTimeEvent*sizeof(int));
}
int BouncingBall::getDimTimeEvent() const
{
  return _dimTimeEvent;
}
void BouncingBall::getTimeEvent(time_event_type& time_events)
{
}

bool BouncingBall::isODE()
{
  return 2>0 ;
}
int BouncingBall::getDimZeroFunc()
{
  return _dimZeroFunc;
}

bool BouncingBall::getCondition(unsigned int index)
{
  bool tmp2;
  bool tmp3;
  switch(index)
  {
    case 0:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp2=(__z[0]<=0.0);
           _conditions[0]=tmp2;
           return tmp2;
       }
       else
           return _conditions[0];
    }
    case 1:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp3=(__z[1]<=0.0);
           _conditions[1]=tmp3;
           return tmp3;
       }
       else
           return _conditions[1];
    }
    default:
    {
      string error =string("Wrong condition index ") + boost::lexical_cast<string>(index);
     throw ModelicaSimulationError(EVENT_HANDLING,error);
    }
  };
}
bool BouncingBall::handleSystemEvents(bool* events)
{
  _callType = IContinuous::DISCRETE;

  bool restart = true;
  bool state_vars_reinitialized = false;
  int iter = 0;

  while(restart && !(iter++ > 100))
  {
      bool st_vars_reinit = false;
      //iterate and handle all events inside the eventqueue
      restart = _event_handling->startEventIteration(st_vars_reinit);
      state_vars_reinitialized = state_vars_reinitialized || st_vars_reinit;

      saveAll();
  }

  if(iter>100 && restart ){
   string error = string("Number of event iteration steps exceeded at time: ") + boost::lexical_cast<string>(_simTime);
  throw ModelicaSimulationError(EVENT_HANDLING,error);
   }
   _callType = IContinuous::CONTINUOUS;

  return state_vars_reinitialized;
}
void BouncingBall::saveAll()
{
     _sim_vars->savePreVariables();
}




void BouncingBall::getReal(double* z)
{
  const double* real_vars = _sim_vars->getRealVarsVector();
  memcpy(z,real_vars,8);
}



void BouncingBall::setReal(const double* z)
{
   _sim_vars->setRealVarsVector(z);
}



void BouncingBall::getInteger(int* z)
{
  const int* int_vars = _sim_vars->getIntVarsVector();
  memcpy(z,int_vars,2);
}



void BouncingBall::getBoolean(bool* z)
{
  const bool* bool_vars = _sim_vars->getBoolVarsVector();
  memcpy(z,bool_vars,6);
}



void BouncingBall::getString(string* z)
{
}

void BouncingBall::setInteger(const int* z)
{
   _sim_vars->setIntVarsVector(z);
}

void BouncingBall::setBoolean(const bool* z)
{
  _sim_vars->setBoolVarsVector(z);
}

void BouncingBall::setString(const string* z)
{
}

//AlgVars

void BouncingBall::defineAlgVars()
{
}

//DiscreteAlgVars
void BouncingBall::defineDiscreteAlgVars_0()
{
}

void BouncingBall::defineDiscreteAlgVars()
{
    defineDiscreteAlgVars_0();
}

//IntAlgVars
void BouncingBall::defineIntAlgVars_0()
{
}
void BouncingBall::defineIntAlgVars()
{
    defineIntAlgVars_0();
}

//BoolAlgVars
void BouncingBall::defineBoolAlgVars_0()
{
}
void BouncingBall::defineBoolAlgVars()
{
    defineBoolAlgVars_0();
}

//ParameterRealVars
void BouncingBall::defineParameterRealVars_0()
{
}
void BouncingBall::defineParameterRealVars()
{
    defineParameterRealVars_0();
}

//ParameterIntVars
void BouncingBall::defineParameterIntVars()
{
}

//ParameterBoolVars
void BouncingBall::defineParameterBoolVars()
{
}

//AliasRealVars
void BouncingBall::defineAliasRealVars()
{
}

//AliasIntVars
void BouncingBall::defineAliasIntVars()
{
}

//AliasBoolVars
void BouncingBall::defineAliasBoolVars()
{
}

//MixedArrayVars
void BouncingBall::defineMixedArrayVars()
{
}

//String parameter 0

void BouncingBall::defineConstVals()
{
}
