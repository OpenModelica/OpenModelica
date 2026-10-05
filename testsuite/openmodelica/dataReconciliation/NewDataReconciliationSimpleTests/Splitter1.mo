within NewDataReconciliationSimpleTests;

model Splitter1 "OK"
  Real Q1(uncertain = Uncertainty.refine, start = 2.10);
  Real Q2(uncertain = Uncertainty.refine, start = 1.05);
  Real Q3(uncertain = Uncertainty.refine, start = 0.97);
  Real P01 annotation(__OpenModelica_BoundaryCondition = true);
  Real P02 annotation(__OpenModelica_BoundaryCondition = true);
  Real P03 annotation(__OpenModelica_BoundaryCondition = true);
  Real T1_P1, T1_P2, T2_P1, T2_P2, T3_P1, T3_P2;
  Real V_Q1, V_Q2, V_Q3;
  Real T1_Q1, T1_Q2, T2_Q1, T2_Q2, T3_Q1, T3_Q2;
  Real P, V_P1, V_P2, V_P3;
equation
  P01 = 3;
  P02 = 1;
  P03 = 1;
  T1_P1 = P01;
  T2_P2 = P02;
  T3_P2 = P03;
  T1_P1 - T1_P2 = Q1^2 annotation(
    __OpenModelica_ApproximatedEquation = true);
  T2_P1 - T2_P2 = Q2^2 annotation(
    __OpenModelica_ApproximatedEquation = true);
  T3_P1 - T3_P2 = Q3^2 annotation(
    __OpenModelica_ApproximatedEquation = true);
  V_Q1 = V_Q2 + V_Q3;
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
  annotation(
    Icon(coordinateSystem(preserveAspectRatio = false)),
    Diagram(coordinateSystem(preserveAspectRatio = false)));
end Splitter1;
