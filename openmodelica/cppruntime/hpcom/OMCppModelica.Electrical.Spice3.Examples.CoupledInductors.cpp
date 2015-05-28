#if defined(__TRICORE__) || defined(__vxworks)
  #include <DataExchange/SimDouble.h>
#endif

/* Constructor */
CoupledInductors::CoupledInductors(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
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
    _dimContinuousStates = 5;
    _dimRHS = 5;
    _dimBoolean = 6;
    _dimInteger = 1;
    _dimString = 0 + 0;
    _dimReal = 62;
    _dimZeroFunc = 1;
    _dimTimeEvent = 0;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&CoupledInductors::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
}

CoupledInductors::CoupledInductors(CoupledInductors &instance) : SystemDefaultImplementation(instance.getGlobalSettings(),instance._sim_data,instance._sim_vars)
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
    _dimContinuousStates = 5;
    _dimRHS = 5;
    _dimBoolean = 6;
    _dimInteger = 1;
    _dimString = 0 + 0;
    _dimReal = 62;
    _dimZeroFunc = 1;
    _dimTimeEvent = 0;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&CoupledInductors::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    double* realVars = new double[121 + _dimContinuousStates + _dimContinuousStates];
    int* integerVars = new int[0];
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
CoupledInductors::~CoupledInductors()
{
  deleteObjects();
}

void CoupledInductors::deleteObjects()
{

  if(_functions != NULL)
    delete _functions;

  deleteAlgloopSolverVariables();
}

boost::shared_ptr<IAlgLoopSolverFactory> CoupledInductors::getAlgLoopSolverFactory()
{
    return _algLoopSolverFactory;
}

boost::shared_ptr<ISimData> CoupledInductors::getSimData()
{
    return _sim_data;
}

void CoupledInductors::initializeAlgloopSolverVariables_0()
{
  _conditions053 = NULL;
  _conditions153 = NULL;
  _algloop53Vars = NULL;
}


void CoupledInductors::initializeAlgloopSolverVariables()
{
  initializeAlgloopSolverVariables_0();
  initializeJacAlgloopSolverVariables();
}


void CoupledInductors::initializeJacAlgloopSolverVariables()
{
}

void CoupledInductors::deleteAlgloopSolverVariables_0()
{
     if(_conditions053)
       delete [] _conditions053;
     if(_conditions153)
       delete [] _conditions153;
     if(_algloop53Vars)
       delete [] _algloop53Vars;

}


void CoupledInductors::deleteAlgloopSolverVariables()
{
  deleteAlgloopSolverVariables_0();
  deleteJacAlgloopSolverVariables();
}
void CoupledInductors::deleteJacAlgloopSolverVariables()
{
}

