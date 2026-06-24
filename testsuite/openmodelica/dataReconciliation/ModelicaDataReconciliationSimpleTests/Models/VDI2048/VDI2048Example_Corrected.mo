within ModelicaDataReconciliationSimpleTests.Models.VDI2048;
model VDI2048Example_Corrected
  Real mFDKEL(uncertain=Uncertainty.refine) = 46.241;
  Real mFDKELL(uncertain=Uncertainty.refine) = 45.668;
  Real mSPL(uncertain=Uncertainty.refine) = 44.575;
  Real mSPLL(uncertain=Uncertainty.refine) = 44.319;
  Real mV(uncertain=Uncertainty.refine);
  Real mHK(uncertain=Uncertainty.refine) = 69.978;
  Real mA7(uncertain=Uncertainty.refine) = 10.364;
  Real mA6(uncertain=Uncertainty.refine) = 3.744;
  Real mA5(uncertain=Uncertainty.refine);
  Real mHDNK(uncertain=Uncertainty.refine);
  Real mD(uncertain=Uncertainty.refine) = 2.092;

  Real mFD1;
  Real mFD2;
  Real mFD3;
  Real mHDANZ;

equation

  mFD1 = mFDKEL + mFDKELL - 0.2*mV;
  mFD2 = mSPL + mSPLL - 0.6*mV;
  mFD3 = mHK + mA7 + mA6 + mA5 + 0.4*mV;
  mHDANZ = mA7 + mA6 + mA5;

  0 = mFD1 - mFD2;
  0 = mFD2 - mFD3;
  0 = mHDANZ - mHDNK;

  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",

      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.VDI2048Example_Corrected_Inputs.csv"));
end VDI2048Example_Corrected;
