#include <Core/ModelicaDefine.h>
#include <Core/Modelica.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSC.h"
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCFunctions.h"
#include <Core/System/EventHandling.h>
#include <Core/System/DiscreteEvents.h>
#if defined(__TRICORE__) || defined(__vxworks)
#include <DataExchange/SimDouble.h>
#endif


/* Constructor */
CauerLowPassSC::CauerLowPassSC(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
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
    defineAliasRealVars();
    defineAliasIntVars();
    defineAliasBoolVars();
    
    //Number of equations
    _dimContinuousStates = 16;
    _dimRHS = 16;
    _dimBoolean = 45;
    _dimInteger = 1;
    _dimString = 0 + 0;
    _dimReal = 429;
    _dimZeroFunc = 23;
    _dimTimeEvent = 11;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&CauerLowPassSC::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    terminateThreads = false;
    command = IContinuous::UNDEF_UPDATE;
    


}

CauerLowPassSC::CauerLowPassSC(CauerLowPassSC &instance) : SystemDefaultImplementation(instance.getGlobalSettings(),instance._sim_data,instance._sim_vars)
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
    defineAliasRealVars();
    defineAliasIntVars();
    defineAliasBoolVars();
    
    //Number of equations
    _dimContinuousStates = 16;
    _dimRHS = 16;
    _dimBoolean = 45;
    _dimInteger = 1;
    _dimString = 0 + 0;
    _dimReal = 429;
    _dimZeroFunc = 23;
    _dimTimeEvent = 11;
    //Number of residues
     _event_handling= boost::shared_ptr<EventHandling>(new EventHandling());
      //DAEs are not supported yet, Index reduction is enabled
      _dimAE = 0; // algebraic equations
      //Initialize the state vector
      SystemDefaultImplementation::initialize();
      //Instantiate auxiliary object for event handling functionality
      //_event_handling.getCondition =  boost::bind(&CauerLowPassSC::getCondition, this, _1);
      
      //Todo: reindex all arrays removed  // arrayReindex(modelInfo,useFlatArrayNotation)
      
      _functions = new Functions(_simTime,__z,__zDot,_initial,_terminate);
    double* realVars = new double[675 + _dimContinuousStates + _dimContinuousStates];
    int* integerVars = new int[0];
    bool* booleanVars = new bool[66];
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
     terminateThreads = false;
     command = IContinuous::UNDEF_UPDATE;
     


}

/* Destructor */
CauerLowPassSC::~CauerLowPassSC()
{
  deleteObjects();
  terminateThreads = true;
}

void CauerLowPassSC::deleteObjects()
{

  if(_functions != NULL)
    delete _functions;

  deleteAlgloopSolverVariables();
}

boost::shared_ptr<IAlgLoopSolverFactory> CauerLowPassSC::getAlgLoopSolverFactory()
{
    return _algLoopSolverFactory;
}

boost::shared_ptr<ISimData> CauerLowPassSC::getSimData()
{
    return _sim_data;
}

void CauerLowPassSC::initializeAlgloopSolverVariables_0()
{
  _conditions0222 = NULL;
  _conditions1222 = NULL;
  _algloop222Vars = NULL;
  _conditions0228 = NULL;
  _conditions1228 = NULL;
  _algloop228Vars = NULL;
  _conditions0234 = NULL;
  _conditions1234 = NULL;
  _algloop234Vars = NULL;
  _conditions0240 = NULL;
  _conditions1240 = NULL;
  _algloop240Vars = NULL;
  _conditions0246 = NULL;
  _conditions1246 = NULL;
  _algloop246Vars = NULL;
  _conditions0252 = NULL;
  _conditions1252 = NULL;
  _algloop252Vars = NULL;
  _conditions0260 = NULL;
  _conditions1260 = NULL;
  _algloop260Vars = NULL;
  _conditions0266 = NULL;
  _conditions1266 = NULL;
  _algloop266Vars = NULL;
  _conditions0275 = NULL;
  _conditions1275 = NULL;
  _algloop275Vars = NULL;
  _conditions0281 = NULL;
  _conditions1281 = NULL;
  _algloop281Vars = NULL;
  _conditions0289 = NULL;
  _conditions1289 = NULL;
  _algloop289Vars = NULL;
  _conditions0290 = NULL;
  _conditions1290 = NULL;
  _algloop290Vars = NULL;
}


void CauerLowPassSC::initializeAlgloopSolverVariables_1()
{
}


void CauerLowPassSC::initializeAlgloopSolverVariables_2()
{
  _conditions0124 = NULL;
  _conditions1124 = NULL;
  _algloop124Vars = NULL;
  _conditions0131 = NULL;
  _conditions1131 = NULL;
  _algloop131Vars = NULL;
  _conditions0138 = NULL;
  _conditions1138 = NULL;
  _algloop138Vars = NULL;
  _conditions0145 = NULL;
  _conditions1145 = NULL;
  _algloop145Vars = NULL;
  _conditions0152 = NULL;
  _conditions1152 = NULL;
  _algloop152Vars = NULL;
  _conditions0159 = NULL;
  _conditions1159 = NULL;
  _algloop159Vars = NULL;
  _conditions0166 = NULL;
  _conditions1166 = NULL;
  _algloop166Vars = NULL;
  _conditions0167 = NULL;
  _conditions1167 = NULL;
  _algloop167Vars = NULL;
  _conditions0174 = NULL;
  _conditions1174 = NULL;
  _algloop174Vars = NULL;
  _conditions0181 = NULL;
  _conditions1181 = NULL;
  _algloop181Vars = NULL;
  _conditions0192 = NULL;
  _conditions1192 = NULL;
  _algloop192Vars = NULL;
  _conditions0200 = NULL;
  _conditions1200 = NULL;
  _algloop200Vars = NULL;
}


void CauerLowPassSC::initializeAlgloopSolverVariables()
{
  initializeAlgloopSolverVariables_0();initializeAlgloopSolverVariables_1();initializeAlgloopSolverVariables_2();
  initializeJacAlgloopSolverVariables();
}


void CauerLowPassSC::initializeJacAlgloopSolverVariables()
{
}

void CauerLowPassSC::deleteAlgloopSolverVariables_0()
{
     if(_conditions0222)
       delete [] _conditions0222;
     if(_conditions1222)
       delete [] _conditions1222;
     if(_algloop222Vars)
       delete [] _algloop222Vars;
     if(_conditions0228)
       delete [] _conditions0228;
     if(_conditions1228)
       delete [] _conditions1228;
     if(_algloop228Vars)
       delete [] _algloop228Vars;
     if(_conditions0234)
       delete [] _conditions0234;
     if(_conditions1234)
       delete [] _conditions1234;
     if(_algloop234Vars)
       delete [] _algloop234Vars;
     if(_conditions0240)
       delete [] _conditions0240;
     if(_conditions1240)
       delete [] _conditions1240;
     if(_algloop240Vars)
       delete [] _algloop240Vars;
     if(_conditions0246)
       delete [] _conditions0246;
     if(_conditions1246)
       delete [] _conditions1246;
     if(_algloop246Vars)
       delete [] _algloop246Vars;
     if(_conditions0252)
       delete [] _conditions0252;
     if(_conditions1252)
       delete [] _conditions1252;
     if(_algloop252Vars)
       delete [] _algloop252Vars;
     if(_conditions0260)
       delete [] _conditions0260;
     if(_conditions1260)
       delete [] _conditions1260;
     if(_algloop260Vars)
       delete [] _algloop260Vars;
     if(_conditions0266)
       delete [] _conditions0266;
     if(_conditions1266)
       delete [] _conditions1266;
     if(_algloop266Vars)
       delete [] _algloop266Vars;
     if(_conditions0275)
       delete [] _conditions0275;
     if(_conditions1275)
       delete [] _conditions1275;
     if(_algloop275Vars)
       delete [] _algloop275Vars;
     if(_conditions0281)
       delete [] _conditions0281;
     if(_conditions1281)
       delete [] _conditions1281;
     if(_algloop281Vars)
       delete [] _algloop281Vars;
     if(_conditions0289)
       delete [] _conditions0289;
     if(_conditions1289)
       delete [] _conditions1289;
     if(_algloop289Vars)
       delete [] _algloop289Vars;
     if(_conditions0290)
       delete [] _conditions0290;
     if(_conditions1290)
       delete [] _conditions1290;
     if(_algloop290Vars)
       delete [] _algloop290Vars;

}


void CauerLowPassSC::deleteAlgloopSolverVariables_1()
{

}


void CauerLowPassSC::deleteAlgloopSolverVariables_2()
{
     if(_conditions0124)
       delete [] _conditions0124;
     if(_conditions1124)
       delete [] _conditions1124;
     if(_algloop124Vars)
       delete [] _algloop124Vars;
     if(_conditions0131)
       delete [] _conditions0131;
     if(_conditions1131)
       delete [] _conditions1131;
     if(_algloop131Vars)
       delete [] _algloop131Vars;
     if(_conditions0138)
       delete [] _conditions0138;
     if(_conditions1138)
       delete [] _conditions1138;
     if(_algloop138Vars)
       delete [] _algloop138Vars;
     if(_conditions0145)
       delete [] _conditions0145;
     if(_conditions1145)
       delete [] _conditions1145;
     if(_algloop145Vars)
       delete [] _algloop145Vars;
     if(_conditions0152)
       delete [] _conditions0152;
     if(_conditions1152)
       delete [] _conditions1152;
     if(_algloop152Vars)
       delete [] _algloop152Vars;
     if(_conditions0159)
       delete [] _conditions0159;
     if(_conditions1159)
       delete [] _conditions1159;
     if(_algloop159Vars)
       delete [] _algloop159Vars;
     if(_conditions0166)
       delete [] _conditions0166;
     if(_conditions1166)
       delete [] _conditions1166;
     if(_algloop166Vars)
       delete [] _algloop166Vars;
     if(_conditions0167)
       delete [] _conditions0167;
     if(_conditions1167)
       delete [] _conditions1167;
     if(_algloop167Vars)
       delete [] _algloop167Vars;
     if(_conditions0174)
       delete [] _conditions0174;
     if(_conditions1174)
       delete [] _conditions1174;
     if(_algloop174Vars)
       delete [] _algloop174Vars;
     if(_conditions0181)
       delete [] _conditions0181;
     if(_conditions1181)
       delete [] _conditions1181;
     if(_algloop181Vars)
       delete [] _algloop181Vars;
     if(_conditions0192)
       delete [] _conditions0192;
     if(_conditions1192)
       delete [] _conditions1192;
     if(_algloop192Vars)
       delete [] _algloop192Vars;
     if(_conditions0200)
       delete [] _conditions0200;
     if(_conditions1200)
       delete [] _conditions1200;
     if(_algloop200Vars)
       delete [] _algloop200Vars;

}


