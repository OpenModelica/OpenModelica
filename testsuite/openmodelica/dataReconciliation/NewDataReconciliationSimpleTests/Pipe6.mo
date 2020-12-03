within NewDataReconciliationSimpleTests;

model Pipe6 "OK"
    parameter Real P1=3 annotation(__OpenModelica_BoundaryCondition = true);
    parameter Real P2=1 annotation(__OpenModelica_BoundaryCondition = true);
    parameter Real k=1;
    Real Q1(uncertain=Uncertainty.refine);
    Real Q2(uncertain=Uncertainty.refine);
    Real P;
equation
    P1 - P = k*Q1^2;
    P - P2 = k*Q2^2;
    Q1 = Q2;
end Pipe6;
