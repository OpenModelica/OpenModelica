within ModelicaDataReconciliationSimpleTests.Models.Splitter;

model Splitter0
  parameter Modelica.Units.SI.MassFlowRate Q2_0 = 5 annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.Units.SI.MassFlowRate Q3_0 = 5 annotation(__OpenModelica_BoundaryCondition = true);
  parameter Modelica.Units.SI.Temperature T1_0 = 293.15 annotation(__OpenModelica_BoundaryCondition = true);

  Modelica.Units.SI.MassFlowRate Q1(start=1e3, uncertain=Uncertainty.refine);
  Modelica.Units.SI.MassFlowRate Q2(start=1e3, uncertain=Uncertainty.refine) ;
  Modelica.Units.SI.MassFlowRate Q3(start=1e3, uncertain=Uncertainty.refine) ;

  Modelica.Units.SI.Temperature T1(start=273.15, uncertain=Uncertainty.refine);

equation
  T1 = T1_0;
  Q2 = Q2_0;
  Q3 = Q3_0;

  Q1 = Q2 + Q3;
annotation (__OpenModelica_simulationFlags(
      lv="LOG_JAC", eps = "0.023",
      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/Splitter0_Inputs.csv"));
end Splitter0;