void CauerLowPassSC::deleteAlgloopSolverVariables()
{
  deleteAlgloopSolverVariables_0();deleteAlgloopSolverVariables_1();deleteAlgloopSolverVariables_2();
  deleteJacAlgloopSolverVariables();
}
void CauerLowPassSC::deleteJacAlgloopSolverVariables()
{
}

/*
equation index: 209
type: SIMPLE_ASSIGN
$whenCondition11 = sample(11, R11.BooleanPulse1.startTime, R11.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_209()
{
  _$whenCondition11 = _time_conditions[10];
}
/*
equation index: 210
type: SIMPLE_ASSIGN
$whenCondition10 = sample(10, R10.BooleanPulse1.startTime, R10.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_210()
{
  _$whenCondition10 = _time_conditions[9];
}
/*
equation index: 211
type: SIMPLE_ASSIGN
$whenCondition9 = sample(9, R7.BooleanPulse1.startTime, R7.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_211()
{
  _$whenCondition9 = _time_conditions[8];
}
/*
equation index: 212
type: SIMPLE_ASSIGN
$whenCondition8 = sample(8, Rp1.BooleanPulse1.startTime, Rp1.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_212()
{
  _$whenCondition8 = _time_conditions[7];
}
/*
equation index: 213
type: SIMPLE_ASSIGN
$whenCondition7 = sample(7, R3.BooleanPulse1.startTime, R3.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_213()
{
  _$whenCondition7 = _time_conditions[6];
}
/*
equation index: 214
type: SIMPLE_ASSIGN
$whenCondition6 = sample(6, R2.BooleanPulse1.startTime, R2.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_214()
{
  _$whenCondition6 = _time_conditions[5];
}
/*
equation index: 215
type: SIMPLE_ASSIGN
$whenCondition5 = sample(5, R1.BooleanPulse1.startTime, R1.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_215()
{
  _$whenCondition5 = _time_conditions[4];
}
/*
equation index: 216
type: SIMPLE_ASSIGN
$whenCondition4 = sample(4, R9.BooleanPulse1.startTime, R9.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_216()
{
  _$whenCondition4 = _time_conditions[3];
}
/*
equation index: 217
type: SIMPLE_ASSIGN
$whenCondition3 = sample(3, R8.BooleanPulse1.startTime, R8.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_217()
{
  _$whenCondition3 = _time_conditions[2];
}
/*
equation index: 218
type: SIMPLE_ASSIGN
$whenCondition2 = sample(2, R5.BooleanPulse1.startTime, R5.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_218()
{
  _$whenCondition2 = _time_conditions[1];
}
/*
equation index: 219
type: SIMPLE_ASSIGN
$whenCondition1 = sample(1, R4.BooleanPulse1.startTime, R4.BooleanPulse1.period)
*/
void CauerLowPassSC::evaluate_219()
{
  _$whenCondition1 = _time_conditions[0];
}
/*
equation index: 220
type: WHEN

when {$whenCondition11} then
  R11._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_220()
{
  if(_initial)
  {
     _R11_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R11_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition11 && !_discrete_events->pre(_$whenCondition11)))
  {
    _R11_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R11_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R11_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 221
type: SIMPLE_ASSIGN
R11._BooleanPulse1._y = time >= R11.BooleanPulse1.pulsStart and time < R11.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_221()
{
  _R11_P_BooleanPulse1_P_y = (getCondition(21) && getCondition(22));
}
/*
equation index: 222
type: LINEAR

<var>R11._IdealCommutingSwitch2._n2._i</var>
<var>R11._IdealCommutingSwitch2._s2</var>
<var>R11._n1._i</var>
<var>R11._IdealCommutingSwitch1._s1</var>
<var>R11._IdealCommutingSwitch1._n2._i</var>
<var>R11._IdealCommutingSwitch1._s2</var>
<var>R11._Capacitor1._p._v</var>
<var>R11._Capacitor1._n._v</var>
<var>R11._IdealCommutingSwitch2._s1</var>
<var>R11._n2._i</var>
<var>R11._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>C4.v</cell>
  <cell>-R11.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R11.BooleanPulse1.y then R11.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R11.BooleanPulse1.y then R11.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R11.BooleanPulse1.y then R11.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R11.BooleanPulse1.y then R11.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_222()
{
  bool restart222 = true;
  unsigned int iterations222 = 0;
  _algLoop222->getReal(_algloop222Vars );
  bool restatDiscrete222= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop222->evaluate();
          while(restart222 && !(iterations222++>500))
          {
              getConditions(_conditions0222);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver222->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1222);
              restart222 = !std::equal (_conditions1222, _conditions1222+_dimZeroFunc,_conditions0222);
          }
      }
      else
      _algLoopSolver222->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete222=true;
  }
  
  if((restart222&& iterations222 > 0)|| restatDiscrete222)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop222->setReal(_algloop222Vars );
          _algLoopSolver222->solve();
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
equation index: 223
type: SIMPLE_ASSIGN
R11._IdealCommutingSwitch1._LossPower = (-R11.Capacitor1.i) * R11.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_223()
{
  _R11_P_IdealCommutingSwitch1_P_LossPower = ((-_R11_P_Capacitor1_P_i) * _R11_P_Capacitor1_P_p_P_v);
}
/*
equation index: 224
type: SIMPLE_ASSIGN
R11._IdealCommutingSwitch2._LossPower = R11.Capacitor1.i * R11.Capacitor1.n.v + R11.n2.i * C4.v
*/
void CauerLowPassSC::evaluate_224()
{
  _R11_P_IdealCommutingSwitch2_P_LossPower = ((_R11_P_Capacitor1_P_i * _R11_P_Capacitor1_P_n_P_v) + (_R11_P_n2_P_i * __z[3]));
}
/*
equation index: 225
type: SIMPLE_ASSIGN
der(R11._Capacitor1._v) = DIVISION(R11.Capacitor1.i, R11.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_225()
{
   __zDot[7]  = division(_R11_P_Capacitor1_P_i,_R11_P_Capacitor1_P_C,"R11.Capacitor1.C");
}
/*
equation index: 226
type: WHEN

when {$whenCondition10} then
  R10._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_226()
{
  if(_initial)
  {
     _R10_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R10_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition10 && !_discrete_events->pre(_$whenCondition10)))
  {
    _R10_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R10_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R10_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 227
type: SIMPLE_ASSIGN
R10._BooleanPulse1._y = time >= R10.BooleanPulse1.pulsStart and time < R10.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_227()
{
  _R10_P_BooleanPulse1_P_y = (getCondition(19) && getCondition(20));
}
/*
equation index: 228
type: LINEAR

<var>R10._IdealCommutingSwitch2._n2._i</var>
<var>R10._IdealCommutingSwitch2._s2</var>
<var>R10._n1._i</var>
<var>R10._IdealCommutingSwitch1._s1</var>
<var>R10._IdealCommutingSwitch1._n2._i</var>
<var>R10._IdealCommutingSwitch1._s2</var>
<var>R10._Capacitor1._p._v</var>
<var>R10._Capacitor1._n._v</var>
<var>R10._IdealCommutingSwitch2._s1</var>
<var>R10._n2._i</var>
<var>R10._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R10.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C7.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R10.BooleanPulse1.y then R10.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R10.BooleanPulse1.y then R10.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R10.BooleanPulse1.y then R10.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R10.BooleanPulse1.y then R10.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_228()
{
  bool restart228 = true;
  unsigned int iterations228 = 0;
  _algLoop228->getReal(_algloop228Vars );
  bool restatDiscrete228= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop228->evaluate();
          while(restart228 && !(iterations228++>500))
          {
              getConditions(_conditions0228);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver228->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1228);
              restart228 = !std::equal (_conditions1228, _conditions1228+_dimZeroFunc,_conditions0228);
          }
      }
      else
      _algLoopSolver228->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete228=true;
  }
  
  if((restart228&& iterations228 > 0)|| restatDiscrete228)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop228->setReal(_algloop228Vars );
          _algLoopSolver228->solve();
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
equation index: 229
type: SIMPLE_ASSIGN
R10._IdealCommutingSwitch1._LossPower = (-R10.n1.i) * C7.v - R10.Capacitor1.i * R10.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_229()
{
  _R10_P_IdealCommutingSwitch1_P_LossPower = (((-_R10_P_n1_P_i) * __z[4]) - (_R10_P_Capacitor1_P_i * _R10_P_Capacitor1_P_p_P_v));
}
/*
equation index: 230
type: SIMPLE_ASSIGN
R10._IdealCommutingSwitch2._LossPower = R10.Capacitor1.i * R10.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_230()
{
  _R10_P_IdealCommutingSwitch2_P_LossPower = (_R10_P_Capacitor1_P_i * _R10_P_Capacitor1_P_n_P_v);
}
/*
equation index: 231
type: SIMPLE_ASSIGN
der(R10._Capacitor1._v) = DIVISION(R10.Capacitor1.i, R10.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_231()
{
   __zDot[6]  = division(_R10_P_Capacitor1_P_i,_R10_P_Capacitor1_P_C,"R10.Capacitor1.C");
}
/*
equation index: 232
type: WHEN

when {$whenCondition9} then
  R7._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_232()
{
  if(_initial)
  {
     _R7_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R7_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition9 && !_discrete_events->pre(_$whenCondition9)))
  {
    _R7_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R7_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R7_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 233
type: SIMPLE_ASSIGN
R7._BooleanPulse1._y = time >= R7.BooleanPulse1.pulsStart and time < R7.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_233()
{
  _R7_P_BooleanPulse1_P_y = (getCondition(17) && getCondition(18));
}
/*
equation index: 234
type: LINEAR

<var>R7._IdealCommutingSwitch2._n2._i</var>
<var>R7._IdealCommutingSwitch2._s2</var>
<var>R7._n1._i</var>
<var>R7._IdealCommutingSwitch1._s1</var>
<var>R7._IdealCommutingSwitch1._n2._i</var>
<var>R7._IdealCommutingSwitch1._s2</var>
<var>R7._Capacitor1._p._v</var>
<var>R7._Capacitor1._n._v</var>
<var>R7._IdealCommutingSwitch2._s1</var>
<var>R7._n2._i</var>
<var>R7._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R7.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C3.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R7.BooleanPulse1.y then R7.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R7.BooleanPulse1.y then R7.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R7.BooleanPulse1.y then R7.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R7.BooleanPulse1.y then R7.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_234()
{
  bool restart234 = true;
  unsigned int iterations234 = 0;
  _algLoop234->getReal(_algloop234Vars );
  bool restatDiscrete234= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop234->evaluate();
          while(restart234 && !(iterations234++>500))
          {
              getConditions(_conditions0234);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver234->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1234);
              restart234 = !std::equal (_conditions1234, _conditions1234+_dimZeroFunc,_conditions0234);
          }
      }
      else
      _algLoopSolver234->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete234=true;
  }
  
  if((restart234&& iterations234 > 0)|| restatDiscrete234)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop234->setReal(_algloop234Vars );
          _algLoopSolver234->solve();
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
equation index: 235
type: SIMPLE_ASSIGN
R7._IdealCommutingSwitch1._LossPower = (-R7.n1.i) * C3.v - R7.Capacitor1.i * R7.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_235()
{
  _R7_P_IdealCommutingSwitch1_P_LossPower = (((-_R7_P_n1_P_i) * __z[2]) - (_R7_P_Capacitor1_P_i * _R7_P_Capacitor1_P_p_P_v));
}
/*
equation index: 236
type: SIMPLE_ASSIGN
R7._IdealCommutingSwitch2._LossPower = R7.Capacitor1.i * R7.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_236()
{
  _R7_P_IdealCommutingSwitch2_P_LossPower = (_R7_P_Capacitor1_P_i * _R7_P_Capacitor1_P_n_P_v);
}
/*
equation index: 237
type: SIMPLE_ASSIGN
der(R7._Capacitor1._v) = DIVISION(R7.Capacitor1.i, R7.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_237()
{
   __zDot[12]  = division(_R7_P_Capacitor1_P_i,_R7_P_Capacitor1_P_C,"R7.Capacitor1.C");
}
/*
equation index: 238
type: WHEN

when {$whenCondition8} then
  Rp1._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_238()
{
  if(_initial)
  {
     _Rp1_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_Rp1_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition8 && !_discrete_events->pre(_$whenCondition8)))
  {
    _Rp1_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _Rp1_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_Rp1_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 239
type: SIMPLE_ASSIGN
Rp1._BooleanPulse1._y = time >= Rp1.BooleanPulse1.pulsStart and time < Rp1.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_239()
{
  _Rp1_P_BooleanPulse1_P_y = (getCondition(15) && getCondition(16));
}
/*
equation index: 240
type: LINEAR

<var>Rp1._IdealCommutingSwitch2._n2._i</var>
<var>Rp1._IdealCommutingSwitch2._s2</var>
<var>Rp1._n1._i</var>
<var>Rp1._IdealCommutingSwitch1._s1</var>
<var>Rp1._IdealCommutingSwitch1._n2._i</var>
<var>Rp1._IdealCommutingSwitch1._s2</var>
<var>Rp1._Capacitor1._p._v</var>
<var>Rp1._Capacitor1._n._v</var>
<var>Rp1._IdealCommutingSwitch2._s1</var>
<var>Rp1._n2._i</var>
<var>Rp1._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-Rp1.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C7.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_240()
{
  bool restart240 = true;
  unsigned int iterations240 = 0;
  _algLoop240->getReal(_algloop240Vars );
  bool restatDiscrete240= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop240->evaluate();
          while(restart240 && !(iterations240++>500))
          {
              getConditions(_conditions0240);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver240->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1240);
              restart240 = !std::equal (_conditions1240, _conditions1240+_dimZeroFunc,_conditions0240);
          }
      }
      else
      _algLoopSolver240->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete240=true;
  }
  
  if((restart240&& iterations240 > 0)|| restatDiscrete240)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop240->setReal(_algloop240Vars );
          _algLoopSolver240->solve();
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
equation index: 241
type: SIMPLE_ASSIGN
Rp1._IdealCommutingSwitch1._LossPower = (-Rp1.n1.i) * C7.v - Rp1.Capacitor1.i * Rp1.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_241()
{
  _Rp1_P_IdealCommutingSwitch1_P_LossPower = (((-_Rp1_P_n1_P_i) * __z[4]) - (_Rp1_P_Capacitor1_P_i * _Rp1_P_Capacitor1_P_p_P_v));
}
/*
equation index: 242
type: SIMPLE_ASSIGN
Rp1._IdealCommutingSwitch2._LossPower = Rp1.Capacitor1.i * Rp1.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_242()
{
  _Rp1_P_IdealCommutingSwitch2_P_LossPower = (_Rp1_P_Capacitor1_P_i * _Rp1_P_Capacitor1_P_n_P_v);
}
/*
equation index: 243
type: SIMPLE_ASSIGN
der(Rp1._Capacitor1._v) = DIVISION(Rp1.Capacitor1.i, Rp1.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_243()
{
   __zDot[15]  = division(_Rp1_P_Capacitor1_P_i,_Rp1_P_Capacitor1_P_C,"Rp1.Capacitor1.C");
}
/*
equation index: 244
type: WHEN

when {$whenCondition7} then
  R3._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_244()
{
  if(_initial)
  {
     _R3_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R3_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition7 && !_discrete_events->pre(_$whenCondition7)))
  {
    _R3_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R3_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R3_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 245
type: SIMPLE_ASSIGN
R3._BooleanPulse1._y = time >= R3.BooleanPulse1.pulsStart and time < R3.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_245()
{
  _R3_P_BooleanPulse1_P_y = (getCondition(13) && getCondition(14));
}
/*
equation index: 246
type: LINEAR

<var>R3._n2._i</var>
<var>R3._IdealCommutingSwitch2._s1</var>
<var>R3._n1._i</var>
<var>R3._IdealCommutingSwitch1._s1</var>
<var>R3._IdealCommutingSwitch1._n2._i</var>
<var>R3._IdealCommutingSwitch1._s2</var>
<var>R3._Capacitor1._p._v</var>
<var>R3._Capacitor1._n._v</var>
<var>R3._IdealCommutingSwitch2._s2</var>
<var>R3._IdealCommutingSwitch2._n2._i</var>
<var>R3._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R3.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C1.v</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R3.BooleanPulse1.y then R3.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R3.BooleanPulse1.y then R3.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R3.BooleanPulse1.y then R3.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R3.BooleanPulse1.y then R3.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_246()
{
  bool restart246 = true;
  unsigned int iterations246 = 0;
  _algLoop246->getReal(_algloop246Vars );
  bool restatDiscrete246= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop246->evaluate();
          while(restart246 && !(iterations246++>500))
          {
              getConditions(_conditions0246);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver246->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1246);
              restart246 = !std::equal (_conditions1246, _conditions1246+_dimZeroFunc,_conditions0246);
          }
      }
      else
      _algLoopSolver246->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete246=true;
  }
  
  if((restart246&& iterations246 > 0)|| restatDiscrete246)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop246->setReal(_algloop246Vars );
          _algLoopSolver246->solve();
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
equation index: 247
type: SIMPLE_ASSIGN
R3._IdealCommutingSwitch1._LossPower = (-R3.Capacitor1.i) * R3.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_247()
{
  _R3_P_IdealCommutingSwitch1_P_LossPower = ((-_R3_P_Capacitor1_P_i) * _R3_P_Capacitor1_P_p_P_v);
}
/*
equation index: 248
type: SIMPLE_ASSIGN
R3._IdealCommutingSwitch2._LossPower = R3.Capacitor1.i * R3.Capacitor1.n.v - R3.n2.i * C1.v
*/
void CauerLowPassSC::evaluate_248()
{
  _R3_P_IdealCommutingSwitch2_P_LossPower = ((_R3_P_Capacitor1_P_i * _R3_P_Capacitor1_P_n_P_v) - (_R3_P_n2_P_i * __z[0]));
}
/*
equation index: 249
type: SIMPLE_ASSIGN
der(R3._Capacitor1._v) = DIVISION(R3.Capacitor1.i, R3.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_249()
{
   __zDot[9]  = division(_R3_P_Capacitor1_P_i,_R3_P_Capacitor1_P_C,"R3.Capacitor1.C");
}
/*
equation index: 250
type: WHEN

when {$whenCondition6} then
  R2._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_250()
{
  if(_initial)
  {
     _R2_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R2_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition6 && !_discrete_events->pre(_$whenCondition6)))
  {
    _R2_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R2_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R2_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 251
type: SIMPLE_ASSIGN
R2._BooleanPulse1._y = time >= R2.BooleanPulse1.pulsStart and time < R2.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_251()
{
  _R2_P_BooleanPulse1_P_y = (getCondition(11) && getCondition(12));
}
/*
equation index: 252
type: LINEAR

<var>R2._IdealCommutingSwitch2._n2._i</var>
<var>R2._IdealCommutingSwitch2._s2</var>
<var>R2._n1._i</var>
<var>R2._IdealCommutingSwitch1._s1</var>
<var>R2._IdealCommutingSwitch1._n2._i</var>
<var>R2._IdealCommutingSwitch1._s2</var>
<var>R2._Capacitor1._p._v</var>
<var>R2._Capacitor1._n._v</var>
<var>R2._IdealCommutingSwitch2._s1</var>
<var>R2._n2._i</var>
<var>R2._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R2.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C3.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R2.BooleanPulse1.y then R2.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R2.BooleanPulse1.y then R2.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R2.BooleanPulse1.y then R2.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R2.BooleanPulse1.y then R2.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_252()
{
  bool restart252 = true;
  unsigned int iterations252 = 0;
  _algLoop252->getReal(_algloop252Vars );
  bool restatDiscrete252= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop252->evaluate();
          while(restart252 && !(iterations252++>500))
          {
              getConditions(_conditions0252);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver252->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1252);
              restart252 = !std::equal (_conditions1252, _conditions1252+_dimZeroFunc,_conditions0252);
          }
      }
      else
      _algLoopSolver252->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete252=true;
  }
  
  if((restart252&& iterations252 > 0)|| restatDiscrete252)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop252->setReal(_algloop252Vars );
          _algLoopSolver252->solve();
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
equation index: 253
type: SIMPLE_ASSIGN
R2._IdealCommutingSwitch1._LossPower = (-R2.n1.i) * C3.v - R2.Capacitor1.i * R2.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_253()
{
  _R2_P_IdealCommutingSwitch1_P_LossPower = (((-_R2_P_n1_P_i) * __z[2]) - (_R2_P_Capacitor1_P_i * _R2_P_Capacitor1_P_p_P_v));
}
/*
equation index: 254
type: SIMPLE_ASSIGN
R2._IdealCommutingSwitch2._LossPower = R2.Capacitor1.i * R2.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_254()
{
  _R2_P_IdealCommutingSwitch2_P_LossPower = (_R2_P_Capacitor1_P_i * _R2_P_Capacitor1_P_n_P_v);
}
/*
equation index: 255
type: SIMPLE_ASSIGN
der(R2._Capacitor1._v) = DIVISION(R2.Capacitor1.i, R2.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_255()
{
   __zDot[8]  = division(_R2_P_Capacitor1_P_i,_R2_P_Capacitor1_P_C,"R2.Capacitor1.C");
}
/*
equation index: 256
type: WHEN

when {$whenCondition5} then
  R1._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_256()
{
  if(_initial)
  {
     _R1_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R1_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition5 && !_discrete_events->pre(_$whenCondition5)))
  {
    _R1_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R1_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R1_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 257
type: SIMPLE_ASSIGN
R1._BooleanPulse1._y = time >= R1.BooleanPulse1.pulsStart and time < R1.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_257()
{
  _R1_P_BooleanPulse1_P_y = (getCondition(9) && getCondition(10));
}
/*
equation index: 258
type: WHEN

when {$whenCondition4} then
  R9._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_258()
{
  if(_initial)
  {
     _R9_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R9_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition4 && !_discrete_events->pre(_$whenCondition4)))
  {
    _R9_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R9_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R9_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 259
type: SIMPLE_ASSIGN
R9._BooleanPulse1._y = time >= R9.BooleanPulse1.pulsStart and time < R9.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_259()
{
  _R9_P_BooleanPulse1_P_y = (getCondition(7) && getCondition(8));
}
/*
equation index: 260
type: LINEAR

<var>R9._IdealCommutingSwitch2._n2._i</var>
<var>R9._IdealCommutingSwitch2._s2</var>
<var>R9._IdealCommutingSwitch1._n1._i</var>
<var>R9._IdealCommutingSwitch1._s1</var>
<var>R9._n1._i</var>
<var>R9._IdealCommutingSwitch1._s2</var>
<var>R9._Capacitor1._p._v</var>
<var>R9._Capacitor1._n._v</var>
<var>R9._IdealCommutingSwitch2._s1</var>
<var>R9._n2._i</var>
<var>R9._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R9.Capacitor1.v</cell>
  <cell>C2.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R9.BooleanPulse1.y then R9.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R9.BooleanPulse1.y then R9.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R9.BooleanPulse1.y then R9.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R9.BooleanPulse1.y then R9.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_260()
{
  bool restart260 = true;
  unsigned int iterations260 = 0;
  _algLoop260->getReal(_algloop260Vars );
  bool restatDiscrete260= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop260->evaluate();
          while(restart260 && !(iterations260++>500))
          {
              getConditions(_conditions0260);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver260->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1260);
              restart260 = !std::equal (_conditions1260, _conditions1260+_dimZeroFunc,_conditions0260);
          }
      }
      else
      _algLoopSolver260->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete260=true;
  }
  
  if((restart260&& iterations260 > 0)|| restatDiscrete260)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop260->setReal(_algloop260Vars );
          _algLoopSolver260->solve();
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
equation index: 261
type: SIMPLE_ASSIGN
R9._IdealCommutingSwitch1._LossPower = R9.n1.i * C2.v - R9.Capacitor1.i * R9.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_261()
{
  _R9_P_IdealCommutingSwitch1_P_LossPower = ((_R9_P_n1_P_i * __z[1]) - (_R9_P_Capacitor1_P_i * _R9_P_Capacitor1_P_p_P_v));
}
/*
equation index: 262
type: SIMPLE_ASSIGN
R9._IdealCommutingSwitch2._LossPower = R9.Capacitor1.i * R9.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_262()
{
  _R9_P_IdealCommutingSwitch2_P_LossPower = (_R9_P_Capacitor1_P_i * _R9_P_Capacitor1_P_n_P_v);
}
/*
equation index: 263
type: SIMPLE_ASSIGN
der(R9._Capacitor1._v) = DIVISION(R9.Capacitor1.i, R9.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_263()
{
   __zDot[14]  = division(_R9_P_Capacitor1_P_i,_R9_P_Capacitor1_P_C,"R9.Capacitor1.C");
}
/*
equation index: 264
type: WHEN

when {$whenCondition3} then
  R8._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_264()
{
  if(_initial)
  {
     _R8_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R8_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition3 && !_discrete_events->pre(_$whenCondition3)))
  {
    _R8_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R8_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R8_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 265
type: SIMPLE_ASSIGN
R8._BooleanPulse1._y = time >= R8.BooleanPulse1.pulsStart and time < R8.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_265()
{
  _R8_P_BooleanPulse1_P_y = (getCondition(5) && getCondition(6));
}
/*
equation index: 266
type: LINEAR

<var>R8._IdealCommutingSwitch2._n2._i</var>
<var>R8._IdealCommutingSwitch2._s2</var>
<var>R8._IdealCommutingSwitch1._n1._i</var>
<var>R8._IdealCommutingSwitch1._s1</var>
<var>R8._n1._i</var>
<var>R8._IdealCommutingSwitch1._s2</var>
<var>R8._Capacitor1._p._v</var>
<var>R8._Capacitor1._n._v</var>
<var>R8._IdealCommutingSwitch2._s1</var>
<var>R8._n2._i</var>
<var>R8._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R8.Capacitor1.v</cell>
  <cell>C4.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R8.BooleanPulse1.y then R8.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R8.BooleanPulse1.y then R8.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R8.BooleanPulse1.y then R8.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R8.BooleanPulse1.y then R8.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_266()
{
  bool restart266 = true;
  unsigned int iterations266 = 0;
  _algLoop266->getReal(_algloop266Vars );
  bool restatDiscrete266= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop266->evaluate();
          while(restart266 && !(iterations266++>500))
          {
              getConditions(_conditions0266);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver266->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1266);
              restart266 = !std::equal (_conditions1266, _conditions1266+_dimZeroFunc,_conditions0266);
          }
      }
      else
      _algLoopSolver266->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete266=true;
  }
  
  if((restart266&& iterations266 > 0)|| restatDiscrete266)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop266->setReal(_algloop266Vars );
          _algLoopSolver266->solve();
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
equation index: 267
type: SIMPLE_ASSIGN
R8._IdealCommutingSwitch1._LossPower = R8.n1.i * C4.v - R8.Capacitor1.i * R8.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_267()
{
  _R8_P_IdealCommutingSwitch1_P_LossPower = ((_R8_P_n1_P_i * __z[3]) - (_R8_P_Capacitor1_P_i * _R8_P_Capacitor1_P_p_P_v));
}
/*
equation index: 268
type: SIMPLE_ASSIGN
C7._i = (-R9.n2.i) - R8.n2.i
*/
void CauerLowPassSC::evaluate_268()
{
  _C7_P_i = ((-_R9_P_n2_P_i) - _R8_P_n2_P_i);
}
/*
equation index: 269
type: SIMPLE_ASSIGN
der(C7._v) = DIVISION(C7.i, C7.C)
*/
void CauerLowPassSC::evaluate_269()
{
   __zDot[4]  = division(_C7_P_i,_C7_P_C,"C7.C");
}
/*
equation index: 270
type: SIMPLE_ASSIGN
Op4._out._i = C7.i - R10.n1.i - Rp1.n1.i
*/
void CauerLowPassSC::evaluate_270()
{
  _Op4_P_out_P_i = ((_C7_P_i - _R10_P_n1_P_i) - _Rp1_P_n1_P_i);
}
/*
equation index: 271
type: SIMPLE_ASSIGN
R8._IdealCommutingSwitch2._LossPower = R8.Capacitor1.i * R8.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_271()
{
  _R8_P_IdealCommutingSwitch2_P_LossPower = (_R8_P_Capacitor1_P_i * _R8_P_Capacitor1_P_n_P_v);
}
/*
equation index: 272
type: SIMPLE_ASSIGN
der(R8._Capacitor1._v) = DIVISION(R8.Capacitor1.i, R8.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_272()
{
   __zDot[13]  = division(_R8_P_Capacitor1_P_i,_R8_P_Capacitor1_P_C,"R8.Capacitor1.C");
}
/*
equation index: 273
type: WHEN

when {$whenCondition2} then
  R5._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_273()
{
  if(_initial)
  {
     _R5_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R5_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition2 && !_discrete_events->pre(_$whenCondition2)))
  {
    _R5_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R5_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R5_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 274
type: SIMPLE_ASSIGN
R5._BooleanPulse1._y = time >= R5.BooleanPulse1.pulsStart and time < R5.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_274()
{
  _R5_P_BooleanPulse1_P_y = (getCondition(3) && getCondition(4));
}
/*
equation index: 275
type: LINEAR

<var>R5._IdealCommutingSwitch2._n2._i</var>
<var>R5._IdealCommutingSwitch2._s2</var>
<var>R5._IdealCommutingSwitch1._n1._i</var>
<var>R5._IdealCommutingSwitch1._s1</var>
<var>R5._n1._i</var>
<var>R5._IdealCommutingSwitch1._s2</var>
<var>R5._Capacitor1._p._v</var>
<var>R5._Capacitor1._n._v</var>
<var>R5._IdealCommutingSwitch2._s1</var>
<var>R5._n2._i</var>
<var>R5._Capacitor1._i</var>
<row>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R5.Capacitor1.v</cell>
  <cell>C2.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>-1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R5.BooleanPulse1.y then R5.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R5.BooleanPulse1.y then R5.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R5.BooleanPulse1.y then R5.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R5.BooleanPulse1.y then R5.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_275()
{
  bool restart275 = true;
  unsigned int iterations275 = 0;
  _algLoop275->getReal(_algloop275Vars );
  bool restatDiscrete275= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop275->evaluate();
          while(restart275 && !(iterations275++>500))
          {
              getConditions(_conditions0275);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver275->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1275);
              restart275 = !std::equal (_conditions1275, _conditions1275+_dimZeroFunc,_conditions0275);
          }
      }
      else
      _algLoopSolver275->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete275=true;
  }
  
  if((restart275&& iterations275 > 0)|| restatDiscrete275)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop275->setReal(_algloop275Vars );
          _algLoopSolver275->solve();
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
equation index: 276
type: SIMPLE_ASSIGN
R5._IdealCommutingSwitch1._LossPower = R5.n1.i * C2.v - R5.Capacitor1.i * R5.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_276()
{
  _R5_P_IdealCommutingSwitch1_P_LossPower = ((_R5_P_n1_P_i * __z[1]) - (_R5_P_Capacitor1_P_i * _R5_P_Capacitor1_P_p_P_v));
}
/*
equation index: 277
type: SIMPLE_ASSIGN
R5._IdealCommutingSwitch2._LossPower = R5.Capacitor1.i * R5.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_277()
{
  _R5_P_IdealCommutingSwitch2_P_LossPower = (_R5_P_Capacitor1_P_i * _R5_P_Capacitor1_P_n_P_v);
}
/*
equation index: 278
type: SIMPLE_ASSIGN
der(R5._Capacitor1._v) = DIVISION(R5.Capacitor1.i, R5.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_278()
{
   __zDot[11]  = division(_R5_P_Capacitor1_P_i,_R5_P_Capacitor1_P_C,"R5.Capacitor1.C");
}
/*
equation index: 279
type: WHEN

when {$whenCondition1} then
  R4._BooleanPulse1._pulsStart = time;
end when;
*/
void CauerLowPassSC::evaluate_279()
{
  if(_initial)
  {
     _R4_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R4_P_BooleanPulse1_P_pulsStart);
  }
  else if (0 || (_$whenCondition1 && !_discrete_events->pre(_$whenCondition1)))
  {
    _R4_P_BooleanPulse1_P_pulsStart = _simTime;;
  }
  else
  {
         _R4_P_BooleanPulse1_P_pulsStart = _discrete_events->pre(_R4_P_BooleanPulse1_P_pulsStart);
   }
}
/*
equation index: 280
type: SIMPLE_ASSIGN
R4._BooleanPulse1._y = time >= R4.BooleanPulse1.pulsStart and time < R4.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSC::evaluate_280()
{
  _R4_P_BooleanPulse1_P_y = (getCondition(1) && getCondition(2));
}
/*
equation index: 281
type: LINEAR

<var>R4._IdealCommutingSwitch2._n2._i</var>
<var>R4._IdealCommutingSwitch2._s2</var>
<var>R4._Ground1._p._i</var>
<var>R4._IdealCommutingSwitch1._s1</var>
<var>R4._n1._i</var>
<var>R4._IdealCommutingSwitch1._s2</var>
<var>R4._Capacitor1._p._v</var>
<var>R4._Capacitor1._n._v</var>
<var>R4._IdealCommutingSwitch2._s1</var>
<var>R4._n2._i</var>
<var>R4._Capacitor1._i</var>
<row>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R4.Capacitor1.v</cell>
  <cell>-C1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="4">
    <residual>-1.0</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="0">
    <residual>-1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>if R4.BooleanPulse1.y then R4.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-(if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="4" col="6">
    <residual>-1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-(if R4.BooleanPulse1.y then R4.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="6">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>1.0</residual>
  </cell><cell row="6" col="5">
    <residual>if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="7" col="3">
    <residual>-(if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="7" col="6">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="3">
    <residual>if R4.BooleanPulse1.y then R4.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R4.BooleanPulse1.y then R4.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="7">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_281()
{
  bool restart281 = true;
  unsigned int iterations281 = 0;
  _algLoop281->getReal(_algloop281Vars );
  bool restatDiscrete281= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop281->evaluate();
          while(restart281 && !(iterations281++>500))
          {
              getConditions(_conditions0281);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver281->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1281);
              restart281 = !std::equal (_conditions1281, _conditions1281+_dimZeroFunc,_conditions0281);
          }
      }
      else
      _algLoopSolver281->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete281=true;
  }
  
  if((restart281&& iterations281 > 0)|| restatDiscrete281)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop281->setReal(_algloop281Vars );
          _algLoopSolver281->solve();
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
equation index: 282
type: SIMPLE_ASSIGN
R4._IdealCommutingSwitch1._LossPower = (-R4.n1.i) * C1.v - R4.Capacitor1.i * R4.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_282()
{
  _R4_P_IdealCommutingSwitch1_P_LossPower = (((-_R4_P_n1_P_i) * __z[0]) - (_R4_P_Capacitor1_P_i * _R4_P_Capacitor1_P_p_P_v));
}
/*
equation index: 283
type: SIMPLE_ASSIGN
C3._i = (-R5.n2.i) - R4.n2.i
*/
void CauerLowPassSC::evaluate_283()
{
  _C3_P_i = ((-_R5_P_n2_P_i) - _R4_P_n2_P_i);
}
/*
equation index: 284
type: SIMPLE_ASSIGN
der(C3._v) = DIVISION(C3.i, C3.C)
*/
void CauerLowPassSC::evaluate_284()
{
   __zDot[2]  = division(_C3_P_i,_C3_P_C,"C3.C");
}
/*
equation index: 285
type: SIMPLE_ASSIGN
Op2._out._i = C3.i - R7.n1.i - R2.n1.i
*/
void CauerLowPassSC::evaluate_285()
{
  _Op2_P_out_P_i = ((_C3_P_i - _R7_P_n1_P_i) - _R2_P_n1_P_i);
}
/*
equation index: 286
type: SIMPLE_ASSIGN
R4._IdealCommutingSwitch2._LossPower = R4.Capacitor1.i * R4.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_286()
{
  _R4_P_IdealCommutingSwitch2_P_LossPower = (_R4_P_Capacitor1_P_i * _R4_P_Capacitor1_P_n_P_v);
}
/*
equation index: 287
type: SIMPLE_ASSIGN
der(R4._Capacitor1._v) = DIVISION(R4.Capacitor1.i, R4.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_287()
{
   __zDot[10]  = division(_R4_P_Capacitor1_P_i,_R4_P_Capacitor1_P_C,"R4.Capacitor1.C");
}
/*
equation index: 288
type: SIMPLE_ASSIGN
V._v = V.signalSource.offset + (if time < V.signalSource.startTime then 0.0 else V.signalSource.height)
*/
void CauerLowPassSC::evaluate_288()
{
  double tmp0;
  if (getCondition(0)) {
    tmp0 = 0.0;
  } else {
    tmp0 = _V_P_signalSource_P_height;
  }
  _V_P_v = (_V_P_signalSource_P_offset + tmp0);
}
/*
equation index: 289
type: LINEAR

<var>R1._n2._i</var>
<var>R1._IdealCommutingSwitch2._s1</var>
<var>R1._Capacitor1._i</var>
<var>R1._IdealCommutingSwitch2._n2._i</var>
<var>R1._IdealCommutingSwitch2._s2</var>
<var>R1._Capacitor1._n._v</var>
<var>R1._Capacitor1._p._v</var>
<var>R1._IdealCommutingSwitch1._s2</var>
<var>R1._IdealCommutingSwitch1._n2._i</var>
<var>V._i</var>
<var>R1._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-V.v</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R1.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="6">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R1.BooleanPulse1.y then R1.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="2">
    <residual>1.0</residual>
  </cell><cell row="2" col="8">
    <residual>-1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="3" col="8">
    <residual>1.0</residual>
  </cell><cell row="4" col="6">
    <residual>1.0</residual>
  </cell><cell row="4" col="7">
    <residual>-(if R1.BooleanPulse1.y then R1.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-1.0</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R1.BooleanPulse1.y then R1.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="8" col="0">
    <residual>-1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="3">
    <residual>-1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="9" col="5">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R1.BooleanPulse1.y then R1.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_289()
{
  bool restart289 = true;
  unsigned int iterations289 = 0;
  _algLoop289->getReal(_algloop289Vars );
  bool restatDiscrete289= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop289->evaluate();
          while(restart289 && !(iterations289++>500))
          {
              getConditions(_conditions0289);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver289->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1289);
              restart289 = !std::equal (_conditions1289, _conditions1289+_dimZeroFunc,_conditions0289);
          }
      }
      else
      _algLoopSolver289->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete289=true;
  }
  
  if((restart289&& iterations289 > 0)|| restatDiscrete289)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop289->setReal(_algloop289Vars );
          _algLoopSolver289->solve();
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
equation index: 290
type: LINEAR

<var>C2._i</var>
<var>C4._i</var>
<var>der(C4._v)</var>
<var>C9._i</var>
<var>C8._i</var>
<var>der(C2._v)</var>
<var>C6._i</var>
<var>C5._i</var>
<var>der(C1._v)</var>
<var>C1._i</var>
<row>
  <cell>(-R1.n2.i) - R2.n2.i - R3.n1.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>(-Rp1.n2.i) - R7.n2.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>(-R11.n1.i) - R10.n2.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="0">
    <residual>-1.0</residual>
  </cell><cell row="0" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="8">
    <residual>-C1.C</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="2" col="7">
    <residual>1.0</residual>
  </cell><cell row="2" col="8">
    <residual>C5.C</residual>
  </cell><cell row="3" col="1">
    <residual>-1.0</residual>
  </cell><cell row="3" col="6">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="4" col="5">
    <residual>C6.C</residual>
  </cell><cell row="4" col="6">
    <residual>1.0</residual>
  </cell><cell row="5" col="4">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-C8.C</residual>
  </cell><cell row="6" col="3">
    <residual>1.0</residual>
  </cell><cell row="6" col="4">
    <residual>-1.0</residual>
  </cell><cell row="7" col="2">
    <residual>C9.C</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="8" col="1">
    <residual>1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-C4.C</residual>
  </cell><cell row="9" col="0">
    <residual>1.0</residual>
  </cell><cell row="9" col="5">
    <residual>-C2.C</residual>
  </cell>
</matrix>
*/
void CauerLowPassSC::evaluate_290()
{
  bool restart290 = true;
  unsigned int iterations290 = 0;
  _algLoop290->getReal(_algloop290Vars );
  bool restatDiscrete290= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop290->evaluate();
          while(restart290 && !(iterations290++>500))
          {
              getConditions(_conditions0290);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver290->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1290);
              restart290 = !std::equal (_conditions1290, _conditions1290+_dimZeroFunc,_conditions0290);
          }
      }
      else
      _algLoopSolver290->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete290=true;
  }
  
  if((restart290&& iterations290 > 0)|| restatDiscrete290)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop290->setReal(_algloop290Vars );
          _algLoopSolver290->solve();
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
equation index: 291
type: SIMPLE_ASSIGN
Op5._out._i = C9.i - R8.n1.i - R11.n2.i - C4.i
*/
void CauerLowPassSC::evaluate_291()
{
  _Op5_P_out_P_i = (((_C9_P_i - _R8_P_n1_P_i) - _R11_P_n2_P_i) - _C4_P_i);
}
/*
equation index: 292
type: SIMPLE_ASSIGN
Op3._out._i = C6.i - R5.n1.i - R9.n1.i - C2.i - C8.i
*/
void CauerLowPassSC::evaluate_292()
{
  _Op3_P_out_P_i = ((((_C6_P_i - _R5_P_n1_P_i) - _R9_P_n1_P_i) - _C2_P_i) - _C8_P_i);
}
/*
equation index: 293
type: SIMPLE_ASSIGN
Op1._out._i = C1.i - R4.n1.i - C5.i - R3.n2.i
*/
void CauerLowPassSC::evaluate_293()
{
  _Op1_P_out_P_i = (((_C1_P_i - _R4_P_n1_P_i) - _C5_P_i) - _R3_P_n2_P_i);
}
/*
equation index: 294
type: SIMPLE_ASSIGN
der(R1._Capacitor1._v) = DIVISION(R1.Capacitor1.i, R1.Capacitor1.C)
*/
void CauerLowPassSC::evaluate_294()
{
   __zDot[5]  = division(_R1_P_Capacitor1_P_i,_R1_P_Capacitor1_P_C,"R1.Capacitor1.C");
}
/*
equation index: 295
type: SIMPLE_ASSIGN
R1._IdealCommutingSwitch2._LossPower = R1.Capacitor1.i * R1.Capacitor1.n.v
*/
void CauerLowPassSC::evaluate_295()
{
  _R1_P_IdealCommutingSwitch2_P_LossPower = (_R1_P_Capacitor1_P_i * _R1_P_Capacitor1_P_n_P_v);
}
/*
equation index: 296
type: SIMPLE_ASSIGN
R1._IdealCommutingSwitch1._LossPower = (-V.i) * V.v - R1.Capacitor1.i * R1.Capacitor1.p.v
*/
void CauerLowPassSC::evaluate_296()
{
  _R1_P_IdealCommutingSwitch1_P_LossPower = (((-_V_P_i) * _V_P_v) - (_R1_P_Capacitor1_P_i * _R1_P_Capacitor1_P_p_P_v));
}

