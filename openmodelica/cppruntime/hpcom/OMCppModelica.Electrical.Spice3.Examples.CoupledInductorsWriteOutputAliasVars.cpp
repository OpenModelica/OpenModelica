     void CoupledInductorsWriteOutput::writeBoolAliasVarsResultNames(vector<string>& names)
     {
     }
     void  CoupledInductorsWriteOutput::writeAliasVarsResultNames(vector<string>& names)
     {
      names +="C1.n.i","C1.n.v","C1.p.i","C1.p.v","C1.v","C2.n.i","C2.n.v","C2.p.i","C2.p.v","C2.v";
       names += "L1.ICP.L","L1.i","L1.n.i","L1.n.v","L1.p.i","L1.p.v","L2.ICP.L","L2.i","L2.n.i","L2.n.v";
       names += "L2.p.i","L2.p.v","L3.ICP.L","L3.i","L3.n.i","L3.n.v","L3.p.i","L3.p.v","R1.i","R1.n.i";
       names += "R1.n.v","R1.p.i","R1.p.v","R2.i","R2.n.i","R2.n.v","R2.p.i","R2.p.v","R3.n.i","R3.n.v";
       names += "R3.p.i","R3.p.v","R3.v","R4.i","R4.n.i","R4.n.v","R4.p.i","R4.p.v","R5.n.i","R5.n.v";
       names += "R5.p.i","R5.p.v","R5.v","k1.inductiveCouplePin1.L","k1.inductiveCouplePin1.di","k1.inductiveCouplePin2.L","k1.inductiveCouplePin2.di","k2.inductiveCouplePin1.L","k2.inductiveCouplePin1.di","k2.inductiveCouplePin2.L";
       names += "k2.inductiveCouplePin2.di","k3.inductiveCouplePin1.L","k3.inductiveCouplePin1.di","k3.inductiveCouplePin2.L","k3.inductiveCouplePin2.di","sineVoltage.i","sineVoltage.n.i","sineVoltage.n.v","sineVoltage.p.i","sineVoltage.p.v";
     }
     
     void   CoupledInductorsWriteOutput::writeIntAliasVarsResultNames(vector<string>& names)
     {
     }
     
     
     
     
     
     void  CoupledInductorsWriteOutput::writeAliasVarsResultDescription(vector<string>& description)
     {
      description +="Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)";
       description += "","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing from pin p to pin n","Current flowing into the pin";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)","","di/dt","","di/dt","","di/dt","";
       description += "di/dt","","di/dt","","di/dt","Current flowing from pin p to pin n","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
     }
     
    void   CoupledInductorsWriteOutput::writeIntAliasVarsResultDescription(vector<string>& description)
     {
     }
     
     void CoupledInductorsWriteOutput::writeBoolAliasVarsResultDescription(vector<string>& description)
     {
     }
     void CoupledInductorsWriteOutput::writeAliasVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(29) = -_C1_P_i;
        (*v)(30) = _ground_P_p_P_v;
        (*v)(31) = _C1_P_i;
        (*v)(32) =   __z[0]  ;
        (*v)(33) =   __z[0]  ;
        (*v)(34) = -_C2_P_i;
        (*v)(35) = _ground_P_p_P_v;
        (*v)(36) = _C2_P_i;
        (*v)(37) =   __z[1]  ;
        (*v)(38) =   __z[1]  ;
        (*v)(39) = _L1_P_L;
        (*v)(40) =   __z[2]  ;
        (*v)(41) = -  __z[2]  ;
        (*v)(42) = _ground_P_p_P_v;
        (*v)(43) =   __z[2]  ;
        (*v)(44) = _L1_P_v;
        (*v)(45) = _L2_P_L;
        (*v)(46) =   __z[3]  ;
        (*v)(47) = -  __z[3]  ;
        (*v)(48) = _ground_P_p_P_v;
        (*v)(49) =   __z[3]  ;
        (*v)(50) = _L2_P_v;
        (*v)(51) = _L3_P_L;
        (*v)(52) =   __z[4]  ;
        (*v)(53) = -  __z[4]  ;
        (*v)(54) = _ground_P_p_P_v;
        (*v)(55) =   __z[4]  ;
        (*v)(56) = _L3_P_v;
        (*v)(57) =   __z[2]  ;
        (*v)(58) = -  __z[2]  ;
        (*v)(59) = _L1_P_v;
        (*v)(60) =   __z[2]  ;
        (*v)(61) = _sineVoltage_P_v;
        (*v)(62) =   __z[3]  ;
        (*v)(63) = -  __z[3]  ;
        (*v)(64) = _L2_P_v;
        (*v)(65) =   __z[3]  ;
        (*v)(66) =   __z[0]  ;
        (*v)(67) = -_R3_P_i;
        (*v)(68) = _ground_P_p_P_v;
        (*v)(69) = _R3_P_i;
        (*v)(70) =   __z[0]  ;
        (*v)(71) =   __z[0]  ;
        (*v)(72) =   __z[4]  ;
        (*v)(73) = -  __z[4]  ;
        (*v)(74) = _L3_P_v;
        (*v)(75) =   __z[4]  ;
        (*v)(76) =   __z[1]  ;
        (*v)(77) = -_R5_P_i;
        (*v)(78) = _ground_P_p_P_v;
        (*v)(79) = _R5_P_i;
        (*v)(80) =   __z[1]  ;
        (*v)(81) =   __z[1]  ;
        (*v)(82) = _L1_P_L;
        (*v)(83) = _L1_P_ICP_P_di;
        (*v)(84) = _L2_P_L;
        (*v)(85) = _L2_P_ICP_P_di;
        (*v)(86) = _L1_P_L;
        (*v)(87) = _L1_P_ICP_P_di;
        (*v)(88) = _L3_P_L;
        (*v)(89) = _L3_P_ICP_P_di;
        (*v)(90) = _L3_P_L;
        (*v)(91) = _L3_P_ICP_P_di;
        (*v)(92) = _L2_P_L;
        (*v)(93) = _L2_P_ICP_P_di;
        (*v)(94) = -  __z[2]  ;
        (*v)(95) =   __z[2]  ;
        (*v)(96) = _ground_P_p_P_v;
        (*v)(97) = -  __z[2]  ;
        (*v)(98) = _sineVoltage_P_v;
     }
     
     void CoupledInductorsWriteOutput::writeAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 70
       CoupledInductorsWriteOutput::writeAliasVarsValues_0(v);
     }
     
     void CoupledInductorsWriteOutput::writeIntAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     
     void CoupledInductorsWriteOutput::writeBoolAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     
     