/*
equation index: 39
type: SIMPLE_ASSIGN
R5._i = DIVISION(C2.vinternal, R5.R)
*/
void CoupledInductors::evaluate_39()
{
  _R5_P_i = division(__z[1],_R5_P_R,"R5.R");
}
/*
equation index: 40
type: SIMPLE_ASSIGN
C2._i = (-L3.iinternal) - R5.i
*/
void CoupledInductors::evaluate_40()
{
  _C2_P_i = ((-__z[4]) - _R5_P_i);
}
/*
equation index: 41
type: SIMPLE_ASSIGN
der(C2._vinternal) = DIVISION(C2.i, C2.C)
*/
void CoupledInductors::evaluate_41()
{
   __zDot[1]  = division(_C2_P_i,_C2_P_C,"C2.C");
}
/*
equation index: 42
type: SIMPLE_ASSIGN
R4._v = R4.R * L3.iinternal
*/
void CoupledInductors::evaluate_42()
{
  _R4_P_v = (_R4_P_R * __z[4]);
}
/*
equation index: 43
type: SIMPLE_ASSIGN
L3._v = C2.vinternal - R4.v
*/
void CoupledInductors::evaluate_43()
{
  _L3_P_v = (__z[1] - _R4_P_v);
}
/*
equation index: 44
type: SIMPLE_ASSIGN
R3._i = DIVISION(C1.vinternal, R3.R)
*/
void CoupledInductors::evaluate_44()
{
  _R3_P_i = division(__z[0],_R3_P_R,"R3.R");
}
/*
equation index: 45
type: SIMPLE_ASSIGN
C1._i = (-L2.iinternal) - R3.i
*/
void CoupledInductors::evaluate_45()
{
  _C1_P_i = ((-__z[3]) - _R3_P_i);
}
/*
equation index: 46
type: SIMPLE_ASSIGN
der(C1._vinternal) = DIVISION(C1.i, C1.C)
*/
void CoupledInductors::evaluate_46()
{
   __zDot[0]  = division(_C1_P_i,_C1_P_C,"C1.C");
}
/*
equation index: 47
type: SIMPLE_ASSIGN
ground._p._i = R3.i - ((-R5.i) - C2.i - L2.iinternal - L3.iinternal - C1.i)
*/
void CoupledInductors::evaluate_47()
{
  _ground_P_p_P_i = (_R3_P_i - (((((-_R5_P_i) - _C2_P_i) - __z[3]) - __z[4]) - _C1_P_i));
}
/*
equation index: 48
type: SIMPLE_ASSIGN
R2._v = R2.R * L2.iinternal
*/
void CoupledInductors::evaluate_48()
{
  _R2_P_v = (_R2_P_R * __z[3]);
}
/*
equation index: 49
type: SIMPLE_ASSIGN
L2._v = C1.vinternal - R2.v
*/
void CoupledInductors::evaluate_49()
{
  _L2_P_v = (__z[0] - _R2_P_v);
}
/*
equation index: 50
type: SIMPLE_ASSIGN
R1._v = R1.R * L1.iinternal
*/
void CoupledInductors::evaluate_50()
{
  _R1_P_v = (_R1_P_R * __z[2]);
}
/*
equation index: 51
type: SIMPLE_ASSIGN
sineVoltage._v = sineVoltage.VO + (if time < sineVoltage.TD then 0.0 else sineVoltage.VA * exp((sineVoltage.TD - time) * sineVoltage.THETA) * sin(6.283185307179586 * sineVoltage.FREQ * (time - sineVoltage.TD)))
*/
void CoupledInductors::evaluate_51()
{
  double tmp0;
  double tmp1;
  double tmp2;
  if (getCondition(0)) {
    tmp2 = 0.0;
  } else {
    tmp0 = exp(((_sineVoltage_P_TD - _simTime) * _sineVoltage_P_THETA));
    tmp1 = sin((6.283185307179586 * (_sineVoltage_P_FREQ * (_simTime - _sineVoltage_P_TD))));
    tmp2 = (_sineVoltage_P_VA * (tmp0 * tmp1));
  }
  _sineVoltage_P_v = (_sineVoltage_P_VO + tmp2);
}
/*
equation index: 52
type: SIMPLE_ASSIGN
L1._v = sineVoltage.v - R1.v
*/
void CoupledInductors::evaluate_52()
{
  _L1_P_v = (_sineVoltage_P_v - _R1_P_v);
}
/*
equation index: 53
type: LINEAR

<var>L3._ICP._v</var>
<var>k1._inductiveCouplePin1._v</var>
<var>k1._inductiveCouplePin2._v</var>
<var>L1._ICP._di</var>
<var>k2._inductiveCouplePin2._v</var>
<var>k3._inductiveCouplePin1._v</var>
<var>L2._ICP._di</var>
<var>L2._ICP._v</var>
<var>k3._inductiveCouplePin2._v</var>
<var>L3._ICP._di</var>
<var>k2._inductiveCouplePin1._v</var>
<var>L1._ICP._v</var>
<row>
  <cell>L1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>L2.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>L3.v</cell>
</row>
<matrix>
  <cell row="0" col="3">
    <residual>L1.L</residual>
  </cell><cell row="0" col="11">
    <residual>-1.0</residual>
  </cell><cell row="1" col="1">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="11">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>k2.M</residual>
  </cell><cell row="2" col="10">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>1.0</residual>
  </cell><cell row="3" col="9">
    <residual>k3.M</residual>
  </cell><cell row="4" col="2">
    <residual>1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="4" col="8">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>L2.L</residual>
  </cell><cell row="5" col="7">
    <residual>-1.0</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="6" col="6">
    <residual>k3.M</residual>
  </cell><cell row="7" col="0">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>1.0</residual>
  </cell><cell row="7" col="5">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>k2.M</residual>
  </cell><cell row="8" col="4">
    <residual>1.0</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="9" col="3">
    <residual>k1.M</residual>
  </cell><cell row="10" col="1">
    <residual>1.0</residual>
  </cell><cell row="10" col="6">
    <residual>k1.M</residual>
  </cell><cell row="11" col="0">
    <residual>-1.0</residual>
  </cell><cell row="11" col="9">
    <residual>L3.L</residual>
  </cell>
</matrix>
*/
void CoupledInductors::evaluate_53()
{
  bool restart53 = true;
  unsigned int iterations53 = 0;
  _algLoop53->getReal(_algloop53Vars );
  bool restatDiscrete53= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop53->evaluate();
          while(restart53 && !(iterations53++>500))
          {
              getConditions(_conditions053);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver53->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions153);
              restart53 = !std::equal (_conditions153, _conditions153+_dimZeroFunc,_conditions053);
          }
      }
      else
      _algLoopSolver53->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete53=true;
  }
  
  if((restart53&& iterations53 > 0)|| restatDiscrete53)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop53->setReal(_algloop53Vars );
          _algLoopSolver53->solve();
          _callType = calltype;
      }
      catch(ModelicaSimulationError& ex)
      {
        string error = add_error_info("Nonlinear solver stopped",ex.what(),ex.getErrorID(),_simTime);
        throw ModelicaSimulationError(ALGLOOP_EQ_SYSTEM,error);
      }
  
  }
  
  
}
/*
equation index: 54
type: SIMPLE_ASSIGN
der(L3._iinternal) = L3.ICP.di
*/
void CoupledInductors::evaluate_54()
{
   __zDot[4]  = _L3_P_ICP_P_di;
}
/*
equation index: 55
type: SIMPLE_ASSIGN
der(L2._iinternal) = L2.ICP.di
*/
void CoupledInductors::evaluate_55()
{
   __zDot[3]  = _L2_P_ICP_P_di;
}
/*
equation index: 56
type: SIMPLE_ASSIGN
der(L1._iinternal) = L1.ICP.di
*/
void CoupledInductors::evaluate_56()
{
   __zDot[2]  = _L1_P_ICP_P_di;
}
/*
equation index: 63
type: ALGORITHM

  assert(k3.k < 1.0, "coupling factor must be less than one");
*/
void CoupledInductors::evaluate_63()
{

   if(!(_k3_P_k < 1.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"coupling factor must be less than one");
    
   }
}
/*
equation index: 62
type: ALGORITHM

  assert(k3.k >= 0.0, "Coupling factor must be not negative");
*/
void CoupledInductors::evaluate_62()
{

   if(!(_k3_P_k >= 0.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"Coupling factor must be not negative");
    
   }
}
/*
equation index: 61
type: ALGORITHM

  assert(k2.k < 1.0, "coupling factor must be less than one");
*/
void CoupledInductors::evaluate_61()
{

   if(!(_k2_P_k < 1.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"coupling factor must be less than one");
    
   }
}
/*
equation index: 60
type: ALGORITHM

  assert(k2.k >= 0.0, "Coupling factor must be not negative");
*/
void CoupledInductors::evaluate_60()
{

   if(!(_k2_P_k >= 0.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"Coupling factor must be not negative");
    
   }
}
/*
equation index: 59
type: ALGORITHM

  assert(k1.k < 1.0, "coupling factor must be less than one");
*/
void CoupledInductors::evaluate_59()
{

   if(!(_k1_P_k < 1.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"coupling factor must be less than one");
    
   }
}
/*
equation index: 58
type: ALGORITHM

  assert(k1.k >= 0.0, "Coupling factor must be not negative");
*/
void CoupledInductors::evaluate_58()
{

   if(!(_k1_P_k >= 0.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"Coupling factor must be not negative");
    
   }
}
/*
equation index: 57
type: ALGORITHM

  assert(sineVoltage.FREQ > 0.0, "Frequency less or equal zero");
*/
void CoupledInductors::evaluate_57()
{

   if(!(_sineVoltage_P_FREQ > 0.0))
   {
    throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"Frequency less or equal zero");
    
   }
}

