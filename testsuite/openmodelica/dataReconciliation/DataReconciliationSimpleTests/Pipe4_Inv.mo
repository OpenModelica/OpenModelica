within DataReconciliationSimpleTests;
model Pipe4_Inv
  Real p;
  parameter Real q=1;
  Real Q1(uncertain=Uncertainty.refine)=0;
  Real Q2(uncertain=Uncertainty.refine)=0;
  Real y1, y2;
equation
  p=2;
  Q1 = y1;
  Q2 = q*y2;
  // y1 = y2;
  // Q1 = q*p;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Pipe4_Inv;
