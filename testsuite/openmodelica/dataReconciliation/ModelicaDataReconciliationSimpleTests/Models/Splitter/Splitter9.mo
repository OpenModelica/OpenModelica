within ModelicaDataReconciliationSimpleTests.Models.Splitter;
model Splitter9 "Article example"
  Real k1(uncertain=Uncertainty.refine);
  parameter Real k2=1;
  parameter Real k3=1;
  parameter Real cp=4200;
  parameter Real b=190;
  parameter Real W=1.e6;

  parameter Real P1_bc=3.e5 annotation (__OpenModelica_BoundaryCondition=true);
  parameter Real Q2_bc=1.05 annotation (__OpenModelica_BoundaryCondition=true);
  parameter Real Q3_bc=0.97 annotation (__OpenModelica_BoundaryCondition=true);
  parameter Real h1_bc=1.e5 annotation (__OpenModelica_BoundaryCondition=true);

  Real Q1(uncertain=Uncertainty.refine);
  Real Q2(uncertain=Uncertainty.refine);
  Real Q3(uncertain=Uncertainty.refine);

  Real P;
  Real P1(uncertain=Uncertainty.refine);
  Real P2(uncertain=Uncertainty.refine);
  Real P3(uncertain=Uncertainty.refine);

  Real P1_l;
  Real P1_r;
  Real P2_l;
  Real P2_r;
  Real P3_l;
  Real P3_r;

  Real h;
  Real h1;
  Real h2;
  Real h3;

  Real T(uncertain=Uncertainty.refine);
  Real T1(uncertain=Uncertainty.refine);
  Real T2(uncertain=Uncertainty.refine);
  Real T3(uncertain=Uncertainty.refine);

equation

  P1_l = P1_bc;
  h1 = h1_bc;
  Q2 = Q2_bc;
  Q3 = Q3_bc;

  k1 = 1;

  0 = Q1 - Q2 - Q3;
  0 = h1*Q1 - h2*Q2 - h3*Q3 + W;

  P1_l - P1_r = k1*Q1^2;
  P2_l - P2_r = k2*Q2^2;
  P3_l - P3_r = k3*Q3^2;

  P = P1_r;
  P = P2_l;
  P = P3_l;

  h2 = h;
  h3 = h;

  P1 = (P1_l + P1_r)/2;
  P2 = (P2_l + P2_r)/2;
  P3 = (P3_l + P3_r)/2;

  h = cp*T + b*P;
  h1 = cp*T1 + b*P1;
  h2 = cp*T2 + b*P2;
  h3 = cp*T3 + b*P3;

  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",

      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.Splitter9_Inputs.csv"));
end Splitter9;
