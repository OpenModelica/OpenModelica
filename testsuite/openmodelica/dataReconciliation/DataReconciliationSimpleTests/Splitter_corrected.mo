within DataReconciliationSimpleTests;
model Splitter_corrected
  Real Q(uncertain=Uncertainty.refine,start=2.10);
  Real Q1(uncertain=Uncertainty.refine,start=1.05);
  Real Q2(uncertain=Uncertainty.refine,start=0.97);
  Real y, y1, y2, a, yy;
  parameter Real A=0.5;
  Real Y;
equation
  Y = 2;
  y = Y;
  a = A;
  y1 = a*yy;
  yy = y1 + y2;
  Q = y;
  Q1 = y1;
  Q2 = y2;
  yy = Q;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Splitter_corrected;
