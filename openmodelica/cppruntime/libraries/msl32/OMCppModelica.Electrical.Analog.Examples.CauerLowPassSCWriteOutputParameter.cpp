     void   CauerLowPassSCWriteOutput::writeParametertNames(vector<string>& names)
     {
      /*workarround ced*/
     
      names += "C1.C","C2.C","C3.C","C4.C","C5.C","C6.C","C7.C","C8.C","C9.C","R1.BooleanPulse1.period";
       names += "R1.BooleanPulse1.startTime","R1.BooleanPulse1.width","R1.Capacitor1.C","R1.IdealCommutingSwitch1.Goff","R1.IdealCommutingSwitch1.Ron","R1.IdealCommutingSwitch1.T","R1.IdealCommutingSwitch2.Goff","R1.IdealCommutingSwitch2.Ron","R1.IdealCommutingSwitch2.T","R1.R";
       names += "R1.clock","R10.BooleanPulse1.period","R10.BooleanPulse1.startTime","R10.BooleanPulse1.width","R10.Capacitor1.C","R10.IdealCommutingSwitch1.Goff","R10.IdealCommutingSwitch1.Ron","R10.IdealCommutingSwitch1.T","R10.IdealCommutingSwitch2.Goff","R10.IdealCommutingSwitch2.Ron";
       names += "R10.IdealCommutingSwitch2.T","R10.R","R10.clock","R11.BooleanPulse1.period","R11.BooleanPulse1.startTime","R11.BooleanPulse1.width","R11.Capacitor1.C","R11.IdealCommutingSwitch1.Goff","R11.IdealCommutingSwitch1.Ron","R11.IdealCommutingSwitch1.T";
       names += "R11.IdealCommutingSwitch2.Goff","R11.IdealCommutingSwitch2.Ron","R11.IdealCommutingSwitch2.T","R11.R","R11.clock","R2.BooleanPulse1.period","R2.BooleanPulse1.startTime","R2.BooleanPulse1.width","R2.Capacitor1.C","R2.IdealCommutingSwitch1.Goff";
       names += "R2.IdealCommutingSwitch1.Ron","R2.IdealCommutingSwitch1.T","R2.IdealCommutingSwitch2.Goff","R2.IdealCommutingSwitch2.Ron","R2.IdealCommutingSwitch2.T","R2.R","R2.clock","R3.BooleanPulse1.period","R3.BooleanPulse1.startTime","R3.BooleanPulse1.width";
       names += "R3.Capacitor1.C","R3.IdealCommutingSwitch1.Goff","R3.IdealCommutingSwitch1.Ron","R3.IdealCommutingSwitch1.T","R3.IdealCommutingSwitch2.Goff","R3.IdealCommutingSwitch2.Ron","R3.IdealCommutingSwitch2.T","R3.R","R3.clock","R4.BooleanPulse1.period";
       names += "R4.BooleanPulse1.startTime","R4.BooleanPulse1.width","R4.Capacitor1.C","R4.IdealCommutingSwitch1.Goff","R4.IdealCommutingSwitch1.Ron","R4.IdealCommutingSwitch1.T","R4.IdealCommutingSwitch2.Goff","R4.IdealCommutingSwitch2.Ron","R4.IdealCommutingSwitch2.T","R4.R";
       names += "R4.clock","R5.BooleanPulse1.period","R5.BooleanPulse1.startTime","R5.BooleanPulse1.width","R5.Capacitor1.C","R5.IdealCommutingSwitch1.Goff","R5.IdealCommutingSwitch1.Ron","R5.IdealCommutingSwitch1.T","R5.IdealCommutingSwitch2.Goff","R5.IdealCommutingSwitch2.Ron";
       names += "R5.IdealCommutingSwitch2.T","R5.R","R5.clock","R7.BooleanPulse1.period","R7.BooleanPulse1.startTime","R7.BooleanPulse1.width","R7.Capacitor1.C","R7.IdealCommutingSwitch1.Goff","R7.IdealCommutingSwitch1.Ron","R7.IdealCommutingSwitch1.T";
       names += "R7.IdealCommutingSwitch2.Goff","R7.IdealCommutingSwitch2.Ron","R7.IdealCommutingSwitch2.T","R7.R","R7.clock","R8.BooleanPulse1.period","R8.BooleanPulse1.startTime","R8.BooleanPulse1.width","R8.Capacitor1.C","R8.IdealCommutingSwitch1.Goff";
       names += "R8.IdealCommutingSwitch1.Ron","R8.IdealCommutingSwitch1.T","R8.IdealCommutingSwitch2.Goff","R8.IdealCommutingSwitch2.Ron","R8.IdealCommutingSwitch2.T","R8.R","R8.clock","R9.BooleanPulse1.period","R9.BooleanPulse1.startTime","R9.BooleanPulse1.width";
       names += "R9.Capacitor1.C","R9.IdealCommutingSwitch1.Goff","R9.IdealCommutingSwitch1.Ron","R9.IdealCommutingSwitch1.T","R9.IdealCommutingSwitch2.Goff","R9.IdealCommutingSwitch2.Ron","R9.IdealCommutingSwitch2.T","R9.R","R9.clock","Rp1.BooleanPulse1.period";
       names += "Rp1.BooleanPulse1.startTime","Rp1.BooleanPulse1.width","Rp1.Capacitor1.C","Rp1.IdealCommutingSwitch1.Goff","Rp1.IdealCommutingSwitch1.Ron","Rp1.IdealCommutingSwitch1.T","Rp1.IdealCommutingSwitch2.Goff","Rp1.IdealCommutingSwitch2.Ron","Rp1.IdealCommutingSwitch2.T","Rp1.R";
       names += "Rp1.clock","V.V","V.offset","V.signalSource.height","V.signalSource.offset","V.signalSource.startTime","V.startTime","c1","c2","c3";
       names += "c4","c5","l1","l2";

     }
     
      void   CauerLowPassSCWriteOutput::writeIntParameterNames(vector<string>& names)
     {
     }
      void   CauerLowPassSCWriteOutput::writeBoolParameterNames(vector<string>& names)
     {
      names += "R1.IdealCommutingSwitch1.useHeatPort","R1.IdealCommutingSwitch2.useHeatPort","R10.IdealCommutingSwitch1.useHeatPort","R10.IdealCommutingSwitch2.useHeatPort","R11.IdealCommutingSwitch1.useHeatPort","R11.IdealCommutingSwitch2.useHeatPort","R2.IdealCommutingSwitch1.useHeatPort","R2.IdealCommutingSwitch2.useHeatPort","R3.IdealCommutingSwitch1.useHeatPort","R3.IdealCommutingSwitch2.useHeatPort";
       names += "R4.IdealCommutingSwitch1.useHeatPort","R4.IdealCommutingSwitch2.useHeatPort","R5.IdealCommutingSwitch1.useHeatPort","R5.IdealCommutingSwitch2.useHeatPort","R7.IdealCommutingSwitch1.useHeatPort","R7.IdealCommutingSwitch2.useHeatPort","R8.IdealCommutingSwitch1.useHeatPort","R8.IdealCommutingSwitch2.useHeatPort","R9.IdealCommutingSwitch1.useHeatPort","R9.IdealCommutingSwitch2.useHeatPort";
       names += "Rp1.IdealCommutingSwitch1.useHeatPort","Rp1.IdealCommutingSwitch2.useHeatPort";
     }
     void   CauerLowPassSCWriteOutput::writeParameterDescription(vector<string>& names)
     {
      /*workarround ced*/
      names += "Capacitance","Capacitance","Capacitance","Capacitance","Capacitance","Capacitance","Capacitance","Capacitance","Capacitance","Time for one period";
       names += "Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance";
       names += "Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance";
       names += "Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false";
       names += "Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance";
       names += "Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period";
       names += "Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period";
       names += "Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance";
       names += "Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance";
       names += "Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false";
       names += "Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance";
       names += "Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period","Time instant of first pulse","Width of pulse in % of period";
       names += "Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance","Clock","Time for one period";
       names += "Time instant of first pulse","Width of pulse in % of period","Capacitance","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Opened switch conductance","Closed switch resistance","Fixed device temperature if useHeatPort = false","Resistance";
       names += "Clock","Height of step","Voltage offset","Height of step","Offset of output signal y","Output y = offset for time < startTime","Time offset","filter coefficient c1","filter coefficient c2","filter coefficient c3";
       names += "filter coefficient c4","filter coefficient c5","filter coefficient i1","filter coefficient i2";

     }
     
      void   CauerLowPassSCWriteOutput::writeIntParameterDescription(vector<string>& names)
     {
     }
     
      void   CauerLowPassSCWriteOutput::writeBoolParameterDescription(vector<string>& names)
     {
      names += "=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled";
       names += "=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled","=true, if HeatPort is enabled";
       names += "=true, if HeatPort is enabled","=true, if HeatPort is enabled";
     }
     void CauerLowPassSCWriteOutput::writeParams(HistoryImplType::value_type_p& params)
     {
      /*const int paramVarsStart = 1;
      const int intParamVarsStart  = paramVarsStart       + 154;
      const int boolparamVarsStart    = intParamVarsStart  + 0;
      */
      writeParamsReal(params);
      writeParamsInt(params);
      writeParamsBool(params);
     }
     void CauerLowPassSCWriteOutput::writeParamsReal_0( HistoryImplType::value_type_p& params  )
     {
        params(1)=_C1_P_C;params(2)=_C2_P_C;params(3)=_C3_P_C;params(4)=_C4_P_C;params(5)=_C5_P_C;params(6)=_C6_P_C;params(7)=_C7_P_C;params(8)=_C8_P_C;
        params(9)=_C9_P_C;params(10)=_R1_P_BooleanPulse1_P_period;params(11)=_R1_P_BooleanPulse1_P_startTime;params(12)=_R1_P_BooleanPulse1_P_width;params(13)=_R1_P_Capacitor1_P_C;params(14)=_R1_P_IdealCommutingSwitch1_P_Goff;params(15)=_R1_P_IdealCommutingSwitch1_P_Ron;params(16)=_R1_P_IdealCommutingSwitch1_P_T;
        params(17)=_R1_P_IdealCommutingSwitch2_P_Goff;params(18)=_R1_P_IdealCommutingSwitch2_P_Ron;params(19)=_R1_P_IdealCommutingSwitch2_P_T;params(20)=_R1_P_R;params(21)=_R1_P_clock;params(22)=_R10_P_BooleanPulse1_P_period;params(23)=_R10_P_BooleanPulse1_P_startTime;params(24)=_R10_P_BooleanPulse1_P_width;
        params(25)=_R10_P_Capacitor1_P_C;params(26)=_R10_P_IdealCommutingSwitch1_P_Goff;params(27)=_R10_P_IdealCommutingSwitch1_P_Ron;params(28)=_R10_P_IdealCommutingSwitch1_P_T;params(29)=_R10_P_IdealCommutingSwitch2_P_Goff;params(30)=_R10_P_IdealCommutingSwitch2_P_Ron;params(31)=_R10_P_IdealCommutingSwitch2_P_T;params(32)=_R10_P_R;
        params(33)=_R10_P_clock;params(34)=_R11_P_BooleanPulse1_P_period;params(35)=_R11_P_BooleanPulse1_P_startTime;params(36)=_R11_P_BooleanPulse1_P_width;params(37)=_R11_P_Capacitor1_P_C;params(38)=_R11_P_IdealCommutingSwitch1_P_Goff;params(39)=_R11_P_IdealCommutingSwitch1_P_Ron;params(40)=_R11_P_IdealCommutingSwitch1_P_T;
        params(41)=_R11_P_IdealCommutingSwitch2_P_Goff;params(42)=_R11_P_IdealCommutingSwitch2_P_Ron;params(43)=_R11_P_IdealCommutingSwitch2_P_T;params(44)=_R11_P_R;params(45)=_R11_P_clock;params(46)=_R2_P_BooleanPulse1_P_period;params(47)=_R2_P_BooleanPulse1_P_startTime;params(48)=_R2_P_BooleanPulse1_P_width;
        params(49)=_R2_P_Capacitor1_P_C;params(50)=_R2_P_IdealCommutingSwitch1_P_Goff;params(51)=_R2_P_IdealCommutingSwitch1_P_Ron;params(52)=_R2_P_IdealCommutingSwitch1_P_T;params(53)=_R2_P_IdealCommutingSwitch2_P_Goff;params(54)=_R2_P_IdealCommutingSwitch2_P_Ron;params(55)=_R2_P_IdealCommutingSwitch2_P_T;params(56)=_R2_P_R;
        params(57)=_R2_P_clock;params(58)=_R3_P_BooleanPulse1_P_period;params(59)=_R3_P_BooleanPulse1_P_startTime;params(60)=_R3_P_BooleanPulse1_P_width;params(61)=_R3_P_Capacitor1_P_C;params(62)=_R3_P_IdealCommutingSwitch1_P_Goff;params(63)=_R3_P_IdealCommutingSwitch1_P_Ron;params(64)=_R3_P_IdealCommutingSwitch1_P_T;
        params(65)=_R3_P_IdealCommutingSwitch2_P_Goff;params(66)=_R3_P_IdealCommutingSwitch2_P_Ron;params(67)=_R3_P_IdealCommutingSwitch2_P_T;params(68)=_R3_P_R;params(69)=_R3_P_clock;params(70)=_R4_P_BooleanPulse1_P_period;params(71)=_R4_P_BooleanPulse1_P_startTime;params(72)=_R4_P_BooleanPulse1_P_width;
        params(73)=_R4_P_Capacitor1_P_C;params(74)=_R4_P_IdealCommutingSwitch1_P_Goff;params(75)=_R4_P_IdealCommutingSwitch1_P_Ron;params(76)=_R4_P_IdealCommutingSwitch1_P_T;params(77)=_R4_P_IdealCommutingSwitch2_P_Goff;params(78)=_R4_P_IdealCommutingSwitch2_P_Ron;params(79)=_R4_P_IdealCommutingSwitch2_P_T;params(80)=_R4_P_R;
        params(81)=_R4_P_clock;params(82)=_R5_P_BooleanPulse1_P_period;params(83)=_R5_P_BooleanPulse1_P_startTime;params(84)=_R5_P_BooleanPulse1_P_width;params(85)=_R5_P_Capacitor1_P_C;params(86)=_R5_P_IdealCommutingSwitch1_P_Goff;params(87)=_R5_P_IdealCommutingSwitch1_P_Ron;params(88)=_R5_P_IdealCommutingSwitch1_P_T;
        params(89)=_R5_P_IdealCommutingSwitch2_P_Goff;params(90)=_R5_P_IdealCommutingSwitch2_P_Ron;params(91)=_R5_P_IdealCommutingSwitch2_P_T;params(92)=_R5_P_R;params(93)=_R5_P_clock;params(94)=_R7_P_BooleanPulse1_P_period;params(95)=_R7_P_BooleanPulse1_P_startTime;params(96)=_R7_P_BooleanPulse1_P_width;
        params(97)=_R7_P_Capacitor1_P_C;params(98)=_R7_P_IdealCommutingSwitch1_P_Goff;params(99)=_R7_P_IdealCommutingSwitch1_P_Ron;params(100)=_R7_P_IdealCommutingSwitch1_P_T;
     }
     void CauerLowPassSCWriteOutput::writeParamsReal_1( HistoryImplType::value_type_p& params  )
     {
        params(101)=_R7_P_IdealCommutingSwitch2_P_Goff;params(102)=_R7_P_IdealCommutingSwitch2_P_Ron;params(103)=_R7_P_IdealCommutingSwitch2_P_T;params(104)=_R7_P_R;params(105)=_R7_P_clock;params(106)=_R8_P_BooleanPulse1_P_period;params(107)=_R8_P_BooleanPulse1_P_startTime;params(108)=_R8_P_BooleanPulse1_P_width;
        params(109)=_R8_P_Capacitor1_P_C;params(110)=_R8_P_IdealCommutingSwitch1_P_Goff;params(111)=_R8_P_IdealCommutingSwitch1_P_Ron;params(112)=_R8_P_IdealCommutingSwitch1_P_T;params(113)=_R8_P_IdealCommutingSwitch2_P_Goff;params(114)=_R8_P_IdealCommutingSwitch2_P_Ron;params(115)=_R8_P_IdealCommutingSwitch2_P_T;params(116)=_R8_P_R;
        params(117)=_R8_P_clock;params(118)=_R9_P_BooleanPulse1_P_period;params(119)=_R9_P_BooleanPulse1_P_startTime;params(120)=_R9_P_BooleanPulse1_P_width;params(121)=_R9_P_Capacitor1_P_C;params(122)=_R9_P_IdealCommutingSwitch1_P_Goff;params(123)=_R9_P_IdealCommutingSwitch1_P_Ron;params(124)=_R9_P_IdealCommutingSwitch1_P_T;
        params(125)=_R9_P_IdealCommutingSwitch2_P_Goff;params(126)=_R9_P_IdealCommutingSwitch2_P_Ron;params(127)=_R9_P_IdealCommutingSwitch2_P_T;params(128)=_R9_P_R;params(129)=_R9_P_clock;params(130)=_Rp1_P_BooleanPulse1_P_period;params(131)=_Rp1_P_BooleanPulse1_P_startTime;params(132)=_Rp1_P_BooleanPulse1_P_width;
        params(133)=_Rp1_P_Capacitor1_P_C;params(134)=_Rp1_P_IdealCommutingSwitch1_P_Goff;params(135)=_Rp1_P_IdealCommutingSwitch1_P_Ron;params(136)=_Rp1_P_IdealCommutingSwitch1_P_T;params(137)=_Rp1_P_IdealCommutingSwitch2_P_Goff;params(138)=_Rp1_P_IdealCommutingSwitch2_P_Ron;params(139)=_Rp1_P_IdealCommutingSwitch2_P_T;params(140)=_Rp1_P_R;
        params(141)=_Rp1_P_clock;params(142)=_V_P_V;params(143)=_V_P_offset;params(144)=_V_P_signalSource_P_height;params(145)=_V_P_signalSource_P_offset;params(146)=_V_P_signalSource_P_startTime;params(147)=_V_P_startTime;params(148)=_c1;
        params(149)=_c2;params(150)=_c3;params(151)=_c4;params(152)=_c5;params(153)=_l1;params(154)=_l2;
     }
     
     void CauerLowPassSCWriteOutput::writeParamsReal(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 165
       CauerLowPassSCWriteOutput::writeParamsReal_0(params);CauerLowPassSCWriteOutput::writeParamsReal_1(params);
     }
     
     void CauerLowPassSCWriteOutput::writeParamsInt(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 0
     }
     void CauerLowPassSCWriteOutput::writeParamsBool_0( HistoryImplType::value_type_p& params  )
     {
        params(155)=_R1_P_IdealCommutingSwitch1_P_useHeatPort;params(156)=_R1_P_IdealCommutingSwitch2_P_useHeatPort;params(157)=_R10_P_IdealCommutingSwitch1_P_useHeatPort;params(158)=_R10_P_IdealCommutingSwitch2_P_useHeatPort;params(159)=_R11_P_IdealCommutingSwitch1_P_useHeatPort;params(160)=_R11_P_IdealCommutingSwitch2_P_useHeatPort;params(161)=_R2_P_IdealCommutingSwitch1_P_useHeatPort;params(162)=_R2_P_IdealCommutingSwitch2_P_useHeatPort;
        params(163)=_R3_P_IdealCommutingSwitch1_P_useHeatPort;params(164)=_R3_P_IdealCommutingSwitch2_P_useHeatPort;params(165)=_R4_P_IdealCommutingSwitch1_P_useHeatPort;params(166)=_R4_P_IdealCommutingSwitch2_P_useHeatPort;params(167)=_R5_P_IdealCommutingSwitch1_P_useHeatPort;params(168)=_R5_P_IdealCommutingSwitch2_P_useHeatPort;params(169)=_R7_P_IdealCommutingSwitch1_P_useHeatPort;params(170)=_R7_P_IdealCommutingSwitch2_P_useHeatPort;
        params(171)=_R8_P_IdealCommutingSwitch1_P_useHeatPort;params(172)=_R8_P_IdealCommutingSwitch2_P_useHeatPort;params(173)=_R9_P_IdealCommutingSwitch1_P_useHeatPort;params(174)=_R9_P_IdealCommutingSwitch2_P_useHeatPort;params(175)=_Rp1_P_IdealCommutingSwitch1_P_useHeatPort;params(176)=_Rp1_P_IdealCommutingSwitch2_P_useHeatPort;
     }
     
     void CauerLowPassSCWriteOutput::writeParamsBool(HistoryImplType::value_type_p& params  )
     {
       //number of vars: 22
       CauerLowPassSCWriteOutput::writeParamsBool_0(params);
     }