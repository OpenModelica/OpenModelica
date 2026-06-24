within ModelicaDataReconciliationSimpleTests.Models.Pipe;

model PipeCorrelation
parameter Real Q_0 = 10 annotation (__OpenModelica_BoundaryCondition = true);
    Real Q1 (start = 10, uncertain = Uncertainty.refine);
    Real Q2 (start = 10, uncertain = Uncertainty.refine);

equation
    Q1 = Q2;
    Q1 = Q_0;
annotation (__OpenModelica_simulationFlags(
      lv = "LOG_JAC", eps = "0.023",
      s="dassl",
      sx="modelica://ModelicaDataReconciliationSimpleTests/resources/PipeCorrelation_Inputs.csv", cx = "modelica://ModelicaDataReconciliationSimpleTests/resources/PipeCorrelation_InputsS_xj.csv"));

end PipeCorrelation;