within NewDataReconciliationSimpleTests;
model Splitter "OK - Check numerical results"
  Real Q(uncertain=Uncertainty.refine,start=2.10);
  Real Q1(uncertain=Uncertainty.refine,start=1.05);
  Real Q2(uncertain=Uncertainty.refine,start=0.97);
  Real y, y1, y2, a;
  parameter Real A=0.5;
  Real Y annotation(__OpenModelica_BoundaryCondition = true);
equation
  Y = 2;
//  y = Y;
  Q = Y;
  a = A;
  y1 = a*y;
  y = y1 + y2;
  Q = y;
  Q1 = y1;
  Q2 = y2;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Splitter;
