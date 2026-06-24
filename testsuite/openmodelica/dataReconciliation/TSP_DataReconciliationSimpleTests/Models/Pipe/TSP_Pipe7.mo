within TSP_DataReconciliationSimpleTests.Models.Pipe;
model TSP_Pipe7
  Components.BoundaryConditions.Sink sink1
    annotation (Placement(visible=true,transformation(origin={92,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss1(
    Pm(
      displayUnit="Pa"),
    Q(
      start=100.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    fluid=3,
    h(
      start=1e5,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={-50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.PressureLoss.SingularPressureLoss singularPressureLoss2(
    Pm(
      displayUnit="Pa"),
    Q(
      start=99.3,
      uncertain=Uncertainty.refine),
    T(
      displayUnit="K"),
    flow_reversal=false,
    fluid=3,
    h(
      start=1.1e5,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={50,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.Volumes.VolumeATh volumeATh1(
    P(
      displayUnit="Pa"),
    fluid=3,
    h(
      start=1,
      uncertain=Uncertainty.refine),
    rho(
      displayUnit="kg/m3"))
    annotation (Placement(visible=true,transformation(origin={0,0},extent={{-10,-10},{10,10}},rotation=0)));
  Components.BoundaryConditions.SourcePQ sourcePQ1(
    h0=105000)
    annotation (Placement(visible=true,transformation(origin={-90,0},extent={{-10,-10},{10,10}},rotation=0)));
equation
  connect(singularPressureLoss1.C2,volumeATh1.Ce1)
    annotation (Line(points={{-40,0},{-10,0}},color={0,0,255}));
  connect(volumeATh1.Cs1,singularPressureLoss2.C1)
    annotation (Line(points={{10,0},{40,0}},color={0,0,255}));
  connect(sourcePQ1.C,singularPressureLoss1.C1)
    annotation (Line(points={{-80,0},{-60,0}},color={0,0,255}));
  connect(singularPressureLoss2.C2,sink1.C)
    annotation (Line(points={{60,0},{82,0},{82,0},{82,0}},color={0,0,255}));
  annotation (
    __OpenModelica_simulationFlags(
      lv="LOG_JAC",
      eps="0.023",
      s="dassl",
      sx="modelica://TSP_DataReconciliationSimpleTests/resources/NewDataReconciliationSimpleTests.TSP_Pipe7_Inputs.csv"));
end TSP_Pipe7;