bool CauerLowPassSC::evaluateAll(const UPDATETYPE command)
{
  bool state_var_reinitialized = false;
  
  /* Evaluate Equations*/
  evaluate_209();
  evaluate_210();
  evaluate_211();
  evaluate_212();
  evaluate_213();
  evaluate_214();
  evaluate_215();
  evaluate_216();
  evaluate_217();
  evaluate_218();
  evaluate_219();
  evaluate_220();
  evaluate_221();
  evaluate_222();
  evaluate_223();
  evaluate_224();
  evaluate_225();
  evaluate_226();
  evaluate_227();
  evaluate_228();
  evaluate_229();
  evaluate_230();
  evaluate_231();
  evaluate_232();
  evaluate_233();
  evaluate_234();
  evaluate_235();
  evaluate_236();
  evaluate_237();
  evaluate_238();
  evaluate_239();
  evaluate_240();
  evaluate_241();
  evaluate_242();
  evaluate_243();
  evaluate_244();
  evaluate_245();
  evaluate_246();
  evaluate_247();
  evaluate_248();
  evaluate_249();
  evaluate_250();
  evaluate_251();
  evaluate_252();
  evaluate_253();
  evaluate_254();
  evaluate_255();
  evaluate_256();
  evaluate_257();
  evaluate_258();
  evaluate_259();
  evaluate_260();
  evaluate_261();
  evaluate_262();
  evaluate_263();
  evaluate_264();
  evaluate_265();
  evaluate_266();
  evaluate_267();
  evaluate_268();
  evaluate_269();
  evaluate_270();
  evaluate_271();
  evaluate_272();
  evaluate_273();
  evaluate_274();
  evaluate_275();
  evaluate_276();
  evaluate_277();
  evaluate_278();
  evaluate_279();
  evaluate_280();
  evaluate_281();
  evaluate_282();
  evaluate_283();
  evaluate_284();
  evaluate_285();
  evaluate_286();
  evaluate_287();
  evaluate_288();
  evaluate_289();
  evaluate_290();
  evaluate_291();
  evaluate_292();
  evaluate_293();
  evaluate_294();
  evaluate_295();
  evaluate_296();
  
  /* evaluateODE(command);
  
  evaluate_220();
  evaluate_223();
  evaluate_224();
  evaluate_226();
  evaluate_229();
  evaluate_230();
  evaluate_232();
  evaluate_235();
  evaluate_236();
  evaluate_238();
  evaluate_241();
  evaluate_242();
  evaluate_244();
  evaluate_247();
  evaluate_248();
  evaluate_250();
  evaluate_253();
  evaluate_254();
  evaluate_256();
  evaluate_258();
  evaluate_261();
  evaluate_262();
  evaluate_264();
  evaluate_267();
  evaluate_270();
  evaluate_271();
  evaluate_273();
  evaluate_276();
  evaluate_277();
  evaluate_279();
  evaluate_282();
  evaluate_285();
  evaluate_286();
  evaluate_291();
  evaluate_292();
  evaluate_293();
  evaluate_295();
  evaluate_296();
  */
  // Reinits
  
  
  
  
  
  
  
  
  
  
  

  return state_var_reinitialized;
}

void CauerLowPassSC::evaluateZeroFuncs(const UPDATETYPE command)
{
  /* Evaluate Equations*/
  evaluate_209();
  evaluate_210();
  evaluate_211();
  evaluate_212();
  evaluate_213();
  evaluate_214();
  evaluate_215();
  evaluate_216();
  evaluate_217();
  evaluate_218();
  evaluate_219();
}

bool CauerLowPassSC::evaluateConditions(const UPDATETYPE command)
{
  return evaluateAll(command);
}

//using type: pthreads
void CauerLowPassSC::evaluateODE(const UPDATETYPE command)
{
  this->command = command;
  // Task 1
  evaluate_209();
  // End Task 1
  // Task 32
  evaluate_280();
  evaluate_281();
  // End Task 32
  // Task 2
  evaluate_210();
  // End Task 2
  // Task 34
  evaluate_287();
  // End Task 34
  // Task 3
  evaluate_211();
  // End Task 3
  // Task 30
  evaluate_274();
  evaluate_275();
  // End Task 30
  // Task 4
  evaluate_212();
  // End Task 4
  // Task 33
  evaluate_283();
  evaluate_284();
  // End Task 33
  // Task 5
  evaluate_213();
  // End Task 5
  // Task 31
  evaluate_278();
  // End Task 31
  // Task 6
  evaluate_214();
  // End Task 6
  // Task 27
  evaluate_265();
  evaluate_266();
  // End Task 27
  // Task 7
  evaluate_215();
  // End Task 7
  // Task 29
  evaluate_272();
  // End Task 29
  // Task 8
  evaluate_216();
  // End Task 8
  // Task 25
  evaluate_259();
  evaluate_260();
  // End Task 25
  // Task 9
  evaluate_217();
  // End Task 9
  // Task 28
  evaluate_268();
  evaluate_269();
  // End Task 28
  // Task 10
  evaluate_218();
  // End Task 10
  // Task 26
  evaluate_263();
  // End Task 26
  // Task 11
  evaluate_219();
  // End Task 11
  // Task 24
  evaluate_257();
  evaluate_288();
  evaluate_289();
  // End Task 24
  // Task 12
  evaluate_221();
  evaluate_222();
  // End Task 12
  // Task 36
  evaluate_294();
  // End Task 36
  // Task 13
  evaluate_225();
  // End Task 13
  // Task 22
  evaluate_251();
  evaluate_252();
  // End Task 22
  // Task 14
  evaluate_227();
  evaluate_228();
  // End Task 14
  // Task 23
  evaluate_255();
  // End Task 23
  // Task 15
  evaluate_231();
  // End Task 15
  // Task 20
  evaluate_245();
  evaluate_246();
  // End Task 20
  // Task 16
  evaluate_233();
  evaluate_234();
  // End Task 16
  // Task 21
  evaluate_249();
  // End Task 21
  // Task 17
  evaluate_237();
  // End Task 17
  // Task 18
  evaluate_239();
  evaluate_240();
  // End Task 18
  // Task 35
  evaluate_290();
  // End Task 35
  // Task 19
  evaluate_243();
  // End Task 19
}

