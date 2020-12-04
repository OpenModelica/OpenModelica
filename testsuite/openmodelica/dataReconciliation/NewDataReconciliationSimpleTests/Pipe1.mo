within NewDataReconciliationSimpleTests;
model Pipe1 "OK"
    Real p annotation(__OpenModelica_BoundaryCondition = true);
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
equation
    p=2;
    Q1 = Q2;
    Q1 = p;
  annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
        coordinateSystem(preserveAspectRatio=false)));
end Pipe1;
