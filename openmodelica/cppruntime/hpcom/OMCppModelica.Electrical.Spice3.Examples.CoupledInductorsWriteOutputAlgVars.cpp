    void CoupledInductorsWriteOutput::writeAlgVarsResultNames(vector<string>& names)
    {
     names += "C1.i","C2.i","L1.ICP.di","L1.ICP.v","L1.v","L2.ICP.di","L2.ICP.v","L2.v","L3.ICP.di","L3.ICP.v";
      names += "L3.v","R1.v","R2.v","R3.i","R4.v","R5.i","ground.p.i","ground.p.v","k1.M","k1.inductiveCouplePin1.v";
      names += "k1.inductiveCouplePin2.v","k2.M","k2.inductiveCouplePin1.v","k2.inductiveCouplePin2.v","k3.M","k3.inductiveCouplePin1.v","k3.inductiveCouplePin2.v","sineVoltage.v";

    }
    void CoupledInductorsWriteOutput::writeDiscreteAlgVarsResultNames(vector<string>& names)
    {

    }
    void  CoupledInductorsWriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
     {
     }
     void CoupledInductorsWriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
     {
     }
    void CoupledInductorsWriteOutput::writeAlgVarsResultDescription(vector<string>& description)
    {
     description += "Current flowing from pin p to pin n","Current flowing from pin p to pin n","di/dt","","Voltage drop between the two pins (= p.v - n.v)","di/dt","","Voltage drop between the two pins (= p.v - n.v)","di/dt","";
      description += "Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Voltage drop between the two pins (= p.v - n.v)","Current flowing from pin p to pin n","Voltage drop between the two pins (= p.v - n.v)","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","mutual inductance","";
      description += "","mutual inductance","","","mutual inductance","","","Voltage drop between the two pins (= p.v - n.v)";

    }
    void CoupledInductorsWriteOutput::writeDiscreteAlgVarsResultDescription(vector<string>& description)
    {

    }
    void  CoupledInductorsWriteOutput::writeIntAlgVarsResultDescription(vector<string>& description)
     {
     }
     void CoupledInductorsWriteOutput::writeBoolAlgVarsResultDescription(vector<string>& description)
     {
     }
     void CoupledInductorsWriteOutput::writeAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(1)=_C1_P_i;
        (*v)(2)=_C2_P_i;
        (*v)(3)=_L1_P_ICP_P_di;
        (*v)(4)=_L1_P_ICP_P_v;
        (*v)(5)=_L1_P_v;
        (*v)(6)=_L2_P_ICP_P_di;
        (*v)(7)=_L2_P_ICP_P_v;
        (*v)(8)=_L2_P_v;
        (*v)(9)=_L3_P_ICP_P_di;
        (*v)(10)=_L3_P_ICP_P_v;
        (*v)(11)=_L3_P_v;
        (*v)(12)=_R1_P_v;
        (*v)(13)=_R2_P_v;
        (*v)(14)=_R3_P_i;
        (*v)(15)=_R4_P_v;
        (*v)(16)=_R5_P_i;
        (*v)(17)=_ground_P_p_P_i;
        (*v)(18)=_ground_P_p_P_v;
        (*v)(19)=_k1_P_M;
        (*v)(20)=_k1_P_inductiveCouplePin1_P_v;
        (*v)(21)=_k1_P_inductiveCouplePin2_P_v;
        (*v)(22)=_k2_P_M;
        (*v)(23)=_k2_P_inductiveCouplePin1_P_v;
        (*v)(24)=_k2_P_inductiveCouplePin2_P_v;
        (*v)(25)=_k3_P_M;
        (*v)(26)=_k3_P_inductiveCouplePin1_P_v;
        (*v)(27)=_k3_P_inductiveCouplePin2_P_v;
        (*v)(28)=_sineVoltage_P_v;
     }
     
     void CoupledInductorsWriteOutput::writeAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 28
       CoupledInductorsWriteOutput::writeAlgVarsValues_0(v);
     }
     
     void CoupledInductorsWriteOutput::writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     
     void CoupledInductorsWriteOutput::writeIntAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     
     void CoupledInductorsWriteOutput::writeBoolAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }

