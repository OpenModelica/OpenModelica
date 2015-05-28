#include "OMCppModelica.Electrical.Spice3.Examples.CoupledInductorsAlgloop53.h"

CoupledInductorsInitialize::CoupledInductorsInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
: CoupledInductors(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

CoupledInductorsInitialize::~CoupledInductorsInitialize()
{
}

bool CoupledInductorsInitialize::initial()
{
  return _initial;
}
void CoupledInductorsInitialize::setInitial(bool status)
{
  _initial = status;
  if(_initial)
    _callType = IContinuous::DISCRETE;
  else
    _callType = IContinuous::CONTINUOUS;
}

void CoupledInductorsInitialize::initialize()
{



   initializeMemory();

   initializeFreeVariables();
   initializeBoundVariables();
   saveAll();
}

void CoupledInductorsInitialize::initializeMemory()
{
   _discrete_events = _event_handling->initialize(this,_sim_vars);

   //create and initialize Algloopsolvers
   _algLoop53 =  boost::shared_ptr<IAlgLoop>(new CoupledInductorsAlgloop53(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver53 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop53.get()));
   
   //initialize Algloop variables
   initializeAlgloopSolverVariables();
   //init alg loop vars
                   if(_algloop53Vars)
       delete [] _algloop53Vars;
     if(_conditions053)
       delete [] _conditions053;
     if(_conditions153)
       delete [] _conditions153;
     unsigned int dim53 = _algLoop53->getDimReal();
     _algloop53Vars = new double[dim53];
     _conditions053 = new bool[_dimZeroFunc];
     _conditions153 = new bool[_dimZeroFunc];                                                

}

void CoupledInductorsInitialize::initializeFreeVariables()
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

void CoupledInductorsInitialize::initializeBoundVariables()
{
   //variable decls
   
   //bound start values
   
   //init event handling
   bool events[1];
   memset(events,true,1);
   for(int i=0;i<=1;++i) { handleEvent(events); }
   
   //init equations
   initEquations();
   
   //init alg loop solvers
   if(_algLoopSolver53)
       _algLoopSolver53->initialize();
   
   for(int i=0;i<_dimZeroFunc;i++)
   {
      getCondition(i);
   }
   
   //initialAnalyticJacobian();
   
    
}

void CoupledInductorsInitialize::initEquations()
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
   initEquation_15();
   initEquation_16();
   initEquation_17();
   initEquation_18();
   initEquation_19();
   initEquation_20();
   initEquation_21();
   initEquation_22();
   initEquation_23();
   initEquation_24();
   initEquation_25();
   initEquation_26();
   initEquation_27();
   initEquation_28();
   initEquation_29();
   initEquation_30();
   initEquation_31();
   initEquation_32();
   initEquation_33();
   initEquation_34();
   initEquation_35();
   initEquation_36();
   initEquation_37();
   initEquation_38();
}
/*
equation index: 1
type: SIMPLE_ASSIGN
k1._M = k1.k * sqrt(L1.L * L2.L)
*/
void CoupledInductorsInitialize::initEquation_1()
{
  double tmp4;
  tmp4 = sqrt((_L1_P_L * _L2_P_L));
  _k1_P_M = (_k1_P_k * tmp4);
}
/*
equation index: 2
type: SIMPLE_ASSIGN
k2._M = k2.k * sqrt(L1.L * L3.L)
*/
void CoupledInductorsInitialize::initEquation_2()
{
  double tmp5;
  tmp5 = sqrt((_L1_P_L * _L3_P_L));
  _k2_P_M = (_k2_P_k * tmp5);
}
/*
equation index: 3
type: SIMPLE_ASSIGN
k3._M = k3.k * sqrt(L3.L * L2.L)
*/
void CoupledInductorsInitialize::initEquation_3()
{
  double tmp6;
  tmp6 = sqrt((_L3_P_L * _L2_P_L));
  _k3_P_M = (_k3_P_k * tmp6);
}
/*
equation index: 4
type: SIMPLE_ASSIGN
sineVoltage._v = sineVoltage.VO + (if time < sineVoltage.TD then 0.0 else sineVoltage.VA * exp((sineVoltage.TD - time) * sineVoltage.THETA) * sin(6.283185307179586 * sineVoltage.FREQ * (time - sineVoltage.TD)))
*/
void CoupledInductorsInitialize::initEquation_4()
{
  double tmp7;
  double tmp8;
  double tmp9;
  if (getCondition(0)) {
    tmp9 = 0.0;
  } else {
    tmp7 = exp(((_sineVoltage_P_TD - _simTime) * _sineVoltage_P_THETA));
    tmp8 = sin((6.283185307179586 * (_sineVoltage_P_FREQ * (_simTime - _sineVoltage_P_TD))));
    tmp9 = (_sineVoltage_P_VA * (tmp7 * tmp8));
  }
  _sineVoltage_P_v = (_sineVoltage_P_VO + tmp9);
}
/*
equation index: 5
type: SIMPLE_ASSIGN
C2._vinternal = C2.IC
*/
void CoupledInductorsInitialize::initEquation_5()
{
    __z[1]   = _C2_P_IC;
}
/*
equation index: 6
type: SIMPLE_ASSIGN
R5._i = DIVISION(C2.vinternal, R5.R)
*/
void CoupledInductorsInitialize::initEquation_6()
{
  _R5_P_i = division(__z[1],_R5_P_R,"R5.R");
}
/*
equation index: 7
type: SIMPLE_ASSIGN
der(L3._iinternal) = 0.0
*/
void CoupledInductorsInitialize::initEquation_7()
{
   __zDot[4]  = 0.0;
}
/*
equation index: 8
type: SIMPLE_ASSIGN
L3._ICP._di = $DER.L3.iinternal
*/
void CoupledInductorsInitialize::initEquation_8()
{
  _L3_P_ICP_P_di = __zDot[4];
}
/*
equation index: 9
type: SIMPLE_ASSIGN
k3._inductiveCouplePin2._v = (-k3.M) * L3.ICP.di
*/
void CoupledInductorsInitialize::initEquation_9()
{
  _k3_P_inductiveCouplePin2_P_v = ((-_k3_P_M) * _L3_P_ICP_P_di);
}
/*
equation index: 10
type: SIMPLE_ASSIGN
k2._inductiveCouplePin1._v = (-k2.M) * L3.ICP.di
*/
void CoupledInductorsInitialize::initEquation_10()
{
  _k2_P_inductiveCouplePin1_P_v = ((-_k2_P_M) * _L3_P_ICP_P_di);
}
/*
equation index: 11
type: SIMPLE_ASSIGN
C1._vinternal = C1.IC
*/
void CoupledInductorsInitialize::initEquation_11()
{
    __z[0]   = _C1_P_IC;
}
/*
equation index: 12
type: SIMPLE_ASSIGN
R3._i = DIVISION(C1.vinternal, R3.R)
*/
void CoupledInductorsInitialize::initEquation_12()
{
  _R3_P_i = division(__z[0],_R3_P_R,"R3.R");
}
/*
equation index: 13
type: SIMPLE_ASSIGN
der(L2._iinternal) = 0.0
*/
void CoupledInductorsInitialize::initEquation_13()
{
   __zDot[3]  = 0.0;
}
/*
equation index: 14
type: SIMPLE_ASSIGN
L2._ICP._di = $DER.L2.iinternal
*/
void CoupledInductorsInitialize::initEquation_14()
{
  _L2_P_ICP_P_di = __zDot[3];
}
/*
equation index: 15
type: SIMPLE_ASSIGN
k3._inductiveCouplePin1._v = (-k3.M) * L2.ICP.di
*/
void CoupledInductorsInitialize::initEquation_15()
{
  _k3_P_inductiveCouplePin1_P_v = ((-_k3_P_M) * _L2_P_ICP_P_di);
}
/*
equation index: 16
type: SIMPLE_ASSIGN
k1._inductiveCouplePin1._v = (-k1.M) * L2.ICP.di
*/
void CoupledInductorsInitialize::initEquation_16()
{
  _k1_P_inductiveCouplePin1_P_v = ((-_k1_P_M) * _L2_P_ICP_P_di);
}
/*
equation index: 17
type: SIMPLE_ASSIGN
L1._ICP._v = (-k2.inductiveCouplePin1.v) - k1.inductiveCouplePin1.v
*/
void CoupledInductorsInitialize::initEquation_17()
{
  _L1_P_ICP_P_v = ((-_k2_P_inductiveCouplePin1_P_v) - _k1_P_inductiveCouplePin1_P_v);
}
/*
equation index: 18
type: SIMPLE_ASSIGN
der(L1._iinternal) = 0.0
*/
void CoupledInductorsInitialize::initEquation_18()
{
   __zDot[2]  = 0.0;
}
/*
equation index: 19
type: SIMPLE_ASSIGN
L1._ICP._di = $DER.L1.iinternal
*/
void CoupledInductorsInitialize::initEquation_19()
{
  _L1_P_ICP_P_di = __zDot[2];
}
/*
equation index: 20
type: SIMPLE_ASSIGN
k2._inductiveCouplePin2._v = (-k2.M) * L1.ICP.di
*/
void CoupledInductorsInitialize::initEquation_20()
{
  _k2_P_inductiveCouplePin2_P_v = ((-_k2_P_M) * _L1_P_ICP_P_di);
}
/*
equation index: 21
type: SIMPLE_ASSIGN
L3._ICP._v = (-k2.inductiveCouplePin2.v) - k3.inductiveCouplePin1.v
*/
void CoupledInductorsInitialize::initEquation_21()
{
  _L3_P_ICP_P_v = ((-_k2_P_inductiveCouplePin2_P_v) - _k3_P_inductiveCouplePin1_P_v);
}
/*
equation index: 22
type: SIMPLE_ASSIGN
L3._v = L3.L * L3.ICP.di - L3.ICP.v
*/
void CoupledInductorsInitialize::initEquation_22()
{
  _L3_P_v = ((_L3_P_L * _L3_P_ICP_P_di) - _L3_P_ICP_P_v);
}
/*
equation index: 23
type: SIMPLE_ASSIGN
R4._v = C2.vinternal - L3.v
*/
void CoupledInductorsInitialize::initEquation_23()
{
  _R4_P_v = (__z[1] - _L3_P_v);
}
/*
equation index: 24
type: SIMPLE_ASSIGN
L3._iinternal = DIVISION(R4.v, R4.R)
*/
void CoupledInductorsInitialize::initEquation_24()
{
    __z[4]   = division(_R4_P_v,_R4_P_R,"R4.R");
}
/*
equation index: 25
type: SIMPLE_ASSIGN
C2._i = (-L3.iinternal) - R5.i
*/
void CoupledInductorsInitialize::initEquation_25()
{
  _C2_P_i = ((-__z[4]) - _R5_P_i);
}
/*
equation index: 26
type: SIMPLE_ASSIGN
der(C2._vinternal) = DIVISION(C2.i, C2.C)
*/
void CoupledInductorsInitialize::initEquation_26()
{
   __zDot[1]  = division(_C2_P_i,_C2_P_C,"C2.C");
}
/*
equation index: 27
type: SIMPLE_ASSIGN
k1._inductiveCouplePin2._v = (-k1.M) * L1.ICP.di
*/
void CoupledInductorsInitialize::initEquation_27()
{
  _k1_P_inductiveCouplePin2_P_v = ((-_k1_P_M) * _L1_P_ICP_P_di);
}
/*
equation index: 28
type: SIMPLE_ASSIGN
L2._ICP._v = (-k1.inductiveCouplePin2.v) - k3.inductiveCouplePin2.v
*/
void CoupledInductorsInitialize::initEquation_28()
{
  _L2_P_ICP_P_v = ((-_k1_P_inductiveCouplePin2_P_v) - _k3_P_inductiveCouplePin2_P_v);
}
/*
equation index: 29
type: SIMPLE_ASSIGN
L2._v = L2.L * L2.ICP.di - L2.ICP.v
*/
void CoupledInductorsInitialize::initEquation_29()
{
  _L2_P_v = ((_L2_P_L * _L2_P_ICP_P_di) - _L2_P_ICP_P_v);
}
/*
equation index: 30
type: SIMPLE_ASSIGN
R2._v = C1.vinternal - L2.v
*/
void CoupledInductorsInitialize::initEquation_30()
{
  _R2_P_v = (__z[0] - _L2_P_v);
}
/*
equation index: 31
type: SIMPLE_ASSIGN
L2._iinternal = DIVISION(R2.v, R2.R)
*/
void CoupledInductorsInitialize::initEquation_31()
{
    __z[3]   = division(_R2_P_v,_R2_P_R,"R2.R");
}
/*
equation index: 32
type: SIMPLE_ASSIGN
C1._i = (-L2.iinternal) - R3.i
*/
void CoupledInductorsInitialize::initEquation_32()
{
  _C1_P_i = ((-__z[3]) - _R3_P_i);
}
/*
equation index: 33
type: SIMPLE_ASSIGN
der(C1._vinternal) = DIVISION(C1.i, C1.C)
*/
void CoupledInductorsInitialize::initEquation_33()
{
   __zDot[0]  = division(_C1_P_i,_C1_P_C,"C1.C");
}
/*
equation index: 34
type: SIMPLE_ASSIGN
ground._p._i = R3.i - ((-R5.i) - C2.i - L2.iinternal - L3.iinternal - C1.i)
*/
void CoupledInductorsInitialize::initEquation_34()
{
  _ground_P_p_P_i = (_R3_P_i - (((((-_R5_P_i) - _C2_P_i) - __z[3]) - __z[4]) - _C1_P_i));
}
/*
equation index: 35
type: SIMPLE_ASSIGN
L1._v = L1.L * L1.ICP.di - L1.ICP.v
*/
void CoupledInductorsInitialize::initEquation_35()
{
  _L1_P_v = ((_L1_P_L * _L1_P_ICP_P_di) - _L1_P_ICP_P_v);
}
/*
equation index: 36
type: SIMPLE_ASSIGN
R1._v = sineVoltage.v - L1.v
*/
void CoupledInductorsInitialize::initEquation_36()
{
  _R1_P_v = (_sineVoltage_P_v - _L1_P_v);
}
/*
equation index: 37
type: SIMPLE_ASSIGN
L1._iinternal = DIVISION(R1.v, R1.R)
*/
void CoupledInductorsInitialize::initEquation_37()
{
    __z[2]   = division(_R1_P_v,_R1_P_R,"R1.R");
}
/*
equation index: 38
type: SIMPLE_ASSIGN
ground._p._v = 0.0
*/
void CoupledInductorsInitialize::initEquation_38()
{
  _ground_P_p_P_v = 0.0;
}
void CoupledInductorsInitialize::initializeStateVars()
{

             setRealStartValue(  __z[0]  ,0.0);

             setRealStartValue(  __z[1]  ,0.0);

             setRealStartValue(  __z[2]  ,0.0);

             setRealStartValue(  __z[3]  ,0.0);

             setRealStartValue(  __z[4]  ,0.0);
}
void CoupledInductorsInitialize::initializeDerVars()
{

             setRealStartValue( __zDot[0] ,0.0);

             setRealStartValue( __zDot[1] ,0.0);

             setRealStartValue( __zDot[2] ,0.0);

             setRealStartValue( __zDot[3] ,0.0);

             setRealStartValue( __zDot[4] ,0.0);
}