bool CoupledInductors::evaluateAll(const UPDATETYPE command)
{
  bool state_var_reinitialized = false;
  
  evaluateParallel(command, false);
  
  
  return state_var_reinitialized;
}

void CoupledInductors::evaluateZeroFuncs(const UPDATETYPE command)
{
  /* Evaluate Equations*/
}

bool CoupledInductors::evaluateConditions(const UPDATETYPE command)
{
  return evaluateAll(command);
}

    void CoupledInductors::evaluateODE(const UPDATETYPE command)
    {
      evaluateParallel(command, true);
    }
    
    void CoupledInductors::evaluateParallel(const UPDATETYPE command, bool evaluateODE)
{
  if(evaluateODE)
  {
    // Task 1
    evaluate_39();
    evaluate_40();
    evaluate_41();
    // End Task 1
    // Task 3
    evaluate_42();
    evaluate_43();
    evaluate_48();
    evaluate_49();
    evaluate_50();
    evaluate_51();
    evaluate_52();
    evaluate_53();
    // End Task 3
    // Task 2
    evaluate_44();
    evaluate_45();
    evaluate_46();
    // End Task 2
    // Task 4
    evaluate_54();
    // End Task 4
    // Task 5
    evaluate_55();
    // End Task 5
    // Task 6
    evaluate_56();
    // End Task 6
  }
  else
  {
    // Task 1
    evaluate_39();
    // End Task 1
    // Task 2
    evaluate_40();
    // End Task 2
    // Task 3
    evaluate_41();
    // End Task 3
    // Task 4
    evaluate_42();
    // End Task 4
    // Task 5
    evaluate_43();
    // End Task 5
    // Task 6
    evaluate_44();
    // End Task 6
    // Task 7
    evaluate_45();
    // End Task 7
    // Task 8
    evaluate_46();
    // End Task 8
    // Task 9
    evaluate_47();
    // End Task 9
    // Task 10
    evaluate_48();
    // End Task 10
    // Task 11
    evaluate_49();
    // End Task 11
    // Task 12
    evaluate_50();
    // End Task 12
    // Task 13
    evaluate_51();
    // End Task 13
    // Task 14
    evaluate_52();
    // End Task 14
    // Task 15
    evaluate_53();
    // End Task 15
    // Task 16
    evaluate_54();
    // End Task 16
    // Task 17
    evaluate_55();
    // End Task 17
    // Task 18
    evaluate_56();
    // End Task 18
    // Task 25
    evaluate_57();
    // End Task 25
    // Task 24
    evaluate_58();
    // End Task 24
    // Task 23
    evaluate_59();
    // End Task 23
    // Task 22
    evaluate_60();
    // End Task 22
    // Task 21
    evaluate_61();
    // End Task 21
    // Task 20
    evaluate_62();
    // End Task 20
    // Task 19
    evaluate_63();
    // End Task 19
  }
}

