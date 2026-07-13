within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe
  Components.BoundaryConditions.SourcePQ sourcePQ1
    annotation (Placement(visible=true,transformation(origin={-70,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.Sink sink1
    annotation (Placement(visible=true,transformation(origin={70,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-30,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={30,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(singularPressureLoss2.C2,sink1.C)
    annotation (Line(points={{40,0},{60,0},{60,0},{60,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,singularPressureLoss2.C1)
    annotation (Line(points={{-20,0},{18,0},{18,0},{20,0},{20,0}},color={0,0,255}));
  connect(sourcePQ1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-60,0},{-40,0},{-40,0},{-40,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe_Inputs.csv"));
end TSP_Pipe;
