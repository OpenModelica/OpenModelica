

BouncingBallWriteOutput::BouncingBallWriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars)
    : BouncingBall(globalSettings, nonlinsolverfactory, sim_data,sim_vars)
{
  _historyImpl = new HistoryImplType(*globalSettings);
}

BouncingBallWriteOutput::~BouncingBallWriteOutput()
{
  delete _historyImpl;
}

IHistory* BouncingBallWriteOutput::getHistory()
{
  return _historyImpl;
}

void BouncingBallWriteOutput::initialize()
{
   _historyImpl->init();


   _historyImpl->clear();
}

 void BouncingBallWriteOutput::writeOutput(const IWriteOutput::OUTPUT command)
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
 
 void BouncingBallWriteOutput::writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2)
 {
   (*v)(8)=__z[0];
   (*v)(9)=__z[1];
   (*v2)(1)=__zDot[0]; 
   (*v2)(2)=__zDot[1]; 
 }

 
 
 
       void  BouncingBallWriteOutput::writeStateVarsResultNames(vector<string>& names)
       {
       names += "h","v";
       }
       
       void   BouncingBallWriteOutput::writeDerivativeVarsResultNames(vector<string>& names)
       {
        names += "der(h)","der(v)";
       }
       
       
       
       
       void  BouncingBallWriteOutput::writeStateVarsResultDescription(vector<string>& description)
       {
       description += "height of ball","velocity of ball";
       }
       
       void   BouncingBallWriteOutput::writeDerivativeVarsResultDescription(vector<string>& description)
       {
        description += "height of ball","velocity of ball";
       }
       
       