// Release instance
void CoupledInductors::destroy()
{
  delete this;
}

// Set current integration time
void CoupledInductors::setTime(const double& t)
{
  SystemDefaultImplementation::setTime(t);
}

// Provide number (dimension) of variables according to the index
int CoupledInductors::getDimContinuousStates() const
{
  return(SystemDefaultImplementation::getDimContinuousStates());
}


// Provide number (dimension) of variables according to the index
int CoupledInductors::getDimBoolean() const
{
  return(SystemDefaultImplementation::getDimBoolean());
}

// Provide number (dimension) of variables according to the index
int CoupledInductors::getDimInteger() const
{
  return(SystemDefaultImplementation::getDimInteger());
}
// Provide number (dimension) of variables according to the index
int CoupledInductors::getDimReal() const
{
  return(SystemDefaultImplementation::getDimReal());
}

// Provide number (dimension) of variables according to the index
int CoupledInductors::getDimString() const
{
  return(SystemDefaultImplementation::getDimString());
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int CoupledInductors::getDimRHS() const
{
  return(SystemDefaultImplementation::getDimRHS());
}

void CoupledInductors::getContinuousStates(double* z)
{
  SystemDefaultImplementation::getContinuousStates(z);
}
void CoupledInductors::getNominalStates(double* z)
{
   z[0] = 1.0;
   z[1] = 1.0;
   z[2] = 1.0;
   z[3] = 1.0;
   z[4] = 1.0;
}

// Set variables with given index to the system
void CoupledInductors::setContinuousStates(const double* z)
{
  SystemDefaultImplementation::setContinuousStates(z);
}

// Provide the right hand side (according to the index)
void CoupledInductors::getRHS(double* f)
{
  SystemDefaultImplementation::getRHS(f);
}

void CoupledInductors::setRHS(const double* f)
{
  SystemDefaultImplementation::setRHS(f);
}

bool CoupledInductors::isStepEvent()
{
 throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"isStepEvent is not yet implemented");

}

void CoupledInductors::setTerminal(bool terminal)
{
  _terminal=terminal;
}

bool CoupledInductors::terminal()
{
  return _terminal;
}

bool CoupledInductors::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

bool CoupledInductors::provideSymbolicJacobian()
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"provideSymbolicJacobian is not yet implemented");
}

