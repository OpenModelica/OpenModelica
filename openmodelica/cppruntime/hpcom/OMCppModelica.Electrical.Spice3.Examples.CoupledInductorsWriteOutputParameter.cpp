     void   CoupledInductorsWriteOutput::writeParametertNames(vector<string>& names)
     {
      /*workarround ced*/
     
      names += "C1.C","C1.IC","C2.C","C2.IC","L1.IC","L1.L","L2.IC","L2.L","L3.IC","L3.L";
       names += "R1.R","R2.R","R3.R","R4.R","R5.R","k1.k","k2.k","k3.k","sineVoltage.FREQ","sineVoltage.TD";
       names += "sineVoltage.THETA","sineVoltage.VA","sineVoltage.VO";

     }
     
      void   CoupledInductorsWriteOutput::writeIntParameterNames(vector<string>& names)
     {
     }
      void   CoupledInductorsWriteOutput::writeBoolParameterNames(vector<string>& names)
     {
      names += "C1.UIC","C2.UIC","L1.UIC","L2.UIC","L3.UIC";
     }
     void   CoupledInductorsWriteOutput::writeParameterDescription(vector<string>& names)
     {
      /*workarround ced*/
      names += "Capacitance","Initial value","Capacitance","Initial value","Initial value; used, if UIC is true","Inductance","Initial value; used, if UIC is true","Inductance","Initial value; used, if UIC is true","Inductance";
       names += "Resistance","Resistance","Resistance","Resistance","Resistance","Coupling Factor","Coupling Factor","Coupling Factor","Frequency","Delay";
       names += "Damping factor","Amplitude","Offset";

     }
     
      void   CoupledInductorsWriteOutput::writeIntParameterDescription(vector<string>& names)
     {
     }
     
      void   CoupledInductorsWriteOutput::writeBoolParameterDescription(vector<string>& names)
     {
      names += "Use initial conditions: true, if initial condition is used","Use initial conditions: true, if initial condition is used","Use initial conditions","Use initial conditions","Use initial conditions";
     }
     void CoupledInductorsWriteOutput::writeParams(HistoryImplType::value_type_p& params)
     {
      /*const int paramVarsStart = 1;
      const int intParamVarsStart  = paramVarsStart       + 23;
      const int boolparamVarsStart    = intParamVarsStart  + 0;
      */
      writeParamsReal(params);
      writeParamsInt(params);
      writeParamsBool(params);
     }
     void CoupledInductorsWriteOutput::writeParamsReal_0( HistoryImplType::value_type_p& params  )
     {
        params(1)=_C1_P_C;params(2)=_C1_P_IC;params(3)=_C2_P_C;params(4)=_C2_P_IC;params(5)=_L1_P_IC;params(6)=_L1_P_L;params(7)=_L2_P_IC;params(8)=_L2_P_L;
        params(9)=_L3_P_IC;params(10)=_L3_P_L;params(11)=_R1_P_R;params(12)=_R2_P_R;params(13)=_R3_P_R;params(14)=_R4_P_R;params(15)=_R5_P_R;params(16)=_k1_P_k;
        params(17)=_k2_P_k;params(18)=_k3_P_k;params(19)=_sineVoltage_P_FREQ;params(20)=_sineVoltage_P_TD;params(21)=_sineVoltage_P_THETA;params(22)=_sineVoltage_P_VA;params(23)=_sineVoltage_P_VO;
     }
     
     void CoupledInductorsWriteOutput::writeParamsReal(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 23
       CoupledInductorsWriteOutput::writeParamsReal_0(params);
     }
     
     void CoupledInductorsWriteOutput::writeParamsInt(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 0
     }
     void CoupledInductorsWriteOutput::writeParamsBool_0( HistoryImplType::value_type_p& params  )
     {
        params(24)=_C1_P_UIC;params(25)=_C2_P_UIC;params(26)=_L1_P_UIC;params(27)=_L2_P_UIC;params(28)=_L3_P_UIC;
     }
     
     void CoupledInductorsWriteOutput::writeParamsBool(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 5
       CoupledInductorsWriteOutput::writeParamsBool_0(params);
     }