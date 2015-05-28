    void CauerLowPassSCWriteOutput::writeAlgVarsResultNames(vector<string>& names)
    {
     names += "C1.i","C2.i","C3.i","C4.i","C5.i","C6.i","C7.i","C8.i","C9.i","G.p.i";
      names += "G.p.v","G1.p.i","G1.p.v","G2.p.i","G2.p.v","G3.p.i","G3.p.v","G4.p.i","G4.p.v","Ground1.p.v";
      names += "Op1.in_n.i","Op1.in_p.i","Op1.out.i","Op2.in_n.i","Op2.in_p.i","Op2.out.i","Op3.in_n.i","Op3.in_p.i","Op3.out.i","Op4.in_n.i";
      names += "Op4.in_p.i","Op4.out.i","Op5.in_n.i","Op5.in_p.i","Op5.out.i","R1.Capacitor1.i","R1.Capacitor1.n.v","R1.Capacitor1.p.v","R1.Ground1.p.v","R1.Ground2.p.v";
      names += "R1.IdealCommutingSwitch1.LossPower","R1.IdealCommutingSwitch1.n2.i","R1.IdealCommutingSwitch2.LossPower","R1.IdealCommutingSwitch2.n2.i","R1.n2.i","R10.Capacitor1.i","R10.Capacitor1.n.v","R10.Capacitor1.p.v","R10.Ground1.p.v","R10.Ground2.p.v";
      names += "R10.IdealCommutingSwitch1.LossPower","R10.IdealCommutingSwitch1.n2.i","R10.IdealCommutingSwitch2.LossPower","R10.IdealCommutingSwitch2.n2.i","R10.n1.i","R10.n2.i","R11.Capacitor1.i","R11.Capacitor1.n.v","R11.Capacitor1.p.v","R11.Ground1.p.v";
      names += "R11.Ground2.p.v","R11.IdealCommutingSwitch1.LossPower","R11.IdealCommutingSwitch1.n2.i","R11.IdealCommutingSwitch2.LossPower","R11.IdealCommutingSwitch2.n2.i","R11.n1.i","R11.n2.i","R2.Capacitor1.i","R2.Capacitor1.n.v","R2.Capacitor1.p.v";
      names += "R2.Ground1.p.v","R2.Ground2.p.v","R2.IdealCommutingSwitch1.LossPower","R2.IdealCommutingSwitch1.n2.i","R2.IdealCommutingSwitch2.LossPower","R2.IdealCommutingSwitch2.n2.i","R2.n1.i","R2.n2.i","R3.Capacitor1.i","R3.Capacitor1.n.v";
      names += "R3.Capacitor1.p.v","R3.Ground1.p.v","R3.Ground2.p.v","R3.IdealCommutingSwitch1.LossPower","R3.IdealCommutingSwitch1.n2.i","R3.IdealCommutingSwitch2.LossPower","R3.IdealCommutingSwitch2.n2.i","R3.n1.i","R3.n2.i","R4.Capacitor1.i";
      names += "R4.Capacitor1.n.v","R4.Capacitor1.p.v","R4.Ground1.p.i","R4.Ground1.p.v","R4.Ground2.p.v","R4.IdealCommutingSwitch1.LossPower","R4.IdealCommutingSwitch2.LossPower","R4.IdealCommutingSwitch2.n2.i","R4.n1.i","R4.n2.i";
      names += "R5.Capacitor1.i","R5.Capacitor1.n.v","R5.Capacitor1.p.v","R5.Ground1.p.v","R5.Ground2.p.v","R5.IdealCommutingSwitch1.LossPower","R5.IdealCommutingSwitch1.n1.i","R5.IdealCommutingSwitch2.LossPower","R5.IdealCommutingSwitch2.n2.i","R5.n1.i";
      names += "R5.n2.i","R7.Capacitor1.i","R7.Capacitor1.n.v","R7.Capacitor1.p.v","R7.Ground1.p.v","R7.Ground2.p.v","R7.IdealCommutingSwitch1.LossPower","R7.IdealCommutingSwitch1.n2.i","R7.IdealCommutingSwitch2.LossPower","R7.IdealCommutingSwitch2.n2.i";
      names += "R7.n1.i","R7.n2.i","R8.Capacitor1.i","R8.Capacitor1.n.v","R8.Capacitor1.p.v","R8.Ground1.p.v","R8.Ground2.p.v","R8.IdealCommutingSwitch1.LossPower","R8.IdealCommutingSwitch1.n1.i","R8.IdealCommutingSwitch2.LossPower";
      names += "R8.IdealCommutingSwitch2.n2.i","R8.n1.i","R8.n2.i","R9.Capacitor1.i","R9.Capacitor1.n.v","R9.Capacitor1.p.v","R9.Ground1.p.v","R9.Ground2.p.v","R9.IdealCommutingSwitch1.LossPower","R9.IdealCommutingSwitch1.n1.i";
      names += "R9.IdealCommutingSwitch2.LossPower","R9.IdealCommutingSwitch2.n2.i","R9.n1.i","R9.n2.i","Rp1.Capacitor1.i","Rp1.Capacitor1.n.v","Rp1.Capacitor1.p.v","Rp1.Ground1.p.v","Rp1.Ground2.p.v","Rp1.IdealCommutingSwitch1.LossPower";
      names += "Rp1.IdealCommutingSwitch1.n2.i","Rp1.IdealCommutingSwitch2.LossPower","Rp1.IdealCommutingSwitch2.n2.i","Rp1.n1.i","Rp1.n2.i","V.i","V.v";

    }
    void CauerLowPassSCWriteOutput::writeDiscreteAlgVarsResultNames(vector<string>& names)
    {

    }
    void  CauerLowPassSCWriteOutput::writeIntAlgVarsResultNames(vector<string>& names)
     {
     }
     void CauerLowPassSCWriteOutput::writeBoolAlgVarsResultNames(vector<string>& names)
     {
     names +="$whenCondition1","$whenCondition10","$whenCondition11","$whenCondition2","$whenCondition3","$whenCondition4","$whenCondition5","$whenCondition6","$whenCondition7","$whenCondition8";
      names += "$whenCondition9","R1.BooleanPulse1.y","R10.BooleanPulse1.y","R11.BooleanPulse1.y","R2.BooleanPulse1.y","R3.BooleanPulse1.y","R4.BooleanPulse1.y","R5.BooleanPulse1.y","R7.BooleanPulse1.y","R8.BooleanPulse1.y";
      names += "R9.BooleanPulse1.y","Rp1.BooleanPulse1.y";
     }
    void CauerLowPassSCWriteOutput::writeAlgVarsResultDescription(vector<string>& description)
    {
     description += "Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing from pin p to pin n","Current flowing into the pin";
      description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin";
      description += "Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin";
      description += "Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin";
      description += "Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin";
      description += "Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin";
      description += "Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin";
      description += "Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin";
      description += "Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n";
      description += "Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin";
      description += "Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin";
      description += "Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin";
      description += "Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Loss power leaving component via HeatPort";
      description += "Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort","Current flowing into the pin";
      description += "Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Loss power leaving component via HeatPort";
      description += "Current flowing into the pin","Loss power leaving component via HeatPort","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing from pin p to pin n","Voltage drop between the two pins (= p.v - n.v)";

    }
    void CauerLowPassSCWriteOutput::writeDiscreteAlgVarsResultDescription(vector<string>& description)
    {

    }
    void  CauerLowPassSCWriteOutput::writeIntAlgVarsResultDescription(vector<string>& description)
     {
     }
     void CauerLowPassSCWriteOutput::writeBoolAlgVarsResultDescription(vector<string>& description)
     {
     description +="","","","","","","","","","";
      description += "","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal","Connector of Boolean output signal";
      description += "Connector of Boolean output signal","Connector of Boolean output signal";
     }
     void CauerLowPassSCWriteOutput::writeAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(1)=_C1_P_i;
        (*v)(2)=_C2_P_i;
        (*v)(3)=_C3_P_i;
        (*v)(4)=_C4_P_i;
        (*v)(5)=_C5_P_i;
        (*v)(6)=_C6_P_i;
        (*v)(7)=_C7_P_i;
        (*v)(8)=_C8_P_i;
        (*v)(9)=_C9_P_i;
        (*v)(10)=_G_P_p_P_i;
        (*v)(11)=_G_P_p_P_v;
        (*v)(12)=_G1_P_p_P_i;
        (*v)(13)=_G1_P_p_P_v;
        (*v)(14)=_G2_P_p_P_i;
        (*v)(15)=_G2_P_p_P_v;
        (*v)(16)=_G3_P_p_P_i;
        (*v)(17)=_G3_P_p_P_v;
        (*v)(18)=_G4_P_p_P_i;
        (*v)(19)=_G4_P_p_P_v;
        (*v)(20)=_Ground1_P_p_P_v;
        (*v)(21)=_Op1_P_in_n_P_i;
        (*v)(22)=_Op1_P_in_p_P_i;
        (*v)(23)=_Op1_P_out_P_i;
        (*v)(24)=_Op2_P_in_n_P_i;
        (*v)(25)=_Op2_P_in_p_P_i;
        (*v)(26)=_Op2_P_out_P_i;
        (*v)(27)=_Op3_P_in_n_P_i;
        (*v)(28)=_Op3_P_in_p_P_i;
        (*v)(29)=_Op3_P_out_P_i;
        (*v)(30)=_Op4_P_in_n_P_i;
        (*v)(31)=_Op4_P_in_p_P_i;
        (*v)(32)=_Op4_P_out_P_i;
        (*v)(33)=_Op5_P_in_n_P_i;
        (*v)(34)=_Op5_P_in_p_P_i;
        (*v)(35)=_Op5_P_out_P_i;
        (*v)(36)=_R1_P_Capacitor1_P_i;
        (*v)(37)=_R1_P_Capacitor1_P_n_P_v;
        (*v)(38)=_R1_P_Capacitor1_P_p_P_v;
        (*v)(39)=_R1_P_Ground1_P_p_P_v;
        (*v)(40)=_R1_P_Ground2_P_p_P_v;
        (*v)(41)=_R1_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(42)=_R1_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(43)=_R1_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(44)=_R1_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(45)=_R1_P_n2_P_i;
        (*v)(46)=_R10_P_Capacitor1_P_i;
        (*v)(47)=_R10_P_Capacitor1_P_n_P_v;
        (*v)(48)=_R10_P_Capacitor1_P_p_P_v;
        (*v)(49)=_R10_P_Ground1_P_p_P_v;
        (*v)(50)=_R10_P_Ground2_P_p_P_v;
        (*v)(51)=_R10_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(52)=_R10_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(53)=_R10_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(54)=_R10_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(55)=_R10_P_n1_P_i;
        (*v)(56)=_R10_P_n2_P_i;
        (*v)(57)=_R11_P_Capacitor1_P_i;
        (*v)(58)=_R11_P_Capacitor1_P_n_P_v;
        (*v)(59)=_R11_P_Capacitor1_P_p_P_v;
        (*v)(60)=_R11_P_Ground1_P_p_P_v;
        (*v)(61)=_R11_P_Ground2_P_p_P_v;
        (*v)(62)=_R11_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(63)=_R11_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(64)=_R11_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(65)=_R11_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(66)=_R11_P_n1_P_i;
        (*v)(67)=_R11_P_n2_P_i;
        (*v)(68)=_R2_P_Capacitor1_P_i;
        (*v)(69)=_R2_P_Capacitor1_P_n_P_v;
        (*v)(70)=_R2_P_Capacitor1_P_p_P_v;
        (*v)(71)=_R2_P_Ground1_P_p_P_v;
        (*v)(72)=_R2_P_Ground2_P_p_P_v;
        (*v)(73)=_R2_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(74)=_R2_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(75)=_R2_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(76)=_R2_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(77)=_R2_P_n1_P_i;
        (*v)(78)=_R2_P_n2_P_i;
        (*v)(79)=_R3_P_Capacitor1_P_i;
        (*v)(80)=_R3_P_Capacitor1_P_n_P_v;
        (*v)(81)=_R3_P_Capacitor1_P_p_P_v;
        (*v)(82)=_R3_P_Ground1_P_p_P_v;
        (*v)(83)=_R3_P_Ground2_P_p_P_v;
        (*v)(84)=_R3_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(85)=_R3_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(86)=_R3_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(87)=_R3_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(88)=_R3_P_n1_P_i;
        (*v)(89)=_R3_P_n2_P_i;
        (*v)(90)=_R4_P_Capacitor1_P_i;
        (*v)(91)=_R4_P_Capacitor1_P_n_P_v;
        (*v)(92)=_R4_P_Capacitor1_P_p_P_v;
        (*v)(93)=_R4_P_Ground1_P_p_P_i;
        (*v)(94)=_R4_P_Ground1_P_p_P_v;
        (*v)(95)=_R4_P_Ground2_P_p_P_v;
        (*v)(96)=_R4_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(97)=_R4_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(98)=_R4_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(99)=_R4_P_n1_P_i;
        (*v)(100)=_R4_P_n2_P_i;
     }
     void CauerLowPassSCWriteOutput::writeAlgVarsValues_1(HistoryImplType::value_type_v *v)
     {
        (*v)(101)=_R5_P_Capacitor1_P_i;
        (*v)(102)=_R5_P_Capacitor1_P_n_P_v;
        (*v)(103)=_R5_P_Capacitor1_P_p_P_v;
        (*v)(104)=_R5_P_Ground1_P_p_P_v;
        (*v)(105)=_R5_P_Ground2_P_p_P_v;
        (*v)(106)=_R5_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(107)=_R5_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(108)=_R5_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(109)=_R5_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(110)=_R5_P_n1_P_i;
        (*v)(111)=_R5_P_n2_P_i;
        (*v)(112)=_R7_P_Capacitor1_P_i;
        (*v)(113)=_R7_P_Capacitor1_P_n_P_v;
        (*v)(114)=_R7_P_Capacitor1_P_p_P_v;
        (*v)(115)=_R7_P_Ground1_P_p_P_v;
        (*v)(116)=_R7_P_Ground2_P_p_P_v;
        (*v)(117)=_R7_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(118)=_R7_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(119)=_R7_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(120)=_R7_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(121)=_R7_P_n1_P_i;
        (*v)(122)=_R7_P_n2_P_i;
        (*v)(123)=_R8_P_Capacitor1_P_i;
        (*v)(124)=_R8_P_Capacitor1_P_n_P_v;
        (*v)(125)=_R8_P_Capacitor1_P_p_P_v;
        (*v)(126)=_R8_P_Ground1_P_p_P_v;
        (*v)(127)=_R8_P_Ground2_P_p_P_v;
        (*v)(128)=_R8_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(129)=_R8_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(130)=_R8_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(131)=_R8_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(132)=_R8_P_n1_P_i;
        (*v)(133)=_R8_P_n2_P_i;
        (*v)(134)=_R9_P_Capacitor1_P_i;
        (*v)(135)=_R9_P_Capacitor1_P_n_P_v;
        (*v)(136)=_R9_P_Capacitor1_P_p_P_v;
        (*v)(137)=_R9_P_Ground1_P_p_P_v;
        (*v)(138)=_R9_P_Ground2_P_p_P_v;
        (*v)(139)=_R9_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(140)=_R9_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(141)=_R9_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(142)=_R9_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(143)=_R9_P_n1_P_i;
        (*v)(144)=_R9_P_n2_P_i;
        (*v)(145)=_Rp1_P_Capacitor1_P_i;
        (*v)(146)=_Rp1_P_Capacitor1_P_n_P_v;
        (*v)(147)=_Rp1_P_Capacitor1_P_p_P_v;
        (*v)(148)=_Rp1_P_Ground1_P_p_P_v;
        (*v)(149)=_Rp1_P_Ground2_P_p_P_v;
        (*v)(150)=_Rp1_P_IdealCommutingSwitch1_P_LossPower;
        (*v)(151)=_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(152)=_Rp1_P_IdealCommutingSwitch2_P_LossPower;
        (*v)(153)=_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(154)=_Rp1_P_n1_P_i;
        (*v)(155)=_Rp1_P_n2_P_i;
        (*v)(156)=_V_P_i;
        (*v)(157)=_V_P_v;
     }
     
     void CauerLowPassSCWriteOutput::writeAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 157
       CauerLowPassSCWriteOutput::writeAlgVarsValues_0(v);CauerLowPassSCWriteOutput::writeAlgVarsValues_1(v);
     }
     
     void CauerLowPassSCWriteOutput::writeDiscreteAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     
     void CauerLowPassSCWriteOutput::writeIntAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     void CauerLowPassSCWriteOutput::writeBoolAlgVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(158)=_$whenCondition1;
        (*v)(159)=_$whenCondition10;
        (*v)(160)=_$whenCondition11;
        (*v)(161)=_$whenCondition2;
        (*v)(162)=_$whenCondition3;
        (*v)(163)=_$whenCondition4;
        (*v)(164)=_$whenCondition5;
        (*v)(165)=_$whenCondition6;
        (*v)(166)=_$whenCondition7;
        (*v)(167)=_$whenCondition8;
        (*v)(168)=_$whenCondition9;
        (*v)(169)=_R1_P_BooleanPulse1_P_y;
        (*v)(170)=_R10_P_BooleanPulse1_P_y;
        (*v)(171)=_R11_P_BooleanPulse1_P_y;
        (*v)(172)=_R2_P_BooleanPulse1_P_y;
        (*v)(173)=_R3_P_BooleanPulse1_P_y;
        (*v)(174)=_R4_P_BooleanPulse1_P_y;
        (*v)(175)=_R5_P_BooleanPulse1_P_y;
        (*v)(176)=_R7_P_BooleanPulse1_P_y;
        (*v)(177)=_R8_P_BooleanPulse1_P_y;
        (*v)(178)=_R9_P_BooleanPulse1_P_y;
        (*v)(179)=_Rp1_P_BooleanPulse1_P_y;
     }
     
     void CauerLowPassSCWriteOutput::writeBoolAlgVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 22
       CauerLowPassSCWriteOutput::writeBoolAlgVarsValues_0(v);
     }

