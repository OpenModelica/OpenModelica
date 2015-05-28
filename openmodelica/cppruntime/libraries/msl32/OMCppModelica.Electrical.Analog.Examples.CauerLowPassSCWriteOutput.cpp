/* #include <Core/Modelica.h>
#include <Core/ModelicaDefine.h>
#include "OMCppModelica.Electrical.Analog.Examples.CauerLowPassSCWriteOutput.h" */

CauerLowPassSCWriteOutput::CauerLowPassSCWriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CauerLowPassSC(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
  _historyImpl = new HistoryImplType(*globalSettings);
}

CauerLowPassSCWriteOutput::~CauerLowPassSCWriteOutput()
{
  delete _historyImpl;
}

IHistory* CauerLowPassSCWriteOutput::getHistory()
{
  return _historyImpl;
}

void CauerLowPassSCWriteOutput::initialize()
{
   _historyImpl->init();


   _historyImpl->clear();
}

 void CauerLowPassSCWriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
 {
  //Write head line
  if (command & IWriteOutput::HEAD_LINE)
  {
    vector<string> varsnames;
    vector<string> vardescs;
    vector<string> paramnames;
    vector<string> paramdecs;
    writeAlgVarsResultNames(varsnames);
    writeDiscreteAlgVarsResultNames(varsnames);
    writeIntAlgVarsResultNames(varsnames);
    writeBoolAlgVarsResultNames(varsnames);
    writeAliasVarsResultNames(varsnames);
    writeIntAliasVarsResultNames(varsnames);
    writeBoolAliasVarsResultNames(varsnames);
    writeStateVarsResultNames(varsnames);
    writeDerivativeVarsResultNames(varsnames);
 
    writeParametertNames(paramnames);
    writeIntParameterNames(paramnames);
    writeBoolParameterNames(paramnames);
    writeAlgVarsResultDescription(vardescs);
    writeDiscreteAlgVarsResultDescription(vardescs);
    writeIntAlgVarsResultDescription(vardescs);
    writeBoolAlgVarsResultDescription(vardescs);
    writeAliasVarsResultDescription(vardescs);
    writeIntAliasVarsResultDescription(vardescs);
    writeBoolAliasVarsResultDescription(vardescs);
    writeStateVarsResultDescription(vardescs);
    writeDerivativeVarsResultDescription(vardescs);
    writeParameterDescription(paramdecs);
    writeIntParameterDescription(paramdecs);
    writeBoolParameterDescription(paramdecs);
    _historyImpl->write(varsnames,vardescs,paramnames,paramdecs);
      HistoryImplType::value_type_p params;
    
      writeParams(params);
     _historyImpl->write(params,_global_settings->getStartTime(),_global_settings->getEndTime());
  }
  //Write the current values
  else
  {
    /* HistoryImplType::value_type_v v;
    HistoryImplType::value_type_dv v2; */
    
    boost::shared_ptr<HistoryImplType::values_type> container = _historyImpl->getFreeContainer();
    boost::shared_ptr<HistoryImplType::value_type_v> v = container->get<0>();
     boost::shared_ptr<HistoryImplType::value_type_dv> v2 = container->get<1>();
    container->get<2>() = _simTime;
    
    writeAlgVarsValues(v.get());
    writeDiscreteAlgVarsValues(v.get());
    writeIntAlgVarsValues(v.get());
    writeBoolAlgVarsValues(v.get());
    writeAliasVarsValues(v.get());
    writeIntAliasVarsValues(v.get());
    writeBoolAliasVarsValues(v.get());
    writeStateValues(v.get(),v2.get());
    
    
    //_historyImpl->write(v,v2,_simTime);
    _historyImpl->addContainerToWriteQueue(container);
  }
 }
 
 void CauerLowPassSCWriteOutput::writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2)
 {
   (*v)(462)=__z[0];
   (*v)(463)=__z[1];
   (*v)(464)=__z[2];
   (*v)(465)=__z[3];
   (*v)(466)=__z[4];
   (*v)(467)=__z[5];
   (*v)(468)=__z[6];
   (*v)(469)=__z[7];
   (*v)(470)=__z[8];
   (*v)(471)=__z[9];
   (*v)(472)=__z[10];
   (*v)(473)=__z[11];
   (*v)(474)=__z[12];
   (*v)(475)=__z[13];
   (*v)(476)=__z[14];
   (*v)(477)=__z[15];
   (*v2)(1)=__zDot[0]; 
   (*v2)(2)=__zDot[1]; 
   (*v2)(3)=__zDot[2]; 
   (*v2)(4)=__zDot[3]; 
   (*v2)(5)=__zDot[4]; 
   (*v2)(6)=__zDot[5]; 
   (*v2)(7)=__zDot[6]; 
   (*v2)(8)=__zDot[7]; 
   (*v2)(9)=__zDot[8]; 
   (*v2)(10)=__zDot[9]; 
   (*v2)(11)=__zDot[10]; 
   (*v2)(12)=__zDot[11]; 
   (*v2)(13)=__zDot[12]; 
   (*v2)(14)=__zDot[13]; 
   (*v2)(15)=__zDot[14]; 
   (*v2)(16)=__zDot[15]; 
 }

 
 
 
       void  CauerLowPassSCWriteOutput::writeStateVarsResultNames(vector<string>& names)
       {
       names += "C1.v","C2.v","C3.v","C4.v","C7.v","R1.Capacitor1.v","R10.Capacitor1.v","R11.Capacitor1.v","R2.Capacitor1.v","R3.Capacitor1.v";
        names += "R4.Capacitor1.v","R5.Capacitor1.v","R7.Capacitor1.v","R8.Capacitor1.v","R9.Capacitor1.v","Rp1.Capacitor1.v";
       }
       
       void   CauerLowPassSCWriteOutput::writeDerivativeVarsResultNames(vector<string>& names)
       {
        names += "der(C1.v)","der(C2.v)","der(C3.v)","der(C4.v)","der(C7.v)","der(R1.Capacitor1.v)","der(R10.Capacitor1.v)","der(R11.Capacitor1.v)","der(R2.Capacitor1.v)","der(R3.Capacitor1.v)";
         names += "der(R4.Capacitor1.v)","der(R5.Capacitor1.v)","der(R7.Capacitor1.v)","der(R8.Capacitor1.v)","der(R9.Capacitor1.v)","der(Rp1.Capacitor1.v)";
       }
       
       
       
       
       void  CauerLowPassSCWriteOutput::writeStateVarsResultDescription(vector<string>& description)
       {
       description += "Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)";
        description += "Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)";
       }
       
       void   CauerLowPassSCWriteOutput::writeDerivativeVarsResultDescription(vector<string>& description)
       {
        description += "Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)";
         description += "Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)";
       }
       
       
