within DataReconciliationSimpleTests;
model FourFlows_Inv
    Real Q1(uncertain=Uncertainty.refine,start=2.10)=0;
    Real Q2(uncertain=Uncertainty.refine,start=1.10)=0;
    Real Q3(uncertain=Uncertainty.refine,start=0.95)=0;
    Real Q4(uncertain=Uncertainty.refine,start=2.00)=0;
    Real q0 = 100;
    parameter Real a = 0.5;
  equation
    // Q1 = q0;
    // Q2 = a*q0;
    // Q1 = Q2 + Q3;
    // Q4 = Q2 + Q3;
    annotation (Icon(coordinateSystem(preserveAspectRatio=false)), Diagram(
          coordinateSystem(preserveAspectRatio=false)));
  end FourFlows_Inv;
