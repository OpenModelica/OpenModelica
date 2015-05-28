
BouncingBallInitialize::BouncingBallInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
: BouncingBall(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

BouncingBallInitialize::~BouncingBallInitialize()
{
}

bool BouncingBallInitialize::initial()
{
  return _initial;
}
void BouncingBallInitialize::setInitial(bool status)
{
  _initial = status;
  if(_initial)
    _callType = IContinuous::DISCRETE;
  else
    _callType = IContinuous::CONTINUOUS;
}

void BouncingBallInitialize::initialize()
{



   initializeMemory();

   initializeFreeVariables();
   initializeBoundVariables();
   saveAll();
}

void BouncingBallInitialize::initializeMemory()
{
   _discrete_events = _event_handling->initialize(this,_sim_vars);

   //create and initialize Algloopsolvers
   
   //initialize Algloop variables
   initializeAlgloopSolverVariables();
   //init alg loop vars
                          

}

void BouncingBallInitialize::initializeFreeVariables()
{
   _simTime = 0.0;

   /*initialize parameter*/
   initializeParameterVars();
   initializeIntParameterVars();
   initializeBoolParameterVars();
   initializeStringParameterVars();
   initializeAlgVars();
   initializeDiscreteAlgVars();
   initializeIntAlgVars();
   initializeBoolAlgVars();
   //initializeAliasVars();
   //initializeIntAliasVars();
   //initializeBoolAliasVars();
   initializeStringAliasVars();
   initializeStateVars();
   initializeDerVars();
    /*external vars decls*/
   initializeExternalVar();

#if defined(__TRICORE__) || defined(__vxworks)
   //init inputs
   stepStarted(0.0);
#endif
}

void BouncingBallInitialize::initializeBoundVariables()
{
   //variable decls
   
   //bound start values
   
   //init event handling
   bool events[3];
   memset(events,true,3);
   for(int i=0;i<=3;++i) { handleEvent(events); }
   
   //init equations
   initEquations();
   
   //init alg loop solvers
   
   for(int i=0;i<_dimZeroFunc;i++)
   {
      getCondition(i);
   }
   
   //initialAnalyticJacobian();
   
    
}

void BouncingBallInitialize::initEquations()
{
   initEquation_1();
   initEquation_2();
   initEquation_3();
   initEquation_4();
   initEquation_5();
   initEquation_6();
   initEquation_7();
   initEquation_8();
   initEquation_9();
   initEquation_10();
   initEquation_11();
   initEquation_12();
   initEquation_13();
   initEquation_14();
}
/*
equation index: 1
type: SIMPLE_ASSIGN
$PRE._n_bounce = $_start(n_bounce)
*/
void BouncingBallInitialize::initEquation_1()
{
  _n_bounce = getIntStartValue(_n_bounce);
  _discrete_events->save( _n_bounce);
}
/*
equation index: 2
type: SIMPLE_ASSIGN
n_bounce = $PRE.n_bounce
*/
void BouncingBallInitialize::initEquation_2()
{
  _n_bounce = _discrete_events->pre(_n_bounce);
}
/*
equation index: 3
type: SIMPLE_ASSIGN
$PRE._v_new = $_start(v_new)
*/
void BouncingBallInitialize::initEquation_3()
{
  _v_new = getRealStartValue(_v_new);
  _discrete_events->save( _v_new);
}
/*
equation index: 4
type: SIMPLE_ASSIGN
v_new = $PRE.v_new
*/
void BouncingBallInitialize::initEquation_4()
{
  _v_new = _discrete_events->pre(_v_new);
}
/*
equation index: 5
type: SIMPLE_ASSIGN
$PRE._flying = $_start(flying)
*/
void BouncingBallInitialize::initEquation_5()
{
  _flying = getBoolStartValue(_flying);
  _discrete_events->save( _flying);
}
/*
equation index: 6
type: SIMPLE_ASSIGN
flying = $PRE.flying
*/
void BouncingBallInitialize::initEquation_6()
{
  _flying = _discrete_events->pre(_flying);
}
/*
equation index: 7
type: SIMPLE_ASSIGN
der(v) = if flying then -g else 0.0
*/
void BouncingBallInitialize::initEquation_7()
{
  double tmp4;
  if (_flying) {
    tmp4 = (-_g);
  } else {
    tmp4 = 0.0;
  }
   __zDot[1]  = tmp4;
}
/*
equation index: 8
type: SIMPLE_ASSIGN
h = $_start(h)
*/
void BouncingBallInitialize::initEquation_8()
{
    __z[0]   = getRealStartValue(  __z[0]  );
}
/*
equation index: 9
type: SIMPLE_ASSIGN
v = $_start(v)
*/
void BouncingBallInitialize::initEquation_9()
{
    __z[1]   = getRealStartValue(  __z[1]  );
}
/*
equation index: 10
type: SIMPLE_ASSIGN
$whenCondition3 = h <= 0.0 and v <= 0.0
*/
void BouncingBallInitialize::initEquation_10()
{
  _$whenCondition3 = (getCondition(0) && getCondition(1));
}
/*
equation index: 11
type: SIMPLE_ASSIGN
impact = h <= 0.0
*/
void BouncingBallInitialize::initEquation_11()
{
  _impact = getCondition(0);
}
/*
equation index: 12
type: SIMPLE_ASSIGN
der(h) = v
*/
void BouncingBallInitialize::initEquation_12()
{
   __zDot[0]  = __z[1];
}
/*
equation index: 13
type: SIMPLE_ASSIGN
$whenCondition1 = impact and v <= 0.0
*/
void BouncingBallInitialize::initEquation_13()
{
  _$whenCondition1 = (_impact && getCondition(1));
}
/*
equation index: 14
type: SIMPLE_ASSIGN
$whenCondition2 = impact
*/
void BouncingBallInitialize::initEquation_14()
{
  _$whenCondition2 = _impact;
}
void BouncingBallInitialize::initializeStateVars()
{

               setRealStartValue(  __z[0]  ,1.0);

             setRealStartValue(  __z[1]  ,0.0);
}
void BouncingBallInitialize::initializeDerVars()
{

             setRealStartValue( __zDot[0] ,0.0);

             setRealStartValue( __zDot[1] ,0.0);
}