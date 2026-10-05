within NewDataReconciliationSimpleTests;

model Splitter5g
  Real Q1(uncertain = Uncertainty.refine, start=2); // Variable of interest
  Real Q2(uncertain = Uncertainty.refine, start=1); // Variable of interest
  Real Q3(uncertain = Uncertainty.refine, start=0); // Variable of interest
  Real T1(uncertain = Uncertainty.refine); // Variable of interest
  Real T2(uncertain = Uncertainty.refine); // Variable of interest
  Real T3(uncertain = Uncertainty.refine); // Variable of interest
  Real T(uncertain = Uncertainty.refine); // Variable of interest
  Real P1(uncertain = Uncertainty.refine); // Variable of interest;
  Real P2(uncertain = Uncertainty.refine); // Variable of interest;
  Real P3(uncertain = Uncertainty.refine); // Variable of interest;

  Real P01(uncertain = Uncertainty.propagate) = 10 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  Real Q02(uncertain = Uncertainty.propagate) = 1 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  Real Q03(uncertain = Uncertainty.propagate) = 1 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  Real h01(uncertain = Uncertainty.propagate) = 1e5 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  Real h02 = 1e5 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  Real h03 = 1e5 annotation(__OpenModelica_BoundaryCondition = true); // Boundary condition
  parameter Real cp = 5000;
  parameter Real b = -0.01;
  parameter Real W = 1e6;
  Real Q04, Q05;
  Real T1_P1, T1_P2, T2_P1, T2_P2, T3_P1, T3_P2;
  Real V_Q1, V_Q2, V_Q3, V_Q4, V_Q5;
  Real T1_Q1, T1_Q2, T2_Q1, T2_Q2, T3_Q1, T3_Q2;
  Real P, V_P1, V_P2, V_P3;
  Real V_h, V_h1, V_h2, V_h3, V_h4, V_h5;
  Real T1_h, T2_h, T3_h;
equation
  Q04 = 0;
  V_h4 = 1.e5;
  Q05 = 0;
  V_h5 = 1.e5;
  V_Q4 = Q04;
  V_Q5 = Q05;
  T1_P1 = P01;
  T2_Q2 = Q02;
  T3_Q2 = Q03;
  T1_P1 - T1_P2 = Q1^2;
  T2_P1 - T2_P2 = Q2^2;
  T3_P1 - T3_P2 = Q3^2;
  V_Q1 = V_Q2 + V_Q3 + V_Q4 + V_Q5;
  V_Q1 = T1_Q2;
  T1_Q2 = Q1;
  V_Q2 = T2_Q1;
  T2_Q1 = Q2;
  V_Q3 = T3_Q1;
  T3_Q1 = Q3;
  T1_P2 = V_P1;
  V_P1 = P;
  T2_P1 = V_P2;
  V_P2 = P;
  T3_P1 = V_P3;
  V_P3 = P;
  T1_Q1 = Q1;
  T2_Q2 = Q2;
  T3_Q2 = Q3;

  0 = V_h1*V_Q1 - V_h2*V_Q2 - V_h3*V_Q3 - V_h4*V_Q4 - V_h5*V_Q5 + W;
  V_h1 = T1_h;
  V_h2 = T2_h;
  V_h3 = T3_h;

  //T1_h = if Q1 > 0 then h01 else V_h;
  //T2_h = if Q2 > 0 then V_h else h02;
  //T3_h = if Q3 > 0 then V_h else h03;

  T1_h = h01;
  T2_h = V_h;
  T3_h = V_h;

  T1_h = cp*T1 + b*P1;
  T2_h = cp*T2 + b*P2;
  T3_h = cp*T3 + b*P3;

  V_h = cp*T + b*P;

  P1 = (T1_P1 + T1_P2)/2;
  P2 = (T2_P1 + T2_P2)/2;
  P3 = (T3_P1 + T3_P2)/2;

  annotation(
    Icon(coordinateSystem(preserveAspectRatio = false)),
    Diagram(coordinateSystem(preserveAspectRatio = false)));
end Splitter5g;
