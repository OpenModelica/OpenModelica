within DataReconciliationSimpleTests;
model Pipe3_Inv
    Real p=2;
    Real Q1(uncertain=Uncertainty.refine)=0;
    Real Q2(uncertain=Uncertainty.refine)=0;
    Real y1, y2;
equation
    Q1 = y1;
    Q2 = y2;
    // y1 = y2;
    // Q1 = p;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Pipe3_Inv;
