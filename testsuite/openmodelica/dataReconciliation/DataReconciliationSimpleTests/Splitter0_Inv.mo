within DataReconciliationSimpleTests;

model Splitter0_Inv
  Real Q1(uncertain = Uncertainty.refine, start = 2.10)=0;
  Real Q2(uncertain = Uncertainty.refine, start = 1.05)=1;
  Real Q3(uncertain = Uncertainty.refine, start = 0.97)=1;
equation
  Q1 = Q2 + Q3;
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = false)),
    Diagram(coordinateSystem(preserveAspectRatio = false)));
end Splitter0_Inv;
