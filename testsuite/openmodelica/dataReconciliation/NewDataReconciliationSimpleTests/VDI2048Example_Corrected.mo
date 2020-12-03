within NewDataReconciliationSimpleTests;

model VDI2048Example_Corrected
  Real mFDKEL(uncertain = Uncertainty.refine, start = 46.241) = 46.241;
  Real mFDKELL(uncertain = Uncertainty.refine, start = 45.668) = 45.668;
  Real mSPL(uncertain = Uncertainty.refine, start = 44.575) = 44.575;
  Real mSPLL(uncertain = Uncertainty.refine, start = 44.319) = 44.319;
  Real mV(uncertain = Uncertainty.refine, start = 0.525);
  Real mHK(uncertain = Uncertainty.refine, start = 69.978) = 69.978;
  Real mA7(uncertain = Uncertainty.refine, start = 10.364) = 10.364;
  Real mA6(uncertain = Uncertainty.refine, start = 3.744) = 3.744;
  Real mA5(uncertain = Uncertainty.refine, start = 4.391);
  Real mHDNK(uncertain = Uncertainty.refine, start = 18.498);
  equation
  mFDKEL + mFDKELL - mSPL - mSPLL + 0.4 * mV = 0;
  mSPL + mSPLL - mV - mHK - mA7 - mA6 - mA5 = 0;
  mA7 + mA6 + mA5 - mHDNK = 0;
  annotation(
    Icon(coordinateSystem(initialScale = 0.1, grid = {10, 10})),
    Diagram(coordinateSystem(initialScale = 0.1, grid = {10, 10})));
end VDI2048Example_Corrected;
