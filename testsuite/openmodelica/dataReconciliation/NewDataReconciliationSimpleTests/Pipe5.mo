within NewDataReconciliationSimpleTests;
model Pipe5 "OK"
  Real p annotation(__OpenModelica_BoundaryCondition = true);
  parameter Real q=1;
  Real Q1(uncertain=Uncertainty.refine);
  Real Q2(uncertain=Uncertainty.refine);
  Real y1, y2;
equation
  p=2;
  Q1 = y1;
  Q2 = q*y2;
  y1 = q*y2;
  Q1 = p;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Pipe5;
