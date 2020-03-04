within DataReconciliationSimpleTests;
model FourFlows
    Real Q1(uncertain=Uncertainty.refine,start=2.10);
    Real Q2(uncertain=Uncertainty.refine,start=1.10);
    Real Q3(uncertain=Uncertainty.refine,start=0.95);
    Real Q4(uncertain=Uncertainty.refine,start=2.00);
    parameter Real q0 = 100 annotation(__OpenModelica_BoundaryCondition = true);
    parameter Real a = 0.5 annotation(__OpenModelica_BoundaryCondition = true);
  equation
    Q1 = q0;
    Q2 = a*q0;
    Q1 = Q2 + Q3;
    Q4 = Q2 + Q3;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end FourFlows;