// Release instance
void CauerLowPassSC::destroy()
{
  delete this;
}

// Set current integration time
void CauerLowPassSC::setTime(const double& t)
{
  SystemDefaultImplementation::setTime(t);
}

// Provide number (dimension) of variables according to the index
int CauerLowPassSC::getDimContinuousStates() const
{
  return(SystemDefaultImplementation::getDimContinuousStates());
}


// Provide number (dimension) of variables according to the index
int CauerLowPassSC::getDimBoolean() const
{
  return(SystemDefaultImplementation::getDimBoolean());
}

// Provide number (dimension) of variables according to the index
int CauerLowPassSC::getDimInteger() const
{
  return(SystemDefaultImplementation::getDimInteger());
}
// Provide number (dimension) of variables according to the index
int CauerLowPassSC::getDimReal() const
{
  return(SystemDefaultImplementation::getDimReal());
}

// Provide number (dimension) of variables according to the index
int CauerLowPassSC::getDimString() const
{
  return(SystemDefaultImplementation::getDimString());
}

// Provide number (dimension) of right hand sides (equations and/or residuals) according to the index
int CauerLowPassSC::getDimRHS() const
{
  return(SystemDefaultImplementation::getDimRHS());
}

void CauerLowPassSC::getContinuousStates(double* z)
{
  SystemDefaultImplementation::getContinuousStates(z);
}
void CauerLowPassSC::getNominalStates(double* z)
{
   z[0] = 1.0;
   z[1] = 1.0;
   z[2] = 1.0;
   z[3] = 1.0;
   z[4] = 1.0;
   z[5] = 1.0;
   z[6] = 1.0;
   z[7] = 1.0;
   z[8] = 1.0;
   z[9] = 1.0;
   z[10] = 1.0;
   z[11] = 1.0;
   z[12] = 1.0;
   z[13] = 1.0;
   z[14] = 1.0;
   z[15] = 1.0;
}

