/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCInitialize.h" */
#include <Core/System/EventHandling.h>
#include <Core/System/DiscreteEvents.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop222.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop228.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop234.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop240.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop246.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop252.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop260.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop266.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop275.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop281.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop289.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop290.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop124.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop131.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop138.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop145.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop152.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop159.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop166.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop167.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop174.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop181.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop192.h"

#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCAlgloop200.h"

CauerLowPassSCInitialize::CauerLowPassSCInitialize(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
: CauerLowPassSC(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
}

CauerLowPassSCInitialize::~CauerLowPassSCInitialize()
{
}

bool CauerLowPassSCInitialize::initial()
{
  return _initial;
}
void CauerLowPassSCInitialize::setInitial(bool status)
{
  _initial = status;
  if(_initial)
    _callType = IContinuous::DISCRETE;
  else
    _callType = IContinuous::CONTINUOUS;
}

void CauerLowPassSCInitialize::initialize()
{



   initializeMemory();

   initializeFreeVariables();
   initializeBoundVariables();
   saveAll();
}

void CauerLowPassSCInitialize::initializeMemory()
{
   _discrete_events = _event_handling->initialize(this,_sim_vars);

   //create and initialize Algloopsolvers
   _algLoop222 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop222(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver222 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop222.get()));
   _algLoop228 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop228(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver228 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop228.get()));
   _algLoop234 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop234(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver234 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop234.get()));
   _algLoop240 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop240(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver240 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop240.get()));
   _algLoop246 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop246(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver246 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop246.get()));
   _algLoop252 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop252(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver252 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop252.get()));
   _algLoop260 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop260(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver260 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop260.get()));
   _algLoop266 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop266(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver266 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop266.get()));
   _algLoop275 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop275(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver275 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop275.get()));
   _algLoop281 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop281(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver281 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop281.get()));
   _algLoop289 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop289(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver289 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop289.get()));
   _algLoop290 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop290(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver290 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop290.get()));
   _algLoop124 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop124(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver124 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop124.get()));
   _algLoop131 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop131(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver131 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop131.get()));
   _algLoop138 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop138(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver138 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop138.get()));
   _algLoop145 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop145(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver145 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop145.get()));
   _algLoop152 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop152(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver152 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop152.get()));
   _algLoop159 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop159(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver159 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop159.get()));
   _algLoop166 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop166(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver166 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop166.get()));
   _algLoop167 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop167(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver167 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop167.get()));
   _algLoop174 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop174(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver174 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop174.get()));
   _algLoop181 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop181(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver181 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop181.get()));
   _algLoop192 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop192(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver192 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop192.get()));
   _algLoop200 =  boost::shared_ptr<IAlgLoop>(new CauerLowPassSCAlgloop200(this,__z,__zDot,_conditions,_discrete_events));
   _algLoopSolver200 = boost::shared_ptr<IAlgLoopSolver>(_algLoopSolverFactory->createAlgLoopSolver(_algLoop200.get()));
   
   //initialize Algloop variables
   initializeAlgloopSolverVariables();
   //init alg loop vars
                  if(_algloop222Vars)
       delete [] _algloop222Vars;
     if(_conditions0222)
       delete [] _conditions0222;
     if(_conditions1222)
       delete [] _conditions1222;
     unsigned int dim222 = _algLoop222->getDimReal();
     _algloop222Vars = new double[dim222];
     _conditions0222 = new bool[_dimZeroFunc];
     _conditions1222 = new bool[_dimZeroFunc];       if(_algloop228Vars)
       delete [] _algloop228Vars;
     if(_conditions0228)
       delete [] _conditions0228;
     if(_conditions1228)
       delete [] _conditions1228;
     unsigned int dim228 = _algLoop228->getDimReal();
     _algloop228Vars = new double[dim228];
     _conditions0228 = new bool[_dimZeroFunc];
     _conditions1228 = new bool[_dimZeroFunc];       if(_algloop234Vars)
       delete [] _algloop234Vars;
     if(_conditions0234)
       delete [] _conditions0234;
     if(_conditions1234)
       delete [] _conditions1234;
     unsigned int dim234 = _algLoop234->getDimReal();
     _algloop234Vars = new double[dim234];
     _conditions0234 = new bool[_dimZeroFunc];
     _conditions1234 = new bool[_dimZeroFunc];       if(_algloop240Vars)
       delete [] _algloop240Vars;
     if(_conditions0240)
       delete [] _conditions0240;
     if(_conditions1240)
       delete [] _conditions1240;
     unsigned int dim240 = _algLoop240->getDimReal();
     _algloop240Vars = new double[dim240];
     _conditions0240 = new bool[_dimZeroFunc];
     _conditions1240 = new bool[_dimZeroFunc];       if(_algloop246Vars)
       delete [] _algloop246Vars;
     if(_conditions0246)
       delete [] _conditions0246;
     if(_conditions1246)
       delete [] _conditions1246;
     unsigned int dim246 = _algLoop246->getDimReal();
     _algloop246Vars = new double[dim246];
     _conditions0246 = new bool[_dimZeroFunc];
     _conditions1246 = new bool[_dimZeroFunc];       if(_algloop252Vars)
       delete [] _algloop252Vars;
     if(_conditions0252)
       delete [] _conditions0252;
     if(_conditions1252)
       delete [] _conditions1252;
     unsigned int dim252 = _algLoop252->getDimReal();
     _algloop252Vars = new double[dim252];
     _conditions0252 = new bool[_dimZeroFunc];
     _conditions1252 = new bool[_dimZeroFunc];         if(_algloop260Vars)
       delete [] _algloop260Vars;
     if(_conditions0260)
       delete [] _conditions0260;
     if(_conditions1260)
       delete [] _conditions1260;
     unsigned int dim260 = _algLoop260->getDimReal();
     _algloop260Vars = new double[dim260];
     _conditions0260 = new bool[_dimZeroFunc];
     _conditions1260 = new bool[_dimZeroFunc];       if(_algloop266Vars)
       delete [] _algloop266Vars;
     if(_conditions0266)
       delete [] _conditions0266;
     if(_conditions1266)
       delete [] _conditions1266;
     unsigned int dim266 = _algLoop266->getDimReal();
     _algloop266Vars = new double[dim266];
     _conditions0266 = new bool[_dimZeroFunc];
     _conditions1266 = new bool[_dimZeroFunc];          if(_algloop275Vars)
       delete [] _algloop275Vars;
     if(_conditions0275)
       delete [] _conditions0275;
     if(_conditions1275)
       delete [] _conditions1275;
     unsigned int dim275 = _algLoop275->getDimReal();
     _algloop275Vars = new double[dim275];
     _conditions0275 = new bool[_dimZeroFunc];
     _conditions1275 = new bool[_dimZeroFunc];       if(_algloop281Vars)
       delete [] _algloop281Vars;
     if(_conditions0281)
       delete [] _conditions0281;
     if(_conditions1281)
       delete [] _conditions1281;
     unsigned int dim281 = _algLoop281->getDimReal();
     _algloop281Vars = new double[dim281];
     _conditions0281 = new bool[_dimZeroFunc];
     _conditions1281 = new bool[_dimZeroFunc];         if(_algloop289Vars)
       delete [] _algloop289Vars;
     if(_conditions0289)
       delete [] _conditions0289;
     if(_conditions1289)
       delete [] _conditions1289;
     unsigned int dim289 = _algLoop289->getDimReal();
     _algloop289Vars = new double[dim289];
     _conditions0289 = new bool[_dimZeroFunc];
     _conditions1289 = new bool[_dimZeroFunc];  if(_algloop290Vars)
       delete [] _algloop290Vars;
     if(_conditions0290)
       delete [] _conditions0290;
     if(_conditions1290)
       delete [] _conditions1290;
     unsigned int dim290 = _algLoop290->getDimReal();
     _algloop290Vars = new double[dim290];
     _conditions0290 = new bool[_dimZeroFunc];
     _conditions1290 = new bool[_dimZeroFunc];                                                                                                                                   if(_algloop124Vars)
       delete [] _algloop124Vars;
     if(_conditions0124)
       delete [] _conditions0124;
     if(_conditions1124)
       delete [] _conditions1124;
     unsigned int dim124 = _algLoop124->getDimReal();
     _algloop124Vars = new double[dim124];
     _conditions0124 = new bool[_dimZeroFunc];
     _conditions1124 = new bool[_dimZeroFunc];        if(_algloop131Vars)
       delete [] _algloop131Vars;
     if(_conditions0131)
       delete [] _conditions0131;
     if(_conditions1131)
       delete [] _conditions1131;
     unsigned int dim131 = _algLoop131->getDimReal();
     _algloop131Vars = new double[dim131];
     _conditions0131 = new bool[_dimZeroFunc];
     _conditions1131 = new bool[_dimZeroFunc];        if(_algloop138Vars)
       delete [] _algloop138Vars;
     if(_conditions0138)
       delete [] _conditions0138;
     if(_conditions1138)
       delete [] _conditions1138;
     unsigned int dim138 = _algLoop138->getDimReal();
     _algloop138Vars = new double[dim138];
     _conditions0138 = new bool[_dimZeroFunc];
     _conditions1138 = new bool[_dimZeroFunc];        if(_algloop145Vars)
       delete [] _algloop145Vars;
     if(_conditions0145)
       delete [] _conditions0145;
     if(_conditions1145)
       delete [] _conditions1145;
     unsigned int dim145 = _algLoop145->getDimReal();
     _algloop145Vars = new double[dim145];
     _conditions0145 = new bool[_dimZeroFunc];
     _conditions1145 = new bool[_dimZeroFunc];        if(_algloop152Vars)
       delete [] _algloop152Vars;
     if(_conditions0152)
       delete [] _conditions0152;
     if(_conditions1152)
       delete [] _conditions1152;
     unsigned int dim152 = _algLoop152->getDimReal();
     _algloop152Vars = new double[dim152];
     _conditions0152 = new bool[_dimZeroFunc];
     _conditions1152 = new bool[_dimZeroFunc];        if(_algloop159Vars)
       delete [] _algloop159Vars;
     if(_conditions0159)
       delete [] _conditions0159;
     if(_conditions1159)
       delete [] _conditions1159;
     unsigned int dim159 = _algLoop159->getDimReal();
     _algloop159Vars = new double[dim159];
     _conditions0159 = new bool[_dimZeroFunc];
     _conditions1159 = new bool[_dimZeroFunc];        if(_algloop166Vars)
       delete [] _algloop166Vars;
     if(_conditions0166)
       delete [] _conditions0166;
     if(_conditions1166)
       delete [] _conditions1166;
     unsigned int dim166 = _algLoop166->getDimReal();
     _algloop166Vars = new double[dim166];
     _conditions0166 = new bool[_dimZeroFunc];
     _conditions1166 = new bool[_dimZeroFunc];  if(_algloop167Vars)
       delete [] _algloop167Vars;
     if(_conditions0167)
       delete [] _conditions0167;
     if(_conditions1167)
       delete [] _conditions1167;
     unsigned int dim167 = _algLoop167->getDimReal();
     _algloop167Vars = new double[dim167];
     _conditions0167 = new bool[_dimZeroFunc];
     _conditions1167 = new bool[_dimZeroFunc];        if(_algloop174Vars)
       delete [] _algloop174Vars;
     if(_conditions0174)
       delete [] _conditions0174;
     if(_conditions1174)
       delete [] _conditions1174;
     unsigned int dim174 = _algLoop174->getDimReal();
     _algloop174Vars = new double[dim174];
     _conditions0174 = new bool[_dimZeroFunc];
     _conditions1174 = new bool[_dimZeroFunc];        if(_algloop181Vars)
       delete [] _algloop181Vars;
     if(_conditions0181)
       delete [] _conditions0181;
     if(_conditions1181)
       delete [] _conditions1181;
     unsigned int dim181 = _algLoop181->getDimReal();
     _algloop181Vars = new double[dim181];
     _conditions0181 = new bool[_dimZeroFunc];
     _conditions1181 = new bool[_dimZeroFunc];            if(_algloop192Vars)
       delete [] _algloop192Vars;
     if(_conditions0192)
       delete [] _conditions0192;
     if(_conditions1192)
       delete [] _conditions1192;
     unsigned int dim192 = _algLoop192->getDimReal();
     _algloop192Vars = new double[dim192];
     _conditions0192 = new bool[_dimZeroFunc];
     _conditions1192 = new bool[_dimZeroFunc];         if(_algloop200Vars)
       delete [] _algloop200Vars;
     if(_conditions0200)
       delete [] _conditions0200;
     if(_conditions1200)
       delete [] _conditions1200;
     unsigned int dim200 = _algLoop200->getDimReal();
     _algloop200Vars = new double[dim200];
     _conditions0200 = new bool[_dimZeroFunc];
     _conditions1200 = new bool[_dimZeroFunc];        

}

