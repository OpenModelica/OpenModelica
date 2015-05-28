
  void CoupledInductorsInitialize::initializeAlgVars_0()
  {

              setRealStartValue(_C1_P_i,0.0);

              setRealStartValue(_C2_P_i,0.0);

              setRealStartValue(_L1_P_ICP_P_di,0.0);

              setRealStartValue(_L1_P_ICP_P_v,0.0);

              setRealStartValue(_L1_P_v,0.0);

              setRealStartValue(_L2_P_ICP_P_di,0.0);

              setRealStartValue(_L2_P_ICP_P_v,0.0);

              setRealStartValue(_L2_P_v,0.0);

              setRealStartValue(_L3_P_ICP_P_di,0.0);

              setRealStartValue(_L3_P_ICP_P_v,0.0);

              setRealStartValue(_L3_P_v,0.0);

              setRealStartValue(_R1_P_v,0.0);

              setRealStartValue(_R2_P_v,0.0);

              setRealStartValue(_R3_P_i,0.0);

              setRealStartValue(_R4_P_v,0.0);

              setRealStartValue(_R5_P_i,0.0);

              setRealStartValue(_ground_P_p_P_i,0.0);

              setRealStartValue(_ground_P_p_P_v,0.0);

              setRealStartValue(_k1_P_M,0.0);

              setRealStartValue(_k1_P_inductiveCouplePin1_P_v,0.0);

              setRealStartValue(_k1_P_inductiveCouplePin2_P_v,0.0);

              setRealStartValue(_k2_P_M,0.0);

              setRealStartValue(_k2_P_inductiveCouplePin1_P_v,0.0);

              setRealStartValue(_k2_P_inductiveCouplePin2_P_v,0.0);

              setRealStartValue(_k3_P_M,0.0);

              setRealStartValue(_k3_P_inductiveCouplePin1_P_v,0.0);

              setRealStartValue(_k3_P_inductiveCouplePin2_P_v,0.0);

              setRealStartValue(_sineVoltage_P_v,0.0);
  }
  
  void CoupledInductorsInitialize::initializeAlgVars()
  {
    CoupledInductorsInitialize::initializeAlgVars_0();
  }

void CoupledInductorsInitialize::initializeDiscreteAlgVars()
{
}


void CoupledInductorsInitialize::initializeIntAlgVars()
{
}

 void CoupledInductorsInitialize::initializeBoolAlgVars()
{
}