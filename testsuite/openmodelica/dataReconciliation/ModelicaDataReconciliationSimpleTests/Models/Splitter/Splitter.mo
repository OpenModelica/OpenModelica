within ModelicaDataReconciliationSimpleTests.Models.Splitter;
model Splitter
  Real Q(uncertain=Uncertainty.refine, start=2.10);
  Real Q1(uncertain=Uncertainty.refine, start=1.05);
  Real Q2(uncertain=Uncertainty.refine, start=0.97);
  Real y;
  Real y1;
  Real y2;
  Real a;
  parameter Real A=0.5;
  parameter Real Y=2 annotation (__OpenModelica_BoundaryCondition=true);
equation
  //  Y = 2;
  //  y = Y;
  Q = Y;
  a = A;
  y1 = a*y;
  y = y1 + y2;
  Q = y;
  Q1 = y1;
  Q2 = y2;
  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",

      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.Splitter_Inputs.csv"));
end Splitter;
