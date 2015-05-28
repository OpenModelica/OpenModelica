  void CoupledInductorsInitialize::initializeParameterVars_0()
  {

                setRealStartValue(_C1_P_C,1e-06);
                setRealStartValue(_C1_P_IC,0.0);

                setRealStartValue(_C2_P_C,0.002);
                setRealStartValue(_C2_P_IC,0.0);
                setRealStartValue(_L1_P_IC,0.0);

                setRealStartValue(_L1_P_L,1.0);
                setRealStartValue(_L2_P_IC,0.0);

                setRealStartValue(_L2_P_L,0.01);
                setRealStartValue(_L3_P_IC,0.0);

                setRealStartValue(_L3_P_L,0.01);

                setRealStartValue(_R1_P_R,1.0);

                setRealStartValue(_R2_P_R,1.0);

                setRealStartValue(_R3_P_R,1000.0);

                setRealStartValue(_R4_P_R,1.0);

                setRealStartValue(_R5_P_R,1000.0);

                setRealStartValue(_k1_P_k,0.1);

                setRealStartValue(_k2_P_k,0.05);

                setRealStartValue(_k3_P_k,0.05);

                setRealStartValue(_sineVoltage_P_FREQ,50.0);
                setRealStartValue(_sineVoltage_P_TD,0.0);
                setRealStartValue(_sineVoltage_P_THETA,0.0);

                setRealStartValue(_sineVoltage_P_VA,220.0);
                setRealStartValue(_sineVoltage_P_VO,0.0);
  }
  
  void CoupledInductorsInitialize::initializeParameterVars()
  {
    CoupledInductorsInitialize::initializeParameterVars_0();
  }
  
  void CoupledInductorsInitialize::initializeIntParameterVars()
  {
  }
  void CoupledInductorsInitialize::initializeBoolParameterVars_0()
  {

                setBoolStartValue(_C1_P_UIC,false);

                setBoolStartValue(_C2_P_UIC,false);

                setBoolStartValue(_L1_P_UIC,false);

                setBoolStartValue(_L2_P_UIC,false);

                setBoolStartValue(_L3_P_UIC,false);
  }
  
  void CoupledInductorsInitialize::initializeBoolParameterVars()
  {
    CoupledInductorsInitialize::initializeBoolParameterVars_0();
  }
  
  void CoupledInductorsInitialize::initializeStringParameterVars()
  {
  }