void CoupledInductors::handleEvent(const bool* events)
{
}
bool CoupledInductors::checkForDiscreteEvents()
{
  return false;
}
void CoupledInductors::getZeroFunc(double* f)
{
  if(_conditions[0])
      f[0]=(_simTime - 1e-9 - _sineVoltage_P_TD);
  else
      f[0]=(_sineVoltage_P_TD - _simTime -  1e-9);
}

void CoupledInductors::setConditions(bool* c)
{
  SystemDefaultImplementation::setConditions(c);
}
void CoupledInductors::getConditions(bool* c)
{
    SystemDefaultImplementation::getConditions(c);
}
bool CoupledInductors::isConsistent()
{
  return SystemDefaultImplementation::isConsistent();
}

bool CoupledInductors::stepCompleted(double time)
{
 _algLoopSolver53->stepCompleted(_simTime);

  storeTime(time);

#if defined(__TRICORE__) || defined(__vxworks)
#endif

saveAll();
return _terminate;
}

bool CoupledInductors::stepStarted(double time)
{
#if defined(__TRICORE__) || defined(__vxworks)
#endif

return true;
}

void CoupledInductors::handleTimeEvent(int* time_events)
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
int CoupledInductors::getDimTimeEvent() const
{
  return _dimTimeEvent;
}
void CoupledInductors::getTimeEvent(time_event_type& time_events)
{
}

bool CoupledInductors::isODE()
{
  return 5>0 ;
}
int CoupledInductors::getDimZeroFunc()
{
  return _dimZeroFunc;
}

bool CoupledInductors::getCondition(unsigned int index)
{
  bool tmp3;
  switch(index)
  {
    case 0:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp3=(_simTime<_sineVoltage_P_TD);
           _conditions[0]=tmp3;
           return tmp3;
       }
       else
           return _conditions[0];
    }
    default:
    {
      string error =string("Wrong condition index ") + boost::lexical_cast<string>(index);
     throw ModelicaSimulationError(EVENT_HANDLING,error);
    }
  };
}
bool CoupledInductors::handleSystemEvents(bool* events)
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
void CoupledInductors::saveAll()
{
     _sim_vars->savePreVariables();
}




void CoupledInductors::getReal(double* z)
{
  const double* real_vars = _sim_vars->getRealVarsVector();
  memcpy(z,real_vars,62);
}



void CoupledInductors::setReal(const double* z)
{
   _sim_vars->setRealVarsVector(z);
}



void CoupledInductors::getInteger(int* z)
{
  const int* int_vars = _sim_vars->getIntVarsVector();
  memcpy(z,int_vars,1);
}



void CoupledInductors::getBoolean(bool* z)
{
  const bool* bool_vars = _sim_vars->getBoolVarsVector();
  memcpy(z,bool_vars,6);
}



void CoupledInductors::getString(string* z)
{
}

void CoupledInductors::setInteger(const int* z)
{
   _sim_vars->setIntVarsVector(z);
}

void CoupledInductors::setBoolean(const bool* z)
{
  _sim_vars->setBoolVarsVector(z);
}

void CoupledInductors::setString(const string* z)
{
}

//AlgVars
void CoupledInductors::defineAlgVars_0()
{
}

void CoupledInductors::defineAlgVars()
{
    defineAlgVars_0();
}

//DiscreteAlgVars

void CoupledInductors::defineDiscreteAlgVars()
{
}

//IntAlgVars
void CoupledInductors::defineIntAlgVars()
{
}

//BoolAlgVars
void CoupledInductors::defineBoolAlgVars()
{
}

//ParameterRealVars
void CoupledInductors::defineParameterRealVars_0()
{
}
void CoupledInductors::defineParameterRealVars()
{
    defineParameterRealVars_0();
}

//ParameterIntVars
void CoupledInductors::defineParameterIntVars()
{
}

//ParameterBoolVars
void CoupledInductors::defineParameterBoolVars_0()
{
}
void CoupledInductors::defineParameterBoolVars()
{
    defineParameterBoolVars_0();
}

//AliasRealVars
void CoupledInductors::defineAliasRealVars_0()
{
}
void CoupledInductors::defineAliasRealVars()
{
    defineAliasRealVars_0();
}

//AliasIntVars
void CoupledInductors::defineAliasIntVars()
{
}

//AliasBoolVars
void CoupledInductors::defineAliasBoolVars()
{
}

//MixedArrayVars
void CoupledInductors::defineMixedArrayVars()
{
}

//String parameter 0

void CoupledInductors::defineConstVals()
{
}
