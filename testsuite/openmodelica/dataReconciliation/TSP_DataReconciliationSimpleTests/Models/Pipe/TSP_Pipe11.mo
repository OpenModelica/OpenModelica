within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe11
  Components.BoundaryConditions.Sink sink1
    annotation (Placement(visible=true,transformation(origin={92,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      start=100.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    h(
      start=1e5,
      uncertain=Uncertainty.refine),
    p_rho(
      displayUnit="kg/m3"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa",
      uncertain=Uncertainty.refine),
    Q(
      start=99.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    h(
      start=1.1e5,
      uncertain=Uncertainty.refine),
    p_rho(
      displayUnit="kg/m3"),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourcePQ1(
    h0=105000)
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(sourcePQ1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sink1.C)
    annotation (Line(points={{60,0},{82,0},{82,0},{82,0}},color={0,0,255}));
  connect(singularPressureLoss1.C2,singularPressureLoss2.C1)
    annotation (Line(points={{-40,0},{40,0},{40,0},{40,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe11_Inputs.csv"));
end TSP_Pipe11;