// Set variables with given index to the system
void CauerLowPassSC::setContinuousStates(const double* z)
{
  SystemDefaultImplementation::setContinuousStates(z);
}

// Provide the right hand side (according to the index)
void CauerLowPassSC::getRHS(double* f)
{
  SystemDefaultImplementation::getRHS(f);
}

void CauerLowPassSC::setRHS(const double* f)
{
  SystemDefaultImplementation::setRHS(f);
}

bool CauerLowPassSC::isStepEvent()
{
 throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"isStepEvent is not yet implemented");

}

void CauerLowPassSC::setTerminal(bool terminal)
{
  _terminal=terminal;
}

bool CauerLowPassSC::terminal()
{
  return _terminal;
}

bool CauerLowPassSC::isAlgebraic()
{
  return false; // Indexreduction is enabled
}

bool CauerLowPassSC::provideSymbolicJacobian()
{
  throw ModelicaSimulationError(MODEL_EQ_SYSTEM,"provideSymbolicJacobian is not yet implemented");
}

void CauerLowPassSC::handleEvent(const bool* events)
{
}
bool CauerLowPassSC::checkForDiscreteEvents()
{
  if (_discrete_events->changeDiscreteVar(_$whenCondition11)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition10)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition9)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition8)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition7)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition6)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition5)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition4)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition3)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition2)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_$whenCondition1)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R4_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R4_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R5_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R5_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R8_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R8_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R9_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R9_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R1_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R1_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R2_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R2_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R3_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R3_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_Rp1_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_Rp1_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R7_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R7_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R10_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R10_P_BooleanPulse1_P_pulsStart)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R11_P_BooleanPulse1_P_y)) {  return true; }
  if (_discrete_events->changeDiscreteVar(_R11_P_BooleanPulse1_P_pulsStart)) {  return true; }
  return false;
}
void CauerLowPassSC::getZeroFunc(double* f)
{
  if(_conditions[0])
      f[0]=(_simTime - 1e-9 - _V_P_signalSource_P_startTime);
  else
      f[0]=(_V_P_signalSource_P_startTime - _simTime -  1e-9);
  if(_conditions[1])
      f[1] = (_R4_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[1] = (_simTime - 1e-9 - _R4_P_BooleanPulse1_P_pulsStart);
  if(_conditions[2])
      f[2]=(_simTime - 1e-9 - (_R4_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[2]=((_R4_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[3])
      f[3] = (_R5_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[3] = (_simTime - 1e-9 - _R5_P_BooleanPulse1_P_pulsStart);
  if(_conditions[4])
      f[4]=(_simTime - 1e-9 - (_R5_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[4]=((_R5_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[5])
      f[5] = (_R8_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[5] = (_simTime - 1e-9 - _R8_P_BooleanPulse1_P_pulsStart);
  if(_conditions[6])
      f[6]=(_simTime - 1e-9 - (_R8_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[6]=((_R8_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[7])
      f[7] = (_R9_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[7] = (_simTime - 1e-9 - _R9_P_BooleanPulse1_P_pulsStart);
  if(_conditions[8])
      f[8]=(_simTime - 1e-9 - (_R9_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[8]=((_R9_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[9])
      f[9] = (_R1_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[9] = (_simTime - 1e-9 - _R1_P_BooleanPulse1_P_pulsStart);
  if(_conditions[10])
      f[10]=(_simTime - 1e-9 - (_R1_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[10]=((_R1_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[11])
      f[11] = (_R2_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[11] = (_simTime - 1e-9 - _R2_P_BooleanPulse1_P_pulsStart);
  if(_conditions[12])
      f[12]=(_simTime - 1e-9 - (_R2_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[12]=((_R2_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[13])
      f[13] = (_R3_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[13] = (_simTime - 1e-9 - _R3_P_BooleanPulse1_P_pulsStart);
  if(_conditions[14])
      f[14]=(_simTime - 1e-9 - (_R3_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[14]=((_R3_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[15])
      f[15] = (_Rp1_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[15] = (_simTime - 1e-9 - _Rp1_P_BooleanPulse1_P_pulsStart);
  if(_conditions[16])
      f[16]=(_simTime - 1e-9 - (_Rp1_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[16]=((_Rp1_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[17])
      f[17] = (_R7_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[17] = (_simTime - 1e-9 - _R7_P_BooleanPulse1_P_pulsStart);
  if(_conditions[18])
      f[18]=(_simTime - 1e-9 - (_R7_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[18]=((_R7_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[19])
      f[19] = (_R10_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[19] = (_simTime - 1e-9 - _R10_P_BooleanPulse1_P_pulsStart);
  if(_conditions[20])
      f[20]=(_simTime - 1e-9 - (_R10_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[20]=((_R10_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  if(_conditions[21])
      f[21] = (_R11_P_BooleanPulse1_P_pulsStart - _simTime - 1e-9);
  else
      f[21] = (_simTime - 1e-9 - _R11_P_BooleanPulse1_P_pulsStart);
  if(_conditions[22])
      f[22]=(_simTime - 1e-9 - (_R11_P_BooleanPulse1_P_pulsStart + 0.05));
  else
      f[22]=((_R11_P_BooleanPulse1_P_pulsStart + 0.05) - _simTime -  1e-9);
  //sample for 23
  //sample for 24
  //sample for 25
  //sample for 26
  //sample for 27
  //sample for 28
  //sample for 29
  //sample for 30
  //sample for 31
  //sample for 32
  //sample for 33
}

void CauerLowPassSC::setConditions(bool* c)
{
  SystemDefaultImplementation::setConditions(c);
}
void CauerLowPassSC::getConditions(bool* c)
{
    SystemDefaultImplementation::getConditions(c);
}
bool CauerLowPassSC::isConsistent()
{
  return SystemDefaultImplementation::isConsistent();
}

bool CauerLowPassSC::stepCompleted(double time)
{
 _algLoopSolver222->stepCompleted(_simTime);
 _algLoopSolver228->stepCompleted(_simTime);
 _algLoopSolver234->stepCompleted(_simTime);
 _algLoopSolver240->stepCompleted(_simTime);
 _algLoopSolver246->stepCompleted(_simTime);
 _algLoopSolver252->stepCompleted(_simTime);
 _algLoopSolver260->stepCompleted(_simTime);
 _algLoopSolver266->stepCompleted(_simTime);
 _algLoopSolver275->stepCompleted(_simTime);
 _algLoopSolver281->stepCompleted(_simTime);
 _algLoopSolver289->stepCompleted(_simTime);
 _algLoopSolver290->stepCompleted(_simTime);
 _algLoopSolver124->stepCompleted(_simTime);
 _algLoopSolver131->stepCompleted(_simTime);
 _algLoopSolver138->stepCompleted(_simTime);
 _algLoopSolver145->stepCompleted(_simTime);
 _algLoopSolver152->stepCompleted(_simTime);
 _algLoopSolver159->stepCompleted(_simTime);
 _algLoopSolver166->stepCompleted(_simTime);
 _algLoopSolver167->stepCompleted(_simTime);
 _algLoopSolver174->stepCompleted(_simTime);
 _algLoopSolver181->stepCompleted(_simTime);
 _algLoopSolver192->stepCompleted(_simTime);
 _algLoopSolver200->stepCompleted(_simTime);

  storeTime(time);

#if defined(__TRICORE__) || defined(__vxworks)
#endif

saveAll();
return _terminate;
}

bool CauerLowPassSC::stepStarted(double time)
{
#if defined(__TRICORE__) || defined(__vxworks)
#endif

return true;
}

void CauerLowPassSC::handleTimeEvent(int* time_events)
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
int CauerLowPassSC::getDimTimeEvent() const
{
  return _dimTimeEvent;
}
void CauerLowPassSC::getTimeEvent(time_event_type& time_events)
{
  time_events.push_back(std::make_pair(_R4_P_BooleanPulse1_P_startTime, _R4_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R5_P_BooleanPulse1_P_startTime, _R5_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R8_P_BooleanPulse1_P_startTime, _R8_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R9_P_BooleanPulse1_P_startTime, _R9_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R1_P_BooleanPulse1_P_startTime, _R1_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R2_P_BooleanPulse1_P_startTime, _R2_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R3_P_BooleanPulse1_P_startTime, _R3_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_Rp1_P_BooleanPulse1_P_startTime, _Rp1_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R7_P_BooleanPulse1_P_startTime, _R7_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R10_P_BooleanPulse1_P_startTime, _R10_P_BooleanPulse1_P_period));
  
  time_events.push_back(std::make_pair(_R11_P_BooleanPulse1_P_startTime, _R11_P_BooleanPulse1_P_period));
}

bool CauerLowPassSC::isODE()
{
  return 16>0 ;
}
int CauerLowPassSC::getDimZeroFunc()
{
  return _dimZeroFunc;
}

bool CauerLowPassSC::getCondition(unsigned int index)
{
  bool tmp1;
  bool tmp2;
  bool tmp3;
  bool tmp4;
  bool tmp5;
  bool tmp6;
  bool tmp7;
  bool tmp8;
  bool tmp9;
  bool tmp10;
  bool tmp11;
  bool tmp12;
  bool tmp13;
  bool tmp14;
  bool tmp15;
  bool tmp16;
  bool tmp17;
  bool tmp18;
  bool tmp19;
  bool tmp20;
  bool tmp21;
  bool tmp22;
  bool tmp23;
  switch(index)
  {
    case 0:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp1=(_simTime<_V_P_signalSource_P_startTime);
           _conditions[0]=tmp1;
           return tmp1;
       }
       else
           return _conditions[0];
    }
    case 1:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp2=(_simTime>=_R4_P_BooleanPulse1_P_pulsStart);
           _conditions[1]=tmp2;
           return tmp2;
       }
       else
           return _conditions[1];
    }
    case 2:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp3=(_simTime<(_R4_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[2]=tmp3;
           return tmp3;
       }
       else
           return _conditions[2];
    }
    case 3:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp4=(_simTime>=_R5_P_BooleanPulse1_P_pulsStart);
           _conditions[3]=tmp4;
           return tmp4;
       }
       else
           return _conditions[3];
    }
    case 4:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp5=(_simTime<(_R5_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[4]=tmp5;
           return tmp5;
       }
       else
           return _conditions[4];
    }
    case 5:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp6=(_simTime>=_R8_P_BooleanPulse1_P_pulsStart);
           _conditions[5]=tmp6;
           return tmp6;
       }
       else
           return _conditions[5];
    }
    case 6:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp7=(_simTime<(_R8_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[6]=tmp7;
           return tmp7;
       }
       else
           return _conditions[6];
    }
    case 7:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp8=(_simTime>=_R9_P_BooleanPulse1_P_pulsStart);
           _conditions[7]=tmp8;
           return tmp8;
       }
       else
           return _conditions[7];
    }
    case 8:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp9=(_simTime<(_R9_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[8]=tmp9;
           return tmp9;
       }
       else
           return _conditions[8];
    }
    case 9:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp10=(_simTime>=_R1_P_BooleanPulse1_P_pulsStart);
           _conditions[9]=tmp10;
           return tmp10;
       }
       else
           return _conditions[9];
    }
    case 10:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp11=(_simTime<(_R1_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[10]=tmp11;
           return tmp11;
       }
       else
           return _conditions[10];
    }
    case 11:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp12=(_simTime>=_R2_P_BooleanPulse1_P_pulsStart);
           _conditions[11]=tmp12;
           return tmp12;
       }
       else
           return _conditions[11];
    }
    case 12:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp13=(_simTime<(_R2_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[12]=tmp13;
           return tmp13;
       }
       else
           return _conditions[12];
    }
    case 13:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp14=(_simTime>=_R3_P_BooleanPulse1_P_pulsStart);
           _conditions[13]=tmp14;
           return tmp14;
       }
       else
           return _conditions[13];
    }
    case 14:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp15=(_simTime<(_R3_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[14]=tmp15;
           return tmp15;
       }
       else
           return _conditions[14];
    }
    case 15:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp16=(_simTime>=_Rp1_P_BooleanPulse1_P_pulsStart);
           _conditions[15]=tmp16;
           return tmp16;
       }
       else
           return _conditions[15];
    }
    case 16:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp17=(_simTime<(_Rp1_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[16]=tmp17;
           return tmp17;
       }
       else
           return _conditions[16];
    }
    case 17:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp18=(_simTime>=_R7_P_BooleanPulse1_P_pulsStart);
           _conditions[17]=tmp18;
           return tmp18;
       }
       else
           return _conditions[17];
    }
    case 18:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp19=(_simTime<(_R7_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[18]=tmp19;
           return tmp19;
       }
       else
           return _conditions[18];
    }
    case 19:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp20=(_simTime>=_R10_P_BooleanPulse1_P_pulsStart);
           _conditions[19]=tmp20;
           return tmp20;
       }
       else
           return _conditions[19];
    }
    case 20:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp21=(_simTime<(_R10_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[20]=tmp21;
           return tmp21;
       }
       else
           return _conditions[20];
    }
    case 21:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp22=(_simTime>=_R11_P_BooleanPulse1_P_pulsStart);
           _conditions[21]=tmp22;
           return tmp22;
       }
       else
           return _conditions[21];
    }
    case 22:
    {
       if(_callType & IContinuous::DISCRETE)
       {
           tmp23=(_simTime<(_R11_P_BooleanPulse1_P_pulsStart + 0.05));
           _conditions[22]=tmp23;
           return tmp23;
       }
       else
           return _conditions[22];
    }
    
    
    
    
    
    
    
    
    
    
    
    default:
    {
      string error =string("Wrong condition index ") + boost::lexical_cast<string>(index);
     throw ModelicaSimulationError(EVENT_HANDLING,error);
    }
  };
}
bool CauerLowPassSC::handleSystemEvents(bool* events)
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
void CauerLowPassSC::saveAll()
{
     _sim_vars->savePreVariables();
}




void CauerLowPassSC::getReal(double* z)
{
  const double* real_vars = _sim_vars->getRealVarsVector();
  memcpy(z,real_vars,429);
}



void CauerLowPassSC::setReal(const double* z)
{
   _sim_vars->setRealVarsVector(z);
}



void CauerLowPassSC::getInteger(int* z)
{
  const int* int_vars = _sim_vars->getIntVarsVector();
  memcpy(z,int_vars,1);
}



void CauerLowPassSC::getBoolean(bool* z)
{
  const bool* bool_vars = _sim_vars->getBoolVarsVector();
  memcpy(z,bool_vars,45);
}



void CauerLowPassSC::getString(string* z)
{
}

void CauerLowPassSC::setInteger(const int* z)
{
   _sim_vars->setIntVarsVector(z);
}

void CauerLowPassSC::setBoolean(const bool* z)
{
  _sim_vars->setBoolVarsVector(z);
}

void CauerLowPassSC::setString(const string* z)
{
}

//AlgVars
void CauerLowPassSC::defineAlgVars_0()
{
}
void CauerLowPassSC::defineAlgVars_1()
{
}
void CauerLowPassSC::defineAlgVars_2()
{
}

void CauerLowPassSC::defineAlgVars()
{
    defineAlgVars_0();
    defineAlgVars_1();
    defineAlgVars_2();
}

//DiscreteAlgVars
void CauerLowPassSC::defineDiscreteAlgVars_0()
{
}

void CauerLowPassSC::defineDiscreteAlgVars()
{
    defineDiscreteAlgVars_0();
}

//IntAlgVars
void CauerLowPassSC::defineIntAlgVars()
{
}

//BoolAlgVars
void CauerLowPassSC::defineBoolAlgVars_0()
{
}
void CauerLowPassSC::defineBoolAlgVars()
{
    defineBoolAlgVars_0();
}

//ParameterRealVars
void CauerLowPassSC::defineParameterRealVars_0()
{
}
void CauerLowPassSC::defineParameterRealVars_1()
{
}
void CauerLowPassSC::defineParameterRealVars()
{
    defineParameterRealVars_0();
    defineParameterRealVars_1();
}

//ParameterIntVars
void CauerLowPassSC::defineParameterIntVars()
{
}

//ParameterBoolVars
void CauerLowPassSC::defineParameterBoolVars_0()
{
}
void CauerLowPassSC::defineParameterBoolVars()
{
    defineParameterBoolVars_0();
}

//AliasRealVars
void CauerLowPassSC::defineAliasRealVars_0()
{
}
void CauerLowPassSC::defineAliasRealVars_1()
{
}
void CauerLowPassSC::defineAliasRealVars_2()
{
}
void CauerLowPassSC::defineAliasRealVars()
{
    defineAliasRealVars_0();
    defineAliasRealVars_1();
    defineAliasRealVars_2();
}

//AliasIntVars
void CauerLowPassSC::defineAliasIntVars()
{
}

//AliasBoolVars
void CauerLowPassSC::defineAliasBoolVars_0()
{
}
void CauerLowPassSC::defineAliasBoolVars()
{
    defineAliasBoolVars_0();
}

//String parameter 0

void CauerLowPassSC::defineConstVals()
{
}
