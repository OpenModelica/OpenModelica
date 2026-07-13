within ModelicaDataReconciliationSimpleTests.Models.Pipe;
model Pipe5
  Real p=2 annotation (__OpenModelica_BoundaryCondition=true);
  parameter Real q=1;
  Real Q1(uncertain=Uncertainty.refine);
  Real Q2(uncertain=Uncertainty.refine);
  Real y1;
  Real y2;
equation
  //p=2;
  Q1 = y1;
  Q2 = q*y2;
  y1 = q*y2;
  Q1 = p;
  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",

      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.Pipe5_Inputs.csv"));
end Pipe5;