void CauerLowPassSCInitialize::initializeFreeVariables()
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

void CauerLowPassSCInitialize::initializeBoundVariables()
{
   //variable decls
   
   //bound start values
   
   //init event handling
   bool events[12];
   memset(events,true,12);
   for(int i=0;i<=12;++i) { handleEvent(events); }
   
   //init equations
   initEquations();
   
   //init alg loop solvers
   if(_algLoopSolver222)
       _algLoopSolver222->initialize();if(_algLoopSolver228)
       _algLoopSolver228->initialize();if(_algLoopSolver234)
       _algLoopSolver234->initialize();if(_algLoopSolver240)
       _algLoopSolver240->initialize();if(_algLoopSolver246)
       _algLoopSolver246->initialize();if(_algLoopSolver252)
       _algLoopSolver252->initialize();if(_algLoopSolver260)
       _algLoopSolver260->initialize();if(_algLoopSolver266)
       _algLoopSolver266->initialize();if(_algLoopSolver275)
       _algLoopSolver275->initialize();if(_algLoopSolver281)
       _algLoopSolver281->initialize();if(_algLoopSolver289)
       _algLoopSolver289->initialize();if(_algLoopSolver290)
       _algLoopSolver290->initialize();if(_algLoopSolver124)
       _algLoopSolver124->initialize();if(_algLoopSolver131)
       _algLoopSolver131->initialize();if(_algLoopSolver138)
       _algLoopSolver138->initialize();if(_algLoopSolver145)
       _algLoopSolver145->initialize();if(_algLoopSolver152)
       _algLoopSolver152->initialize();if(_algLoopSolver159)
       _algLoopSolver159->initialize();if(_algLoopSolver166)
       _algLoopSolver166->initialize();if(_algLoopSolver167)
       _algLoopSolver167->initialize();if(_algLoopSolver174)
       _algLoopSolver174->initialize();if(_algLoopSolver181)
       _algLoopSolver181->initialize();if(_algLoopSolver192)
       _algLoopSolver192->initialize();if(_algLoopSolver200)
       _algLoopSolver200->initialize();
   
   for(int i=0;i<_dimZeroFunc;i++)
   {
      getCondition(i);
   }
   
   //initialAnalyticJacobian();
   
    
}

