     void CauerLowPassSCWriteOutput::writeBoolAliasVarsResultNames(vector<string>& names)
     {
       names += "R1.IdealCommutingSwitch1.control","R1.IdealCommutingSwitch2.control","R10.IdealCommutingSwitch1.control","R10.IdealCommutingSwitch2.control","R11.IdealCommutingSwitch1.control","R11.IdealCommutingSwitch2.control","R2.IdealCommutingSwitch1.control","R2.IdealCommutingSwitch2.control","R3.IdealCommutingSwitch1.control","R3.IdealCommutingSwitch2.control";
        names += "R4.IdealCommutingSwitch1.control","R4.IdealCommutingSwitch2.control","R5.IdealCommutingSwitch1.control","R5.IdealCommutingSwitch2.control","R7.IdealCommutingSwitch1.control","R7.IdealCommutingSwitch2.control","R8.IdealCommutingSwitch1.control","R8.IdealCommutingSwitch2.control","R9.IdealCommutingSwitch1.control","R9.IdealCommutingSwitch2.control";
        names += "Rp1.IdealCommutingSwitch1.control","Rp1.IdealCommutingSwitch2.control";
     }
     void  CauerLowPassSCWriteOutput::writeAliasVarsResultNames(vector<string>& names)
     {
      names +="C1.n.i","C1.n.v","C1.p.i","C1.p.v","C2.n.i","C2.n.v","C2.p.i","C2.p.v","C3.n.i","C3.n.v";
       names += "C3.p.i","C3.p.v","C4.n.i","C4.n.v","C4.p.i","C4.p.v","C5.n.i","C5.n.v","C5.p.i","C5.p.v";
       names += "C5.v","C6.n.i","C6.n.v","C6.p.i","C6.p.v","C6.v","C7.n.i","C7.n.v","C7.p.i","C7.p.v";
       names += "C8.n.i","C8.n.v","C8.p.i","C8.p.v","C8.v","C9.n.i","C9.n.v","C9.p.i","C9.p.v","C9.v";
       names += "Ground1.p.i","Op1.in_n.v","Op1.in_p.v","Op1.out.v","Op2.in_n.v","Op2.in_p.v","Op2.out.v","Op3.in_n.v","Op3.in_p.v","Op3.out.v";
       names += "Op4.in_n.v","Op4.in_p.v","Op4.out.v","Op5.in_n.v","Op5.in_p.v","Op5.out.v","R1.Capacitor1.n.i","R1.Capacitor1.p.i","R1.Ground1.p.i","R1.Ground2.p.i";
       names += "R1.IdealCommutingSwitch1.T_heatPort","R1.IdealCommutingSwitch1.n1.i","R1.IdealCommutingSwitch1.n1.v","R1.IdealCommutingSwitch1.n2.v","R1.IdealCommutingSwitch1.p.i","R1.IdealCommutingSwitch1.p.v","R1.IdealCommutingSwitch2.T_heatPort","R1.IdealCommutingSwitch2.n1.i","R1.IdealCommutingSwitch2.n1.v","R1.IdealCommutingSwitch2.n2.v";
       names += "R1.IdealCommutingSwitch2.p.i","R1.IdealCommutingSwitch2.p.v","R1.n1.i","R1.n1.v","R1.n2.v","R10.Capacitor1.n.i","R10.Capacitor1.p.i","R10.Ground1.p.i","R10.Ground2.p.i","R10.IdealCommutingSwitch1.T_heatPort";
       names += "R10.IdealCommutingSwitch1.n1.i","R10.IdealCommutingSwitch1.n1.v","R10.IdealCommutingSwitch1.n2.v","R10.IdealCommutingSwitch1.p.i","R10.IdealCommutingSwitch1.p.v","R10.IdealCommutingSwitch2.T_heatPort","R10.IdealCommutingSwitch2.n1.i","R10.IdealCommutingSwitch2.n1.v","R10.IdealCommutingSwitch2.n2.v","R10.IdealCommutingSwitch2.p.i";
       names += "R10.IdealCommutingSwitch2.p.v","R10.n1.v","R10.n2.v","R11.Capacitor1.n.i","R11.Capacitor1.p.i","R11.Ground1.p.i","R11.Ground2.p.i","R11.IdealCommutingSwitch1.T_heatPort","R11.IdealCommutingSwitch1.n1.i","R11.IdealCommutingSwitch1.n1.v";
       names += "R11.IdealCommutingSwitch1.n2.v","R11.IdealCommutingSwitch1.p.i","R11.IdealCommutingSwitch1.p.v","R11.IdealCommutingSwitch2.T_heatPort","R11.IdealCommutingSwitch2.n1.i","R11.IdealCommutingSwitch2.n1.v","R11.IdealCommutingSwitch2.n2.v","R11.IdealCommutingSwitch2.p.i","R11.IdealCommutingSwitch2.p.v","R11.n1.v";
       names += "R11.n2.v","R2.Capacitor1.n.i","R2.Capacitor1.p.i","R2.Ground1.p.i","R2.Ground2.p.i","R2.IdealCommutingSwitch1.T_heatPort","R2.IdealCommutingSwitch1.n1.i","R2.IdealCommutingSwitch1.n1.v","R2.IdealCommutingSwitch1.n2.v","R2.IdealCommutingSwitch1.p.i";
       names += "R2.IdealCommutingSwitch1.p.v","R2.IdealCommutingSwitch2.T_heatPort","R2.IdealCommutingSwitch2.n1.i","R2.IdealCommutingSwitch2.n1.v","R2.IdealCommutingSwitch2.n2.v","R2.IdealCommutingSwitch2.p.i","R2.IdealCommutingSwitch2.p.v","R2.n1.v","R2.n2.v","R3.Capacitor1.n.i";
       names += "R3.Capacitor1.p.i","R3.Ground1.p.i","R3.Ground2.p.i","R3.IdealCommutingSwitch1.T_heatPort","R3.IdealCommutingSwitch1.n1.i","R3.IdealCommutingSwitch1.n1.v","R3.IdealCommutingSwitch1.n2.v","R3.IdealCommutingSwitch1.p.i","R3.IdealCommutingSwitch1.p.v","R3.IdealCommutingSwitch2.T_heatPort";
       names += "R3.IdealCommutingSwitch2.n1.i","R3.IdealCommutingSwitch2.n1.v","R3.IdealCommutingSwitch2.n2.v","R3.IdealCommutingSwitch2.p.i","R3.IdealCommutingSwitch2.p.v","R3.n1.v","R3.n2.v","R4.Capacitor1.n.i","R4.Capacitor1.p.i","R4.Ground2.p.i";
       names += "R4.IdealCommutingSwitch1.T_heatPort","R4.IdealCommutingSwitch1.n1.i","R4.IdealCommutingSwitch1.n1.v","R4.IdealCommutingSwitch1.n2.i","R4.IdealCommutingSwitch1.n2.v","R4.IdealCommutingSwitch1.p.i","R4.IdealCommutingSwitch1.p.v","R4.IdealCommutingSwitch2.T_heatPort","R4.IdealCommutingSwitch2.n1.i","R4.IdealCommutingSwitch2.n1.v";
       names += "R4.IdealCommutingSwitch2.n2.v","R4.IdealCommutingSwitch2.p.i","R4.IdealCommutingSwitch2.p.v","R4.n1.v","R4.n2.v","R5.Capacitor1.n.i","R5.Capacitor1.p.i","R5.Ground1.p.i","R5.Ground2.p.i","R5.IdealCommutingSwitch1.T_heatPort";
       names += "R5.IdealCommutingSwitch1.n1.v","R5.IdealCommutingSwitch1.n2.i","R5.IdealCommutingSwitch1.n2.v","R5.IdealCommutingSwitch1.p.i","R5.IdealCommutingSwitch1.p.v","R5.IdealCommutingSwitch2.T_heatPort","R5.IdealCommutingSwitch2.n1.i","R5.IdealCommutingSwitch2.n1.v","R5.IdealCommutingSwitch2.n2.v","R5.IdealCommutingSwitch2.p.i";
       names += "R5.IdealCommutingSwitch2.p.v","R5.n1.v","R5.n2.v","R7.Capacitor1.n.i","R7.Capacitor1.p.i","R7.Ground1.p.i","R7.Ground2.p.i","R7.IdealCommutingSwitch1.T_heatPort","R7.IdealCommutingSwitch1.n1.i","R7.IdealCommutingSwitch1.n1.v";
       names += "R7.IdealCommutingSwitch1.n2.v","R7.IdealCommutingSwitch1.p.i","R7.IdealCommutingSwitch1.p.v","R7.IdealCommutingSwitch2.T_heatPort","R7.IdealCommutingSwitch2.n1.i","R7.IdealCommutingSwitch2.n1.v","R7.IdealCommutingSwitch2.n2.v","R7.IdealCommutingSwitch2.p.i","R7.IdealCommutingSwitch2.p.v","R7.n1.v";
       names += "R7.n2.v","R8.Capacitor1.n.i","R8.Capacitor1.p.i","R8.Ground1.p.i","R8.Ground2.p.i","R8.IdealCommutingSwitch1.T_heatPort","R8.IdealCommutingSwitch1.n1.v","R8.IdealCommutingSwitch1.n2.i","R8.IdealCommutingSwitch1.n2.v","R8.IdealCommutingSwitch1.p.i";
       names += "R8.IdealCommutingSwitch1.p.v","R8.IdealCommutingSwitch2.T_heatPort","R8.IdealCommutingSwitch2.n1.i","R8.IdealCommutingSwitch2.n1.v","R8.IdealCommutingSwitch2.n2.v","R8.IdealCommutingSwitch2.p.i","R8.IdealCommutingSwitch2.p.v","R8.n1.v","R8.n2.v","R9.Capacitor1.n.i";
       names += "R9.Capacitor1.p.i","R9.Ground1.p.i","R9.Ground2.p.i","R9.IdealCommutingSwitch1.T_heatPort","R9.IdealCommutingSwitch1.n1.v","R9.IdealCommutingSwitch1.n2.i","R9.IdealCommutingSwitch1.n2.v","R9.IdealCommutingSwitch1.p.i","R9.IdealCommutingSwitch1.p.v","R9.IdealCommutingSwitch2.T_heatPort";
       names += "R9.IdealCommutingSwitch2.n1.i","R9.IdealCommutingSwitch2.n1.v","R9.IdealCommutingSwitch2.n2.v","R9.IdealCommutingSwitch2.p.i","R9.IdealCommutingSwitch2.p.v","R9.n1.v","R9.n2.v","Rp1.Capacitor1.n.i","Rp1.Capacitor1.p.i","Rp1.Ground1.p.i";
       names += "Rp1.Ground2.p.i","Rp1.IdealCommutingSwitch1.T_heatPort","Rp1.IdealCommutingSwitch1.n1.i","Rp1.IdealCommutingSwitch1.n1.v","Rp1.IdealCommutingSwitch1.n2.v","Rp1.IdealCommutingSwitch1.p.i","Rp1.IdealCommutingSwitch1.p.v","Rp1.IdealCommutingSwitch2.T_heatPort","Rp1.IdealCommutingSwitch2.n1.i","Rp1.IdealCommutingSwitch2.n1.v";
       names += "Rp1.IdealCommutingSwitch2.n2.v","Rp1.IdealCommutingSwitch2.p.i","Rp1.IdealCommutingSwitch2.p.v","Rp1.n1.v","Rp1.n2.v","V.n.i","V.n.v","V.p.i","V.p.v","V.signalSource.y";
     }
     
     void   CauerLowPassSCWriteOutput::writeIntAliasVarsResultNames(vector<string>& names)
     {
     }
     
     
     
     
     
     void  CauerLowPassSCWriteOutput::writeAliasVarsResultDescription(vector<string>& description)
     {
      description +="Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
       description += "Voltage drop between the two pins (= p.v - n.v)","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Voltage drop between the two pins (= p.v - n.v)";
       description += "Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin";
       description += "Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin";
       description += "Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin";
       description += "Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort";
       description += "Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin";
       description += "Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin";
       description += "Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin";
       description += "Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort";
       description += "Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin";
       description += "Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin";
       description += "Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin";
       description += "Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin";
       description += "Current flowing into the pin","Current flowing into the pin","Current flowing into the pin","Temperature of HeatPort","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort";
       description += "Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Current flowing into the pin","Current flowing into the pin";
       description += "Current flowing into the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Temperature of HeatPort","Current flowing into the pin","Potential at the pin";
       description += "Potential at the pin","Current flowing into the pin","Potential at the pin","Potential at the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Current flowing into the pin","Potential at the pin","Connector of Real output signal";
     }
     
    void   CauerLowPassSCWriteOutput::writeIntAliasVarsResultDescription(vector<string>& description)
     {
     }
     
     void CauerLowPassSCWriteOutput::writeBoolAliasVarsResultDescription(vector<string>& description)
     {
       description += "true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected";
        description += "true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected";
        description += "true => p--n2 connected, false => p--n1 connected","true => p--n2 connected, false => p--n1 connected";
     }
     void CauerLowPassSCWriteOutput::writeAliasVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(180) = -_C1_P_i;
        (*v)(181) = -  __z[0]  ;
        (*v)(182) = _C1_P_i;
        (*v)(183) = _G_P_p_P_v;
        (*v)(184) = -_C2_P_i;
        (*v)(185) = _G_P_p_P_v;
        (*v)(186) = _C2_P_i;
        (*v)(187) =   __z[1]  ;
        (*v)(188) = -_C3_P_i;
        (*v)(189) = -  __z[2]  ;
        (*v)(190) = _C3_P_i;
        (*v)(191) = _G1_P_p_P_v;
        (*v)(192) = -_C4_P_i;
        (*v)(193) = _G2_P_p_P_v;
        (*v)(194) = _C4_P_i;
        (*v)(195) =   __z[3]  ;
        (*v)(196) = -_C5_P_i;
        (*v)(197) = _G2_P_p_P_v;
        (*v)(198) = _C5_P_i;
        (*v)(199) = -  __z[0]  ;
        (*v)(200) = -  __z[0]  ;
        (*v)(201) = -_C6_P_i;
        (*v)(202) =   __z[1]  ;
        (*v)(203) = _C6_P_i;
        (*v)(204) = _G2_P_p_P_v;
        (*v)(205) = -  __z[1]  ;
        (*v)(206) = -_C7_P_i;
        (*v)(207) = -  __z[4]  ;
        (*v)(208) = _C7_P_i;
        (*v)(209) = _G3_P_p_P_v;
        (*v)(210) = -_C8_P_i;
        (*v)(211) = _G4_P_p_P_v;
        (*v)(212) = _C8_P_i;
        (*v)(213) =   __z[1]  ;
        (*v)(214) =   __z[1]  ;
        (*v)(215) = -_C9_P_i;
        (*v)(216) =   __z[3]  ;
        (*v)(217) = _C9_P_i;
        (*v)(218) = _G4_P_p_P_v;
        (*v)(219) = -  __z[3]  ;
        (*v)(220) = -_V_P_i;
        (*v)(221) = _G_P_p_P_v;
        (*v)(222) = _G_P_p_P_v;
        (*v)(223) = -  __z[0]  ;
        (*v)(224) = _G1_P_p_P_v;
        (*v)(225) = _G1_P_p_P_v;
        (*v)(226) = -  __z[2]  ;
        (*v)(227) = _G2_P_p_P_v;
        (*v)(228) = _G2_P_p_P_v;
        (*v)(229) =   __z[1]  ;
        (*v)(230) = _G3_P_p_P_v;
        (*v)(231) = _G3_P_p_P_v;
        (*v)(232) = -  __z[4]  ;
        (*v)(233) = _G4_P_p_P_v;
        (*v)(234) = _G4_P_p_P_v;
        (*v)(235) =   __z[3]  ;
        (*v)(236) = -_R1_P_Capacitor1_P_i;
        (*v)(237) = _R1_P_Capacitor1_P_i;
        (*v)(238) = -_R1_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(239) = -_R1_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(240) = _R1_P_IdealCommutingSwitch1_P_T;
        (*v)(241) = _V_P_i;
        (*v)(242) = -_V_P_v;
        (*v)(243) = _R1_P_Ground1_P_p_P_v;
        (*v)(244) = -_R1_P_Capacitor1_P_i;
        (*v)(245) = _R1_P_Capacitor1_P_p_P_v;
        (*v)(246) = _R1_P_IdealCommutingSwitch2_P_T;
        (*v)(247) = _R1_P_n2_P_i;
        (*v)(248) = _G_P_p_P_v;
        (*v)(249) = _R1_P_Ground2_P_p_P_v;
        (*v)(250) = _R1_P_Capacitor1_P_i;
        (*v)(251) = _R1_P_Capacitor1_P_n_P_v;
        (*v)(252) = _V_P_i;
        (*v)(253) = -_V_P_v;
        (*v)(254) = _G_P_p_P_v;
        (*v)(255) = -_R10_P_Capacitor1_P_i;
        (*v)(256) = _R10_P_Capacitor1_P_i;
        (*v)(257) = -_R10_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(258) = -_R10_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(259) = _R10_P_IdealCommutingSwitch1_P_T;
        (*v)(260) = _R10_P_n1_P_i;
        (*v)(261) = -  __z[4]  ;
        (*v)(262) = _R10_P_Ground1_P_p_P_v;
        (*v)(263) = -_R10_P_Capacitor1_P_i;
        (*v)(264) = _R10_P_Capacitor1_P_p_P_v;
        (*v)(265) = _R10_P_IdealCommutingSwitch2_P_T;
        (*v)(266) = _R10_P_n2_P_i;
        (*v)(267) = _G4_P_p_P_v;
        (*v)(268) = _R10_P_Ground2_P_p_P_v;
        (*v)(269) = _R10_P_Capacitor1_P_i;
        (*v)(270) = _R10_P_Capacitor1_P_n_P_v;
        (*v)(271) = -  __z[4]  ;
        (*v)(272) = _G4_P_p_P_v;
        (*v)(273) = -_R11_P_Capacitor1_P_i;
        (*v)(274) = _R11_P_Capacitor1_P_i;
        (*v)(275) = -_R11_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(276) = -_R11_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(277) = _R11_P_IdealCommutingSwitch1_P_T;
        (*v)(278) = _R11_P_n1_P_i;
        (*v)(279) = _G4_P_p_P_v;
     }
     void CauerLowPassSCWriteOutput::writeAliasVarsValues_1(HistoryImplType::value_type_v *v)
     {
        (*v)(280) = _R11_P_Ground1_P_p_P_v;
        (*v)(281) = -_R11_P_Capacitor1_P_i;
        (*v)(282) = _R11_P_Capacitor1_P_p_P_v;
        (*v)(283) = _R11_P_IdealCommutingSwitch2_P_T;
        (*v)(284) = _R11_P_n2_P_i;
        (*v)(285) =   __z[3]  ;
        (*v)(286) = _R11_P_Ground2_P_p_P_v;
        (*v)(287) = _R11_P_Capacitor1_P_i;
        (*v)(288) = _R11_P_Capacitor1_P_n_P_v;
        (*v)(289) = _G4_P_p_P_v;
        (*v)(290) =   __z[3]  ;
        (*v)(291) = -_R2_P_Capacitor1_P_i;
        (*v)(292) = _R2_P_Capacitor1_P_i;
        (*v)(293) = -_R2_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(294) = -_R2_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(295) = _R2_P_IdealCommutingSwitch1_P_T;
        (*v)(296) = _R2_P_n1_P_i;
        (*v)(297) = -  __z[2]  ;
        (*v)(298) = _R2_P_Ground1_P_p_P_v;
        (*v)(299) = -_R2_P_Capacitor1_P_i;
        (*v)(300) = _R2_P_Capacitor1_P_p_P_v;
        (*v)(301) = _R2_P_IdealCommutingSwitch2_P_T;
        (*v)(302) = _R2_P_n2_P_i;
        (*v)(303) = _G_P_p_P_v;
        (*v)(304) = _R2_P_Ground2_P_p_P_v;
        (*v)(305) = _R2_P_Capacitor1_P_i;
        (*v)(306) = _R2_P_Capacitor1_P_n_P_v;
        (*v)(307) = -  __z[2]  ;
        (*v)(308) = _G_P_p_P_v;
        (*v)(309) = -_R3_P_Capacitor1_P_i;
        (*v)(310) = _R3_P_Capacitor1_P_i;
        (*v)(311) = -_R3_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(312) = -_R3_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(313) = _R3_P_IdealCommutingSwitch1_P_T;
        (*v)(314) = _R3_P_n1_P_i;
        (*v)(315) = _G_P_p_P_v;
        (*v)(316) = _R3_P_Ground1_P_p_P_v;
        (*v)(317) = -_R3_P_Capacitor1_P_i;
        (*v)(318) = _R3_P_Capacitor1_P_p_P_v;
        (*v)(319) = _R3_P_IdealCommutingSwitch2_P_T;
        (*v)(320) = _R3_P_n2_P_i;
        (*v)(321) = -  __z[0]  ;
        (*v)(322) = _R3_P_Ground2_P_p_P_v;
        (*v)(323) = _R3_P_Capacitor1_P_i;
        (*v)(324) = _R3_P_Capacitor1_P_n_P_v;
        (*v)(325) = _G_P_p_P_v;
        (*v)(326) = -  __z[0]  ;
        (*v)(327) = -_R4_P_Capacitor1_P_i;
        (*v)(328) = _R4_P_Capacitor1_P_i;
        (*v)(329) = -_R4_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(330) = _R4_P_IdealCommutingSwitch1_P_T;
        (*v)(331) = -_R4_P_Ground1_P_p_P_i;
        (*v)(332) = _R4_P_Ground1_P_p_P_v;
        (*v)(333) = _R4_P_n1_P_i;
        (*v)(334) = -  __z[0]  ;
        (*v)(335) = -_R4_P_Capacitor1_P_i;
        (*v)(336) = _R4_P_Capacitor1_P_p_P_v;
        (*v)(337) = _R4_P_IdealCommutingSwitch2_P_T;
        (*v)(338) = _R4_P_n2_P_i;
        (*v)(339) = _G1_P_p_P_v;
        (*v)(340) = _R4_P_Ground2_P_p_P_v;
        (*v)(341) = _R4_P_Capacitor1_P_i;
        (*v)(342) = _R4_P_Capacitor1_P_n_P_v;
        (*v)(343) = -  __z[0]  ;
        (*v)(344) = _G1_P_p_P_v;
        (*v)(345) = -_R5_P_Capacitor1_P_i;
        (*v)(346) = _R5_P_Capacitor1_P_i;
        (*v)(347) = -_R5_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(348) = -_R5_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(349) = _R5_P_IdealCommutingSwitch1_P_T;
        (*v)(350) = _R5_P_Ground1_P_p_P_v;
        (*v)(351) = _R5_P_n1_P_i;
        (*v)(352) =   __z[1]  ;
        (*v)(353) = -_R5_P_Capacitor1_P_i;
        (*v)(354) = _R5_P_Capacitor1_P_p_P_v;
        (*v)(355) = _R5_P_IdealCommutingSwitch2_P_T;
        (*v)(356) = _R5_P_n2_P_i;
        (*v)(357) = _G1_P_p_P_v;
        (*v)(358) = _R5_P_Ground2_P_p_P_v;
        (*v)(359) = _R5_P_Capacitor1_P_i;
        (*v)(360) = _R5_P_Capacitor1_P_n_P_v;
        (*v)(361) =   __z[1]  ;
        (*v)(362) = _G1_P_p_P_v;
        (*v)(363) = -_R7_P_Capacitor1_P_i;
        (*v)(364) = _R7_P_Capacitor1_P_i;
        (*v)(365) = -_R7_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(366) = -_R7_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(367) = _R7_P_IdealCommutingSwitch1_P_T;
        (*v)(368) = _R7_P_n1_P_i;
        (*v)(369) = -  __z[2]  ;
        (*v)(370) = _R7_P_Ground1_P_p_P_v;
        (*v)(371) = -_R7_P_Capacitor1_P_i;
        (*v)(372) = _R7_P_Capacitor1_P_p_P_v;
        (*v)(373) = _R7_P_IdealCommutingSwitch2_P_T;
        (*v)(374) = _R7_P_n2_P_i;
        (*v)(375) = _G2_P_p_P_v;
        (*v)(376) = _R7_P_Ground2_P_p_P_v;
        (*v)(377) = _R7_P_Capacitor1_P_i;
        (*v)(378) = _R7_P_Capacitor1_P_n_P_v;
        (*v)(379) = -  __z[2]  ;
     }
     void CauerLowPassSCWriteOutput::writeAliasVarsValues_2(HistoryImplType::value_type_v *v)
     {
        (*v)(380) = _G2_P_p_P_v;
        (*v)(381) = -_R8_P_Capacitor1_P_i;
        (*v)(382) = _R8_P_Capacitor1_P_i;
        (*v)(383) = -_R8_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(384) = -_R8_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(385) = _R8_P_IdealCommutingSwitch1_P_T;
        (*v)(386) = _R8_P_Ground1_P_p_P_v;
        (*v)(387) = _R8_P_n1_P_i;
        (*v)(388) =   __z[3]  ;
        (*v)(389) = -_R8_P_Capacitor1_P_i;
        (*v)(390) = _R8_P_Capacitor1_P_p_P_v;
        (*v)(391) = _R8_P_IdealCommutingSwitch2_P_T;
        (*v)(392) = _R8_P_n2_P_i;
        (*v)(393) = _G3_P_p_P_v;
        (*v)(394) = _R8_P_Ground2_P_p_P_v;
        (*v)(395) = _R8_P_Capacitor1_P_i;
        (*v)(396) = _R8_P_Capacitor1_P_n_P_v;
        (*v)(397) =   __z[3]  ;
        (*v)(398) = _G3_P_p_P_v;
        (*v)(399) = -_R9_P_Capacitor1_P_i;
        (*v)(400) = _R9_P_Capacitor1_P_i;
        (*v)(401) = -_R9_P_IdealCommutingSwitch1_P_n1_P_i;
        (*v)(402) = -_R9_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(403) = _R9_P_IdealCommutingSwitch1_P_T;
        (*v)(404) = _R9_P_Ground1_P_p_P_v;
        (*v)(405) = _R9_P_n1_P_i;
        (*v)(406) =   __z[1]  ;
        (*v)(407) = -_R9_P_Capacitor1_P_i;
        (*v)(408) = _R9_P_Capacitor1_P_p_P_v;
        (*v)(409) = _R9_P_IdealCommutingSwitch2_P_T;
        (*v)(410) = _R9_P_n2_P_i;
        (*v)(411) = _G3_P_p_P_v;
        (*v)(412) = _R9_P_Ground2_P_p_P_v;
        (*v)(413) = _R9_P_Capacitor1_P_i;
        (*v)(414) = _R9_P_Capacitor1_P_n_P_v;
        (*v)(415) =   __z[1]  ;
        (*v)(416) = _G3_P_p_P_v;
        (*v)(417) = -_Rp1_P_Capacitor1_P_i;
        (*v)(418) = _Rp1_P_Capacitor1_P_i;
        (*v)(419) = -_Rp1_P_IdealCommutingSwitch1_P_n2_P_i;
        (*v)(420) = -_Rp1_P_IdealCommutingSwitch2_P_n2_P_i;
        (*v)(421) = _Rp1_P_IdealCommutingSwitch1_P_T;
        (*v)(422) = _Rp1_P_n1_P_i;
        (*v)(423) = -  __z[4]  ;
        (*v)(424) = _Rp1_P_Ground1_P_p_P_v;
        (*v)(425) = -_Rp1_P_Capacitor1_P_i;
        (*v)(426) = _Rp1_P_Capacitor1_P_p_P_v;
        (*v)(427) = _Rp1_P_IdealCommutingSwitch2_P_T;
        (*v)(428) = _Rp1_P_n2_P_i;
        (*v)(429) = _G2_P_p_P_v;
        (*v)(430) = _Rp1_P_Ground2_P_p_P_v;
        (*v)(431) = _Rp1_P_Capacitor1_P_i;
        (*v)(432) = _Rp1_P_Capacitor1_P_n_P_v;
        (*v)(433) = -  __z[4]  ;
        (*v)(434) = _G2_P_p_P_v;
        (*v)(435) = -_V_P_i;
        (*v)(436) = -_V_P_v;
        (*v)(437) = _V_P_i;
        (*v)(438) = _Ground1_P_p_P_v;
        (*v)(439) = _V_P_v;
     }
     
     void CauerLowPassSCWriteOutput::writeAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 260
       CauerLowPassSCWriteOutput::writeAliasVarsValues_0(v);CauerLowPassSCWriteOutput::writeAliasVarsValues_1(v);CauerLowPassSCWriteOutput::writeAliasVarsValues_2(v);
     }
     
     void CauerLowPassSCWriteOutput::writeIntAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 0
     }
     void CauerLowPassSCWriteOutput::writeBoolAliasVarsValues_0(HistoryImplType::value_type_v *v)
     {
        (*v)(440) = _R1_P_BooleanPulse1_P_y;
        (*v)(441) = _R1_P_BooleanPulse1_P_y;
        (*v)(442) = _R10_P_BooleanPulse1_P_y;
        (*v)(443) = _R10_P_BooleanPulse1_P_y;
        (*v)(444) = _R11_P_BooleanPulse1_P_y;
        (*v)(445) = _R11_P_BooleanPulse1_P_y;
        (*v)(446) = _R2_P_BooleanPulse1_P_y;
        (*v)(447) = _R2_P_BooleanPulse1_P_y;
        (*v)(448) = _R3_P_BooleanPulse1_P_y;
        (*v)(449) = _R3_P_BooleanPulse1_P_y;
        (*v)(450) = _R4_P_BooleanPulse1_P_y;
        (*v)(451) = _R4_P_BooleanPulse1_P_y;
        (*v)(452) = _R5_P_BooleanPulse1_P_y;
        (*v)(453) = _R5_P_BooleanPulse1_P_y;
        (*v)(454) = _R7_P_BooleanPulse1_P_y;
        (*v)(455) = _R7_P_BooleanPulse1_P_y;
        (*v)(456) = _R8_P_BooleanPulse1_P_y;
        (*v)(457) = _R8_P_BooleanPulse1_P_y;
        (*v)(458) = _R9_P_BooleanPulse1_P_y;
        (*v)(459) = _R9_P_BooleanPulse1_P_y;
        (*v)(460) = _Rp1_P_BooleanPulse1_P_y;
        (*v)(461) = _Rp1_P_BooleanPulse1_P_y;
     }
     
     void CauerLowPassSCWriteOutput::writeBoolAliasVarsValues(HistoryImplType::value_type_v *v)
     {
       //number of vars: 22
       CauerLowPassSCWriteOutput::writeBoolAliasVarsValues_0(v);
     }
     
     
