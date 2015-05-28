

CoupledInductorsWriteOutput::CoupledInductorsWriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : CoupledInductors(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
  _historyImpl = new HistoryImplType(*globalSettings);
}

CoupledInductorsWriteOutput::~CoupledInductorsWriteOutput()
{
  delete _historyImpl;
}

IHistory* CoupledInductorsWriteOutput::getHistory()
{
  return _historyImpl;
}

void CoupledInductorsWriteOutput::initialize()
{
   _historyImpl->init();


   _historyImpl->clear();
}

 void CoupledInductorsWriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
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
 
 void CoupledInductorsWriteOutput::writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2)
 {
   (*v)(99)=__z[0];
   (*v)(100)=__z[1];
   (*v)(101)=__z[2];
   (*v)(102)=__z[3];
   (*v)(103)=__z[4];
   (*v2)(1)=__zDot[0]; 
   (*v2)(2)=__zDot[1]; 
   (*v2)(3)=__zDot[2]; 
   (*v2)(4)=__zDot[3]; 
   (*v2)(5)=__zDot[4]; 
 }

 
 
 
       void  CoupledInductorsWriteOutput::writeStateVarsResultNames(vector<string>& names)
       {
       names += "C1.vinternal","C2.vinternal","L1.iinternal","L2.iinternal","L3.iinternal";
       }
       
       void   CoupledInductorsWriteOutput::writeDerivativeVarsResultNames(vector<string>& names)
       {
        names += "der(C1.vinternal)","der(C2.vinternal)","der(L1.iinternal)","der(L2.iinternal)","der(L3.iinternal)";
       }
       
       
       
       
       void  CoupledInductorsWriteOutput::writeStateVarsResultDescription(vector<string>& description)
       {
       description += "","","","","";
       }
       
       void   CoupledInductorsWriteOutput::writeDerivativeVarsResultDescription(vector<string>& description)
       {
        description += "","","","","";
       }
       
       