void CauerLowPassSCInitialize::initEquations()
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
   initEquation_39();
   initEquation_40();
   initEquation_41();
   initEquation_42();
   initEquation_43();
   initEquation_44();
   initEquation_45();
   initEquation_46();
   initEquation_47();
   initEquation_48();
   initEquation_49();
   initEquation_50();
   initEquation_51();
   initEquation_52();
   initEquation_53();
   initEquation_54();
   initEquation_55();
   initEquation_56();
   initEquation_57();
   initEquation_58();
   initEquation_59();
   initEquation_60();
   initEquation_61();
   initEquation_62();
   initEquation_63();
   initEquation_64();
   initEquation_65();
   initEquation_66();
   initEquation_67();
   initEquation_68();
   initEquation_69();
   initEquation_70();
   initEquation_71();
   initEquation_72();
   initEquation_73();
   initEquation_74();
   initEquation_75();
   initEquation_76();
   initEquation_77();
   initEquation_78();
   initEquation_79();
   initEquation_80();
   initEquation_81();
   initEquation_82();
   initEquation_83();
   initEquation_84();
   initEquation_85();
   initEquation_86();
   initEquation_87();
   initEquation_88();
   initEquation_89();
   initEquation_90();
   initEquation_91();
   initEquation_92();
   initEquation_93();
   initEquation_94();
   initEquation_95();
   initEquation_96();
   initEquation_97();
   initEquation_98();
   initEquation_99();
   initEquation_100();
   initEquation_101();
   initEquation_102();
   initEquation_103();
   initEquation_104();
   initEquation_105();
   initEquation_106();
   initEquation_107();
   initEquation_108();
   initEquation_109();
   initEquation_110();
   initEquation_111();
   initEquation_112();
   initEquation_113();
   initEquation_114();
   initEquation_115();
   initEquation_116();
   initEquation_117();
   initEquation_118();
   initEquation_119();
   initEquation_120();
   initEquation_121();
   initEquation_122();
   initEquation_123();
   initEquation_124();
   initEquation_125();
   initEquation_126();
   initEquation_127();
   initEquation_128();
   initEquation_129();
   initEquation_130();
   initEquation_131();
   initEquation_132();
   initEquation_133();
   initEquation_134();
   initEquation_135();
   initEquation_136();
   initEquation_137();
   initEquation_138();
   initEquation_139();
   initEquation_140();
   initEquation_141();
   initEquation_142();
   initEquation_143();
   initEquation_144();
   initEquation_145();
   initEquation_146();
   initEquation_147();
   initEquation_148();
   initEquation_149();
   initEquation_150();
   initEquation_151();
   initEquation_152();
   initEquation_153();
   initEquation_154();
   initEquation_155();
   initEquation_156();
   initEquation_157();
   initEquation_158();
   initEquation_159();
   initEquation_160();
   initEquation_161();
   initEquation_162();
   initEquation_163();
   initEquation_164();
   initEquation_165();
   initEquation_166();
   initEquation_167();
   initEquation_168();
   initEquation_169();
   initEquation_170();
   initEquation_171();
   initEquation_172();
   initEquation_173();
   initEquation_174();
   initEquation_175();
   initEquation_176();
   initEquation_177();
   initEquation_178();
   initEquation_179();
   initEquation_180();
   initEquation_181();
   initEquation_182();
   initEquation_183();
   initEquation_184();
   initEquation_185();
   initEquation_186();
   initEquation_187();
   initEquation_188();
   initEquation_189();
   initEquation_190();
   initEquation_191();
   initEquation_192();
   initEquation_193();
   initEquation_194();
   initEquation_195();
   initEquation_196();
   initEquation_197();
   initEquation_198();
   initEquation_199();
   initEquation_200();
   initEquation_201();
   initEquation_202();
   initEquation_203();
   initEquation_204();
   initEquation_205();
   initEquation_206();
   initEquation_207();
   initEquation_208();
}
/*
equation index: 1
type: SIMPLE_ASSIGN
$whenCondition11 = false
*/
void CauerLowPassSCInitialize::initEquation_1()
{
  _$whenCondition11 = false;
}
/*
equation index: 2
type: SIMPLE_ASSIGN
$whenCondition10 = false
*/
void CauerLowPassSCInitialize::initEquation_2()
{
  _$whenCondition10 = false;
}
/*
equation index: 3
type: SIMPLE_ASSIGN
$whenCondition9 = false
*/
void CauerLowPassSCInitialize::initEquation_3()
{
  _$whenCondition9 = false;
}
/*
equation index: 4
type: SIMPLE_ASSIGN
$whenCondition8 = false
*/
void CauerLowPassSCInitialize::initEquation_4()
{
  _$whenCondition8 = false;
}
/*
equation index: 5
type: SIMPLE_ASSIGN
$whenCondition7 = false
*/
void CauerLowPassSCInitialize::initEquation_5()
{
  _$whenCondition7 = false;
}
/*
equation index: 6
type: SIMPLE_ASSIGN
$whenCondition6 = false
*/
void CauerLowPassSCInitialize::initEquation_6()
{
  _$whenCondition6 = false;
}
/*
equation index: 7
type: SIMPLE_ASSIGN
$whenCondition5 = false
*/
void CauerLowPassSCInitialize::initEquation_7()
{
  _$whenCondition5 = false;
}
/*
equation index: 8
type: SIMPLE_ASSIGN
$whenCondition4 = false
*/
void CauerLowPassSCInitialize::initEquation_8()
{
  _$whenCondition4 = false;
}
/*
equation index: 9
type: SIMPLE_ASSIGN
$whenCondition3 = false
*/
void CauerLowPassSCInitialize::initEquation_9()
{
  _$whenCondition3 = false;
}
/*
equation index: 10
type: SIMPLE_ASSIGN
$whenCondition2 = false
*/
void CauerLowPassSCInitialize::initEquation_10()
{
  _$whenCondition2 = false;
}
/*
equation index: 11
type: SIMPLE_ASSIGN
$whenCondition1 = false
*/
void CauerLowPassSCInitialize::initEquation_11()
{
  _$whenCondition1 = false;
}
/*
equation index: 12
type: SIMPLE_ASSIGN
Op1._in_p._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_12()
{
  _Op1_P_in_p_P_i = 0.0;
}
/*
equation index: 13
type: SIMPLE_ASSIGN
Op2._in_p._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_13()
{
  _Op2_P_in_p_P_i = 0.0;
}
/*
equation index: 14
type: SIMPLE_ASSIGN
Op3._in_p._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_14()
{
  _Op3_P_in_p_P_i = 0.0;
}
/*
equation index: 15
type: SIMPLE_ASSIGN
Op4._in_p._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_15()
{
  _Op4_P_in_p_P_i = 0.0;
}
/*
equation index: 16
type: SIMPLE_ASSIGN
Op5._in_p._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_16()
{
  _Op5_P_in_p_P_i = 0.0;
}
/*
equation index: 17
type: SIMPLE_ASSIGN
Op1._in_n._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_17()
{
  _Op1_P_in_n_P_i = 0.0;
}
/*
equation index: 18
type: SIMPLE_ASSIGN
Op2._in_n._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_18()
{
  _Op2_P_in_n_P_i = 0.0;
}
/*
equation index: 19
type: SIMPLE_ASSIGN
Op3._in_n._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_19()
{
  _Op3_P_in_n_P_i = 0.0;
}
/*
equation index: 20
type: SIMPLE_ASSIGN
Op4._in_n._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_20()
{
  _Op4_P_in_n_P_i = 0.0;
}
/*
equation index: 21
type: SIMPLE_ASSIGN
Op5._in_n._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_21()
{
  _Op5_P_in_n_P_i = 0.0;
}
/*
equation index: 22
type: SIMPLE_ASSIGN
n1._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_22()
{
  _n1_P_i = 0.0;
}
/*
equation index: 23
type: SIMPLE_ASSIGN
n2._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_23()
{
  _n2_P_i = 0.0;
}
/*
equation index: 24
type: SIMPLE_ASSIGN
n3._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_24()
{
  _n3_P_i = 0.0;
}
/*
equation index: 25
type: SIMPLE_ASSIGN
n4._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_25()
{
  _n4_P_i = 0.0;
}
/*
equation index: 26
type: SIMPLE_ASSIGN
n5._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_26()
{
  _n5_P_i = 0.0;
}
/*
equation index: 27
type: SIMPLE_ASSIGN
p1._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_27()
{
  _p1_P_i = 0.0;
}
/*
equation index: 28
type: SIMPLE_ASSIGN
n6._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_28()
{
  _n6_P_i = 0.0;
}
/*
equation index: 29
type: SIMPLE_ASSIGN
n7._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_29()
{
  _n7_P_i = 0.0;
}
/*
equation index: 30
type: SIMPLE_ASSIGN
n8._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_30()
{
  _n8_P_i = 0.0;
}
/*
equation index: 31
type: SIMPLE_ASSIGN
p2._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_31()
{
  _p2_P_i = 0.0;
}
/*
equation index: 32
type: SIMPLE_ASSIGN
out1._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_32()
{
  _out1_P_i = 0.0;
}
/*
equation index: 33
type: SIMPLE_ASSIGN
p3._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_33()
{
  _p3_P_i = 0.0;
}
/*
equation index: 34
type: SIMPLE_ASSIGN
n9._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_34()
{
  _n9_P_i = 0.0;
}
/*
equation index: 35
type: SIMPLE_ASSIGN
n10._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_35()
{
  _n10_P_i = 0.0;
}
/*
equation index: 36
type: SIMPLE_ASSIGN
n11._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_36()
{
  _n11_P_i = 0.0;
}
/*
equation index: 37
type: SIMPLE_ASSIGN
n12._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_37()
{
  _n12_P_i = 0.0;
}
/*
equation index: 38
type: SIMPLE_ASSIGN
n13._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_38()
{
  _n13_P_i = 0.0;
}
/*
equation index: 39
type: SIMPLE_ASSIGN
p4._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_39()
{
  _p4_P_i = 0.0;
}
/*
equation index: 40
type: SIMPLE_ASSIGN
n14._i = 0.0
*/
void CauerLowPassSCInitialize::initEquation_40()
{
  _n14_P_i = 0.0;
}
/*
equation index: 41
type: SIMPLE_ASSIGN
R4._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_41()
{
  _R4_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 42
type: SIMPLE_ASSIGN
R4._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_42()
{
  _R4_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 43
type: SIMPLE_ASSIGN
R5._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_43()
{
  _R5_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 44
type: SIMPLE_ASSIGN
R5._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_44()
{
  _R5_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 45
type: SIMPLE_ASSIGN
R8._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_45()
{
  _R8_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 46
type: SIMPLE_ASSIGN
R8._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_46()
{
  _R8_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 47
type: SIMPLE_ASSIGN
R9._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_47()
{
  _R9_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 48
type: SIMPLE_ASSIGN
R9._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_48()
{
  _R9_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 49
type: SIMPLE_ASSIGN
R1._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_49()
{
  _R1_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 50
type: SIMPLE_ASSIGN
R1._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_50()
{
  _R1_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 51
type: SIMPLE_ASSIGN
R2._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_51()
{
  _R2_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 52
type: SIMPLE_ASSIGN
R2._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_52()
{
  _R2_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 53
type: SIMPLE_ASSIGN
R3._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_53()
{
  _R3_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 54
type: SIMPLE_ASSIGN
R3._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_54()
{
  _R3_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 55
type: SIMPLE_ASSIGN
Rp1._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_55()
{
  _Rp1_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 56
type: SIMPLE_ASSIGN
Rp1._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_56()
{
  _Rp1_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 57
type: SIMPLE_ASSIGN
R7._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_57()
{
  _R7_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 58
type: SIMPLE_ASSIGN
R7._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_58()
{
  _R7_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 59
type: SIMPLE_ASSIGN
R10._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_59()
{
  _R10_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 60
type: SIMPLE_ASSIGN
R10._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_60()
{
  _R10_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 61
type: SIMPLE_ASSIGN
R11._Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_61()
{
  _R11_P_Ground1_P_p_P_v = 0.0;
}
/*
equation index: 62
type: SIMPLE_ASSIGN
R11._Ground2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_62()
{
  _R11_P_Ground2_P_p_P_v = 0.0;
}
/*
equation index: 63
type: SIMPLE_ASSIGN
G._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_63()
{
  _G_P_p_P_v = 0.0;
}
/*
equation index: 64
type: SIMPLE_ASSIGN
G1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_64()
{
  _G1_P_p_P_v = 0.0;
}
/*
equation index: 65
type: SIMPLE_ASSIGN
G2._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_65()
{
  _G2_P_p_P_v = 0.0;
}
/*
equation index: 66
type: SIMPLE_ASSIGN
G3._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_66()
{
  _G3_P_p_P_v = 0.0;
}
/*
equation index: 67
type: SIMPLE_ASSIGN
G4._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_67()
{
  _G4_P_p_P_v = 0.0;
}
/*
equation index: 68
type: SIMPLE_ASSIGN
Ground1._p._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_68()
{
  _Ground1_P_p_P_v = 0.0;
}
/*
equation index: 69
type: SIMPLE_ASSIGN
R4._BooleanPulse1._period = R4.clock
*/
void CauerLowPassSCInitialize::initEquation_69()
{
  _R4_P_BooleanPulse1_P_period = _R4_P_clock;
}
/*
equation index: 70
type: SIMPLE_ASSIGN
R5._BooleanPulse1._period = R5.clock
*/
void CauerLowPassSCInitialize::initEquation_70()
{
  _R5_P_BooleanPulse1_P_period = _R5_P_clock;
}
/*
equation index: 71
type: SIMPLE_ASSIGN
R8._BooleanPulse1._period = R8.clock
*/
void CauerLowPassSCInitialize::initEquation_71()
{
  _R8_P_BooleanPulse1_P_period = _R8_P_clock;
}
/*
equation index: 72
type: SIMPLE_ASSIGN
R9._BooleanPulse1._period = R9.clock
*/
void CauerLowPassSCInitialize::initEquation_72()
{
  _R9_P_BooleanPulse1_P_period = _R9_P_clock;
}
/*
equation index: 73
type: SIMPLE_ASSIGN
R1._BooleanPulse1._period = R1.clock
*/
void CauerLowPassSCInitialize::initEquation_73()
{
  _R1_P_BooleanPulse1_P_period = _R1_P_clock;
}
/*
equation index: 74
type: SIMPLE_ASSIGN
R2._BooleanPulse1._period = R2.clock
*/
void CauerLowPassSCInitialize::initEquation_74()
{
  _R2_P_BooleanPulse1_P_period = _R2_P_clock;
}
/*
equation index: 75
type: SIMPLE_ASSIGN
R3._BooleanPulse1._period = R3.clock
*/
void CauerLowPassSCInitialize::initEquation_75()
{
  _R3_P_BooleanPulse1_P_period = _R3_P_clock;
}
/*
equation index: 76
type: SIMPLE_ASSIGN
Rp1._BooleanPulse1._period = Rp1.clock
*/
void CauerLowPassSCInitialize::initEquation_76()
{
  _Rp1_P_BooleanPulse1_P_period = _Rp1_P_clock;
}
/*
equation index: 77
type: SIMPLE_ASSIGN
R7._BooleanPulse1._period = R7.clock
*/
void CauerLowPassSCInitialize::initEquation_77()
{
  _R7_P_BooleanPulse1_P_period = _R7_P_clock;
}
/*
equation index: 78
type: SIMPLE_ASSIGN
R10._BooleanPulse1._period = R10.clock
*/
void CauerLowPassSCInitialize::initEquation_78()
{
  _R10_P_BooleanPulse1_P_period = _R10_P_clock;
}
/*
equation index: 79
type: SIMPLE_ASSIGN
R11._BooleanPulse1._period = R11.clock
*/
void CauerLowPassSCInitialize::initEquation_79()
{
  _R11_P_BooleanPulse1_P_period = _R11_P_clock;
}
/*
equation index: 80
type: SIMPLE_ASSIGN
R11._Capacitor1._C = DIVISION(R11.clock, R11.R)
*/
void CauerLowPassSCInitialize::initEquation_80()
{
  _R11_P_Capacitor1_P_C = division(_R11_P_clock,_R11_P_R,"R11.R");
}
/*
equation index: 81
type: SIMPLE_ASSIGN
R10._Capacitor1._C = DIVISION(R10.clock, R10.R)
*/
void CauerLowPassSCInitialize::initEquation_81()
{
  _R10_P_Capacitor1_P_C = division(_R10_P_clock,_R10_P_R,"R10.R");
}
/*
equation index: 82
type: SIMPLE_ASSIGN
R7._Capacitor1._C = DIVISION(R7.clock, R7.R)
*/
void CauerLowPassSCInitialize::initEquation_82()
{
  _R7_P_Capacitor1_P_C = division(_R7_P_clock,_R7_P_R,"R7.R");
}
/*
equation index: 83
type: SIMPLE_ASSIGN
Rp1._Capacitor1._C = DIVISION(Rp1.clock, Rp1.R)
*/
void CauerLowPassSCInitialize::initEquation_83()
{
  _Rp1_P_Capacitor1_P_C = division(_Rp1_P_clock,_Rp1_P_R,"Rp1.R");
}
/*
equation index: 84
type: SIMPLE_ASSIGN
R3._Capacitor1._C = DIVISION(R3.clock, R3.R)
*/
void CauerLowPassSCInitialize::initEquation_84()
{
  _R3_P_Capacitor1_P_C = division(_R3_P_clock,_R3_P_R,"R3.R");
}
/*
equation index: 85
type: SIMPLE_ASSIGN
R2._Capacitor1._C = DIVISION(R2.clock, R2.R)
*/
void CauerLowPassSCInitialize::initEquation_85()
{
  _R2_P_Capacitor1_P_C = division(_R2_P_clock,_R2_P_R,"R2.R");
}
/*
equation index: 86
type: SIMPLE_ASSIGN
R1._Capacitor1._C = DIVISION(R1.clock, R1.R)
*/
void CauerLowPassSCInitialize::initEquation_86()
{
  _R1_P_Capacitor1_P_C = division(_R1_P_clock,_R1_P_R,"R1.R");
}
/*
equation index: 87
type: SIMPLE_ASSIGN
R9._Capacitor1._C = DIVISION(R9.clock, R9.R)
*/
void CauerLowPassSCInitialize::initEquation_87()
{
  _R9_P_Capacitor1_P_C = division(_R9_P_clock,_R9_P_R,"R9.R");
}
/*
equation index: 88
type: SIMPLE_ASSIGN
R8._Capacitor1._C = DIVISION(R8.clock, R8.R)
*/
void CauerLowPassSCInitialize::initEquation_88()
{
  _R8_P_Capacitor1_P_C = division(_R8_P_clock,_R8_P_R,"R8.R");
}
/*
equation index: 89
type: SIMPLE_ASSIGN
R5._Capacitor1._C = DIVISION(R5.clock, R5.R)
*/
void CauerLowPassSCInitialize::initEquation_89()
{
  _R5_P_Capacitor1_P_C = division(_R5_P_clock,_R5_P_R,"R5.R");
}
/*
equation index: 90
type: SIMPLE_ASSIGN
R4._Capacitor1._C = DIVISION(R4.clock, R4.R)
*/
void CauerLowPassSCInitialize::initEquation_90()
{
  _R4_P_Capacitor1_P_C = division(_R4_P_clock,_R4_P_R,"R4.R");
}
/*
equation index: 91
type: SIMPLE_ASSIGN
V._signalSource._height = V.V
*/
void CauerLowPassSCInitialize::initEquation_91()
{
  _V_P_signalSource_P_height = _V_P_V;
}
/*
equation index: 92
type: SIMPLE_ASSIGN
V._signalSource._startTime = V.startTime
*/
void CauerLowPassSCInitialize::initEquation_92()
{
  _V_P_signalSource_P_startTime = _V_P_startTime;
}
/*
equation index: 93
type: SIMPLE_ASSIGN
V._signalSource._offset = V.offset
*/
void CauerLowPassSCInitialize::initEquation_93()
{
  _V_P_signalSource_P_offset = _V_P_offset;
}
/*
equation index: 94
type: SIMPLE_ASSIGN
C7._C = l2
*/
void CauerLowPassSCInitialize::initEquation_94()
{
  _C7_P_C = _l2;
}
/*
equation index: 95
type: SIMPLE_ASSIGN
C3._C = l1
*/
void CauerLowPassSCInitialize::initEquation_95()
{
  _C3_P_C = _l1;
}
/*
equation index: 96
type: SIMPLE_ASSIGN
c4 = DIVISION(1.0, l2 * 1.392270203025)
*/
void CauerLowPassSCInitialize::initEquation_96()
{
  _c4 = division(1.0,(_l2 * 1.392270203025),"l2 * 1.392270203025");
}
/*
equation index: 97
type: SIMPLE_ASSIGN
C4._C = c4
*/
void CauerLowPassSCInitialize::initEquation_97()
{
  _C4_P_C = _c4;
}
/*
equation index: 98
type: SIMPLE_ASSIGN
C8._C = c4
*/
void CauerLowPassSCInitialize::initEquation_98()
{
  _C8_P_C = _c4;
}
/*
equation index: 99
type: SIMPLE_ASSIGN
C9._C = c4 + c5
*/
void CauerLowPassSCInitialize::initEquation_99()
{
  _C9_P_C = (_c4 + _c5);
}
/*
equation index: 100
type: SIMPLE_ASSIGN
c2 = DIVISION(1.0, l1 * 2.906997720064)
*/
void CauerLowPassSCInitialize::initEquation_100()
{
  _c2 = division(1.0,(_l1 * 2.906997720064),"l1 * 2.906997720064");
}
/*
equation index: 101
type: SIMPLE_ASSIGN
C1._C = c1 + c2
*/
void CauerLowPassSCInitialize::initEquation_101()
{
  _C1_P_C = (_c1 + _c2);
}
/*
equation index: 102
type: SIMPLE_ASSIGN
C2._C = c2
*/
void CauerLowPassSCInitialize::initEquation_102()
{
  _C2_P_C = _c2;
}
/*
equation index: 103
type: SIMPLE_ASSIGN
C5._C = c2
*/
void CauerLowPassSCInitialize::initEquation_103()
{
  _C5_P_C = _c2;
}
/*
equation index: 104
type: SIMPLE_ASSIGN
C6._C = c2 + c3 + c4
*/
void CauerLowPassSCInitialize::initEquation_104()
{
  _C6_P_C = (_c2 + (_c3 + _c4));
}
/*
equation index: 105
type: SIMPLE_ASSIGN
V._v = V.signalSource.offset + (if time < V.signalSource.startTime then 0.0 else V.signalSource.height)
*/
void CauerLowPassSCInitialize::initEquation_105()
{
  double tmp24;
  if (getCondition(0)) {
    tmp24 = 0.0;
  } else {
    tmp24 = _V_P_signalSource_P_height;
  }
  _V_P_v = (_V_P_signalSource_P_offset + tmp24);
}
/*
equation index: 106
type: SIMPLE_ASSIGN
C1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_106()
{
    __z[0]   = 0.0;
}
/*
equation index: 107
type: SIMPLE_ASSIGN
C2._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_107()
{
    __z[1]   = 0.0;
}
/*
equation index: 108
type: SIMPLE_ASSIGN
C3._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_108()
{
    __z[2]   = 0.0;
}
/*
equation index: 109
type: SIMPLE_ASSIGN
C4._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_109()
{
    __z[3]   = 0.0;
}
/*
equation index: 110
type: SIMPLE_ASSIGN
C7._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_110()
{
    __z[4]   = 0.0;
}
/*
equation index: 111
type: SIMPLE_ASSIGN
R4._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_111()
{
    __z[10]   = 0.0;
}
/*
equation index: 112
type: SIMPLE_ASSIGN
R5._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_112()
{
    __z[11]   = 0.0;
}
/*
equation index: 113
type: SIMPLE_ASSIGN
R8._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_113()
{
    __z[13]   = 0.0;
}
/*
equation index: 114
type: SIMPLE_ASSIGN
R9._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_114()
{
    __z[14]   = 0.0;
}
/*
equation index: 115
type: SIMPLE_ASSIGN
R1._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_115()
{
    __z[5]   = 0.0;
}
/*
equation index: 116
type: SIMPLE_ASSIGN
R2._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_116()
{
    __z[8]   = 0.0;
}
/*
equation index: 117
type: SIMPLE_ASSIGN
R3._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_117()
{
    __z[9]   = 0.0;
}
/*
equation index: 118
type: SIMPLE_ASSIGN
Rp1._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_118()
{
    __z[15]   = 0.0;
}
/*
equation index: 119
type: SIMPLE_ASSIGN
R7._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_119()
{
    __z[12]   = 0.0;
}
/*
equation index: 120
type: SIMPLE_ASSIGN
R10._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_120()
{
    __z[6]   = 0.0;
}
/*
equation index: 121
type: SIMPLE_ASSIGN
R11._Capacitor1._v = 0.0
*/
void CauerLowPassSCInitialize::initEquation_121()
{
    __z[7]   = 0.0;
}
/*
equation index: 122
type: SIMPLE_ASSIGN
R11._BooleanPulse1._pulsStart = R11.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_122()
{
  _R11_P_BooleanPulse1_P_pulsStart = _R11_P_BooleanPulse1_P_startTime;
}
/*
equation index: 123
type: SIMPLE_ASSIGN
R11._BooleanPulse1._y = time >= R11.BooleanPulse1.pulsStart and time < R11.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_123()
{
  _R11_P_BooleanPulse1_P_y = (getCondition(21) && getCondition(22));
}
/*
equation index: 124
type: LINEAR

<var>R11._IdealCommutingSwitch1._n2._i</var>
<var>R11._IdealCommutingSwitch1._s2</var>
<var>R11._Capacitor1._p._v</var>
<var>R11._n2._i</var>
<var>R11._IdealCommutingSwitch2._s1</var>
<var>R11._Capacitor1._n._v</var>
<var>R11._IdealCommutingSwitch2._s2</var>
<var>R11._IdealCommutingSwitch2._n2._i</var>
<var>R11._Capacitor1._i</var>
<var>R11._n1._i</var>
<var>R11._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>C4.v</cell>
  <cell>-0.0</cell>
  <cell>-R11.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R11.BooleanPulse1.y then R11.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R11.BooleanPulse1.y then R11.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R11.BooleanPulse1.y then R11.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R11.BooleanPulse1.y then R11.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R11.BooleanPulse1.y then 1.0 else R11.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_124()
{
  bool restart124 = true;
  unsigned int iterations124 = 0;
  _algLoop124->getReal(_algloop124Vars );
  bool restatDiscrete124= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop124->evaluate();
          while(restart124 && !(iterations124++>500))
          {
              getConditions(_conditions0124);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver124->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1124);
              restart124 = !std::equal (_conditions1124, _conditions1124+_dimZeroFunc,_conditions0124);
          }
      }
      else
      _algLoopSolver124->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete124=true;
  }
  
  if((restart124&& iterations124 > 0)|| restatDiscrete124)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop124->setReal(_algloop124Vars );
          _algLoopSolver124->solve();
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
equation index: 125
type: SIMPLE_ASSIGN
der(R11._Capacitor1._v) = DIVISION(R11.Capacitor1.i, R11.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_125()
{
   __zDot[7]  = division(_R11_P_Capacitor1_P_i,_R11_P_Capacitor1_P_C,"R11.Capacitor1.C");
}
/*
equation index: 126
type: SIMPLE_ASSIGN
R11._IdealCommutingSwitch2._LossPower = R11.Capacitor1.i * R11.Capacitor1.n.v + R11.n2.i * C4.v
*/
void CauerLowPassSCInitialize::initEquation_126()
{
  _R11_P_IdealCommutingSwitch2_P_LossPower = ((_R11_P_Capacitor1_P_i * _R11_P_Capacitor1_P_n_P_v) + (_R11_P_n2_P_i * __z[3]));
}
/*
equation index: 127
type: SIMPLE_ASSIGN
R11._IdealCommutingSwitch1._LossPower = (-R11.Capacitor1.i) * R11.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_127()
{
  _R11_P_IdealCommutingSwitch1_P_LossPower = ((-_R11_P_Capacitor1_P_i) * _R11_P_Capacitor1_P_p_P_v);
}
/*
equation index: 128
type: SIMPLE_ASSIGN
$PRE._R11._BooleanPulse1._pulsStart = R11.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_128()
{
  _R11_P_BooleanPulse1_P_pulsStart = _R11_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R11_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 129
type: SIMPLE_ASSIGN
R10._BooleanPulse1._pulsStart = R10.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_129()
{
  _R10_P_BooleanPulse1_P_pulsStart = _R10_P_BooleanPulse1_P_startTime;
}
/*
equation index: 130
type: SIMPLE_ASSIGN
R10._BooleanPulse1._y = time >= R10.BooleanPulse1.pulsStart and time < R10.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_130()
{
  _R10_P_BooleanPulse1_P_y = (getCondition(19) && getCondition(20));
}
/*
equation index: 131
type: LINEAR

<var>R10._IdealCommutingSwitch2._n2._i</var>
<var>R10._IdealCommutingSwitch2._s2</var>
<var>R10._Capacitor1._i</var>
<var>R10._n2._i</var>
<var>R10._IdealCommutingSwitch2._s1</var>
<var>R10._Capacitor1._n._v</var>
<var>R10._Capacitor1._p._v</var>
<var>R10._IdealCommutingSwitch1._s2</var>
<var>R10._IdealCommutingSwitch1._n2._i</var>
<var>R10._n1._i</var>
<var>R10._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-C7.v</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R10.Capacitor1.v</cell>
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
    <residual>-(if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R10.BooleanPulse1.y then R10.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="2">
    <residual>1.0</residual>
  </cell><cell row="2" col="8">
    <residual>-1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="3" col="8">
    <residual>1.0</residual>
  </cell><cell row="4" col="6">
    <residual>1.0</residual>
  </cell><cell row="4" col="7">
    <residual>-(if R10.BooleanPulse1.y then R10.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-1.0</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R10.BooleanPulse1.y then R10.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="0">
    <residual>-1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="3">
    <residual>-1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R10.BooleanPulse1.y then R10.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="5">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R10.BooleanPulse1.y then 1.0 else R10.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_131()
{
  bool restart131 = true;
  unsigned int iterations131 = 0;
  _algLoop131->getReal(_algloop131Vars );
  bool restatDiscrete131= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop131->evaluate();
          while(restart131 && !(iterations131++>500))
          {
              getConditions(_conditions0131);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver131->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1131);
              restart131 = !std::equal (_conditions1131, _conditions1131+_dimZeroFunc,_conditions0131);
          }
      }
      else
      _algLoopSolver131->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete131=true;
  }
  
  if((restart131&& iterations131 > 0)|| restatDiscrete131)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop131->setReal(_algloop131Vars );
          _algLoopSolver131->solve();
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
equation index: 132
type: SIMPLE_ASSIGN
der(R10._Capacitor1._v) = DIVISION(R10.Capacitor1.i, R10.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_132()
{
   __zDot[6]  = division(_R10_P_Capacitor1_P_i,_R10_P_Capacitor1_P_C,"R10.Capacitor1.C");
}
/*
equation index: 133
type: SIMPLE_ASSIGN
R10._IdealCommutingSwitch2._LossPower = R10.Capacitor1.i * R10.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_133()
{
  _R10_P_IdealCommutingSwitch2_P_LossPower = (_R10_P_Capacitor1_P_i * _R10_P_Capacitor1_P_n_P_v);
}
/*
equation index: 134
type: SIMPLE_ASSIGN
R10._IdealCommutingSwitch1._LossPower = (-R10.n1.i) * C7.v - R10.Capacitor1.i * R10.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_134()
{
  _R10_P_IdealCommutingSwitch1_P_LossPower = (((-_R10_P_n1_P_i) * __z[4]) - (_R10_P_Capacitor1_P_i * _R10_P_Capacitor1_P_p_P_v));
}
/*
equation index: 135
type: SIMPLE_ASSIGN
$PRE._R10._BooleanPulse1._pulsStart = R10.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_135()
{
  _R10_P_BooleanPulse1_P_pulsStart = _R10_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R10_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 136
type: SIMPLE_ASSIGN
R7._BooleanPulse1._pulsStart = R7.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_136()
{
  _R7_P_BooleanPulse1_P_pulsStart = _R7_P_BooleanPulse1_P_startTime;
}
/*
equation index: 137
type: SIMPLE_ASSIGN
R7._BooleanPulse1._y = time >= R7.BooleanPulse1.pulsStart and time < R7.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_137()
{
  _R7_P_BooleanPulse1_P_y = (getCondition(17) && getCondition(18));
}
/*
equation index: 138
type: LINEAR

<var>R7._IdealCommutingSwitch2._n2._i</var>
<var>R7._IdealCommutingSwitch2._s2</var>
<var>R7._Capacitor1._i</var>
<var>R7._n2._i</var>
<var>R7._IdealCommutingSwitch2._s1</var>
<var>R7._Capacitor1._n._v</var>
<var>R7._IdealCommutingSwitch1._s1</var>
<var>R7._n1._i</var>
<var>R7._IdealCommutingSwitch1._n2._i</var>
<var>R7._IdealCommutingSwitch1._s2</var>
<var>R7._Capacitor1._p._v</var>
<row>
  <cell>-C3.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-R7.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="6">
    <residual>-(if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="0" col="10">
    <residual>1.0</residual>
  </cell><cell row="1" col="9">
    <residual>-(if R7.BooleanPulse1.y then R7.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="1" col="10">
    <residual>1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch1.Goff</residual>
  </cell><cell row="3" col="2">
    <residual>1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R7.BooleanPulse1.y then R7.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="10">
    <residual>-1.0</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R7.BooleanPulse1.y then R7.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="0">
    <residual>-1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="3">
    <residual>-1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R7.BooleanPulse1.y then R7.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="5">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R7.BooleanPulse1.y then 1.0 else R7.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_138()
{
  bool restart138 = true;
  unsigned int iterations138 = 0;
  _algLoop138->getReal(_algloop138Vars );
  bool restatDiscrete138= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop138->evaluate();
          while(restart138 && !(iterations138++>500))
          {
              getConditions(_conditions0138);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver138->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1138);
              restart138 = !std::equal (_conditions1138, _conditions1138+_dimZeroFunc,_conditions0138);
          }
      }
      else
      _algLoopSolver138->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete138=true;
  }
  
  if((restart138&& iterations138 > 0)|| restatDiscrete138)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop138->setReal(_algloop138Vars );
          _algLoopSolver138->solve();
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
equation index: 139
type: SIMPLE_ASSIGN
der(R7._Capacitor1._v) = DIVISION(R7.Capacitor1.i, R7.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_139()
{
   __zDot[12]  = division(_R7_P_Capacitor1_P_i,_R7_P_Capacitor1_P_C,"R7.Capacitor1.C");
}
/*
equation index: 140
type: SIMPLE_ASSIGN
R7._IdealCommutingSwitch2._LossPower = R7.Capacitor1.i * R7.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_140()
{
  _R7_P_IdealCommutingSwitch2_P_LossPower = (_R7_P_Capacitor1_P_i * _R7_P_Capacitor1_P_n_P_v);
}
/*
equation index: 141
type: SIMPLE_ASSIGN
R7._IdealCommutingSwitch1._LossPower = (-R7.n1.i) * C3.v - R7.Capacitor1.i * R7.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_141()
{
  _R7_P_IdealCommutingSwitch1_P_LossPower = (((-_R7_P_n1_P_i) * __z[2]) - (_R7_P_Capacitor1_P_i * _R7_P_Capacitor1_P_p_P_v));
}
/*
equation index: 142
type: SIMPLE_ASSIGN
$PRE._R7._BooleanPulse1._pulsStart = R7.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_142()
{
  _R7_P_BooleanPulse1_P_pulsStart = _R7_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R7_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 143
type: SIMPLE_ASSIGN
Rp1._BooleanPulse1._pulsStart = Rp1.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_143()
{
  _Rp1_P_BooleanPulse1_P_pulsStart = _Rp1_P_BooleanPulse1_P_startTime;
}
/*
equation index: 144
type: SIMPLE_ASSIGN
Rp1._BooleanPulse1._y = time >= Rp1.BooleanPulse1.pulsStart and time < Rp1.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_144()
{
  _Rp1_P_BooleanPulse1_P_y = (getCondition(15) && getCondition(16));
}
/*
equation index: 145
type: LINEAR

<var>Rp1._IdealCommutingSwitch1._n2._i</var>
<var>Rp1._IdealCommutingSwitch1._s2</var>
<var>Rp1._Capacitor1._p._v</var>
<var>Rp1._IdealCommutingSwitch2._n2._i</var>
<var>Rp1._IdealCommutingSwitch2._s2</var>
<var>Rp1._Capacitor1._n._v</var>
<var>Rp1._IdealCommutingSwitch2._s1</var>
<var>Rp1._n2._i</var>
<var>Rp1._Capacitor1._i</var>
<var>Rp1._n1._i</var>
<var>Rp1._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-C7.v</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-Rp1.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if Rp1.BooleanPulse1.y then Rp1.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if Rp1.BooleanPulse1.y then 1.0 else Rp1.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_145()
{
  bool restart145 = true;
  unsigned int iterations145 = 0;
  _algLoop145->getReal(_algloop145Vars );
  bool restatDiscrete145= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop145->evaluate();
          while(restart145 && !(iterations145++>500))
          {
              getConditions(_conditions0145);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver145->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1145);
              restart145 = !std::equal (_conditions1145, _conditions1145+_dimZeroFunc,_conditions0145);
          }
      }
      else
      _algLoopSolver145->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete145=true;
  }
  
  if((restart145&& iterations145 > 0)|| restatDiscrete145)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop145->setReal(_algloop145Vars );
          _algLoopSolver145->solve();
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
equation index: 146
type: SIMPLE_ASSIGN
der(Rp1._Capacitor1._v) = DIVISION(Rp1.Capacitor1.i, Rp1.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_146()
{
   __zDot[15]  = division(_Rp1_P_Capacitor1_P_i,_Rp1_P_Capacitor1_P_C,"Rp1.Capacitor1.C");
}
/*
equation index: 147
type: SIMPLE_ASSIGN
Rp1._IdealCommutingSwitch2._LossPower = Rp1.Capacitor1.i * Rp1.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_147()
{
  _Rp1_P_IdealCommutingSwitch2_P_LossPower = (_Rp1_P_Capacitor1_P_i * _Rp1_P_Capacitor1_P_n_P_v);
}
/*
equation index: 148
type: SIMPLE_ASSIGN
Rp1._IdealCommutingSwitch1._LossPower = (-Rp1.n1.i) * C7.v - Rp1.Capacitor1.i * Rp1.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_148()
{
  _Rp1_P_IdealCommutingSwitch1_P_LossPower = (((-_Rp1_P_n1_P_i) * __z[4]) - (_Rp1_P_Capacitor1_P_i * _Rp1_P_Capacitor1_P_p_P_v));
}
/*
equation index: 149
type: SIMPLE_ASSIGN
$PRE._Rp1._BooleanPulse1._pulsStart = Rp1.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_149()
{
  _Rp1_P_BooleanPulse1_P_pulsStart = _Rp1_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _Rp1_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 150
type: SIMPLE_ASSIGN
R3._BooleanPulse1._pulsStart = R3.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_150()
{
  _R3_P_BooleanPulse1_P_pulsStart = _R3_P_BooleanPulse1_P_startTime;
}
/*
equation index: 151
type: SIMPLE_ASSIGN
R3._BooleanPulse1._y = time >= R3.BooleanPulse1.pulsStart and time < R3.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_151()
{
  _R3_P_BooleanPulse1_P_y = (getCondition(13) && getCondition(14));
}
/*
equation index: 152
type: LINEAR

<var>R3._IdealCommutingSwitch1._n2._i</var>
<var>R3._IdealCommutingSwitch1._s2</var>
<var>R3._Capacitor1._p._v</var>
<var>R3._n2._i</var>
<var>R3._IdealCommutingSwitch2._s1</var>
<var>R3._Capacitor1._n._v</var>
<var>R3._IdealCommutingSwitch2._s2</var>
<var>R3._IdealCommutingSwitch2._n2._i</var>
<var>R3._Capacitor1._i</var>
<var>R3._n1._i</var>
<var>R3._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-C1.v</cell>
  <cell>-0.0</cell>
  <cell>-R3.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R3.BooleanPulse1.y then R3.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R3.BooleanPulse1.y then R3.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R3.BooleanPulse1.y then R3.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R3.BooleanPulse1.y then R3.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R3.BooleanPulse1.y then 1.0 else R3.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_152()
{
  bool restart152 = true;
  unsigned int iterations152 = 0;
  _algLoop152->getReal(_algloop152Vars );
  bool restatDiscrete152= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop152->evaluate();
          while(restart152 && !(iterations152++>500))
          {
              getConditions(_conditions0152);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver152->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1152);
              restart152 = !std::equal (_conditions1152, _conditions1152+_dimZeroFunc,_conditions0152);
          }
      }
      else
      _algLoopSolver152->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete152=true;
  }
  
  if((restart152&& iterations152 > 0)|| restatDiscrete152)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop152->setReal(_algloop152Vars );
          _algLoopSolver152->solve();
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
equation index: 153
type: SIMPLE_ASSIGN
der(R3._Capacitor1._v) = DIVISION(R3.Capacitor1.i, R3.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_153()
{
   __zDot[9]  = division(_R3_P_Capacitor1_P_i,_R3_P_Capacitor1_P_C,"R3.Capacitor1.C");
}
/*
equation index: 154
type: SIMPLE_ASSIGN
R3._IdealCommutingSwitch2._LossPower = R3.Capacitor1.i * R3.Capacitor1.n.v - R3.n2.i * C1.v
*/
void CauerLowPassSCInitialize::initEquation_154()
{
  _R3_P_IdealCommutingSwitch2_P_LossPower = ((_R3_P_Capacitor1_P_i * _R3_P_Capacitor1_P_n_P_v) - (_R3_P_n2_P_i * __z[0]));
}
/*
equation index: 155
type: SIMPLE_ASSIGN
R3._IdealCommutingSwitch1._LossPower = (-R3.Capacitor1.i) * R3.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_155()
{
  _R3_P_IdealCommutingSwitch1_P_LossPower = ((-_R3_P_Capacitor1_P_i) * _R3_P_Capacitor1_P_p_P_v);
}
/*
equation index: 156
type: SIMPLE_ASSIGN
$PRE._R3._BooleanPulse1._pulsStart = R3.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_156()
{
  _R3_P_BooleanPulse1_P_pulsStart = _R3_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R3_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 157
type: SIMPLE_ASSIGN
R2._BooleanPulse1._pulsStart = R2.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_157()
{
  _R2_P_BooleanPulse1_P_pulsStart = _R2_P_BooleanPulse1_P_startTime;
}
/*
equation index: 158
type: SIMPLE_ASSIGN
R2._BooleanPulse1._y = time >= R2.BooleanPulse1.pulsStart and time < R2.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_158()
{
  _R2_P_BooleanPulse1_P_y = (getCondition(11) && getCondition(12));
}
/*
equation index: 159
type: LINEAR

<var>R2._IdealCommutingSwitch1._n2._i</var>
<var>R2._IdealCommutingSwitch1._s2</var>
<var>R2._Capacitor1._p._v</var>
<var>R2._IdealCommutingSwitch2._n2._i</var>
<var>R2._IdealCommutingSwitch2._s2</var>
<var>R2._Capacitor1._n._v</var>
<var>R2._IdealCommutingSwitch2._s1</var>
<var>R2._n2._i</var>
<var>R2._Capacitor1._i</var>
<var>R2._n1._i</var>
<var>R2._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-C3.v</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R2.Capacitor1.v</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R2.BooleanPulse1.y then R2.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R2.BooleanPulse1.y then R2.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R2.BooleanPulse1.y then R2.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R2.BooleanPulse1.y then R2.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R2.BooleanPulse1.y then 1.0 else R2.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_159()
{
  bool restart159 = true;
  unsigned int iterations159 = 0;
  _algLoop159->getReal(_algloop159Vars );
  bool restatDiscrete159= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop159->evaluate();
          while(restart159 && !(iterations159++>500))
          {
              getConditions(_conditions0159);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver159->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1159);
              restart159 = !std::equal (_conditions1159, _conditions1159+_dimZeroFunc,_conditions0159);
          }
      }
      else
      _algLoopSolver159->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete159=true;
  }
  
  if((restart159&& iterations159 > 0)|| restatDiscrete159)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop159->setReal(_algloop159Vars );
          _algLoopSolver159->solve();
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
equation index: 160
type: SIMPLE_ASSIGN
der(R2._Capacitor1._v) = DIVISION(R2.Capacitor1.i, R2.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_160()
{
   __zDot[8]  = division(_R2_P_Capacitor1_P_i,_R2_P_Capacitor1_P_C,"R2.Capacitor1.C");
}
/*
equation index: 161
type: SIMPLE_ASSIGN
R2._IdealCommutingSwitch2._LossPower = R2.Capacitor1.i * R2.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_161()
{
  _R2_P_IdealCommutingSwitch2_P_LossPower = (_R2_P_Capacitor1_P_i * _R2_P_Capacitor1_P_n_P_v);
}
/*
equation index: 162
type: SIMPLE_ASSIGN
R2._IdealCommutingSwitch1._LossPower = (-R2.n1.i) * C3.v - R2.Capacitor1.i * R2.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_162()
{
  _R2_P_IdealCommutingSwitch1_P_LossPower = (((-_R2_P_n1_P_i) * __z[2]) - (_R2_P_Capacitor1_P_i * _R2_P_Capacitor1_P_p_P_v));
}
/*
equation index: 163
type: SIMPLE_ASSIGN
$PRE._R2._BooleanPulse1._pulsStart = R2.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_163()
{
  _R2_P_BooleanPulse1_P_pulsStart = _R2_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R2_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 164
type: SIMPLE_ASSIGN
R1._BooleanPulse1._pulsStart = R1.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_164()
{
  _R1_P_BooleanPulse1_P_pulsStart = _R1_P_BooleanPulse1_P_startTime;
}
/*
equation index: 165
type: SIMPLE_ASSIGN
R1._BooleanPulse1._y = time >= R1.BooleanPulse1.pulsStart and time < R1.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_165()
{
  _R1_P_BooleanPulse1_P_y = (getCondition(9) && getCondition(10));
}
/*
equation index: 166
type: LINEAR

<var>R1._IdealCommutingSwitch2._n2._i</var>
<var>R1._IdealCommutingSwitch2._s2</var>
<var>R1._Capacitor1._i</var>
<var>R1._n2._i</var>
<var>R1._IdealCommutingSwitch2._s1</var>
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
    <residual>-(if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R1.BooleanPulse1.y then R1.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="0">
    <residual>-1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="3">
    <residual>-1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R1.BooleanPulse1.y then R1.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="9" col="5">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R1.BooleanPulse1.y then 1.0 else R1.IdealCommutingSwitch2.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_166()
{
  bool restart166 = true;
  unsigned int iterations166 = 0;
  _algLoop166->getReal(_algloop166Vars );
  bool restatDiscrete166= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop166->evaluate();
          while(restart166 && !(iterations166++>500))
          {
              getConditions(_conditions0166);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver166->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1166);
              restart166 = !std::equal (_conditions1166, _conditions1166+_dimZeroFunc,_conditions0166);
          }
      }
      else
      _algLoopSolver166->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete166=true;
  }
  
  if((restart166&& iterations166 > 0)|| restatDiscrete166)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop166->setReal(_algloop166Vars );
          _algLoopSolver166->solve();
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
equation index: 167
type: LINEAR

<var>C4._i</var>
<var>der(C4._v)</var>
<var>C9._i</var>
<var>C8._i</var>
<var>C1._i</var>
<var>der(C1._v)</var>
<var>C5._i</var>
<var>C6._i</var>
<var>der(C2._v)</var>
<var>C2._i</var>
<row>
  <cell>(-R1.n2.i) - R2.n2.i - R3.n1.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>(-Rp1.n2.i) - R7.n2.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>(-R11.n1.i) - R10.n2.i</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="4">
    <residual>1.0</residual>
  </cell><cell row="0" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="8">
    <residual>-C2.C</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="2" col="7">
    <residual>1.0</residual>
  </cell><cell row="2" col="8">
    <residual>C6.C</residual>
  </cell><cell row="3" col="0">
    <residual>-1.0</residual>
  </cell><cell row="3" col="6">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>1.0</residual>
  </cell><cell row="4" col="5">
    <residual>C5.C</residual>
  </cell><cell row="4" col="6">
    <residual>1.0</residual>
  </cell><cell row="5" col="4">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>-C1.C</residual>
  </cell><cell row="6" col="3">
    <residual>1.0</residual>
  </cell><cell row="6" col="8">
    <residual>-C8.C</residual>
  </cell><cell row="7" col="2">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>-1.0</residual>
  </cell><cell row="8" col="1">
    <residual>C9.C</residual>
  </cell><cell row="8" col="2">
    <residual>1.0</residual>
  </cell><cell row="9" col="0">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-C4.C</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_167()
{
  bool restart167 = true;
  unsigned int iterations167 = 0;
  _algLoop167->getReal(_algloop167Vars );
  bool restatDiscrete167= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop167->evaluate();
          while(restart167 && !(iterations167++>500))
          {
              getConditions(_conditions0167);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver167->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1167);
              restart167 = !std::equal (_conditions1167, _conditions1167+_dimZeroFunc,_conditions0167);
          }
      }
      else
      _algLoopSolver167->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete167=true;
  }
  
  if((restart167&& iterations167 > 0)|| restatDiscrete167)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop167->setReal(_algloop167Vars );
          _algLoopSolver167->solve();
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
equation index: 168
type: SIMPLE_ASSIGN
der(R1._Capacitor1._v) = DIVISION(R1.Capacitor1.i, R1.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_168()
{
   __zDot[5]  = division(_R1_P_Capacitor1_P_i,_R1_P_Capacitor1_P_C,"R1.Capacitor1.C");
}
/*
equation index: 169
type: SIMPLE_ASSIGN
R1._IdealCommutingSwitch2._LossPower = R1.Capacitor1.i * R1.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_169()
{
  _R1_P_IdealCommutingSwitch2_P_LossPower = (_R1_P_Capacitor1_P_i * _R1_P_Capacitor1_P_n_P_v);
}
/*
equation index: 170
type: SIMPLE_ASSIGN
R1._IdealCommutingSwitch1._LossPower = (-V.i) * V.v - R1.Capacitor1.i * R1.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_170()
{
  _R1_P_IdealCommutingSwitch1_P_LossPower = (((-_V_P_i) * _V_P_v) - (_R1_P_Capacitor1_P_i * _R1_P_Capacitor1_P_p_P_v));
}
/*
equation index: 171
type: SIMPLE_ASSIGN
$PRE._R1._BooleanPulse1._pulsStart = R1.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_171()
{
  _R1_P_BooleanPulse1_P_pulsStart = _R1_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R1_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 172
type: SIMPLE_ASSIGN
R9._BooleanPulse1._pulsStart = R9.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_172()
{
  _R9_P_BooleanPulse1_P_pulsStart = _R9_P_BooleanPulse1_P_startTime;
}
/*
equation index: 173
type: SIMPLE_ASSIGN
R9._BooleanPulse1._y = time >= R9.BooleanPulse1.pulsStart and time < R9.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_173()
{
  _R9_P_BooleanPulse1_P_y = (getCondition(7) && getCondition(8));
}
/*
equation index: 174
type: LINEAR

<var>R9._n1._i</var>
<var>R9._IdealCommutingSwitch1._s2</var>
<var>R9._Capacitor1._p._v</var>
<var>R9._n2._i</var>
<var>R9._IdealCommutingSwitch2._s1</var>
<var>R9._Capacitor1._n._v</var>
<var>R9._IdealCommutingSwitch2._s2</var>
<var>R9._IdealCommutingSwitch2._n2._i</var>
<var>R9._Capacitor1._i</var>
<var>R9._IdealCommutingSwitch1._n1._i</var>
<var>R9._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R9.Capacitor1.v</cell>
  <cell>C2.v</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R9.BooleanPulse1.y then R9.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R9.BooleanPulse1.y then R9.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R9.BooleanPulse1.y then R9.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R9.BooleanPulse1.y then R9.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R9.BooleanPulse1.y then 1.0 else R9.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_174()
{
  bool restart174 = true;
  unsigned int iterations174 = 0;
  _algLoop174->getReal(_algloop174Vars );
  bool restatDiscrete174= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop174->evaluate();
          while(restart174 && !(iterations174++>500))
          {
              getConditions(_conditions0174);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver174->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1174);
              restart174 = !std::equal (_conditions1174, _conditions1174+_dimZeroFunc,_conditions0174);
          }
      }
      else
      _algLoopSolver174->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete174=true;
  }
  
  if((restart174&& iterations174 > 0)|| restatDiscrete174)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop174->setReal(_algloop174Vars );
          _algLoopSolver174->solve();
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
equation index: 175
type: SIMPLE_ASSIGN
der(R9._Capacitor1._v) = DIVISION(R9.Capacitor1.i, R9.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_175()
{
   __zDot[14]  = division(_R9_P_Capacitor1_P_i,_R9_P_Capacitor1_P_C,"R9.Capacitor1.C");
}
/*
equation index: 176
type: SIMPLE_ASSIGN
R9._IdealCommutingSwitch2._LossPower = R9.Capacitor1.i * R9.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_176()
{
  _R9_P_IdealCommutingSwitch2_P_LossPower = (_R9_P_Capacitor1_P_i * _R9_P_Capacitor1_P_n_P_v);
}
/*
equation index: 177
type: SIMPLE_ASSIGN
R9._IdealCommutingSwitch1._LossPower = R9.n1.i * C2.v - R9.Capacitor1.i * R9.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_177()
{
  _R9_P_IdealCommutingSwitch1_P_LossPower = ((_R9_P_n1_P_i * __z[1]) - (_R9_P_Capacitor1_P_i * _R9_P_Capacitor1_P_p_P_v));
}
/*
equation index: 178
type: SIMPLE_ASSIGN
$PRE._R9._BooleanPulse1._pulsStart = R9.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_178()
{
  _R9_P_BooleanPulse1_P_pulsStart = _R9_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R9_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 179
type: SIMPLE_ASSIGN
R8._BooleanPulse1._pulsStart = R8.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_179()
{
  _R8_P_BooleanPulse1_P_pulsStart = _R8_P_BooleanPulse1_P_startTime;
}
/*
equation index: 180
type: SIMPLE_ASSIGN
R8._BooleanPulse1._y = time >= R8.BooleanPulse1.pulsStart and time < R8.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_180()
{
  _R8_P_BooleanPulse1_P_y = (getCondition(5) && getCondition(6));
}
/*
equation index: 181
type: LINEAR

<var>R8._n1._i</var>
<var>R8._IdealCommutingSwitch1._s2</var>
<var>R8._Capacitor1._p._v</var>
<var>R8._n2._i</var>
<var>R8._IdealCommutingSwitch2._s1</var>
<var>R8._Capacitor1._n._v</var>
<var>R8._IdealCommutingSwitch2._s2</var>
<var>R8._IdealCommutingSwitch2._n2._i</var>
<var>R8._Capacitor1._i</var>
<var>R8._IdealCommutingSwitch1._n1._i</var>
<var>R8._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R8.Capacitor1.v</cell>
  <cell>C4.v</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R8.BooleanPulse1.y then R8.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R8.BooleanPulse1.y then R8.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R8.BooleanPulse1.y then R8.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R8.BooleanPulse1.y then R8.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R8.BooleanPulse1.y then 1.0 else R8.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_181()
{
  bool restart181 = true;
  unsigned int iterations181 = 0;
  _algLoop181->getReal(_algloop181Vars );
  bool restatDiscrete181= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop181->evaluate();
          while(restart181 && !(iterations181++>500))
          {
              getConditions(_conditions0181);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver181->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1181);
              restart181 = !std::equal (_conditions1181, _conditions1181+_dimZeroFunc,_conditions0181);
          }
      }
      else
      _algLoopSolver181->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete181=true;
  }
  
  if((restart181&& iterations181 > 0)|| restatDiscrete181)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop181->setReal(_algloop181Vars );
          _algLoopSolver181->solve();
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
equation index: 182
type: SIMPLE_ASSIGN
der(R8._Capacitor1._v) = DIVISION(R8.Capacitor1.i, R8.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_182()
{
   __zDot[13]  = division(_R8_P_Capacitor1_P_i,_R8_P_Capacitor1_P_C,"R8.Capacitor1.C");
}
/*
equation index: 183
type: SIMPLE_ASSIGN
Op5._out._i = C9.i - R8.n1.i - R11.n2.i - C4.i
*/
void CauerLowPassSCInitialize::initEquation_183()
{
  _Op5_P_out_P_i = (((_C9_P_i - _R8_P_n1_P_i) - _R11_P_n2_P_i) - _C4_P_i);
}
/*
equation index: 184
type: SIMPLE_ASSIGN
R8._IdealCommutingSwitch2._LossPower = R8.Capacitor1.i * R8.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_184()
{
  _R8_P_IdealCommutingSwitch2_P_LossPower = (_R8_P_Capacitor1_P_i * _R8_P_Capacitor1_P_n_P_v);
}
/*
equation index: 185
type: SIMPLE_ASSIGN
C7._i = (-R9.n2.i) - R8.n2.i
*/
void CauerLowPassSCInitialize::initEquation_185()
{
  _C7_P_i = ((-_R9_P_n2_P_i) - _R8_P_n2_P_i);
}
/*
equation index: 186
type: SIMPLE_ASSIGN
Op4._out._i = C7.i - R10.n1.i - Rp1.n1.i
*/
void CauerLowPassSCInitialize::initEquation_186()
{
  _Op4_P_out_P_i = ((_C7_P_i - _R10_P_n1_P_i) - _Rp1_P_n1_P_i);
}
/*
equation index: 187
type: SIMPLE_ASSIGN
der(C7._v) = DIVISION(C7.i, C7.C)
*/
void CauerLowPassSCInitialize::initEquation_187()
{
   __zDot[4]  = division(_C7_P_i,_C7_P_C,"C7.C");
}
/*
equation index: 188
type: SIMPLE_ASSIGN
R8._IdealCommutingSwitch1._LossPower = R8.n1.i * C4.v - R8.Capacitor1.i * R8.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_188()
{
  _R8_P_IdealCommutingSwitch1_P_LossPower = ((_R8_P_n1_P_i * __z[3]) - (_R8_P_Capacitor1_P_i * _R8_P_Capacitor1_P_p_P_v));
}
/*
equation index: 189
type: SIMPLE_ASSIGN
$PRE._R8._BooleanPulse1._pulsStart = R8.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_189()
{
  _R8_P_BooleanPulse1_P_pulsStart = _R8_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R8_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 190
type: SIMPLE_ASSIGN
R5._BooleanPulse1._pulsStart = R5.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_190()
{
  _R5_P_BooleanPulse1_P_pulsStart = _R5_P_BooleanPulse1_P_startTime;
}
/*
equation index: 191
type: SIMPLE_ASSIGN
R5._BooleanPulse1._y = time >= R5.BooleanPulse1.pulsStart and time < R5.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_191()
{
  _R5_P_BooleanPulse1_P_y = (getCondition(3) && getCondition(4));
}
/*
equation index: 192
type: LINEAR

<var>R5._n1._i</var>
<var>R5._IdealCommutingSwitch1._s2</var>
<var>R5._Capacitor1._p._v</var>
<var>R5._n2._i</var>
<var>R5._IdealCommutingSwitch2._s1</var>
<var>R5._Capacitor1._n._v</var>
<var>R5._IdealCommutingSwitch2._s2</var>
<var>R5._IdealCommutingSwitch2._n2._i</var>
<var>R5._Capacitor1._i</var>
<var>R5._IdealCommutingSwitch1._n1._i</var>
<var>R5._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R5.Capacitor1.v</cell>
  <cell>C2.v</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R5.BooleanPulse1.y then R5.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>-1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R5.BooleanPulse1.y then R5.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R5.BooleanPulse1.y then R5.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R5.BooleanPulse1.y then R5.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R5.BooleanPulse1.y then 1.0 else R5.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_192()
{
  bool restart192 = true;
  unsigned int iterations192 = 0;
  _algLoop192->getReal(_algloop192Vars );
  bool restatDiscrete192= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop192->evaluate();
          while(restart192 && !(iterations192++>500))
          {
              getConditions(_conditions0192);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver192->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1192);
              restart192 = !std::equal (_conditions1192, _conditions1192+_dimZeroFunc,_conditions0192);
          }
      }
      else
      _algLoopSolver192->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete192=true;
  }
  
  if((restart192&& iterations192 > 0)|| restatDiscrete192)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop192->setReal(_algloop192Vars );
          _algLoopSolver192->solve();
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
equation index: 193
type: SIMPLE_ASSIGN
der(R5._Capacitor1._v) = DIVISION(R5.Capacitor1.i, R5.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_193()
{
   __zDot[11]  = division(_R5_P_Capacitor1_P_i,_R5_P_Capacitor1_P_C,"R5.Capacitor1.C");
}
/*
equation index: 194
type: SIMPLE_ASSIGN
Op3._out._i = C6.i - R5.n1.i - R9.n1.i - C2.i - C8.i
*/
void CauerLowPassSCInitialize::initEquation_194()
{
  _Op3_P_out_P_i = ((((_C6_P_i - _R5_P_n1_P_i) - _R9_P_n1_P_i) - _C2_P_i) - _C8_P_i);
}
/*
equation index: 195
type: SIMPLE_ASSIGN
R5._IdealCommutingSwitch2._LossPower = R5.Capacitor1.i * R5.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_195()
{
  _R5_P_IdealCommutingSwitch2_P_LossPower = (_R5_P_Capacitor1_P_i * _R5_P_Capacitor1_P_n_P_v);
}
/*
equation index: 196
type: SIMPLE_ASSIGN
R5._IdealCommutingSwitch1._LossPower = R5.n1.i * C2.v - R5.Capacitor1.i * R5.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_196()
{
  _R5_P_IdealCommutingSwitch1_P_LossPower = ((_R5_P_n1_P_i * __z[1]) - (_R5_P_Capacitor1_P_i * _R5_P_Capacitor1_P_p_P_v));
}
/*
equation index: 197
type: SIMPLE_ASSIGN
$PRE._R5._BooleanPulse1._pulsStart = R5.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_197()
{
  _R5_P_BooleanPulse1_P_pulsStart = _R5_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R5_P_BooleanPulse1_P_pulsStart);
}
/*
equation index: 198
type: SIMPLE_ASSIGN
R4._BooleanPulse1._pulsStart = R4.BooleanPulse1.startTime
*/
void CauerLowPassSCInitialize::initEquation_198()
{
  _R4_P_BooleanPulse1_P_pulsStart = _R4_P_BooleanPulse1_P_startTime;
}
/*
equation index: 199
type: SIMPLE_ASSIGN
R4._BooleanPulse1._y = time >= R4.BooleanPulse1.pulsStart and time < R4.BooleanPulse1.pulsStart + 0.05
*/
void CauerLowPassSCInitialize::initEquation_199()
{
  _R4_P_BooleanPulse1_P_y = (getCondition(1) && getCondition(2));
}
/*
equation index: 200
type: LINEAR

<var>R4._n1._i</var>
<var>R4._IdealCommutingSwitch1._s2</var>
<var>R4._Capacitor1._p._v</var>
<var>R4._n2._i</var>
<var>R4._IdealCommutingSwitch2._s1</var>
<var>R4._Capacitor1._n._v</var>
<var>R4._IdealCommutingSwitch2._s2</var>
<var>R4._IdealCommutingSwitch2._n2._i</var>
<var>R4._Capacitor1._i</var>
<var>R4._Ground1._p._i</var>
<var>R4._IdealCommutingSwitch1._s1</var>
<row>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-0.0</cell>
  <cell>-R4.Capacitor1.v</cell>
  <cell>-C1.v</cell>
  <cell>-0.0</cell>
</row>
<matrix>
  <cell row="0" col="2">
    <residual>1.0</residual>
  </cell><cell row="0" col="10">
    <residual>-(if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch1.Ron)</residual>
  </cell><cell row="1" col="9">
    <residual>-1.0</residual>
  </cell><cell row="1" col="10">
    <residual>if R4.BooleanPulse1.y then R4.IdealCommutingSwitch1.Goff else 1.0</residual>
  </cell><cell row="2" col="0">
    <residual>-1.0</residual>
  </cell><cell row="2" col="8">
    <residual>1.0</residual>
  </cell><cell row="2" col="9">
    <residual>1.0</residual>
  </cell><cell row="3" col="3">
    <residual>-1.0</residual>
  </cell><cell row="3" col="7">
    <residual>-1.0</residual>
  </cell><cell row="3" col="8">
    <residual>-1.0</residual>
  </cell><cell row="4" col="6">
    <residual>if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch2.Goff</residual>
  </cell><cell row="4" col="7">
    <residual>1.0</residual>
  </cell><cell row="5" col="5">
    <residual>1.0</residual>
  </cell><cell row="5" col="6">
    <residual>-(if R4.BooleanPulse1.y then R4.IdealCommutingSwitch2.Ron else 1.0)</residual>
  </cell><cell row="6" col="4">
    <residual>-(if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch2.Ron)</residual>
  </cell><cell row="6" col="5">
    <residual>1.0</residual>
  </cell><cell row="7" col="3">
    <residual>1.0</residual>
  </cell><cell row="7" col="4">
    <residual>if R4.BooleanPulse1.y then R4.IdealCommutingSwitch2.Goff else 1.0</residual>
  </cell><cell row="8" col="2">
    <residual>-1.0</residual>
  </cell><cell row="8" col="5">
    <residual>1.0</residual>
  </cell><cell row="9" col="1">
    <residual>-(if R4.BooleanPulse1.y then R4.IdealCommutingSwitch1.Ron else 1.0)</residual>
  </cell><cell row="9" col="2">
    <residual>1.0</residual>
  </cell><cell row="10" col="0">
    <residual>1.0</residual>
  </cell><cell row="10" col="1">
    <residual>if R4.BooleanPulse1.y then 1.0 else R4.IdealCommutingSwitch1.Goff</residual>
  </cell>
</matrix>
*/
void CauerLowPassSCInitialize::initEquation_200()
{
  bool restart200 = true;
  unsigned int iterations200 = 0;
  _algLoop200->getReal(_algloop200Vars );
  bool restatDiscrete200= false;
  IContinuous::UPDATETYPE calltype = _callType;
  try
  {
   if( _callType == IContinuous::DISCRETE )
      {
          _algLoop200->evaluate();
          while(restart200 && !(iterations200++>500))
          {
              getConditions(_conditions0200);
              _callType = IContinuous::CONTINUOUS;
              _algLoopSolver200->solve();
              _callType = IContinuous::DISCRETE;
              for(int i=0;i<_dimZeroFunc;i++)
              {
                  getCondition(i);
              }
              
              getConditions(_conditions1200);
              restart200 = !std::equal (_conditions1200, _conditions1200+_dimZeroFunc,_conditions0200);
          }
      }
      else
      _algLoopSolver200->solve();
      
  }
  catch(ModelicaSimulationError &ex)
  {
       restatDiscrete200=true;
  }
  
  if((restart200&& iterations200 > 0)|| restatDiscrete200)
  {
      try
      {  //workaround: try to solve algoop discrete (evaluate all zero crossing conditions) since we do not have the information which zercrossing contains a algloop var
          _callType = IContinuous::DISCRETE;
          _algLoop200->setReal(_algloop200Vars );
          _algLoopSolver200->solve();
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
equation index: 201
type: SIMPLE_ASSIGN
der(R4._Capacitor1._v) = DIVISION(R4.Capacitor1.i, R4.Capacitor1.C)
*/
void CauerLowPassSCInitialize::initEquation_201()
{
   __zDot[10]  = division(_R4_P_Capacitor1_P_i,_R4_P_Capacitor1_P_C,"R4.Capacitor1.C");
}
/*
equation index: 202
type: SIMPLE_ASSIGN
Op1._out._i = C1.i - R4.n1.i - C5.i - R3.n2.i
*/
void CauerLowPassSCInitialize::initEquation_202()
{
  _Op1_P_out_P_i = (((_C1_P_i - _R4_P_n1_P_i) - _C5_P_i) - _R3_P_n2_P_i);
}
/*
equation index: 203
type: SIMPLE_ASSIGN
R4._IdealCommutingSwitch2._LossPower = R4.Capacitor1.i * R4.Capacitor1.n.v
*/
void CauerLowPassSCInitialize::initEquation_203()
{
  _R4_P_IdealCommutingSwitch2_P_LossPower = (_R4_P_Capacitor1_P_i * _R4_P_Capacitor1_P_n_P_v);
}
/*
equation index: 204
type: SIMPLE_ASSIGN
C3._i = (-R5.n2.i) - R4.n2.i
*/
void CauerLowPassSCInitialize::initEquation_204()
{
  _C3_P_i = ((-_R5_P_n2_P_i) - _R4_P_n2_P_i);
}
/*
equation index: 205
type: SIMPLE_ASSIGN
Op2._out._i = C3.i - R7.n1.i - R2.n1.i
*/
void CauerLowPassSCInitialize::initEquation_205()
{
  _Op2_P_out_P_i = ((_C3_P_i - _R7_P_n1_P_i) - _R2_P_n1_P_i);
}
/*
equation index: 206
type: SIMPLE_ASSIGN
der(C3._v) = DIVISION(C3.i, C3.C)
*/
void CauerLowPassSCInitialize::initEquation_206()
{
   __zDot[2]  = division(_C3_P_i,_C3_P_C,"C3.C");
}
/*
equation index: 207
type: SIMPLE_ASSIGN
R4._IdealCommutingSwitch1._LossPower = (-R4.n1.i) * C1.v - R4.Capacitor1.i * R4.Capacitor1.p.v
*/
void CauerLowPassSCInitialize::initEquation_207()
{
  _R4_P_IdealCommutingSwitch1_P_LossPower = (((-_R4_P_n1_P_i) * __z[0]) - (_R4_P_Capacitor1_P_i * _R4_P_Capacitor1_P_p_P_v));
}
/*
equation index: 208
type: SIMPLE_ASSIGN
$PRE._R4._BooleanPulse1._pulsStart = R4.BooleanPulse1.pulsStart
*/
void CauerLowPassSCInitialize::initEquation_208()
{
  _R4_P_BooleanPulse1_P_pulsStart = _R4_P_BooleanPulse1_P_pulsStart;
  _discrete_events->save( _R4_P_BooleanPulse1_P_pulsStart);
}
void CauerLowPassSCInitialize::initializeStateVars()
{
               setRealStartValue(  __z[0]  ,0.0);
               setRealStartValue(  __z[1]  ,0.0);
               setRealStartValue(  __z[2]  ,0.0);
               setRealStartValue(  __z[3]  ,0.0);
               setRealStartValue(  __z[4]  ,0.0);
               setRealStartValue(  __z[5]  ,0.0);
               setRealStartValue(  __z[6]  ,0.0);
               setRealStartValue(  __z[7]  ,0.0);
               setRealStartValue(  __z[8]  ,0.0);
               setRealStartValue(  __z[9]  ,0.0);
               setRealStartValue(  __z[10]  ,0.0);
               setRealStartValue(  __z[11]  ,0.0);
               setRealStartValue(  __z[12]  ,0.0);
               setRealStartValue(  __z[13]  ,0.0);
               setRealStartValue(  __z[14]  ,0.0);
               setRealStartValue(  __z[15]  ,0.0);
}
void CauerLowPassSCInitialize::initializeDerVars()
{

             setRealStartValue( __zDot[0] ,0.0);

             setRealStartValue( __zDot[1] ,0.0);

             setRealStartValue( __zDot[2] ,0.0);

             setRealStartValue( __zDot[3] ,0.0);

             setRealStartValue( __zDot[4] ,0.0);

             setRealStartValue( __zDot[5] ,0.0);

             setRealStartValue( __zDot[6] ,0.0);

             setRealStartValue( __zDot[7] ,0.0);

             setRealStartValue( __zDot[8] ,0.0);

             setRealStartValue( __zDot[9] ,0.0);

             setRealStartValue( __zDot[10] ,0.0);

             setRealStartValue( __zDot[11] ,0.0);

             setRealStartValue( __zDot[12] ,0.0);

             setRealStartValue( __zDot[13] ,0.0);

             setRealStartValue( __zDot[14] ,0.0);

             setRealStartValue( __zDot[15] ,0.0);
}