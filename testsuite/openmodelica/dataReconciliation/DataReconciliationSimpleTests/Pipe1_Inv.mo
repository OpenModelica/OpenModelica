within DataReconciliationSimpleTests;
model Pipe1_Inv
    Real p;
    Real Q1(uncertain=Uncertainty.refine)=0;
    Real Q2(uncertain=Uncertainty.refine)=0;
equation
    p=2;
    //Q1 = Q2;
    //Q1 = p;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Pipe1_Inv;
