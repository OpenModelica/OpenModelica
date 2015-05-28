#pragma once
typedef HistoryImpl<MatFileWriter,28+0+0+0+70+0+0+5,5,0,28> HistoryImplType;

/*****************************************************************************
*
* Simulation code to write simulation file
*
*****************************************************************************/

class CoupledInductorsWriteOutput : virtual public CoupledInductors
{
public:
  CoupledInductorsWriteOutput(IGlobalSettings* globalSettings, boost::shared_ptr<IAlgLoopSolverFactory> nonlinsolverfactory, boost::shared_ptr<ISimData> sim_data, boost::shared_ptr<ISimVars> sim_vars);
  virtual ~CoupledInductorsWriteOutput();
  
  
  /// Output routine (to be called by the solver after every successful integration step)
  virtual void writeOutput(const IWriteOutput::OUTPUT command = IWriteOutput::UNDEF_OUTPUT);
  virtual IHistory* getHistory();
  
protected:
  void initialize();
 private:
      void writeParams(HistoryImplType::value_type_p& params);
      void writeParamsReal_0(HistoryImplType::value_type_p& params );
      void writeParamsReal(HistoryImplType::value_type_p& params  );
      void writeParamsInt(HistoryImplType::value_type_p& params  );
      void writeParamsBool_0(HistoryImplType::value_type_p& params  );
      void writeParamsBool(HistoryImplType::value_type_p& params  );
      
      
      void writeAlgVarsValues(HistoryImplType::value_type_v *v);
      void writeAlgVarsValues_0(HistoryImplType::value_type_v *v);
      void writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v);
      void writeIntAlgVarsValues(HistoryImplType::value_type_v *v);
      void writeBoolAlgVarsValues(HistoryImplType::value_type_v *v);
      void writeAliasVarsValues(HistoryImplType::value_type_v *v);
      void writeAliasVarsValues_0(HistoryImplType::value_type_v *v);
      void writeIntAliasVarsValues(HistoryImplType::value_type_v *v);
      void writeBoolAliasVarsValues(HistoryImplType::value_type_v *v);
      void writeStateValues(HistoryImplType::value_type_v *v, HistoryImplType::value_type_dv *v2);
      
  
  void writeAlgVarsResultNames(vector<string>& names);
  void writeDiscreteAlgVarsResultNames(vector<string>& names);
  void writeIntAlgVarsResultNames(vector<string>& names);
  void writeBoolAlgVarsResultNames(vector<string>& names);
  void writeAliasVarsResultNames(vector<string>& names);
  void writeIntAliasVarsResultNames(vector<string>& names);
  void writeBoolAliasVarsResultNames(vector<string>& names);
  void writeStateVarsResultNames(vector<string>& names);
  void writeDerivativeVarsResultNames(vector<string>& names);
  void writeParametertNames(vector<string>& names);
  void writeIntParameterNames(vector<string>& names);
  void writeBoolParameterNames(vector<string>& names);
  
  void writeAlgVarsResultDescription(vector<string>& names);
  void writeDiscreteAlgVarsResultDescription(vector<string>& names);
  void writeIntAlgVarsResultDescription(vector<string>& names);
  void writeBoolAlgVarsResultDescription(vector<string>& names);
  void writeAliasVarsResultDescription(vector<string>& names);
  void writeIntAliasVarsResultDescription(vector<string>& names);
  void writeBoolAliasVarsResultDescription(vector<string>& names);
  void writeStateVarsResultDescription(vector<string>& names);
  void writeDerivativeVarsResultDescription(vector<string>& names);
  void writeParameterDescription(vector<string>& names);
  void writeIntParameterDescription(vector<string>& names);
  void writeBoolParameterDescription(vector<string>& names);
  
  HistoryImplType* _historyImpl;
};