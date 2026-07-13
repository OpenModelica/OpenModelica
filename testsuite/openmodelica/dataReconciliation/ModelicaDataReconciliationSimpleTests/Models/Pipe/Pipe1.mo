within ModelicaDataReconciliationSimpleTests.Models.Pipe;
model Pipe1
  Real p=2 annotation (__OpenModelica_BoundaryCondition=true);
  Real Q1(uncertain=Uncertainty.refine);
  Real Q2(uncertain=Uncertainty.refine);
equation
  //p=2;
  Q1 = Q2;
  Q1 = p;
  annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",

      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.Pipe1_Inputs.csv"));
end Pipe1;
